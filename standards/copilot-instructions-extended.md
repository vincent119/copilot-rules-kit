---
description: '全域 Copilot / VS Code Agent 專案產生與編輯規範（含擴充詞彙映射）'
applyTo: '**/*'
extends:
  common: ".github/copilot-common.md"
  vocabulary: ".github/copilot-vocabulary.yaml"
---

# 專案通用 Copilot / Agent 指南

This document extends from `copilot-common.md` and `copilot-vocabulary.yaml`.

---

## 通用原則

- **產出內容需可直接執行或編譯**（非片段）。
- **保留現有專案結構與命名慣例**。
- 修改時應「延續」風格，而非「覆蓋」風格。
- 所有程式碼需能通過編譯器、linter 與格式化工具。
- 文件預設使用 **英文註解**；僅在需要時翻譯為中文。
- 禁用 emoji、裝飾符號或非 ASCII 控制字元。
- 禁止生成多餘的 LICENSE、README 或 package 重複段落。
- **縮排規範：使用 1 個 Tab，等同 2 空白寬度**（editor.tabSize = 2）。

---

## 檔案操作規則

- 若目標檔案已存在：
  - 僅在必要時修改或插入內容。
  - 不可新增重複的 `package`、`module`、`import` 區段。
- 若需重寫檔案：
  - 確認 package/module 名稱一致。
  - 檔案開頭保留標準註解或版權資訊。
- 修改多檔案時，請附上每個檔案的摘要與變更目的。

---

## 智慧產生行為

- 優先採用語言原生庫與標準解法。
- 不引入外部套件，除非需求明確且具可維護性。
- 程式碼應模組化（避免全域變數與長函式）。
- 生成新類別或函式時，需附最小範例。
- 若為配置（YAML/JSON），保持原有縮排與格式（1 Tab = 2 spaces）。

---

## 註解與文件

- 註解應簡潔、準確、描述「為何」而非「怎麼做」。
- 文件需同步更新（如 README、架構圖等）。
- 註解語言統一為英文，必要時補充繁中翻譯。

---

## 各語言特化（自動對應 `*.instructions.md`）

- `go.instructions.md` → 適用於 Go 語言（gofmt, goimports, idiomatic Go）
- `ts.instructions.md` → 適用於 TypeScript 專案（ESLint, Prettier）
- `yaml.instructions.md` → 適用於 IaC（Kubernetes, Pulumi, CloudFormation）
- `helm.instructions.md` → 適用於 Helm Chart 模板與 values.yaml
- `python.instructions.md` → 適用於 Python 專案（PEP8, Black, mypy）

---

## 詞彙與術語（外部參照）

- 本檔不再內嵌詞彙表；請統一參照 `.github/copilot-vocabulary.yaml`
- 若詞彙衝突，以 vocabulary 檔為準。
- forbidden/mapping/normalization 詳見該檔。

---

## Review Checklist

- [ ] 確認程式碼可編譯 / 可執行
- [ ] 縮排一致（1 Tab = 2 空白）
- [ ] 格式化遵循語言標準
- [ ] 保留原始檔案 header、license、註解
- [ ] 無多餘匯入或未使用變數
- [ ] 語意與邏輯與既有專案一致
- [ ] 文件與註解同步更新

---

建議放置路徑：
```
.github/
 ├─ copilot-instructions.md   ← 全域設定（此檔案）
 ├─ go.instructions.md        ← Go 專用
 ├─ ts.instructions.md        ← TypeScript 專用（選用）
 ├─ yaml.instructions.md      ← YAML / IaC 專用（選用）
 ├─ helm.instructions.md      ← Helm 專用（選用）
 └─ python.instructions.md    ← Python 專用（選用）
```
