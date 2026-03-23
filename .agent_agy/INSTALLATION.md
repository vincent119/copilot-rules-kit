# 安裝指南

本文件說明如何在不同開發環境中使用 `.agent_agy/` 內的 Go 開發規範與 Skills。

---

## 🆚 與其他方案比較

### 與其他 Skills 方案的差異

| 特性 | copilot-rules-kit | antigravity-awesome-skills | Kiro |
|------|-------------------|----------------------------|------|
| **安裝方式** | **NPX CLI / Git Submodule/Subtree** | NPX CLI 一鍵安裝 | NPX CLI 一鍵安裝 |
| **目標場景** | Go 專案開發規範 | 通用 AI Agent Skills（1,300+ 個） | IDE + Skills + Multi-Agent |
| **Skills 數量** | 13 個專業 Go Skills | 1,300+ 跨領域 Skills | 17 個 Claude Skills + 社群 |
| **工具支援** | VS Code, Cursor, JetBrains, **Kiro** | Claude Code, Cursor, Gemini CLI, Antigravity 等 | Kiro IDE (基於 AWS Q) |
| **自動路徑** | 自動偵測 VS Code/Cursor/Kiro | 自動偵測並安裝到正確路徑 | `~/.kiro/skills/` 或專案 `.kiro/skills/` |
| **Context 管理** | 設計為按需載入 | Bundles + Activation Scripts | Multi-Agent 編排 (oh-my-kiro) |
| **更新機制** | NPX 重新執行 | NPX 重新執行 | NPX 重新執行 |
| **客製化** | 直接修改 Skills | 使用 Bundles 選擇需要的 Skills | Spec-driven workflow + Agents |
| **特色功能** | Go 生態深度整合 | 最大規模 Skills 集合 | Multi-Agent 編排 + MCP 支援 |

### copilot-rules-kit 的優勢

**✅ 專注於 Go 生態**
- 深度整合 Go 最佳實踐（DDD、gRPC、Testing）
- 包含自訂套件（zlogger、commons/graceful）
- 針對 Go 專案優化的 token 消耗策略

**✅ 更輕量**
- 核心規範 ~2,500 tokens（vs 大量通用 Skills）
- 13 個精選 Go Skills，按需載入
- 不需要額外的依賴

**✅ 更靈活**
- Git Submodule/Subtree 更適合團隊協作
- 可以針對專案客製化規範
- 容易 fork 並維護私有版本
- 跨 IDE 支援（VS Code、Cursor、Kiro）

### antigravity-awesome-skills 的優勢

**✅ 最大規模的 Skills 集合**
- 1,300+ Skills 涵蓋前後端、測試、安全、DevOps
- Bundles 機制（Web Wizard、Security Engineer 等）
- 社群貢獻與官方 Skills 集合

**✅ 更成熟的生態**
- 27k+ GitHub Stars
- 完整的文件與使用指南
- Web App 瀏覽介面
- Activation Scripts 管理 context overload

### Kiro 的優勢

**✅ IDE + Skills + Multi-Agent 一體化**
- 內建 IDE（基於 AWS Q/CodeWhisperer）
- Spec-driven development workflow
- Multi-Agent 編排（oh-my-kiro：Phantom/Revenant/Wraith）

**✅ 進階 Agent 系統**
- 7 個專業子 Agent（Explorer、Analyst、Implementer 等）
- 規劃與執行分離（Plan → Execute）
- MCP (Model Context Protocol) 支援

**✅ 完整的生態系統**
- `kiro-super-skills` - 17 個 Anthropic Claude Skills
- `oh-my-kiro` - Multi-agent 編排框架
- `.kiro/` 配置系統（agents、steering、hooks）

### 選擇建議

**選擇 copilot-rules-kit 如果：**
- 你的專案主要是 Go
- 需要深度的 Go 最佳實踐指引（DDD、gRPC、Testing）
- 想要輕量、專注的規範集
- 需要整合自訂套件（如 zlogger、graceful）
- 跨 IDE 工作（VS Code、Cursor、Kiro）

**選擇 antigravity-awesome-skills 如果：**
- 需要跨語言、跨領域的 Skills
- 希望一鍵安裝到多種 AI 工具
- 需要社群驗證的通用 Skills（1,300+ 個）
- 想要 Bundles 與 Workflows

**選擇 Kiro 如果：**
- 需要完整的 IDE + Agent 系統
- 喜歡 Spec-driven development 工作流程
- 需要 Multi-Agent 編排（規劃與執行分離）
- 想要 MCP 工具整合
- 願意使用新興的 AI IDE

**組合使用策略**：

```bash
# 策略 1：VS Code/Cursor + antigravity + copilot-rules-kit
# 通用 Skills（廣度）
npx antigravity-awesome-skills --path ~/.agent/skills/community

# Go 專業規範（深度）
npx @vincent119/go-copilot-rules --vscode

# 策略 2：Kiro + copilot-rules-kit
# Kiro IDE（完整 Agent 系統）
npx oh-my-kiro@latest --global

# Go 專業規範（深度整合）
npx @vincent119/go-copilot-rules --path ~/.kiro/skills/go

# 策略 3：All-in（最大化）
# antigravity（通用 Skills）
npx antigravity-awesome-skills

# copilot-rules-kit（Go 深度）
npx @vincent119/go-copilot-rules

# kiro-super-skills（Claude Skills）
npm install -g kiro-super-skills
```

---

## 自動安裝（推薦）

**✨ 類似 [antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) 的 NPX 一鍵安裝！**

### 🎯 使用 NPX（最簡單）

```bash
# 自動偵測並安裝（VS Code、Cursor 或 Kiro）
npx @vincent119/go-copilot-rules

# 安裝到 VS Code
npx @vincent119/go-copilot-rules --vscode

# 安裝到 Cursor
npx @vincent119/go-copilot-rules --cursor

# 安裝到 Kiro（專案）
npx @vincent119/go-copilot-rules --kiro

# 安裝到 Kiro（全域）
npx @vincent119/go-copilot-rules --kiro-global

# 只安裝特定 Skills
npx @vincent119/go-copilot-rules --skills "go-ddd,go-grpc,go-observability"

# 自訂安裝路徑
npx @vincent119/go-copilot-rules --path ~/.my-copilot-rules

# 查看所有選項
npx @vincent119/go-copilot-rules --help
```

**支援的選項**：
- `--vscode` - 安裝到 `.agent_agy/`（VS Code Copilot 預設路徑）
- `--cursor` - 安裝到 `.cursor/skills/`（Cursor 預設路徑）
- `--kiro` - 安裝到 `.kiro/skills/`（Kiro 專案路徑）
- `--kiro-global` - 安裝到 `~/.kiro/skills/`（Kiro 全域路徑）
- `--path <dir>` - 安裝到自訂路徑
- `--core-only` - 只安裝核心規範（不包含 Skills）
- `--skills-only` - 只安裝 Skills（不包含核心規範）
- `--skills <list>` - 只安裝特定 Skills（逗號分隔）

### 🚀 使用安裝腳本（替代方案）

如果你不想使用 NPX，也可以直接執行安裝腳本：

```bash
# 方法 1：一鍵安裝（從 GitHub 直接執行）
bash <(curl -s https://raw.githubusercontent.com/vincent119/copilot-rules-kit/main/scripts/quick-install.sh)

# 方法 2：Clone 後手動安裝
git clone https://github.com/vincent119/copilot-rules-kit.git /tmp/copilot-rules-kit
cd /tmp/copilot-rules-kit

# VS Code
./scripts/install-skills.sh --vscode

# Cursor
./scripts/install-skills.sh --cursor

# 只安裝特定 Skills
./scripts/install-skills.sh --skills "go-ddd,go-grpc,go-testing-advanced"

# 查看所有選項
./scripts/install-skills.sh --help
```

---

## VS Code

### 方法 1：直接複製到專案

**適用場景**：單一專案、需要客製化規範

```bash
# 在你的 Go 專案根目錄
cp -r /path/to/copilot-rules-kit/.agent_agy .

# 或者只複製核心規範
mkdir -p .github/copilot
cp .agent_agy/rules/go-core.copilot-instructions.md .github/copilot/
```

**優點**：
- 簡單直接
- 可以針對專案客製化
- 不需要額外的 Git 配置

**缺點**：
- 規範更新需要手動同步
- 多專案維護麻煩

---

### 方法 2：使用 Git Submodule

**適用場景**：多個專案共用、希望規範集中管理

#### 新增 Submodule

```bash
# 在你的 Go 專案根目錄
git submodule add https://github.com/vincent119/copilot-rules-kit.git .copilot-rules

# 建立符號連結（讓 Copilot 能找到）
ln -s .copilot-rules/.agent_agy .agent_agy

# 提交變更
git add .gitmodules .copilot-rules .agent_agy
git commit -m "chore: add copilot rules as submodule"
```

#### 更新 Submodule

```bash
# 拉取最新規範
git submodule update --remote .copilot-rules
git commit -am "chore: update copilot rules"
```

#### Clone 專案時初始化 Submodule

```bash
# 方法 1：clone 時一併初始化
git clone --recurse-submodules <your-repo-url>

# 方法 2：clone 後手動初始化
git clone <your-repo-url>
cd <your-repo>
git submodule init
git submodule update
```

**優點**：
- 多專案共用，維護方便
- 規範更新只需 pull
- 保持獨立版本控制

**缺點**：
- 需要理解 Git Submodule
- Clone 專案需要額外步驟
- 符號連結在 Windows 可能有問題

---

### 方法 3：使用 Git Subtree

**適用場景**：希望內嵌到專案、不想處理 Submodule

#### 新增 Subtree

```bash
# 在你的 Go 專案根目錄
git subtree add --prefix .copilot-rules \
  https://github.com/vincent119/copilot-rules-kit.git main --squash

# 建立符號連結
ln -s .copilot-rules/.agent_agy .agent_agy
git add .agent_agy
git commit -m "chore: add copilot rules symlink"
```

#### 更新 Subtree

```bash
# 拉取最新規範
git subtree pull --prefix .copilot-rules \
  https://github.com/vincent119/copilot-rules-kit.git main --squash
```

**優點**：
- Clone 專案時自動包含規範（無需額外步驟）
- 比 Submodule 簡單
- 可選擇性合併上游更新

**缺點**：
- 更新操作稍複雜
- 歷史記錄會變大

---

### 方法 4：符號連結（本地開發）

**適用場景**：本地多個專案共用、不想提交到 Git

```bash
# 在你的 Go 專案根目錄
ln -s /path/to/copilot-rules-kit/.agent_agy .agent_agy

# 忽略符號連結（不提交到 Git）
echo ".agent_agy" >> .gitignore
```

**優點**：
- 最簡單
- 所有專案即時同步
- 不污染 Git 歷史

**缺點**：
- 僅限本地開發
- 其他開發者無法使用
- Windows 需要管理員權限建立符號連結

---

## 在不同專案中選擇性載入 Skills

### 情境 1：只需核心規範

```bash
# 只複製核心規範檔案
mkdir -p .github/copilot
cp /path/to/copilot-rules-kit/.agent_agy/rules/go-core.copilot-instructions.md \
   .github/copilot/go-core.copilot-instructions.md
```

### 情境 2：只需特定 Skills

```bash
# 建立 Skills 目錄
mkdir -p .agent_agy/skills

# 只複製需要的 Skills
cp -r /path/to/copilot-rules-kit/.agent_agy/skills/go-ddd \
      .agent_agy/skills/
cp -r /path/to/copilot-rules-kit/.agent_agy/skills/go-grpc \
      .agent_agy/skills/
```

---

## Kiro IDE

### 方法 1：NPX 安裝（推薦）

**專案級別安裝**：

```bash
# 在你的專案根目錄
npx @vincent119/go-copilot-rules --kiro

# 或之後在 Kiro 中執行
npx oh-my-kiro@latest  # 選擇性安裝 oh-my-kiro（Multi-Agent 系統）
```

**全域安裝**（所有專案可用）：

```bash
# 安裝到 ~/.kiro/skills/
npx @vincent119/go-copilot-rules --kiro-global

# 配合 oh-my-kiro 使用
npx oh-my-kiro@latest --global
```

### 方法 2：手動複製

```bash
# 專案級別
cp -r /path/to/copilot-rules-kit/.agent_agy/skills/* .kiro/skills/

# 全域級別
mkdir -p ~/.kiro/skills
cp -r /path/to/copilot-rules-kit/.agent_agy/skills/* ~/.kiro/skills/
```

### 驗證安裝

1. 打開 Kiro IDE
2. 在專案中按 `ctrl+e` 啟動 Wraith（直接任務執行器）
3. 輸入：「這個專案有哪些 Go Skills 可用？」
4. Kiro 應該會列出 13 個 Go Skills

### 與 oh-my-kiro 結合使用

[oh-my-kiro](https://www.npmjs.com/package/oh-my-kiro) 是 Kiro 的 Multi-Agent 編排系統，可與本 Skills 完美結合：

```bash
# 1. 安裝 oh-my-kiro（Multi-Agent 系統）
npx oh-my-kiro@latest --global

# 2. 安裝 Go Skills
npx @vincent119/go-copilot-rules --kiro-global

# 3. 在 Kiro 中使用
# - ctrl+p: Phantom（規劃 Agent）使用 go-ddd 規劃 DDD 架構
# - ctrl+a: Revenant（執行 Agent）使用 go-grpc 實作 gRPC 服務
# - ctrl+e: Wraith（直接執行）使用 go-testing-advanced 撰寫測試
```

**工作流程範例**：

```
1. 使用 Phantom（ctrl+p）規劃一個 gRPC 微服務
   → ghost-analyst 分析需求時自動觸發 go-ddd Skill
   → ghost-explorer 探索現有代碼時使用 go-grpc Skill

2. Phantom 產出計劃（.kiro/plans/grpc-service.md）

3. 使用 Revenant（ctrl+a）執行計劃
   → ghost-implementer 實作時自動使用 go-grpc、go-observability Skills
   → ghost-reviewer 審查時參考 go-testing-advanced Skill

4. 使用 Wraith（ctrl+e）快速修正
   → 「使用 zlogger 加入結構化日誌」（自動觸發 go-observability）
```

### Kiro Skills 路徑優先級

Kiro 會依序搜尋 Skills：

1. 專案級別：`.kiro/skills/`（優先）
2. 全域級別：`~/.kiro/skills/`

建議策略：
- **全域安裝** go-copilot-rules（所有 Go 專案共用）
- **專案安裝** 自訂 Skills（專案特定需求）

---

## 其他 IDE

### JetBrains IDEs（GoLand、IntelliJ IDEA）

**支援狀態**：部分支援

JetBrains IDEs 的 GitHub Copilot 插件支援 `.github/copilot/` 目錄下的 `copilot-instructions.md`，但 **Skills 機制支援有限**。

**建議配置**：

```bash
# 將核心規範放到 JetBrains 能識別的位置
mkdir -p .github/copilot
cp .agent_agy/rules/go-core.copilot-instructions.md \
   .github/copilot/go-copilot-instructions.md
```

**限制**：
- 無法使用 Skills 的按需載入機制
- 建議將常用規範合併為單一檔案

---

### Cursor

**支援狀態**：完整支援

Cursor 基於 VS Code，完整支援 Copilot Skills 機制。使用方式與 VS Code 相同：

```bash
# 直接複製或建立符號連結
cp -r /path/to/copilot-rules-kit/.agent_agy .
```

---

### Neovim / Vim

**支援狀態**：有限支援

使用 [copilot.vim](https://github.com/github/copilot.vim) 或 [copilot.lua](https://github.com/zbirenbaum/copilot.lua)：

```bash
# 將核心規範放到專案根目錄
cp .agent_agy/rules/go-core.copilot-instructions.md \
   .copilot-instructions.md
```

**限制**：
- Copilot.vim 對自訂指令支援有限
- 建議使用簡化版規範

---

## GitHub Copilot CLI

**支援狀態**：不直接支援

GitHub Copilot CLI (`gh copilot`) 目前不支援讀取專案內的自訂規範。

**替代方案**：

1. **在 Prompt 中包含規範**：
   ```bash
   gh copilot suggest "根據 DDD 規範，實作一個 User Aggregate"
   ```

2. **使用 Shell Alias**：
   ```bash
   # ~/.zshrc or ~/.bashrc
   alias ghc-ddd='gh copilot suggest --context "遵循 DDD 規範：Aggregate Root 包含 ID/Version，使用 Functional Options"'
   ```

---

## 驗證安裝

### VS Code

1. 打開專案內的任何 `.go` 檔案
2. 觸發 Copilot Chat（快捷鍵：`Cmd/Ctrl + I`）
3. 詢問：「這個專案有哪些 Copilot Skills？」
4. 應該會列出 `go-ddd`、`go-grpc` 等 Skills

### 測試核心規範

在 Go 檔案中輸入：

```go
func GetUser(id string) {
    // Copilot 應該建議錯誤處理：(user User, err error)
}
```

Copilot 應該自動建議修正為：
```go
func GetUser(id string) (User, error) {
    // ...
}
```

### 測試 Skills 觸發

在 Copilot Chat 輸入：

```
如何實作 DDD 的 Aggregate Root？
```

應該會觸發 `go-ddd` Skill 並提供詳細指引。

---

## 團隊協作建議

### 方案 1：Submodule（推薦）

**適合**：多專案團隊、規範統一管理

```bash
# 團隊規範 Repo
https://github.com/your-org/copilot-rules-kit

# 各專案引用
git submodule add https://github.com/your-org/copilot-rules-kit .copilot-rules
ln -s .copilot-rules/.agent_agy .agent_agy
```

### 方案 2：內部 Package

**適合**：大型組織、需要嚴格版本控制

```bash
# 發布為內部 Go Module（僅文件）
module github.com/your-org/go-standards

# 各專案透過 go install 安裝配置腳本
go install github.com/your-org/go-standards/setup@latest
setup install-copilot-rules
```

### 方案 3：各專案獨立維護

**適合**：小團隊、專案差異大

```bash
# 各專案自行維護 .agent_agy/
# 定期同步主規範 Repo 的更新
```

---

## 常見問題

### Q: NPX 與 Bash 腳本有何差異？

**A**:
- **NPX 方式**（`npx @vincent119/go-copilot-rules`）：
  - ✅ 最簡單，無需 Clone 專案
  - ✅ 自動獲取最新版本
  - ✅ 跨平台支援
  - ⚠️ 需要 npm/npx 環境

- **Bash 腳本方式**（`quick-install.sh`）：
  - ✅ 無需 npm 環境
  - ✅ 可離線使用（Clone 後）
  - ✅ 更靈活的客製化
  - ⚠️ 需要 Git 環境

**建議**：如果有 npm，優先使用 NPX；否則使用 Bash 腳本。

### 快速安裝腳本範例（已實現）

建立 `install-go-rules.sh`：

```bash
#!/bin/bash
# Go Copilot Rules 快速安裝腳本

set -e

REPO="https://github.com/vincent119/copilot-rules-kit.git"
TEMP_DIR="/tmp/copilot-rules-kit-$$"
TARGET_DIR="${1:-.agent_agy}"

echo "📦 下載 Go Copilot Rules..."
git clone --depth 1 "$REPO" "$TEMP_DIR"

echo "📋 複製 Skills 到 $TARGET_DIR..."
mkdir -p "$TARGET_DIR"
cp -r "$TEMP_DIR/.agent_agy/"* "$TARGET_DIR/"

echo "🧹 清理暫存檔案..."
rm -rf "$TEMP_DIR"

echo "✅ 安裝完成！"
echo ""
echo "📖 查看可用的 Skills："
ls -1 "$TARGET_DIR/skills/"
echo ""
echo "💡 開始使用："
echo "   1. 在 Copilot Chat 輸入：'這個專案有哪些 Skills？'"
echo "   2. 試試看：'如何實作 DDD Aggregate Root？'（會觸發 go-ddd Skill）"
```

使用方式：

```bash
# 安裝到預設位置（.agent_agy/）
bash install-go-rules.sh

# 安裝到自訂位置
bash install-go-rules.sh ~/.agent/skills/go

# 或從網路直接執行
bash <(curl -s https://raw.githubusercontent.com/vincent119/copilot-rules-kit/main/scripts/quick-install.sh)
```

---

### Q: 符號連結在 Windows 是否可用？

**A**: 需要以管理員身份執行，或啟用開發者模式：

```powershell
# PowerShell (管理員)
New-Item -ItemType SymbolicLink -Path .agent_agy -Target C:\path\to\copilot-rules-kit\.agent_agy
```

或使用 Git Bash（需開啟符號連結支援）。

---

### Q: Submodule 與 Subtree 如何選擇？

| 特性           | Submodule      | Subtree        |
|----------------|----------------|----------------|
| Clone 便利性   | 需額外步驟     | 自動包含       |
| 更新操作       | 簡單           | 稍複雜         |
| 獨立版本控制   | ✅             | ❌             |
| 歷史記錄大小   | 小             | 大             |
| 團隊協作       | 需要理解機制   | 較簡單         |

**建議**：
- 團隊熟悉 Git → Submodule
- 希望簡化流程 → Subtree

---

### Q: 可以混用多個規範來源嗎？

**A**: 可以。Copilot 會合併所有找到的規範：

```
project/
├── .agent_agy/                    # 來自 copilot-rules-kit
│   ├── rules/go-core.copilot-instructions.md
│   └── skills/...
└── .github/copilot/
    └── project-specific.copilot-instructions.md  # 專案特定規範
```

---

### Q: 如何避免 Token 消耗過多？

**A**:
1. 只安裝需要的 Skills（選擇性複製）
2. 根據專案類型定製：
   - **HTTP API 專案**：go-http-advanced、go-api-design
   - **gRPC 微服務**：go-grpc、go-ddd、go-observability
   - **CLI 工具**：go-core + go-configuration

---

## 更新日誌

- **2026-03-23**：建立安裝指南
- **2026-03-23**：新增與 antigravity-awesome-skills 的比較
- **2026-03-23**：提供快速安裝腳本範例

---

## 未來計劃

根據 [antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) 的最佳實踐，我們計劃持續改進：

### ✅ 已完成（V1.0）

**NPX 安裝工具**
```bash
# ✅ 已實現：自動偵測 IDE 並安裝到正確位置
npx @vincent119/go-copilot-rules

# ✅ 已實現：針對特定工具安裝
npx @vincent119/go-copilot-rules --vscode
npx @vincent119/go-copilot-rules --cursor
npx @vincent119/go-copilot-rules --path ~/.my-skills

# ✅ 已實現：選擇性安裝 Skills
npx @vincent119/go-copilot-rules --skills "go-ddd,go-grpc"

# ✅ 已實現：只安裝核心規範
npx @vincent119/go-copilot-rules --core-only
```

### 🔄 進行中（V2.0）

**2. Context 管理機制**
```bash
# 只啟用特定 Skills（節省 token）
./scripts/activate-skills.sh go-ddd go-grpc go-testing-advanced

# 啟用 Bundles
./scripts/activate-skills.sh --bundle backend-api
./scripts/activate-skills.sh --bundle microservices

# 重置回全部 Skills
./scripts/activate-skills.sh --reset
```

**3. Bundles 預設集**
- **Backend API**：go-http-advanced, go-api-design, go-database, go-observability
- **Microservices**：go-grpc, go-ddd, go-graceful-shutdown, go-configuration
- **Testing**：go-testing-advanced, go-examples
- **DevOps**：go-ci-tooling, go-configuration, go-graceful-shutdown

**4. VS Code Extension（考慮中）**
- 視覺化 Skills 管理
- 一鍵啟用/停用 Skills
- Skills 觸發統計
- 客製化規範編輯器

### 📝 貢獻

如果你想幫助實現這些功能：
1. [提 Issue](https://github.com/vincent119/copilot-rules-kit/issues/new) 討論需求
2. Fork 專案並送 PR
3. 分享你的使用經驗與改進建議

---

## 更新日誌
