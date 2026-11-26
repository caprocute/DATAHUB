#!/usr/bin/env bash
# Chạy thử DDL PH-14 trên PostgreSQL sạch rồi chạy bài kiểm cô lập tenant.
# Dùng: DH_PG_URL=postgres://... bash chay_thu.sh [--giu]   (từ thư mục csdl/ph14 hoặc bất kỳ đâu)
# Mặc định xóa schema ph14_national và hai vai trò dh_integration_app của bài kiểm trước khi chạy lại.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${DH_PG_URL:?cần biến DH_PG_URL}"
PSQL=(psql "$DH_PG_URL" -q -v ON_ERROR_STOP=1)
if [ "${1:-}" != "--giu" ]; then
  "${PSQL[@]}" -c "SET client_min_messages = warning; DROP SCHEMA IF EXISTS ph14_national CASCADE" >/dev/null
fi
for f in ddl/ph14_*.sql; do
  echo "== $f"
  "${PSQL[@]}" -f "$f"
done
for f in test/ph14_*.sql; do
  echo "== $f"
  "${PSQL[@]}" -f "$f" 2>&1 | grep -E 'PASS|FAIL|ERROR|Hoàn tất' || true
done
