---
name: go-ddd
description: |
  Go DDD 架構設計規範：領域驅動設計 (Domain-Driven Design)、Bounded Context（限界上下文）、
  Aggregate Root（聚合根）、Repository Pattern、Shared Kernel（共用核心）、依賴注入整合。

  **適用場景**：設計微服務架構、規劃專案目錄結構、實作 DDD 分層、定義領域模型、
  拆分 Bounded Context、設計 Repository 介面。
keywords:
  - ddd
  - domain driven design
  - bounded context
  - aggregate
  - entity
  - value object
  - repository pattern
  - domain layer
  - application layer
  - infrastructure layer
  - delivery layer
  - project structure
  - microservices
  - monolith to microservices
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Go DDD 架構設計規範

> **相關 Skills**：本規範需搭配 `go-dependency-injection` 與 `go-domain-events`

---

## 目錄結構

```bash
.
├── cmd/
│   └── <app>/main.go          # 進入點：只負責載入 configs、初始化 internal/infra (DB/Redis) 並啟動依賴注入
├── api/                       # 對外契約：OpenAPI (Swagger)、Protobuf 定義與產生的程式碼
├── configs/                   # 設定檔：config.yaml, env.example
├── internal/                  # 核心邏輯：外部無法 import
│   ├── <service>/             # 業務服務【Bounded Context】
│   │   ├── domain/            # 領域層：Entity, VO, Repository Interface (純業務，禁 SQL/JSON)
│   │   ├── application/       # 應用層：Use Case 流程編排，依賴 domain interface
│   │   ├── infra/             # 實作層：Repository Impl (SQL/GORM), JWT 實作, 外部 API 呼叫
│   │   ├── delivery/          # 介面層：HTTP Handlers, gRPC Services, DTO 定義
│   │   └── di.go              # 依賴注入 (Google Wire or Fx)
│   ├── infra/                 # 【全域基礎設施】
│   │   ├── database/          # DB 連線池初始化 (MySQL, Postgres)
│   │   ├── cache/             # Redis, Memcached 客戶端
│   │   └── logger/            # 結構化日誌 (Zap/Slog) 配置
│   └── pkg/                   # 【Shared Kernel】跨 Bounded Context 的共用領域抽象（例：Money、DomainError）
│                              # 僅限「跨 Bounded Context 皆成立」的抽象
│                              # 禁止放入特定 service 的規則或流程
├── pkg/                       # 【通用工具】uuid, retry, stringutils (完全不含業務邏輯)
├── migrations/                # Database Migration 檔案（詳見 go-database Skill）
├── scripts/                   # 腳本：DB Migration, Makefile 輔助腳本
├── deployments/               # Kubernetes、Helm Chart 與部署相關檔案
│   ├── helm/                  # Helm charts
│   └── kustomization/         # Kustomize overlays
├── docs/                      # swagger.yaml, 架構設計文件
├── documents/                 # 專案文件
│   ├── en/                    # 專案相關文件（需求規格、設計文件、SOP）
│   └── zh/                    # 專案相關文件（需求規格、設計文件、SOP）
├── test/                      # 整合測試與測試資料 (fixtures) 黑箱 / 整合測試，禁止直接測 domain 私有狀態
├── Dockerfile                 # Multi-stage build
├── Makefile                   # 常用指令 (make wire, make test, make lint)
├── .dockerignore              # Docker build 忽略清單（排除編譯輸出、暫存檔與測試資料）
├── .gitignore                 # Git 忽略清單（node_modules、vendor、log、tmp 等）
├── .golangci.yml              # 靜態分析與 Linter 設定（統一風格與品質門檻）
├── README.md                  # 專案說明：目的、架構、建置步驟、測試與部署指引
├── LICENSE                    # 授權條款；內部專案可標註版權與使用限制
├── go.mod                     # Go 模組定義與依賴版本管理
└── go.sum                     # 依賴模組驗證雜湊清單（確保可重建性）
```

---

## 架構總覽（Architecture Overview）

### 核心原則

本專案採用 **領域驅動設計（Domain-Driven Design, DDD）** 作為核心架構方法，並僅在最外層以 MVC 作為介面實作模式，兩者責任邊界清楚、互不混用。

- 每一項業務能力皆建模為一個獨立的 **限界上下文（Bounded Context）**，並置於 `internal/<service>/` 目錄下
- 業務規則集中於 **領域層（Domain Layer）**，與任何框架或基礎設施實作完全解耦
- **MVC 僅應用於交付層（Delivery Layer）**，用於處理對外介面（HTTP / gRPC）
- 基礎設施相關關注點（資料庫、快取、日誌等）皆透過 **依賴注入（Dependency Injection）** 進行解耦與提供
- MVC 僅作為 Delivery Layer 的實作模式之一，不構成系統核心架構

### 演進路徑

此架構能確保系統具備長期可維護性、可測試性，並可在不破壞核心業務模型的前提下，平順演進自單體架構至微服務架構。

---

## Shared Kernel（共用核心）使用規範

> Shared Kernel 位於 `internal/pkg/`，存放跨 Bounded Context 通用的領域抽象。

### ✅ 適合放入的內容

| 類型 | 範例 |
|------|------|
| Value Objects | `Money`, `Email`, `PhoneNumber`, `Address` |
| Domain Error | `DomainError`, `ValidationError`, `NotFoundError` |
| 通用介面 | `Clock`, `UUIDGenerator`（用於測試注入） |
| 規格抽象 | `Specification<T>` pattern 基底 |

### ❌ 禁止放入的內容

| 類型 | 原因 |
|------|------|
| 特定 BC 的 Entity/Aggregate | 造成 BC 間耦合 |
| 業務流程編排（Use Case） | 違反 BC 邊界獨立性 |
| 框架耦合的實作（如 GORM Model） | 應放 Infra 層 |
| 可變狀態或 Singleton | 難以測試與併行安全 |

### 變更流程

1. 修改 Shared Kernel 需所有**相依 BC 負責人同意**
2. 變更需附**影響範圍分析**（列出受影響的 BC）
3. **向下相容**變更可直接合併；破壞性變更需升版並遷移計畫

### 設計原則

- **最小化**：只放真正跨 BC 通用的抽象
- **不可變**：Value Objects 設計為 immutable
- **無副作用**：Shared Kernel 內的邏輯不應有 I/O 或外部依賴

---

## 分層職責說明

### Domain Layer（領域層）

**位置**：`internal/<service>/domain/`

**職責**：
- 定義 Entity（實體）、Value Object（值物件）、Aggregate Root（聚合根）
- 定義 Repository Interface（輸出埠）
- 包含核心業務邏輯與不變條件（Invariant）
- **完全不依賴**框架、資料庫、HTTP、JSON

**範例**：
```go
// internal/order/domain/order.go
package domain

import "time"

// Order 訂單聚合根
type Order struct {
    id          string
    customerID  string
    items       []OrderItem
    totalAmount Money
    status      OrderStatus
    createdAt   time.Time
}

// PlaceOrder 建立訂單（工廠方法）
func PlaceOrder(customerID string, items []OrderItem) (*Order, error) {
    if len(items) == 0 {
        return nil, ErrEmptyOrder
    }

    order := &Order{
        id:         generateID(),
        customerID: customerID,
        items:      items,
        status:     OrderStatusPending,
        createdAt:  time.Now().UTC(),
    }

    order.calculateTotal()
    return order, nil
}

// Repository 輸出埠（interface 定義在 Domain，實作在 Infra）
type Repository interface {
    Save(ctx context.Context, order *Order) error
    FindByID(ctx context.Context, id string) (*Order, error)
}
```

### Application Layer（應用層）

**位置**：`internal/<service>/application/`

**職責**：
- Use Case 流程編排（呼叫多個 Repository、Domain Service）
- 事務管理（Transaction）
- 對外介面（Input Port）
- 依賴 Domain Interface，不依賴具體實作

**範例**：
```go
// internal/order/application/create_order_usecase.go
package application

type CreateOrderUseCase struct {
    repo domain.Repository
    eventBus EventBus
}

func (uc *CreateOrderUseCase) Execute(ctx context.Context, input CreateOrderInput) error {
    // 1. 建立領域模型
    order, err := domain.PlaceOrder(input.CustomerID, input.Items)
    if err != nil {
        return fmt.Errorf("place order: %w", err)
    }

    // 2. 持久化
    if err := uc.repo.Save(ctx, order); err != nil {
        return fmt.Errorf("save order: %w", err)
    }

    // 3. 發布領域事件
    uc.eventBus.Publish(ctx, OrderCreatedEvent{OrderID: order.ID()})

    return nil
}
```

### Infrastructure Layer（基礎設施層）

**位置**：`internal/<service>/infra/`

**職責**：
- Repository 實作（SQL、GORM、Redis）
- 外部 API 呼叫
- JWT 驗證實作
- Message Queue 發送

**範例**：
```go
// internal/order/infra/order_repository.go
package infra

import (
    "gorm.io/gorm"
    "myapp/internal/order/domain"
)

type OrderRepositoryImpl struct {
    db *gorm.DB
}

func (r *OrderRepositoryImpl) Save(ctx context.Context, order *domain.Order) error {
    // 將領域模型轉為 GORM 模型
    model := toGORMModel(order)
    return r.db.WithContext(ctx).Create(model).Error
}

func (r *OrderRepositoryImpl) FindByID(ctx context.Context, id string) (*domain.Order, error) {
    var model OrderModel
    if err := r.db.WithContext(ctx).First(&model, "id = ?", id).Error; err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, domain.ErrOrderNotFound
        }
        return nil, err
    }
    return toDomainModel(&model), nil
}
```

### Delivery Layer（交付層）

**位置**：`internal/<service>/delivery/`

**職責**：
- HTTP Handlers、gRPC Services
- 請求驗證、DTO 轉換
- 呼叫 Application Layer Use Case

**範例**：
```go
// internal/order/delivery/http/order_handler.go
package http

type OrderHandler struct {
    createOrderUC *application.CreateOrderUseCase
}

// CreateOrder 處理 HTTP 請求
// @Summary 建立訂單
// @Router /orders [post]
func (h *OrderHandler) CreateOrder(c *gin.Context) {
    var req CreateOrderRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }

    input := application.CreateOrderInput{
        CustomerID: req.CustomerID,
        Items:      toUseCaseItems(req.Items),
    }

    if err := h.createOrderUC.Execute(c.Request.Context(), input); err != nil {
        c.JSON(500, gin.H{"error": err.Error()})
        return
    }

    c.JSON(201, gin.H{"message": "order created"})
}
```

---

## Bounded Context 設計準則

### 識別 BC 的標準

1. **獨立的業務能力**：訂單管理、使用者管理、支付處理
2. **不同的語言術語**：Order vs Payment vs Shipment
3. **獨立的團隊擁有權**：不同團隊維護不同 BC
4. **可獨立部署**：未來拆分成微服務時的單位

### BC 之間的通訊

| 通訊方式 | 適用場景 | 實作 |
|----------|----------|------|
| **同步 API 呼叫** | 強一致性需求 | HTTP / gRPC |
| **非同步事件** | 最終一致性可接受 | Message Queue（NATS、Kafka） |
| **Shared Database** | ❌ **禁止** | 造成耦合 |

### 跨 BC 資料訪問

**原則**：每個 BC 擁有自己的資料庫 Schema 或 Table Prefix

**正確做法**：
```go
// ✅ 透過 API 呼叫其他 BC
func (uc *CreateOrderUseCase) Execute(ctx context.Context, input CreateOrderInput) error {
    // 呼叫 User BC 的 API 驗證使用者
    user, err := uc.userClient.GetUser(ctx, input.CustomerID)
    if err != nil {
        return fmt.Errorf("get user: %w", err)
    }

    // ...訂單邏輯
}
```

**錯誤做法**：
```go
// ❌ 直接查詢其他 BC 的資料表
func (r *OrderRepo) GetUserName(ctx context.Context, userID string) (string, error) {
    var name string
    // 錯誤：跨越 BC 邊界直接查詢 users 表
    r.db.Raw("SELECT name FROM users WHERE id = ?", userID).Scan(&name)
    return name, nil
}
```

---

## 檢查清單

**Domain Layer**
- [ ] 無 `import` 任何框架（GORM、Gin、gRPC）
- [ ] 無 JSON/YAML tags
- [ ] Repository 定義為 Interface
- [ ] Entity 方法包含業務邏輯驗證

**Application Layer**
- [ ] Use Case 依賴 Domain Interface
- [ ] 無直接 `import` Infrastructure 實作
- [ ] 事務邊界清晰

**Infrastructure Layer**
- [ ] Repository 實作不洩漏到 Domain
- [ ] GORM Model 與 Domain Entity 分離
- [ ] 錯誤轉換為 Domain Error

**Delivery Layer**
- [ ] HTTP Handler 不直接操作 Domain Entity
- [ ] DTO 與 Domain Model 分離
- [ ] 驗證在此層完成

**Bounded Context**
- [ ] 每個 BC 有獨立的資料庫 Schema/Prefix
- [ ] BC 之間透過 API 或事件通訊
- [ ] 無跨 BC 的直接資料庫查詢
