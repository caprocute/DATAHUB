#!/usr/bin/env bash
# Chạy lần lượt các cổng tự động G1…G5 cho lát cắt (K-GOI-DAC-TA §5). G6 là người duyệt.
# Cần: Docker (Testcontainers), biến PG* trỏ tới PostgreSQL 18 cho G1, Node 22, JDK 21, Maven.
set -euo pipefail
GOC="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$GOC"
PH="${1:-PH07}"
t0=$(date +%s)
echo "== G1 đặc tả";             python3 datahub/tools/g1_dac_ta.py "datahub/spec/$PH/goi.yaml"
echo "== G2+G3+G4(API) backend"; mvn -B -q -f datahub/services/dh-data/pom.xml verify
echo "== G2+G3 web";             npm --prefix datahub/web ci --no-audit --no-fund >/dev/null && npm --prefix datahub/web run check
echo "== G4 E2E";                npm --prefix datahub/web run e2e
echo "== G5 bảo mật";            bash datahub/tools/g5_bao_mat.sh
echo "Mọi cổng tự động XANH sau $(( $(date +%s) - t0 )) giây. G6: người duyệt PR."
