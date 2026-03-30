---
name: go-domain-events
description: |
  Go Domain Events 實作：事件定義、發布模式、Event Bus、Outbox Pattern、冪等處理、
  Event Sourcing 基礎、非同步處理。

  **適用場景**：DDD Domain Events、實作 Event Bus、Outbox Pattern、冪等性設計、
  非同步事件處理、微服務溝通、Event Sourcing、解耦業務邏輯。
keywords:
  - domain events
  - event bus
  - outbox pattern
  - idempotency
  - event sourcing
  - async events
  - event-driven
  - message queue
  - event publishing
  - saga pattern
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Go Domain Events 實作規範

> **相關 Skills**：本規範建議搭配 `go-ddd`（領域驅動設計）與 `go-database`（Outbox Pattern）

---

## Domain Events 概念

### 為何需要 Domain Events？

- **解耦**：業務邏輯不直接依賴下游服務
- **可擴展**：新增 Event Handler 不影響既有程式碼
- **可測試**：可獨立測試事件發布與處理邏輯
- **審計**：事件即為業務操作的歷史記錄

### 事件 vs 命令

| 類型   | 時態   | 範例                      | 可拒絕 |
|--------|--------|---------------------------|--------|
| 命令   | 未來式 | CreateUser、PlaceOrder   | 是     |
| 事件   | 過去式 | UserCreated、OrderPlaced | 否     |

---

## 事件定義

### 基本事件結構

```go
package domain

import (
    "time"
    "github.com/google/uuid"
)

// DomainEvent 介面
type DomainEvent interface {
    EventID() string
    EventType() string
    AggregateID() string
    OccurredAt() time.Time
}

// BaseEvent 基礎實作
type BaseEvent struct {
    ID          string    `json:"id"`
    Type        string    `json:"type"`
    AggrID      string    `json:"aggregate_id"`
    Timestamp   time.Time `json:"occurred_at"`
    Version     int       `json:"version"`
}

func NewBaseEvent(eventType string, aggregateID string, version int) BaseEvent {
    return BaseEvent{
        ID:        uuid.New().String(),
        Type:      eventType,
        AggrID:    aggregateID,
        Timestamp: time.Now(),
        Version:   version,
    }
}

func (e BaseEvent) EventID() string       { return e.ID }
func (e BaseEvent) EventType() string     { return e.Type }
func (e BaseEvent) AggregateID() string   { return e.AggrID }
func (e BaseEvent) OccurredAt() time.Time { return e.Timestamp }
```

### 具體事件範例

```go
// UserCreated 事件
type UserCreated struct {
    BaseEvent
    Email string `json:"email"`
    Name  string `json:"name"`
}

func NewUserCreated(userID string, email string, name string) *UserCreated {
    return &UserCreated{
        BaseEvent: NewBaseEvent("UserCreated", userID, 1),
        Email:     email,
        Name:      name,
    }
}

// OrderPlaced 事件
type OrderPlaced struct {
    BaseEvent
    OrderID    string  `json:"order_id"`
    CustomerID string  `json:"customer_id"`
    Amount     float64 `json:"amount"`
}

func NewOrderPlaced(orderID string, customerID string, amount float64) *OrderPlaced {
    return &OrderPlaced{
        BaseEvent: NewBaseEvent("OrderPlaced", orderID, 1),
        OrderID:   orderID,
        CustomerID: customerID,
        Amount:    amount,
    }
}
```

---

## Event Bus

### In-Memory Event Bus（簡單場景）

```go
package eventbus

import (
    "context"
    "sync"
)

type EventHandler func(ctx context.Context, event DomainEvent) error

type EventBus struct {
    mu       sync.RWMutex
    handlers map[string][]EventHandler
}

func NewEventBus() *EventBus {
    return &EventBus{
        handlers: make(map[string][]EventHandler),
    }
}

// Subscribe 註冊事件處理器
func (eb *EventBus) Subscribe(eventType string, handler EventHandler) {
    eb.mu.Lock()
    defer eb.mu.Unlock()

    eb.handlers[eventType] = append(eb.handlers[eventType], handler)
}

// Publish 發布事件
func (eb *EventBus) Publish(ctx context.Context, event DomainEvent) error {
    eb.mu.RLock()
    handlers := eb.handlers[event.EventType()]
    eb.mu.RUnlock()

    for _, handler := range handlers {
        // 同步處理（簡單場景）
        if err := handler(ctx, event); err != nil {
            return fmt.Errorf("handler failed: %w", err)
        }
    }

    return nil
}
```

### 使用範例

```go
func main() {
    bus := eventbus.NewEventBus()

    // 註冊 Handler
    bus.Subscribe("UserCreated", func(ctx context.Context, event DomainEvent) error {
        e := event.(*UserCreated)
        log.Printf("User created: %s (%s)", e.Name, e.Email)
        return nil
    })

    bus.Subscribe("UserCreated", func(ctx context.Context, event DomainEvent) error {
        e := event.(*UserCreated)
        // 發送歡迎信
        return emailService.SendWelcomeEmail(e.Email)
    })

    // 發布事件
    event := NewUserCreated("123", "john@example.com", "John")
    if err := bus.Publish(context.Background(), event); err != nil {
        log.Fatal(err)
    }
}
```

---

## Outbox Pattern

### 為何需要 Outbox Pattern？

**問題**：資料庫事務與訊息發布不是原子操作
```go
// ❌ 問題：若 Publish 失敗，使用者已建立但事件未發出
tx.Exec("INSERT INTO users ...")
tx.Commit()
eventBus.Publish(userCreatedEvent)  // 可能失敗
```

**解決方案**：將事件寫入資料庫（Outbox Table），再由後台程序發送

### Outbox Table Schema

```sql
CREATE TABLE outbox_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type  VARCHAR(100) NOT NULL,
    aggregate_id VARCHAR(100) NOT NULL,
    payload     JSONB NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    published_at TIMESTAMPTZ,
    retry_count INT DEFAULT 0,
    error       TEXT
);

CREATE INDEX idx_outbox_events_unpublished
ON outbox_events (occurred_at)
WHERE published_at IS NULL;
```

### 寫入 Outbox（Transaction）

```go
func (r *UserRepository) Create(ctx context.Context, tx *sql.Tx, user *User) error {
    // 1. 插入 User
    _, err := tx.ExecContext(ctx, `
        INSERT INTO users (id, email, name) VALUES ($1, $2, $3)
    `, user.ID, user.Email, user.Name)
    if err != nil {
        return fmt.Errorf("insert user: %w", err)
    }

    // 2. 寫入 Outbox Event（同一個 Transaction）
    event := NewUserCreated(user.ID, user.Email, user.Name)
    payload, _ := json.Marshal(event)

    _, err = tx.ExecContext(ctx, `
        INSERT INTO outbox_events (event_type, aggregate_id, payload, occurred_at)
        VALUES ($1, $2, $3, $4)
    `, event.EventType(), event.AggregateID(), payload, event.OccurredAt())
    if err != nil {
        return fmt.Errorf("insert outbox: %w", err)
    }

    return nil
}
```

### Outbox Publisher（Background Worker）

```go
type OutboxPublisher struct {
    db        *sql.DB
    publisher EventPublisher  // 例如 Kafka、RabbitMQ
    logger    *zap.Logger
}

func (op *OutboxPublisher) Run(ctx context.Context) {
    ticker := time.NewTicker(5 * time.Second)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            if err := op.processOutbox(ctx); err != nil {
                op.logger.Error("process outbox failed", zap.Error(err))
            }
        }
    }
}

func (op *OutboxPublisher) processOutbox(ctx context.Context) error {
    // 1. 查詢未發布的事件（限制筆數避免記憶體爆炸）
    rows, err := op.db.QueryContext(ctx, `
        SELECT id, event_type, payload
        FROM outbox_events
        WHERE published_at IS NULL
        ORDER BY occurred_at
        LIMIT 100
        FOR UPDATE SKIP LOCKED
    `)
    if err != nil {
        return fmt.Errorf("query outbox: %w", err)
    }
    defer rows.Close()

    for rows.Next() {
        var id string
        var eventType string
        var payload []byte

        if err := rows.Scan(&id, &eventType, &payload); err != nil {
            return fmt.Errorf("scan row: %w", err)
        }

        // 2. 發布事件到 Message Queue
        if err := op.publisher.Publish(ctx, eventType, payload); err != nil {
            // 更新重試次數與錯誤訊息
            op.db.ExecContext(ctx, `
                UPDATE outbox_events
                SET retry_count = retry_count + 1, error = $1
                WHERE id = $2
            `, err.Error(), id)

            continue
        }

        // 3. 標記為已發布
        _, err := op.db.ExecContext(ctx, `
            UPDATE outbox_events SET published_at = NOW() WHERE id = $1
        `, id)
        if err != nil {
            return fmt.Errorf("update outbox: %w", err)
        }
    }

    return nil
}
```

---

## 冪等性處理

### 為何需要冪等性？

**問題**：同一事件可能被處理多次（網路重試、系統故障）

### 冪等性 Key

```go
// Event 包含冪等性 Key
type UserCreated struct {
    BaseEvent
    Email string `json:"email"`
    Name  string `json:"name"`
}

func (e *UserCreated) IdempotencyKey() string {
    // 使用 EventID 作為冪等性 Key
    return e.EventID()
}
```

### Processed Events Table

```sql
CREATE TABLE processed_events (
    event_id VARCHAR(100) PRIMARY KEY,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_processed_events_processed_at ON processed_events (processed_at);
```

### Handler 實作

```go
func (h *UserEventHandler) Handle(ctx context.Context, event *UserCreated) error {
    // 1. 檢查是否已處理
    var exists bool
    err := h.db.QueryRowContext(ctx, `
        SELECT EXISTS(SELECT 1 FROM processed_events WHERE event_id = $1)
    `, event.EventID()).Scan(&exists)
    if err != nil {
        return fmt.Errorf("check processed: %w", err)
    }

    if exists {
        h.logger.Info("event already processed", zap.String("event_id", event.EventID()))
        return nil  // 冪等：直接返回成功
    }

    // 2. 處理事件
    tx, err := h.db.BeginTx(ctx, nil)
    if err != nil {
        return fmt.Errorf("begin tx: %w", err)
    }
    defer tx.Rollback()

    // 業務邏輯
    if err := h.sendWelcomeEmail(ctx, event.Email); err != nil {
        return fmt.Errorf("send email: %w", err)
    }

    // 3. 記錄為已處理（同一個 Transaction）
    _, err = tx.ExecContext(ctx, `
        INSERT INTO processed_events (event_id) VALUES ($1)
    `, event.EventID())
    if err != nil {
        return fmt.Errorf("insert processed: %w", err)
    }

    return tx.Commit()
}
```

---

## Event Sourcing 基礎

### 概念

**Event Sourcing**：不儲存當前狀態，而是儲存所有歷史事件，透過重播事件重建狀態

### Event Store Schema

```sql
CREATE TABLE event_store (
    sequence_number BIGSERIAL PRIMARY KEY,
    stream_id VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSONB NOT NULL,
    metadata JSONB,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_event_store_stream_id ON event_store (stream_id, sequence_number);
```

### Append Event

```go
func (es *EventStore) Append(ctx context.Context, streamID string, event DomainEvent) error {
    payload, _ := json.Marshal(event)

    _, err := es.db.ExecContext(ctx, `
        INSERT INTO event_store (stream_id, event_type, event_data, occurred_at)
        VALUES ($1, $2, $3, $4)
    `, streamID, event.EventType(), payload, event.OccurredAt())

    return err
}
```

### Replay Events（重建狀態）

```go
func (es *EventStore) Replay(ctx context.Context, streamID string) ([]DomainEvent, error) {
    rows, err := es.db.QueryContext(ctx, `
        SELECT event_type, event_data
        FROM event_store
        WHERE stream_id = $1
        ORDER BY sequence_number
    `, streamID)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var events []DomainEvent
    for rows.Next() {
        var eventType string
        var payload []byte

        if err := rows.Scan(&eventType, &payload); err != nil {
            return nil, err
        }

        // 反序列化事件（需要 Event Registry）
        event, err := deserializeEvent(eventType, payload)
        if err != nil {
            return nil, err
        }

        events = append(events, event)
    }

    return events, nil
}
```

---

## 檢查清單

**事件定義**
- [ ] 事件名稱使用過去式（UserCreated、OrderPlaced）
- [ ] 事件包含 EventID、Timestamp、AggregateID
- [ ] 事件不可變（Immutable）
- [ ] 事件包含業務所需的所有資訊

**Event Bus**
- [ ] 支援多個 Handler 訂閱同一事件
- [ ] Handler 失敗不影響其他 Handler
- [ ] 考慮非同步處理（避免阻塞主流程）
- [ ] 使用 Context 傳遞取消訊號

**Outbox Pattern**
- [ ] 事件與業務操作在同一個 Transaction
- [ ] 使用 `FOR UPDATE SKIP LOCKED` 避免競爭
- [ ] 定期清理已發布的舊事件
- [ ] 監控 Outbox 堆積情況

**冪等性**
- [ ] 事件包含唯一 ID（冪等性 Key）
- [ ] Handler 處理前檢查是否已處理
- [ ] 記錄已處理事件到資料庫
- [ ] 定期清理舊的已處理記錄

**Event Sourcing**
- [ ] 事件為唯一資料來源（Single Source of Truth）
- [ ] 不可刪除或修改事件
- [ ] 支援快照（Snapshot）避免重播太多事件
- [ ] 謹慎設計事件結構（難以變更）

**測試**
- [ ] 測試事件發布與訂閱
- [ ] 測試 Handler 冪等性
- [ ] 測試事件重播邏輯
- [ ] 模擬 Handler 失敗場景
