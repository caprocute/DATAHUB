--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0030-catalog-version.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-0300-catalog-version
CREATE TABLE ph07_rdm.catalog_version (
  id              uuid          NOT NULL,
  tenant_id       varchar(16)   NOT NULL,
  catalog_id      uuid          NOT NULL,
  version_no      integer       NOT NULL,
  status          varchar(32)   NOT NULL DEFAULT 'DRAFT',
  effective_from  date,
  effective_to    date,
  legal_basis     text,
  change_note     text,
  origin          varchar(32)   NOT NULL DEFAULT 'MANUAL',
  item_count      integer       NOT NULL DEFAULT 0,
  stats           jsonb         NOT NULL DEFAULT '{}'::jsonb,
  submitted_by    uuid,
  submitted_at    timestamptz,
  approved_by     uuid,
  approved_at     timestamptz,
  published_by    uuid,
  published_at    timestamptz,
  snapshot_uri    varchar(2048),
  schema_hash     char(64),
  last_edited_by  uuid,
  last_edited_at  timestamptz,
  created_at      timestamptz   NOT NULL DEFAULT now(),
  created_by      uuid          NOT NULL,
  updated_at      timestamptz   NOT NULL DEFAULT now(),
  updated_by      uuid          NOT NULL,
  version         integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_catalog_version PRIMARY KEY (id),
  CONSTRAINT uq_catalog_version_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_catalog_version_no UNIQUE (catalog_id, version_no),
  CONSTRAINT fk_catalog_version_catalog FOREIGN KEY (catalog_id, tenant_id)
    REFERENCES ph07_rdm.catalog (id, tenant_id),
  CONSTRAINT ck_catalog_version_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_catalog_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_catalog_version_status CHECK (status IN ('DRAFT','IN_REVIEW','APPROVED','PUBLISHED','DISCARDED')),
  CONSTRAINT ck_catalog_version_origin CHECK (origin IN ('MANUAL','IMPORT','API','SYNC','MIGRATION')),
  CONSTRAINT ck_catalog_version_range CHECK (effective_to IS NULL OR (effective_from IS NOT NULL AND effective_to > effective_from)),
  CONSTRAINT ck_catalog_version_published CHECK (status <> 'PUBLISHED'
      OR (effective_from IS NOT NULL AND published_at IS NOT NULL AND published_by IS NOT NULL)),
  CONSTRAINT ck_catalog_version_stats CHECK (jsonb_typeof(stats) = 'object'),
  CONSTRAINT ck_catalog_version_item_count CHECK (item_count >= 0),
  -- BR-07-007: khoảng hiệu lực [from, to) của các phiên bản đã phát hành
  -- trong một danh mục không chồng lấn. Index GiST của ràng buộc này cũng
  -- phục vụ truy vấn "phiên bản hiệu lực tại ngày d" (toán tử @>).
  CONSTRAINT ex_catalog_version_no_overlap EXCLUDE USING gist (
      catalog_id WITH =,
      daterange(effective_from, effective_to, '[)') WITH &&
  ) WHERE (status = 'PUBLISHED')
);
-- BR-07-005: mỗi danh mục tối đa một phiên bản mở.
CREATE UNIQUE INDEX uq_catalog_version_open ON ph07_rdm.catalog_version (catalog_id)
  WHERE status IN ('DRAFT','IN_REVIEW','APPROVED');
-- Danh sách phiên bản (API-07-011) và tìm phiên bản phát hành mới nhất.
CREATE INDEX ix_catalog_version_catalog ON ph07_rdm.catalog_version (catalog_id, version_no DESC);
-- Hộp chờ duyệt theo tenant.
CREATE INDEX ix_catalog_version_review ON ph07_rdm.catalog_version (tenant_id, submitted_at)
  WHERE status = 'IN_REVIEW';
ALTER TABLE ph07_rdm.catalog_version SET (fillfactor = 90);
CREATE TRIGGER tg_catalog_version_touch BEFORE UPDATE ON ph07_rdm.catalog_version
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.catalog_version ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.catalog_version FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_catalog_version_select ON ph07_rdm.catalog_version FOR SELECT
  USING (tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'));
CREATE POLICY rls_catalog_version_insert ON ph07_rdm.catalog_version FOR INSERT
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_catalog_version_update ON ph07_rdm.catalog_version FOR UPDATE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'))
  WITH CHECK ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
           OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
CREATE POLICY rls_catalog_version_delete ON ph07_rdm.catalog_version FOR DELETE
  USING ((tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')
      OR (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM'));
COMMENT ON TABLE ph07_rdm.catalog_version IS 'EN-07-03 Phiên bản danh mục: ảnh chụp đầy đủ, bất biến khi PUBLISHED (ADR-051). Mẫu RLS S.';
COMMENT ON COLUMN ph07_rdm.catalog_version.status IS 'DRAFT, IN_REVIEW, APPROVED, PUBLISHED, DISCARDED. Nhãn Đang/Sắp/Hết hiệu lực tính từ khoảng ngày, không lưu.';
COMMENT ON COLUMN ph07_rdm.catalog_version.effective_from IS 'Ngày bắt đầu hiệu lực (bao gồm). Bắt buộc khi PUBLISHED.';
COMMENT ON COLUMN ph07_rdm.catalog_version.effective_to IS 'Ngày hết hiệu lực (không bao gồm); rỗng là vô hạn. Được đặt bằng effective_from của phiên bản kế tiếp khi phát hành.';
COMMENT ON COLUMN ph07_rdm.catalog_version.stats IS 'Thống kê khác biệt so với phiên bản trước: {"added":n,"changed":n,"deprecated":n,"removed":n,"breaking":bool}.';
COMMENT ON COLUMN ph07_rdm.catalog_version.schema_hash IS 'SHA-256 hex của JSON Schema sinh từ attribute_def; dùng làm ETag lược đồ.';
COMMENT ON COLUMN ph07_rdm.catalog_version.last_edited_by IS 'Người sửa nội dung bản nháp lần cuối (bản ghi, thuộc tính); phục vụ kiểm tra bốn mắt (D02-08). Cột bổ sung ngoài khung.';
COMMENT ON COLUMN ph07_rdm.catalog_version.version IS 'Khóa lạc quan của cả bản nháp: ứng dụng tăng mỗi khi nội dung bản nháp đổi; tác vụ nhập so sánh khi commit (BR-07-016).';
--rollback DROP TABLE IF EXISTS ph07_rdm.catalog_version CASCADE;

--changeset ph07:ph07-0301-catalog-current-version-fk
ALTER TABLE ph07_rdm.catalog
  ADD CONSTRAINT fk_catalog_current_version FOREIGN KEY (current_version_id, tenant_id)
  REFERENCES ph07_rdm.catalog_version (id, tenant_id);
--rollback ALTER TABLE ph07_rdm.catalog DROP CONSTRAINT IF EXISTS fk_catalog_current_version;
