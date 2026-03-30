---
name: go-examples
description: |
  Go 實作範例庫：完整的 HTTP Client、Repository Pattern、Use Case、Handler、
  Service 實作範例，涵蓋常見場景的最佳實務程式碼。

  **適用場景**：參考完整實作範例、學習最佳實務、快速啟動新專案、程式碼審查參考、
  架構設計模板、HTTP、gRPC、Database 整合範例。
keywords:
  - examples
  - code examples
  - http client example
  - repository pattern
  - use case example
  - handler example
  - service example
  - best practices
  - template
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Go 實作範例庫

> **注意**：本 Skill 提供完整的實作範例，展示最佳實務與常見模式

---

## HTTP Client 範例

### 基礎 HTTP Client

```go
package httpclient

import (
    "context"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "time"
)

type Client struct {
    baseURL    string
    httpClient *http.Client
    apiKey     string
}

func NewClient(baseURL string, apiKey string) *Client {
    return &Client{
        baseURL: baseURL,
        apiKey:  apiKey,
        httpClient: &http.Client{
            Timeout: 30 * time.Second,
            Transport: &http.Transport{
                MaxIdleConns:        100,
                MaxIdleConnsPerHost: 10,
                IdleConnTimeout:     90 * time.Second,
            },
        },
    }
}

func (c *Client) GetUser(ctx context.Context, userID string) (*User, error) {
    url := fmt.Sprintf("%s/users/%s", c.baseURL, userID)

    req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
    if err != nil {
        return nil, fmt.Errorf("create request: %w", err)
    }

    req.Header.Set("Authorization", "Bearer "+c.apiKey)
    req.Header.Set("Accept", "application/json")

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, fmt.Errorf("do request: %w", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        body, _ := io.ReadAll(resp.Body)
        return nil, fmt.Errorf("unexpected status %d: %s", resp.StatusCode, string(body))
    }

    var user User
    if err := json.NewDecoder(resp.Body).Decode(&user); err != nil {
        return nil, fmt.Errorf("decode response: %w", err)
    }

    return &user, nil
}

func (c *Client) CreateUser(ctx context.Context, req *CreateUserRequest) (*User, error) {
    url := fmt.Sprintf("%s/users", c.baseURL)

    body, err := json.Marshal(req)
    if err != nil {
        return nil, fmt.Errorf("marshal request: %w", err)
    }

    httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
    if err != nil {
        return nil, fmt.Errorf("create request: %w", err)
    }

    httpReq.Header.Set("Authorization", "Bearer "+c.apiKey)
    httpReq.Header.Set("Content-Type", "application/json")
    httpReq.Header.Set("Accept", "application/json")

    resp, err := c.httpClient.Do(httpReq)
    if err != nil {
        return nil, fmt.Errorf("do request: %w", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusCreated {
        body, _ := io.ReadAll(resp.Body)
        return nil, fmt.Errorf("unexpected status %d: %s", resp.StatusCode, string(body))
    }

    var user User
    if err := json.NewDecoder(resp.Body).Decode(&user); err != nil {
        return nil, fmt.Errorf("decode response: %w", err)
    }

    return &user, nil
}
```

---

## Repository Pattern 範例

### Interface 定義

```go
package repository

import "context"

type UserRepository interface {
    Create(ctx context.Context, user *User) error
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id int64) error
    FindByID(ctx context.Context, id int64) (*User, error)
    FindByEmail(ctx context.Context, email string) (*User, error)
    List(ctx context.Context, filters ListFilters) ([]*User, error)
}
```

### PostgreSQL 實作

```go
package repository

import (
    "context"
    "database/sql"
    "errors"
    "fmt"
    "time"
)

type postgresUserRepository struct {
    db *sql.DB
}

func NewPostgresUserRepository(db *sql.DB) UserRepository {
    return &postgresUserRepository{db: db}
}

func (r *postgresUserRepository) Create(ctx context.Context, user *User) error {
    query := `
        INSERT INTO users (email, name, password_hash, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id
    `

    now := time.Now()
    err := r.db.QueryRowContext(
        ctx, query,
        user.Email, user.Name, user.PasswordHash, now, now,
    ).Scan(&user.ID)

    if err != nil {
        return fmt.Errorf("insert user: %w", err)
    }

    user.CreatedAt = now
    user.UpdatedAt = now

    return nil
}

func (r *postgresUserRepository) FindByID(ctx context.Context, id int64) (*User, error) {
    query := `
        SELECT id, email, name, password_hash, created_at, updated_at
        FROM users
        WHERE id = $1
    `

    var user User
    err := r.db.QueryRowContext(ctx, query, id).Scan(
        &user.ID, &user.Email, &user.Name, &user.PasswordHash,
        &user.CreatedAt, &user.UpdatedAt,
    )

    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrUserNotFound
        }
        return nil, fmt.Errorf("query user: %w", err)
    }

    return &user, nil
}

func (r *postgresUserRepository) FindByEmail(ctx context.Context, email string) (*User, error) {
    query := `
        SELECT id, email, name, password_hash, created_at, updated_at
        FROM users
        WHERE email = $1
    `

    var user User
    err := r.db.QueryRowContext(ctx, query, email).Scan(
        &user.ID, &user.Email, &user.Name, &user.PasswordHash,
        &user.CreatedAt, &user.UpdatedAt,
    )

    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrUserNotFound
        }
        return nil, fmt.Errorf("query user: %w", err)
    }

    return &user, nil
}

func (r *postgresUserRepository) Update(ctx context.Context, user *User) error {
    query := `
        UPDATE users
        SET name = $1, updated_at = $2
        WHERE id = $3
    `

    now := time.Now()
    result, err := r.db.ExecContext(ctx, query, user.Name, now, user.ID)
    if err != nil {
        return fmt.Errorf("update user: %w", err)
    }

    rowsAffected, err := result.RowsAffected()
    if err != nil {
        return fmt.Errorf("get rows affected: %w", err)
    }

    if rowsAffected == 0 {
        return ErrUserNotFound
    }

    user.UpdatedAt = now
    return nil
}

func (r *postgresUserRepository) Delete(ctx context.Context, id int64) error {
    query := `DELETE FROM users WHERE id = $1`

    result, err := r.db.ExecContext(ctx, query, id)
    if err != nil {
        return fmt.Errorf("delete user: %w", err)
    }

    rowsAffected, err := result.RowsAffected()
    if err != nil {
        return fmt.Errorf("get rows affected: %w", err)
    }

    if rowsAffected == 0 {
        return ErrUserNotFound
    }

    return nil
}

func (r *postgresUserRepository) List(ctx context.Context, filters ListFilters) ([]*User, error) {
    query := `
        SELECT id, email, name, password_hash, created_at, updated_at
        FROM users
        WHERE 1=1
    `
    args := []interface{}{}
    argPos := 1

    if filters.Email != "" {
        query += fmt.Sprintf(" AND email LIKE $%d", argPos)
        args = append(args, "%"+filters.Email+"%")
        argPos++
    }

    query += " ORDER BY created_at DESC"

    if filters.Limit > 0 {
        query += fmt.Sprintf(" LIMIT $%d", argPos)
        args = append(args, filters.Limit)
        argPos++
    }

    if filters.Offset > 0 {
        query += fmt.Sprintf(" OFFSET $%d", argPos)
        args = append(args, filters.Offset)
    }

    rows, err := r.db.QueryContext(ctx, query, args...)
    if err != nil {
        return nil, fmt.Errorf("query users: %w", err)
    }
    defer rows.Close()

    var users []*User
    for rows.Next() {
        var user User
        if err := rows.Scan(
            &user.ID, &user.Email, &user.Name, &user.PasswordHash,
            &user.CreatedAt, &user.UpdatedAt,
        ); err != nil {
            return nil, fmt.Errorf("scan user: %w", err)
        }
        users = append(users, &user)
    }

    if err := rows.Err(); err != nil {
        return nil, fmt.Errorf("rows error: %w", err)
    }

    return users, nil
}
```

---

## Use Case 範例

### 建立使用者 Use Case

```go
package usecase

import (
    "context"
    "errors"
    "fmt"
    "go.uber.org/zap"
    "golang.org/x/crypto/bcrypt"
)

type CreateUserUseCase struct {
    userRepo UserRepository
    eventBus EventBus
    logger   *zap.Logger
}

func NewCreateUserUseCase(
    userRepo UserRepository,
    eventBus EventBus,
    logger *zap.Logger,
) *CreateUserUseCase {
    return &CreateUserUseCase{
        userRepo: userRepo,
        eventBus: eventBus,
        logger:   logger,
    }
}

func (uc *CreateUserUseCase) Execute(ctx context.Context, req *CreateUserRequest) (*User, error) {
    // 1. 驗證請求
    if err := req.Validate(); err != nil {
        return nil, fmt.Errorf("validate request: %w", err)
    }

    // 2. 檢查 Email 是否已存在
    existingUser, err := uc.userRepo.FindByEmail(ctx, req.Email)
    if err != nil && !errors.Is(err, ErrUserNotFound) {
        return nil, fmt.Errorf("check existing user: %w", err)
    }

    if existingUser != nil {
        return nil, ErrEmailAlreadyExists
    }

    // 3. Hash 密碼
    passwordHash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
    if err != nil {
        return nil, fmt.Errorf("hash password: %w", err)
    }

    // 4. 建立使用者
    user := &User{
        Email:        req.Email,
        Name:         req.Name,
        PasswordHash: string(passwordHash),
    }

    if err := uc.userRepo.Create(ctx, user); err != nil {
        return nil, fmt.Errorf("create user: %w", err)
    }

    // 5. 發布 Domain Event
    event := NewUserCreated(user.ID, user.Email, user.Name)
    if err := uc.eventBus.Publish(ctx, event); err != nil {
        uc.logger.Error("failed to publish event",
            zap.Error(err),
            zap.Int64("user_id", user.ID),
        )
        // 不要因為事件發布失敗而回滾整個操作
    }

    uc.logger.Info("user created",
        zap.Int64("user_id", user.ID),
        zap.String("email", user.Email),
    )

    return user, nil
}
```

---

## HTTP Handler 範例

### RESTful API Handler

```go
package handler

import (
    "encoding/json"
    "errors"
    "net/http"
    "strconv"
    "go.uber.org/zap"
    "github.com/gorilla/mux"
)

type UserHandler struct {
    createUserUC *CreateUserUseCase
    getUserUC    *GetUserUseCase
    listUsersUC  *ListUsersUseCase
    logger       *zap.Logger
}

func NewUserHandler(
    createUserUC *CreateUserUseCase,
    getUserUC *GetUserUseCase,
    listUsersUC *ListUsersUseCase,
    logger *zap.Logger,
) *UserHandler {
    return &UserHandler{
        createUserUC: createUserUC,
        getUserUC:    getUserUC,
        listUsersUC:  listUsersUC,
        logger:       logger,
    }
}

func (h *UserHandler) RegisterRoutes(r *mux.Router) {
    r.HandleFunc("/users", h.CreateUser).Methods(http.MethodPost)
    r.HandleFunc("/users/{id}", h.GetUser).Methods(http.MethodGet)
    r.HandleFunc("/users", h.ListUsers).Methods(http.MethodGet)
}

func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        h.respondError(w, http.StatusBadRequest, "INVALID_REQUEST", "Invalid JSON", err.Error())
        return
    }

    user, err := h.createUserUC.Execute(r.Context(), &req)
    if err != nil {
        h.handleUseCaseError(w, err)
        return
    }

    h.respondJSON(w, http.StatusCreated, ToUserResponse(user))
}

func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
    vars := mux.Vars(r)
    idStr := vars["id"]

    id, err := strconv.ParseInt(idStr, 10, 64)
    if err != nil {
        h.respondError(w, http.StatusBadRequest, "INVALID_ID", "Invalid user ID", "")
        return
    }

    user, err := h.getUserUC.Execute(r.Context(), id)
    if err != nil {
        h.handleUseCaseError(w, err)
        return
    }

    h.respondJSON(w, http.StatusOK, ToUserResponse(user))
}

func (h *UserHandler) ListUsers(w http.ResponseWriter, r *http.Request) {
    email := r.URL.Query().Get("email")
    limit := parseIntDefault(r.URL.Query().Get("limit"), 20)
    offset := parseIntDefault(r.URL.Query().Get("offset"), 0)

    filters := ListFilters{
        Email:  email,
        Limit:  limit,
        Offset: offset,
    }

    users, err := h.listUsersUC.Execute(r.Context(), filters)
    if err != nil {
        h.handleUseCaseError(w, err)
        return
    }

    response := make([]*UserResponse, len(users))
    for i, user := range users {
        response[i] = ToUserResponse(user)
    }

    h.respondJSON(w, http.StatusOK, response)
}

func (h *UserHandler) handleUseCaseError(w http.ResponseWriter, err error) {
    switch {
    case errors.Is(err, ErrUserNotFound):
        h.respondError(w, http.StatusNotFound, "USER_NOT_FOUND", "User not found", "")
    case errors.Is(err, ErrEmailAlreadyExists):
        h.respondError(w, http.StatusConflict, "EMAIL_EXISTS", "Email already exists", "")
    case errors.Is(err, ErrValidation):
        h.respondError(w, http.StatusBadRequest, "VALIDATION_ERROR", err.Error(), "")
    default:
        h.logger.Error("unexpected error", zap.Error(err))
        h.respondError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "Internal server error", "")
    }
}

func (h *UserHandler) respondJSON(w http.ResponseWriter, status int, data interface{}) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(SuccessResponse{Data: data})
}

func (h *UserHandler) respondError(w http.ResponseWriter, status int, code, message, details string) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(ErrorResponse{
        Error: &APIError{
            Code:    code,
            Message: message,
            Details: details,
        },
    })
}
```

---

## Service 完整範例

### 主程式（main.go）

```go
package main

import (
    "context"
    "database/sql"
    "fmt"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "go.uber.org/zap"
    _ "github.com/lib/pq"
)

func main() {
    // 1. 初始化 Logger
    logger, _ := zap.NewProduction()
    defer logger.Sync()

    // 2. 載入設定
    cfg, err := config.Load()
    if err != nil {
        logger.Fatal("failed to load config", zap.Error(err))
    }

    // 3. 連線資料庫
    db, err := sql.Open("postgres", cfg.Database.DSN())
    if err != nil {
        logger.Fatal("failed to connect database", zap.Error(err))
    }
    defer db.Close()

    if err := db.Ping(); err != nil {
        logger.Fatal("failed to ping database", zap.Error(err))
    }

    // 4. 初始化 Repository
    userRepo := repository.NewPostgresUserRepository(db)

    // 5. 初始化 Event Bus
    eventBus := eventbus.NewEventBus()

    // 6. 初始化 Use Cases
    createUserUC := usecase.NewCreateUserUseCase(userRepo, eventBus, logger)
    getUserUC := usecase.NewGetUserUseCase(userRepo, logger)
    listUsersUC := usecase.NewListUsersUseCase(userRepo, logger)

    // 7. 初始化 Handler
    userHandler := handler.NewUserHandler(createUserUC, getUserUC, listUsersUC, logger)

    // 8. 建立 Router
    router := mux.NewRouter()
    userHandler.RegisterRoutes(router.PathPrefix("/api/v1").Subrouter())

    // 9. 建立 HTTP Server
    srv := &http.Server{
        Addr:         fmt.Sprintf(":%d", cfg.Server.Port),
        Handler:      router,
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
        IdleTimeout:  60 * time.Second,
    }

    // 10. 啟動 Server（Goroutine）
    go func() {
        logger.Info("starting server", zap.Int("port", cfg.Server.Port))
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            logger.Fatal("server failed", zap.Error(err))
        }
    }()

    // 11. 優雅關機
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    logger.Info("shutting down server...")

    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    if err := srv.Shutdown(ctx); err != nil {
        logger.Fatal("server forced to shutdown", zap.Error(err))
    }

    logger.Info("server exited")
}
```

---

## 檢查清單

**HTTP Client**
- [ ] 重用 `http.Client`
- [ ] 設定逾時與 Transport 配置
- [ ] 處理錯誤狀態碼
- [ ] 嚴格 `defer resp.Body.Close()`

**Repository**
- [ ] Interface 定義在 Domain/Use Case 層
- [ ] 實作在 Infrastructure 層
- [ ] 錯誤處理（區分 NotFound 與其他錯誤）
- [ ] 使用 Context 傳遞

**Use Case**
- [ ] 包含業務邏輯驗證
- [ ] 依賴 Repository Interface
- [ ] 記錄日誌（成功與失敗）
- [ ] 發布 Domain Events

**Handler**
- [ ] 統一錯誤處理（`handleUseCaseError`）
- [ ] 使用 JSON Envelope 回應
- [ ] 參數驗證與類型轉換
- [ ] 正確的 HTTP 狀態碼

**Service**
- [ ] 依賴注入（避免全域變數）
- [ ] 優雅關機（Graceful Shutdown）
- [ ] 完整的錯誤處理與日誌
- [ ] 配置外部化（環境變數）
