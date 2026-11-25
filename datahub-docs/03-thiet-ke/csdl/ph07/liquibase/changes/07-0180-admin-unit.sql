--liquibase formatted sql
-- Nguồn: ddl/ph07_rdm.sql · 07-0180-admin-unit.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph07:ph07-1800-admin-unit
CREATE TABLE ph07_rdm.admin_unit (
  id              uuid          NOT NULL,
  tenant_id       varchar(16)   NOT NULL DEFAULT 'COMMON',
  code            varchar(64)   NOT NULL,
  name            varchar(255)  NOT NULL,
  level           varchar(32)   NOT NULL,
  unit_type       varchar(32)   NOT NULL,
  parent_id       uuid,
  effective_from  date          NOT NULL,
  effective_to    date,
  successor_ids   jsonb,
  source_version  text          NOT NULL,
  created_at      timestamptz   NOT NULL DEFAULT now(),
  created_by      uuid          NOT NULL,
  updated_at      timestamptz   NOT NULL DEFAULT now(),
  updated_by      uuid          NOT NULL,
  version         integer       NOT NULL DEFAULT 0,
  deleted_at      timestamptz,
  CONSTRAINT pk_admin_unit PRIMARY KEY (id),
  CONSTRAINT fk_admin_unit_parent FOREIGN KEY (parent_id) REFERENCES ph07_rdm.admin_unit (id),
  CONSTRAINT ck_admin_unit_tenant CHECK (tenant_id = 'COMMON'),
  CONSTRAINT ck_admin_unit_code CHECK (code ~ '^[0-9]{2}([0-9]{1}|[0-9]{3})?$'),
  CONSTRAINT ck_admin_unit_name_nfc CHECK (name IS NFC NORMALIZED),
  CONSTRAINT ck_admin_unit_level CHECK (level IN ('PROVINCE','DISTRICT','COMMUNE')),
  CONSTRAINT ck_admin_unit_type CHECK (
       (level = 'PROVINCE' AND unit_type IN ('TINH','THANH_PHO'))
    OR (level = 'DISTRICT' AND unit_type IN ('QUAN','HUYEN','THI_XA','THANH_PHO'))
    OR (level = 'COMMUNE'  AND unit_type IN ('XA','PHUONG','DAC_KHU','THI_TRAN'))),
  CONSTRAINT ck_admin_unit_range CHECK (effective_to IS NULL OR effective_to > effective_from),
  CONSTRAINT ck_admin_unit_successors CHECK (successor_ids IS NULL OR jsonb_typeof(successor_ids) = 'array'),
  -- BR-07-021: không gán lại một mã cho đơn vị khác trong khoảng thời gian chồng lấn.
  CONSTRAINT ex_admin_unit_code EXCLUDE USING gist (
      code WITH =, daterange(effective_from, effective_to, '[)') WITH &&) WHERE (deleted_at IS NULL)
);
CREATE INDEX ix_admin_unit_parent ON ph07_rdm.admin_unit (parent_id);
CREATE INDEX ix_admin_unit_current ON ph07_rdm.admin_unit (level, code) WHERE effective_to IS NULL AND deleted_at IS NULL;
CREATE TRIGGER tg_admin_unit_touch BEFORE UPDATE ON ph07_rdm.admin_unit
  FOR EACH ROW EXECUTE FUNCTION ph07_rdm.tg_touch();
ALTER TABLE ph07_rdm.admin_unit ENABLE ROW LEVEL SECURITY;
ALTER TABLE ph07_rdm.admin_unit FORCE ROW LEVEL SECURITY;
CREATE POLICY rls_admin_unit_select ON ph07_rdm.admin_unit FOR SELECT
  USING (tenant_id IN (current_setting('app.tenant_id', false), 'COMMON'));
CREATE POLICY rls_admin_unit_insert ON ph07_rdm.admin_unit FOR INSERT
  WITH CHECK (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM');
CREATE POLICY rls_admin_unit_update ON ph07_rdm.admin_unit FOR UPDATE
  USING (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM')
  WITH CHECK (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM');
CREATE POLICY rls_admin_unit_delete ON ph07_rdm.admin_unit FOR DELETE
  USING (tenant_id = 'COMMON' AND current_setting('app.tenant_id', false) = 'PLATFORM');
COMMENT ON TABLE ph07_rdm.admin_unit IS 'EN-07-18 = DD-07 Đơn vị hành chính: bảng chiếu định danh ổn định từ danh mục DVHC, làm mới trong giao dịch phát hành (f_refresh_admin_unit). Chỉ COMMON; chỉ PLATFORM ghi.';
COMMENT ON COLUMN ph07_rdm.admin_unit.level IS 'PROVINCE, COMMUNE (hiện hành); DISTRICT chỉ trong dữ liệu lịch sử trước 01/7/2025.';
COMMENT ON COLUMN ph07_rdm.admin_unit.unit_type IS 'TINH, THANH_PHO (cấp tỉnh hoặc huyện), QUAN, HUYEN, THI_XA, XA, PHUONG, DAC_KHU, THI_TRAN (lịch sử). Giá trị lịch sử là đề xuất bổ sung D02-07.';
COMMENT ON COLUMN ph07_rdm.admin_unit.successor_ids IS 'Mảng id đơn vị kế thừa khi sáp nhập, chia tách, đổi mã.';
COMMENT ON COLUMN ph07_rdm.admin_unit.source_version IS 'Phiên bản danh mục nguồn, dạng "DVHC:{version_no}".';
--rollback DROP TABLE IF EXISTS ph07_rdm.admin_unit CASCADE;
