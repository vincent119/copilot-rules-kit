---
name: go-api-design
description: |
  Go API 設計與版本管理：JSON Envelope、Request/Response 模式、API Versioning、
  Pagination、Filter、Sort、Swagger 文件、棄用通知、HTTP 狀態碼最佳實務。

  **適用場景**：設計 RESTful API、實作 API 版本控制、定義統一回應格式、分頁與篩選、
  撰寫 OpenAPI Spec、棄用 API 版本、錯誤碼定義。
keywords:
  - api design
  - rest api
  - json envelope
  - api versioning
  - pagination
  - swagger
  - openapi
  - deprecation
  - http status code
  - response format
  - api best practices
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Go API 設計與版本管理規範

> **相關 Skills**：本規範建議搭配 `go-core`（錯誤處理）與 `go-observability`（日誌）

---

## JSON Envelope 模式

### 統一回應格式

```go
// 成功回應
type SuccessResponse struct {
    Data interface{} `json:"data"`
    Meta *Meta       `json:"meta,omitempty"`
}

type Meta struct {
    RequestID string `json:"request_id"`
    Timestamp int64  `json:"timestamp"`
}

// 錯誤回應
type ErrorResponse struct {
    Error *APIError `json:"error"`
    Meta  *Meta     `json:"meta,omitempty"`
}

type APIError struct {
    Code    string `json:"code"`             // 業務錯誤碼
    Message string `json:"message"`          // 使用者可讀訊息
    Details string `json:"details,omitempty"` // 詳細錯誤（開發用）
}
```

### 回應範例

```json
// 成功
{
  "data": {
    "id": "123",
    "name": "John"
  },
  "meta": {
    "request_id": "abc-123",
    "timestamp": 1234567890
  }
}

// 錯誤
{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "User with ID 123 not found",
    "details": "查詢資料庫時發現該使用者不存在"
  },
  "meta": {
    "request_id": "abc-123",
    "timestamp": 1234567890
  }
}
```

### 輔助函式

```go
func RespondJSON(w http.ResponseWriter, statusCode int, data interface{}) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(statusCode)

    resp := SuccessResponse{
        Data: data,
        Meta: &Meta{
            RequestID: GetRequestID(r.Context()),
            Timestamp: time.Now().Unix(),
        },
    }

    json.NewEncoder(w).Encode(resp)
}

func RespondError(w http.ResponseWriter, statusCode int, code, message, details string) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(statusCode)

    resp := ErrorResponse{
        Error: &APIError{
            Code:    code,
            Message: message,
            Details: details,
        },
        Meta: &Meta{
            RequestID: GetRequestID(r.Context()),
            Timestamp: time.Now().Unix(),
        },
    }

    json.NewEncoder(w).Encode(resp)
}
```

---

## API 版本管理

### 版本策略

**路徑版本**（推薦）：
```
/api/v1/users
/api/v2/users
```

**Header 版本**（進階）：
```
GET /api/users
Accept: application/vnd.myapp.v2+json
```

### 實作範例

```go
func NewRouter() *mux.Router {
    r := mux.NewRouter()

    // V1 Routes
    v1 := r.PathPrefix("/api/v1").Subrouter()
    v1.HandleFunc("/users", v1.ListUsers).Methods("GET")
    v1.HandleFunc("/users/{id}", v1.GetUser).Methods("GET")

    // V2 Routes
    v2 := r.PathPrefix("/api/v2").Subrouter()
    v2.HandleFunc("/users", v2.ListUsers).Methods("GET")
    v2.HandleFunc("/users/{id}", v2.GetUser).Methods("GET")

    return r
}
```

### 棄用通知

**HTTP Header**：
```go
func DeprecatedMiddleware(deprecatedAt time.Time, sunsetAt time.Time) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            // RFC 8594
            w.Header().Set("Deprecation", deprecatedAt.Format(http.TimeFormat))
            w.Header().Set("Sunset", sunsetAt.Format(http.TimeFormat))
            w.Header().Set("Link", `</api/v2>; rel="successor-version"`)

            next.ServeHTTP(w, r)
        })
    }
}
```

**回應 Body 包含警告**：
```go
type SuccessResponse struct {
    Data     interface{} `json:"data"`
    Meta     *Meta       `json:"meta,omitempty"`
    Warnings []string    `json:"warnings,omitempty"`
}

// 使用範例
resp := SuccessResponse{
    Data: users,
    Warnings: []string{
        "This API version is deprecated. Please migrate to /api/v2 before 2024-12-31",
    },
}
```

---

## Pagination 與篩選

### Cursor-Based Pagination（推薦）

**適用**：大數據集、即時插入/刪除頻繁

```go
type PaginationRequest struct {
    Cursor string `json:"cursor"`
    Limit  int    `json:"limit"`
}

type PaginationResponse struct {
    Items      interface{} `json:"items"`
    NextCursor string      `json:"next_cursor,omitempty"`
    HasMore    bool        `json:"has_more"`
}

func (s *UserService) ListUsers(ctx context.Context, req PaginationRequest) (*PaginationResponse, error) {
    if req.Limit <= 0 || req.Limit > 100 {
        req.Limit = 20
    }

    // 解碼 Cursor（例如：Base64(ID)）
    var lastID int64
    if req.Cursor != "" {
        decoded, _ := base64.StdEncoding.DecodeString(req.Cursor)
        lastID, _ = strconv.ParseInt(string(decoded), 10, 64)
    }

    // 查詢（多拿 1 筆判斷是否有下一頁）
    users, err := s.repo.FindUsers(ctx, lastID, req.Limit+1)
    if err != nil {
        return nil, err
    }

    hasMore := len(users) > req.Limit
    if hasMore {
        users = users[:req.Limit]
    }

    // 產生下一頁 Cursor
    var nextCursor string
    if hasMore {
        lastUser := users[len(users)-1]
        nextCursor = base64.StdEncoding.EncodeToString([]byte(fmt.Sprintf("%d", lastUser.ID)))
    }

    return &PaginationResponse{
        Items:      users,
        NextCursor: nextCursor,
        HasMore:    hasMore,
    }, nil
}
```

### Offset-Based Pagination（簡單場景）

```go
type OffsetPaginationRequest struct {
    Page     int `json:"page"`      // 從 1 開始
    PageSize int `json:"page_size"`
}

type OffsetPaginationResponse struct {
    Items      interface{} `json:"items"`
    TotalCount int         `json:"total_count"`
    Page       int         `json:"page"`
    PageSize   int         `json:"page_size"`
    TotalPages int         `json:"total_pages"`
}
```

### 篩選與排序

```go
type ListUsersRequest struct {
    // Pagination
    Cursor string `json:"cursor"`
    Limit  int    `json:"limit"`

    // Filters
    Status    string `json:"status"`     // e.g., "active", "inactive"
    CreatedAt string `json:"created_at"` // e.g., "2024-01-01..2024-12-31"

    // Sorting
    SortBy    string `json:"sort_by"`    // e.g., "created_at", "name"
    SortOrder string `json:"sort_order"` // "asc" or "desc"
}

func ParseFilters(r *http.Request) (*ListUsersRequest, error) {
    req := &ListUsersRequest{
        Cursor:    r.URL.Query().Get("cursor"),
        Limit:     parseIntDefault(r.URL.Query().Get("limit"), 20),
        Status:    r.URL.Query().Get("status"),
        CreatedAt: r.URL.Query().Get("created_at"),
        SortBy:    r.URL.Query().Get("sort_by"),
        SortOrder: r.URL.Query().Get("sort_order"),
    }

    // Validation
    if req.SortOrder != "" && req.SortOrder != "asc" && req.SortOrder != "desc" {
        return nil, errors.New("invalid sort_order")
    }

    return req, nil
}
```

---

## Swagger / OpenAPI

### Annotation 範例（swaggo/swag）

```go
// ListUsers godoc
// @Summary      列出使用者
// @Description  支援分頁、篩選、排序
// @Tags         users
// @Accept       json
// @Produce      json
// @Param        cursor     query    string  false  "分頁 Cursor"
// @Param        limit      query    int     false  "每頁筆數"  default(20)  maximum(100)
// @Param        status     query    string  false  "狀態篩選"  Enums(active, inactive)
// @Success      200  {object}  PaginationResponse{items=[]User}
// @Failure      400  {object}  ErrorResponse
// @Failure      500  {object}  ErrorResponse
// @Router       /api/v1/users [get]
// @Security     BearerAuth
func (h *UserHandler) ListUsers(w http.ResponseWriter, r *http.Request) {
    // ...
}
```

### 生成文件

```bash
# 安裝 swag
go install github.com/swaggo/swag/cmd/swag@latest

# 生成 docs/
swag init --generalInfo cmd/server/main.go

# 整合 Swagger UI
import _ "myapp/docs"

func main() {
    r := mux.NewRouter()

    // Swagger JSON
    r.PathPrefix("/swagger/").Handler(httpSwagger.WrapHandler)

    http.ListenAndServe(":8080", r)
}
```

---

## HTTP 狀態碼最佳實務

### 常用狀態碼

| 狀態碼 | 意義 | 使用時機 |
|--------|------|----------|
| 200 OK | 成功 | GET、PUT、PATCH 成功 |
| 201 Created | 已建立 | POST 成功建立資源 |
| 204 No Content | 無內容 | DELETE 成功 |
| 400 Bad Request | 請求錯誤 | 參數驗證失敗 |
| 401 Unauthorized | 未授權 | Token 無效或缺少 |
| 403 Forbidden | 禁止存取 | 有權限但不允許操作 |
| 404 Not Found | 找不到 | 資源不存在 |
| 409 Conflict | 衝突 | 資源已存在、樂觀鎖衝突 |
| 422 Unprocessable Entity | 無法處理 | 業務邏輯驗證失敗 |
| 429 Too Many Requests | 請求過多 | Rate Limiting |
| 500 Internal Server Error | 伺服器錯誤 | 未預期的錯誤 |
| 503 Service Unavailable | 服務不可用 | 維護中、依賴服務失敗 |

### 錯誤碼設計

```go
// 錯誤碼常數
const (
    // 4xx Client Errors
    ErrCodeValidation          = "VALIDATION_ERROR"
    ErrCodeUnauthorized        = "UNAUTHORIZED"
    ErrCodeForbidden           = "FORBIDDEN"
    ErrCodeNotFound            = "NOT_FOUND"
    ErrCodeConflict            = "CONFLICT"
    ErrCodeRateLimitExceeded   = "RATE_LIMIT_EXCEEDED"

    // 5xx Server Errors
    ErrCodeInternal            = "INTERNAL_ERROR"
    ErrCodeDatabaseUnavailable = "DATABASE_UNAVAILABLE"
    ErrCodeExternalService     = "EXTERNAL_SERVICE_ERROR"
)

// 自動映射 HTTP 狀態碼
func MapErrorToHTTPStatus(code string) int {
    switch code {
    case ErrCodeValidation:
        return http.StatusBadRequest
    case ErrCodeUnauthorized:
        return http.StatusUnauthorized
    case ErrCodeForbidden:
        return http.StatusForbidden
    case ErrCodeNotFound:
        return http.StatusNotFound
    case ErrCodeConflict:
        return http.StatusConflict
    case ErrCodeRateLimitExceeded:
        return http.StatusTooManyRequests
    default:
        return http.StatusInternalServerError
    }
}
```

---

## Request/Response 模型

### DTO 設計原則

- **Input DTO**：用於接收請求、驗證
- **Output DTO**：用於回應、可包含計算欄位
- **Domain Model**：不應直接暴露

### 範例

```go
// Input DTO
type CreateUserRequest struct {
    Email    string `json:"email" validate:"required,email"`
    Name     string `json:"name" validate:"required,min=2,max=50"`
    Password string `json:"password" validate:"required,min=8"`
}

// Output DTO
type UserResponse struct {
    ID        string    `json:"id"`
    Email     string    `json:"email"`
    Name      string    `json:"name"`
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
    // 不包含密碼！
}

// Domain Model
type User struct {
    ID           int64
    Email        string
    Name         string
    PasswordHash string  // 不應返回給前端
    CreatedAt    time.Time
    UpdatedAt    time.Time
}

// 轉換函式
func ToUserResponse(user *User) *UserResponse {
    return &UserResponse{
        ID:        strconv.FormatInt(user.ID, 10),
        Email:     user.Email,
        Name:      user.Name,
        CreatedAt: user.CreatedAt,
        UpdatedAt: user.UpdatedAt,
    }
}
```

---

## Rate Limiting

### Token Bucket 實作

```go
import "golang.org/x/time/rate"

type RateLimiter struct {
    limiter *rate.Limiter
}

func NewRateLimiter(requestsPerSecond int) *RateLimiter {
    return &RateLimiter{
        limiter: rate.NewLimiter(rate.Limit(requestsPerSecond), requestsPerSecond),
    }
}

func (rl *RateLimiter) Middleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        if !rl.limiter.Allow() {
            RespondError(w, http.StatusTooManyRequests,
                ErrCodeRateLimitExceeded,
                "Rate limit exceeded",
                "請稍後再試",
            )
            return
        }

        next.ServeHTTP(w, r)
    })
}
```

---

## 檢查清單

**回應格式**
- [ ] 使用統一的 JSON Envelope（`data` / `error`）
- [ ] 包含 `meta`（request_id、timestamp）
- [ ] 錯誤回應包含業務錯誤碼（`code`）
- [ ] 訊息友善、可本地化

**版本管理**
- [ ] 使用路徑版本（`/api/v1`、`/api/v2`）
- [ ] 主版本號僅在 Breaking Changes 時遞增
- [ ] 提供棄用通知（`Deprecation` Header）
- [ ] 文件說明遷移路徑

**分頁與篩選**
- [ ] 大數據集使用 Cursor-Based Pagination
- [ ] Limit 設定上限（例如 100）
- [ ] 支援排序（`sort_by`、`sort_order`）
- [ ] 篩選參數驗證

**API 文件**
- [ ] 使用 Swagger/OpenAPI 3.0
- [ ] 每個 Endpoint 註解（Summary、Description、Tags）
- [ ] 包含請求/回應範例
- [ ] 文件與程式碼同步

**HTTP 狀態碼**
- [ ] 201 用於 POST 建立資源
- [ ] 204 用於 DELETE 成功
- [ ] 4xx 用於客戶端錯誤
- [ ] 5xx 用於伺服器錯誤
- [ ] 避免濫用 200 OK

**安全性**
- [ ] 敏感欄位不返回（密碼、Token）
- [ ] 使用 HTTPS
- [ ] 實作 Rate Limiting
- [ ] CORS 配置正確
