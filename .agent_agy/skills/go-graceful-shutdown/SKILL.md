---
name: go-graceful-shutdown
description: |
  Go 優雅關機（Graceful Shutdown）模式：Signal 處理、HTTP Server shutdown、gRPC GracefulStop、
  Worker/Consumer 停止、Kubernetes 整合、Context 取消機制、資源清理流程。

  **適用場景**：實作 HTTP Server 優雅關機、gRPC Server 停止、Background Worker 終止、
  Kubernetes 部署配置、處理 SIGTERM/SIGINT、實作 preStop hook、避免請求中斷。
keywords:
  - graceful shutdown
  - signal handling
  - sigterm
  - sigint
  - http shutdown
  - grpc graceful stop
  - kubernetes
  - prestop hook
  - context cancellation
  - drain
  - worker shutdown
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Go 優雅關機（Graceful Shutdown）規範

> **相關 Skills**：本規範建議搭配 `go-grpc`（gRPC Server）與 `go-http-advanced`（HTTP Server）

---

## 推薦套件

**優先選擇**：[vincent119/commons/graceful](https://github.com/vincent119/commons/tree/main/graceful)

**核心特性**：
- 統一的生命週期管理介面（訊號監聽、Context 管理、資源清理）
- 內建 HTTP Server 支援（`HTTPTask`）
- 靈活的清理機制（LIFO 順序、timeout 控制）
- 支援 `log/slog` 結構化日誌
- 自動錯誤聚合（`errors.Join`）

**安裝**：
```bash
go get github.com/vincent119/commons/graceful
```

### 基本使用（HTTP Server）

```go
package main

import (
    "context"
    "log/slog"
    "net/http"
    "os"
    "time"

    "github.com/vincent119/commons/graceful"
)

func main() {
    logger := slog.New(slog.NewTextHandler(os.Stderr, nil))
    srv := &http.Server{Addr: ":8080"}

    // 初始化資源
    // db, _ := sql.Open(...)

    err := graceful.Run(
        // 1. 主要任務：HTTPTask 封裝 srv.ListenAndServe
        graceful.HTTPTask(srv),

        // 2. 設定 Logger
        graceful.WithLogger(logger),

        // 3. 設定 Shutdown Timeout（預設 30s）
        graceful.WithTimeout(10*time.Second),

        // 4. 註冊清理函式（LIFO 順序執行）
        graceful.WithCleanup(func(ctx context.Context) error {
            logger.Info("shutting down server...")
            return srv.Shutdown(ctx)
        }),

        // 5. 註冊 io.Closer 資源（自動呼叫 Close()）
        // graceful.WithCloser(db),
        // graceful.WithClosers(redis, cache),  // 批量註冊
    )

    if err != nil {
        logger.Error("application exited with error", "error", err)
        os.Exit(1)
    }
}
```

### 通用 Worker 用法

**任何符合 `func(ctx context.Context) error` 的任務都可使用**：

```go
func MyWorker(ctx context.Context) error {
    ticker := time.NewTicker(10 * time.Second)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            // 收到訊號，優雅退出
            return nil
        case <-ticker.C:
            // 執行工作
            if err := doWork(); err != nil {
                return err
            }
        }
    }
}

func main() {
    graceful.Run(
        MyWorker,
        graceful.WithTimeout(5*time.Second),
    )
}
```

### 進階選項

```go
err := graceful.Run(
    task,
    // 設定 shutdown timeout（預設 30s）
    graceful.WithTimeout(15*time.Second),

    // 設定 logger（預設 slog.Default()）
    graceful.WithLogger(logger),

    // 註冊清理函式（LIFO 順序）
    graceful.WithCleanup(func(ctx context.Context) error {
        // 先註冊的後執行
        return db.Close()
    }),
    graceful.WithCleanup(func(ctx context.Context) error {
        // 後註冊的先執行
        return srv.Shutdown(ctx)
    }),

    // 註冊單個 io.Closer
    graceful.WithCloser(db),

    // 批量註冊多個 io.Closer（按順序關閉）
    graceful.WithClosers(redis, cache, queue),
)
```

**重要注意事項**：
1. **清理順序**：`WithCleanup` 採用 LIFO (後進先出)。建議先註冊底層資源（DB），再註冊上層服務（HTTP Server），確保關機時先停止服務再關閉資料庫
2. **錯誤合併**：若主任務與清理工作皆發生錯誤，`graceful.Run` 使用 `errors.Join` 返回所有錯誤
3. **超時控制**：每個 Cleanup 函式必須尊重 `ctx.Done()`，避免阻塞整體關機流程

---

## 進階實作（手動模式）

> **注意**：以下為不使用 `commons/graceful` 的手動實作方式，僅供理解原理或特殊場景使用

### 核心原則

**必須實作優雅關機的元件**：
- HTTP Server
- gRPC Server
- Background Worker / Scheduler
- Message Queue Consumer
- 所有外部資源連線（DB、Cache、Message Queue）

**關機流程順序**：
1. 接收系統訊號（`SIGINT`, `SIGTERM`）
2. 停止接受新請求（HTTP Server `Shutdown` / gRPC `GracefulStop`）
3. 等待進行中的請求或任務完成
4. 在 timeout 到期後強制結束
5. 關閉所有外部資源（DB、Cache、Queue、Tracer）

**禁止行為**：
- 禁止在正常關機流程中使用 `os.Exit()`
- 禁止在 server goroutine 使用 `log.Fatal` / `logger.Fatal`（會跳過 defer 與資源收尾）
- 禁止忽略 `ctx.Done()` 造成關機卡死

---

## Signal 處理（Go 1.16+）

### 使用 signal.NotifyContext

```go
import (
    "context"
    "os"
    "os/signal"
    "syscall"
)

func main() {
    // 將 OS 訊號轉為可取消的 context
    ctx, stop := signal.NotifyContext(
        context.Background(),
        os.Interrupt,     // SIGINT (Ctrl+C)
        syscall.SIGTERM,  // SIGTERM (Kubernetes 預設)
    )
    defer stop()  // 釋放資源

    // 啟動 Server（會阻塞）
    if err := runServer(ctx); err != nil {
        log.Fatalf("server error: %v", err)
    }
}
```

---

## HTTP Server 優雅關機

### 標準模式

```go
func runHTTPServer(
    srv *http.Server,
    shutdownTimeout time.Duration,
    closeResources func(ctx context.Context) error,  // 關閉 DB/Redis/Scheduler
    logger *zap.Logger,
) error {
    // 1) 訊號轉 ctx
    ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer stop()

    // 2) 監控 server 是否異常退出（避免只等訊號，卻漏掉 server 先掛）
    srvErr := make(chan error, 1)

    go func() {
        // ListenAndServe 正常因 Shutdown/Close 退出會回傳 http.ErrServerClosed
        if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
            srvErr <- err
        }
        close(srvErr)  // 關閉 channel 表示 server goroutine 已結束
    }()

    // 3) 等待：訊號 or server 異常
    select {
    case <-ctx.Done():  // 收到關機訊號
        logger.Info("received shutdown signal")
    case err := <-srvErr:  // 服務異常退出
        if err != nil {
            logger.Error("http server stopped unexpectedly", zap.Error(err))
            return err
        }
    }

    // 4) 統一走 graceful shutdown：先停止接新請求，再收尾資源
    shutdownCtx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
    defer cancel()

    if err := srv.Shutdown(shutdownCtx); err != nil {
        // Shutdown 會等待 in-flight request，若卡住要有最後手段
        logger.Error("http server shutdown failed", zap.Error(err))
        _ = srv.Close()  // 最後手段：避免卡住（可能中斷連線）
    }

    // 5) 關閉外部資源（scheduler/worker/redis/db...）
    var resErr error
    if closeResources != nil {
        resErr = closeResources(shutdownCtx)
        if resErr != nil {
            logger.Error("close resources failed", zap.Error(resErr))
        }
    }

    logger.Info("server exited")
    return resErr
}
```

### Gin Framework 範例

```go
import "github.com/gin-gonic/gin"

func main() {
    r := gin.Default()
    r.GET("/ping", func(c *gin.Context) {
        c.JSON(200, gin.H{"message": "pong"})
    })

    srv := &http.Server{
        Addr:    ":8080",
        Handler: r,
    }

    // 使用通用 runHTTPServer 函式
    if err := runHTTPServer(srv, 30*time.Second, nil, logger); err != nil {
        log.Fatal(err)
    }
}
```

---

## gRPC Server 優雅關機

### GracefulStop 範例

```go
func runGRPCServer(
    grpcServer *grpc.Server,
    lis net.Listener,
    shutdownTimeout time.Duration,
    logger *zap.Logger,
) error {
    // 1) 訊號監聽
    ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer stop()

    // 2) Server goroutine
    srvErr := make(chan error, 1)
    go func() {
        if err := grpcServer.Serve(lis); err != nil {
            srvErr <- err
        }
        close(srvErr)
    }()

    // 3) 等待訊號或錯誤
    select {
    case <-ctx.Done():
        logger.Info("received shutdown signal")
    case err := <-srvErr:
        if err != nil {
            logger.Error("grpc server error", zap.Error(err))
            return err
        }
    }

    // 4) Graceful Stop（等待進行中的請求完成）
    stopped := make(chan struct{})
    go func() {
        grpcServer.GracefulStop()  // 阻塞直到所有請求完成
        close(stopped)
    }()

    // 5) 等待 GracefulStop 或 timeout
    select {
    case <-stopped:
        logger.Info("grpc server stopped gracefully")
    case <-time.After(shutdownTimeout):
        logger.Warn("graceful stop timeout, forcing shutdown")
        grpcServer.Stop()  // 強制停止
    }

    return nil
}
```

---

## Background Worker 優雅關機

### Worker 模式

```go
type Worker struct {
    logger *zap.Logger
}

func (w *Worker) Run(ctx context.Context) error {
    ticker := time.NewTicker(10 * time.Second)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            // 收到取消訊號，停止拉取新任務
            w.logger.Info("worker shutting down")
            return ctx.Err()
        case <-ticker.C:
            // 執行週期性任務
            if err := w.processTask(ctx); err != nil {
                w.logger.Error("task failed", zap.Error(err))
            }
        }
    }
}

func (w *Worker) processTask(ctx context.Context) error {
    // 長時間任務需定期檢查 ctx.Done()
    for i := 0; i < 100; i++ {
        select {
        case <-ctx.Done():
            w.logger.Warn("task interrupted")
            return ctx.Err()
        default:
            // 執行任務片段
            time.Sleep(100 * time.Millisecond)
        }
    }
    return nil
}
```

### Message Queue Consumer 範例

```go
type Consumer struct {
    queue  *Queue
    logger *zap.Logger
}

func (c *Consumer) Start(ctx context.Context) error {
    for {
        select {
        case <-ctx.Done():
            c.logger.Info("consumer stopping, draining queue...")

            // 處理剩餘訊息（或設定 timeout）
            drainCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
            defer cancel()

            for c.queue.HasMessages() {
                select {
                case <-drainCtx.Done():
                    c.logger.Warn("drain timeout, some messages may be lost")
                    return drainCtx.Err()
                default:
                    msg, err := c.queue.Receive(drainCtx)
                    if err != nil {
                        return err
                    }
                    _ = c.processMessage(drainCtx, msg)
                }
            }

            return nil
        default:
            msg, err := c.queue.Receive(ctx)
            if err != nil {
                if errors.Is(err, context.Canceled) {
                    return err
                }
                c.logger.Error("receive failed", zap.Error(err))
                continue
            }

            if err := c.processMessage(ctx, msg); err != nil {
                c.logger.Error("process failed", zap.Error(err))
            }
        }
    }
}
```

---

## 資源清理函式

### 統一清理介面

```go
type Resources struct {
    db        *gorm.DB
    redis     *redis.Client
    scheduler *Scheduler
    tracer    func()  // OTel Shutdown
}

func (r *Resources) Close(ctx context.Context) error {
    var errs []error

    // 1. 停止 Scheduler
    if r.scheduler != nil {
        if err := r.scheduler.Stop(ctx); err != nil {
            errs = append(errs, fmt.Errorf("stop scheduler: %w", err))
        }
    }

    // 2. 關閉 Tracer（OTel）
    if r.tracer != nil {
        r.tracer()
    }

    // 3. 關閉 Redis
    if r.redis != nil {
        if err := r.redis.Close(); err != nil {
            errs = append(errs, fmt.Errorf("close redis: %w", err))
        }
    }

    // 4. 關閉 DB（最後才關閉）
    if r.db != nil {
        sqlDB, err := r.db.DB()
        if err == nil {
            if err := sqlDB.Close(); err != nil {
                errs = append(errs, fmt.Errorf("close db: %w", err))
            }
        }
    }

    // 聚合錯誤
    if len(errs) > 0 {
        return errors.Join(errs...)
    }

    return nil
}
```

### 使用範例

```go
func main() {
    // 初始化資源
    resources := &Resources{
        db:        initDB(),
        redis:     initRedis(),
        scheduler: initScheduler(),
        tracer:    initTracer(),
    }

    // 建立 HTTP Server
    srv := &http.Server{
        Addr:    ":8080",
        Handler: buildHandler(),
    }

    // 啟動並等待關機
    if err := runHTTPServer(srv, 30*time.Second, resources.Close, logger); err != nil {
        log.Fatal(err)
    }
}
```

---

## Kubernetes 整合

### terminationGracePeriodSeconds 配置

**原則**：
- `terminationGracePeriodSeconds` ≥ 應用層 Shutdown timeout + buffer（建議 5-10 秒）

**範例**：
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      terminationGracePeriodSeconds: 45  # 應用層 30s + buffer 15s
      containers:
        - name: app
          image: myapp:latest
          env:
            - name: SHUTDOWN_TIMEOUT
              value: "30"
```

### preStop Hook

**目的**：確保 Pod 從 Service Endpoints 移除後再開始 shutdown（避免新請求進來）

```yaml
lifecycle:
  preStop:
    exec:
      command: ["sleep", "5"]  # 等待 Endpoints 更新
```

### 完整範例

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  template:
    spec:
      terminationGracePeriodSeconds: 45
      containers:
        - name: app
          image: myapp:latest
          ports:
            - containerPort: 8080
              name: http
          env:
            - name: SHUTDOWN_TIMEOUT
              value: "30"
          lifecycle:
            preStop:
              exec:
                command: ["sleep", "5"]
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /readyz
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
```

---

## 測試優雅關機

### 模擬關機測試

```go
func TestGracefulShutdown(t *testing.T) {
    srv := &http.Server{
        Addr: ":0",  // 隨機 Port
        Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            time.Sleep(2 * time.Second)  // 模擬慢請求
            w.WriteHeader(200)
        }),
    }

    // 啟動 Server
    lis, err := net.Listen("tcp", srv.Addr)
    if err != nil {
        t.Fatal(err)
    }

    go func() {
        _ = srv.Serve(lis)
    }()

    // 發送請求
    reqDone := make(chan bool)
    go func() {
        resp, err := http.Get("http://" + lis.Addr().String())
        if err != nil {
            t.Errorf("request failed: %v", err)
        }
        resp.Body.Close()
        reqDone <- true
    }()

    // 等待請求開始
    time.Sleep(100 * time.Millisecond)

    // 觸發關機
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    if err := srv.Shutdown(ctx); err != nil {
        t.Errorf("shutdown failed: %v", err)
    }

    // 驗證請求完成
    <-reqDone
}
```

---

## 檢查清單

**優先推薦**
- [ ] 使用 `github.com/vincent119/commons/graceful` 套件（統一生命週期管理）
- [ ] `graceful.Run()` 作為主程式入口
- [ ] 使用 `graceful.HTTPTask()` 包裝 HTTP Server
- [ ] 使用 `graceful.WithCleanup()` 註冊清理函式（LIFO 順序）
- [ ] 使用 `graceful.WithCloser()` / `WithClosers()` 註冊資源（自動 Close）
- [ ] 設定適當的 `WithTimeout()`（建議 10-30 秒）
- [ ] 整合 `log/slog` 結構化日誌

**Signal 處理（手動實作）**
- [ ] 使用 `signal.NotifyContext` 監聽 `SIGINT` 與 `SIGTERM`
- [ ] 不在正常流程使用 `os.Exit()`
- [ ] 不在 server goroutine 使用 `log.Fatal()`

**HTTP Server**
- [ ] 使用 `srv.Shutdown(ctx)` 而非 `srv.Close()`
- [ ] 設定 shutdown timeout（建議 30 秒）
- [ ] 處理 `http.ErrServerClosed`（正常退出）
- [ ] Shutdown 失敗時強制 `srv.Close()`

**gRPC Server**
- [ ] 使用 `grpcServer.GracefulStop()` 而非 `Stop()`
- [ ] GracefulStop 設定 timeout（避免無限等待）
- [ ] Timeout 後強制 `grpcServer.Stop()`

**Background Worker**
- [ ] 監聽 `ctx.Done()` 停止拉取新任務
- [ ] 長時間任務定期檢查 `ctx.Done()`
- [ ] Message Queue Consumer 實作 drain 邏輯

**資源清理**
- [ ] 按順序關閉：Scheduler → Tracer → Cache → DB
- [ ] 使用 `errors.Join` 聚合清理錯誤
- [ ] 清理函式接受 `context.Context`（支持 timeout）

**Kubernetes**
- [ ] `terminationGracePeriodSeconds` ≥ shutdown timeout + buffer
- [ ] 配置 `preStop` hook（sleep 5s）
- [ ] 實作 `/readyz` endpoint（關機時回傳 503）

**測試**
- [ ] 模擬 SIGTERM 測試關機流程
- [ ] 驗證進行中的請求能完成
- [ ] 驗證 timeout 後強制關閉
- [ ] 測試清理函式 LIFO 執行順序（使用 `graceful`）
- [ ] 測試錯誤聚合（多個清理函式同時失敗）
