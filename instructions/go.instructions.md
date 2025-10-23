---
description: 'Go 開發與 Copilot/Agent 產生規範指引'
applyTo: '**/*.go,**/go.mod,**/go.sum'
---

# Go 開發與 Copilot / Agent 指南

本檔延伸自 .github/standards/copilot-common.md 與 .github/standards/copilot-vocabulary.yaml，統一格式、安全與用詞規範。

本文件整合 **Go 語言最佳實踐** 與 **Copilot / VS Code Agent 產生守則**，
確保自動產生或人工撰寫的程式碼皆符合 idiomatic Go 標準，並可直接編譯使用。

---

## Copilot / Agent 產生守則

### 檔案與 package 規範
- **每個檔案只能有一行 `package <name>` 宣告**，嚴禁重複。
  - 編輯現有檔案 → 保留原本的 package。
  - 新增檔案 → 需與同資料夾中其他 `.go` 檔案相同的 package 名稱。
  - 取代整個檔案內容時，也只能有一行 package 宣告在最上方。
- 可執行程式放在 `cmd/<app>/main.go`，library 專案不得含 `main()`。

### Imports 與工具
- 程式碼需通過 `gofmt`、`goimports`。
- 自動清理未使用的 imports，避免循環依賴。
- 若模組有變更，應提示使用者執行 `go mod tidy`。
- 縮排規範：1 個 Tab = 2 空白；檔尾保留單一換行；UTF-8（無 BOM）。

### 錯誤處理與流程控制
- 呼叫後立即檢查 `err`，採用早回（early return）。
- 包裝錯誤使用 `fmt.Errorf("context: %w", err)`。
- 外層檢查錯誤使用 `errors.Is`、`errors.As`。
- 錯誤訊息以小寫開頭，不加標點。

### 並行與 I/O 安全
- 建立 goroutine 時需有明確退出機制，使用 `sync.WaitGroup` 或 channel。
- 避免 goroutine 泄漏，務必正確關閉資源。
- 不可重用已讀取的 `req.Body`，需重新建立：
  ```go
  buf := bytes.Clone(src)
  req.Body = io.NopCloser(bytes.NewReader(buf))
  req.GetBody = func() (io.ReadCloser, error) {
      return io.NopCloser(bytes.NewReader(buf)), nil
  }
  ```
- 使用 `io.Pipe` 或 multipart writer 時：
  - 必須依序寫入，不可並行。
  - 錯誤時用 `pw.CloseWithError(err)`；成功時 `mw.Close()` → `pw.Close()`。

### HTTP Client 設計
- Client 結構體僅存設定（BaseURL、`*http.Client`、headers）。
- 不得在 client 內保存 `*http.Request` 或請求狀態。
- 每個方法：
  - 接收 `context.Context`
  - 在方法內構建 request
  - 呼叫 `c.httpClient.Do(req)` 並 `defer resp.Body.Close()`

### JSON / Struct Tag
- 為 struct 欄位加上 `json,yaml,mapstructure` tag。
- 選填欄位使用 `omitempty`。
- Go 1.18+ 中使用 `any`，不再使用 `interface{}`。

### 測試與範例
- 採用表格驅動測試（table-driven tests）。
- 輔助函式加上 `t.Helper()`。
- 清理資源使用 `t.Cleanup()`。
- 匯出 API 需提供範例（`example_test.go`）。

### 產出內容要求
- 輸出完整、可編譯檔案或明確差異（diff）。
- 多檔案變更時，列出檔名與修改摘要。
- 若新增外部套件，附上 `go get <module>@version`。

### 詞彙與術語（外部參照）
- 本檔不內嵌詞彙表；請統一參照 `.github/copilot-vocabulary.yaml`。
- 若術語與既有命名衝突，請在變更說明提供過渡策略；衝突時以 vocabulary 檔為準。
- forbidden / preferred / mapping / normalization 規則詳見該檔。

### Review Checklist
- [ ] 僅一個 `package` 宣告
- [ ] 通過 `gofmt` / `goimports`
- [ ] 無未使用 imports、無循環依賴
- [ ] 錯誤即時檢查並使用 `%w` 包裝
- [ ] goroutine / channel 正確收斂
- [ ] I/O 操作安全（含 Close、Pipe、Body）
- [ ] JSON tag 一致、零值可用
- [ ] 測試可執行、範例完整
- [ ] go.mod tidy 後無變更

---

## Go 一般開發規範

### 通用原則
- 程式應簡潔明確、遵循 Go 習慣用法。
- 清晰優於巧妙；遵守最少驚訝原則。
- 主流程靠左排列（減少巢狀結構）。
- 盡量讓零值可直接使用。
- 以名稱與結構自我說明程式行為。
- 註解與文件預設使用英文。

### 命名慣例
- package 名稱全小寫、單字、無底線。
- 避免通用名稱如 `util`、`common`。
- 變數與函式採用小駝峰（camelCase）。
- 匯出名稱首字母大寫。
- Interface 採 `-er` 結尾（如 `Reader`, `Writer`）。

### 常數
- 群組相關常數使用 `const (...)` 區塊。
- 採用型別化常數以增加安全性。

### 程式碼風格
- 一律使用 `gofmt`。
- 合理斷行、空行分段邏輯區塊。
- 註解描述「為何」，非「做什麼」。

### 錯誤處理
- 不忽略錯誤；必要時註明理由。
- 錯誤訊息小寫開頭、不加標點。
- 不同層級間錯誤只記錄一次。

### 專案架構
- 可執行程式放 `cmd/`，可重用套件放 `pkg/` 或 `internal/`。
- 避免循環依賴。

### 並行處理
- 使用 `sync.WaitGroup` 或 channel。
- sender 關閉 channel。
- 批量讀取可使用緩衝 channel。
- 共享狀態以 `sync.Mutex`、`sync.RWMutex` 保護。

### 效能與 I/O
- 預先配置 slice。
- 使用 `sync.Pool` 重複利用物件。
- Reader 通常為一次性，需緩衝才能重複。

### 測試
- 使用 `_test.go` 命名。
- 子測試採 `t.Run()`。
- 輔助函式標註 `t.Helper()`。

### 安全性
- 驗證所有外部輸入。
- 使用標準 `crypto/*` 套件。
- 網路通訊須使用 TLS。

### 文件與註解
- 匯出符號需撰寫說明。
- 文件與程式同步維護。
- 避免使用 emoji。

### 開發流程
- commit 前執行 `go fmt`, `go vet`, `golangci-lint`。
- 單一 commit 專注一個改動。
- 確保測試通過再提交。

### 常見陷阱
- 未檢查錯誤。
- goroutine 泄漏。
- 忘記 `defer Close()`。
- 同時寫入 map。
- interface nil 與 pointer nil 混淆。
- 重複 package 宣告。
- 過度使用 `any` 或無限制泛型。

---

📁 **建議存放路徑：**
`.github/copilot-instructions.md`
此設定將自動套用於所有 Go 檔案（`*.go`, `go.mod`, `go.sum`）。
