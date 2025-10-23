#!/usr/bin/env bash
# 嚴格模式
set -euo pipefail

# 上游規範套件倉庫 URL
REPO_URL="https://github.com/vincent119/copilot-rules-kit.git"

# 前置子目錄（導入位置），預設 .github/rules
PREFIX="${1:-.github/rules}"

# 來源 ref（分支或 tag），預設 main
REF="${2:-main}"

# 首次導入（--squash：壓縮上游歷史）
git subtree add --prefix "$PREFIX" "$REPO_URL" "$REF" --squash
