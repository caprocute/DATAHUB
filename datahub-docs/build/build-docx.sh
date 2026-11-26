#!/usr/bin/env bash
# Xuất tài liệu Markdown của datahub-docs ra .docx theo khuôn trình bày K-TRINH-BAY
# (bìa, thông tin tài liệu, lịch sử phiên bản, ký duyệt, mục lục, đánh số bảng và hình,
#  đầu và chân trang, sơ đồ Mermaid thành hình).
# Dùng: build/build-docx.sh                       # tất cả
#       build/build-docx.sh 02-yeu-cau/D02-01-brd.md
#       DH_PDF=1 build/build-docx.sh <tệp>        # kèm bản PDF; số trang mục lục điền sẵn vào .docx (cần LibreOffice)
# Yêu cầu: pandoc ≥ 3; python3 + python-docx; mmdc (@mermaid-js/mermaid-cli) để vẽ sơ đồ.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=build/out
mkdir -p "$OUT/mermaid"
python3 build/make_reference.py >/dev/null
export DH_MERMAID_OUT="$OUT/mermaid"

# Trình duyệt cho mmdc: dùng Chromium có sẵn của máy nếu Puppeteer chưa tải.
if [ -z "${PUPPETEER_EXECUTABLE_PATH:-}" ] && [ -x /opt/pw-browsers/chromium ]; then
  export PUPPETEER_EXECUTABLE_PATH=/opt/pw-browsers/chromium
fi
command -v mmdc >/dev/null || echo "! Chưa có mmdc: sơ đồ Mermaid sẽ giữ dạng mã. Cài: npm i -g @mermaid-js/mermaid-cli"

if [ $# -gt 0 ]; then files=("$@"); else
  mapfile -t files < <(find . -path ./build -prune -o -name 'D*.md' -print -o -name 'ADR-*.md' -print | sort)
fi

for f in "${files[@]}"; do
  name=$(basename "$f" .md)
  ma=$(sed -n 's/^ma_tai_lieu: //p' "$f" | head -1)
  ten=$(sed -n 's/^ten: //p' "$f" | head -1)
  pandoc "$f" \
    --from markdown+yaml_metadata_block+pipe_tables+fenced_divs \
    --reference-doc build/reference.docx \
    --lua-filter build/trinh-bay.lua \
    --resource-path "$(dirname "$f"):." \
    --metadata toc-title="Mục lục" \
    --toc --toc-depth=3 \
    -o "$OUT/$name.docx"
  python3 build/hau_xu_ly.py "$OUT/$name.docx" "${ma:-$name}" "${ten:-$name}"
  if [ "${DH_PDF:-0}" = "1" ]; then
    if python3 build/cap_nhat_muc_luc.py "$OUT/$name.docx" "$OUT/$name.pdf"; then
      python3 build/hau_xu_ly.py --so-trang "$OUT/$name.docx" "$OUT/$name.docx.so-trang.txt"
      rm -f "$OUT/$name.docx.so-trang.txt"
    else echo "! Không tạo được PDF cho $name"; fi
  fi
  echo "✓ $OUT/$name.docx"
done
