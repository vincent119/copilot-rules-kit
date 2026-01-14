---
name: skill-creator
description: 指導如何創建有效的技能。當使用者想要創建新技能（或更新現有技能）以擴展 Claude 的能力，包括專門知識、工作流程或工具整合時，應使用此技能。
license: Complete terms in LICENSE.txt
---

# 技能創建者 (Skill Creator)

此技能提供創建有效技能的指導。

## 關於技能 (About Skills)

技能是模組化、獨立的套件，通過提供專門知識、工作流程和工具來擴展 Claude 的能力。將它們視為特定領域或任務的「入門指南」——它們將 Claude 從通用代理轉變為配備了任何模型都無法完全擁有的程序性知識的專用代理。

### 技能提供什麼

1. **專門工作流程 (Specialized workflows)** - 特定領域的多步驟程序
2. **工具整合 (Tool integrations)** - 處理特定檔案格式或 API 的說明
3. **領域專長 (Domain expertise)** - 公司特定的知識、架構、業務邏輯
4. **打包資源 (Bundled resources)** - 用於複雜和重複任務的腳本、參考資料和資產

## 核心原則 (Core Principles)

### 簡潔是關鍵 (Concise is Key)

上下文視窗 (Context window) 是公共財。技能與 Claude 需要的其他所有內容共享上下文視窗：系統提示、對話歷史、其他技能的元數據以及實際的使用者請求。

**預設假設：Claude 已經非常聰明。** 僅添加 Claude 尚未擁有的上下文。質疑每一條資訊：「Claude 真的需要這個解釋嗎？」以及「這段文字值得它的 token 成本嗎？」

偏好簡潔的範例，而非冗長的解釋。

### 設定適當的自由度 (Set Appropriate Degrees of Freedom)

將具體程度與任務的脆弱性和可變性相匹配：

**高自由度（基於文字的指令）**：當多種方法都有效、決策取決於背景或啟發法引導方法時使用。

**中等自由度（偽代碼或帶參數的腳本）**：當存在偏好的模式、可接受某些變化或配置影響行為時使用。

**低自由度（特定腳本，少量參數）**：當操作脆弱且容易出錯、一致性至關重要或必須遵循特定順序時使用。

將 Claude 想像成在探索路徑：一座狹窄的橋樑需要特定的護欄（低自由度），而開闊的田野允許許多路線（高自由度）。

### 技能的解剖結構 (Anatomy of a Skill)

每個技能包含一個必要的 `SKILL.md` 檔案和可選的打包資源：

```bash
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter metadata (required)
│   │   ├── name: (required)
│   │   └── description: (required)
│   └── Markdown instructions (required)
└── Bundled Resources (optional)
    ├── scripts/          - Executable code (Python/Bash/etc.)
    ├── references/       - Documentation intended to be loaded into context as needed
    └── assets/           - Files used in output (templates, icons, fonts, etc.)
```

#### SKILL.md (必備)

每個 `SKILL.md` 包含：

- **Frontmatter** (YAML)：包含 `name` 和 `description` 欄位。這些是 Claude 讀取以決定何時使用技能的唯一欄位，因此清晰且全面地描述技能是什麼以及何時使用它非常重要。
- **Body** (Markdown)：使用技能的說明和指導。僅在技能觸發後（如果有的話）才載入。

#### 打包資源 (可選)

##### Scripts (`scripts/`)

用於需要確定性可靠性或重複重寫的任務的可執行代碼（Python/Bash 等）。

- **何時包含**：當相同的代碼被重複重寫或需要確定性可靠性時
- **範例**：用於 PDF 旋轉任務的 `scripts/rotate_pdf.py`
- **優點**：Token 高效、確定性、無需載入上下文即可執行
- **注意**：腳本可能仍需要 Claude 閱讀以進行修補或環境特定的調整

##### References (`references/`)

旨在根據需要載入上下文以告知 Claude 過程和思維的文件和參考資料。

- **何時包含**：供 Claude 工作時參考的文件
- **範例**：用於財務架構的 `references/finance.md`、用於公司 NDA 模板的 `references/mnda.md`、用於公司政策的 `references/policies.md`、用於 API 規格的 `references/api_docs.md`
- **使用案例**：資料庫架構、API 文件、領域知識、公司政策、詳細工作流程指南
- **優點**：保持 `SKILL.md` 精簡，僅在 Claude 確定需要時載入
- **最佳實務**：如果檔案很大（>10k 字），請在 `SKILL.md` 中包含 grep 搜尋模式
- **避免重複**：資訊應存在於 `SKILL.md` 或參考檔案中，而非兩者皆有。傾向於將詳細資訊放在參考檔案中，除非它對技能來說是真正的核心——這能保持 `SKILL.md` 精簡，同時讓資訊可被發現而不佔用上下文視窗。僅在 `SKILL.md` 中保留必要的程序說明和工作流程指導；將詳細的參考資料、架構和範例移動到參考檔案。

##### Assets (`assets/`)

不打算載入上下文，而是用於 Claude 產生的輸出中的檔案。

- **何時包含**：當技能需要用於最終輸出的檔案時
- **範例**：用於品牌資產的 `assets/logo.png`、用於 PowerPoint 模板的 `assets/slides.pptx`、用於 HTML/React 樣板的 `assets/frontend-template/`、用於排版的 `assets/font.ttf`
- **使用案例**：模板、圖像、圖標、樣板代碼、字體、被複製或修改的範例文件
- **優點**：將輸出資源與文件分離，使 Claude 能夠使用檔案而無需將它們載入上下文

#### 技能中不應包含什麼

技能應僅包含直接支援其功能的基本檔案。**請勿**創建無關的文件或輔助檔案，包括：

- README.md
- INSTALLATION_GUIDE.md
- QUICK_REFERENCE.md
- CHANGELOG.md
- etc.

技能應僅包含 AI 代理完成手頭工作所需的資訊。它不應包含關於創建過程、設定和測試程序、使用者導向文件等的輔助上下文。創建額外的文件只會增加混亂和困惑。

### 漸進式揭露設計原則 (Progressive Disclosure Design Principle)

技能使用三級載入系統來有效地管理上下文：

1. **Metadata (name + description)** - 總是在上下文中 (~100 字)
2. **SKILL.md body** - 當技能觸發時 (<5k 字)
3. **Bundled resources** - 根據 Claude 的需要（無限制，因為腳本可以在不讀入上下文視窗的情況下執行）

#### 漸進式揭露模式

將 `SKILL.md` 本體保持在 500 行以內，以最小化上下文膨脹。接近此限制時，將內容拆分為單獨的檔案。當將內容拆分到其他檔案時，在 `SKILL.md` 中引用它們並清楚描述何時閱讀它們非常重要，以確保技能的使用者知道它們的存在以及何時使用它們。

**關鍵原則：** 當技能支援多種變體、框架或選項時，僅在 `SKILL.md` 中保留核心工作流程和選擇指導。將變體特定的細節（模式、範例、配置）移動到單獨的參考檔案中。

##### Pattern 1: High-level guide with references

```markdown
# PDF Processing

## Quick start

Extract text with pdfplumber:
[code example]

## Advanced features

* **Form filling**: See [FORMS.md](FORMS.md) for complete guide
* **API reference**: See [REFERENCE.md](REFERENCE.md) for all methods
* **Examples**: See [EXAMPLES.md](EXAMPLES.md) for common patterns
```

Claude 僅在需要時載入 `FORMS.md`、`REFERENCE.md` 或 `EXAMPLES.md`。

##### Pattern 2: Domain-specific organization

對於擁有多個領域的技能，按領域組織內容以避免載入不相關的上下文：

```bash
bigquery-skill/
├── SKILL.md (overview and navigation)
└── reference/
    ├── finance.md (revenue, billing metrics)
    ├── sales.md (opportunities, pipeline)
    ├── product.md (API usage, features)
    └── marketing.md (campaigns, attribution)
```

當使用者詢問銷售指標時，Claude 僅讀取 `sales.md`。

同樣，對於支援多個框架或變體的技能，按變體組織：

```bash
cloud-deploy/
├── SKILL.md (workflow + provider selection)
└── references/
    ├── aws.md (AWS deployment patterns)
    ├── gcp.md (GCP deployment patterns)
    └── azure.md (Azure deployment patterns)
```

當使用者選擇 AWS 時，Claude 僅讀取 `aws.md`。

##### Pattern 3: Conditional details

顯示基本內容，連結到進階內容：

```markdown
# DOCX Processing

## Creating documents

Use docx-js for new documents. See [DOCX-JS.md](DOCX-JS.md).

## Editing documents

For simple edits, modify the XML directly.

* **For tracked changes**: See [REDLINING.md](REDLINING.md)
* **For OOXML details**: See [OOXML.md](OOXML.md)
```

Claude 僅在使用者需要這些功能時讀取 `REDLINING.md` 或 `OOXML.md`。

**重要準則：**

- **避免深層嵌套引用** - 保持引用距離 `SKILL.md` 一層深度。所有參考檔案應直接從 `SKILL.md` 連結。
- **結構化較長的參考檔案** - 對於超過 100 行的檔案，在頂部包含目錄，以便 Claude 在預覽時看到完整範圍。

## 技能創建過程 (Skill Creation Process)

技能創建涉及以下步驟：

1. 通過具體範例理解技能
2. 規劃可重用的技能內容（腳本、參考資料、資產）
3. 初始化技能（運行 `init_skill.py`）
4. 編輯技能（實作資源並編寫 `SKILL.md`）
5. 打包技能（運行 `package_skill.py`）
6. 根據實際使用進行迭代

依序遵循這些步驟，只有在有明確理由不適用時才跳過。

### Step 1: 通過具體範例理解技能

僅當技能的使用模式已被清楚理解時才跳過此步驟。即使在處理現有技能時，這仍然很有價值。

要創建有效的技能，請清楚理解技能將如何被使用的具體範例。這種理解可以來自直接的使用者範例或經使用者回饋驗證的生成範例。

例如，在構建圖像編輯器技能時，相關問題包括：

- 「圖像編輯器技能應該支援哪些功能？編輯、旋轉，還有其他嗎？」
- 「你能舉一些這個技能如何被使用的例子嗎？」
- 「我可以想像使用者要求像『去除這張圖片的紅眼』或『旋轉這張圖片』這樣的事情。你還能想像這個技能被用於其他方式嗎？」
- 「使用者說什麼會觸發這個技能？」

為避免讓使用者不知所措，避免在單條訊息中問太多問題。從最重要的問題開始，並根據需要進行後續追問以獲得更好的效果。

當對技能應支援的功能有清晰的認識時，結束此步驟。

### Step 2: 規劃可重用的技能內容

為了將具體範例轉化為有效的技能，通過以下方式分析每個範例：

1. 考慮如何從頭開始執行該範例
2. 識別在重複執行這些工作流程時，哪些腳本、參考資料和資產會有幫助

範例：當構建一個 `pdf-editor` 技能來處理像「幫我旋轉這個 PDF」這樣的查詢時，分析顯示：

1. 旋轉 PDF 需要每次重新編寫相同的代碼
2. 一個 `scripts/rotate_pdf.py` 腳本會有助於存儲在技能中

範例：當設計一個 `frontend-webapp-builder` 技能來處理像「幫我建立一個待辦事項應用」或「幫我建立一個儀表板來追蹤我的步數」這樣的查詢時，分析顯示：

1. 編寫前端 Web 應用需要每次使用相同的樣板 HTML/React
2. 一個包含樣板 HTML/React 專案檔案的 `assets/hello-world/` 模板會有助於存儲在技能中

範例：當構建一個 `big-query` 技能來處理像「今天有多少使用者登入？」這樣的查詢時，分析顯示：

1. 查詢 BigQuery 需要每次重新發現資料表架構和關係
2. 一個記錄資料表架構的 `references/schema.md` 檔案會有助於存儲在技能中

要建立技能的內容，分析每個具體範例以創建要包含的可重用資源清單：腳本、參考資料和資產。

### Step 3: 初始化技能

此時，是實際創建技能的時候了。

僅當正在開發的技能已經存在，且需要迭代或打包時才跳過此步驟。在這種情況下，繼續下一步。

當從頭開始創建新技能時，務必運行 `init_skill.py` 腳本。該腳本方便地生成一個新的模板技能目錄，自動包含技能所需的一切，使技能創建過程更加高效和可靠。

用法：

```bash
scripts/init_skill.py <skill-name> --path <output-directory>
```

該腳本：

- 在指定路徑創建技能目錄
- 生成帶有適當 frontmatter 和 TODO 佔位符的 `SKILL.md` 模板
- 創建範例資源目錄：`scripts/`、`references/` 和 `assets/`
- 在每個目錄中添加可自定義或刪除的範例檔案

初始化後，根據需要自定義或移除生成的 `SKILL.md` 和範例檔案。

### Step 4: 編輯技能

當編輯（新生成或現有的）技能時，請記住該技能是為了讓另一個 Claude 實例使用而創建的。包含對 Claude 有益且非顯而易見的資訊。考慮哪些程序性知識、領域特定細節或可重用資產將幫助另一個 Claude 實例更有效地執行這些任務。

#### 學習經過驗證的設計模式

根據你的技能需求參考這些實用的指南：

- **多步驟過程**：參閱 `references/workflows.md` 了解順序工作流程和條件邏輯
- **特定輸出格式或品質標準**：參閱 `references/output-patterns.md` 了解模板和範例模式

這些檔案包含有效技能設計的既定最佳實務。

#### 從可重用的技能內容開始

要開始實作，從上面識別的可重用資源開始：`scripts/`、`references/` 和 `assets/` 檔案。注意此步驟可能需要使用者輸入。例如，當實作 `brand-guidelines` 技能時，使用者可能需要提供用於存儲在 `assets/` 中的品牌資產或模板，或用於存儲在 `references/` 中的文件。

添加的腳本必須通過實際運行來測試，以確保沒有錯誤並且輸出符合預期。如果有許多類似的腳本，只需測試代表性的樣本，以確保對它們都能工作有信心，同時平衡完成時間。

應刪除技能不需要的任何範例檔案和目錄。初始化腳本在 `scripts/`、`references/` 和 `assets/` 中創建範例檔案以演示結構，但大多數技能不需要全部。

#### 更新 SKILL.md

**寫作準則：** 始終使用祈使句/不定式。

##### Frontmatter

編寫帶有 `name` 和 `description` 的 YAML frontmatter：

- `name`：技能名稱
- `description`：這是技能的主要觸發機制，並幫助 Claude 理解何時使用該技能。
  - 包含技能做什麼以及何時使用它的具體觸發因素/背景。
  - 在此處包含所有「何時使用」資訊 - 不要在本文中。本文僅在觸發後載入，因此本文中的「何時使用此技能」章節對 Claude 沒有幫助。
  - `docx` 技能的範例描述：「全面的文件創建、編輯和分析，支援追蹤修訂、註解、格式保留和文字提取。當 Claude 需要處理專業文件 (.docx 檔案) 時使用：(1) 創建新文件，(2) 修改或編輯內容，(3) 處理追蹤修訂，(4) 添加註解，或任何其他文件任務」

不要在 YAML frontmatter 中包含任何其他欄位。

##### Body

編寫使用技能及其打包資源的說明。

### Step 5: 打包技能

一旦技能開發完成，必須將其打包成可分發的 .skill 檔案以與使用者共享。打包過程會首先自動驗證技能，以確保其符合所有要求：

```bash
scripts/package_skill.py <path/to/skill-folder>
```

可選的輸出目錄規格：

```bash
scripts/package_skill.py <path/to/skill-folder> ./dist
```

打包腳本將：

1. 自動 **驗證** 技能，檢查：

- YAML frontmatter 格式和必要欄位
- 技能命名慣例和目錄結構
- 描述的完整性和品質
- 檔案組織和資源引用

1. 如果驗證通過，**打包** 技能，創建以技能命名的 .skill 檔案（例如 `my-skill.skill`），其中包含所有檔案並保持分發所需的正確目錄結構。.skill 檔案是帶有 .skill 副檔名的 zip 檔案。

如果驗證失敗，腳本將報告錯誤並退出而不創建套件。修復任何驗證錯誤並再次運行打包指令。

### Step 6: 迭代

測試技能後，使用者可能會要求改進。這通常發生在使用技能後，對技能表現有新鮮的上下文。

**迭代工作流程：**

1. 在實際任務上使用技能
2. 注意掙扎或效率低下的地方
3. 識別 `SKILL.md` 或打包資源應如何更新
4. 實作變更並再次測試
