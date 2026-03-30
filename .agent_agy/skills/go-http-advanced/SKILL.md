---
name: go-http-advanced
description: |
  Go HTTP 進階實作：Transport 重用與配置、重試策略與指數退避、Body 重播機制、
  Multipart 上傳、逾時控制、HTTP Client 最佳實務、Context 傳遞。

  **適用場景**：實作 HTTP Client、設計重試策略、處理 Body 重播、Multipart 檔案上傳、
  配置 Connection Pool、逾時管理、Context 取消、HTTP Middleware。
keywords:
  - http client
  - http transport
  - retry
  - backoff
  - connection pool
  - timeout
  - context
  - multipart upload
  - body replay
  - middleware
  - http.Client
  - httpdo
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Go HTTP 進階實作規範

> **相關 Skills**：本規範建議搭配 `go-observability`（Tracing）與 `go-graceful-shutdown`

---

## Transport 重用與配置

### 核心原則

- **重用 Transport**：避免每次請求都建立新的 `http.Client`
- **設定逾時**：Connection、TLS Handshake、Response Header
- **Connection Pool 管理**：MaxIdleConns、IdleConnTimeout

### 標準配置

```go
import (
    "net/http"
    "time"
)

// 建立可重用的 HTTP Client
func NewHTTPClient() *http.Client {
    transport := &http.Transport{
        // Connection Pool 配置
        MaxIdleConns:        100,              // 總最大空閒連線數
        MaxIdleConnsPerHost: 10,               // 每個 Host 最大空閒連線數
        IdleConnTimeout:     90 * time.Second, // 空閒連線保持時間

        // 連線逾時
        DialContext: (&net.Dialer{
            Timeout:   5 * time.Second,  // TCP 連線逾時
            KeepAlive: 30 * time.Second, // Keep-Alive 探測間隔
        }).DialContext,

        // TLS 配置
        TLSHandshakeTimeout:   10 * time.Second,
        ExpectContinueTimeout: 1 * time.Second,

        // HTTP/2 支援
        ForceAttemptHTTP2: true,
    }

    return &http.Client{
        Transport: transport,
        Timeout:   30 * time.Second,  // 全域請求逾時（包含讀取 Body）
    }
}
```

### Client 封裝範例

```go
type APIClient struct {
    baseURL    string
    httpClient *http.Client
    headers    map[string]string  // 預設 Headers
}

func NewAPIClient(baseURL string, httpClient *http.Client) *APIClient {
    if httpClient == nil {
        httpClient = NewHTTPClient()
    }

    return &APIClient{
        baseURL:    strings.TrimSuffix(baseURL, "/"),
        httpClient: httpClient,
        headers: map[string]string{
            "User-Agent": "myapp/1.0",
        },
    }
}

func (c *APIClient) Get(ctx context.Context, path string) (*http.Response, error) {
    req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+path, nil)
    if err != nil {
        return nil, fmt.Errorf("new request: %w", err)
    }

    // 加入預設 Headers
    for k, v := range c.headers {
        req.Header.Set(k, v)
    }

    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, fmt.Errorf("do request: %w", err)
    }

    return resp, nil
}
```

---

## 重試策略與指數退避

### 可重試的錯誤

**原則**：
- **冪等方法**（GET、PUT、DELETE）可重試
- **非冪等方法**（POST）謹慎重試（需確保冪等性）
- 對 5xx/網路錯誤重試，對業務 4xx 不重試

### 重試判斷邏輯

```go
func isRetryable(err error, resp *http.Response) bool {
    // 網路錯誤：可重試
    if err != nil {
        // Timeout、DNS、Connection refused 等
        return true
    }

    // HTTP 狀態碼判斷
    switch resp.StatusCode {
    case http.StatusTooManyRequests:      // 429
        return true
    case http.StatusInternalServerError:   // 500
        return true
    case http.StatusBadGateway:            // 502
        return true
    case http.StatusServiceUnavailable:    // 503
        return true
    case http.StatusGatewayTimeout:        // 504
        return true
    default:
        return false
    }
}
```

### 指數退避實作

```go
type RetryConfig struct {
    MaxRetries int
    InitialBackoff time.Duration
    MaxBackoff time.Duration
    Multiplier float64
}

func DefaultRetryConfig() RetryConfig {
    return RetryConfig{
        MaxRetries:     3,
        InitialBackoff: 100 * time.Millisecond,
        MaxBackoff:     5 * time.Second,
        Multiplier:     2.0,
    }
}

func (c *APIClient) DoWithRetry(ctx context.Context, req *http.Request, cfg RetryConfig) (*http.Response, error) {
    backoff := cfg.InitialBackoff

    for attempt := 0; attempt <= cfg.MaxRetries; attempt++ {
        // Clone Request（因為 Body 只能讀一次）
        reqClone := req.Clone(ctx)

        resp, err := c.httpClient.Do(reqClone)

        // 成功或不可重試：直接返回
        if !isRetryable(err, resp) {
            return resp, err
        }

        // 已達最大重試次數
        if attempt == cfg.MaxRetries {
            if resp != nil {
                return resp, fmt.Errorf("max retries exceeded, last status: %d", resp.StatusCode)
            }
            return nil, fmt.Errorf("max retries exceeded: %w", err)
        }

        // 關閉 Response Body（避免連線洩漏）
        if resp != nil {
            io.Copy(io.Discard, resp.Body)
            resp.Body.Close()
        }

        // Exponential Backoff
        select {
        case <-time.After(backoff):
            backoff = time.Duration(float64(backoff) * cfg.Multiplier)
            if backoff > cfg.MaxBackoff {
                backoff = cfg.MaxBackoff
            }
        case <-ctx.Done():
            return nil, ctx.Err()
        }
    }

    return nil, fmt.Errorf("unexpected retry loop exit")
}
```

---

## Body 重播機制

### 問題：Body 只能讀一次

```go
// ❌ 錯誤：Body 已被讀取，無法重試
req, _ := http.NewRequest("POST", url, body)
resp, err := client.Do(req)
// 若重試，body 已為空
```

### 解決方案：Clone Body

```go
func CloneBody(src []byte) io.ReadCloser {
    buf := bytes.Clone(src)
    return io.NopCloser(bytes.NewReader(buf))
}

// 可重播的 Request
func NewReplayableRequest(ctx context.Context, method, url string, body []byte) (*http.Request, error) {
    req, err := http.NewRequestWithContext(ctx, method, url, CloneBody(body))
    if err != nil {
        return nil, err
    }

    // 設定 GetBody（支持 Redirect 與重試）
    req.GetBody = func() (io.ReadCloser, error) {
        return CloneBody(body), nil
    }

    return req, nil
}
```

---

## Multipart 上傳

### 檔案上傳範例

```go
func UploadFile(ctx context.Context, url string, filePath string) error {
    // 1. 建立 Multipart Writer
    body := &bytes.Buffer{}
    writer := multipart.NewWriter(body)

    // 2. 新增檔案欄位
    file, err := os.Open(filePath)
    if err != nil {
        return fmt.Errorf("open file: %w", err)
    }
    defer file.Close()

    part, err := writer.CreateFormFile("file", filepath.Base(filePath))
    if err != nil {
        return fmt.Errorf("create form file: %w", err)
    }

    if _, err := io.Copy(part, file); err != nil {
        return fmt.Errorf("copy file: %w", err)
    }

    // 3. 新增其他欄位
    _ = writer.WriteField("description", "my file")

    // 4. 關閉 Writer（必要）
    if err := writer.Close(); err != nil {
        return fmt.Errorf("close writer: %w", err)
    }

    // 5. 建立 Request
    req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, body)
    if err != nil {
        return fmt.Errorf("new request: %w", err)
    }

    // 設定 Content-Type（包含 boundary）
    req.Header.Set("Content-Type", writer.FormDataContentType())

    // 6. 發送請求
    client := &http.Client{}
    resp, err := client.Do(req)
    if err != nil {
        return fmt.Errorf("do request: %w", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        body, _ := io.ReadAll(resp.Body)
        return fmt.Errorf("upload failed: %d %s", resp.StatusCode, string(body))
    }

    return nil
}
```

### 串流上傳（大檔案）

```go
func UploadLargeFile(ctx context.Context, url string, filePath string) error {
    file, err := os.Open(filePath)
    if err != nil {
        return fmt.Errorf("open file: %w", err)
    }
    defer file.Close()

    // 使用 io.Pipe 避免載入整個檔案到記憶體
    pr, pw := io.Pipe()
    writer := multipart.NewWriter(pw)

    // Goroutine 寫入 Pipe
    go func() {
        defer pw.Close()
        defer writer.Close()

        part, err := writer.CreateFormFile("file", filepath.Base(filePath))
        if err != nil {
            pw.CloseWithError(fmt.Errorf("create form file: %w", err))
            return
        }

        if _, err := io.Copy(part, file); err != nil {
            pw.CloseWithError(fmt.Errorf("copy file: %w", err))
            return
        }

        // 必須先關閉 writer，再關閉 pw
        if err := writer.Close(); err != nil {
            pw.CloseWithError(err)
        }
    }()

    // 建立 Request（使用 Pipe Reader）
    req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, pr)
    if err != nil {
        return fmt.Errorf("new request: %w", err)
    }

    req.Header.Set("Content-Type", writer.FormDataContentType())

    client := &http.Client{}
    resp, err := client.Do(req)
    if err != nil {
        return fmt.Errorf("do request: %w", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        return fmt.Errorf("upload failed: %d", resp.StatusCode)
    }

    return nil
}
```

---

## 逾時控制

### 多層逾時管理

```go
// 1. Transport 層逾時（Connection、TLS）
transport := &http.Transport{
    DialContext: (&net.Dialer{
        Timeout: 5 * time.Second,  // TCP 連線逾時
    }).DialContext,
    TLSHandshakeTimeout: 10 * time.Second,
}

// 2. Client 層逾時（整個請求，包含讀取 Body）
client := &http.Client{
    Transport: transport,
    Timeout:   30 * time.Second,
}

// 3. Request 層逾時（Context）
ctx, cancel := context.WithTimeout(context.Background(), 10 * time.Second)
defer cancel()

req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)
resp, err := client.Do(req)
```

### 優先級

**Context Timeout（最高優先級）> Client Timeout > Transport Timeout**

---

## HTTP Middleware

### Middleware 模式

```go
type Middleware func(http.Handler) http.Handler

// Logging Middleware
func LoggingMiddleware(logger *zap.Logger) Middleware {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()

            // Wrap ResponseWriter
            rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

            next.ServeHTTP(rw, r)

            logger.Info("http request",
                zap.String("method", r.Method),
                zap.String("path", r.URL.Path),
                zap.Int("status", rw.statusCode),
                zap.Duration("duration", time.Since(start)),
            )
        })
    }
}

type responseWriter struct {
    http.ResponseWriter
    statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
    rw.statusCode = code
    rw.ResponseWriter.WriteHeader(code)
}

// 組合 Middleware
func Chain(h http.Handler, middlewares ...Middleware) http.Handler {
    for i := len(middlewares) - 1; i >= 0; i-- {
        h = middlewares[i](h)
    }
    return h
}

// 使用範例
func main() {
    mux := http.NewServeMux()
    mux.HandleFunc("/", homeHandler)

    handler := Chain(mux,
        LoggingMiddleware(logger),
        MetricsMiddleware(),
        AuthMiddleware(),
    )

    http.ListenAndServe(":8080", handler)
}
```

---

## 檢查清單

**HTTP Client**
- [ ] 重用 `http.Client` 與 `http.Transport`
- [ ] 配置 Connection Pool（MaxIdleConns、IdleConnTimeout）
- [ ] 設定 3 層逾時（Transport、Client、Context）
- [ ] 使用 `req.WithContext(ctx)` 支持取消

**重試策略**
- [ ] 僅對冪等方法重試（GET、PUT、DELETE）
- [ ] 實作指數退避（Exponential Backoff）
- [ ] 設定最大重試次數（建議 3 次）
- [ ] 重試前關閉 Response Body

**Body 處理**
- [ ] 使用 `bytes.Clone` 實作 Body 重播
- [ ] 設定 `req.GetBody` 支持 Redirect
- [ ] 嚴格 `defer resp.Body.Close()`

**Multipart 上傳**
- [ ] 大檔案使用 `io.Pipe` 串流上傳
- [ ] 先關閉 `writer`，再關閉 `pw`
- [ ] 失敗時使用 `pw.CloseWithError(err)`
- [ ] 設定正確的 `Content-Type`（包含 boundary）

**Middleware**
- [ ] Middleware 順序：Recovery → Tracing → Logging → Auth
- [ ] Wrap ResponseWriter 捕獲狀態碼
- [ ] 使用 Chain 組合 Middleware
