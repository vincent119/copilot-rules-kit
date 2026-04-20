---
name: sre-cicd-pipeline
description: CI/CD Pipeline 文件產生器。用於建立部署流程文件，包含 Pipeline 階段定義、
  部署策略、Rollback 流程、環境與分支對應、Secrets 管理。
keywords:
  - cicd
  - ci/cd
  - pipeline
  - deployment
  - deploy
  - rollback
  - canary
  - blue green
  - rolling update
  - gitlab ci
  - github actions
  - container registry
  - ecr
  - docker
  - build
  - release
  - artifact
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.0
tag: skill
type: skill
---

# SRE CI/CD Pipeline 技能

產生標準化的 CI/CD Pipeline 文件，涵蓋部署流程、策略、Rollback、環境管理。

## 此技能的功能

- 建立 CI/CD Pipeline 架構文件
- 產生 Mermaid 部署流程圖（Deployment Sequence + Pipeline Stage）
- 定義 Pipeline 各階段（Lint、Test、Build、Push、Deploy、Health Check）
- 記錄部署策略（Rolling / Canary / Blue-Green）
- 記錄 Rollback 流程與步驟
- 記錄環境與分支對應關係
- 記錄 Secrets 管理與 Artifact 保留政策

## 適用時機

- 新專案 CI/CD Pipeline 設計
- 部署流程文件化
- 部署策略規劃（Rolling / Canary / Blue-Green）
- Rollback 流程設計
- Pipeline 階段定義與最佳化
- 環境與分支策略規劃

## 參考檔案

- `references/CICD-PIPELINE.template.md` - CI/CD Pipeline 範本（含部署流程、Rollback、策略）

## 問答式產生流程

當使用者要求產生 CI/CD Pipeline 文件時，採用問答方式逐步收集資訊：

1. 專案名稱與團隊
   - 問：「專案名稱是什麼？負責團隊？」

2. CI/CD 平台與工具
   - 問：「使用哪個 CI/CD 平台？（GitLab CI / GitHub Actions / Jenkins / 其他）」
   - 問：「Container Registry 用什麼？（ECR / GCR / Docker Hub / 其他）」
   - 問：「部署目標是什麼？（Kubernetes / EC2 / ECS / Lambda / 其他）」
   - 問：「部署工具用什麼？（kubectl / Kustomize / Helm / Script / 其他）」

3. 分支策略
   - 問：「分支策略是什麼？哪些分支對應哪些環境？」

4. Pipeline 階段
   - 問：「Pipeline 包含哪些階段？（Lint / Test / Build / Deploy / 其他）」
   - 逐一收集每個階段的工具、超時設定、失敗處理

5. 部署策略
   - 問：「部署策略是什麼？（Rolling / Canary / Blue-Green）」
   - 收集相關參數（最小可用比例、Canary 比例、觀察時間等）

6. Rollback
   - 問：「Rollback 方式是什麼？自動還是手動？觸發條件？」

7. Secrets 管理
   - 問：「Secrets 存放在哪裡？（AWS Secrets Manager / Vault / K8s Secret / 其他）」

8. 確認與產生
   - 將收集到的資訊整理成摘要，請使用者確認
   - 確認後，根據 `references/CICD-PIPELINE.template.md` 範本產生完整文件

### 問答規則

- 每次只問一個主題，避免一次丟出太多問題
- 提供範例值作為參考，但不可自動填入
- 使用者回答不完整時，主動追問缺少的欄位
- 所有資訊收集完畢後，先顯示摘要讓使用者確認再產生文件
- 產生的文件必須包含 Mermaid 流程圖
