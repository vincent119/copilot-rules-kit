---
name: devops-runbooks
description: Operational runbook and procedure documentation specialist. Use when
  creating incident response procedures, operational playbooks, or system maintenance
  guides.
keywords:
  - runbook
  - incident response
  - operational procedure
  - playbook
  - on-call
  - disaster recovery
  - rollback
  - escalation
  - maintenance
  - troubleshooting guide
author: Vincent Yu
status: unpublished
updated: '2026-03-30'
version: 1.0.1
tag: skill
type: skill
---

# DevOps Runbooks 技能

建立可執行的 Runbook，涵蓋營運程序、Incident Response 及系統維護。

## 此技能的功能

- 建立營運 Runbook
- 記錄 Incident 處理程序
- 定義 Escalation 路徑
- 提供 Troubleshooting 指南
- 記錄 Rollback 程序
- 累積營運知識庫

## 適用時機

- Incident Response 規劃
- On-call 文件撰寫
- 系統維護程序
- Disaster Recovery 規劃
- 知識傳承

## 參考檔案

- `references/RUNBOOK.template.md` - 完整的營運 Runbook 範本

## Runbook 結構

1. **概述** - 目的與使用時機
2. **SLA / SLO** - 服務等級目標與量測方式
3. **前置條件** - 所需權限與工具
4. **快速參考** - 常用指令與 URL
5. **執行步驟** - 逐步操作與驗證
6. **Rollback** - 如何還原變更
7. **Troubleshooting** - 常見問題排除
8. **Escalation** - 何時及如何升級處理
9. **對外溝通** - Stakeholder 通知範本
10. **Post-Incident Review** - 執行回顧與改善

## 最佳實踐

- 指令必須可直接複製貼上執行
- 每個步驟附上預期輸出
- 清楚記錄決策點
- 每個步驟定義 Rollback 方式
- 定期測試以保持程序有效性
- 包含 Escalation 聯絡人
- 每個步驟標註預估執行時間
- 區分「自動化可執行」vs「需人工判斷」的步驟
- 標註具破壞性的操作（Destructive Operation），並加上確認提示
- 提供 Dry-run 指引，讓操作者先驗證再正式執行
