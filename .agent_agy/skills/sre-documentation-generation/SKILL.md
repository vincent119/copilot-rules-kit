---
name: sre-documentation-generation
description: SRE 文件產生器。用於建立 SLO/SLI 定義、服務架構文件、容量規劃、變更管理、
  On-call 手冊、Post-Mortem 報告等 SRE 相關文件。
keywords:
  - sre
  - site reliability
  - slo
  - sli
  - error budget
  - post-mortem
  - capacity planning
  - change management
  - on-call
  - service level
  - toil reduction
  - reliability
  - availability
  - observability
  - service architecture
  - service overview
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.1.0
tag: skill
type: skill
---

# SRE Documentation Generation 技能

產生標準化的 SRE 文件，涵蓋服務可靠性、SLO/SLI 定義、Post-Mortem、服務架構概覽。

## 此技能的功能

- 建立 SLO/SLI 定義文件
- 產生 Post-Mortem 報告
- 建立服務架構與依賴關係文件
- 產生容量規劃文件
- 建立變更管理紀錄
- 產生 On-call 手冊
- 建立 Toil 追蹤與消除計畫
- 產生 Error Budget 政策文件

## 適用時機

- 新服務上線前的可靠性文件準備
- Incident 發生後撰寫 Post-Mortem
- 定期 SLO 審查與調整
- 容量規劃與擴展評估
- On-call 輪值交接
- Toil 識別與消除規劃
- 變更管理流程記錄

## 相關技能

- `sre-vpc-architecture` - AWS VPC 架構文件產生
- `sre-cicd-pipeline` - CI/CD Pipeline 文件產生

## 參考檔案

- `references/SLO-DEFINITION.template.md` - SLO/SLI 定義範本
- `references/POST-MORTEM.template.md` - Post-Mortem 報告範本
- `references/SERVICE-OVERVIEW.template.md` - 服務架構概覽範本

## 文件類型總覽

### 1. SLO/SLI 定義

定義服務的可靠性目標與量測指標，包含 Error Budget 政策。

核心要素：
- SLI 指標定義（延遲、可用性、吞吐量、正確性）
- SLO 目標值與量測窗口
- Error Budget 計算與消耗政策
- 告警閾值與 Escalation 規則

### 2. Post-Mortem 報告

Incident 發生後的結構化回顧，聚焦根因分析與改善行動。

核心要素：
- 事件時間軸
- 影響範圍與嚴重程度
- 根因分析（5 Whys / Fishbone）
- Action Items 與負責人
- 經驗教訓

### 3. 服務架構概覽

記錄服務的架構、依賴關係與關鍵路徑。

核心要素：
- 服務拓撲與依賴圖
- 關鍵路徑與單點故障
- 資料流與 API 邊界
- 降級策略與 Fallback 機制

## 問答式產生流程

當使用者要求產生文件時，必須採用問答方式逐步收集資訊，不可自行假設或填入範例值。

### SLO/SLI 定義問答流程

依照以下順序逐步詢問：

1. 服務名稱與簡述
2. SLI 指標類型（延遲、可用性、吞吐量、正確性，可多選）
3. 逐一收集每個 SLI 的量測方式與資料來源
4. SLO 目標值與量測窗口（例如：99.9% / 30 天滾動）
5. Error Budget 政策（消耗超過閾值時的行動）
6. 告警閾值與 Escalation 規則
7. 確認與產生

### Post-Mortem 報告問答流程

依照以下順序逐步詢問：

1. Incident 標題與日期
2. 嚴重程度（P1/P2/P3/P4）
3. 影響範圍（受影響的服務、使用者數量、持續時間）
4. 事件時間軸（發現、回應、緩解、解決的時間點）
5. 根因分析（引導使用者用 5 Whys 方式回答）
6. Action Items（每項需包含負責人與截止日期）
7. 經驗教訓
8. 確認與產生

### 問答規則

- 每次只問一個主題，避免一次丟出太多問題
- 提供範例值作為參考，但不可自動填入
- 使用者回答不完整時，主動追問缺少的欄位
- 所有資訊收集完畢後，先顯示摘要讓使用者確認再產生文件

## 最佳實踐

- SLO 必須基於使用者體驗定義，而非系統指標
- Post-Mortem 採用 Blameless 文化，聚焦系統改善
- 所有 Action Items 必須有明確負責人與截止日期
- Error Budget 政策需事先與產品團隊達成共識
- 文件定期審查，建議每季至少一次
- 使用量化數據支撐決策，避免主觀判斷
- 區分 Leading Indicator 與 Lagging Indicator
- 容量規劃需考慮季節性流量變化
