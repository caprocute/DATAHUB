#!/usr/bin/env bash
# Cổng G5 · Bảo mật (K-GOI-DAC-TA §5): SAST Semgrep, lỗ hổng phụ thuộc npm và Maven (Trivy ở CI).
# gitleaks chạy toàn repo ở .github/workflows/gate-s.yml.
set -euo pipefail
GOC="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$GOC"
loi=0
echo "G5 · bảo mật"
if command -v semgrep >/dev/null; then
  set +e
  semgrep scan --quiet --error --metrics=off \
    --config p/java --config p/typescript --config p/react --config p/secrets \
    --exclude '**/generated/**' --exclude '**/node_modules/**' --exclude '**/target/**' \
    datahub/services datahub/web >/tmp/g5-semgrep.txt 2>&1
  rc=$?
  set -e
  case $rc in
    0) echo "  ✓ Semgrep 0 phát hiện" ;;
    1) echo "  ✗ Semgrep có phát hiện:"; tail -40 /tmp/g5-semgrep.txt; loi=1 ;;
    *) echo "  ✗ Semgrep KHÔNG CHẠY ĐƯỢC (mã $rc, thường do không tải được bộ luật):"; tail -5 /tmp/g5-semgrep.txt; loi=1 ;;
  esac
else
  echo "  ✗ Semgrep chưa cài (pip install semgrep)"; loi=1
fi
if [ -d datahub/web/node_modules ]; then
  npm --prefix datahub/web audit --omit=dev --audit-level=high >/tmp/g5-npm.txt 2>&1 \
    && echo "  ✓ npm audit (prod) không có lỗ hổng high/critical" \
    || { echo "  ✗ npm audit:"; tail -20 /tmp/g5-npm.txt; loi=1; }
fi
if command -v trivy >/dev/null; then
  trivy fs --quiet --exit-code 1 --severity HIGH,CRITICAL --ignore-unfixed datahub/ \
    && echo "  ✓ Trivy không có lỗ hổng HIGH/CRITICAL" || { echo "  ✗ Trivy"; loi=1; }
else
  echo "  - Trivy chạy ở CI (bước riêng trong datahub-code.yml)"
fi
[ $loi -eq 0 ] && echo "G5 XANH" || { echo "G5 ĐỎ"; exit 1; }
