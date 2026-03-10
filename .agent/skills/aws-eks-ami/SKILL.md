---
name: aws-eks-ami
description: 查詢並獲取 Amazon EKS 專用的 AMI (Amazon Machine Image) 資訊。當使用者需要取得特定 Kubernetes 版本（如 1.33 等）的 EKS Node AMI ID 時使用此技能。
---

# 獲取 Amazon EKS AMI

此技能提供查詢 Amazon EKS 專用 AMI（基於 Amazon Linux 2023、x86_64 架構）的功能。這些 AMI 包含所有必要的執行環境與工具，確保工作節點 (Worker Node) 能順利加入叢集並執行應用程式。

## 如何使用此技能

當使用者詢問關於 EKS AMI，或請求獲取特定版本的 EKS AMI 時，請執行打包在此技能中的腳本。

### 步驟說明

1. **確認 Kubernetes 版本**：檢查使用者是否有指定 Kubernetes 版本（例如 `1.31`、`1.32`）。若使用者未指定，腳本預設會查詢 `1.33` 版本的 AMI。
2. **執行查詢腳本**：執行 `scripts/get-aws-eks-ami.sh` 腳本以獲取 AMI 列表。
   - **預設查詢**：

     ```bash
     ./scripts/get-aws-eks-ami.sh
     ```

   - **指定版本查詢**（使用 `K8S_VERSION` 環境變數）：

     ```bash
     K8S_VERSION='1.32' ./scripts/get-aws-eks-ami.sh
     ```

   - **指定地區與版本查詢**（支援地區中英文別名轉換）：

     腳本會自動將常見的地名（如 `Tokyo`、`東京`、`Seoul` 等）轉換為 AWS 的 Region Code：

     ```bash
     REGION='Tokyo' K8S_VERSION='1.32' ./scripts/get-aws-eks-ami.sh
     ```

3. **回報結果**：腳本會以表格形式列出符合條件的 AMI 資訊，並依照建立時間 (`CreationDate`) 從新到舊排序。請將最新（最上方）的 AMI ID 及詳細資訊整理後回覆給使用者。
