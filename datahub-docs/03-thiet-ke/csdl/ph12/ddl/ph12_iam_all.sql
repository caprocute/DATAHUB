-- =============================================================================
-- D03-03-PH12 · Chạy toàn bộ DDL schema ph12_iam theo thứ tự (một phiên psql)
--   psql "$DH_PG_URL" -v ON_ERROR_STOP=1 -f ph12_iam_all.sql
-- Môi trường thật dùng Liquibase, changeset sinh từ dấu -- @file / -- @changeset / -- @rollback.
-- =============================================================================
\set ON_ERROR_STOP on
\ir ph12_iam_01_bootstrap.sql
\ir ph12_iam_02_user_role.sql
\ir ph12_iam_03_identity.sql
\ir ph12_iam_04_policy.sql
\ir ph12_iam_05_audit_tech.sql
\ir ph12_iam_06_seed_grants.sql
RESET ROLE;
