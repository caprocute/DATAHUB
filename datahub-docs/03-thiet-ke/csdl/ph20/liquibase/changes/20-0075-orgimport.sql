--liquibase formatted sql
-- Nguồn: ddl/ph20_tenant.sql · 20-0075-orgimport.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph20:ph20-0430-org-import-job
CREATE TABLE ph20_tenant.org_import_job (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  file_id                uuid           NOT NULL,
  format                 varchar(4)     NOT NULL,
  mode                   varchar(12)    NOT NULL DEFAULT 'CREATE_ONLY',
  status                 varchar(10)    NOT NULL DEFAULT 'UPLOADED',
  total_rows             integer        NOT NULL DEFAULT 0,
  valid_rows             integer        NOT NULL DEFAULT 0,
  error_rows             integer        NOT NULL DEFAULT 0,
  applied_rows           integer        NOT NULL DEFAULT 0,
  preview_expires_at     timestamptz,
  applied_at             timestamptz,
  error_file_id          uuid,
  error_message          varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_org_import_job PRIMARY KEY (id),
  CONSTRAINT uq_org_import_job_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_org_import_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_org_import_job_status CHECK (status IN ('UPLOADED', 'PREVIEWED', 'APPLYING', 'DONE', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_org_import_job_mode CHECK (mode IN ('CREATE_ONLY', 'UPSERT')),
  CONSTRAINT ck_org_import_job_format CHECK (format IN ('XLSX', 'CSV')),
  CONSTRAINT ck_org_import_job_rows CHECK (total_rows >= 0 AND valid_rows >= 0 AND error_rows >= 0 AND applied_rows >= 0 AND valid_rows + error_rows <= total_rows AND applied_rows <= valid_rows),
  CONSTRAINT ck_org_import_job_done CHECK (status <> 'DONE' OR applied_at IS NOT NULL),
  CONSTRAINT fk_org_import_job_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_org_import_job_file FOREIGN KEY (file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id),
  CONSTRAINT fk_org_import_job_error_file FOREIGN KEY (error_file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id)
);
CREATE INDEX ix_org_import_job_status ON ph20_tenant.org_import_job (tenant_id, status);
CREATE INDEX ix_org_import_job_fk_file ON ph20_tenant.org_import_job (tenant_id, file_id);
CREATE INDEX ix_org_import_job_fk_error_file ON ph20_tenant.org_import_job (tenant_id, error_file_id);
CREATE TRIGGER tg_org_import_job_touch BEFORE UPDATE ON ph20_tenant.org_import_job FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.org_import_job', 'OWN');
COMMENT ON TABLE ph20_tenant.org_import_job IS 'EN-20-30 Lô nhập tổ chức (FR-20-055): tệp Excel hoặc CSV, xem trước kết quả kiểm tra rồi mới áp dụng; số dòng tối đa `20.org.import-max-rows` kiểm ở dịch vụ; bản xem trước hết hạn.';
COMMENT ON COLUMN ph20_tenant.org_import_job.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.org_import_job.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.org_import_job.file_id IS 'Tệp nhập ở `file_object`.';
COMMENT ON COLUMN ph20_tenant.org_import_job.format IS 'Định dạng tệp: `XLSX` hoặc `CSV`.';
COMMENT ON COLUMN ph20_tenant.org_import_job.mode IS 'Chế độ: `CREATE_ONLY` (chỉ thêm mới) hoặc `UPSERT` (thêm hoặc cập nhật).';
COMMENT ON COLUMN ph20_tenant.org_import_job.status IS 'Trạng thái: `UPLOADED`, `PREVIEWED`, `APPLYING`, `DONE`, `FAILED`, `CANCELLED`.';
COMMENT ON COLUMN ph20_tenant.org_import_job.total_rows IS 'Tổng số dòng dữ liệu.';
COMMENT ON COLUMN ph20_tenant.org_import_job.valid_rows IS 'Số dòng hợp lệ.';
COMMENT ON COLUMN ph20_tenant.org_import_job.error_rows IS 'Số dòng lỗi.';
COMMENT ON COLUMN ph20_tenant.org_import_job.applied_rows IS 'Số dòng đã áp dụng.';
COMMENT ON COLUMN ph20_tenant.org_import_job.preview_expires_at IS 'Hạn giữ bản xem trước.';
COMMENT ON COLUMN ph20_tenant.org_import_job.applied_at IS 'Thời điểm áp dụng xong.';
COMMENT ON COLUMN ph20_tenant.org_import_job.error_file_id IS 'Tệp liệt kê dòng lỗi để tải về sửa.';
COMMENT ON COLUMN ph20_tenant.org_import_job.error_message IS 'Thông điệp lỗi chung.';
COMMENT ON COLUMN ph20_tenant.org_import_job.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.org_import_job.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.org_import_job.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.org_import_job.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.org_import_job.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.org_import_job CASCADE;

--changeset ph20:ph20-0440-org-import-row
CREATE TABLE ph20_tenant.org_import_row (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  job_id                 uuid           NOT NULL,
  row_no                 integer        NOT NULL,
  org_code               varchar(64),
  action                 varchar(8)     NOT NULL DEFAULT 'SKIP',
  status                 varchar(8)     NOT NULL DEFAULT 'VALID',
  errors                 jsonb          NOT NULL DEFAULT '[]',
  data                   jsonb          NOT NULL,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_org_import_row PRIMARY KEY (id),
  CONSTRAINT uq_org_import_row_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_org_import_row_row UNIQUE (job_id, row_no),
  CONSTRAINT ck_org_import_row_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_org_import_row_action CHECK (action IN ('CREATE', 'UPDATE', 'SKIP', 'ERROR')),
  CONSTRAINT ck_org_import_row_status CHECK (status IN ('VALID', 'ERROR', 'APPLIED', 'SKIPPED')),
  CONSTRAINT ck_org_import_row_row CHECK (row_no >= 1),
  CONSTRAINT ck_org_import_row_errors CHECK (jsonb_typeof(errors) = 'array' AND jsonb_typeof(data) = 'object'),
  CONSTRAINT ck_org_import_row_error_action CHECK (status <> 'ERROR' OR action = 'ERROR'),
  CONSTRAINT fk_org_import_row_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_org_import_row_job FOREIGN KEY (job_id, tenant_id) REFERENCES ph20_tenant.org_import_job (id, tenant_id) ON DELETE CASCADE
);
CREATE INDEX ix_org_import_row_fk_job ON ph20_tenant.org_import_row (tenant_id, job_id);
CREATE TRIGGER tg_org_import_row_touch BEFORE UPDATE ON ph20_tenant.org_import_row FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.org_import_row', 'OWN');
COMMENT ON TABLE ph20_tenant.org_import_row IS 'EN-20-30 Dòng của lô nhập tổ chức (FR-20-055): nội dung từng dòng, hành động dự kiến và lỗi kiểm tra; dòng lỗi không được áp dụng.';
COMMENT ON COLUMN ph20_tenant.org_import_row.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.org_import_row.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.org_import_row.job_id IS 'Lô nhập.';
COMMENT ON COLUMN ph20_tenant.org_import_row.row_no IS 'Số thứ tự dòng trong tệp, bắt đầu từ 1.';
COMMENT ON COLUMN ph20_tenant.org_import_row.org_code IS 'Mã tổ chức đọc được từ dòng.';
COMMENT ON COLUMN ph20_tenant.org_import_row.action IS 'Hành động: `CREATE`, `UPDATE`, `SKIP`, `ERROR`.';
COMMENT ON COLUMN ph20_tenant.org_import_row.status IS 'Trạng thái: `VALID`, `ERROR`, `APPLIED`, `SKIPPED`.';
COMMENT ON COLUMN ph20_tenant.org_import_row.errors IS 'Danh sách lỗi kiểm tra (cột, mã lỗi, thông điệp).';
COMMENT ON COLUMN ph20_tenant.org_import_row.data IS 'Nội dung dòng đã chuẩn hóa.';
COMMENT ON COLUMN ph20_tenant.org_import_row.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.org_import_row.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.org_import_row.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.org_import_row.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.org_import_row.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.org_import_row CASCADE;
