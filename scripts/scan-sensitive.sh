#!/usr/bin/env bash
# Scan the tech-notes tree for sensitive patterns. Exit 1 on any real hit.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Only scan published note content + LICENSE; skip meta docs/scripts that mention scrub rules
RG_GLOBS=(-g '*.md' -g '!SYNC.md' -g '!README.md' -g '!scripts/**' -g '!publish.txt')

PATTERNS=(
  '10\.\d+\.\d+\.\d+'
  '172\.(1[6-9]|2\d|3[01])\.\d+\.\d+'
  '192\.168\.\d+\.\d+'
  'sk-[A-Za-z0-9]{10,}'
  'inchtek'
  'inFlow'
  'dev-asset-hub'
  '\bzwx\b'
  '/Users/zwx'
  '中通'
  '\bzto\b'
  '云驰'
  '雄安'
  'icvs'
  'Sub2API'
  '郑文轩'
  '英驰'
)

hits=0
echo "== sensitive scan: $ROOT =="

for pat in "${PATTERNS[@]}"; do
  match=$(rg -n --pcre2 -i "${RG_GLOBS[@]}" -- "$pat" . 2>/dev/null || true)
  if [[ "$pat" == '中通' && -n "$match" ]]; then
    match=$(printf '%s\n' "$match" | rg -v '中通常|中通过|中通向|中通用' || true)
  fi
  if [[ -n "$match" ]]; then
    echo "--- HIT: $pat ---"
    echo "$match"
    hits=$((hits+1))
  else
    echo "OK: $pat"
  fi
done

echo "--- info: password-like lines (review only, not fail) ---"
rg -n --pcre2 "${RG_GLOBS[@]}" -i 'password\s*[:=]' . 2>/dev/null || echo "(none)"

python3 - <<'PY'
from pathlib import Path
import re, sys
root = Path(".")
skip = {"README.md", "SYNC.md"}
all_stems = {f.stem for f in root.rglob("*.md")}
link_re = re.compile(r"\[\[([^\]|#]+)(?:[|#][^\]]*)?\]\]")
broken = []
for p in root.rglob("*.md"):
    if p.name in skip or "scripts" in p.parts:
        continue
    text = p.read_text(encoding="utf-8")
    for m in link_re.finditer(text):
        target = m.group(1).strip()
        raw = m.group(0)
        if target.startswith(("http", ":", 'b"', "b'", "RFC ")):
            continue
        stem = Path(target).name
        if stem in all_stems:
            continue
        if (root / f"{target}.md").exists() or (root / target).exists():
            continue
        if any(f.stem == stem for f in root.rglob("*.md")):
            continue
        broken.append(f"{p}: {raw}")
if broken:
    print("--- HIT: broken wikilinks ---")
    print("\n".join(broken))
    sys.exit(2)
print("OK: wikilinks")
PY
wiki_rc=$?
if [[ $wiki_rc -eq 2 ]]; then
  hits=$((hits+1))
fi

if [[ $hits -gt 0 ]]; then
  echo "FAIL: $hits pattern group(s) hit"
  exit 1
fi
echo "PASS: clean"
exit 0
