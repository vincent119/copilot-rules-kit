# CloudWatch 警報參考 (CloudWatch Alarms Reference)

常見的 AWS 服務 CloudWatch 警報配置。

## Lambda 函數 (Lambda Functions)

### 錯誤率警報 (Error Rate Alarm)

```typescript
new cloudwatch.Alarm(this, 'LambdaErrorAlarm', {
  metric: lambdaFunction.metricErrors({
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: 10,
  evaluationPeriods: 1,
  treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
  alarmDescription: 'Lambda error count exceeded threshold (Lambda 錯誤數超過閥值)',
});
```

### 持續時間警報（接近超時）(Duration Alarm - Approaching Timeout)

```typescript
new cloudwatch.Alarm(this, 'LambdaDurationAlarm', {
  metric: lambdaFunction.metricDuration({
    statistic: 'Maximum',
    period: Duration.minutes(5),
  }),
  threshold: lambdaFunction.timeout.toMilliseconds() * 0.8, // 80% of timeout (超時時間的 80%)
  evaluationPeriods: 2,
  alarmDescription: 'Lambda duration approaching timeout (Lambda 執行時間接近超時)',
});
```

### 限流警報 (Throttle Alarm)

```typescript
new cloudwatch.Alarm(this, 'LambdaThrottleAlarm', {
  metric: lambdaFunction.metricThrottles({
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: 5,
  evaluationPeriods: 1,
  alarmDescription: 'Lambda function is being throttled (Lambda 函數遭到限流)',
});
```

### 並發執行警報 (Concurrent Executions Alarm)

```typescript
new cloudwatch.Alarm(this, 'LambdaConcurrencyAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/Lambda',
    metricName: 'ConcurrentExecutions',
    dimensionsMap: {
      FunctionName: lambdaFunction.functionName,
    },
    statistic: 'Maximum',
    period: Duration.minutes(1),
  }),
  threshold: 100, // Adjust based on reserved concurrency (根據保留並發量調整)
  evaluationPeriods: 2,
  alarmDescription: 'Lambda concurrent executions high (Lambda 並發執行數過高)',
});
```

## API Gateway

### 5XX 錯誤率警報 (5XX Error Rate Alarm)

```typescript
new cloudwatch.Alarm(this, 'Api5xxAlarm', {
  metric: api.metricServerError({
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: 10,
  evaluationPeriods: 1,
  alarmDescription: 'API Gateway 5XX errors exceeded threshold (API Gateway 5XX 錯誤超過閥值)',
});
```

### 4XX 錯誤率警報 (4XX Error Rate Alarm)

```typescript
new cloudwatch.Alarm(this, 'Api4xxAlarm', {
  metric: api.metricClientError({
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: 50,
  evaluationPeriods: 2,
  alarmDescription: 'API Gateway 4XX errors exceeded threshold (API Gateway 4XX 錯誤超過閥值)',
});
```

### 延遲警報 (Latency Alarm)

```typescript
new cloudwatch.Alarm(this, 'ApiLatencyAlarm', {
  metric: api.metricLatency({
    statistic: 'p99',
    period: Duration.minutes(5),
  }),
  threshold: 2000, // 2 seconds (2 秒)
  evaluationPeriods: 2,
  alarmDescription: 'API Gateway p99 latency exceeded threshold (API Gateway p99 延遲超過閥值)',
});
```

## DynamoDB

### 讀取限流警報 (Read Throttle Alarm)

```typescript
new cloudwatch.Alarm(this, 'DynamoDBReadThrottleAlarm', {
  metric: table.metricUserErrors({
    dimensions: {
      Operation: 'GetItem',
    },
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: 5,
  evaluationPeriods: 1,
  alarmDescription: 'DynamoDB read operations being throttled (DynamoDB 讀取操作被限流)',
});
```

### 寫入限流警報 (Write Throttle Alarm)

```typescript
new cloudwatch.Alarm(this, 'DynamoDBWriteThrottleAlarm', {
  metric: table.metricUserErrors({
    dimensions: {
      Operation: 'PutItem',
    },
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: 5,
  evaluationPeriods: 1,
  alarmDescription: 'DynamoDB write operations being throttled (DynamoDB 寫入操作被限流)',
});
```

### 已用容量警報 (Consumed Capacity Alarm)

```typescript
new cloudwatch.Alarm(this, 'DynamoDBCapacityAlarm', {
  metric: table.metricConsumedReadCapacityUnits({
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: provisionedCapacity * 0.8, // 80% of provisioned (配置容量的 80%)
  evaluationPeriods: 2,
  alarmDescription: 'DynamoDB consumed capacity approaching limit (DynamoDB 已用容量接近上限)',
});
```

## EC2 Instances

### CPU 使用率警報 (CPU Utilization Alarm)

```typescript
new cloudwatch.Alarm(this, 'EC2CpuAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/EC2',
    metricName: 'CPUUtilization',
    dimensionsMap: {
      InstanceId: instance.instanceId,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 80,
  evaluationPeriods: 3,
  alarmDescription: 'EC2 CPU utilization high (EC2 CPU 使用率過高)',
});
```

### 狀態檢查失敗警報 (Status Check Failed Alarm)

```typescript
new cloudwatch.Alarm(this, 'EC2StatusCheckAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/EC2',
    metricName: 'StatusCheckFailed',
    dimensionsMap: {
      InstanceId: instance.instanceId,
    },
    statistic: 'Maximum',
    period: Duration.minutes(1),
  }),
  threshold: 1,
  evaluationPeriods: 2,
  alarmDescription: 'EC2 status check failed (EC2 狀態檢查失敗)',
});
```

### 磁碟空間警報（需要 CloudWatch Agent）(Disk Space Alarm)

```typescript
new cloudwatch.Alarm(this, 'EC2DiskAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'CWAgent',
    metricName: 'disk_used_percent',
    dimensionsMap: {
      InstanceId: instance.instanceId,
      path: '/',
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 85,
  evaluationPeriods: 2,
  alarmDescription: 'EC2 disk space usage high (EC2 磁碟空間使用率過高)',
});
```

## RDS Databases

### CPU 警報 (CPU Alarm)

```typescript
new cloudwatch.Alarm(this, 'RDSCpuAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/RDS',
    metricName: 'CPUUtilization',
    dimensionsMap: {
      DBInstanceIdentifier: dbInstance.instanceIdentifier,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 80,
  evaluationPeriods: 3,
  alarmDescription: 'RDS CPU utilization high (RDS CPU 使用率過高)',
});
```

### 連線數警報 (Connection Count Alarm)

```typescript
new cloudwatch.Alarm(this, 'RDSConnectionAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/RDS',
    metricName: 'DatabaseConnections',
    dimensionsMap: {
      DBInstanceIdentifier: dbInstance.instanceIdentifier,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: maxConnections * 0.8, // 80% of max connections (最大連線數的 80%)
  evaluationPeriods: 2,
  alarmDescription: 'RDS connection count approaching limit (RDS 連線數接近上限)',
});
```

### 剩餘儲存空間警報 (Free Storage Space Alarm)

```typescript
new cloudwatch.Alarm(this, 'RDSStorageAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/RDS',
    metricName: 'FreeStorageSpace',
    dimensionsMap: {
      DBInstanceIdentifier: dbInstance.instanceIdentifier,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 10 * 1024 * 1024 * 1024, // 10 GB in bytes
  comparisonOperator: cloudwatch.ComparisonOperator.LESS_THAN_THRESHOLD,
  evaluationPeriods: 1,
  alarmDescription: 'RDS free storage space low (RDS 剩餘儲存空間過低)',
});
```

## ECS Services

### 任務數警報 (Task Count Alarm)

```typescript
new cloudwatch.Alarm(this, 'ECSTaskCountAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'ECS/ContainerInsights',
    metricName: 'RunningTaskCount',
    dimensionsMap: {
      ServiceName: service.serviceName,
      ClusterName: cluster.clusterName,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 1,
  comparisonOperator: cloudwatch.ComparisonOperator.LESS_THAN_THRESHOLD,
  evaluationPeriods: 2,
  alarmDescription: 'ECS service has no running tasks (ECS 服務沒有執行中的任務)',
});
```

### CPU 使用率警報 (CPU Utilization Alarm)

```typescript
new cloudwatch.Alarm(this, 'ECSCpuAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/ECS',
    metricName: 'CPUUtilization',
    dimensionsMap: {
      ServiceName: service.serviceName,
      ClusterName: cluster.clusterName,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 80,
  evaluationPeriods: 3,
  alarmDescription: 'ECS service CPU utilization high (ECS 服務 CPU 使用率過高)',
});
```

### 記憶體使用率警報 (Memory Utilization Alarm)

```typescript
new cloudwatch.Alarm(this, 'ECSMemoryAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/ECS',
    metricName: 'MemoryUtilization',
    dimensionsMap: {
      ServiceName: service.serviceName,
      ClusterName: cluster.clusterName,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 85,
  evaluationPeriods: 2,
  alarmDescription: 'ECS service memory utilization high (ECS 服務記憶體使用率過高)',
});
```

## SQS Queues

### 佇列深度警報 (Queue Depth Alarm)

```typescript
new cloudwatch.Alarm(this, 'SQSDepthAlarm', {
  metric: queue.metricApproximateNumberOfMessagesVisible({
    statistic: 'Maximum',
    period: Duration.minutes(5),
  }),
  threshold: 1000,
  evaluationPeriods: 2,
  alarmDescription: 'SQS queue depth exceeded threshold (SQS 佇列深度超過閥值)',
});
```

### 最舊訊息存在時間警報 (Age of Oldest Message Alarm)

```typescript
new cloudwatch.Alarm(this, 'SQSAgeAlarm', {
  metric: queue.metricApproximateAgeOfOldestMessage({
    statistic: 'Maximum',
    period: Duration.minutes(5),
  }),
  threshold: 300, // 5 minutes in seconds (5 分鐘，以秒為單位)
  evaluationPeriods: 1,
  alarmDescription: 'SQS messages not being processed timely (SQS 訊息未及時處理)',
});
```

## Application Load Balancer

### 目標健康警報 (Target Health Alarm)

```typescript
new cloudwatch.Alarm(this, 'ALBUnhealthyTargetAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/ApplicationELB',
    metricName: 'UnHealthyHostCount',
    dimensionsMap: {
      LoadBalancer: loadBalancer.loadBalancerFullName,
      TargetGroup: targetGroup.targetGroupFullName,
    },
    statistic: 'Average',
    period: Duration.minutes(5),
  }),
  threshold: 1,
  evaluationPeriods: 2,
  alarmDescription: 'ALB has unhealthy targets (ALB 有不健康的目標)',
});
```

### HTTP 5XX 警報 (HTTP 5XX Alarm)

```typescript
new cloudwatch.Alarm(this, 'ALB5xxAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/ApplicationELB',
    metricName: 'HTTPCode_Target_5XX_Count',
    dimensionsMap: {
      LoadBalancer: loadBalancer.loadBalancerFullName,
    },
    statistic: 'Sum',
    period: Duration.minutes(5),
  }),
  threshold: 10,
  evaluationPeriods: 1,
  alarmDescription: 'ALB target 5XX errors exceeded threshold (ALB 目標 5XX 錯誤超過閥值)',
});
```

### 回應時間警報 (Response Time Alarm)

```typescript
new cloudwatch.Alarm(this, 'ALBLatencyAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/ApplicationELB',
    metricName: 'TargetResponseTime',
    dimensionsMap: {
      LoadBalancer: loadBalancer.loadBalancerFullName,
    },
    statistic: 'p99',
    period: Duration.minutes(5),
  }),
  threshold: 1, // 1 second (1 秒)
  evaluationPeriods: 2,
  alarmDescription: 'ALB p99 response time exceeded threshold (ALB p99 回應時間超過閥值)',
});
```

## 複合警報 (Composite Alarms)

### 服務健康複合警報 (Service Health Composite Alarm)

```typescript
const errorAlarm = new cloudwatch.Alarm(this, 'ErrorAlarm', { /* ... */ });
const latencyAlarm = new cloudwatch.Alarm(this, 'LatencyAlarm', { /* ... */ });
const throttleAlarm = new cloudwatch.Alarm(this, 'ThrottleAlarm', { /* ... */ });

new cloudwatch.CompositeAlarm(this, 'ServiceHealthAlarm', {
  compositeAlarmName: 'service-health',
  alarmRule: cloudwatch.AlarmRule.anyOf(
    errorAlarm,
    latencyAlarm,
    throttleAlarm
  ),
  alarmDescription: 'Overall service health degraded (整體服務健康狀況下降)',
});
```

## 警報動作 (Alarm Actions)

### SNS 主題整合 (SNS Topic Integration)

```typescript
const topic = new sns.Topic(this, 'AlarmTopic', {
  displayName: 'CloudWatch Alarms',
});

// Email subscription
topic.addSubscription(new subscriptions.EmailSubscription('ops@example.com'));

// Add action to alarm
alarm.addAlarmAction(new actions.SnsAction(topic));
alarm.addOkAction(new actions.SnsAction(topic));
```

### 自動擴展動作 (Auto Scaling Action)

```typescript
const scalingAction = targetGroup.scaleOnMetric('ScaleUp', {
  metric: targetGroup.metricTargetResponseTime(),
  scalingSteps: [
    { upper: 1, change: 0 },
    { lower: 1, change: +1 },
    { lower: 2, change: +2 },
  ],
});
```

## 警報最佳實務 (Alarm Best Practices)

### 閥值選擇 (Threshold Selection)

**CPU/記憶體警報**:

- Warning: 70-80%
- Critical: 80-90%
- 考慮突發模式和正常使用情況

**錯誤率警報**:

- 基於 SLA 的閥值 (例如，99.9% = 0.1% 錯誤率)
- 考慮正常錯誤率
- 為不同錯誤類型設定不同閥值

**延遲警報**:

- 面向使用者 API 的 p99 延遲
- Warning: SLA 目標的 80%
- Critical: SLA 目標的 100%

### 評估期間 (Evaluation Periods)

**快速變化的指標** (1-2 個期間):

- 錯誤計數
- 健康檢查失敗
- 關鍵應用程式錯誤

**變緩慢化的指標** (3-5 個期間):

- CPU 使用率
- 記憶體使用率
- 磁碟使用率

**成本相關指標** (較長期間):

- 每日支出
- 資源數量變更
- 使用模式

### 缺失數據處理 (Missing Data Handling)

```typescript
// For intermittent workloads (適用於間歇性工作負載)
alarm.treatMissingData(cloudwatch.TreatMissingData.NOT_BREACHING);

// For always-on services (適用於持續運行的服務)
alarm.treatMissingData(cloudwatch.TreatMissingData.BREACHING);

// To distinguish from data issues (區分數據問題)
alarm.treatMissingData(cloudwatch.TreatMissingData.MISSING);
```

### 警報命名慣例 (Alarm Naming Conventions)

```typescript
// Pattern: <service>-<metric>-<severity>
'lambda-errors-critical'
'api-latency-warning'
'rds-cpu-warning'
'ecs-tasks-critical'
```

### 警報動作最佳實務 (Alarm Actions Best Practices)

1. **依嚴重性區分主題**:
   - Critical alarms (嚴重) → PagerDuty/on-call
   - Warning alarms (警告) → Slack/email
   - Info alarms (資訊) → Metrics dashboard

2. **在警報描述中包含上下文**:
   - 服務名稱
   - 預期閥值
   - 故障排除手冊連結

3. **盡可能自動修復**:
   - Lambda errors → 自動重試
   - CPU high → 觸發自動擴展
   - Disk full → 自動清理

4. **預防警報疲勞 (Alarm Fatigue Prevention)**:
   - 根據實際模式微調閥值
   - 使用複合警報減少雜訊
   - 實作適當的評估期間
   - 定期審閱並調整警報

## 監控儀表板 (Monitoring Dashboard)

### 推薦儀表板佈局 (Recommended Dashboard Layout)

**服務概覽 (Service Overview)**:

- 請求計數與速率
- 錯誤計數與百分比
- 延遲 (p50, p95, p99)
- 可用性百分比

**資源使用率 (Resource Utilization)**:

- 各服務 CPU 使用率
- 各服務記憶體使用率
- 網路吞吐量
- 磁碟 I/O

**成本指標 (Cost Metrics)**:

- 各服務每日支出
- 本月迄今成本
- 預算使用率
- 成本異常

**安全指標 (Security Metrics)**:

- 登入失敗嘗試
- IAM 政策變更
- 安全群組修改
- GuardDuty 發現
