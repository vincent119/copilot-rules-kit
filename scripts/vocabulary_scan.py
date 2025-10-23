#!/usr/bin/env python3
# 目的：掃描專案檔案是否包含禁止詞與建議替換詞（依據 standards/copilot-vocabulary.yaml）
# 使用：
#   python3 .github/rules/scripts/vocabulary_scan.py --vocab .github/rules/standards/copilot-vocabulary.yaml --paths "docs/**/*.md" "src/**/*.ts"
import argparse, yaml, re, sys, pathlib

parser = argparse.ArgumentParser(description="Scan files for disallowed or preferred vocabulary.")
parser.add_argument("--vocab", required=True, help="Path to copilot-vocabulary.yaml")
parser.add_argument("--paths", nargs="+", required=True, help="Glob patterns to scan, e.g. 'src/**/*.ts'")
args = parser.parse_args()

# 讀取字彙設定
with open(args.vocab, "r", encoding="utf-8") as f:
    vocab = yaml.safe_load(f)

disallowed = vocab.get("disallow", [])
preferred = vocab.get("prefer", {})

# 在單一檔案執行檢查
def scan_file(path: pathlib.Path) -> int:
    text = path.read_text(encoding="utf-8", errors="ignore")
    violations = 0

    # 檢查黑名單（完整詞邊界）
    for bad in disallowed:
        if not bad:
            continue
        if re.search(rf"\b{re.escape(bad)}\b", text):
            print(f"[DISALLOWED] {bad} in {path}")
            violations += 1

    # 建議替換
    for wrong, right in preferred.items():
        if not wrong:
            continue
        if re.search(rf"\b{re.escape(wrong)}\b", text):
            print(f"[SUGGEST] {wrong} → {right} in {path}")

    return violations

# 展開 glob 並掃描
total_violations = 0
for pattern in args.paths:
    for p in pathlib.Path().glob(pattern):
        if p.is_file():
            total_violations += scan_file(p)

# 若存在黑名單違規，回傳非零碼以便 CI 失敗
sys.exit(1 if total_violations > 0 else 0)
