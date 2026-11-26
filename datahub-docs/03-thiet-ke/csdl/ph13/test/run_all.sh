#!/bin/bash
# D03-03-PH13 · Chạy toàn bộ DDL và bài kiểm của PH-13 trên CSDL đang trỏ bởi $DH_PG_URL (cần quyền siêu người dùng để tạo vai trò).
# CẢNH BÁO: xóa schema ph13_audit, ph13_obs nếu đã có (dùng cho CSDL thử, không dùng cho môi trường thật).
# Dùng:  DH_PG_URL=postgres://... bash test/run_all.sh [--bench]      (chạy từ thư mục csdl/ph13)
set -euo pipefail
cd "$(dirname "$0")/.."
psql "$DH_PG_URL" -q -v ON_ERROR_STOP=1 -c "DROP SCHEMA IF EXISTS ph13_audit CASCADE" -c "DROP SCHEMA IF EXISTS ph13_obs CASCADE" >/dev/null 2>&1 || true
psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -q -f ddl/ph13_audit.sql
psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -q -f ddl/ph13_obs.sql
psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -q -f test/ph13_isolation_test.sql 2>&1 | tee /tmp/ph13_isolation_test.out | grep -c 'NOTICE:  PASS' | xargs echo "Số khối đạt:"
if [ "${1:-}" = "--bench" ]; then psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -q -f test/ph13_bench_chain.sql; fi
