---
name: go-testing-advanced
description: |
  Go 進階測試策略：Table-driven tests 進階模式、Mocking 策略（uber-go/mock）、
  整合測試設計、Benchmark 與 Fuzz testing、測試覆蓋率要求、測試金字塔原則。

  **適用場景**：撰寫單元測試、設計 Mock、實作整合測試、效能測試（Benchmark）、
  模糊測試（Fuzz）、提升測試覆蓋率、測試 Repository/Use Case。
keywords:
  - testing
  - unit test
  - integration test
  - mock
  - gomock
  - uber-go/mock
  - mockery
  - table driven test
  - benchmark
  - fuzz testing
  - test coverage
  - testify
  - test fixtures
  - test doubles
  - test pyramid
  - t.Helper
  - t.Cleanup
  - t.Context
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Go 進階測試策略

> **相關 Skills**：本規範建議搭配 `go-dependency-injection`（測試 DI 容器配置）

---

## Table-Driven Tests 進階模式

### 基礎模式

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {name: "positive numbers", a: 2, b: 3, expected: 5},
        {name: "negative numbers", a: -1, b: -2, expected: -3},
        {name: "zero", a: 0, b: 0, expected: 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

### 進階模式：測試錯誤情境

```go
func TestProcessData(t *testing.T) {
    tests := []struct {
        name      string
        input     []byte
        wantErr   bool
        errTarget error  // 使用 errors.Is 檢查
    }{
        {
            name:      "valid data",
            input:     []byte(`{"key":"value"}`),
            wantErr:   false,
        },
        {
            name:      "invalid json",
            input:     []byte(`{invalid}`),
            wantErr:   true,
            errTarget: ErrInvalidJSON,
        },
        {
            name:      "empty data",
            input:     nil,
            wantErr:   true,
            errTarget: ErrEmptyData,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ProcessData(tt.input)

            if tt.wantErr {
                if err == nil {
                    t.Fatal("expected error, got nil")
                }
                if tt.errTarget != nil && !errors.Is(err, tt.errTarget) {
                    t.Errorf("expected error %v, got %v", tt.errTarget, err)
                }
            } else {
                if err != nil {
                    t.Errorf("unexpected error: %v", err)
                }
            }
        })
    }
}
```

### 使用 t.Helper() 簡化斷言

```go
// 測試輔助函式
func assertNoError(t *testing.T, err error) {
    t.Helper()  // 標記為輔助函式，錯誤會指向呼叫者行號
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
}

func assertEqual(t *testing.T, got, want interface{}) {
    t.Helper()
    if got != want {
        t.Errorf("got %v, want %v", got, want)
    }
}

// 使用範例
func TestMyFunction(t *testing.T) {
    result, err := MyFunction()
    assertNoError(t, err)
    assertEqual(t, result, "expected")
}
```

---

## Mocking 策略（uber-go/mock）

### 安裝與配置

```bash
# 安裝 uber-go/mock（原 gomock）
go install go.uber.org/mock/mockgen@latest

# 或使用 mockery
go install github.com/vektra/mockery/v2@latest
```

### Interface 設計原則

**原則**：
- Repository / Service 皆以 **interface** 暴露；實作為 private struct
- Interface 定義於 Domain 或 Application 層，實作於 Infra 層

**範例**：
```go
// internal/order/domain/repository.go
package domain

//go:generate mockgen -source=repository.go -destination=../../mocks/order_repository_mock.go -package=mocks
type Repository interface {
    Save(ctx context.Context, order *Order) error
    FindByID(ctx context.Context, id string) (*Order, error)
}
```

### 產生 Mock

```bash
# 在專案根目錄執行
go generate ./...

# 或手動產生
mockgen -source=internal/order/domain/repository.go \
        -destination=internal/mocks/order_repository_mock.go \
        -package=mocks
```

**目錄結構**：
```
internal/
├── order/
│   └── domain/
│       └── repository.go
└── mocks/
    └── order_repository_mock.go  # 統一放置 Mock
```

### 使用 Mock 撰寫單元測試

```go
// internal/order/application/create_order_usecase_test.go
package application_test

import (
    "context"
    "testing"

    "go.uber.org/mock/gomock"
    "myapp/internal/mocks"
    "myapp/internal/order/application"
    "myapp/internal/order/domain"
)

func TestCreateOrderUseCase_Execute(t *testing.T) {
    tests := []struct {
        name    string
        setup   func(*mocks.MockRepository)
        input   application.CreateOrderInput
        wantErr bool
    }{
        {
            name: "success",
            setup: func(m *mocks.MockRepository) {
                // 設定 Mock 預期行為
                m.EXPECT().
                    Save(gomock.Any(), gomock.Any()).
                    Return(nil).
                    Times(1)
            },
            input: application.CreateOrderInput{
                CustomerID: "cust-123",
                Items:      []domain.OrderItem{{ProductID: "prod-1", Quantity: 2}},
            },
            wantErr: false,
        },
        {
            name: "repository error",
            setup: func(m *mocks.MockRepository) {
                m.EXPECT().
                    Save(gomock.Any(), gomock.Any()).
                    Return(domain.ErrDatabaseError).
                    Times(1)
            },
            input: application.CreateOrderInput{
                CustomerID: "cust-123",
                Items:      []domain.OrderItem{{ProductID: "prod-1", Quantity: 2}},
            },
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Arrange
            ctrl := gomock.NewController(t)
            defer ctrl.Finish()

            mockRepo := mocks.NewMockRepository(ctrl)
            tt.setup(mockRepo)

            uc := application.NewCreateOrderUseCase(mockRepo)

            // Act
            err := uc.Execute(t.Context(), tt.input)  // Go 1.24+ 使用 t.Context()

            // Assert
            if (err != nil) != tt.wantErr {
                t.Errorf("Execute() error = %v, wantErr %v", err, tt.wantErr)
            }
        })
    }
}
```

### 進階 Mock 技巧

#### 1. 驗證參數內容

```go
m.EXPECT().
    Save(gomock.Any(), gomock.Cond(func(x interface{}) bool {
        order, ok := x.(*domain.Order)
        return ok && order.CustomerID == "expected-id"
    })).
    Return(nil)
```

#### 2. 模擬多次呼叫

```go
m.EXPECT().FindByID(gomock.Any(), "id-1").Return(&domain.Order{}, nil)
m.EXPECT().FindByID(gomock.Any(), "id-2").Return(nil, domain.ErrNotFound)
```

#### 3. 使用 gomock.InOrder 保證順序

```go
gomock.InOrder(
    m.EXPECT().Save(gomock.Any(), gomock.Any()).Return(nil),
    m.EXPECT().FindByID(gomock.Any(), "id").Return(&domain.Order{}, nil),
)
```

---

## 整合測試設計

### 測試金字塔原則

```
    ╱╲
   ╱  ╲  E2E Tests (10%)
  ╱────╲
 ╱      ╲  Integration Tests (30%)
╱────────╲
╱          ╲  Unit Tests (60%)
────────────
```

### 整合測試範例（使用真實 DB）

```go
// internal/order/infra/order_repository_integration_test.go
// +build integration

package infra_test

import (
    "context"
    "testing"

    "github.com/testcontainers/testcontainers-go"
    "github.com/testcontainers/testcontainers-go/wait"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
)

func setupTestDB(t *testing.T) *gorm.DB {
    t.Helper()

    // 使用 testcontainers 啟動 PostgreSQL
    ctx := context.Background()
    req := testcontainers.ContainerRequest{
        Image:        "postgres:15-alpine",
        ExposedPorts: []string{"5432/tcp"},
        Env: map[string]string{
            "POSTGRES_PASSWORD": "test",
            "POSTGRES_DB":       "testdb",
        },
        WaitingFor: wait.ForListeningPort("5432/tcp"),
    }

    container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: req,
        Started:          true,
    })
    if err != nil {
        t.Fatalf("failed to start container: %v", err)
    }

    t.Cleanup(func() {
        _ = container.Terminate(ctx)
    })

    // 取得連線資訊
    host, _ := container.Host(ctx)
    port, _ := container.MappedPort(ctx, "5432")

    dsn := fmt.Sprintf("host=%s port=%s user=postgres password=test dbname=testdb sslmode=disable",
        host, port.Port())

    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        t.Fatalf("failed to connect db: %v", err)
    }

    // 執行 Migration
    _ = db.AutoMigrate(&OrderModel{})

    return db
}

func TestOrderRepository_Integration(t *testing.T) {
    db := setupTestDB(t)
    repo := infra.NewOrderRepository(db)

    t.Run("save and find", func(t *testing.T) {
        ctx := context.Background()
        order := domain.NewOrder("cust-123", []domain.OrderItem{})

        // Save
        err := repo.Save(ctx, order)
        if err != nil {
            t.Fatalf("Save() error: %v", err)
        }

        // Find
        found, err := repo.FindByID(ctx, order.ID())
        if err != nil {
            t.Fatalf("FindByID() error: %v", err)
        }

        if found.ID() != order.ID() {
            t.Errorf("ID mismatch: got %s, want %s", found.ID(), order.ID())
        }
    })
}
```

### 執行整合測試

```bash
# 僅執行整合測試
go test -tags=integration ./...

# 排除整合測試（預設）
go test ./...
```

---

## Benchmark（效能測試）

### 基礎 Benchmark

```go
func BenchmarkProcessData(b *testing.B) {
    data := generateTestData()

    // 重置計時器（排除準備時間）
    b.ResetTimer()

    for i := 0; i < b.N; i++ {
        ProcessData(data)
    }
}
```

### 並行 Benchmark

```go
func BenchmarkProcessDataParallel(b *testing.B) {
    data := generateTestData()

    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            ProcessData(data)
        }
    })
}
```

### 報告記憶體分配

```go
func BenchmarkEncodeJSON(b *testing.B) {
    obj := &MyStruct{Field: "value"}

    b.ReportAllocs()  // 報告記憶體分配
    b.ResetTimer()

    for i := 0; i < b.N; i++ {
        _, _ = json.Marshal(obj)
    }
}
```

### 執行 Benchmark

```bash
# 執行所有 Benchmark
go test -bench=. -benchmem ./...

# 執行特定 Benchmark
go test -bench=BenchmarkProcessData -benchmem

# 比較兩次結果
go test -bench=. -benchmem > old.txt
# ...程式碼修改...
go test -bench=. -benchmem > new.txt
benchstat old.txt new.txt
```

---

## Fuzz Testing（模糊測試）

### 基礎 Fuzz Test（Go 1.18+）

```go
func FuzzParseInput(f *testing.F) {
    // Seed corpus（種子資料）
    f.Add("valid input")
    f.Add("123")
    f.Add("")

    f.Fuzz(func(t *testing.T, input string) {
        // 測試不應 panic
        result, err := ParseInput(input)

        // 驗證錯誤處理
        if err != nil {
            // 錯誤是預期的，但不應 panic
            return
        }

        // 驗證結果屬性
        if len(result) > 0 && result[0] == 0 {
            t.Errorf("unexpected zero value in result")
        }
    })
}
```

### 執行 Fuzz Test

```bash
# 執行 Fuzz Test（預設 1 分鐘）
go test -fuzz=FuzzParseInput

# 指定執行時間
go test -fuzz=FuzzParseInput -fuzztime=10m

# Fuzz 發現的問題會存入 testdata/fuzz/
```

---

## 測試覆蓋率

### 產生覆蓋率報告

```bash
# 產生覆蓋率檔案
go test -coverprofile=coverage.out ./...

# 查看總覆蓋率
go tool cover -func=coverage.out

# 產生 HTML 報告
go tool cover -html=coverage.out -o coverage.html
```

### 覆蓋率要求

- **單元測試覆蓋率**：≥ 80%（可透過 PR 調整）
- **核心業務邏輯**：≥ 90%
- **整合測試**：涵蓋關鍵路徑與錯誤情境

### CI 整合

```yaml
# .github/workflows/test.yml
- name: Run tests with coverage
  run: |
    go test -race -coverprofile=coverage.out -covermode=atomic ./...
    go tool cover -func=coverage.out | grep total | awk '{print $3}' | sed 's/%//' | \
      awk '{if ($1 < 80) exit 1}'
```

---

## 檢查清單

**單元測試**
- [ ] 使用 table-driven tests
- [ ] 使用 `t.Run` 建立子測試
- [ ] 使用 `t.Helper()` 標記輔助函式
- [ ] 使用 `t.Cleanup()` 清理資源
- [ ] 使用 `t.Context()` 獲取 context（Go 1.24+）
- [ ] Mock 統一放置於 `internal/mocks/`
- [ ] 使用 `go generate` 自動產生 Mock

**整合測試**
- [ ] 使用 build tags（`// +build integration`）
- [ ] 使用 testcontainers 或測試資料庫
- [ ] 測試真實的 DB/Cache 互動
- [ ] 執行 Migration 初始化 Schema

**Benchmark**
- [ ] 使用 `b.ResetTimer()` 排除準備時間
- [ ] 使用 `b.ReportAllocs()` 報告記憶體
- [ ] 關鍵路徑提供 Benchmark

**Fuzz Testing**
- [ ] 輸入解析函式提供 Fuzz Test
- [ ] 驗證不會 panic
- [ ] 種子資料涵蓋邊界情況

**覆蓋率**
- [ ] 單元測試覆蓋率 ≥ 80%
- [ ] CI 自動檢查覆蓋率門檻
- [ ] 核心業務邏輯覆蓋率 ≥ 90%
