---
description: 'Python 編碼規範與自動產生指引（適用 Copilot / VS Code Agent）'
applyTo: '**/*.py'
---

本檔延伸自 `.github/copilot-common.md` 與 `.github/copilot-vocabulary.yaml`，僅針對 Python 特有規範補充。

# Python 編碼指南（for Copilot & VS Code Agent）

本文件規範 Python 程式碼的產生與修改行為，確保 **可執行、可維護、可測試、型別友善**。

---

## 通用原則

- 目標版本：**Python 3.11+**（無相容需求時）。
- 產出必須 **可直接執行或匯入**（非片段），並通過格式化 / Lint。
- **嚴禁** 引入不必要的第三方套件；優先使用標準函式庫。
- 單檔職責單一，避免過度長檔案（> 500 行應拆分）。

---

## 專案與檔案結構

- 套件結構：
  ```text
  pkg_name/
    __init__.py
    module_a.py
    subpkg/
      __init__.py
      feature.py
  ```
- 腳本檔需放 `scripts/` 或 `cmd/`，可執行檔加 shebang：
  ```python
  #!/usr/bin/env python3
  ```
- 檔案編碼使用 UTF-8（預設即可，不需額外宣告）。

---

## 風格與格式化

- **Black**：統一格式化（88 列寬，或專案設定）。
- **isort**：排序 import（profile = black）。
- **Ruff** 或 **Flake8**：靜態檢查（移除未使用變數 / 匯入）。
- Import 順序：
  1. 標準庫
  2. 第三方
  3. 專案內
- 命名規範：
  - 變數 / 函式：`snake_case`
  - 常數：`SCREAMING_SNAKE_CASE`
  - 類別：`PascalCase`
  - 私有：前置底線 `_internal`

---

## 型別註記（Typing）

- **全新程式**：公開函式與方法 **必須** 有型別註記。
- 使用 `typing` 與 `typing_extensions`（必要時）。
- `list[str]` 與 `dict[str, Any]` 取代 `List[str]` 舊寫法。
- 回傳 `None` 時明確標註：`-> None`。
- 不使用裸型別 `Any`；必要時以 `typing.Any` 並加註解說明原因。
- 啟用 `mypy`（或 Ruff 的 type-check 規則）建議設定：
  - `disallow_untyped_defs = True`
  - `warn_unused_ignores = True`
  - `warn_return_any = True`

---

## 程式結構與 API 設計

- **模組切割**：同一模組聚焦單一領域；跨模組共用抽成 utils。
- **函式**：避免超過 30 行；早期回傳降低巢狀。
- **資料模型**：優先 `dataclasses.dataclass`；需要驗證時用 Pydantic（可選）。
- **設定**：讀環境變數時集中於 `config.py`，提供預設值與驗證。
- **錯誤處理**：
  - 自訂例外繼承 `Exception`，名稱以 `Error` 結尾。
  - 加入語境：`raise ValueError(f"invalid id: {id_}")`。
  - **不要同時 log 並 re-raise**（避免重複紀錄）。

---

## I/O 與網路

- 檔案 I/O 使用 `with` 保障關閉：
  ```python
  with open(path, "r", encoding="utf-8") as f:
      data = f.read()
  ```
- HTTP Client：
  - 同步：`requests`；
  - 非同步：`aiohttp` 或 `httpx`（async）。
  - 統一封裝 client 類別：只放 base_url、timeout、重試策略與共用 header；**不得** 保存每次請求的暫態狀態。
- JSON：`json.loads/ dumps`，設定 `ensure_ascii=False` 保留中文。

---

## 非同步（Asyncio）

- 只在需要並行 I/O 時使用；CPU-bound 交給多處理或 C 擴充。
- 事件迴圈外層統一進入點：
  ```python
  import asyncio
  if __name__ == "__main__":
      asyncio.run(main())
  ```
- 任務管理使用 `asyncio.TaskGroup`（3.11+）或 `gather`。
- 任何 `await` 皆需錯誤處理或超時控制。

---

## Logging

- 使用標準庫 `logging`：
  ```python
  import logging
  logger = logging.getLogger(__name__)
  ```
- 不在函式庫層級設定全域 handler；由應用程式入口配置。
- 訊息以結構化欄位為主（若使用 `structlog` 可選）。

---

## 效能與記憶體

- 熱路徑避免重複配置 / 轉換；預先配置 regex、Session、連線池。
- 盡量使用生成器、`yield from` 減少峰值記憶體。
- 避免 `+` 串接字串，使用 `join` 或 `io.StringIO`。
- 批次處理 I/O、資料庫操作，加上超時與重試（指數退避）。

---

## 測試（pytest）

- 測試檔命名：`test_*.py`，函式 `test_xxx_yyy`。
- 使用 **pytest** 與 **pytest-cov**（或內建 `unittest`）。
- Table-driven 測試以 `pytest.mark.parametrize` 撰寫。
- 善用 `fixtures` 與 `tmp_path`、`monkeypatch`。
- CI 需跑：`pytest -q --maxfail=1 --disable-warnings`。

---

## 文件與 Docstring

- 公開 API 使用 **Google style** 或 **NumPy style** docstring，二擇一並一致。
  ```python
  def add(a: int, b: int) -> int:
      """Add two integers.

      Args:
          a: First number.
          b: Second number.

      Returns:
          Sum of a and b.
      """
  ```
- 只寫必要註解，解釋「為何」與邏輯取捨。

---

## 安全實務

- 永不在 repo 存放祕密；使用環境變數或 Vault / AWS Secrets Manager。
- 所有外部輸入需驗證與轉義；避免 `eval`、`exec`。
- 下載與執行檔案前驗證長度與雜湊（若適用）。

---

## 相依與打包

- 使用 `uv` / `pip-tools` / `poetry` 其中之一管理相依；若使用 pip：
  - `requirements.in` → `requirements.txt`（鎖定版本）。
  - `pip install -r requirements.txt --no-deps`（CI）。
- 發佈套件：採用 `pyproject.toml`（PEP 621）。

---

## 詞彙與術語（外部參照）

本檔不再內嵌詞彙表；統一參照 `.github/copilot-vocabulary.yaml`。請遵循其中 forbidden/preferred/mapping 規則。如與既有程式碼命名衝突，應在變更說明中說明並提供過渡策略。

## Copilot / Agent 智能產生行為

- **保留現有模組結構**；新增公開 API 時同步更新 `__all__`（若使用）。
- 產生新函式 / 類別時：提供最小可執行範例與單元測試樣板。
- 若檔案已存在同名成員 → 更新實作而非重複定義。
- 變更 I/O 介面時，**列出副作用**（路徑、環境變數、網路）。

---

## Review Checklist

- [ ] 通過 Black / isort / Ruff（或 Flake8）
- [ ] 公開 API 具型別註記與 Docstring
- [ ] 無未使用匯入與變數
- [ ] I/O 關閉與錯誤處理完整
- [ ] 非同步流程可等待且可中止
- [ ] 測試可重現（無外部依賴或已 mock）

---

放置路徑：
```
.github/python.instructions.md
```
