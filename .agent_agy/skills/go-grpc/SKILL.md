---
name: go-grpc
description: |
  Go gRPC 完整實作規範：Proto 檔案管理、Buf 使用、Interceptor 設計、健康檢查協議、
  Deadline 與 Context 處理、錯誤代碼映射、優雅關機（GracefulStop）。

  **適用場景**：實作 gRPC server、設計 RPC API、配置 Interceptor、處理 gRPC 錯誤、
  實作健康檢查、gRPC 客戶端開發、Kubernetes gRPC 部署。
keywords:
  - grpc
  - protobuf
  - proto
  - rpc
  - interceptor
  - health check
  - deadline
  - context
  - grpc server
  - grpc client
  - buf
  - grpc-gateway
  - grpc status codes
  - graceful stop
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Go gRPC 完整實作規範

> **相關 Skills**：本規範建議搭配 `go-graceful-shutdown` 與 `go-observability`

---

## Proto 檔案管理

### 目錄結構

```bash
api/
├── proto/
│   └── <service>/
│       ├── v1/
│       │   ├── service.proto        # 服務定義
│       │   └── messages.proto       # 訊息定義
│       └── buf.yaml                 # Buf 配置
└── gen/
    └── go/
        └── <service>/
            └── v1/
                ├── service.pb.go         # 產生的程式碼
                └── service_grpc.pb.go    # gRPC 服務程式碼
```

### Buf 配置

**推薦使用 [buf](https://buf.build/)** 管理 linting、breaking change detection、程式碼產生。

**`api/proto/buf.yaml`**：
```yaml
version: v1
name: buf.build/myorg/myservice
breaking:
  use:
    - FILE
lint:
  use:
    - DEFAULT
  except:
    - PACKAGE_VERSION_SUFFIX  # 若不使用 v1 後綴可移除
```

**`api/proto/buf.gen.yaml`**：
```yaml
version: v1
plugins:
  - plugin: go
    out: ../gen/go
    opt:
      - paths=source_relative
  - plugin: go-grpc
    out: ../gen/go
    opt:
      - paths=source_relative
      - require_unimplemented_servers=false
```

### 產生程式碼

```bash
# 使用 buf 產生
cd api/proto
buf generate

# 或使用 Makefile
make proto-gen
```

**重要規範**：
- 產生的程式碼放入 `api/gen/go/`（**不手動編輯**）
- 加入 `.gitignore`（選擇性，通常建議納入版本控制以避免 CI 依賴）
- CI 階段驗證產生檔案與 `.proto` 一致

---

## Interceptor 設計

### 標準 Interceptor 順序（由外至內）

```go
import (
    "go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"
    "github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/recovery"
    "github.com/grpc-ecosystem/go-grpc-middleware/v2/interceptors/logging"
)

func NewGRPCServer(logger *zap.Logger) *grpc.Server {
    return grpc.NewServer(
        grpc.ChainUnaryInterceptor(
            recovery.UnaryServerInterceptor(),           // 1. Panic 回復（最外層）
            otelgrpc.UnaryServerInterceptor(),           // 2. OpenTelemetry tracing
            logging.UnaryServerInterceptor(
                InterceptorLogger(logger),               // 3. 結構化日誌
            ),
            authInterceptor.Unary(),                     // 4. 認證
            validationInterceptor(),                     // 5. 驗證
        ),
        grpc.ChainStreamInterceptor(
            recovery.StreamServerInterceptor(),
            otelgrpc.StreamServerInterceptor(),
            logging.StreamServerInterceptor(
                InterceptorLogger(logger),
            ),
            authInterceptor.Stream(),
        ),
    )
}
```

### 自訂 Interceptor 範例

```go
// 驗證 Interceptor
func validationInterceptor() grpc.UnaryServerInterceptor {
    return func(
        ctx context.Context,
        req interface{},
        info *grpc.UnaryServerInfo,
        handler grpc.UnaryHandler,
    ) (interface{}, error) {
        // 檢查請求是否實作 Validator 介面
        if v, ok := req.(interface{ Validate() error }); ok {
            if err := v.Validate(); err != nil {
                return nil, status.Errorf(codes.InvalidArgument, "validation failed: %v", err)
            }
        }
        return handler(ctx, req)
    }
}
```

---

## 健康檢查

### 必須實作 gRPC Health Checking Protocol

**參照**：[gRPC Health Checking Protocol](https://github.com/grpc/grpc/blob/master/doc/health-checking.md)

**實作步驟**：

1. **安裝套件**：
   ```bash
   go get google.golang.org/grpc/health
   go get google.golang.org/grpc/health/grpc_health_v1
   ```

2. **註冊健康檢查服務**：
   ```go
   import (
       "google.golang.org/grpc/health"
       "google.golang.org/grpc/health/grpc_health_v1"
   )

   func main() {
       grpcServer := grpc.NewServer()

       // 註冊業務服務
       pb.RegisterMyServiceServer(grpcServer, &myServiceImpl{})

       // 註冊健康檢查服務
       healthServer := health.NewServer()
       grpc_health_v1.RegisterHealthServer(grpcServer, healthServer)

       // 設定服務狀態
       healthServer.SetServingStatus("myservice.MyService", grpc_health_v1.HealthCheckResponse_SERVING)

       // ...啟動 server
   }
   ```

3. **Kubernetes 整合（使用 grpc_health_probe）**：
   ```yaml
   # deployment.yaml
   livenessProbe:
     exec:
       command: ["/bin/grpc_health_probe", "-addr=:9090"]
     initialDelaySeconds: 10
     periodSeconds: 10

   readinessProbe:
     exec:
       command: ["/bin/grpc_health_probe", "-addr=:9090"]
     initialDelaySeconds: 5
     periodSeconds: 5
   ```

---

## Deadline 與 Context

### Server 端必須尊重 Client 傳入的 Deadline

**原則**：
- Server 端必須尊重 client 傳入的 deadline
- 長時間操作需定期檢查 `ctx.Done()`
- **禁止**忽略 context cancellation

**範例**：
```go
func (s *MyServiceServer) LongRunningTask(ctx context.Context, req *pb.Request) (*pb.Response, error) {
    // 檢查 deadline
    deadline, ok := ctx.Deadline()
    if ok {
        timeout := time.Until(deadline)
        if timeout < 100*time.Millisecond {
            return nil, status.Error(codes.DeadlineExceeded, "insufficient time to process")
        }
    }

    // 長時間操作需定期檢查 ctx.Done()
    for i := 0; i < 1000; i++ {
        select {
        case <-ctx.Done():
            return nil, status.FromContextError(ctx.Err()).Err()
        default:
            // 執行工作
            processChunk(i)
        }
    }

    return &pb.Response{}, nil
}
```

### Client 端設定 Deadline

```go
// 建議：為每個請求設定明確的 deadline
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()

resp, err := client.MyMethod(ctx, &pb.Request{})
if err != nil {
    if status.Code(err) == codes.DeadlineExceeded {
        log.Printf("request timeout")
    }
    return err
}
```

---

## 錯誤代碼對應

### Domain Error 到 gRPC Status 的映射

| Domain Error | gRPC Status | 描述 |
|--------------|-------------|------|
| `NotFound` | `codes.NotFound` | 資源不存在 |
| `ValidationError` | `codes.InvalidArgument` | 請求參數無效 |
| `Unauthorized` | `codes.Unauthenticated` | 未認證 |
| `Forbidden` | `codes.PermissionDenied` | 無權限 |
| `Conflict` | `codes.AlreadyExists` | 資源已存在 |
| `Internal` | `codes.Internal` | 內部錯誤 |
| `Timeout` | `codes.DeadlineExceeded` | 逾時 |
| `Unavailable` | `codes.Unavailable` | 服務不可用 |

### 錯誤轉換範例

```go
import (
    "google.golang.org/grpc/codes"
    "google.golang.org/grpc/status"
)

// 將 Domain Error 轉換為 gRPC Status
func toGRPCError(err error) error {
    switch {
    case errors.Is(err, domain.ErrNotFound):
        return status.Error(codes.NotFound, err.Error())
    case errors.Is(err, domain.ErrValidation):
        return status.Error(codes.InvalidArgument, err.Error())
    case errors.Is(err, domain.ErrUnauthorized):
        return status.Error(codes.Unauthenticated, err.Error())
    case errors.Is(err, domain.ErrForbidden):
        return status.Error(codes.PermissionDenied, err.Error())
    case errors.Is(err, domain.ErrConflict):
        return status.Error(codes.AlreadyExists, err.Error())
    default:
        return status.Error(codes.Internal, "internal server error")
    }
}

// 使用範例
func (s *MyServiceServer) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.User, error) {
    user, err := s.userRepo.FindByID(ctx, req.GetUserId())
    if err != nil {
        return nil, toGRPCError(err)
    }
    return toProtoUser(user), nil
}
```

---

## GracefulStop 範例

> **詳細優雅關機流程請參閱 `go-graceful-shutdown` Skill**

```go
import (
    "os"
    "os/signal"
    "syscall"
    "time"
)

func runGRPCServer(grpcServer *grpc.Server, lis net.Listener, logger *zap.Logger) error {
    // 1. 訊號監聽
    ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer stop()

    // 2. Server goroutine
    srvErr := make(chan error, 1)
    go func() {
        if err := grpcServer.Serve(lis); err != nil {
            srvErr <- err
        }
        close(srvErr)
    }()

    // 3. 等待訊號或錯誤
    select {
    case <-ctx.Done():
        logger.Info("received shutdown signal")
    case err := <-srvErr:
        if err != nil {
            logger.Error("grpc server error", zap.Error(err))
            return err
        }
    }

    // 4. Graceful Stop（等待進行中的請求完成）
    stopped := make(chan struct{})
    go func() {
        grpcServer.GracefulStop()  // 阻塞直到所有請求完成
        close(stopped)
    }()

    // 5. 等待 GracefulStop 或 timeout
    shutdownTimeout := 30 * time.Second
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

## Client 開發最佳實務

### Connection Pool 重用

```go
// ✅ 正確：重用 gRPC Connection
type MyClient struct {
    conn   *grpc.ClientConn
    client pb.MyServiceClient
}

func NewMyClient(target string) (*MyClient, error) {
    conn, err := grpc.Dial(
        target,
        grpc.WithTransportCredentials(insecure.NewCredentials()),
        grpc.WithDefaultCallOptions(
            grpc.MaxCallRecvMsgSize(10<<20), // 10MB
        ),
    )
    if err != nil {
        return nil, fmt.Errorf("dial: %w", err)
    }

    return &MyClient{
        conn:   conn,
        client: pb.NewMyServiceClient(conn),
    }, nil
}

func (c *MyClient) Close() error {
    return c.conn.Close()
}
```

### Retry 策略

```go
import (
    "google.golang.org/grpc/codes"
    "google.golang.org/grpc/status"
)

// 可重試的錯誤碼
func isRetryable(err error) bool {
    st, ok := status.FromError(err)
    if !ok {
        return false
    }

    switch st.Code() {
    case codes.Unavailable, codes.DeadlineExceeded, codes.ResourceExhausted:
        return true
    default:
        return false
    }
}

// Retry 包裝器
func retryableCall(ctx context.Context, fn func() error) error {
    maxRetries := 3
    backoff := 100 * time.Millisecond

    for i := 0; i < maxRetries; i++ {
        err := fn()
        if err == nil {
            return nil
        }

        if !isRetryable(err) {
            return err
        }

        if i < maxRetries-1 {
            select {
            case <-time.After(backoff):
                backoff *= 2  // Exponential backoff
            case <-ctx.Done():
                return ctx.Err()
            }
        }
    }

    return fmt.Errorf("max retries exceeded")
}
```

---

## 檢查清單

**Proto 定義**
- [ ] 使用 Buf 管理 linting 與 breaking changes
- [ ] 訊息欄位使用 snake_case
- [ ] 服務方法使用 PascalCase
- [ ] 產生的程式碼放入 `api/gen/go/`

**Server 實作**
- [ ] 實作 gRPC Health Checking Protocol
- [ ] 配置 Interceptor（Recovery、Tracing、Logging、Auth）
- [ ] 長時間操作檢查 `ctx.Done()`
- [ ] Domain Error 轉換為正確的 gRPC Status Code
- [ ] 實作 GracefulStop

**Client 實作**
- [ ] 重用 gRPC Connection
- [ ] 為每個請求設定 Deadline
- [ ] 實作 Retry 策略（僅限可重試錯誤）
- [ ] 正確處理 `conn.Close()`

**Kubernetes 部署**
- [ ] 配置 `livenessProbe` 使用 `grpc_health_probe`
- [ ] 配置 `readinessProbe`
- [ ] `terminationGracePeriodSeconds` ≥ GracefulStop timeout + buffer
