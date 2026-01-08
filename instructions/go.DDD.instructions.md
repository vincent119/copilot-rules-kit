---
description: 'Go 開發與 Copilot/Agent 產生規範指引（整合 Uber Go Style Guide）'
applyTo: "**/*.go,**/go.mod,**/go.sum"
---

# Go 開發與 Copilot / Agent 指南（整合 Uber Guide 版本）

本檔延伸自 `.github/standards/copilot-common.md` 與 `.github/standards/copilot-vocabulary.yaml`，
並 **參照**：

- [Uber Go 風格指南（繁體中文維護版）](https://github.com/ianchen0119/uber_go_guide_tw)
- [Effective Go（官方）](https://go.dev/doc/effective_go#introduction)
- Go 版本目標：**Go 1.25+**（如需更動版本，PR 必述影響）
- Go 版本策略：跟隨 Go 官方 stable（半年一版），升版前需完成 CI、-race、關鍵路徑壓測與相容性驗證。

> 目標：統一格式、用詞與安全實務，確保自動產生或人工撰寫的程式碼皆符合 idiomatic Go，並可直接編譯、部署與維護。

---
## 目錄
- [Copilot / Agent 產生守則](#copilot--agent-產生守則)
- [Go 一般開發規範](#go-一般開發規範整合-uber--effective-go)
- [Domain Events](#domain-events領域事件)
- [優雅關機](#優雅關機graceful-shutdown)
- [目錄結構](#目錄結構)
- [CI 與工具建議](#ci-與工具建議可直接採用)


## Copilot / Agent 產生守則

### 檔案與 package 規範
- 每檔僅 **一行** `package <name>` 宣告（置頂）。
  - 編輯檔案：保留原 package。
  - 新檔案：與資料夾既有 `.go` 同名 package。
- 可執行程式置於 `cmd/<app>/main.go`，library 不得含 `main()`。
- package 名稱：**全小寫、單字、無底線**（Uber）。

### Imports 與工具
- 產出前必可通過 `gofmt -s`（建議 `gofumpt`）、`goimports`、`go vet`。
- 自動清除未用 imports，避免循環依賴。
- 變更 `go.mod` 後提示 `go mod tidy`。
- 縮排：Tab；檔尾留 **單一** 換行；UTF-8（無 BOM）。
- Imports 排序：**標準庫 → 第三方 → 專案內部**；群組以空行分隔。

### 錯誤處理與流程
- 呼叫後**立即**檢查 `err`，採 **early return**。
- 包裝錯誤：`fmt.Errorf("context: %w", err)`；跨層使用 `errors.Is/As`。
- 多重錯誤聚合使用 `errors.Join`（如：驗證列表或 defer Close）。
- 訊息小寫開頭，尾端**不加標點**。
- 僅在**不可恢復初始化**時用 `panic`；避免在 library 使用。
- 禁止「只記錄不回傳」導致錯誤吞沒；**記錄與回傳擇一**，以邏輯層級決定。

### 函式設計
- 函式應該簡短且專注於單一任務（建議不超過 50 行）
- 參數數量盡量控制在 3-4 個以內
- 使用具名回傳值提高可讀性（但避免 naked return）
- `context.Context` 應該作為第一個參數
- `error` 應該作為最後一個回傳值
- 避免 `bool` 參數（改用具名 Option 或拆分函式）
- 多參數時採用 **Functional Options Pattern**（`opts ...Option`）提升擴展性

```go
// ✅ 正確：context 第一、error 最後、使用 Functional Options
func ProcessData(ctx context.Context, data []byte, opts ...Option) (Result, error)

// ✅ Functional Options Pattern 範例
type Option func(*config)

func WithTimeout(d time.Duration) Option {
    return func(c *config) { c.timeout = d }
}

func WithRetries(n int) Option {
    return func(c *config) { c.retries = n }
}

// ❌ 錯誤：bool 參數、context 不在第一個
func ProcessData(data []byte, timeout int, retries int, debug bool, ctx context.Context) (Result, error)
```

### 並行與 I/O 安全 區塊
- 每個 goroutine 需有**退出機制**（`context`、`WaitGroup` 或關閉 channel）。
- Channel 緩衝預設 0 或 1（除非有量測證據）。
- 嚴禁 goroutine 泄漏；資源關閉要落在呼叫點 `defer Close()`。
- 不可重用已讀取的 `req.Body`；需 **clone**：
  ```go
  // 將來源位元組切片拷貝，確保可重播 Body
  buf := bytes.Clone(src)
  req.Body = io.NopCloser(bytes.NewReader(buf))
  req.GetBody = func() (io.ReadCloser, error) {
      return io.NopCloser(bytes.NewReader(buf)), nil
  }
  ```
- `io.Pipe`/multipart 必須**單執行緒順序寫入**；失敗用 `pw.CloseWithError(err)`、成功 `mw.Close()` 再 `pw.Close()`。
- 底層 slice/map 在**邊界（入/出）**時一律複製，避免別名共享。

### HTTP Client 設計
- `Client` 僅存設定（BaseURL、`*http.Client`、headers）；**不得**保存 `*http.Request` 或可變請求狀態。
- 方法介面：
  - 皆接收 `context.Context`。
  - 內部建 `http.Request` → `c.httpClient.Do(req)` → `defer resp.Body.Close()`。
  - 要求**逾時/重試/回退**策略明確，並遵循「Net/HTTP 實務」章節。

### JSON / Struct Tag
- 對外型別欄位加上 `json,yaml,mapstructure` tags；**選填**欄位 `omitempty`。
- 輸入端（decode）預設**拒絕未知欄位**：
  ```go
  dec := json.NewDecoder(r)
  dec.DisallowUnknownFields()
  ```
- 使用 `any` 取代 `interface{}`；但優先具體型別。
- 時間欄位採 **RFC3339**（UTC 優先）；必要時標注本地時區偏差。

### 測試與範例
- 採 **table-driven tests**；子測試用 `t.Run`。
- 使用 `t.Context()` 獲取自動管理的 context （Go 1.24+；本專案目標 Go 1.25+ 故可直接採用）。
- 輔助函式 `t.Helper()`；清理用 `t.Cleanup()`。
- 匯出 API 提供 `example_test.go`。
- 優先標準 `testing`；除非必要不引入 assert 套件。
- **Mocking 策略**：使用 `uber-go/mock` (原 gomock) 針對 interface 生成 mock，統一置於 `internal/mocks` 或同層 `mocks` 套件。
- 需通過：`-race`、單元涵蓋率門檻（預設 80% 可調整；變更需 PR 說明）。
- 提供**基準**與**模糊測試（fuzz）**於關鍵路徑。

### 產出內容要求
- 輸出 **完整可編譯檔案**或明確 **diff**。
- 多檔變更列出：檔名 / 變更摘要 / 風險。
- 新增外部套件需附：`go get <module>@<version>` 與風險評估。

### 詞彙與術語
- 優先 `.github/standards/copilot-vocabulary.yaml`。
- 與現有命名衝突時以 vocabulary 為準。
- 與 Uber/Effective Go 不一致時，PR **必述理由**與替代方案。

---

## Go 一般開發規範（整合 Uber + Effective Go）

### 通用原則
- 清晰優於巧妙；主流程靠左排列；讓 **零值可用**。
- 結構自我說明；註解描述「**為何**」而非「做什麼」。

### 命名慣例
- package：全小寫、單字、無底線；避免 `util`、`common`。
- 變數/函式：小駝峰；匯出名稱首字母大寫。
- 介面以 `-er` 結尾（Reader/Writer）；**小介面**優先。
- 縮略詞大小寫一致：`HTTPServer`、`URLParser`。
- 建構子命名採 `NewType(...)`；必要時 `WithXxx` 選項，但避免過度抽象。
- 常數使用駝峰式（匯出：`MaxRetryCount`；私有：`maxRetryCount`），**禁用全大寫底線**。

### 常數與列舉
- 群組 `const (...)`；**型別化常數**避免魔數。
- Enum 起始值**考慮零值可用性**，必要時保留 `Unknown`。

### 接收者與方法
- 以量測決定**指標/值**接收者（大型結構/需變異 → 指標；小值/不變 → 值）。
- 避免 `init()` 副作用與全域可變狀態。
- 針對可能回傳大量數據的列表方法，優先使用 **Iterators** (`func(yield func(T) bool)`) (Go 1.23+) 取代 Slice 回傳。

```go
// Iterator 範例：避免一次載入全部資料
func (s *Set[T]) Iterator() iter.Seq[T] {
    return func(yield func(T) bool) {
        for _, v := range s.values {
            if !yield(v) {
                return
            }
        }
    }
}
```

### `context` 規範
- 對外 API **第一個參數**為 `ctx context.Context`。
- 禁用 `context.Background()` 直傳至深層；由呼叫者注入。
- 設定逾時/截止於**呼叫邊界**；尊重 `ctx.Done()`。
- 不將 `ctx` 保存於結構體。

### 並行進階
- 以 `errgroup`/`WaitGroup` + `ctx` 收斂；提供**背壓**與**取消**。
- 共享狀態以 `sync.Mutex/RWMutex` 或無鎖結構（經量測）保護。

### Domain Events（領域事件）

#### 定義規範
- Event 為**不可變 struct**，包含：
  - `EventID`：事件唯一識別碼（UUID）
  - `OccurredAt`：事件發生時間（UTC, RFC3339）
  - `AggregateID`：所屬聚合根 ID
  - `EventType`：事件類型字串（格式：`<Aggregate>.<PastTenseVerb>`）
- 事件命名使用**過去式動詞**：`OrderCreated`、`PaymentCompleted`、`UserEmailChanged`

#### 事件結構範例
```go
// DomainEvent 為所有領域事件的基底結構
type DomainEvent struct {
    EventID     string    `json:"eventId"`
    EventType   string    `json:"eventType"`
    AggregateID string    `json:"aggregateId"`
    OccurredAt  time.Time `json:"occurredAt"`
}

// OrderCreated 訂單建立事件
type OrderCreated struct {
    DomainEvent
    CustomerID string  `json:"customerId"`
    TotalAmount float64 `json:"totalAmount"`
}
```

#### 發布模式
| 模式 | 適用場景 | 實作方式 |
|------|----------|----------|
| 同步 | 同一 Bounded Context 內 | Aggregate Root 回傳 `[]DomainEvent` |
| 非同步 | 跨 BC / 外部系統 | Message Queue（NATS、Kafka、RabbitMQ） |

#### Outbox Pattern（推薦）
- **目的**：確保事件與狀態在同一交易中一致
- **流程**：
  1. 業務操作與事件寫入 `outbox` 表於同一 DB Transaction
  2. 背景 Worker 輪詢 `outbox` 表並發佈至 Message Queue
  3. 發佈成功後標記或刪除該筆紀錄
- **優點**：避免分散式交易，保證最終一致性

#### 冪等處理
- Consumer **必須**處理重複事件（網路重試、At-Least-Once 語意）
- 使用 `EventID` 進行去重，可搭配 Redis SET 或資料庫唯一約束
- 設計事件處理邏輯時，確保多次執行結果一致

### 優雅關機（Graceful Shutdown）

- 所有 server、background worker、consumer **必須實作優雅關機**。
- 必須監聽 `SIGINT`、`SIGTERM`，並轉換為 `context.Context` 的取消事件。
- 關機時流程必須遵循以下順序：

  1. 接收系統訊號（`signal.NotifyContext`）
  2. 停止接受新請求（HTTP Server `Shutdown` / gRPC `GracefulStop`）
  3. 等待進行中的請求或任務完成
  4. 在 timeout 到期後強制結束
  5. 關閉所有外部資源（DB、Cache、Queue、Tracer）

- 所有 goroutine 必須能回應 `ctx.Done()` 並自行結束。
- 不得在 goroutine 中忽略取消訊號造成關機卡死。
- 禁止在正常關機流程中使用 `os.Exit()`。
- Kubernetes 環境需搭配 `terminationGracePeriodSeconds` 與 `preStop` hook，
  確保應用層 Shutdown timeout 與 Pod 終止行為一致。
- background worker / queue consumer 必須在收到 ctx.Done() 後停止拉取新任務，
  並完成當前任務或在 timeout 後中止。
- 長時間服務建議提供關機路徑測試（模擬 ctx cancel / SIGTERM）。
- 禁止在 server goroutine 使用 `log.Fatal` / `zlogger.Fatal`（會跳過 defer 與資源收尾）；改為回傳錯誤到 srvErr，由主流程統一處理。
- Shutdown timeout 必須與部署環境一致：
  - Kubernetes：`terminationGracePeriodSeconds >= shutdownTimeout + buffer`（建議 buffer 5~10 秒）。
  - 關機順序固定：Stop accept → Drain → Stop workers/consumers → Close external resources。
- 關機路徑必須可測：至少提供一個「可注入 cancel」的測試入口（例如把 `runHTTPServer` 做成可測函式）。

#### Kubernetes preStop hook 建議
```yaml
# 確保 Pod 從 Service Endpoints 移除後再開始 shutdown
lifecycle:
  preStop:
    exec:
      command: ["sleep", "5"]  # 等待從 endpoints 移除
```

#### HTTP Server 建議實作模式

> 需 Go 1.16+（`signal.NotifyContext`）；本專案目標 Go 1.25+ 故可直接採用。

```go
// 建議：以 signal.NotifyContext 將 OS 訊號轉為可取消的 context，並同時監控 server 異常退出。
// 特性：不論是 SIGTERM/SIGINT 或 ListenAndServe 異常，都會走同一條 graceful shutdown 流程。
func runHTTPServer(
	srv *http.Server,
	shutdownTimeout time.Duration,
	closeResources func(ctx context.Context) error, // 關閉 scheduler/redis/db 等資源（可為 nil）
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
		close(srvErr) // 關閉 channel 表示 server goroutine 已結束
	}()

	// 3) 等待：訊號 or server 異常
	select {
	case <-ctx.Done(): // 收到關機訊號
	case err := <-srvErr: // 服務異常退出
		if err != nil {
			logger.Error("http server stopped unexpectedly", zap.Error(err))
		}
	}

	// 4) 統一走 graceful shutdown：先停止接新請求，再收尾資源
	shutdownCtx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		// Shutdown 會等待 in-flight request，若卡住要有最後手段
		logger.Error("http server shutdown failed", zap.Error(err))
		_ = srv.Close() // 最後手段：避免卡住（可能中斷連線）
	}

	// 5) 關閉外部資源（scheduler/worker/redis/db...）
	// 注意：若底層 Close() 不吃 context，這裡的 ctx 僅用於「放棄等待」，不能真的中斷卡死的 Close。
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

> gRPC GracefulStop 範例請參見 [gRPC 規範章節](#grpc-規範)。

### Net/HTTP 實務
- **重用 Transport**，設定逾時：
  ```go
  tr := &http.Transport{
      MaxIdleConns:        100,
      IdleConnTimeout:     90 * time.Second,
      TLSHandshakeTimeout: 10 * time.Second,
      ExpectContinueTimeout: 1 * time.Second,
  }
  c := &http.Client{
      Transport: tr,
      Timeout:   15 * time.Second, // 全域上限；更細粒度以 context 控制
  }
  ```
- 明確重試策略（**僅**冪等方法），具退避與上限；對 5xx/網路錯誤重試，對業務 4xx 不重試。
- 嚴格 `resp.Body.Close()`；讀取前先檢 HTTP 狀態碼。

### API 設計規範

#### 統一 API 回應結構 (JSON Envelope)
```go
type APIResponse[T any] struct {
    Code    int    `json:"code"`              // 業務碼 (非 HTTP 狀態碼)
    Message string `json:"message"`           // 提示訊息
    Data    T      `json:"data,omitempty"`    // 泛型資料 payload
    TraceID string `json:"trace_id,omitempty"`
}
```

### API Versioning（版本管理）

#### 版本策略
- **URL Path 優先**：使用 `/v1/`, `/v2/` 作為版本前綴
- Header 版本（選用）：僅用於次要版本協商（如 `Accept: application/vnd.api.v1+json`）

#### API 文件 (Swagger)
- `main.go` 需定義全域資訊與驗證方式：
  ```go
  // @title           My API
  // @version         1.0
  // @securityDefinitions.apikey ApiKeyAuth
  // @in header
  // @name Authorization
  ```
- API Handler 需附上 Swagger 註解（`swag init` 生成）
  ```go
  // GetUser 取得使用者資訊
  // @Summary 取得使用者詳情
  // @Tags Users
  // @Produce json
  // @Param id path string true "User ID"
  // @Security ApiKeyAuth
  // @Success 200 {object} UserResponse
  // @Router /users/{id} [get]
  ```

#### 版本升級原則
| 變更類型 | 處理方式 |
|----------|----------|
| 新增欄位（向下相容） | 無需升版 |
| 移除/修改欄位 | Major version bump（`/v2/`） |
| 行為變更 | Major version bump |

#### 維護期規範
- 新 Major 版本上線後，舊版本**至少維護 6 個月**
- 棄用通知：回應 Header 加入 `Deprecation: true` 與 `Sunset: <date>`
- Swagger/OpenAPI 文件需標註各版本狀態（active/deprecated）

### gRPC 規範

#### Proto 檔案管理
- 統一放置於 `api/proto/<service>/`
- 使用 [buf](https://buf.build/) 管理 linting、breaking change detection
- 產生的程式碼放入 `api/gen/go/`（不手動編輯）

#### Interceptor 設計
```go
// 建議的 Interceptor 順序（由外至內）
grpc.ChainUnaryInterceptor(
    recovery.UnaryServerInterceptor(),      // Panic 回復
    otelgrpc.UnaryServerInterceptor(),      // OpenTelemetry tracing
    logging.UnaryServerInterceptor(logger), // 結構化日誌
    auth.UnaryServerInterceptor(),          // 認證
)
```

#### 健康檢查
- **必須**實作 [gRPC Health Checking Protocol](https://github.com/grpc/grpc/blob/master/doc/health-checking.md)
- 搭配 Kubernetes liveness/readiness probes 使用 `grpc_health_probe`

#### Deadline 與 Context
- Server 端必須尊重 client 傳入的 deadline
- 長時間操作需定期檢查 `ctx.Done()`
- 禁止忽略 context cancellation

#### 錯誤代碼對應
| Domain Error | gRPC Status |
|--------------|-------------|
| NotFound | `codes.NotFound` |
| ValidationError | `codes.InvalidArgument` |
| Unauthorized | `codes.Unauthenticated` |
| Forbidden | `codes.PermissionDenied` |
| Conflict | `codes.AlreadyExists` |
| Internal | `codes.Internal` |

#### GracefulStop 範例
```go
// 收到關機訊號後
grpcServer.GracefulStop() // 等待進行中請求完成
// 若超時則強制停止
// grpcServer.Stop()
```

### 日誌與可觀測性
- 使用**結構化日誌**（如 `zap`）；固定欄位：`trace_id`, `span_id`, `req_id`, `subsystem`。
- `logger.Error("msg", zap.Error(err))` 報告；避免把錯誤訊息再字串化拼接。
- 指標/追蹤採 OpenTelemetry；HTTP/DB 客戶端優先用已 instrument 的實作。
- **Context 傳遞**：所有跨函式呼叫（特別是跨邊界的 DB/HTTP 呼叫）必須傳遞 `ctx`，以確保 Trace ID 能正確串接。

#### Prometheus Metrics 規範
- **核心原則**：
  - **Counter**：**僅能增長 (Increment)**，不可減少。適用於：請求總數、錯誤總數、任務完成次數。
  - **Gauge**：可增減。適用於：當前記憶體用量、Goroutine 數量、Queue 長度。
  - **Histogram**：數值分佈統計。適用於：請求延遲 (Latency)、Payload 大小。
- **命名慣例**：
  - 使用蛇形命名法 (Snake Case)：`http_requests_total`
  - **必須**包含單位後綴：`_seconds` (延遲), `_bytes` (大小), `_total` (計數)
- **Label 規範**：
  - **禁止**高基數 (High Cardinality) 值（如 `user_id`, `email`, `trace_id`），避免搞垮 Prometheus。
  - 必備 Label：`service` (服務名), `env` (環境), `code` (錯誤碼/狀態碼)。
- **程式碼範例**：
  ```go
  // Counter: 僅能 Inc
  requestsTotal.WithLabelValues("200", "GET").Inc()

  // Histogram: 觀測耗時
  timer := prometheus.NewTimer(requestDuration)
  defer timer.ObserveDuration()
  ```

### 時間與時區
- **內部以 UTC 儲存與運算**；輸出呈現再格式化。
- JSON 時間使用 RFC3339（必要時 `time.RFC3339Nano`）。

### 安全性
- 僅用標準 `crypto/*`；禁自製密碼學。
- 外部輸入需驗證與長度限制；避免正則 ReDoS。
- 檔案 I/O 使用 `fs.FS` 與限制型讀取；防 Zip Slip。
- 納入 `gosec`（或等價 analyzer）於 CI；敏感資訊不得進日誌。

### 依賴與模組
- 模組遵循 **SemVer**；破壞性改動於 major path（`/v2`）。
- 嚴格釘版：`go.mod` 使用最小相依原則；避免 transitive 泄漏。
- 移除依賴需跑 `go mod tidy` 並附影響說明。

### Database Migration（資料庫遷移）

#### 工具選擇
- 推薦 [`golang-migrate/migrate`](https://github.com/golang-migrate/migrate) 或 [`pressly/goose`](https://github.com/pressly/goose)
- 選擇後**全專案統一**，禁止混用

#### 命名慣例
```
migrations/
├── 20260108120000_create_users_table.up.sql
├── 20260108120000_create_users_table.down.sql
├── 20260108130000_add_email_index.up.sql
└── 20260108130000_add_email_index.down.sql
```
- 格式：`YYYYMMDDHHMMSS_<description>.<up|down>.sql`
- 描述使用**蛇形命名法**（snake_case）

#### 版本控制
- Migration 檔案**必須**納入 Git
- **禁止**修改已執行的 migration（新增新檔案修正）
- 復原（down）**必須**與 up 對應，確保可回退

#### CI/CD 整合
- Migration 應在**應用啟動前**執行（init container 或 pre-deploy hook）
- 禁止在應用程式 `main()` 中執行 migration（避免多副本競爭）

#### 最佳實務
- 大型表變更使用 **pt-online-schema-change** 或 **gh-ost**（避免鎖表）
- 新增 NOT NULL 欄位需先加入預設值，再移除預設值

### 依賴注入 (Dependency Injection)
- **Infrastructure 層** (如 Database, Cache) 與 **Application 層** (Use Cases) 的依賴關係需透過 DI 容器組裝。
- 建議在 `cmd/` 或 `internal/<service>/di.go` 中統一管理依賴。
- **禁止**在業務邏輯層中手動 `New` 具體的 Infrastructure 實作。
- 本專案 DI 推薦 fx；若採 wire，需提供產生器與 CI 產生檔一致性規範（go generate / wire_gen.go）。

#### DI 測試情境

##### Interface 設計原則
- Repository / Service 皆以 **interface** 暴露；實作為 private struct
- interface 定義於 Domain 或 Application 層，實作於 Infra 層

##### Mock 生成
- 推薦 [`uber-go/mock`](https://github.com/uber-go/mock)（原 gomock）或 [`mockery`](https://github.com/vektra/mockery)
- 統一 Mock 檔案置於 `internal/mocks/` 或 `mocks/` 套件中
- **必須**使用 `go generate` 自動生成，指令範例：
  ```go
  //go:generate mockgen -source=repository.go -destination=../../mocks/repository_mock.go -package=mocks
  type Repository interface { ... }
  ```

##### 測試範例
```go
// 使用 mock 測試 UseCase
func TestCreateOrder(t *testing.T) {
    // Arrange
    mockRepo := mocks.NewMockOrderRepository(t)
    mockRepo.EXPECT().
        Save(mock.Anything, mock.AnythingOfType("*domain.Order")).
        Return(nil)

    uc := application.NewCreateOrderUseCase(mockRepo)

    // Act
    err := uc.Execute(t.Context(), input)

    // Assert
    require.NoError(t, err)
}
```

##### fx 測試模式
```go
func TestIntegration(t *testing.T) {
    app := fxtest.New(t,
        fx.Provide(NewTestDB),       // 測試用 DB
        fx.Provide(NewOrderRepo),
        fx.Provide(NewCreateOrderUseCase),
        fx.Invoke(func(uc *CreateOrderUseCase) {
            // 執行測試
        }),
    )
    app.RequireStart()
    defer app.RequireStop()
}
```

### Configuration（設定管理）

#### 優先順序（由高至低）
1. **環境變數**（`APP_DATABASE_HOST`）
2. **設定檔**（`config.yaml`）
3. **預設值**（程式碼內建）

#### 結構化配置範例
```go
type Config struct {
    Server   ServerConfig   `mapstructure:"server"`
    Database DatabaseConfig `mapstructure:"database"`
    Redis    RedisConfig    `mapstructure:"redis"`
}

func LoadConfig() (*Config, error) {
    viper.SetConfigName("config")
    viper.AddConfigPath("./configs")
    viper.AutomaticEnv()
    viper.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))

    if err := viper.ReadInConfig(); err != nil {
        return nil, fmt.Errorf("read config: %w", err)
    }

    var cfg Config
    if err := viper.Unmarshal(&cfg); err != nil {
        return nil, fmt.Errorf("unmarshal config: %w", err)
    }
    return &cfg, nil
}
```

#### 敏感資訊處理
- **禁止**將 secrets（密碼、API Key）放入設定檔或程式碼
- 使用環境變數或外部 Secret Manager：
  - HashiCorp Vault
  - Infisical
  - Kubernetes Secrets（搭配 External Secrets Operator）

#### 啟動驗證
- 必要設定缺失時，應於啟動階段 `log.Fatal` 終止
- 使用 `validator` 套件驗證結構欄位

#### 範例檔案
- 提供 `config.sample.yaml`（不含真實資料）
- `.env.example` 列出所有環境變數與說明

### 目錄結構
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
│   └── pkg/                   # 【Shared Kernel】跨 Bounded Context 的共用領域抽象（例：Money、DomainError
│                              # 僅限「跨 Bounded Context 皆成立」的抽象
│                              # 禁止放入特定 service 的規則或流程
├── pkg/                       # 【通用工具】uuid, retry, stringutils (完全不含業務邏輯)
├── migrations/                # Database Migration 檔案（詳見 Migration 規範）
├── scripts/                   # 腳本：DB Migration, Makefile 輔助腳本
├── deployments/               # Kubernetes、Helm Chart 與部署相關檔案
│   ├── helm/                  # Helm charts
│   └── kustomization/         # Kustomize overlays
├── docs/                      # swagger.yaml, 架構設計文件
├── documents/                 # 專案文件
│   ├──  en/                   # 專案相關文件（需求規格、設計文件、SOP）
│   └──  zh/                   # 專案相關文件（需求規格、設計文件、SOP）
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

### 架構總覽（Architecture Overview）

#### 本專案採用 領域驅動設計（Domain-Driven Design, DDD） 作為核心架構方法，並僅在最外層以 MVC 作為介面實作模式，兩者責任邊界清楚、互不混用。
- 每一項業務能力皆建模為一個獨立的 限界上下文（Bounded Context），並置於 internal/<service>/ 目錄下。
- 業務規則集中於 領域層（Domain Layer），與任何框架或基礎設施實作完全解耦。
- MVC 僅應用於 交付層（Delivery Layer），用於處理對外介面（HTTP / gRPC）。
- 基礎設施相關關注點（資料庫、快取、日誌等）皆透過 依賴注入（Dependency Injection） 進行解耦與提供。
- MVC 僅作為 Delivery Layer 的實作模式之一，不構成系統核心架構。

#### 此架構能確保系統具備長期可維護性、可測試性，並可在不破壞核心業務模型的前提下，平順演進自單體架構至微服務架構。

### Shared Kernel（共用核心）使用規範

> Shared Kernel 位於 `internal/pkg/`，存放跨 Bounded Context 通用的領域抽象。

#### ✅ 適合放入的內容
| 類型 | 範例 |
|------|------|
| Value Objects | `Money`, `Email`, `PhoneNumber`, `Address` |
| Domain Error | `DomainError`, `ValidationError`, `NotFoundError` |
| 通用介面 | `Clock`, `UUIDGenerator`（用於測試注入） |
| 規格抽象 | `Specification<T>` pattern 基底 |

#### ❌ 禁止放入的內容
| 類型 | 原因 |
|------|------|
| 特定 BC 的 Entity/Aggregate | 造成 BC 間耦合 |
| 業務流程編排（Use Case） | 違反 BC 邊界獨立性 |
| 框架耦合的實作（如 GORM Model） | 應放 Infra 層 |
| 可變狀態或 Singleton | 難以測試與併行安全 |

#### 變更流程
1. 修改 Shared Kernel 需所有**相依 BC 負責人同意**
2. 變更需附**影響範圍分析**（列出受影響的 BC）
3. **向下相容**變更可直接合併；破壞性變更需升版並遷移計畫

#### 設計原則
- **最小化**：只放真正跨 BC 通用的抽象
- **不可變**：Value Objects 設計為 immutable
- **無副作用**：Shared Kernel 內的邏輯不應有 I/O 或外部依賴

### 設定檔與環境變數
- 使用 `spf13/viper` 管理設定。
- **優先級**：環境變數 (ENV) > 設定檔 (yaml/json) > 預設值。
- 結構定義範例：
  ```go
  type Config struct {
      Server   ServerConfig   `mapstructure:"server"`
      Database DatabaseConfig `mapstructure:"database"`
  }
  ```

### 產生器與 build
- 使用 `//go:build` 標籤管理條件編譯；禁止舊 `+build` 註解。
- 建議使用 **Config/Env** 控制環境行為（12-Factor App 原則），避免 build tags 導致 binary 不一致：
  - 開發環境：開啟詳細錯誤堆疊、Swagger UI（透過 `APP_ENV=dev`）
  - 生產環境：僅輸出 JSON 日誌、關閉 Debug 路由（透過 `APP_ENV=prod`）
- `go generate` 指令須在檔頭註解，並可重複執行（可重入）。
- CGO 預設關閉；開啟需 PR 說明平台/效能/部署影響。

---

## Copilot / Agent 提示模板（Do/Don't）

**Do**
- 僅產生一個 `package` 宣告；imports 分群。
- 立即檢查 `err`，使用 `%w` 包裝。
- 所有公開 API 第一參數 `context.Context`。
- 在邊界複製 slice/map；為 struct 加 `json`/`yaml` tags。
- 撰寫 table-driven 測試 + `t.Helper()`，並加入一個基準測試。
- 撰寫 table-driven 測試 + `t.Helper()`，並加入一個基準測試。

**Don’t**
- 不要保存 `context.Context` 或 `*http.Request` 於 struct。
- 不要在 library 使用 `panic`；不要忽略 `Close()`。
- 不要以 `interface{}` 取代具體型別；不要暴露可變 slice/map。
- 不要在長迴圈內直接 `defer` 造成延後釋放與資源累積；必要時以匿名函式縮小 scope，或顯式 `Close()`。

---

## 實作範例片段

> 具體展示關鍵規則如何落地。

```go
// Package client 提供與遠端服務互動的 HTTP 用戶端。
// 零值不可用，請使用 New 建構子建立。
package client

import (
	"context"          // 佈線取消與逾時的標準機制
	"encoding/json"    // 編解碼輸入/輸出
	"errors"           // 錯誤比對
	"fmt"              // 錯誤包裝與格式化
	"io"               // I/O 介面
	"net/http"         // HTTP 基礎
	"time"             // 逾時與回退間隔
)

// ErrNotFound：對應遠端 404 的語意錯誤（sentinel error）。
var ErrNotFound = errors.New("resource not found") // 小寫開頭，不加標點

// Client 僅保存不可變設定與共享 *http.Client；不保存請求狀態。
type Client struct {
	baseURL    string        // 基底位址（不可含尾斜線）
	httpClient *http.Client  // 可注入以便測試與重用 Transport
}

// New 建立可用的 Client；呼叫者可注入自定 *http.Client。
func New(baseURL string, hc *http.Client) *Client {
	if hc == nil {
		hc = &http.Client{Timeout: 15 * time.Second} // 安全預設
	}
	return &Client{baseURL: baseURL, httpClient: hc}
}

// Resource 對外輸出時含有 json 標籤，零值可用。
type Resource struct {
	ID        string    `json:"id"`
	Name      string    `json:"name,omitempty"`
	UpdatedAt time.Time `json:"updatedAt"` // RFC3339 UTC
}

// Get 透過 context 控制逾時/取消，正確關閉 Body 並轉換語意錯誤。
func (c *Client) Get(ctx context.Context, id string) (Resource, error) {
	var out Resource

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+"/v1/resources/"+id, nil)
	if err != nil {
		return out, fmt.Errorf("new request: %w", err)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return out, fmt.Errorf("do request: %w", err)
	}
	defer resp.Body.Close() // 確保釋放連線

	switch resp.StatusCode {
	case http.StatusOK:
		dec := json.NewDecoder(resp.Body)
		dec.DisallowUnknownFields()
		if err := dec.Decode(&out); err != nil {
			return out, fmt.Errorf("decode: %w", err)
		}
		return out, nil
	case http.StatusNotFound:
		// 將 HTTP 狀態轉換為語意錯誤
		io.Copy(io.Discard, resp.Body) // 盡量讀完以便連線重用
		return out, ErrNotFound
	default:
		b, _ := io.ReadAll(io.LimitReader(resp.Body, 64<<10)) // 限流保護
		return out, fmt.Errorf("unexpected status %d: %s", resp.StatusCode, string(b))
	}
}
```

---

## 常用套件堆疊 (Tech Stack)

### Web 框架
- `net/http` - 標準庫，適合簡單 API
- `github.com/gin-gonic/gin` - 高效能 Web 框架

### 資料庫
- `database/sql` - 標準 SQL 介面
- `github.com/jmoiron/sqlx` - SQL 擴充
- `gorm.io/gorm` - ORM 框架

### 工具類
- `github.com/spf13/cobra` - CLI 框架
- `github.com/spf13/viper` - 設定管理
- `github.com/vincent119/zlogger` - 高效能日誌
- `github.com/go-playground/validator` - Struct 驗證
- `go.uber.org/fx` - 依賴注入 (DI)
- `github.com/prometheus/client_golang` - Prometheus Metrics
- `github.com/redis/go-redis/v9` - Redis Client
- `github.com/vincent119/commons` - 常用工具庫
- `github.com/swaggo/swag` - Swagger 文件產生
- `uber-go/mock` - Mock 生成工具 (gomock)
- `shields.io` - 狀態徽章 (README 用)

---

## Review Checklist
- [ ] 僅一個 `package` 宣告（置頂）
- [ ] 通過 `gofmt -s` / `goimports` / `go vet`
- [ ] 無未使用 imports、無循環依賴
- [ ] `err` 立即檢查並以 `%w` 包裝；跨層以 `errors.Is/As`
- [ ] goroutine / channel 正確收斂；無泄漏
- [ ] I/O 操作安全（含 Close、Pipe、Body 重新可讀）
- [ ] JSON tag 一致、解碼拒絕未知欄位、零值可用
- [ ] 測試含 table-driven、-race、必要 fuzz/bench
- [ ] `go.mod` 依賴釘版；`go mod tidy` 後無不明變更
- [ ] Server/Worker 實作 Graceful Shutdown (監聽 SIGINT/SIGTERM)
- [ ] 使用依賴注入 (DI)，無業務層手動 `New` 實體
- [ ] 跨邊界呼叫有傳遞 `context` (Trace ID)
- [ ] DB Migration 透過版本化腳本管理 (無 AutoMigrate)
- [ ] Domain Event 定義為不可變 struct，包含 EventID 與 OccurredAt
- [ ] 與 Uber / Effective Go 一致或於 PR 註明偏離理由

---

## CI 與工具建議（可直接採用）

### `.gitignore`（建議）
```gitignore
# Go
*.exe
*.test
*.out
coverage.out
vendor/

# IDE
.idea/
.vscode/
*.swp

# 環境與敏感資訊
.env
*.local.yaml
```

### `Makefile`（節選）
```makefile
.PHONY: tidy lint test bench cover fmt vet swagger

tidy:
	go mod tidy

lint:
	golangci-lint run ./...

test:
	go test -race -count=1 ./...

bench:
	go test -run=NONE -bench=. -benchmem ./...

# 執行測試並顯示覆蓋率
cover:
	go test -cover ./...

# 產生覆蓋率報告（HTML）
cover-html:
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out

# 格式化程式碼
fmt:
	go fmt ./...

# 靜態分析
vet:
	go vet ./...

# 更新 Swagger 文檔
swagger:
	swag init -g cmd/main.go
```

#### 常用測試指令
```bash
# 執行特定測試
go test -run TestFunctionName ./path/to/package

# 執行特定 package 的所有測試
go test -v ./internal/order/...

# 執行測試並產生覆蓋率報告
go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out
```

### `.golangci.yml`（節選）
```yaml
run:
  timeout: 5m
linters:
  enable:
    - errcheck
    - gocritic
    - gofumpt
    - govet
    - ineffassign
    - staticcheck
    - unparam
    - prealloc
    - revive
    - gosec
linters-settings:
  gosec:
    excludes:
      - G404
  revive:
    ignore-generated-header: true
issues:
  exclude-use-default: false
```

### PR 模板要點
- 目的與背景（為何要改）
- 變更摘要（做了什麼）
- 風險與復原方案
- 測試證據（覆蓋率、基準、相容性）
- 偏離 Uber/Effective Go 的理由（若有）

---

**建議存放路徑：** `.github/instructions/go.DDD.instructions.md`
此設定將自動套用於所有 Go 檔案（`*.go`, `go.mod`, `go.sum`）。
