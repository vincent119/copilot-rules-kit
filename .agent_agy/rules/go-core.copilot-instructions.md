---

applyTo: "**/*.go,**/go.mod,**/go.sum"

---

# Go 核心開發規範（精簡版）

本檔僅包含**所有 Go 程式碼都需要的基礎規則**。進階主題（DDD、gRPC、Migration 等）已拆分為獨立 Skills，按需載入。

> **參照標準**：[Uber Go 風格指南](https://github.com/ianchen0119/uber_go_guide_tw) | [Effective Go](https://go.dev/doc/effective_go)
> **Go 版本目標**：Go 1.25+

---

## Copilot / Agent 產生守則

### 檔案與 Package 規範
- 每檔僅 **一行** `package <name>` 宣告（置頂）
  - 編輯檔案：保留原 package
  - 新檔案：與資料夾既有 `.go` 同名 package
- 可執行程式置於 `cmd/<app>/main.go`，library 不得含 `main()`
- Package 名稱：**全小寫、單字、無底線**（避免 `util`、`common`）

### Imports 與工具
- 產出前必可通過 `gofmt -s`（建議 `gofumpt`）、`goimports`、`go vet`
- 自動清除未用 imports，避免循環依賴
- 變更 `go.mod` 後提示 `go mod tidy`
- 縮排：Tab；檔尾留 **單一** 換行；UTF-8（無 BOM）
- Imports 排序：**標準庫 → 第三方 → 專案內部**；群組以空行分隔

### 錯誤處理與流程
- 呼叫後**立即**檢查 `err`，採 **early return**
- 包裝錯誤：`fmt.Errorf("context: %w", err)`；跨層使用 `errors.Is/As`
- 多重錯誤聚合使用 `errors.Join`（如：驗證列表或 defer Close）
- 訊息小寫開頭，尾端**不加標點**
- 僅在**不可恢復初始化**時用 `panic`；避免在 library 使用
- 禁止「只記錄不回傳」導致錯誤吞沒；**記錄與回傳擇一**，以邏輯層級決定

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

### 並行與 I/O 安全
- 每個 goroutine 需有**退出機制**（`context`、`WaitGroup` 或關閉 channel）
- Channel 緩衝預設 0 或 1（除非有量測證據）
- 嚴禁 goroutine 泄漏；資源關閉要落在呼叫點 `defer Close()`
- 不可重用已讀取的 `req.Body`；需 **clone**：
  ```go
  // 將來源位元組切片拷貝，確保可重播 Body
  buf := bytes.Clone(src)
  req.Body = io.NopCloser(bytes.NewReader(buf))
  req.GetBody = func() (io.ReadCloser, error) {
      return io.NopCloser(bytes.NewReader(buf)), nil
  }
  ```
- `io.Pipe`/multipart 必須**單執行緒順序寫入**；失敗用 `pw.CloseWithError(err)`、成功 `mw.Close()` 再 `pw.Close()`
- 底層 slice/map 在**邊界（入/出）**時一律複製，避免別名共享

### JSON / Struct Tag
- 對外型別欄位加上 `json,yaml,mapstructure` tags；**選填**欄位 `omitempty`
- 輸入端（decode）預設**拒絕未知欄位**：
  ```go
  dec := json.NewDecoder(r)
  dec.DisallowUnknownFields()
  ```
- 使用 `any` 取代 `interface{}`；但優先具體型別
- 時間欄位採 **RFC3339**（UTC 優先）；必要時標注本地時區偏差

### 測試基礎
- 採 **table-driven tests**；子測試用 `t.Run`
- 使用 `t.Context()` 獲取自動管理的 context（Go 1.24+；本專案目標 Go 1.25+ 故可直接採用）
- 輔助函式 `t.Helper()`；清理用 `t.Cleanup()`
- 匯出 API 提供 `example_test.go`
- 優先標準 `testing`；除非必要不引入 assert 套件

### 產出內容要求
- 輸出 **完整可編譯檔案**或明確 **diff**
- 多檔變更列出：檔名 / 變更摘要 / 風險
- 新增外部套件需附：`go get <module>@<version>` 與風險評估

### 詞彙與術語
- 優先 `.github/standards/copilot-vocabulary.yaml`
- 與現有命名衝突時以 vocabulary 為準
- 與 Uber/Effective Go 不一致時，PR **必述理由**與替代方案

---

## Go 一般開發規範

### 通用原則
- 清晰優於巧妙；主流程靠左排列；讓 **零值可用**
- 結構自我說明；註解描述「**為何**」而非「做什麼」

### 命名慣例
- Package：全小寫、單字、無底線；避免 `util`、`common`
- 變數/函式：小駝峰；匯出名稱首字母大寫
- 介面以 `-er` 結尾（Reader/Writer）；**小介面**優先
- 縮略詞大小寫一致：`HTTPServer`、`URLParser`
- 建構子命名採 `NewType(...)`；必要時 `WithXxx` 選項，但避免過度抽象
- 常數使用駝峰式（匯出：`MaxRetryCount`；私有：`maxRetryCount`），**禁用全大寫底線**

### 常數與列舉
- 群組 `const (...)`；**型別化常數**避免魔數
- Enum 起始值**考慮零值可用性**，必要時保留 `Unknown`

### 接收者與方法
- 以量測決定**指標/值**接收者（大型結構/需變異 → 指標；小值/不變 → 值）
- 避免 `init()` 副作用與全域可變狀態
- 針對可能回傳大量數據的列表方法，優先使用 **Iterators** (`func(yield func(T) bool)`) (Go 1.23+) 取代 Slice 回傳

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

### Context 規範
- 對外 API **第一個參數**為 `ctx context.Context`
- 禁用 `context.Background()` 直傳至深層；由呼叫者注入
- 設定逾時/截止於**呼叫邊界**；尊重 `ctx.Done()`
- 不將 `ctx` 保存於結構體

### 並行進階
- 以 `errgroup`/`WaitGroup` + `ctx` 收斂；提供**背壓**與**取消**
- 共享狀態以 `sync.Mutex/RWMutex` 或無鎖結構（經量測）保護

### 時間與時區
- **內部以 UTC 儲存與運算**；輸出呈現再格式化
- JSON 時間使用 RFC3339（必要時 `time.RFC3339Nano`）

### 安全性
- 僅用標準 `crypto/*`；禁自製密碼學
- 外部輸入需驗證與長度限制；避免正則 ReDoS
- 檔案 I/O 使用 `fs.FS` 與限制型讀取；防 Zip Slip
- 納入 `gosec`（或等價 analyzer）於 CI；敏感資訊不得進日誌

### 依賴與模組
- 模組遵循 **SemVer**；破壞性改動於 major path（`/v2`）
- 嚴格釘版：`go.mod` 使用最小相依原則；避免 transitive 泄漏
- 移除依賴需跑 `go mod tidy` 並附影響說明

### 設定檔與環境變數
- 使用 `spf13/viper` 管理設定
- **優先級**：環境變數 (ENV) > 設定檔 (yaml/json) > 預設值
- 結構定義範例：
  ```go
  type Config struct {
      Server   ServerConfig   `mapstructure:"server"`
      Database DatabaseConfig `mapstructure:"database"`
  }
  ```

### 產生器與 Build
- 使用 `//go:build` 標籤管理條件編譯；禁止舊 `+build` 註解
- 建議使用 **Config/Env** 控制環境行為（12-Factor App 原則），避免 build tags 導致 binary 不一致
- `go generate` 指令須在檔頭註解，並可重複執行（可重入）
- CGO 預設關閉；開啟需 PR 說明平台/效能/部署影響

---

## 常用套件堆疊

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

---

## Review Checklist（精簡版）

- [ ] 僅一個 `package` 宣告（置頂）
- [ ] 通過 `gofmt -s` / `goimports` / `go vet`
- [ ] 無未使用 imports、無循環依賴
- [ ] `err` 立即檢查並以 `%w` 包裝；跨層以 `errors.Is/As`
- [ ] Goroutine / channel 正確收斂；無泄漏
- [ ] I/O 操作安全（含 Close、Pipe、Body 重新可讀）
- [ ] JSON tag 一致、解碼拒絕未知欄位、零值可用
- [ ] 測試含 table-driven、-race
- [ ] `go.mod` 依賴釘版；`go mod tidy` 後無不明變更
- [ ] 與 Uber / Effective Go 一致或於 PR 註明偏離理由

---

## Copilot / Agent 提示模板（Do/Don't）

**Do**
- 僅產生一個 `package` 宣告；imports 分群
- 立即檢查 `err`，使用 `%w` 包裝
- 所有公開 API 第一參數 `context.Context`
- 在邊界複製 slice/map；為 struct 加 `json`/`yaml` tags
- 撰寫 table-driven 測試 + `t.Helper()`

**Don't**
- 不要保存 `context.Context` 或 `*http.Request` 於 struct
- 不要在 library 使用 `panic`；不要忽略 `Close()`
- 不要以 `interface{}` 取代具體型別；不要暴露可變 slice/map
- 不要在長迴圈內直接 `defer` 造成延後釋放與資源累積；必要時以匿名函式縮小 scope，或顯式 `Close()`

---

> **進階主題已拆分為獨立 Skills**
> DDD 架構 | gRPC 規範 | 進階測試 | Database Migration | 可觀測性 | 優雅關機 | HTTP 進階 | API 設計 | 依賴注入 | 設定管理 | CI 工具 | Domain Events | 實作範例
>
> 使用時 Copilot 會根據對話內容自動載入相關 Skill。
