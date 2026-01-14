# AWS 成本與運維模式 (AWS Cost & Operations Patterns)

針對 AWS 成本優化、監控與運維卓越的綜合模式與最佳實務。

## 目錄 (Table of Contents)

- [成本優化模式](#成本優化模式-cost-optimization-patterns)
- [監控模式](#監控模式-monitoring-patterns)
- [可觀測性模式](#可觀測性模式-observability-patterns)
- [安全與審計模式](#安全與審計模式-security-and-audit-patterns)
- [故障排除工作流程](#故障排除工作流程-troubleshooting-workflows)

## 成本優化模式 (Cost Optimization Patterns)

### 模式 1: 部署前成本估算 (Cost Estimation Before Deployment)

**時機**: 部署任何新基礎設施之前

**MCP Server**: AWS Pricing MCP

**步驟**:

1. 列出所有要部署的資源
2. 查詢每種資源類型的定價
3. 根據預期使用量計算月費
4. 比較跨區域 (Region) 的定價
5. 在架構文件中記錄成本估算

**範例**:

```bash
Resource: Lambda Function
- Invocations: 1,000,000/month
- Duration: 3 seconds avg
- Memory: 512 MB
- Region: us-east-1
Estimated cost: $X/month
```

### 模式 2: 每月成本審閱 (Monthly Cost Review)

**時機**: 每月的第一週

**MCP Servers**: Cost Explorer MCP, Billing and Cost Management MCP

**步驟**:

1. 審閱總支出與預算的對比
2. 分析各服務的成本 (前 5 大服務)
3. 識別成本異常 (增加超過 20%)
4. 依環境審閱成本 (dev/staging/prod)
5. 檢查成本分配標籤 (Cost Allocation Tag) 的覆蓋率
6. 產生成本優化建議

**關鍵指標**:

- 月環比成本變化
- 各環境成本
- 各應用程式/專案成本
- 未標記資源的成本

### 模式 3: 資源適當配置 (Right-Sizing Resources)

**時機**: 每季或當使用率警報觸發時

**MCP Servers**: CloudWatch MCP, Cost Explorer MCP

**步驟**:

1. 查詢 CloudWatch 以獲取資源使用率指標
2. 識別過度配置的資源 (使用率 < 40%)
3. 識別配置不足的資源 (使用率 > 80%)
4. 計算適當配置後的潛在節省
5. 規劃並執行適當配置變更
6. 監控變更後的效能

**常見適當配置情境**:

- CPU 使用率低的 EC2 實例
- 容量過剩的 RDS 實例
- 讀寫使用率低的 DynamoDB 表
- 記憶體配置過高的 Lambda 函數

### 模式 4: 清理未使用的資源 (Unused Resource Cleanup)

**時機**: 每月或由成本異常觸發

**MCP Servers**: Cost Explorer MCP, CloudTrail MCP

**步驟**:

1. 識別零使用量的資源
2. 查詢 CloudTrail 以獲取最後存取時間
3. 標記資源以進行刪除審閱
4. 通知資源擁有者
5. 刪除確認未使用的資源
6. 追蹤節省的成本

**常見未使用的資源**:

- 未掛載的 EBS 卷
- 老舊的 EBS 快照
- 閒置的 Load Balancers
- 未使用的 Elastic IPs
- 老舊的 AMIs 和快照
- 已停止的 EC2 實例 (長期)

## 監控模式 (Monitoring Patterns)

### 模式 1: 關鍵服務監控 (Critical Service Monitoring)

**時機**: 所有生產環境服務

**MCP Server**: CloudWatch MCP

**監控指標**:

- **可用性 (Availability)**: 服務正常運行時間、健康檢查
- **效能 (Performance)**: 延遲、回應時間
- **錯誤 (Errors)**: 錯誤率、失敗的請求
- **飽和度 (Saturation)**: CPU、記憶體、磁碟、網路使用率

**警報閥值** (根據 SLA 調整):

- Error rate: 連續 2 個期間 > 1%
- Latency: 5 分鐘內 p99 > 1 秒
- CPU: 10 分鐘內 > 80%
- Memory: 5 分鐘內 > 85%

### 模式 2: Lambda 函數監控 (Lambda Function Monitoring)

**MCP Server**: CloudWatch MCP

**關鍵指標**:

```bash
- Invocations (次數)
- Errors (次數, %)
- Duration (平均, p99)
- Throttles (次數)
- ConcurrentExecutions (最大值)
- IteratorAge (用於串流處理)
```

**推薦警報**:

- Error rate > 1%
- Duration > 超時時間的 80%
- Throttles > 0
- ConcurrentExecutions > 保留量的 80%

### 模式 3: API Gateway 監控 (API Gateway Monitoring)

**MCP Server**: CloudWatch MCP

**關鍵指標**:

```bash
- Count (總請求數)
- 4XXError, 5XXError
- Latency (p50, p95, p99)
- IntegrationLatency
- CacheHitCount, CacheMissCount
```

**推薦警報**:

- 5XX error rate > 0.5%
- 4XX error rate > 5%
- Latency p99 > 2 秒
- Integration latency 激增

### 模式 4: 資料庫監控 (Database Monitoring)

**MCP Server**: CloudWatch MCP

**RDS 指標**:

```bash
- CPUUtilization
- DatabaseConnections
- FreeableMemory
- ReadLatency, WriteLatency
- ReadIOPS, WriteIOPS
- FreeStorageSpace
```

**DynamoDB 指標**:

```bash
- ConsumedReadCapacityUnits
- ConsumedWriteCapacityUnits
- UserErrors
- SystemErrors
- ThrottledRequests
```

**推薦警報**:

- RDS CPU > 80% 持續 10 分鐘
- RDS connections > 最大值的 80%
- RDS free storage < 10 GB
- DynamoDB throttled requests > 0
- DynamoDB user errors 激增

## 可觀測性模式 (Observability Patterns)

### 模式 1: 分散式追蹤設定 (Distributed Tracing Setup)

**MCP Server**: CloudWatch Application Signals MCP

**元件**:

1. **服務地圖 (Service Map)**: 視覺化服務相依性
2. **追蹤 (Traces)**: 跨服務追蹤請求
3. **指標 (Metrics)**: 監控每個服務的延遲和錯誤
4. **SLOs**: 定義並追蹤服務水準目標

**實作**:

- 在 Lambda 函數上啟用 X-Ray 追蹤
- 將 X-Ray SDK 添加到應用程式代碼
- 配置採樣規則
- 建立 Service Lens 儀表板

### 模式 2: 日誌聚合與分析 (Log Aggregation and Analysis)

**MCP Server**: CloudWatch MCP

**日誌策略**:

1. **集中化日誌**: 將所有應用程式日誌發送到 CloudWatch Logs
2. **結構化日誌**: 使用 JSON 格式進行結構化記錄
3. **Log Insights**: 使用 CloudWatch Logs Insights 進行查詢
4. **保留**: 設定適當的保留期間

**Log Insights 查詢範例**:

```bash
# 尋找過去一小時內的錯誤
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100

# 依類型統計錯誤
stats count() by error_type
| sort count desc

# 計算 p99 延遲
stats percentile(duration, 99) by service_name
```

### 模式 3: 自訂指標 (Custom Metrics)

**MCP Server**: CloudWatch MCP

**何時使用自訂指標**:

- 業務特定的 KPI (每分鐘訂單數、每小時營收)
- 應用程式特定指標 (快取命中率、佇列深度)
- AWS 未提供的效能指標

**最佳實務**:

- 使用一致的命名空間: `CompanyName/ApplicationName`
- 包含相關維度 (環境、區域、版本)
- 以適當的間隔發布指標
- 使用 Metric Filters 從日誌衍生指標

## 安全與審計模式 (Security and Audit Patterns)

### 模式 1: API 活動審計 (API Activity Auditing)

**MCP Server**: CloudTrail MCP

**定期審計查詢**:

```bash
# 尋找所有 IAM 變更
eventName: CreateUser, DeleteUser, AttachUserPolicy, etc.
Time: Last 24 hours

# 追蹤 S3 bucket 刪除
eventName: DeleteBucket
Time: Last 7 days

# 尋找失敗的登入嘗試
eventName: ConsoleLogin
errorCode: Failure

# 監控特權操作
userIdentity.arn: *admin* OR *root*
```

**審計排程**:

- 每日: 審閱特權使用者操作
- 每週: 審計 IAM 變更和安全群組修改
- 每月: 全面安全審閱

### 模式 2: 安全態勢評估 (Security Posture Assessment)

**MCP Server**: Well-Architected Security Assessment Tool MCP

**評估領域**:

1. **身分與存取管理 (IAM)**
   - 最小權限實作
   - 強制 MFA
   - 角色基礎存取控制 (RBAC)
   - 服務控制策略 (SCPs)

2. **偵測控制**
   - 所有區域啟用 CloudTrail
   - 審閱 GuardDuty 發現
   - Config 規則合規性
   - Security Hub 發現

3. **基礎設施保護**
   - VPC 安全群組審閱
   - Network ACLs 配置
   - AWS WAF 規則
   - 安全群組入站規則

4. **資料保護**
   - 靜態加密 (S3, EBS, RDS)
   - 傳輸中加密 (TLS/SSL)
   - KMS 金鑰使用與輪換
   - Secrets Manager 使用

5. **事件回應**
   - 記錄 IR 劇本 (Playbooks)
   - 自動化回應程序
   - 聯絡資訊保持最新
   - 定期 IR 演練

**評估頻率**:

- 每季: 完整的 Well-Architected 審閱
- 每月: 高優先順序發現審閱
- 每週: 關鍵安全發現

### 模式 3: 合規監控 (Compliance Monitoring)

**MCP Servers**: CloudTrail MCP, CloudWatch MCP

**合規需求**:

- 數據駐留 (確保數據留在批准的區域)
- 存取日誌記錄 (記錄並保留所有存取)
- 加密需求 (數據靜態和傳輸中加密)
- 變更管理 (所有變更在 CloudTrail 中追蹤)

**合規儀表板**:

- 各服務加密覆蓋率
- CloudTrail 記錄狀態
- 失敗的登入嘗試
- 特權存取使用情況
- 不合規資源

## 故障排除工作流程 (Troubleshooting Workflows)

### 工作流程 1: Lambda 高錯誤率 (High Lambda Error Rate)

**MCP Servers**: CloudWatch MCP, CloudWatch Application Signals MCP

**步驟**:

1. 查詢 CloudWatch 獲取 Lambda 錯誤指標
2. 檢查 CloudWatch Logs 中的錯誤日誌
3. 識別錯誤模式 (超時、記憶體、權限)
4. 檢查 Lambda 配置 (記憶體、超時、權限)
5. 審閱最近的代碼部署
6. 檢查下游服務健康狀況
7. 實作修復並監控

### 工作流程 2: 延遲增加 (Increased Latency)

**MCP Servers**: CloudWatch MCP, CloudWatch Application Signals MCP

**步驟**:

1. 識別 CloudWatch 指標中的延遲激增
2. 檢查服務地圖以找出緩慢的相依性
3. 查詢分散式追蹤以找出緩慢的請求
4. 檢查資料庫查詢效能
5. 審閱 API Gateway 整合延遲
6. 檢查 Lambda 冷啟動
7. 識別瓶頸並優化

### 工作流程 3: 成本激增調查 (Cost Spike Investigation)

**MCP Servers**: Cost Explorer MCP, CloudWatch MCP, CloudTrail MCP

**步驟**:

1. 使用 Cost Explorer 識別導致激增的服務
2. 檢查 CloudWatch 指標以確認使用量增加
3. 審閱 CloudTrail 以查看最近的資源與建立
4. 識別根本原因 (錯誤配置、失控程序、攻擊)
5. 實作成本控制 (預算、警報、服務配額)
6. 清理不必要的資源

### 工作流程 4: 安全事件回應 (Security Incident Response)

**MCP Servers**: CloudTrail MCP, GuardDuty (via CloudWatch), Well-Architected Assessment MCP

**步驟**:

1. 在 GuardDuty 或 CloudWatch 中識別安全事件
2. 查詢 CloudTrail 以獲取相關 API 活動
3. 確定範圍與影響
4. 隔離受影響的資源
5. 撤銷被洩露的憑證
6. 實作補救措施
7. 進行事後檢討
8. 更新安全控制

## 總結 (Summary)

- **成本優化**: 使用 Pricing, Cost Explorer, 和 Billing MCPs 進行主動成本管理
- **監控**: 為所有關鍵服務設定全面的 CloudWatch 警報
- **可觀測性**: 實作分散式追蹤和結構化日誌
- **安全**: 定期 CloudTrail 審計和 Well-Architected 評估
- **主動**: 不要等待事故發生 - 持續監控並優化
