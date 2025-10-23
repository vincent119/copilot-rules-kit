---
description: '全域 Copilot / VS Code Agent 專案產生與編輯規範'
applyTo: '**/*'
extends:
  common: ".github/copilot-common.md"
  vocabulary: ".github/copilot-vocabulary.yaml"
---

# Copilot / Agent 全域規範

本檔延伸自 .github/copilot-common.md 與 .github/copilot-vocabulary.yaml，統一專案產出行為與用詞規範。

---

## 通用原則

- **產出內容需可直接執行或編譯**（非片段）。
- **保留現有專案結構與命名慣例**。
- 修改時應「延續風格」而非「覆蓋」。
- 禁止生成重複的 LICENSE、README 或模組段落。
- 所有程式碼須通過：
  - 編譯器（compile）
  - Linter
  - Formatter
- 預設註解語言為英文（必要時補繁體中文）。
- 禁止使用 emoji、裝飾符號、非 ASCII 字元。
- **縮排：1 個 Tab = 2 空白。**

---

## 檔案操作規則

- 若目標檔案已存在：
  - 僅修改必要部分，保留未指定內容。
  - 不可重複新增 `package`、`module` 或 `import` 區段。
- 若需重寫檔案：
  - 確認 package/module 名稱一致。
  - 保留檔案開頭註解與版權資訊。
- 修改多檔案時：
  - 附上每個檔案變更摘要與目的。

---

## 智慧產生行為

- 優先採用語言內建或標準解法。
- 不引入外部套件除非確有必要且具可維護性。
- 程式碼應模組化、避免全域變數或過長函式。
- 生成新類別／函式時，附上最小範例。
- 配置檔（YAML/JSON）應：
  - 保留原有縮排與格式。
  - 縮排統一為 1 Tab（2 空白寬）。

---

## 註解與文件

- 註解應著重「為何」而非「怎麼做」。
- 文件（README、架構圖等）需同步更新。
- 註解語言統一為英文，必要時補繁中。
- 文件內容需簡潔且可直接渲染。

---

## 各語言特化設定（自動對應）

| 檔案名稱 | 適用領域 |
|-----------|-----------|
| `go.instructions.md` | Go（`gofmt`, `goimports`, idiomatic Go） |
| `ts.instructions.md` | TypeScript（ESLint, Prettier） |
| `yaml.instructions.md` | YAML / IaC（Kubernetes, Pulumi, CloudFormation） |
| `helm.instructions.md` | Helm Chart / values.yaml |
| `python.instructions.md` | Python（PEP8, Black, mypy） |

---

## 詞彙與術語（外部參照）

- 本檔不再內嵌詞彙表；請統一參照 `.github/copilot-vocabulary.yaml`。
- 若詞彙衝突，以 vocabulary 檔為準。
- forbidden / preferred / mapping / normalization 詳見該檔。

---

## Review Checklist

- [ ] 程式碼可編譯 / 可執行
- [ ] 格式化一致（1 Tab = 2 空白）
- [ ] 保留 header、license、註解
- [ ] 無未使用變數與多餘 import
- [ ] 語意與既有邏輯一致
- [ ] 文件同步更新

---

建議放置路徑：
```
.github/
├─ copilot-instructions.md          ← 全域設定（此檔案）
├─ copilot-instructions.yaml        ← 同步給 Agent 使用
├─ copilot-chat-instructions.md     ← Chat 模式專用
├─ go.instructions.md
├─ ts.instructions.md
├─ yaml.instructions.md
├─ helm.instructions.md
└─ python.instructions.md
```
