---
name: go-observability
description: |
  Go 可觀測性規範：結構化日誌（zap/slog）、Prometheus Metrics 規範、OpenTelemetry 整合、
  Context 傳遞與 Trace ID 串接、日誌等級管理、Metrics 命名慣例。

  **適用場景**：實作結構化日誌、設計 Prometheus Metrics、整合 OpenTelemetry Tracing、
  配置日誌欄位、實作 Context 傳遞、分散式追蹤、監控告警。
keywords:
  - logging
  - structured logging
  - zap
  - slog
  - prometheus
  - metrics
  - counter
  - gauge
  - histogram
  - opentelemetry
  - tracing
  - trace id
  - span
  - observability
  - monitoring
  - alerting
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Go 可觀測性規範

> **相關 Skills**：本規範建議搭配 `go-grpc`（gRPC Interceptor）與 `go-http-advanced`（HTTP Middleware）

---

## 結構化日誌（Structured Logging）

### 推薦套件

1. **[vincent119/zlogger](https://github.com/vincent119/zlogger)** - 基於 zap 的簡化封裝（**推薦**）
2. **[uber-go/zap](https://github.com/uber-go/zap)** - 高效能、低分配
3. **[log/slog](https://pkg.go.dev/log/slog)** - Go 1.21+ 標準庫

**原則**：
- 使用**結構化日誌**，禁止純字串拼接
- 固定欄位：`trace_id`, `request_id`, `user_id`, `subsystem`
- 使用 Context 方法自動注入追蹤欄位
- 錯誤使用 `zlogger.Err(err)` 而非字串拼接

### zlogger 基本使用（推薦）

```go
package main

import (
    "github.com/vincent119/zlogger"
)

func main() {
    // 初始化（使用預設配置）
    zlogger.Init(nil)
    defer zlogger.Sync()

    // 基本日誌
    zlogger.Info("伺服器啟動", zlogger.String("port", "8080"))
    zlogger.Debug("除錯訊息", zlogger.Int("count", 42))

    // 錯誤日誌
    if err := someOperation(); err != nil {
        zlogger.Error("操作失敗", zlogger.Err(err))  // ✅ 正確
        // ❌ 錯誤：zlogger.Error(fmt.Sprintf("操作失敗: %v", err))
    }
}
```

### 自訂配置

```go
package main

import (
    "github.com/vincent119/zlogger"
)

func main() {
    cfg := &zlogger.Config{
        Level:       "info",            // debug, info, warn, error
        Format:      "json",            // json 或 console
        Outputs:     []string{"console", "file"},
        LogPath:     "./logs",
        FileName:    "app.log",
        AddCaller:   true,
        Development: false,
        ColorEnabled: true,            // Console 顏色輸出
    }
    zlogger.Init(cfg)
    defer zlogger.Sync()
}
```

### 從設定檔載入

```yaml
# config.yaml
log:
  level: debug
  format: json
  outputs:
    - console
    - file
  log_path: ./logs
  file_name: app.log
  add_caller: true
  development: false
  color_enabled: true
```

```go
import (
    "github.com/spf13/viper"
    "github.com/vincent119/zlogger"
)

type Config struct {
    Log zlogger.Config `yaml:"log"`
}

func main() {
    viper.SetConfigFile("config.yaml")
    viper.ReadInConfig()

    var cfg Config
    viper.Unmarshal(&cfg)

    zlogger.Init(&cfg.Log)
    defer zlogger.Sync()
}
```

### Context 支援（自動追蹤）

```go
import (
    "context"
    "github.com/vincent119/zlogger"
)

func HandleRequest(ctx context.Context) {
    // 建立帶追蹤資訊的 Context
    ctx = zlogger.WithRequestID(ctx, "req-123")
    ctx = zlogger.WithUserID(ctx, 12345)
    ctx = zlogger.WithTraceID(ctx, "trace-abc")

    // 使用 Context 方法，自動帶入追蹤欄位
    zlogger.InfoContext(ctx, "處理請求",
        zlogger.String("action", "login"),
    )

    if err := processUser(ctx); err != nil {
        // 自動包含 request_id, user_id, trace_id
        zlogger.ErrorContext(ctx, "處理失敗", zlogger.Err(err))
    }
}

func processUser(ctx context.Context) error {
    // Context 欄位自動繼承
    zlogger.DebugContext(ctx, "查詢使用者資料",
        zlogger.String("table", "users"),
    )
    return nil
}
```

### 日誌等級規範

| 等級 | 使用時機 | 範例 |
|------|----------|------|
| **Debug** | 開發除錯資訊 | 變數值、中間狀態 |
| **Info** | 一般資訊 | 請求開始、完成、配置載入 |
| **Warn** | 警告（不影響功能） | 重試、備援機制觸發、參數預設值 |
| **Error** | 錯誤（影響功能） | 請求失敗、DB 錯誤、外部 API 失敗 |
| **Fatal** | 致命錯誤（程式終止） | 僅限 `main()` 初始化階段 |

**禁止**：
- 不在 library 或 handler 使用 `logger.Fatal()`（會跳過 defer 與資源清理）
- 不在迴圈內使用 `logger.Debug()`（效能問題）

---

## Prometheus Metrics 規範

### 核心原則

#### Metric 類型

| 類型 | 特性 | 適用場景 |
|------|------|----------|
| **Counter** | **僅能增長 (Increment)**，不可減少 | 請求總數、錯誤總數、任務完成次數 |
| **Gauge** | 可增減 | 當前記憶體用量、Goroutine 數量、Queue 長度 |
| **Histogram** | 數值分佈統計 | 請求延遲 (Latency)、Payload 大小 |
| **Summary** | 類似 Histogram（較少使用） | 客戶端計算百分位數 |

#### 命名慣例

**格式**：`<namespace>_<subsystem>_<name>_<unit>`

**規則**：
- 使用蛇形命名法 (Snake Case)：`http_requests_total`
- **必須**包含單位後綴：
  - `_seconds` - 延遲、時間
  - `_bytes` - 大小
  - `_total` - 計數（Counter 專用）
  - `_ratio` - 比率（0-1 之間）

**範例**：
```
✅ 正確
http_requests_total
http_request_duration_seconds
db_query_duration_seconds
cache_hit_ratio

❌ 錯誤
httpRequestsCount           # 應用蛇形命名
request_latency             # 缺少單位
total_requests              # total 應在結尾
```

### Label 規範

**原則**：
- **禁止**高基數 (High Cardinality) 值（如 `user_id`, `email`, `trace_id`），避免搞垮 Prometheus
- 必備 Label：`service` (服務名), `env` (環境), `code` (錯誤碼/狀態碼)
- Label 數量建議 ≤ 5 個

**範例**：
```go
// ✅ 正確：低基數 Labels
http_requests_total{method="GET", status="200", service="api", env="prod"}

// ❌ 錯誤：高基數 Labels
httpGin Middleware 整合（zlogger）

```go
package middleware

import (
    "time"
    "github.com/gin-gonic/gin"
    "github.com/google/uuid"
    "github.com/vincent119/zlogger"
)

const (
    LogFieldsKey = "log_fields"
    LogSkipKey   = "log_skip"
)

// SetLogFields 設定自訂日誌欄位
func SetLogFields(c *gin.Context, fields ...zlogger.Field) {
    if existing, exists := c.Get(LogFieldsKey); exists {
        fields = append(existing.([]zlogger.Field), fields...)
    }
    c.Set(LogFieldsKey, fields)
}

// SkipMiddlewareLog 跳過中間件日誌（handler 自行記錄時）
func SkipMiddlewareLog(c *gin.Context) {
    c.Set(LogSkipKey, true)
}

// Logger 日誌 + Metrics 中間件
func Logger() gin.HandlerFunc {
    return func(c *gin.Context) {
        start := time.Now()

        // 生成 Request ID
        requestID := uuid.New().String()
        c.Set("requestID", requestID)
        c.Header("X-Request-ID", requestID)

        // 注入 Context
        ctx := zlogger.WithRequestID(c.Request.Context(), requestID)
        c.Request = c.Request.WithContext(ctx)

        c.Next()

        // 檢查是否跳過日誌
        if skip, exists := c.Get(LogSkipKey); exists && skip.(bool) {
            return
        }

        latency := time.Since(start)

        // 基本欄位
        fields := []zlogger.Field{
            zlogger.String("method", c.Request.Method),
            zlogger.String("path", c.Request.URL.Path),
            zlogger.String("query", c.Request.URL.RawQuery),
            zlogger.String("ip", c.ClientIP()),
            zlogger.Int("status", c.Writer.Status()),
            zlogger.Duration("latency", latency),
            zlogger.String("user-agent", c.Request.UserAgent()),
        }

        // 加入自訂欄位
        if customFields, exists := c.Get(LogFieldsKey); exists {
            fields = append(fields, customFields.([]zlogger.Field)...)
        }

        // 記錄日誌
        if len(c.Errors) > 0 {
            fields = append(fields, zlogger.String("error", c.Errors.String()))
            zlogger.ErrorContext(ctx, "HTTP Request Error", fields...)
        } else {
            zlogger.InfoContext(ctx, "HTTP Request", fields...)
        }

        // 記錄 Metrics
        metrics.RecordRequest(
            c.Request.Method,
            strconv.Itoa(c.Writer.Status()),
            c.Request.URL.Path,
            latency.Seconds(),
        )
    }
}

// 使用範例（Handler）
func GetUserHandler(c *gin.Context) {
    // 方式一：使用 SetLogFields 新增自訂欄位
    middleware.SetLogFields(c,
        zlogger.String("category", "user"),
        zlogger.String("action", "get"),
    )

    // 方式二：直接使用 Context 記錄日誌
    zlogger.InfoContext(c.Request.Context(), "獲取使用者",
        zlogger.Uint("user_id", 12345),
    )

    // 若 Handler 已記錄，可跳過中間件日誌
    middleware.SkipMiddlewareLog(c)

    c.JSON(200, gin.H{"status": "ok"})
}
```

### HTTP Middleware（標準庫）er_id="user-12345", trace_id="abc123..."}  // 會產生大量 time series
```

### 實作範例

```go
package metrics

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    // Counter: 僅能 Inc
    HttpRequestsTotal = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "status", "path"},  // Labels
    )

    // Histogram: 觀測延遲分佈
    HttpRequestDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_request_duration_seconds",
            Help:    "HTTP request duration in seconds",
            Buckets: prometheus.DefBuckets,  // 或自訂：[]float64{0.01, 0.05, 0.1, 0.5, 1, 2.5, 5, 10}
        },
        []string{"method", "path"},
    )

    // Gauge: 當前 Goroutine 數量
    CurrentGoroutines = promauto.NewGauge(
        prometheus.GaugeOpts{
            Name: "goroutines_current",
            Help: "Current number of goroutines",
        },
    )
)

// 使用範例
func RecordRequest(method, status, path string, duration float64) {
    // Counter: 增加計數
    HttpRequestsTotal.WithLabelValues(method, status, path).Inc()

    // Histogram: 記錄延遲
    HttpRequestDuration.WithLabelValues(method, path).Observe(duration)
}

// Gauge 使用範例
func UpdateGoroutineCount() {
    count := runtime.NumGoroutine()
    CurrentGoroutines.Set(float64(count))
}
```

### HTTP Middleware 整合

```go
func MetricsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()

        // 包裝 ResponseWriter 以捕獲狀態碼
        rw := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

        next.ServeHTTP(rw, r)

        // 記錄 Metrics
        duration := time.Since(start).Seconds()
        metrics.RecordRequest(
            r.Method,
            strconv.Itoa(rw.statusCode),
            r.URL.Path,
            duration,
        )
    })
}

type responseWriter struct {
    http.ResponseWriter
    statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
    rw.statusCode = code
    rw.ResponseWriter.WriteHeader(code)
}
```

### 暴露 Metrics Endpoint

```go
import (
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
    // 業務 API
    http.Handle("/api/", apiHandler)

    // Metrics Endpoint（通常使用不同 Port）
    metricsServer := &http.Server{
        Addr:    ":9090",
        Handler: promhttp.Handler(),  // 暴露 /metrics
    }

    go metricsServer.ListenAndServe()

    // ...啟動主 Server
}
```

---

## OpenTelemetry 整合

### 安裝套件

```bash
go get go.opentelemetry.io/otel
go get go.opentelemetry.io/otel/exporters/jaeger
go get go.opentelemetry.io/otel/sdk/trace
go get go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp
go get go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc
```

### 初始化 Tracer

```go
package tracing

import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/jaeger"
    "go.opentelemetry.io/otel/sdk/resource"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.4.0"
)

func InitTracer(serviceName, jaegerEndpoint string) (func(), error) {
    // Jaeger Exporter
    exporter, err := jaeger.New(jaeger.WithCollectorEndpoint(jaeger.WithEndpoint(jaegerEndpoint)))
    if err != nil {
        return nil, fmt.Errorf("failed to create jaeger exporter: %w", err)
    }

    // Trace Provider
    tp := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(exporter),
        sdktrace.WithResource(resource.NewWithAttributes(
   zlogger 自動整合 Trace ID
func HandleRequest(ctx context.Context) {
    // 從 OpenTelemetry 取得 Trace ID
    traceID := GetTraceID(ctx)
    ctx = zlogger.WithTraceID(ctx, traceID)

    // 日誌自動包含 trace_id
    zlogger.InfoContext(ctx, "處理請求")
}
```

---

## 按級別分離日誌檔案（zlogger）

```go
import (
    "go.uber.org/zap/zapcore"
    "github.com/vincent119/zlogger"
)

func main() {
    // 建立分離輸出的核心
    core, cleanup, err := zlogger.GetSplitCore("./logs", "app", zapcore.EncoderConfig{
        TimeKey:     "ts",
        LevelKey:    "level",
        MessageKey:  "msg",
        EncodeTime:  zapcore.ISO8601TimeEncoder,
        EncodeLevel: zapcore.CapitalLevelEncoder,
    })
    if err != nil {
        panic(err)
    }
    defer cleanup()

    // 會產生以下檔案：
    // - logs/app-info-2024-01-01.log
    // - logs/app-warn-2024-01-01.log
    // - logs/app-error-2024-01-01.log
}
```

---

## 動態調整日誌等級

```go
// 運行時調整等級（例如透過 API）
func SetLogLevel(level string) {
    zlogger.SetLevel(level)  // "debug", "info", "warn", "error"
}

// 範例：HTTP Endpoint
func handleSetLogLevel(c *gin.Context) {
    level := c.Query("level")
    zlogger.SetLevel(level)
    c.JSON(200, gin.H{"level": level})
}
```

---

## 檢查清單

**結構化日誌**
- [ ] 使用 zlogger（或 zap/slog）
- [ ] 使用 Context 方法（InfoContext, ErrorContext）
- [ ] 固定欄位包含 `request_id`, `trace_id`, `user_id`
- [ ] 使用 `zlogger.Err(err)` 而非字串拼接
- [ ] 不在 library 使用 `
```go
import (
    "go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
)

func main() {
    // 初始化 Tracer
    shutdown, err := tracing.InitTracer("myservice", "http://jaeger:14268/api/traces")
    if err != nil {
        log.Fatal(err)
    }
    defer shutdown()

    // 包裝 Handler
    handler := otelhttp.NewHandler(http.HandlerFunc(myHandler), "myservice")

    http.ListenAndServe(":8080", handler)
}
```

### gRPC Server 整合

```go
import (
    "go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"
)

func main() {
    grpcServer := grpc.NewServer(
        grpc.UnaryInterceptor(otelgrpc.UnaryServerInterceptor()),
        grpc.StreamInterceptor(otelgrpc.StreamServerInterceptor()),
    )

    // ...註冊服務
}
```

### Context 傳遞與 Trace ID

**核心原則**：
- 所有跨函式呼叫（特別是跨邊界的 DB/HTTP 呼叫）必須傳遞 `ctx`，以確保 Trace ID 能正確串接

```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/trace"
)

func ProcessOrder(ctx context.Context, orderID string) error {
    tracer := otel.Tracer("myservice")

    // 建立 Span
    ctx, span := tracer.Start(ctx, "ProcessOrder")
    defer span.End()

    // 傳遞 ctx 至子函式（Trace 自動串接）
    if err := validateOrder(ctx, orderID); err != nil {
        span.RecordError(err)  // 記錄錯誤到 Span
        return err
    }

    if err := saveOrder(ctx, orderID); err != nil {
        span.RecordError(err)
        return err
    }

    return nil
}

func validateOrder(ctx context.Context, orderID string) error {
    // 自動繼承 Parent Span
    tracer := otel.Tracer("myservice")
    ctx, span := tracer.Start(ctx, "validateOrder")
    defer span.End()

    // ...驗證邏輯
    return nil
}
```

### 取得 Trace ID

```go
func GetTraceID(ctx context.Context) string {
    spanCtx := trace.SpanFromContext(ctx).SpanContext()
    if spanCtx.HasTraceID() {
        return spanCtx.TraceID().String()
    }
    return ""
}

// 注入到 Logger
func LogWithTrace(ctx context.Context, logger *zap.Logger, msg string) {
    traceID := GetTraceID(ctx)
    logger.Info(msg, zap.String("trace_id", traceID))
}
```

---

## 檢查清單

**結構化日誌**
- [ ] 使用 Zap 或 Slog
- [ ] 固定欄位包含 `trace_id`, `span_id`, `req_id`
- [ ] 使用 `zap.Error(err)` 而非字串拼接
- [ ] 不在 library 使用 `logger.Fatal()`
- [ ] 生產環境使用 JSON 格式

**Prometheus Metrics**
- [ ] Counter 僅使用 `Inc()`，不減少
- [ ] Gauge 用於可增減的指標
- [ ] Histogram 用於延遲/大小分佈
- [ ] 命名使用蛇形命名法與單位後綴（`_seconds`, `_bytes`, `_total`）
- [ ] Label 避免高基數值（無 `user_id`, `trace_id`）
- [ ] Metrics Endpoint 暴露於獨立 Port（如 `:9090`）

**OpenTelemetry**
- [ ] 初始化 Tracer 並設定 Service Name
- [ ] HTTP/gRPC 整合 OTel Instrumentation
- [ ] 所有跨邊界呼叫傳遞 `ctx`
- [ ] 使用 `span.RecordError()` 記錄錯誤
- [ ] Logger 包含 Trace ID

**Context 傳遞**
- [ ] 所有對外 API 第一個參數為 `ctx context.Context`
- [ ] DB 查詢使用 `db.WithContext(ctx)`
- [ ] HTTP Client 使用 `req.WithContext(ctx)`
- [ ] gRPC Client 傳遞 `ctx`
