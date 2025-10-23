# copilot-rules-kit

集中維護的 **AI 助手產出規範套件**（for GitHub Copilot / VS Code Agent / 其他 LLM 協作工具）。  
目標：在多個專案之間 **統一生成規範、術語詞彙、與文件模板**，確保產出 **正確性、可維護性、與一致性**。

> 適用情境：公司/團隊以 **git submodule** 或 **git subtree** 導入本套件至各個專案，並以 **tag 版本** 管理升級與回滾。

- Repo：`https://github.com/vincent119/copilot-rules-kit`

---

## 內容構成（中央規範倉庫）

```
copilot-rules-kit/
├── CHANGELOG.md
├── LICENSE
├── README.md
├── samples/
│   └── workflows/
│       └── copilot-standards-check.yml
├── scripts/
│   ├── setup-copilot-submodule.sh
│   ├── setup-copilot-subtree.sh
│   └── vocabulary_scan.py
└── standards/
    ├── bash.instructions.md
    ├── copilot-chat-instructions.yaml
    ├── copilot-common.md
    ├── copilot-instructions-extended.md
    ├── copilot-instructions.md
    ├── copilot-instructions.yaml
    ├── copilot-vocabulary.yaml
    ├── go.instructions.md
    ├── helm.instructions.md
    ├── pulumi.instructions.md
    ├── python.instructions.md
    ├── ts.instructions.md
    └── yaml.instructions.md
```

---

## 消費端導入位置（推薦）

> **導入位置：`.github/rules/`**  
> 優點：與 GitHub Actions、Issue/PR 模板等生態一致；不污染專案根目錄，便於工具化引用。

### A. 以 Git Submodule 導入（推薦：清楚版本邊界、易回滾）

```bash
# 於消費端專案根目錄執行
git submodule add -b main https://github.com/vincent119/copilot-rules-kit.git .github/rules
git submodule update --init --recursive

#（可選）鎖定到特定版本 tag（例：v0.2.0）
cd .github/rules && git fetch --tags && git checkout v0.2.0 && cd -
git add .gitmodules .github/rules
git commit -m "chore(rules): add copilot-rules-kit@v0.2.0 as submodule"
```

**升版到新 tag：**
```bash
cd .github/rules
git fetch --tags
git checkout v0.2.1
cd -
git add .github/rules
git commit -m "chore(rules): bump copilot-rules-kit to v0.2.1"
```

**CI 注意事項：**
```bash
# CI 若需存取規範檔，請先同步子模組
git submodule update --init --recursive
```

### B. 以 Git Subtree 導入（倉庫不帶 submodule 依賴）

```bash
git subtree add --prefix .github/rules https://github.com/vincent119/copilot-rules-kit.git main --squash
```

**從上游拉取最新（同分支或 tag）：**
```bash
git subtree pull --prefix .github/rules https://github.com/vincent119/copilot-rules-kit.git main --squash
```

---

## 腳本使用說明（可於消費端直接使用）

### 1) `scripts/setup-copilot-submodule.sh`
**用途**：一鍵將本套件以 **submodule** 形式導入到消費端的 `.github/rules/`，並鎖定到指定版本。

**用法**：
```bash
# 預設導入到 .github/rules 並鎖定 v0.2.0
bash scripts/setup-copilot-submodule.sh

# 自訂導入目錄與版本
bash scripts/setup-copilot-submodule.sh .github/rules v0.2.1
```

**行為**：
- 新增子模組 → 初始化遞迴 → 抓取 tags → 切換至指定 tag
- 將 `.gitmodules` 與目標目錄加入版本控制並建立提交

### 2) `scripts/setup-copilot-subtree.sh`
**用途**：一鍵以 **subtree** 方式導入到 `.github/rules/`。

**用法**：
```bash
# 導入 main 分支
bash scripts/setup-copilot-subtree.sh

# 指定前置目錄與來源 ref（分支或 tag）
bash scripts/setup-copilot-subtree.sh .github/rules v0.2.1
```

**行為**：
- 以 `--squash` 壓縮上游歷史，保持消費端歷史乾淨

### 3) `scripts/vocabulary_scan.py`
**用途**：依 `standards/copilot-vocabulary.yaml` 執行術語掃描，提示黑名單或建議用語。

**用法**：
```bash
python3 .github/rules/scripts/vocabulary_scan.py   --vocab .github/rules/standards/copilot-vocabulary.yaml   --paths "docs/**/*.md" "src/**/*.go" "src/**/*.ts"
```

**輸出**：
- 發現黑名單：`[DISALLOWED] <詞> in <檔案>`  
- 提示建議改寫：`[SUGGEST] <錯> → <正> in <檔案>`

---

## 範例：GitHub Actions 工作流程（消費端複製後即可用）

將下列檔案複製到 **消費端專案**：`.github/workflows/copilot-standards-check.yml`：

```yaml
name: Copilot Standards Check

on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]

jobs:
  standards-check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repo (with submodules)
        uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Ensure submodules are synced
        run: git submodule update --init --recursive

      - name: Vocabulary Scan
        run: |
          python3 .github/rules/scripts/vocabulary_scan.py             --vocab .github/rules/standards/copilot-vocabulary.yaml             --paths "docs/**/*.md" "src/**/*.go" "src/**/*.ts"
```

> 若採用 **subtree** 導入，`with: submodules: recursive` 可省略。

---

## 授權

MIT（詳見 `LICENSE`）。
