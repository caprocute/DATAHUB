#!/usr/bin/env bash
# Chạy toàn bộ DDL PH-01 trên CSDL mới rồi chạy các bài kiểm.
# Dùng: DH_PG_URL=postgresql://... bash chay_tat_ca.sh   (cần quyền tạo CSDL; không in chuỗi kết nối)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB="${PH01_TEST_DB:-dh_ph01_test}"
psql "$DH_PG_URL" -q -c "DROP DATABASE IF EXISTS $DB" -c "CREATE DATABASE $DB"
URL="$(echo "$DH_PG_URL" | sed -E "s#/[^/?]+(\?.*)?\$#/$DB\1#")"
for f in "$HERE"/../ddl/ph01_[0-9]*.sql; do
  case "$f" in *ph01_99_*) continue;; esac
  echo "== $(basename "$f")"; psql "$URL" -q -v ON_ERROR_STOP=1 -f "$f"
done
echo "== chạy lại ph01_90_grants.sql (runAlways)"; psql "$URL" -q -v ON_ERROR_STOP=1 -f "$HERE/../ddl/ph01_90_grants.sql"
echo "== ph01_isolation_test.sql"; psql "$URL" -q -v ON_ERROR_STOP=1 -f "$HERE/ph01_isolation_test.sql" 2>&1 | grep -E 'PASS|FAIL|ERROR' || true
echo "== ph01_migrate_test.sql"; psql "$URL" -q -v ON_ERROR_STOP=1 -v ddl_dir="$HERE/../ddl" -f "$HERE/ph01_migrate_test.sql" 2>&1 | grep -E 'PASS|FAIL|ERROR' || true
