#!/usr/bin/env bash
# Cổng G5 · Bảo mật (K-GOI-DAC-TA §5): SAST Semgrep, lỗ hổng phụ thuộc npm và Maven (Trivy ở CI).
# gitleaks chạy toàn repo ở .github/workflows/gate-s.yml.
set -euo pipefail
GOC="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$GOC"
loi=0
echo "G5 · bảo mật"
if command -v semgrep >/dev/null; then
  semgrep scan --quiet --error --metrics=off \
    --config p/java --config p/typescript --config p/react --config p/secrets \
    --exclude '**/generated/**' --exclude '**/node_modules/**' --exclude '**/target/**' \
    datahub/services datahub/web && echo "  ✓ Semgrep 0 phát hiện" || { echo "  ✗ Semgrep có phát hiện"; loi=1; }
else
  echo "  - bỏ qua Semgrep (chưa cài: pip install semgrep)"
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
  echo "  - Trivy chạy ở CI (aquasecurity/trivy-action)"
fi
[ $loi -eq 0 ] && echo "G5 XANH" || { echo "G5 ĐỎ"; exit 1; }
