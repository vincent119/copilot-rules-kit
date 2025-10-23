#!/usr/bin/env python3
# filepath: scripts/merge_copilot_instructions.py

import os
import re
import yaml
import argparse
from pathlib import Path

def read_file(file_path):
    """讀取檔案內容"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"無法讀取檔案 {file_path}: {e}")
        return None

def extract_extends_info(yaml_content):
    """從 YAML 內容中提取 extends 資訊"""
    try:
        if isinstance(yaml_content, str):
            data = yaml.safe_load(yaml_content)
        else:
            data = yaml_content

        if not data or 'extends' not in data:
            return {}

        extends_info = data['extends']
        return extends_info
    except Exception as e:
        print(f"解析 YAML 內容時出錯: {e}")
        return {}

def resolve_path(base_path, relative_path):
    """解析相對路徑"""
    # 移除 .github 前綴，因為它可能是針對最終部署位置的相對路徑
    if relative_path.startswith(".github/"):
        relative_path = relative_path[8:]

    # 嘗試不同的路徑組合
    candidates = [
        # 從專案根目錄開始
        os.path.join(base_path, relative_path),
        # 若檔案在 standards 目錄
        os.path.join(base_path, "standards", os.path.basename(relative_path)),
        # 直接使用指定的相對路徑
        relative_path
    ]

    for path in candidates:
        if os.path.exists(path):
            return path

    print(f"警告: 找不到檔案 '{relative_path}'，已嘗試: {candidates}")
    return None

def merge_instructions(base_file, output_file, repo_root):
    """合併指令檔案"""
    base_content = read_file(base_file)
    if not base_content:
        return False

    # 確定基礎檔案格式
    is_yaml = base_file.endswith(('.yaml', '.yml'))

    if is_yaml:
        try:
            yaml_data = yaml.safe_load(base_content)
            extends_info = extract_extends_info(yaml_data)
        except Exception as e:
            print(f"解析 YAML 檔案 {base_file} 時出錯: {e}")
            return False
    else:
        # 使用正則表達式從 Markdown 中提取 extends 資訊
        extends_pattern = r'extends:\s*\n\s*common:\s*"([^"]+)"\s*#.*?\n\s*vocabulary:\s*"([^"]+)"\s*#.*?'
        matches = re.search(extends_pattern, base_content)
        extends_info = {}
        if matches:
            extends_info = {
                'common': matches.group(1),
                'vocabulary': matches.group(2)
            }

    # 沒有 extends 資訊，直接複製原檔案
    if not extends_info:
        print(f"檔案 {base_file} 沒有 extends 資訊，直接複製到輸出")
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(base_content)
        return True

    # 處理依賴檔案
    merged_content = base_content
    for key, path in extends_info.items():
        resolved_path = resolve_path(repo_root, path)
        if not resolved_path:
            continue

        ext_content = read_file(resolved_path)
        if not ext_content:
            continue

        print(f"合併 {key} 從 {resolved_path}")

        # 替換標記
        if key == 'common':
            # 在 YAML 檔案中添加註解標記
            if is_yaml:
                insert_point = base_content.find('rules:')
                if insert_point > -1:
                    # 在 rules 前添加內容
                    merged_content = (f"{base_content[:insert_point]}"
                                     f"# ----- 以下內容合併自 {path} -----\n"
                                     f"{ext_content}\n\n"
                                     f"# ----- 合併內容結束 -----\n\n"
                                     f"{base_content[insert_point:]}")
            else:
                # 在 Markdown 檔案中，找一個合適位置插入
                merged_content = (f"{merged_content}\n\n"
                                 f"<!-- 以下內容合併自 {path} -->\n\n"
                                 f"{ext_content}\n\n"
                                 f"<!-- 合併內容結束 -->\n")

        elif key == 'vocabulary' and resolved_path.endswith(('.yaml', '.yml')):
            vocab_data = yaml.safe_load(ext_content)
            if vocab_data and isinstance(vocab_data, dict):
                # 提取詞彙表內容並格式化
                vocab_section = "# ----- 合併的詞彙表 -----\n"

                if 'mapping' in vocab_data:
                    vocab_section += "# 術語對應：\n"
                    for en, zh in vocab_data['mapping'].items():
                        vocab_section += f"# - {en}: {zh}\n"

                if 'forbidden' in vocab_data:
                    vocab_section += "\n# 禁用詞彙：\n"
                    for word in vocab_data['forbidden']:
                        vocab_section += f"# - {word}\n"

                if 'preferred' in vocab_data:
                    vocab_section += "\n# 建議用詞：\n"
                    for bad, good in vocab_data['preferred'].items():
                        vocab_section += f"# - 避免: {bad} → 使用: {good}\n"

                vocab_section += "# ----- 詞彙表結束 -----\n\n"

                # 找一個合適位置插入詞彙表
                if is_yaml:
                    # 在 YAML 檔案中的註解區域插入
                    desc_pos = merged_content.find('description:')
                    if desc_pos > -1:
                        next_line = merged_content.find('\n', desc_pos)
                        merged_content = (f"{merged_content[:next_line+1]}\n"
                                         f"{vocab_section}"
                                         f"{merged_content[next_line+1:]}")
                else:
                    # 在 Markdown 檔案末尾附加
                    merged_content += f"\n\n{vocab_section}"

    # 更新 extends 部分，表示已合併
    if is_yaml:
        merged_yaml = yaml.safe_load(merged_content)
        if 'extends' in merged_yaml:
            # 添加註解表明檔案已合併
            for key in merged_yaml['extends']:
                merged_yaml['extends'][key] += " # [已合併]"

            # 重新序列化 YAML，保留原格式
            yaml_lines = merged_content.split('\n')
            extends_start = -1
            extends_end = -1

            for i, line in enumerate(yaml_lines):
                if line.strip() == "extends:":
                    extends_start = i
                elif extends_start > -1 and i > extends_start:
                    if line and not line.startswith(' ') and not line.startswith('#'):
                        extends_end = i
                        break

            if extends_start > -1 and extends_end > -1:
                new_extends = ["extends:"]
                for key, value in merged_yaml['extends'].items():
                    new_extends.append(f"  {key}: \"{value}\"")

                merged_content_lines = yaml_lines[:extends_start] + new_extends + yaml_lines[extends_end:]
                merged_content = '\n'.join(merged_content_lines)
    else:
        # 對於 Markdown，使用正則表達式更新 extends 部分
        merged_content = re.sub(
            r'(extends:\s*\n\s*common:\s*")([^"]+)("\s*#.*?\n)',
            r'\1\2 [已合併]\3',
            merged_content
        )
        merged_content = re.sub(
            r'(extends:\s*\n.*?\n\s*vocabulary:\s*")([^"]+)("\s*#.*?\n)',
            r'\1\2 [已合併]\3',
            merged_content
        )

    # 寫入合併後的檔案
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(merged_content)

    print(f"已將合併後的指令寫入 {output_file}")
    return True

def process_instruction_files(repo_root, output_dir):
    """處理所有指令檔案"""
    # 檢查並創建輸出目錄
    os.makedirs(output_dir, exist_ok=True)

    # 要處理的檔案清單
    files_to_process = [
        "copilot-instructions.md",
        "copilot-instructions.yaml",
        "copilot-chat-instructions.yaml"
    ]

    # 處理語言特定指令
    instructions_dir = os.path.join(repo_root, "instructions")
    if os.path.isdir(instructions_dir):
        for file in os.listdir(instructions_dir):
            if file.endswith(".instructions.md"):
                files_to_process.append(os.path.join("instructions", file))

    # 處理每個檔案
    success_count = 0
    for file in files_to_process:
        input_path = os.path.join(repo_root, file)
        if not os.path.exists(input_path):
            print(f"檔案不存在: {input_path}")
            continue

        output_path = os.path.join(output_dir, file)
        if merge_instructions(input_path, output_path, repo_root):
            success_count += 1

    return success_count

def main():
    parser = argparse.ArgumentParser(description='合併 Copilot 指令檔案')
    parser.add_argument('--repo', '-r', default='.', help='儲存庫根目錄路徑')
    parser.add_argument('--output', '-o', default='.github', help='輸出目錄路徑')
    args = parser.parse_args()

    repo_root = os.path.abspath(args.repo)
    output_dir = os.path.abspath(args.output)

    print(f"處理儲存庫: {repo_root}")
    print(f"輸出目錄: {output_dir}")

    count = process_instruction_files(repo_root, output_dir)
    print(f"已成功處理 {count} 個檔案")

if __name__ == "__main__":
    main()
