#!/usr/bin/env bash
# 嚴格模式：遇到任何錯誤即中止、未定義變數視為錯、管線出錯即失敗
set -euo pipefail

# 上游規範套件倉庫 URL（可依需要改為自有 fork）
REPO_URL="https://github.com/vincent119/copilot-rules-kit.git"

# 目標導入目錄，預設為 .github/rules
TARGET_DIR="${1:-.github/rules}"

# 鎖定的版本（tag 或 commit SHA），預設 v0.2.0
TAG_OR_REF="${2:-v0.2.0}"

# 新增 submodule 指向 main 分支
git submodule add -b main "$REPO_URL" "$TARGET_DIR"

# 初始化子模組（含遞迴）
git submodule update --init --recursive

# 進入子模組資料夾，抓取所有 tags 並切換到指定版本
pushd "$TARGET_DIR" >/dev/null
git fetch --tags
git checkout "$TAG_OR_REF"
popd >/dev/null

# 將 .gitmodules 與目標目錄加入版本控制並建立提交
git add .gitmodules "$TARGET_DIR"
git commit -m "chore(rules): add copilot-rules-kit@$TAG_OR_REF as submodule"
