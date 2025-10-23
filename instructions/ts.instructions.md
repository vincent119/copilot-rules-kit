---
description: 'TypeScript / JavaScript 編碼規範與自動產生指引'
applyTo: '**/*.ts,**/*.tsx,**/*.js,**/*.jsx'
---

本檔延伸自 `.github/standards/copilot-common.md` 與 `.github/standards/copilot-vocabulary.yaml`，僅針對 TypeScript / JavaScript 特有規範補充。

# TypeScript / JavaScript 編碼指南（for Copilot & VS Code Agent）

本文件定義 TypeScript / JavaScript 檔案的撰寫、修改與自動生成規範，適用於前端、Node.js、Pulumi、Serverless 或 SDK 專案。
所有生成結果必須 **語法正確、型別安全、可編譯通過、無 ESLint 錯誤**。

---

## 通用原則

- 使用 **ESNext 語法**，並保持向下相容（例如 `async/await`, 解構, 模組化 import）。
- 以 **TypeScript 為優先**，JS 僅作為輕量腳本用途。
- 嚴格遵循 ESLint / Prettier 設定，產出需通過 `eslint --fix`。
- 每個檔案只允許一個 `export default`。
- 僅在必要時產生註解，註解使用英文。

---

## 型別與結構

- 所有函式、常數與物件 **必須具明確型別**。
  ```ts
  const user: User = { id: 1, name: 'Alice' };
  ```
- 函式簽名需明確標註回傳型別。
  ```ts
  function getUser(id: number): Promise<User> {}
  ```
- 不使用 `any`、`Object`、`Function`，改用具體型別或泛型。
- 對外輸出 API 時使用 `interface`，內部結構可用 `type`。
- 型別命名採 **PascalCase**（例如 `UserInfo`、`ApiResponse`）。
- 常數採 **SCREAMING_SNAKE_CASE**；變數採 **camelCase**。
- 類別名稱與檔名保持一致。

---

## 模組與匯入規範

- 採用 ES Modules (`import` / `export`)。
- 匯入順序：
  1. Node.js / 外部套件
  2. 專案內模組（`@/` alias 優先於相對路徑）
  3. 本地相對路徑
- 匯入樣式：
  ```ts
  import fs from 'fs';
  import { join } from 'path';
  import { createUser } from '@/services/user';
  import type { User } from '@/types';
  ```
- 不使用 wildcard import（`import * as X`），除非為明確 namespace。
- 絕不遺留未使用的匯入（Copilot 需自動清理）。

---

## 程式風格

- 每行不超過 120 字元。
- 使用單引號 `'...'`。
- 物件最後一項保留逗號（trailing comma）。
- 空白縮排：**2 spaces**。
- 使用 `const` 優先於 `let`；禁止使用 `var`。
- 使用模板字串取代字串串接。
- 使用明確布林判斷（例如 `if (arr.length > 0)`）。
- 避免巢狀過深，可早期回傳：
  ```ts
  if (!data) return null;
  ```
- 錯誤訊息以小寫開頭，不加句號。

---

## 錯誤處理與非同步

- 所有 `await` 操作需包含錯誤處理：
  ```ts
  try {
    const res = await fetch(url);
  } catch (err) {
    console.error('fetch failed:', err);
  }
  ```
- 錯誤需拋出明確型別：
  ```ts
  throw new Error('invalid user id');
  ```
- 禁止未處理的 Promise（使用 `void` 明示忽略或 `await` 等待）：
  ```ts
  void doSomethingAsync();
  ```

---

## React / 前端專用（若適用）

- Functional Components 優先於 Class Components。
- Component 名稱採 **PascalCase**。
- Hooks 命名以 `use` 開頭。
- Props 與 State 必須具型別：
  ```tsx
  interface Props {
    title: string;
    onClick?: () => void;
  }
  ```
- 嚴禁在 render 階段執行副作用。
- 嚴禁使用 `any` 或隱式型別 Props。
- CSS-in-JS、Tailwind、styled-components 需統一風格。

---

## Pulumi / IaC 中的 TypeScript

- 資源名稱保持一致命名規則（`snake_case` → YAML 對應）。
- 生成的 Pulumi TypeScript 程式碼必須符合：
  ```ts
  new aws.s3.Bucket('myBucket', {
    acl: 'private',
    tags: { Environment: 'UAT' },
  });
  ```
- 禁止硬編碼 ARN、ID、Region，使用輸入參數或 `pulumi.Config()`。
- 輸出（Outputs）名稱與 YAML Stack 中一致。
- 不修改 Pulumi 自動生成區段。

---

## 詞彙與術語（外部參照）

本檔不再內嵌詞彙表；統一參照 `.github/copilot-vocabulary.yaml`。請遵循其中 forbidden/preferred/mapping 規則。如與既有程式碼命名衝突，應在變更說明中說明並提供過渡策略。

## Review Checklist

- [ ] 無 `any` 型別
- [ ] 縮排與 Prettier 一致（2 spaces）
- [ ] ESLint 無錯誤 (`eslint --max-warnings=0`)
- [ ] 所有函式與介面具明確型別
- [ ] React 元件（若有）無副作用
- [ ] 非同步操作皆具錯誤處理
- [ ] Pulumi 程式可成功部署（若適用）

---

放置路徑：
```
.github/ts.instructions.md
```
