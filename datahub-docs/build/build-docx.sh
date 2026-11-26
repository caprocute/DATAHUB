#!/usr/bin/env bash
# Xuất toàn bộ (hoặc một) tài liệu Markdown của datahub-docs ra .docx theo mẫu NĐ 30/2020.
# Dùng: build/build-docx.sh                 # tất cả
#       build/build-docx.sh 02-yeu-cau/D02-01-brd.md
# Yêu cầu: pandoc ≥ 3; python3 + python-docx (sinh mẫu); tùy chọn mmdc để vẽ Mermaid.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=build/out
mkdir -p "$OUT/mermaid"
[ -f build/reference.docx ] || python3 build/make_reference.py
export DH_MERMAID_OUT="$OUT/mermaid"

if [ $# -gt 0 ]; then files=("$@"); else
  mapfile -t files < <(find . -path ./build -prune -o -name 'D*.md' -print -o -name 'ADR-*.md' -print | sort)
fi

for f in "${files[@]}"; do
  name=$(basename "$f" .md)
  pandoc "$f" \
    --from markdown+yaml_metadata_block+pipe_tables \
    --reference-doc build/reference.docx \
    --lua-filter build/mermaid.lua \
    --resource-path "$(dirname "$f"):." \
    --metadata title="$(sed -n 's/^ten: //p' "$f" | head -1)" \
    --toc --toc-depth=3 \
    -o "$OUT/$name.docx"
  echo "✓ $OUT/$name.docx"
done
