-- =============================================================================
-- D03-03-PH02 · Tệp tổng: nạp toàn bộ schema ph02_catalog theo thứ tự
--   psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -f ph02_all.sql
-- Cần siêu người dùng (hoặc người có quyền tạo vai trò và extension pg_trgm, unaccent, btree_gist)
-- ở lần chạy đầu; Liquibase dùng dh_connect_migrator (thành viên ph02_owner) sau khi bootstrap.
-- Di trú W1: ph02_90_migrate_w1.sql, chạy riêng.
-- =============================================================================
\set ON_ERROR_STOP on
\ir ph02_00_bootstrap.sql
\ir ph02_10_catalog.sql
\ir ph02_20_lint_backend_plan.sql
\ir ph02_30_lifecycle.sql
\ir ph02_40_publish_sla_sync.sql
\ir ph02_50_platform.sql
\ir ph02_60_seed_grants.sql
