#!/bin/bash
# filepath: scripts/setup-pre-commit.sh

# 創建 pre-commit hook
cat > .git/hooks/pre-commit << 'EOL'
#!/bin/bash
set -e

echo "合併 Copilot 指令檔案..."
python scripts/merge_copilot_instructions.py --repo . --output .github

# 將合併後的檔案加入此次提交
git add .github/

echo "Copilot 指令合併完成"
EOL

chmod +x .git/hooks/pre-commit
echo "已安裝 pre-commit hook"
