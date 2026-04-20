---
name: sre-vpc-architecture
description: AWS VPC 架構文件產生器。用於建立多環境 VPC 架構文件，包含 IP 規劃、Subnet
  設計、網路拓撲圖、跨環境連線、安全設計。
keywords:
  - vpc
  - aws vpc
  - subnet
  - cidr
  - network
  - ip planning
  - nat gateway
  - security group
  - nacl
  - transit gateway
  - vpc peering
  - network topology
  - availability zone
  - public subnet
  - private subnet
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.0
tag: skill
type: skill
---

# SRE VPC Architecture 技能

產生標準化的 AWS VPC 架構文件，涵蓋多環境 IP 規劃、Subnet 設計、Mermaid 網路拓撲圖。

## 此技能的功能

- 建立多環境 VPC 架構文件
- 產生 IP 規劃摘要與 Subnet 大小設計
- 產生 Mermaid 網路拓撲圖（單一 VPC 內部 + 跨環境互連）
- 記錄 Security Group 與 NACL 規劃
- 記錄 NAT Gateway 配置與高可用設計
- 記錄 VPC Peering / Transit Gateway 連線

## 適用時機

- 新專案 VPC 架構規劃
- 多環境網路設計（dev/staging/prod）
- IP 位址規劃與 Subnet 切割
- 跨帳號、跨 Region 網路連線設計
- 網路安全設計審查
- 現有架構文件化

## 參考檔案

- `references/VPC-ARCHITECTURE.template.md` - AWS VPC 架構範本（含多環境 IP 規劃）

## 問答式產生流程

當使用者要求產生 VPC 架構文件時，採用問答方式逐步收集資訊：

1. 專案名稱
   - 問：「專案名稱是什麼？」

2. 環境清單
   - 問：「有哪些環境？（例如：dev, staging, prod, dr）」

3. 逐一收集每個環境的資訊（對每個環境重複以下問題）：
   - A. AWS Account ID
   - B. Region
   - C. VPC CIDR
   - D. 用途說明
   - E. Subnet 規劃：數量、類型（Public/Private）、CIDR、AZ
   - F. NAT Gateway 數量與高可用需求

4. 跨環境連線
   - 問：「環境之間需要互連嗎？使用 VPC Peering 還是 Transit Gateway？」
   - 若需要，收集連線對應關係

5. 安全設計
   - 問：「需要哪些 Security Group？請列出名稱、用途、主要 Inbound 規則」
   - 問：「NACL 有特殊需求嗎？還是使用預設規則？」

6. 確認與產生
   - 將收集到的資訊整理成摘要，請使用者確認
   - 確認後，根據 `references/VPC-ARCHITECTURE.template.md` 範本產生完整文件

### 問答規則

- 每次只問一個主題，避免一次丟出太多問題
- 提供範例值作為參考，但不可自動填入
- 使用者回答不完整時，主動追問缺少的欄位
- 允許使用者說「跟上一個環境一樣」來複用設定
- 所有環境資訊收集完畢後，先顯示摘要讓使用者確認再產生文件
- 產生的文件必須包含 Mermaid 架構圖
