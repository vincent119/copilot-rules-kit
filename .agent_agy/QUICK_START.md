# 快速開始指南

## ⚠️ 重要提醒

**NPM Package 尚未發布**，目前無法直接使用 `npx @vincent119/go-copilot-rules`。

請使用以下替代方案：

---

## 🚀 方案 1：使用安裝腳本（推薦）

### 從 GitHub 直接安裝

```bash
# 一鍵安裝到當前專案（自動偵測 VS Code/Cursor/Kiro）
bash <(curl -s https://raw.githubusercontent.com/vincent119/copilot-rules-kit/main/scripts/quick-install.sh)
```

### 手動執行腳本

```bash
# Clone 專案
git clone https://github.com/vincent119/copilot-rules-kit.git /tmp/copilot-rules-kit

# 執行安裝腳本
cd /tmp/copilot-rules-kit

# 自動偵測
./scripts/install-skills.sh

# 或指定 IDE
./scripts/install-skills.sh --vscode
./scripts/install-skills.sh --cursor
./scripts/install-skills.sh --kiro
```

---

## 🚀 方案 2：本地 CLI 測試

如果你已經 clone 了此專案：

```bash
# 在專案根目錄
cd /path/to/copilot-rules-kit

# 執行安裝到特定目錄
node cli/install.js --path /path/to/your/project/.kiro/skills

# 或使用相對路徑（需要在目標專案目錄執行）
cd /path/to/your/project
node /path/to/copilot-rules-kit/cli/install.js --kiro
```

---

## 🚀 方案 3：Git Submodule（適合團隊）

```bash
cd /path/to/your/project

# 加入 submodule
git submodule add https://github.com/vincent119/copilot-rules-kit .copilot-rules

# 複製到目標位置
# VS Code
cp -r .copilot-rules/.agent_agy .

# Cursor
mkdir -p .cursor/skills
cp -r .copilot-rules/.agent_agy/skills/* .cursor/skills/

# Kiro
mkdir -p .kiro/skills
cp -r .copilot-rules/.agent_agy/skills/* .kiro/skills/
```

---

## 🚀 方案 4：直接手動複製

```bash
# Clone 到暫存目錄
git clone https://github.com/vincent119/copilot-rules-kit.git /tmp/copilot-rules-kit

cd /path/to/your/project

# 複製到 Kiro
mkdir -p .kiro/skills
cp -r /tmp/copilot-rules-kit/.agent_agy/skills/* .kiro/skills/
cp /tmp/copilot-rules-kit/.agent_agy/INSTALLATION.md .kiro/skills/
cp /tmp/copilot-rules-kit/.agent_agy/SKILLS_INDEX.md .kiro/skills/

# 複製核心規範（可選）
mkdir -p .kiro/rules
cp -r /tmp/copilot-rules-kit/.agent_agy/rules/* .kiro/rules/

# 清理
rm -rf /tmp/copilot-rules-kit
```

---

## ✅ 驗證安裝

### 檢查檔案是否存在

```bash
# Kiro
ls -la .kiro/skills/
tree .kiro/skills/

# 應該看到：
# go-ddd/
# go-grpc/
# go-testing-advanced/
# ... (共 13 個 Skills)
```

### 測試 Skills 是否可用

#### Kiro IDE

1. 打開 Kiro IDE
2. 按 `ctrl+e` 啟動 Wraith
3. 輸入：「列出所有可用的 Go Skills」
4. 應該會看到 13 個 Skills 列表

#### VS Code / Cursor

1. 打開專案
2. 在 Copilot Chat 輸入：「這個專案有哪些 Skills？」
3. 測試觸發：「如何實作 DDD Aggregate Root？」

---

## 🐛 故障排除

### 問題 1：安裝後看不到檔案

**可能原因**：
- CLI 找不到 `.agent_agy` 目錄
- 路徑計算錯誤

**解決方案**：
使用**方案 4**（直接手動複製），這是最可靠的方式。

### 問題 2：Skills 沒有被觸發

**檢查清單**：
1. 檔案是否在正確位置？
   - Kiro: `.kiro/skills/go-xxx/SKILL.md`
   - VS Code: `.agent_agy/skills/go-xxx/SKILL.md`
   - Cursor: `.cursor/skills/go-xxx/SKILL.md`

2. YAML frontmatter 是否正確？
   ```bash
   head -n 5 .kiro/skills/go-ddd/SKILL.md
   # 應該看到：
   # ---
   # name: go-ddd
   # description: ...
   # ---
   ```

3. 重新啟動 IDE

### 問題 3：本地 CLI 執行失敗

**錯誤訊息**：找不到 `.agent_agy` 目錄

**解決方案**：
```bash
# 必須在 copilot-rules-kit 專案根目錄執行
cd /path/to/copilot-rules-kit
node cli/install.js --help

# 或使用絕對路徑
node /path/to/copilot-rules-kit/cli/install.js --kiro
```

---

## 📦 NPM 發布後的使用方式

待 `@vincent119/go-copilot-rules` 發布後，可使用：

```bash
# 自動偵測
npx @vincent119/go-copilot-rules

# Kiro 專案
npx @vincent119/go-copilot-rules --kiro

# Kiro 全域
npx @vincent119/go-copilot-rules --kiro-global

# VS Code
npx @vincent119/go-copilot-rules --vscode

# Cursor
npx @vincent119/go-copilot-rules --cursor
```

---

## 📚 完整文件

- [完整安裝指南](INSTALLATION.md)
- [Skills 索引](SKILLS_INDEX.md)
- [README](README.md)

---

## 💡 推薦方式（依使用情境）

| 情境 | 推薦方案 | 原因 |
|------|---------|------|
| **快速測試** | 方案 4（手動複製） | 最簡單、最可靠 |
| **個人使用** | 方案 1（安裝腳本） | 一鍵安裝，自動備份 |
| **團隊協作** | 方案 3（Git Submodule） | 版本控制、易於更新 |
| **本地開發** | 方案 2（本地 CLI） | 適合測試 CLI 功能 |
