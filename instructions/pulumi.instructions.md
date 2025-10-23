---
description: 'Pulumi（YAML）專用產生與編輯規範：resources / options / providers / stacks / config / secrets'
applyTo: 'Pulumi.yaml,Pulumi.*.yaml,**/Pulumi.yaml,**/Pulumi.*.yaml,**/*.pulumi.yaml'
---

本檔延伸自 `.github/standards/copilot-common.md` 與 `.github/copilot-vocabulary.yaml`，僅針對 Pulumi YAML 特有規範補充。

# Pulumi for YAML 指南（for Copilot & VS Code Agent）

本文件規範 **Pulumi YAML** 程式與 Stack 設定檔（`Pulumi.yaml`, `Pulumi.<stack>.yaml`）的產生與修改行為，確保結果 **可被 Pulumi 成功解析與部署**，不破壞既有資源狀態。

> 本指南僅針對 **YAML 版 Pulumi 程式 / 設定**；若為 TypeScript/Go 程式，請改用對應的 `ts.instructions.md` / `go.instructions.md`。

---

## 基本原則

- **保持 key 順序與縮排（2 spaces）**；不得自動重排。
- 僅修改指定區塊；**不得刪除未知欄位** 或自動合併多個檔案。
- 不引入未支援的屬性；所有屬性名稱需符合對應 **Provider 資源 Schema**。
- 若新增資源，需同時考慮 **相依 / 命名 / provider / options**，避免破壞現有拓樸。

---

## 檔案類型

- `Pulumi.yaml`：專案定義（`name`, `runtime`, `description`，可含 `template`）。
- `Pulumi.<stack>.yaml`：Stack 設定（`config:`、`encryptionsalt` 等）。
- YAML 程式檔（以 Pulumi YAML 形式描述 `resources:`、`outputs:` 等，檔名可自訂）。

> **不要** 自動把 `Pulumi.yaml` 與 `Pulumi.<stack>.yaml` 合併到同一檔。

---

## Pulumi YAML 程式檔結構（最小骨架）

```yaml
# my-infra.pulumi.yaml
name: my-project                  # 專案名（與 Pulumi.yaml 一致）
runtime: yaml
description: Base infra by YAML

resources:
  myBucket:
    type: aws:s3/bucket:Bucket
    properties:
      acl: private
      tags:
        Environment: uat

outputs:
  bucketName: ${myBucket.id}
```

**規則**：
- `resources` / `outputs` 為頂層；每個資源 key（例：`myBucket`）僅使用 **a-z0-9-** 或 **camelCase**。
- 嵌入參照使用 **`${name.property}`**（單層或巢狀）。
- 插值（interpolation）不可被加引號破壞字面量（保留原樣）。

---

## `resources` 詳解

每個資源：

```yaml
resources:
  <logicalName>:
    type: <pkg>:<module>/<kind>:<Type>   # 例：aws:s3/bucket:Bucket
    properties:                          # 對應 provider schema
      ...
    options:
      provider: ${providers.awsUat}      # 指向下方 providers 物件或外部 provider
      protect: false                     # 重要資源可設 true
      dependsOn:
        - ${anotherRes}                  # 明確相依（避免競速）
      ignoreChanges:
        - tags                           # 避免不必要替換
      replaceOnChanges: []               # 僅當特定屬性變動才取代
      parent: ${parentRes}               # 階層化

  # 自訂 Provider（建議集中）
  providers:
    awsUat:
      type: pulumi:providers:aws
      properties:
        region: ap-northeast-1
```

**注意**：
- `options` 下的 key，與語言 SDK 同名（`protect`、`dependsOn`、`ignoreChanges`、`replaceOnChanges`、`provider`、`parent`）。
- `provider` 可引用 `providers` 內自訂 provider **或** 由外部語言程式建立之 provider。
- 不要新增未知的 `options` key。

---

## Cross‑ref / 變數與插值

- 參照另一資源屬性：`${resName.property}`（例：`${myBucket.id}`）。
- 參照輸入陣列 / 物件：`${resName.outputs[0].name}`（支援索引與巢狀）。
- 參照 Stack Config：`${pulumi.config.<ns>:<key>}` 或直接從 `config:` 提取。

**避免**：在 `properties` 中以錯誤大小寫或錯誤路徑存取 provider 屬性。

---

## `Pulumi.<stack>.yaml`（Stack 設定與 Secrets）

```yaml
config:
  aws:region: ap-northeast-1
  project:env: "uat"
  project:dbPassword:
    secure: v1:...base64cipher...      # 使用 `pulumi config set --secret`
```

**規則**：
- Secret 值必須以 `secure:` 儲存；**禁止** 明文密碼 / 金鑰。
- 名稱空間（namespace）慣例：`<project>:` 前綴（例如 `project:`、`im:`）。
- **不要** 修改 `encryptionsalt`；若變更會導致 Secret 解密失敗。

---

## 部署安全守則

- 新增 / 調整資源時，**一律** 明確：
  - `dependsOn`（若有隱性相依）
  - `provider`（跨 Region / 帳號時必填）
  - 關鍵資源設 `protect: true`
- 盡量使用 `ignoreChanges` 避免「飄移」造成替換。
- 變更具破壞性屬性前，先以 `pulumi preview` 驗證 **Diff**。

---

## 常見片段（Snippets）

### 1) S3 存取日誌桶（阻擋公有、保留版）
```yaml
resources:
  logsBucket:
    type: aws:s3/bucket:Bucket
    properties:
      acl: log-delivery-write
      versioning:
        enabled: true
      serverSideEncryptionConfiguration:
        rule:
          applyServerSideEncryptionByDefault:
            sseAlgorithm: AES256
      forceDestroy: false
    options:
      protect: true
```

### 2) 指定 Provider 與相依
```yaml
resources:
  providers:
    awsUat:
      type: pulumi:providers:aws
      properties:
        region: ap-northeast-1

  table:
    type: aws:dynamodb/table:Table
    properties:
      attributes:
        - name: id
          type: S
      hashKey: id
      billingMode: PAY_PER_REQUEST
    options:
      provider: ${providers.awsUat}
      dependsOn:
        - ${logsBucket}
```

### 3) 跨資源輸出給 Stack
```yaml
outputs:
  tableName: ${table.name}
  logsBucketArn: ${logsBucket.arn}
```

---

## 詞彙與術語（外部參照）

本檔不再內嵌詞彙表；統一參照 `.github/copilot-vocabulary.yaml`。請遵循其中 forbidden/preferred/mapping 規則。如與既有程式碼命名衝突，應在變更說明中說明並提供過渡策略。

##  Copilot / Agent 產生行為

- **不要** 重排 `resources`、`options`、`providers` 的 key 順序。
- 新增資源時：同時產出 `options` 與必要 `dependsOn`；**不要** 默認省略。
- 修改時：僅更新目標屬性；**不得** 移除他人手動加入之 `ignoreChanges` 等選項。
- 若參照 Stack Config：先檢查 `Pulumi.<stack>.yaml` 是否已有對應 key，若無請提示再新增。

---
## 詞彙與術語（外部參照）

本檔不再內嵌詞彙表；統一參照 `.github/copilot-vocabulary.yaml`。請遵循其中 forbidden/preferred/mapping 規則。如與既有程式碼命名衝突，應在變更說明中說明並提供過渡策略。

## Review Checklist

- [ ] YAML 縮排 2 spaces、無 Tab / NBSP
- [ ] `type` 與 `properties` 符合 Provider Schema
- [ ] 適當設定 `provider` / `dependsOn` / `protect`
- [ ] Secret 以 `secure:` 儲存於 `Pulumi.<stack>.yaml`
- [ ] `pulumi preview` Diff 合理、無意外替換
- [ ] `outputs:` 名稱與實際引用一致

---

放置路徑：
```
.github/pulumi.instructions.md
```
