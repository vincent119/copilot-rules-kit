#!/bin/bash
# Go Copilot Rules 快速安裝腳本
# 用法: bash <(curl -s https://raw.githubusercontent.com/vincent119/copilot-rules-kit/main/scripts/quick-install.sh)
#      或: ./scripts/quick-install.sh [target_dir]

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 設定
REPO="https://github.com/vincent119/copilot-rules-kit.git"
TEMP_DIR="/tmp/copilot-rules-kit-$$"
TARGET_DIR="${1:-.agent_agy}"

echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Go Copilot Rules 快速安裝器                      ║${NC}"
echo -e "${BLUE}║     專注於 Go 開發的 Copilot Skills 集合             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

# 檢查 Git 是否安裝
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ 錯誤: 找不到 git 命令${NC}"
    echo "請先安裝 git: https://git-scm.com/downloads"
    exit 1
fi

# 檢查目標目錄
if [ -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}⚠️  目標目錄已存在: $TARGET_DIR${NC}"
    read -p "是否要覆蓋？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ 安裝已取消${NC}"
        exit 1
    fi
    echo -e "${YELLOW}📁 備份現有目錄到 ${TARGET_DIR}.backup...${NC}"
    mv "$TARGET_DIR" "${TARGET_DIR}.backup.$(date +%Y%m%d%H%M%S)"
fi

# 下載
echo -e "${BLUE}📦 下載 Go Copilot Rules...${NC}"
git clone --depth 1 --quiet "$REPO" "$TEMP_DIR" 2>/dev/null

# 複製
echo -e "${BLUE}📋 複製 Skills 到 $TARGET_DIR...${NC}"
mkdir -p "$TARGET_DIR"
cp -r "$TEMP_DIR/.agent_agy/"* "$TARGET_DIR/"

# 清理
echo -e "${BLUE}🧹 清理暫存檔案...${NC}"
rm -rf "$TEMP_DIR"

# 統計
CORE_FILES=$(find "$TARGET_DIR/rules" -name "*.md" 2>/dev/null | wc -l)
SKILLS_COUNT=$(find "$TARGET_DIR/skills" -type d -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)

echo ""
echo -e "${GREEN}✅ 安裝完成！${NC}"
echo ""
echo -e "${GREEN}📊 安裝統計:${NC}"
echo -e "   • 核心規範: ${GREEN}${CORE_FILES}${NC} 個檔案"
echo -e "   • 專業 Skills: ${GREEN}${SKILLS_COUNT}${NC} 個"
echo ""
echo -e "${BLUE}📖 可用的 Skills：${NC}"
if [ -d "$TARGET_DIR/skills" ]; then
    for skill in "$TARGET_DIR/skills"/*; do
        if [ -d "$skill" ]; then
            skill_name=$(basename "$skill")
            echo -e "   • ${GREEN}${skill_name}${NC}"
        fi
    done
fi
echo ""
echo -e "${YELLOW}💡 下一步：${NC}"
echo -e "   1. 打開 VS Code 中的任意 .go 檔案"
echo -e "   2. 在 Copilot Chat (${BLUE}Cmd/Ctrl + I${NC}) 輸入："
echo -e "      ${BLUE}'這個專案有哪些 Copilot Skills？'${NC}"
echo -e "   3. 測試 Skills 觸發："
echo -e "      ${BLUE}'如何實作 DDD Aggregate Root？'${NC} → 觸發 ${GREEN}go-ddd${NC}"
echo -e "      ${BLUE}'實作 gRPC Interceptor'${NC} → 觸發 ${GREEN}go-grpc${NC}"
echo -e "      ${BLUE}'優雅關機處理'${NC} → 觸發 ${GREEN}go-graceful-shutdown${NC}"
echo ""
echo -e "${BLUE}📚 完整文件: ${NC}$TARGET_DIR/README.md"
echo -e "${BLUE}📋 Skills 索引: ${NC}$TARGET_DIR/SKILLS_INDEX.md"
echo -e "${BLUE}📦 安裝指南: ${NC}$TARGET_DIR/INSTALLATION.md"
echo ""
