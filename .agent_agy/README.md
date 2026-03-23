# Go 開發規範（模組化版本）

## 🚀 快速開始（1 分鐘）

```bash
# 方法 1：NPX 一鍵安裝（推薦）✨
npx @vincent119/go-copilot-rules

# 方法 2：快速安裝腳本（無需 npm）
bash <(curl -s https://raw.githubusercontent.com/vincent119/copilot-rules-kit/main/scripts/quick-install.sh)

# 方法 3：進階安裝（支援更多選項）
git clone https://github.com/vincent119/copilot-rules-kit.git
cd copilot-rules-kit
./scripts/install-skills.sh --vscode

# 方法 4：只安裝特定 Skills
npx @vincent119/go-copilot-rules --skills "go-ddd,go-grpc,go-testing-advanced"
```

**測試安裝**：在 VS Code Copilot Chat 輸入「如何實作 DDD Aggregate Root？」應該會觸發 `go-ddd` Skill。

📖 **完整安裝指南**：[INSTALLATION.md](INSTALLATION.md) - 包含 Git Submodule、Cursor、JetBrains 等方式

---

## 概述

本目錄包含 **Go 開發規範的模組化拆分版本**，將原本的三個大型指南檔案（總計 ~7,500 tokens）拆分為：

- **1 個輕量核心規範**（~2,500 tokens，always-on）
- **12 個專業 Skills**（每個 500-1,500 tokens，按需載入）

**預期效益**：節省 **60-70% 的 token 消耗**，從 7,500 降至 2,000-4,500（視使用場景）。

---

## 目錄結構

```
.agent_agy/
├── README.md                          # 本文件
├── INSTALLATION.md                    # 安裝指南（如何在不同 IDE/CLI 中使用）
├── SKILLS_INDEX.md                    # Skills 索引與使用指南
├── rules/
│   └── go-core.copilot-instructions.md  # 核心規範（always-on）
└── skills/
    ├── go-ddd/SKILL.md                  # DDD 架構設計
    ├── go-grpc/SKILL.md                 # gRPC 完整規範
    ├── go-testing-advanced/SKILL.md     # 進階測試策略
    ├── go-database/SKILL.md             # Database Migration 與 ORM
    ├── go-observability/SKILL.md        # 日誌與可觀測性
    ├── go-graceful-shutdown/SKILL.md    # 優雅關機模式
    ├── go-http-advanced/SKILL.md        # HTTP 進階實作
    ├── go-api-design/SKILL.md           # API 設計與版本管理
    ├── go-dependency-injection/SKILL.md # 依賴注入模式
    ├── go-configuration/SKILL.md        # 設定管理
    ├── go-ci-tooling/SKILL.md           # CI/CD 與工具配置
    ├── go-domain-events/SKILL.md        # Domain Events 實作
    └── go-examples/SKILL.md             # 實作範例庫
```

---

## 核心概念

### Always-On 核心規範

**檔案**：`rules/go-core.copilot-instructions.md`

**包含內容**：
- Copilot 產生守則（導入、錯誤處理、函式設計）
- 基礎錯誤處理模式（`fmt.Errorf` 與 `errors.Is/As`）
- Functional Options Pattern
- JSON/Struct Tag 規範
- 命名慣例與註解規範

**觸發時機**：所有 Go 程式碼編輯時自動載入

**Token 消耗**：~2,500 tokens

---

### 按需載入 Skills

**機制**：透過檔案中的 YAML frontmatter `description` 欄位（包含豐富的關鍵字）觸發載入

**範例**：
```yaml
---
description: |
  Go DDD 架構設計：Bounded Context、Aggregate Root、Repository Pattern、
  Entity、Value Object、Domain Service。

  **適用場景**：設計 DDD 架構、建立 Aggregate、實作 Repository Pattern。

  **關鍵字**：ddd, domain driven design, aggregate, entity, value object, repository
---
```

**觸發時機**：當你的問題或程式碼包含相關關鍵字時，Copilot 自動載入對應 Skill

---

## 使用指南

### 何時使用核心規範？

**永遠啟用**，適用於所有 Go 程式碼：
- 撰寫任何 Go 函式、結構體
- 處理錯誤
- 設計 API（Functional Options）
- 定義 JSON 模型

### 何時觸發 Skills？

| 場景                  | 觸發的 Skills                          |
|-----------------------|----------------------------------------|
| 設計 DDD 架構          | `go-ddd`                               |
| 實作 gRPC 服務         | `go-grpc`、`go-graceful-shutdown`       |
| 撰寫單元測試           | `go-testing-advanced`                  |
| Database Migration     | `go-database`                          |
| 實作結構化日誌         | `go-observability`                     |
| HTTP Client 重試策略   | `go-http-advanced`                     |
| 設計 RESTful API       | `go-api-design`、`go-http-advanced`     |
| 使用 Fx/Wire           | `go-dependency-injection`              |
| 設定管理（Viper）      | `go-configuration`                     |
| 撰寫 Makefile          | `go-ci-tooling`                        |
| 實作 Domain Events     | `go-domain-events`、`go-ddd`            |
| 參考實作範例           | `go-examples`                          |

💡 **提示**：查看 [SKILLS_INDEX.md](SKILLS_INDEX.md) 了解每個 Skill 的詳細觸發關鍵字

---

## Token 節省效益

### 場景分析

| 場景                  | 原始 Token | 模組化 Token | 節省比例 |
|-----------------------|------------|--------------|----------|
| 簡單函式撰寫           | 7,500      | 2,500        | 67%      |
| DDD 架構設計           | 7,500      | 4,000        | 47%      |
| gRPC + 測試            | 7,500      | 4,500        | 40%      |
| HTTP API + Database    | 7,500      | 5,000        | 33%      |
| 完整專案（多場景）     | 7,500      | 6,000        | 20%      |

**平均節省**：**60-70%**（大部分場景）

---

## 遷移指南

### 從原始檔案遷移

**原始檔案**（保持不動）：
- `go.copilot-instructions.md`（~4,000 tokens）
- `go2.copilot-instructions.md`（~3,000 tokens）
- `go3.copilot-instructions.md`（~500 tokens）

**新架構**：
- `.agent_agy/rules/go-core.copilot-instructions.md`（核心）
- `.agent_agy/skills/...`（專業領域）

### 並行使用（過渡期）

你可以同時保留原始檔案與新架構：
1. 原始檔案仍會載入（全部內容）
2. 新 Skills 會在包含關鍵字時載入
3. 若覺得新架構有效，可停用原始檔案（重新命名為 `.md.bak`）

### 完全遷移

停用原始檔案：
```bash
cd /Users/vincent/Documents/git_home/vin/copilot-rules-kit
mv go.copilot-instructions.md go.copilot-instructions.md.bak
mv go2.copilot-instructions.md go2.copilot-instructions.md.bak
mv go3.copilot-instructions.md go3.copilot-instructions.md.bak
```

---

## Skills 維護

### 新增 Skill

1. 建立目錄：`.agent_agy/skills/<skill-name>/`
2. 建立檔案：`SKILL.md`
3. 包含 YAML frontmatter（description 含豐富關鍵字）
4. 更新 `SKILLS_INDEX.md`

### 更新 Skill

- 直接編輯對應的 `SKILL.md`
- 若更改關鍵字，同步更新 `SKILLS_INDEX.md`

### 刪除 Skill

- 刪除對應目錄
- 從 `SKILLS_INDEX.md` 移除

---

## 常見問題

### Q: 核心規範會與 Skills 衝突嗎？

**A**: 不會。核心規範包含基礎規則，Skills 提供深入細節與進階主題。它們互補而非重複。

### Q: 如何確保 Skill 被觸發？

**A**: 在你的問題或程式碼中包含 Skill 的關鍵字。例如：
- "如何設計 DDD Repository？" → 觸發 `go-ddd`
- "實作 gRPC Interceptor" → 觸發 `go-grpc`

### Q: 可以手動指定載入 Skill 嗎？

**A**: 無法直接指定，但可以在問題中包含關鍵字引導 Copilot。例如：
- "使用 Outbox Pattern 實作 Domain Events"

### Q: 為何不全部合併為一個檔案？

**A**: 單一大檔案會造成：
- 每次都載入全部內容（浪費 token）
- 難以維護與更新
- 難以針對特定場景優化

---

## 授權

本規範遵循專案根目錄的 LICENSE 授權。

---

## 貢獻

歡迎提交 Issue 或 Pull Request 改進規範！

**參考資源**：
- [VS Code Copilot Skills 文件](https://code.visualstudio.com/docs/copilot/copilot-customization)
- [原始 Go 指南](../go.copilot-instructions.md)
