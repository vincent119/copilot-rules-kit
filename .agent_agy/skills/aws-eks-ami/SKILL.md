---
name: aws-eks-ami
description: 查詢 Amazon EKS 專用 AMI (AL2023 x86_64)。支援多版本、多地區、中英文地名查詢。
keywords:
  - eks
  - ami
  - amazon linux
  - al2023
  - worker node
  - node group
  - kubernetes version
  - aws region
  - eks optimized ami
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# Amazon EKS AMI 查詢工具

查詢 Amazon EKS 專用 AMI（Amazon Linux 2023、x86_64 架構），這些 AMI 包含所有必要的執行環境與工具，確保 Worker Node 能順利加入 EKS 叢集。

## 使用時機

當使用者詢問以下需求時，使用此技能：
- 查詢特定 Kubernetes 版本的 EKS AMI
- 獲取特定 AWS 地區的 AMI ID
- 比較不同地區的 AMI 版本
- 查詢最新可用的 EKS Node AMI

## 腳本路徑

此技能的腳本位於技能目錄下。執行前需先定位 `SKILL_DIR`：

```bash
# 自動定位技能目錄（相容 Kiro / Claude Code / VS Code Copilot / Antigravity 等 Agent 環境）
SKILL_DIR="$(find . \
  .agent_agy .agent .kiro .claude .github \
  ~/.agent_agy ~/.agent ~/.kiro ~/.claude \
  -maxdepth 5 -path '*/skills/aws-eks-ami/scripts' -type d 2>/dev/null | head -1)"
```

Agent 執行時應自動解析此路徑，使用者無需手動設定。

## 查詢方式

### 1. 預設查詢
查詢 K8s 1.33 版本，東京地區 (ap-northeast-1)：
```bash
bash "${SKILL_DIR}/get-aws-eks-ami.sh"
```

### 2. 指定 Kubernetes 版本
```bash
K8S_VERSION='1.32' bash "${SKILL_DIR}/get-aws-eks-ami.sh"
```

### 3. 指定地區（支援中英文）
```bash
# 使用英文地名
REGION='Tokyo' K8S_VERSION='1.32' bash "${SKILL_DIR}/get-aws-eks-ami.sh"

# 使用中文地名
REGION='東京' K8S_VERSION='1.31' bash "${SKILL_DIR}/get-aws-eks-ami.sh"

# 使用 AWS Region Code
REGION='us-west-2' K8S_VERSION='1.32' bash "${SKILL_DIR}/get-aws-eks-ami.sh"
```

## 支援的地區

### 亞太地區 (APAC)
| 地名 | 中文名 | Region Code |
|------|--------|-------------|
| Tokyo | 東京 | ap-northeast-1 |
| Seoul | 首爾 | ap-northeast-2 |
| Osaka | 大阪 | ap-northeast-3 |
| Singapore | 新加坡 | ap-southeast-1 |
| Sydney | 雪梨 | ap-southeast-2 |
| Jakarta | 雅加達 | ap-southeast-3 |
| Melbourne | 墨爾本 | ap-southeast-4 |
| HongKong | 香港 | ap-east-1 |
| Bangkok | 曼谷 | ap-southeast-1 |
| Mumbai | 孟買 | ap-south-1 |
| Taipei | 台北 | ap-northeast-1 * |

*台北目前使用東京地區

### 美洲地區
| 地名 | Region Code |
|------|-------------|
| Virginia | us-east-1 |
| Ohio | us-east-2 |
| California | us-west-1 |
| Oregon | us-west-2 |
| Canada | ca-central-1 |
| SaoPaulo | sa-east-1 |

### 歐洲與中東
| 地名 | Region Code |
|------|-------------|
| Ireland | eu-west-1 |
| London | eu-west-2 |
| Paris | eu-west-3 |
| Frankfurt | eu-central-1 |
| Stockholm | eu-north-1 |
| Bahrain | me-south-1 |

## 輸出格式

腳本會以表格形式輸出，按建立時間從新到舊排序：
- **Name**: AMI 完整名稱
- **ImageId**: AMI ID (ami-xxxxx)
- **Architecture**: 架構 (x86_64)
- **CreationDate**: 建立日期

## 注意事項

1. **回覆使用者時，請提供最新（表格最上方）的 AMI ID**
2. 確認使用者的 Kubernetes 版本與 EKS 叢集版本一致
3. 不同地區的 AMI ID 不同，需針對目標地區查詢
4. 建議使用最新版本的 AMI 以獲得安全更新
5. 執行腳本需要安裝 AWS CLI 並配置好認證

## 常見使用案例

### 案例 1: 新建 EKS Node Group
```bash
# 查詢生產環境使用的最新 AMI
REGION='Tokyo' K8S_VERSION='1.32' bash "${SKILL_DIR}/get-aws-eks-ami.sh"
```

### 案例 2: 多地區部署
```bash
# 東京地區
REGION='Tokyo' K8S_VERSION='1.32' bash "${SKILL_DIR}/get-aws-eks-ami.sh"

# 新加坡地區
REGION='Singapore' K8S_VERSION='1.32' bash "${SKILL_DIR}/get-aws-eks-ami.sh"
```

### 案例 3: 版本升級
```bash
# 比較不同版本的 AMI
K8S_VERSION='1.31' bash "${SKILL_DIR}/get-aws-eks-ami.sh"
K8S_VERSION='1.32' bash "${SKILL_DIR}/get-aws-eks-ami.sh"
```
