--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0070-version-review.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-0700-version-review
-- Bảng chỉ-thêm: ngoại lệ có chủ đích với D00-01 §5.1 (giống DD-10),
-- không có updated_at/updated_by/version; actor/at đóng vai created_by/at.
CREATE TABLE ph07_rdm.version_review (
  id          uuid          NOT NULL,
  tenant_id   varchar(16)   NOT NULL,
  version_id  uuid          NOT NULL,
  action      varchar(32)   NOT NULL,
  actor       uuid          NOT NULL,
  comment     text,
  diff_stats  jsonb,
  at          timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_version_review PRIMARY KEY (id),
  CONSTRAINT fk_version_review_version FOREIGN KEY (version_id, tenant_id)
    REFERENCES ph07_rdm.catalog_version (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_version_review_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_version_review_action CHECK (action IN ('SUBMIT','WITHDRAW','APPROVE','UNAPPROVE','REJECT','PUBLISH','DISCARD')),
  CONSTRAINT ck_version_review_reject_reason CHECK (action <> 'REJECT' OR length(btrim(coalesce(comment, ''))) > 0)
);
CREATE INDEX ix_version_review_version ON ph07_rdm.version_review (version_id, at);
ALTER TABLE ph07_rdm.version_review ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.version_review FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_version_review_select ON ph07_rdm.version_review FOR SELECT
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_version_review_insert ON ph07_rdm.version_review FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.version_review IS 'EN-07-07 Nhật ký duyệt phiên bản (chỉ-thêm). Mẫu RLS P: lời phê duyệt COMMON chỉ PLATFORM thấy.';
COMMENT ON COLUMN ph07_rdm.version_review.comment IS 'Ý kiến; bắt buộc khi REJECT.';
--rollback DROP TABLE IF EXISTS ph07_rdm.version_review CASCADE;
