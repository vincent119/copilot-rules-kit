---
description: 'Helm Chart / Templates 產生與編輯規範（適用 Copilot / VS Code Agent）'
applyTo: '**/Chart.yaml,**/values.yaml,**/values/*.yaml,**/templates/**/*.yaml,**/charts/**,**/values.schema.json'
---
本檔延伸自 `.github/standards/copilot-common.md` 與 `.github/standards/copilot-vocabulary.yaml`，並針對 Helm Chart 特有部分進行補充。
本文件規範 **Helm Chart** 的結構、`values.yaml`、`templates/` 與相依管理，確保輸出可被 `helm lint` 與 `helm template` 正確解析、且部署安全。

---

## 通用原則

- 遵循 Chart 標準結構：
  ```text
  mychart/
    Chart.yaml
    values.yaml
    values.schema.json     # 建議：使用 JSON Schema 驗證 values
    templates/
      _helpers.tpl
      deployment.yaml
      service.yaml
      ingress.yaml
    charts/                # dependencies
    files/                 # 非模板檔
  ```
- 縮排 **2 spaces**；所有 YAML 檔不得混用 Tab / NBSP。
- 產出需通過：`helm lint`、`helm template -n <ns> .`。
- 僅在需求明確時新增 template；避免多餘資源。
- 模板與 values **不可** 任意重排現有 key 順序。

---

## Chart.yaml 規範

- 必填欄位：`apiVersion`, `name`, `version`, `type`（預設 `application`）。
- `appVersion` 用於應用版本（非 chart 版號）。
- Dependencies 以 `dependencies:` 管理，禁用舊的 `requirements.yaml`。

**範例**
```yaml
apiVersion: v2
name: mychart
description: Example app
type: application
version: 0.1.0
appVersion: "1.2.3"
dependencies:
  - name: redis
    version: "19.x.x"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
```

---

## values.yaml 規範

- key 使用 **camelCase** 或 **kebab-case**（與既有專案一致）。
- 僅放 **預設值**；環境差異放 `values/uat.yaml`、`values/prod.yaml` 等覆寫檔。
- 避免把秘密放 values；若不得已，用外部 Secret 或 `helm secrets`。

**結構建議**
```yaml
replicaCount: 2

image:
  repository: ghcr.io/acme/app
  tag: "1.2.3"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  className: ""
  hosts: []
  tls: []

resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"

nodeSelector: {}
tolerations: []
affinity: {}
```

---

## values.schema.json（強烈建議）

- 使用 JSON Schema 驗證 values，避免部署期錯誤。
- 最小骨架：
```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "replicaCount": { "type": "integer", "minimum": 1 },
    "image": {
      "type": "object",
      "properties": {
        "repository": { "type": "string" },
        "tag": { "type": "string" }
      },
      "required": ["repository"]
    }
  }
}
```

---

## 模板撰寫（templates/）

- 使用 **Go template** + **Sprig** 函式；避免巢狀過深。
- 每個模板頂部加入註解：來源檔名與資源說明。
- 請用 **_helpers.tpl** 抽共用片段與命名。

**_helpers.tpl 範例**
```gotemplate
{{- define "mychart.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
```

**Deployment 片段**
```gotemplate
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    app.kubernetes.io/name: {{ .Chart.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ .Chart.Name }}
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ .Chart.Name }}
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      containers:
        - name: app
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 8080
          resources: {{- toYaml .Values.resources | nindent 12 }}
```

**最佳實務**
- 以 `toYaml` + `nindent` 輸出複雜子樹。
- 以 `default` 提供備援值：`| default .Chart.AppVersion`。
- 條件渲染：`{{- if .Values.ingress.enabled }}` … `{{- end }}`。
- 以 `tpl` 評估值中的模板字串（若必要）。

---

## 命名與標籤

- 統一使用 **Kubernetes 建議標籤**：
  ```yaml
  app.kubernetes.io/name: {{ .Chart.Name }}
  app.kubernetes.io/instance: {{ .Release.Name }}
  app.kubernetes.io/version: {{ .Chart.AppVersion }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
  app.kubernetes.io/part-of: {{ .Chart.Name }}
  ```
- 名稱長度控制 `63` 字元，使用 `trunc 63 | trimSuffix "-"`。

---

## 依賴與 Library Chart

- 以 `dependencies:` 定義子 Chart，使用 `condition:` 允許開關：
  ```yaml
  dependencies:
    - name: prometheus
      version: "25.x.x"
      repository: "https://prometheus-community.github.io/helm-charts"
      condition: prometheus.enabled
  ```
- 共享模板建議提取為 **Library Chart**（`type: library`），避免複製貼上。

---

## 安全與 Secrets

- 優先以 `Secret`（外部建立）掛載；模板勿放明文。
- 若必須由 Helm 生成 Secret：
  - 支援外部覆寫與輪替（透過 `lookup` 與 `randAlphaNum` 但避免每次變更）。
  - 使用 `lookup` 檢查既有 Secret，避免滾動更新：
    ```gotemplate
    {{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "mychart.fullname" .)) -}}
    ```

---

## 部署與相容性

- 支援 dry-run 與 template 測試：
  ```bash
  helm lint ./mychart
  helm template -n default ./mychart -f values.yaml
  ```
- 用 `capabilities` 判斷目標叢集 API：
  ```gotemplate
  {{- if .Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress" -}}
  apiVersion: networking.k8s.io/v1
  {{- else -}}
  apiVersion: networking.k8s.io/v1beta1
  {{- end }}
  ```
- 對 `PodDisruptionBudget`、`IngressClass`、`PSP/PodSecurity` 等版本差異做條件處理。

---

## Copilot / Agent 產生行為

- **不得** 移除使用者在模板中手加的 `annotations`、`labels`、`extraEnv` 等區塊。
- 新增模板時：同步更新 `values.yaml` 與 `values.schema.json`。
- 修改值路徑時：保留舊 key，使用 `deprecated` 註解並兼容一版。
- 若 chart 已有 `_helpers.tpl` 的 naming，**必須** 循規使用。

---
## 詞彙與術語（外部參照）

本檔不再內嵌詞彙表；統一參照 `.github/copilot-vocabulary.yaml`。請遵循其中 forbidden/preferred/mapping 規則。如與既有程式碼命名衝突，應在變更說明中說明並提供過渡策略。

## Review Checklist

- [ ] `helm lint` / `helm template` 皆通過
- [ ] YAML 縮排 2 spaces，無 Tab/NBSP
- [ ] `values.yaml` 與 `values.schema.json` 一致
- [ ] 模板命名、標籤與 `_helpers.tpl` 規則一致
- [ ] 未引入明文 secrets；可重覆部署不抖動
- [ ] 依賴管理與 `condition:` 正確

---

放置路徑：
```
.github/helm.instructions.md
```
