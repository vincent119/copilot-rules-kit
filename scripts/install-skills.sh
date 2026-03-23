#!/bin/bash
# Go Copilot Rules 進階安裝器
# 支援針對不同 IDE 的自動路徑偵測與選擇性安裝

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 預設值
REPO="https://github.com/vincent119/copilot-rules-kit.git"
TEMP_DIR="/tmp/copilot-rules-kit-$$"
TARGET_DIR=""
MODE="full"  # full, core-only, skills-only
SKILLS=""
IDE=""

# 幫助訊息
show_help() {
    cat << EOF
${BLUE}Go Copilot Rules 進階安裝器${NC}

${YELLOW}用法：${NC}
    $0 [選項]

${YELLOW}選項：${NC}
    --vscode            安裝到 VS Code 預設位置 (.agent_agy/)
    --cursor            安裝到 Cursor 預設位置 (.cursor/skills/)
    --path <dir>        安裝到自訂路徑
    --core-only         只安裝核心規範（不包含 Skills）
    --skills-only       只安裝 Skills（不包含核心規範）
    --skills <list>     只安裝特定 Skills（逗號分隔）
                        範例: --skills "go-ddd,go-grpc,go-testing-advanced"
    --help              顯示此幫助訊息

${YELLOW}範例：${NC}
    # 安裝到 VS Code（預設）
    $0 --vscode

    # 安裝到 Cursor
    $0 --cursor

    # 只安裝核心規範
    $0 --core-only

    # 只安裝特定 Skills
    $0 --skills "go-ddd,go-grpc,go-observability"

    # 安裝到自訂路徑
    $0 --path ~/.my-copilot-rules

${YELLOW}支援的 Skills：${NC}
    go-ddd                  DDD 架構設計
    go-grpc                 gRPC 完整規範
    go-testing-advanced     進階測試策略
    go-database             Database Migration
    go-observability        日誌與可觀測性
    go-graceful-shutdown    優雅關機模式
    go-http-advanced        HTTP 進階實作
    go-api-design           API 設計與版本管理
    go-dependency-injection 依賴注入模式
    go-configuration        設定管理
    go-ci-tooling           CI/CD 與工具配置
    go-domain-events        Domain Events 實作
    go-examples             實作範例庫

EOF
}

# 解析參數
while [[ $# -gt 0 ]]; do
    case $1 in
        --vscode)
            IDE="vscode"
            TARGET_DIR=".agent_agy"
            shift
            ;;
        --cursor)
            IDE="cursor"
            TARGET_DIR=".cursor/skills"
            shift
            ;;
        --path)
            TARGET_DIR="$2"
            shift 2
            ;;
        --core-only)
            MODE="core-only"
            shift
            ;;
        --skills-only)
            MODE="skills-only"
            shift
            ;;
        --skills)
            SKILLS="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ 未知選項: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 如果沒有指定目標目錄，使用預設值
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR=".agent_agy"
    echo -e "${YELLOW}ℹ️  未指定目標目錄，使用預設值: $TARGET_DIR${NC}"
fi

echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Go Copilot Rules 進階安裝器                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📋 安裝配置：${NC}"
echo -e "   • 模式: ${GREEN}${MODE}${NC}"
echo -e "   • 目標: ${GREEN}${TARGET_DIR}${NC}"
if [ -n "$SKILLS" ]; then
    echo -e "   • Skills: ${GREEN}${SKILLS}${NC}"
fi
echo ""

# 檢查 Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ 錯誤: 找不到 git 命令${NC}"
    exit 1
fi

# 備份現有目錄
if [ -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}⚠️  目標目錄已存在，備份到 ${TARGET_DIR}.backup.$(date +%Y%m%d%H%M%S)${NC}"
    mv "$TARGET_DIR" "${TARGET_DIR}.backup.$(date +%Y%m%d%H%M%S)"
fi

# 下載
echo -e "${BLUE}📦 下載 Go Copilot Rules...${NC}"
git clone --depth 1 --quiet "$REPO" "$TEMP_DIR" 2>/dev/null

# 建立目標目錄
mkdir -p "$TARGET_DIR"

# 根據模式複製檔案
case $MODE in
    full)
        echo -e "${BLUE}📋 複製完整規範（核心 + 所有 Skills）...${NC}"
        cp -r "$TEMP_DIR/.agent_agy/"* "$TARGET_DIR/"
        ;;
    core-only)
        echo -e "${BLUE}📋 複製核心規範...${NC}"
        mkdir -p "$TARGET_DIR/rules"
        cp -r "$TEMP_DIR/.agent_agy/rules/"* "$TARGET_DIR/rules/"
        cp "$TEMP_DIR/.agent_agy/README.md" "$TARGET_DIR/" 2>/dev/null || true
        ;;
    skills-only)
        echo -e "${BLUE}📋 複製所有 Skills...${NC}"
        mkdir -p "$TARGET_DIR/skills"
        cp -r "$TEMP_DIR/.agent_agy/skills/"* "$TARGET_DIR/skills/"
        ;;
esac

# 如果指定了特定 Skills
if [ -n "$SKILLS" ]; then
    echo -e "${BLUE}📋 複製選定的 Skills...${NC}"
    mkdir -p "$TARGET_DIR/skills"
    IFS=',' read -ra SKILL_ARRAY <<< "$SKILLS"
    for skill in "${SKILL_ARRAY[@]}"; do
        skill=$(echo "$skill" | xargs)  # 去除空白
        if [ -d "$TEMP_DIR/.agent_agy/skills/$skill" ]; then
            cp -r "$TEMP_DIR/.agent_agy/skills/$skill" "$TARGET_DIR/skills/"
            echo -e "   • ${GREEN}${skill}${NC}"
        else
            echo -e "   • ${RED}${skill}${NC} (不存在，跳過)"
        fi
    done
fi

# 複製文件
if [ -f "$TEMP_DIR/.agent_agy/INSTALLATION.md" ]; then
    cp "$TEMP_DIR/.agent_agy/INSTALLATION.md" "$TARGET_DIR/" 2>/dev/null || true
fi
if [ -f "$TEMP_DIR/.agent_agy/SKILLS_INDEX.md" ]; then
    cp "$TEMP_DIR/.agent_agy/SKILLS_INDEX.md" "$TARGET_DIR/" 2>/dev/null || true
fi

# 清理
echo -e "${BLUE}🧹 清理暫存檔案...${NC}"
rm -rf "$TEMP_DIR"

# 統計
echo ""
echo -e "${GREEN}✅ 安裝完成！${NC}"
echo ""

# 顯示已安裝內容
if [ "$MODE" != "skills-only" ] && [ -d "$TARGET_DIR/rules" ]; then
    CORE_FILES=$(find "$TARGET_DIR/rules" -name "*.md" 2>/dev/null | wc -l)
    echo -e "${GREEN}📊 核心規範: ${CORE_FILES} 個檔案${NC}"
fi

if [ "$MODE" != "core-only" ] && [ -d "$TARGET_DIR/skills" ]; then
    echo -e "${GREEN}📊 已安裝的 Skills：${NC}"
    for skill in "$TARGET_DIR/skills"/*; do
        if [ -d "$skill" ]; then
            skill_name=$(basename "$skill")
            echo -e "   • ${GREEN}${skill_name}${NC}"
        fi
    done
fi

# 針對不同 IDE 的提示
echo ""
echo -e "${YELLOW}💡 下一步：${NC}"
case $IDE in
    cursor)
        echo -e "   1. 重新啟動 Cursor"
        echo -e "   2. 在 Chat 輸入: ${BLUE}@go-ddd 如何設計 Aggregate Root？${NC}"
        ;;
    *)
        echo -e "   1. 打開 VS Code / Cursor"
        echo -e "   2. 在 Copilot Chat 輸入: ${BLUE}'這個專案有哪些 Skills？'${NC}"
        echo -e "   3. 測試觸發: ${BLUE}'如何實作 DDD Aggregate Root？'${NC}"
        ;;
esac
echo ""
echo -e "${BLUE}📚 查看完整文件: ${NC}$TARGET_DIR/INSTALLATION.md"
echo ""
