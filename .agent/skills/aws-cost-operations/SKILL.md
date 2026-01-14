---
name: aws-cost-operations
description: 此技能提供 AWS 成本優化、監控與運維的最佳實務，並整合 Billing、Cost Estimation、Observability 與 Security Assessment 等 MCP Server。
allowed-tools:
  * mcp__pricing__*
  * mcp__costexp__*
  * mcp__cw__*
  * mcp__aws-mcp__*
  * mcp__awsdocs__*
  * Bash(aws ce *)
  * Bash(aws cloudwatch *)
  * Bash(aws logs *)
  * Bash(aws budgets *)
  * Bash(aws cloudtrail *)
  * Bash(aws sts get-caller-identity)
hooks:
  PreToolUse:
    - matcher: Bash(aws ce *)
      command: aws sts get-caller-identity --query Account --output text
      once: true
---

# AWS 成本與運維 (AWS Cost & Operations)

此技能提供 AWS 成本優化、監控、可觀測性與運維卓越的綜合指南，並整合 MCP Server 以協助執行。

## AWS 文件需求

**重要**：此技能需要 AWS MCP 工具以獲取準確、最新的 AWS 資訊。

### 回答 AWS 問題前

1. **務必驗證** 使用 AWS MCP 工具（若可用）：
    * `mcp__aws-mcp__aws___search_documentation` 或 `mcp__*awsdocs*__aws___search_documentation` - 搜尋 AWS 文件
    * `mcp__aws-mcp__aws___read_documentation` 或 `mcp__*awsdocs*__aws___read_documentation` - 閱讀特定頁面
    * `mcp__aws-mcp__aws___get_regional_availability` - 檢查服務可用性

2. **若 AWS MCP 工具不可用**：
    * 引導使用者設定 AWS MCP：請參閱 [AWS MCP 設定指南](../../docs/aws-mcp-setup.md)
    * 協助判斷適合使用者環境的選項：
        * 已有 uvx + AWS credentials → 使用 Full AWS MCP Server
        * 無 Python/credentials → 使用 AWS Documentation MCP (如果是公開文件查詢)
    * 若無法判斷 → 詢問使用者偏好

## 整合的 MCP Servers

此技能包含 8 個自動配置的 MCP Server：

### 成本管理 Servers

#### 1. AWS Billing and Cost Management MCP Server

**用途**: 即時帳單與成本管理

* 檢視目前 AWS 花費與趨勢
* 分析各服務的帳單細節
* 追蹤預算使用率
* 監控成本分配標籤 (Cost Allocation Tags)
* 檢視組織的整合帳單 (Consolidated Billing)

#### 2. AWS Pricing MCP Server

**用途**: 部署前成本估算與優化

* 在部署資源前估算成本
* 比較跨區域 (Region) 的定價
* 計算總體擁有成本 (TCO)
* 評估不同服務選項的成本效益
* 獲取 AWS 服務的當前定價資訊

#### 3. AWS Cost Explorer MCP Server

**用途**: 詳細成本分析與報告

* 分析歷史花費模式
* 建立自訂成本報告
* 識別成本異常與趨勢
* 預測未來成本
* 依服務、區域或標籤分析成本
* 產生成本優化建議

### 監控與可觀測性 Servers

#### 4. Amazon CloudWatch MCP Server

**用途**: 指標、警報與日誌分析

* 查詢 CloudWatch Metrics 與 Logs
* 建立與管理 CloudWatch Alarms
* 分析應用程式效能指標
* 排查運維問題
* 設定自訂儀表板
* 監控資源使用率

#### 5. Amazon CloudWatch Application Signals MCP Server

**用途**: 應用程式監控與效能洞察

* 監控應用程式健康狀態與效能
* 分析服務水準目標 (SLOs)
* 追蹤應用程式相依性
* 識別效能瓶頸
* 監控服務地圖 (Service Map) 與追蹤 (Traces)

#### 6. AWS Managed Prometheus MCP Server

**用途**: 相容 Prometheus 的監控

* 查詢 Prometheus 指標
* 監控容器化應用程式
* 分析 Kubernetes 工作負載指標
* 建立 PromQL 查詢
* 追蹤自訂應用程式指標

### 審計與安全 Servers

#### 7. AWS CloudTrail MCP Server

**用途**: AWS API 活動與審計分析

* 分析 AWS API 呼叫與使用者活動
* 追蹤資源變更與修改
* 調查安全事件
* 審計合規性需求
* 識別異常存取模式
* 審閱誰在何時做了什麼變更

#### 8. AWS Well-Architected Security Assessment Tool MCP Server

**用途**: 針對 Well-Architected Framework 的安全評估

* 根據 AWS 最佳實務評估安全態勢
* 識別安全缺口與漏洞
* 獲取安全改善建議
* 審閱安全支柱 (Security Pillar) 合規性
* 產生安全評估報告

## 何時使用此技能

當需要執行以下任務時，請使用此技能：

* 優化 AWS 成本並減少花費
* 在部署前估算成本
* 監控應用程式與基礎設施效能
* 設定可觀測性與警報
* 分析花費模式與趨勢
* 調查運維問題
* 審計 AWS 活動與變更
* 評估安全態勢
* 實踐運維卓越 (Operational Excellence)

## 成本優化最佳實務 (Cost Optimization Best Practices)

### 部署前成本估算

**務必在部署前估算成本**：

1. 使用 **AWS Pricing MCP** 估算資源成本
2. 比較不同區域的定價
3. 評估替代服務選項
4. 計算預期月費
5. 規劃擴展與成長

**工作流程範例**:

```bash
"估算在 us-east-1 執行一個 Lambda 函數的月費，
假設每月 100 萬次調用，512MB 記憶體，每次持續 3 秒"
```

### 成本分析與優化

**定期成本審閱**:

1. 使用 **Cost Explorer MCP** 分析花費趨勢
2. 識別成本異常與預期外的收費
3. 依服務、區域與環境審閱成本
4. 比較實際成本與預算
5. 產生成本優化建議

**成本優化策略**:

* 調整過度配置的資源 (Right-sizing)
* 使用適當的儲存類別 (S3, EBS)
* 對動態工作負載實作自動擴展 (Auto-scaling)
* 利用 Savings Plans 與 Reserved Instances
* 刪除未使用的資源與快照
* 有效使用成本分配標籤

### 預算監控

**追蹤花費與預算**:

1. 使用 **Billing and Cost Management MCP** 監控預算
2. 設定預算警報以通知超支
3. 定期審閱預算使用率
4. 根據趨勢調整預算
5. 實作成本控制與治理

## 監控與可觀測性最佳實務 (Monitoring Best Practices)

### CloudWatch 指標與警報

**實作全面監控**:

1. 使用 **CloudWatch MCP** 查詢指標與日誌
2. 為關鍵指標設定警報：
   * CPU 與記憶體使用率
   * 錯誤率與延遲 (Latency)
   * 佇列深度 (Queue depths) 與處理時間
   * API Gateway 限流 (Throttling)
   * Lambda 錯誤與超時

3. 建立 CloudWatch 儀表板以視覺化數據

4. 使用 Log Insights 進行故障排除

**警報情境範例**:

* Lambda 錯誤率 > 1%
* EC2 CPU 使用率 > 80%
* API Gateway 4xx/5xx 錯誤激增
* DynamoDB 請求被限流
* ECS 任務失敗

### 應用程式效能監控 (APM)

**監控應用程式健康**:

1. 使用 **CloudWatch Application Signals MCP** 進行 APM
2. 追蹤服務水準目標 (SLOs)
3. 監控應用程式相依性
4. 識別效能瓶頸
5. 設定分散式追蹤 (Distributed Tracing)

### 容器與 Kubernetes 監控

**針對容器化工作負載**:

1. 使用 **AWS Managed Prometheus MCP** 獲取指標
2. 監控容器資源使用率
3. 追蹤 Pod 與 Node 健康狀態
4. 建立 PromQL 查詢自訂指標
5. 設定容器異常警報

## 審計與安全最佳實務 (Audit & Security Best Practices)

### CloudTrail 活動分析

**審計 AWS 活動**:

1. 使用 **CloudTrail MCP** 分析 API 活動
2. 追蹤誰變更了資源
3. 調查安全事件
4. 監控可疑活動模式
5. 審計政策合規性

**常見審計情境**:

* "誰刪除了這個 S3 bucket？"
* "顯示過去 24 小時內所有的 IAM 角色變更"
* "列出失敗的登入嘗試"
* "找出特定使用者的所有操作"
* "追蹤安全群組 (Security Group) 的修改"

### 安全評估

**定期安全審閱**:

1. 使用 **Well-Architected Security Assessment MCP**
2. 根據最佳實務評估安全態勢
3. 識別安全缺口與漏洞
4. 實作建議的安全改善措施
5. 記錄安全合規性

**安全評估領域**:

* 身分與存取管理 (IAM)
* 偵測控制與監控
* 基礎設施保護
* 資料保護與加密
* 事件回應準備

## 有效使用 MCP Servers

### 成本分析工作流程

1. **部署前**: 使用 Pricing MCP 估算成本
2. **部署後**: 使用 Billing MCP 追蹤實際花費
3. **分析**: 使用 Cost Explorer MCP 進行詳細成本分析
4. **優化**: 實作 Cost Explorer 的建議

### 監控工作流程

1. **設定**: 配置 CloudWatch 指標與警報
2. **監控**: 使用 CloudWatch MCP 追蹤關鍵指標
3. **分析**: 使用 Application Signals 獲取 APM 洞察
4. **排查**: 查詢 CloudWatch Logs 解決問題

### 安全工作流程

1. **審計**: 使用 CloudTrail MCP 審閱活動
2. **評估**: 使用 Well-Architected Security Assessment
3. **補救**: 實作安全建議
4. **監控**: 透過 CloudWatch 追蹤安全事件

### MCP 使用最佳實務

1. **成本意識**: 部署資源前先檢查價格
2. **主動監控**: 為關鍵指標設定警報
3. **定期審閱**: 每週分析成本與效能
4. **審計軌跡**: 審閱 CloudTrail Log 以確保合規
5. **安全優先**: 定期執行安全評估
6. **持續優化**: 根據成本與效能建議採取行動

## 運維卓越指南 (Operational Excellence)

### 成本優化

* **全面標記**: 使用一致的成本分配標籤
* **每月審閱**: 分析花費趨勢與異常
* **適當配置**: 匹配資源與實際使用量
* **自動化**: 使用自動擴展與排程
* **監控預算**: 設定成本超支警報

### 監控與警報

* **關鍵指標**: 針對對業務關鍵的指標發出警報
* **減少雜訊**: 微調閥值以減少誤報
* **可執行的警報**: 確保警報包含明確的補救步驟
* **儀表板可視化**: 為關鍵利害關係人建立儀表板
* **日誌保留**: 平衡成本與合規需求

### 安全與合規

* **最小權限**: 僅給予所需的最小權限
* **定期審計**: 審閱 CloudTrail Log 中的異常
* **加密數據**: 使用靜態與傳輸中加密
* **持續與評估**: 頻繁執行安全評估
* **事件回應**: 制定安全事件的處理程序

## 額外資源

有關詳細的操作模式與最佳實務，請參考綜合參考文件：

**檔案**: `references/operations-patterns.md`

此參考文件包含：

* 成本優化策略
* 監控與警報模式
* 可觀測性最佳實務
* 安全與合規指南
* 故障排除工作流程

## CloudWatch Alarms 參考

**檔案**: `references/cloudwatch-alarms.md`

常見的警報配置，針對：

* Lambda Functions
* EC2 Instances
* RDS Databases
* DynamoDB Tables
* API Gateway
* ECS Services
* Application Load Balancers
