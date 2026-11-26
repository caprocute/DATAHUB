--liquibase formatted sql
-- Nguồn: ddl/ph08_dq.sql · 08-0010-asset.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph08:ph08-0100-dq-domain
CREATE TABLE ph08_dq.dq_domain (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  domain_code           varchar(32) NOT NULL,
  name                  varchar(255) NOT NULL,
  description           varchar(2000),
  owner_org_code        varchar(63) NOT NULL,
  steward_user          varchar(64),
  status                varchar(16) NOT NULL DEFAULT 'ACTIVE',
  status_reason         varchar(2000),
  on_dependency_failure varchar(16) NOT NULL DEFAULT 'FAIL_OPEN',
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_domain PRIMARY KEY (id),
  CONSTRAINT uq_dq_domain_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_domain_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_domain_code UNIQUE (tenant_id, domain_code),
  CONSTRAINT ck_dq_domain_code CHECK (domain_code ~ '^[A-Z][A-Z0-9_]{1,31}$'),
  CONSTRAINT ck_dq_domain_owner CHECK (owner_org_code ~ '^[A-Za-z0-9][A-Za-z0-9._-]{1,62}$'),
  CONSTRAINT ck_dq_domain_status CHECK (status IN ('ACTIVE', 'INACTIVE')),
  CONSTRAINT ck_dq_domain_failure CHECK (on_dependency_failure IN ('FAIL_OPEN', 'FAIL_CLOSED')),
  CONSTRAINT ck_dq_domain_reason CHECK (status <> 'INACTIVE' OR COALESCE(char_length(status_reason) >= 20, false))
);
CREATE TRIGGER tg_dq_domain_touch BEFORE UPDATE ON ph08_dq.dq_domain FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_domain_immutable BEFORE UPDATE ON ph08_dq.dq_domain FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'domain_code');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_domain');
COMMENT ON TABLE ph08_dq.dq_domain IS 'EN-08-01 Miền chất lượng dữ liệu: nhóm đối tượng đo theo lĩnh vực quản lý, gắn tổ chức chủ quản (DO) và cán bộ phụ trách (FR-08-001). Mang chế độ xử lý khi dịch vụ phụ thuộc lỗi lúc kiểm tra trực tuyến (FAIL_OPEN, FAIL_CLOSED). Không xóa, chỉ chuyển INACTIVE.';
COMMENT ON COLUMN ph08_dq.dq_domain.owner_org_code IS 'Mã tổ chức chủ quản (DO) ở PH-01; kiểm ở dịch vụ, không khóa ngoại liên schema.';
COMMENT ON COLUMN ph08_dq.dq_domain.on_dependency_failure IS 'FAIL_OPEN cho phép bản ghi đi tiếp khi PH-07, PH-05 không khả dụng; FAIL_CLOSED chặn (FR-08-031, 032).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_domain CASCADE;

--changeset ph08:ph08-0110-dq-asset
CREATE TABLE ph08_dq.dq_asset (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  domain_code           varchar(32) NOT NULL,
  asset_code            varchar(63) NOT NULL,
  name                  varchar(255) NOT NULL,
  asset_type            varchar(16) NOT NULL,
  status                varchar(16) NOT NULL DEFAULT 'DRAFT',
  status_reason         varchar(2000),
  owner_org_code        varchar(63) NOT NULL,
  mdm_domain_code       varchar(32),
  rdm_catalog_code      varchar(64),
  connection_id         uuid,
  object_name           varchar(255),
  flow_code             varchar(63),
  key_columns           varchar(63)[] NOT NULL DEFAULT '{}',
  default_scan_mode     varchar(16) NOT NULL DEFAULT 'FULL',
  sample_ratio          numeric(5,4),
  highest_data_class    varchar(16) NOT NULL DEFAULT 'INTERNAL',
  description           varchar(2000),
  incremental_enabled   boolean NOT NULL DEFAULT false,
  updated_at_field      varchar(63),
  inline_enabled        boolean NOT NULL DEFAULT false,
  inline_mode           varchar(10),
  on_dependency_failure varchar(16),
  inline_timeout_ms     smallint NOT NULL DEFAULT 40,
  gate_enabled          boolean NOT NULL DEFAULT false,
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_asset PRIMARY KEY (id),
  CONSTRAINT uq_dq_asset_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_asset_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_asset_code UNIQUE (tenant_id, asset_code),
  CONSTRAINT fk_dq_asset_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph08_dq.dq_domain (tenant_id, domain_code),
  CONSTRAINT ck_dq_asset_code CHECK (asset_code ~ '^[A-Za-z][A-Za-z0-9_.-]{1,62}$'),
  CONSTRAINT ck_dq_asset_type CHECK (asset_type IN ('MDM_DOMAIN', 'RDM_CATALOG', 'SOURCE_DATASET', 'FLOW_MESSAGE')),
  CONSTRAINT ck_dq_asset_status CHECK (status IN ('DRAFT', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_dq_asset_scan_mode CHECK (default_scan_mode IN ('FULL', 'SAMPLE', 'INCREMENTAL')),
  CONSTRAINT ck_dq_asset_class CHECK (highest_data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_dq_asset_ref CHECK ((asset_type = 'MDM_DOMAIN') = (mdm_domain_code IS NOT NULL) AND (asset_type = 'RDM_CATALOG') = (rdm_catalog_code IS NOT NULL) AND (asset_type = 'SOURCE_DATASET') = (connection_id IS NOT NULL AND object_name IS NOT NULL) AND (asset_type = 'FLOW_MESSAGE') = (flow_code IS NOT NULL)),
  CONSTRAINT ck_dq_asset_inline_mode CHECK (inline_mode IS NULL OR inline_mode IN ('STRICT', 'ADVISORY')),
  CONSTRAINT ck_dq_asset_inline_on CHECK (NOT inline_enabled OR inline_mode IS NOT NULL),
  CONSTRAINT ck_dq_asset_failure CHECK (on_dependency_failure IS NULL OR on_dependency_failure IN ('FAIL_OPEN', 'FAIL_CLOSED')),
  CONSTRAINT ck_dq_asset_timeout CHECK (inline_timeout_ms BETWEEN 10 AND 50),
  CONSTRAINT ck_dq_asset_gate CHECK (NOT gate_enabled OR (asset_type = 'MDM_DOMAIN' AND inline_enabled)),
  CONSTRAINT ck_dq_asset_incremental CHECK (NOT incremental_enabled OR (asset_type <> 'FLOW_MESSAGE' AND (asset_type <> 'SOURCE_DATASET' OR updated_at_field IS NOT NULL))),
  CONSTRAINT ck_dq_asset_updated_field CHECK (updated_at_field IS NULL OR updated_at_field ~ '^[A-Za-z_][A-Za-z0-9_]{0,62}$'),
  CONSTRAINT ck_dq_asset_sample CHECK ((default_scan_mode = 'SAMPLE') = (sample_ratio IS NOT NULL) AND (sample_ratio IS NULL OR (sample_ratio > 0 AND sample_ratio <= 1))),
  CONSTRAINT ck_dq_asset_reason CHECK (status NOT IN ('SUSPENDED', 'RETIRED') OR COALESCE(char_length(status_reason) >= 20, false))
);
CREATE INDEX ix_dq_asset_domain ON ph08_dq.dq_asset (tenant_id, domain_code, status);
CREATE INDEX ix_dq_asset_owner ON ph08_dq.dq_asset (tenant_id, owner_org_code, status);
CREATE INDEX ix_dq_asset_mdm ON ph08_dq.dq_asset (tenant_id, mdm_domain_code) WHERE mdm_domain_code IS NOT NULL;
CREATE INDEX ix_dq_asset_rdm ON ph08_dq.dq_asset (tenant_id, rdm_catalog_code) WHERE rdm_catalog_code IS NOT NULL;
CREATE TRIGGER tg_dq_asset_touch BEFORE UPDATE ON ph08_dq.dq_asset FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_asset_immutable BEFORE UPDATE ON ph08_dq.dq_asset FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'asset_code', 'asset_type');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_asset');
COMMENT ON TABLE ph08_dq.dq_asset IS 'EN-08-02 Đối tượng đo chất lượng, bốn loại: miền dữ liệu chủ PH-06, danh mục PH-07, bảng hoặc khung nhìn nguồn qua kết nối PH-05 chỉ đọc, bản tin luồng PH-04 (FR-08-002, 003, 004, 006, 007). Cột tham chiếu bắt buộc đúng theo loại. Không xóa, chỉ ngừng hoặc khôi phục.';
COMMENT ON COLUMN ph08_dq.dq_asset.connection_id IS 'Mã kết nối PH-05 (tài khoản chỉ đọc, Q359, ADR-067); kiểm ở dịch vụ, không khóa ngoại.';
COMMENT ON COLUMN ph08_dq.dq_asset.mdm_domain_code IS 'Domain PH-06; đọc qua view hợp đồng chỉ đọc do PH-06 cấp, không đọc bảng nghiệp vụ.';
COMMENT ON COLUMN ph08_dq.dq_asset.highest_data_class IS 'Phân loại cao nhất trong các trường, lấy từ PH-09; điều khiển cách lưu giá trị lỗi.';
COMMENT ON COLUMN ph08_dq.dq_asset.incremental_enabled IS 'Bật đo tăng dần theo sự kiện PH-06, PH-07 (FR-08-025, API-08-130, 131); không áp cho FLOW_MESSAGE, SOURCE_DATASET cần updated_at_field.';
COMMENT ON COLUMN ph08_dq.dq_asset.inline_enabled IS 'Cấu hình kiểm tra trực tuyến của đối tượng (FR-08-032, 035): bật, chế độ STRICT hay ADVISORY, hành vi khi phụ thuộc lỗi (rỗng thì theo miền), ngân sách ms, cổng chất lượng cho PH-06.';
COMMENT ON COLUMN ph08_dq.dq_asset.gate_enabled IS 'Cổng chất lượng đầu vào cho PH-06, chỉ MDM_DOMAIN đã bật trực tuyến (FR-08-035).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_asset CASCADE;

--changeset ph08:ph08-0120-dq-asset-field
CREATE TABLE ph08_dq.dq_asset_field (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  asset_id              uuid NOT NULL,
  field_name            varchar(63) NOT NULL,
  label                 varchar(255),
  field_type            varchar(16) NOT NULL DEFAULT 'STRING',
  cde                   boolean NOT NULL DEFAULT false,
  data_class            varchar(16) NOT NULL DEFAULT 'INTERNAL',
  classification_status varchar(16) NOT NULL DEFAULT 'PROPOSED',
  value_mode            varchar(16) NOT NULL DEFAULT 'MASKED',
  rdm_catalog_code      varchar(64),
  sort_order            smallint NOT NULL DEFAULT 0,
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_asset_field PRIMARY KEY (id),
  CONSTRAINT ck_dq_asset_field_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_asset_field_name UNIQUE (tenant_id, asset_id, field_name),
  CONSTRAINT fk_dq_asset_field_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT ck_dq_asset_field_name CHECK (field_name ~ '^[A-Za-z_][A-Za-z0-9_]{0,62}$'),
  CONSTRAINT ck_dq_asset_field_type CHECK (field_type IN ('STRING', 'INTEGER', 'DECIMAL', 'DATE', 'TIMESTAMP', 'BOOLEAN', 'CODE', 'JSON')),
  CONSTRAINT ck_dq_asset_field_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_dq_asset_field_classification CHECK (classification_status IN ('PROPOSED', 'CONFIRMED')),
  CONSTRAINT ck_dq_asset_field_mode CHECK (value_mode IN ('MASKED', 'HASH_ONLY', 'PLAIN')),
  CONSTRAINT ck_dq_asset_field_mode_class CHECK ((data_class <> 'SENSITIVE' OR value_mode = 'HASH_ONLY') AND (data_class <> 'RESTRICTED' OR value_mode <> 'PLAIN'))
);
CREATE INDEX ix_dq_asset_field_cde ON ph08_dq.dq_asset_field (tenant_id, asset_id) WHERE cde;
CREATE TRIGGER tg_dq_asset_field_touch BEFORE UPDATE ON ph08_dq.dq_asset_field FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_asset_field');
COMMENT ON TABLE ph08_dq.dq_asset_field IS 'EN-08-03 Trường của đối tượng đo, kèm cờ phần tử dữ liệu trọng yếu (CDE) và phân loại PH-09 (FR-08-005, 006, 009). Cột value_mode quyết định cách lưu giá trị lỗi: trường Nhạy cảm chỉ được băm, trường Hạn chế phải che.';
COMMENT ON COLUMN ph08_dq.dq_asset_field.value_mode IS 'MASKED lưu giá trị đã che, HASH_ONLY chỉ lưu băm, PLAIN chỉ cho PUBLIC, INTERNAL. SENSITIVE bắt buộc HASH_ONLY, RESTRICTED không được PLAIN (BR giá trị lỗi, FR-08-036).';
COMMENT ON COLUMN ph08_dq.dq_asset_field.cde IS 'Phần tử dữ liệu trọng yếu: lỗi CRITICAL bắt buộc ở CDE theo cấu hình (FR-08-005).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_asset_field CASCADE;

--changeset ph08:ph08-0130-dq-profile-run
CREATE TABLE ph08_dq.dq_profile_run (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  asset_id           uuid NOT NULL,
  status             varchar(16) NOT NULL DEFAULT 'QUEUED',
  scan_mode          varchar(16) NOT NULL DEFAULT 'SAMPLE',
  sample_rows        bigint,
  row_count          bigint,
  requested_by       varchar(64) NOT NULL,
  started_at         timestamptz,
  finished_at        timestamptz,
  source_snapshot_at timestamptz,
  error_code         varchar(16),
  error_message      varchar(2000),
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_profile_run PRIMARY KEY (id),
  CONSTRAINT uq_dq_profile_run_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_profile_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_profile_run_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT ck_dq_profile_run_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'FAILED')),
  CONSTRAINT ck_dq_profile_run_mode CHECK (scan_mode IN ('FULL', 'SAMPLE', 'EXTERNAL')),
  CONSTRAINT ck_dq_profile_run_done CHECK (status NOT IN ('SUCCEEDED', 'FAILED') OR finished_at IS NOT NULL),
  CONSTRAINT ck_dq_profile_run_error CHECK (error_code IS NULL OR error_code ~ '^ERR-08-[0-9]{3}$')
);
CREATE INDEX ix_dq_profile_run_asset ON ph08_dq.dq_profile_run (tenant_id, asset_id, created_at DESC);
CREATE TRIGGER tg_dq_profile_run_touch BEFORE UPDATE ON ph08_dq.dq_profile_run FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_profile_run');
COMMENT ON TABLE ph08_dq.dq_profile_run IS 'EN-08-04 Lần chạy hồ sơ dữ liệu (profiling) cho một đối tượng đo, theo mẫu hoặc toàn bộ (FR-08-008, 011). Kết quả theo cột ở dq_profile_column.';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_profile_run CASCADE;

--changeset ph08:ph08-0140-dq-profile-column
CREATE TABLE ph08_dq.dq_profile_column (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  profile_run_id    uuid NOT NULL,
  asset_id          uuid NOT NULL,
  field_name        varchar(63) NOT NULL,
  inferred_type     varchar(16),
  sensitive         boolean NOT NULL DEFAULT false,
  row_count         bigint NOT NULL,
  null_count        bigint NOT NULL DEFAULT 0,
  empty_count       bigint NOT NULL DEFAULT 0,
  distinct_estimate bigint,
  min_masked        varchar(255),
  max_masked        varchar(255),
  quantiles         jsonb,
  top_values        jsonb NOT NULL DEFAULT '[]',
  pattern_stats     jsonb NOT NULL DEFAULT '[]',
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_profile_column PRIMARY KEY (id),
  CONSTRAINT ck_dq_profile_column_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_profile_column UNIQUE (tenant_id, profile_run_id, field_name),
  CONSTRAINT fk_dq_profile_column_run FOREIGN KEY (tenant_id, profile_run_id) REFERENCES ph08_dq.dq_profile_run (tenant_id, id),
  CONSTRAINT ck_dq_profile_column_name CHECK (field_name ~ '^[A-Za-z_][A-Za-z0-9_]{0,62}$'),
  CONSTRAINT ck_dq_profile_column_counts CHECK (row_count >= 0 AND null_count >= 0 AND empty_count >= 0 AND null_count <= row_count),
  CONSTRAINT ck_dq_profile_column_sensitive CHECK (NOT sensitive OR (min_masked IS NULL AND max_masked IS NULL AND top_values = '[]'::jsonb))
);
CREATE INDEX ix_dq_profile_column_asset ON ph08_dq.dq_profile_column (tenant_id, asset_id, field_name);
CREATE TRIGGER tg_dq_profile_column_touch BEFORE UPDATE ON ph08_dq.dq_profile_column FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_profile_column');
COMMENT ON TABLE ph08_dq.dq_profile_column IS 'EN-08-05 Thống kê hồ sơ theo cột: số rỗng, số giá trị khác nhau ước lượng bằng HyperLogLog, phân vị (Apache DataSketches), mẫu định dạng thường gặp (FR-08-009, 010). Cột Nhạy cảm không lưu giá trị mẫu, nhỏ nhất, lớn nhất.';
COMMENT ON COLUMN ph08_dq.dq_profile_column.sensitive IS 'Sao chép từ dq_asset_field.value_mode = HASH_ONLY; khi true, CHECK cấm lưu giá trị mẫu.';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_profile_column CASCADE;
