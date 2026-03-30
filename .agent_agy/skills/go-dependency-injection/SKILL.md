---
name: go-dependency-injection
description: |
  Go 依賴注入模式與工具：Interface 設計、Constructor Pattern、Uber Fx/Wire 使用、
  測試替身模式、生命週期管理、模組化架構。

  **適用場景**：設計可測試的架構、使用 Fx/Wire、實作 Repository Interface、
  Mock 依賴、模組化系統、Lifecycle Hook、測試隔離。
keywords:
  - dependency injection
  - uber fx
  - google wire
  - interface design
  - constructor
  - mock
  - testable code
  - lifecycle
  - module
  - provider
  - invoke
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Go 依賴注入規範

> **相關 Skills**：本規範建議搭配 `go-testing-advanced`（Mocking）與 `go-ddd`（分層架構）

---

## Interface 設計原則

### 為何需要 Interface？

- **測試隔離**：可替換為 Mock 實作
- **解耦**：高層模組不依賴低層實作細節
- **可擴展**：新增實作不影響既有程式碼

### Interface 設計規則

**小而專一**（Interface Segregation Principle）：
```go
// ❌ 錯誤：過於龐大
type UserRepository interface {
    Create(ctx context.Context, user *User) error
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id int64) error
    FindByID(ctx context.Context, id int64) (*User, error)
    FindByEmail(ctx context.Context, email string) (*User, error)
    List(ctx context.Context, limit int) ([]*User, error)
    Count(ctx context.Context) (int, error)
    // ... 更多方法
}

// ✅ 正確：拆分為小 Interface
type UserReader interface {
    FindByID(ctx context.Context, id int64) (*User, error)
    FindByEmail(ctx context.Context, email string) (*User, error)
}

type UserWriter interface {
    Create(ctx context.Context, user *User) error
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id int64) error
}

// 組合使用
type UserRepository interface {
    UserReader
    UserWriter
}
```

**在使用端定義 Interface**（Consumer-Driven）：
```go
// ✅ 在 Service 層定義需要的 Interface
package service

type UserService struct {
    repo userRepository  // 私有 Interface
}

type userRepository interface {
    FindByID(ctx context.Context, id int64) (*User, error)
    Create(ctx context.Context, user *User) error
}

// Repository 實作不需要明確聲明實作哪個 Interface（隱式滿足）
```

---

## Constructor Pattern

### 基本 Constructor

```go
type UserService struct {
    repo   UserRepository
    logger *zap.Logger
}

// NewUserService 建立 UserService 實例
func NewUserService(repo UserRepository, logger *zap.Logger) *UserService {
    return &UserService{
        repo:   repo,
        logger: logger,
    }
}
```

### Functional Options Pattern（可選配置）

```go
type UserService struct {
    repo   UserRepository
    logger *zap.Logger
    cache  Cache
    config Config
}

type UserServiceOption func(*UserService)

func WithCache(cache Cache) UserServiceOption {
    return func(s *UserService) {
        s.cache = cache
    }
}

func WithConfig(config Config) UserServiceOption {
    return func(s *UserService) {
        s.config = config
    }
}

func NewUserService(repo UserRepository, logger *zap.Logger, opts ...UserServiceOption) *UserService {
    s := &UserService{
        repo:   repo,
        logger: logger,
        config: DefaultConfig(),  // 預設值
    }

    for _, opt := range opts {
        opt(s)
    }

    return s
}

// 使用範例
service := NewUserService(
    repo,
    logger,
    WithCache(redisCache),
    WithConfig(customConfig),
)
```

---

## Uber Fx

### 核心概念

- **Provider**：提供依賴（`fx.Provide`）
- **Invoke**：使用依賴（`fx.Invoke`）
- **Lifecycle**：管理啟動/關閉（`fx.Lifecycle`）
- **Module**：組織依賴

### 基本使用

```go
package main

import (
    "context"
    "go.uber.org/fx"
    "go.uber.org/zap"
)

// 提供 Logger
func NewLogger() (*zap.Logger, error) {
    return zap.NewProduction()
}

// 提供 Repository
func NewUserRepository(db *sql.DB) UserRepository {
    return &postgresUserRepository{db: db}
}

// 提供 Service
func NewUserService(repo UserRepository, logger *zap.Logger) *UserService {
    return &UserService{
        repo:   repo,
        logger: logger,
    }
}

// 提供 HTTP Server
func NewHTTPServer(service *UserService, lc fx.Lifecycle) *http.Server {
    mux := http.NewServeMux()
    mux.HandleFunc("/users", service.HandleListUsers)

    srv := &http.Server{
        Addr:    ":8080",
        Handler: mux,
    }

    // 註冊 Lifecycle Hook
    lc.Append(fx.Hook{
        OnStart: func(ctx context.Context) error {
            go srv.ListenAndServe()
            return nil
        },
        OnStop: func(ctx context.Context) error {
            return srv.Shutdown(ctx)
        },
    })

    return srv
}

func main() {
    app := fx.New(
        // Providers
        fx.Provide(
            NewLogger,
            NewDatabase,
            NewUserRepository,
            NewUserService,
            NewHTTPServer,
        ),
    )

    app.Run()
}
```

### Module 模式

```go
package user

import "go.uber.org/fx"

var Module = fx.Options(
    fx.Provide(
        NewUserRepository,
        NewUserService,
        NewUserHandler,
    ),
)
```

```go
package main

import (
    "myapp/user"
    "myapp/auth"
    "go.uber.org/fx"
)

func main() {
    app := fx.New(
        // 共享依賴
        fx.Provide(
            NewLogger,
            NewDatabase,
        ),

        // 業務模組
        user.Module,
        auth.Module,

        // HTTP Server
        fx.Provide(NewHTTPServer),
    )

    app.Run()
}
```

### 進階：Annotated Provider

```go
// 提供多個相同類型但不同名稱的依賴
func NewPrimaryDB() *sql.DB {
    // ...
}

func NewReplicaDB() *sql.DB {
    // ...
}

// 使用 fx.Annotated 區分
func ProvideDatabases() fx.Option {
    return fx.Options(
        fx.Provide(
            fx.Annotate(
                NewPrimaryDB,
                fx.ResultTags(`name:"primary"`),
            ),
        ),
        fx.Provide(
            fx.Annotate(
                NewReplicaDB,
                fx.ResultTags(`name:"replica"`),
            ),
        ),
    )
}

// 注入時指定名稱
type UserRepository struct {
    db *sql.DB `name:"primary"`
}

func NewUserRepository(db *sql.DB) UserRepository {
    // Fx 自動注入 primary DB
}
```

---

## Google Wire

### Code Generation 方式

**Wire 與 Fx 的差異**：
- **Wire**：編譯期生成程式碼（無 Runtime 依賴）
- **Fx**：Runtime 依賴注入（使用 Reflection）

### 基本使用

```go
// wire.go
//go:build wireinject
// +build wireinject

package main

import (
    "github.com/google/wire"
)

func InitializeApp() (*App, error) {
    wire.Build(
        NewLogger,
        NewDatabase,
        NewUserRepository,
        NewUserService,
        NewApp,
    )
    return nil, nil
}
```

### 生成程式碼

```bash
# 安裝 wire
go install github.com/google/wire/cmd/wire@latest

# 生成 wire_gen.go
wire ./...
```

```go
// wire_gen.go (自動生成)
func InitializeApp() (*App, error) {
    logger, err := NewLogger()
    if err != nil {
        return nil, err
    }

    db, err := NewDatabase()
    if err != nil {
        return nil, err
    }

    repo := NewUserRepository(db)
    service := NewUserService(repo, logger)
    app := NewApp(service)

    return app, nil
}
```

### Provider Set

```go
// wire.go
var UserSet = wire.NewSet(
    NewUserRepository,
    NewUserService,
)

var AuthSet = wire.NewSet(
    NewAuthService,
    NewJWTManager,
)

func InitializeApp() (*App, error) {
    wire.Build(
        NewLogger,
        NewDatabase,
        UserSet,
        AuthSet,
        NewApp,
    )
    return nil, nil
}
```

---

## 測試模式

### Mock Interface

```go
// UserRepository Interface
type UserRepository interface {
    FindByID(ctx context.Context, id int64) (*User, error)
}

// Mock 實作（手動）
type MockUserRepository struct {
    FindByIDFunc func(ctx context.Context, id int64) (*User, error)
}

func (m *MockUserRepository) FindByID(ctx context.Context, id int64) (*User, error) {
    if m.FindByIDFunc != nil {
        return m.FindByIDFunc(ctx, id)
    }
    return nil, errors.New("not implemented")
}

// 測試範例
func TestUserService_GetUser(t *testing.T) {
    mockRepo := &MockUserRepository{
        FindByIDFunc: func(ctx context.Context, id int64) (*User, error) {
            if id == 1 {
                return &User{ID: 1, Name: "John"}, nil
            }
            return nil, ErrNotFound
        },
    }

    service := NewUserService(mockRepo, zap.NewNop())

    user, err := service.GetUser(context.Background(), 1)
    assert.NoError(t, err)
    assert.Equal(t, "John", user.Name)
}
```

### 使用 uber-go/mock（推薦）

```bash
# 生成 Mock
mockgen -source=repository.go -destination=mock/repository_mock.go -package=mock
```

```go
func TestUserService_GetUser(t *testing.T) {
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()

    mockRepo := mock.NewMockUserRepository(ctrl)
    mockRepo.EXPECT().
        FindByID(gomock.Any(), int64(1)).
        Return(&User{ID: 1, Name: "John"}, nil)

    service := NewUserService(mockRepo, zap.NewNop())

    user, err := service.GetUser(context.Background(), 1)
    assert.NoError(t, err)
    assert.Equal(t, "John", user.Name)
}
```

---

## 常見錯誤

### 循環依賴

```go
// ❌ 錯誤：A 依賴 B，B 依賴 A
type ServiceA struct {
    b *ServiceB
}

type ServiceB struct {
    a *ServiceA
}
```

**解決方案**：
1. 重新設計架構（通常是設計問題）
2. 引入 Interface 打破循環
3. 使用 Event Bus 解耦

### 過度設計

```go
// ❌ 錯誤：只有一個實作卻建立 Interface
type UserRepository interface {
    FindByID(ctx context.Context, id int64) (*User, error)
}

type postgresUserRepository struct {}  // 唯一實作
```

**原則**：**先寫具體實作，需要時再抽象為 Interface**

---

## 檢查清單

**Interface 設計**
- [ ] Interface 小而專一（1-3 個方法）
- [ ] 在使用端定義 Interface（而非實作端）
- [ ] 使用 Interface 組合而非繼承
- [ ] 避免空 Interface（`interface{}`）

**Constructor**
- [ ] 所有依賴透過 Constructor 注入
- [ ] 避免在 Constructor 中執行邏輯
- [ ] 可選參數使用 Functional Options Pattern
- [ ] 返回具體類型而非 Interface

**Fx 使用**
- [ ] 使用 `fx.Module` 組織依賴
- [ ] Lifecycle Hook 正確處理錯誤
- [ ] OnStop 清理資源（關閉連線、停止 Goroutine）
- [ ] 避免在 Provider 中啟動 Goroutine

**Wire 使用**
- [ ] 定義 Provider Set 重用依賴組合
- [ ] 執行 `wire` 自動生成程式碼
- [ ] 不要手動編輯 `wire_gen.go`
- [ ] 將 `wire.go` 標記為 `//go:build wireinject`

**測試**
- [ ] 使用 Interface 隔離依賴
- [ ] Mock 外部服務（DB、HTTP、第三方 API）
- [ ] 使用 `gomock` 生成 Mock
- [ ] 測試不應依賴真實資料庫

**架構**
- [ ] 依賴方向：Delivery → Application → Domain → Infrastructure
- [ ] 高層模組不依賴低層實作
- [ ] 避免循環依賴
- [ ] 每個模組有明確邊界
