# Go Skills 索引

本文件列出所有可用的 Go Skills，包含觸發關鍵字、適用場景與內容概述。

---

## 核心規範（Always-On）

### `rules/go-core.copilot-instructions.md`

**觸發時機**：所有 Go 程式碼編輯

**Token 消耗**：~2,500 tokens

**包含內容**：
- ✅ Copilot 產生守則（導入、錯誤處理、函式設計）
- ✅ 基礎錯誤處理（`fmt.Errorf`、`errors.Is/As`、錯誤類型定義）
- ✅ Functional Options Pattern
- ✅ JSON Tag 與 Struct Tag 規範
- ✅ 命名慣例（變數、函式、套件）
- ✅ 註解規範（Godoc）

**適用場景**：
- 所有 Go 程式碼撰寫
- 定義函式與結構體
- 處理錯誤
- 設計選項式 API

---

## Skills（按需載入）

### 1. `skills/go-ddd/SKILL.md` - DDD 架構設計

**觸發關鍵字**：
```
ddd, domain driven design, bounded context, aggregate, aggregate root,
entity, value object, repository pattern, domain service, domain model,
ddd architecture, layered architecture, hexagonal architecture
```

**Token 消耗**：~1,200 tokens

**包含內容**：
- ✅ Bounded Context 設計
- ✅ Aggregate Root 規範
- ✅ Entity vs Value Object
- ✅ Repository Pattern
- ✅ Domain Service vs Application Service
- ✅ 四層架構（Domain/Application/Infrastructure/Delivery）
- ✅ Shared Kernel 設計

**適用場景**：
- 設計 DDD 架構
- 建立 Aggregate 與 Entity
- 實作 Repository Interface
- 設計微服務邊界

**相關 Skills**：`go-domain-events`、`go-dependency-injection`

---

### 2. `skills/go-grpc/SKILL.md` - gRPC 完整規範

**觸發關鍵字**：
```
grpc, protobuf, proto, rpc, buf, grpc server, grpc client, interceptor,
middleware, health check, grpc-health, reflection, grpc metadata, deadline,
context propagation, grpc stream, unary rpc
```

**Token 消耗**：~1,500 tokens

**包含內容**：
- ✅ Proto 檔案管理（Buf 配置）
- ✅ Interceptor 設計（Logging、Auth、Metrics）
- ✅ 健康檢查協議（grpc_health_v1）
- ✅ 錯誤代碼映射（gRPC Code ↔ HTTP Status）
- ✅ Deadline 處理
- ✅ Metadata 傳遞
- ✅ Stream vs Unary RPC

**適用場景**：
- 實作 gRPC 服務
- 配置 Buf 與 protoc
- 設計 Interceptor
- gRPC 與 HTTP 整合

**相關 Skills**：`go-observability`、`go-graceful-shutdown`

---

### 3. `skills/go-testing-advanced/SKILL.md` - 進階測試策略

**觸機關鍵字**：
```
testing, unit test, integration test, mock, gomock, testify, table driven test,
test coverage, benchmark, fuzz test, testcontainers, test fixtures, test helper,
parallel test, sub test
```

**Token 消耗**：~1,500 tokens

**包含內容**：
- ✅ Table-driven Tests
- ✅ Mock 生成與使用（uber-go/mock）
- ✅ 整合測試設計（testcontainers）
- ✅ Benchmark 與 Profiling
- ✅ Fuzz Testing
- ✅ 測試覆蓋率要求
- ✅ Parallel Tests 設計

**適用場景**：
- 撰寫單元測試
- 整合測試（Database、Redis、Kafka）
- 效能測試
- 生成 Mock

**相關 Skills**：`go-dependency-injection`、`go-examples`

---

### 4. `skills/go-database/SKILL.md` - Database Migration 與 ORM

**觸發關鍵字**：
```
database, migration, migrate, goose, gorm, sqlx, sql, postgres, mysql,
schema migration, database versioning, migration rollback, orm, query builder,
pt-online-schema-change, large table migration
```

**Token 消耗**：~1,200 tokens

**包含內容**：
- ✅ Migration 工具（golang-migrate、goose）
- ✅ Migration 命名慣例
- ✅ 大型表變更策略（pt-online-schema-change）
- ✅ Migration 版本控制
- ✅ CI/CD 整合
- ✅ Rollback 策略
- ✅ GORM vs SQLX 使用時機

**適用場景**：
- Database Schema 變更
- Migration 管理
- ORM 選擇與使用
- 大表 DDL 操作

**相關 Skills**：`go-ddd`（Repository Pattern）

---

### 5. `skills/go-observability/SKILL.md` - 日誌與可觀測性

**觸發關鍵字**：
```
logging, zap, logrus, structured logging, metrics, prometheus, tracing,
opentelemetry, jaeger, observability, context propagation, log level,
metrics naming, label cardinality, span, trace id
```

**Token 消耗**：~1,500 tokens

**包含內容**：
- ✅ 結構化日誌（Zap）
- ✅ Metrics 設計（Prometheus）
- ✅ Tracing 整合（OpenTelemetry）
- ✅ Context 傳遞（Trace ID、Request ID）
- ✅ Metrics 命名慣例
- ✅ Label 規範（避免高基數）
- ✅ 日誌等級規範

**適用場景**：
- 實作結構化日誌
- 設計 Metrics
- 整合 Tracing
- 可觀測性架構

**相關 Skills**：`go-grpc`（Interceptor）、`go-http-advanced`（Middleware）

---

### 6. `skills/go-graceful-shutdown/SKILL.md` - 優雅關機模式

**觸發關鍵字**：
```
graceful shutdown, signal handling, sigterm, sigint, shutdown, cleanup,
kubernetes, prestop, prestop hook, http shutdown, grpc gracefulstop,
context cancellation, background worker
```

**Token 消耗**：~800 tokens

**包含內容**：
- ✅ Signal 處理（SIGTERM、SIGINT）
- ✅ HTTP Server 優雅關機
- ✅ gRPC Server GracefulStop
- ✅ Background Worker 停止
- ✅ 資源清理順序
- ✅ Kubernetes preStop Hook
- ✅ 測試方法

**適用場景**：
- 實作優雅關機
- Kubernetes 整合
- Background Worker 管理
- 資源清理

**相關 Skills**：`go-grpc`、`go-http-advanced`

---

### 7. `skills/go-http-advanced/SKILL.md` - HTTP 進階實作

**觸發關鍵字**：
```
http client, http transport, retry, backoff, connection pool, timeout,
context, multipart upload, body replay, middleware, http.Client, httpdo,
exponential backoff, circuit breaker
```

**Token 消耗**：~1,500 tokens

**包含內容**：
- ✅ Transport 重用與配置
- ✅ 重試策略與指數退避
- ✅ Body 重播機制
- ✅ Multipart 上傳
- ✅ 逾時控制（3 層）
- ✅ HTTP Middleware 設計
- ✅ Connection Pool 管理

**適用場景**：
- 實作 HTTP Client
- 設計重試策略
- Multipart 檔案上傳
- HTTP Middleware

**相關 Skills**：`go-observability`、`go-api-design`

---

### 8. `skills/go-api-design/SKILL.md` - API 設計與版本管理

**觸發關鍵字**：
```
api design, rest api, json envelope, api versioning, pagination, swagger,
openapi, deprecation, http status code, response format, api best practices,
cursor pagination, offset pagination, rate limiting
```

**Token 消耗**：~1,500 tokens

**包含內容**：
- ✅ JSON Envelope 模式
- ✅ API 版本管理（路徑版本、Header 版本）
- ✅ 棄用通知（Deprecation Header）
- ✅ Pagination（Cursor-Based、Offset-Based）
- ✅ Filter、Sort 設計
- ✅ Swagger/OpenAPI 整合
- ✅ HTTP 狀態碼最佳實務
- ✅ Rate Limiting

**適用場景**：
- 設計 RESTful API
- API 版本控制
- 分頁與篩選
- OpenAPI 文件

**相關 Skills**：`go-http-advanced`、`go-examples`

---

### 9. `skills/go-dependency-injection/SKILL.md` - 依賴注入模式

**觸發關鍵字**：
```
dependency injection, uber fx, google wire, interface design, constructor,
mock, testable code, lifecycle, module, provider, invoke, wire, fx
```

**Token 消耗**：~1,200 tokens

**包含內容**：
- ✅ Interface 設計原則
- ✅ Constructor Pattern
- ✅ Functional Options Pattern
- ✅ Uber Fx 使用（Module、Lifecycle）
- ✅ Google Wire 使用（Provider Set）
- ✅ 測試模式（Mock Interface）
- ✅ 避免循環依賴

**適用場景**：
- 使用 Fx/Wire
- 設計可測試架構
- Interface 設計
- 模組化系統

**相關 Skills**：`go-testing-advanced`、`go-ddd`

---

### 10. `skills/go-configuration/SKILL.md` - 設定管理

**觸發關鍵字**：
```
configuration, viper, environment variables, secrets, validation, env vars,
config reload, 12-factor, configmap, kubernetes config, dotenv, yaml config,
dynamic reload, config validation
```

**Token 消耗**：~1,200 tokens

**包含內容**：
- ✅ Viper 配置
- ✅ 環境變數優先級
- ✅ Secrets 處理（AWS Secrets Manager、Kubernetes Secret）
- ✅ 設定驗證（validator）
- ✅ 動態重載（viper.WatchConfig）
- ✅ 多環境管理（dev/staging/prod）
- ✅ 12-Factor App 原則

**適用場景**：
- 使用 Viper 管理設定
- 環境變數管理
- Secrets 處理
- 動態重載設定

**相關 Skills**：`go-observability`（日誌配置）

---

### 11. `skills/go-ci-tooling/SKILL.md` - CI/CD 與工具配置

**觸發關鍵字**：
```
ci/cd, makefile, golangci-lint, github actions, docker, pre-commit,
test coverage, lint, build automation, continuous integration, pipeline,
dockerfile, multi-stage build
```

**Token 消耗**：~1,200 tokens

**包含內容**：
- ✅ Makefile 設計（build、test、lint）
- ✅ golangci-lint 配置（.golangci.yml）
- ✅ GitHub Actions（CI Pipeline、Release）
- ✅ Docker 多階段建置
- ✅ Pre-commit Hook
- ✅ 測試覆蓋率報告
- ✅ 版本注入（Ldflags）

**適用場景**：
- 設計 CI/CD Pipeline
- 配置 golangci-lint
- 撰寫 Makefile
- Docker 建置

**相關 Skills**：`go-testing-advanced`

---

### 12. `skills/go-domain-events/SKILL.md` - Domain Events 實作

**觸發關鍵字**：
```
domain events, event bus, outbox pattern, idempotency, event sourcing,
async events, event-driven, message queue, event publishing, saga pattern,
event store, event replay
```

**Token 消耗**：~1,500 tokens

**包含內容**：
- ✅ 事件定義（Event vs Command）
- ✅ Event Bus 實作（In-Memory、Message Queue）
- ✅ Outbox Pattern（Transaction + 事件發布）
- ✅ 冪等性處理（Processed Events Table）
- ✅ Event Sourcing 基礎
- ✅ 非同步事件處理
- ✅ 事件重播

**適用場景**：
- DDD Domain Events
- Outbox Pattern
- Event Sourcing
- 微服務解耦

**相關 Skills**：`go-ddd`、`go-database`

---

### 13. `skills/go-examples/SKILL.md` - 實作範例庫

**觸發關鍵字**：
```
examples, code examples, http client example, repository pattern,
use case example, handler example, service example, best practices, template,
complete example, reference implementation
```

**Token 消耗**：~1,500 tokens

**包含內容**：
- ✅ HTTP Client 完整範例
- ✅ Repository Pattern 實作（PostgreSQL）
- ✅ Use Case 範例（建立使用者）
- ✅ HTTP Handler 範例（RESTful API）
- ✅ Service 主程式範例（main.go）
- ✅ 完整的依賴注入
- ✅ 優雅關機整合

**適用場景**：
- 參考完整實作
- 學習最佳實務
- 快速啟動新專案
- 程式碼審查參考

**相關 Skills**：所有 Skills（涵蓋多種場景）

---

## 使用建議

### 場景映射

| 你想做什麼？                          | 需要的 Skills                              |
|---------------------------------------|--------------------------------------------|
| 設計新的微服務                        | `go-ddd`、`go-examples`、`go-dependency-injection` |
| 實作 gRPC 服務                        | `go-grpc`、`go-observability`、`go-graceful-shutdown` |
| 撰寫單元測試                          | `go-testing-advanced`、`go-dependency-injection` |
| 設計 RESTful API                      | `go-api-design`、`go-http-advanced`、`go-observability` |
| Database Schema Migration             | `go-database`                              |
| 實作 Domain Events                    | `go-domain-events`、`go-ddd`、`go-database` |
| CI/CD Pipeline                        | `go-ci-tooling`、`go-testing-advanced`      |
| 設定管理（Viper）                     | `go-configuration`                         |
| HTTP Client 實作                      | `go-http-advanced`、`go-examples`           |
| 依賴注入（Fx/Wire）                   | `go-dependency-injection`、`go-examples`    |

### 提問技巧

**❌ 不明確**：
- "如何處理錯誤？"（只會載入核心規範）

**✅ 明確**：
- "如何使用 Outbox Pattern 實作 Domain Events？"（觸發 `go-domain-events`）
- "設計 gRPC Interceptor 記錄日誌"（觸發 `go-grpc` + `go-observability`）
- "使用 Uber Fx 實作依賴注入"（觸發 `go-dependency-injection`）

### 關鍵字優化

**在你的問題或程式碼中包含這些詞彙**：
- **技術名詞**：gRPC、Viper、Fx、Wire、Outbox Pattern
- **實作目標**：Migration、Interceptor、Retry、Pagination
- **架構模式**：DDD、Repository Pattern、Event Sourcing

---

## Token 消耗統計

| 內容                     | Token 消耗 |
|--------------------------|------------|
| 核心規範（always-on）    | 2,500      |
| 單個 Skill（平均）       | 1,200      |
| 2 個 Skills 同時載入     | 4,900      |
| 3 個 Skills 同時載入     | 6,100      |
| **原始檔案（全部載入）** | **7,500**  |

**節省比例**：
- 簡單場景（0-1 Skill）：**67-80%**
- 中等場景（2 Skills）：**35%**
- 複雜場景（3+ Skills）：**19-31%**

---

## 更新日誌

### v1.0.0（初始版本）

- ✅ 拆分原始三個檔案為 1 核心 + 12 Skills
- ✅ 建立豐富的 YAML frontmatter description
- ✅ 包含完整的檢查清單與程式碼範例
- ✅ 建立索引與使用指南

---

## 維護指南

### 新增 Skill

1. 建立 `.agent_agy/skills/<skill-name>/SKILL.md`
2. 包含 YAML frontmatter（description 含關鍵字）
3. 更新本文件（SKILLS_INDEX.md）
4. 測試觸發關鍵字

### 更新 Skill

- 編輯對應的 `SKILL.md`
- 若更改關鍵字，同步更新本文件
- 記錄變更到 UPDATE_LOG

### 刪除 Skill

- 刪除對應目錄
- 從本文件移除
- 檢查是否有其他 Skill 引用

---

## 貢獻

歡迎提交改進建議！請確保：
- 新 Skill 包含豐富的關鍵字
- 提供完整的程式碼範例
- 包含檢查清單
- 更新本索引文件
