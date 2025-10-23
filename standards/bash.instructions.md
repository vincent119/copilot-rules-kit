---
description: 'Bash / Shell Script 撰寫與自動產生規範'
applyTo: '**/*.sh,**/*.bash'
extends:
  common: ".github/copilot-common.md"
  vocabulary: ".github/copilot-vocabulary.yaml"
---

# Bash / Shell Script 指南（for Copilot & VS Code Agent）

本檔延伸自 copilot-common.md 與 copilot-vocabulary.yaml，統一格式、安全與用詞規範。

---

## 1. 通用原則

- **以 Bash 為主（#!/usr/bin/env bash）**，僅在明確需要時使用 POSIX sh。
- 生成內容必須：
  - 可直接執行 (`chmod +x`)
  - 通過 `shellcheck` 無嚴重警告
  - 無未定義變數引用 (`set -u`)
  - 正確處理錯誤與退出碼 (`set -e`, `set -o pipefail`)
- 絕不假設執行環境，若需相依套件應先檢查 (`command -v ... || exit 1`)。

---

## 2. Header 與格式

- 開頭必須含：
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  IFS=$'\n\t'
  ```
- 每個函式前加上註解（用途與參數簡述）。
- 變數名稱採 **UPPER_SNAKE_CASE**。
- 函式名稱採 **snake_case**。
- 內文縮排：**2 空白**。
- 僅使用 ANSI 可攜語法，避免 bash 4+ 專屬語法於通用腳本中。

---

## 3. 錯誤處理與安全性

- 永遠明確檢查外部命令結果：
  ```bash
  if ! curl -fsSL "$url" -o "$file"; then
    echo "Download failed" >&2
    exit 1
  fi
  ```
- 禁止使用 `eval`、`source` 未信任來源。
- 所有 `rm`, `mv`, `cp` 操作需加 `--` 防止意外解析參數。
- 所有 `$VAR` 展開必加雙引號 `"${VAR}"`。

---

## 4. 函式與結構

- 函式開頭與結尾間保持一行空白：
  ```bash
  do_task() {
    echo "running"
  }
  ```
- 禁止使用全域暫存變數，應以 `local` 管理。
- 使用 `return` 控制函式內部流程，不直接 `exit`。
- 使用 `trap` 處理中斷與清理：
  ```bash
  trap cleanup EXIT INT TERM
  ```

---

## 5. CLI / 腳本行為

- 若腳本有參數，必須支援 `-h|--help`。
- 使用 `getopts` 或明確 `case "$1" in ...)` 處理參數。
- 所有輸出均應可重導向 (`stdout` / `stderr` 區分明確)。
- 避免互動式輸入；若必要，允許透過環境變數設定。

---

## 6. Logging 規範

```bash
log_info()  { echo "[INFO]  $*" >&2; }
log_warn()  { echo "[WARN]  $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }
```

- 錯誤訊息輸出到 `stderr`。
- 禁止混用 `echo` 與 `printf` 不同風格輸出。
- 重要訊息應加上時間戳（選用 `date +"%F %T"`）。

---

## 7. Copilot / Agent 智能產生行為

- 優先保持原始腳本結構與縮排。
- 生成函式或段落時：
  - 若已存在同名函式 → 更新內容，不重複定義。
  - 若需新增 → 插入於主邏輯前。
- 自動產生變數時：
  - 須以 `readonly` 或 `local` 宣告。
  - 不可覆寫現有環境變數。
- 若檔案包含：
  - `#!/usr/bin/env bash` → 視為 Bash 語法基準。
  - `#!/bin/sh` → 僅使用 POSIX 語法（避免 `[[ ]]`、`declare -A`）。

---

## 詞彙與術語（外部參照）

- 本檔不內嵌詞彙表，統一參照 `.github/copilot-vocabulary.yaml`。
- 若詞彙衝突，以 vocabulary 檔為準。
- forbidden / preferred / mapping / normalization 詳見該檔。

---

## 8. Review Checklist

- [ ] 通過 `shellcheck` 驗證
- [ ] 無未加引號的變數展開
- [ ] 有 `set -euo pipefail`
- [ ] 所有外部命令有錯誤檢查
- [ ] 無多餘 `sudo` 或 `eval`
- [ ] 幫助訊息與參數解析正常

---

📁 放置路徑：
```
.github/bash.instructions.md
```
