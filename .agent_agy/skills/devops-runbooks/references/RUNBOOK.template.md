---
author: Vincent
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: reference
parent: devops-runbooks
---

# Runbook: {{PROCEDURE_NAME}}

**服務:** {{SERVICE_NAME}}
**最後更新:** {{DATE}}
**負責人:** {{TEAM_OR_PERSON}}
**嚴重等級:** {{P1|P2|P3|P4}}

---

## 概述

**目的:** {{WHAT_THIS_RUNBOOK_ADDRESSES}}

**使用時機:** {{TRIGGER_CONDITIONS}}

**預估耗時:** {{TIME_ESTIMATE}}

---

## SLA / SLO

| 指標 | 目標 | 量測方式 |
|------|------|----------|
| 回應時間 | {{TARGET}} | {{MEASUREMENT}} |
| 可用性 | {{TARGET}} | {{MEASUREMENT}} |
| MTTR | {{TARGET}} | {{MEASUREMENT}} |

---

## 前置條件

- [ ] 具備 {{SYSTEM_1}} 存取權限
- [ ] 具備 {{SYSTEM_2}} 存取權限
- [ ] 已安裝 {{TOOL}}
- [ ] 具備 On-call 權限

### 所需憑證

| 系統 | 憑證位置 |
|------|----------|
| {{SYSTEM}} | {{VAULT_PATH_OR_LOCATION}} |

---

## 快速參考

### 常用指令

```bash
{{MOST_COMMON_COMMAND_1}}
{{MOST_COMMON_COMMAND_2}}
```

### 重要 URL

| 資源 | URL |
|------|-----|
| Dashboard | {{URL}} |
| Logs | {{URL}} |
| Metrics | {{URL}} |

### 關鍵聯絡人

| 角色 | 聯絡方式 |
|------|----------|
| Service Owner | {{CONTACT}} |
| Escalation | {{CONTACT}} |

---

## 執行步驟

### 步驟 1: {{STEP_TITLE}}

**預估時間:** {{ESTIMATED_MINUTES}} 分鐘
**類型:** {{AUTOMATED|MANUAL_JUDGMENT}}
**破壞性:** {{YES|NO}}

{{STEP_DESCRIPTION}}

**Dry-run（建議先執行）:**

```bash
{{DRY_RUN_COMMAND}}
```

**正式執行:**

```bash
{{COMMAND}}
```

**預期輸出:**

```
{{EXPECTED_OUTPUT}}
```

**非預期結果:** 前往 [Troubleshooting](#troubleshooting)

---

### 步驟 2: {{STEP_TITLE}}

**預估時間:** {{ESTIMATED_MINUTES}} 分鐘
**類型:** {{AUTOMATED|MANUAL_JUDGMENT}}
**破壞性:** {{YES|NO}}

{{STEP_DESCRIPTION}}

```bash
{{COMMAND}}
```

**驗證:**

```bash
{{VERIFICATION_COMMAND}}
```

---

### 步驟 3: {{STEP_TITLE}}

**預估時間:** {{ESTIMATED_MINUTES}} 分鐘
**類型:** {{AUTOMATED|MANUAL_JUDGMENT}}

{{STEP_DESCRIPTION}}

**決策點:**

- 若 {{CONDITION_A}}: 繼續步驟 4
- 若 {{CONDITION_B}}: 跳至步驟 6
- 若 {{CONDITION_C}}: 進行 Escalation

---

### 步驟 4: {{STEP_TITLE}}

**預估時間:** {{ESTIMATED_MINUTES}} 分鐘
**類型:** {{AUTOMATED|MANUAL_JUDGMENT}}
**破壞性:** {{YES|NO}}

{{STEP_DESCRIPTION}}

---

## 驗證

### 成功條件

- [ ] {{CRITERION_1}}
- [ ] {{CRITERION_2}}
- [ ] {{CRITERION_3}}

### 驗證指令

```bash
{{HEALTH_CHECK_COMMAND}}
```

**預期結果:**

```
{{HEALTHY_OUTPUT}}
```

---

## Rollback

若程序失敗或造成問題：

### 步驟 1: {{ROLLBACK_STEP}}

```bash
{{ROLLBACK_COMMAND}}
```

### 步驟 2: {{ROLLBACK_STEP}}

```bash
{{ROLLBACK_COMMAND}}
```

### 驗證 Rollback

```bash
{{VERIFY_ROLLBACK}}
```

---

## Troubleshooting

### {{ERROR_SCENARIO_1}}

**症狀:**

```
{{ERROR_MESSAGE}}
```

**原因:** {{ROOT_CAUSE}}

**解決方式:**

```bash
{{FIX_COMMAND}}
```

---

### {{ERROR_SCENARIO_2}}

**症狀:** {{SYMPTOM}}

**解決方式:** {{FIX}}

---

### {{ERROR_SCENARIO_3}}

**症狀:** {{SYMPTOM}}

**解決方式:** {{FIX}}

---

## Escalation

### 何時需要 Escalation

- {{ESCALATION_TRIGGER_1}}
- {{ESCALATION_TRIGGER_2}}
- 處理時間超過 {{TIME}}

### Escalation 路徑

1. **L1:** {{CONTACT}}
2. **L2:** {{CONTACT}}
3. **L3:** {{CONTACT}}

### Escalation 範本

```
Subject: [{{SEVERITY}}] {{SERVICE_NAME}} - {{ISSUE_SUMMARY}}

問題描述: {{DESCRIPTION}}
開始時間: {{TIME}}
影響範圍: {{IMPACT}}
已採取措施: {{ACTIONS}}
目前狀態: {{STATUS}}
```

---

## 對外溝通

### Stakeholder 通知範本

用於對外部利害關係人（客戶、管理層、相關團隊）通知事件狀態。

#### 事件開始通知

```
Subject: [{{SEVERITY}}] 服務異常通知 - {{SERVICE_NAME}}

各位好，

我們偵測到 {{SERVICE_NAME}} 目前發生異常狀況。

影響範圍: {{IMPACT_SCOPE}}
開始時間: {{START_TIME}}
目前狀態: 調查中
預計更新時間: {{NEXT_UPDATE_TIME}}

我們正在積極處理，將於上述時間提供下一次更新。

{{TEAM_NAME}}
```

#### 處理中更新通知

```
Subject: [更新] [{{SEVERITY}}] 服務異常處理中 - {{SERVICE_NAME}}

各位好，

關於 {{SERVICE_NAME}} 異常事件的最新進度：

根因: {{ROOT_CAUSE_OR_INVESTIGATION_STATUS}}
目前措施: {{CURRENT_ACTIONS}}
預計恢復時間: {{ETA}}
下次更新時間: {{NEXT_UPDATE_TIME}}

{{TEAM_NAME}}
```

#### 事件解除通知

```
Subject: [已解除] {{SERVICE_NAME}} 服務已恢復正常

各位好，

{{SERVICE_NAME}} 已於 {{RESOLVED_TIME}} 恢復正常運作。

根因: {{ROOT_CAUSE}}
影響時間: {{START_TIME}} ~ {{RESOLVED_TIME}}
影響範圍: {{IMPACT_SUMMARY}}
後續措施: {{FOLLOW_UP_ACTIONS}}

如有任何問題，請聯繫 {{CONTACT}}。

{{TEAM_NAME}}
```

---

## Post-Incident Review

每次執行 Runbook 後填寫，用於持續改善流程。

- 執行日期: {{DATE}}
- 執行者: {{OPERATOR}}
- 實際耗時: {{DURATION}}
- 偏離步驟: {{DEVIATIONS_OR_NONE}}
- 遇到的問題: {{ISSUES_ENCOUNTERED_OR_NONE}}
- 改善建議: {{IMPROVEMENTS}}
- 下次審查日期: {{NEXT_REVIEW_DATE}}

---

## 相關 Runbook

- [{{RELATED_RUNBOOK_1}}]({{PATH}})
- [{{RELATED_RUNBOOK_2}}]({{PATH}})

---

## 附錄

### A. 架構背景

{{RELEVANT_ARCHITECTURE_INFO}}

### B. 歷史事件

| 日期 | 問題 | 解決方式 |
|------|------|----------|
| {{DATE}} | {{ISSUE}} | {{RESOLUTION}} |

### C. 自動化機會

- {{AUTOMATION_IDEA_1}}
- {{AUTOMATION_IDEA_2}}

### D. 變更紀錄

| 版本 | 日期 | 變更者 | 變更內容 |
|------|------|--------|----------|
| {{VERSION}} | {{DATE}} | {{AUTHOR}} | {{CHANGES}} |

---

## 品質檢查清單

- [ ] 步驟清晰且可執行
- [ ] 指令可直接複製貼上執行
- [ ] 每個步驟標註預估時間與類型（Automated / Manual）
- [ ] Destructive Operation 已明確標記
- [ ] 適用步驟已提供 Dry-run 指令
- [ ] 包含驗證步驟
- [ ] Rollback 程序已記錄
- [ ] Escalation 路徑已定義
- [ ] Stakeholder 溝通範本已填寫
- [ ] Troubleshooting 涵蓋常見問題
- [ ] Post-Incident Review 區塊已備妥
- [ ] SLA / SLO 目標已記錄
- [ ] 變更紀錄已更新
- [ ] 最近已測試（{{TIMEFRAME}} 內）
