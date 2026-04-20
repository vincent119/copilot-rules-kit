---
author: Vincent
status: unpublished
updated: '2026-03-30'
version: 1.0.0
tag: skill
type: reference
parent: sre-documentation-generation
---

# SLO 定義: ${SERVICE_NAME}

**負責團隊:** ${TEAM_NAME}
**最後更新:** ${DATE}
**審查週期:** 每季
**下次審查:** ${NEXT_REVIEW_DATE}

---

## 服務概述

**服務名稱:** ${SERVICE_NAME}
**服務描述:** ${SERVICE_DESCRIPTION}
**使用者類型:** ${USER_TYPES}
**關鍵使用者旅程:** ${CRITICAL_USER_JOURNEYS}

---

## SLI 定義

### 可用性 (Availability)

| 項目 | 內容 |
|------|------|
| 定義 | ${AVAILABILITY_DEFINITION} |
| 量測方式 | ${MEASUREMENT_METHOD} |
| 資料來源 | ${DATA_SOURCE} |
| 計算公式 | `成功請求數 / 總請求數 * 100%` |
| 排除條件 | ${EXCLUSIONS} |

### 延遲 (Latency)

| 項目 | 內容 |
|------|------|
| 定義 | ${LATENCY_DEFINITION} |
| 量測方式 | ${MEASUREMENT_METHOD} |
| 資料來源 | ${DATA_SOURCE} |
| 計算公式 | `P50 / P95 / P99 回應時間` |
| 排除條件 | ${EXCLUSIONS} |

### 正確性 (Correctness)

| 項目 | 內容 |
|------|------|
| 定義 | ${CORRECTNESS_DEFINITION} |
| 量測方式 | ${MEASUREMENT_METHOD} |
| 資料來源 | ${DATA_SOURCE} |
| 計算公式 | `正確回應數 / 總回應數 * 100%` |
| 排除條件 | ${EXCLUSIONS} |

### 吞吐量 (Throughput)

| 項目 | 內容 |
|------|------|
| 定義 | ${THROUGHPUT_DEFINITION} |
| 量測方式 | ${MEASUREMENT_METHOD} |
| 資料來源 | ${DATA_SOURCE} |
| 基準值 | ${BASELINE} |

---

## SLO 目標

| SLI | SLO 目標 | 量測窗口 | 備註 |
|-----|----------|----------|------|
| 可用性 | ${TARGET}% | 30 天滾動 | ${NOTES} |
| 延遲 P50 | < ${TARGET}ms | 30 天滾動 | ${NOTES} |
| 延遲 P95 | < ${TARGET}ms | 30 天滾動 | ${NOTES} |
| 延遲 P99 | < ${TARGET}ms | 30 天滾動 | ${NOTES} |
| 正確性 | ${TARGET}% | 30 天滾動 | ${NOTES} |

---

## Error Budget

### 計算方式

```
Error Budget = 1 - SLO 目標
```

| SLI | SLO | Error Budget (30天) | 換算允許停機時間 |
|-----|-----|---------------------|------------------|
| 可用性 | ${TARGET}% | ${BUDGET}% | ${DOWNTIME_MINUTES} 分鐘 |

### Error Budget 消耗政策

#### 預算充足 (消耗 < 50%)

- 正常開發節奏
- 可進行風險較高的變更
- 鼓勵實驗性功能部署

#### 預算警戒 (消耗 50% - 80%)

- 減少高風險變更
- 加強變更審查
- 優先處理可靠性相關工作

#### 預算緊張 (消耗 80% - 100%)

- 凍結非必要變更
- 全力投入可靠性改善
- 每日審查 Error Budget 消耗

#### 預算耗盡 (消耗 > 100%)

- 停止所有功能開發
- 僅允許可靠性修復
- 啟動 Incident Review
- 與產品團隊協商優先級

---

## 告警設定

### 多窗口多燃燒率告警 (Multi-Window Multi-Burn-Rate)

| 嚴重程度 | 燃燒率 | 短窗口 | 長窗口 | 通知方式 |
|----------|--------|--------|--------|----------|
| P1 | 14.4x | 5 分鐘 | 1 小時 | PagerDuty + Slack |
| P2 | 6x | 30 分鐘 | 6 小時 | PagerDuty |
| P3 | 1x | 6 小時 | 3 天 | Slack |

### 告警規則範例

```yaml
# Prometheus alerting rule 範例
groups:
  - name: ${SERVICE_NAME_}slo
    rules:
      - alert: ${SERVICE_NAME_}HighErrorRate_P1
        expr: |
          (
            sum(rate(http_requests_total{service="${SERVICE_NAME}", code=~"5.."}[5m]))
            /
            sum(rate(http_requests_total{service="${SERVICE_NAME}"}[5m]))
          ) > 14.4 * ${ERROR_BUDGET_RATIO}
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "${SERVICE_NAME} 高錯誤率 - P1 燃燒率"
          description: "錯誤率超過 14.4 倍燃燒率，預計 ${HOURS} 小時內耗盡 Error Budget"
```

---

## Dashboard

| Dashboard | URL | 用途 |
|-----------|-----|------|
| SLO 總覽 | ${URL} | Error Budget 消耗趨勢 |
| SLI 即時 | ${URL} | 即時 SLI 數值 |
| 歷史趨勢 | ${URL} | 長期趨勢分析 |

---

## 依賴服務 SLO

| 依賴服務 | 該服務 SLO | 對本服務影響 |
|----------|-----------|-------------|
| ${DEPENDENCY_1} | ${DEP_SLO} | ${IMPACT} |
| ${DEPENDENCY_2} | ${DEP_SLO} | ${IMPACT} |

---

## 審查紀錄

| 日期 | 審查者 | 變更內容 | 原因 |
|------|--------|----------|------|
| ${DATE} | ${REVIEWER} | ${CHANGES} | ${REASON} |

---

## 品質檢查清單

- [ ] SLI 基於使用者體驗定義
- [ ] SLO 目標有歷史數據支撐
- [ ] Error Budget 政策已與產品團隊達成共識
- [ ] 告警規則已設定並測試
- [ ] Dashboard 已建立且可存取
- [ ] 依賴服務 SLO 已確認
- [ ] 審查週期已排定
