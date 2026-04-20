---
author: Vincent
status: unpublished
updated: '2026-03-30'
version: 1.0.0
tag: skill
type: reference
parent: sre-documentation-generation
---

# Post-Mortem: ${INCIDENT_TITLE}

**Incident ID:** ${INCIDENT_ID}
**日期:** ${INCIDENT_DATE}
**撰寫者:** ${AUTHOR}
**審查狀態:** ${REVIEW_STATUS}

---

## 摘要

| 項目 | 內容 |
|------|------|
| 嚴重程度 | ${SEVERITY} |
| 影響時間 | ${START_TIME} ~ ${END_TIME} (共 ${DURATION}) |
| 影響範圍 | ${IMPACT_SCOPE} |
| 受影響使用者 | ${AFFECTED_USERS_COUNT_OR_PERCENTAGE} |
| Error Budget 消耗 | ${BUDGET_CONSUMED}% |
| 偵測方式 | ${DETECTION_METHOD} |
| 偵測時間 | 事件發生後 ${DETECTION_DELAY} |

---

## 影響

### 使用者影響

${USER_IMPACT_DESCRIPTION}

### 業務影響

${BUSINESS_IMPACT_DESCRIPTION}

### 技術影響

${TECHNICAL_IMPACT_DESCRIPTION}

---

## 時間軸

所有時間以 ${TIMEZONE} 表示。

| 時間 | 事件 | 操作者 |
|------|------|--------|
| ${TIME} | 事件開始 - ${TRIGGER_EVENT} | 系統 |
| ${TIME} | 告警觸發 - ${ALERT_NAME} | 監控系統 |
| ${TIME} | On-call 收到通知 | ${PERSON} |
| ${TIME} | 開始調查 | ${PERSON} |
| ${TIME} | 識別根因 | ${PERSON} |
| ${TIME} | 開始修復 | ${PERSON} |
| ${TIME} | 修復部署完成 | ${PERSON} |
| ${TIME} | 服務恢復正常 | ${PERSON} |
| ${TIME} | 確認完全恢復 | ${PERSON} |

---

## 根因分析

### 直接原因

${DIRECT_CAUSE}

### 5 Whys 分析

1. 為什麼 ${SYMPTOM}？
   - 因為 ${CAUSE_1}
2. 為什麼 ${CAUSE_1}？
   - 因為 ${CAUSE_2}
3. 為什麼 ${CAUSE_2}？
   - 因為 ${CAUSE_3}
4. 為什麼 ${CAUSE_3}？
   - 因為 ${CAUSE_4}
5. 為什麼 ${CAUSE_4}？
   - 因為 ${ROOT_CAUSE}

### 根本原因

${ROOT_CAUSE_DESCRIPTION}

### 觸發條件

${TRIGGER_CONDITIONS}

### 貢獻因素

- ${CONTRIBUTING_FACTOR_1}
- ${CONTRIBUTING_FACTOR_2}
- ${CONTRIBUTING_FACTOR_3}

---

## 處理過程

### 有效的措施

- ${WHAT_WENT_WELL_1}
- ${WHAT_WENT_WELL_2}

### 需要改善的地方

- ${WHAT_WENT_POORLY_1}
- ${WHAT_WENT_POORLY_2}

### 運氣成分

- ${LUCKY_FACTOR_1}

---

## Action Items

### 立即修復 (已完成)

| 項目 | 負責人 | 狀態 |
|------|--------|------|
| ${ACTION} | ${OWNER} | 已完成 |

### 短期改善 (2 週內)

| 項目 | 負責人 | 截止日期 | Ticket |
|------|--------|----------|--------|
| ${ACTION} | ${OWNER} | ${DUE_DATE} | ${TICKET_URL} |

### 長期改善 (本季內)

| 項目 | 負責人 | 截止日期 | Ticket |
|------|--------|----------|--------|
| ${ACTION} | ${OWNER} | ${DUE_DATE} | ${TICKET_URL} |

---

## 偵測與回應評估

| 指標 | 數值 | 目標 | 評估 |
|------|------|------|------|
| TTD (偵測時間) | ${VALUE} | < ${TARGET} | ${RESULT} |
| TTE (參與時間) | ${VALUE} | < ${TARGET} | ${RESULT} |
| TTR (修復時間) | ${VALUE} | < ${TARGET} | ${RESULT} |

---

## 經驗教訓

### 關鍵學習

1. ${LESSON_1}
2. ${LESSON_2}
3. ${LESSON_3}

### 可複用的知識

${REUSABLE_KNOWLEDGE}

---

## 相關資源

| 資源 | 連結 |
|------|------|
| Incident Channel | ${URL} |
| 告警紀錄 | ${URL} |
| 相關 PR/Commit | ${URL} |
| Dashboard | ${URL} |

---

## 品質檢查清單

- [ ] 時間軸完整且準確
- [ ] 根因分析深入到系統層面（非個人層面）
- [ ] 所有 Action Items 有明確負責人與截止日期
- [ ] Action Items 已建立對應 Ticket
- [ ] 已識別偵測與回應的改善空間
- [ ] 經驗教訓可供其他團隊參考
- [ ] 已排定 Post-Mortem Review 會議
- [ ] 文件已分享給相關 Stakeholder
