---
author: Vincent
status: unpublished
updated: '2026-03-30'
version: 1.0.0
tag: skill
type: reference
parent: sre-documentation-generation
---

# 服務架構概覽: ${SERVICE_NAME}

**負責團隊:** ${TEAM_NAME}
**最後更新:** ${DATE}
**服務等級:** ${SERVICE_TIER}

---

## 服務基本資訊

| 項目 | 內容 |
|------|------|
| 服務名稱 | ${SERVICE_NAME} |
| 服務描述 | ${SERVICE_DESCRIPTION} |
| 程式語言 | ${LANGUAGE} |
| 框架 | ${FRAMEWORK} |
| Repository | ${REPO_URL} |
| 部署環境 | ${ENVIRONMENTS} |
| 服務等級 | ${TIER} |

### 服務等級定義

| 等級 | 定義 | SLO 要求 | On-call 要求 |
|------|------|----------|-------------|
| Tier 1 | 核心業務，停機直接影響營收 | >= 99.9% | 24/7 |
| Tier 2 | 重要功能，影響使用者體驗 | >= 99.5% | 工作時間 |
| Tier 3 | 輔助功能，可容忍短暫中斷 | >= 99.0% | 最佳努力 |

---

## 架構圖

```
${ASCII_ARCHITECTURE_DIAGRAM}

範例:
┌──────────┐     ┌──────────┐     ┌──────────┐
│  Client  │────>│   LB     │────>│  Service │
└──────────┘     └──────────┘     └────┬─────┘
                                       │
                              ┌────────┴────────┐
                              │                 │
                         ┌────▼────┐      ┌────▼────┐
                         │   DB    │      │  Cache  │
                         └─────────┘      └─────────┘
```

---

## 依賴關係

### 上游依賴 (本服務依賴的服務)

| 服務 | 用途 | 通訊方式 | 失敗影響 | 降級策略 |
|------|------|----------|----------|----------|
| ${SERVICE} | ${PURPOSE} | ${PROTOCOL} | ${IMPACT} | ${FALLBACK} |

### 下游依賴 (依賴本服務的服務)

| 服務 | 用途 | 通訊方式 | 備註 |
|------|------|----------|------|
| ${SERVICE} | ${PURPOSE} | ${PROTOCOL} | ${NOTES} |

### 基礎設施依賴

| 元件 | 用途 | 備註 |
|------|------|------|
| ${COMPONENT} | ${PURPOSE} | ${NOTES} |

---

## 關鍵路徑與單點故障

### 關鍵路徑

1. ${CRITICAL_PATH_1}
2. ${CRITICAL_PATH_2}

### 單點故障 (SPOF)

| SPOF | 影響 | 緩解措施 | 狀態 |
|------|------|----------|------|
| ${SPOF} | ${IMPACT} | ${MITIGATION} | ${SPOF_STATUS} |

---

## 資料流

### 讀取路徑

```
${READ_PATH_DESCRIPTION}
Client -> LB -> Service -> Cache (hit) -> Response
                        -> DB (miss) -> Cache (write) -> Response
```

### 寫入路徑

```
${WRITE_PATH_DESCRIPTION}
Client -> LB -> Service -> DB -> Cache Invalidation -> Response
```

---

## 部署資訊

| 項目 | 內容 |
|------|------|
| 部署方式 | ${DEPLOYMENT_METHOD} |
| 部署頻率 | ${DEPLOYMENT_FREQUENCY} |
| Rollback 方式 | ${ROLLBACK_METHOD} |
| Rollback 時間 | ${ROLLBACK_TIME} |
| Canary 策略 | ${CANARY_STRATEGY} |

### 環境清單

| 環境 | 用途 | URL | 備註 |
|------|------|-----|------|
| dev | 開發測試 | ${URL} | ${NOTES} |
| staging | 預發布驗證 | ${URL} | ${NOTES} |
| production | 正式環境 | ${URL} | ${NOTES} |

---

## 容量與效能

### 目前容量

| 指標 | 目前值 | 上限 | 使用率 |
|------|--------|------|--------|
| QPS | ${CURRENT} | ${MAX} | ${UTILIZATION}% |
| CPU | ${CURRENT} | ${MAX} | ${UTILIZATION}% |
| Memory | ${CURRENT} | ${MAX} | ${UTILIZATION}% |
| Storage | ${CURRENT} | ${MAX} | ${UTILIZATION}% |
| Connections | ${CURRENT} | ${MAX} | ${UTILIZATION}% |

### 擴展策略

| 方向 | 方式 | 觸發條件 | 自動化 |
|------|------|----------|--------|
| 水平擴展 | ${METHOD} | ${TRIGGER} | ${AUTOMATED} |
| 垂直擴展 | ${METHOD} | ${TRIGGER} | ${AUTOMATED} |

---

## 監控與告警

### Dashboard

| Dashboard | URL | 用途 |
|-----------|-----|------|
| 服務總覽 | ${URL} | 整體健康狀態 |
| SLO 追蹤 | ${URL} | Error Budget 消耗 |
| 資源使用 | ${URL} | 容量監控 |

### 關鍵告警

| 告警名稱 | 條件 | 嚴重程度 | 通知方式 |
|----------|------|----------|----------|
| ${ALERT} | ${CONDITION} | ${SEVERITY} | ${NOTIFICATION} |

### Log 位置

| 類型 | 位置 | 保留期限 |
|------|------|----------|
| Application Log | ${LOCATION} | ${RETENTION} |
| Access Log | ${LOCATION} | ${RETENTION} |
| Error Log | ${LOCATION} | ${RETENTION} |

---

## 降級策略

### 降級模式

| 模式 | 觸發條件 | 行為變更 | 使用者影響 |
|------|----------|----------|-----------|
| ${MODE} | ${TRIGGER} | ${BEHAVIOR} | ${USER_IMPACT} |

### Circuit Breaker 設定

| 依賴服務 | 失敗閾值 | 半開時間 | Fallback |
|----------|----------|----------|----------|
| ${SERVICE} | ${THRESHOLD} | ${HALF_OPEN} | ${FALLBACK} |

---

## On-call 資訊

| 項目 | 內容 |
|------|------|
| On-call 排程 | ${SCHEDULE_URL} |
| Escalation 政策 | ${POLICY_URL} |
| Runbook 位置 | ${RUNBOOK_PATH} |
| 溝通頻道 | ${CHANNEL} |

---

## 變更紀錄

| 版本 | 日期 | 變更者 | 變更內容 |
|------|------|--------|----------|
| ${VERSION} | ${DATE} | ${AUTHOR} | ${CHANGES} |

---

## 品質檢查清單

- [ ] 架構圖反映目前狀態
- [ ] 所有依賴關係已記錄
- [ ] 單點故障已識別並有緩解措施
- [ ] 降級策略已定義並測試
- [ ] 監控與告警已設定
- [ ] On-call 資訊完整
- [ ] 容量數據為最新
- [ ] 部署與 Rollback 程序已驗證
