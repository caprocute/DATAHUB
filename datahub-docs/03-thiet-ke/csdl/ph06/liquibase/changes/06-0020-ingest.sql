--liquibase formatted sql
-- Nguồn: ddl/ph06_mdm.sql · 06-0020-ingest.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph06:ph06-0170-candidate-file
CREATE TABLE ph06_mdm.candidate_file (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  domain_code    varchar(32) NOT NULL,
  source_code    varchar(32) NOT NULL,
  file_name      varchar(255) NOT NULL,
  size_bytes     bigint NOT NULL,
  row_count      integer,
  object_ref     varchar(512) NOT NULL,
  sha256         char(64) NOT NULL,
  column_mapping jsonb NOT NULL DEFAULT '{}',
  preview        jsonb,
  previewed_at   timestamptz,
  confirmed_by   varchar(64),
  confirmed_at   timestamptz,
  job_id         uuid,
  expires_at     timestamptz NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_candidate_file PRIMARY KEY (id),
  CONSTRAINT ck_candidate_file_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_candidate_file_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT fk_candidate_file_source FOREIGN KEY (tenant_id, source_code) REFERENCES ph06_mdm.mdm_source (tenant_id, source_code),
  CONSTRAINT ck_candidate_file_size CHECK (size_bytes BETWEEN 1 AND 52428800 AND (row_count IS NULL OR row_count BETWEEN 0 AND 200000)),
  CONSTRAINT ck_candidate_file_sha CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_candidate_file_confirm CHECK ((confirmed_at IS NULL) = (confirmed_by IS NULL))
);
CREATE INDEX ix_candidate_file_domain ON ph06_mdm.candidate_file (tenant_id, domain_code, created_at DESC);
CREATE TRIGGER tg_candidate_file_touch BEFORE UPDATE ON ph06_mdm.candidate_file FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_candidate_file_immutable BEFORE UPDATE ON ph06_mdm.candidate_file FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'source_code', 'sha256');
CALL ph06_mdm.p_enable_rls('ph06_mdm.candidate_file');
COMMENT ON TABLE ph06_mdm.candidate_file IS 'EN-06-25 FR-06-013 Tệp lô nạp ứng viên: tải lên, xem trước, xác nhận. Tệp ≤ 50 MB, ≤ 200.000 dòng (ERR-06-018, 019). Nội dung tệp nằm ở Ceph RGW (object_ref), không trong PostgreSQL; báo cáo xem trước ở preview jsonb, không chứa giá trị SENSITIVE.';
--rollback DROP TABLE IF EXISTS ph06_mdm.candidate_file CASCADE;

--changeset ph06:ph06-0180-source-record-head
CREATE TABLE ph06_mdm.source_record_head (
  id                     uuid NOT NULL,
  tenant_id              varchar(16) NOT NULL,
  domain_code            varchar(32) NOT NULL,
  source_code            varchar(32) NOT NULL,
  source_key             varchar(120) NOT NULL,
  last_version           bigint NOT NULL,
  last_candidate_id      uuid NOT NULL,
  last_source_updated_at timestamptz NOT NULL,
  deleted                boolean NOT NULL DEFAULT false,
  golden_id              uuid,
  created_at             timestamptz NOT NULL DEFAULT now(),
  created_by             varchar(64) NOT NULL,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  updated_by             varchar(64) NOT NULL,
  version                integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_source_record_head PRIMARY KEY (id),
  CONSTRAINT ck_source_record_head_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_source_record_head UNIQUE (tenant_id, domain_code, source_code, source_key),
  CONSTRAINT fk_source_record_head_source FOREIGN KEY (tenant_id, source_code) REFERENCES ph06_mdm.mdm_source (tenant_id, source_code),
  CONSTRAINT ck_source_record_head_version CHECK (last_version >= 0)
);
CREATE INDEX ix_source_record_head_golden ON ph06_mdm.source_record_head (tenant_id, golden_id) WHERE golden_id IS NOT NULL;
CREATE TRIGGER tg_source_record_head_touch BEFORE UPDATE ON ph06_mdm.source_record_head FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CALL ph06_mdm.p_enable_rls('ph06_mdm.source_record_head');
COMMENT ON TABLE ph06_mdm.source_record_head IS 'EN-06-26 FR-06-016 Trạng thái mới nhất của mỗi bản ghi nguồn (sourceCode, sourceKey): phiên bản cao nhất đã nhận, ứng viên cuối, bản ghi vàng đang liên kết. Thực thi BR-06-028 (xử lý một lần theo sourceVersion) và BR-06-029 (bản đến trễ không ghi đè); là bảng nhỏ, khóa duy nhất không phải phân vùng.';
COMMENT ON COLUMN ph06_mdm.source_record_head.golden_id IS 'Bản ghi vàng đang liên kết; tham chiếu logic để không khóa chéo khi hợp nhất.';
--rollback DROP TABLE IF EXISTS ph06_mdm.source_record_head CASCADE;

--changeset ph06:ph06-0190-candidate-record
CREATE TABLE ph06_mdm.candidate_record (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  received_at       timestamptz NOT NULL DEFAULT now(),
  domain_code       varchar(32) NOT NULL,
  source_code       varchar(32) NOT NULL,
  source_key        varchar(120) NOT NULL,
  source_version    bigint NOT NULL,
  source_updated_at timestamptz NOT NULL,
  operation         varchar(8) NOT NULL,
  channel           varchar(16) NOT NULL,
  status            varchar(24) NOT NULL DEFAULT 'RECEIVED',
  model_version     integer,
  raw_enc           bytea,
  raw_kid           varchar(64),
  attrs_norm        jsonb,
  name_norm         varchar(255),
  birth_year        smallint,
  admin_unit_code   varchar(16),
  identifier_type   varchar(16),
  identifier_status varchar(20),
  identifier_hash   bytea,
  block_keys        varchar(72)[],
  warnings          varchar(24)[] NOT NULL DEFAULT '{}',
  attribute_count   smallint NOT NULL DEFAULT 0,
  golden_id         uuid,
  match_outcome     varchar(16),
  file_id           uuid,
  flow_code         varchar(63),
  exchange_id       varchar(64),
  idempotency_key   varchar(128),
  reject_code       varchar(16),
  reject_detail     varchar(2000),
  processed_at      timestamptz,
  CONSTRAINT pk_candidate_record PRIMARY KEY (id, received_at),
  CONSTRAINT ck_candidate_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_candidate_record_op CHECK (operation IN ('CREATE', 'UPDATE', 'DELETE')),
  CONSTRAINT ck_candidate_record_channel CHECK (channel IN ('API', 'FLOW', 'EVENT', 'FILE', 'NATIONAL_SYNC')),
  CONSTRAINT ck_candidate_record_status CHECK (status IN ('RECEIVED', 'REJECTED', 'DUPLICATE', 'SUPERSEDED', 'NORMALIZATION_PENDING', 'NORMALIZED', 'QUEUED', 'LINKED', 'DISCARDED')),
  CONSTRAINT ck_candidate_record_idstatus CHECK (identifier_status IS NULL OR identifier_status IN ('VALID', 'INVALID_FORMAT', 'INVALID_CHECKSUM', 'PLACEHOLDER', 'MISSING')),
  CONSTRAINT ck_candidate_record_idtype CHECK (identifier_type IS NULL OR identifier_type IN ('CCCD_12', 'CMND_9', 'MST_10_13', 'MSDN', 'MA_BHXH_10', 'MA_DVQHNS', 'DVHC_CODE', 'PASSPORT')),
  CONSTRAINT ck_candidate_record_outcome CHECK (match_outcome IS NULL OR match_outcome IN ('MATCH', 'POSSIBLE_MATCH', 'NO_MATCH', 'CONFLICT')),
  CONSTRAINT ck_candidate_record_warnings CHECK (warnings <@ ARRAY['IDENTIFIER_INVALID', 'DATE_PLACEHOLDER', 'ADMIN_UNIT_UNKNOWN', 'ADMIN_UNIT_SPLIT', 'ADMIN_UNIT_CONVERTED', 'CODE_UNMAPPED', 'ADDRESS_UNPARSED']::varchar[]),
  CONSTRAINT ck_candidate_record_hash CHECK (identifier_hash IS NULL OR octet_length(identifier_hash) = 32),
  CONSTRAINT ck_candidate_record_raw CHECK (raw_enc IS NULL OR (raw_kid IS NOT NULL AND octet_length(raw_enc) BETWEEN 29 AND 1048576)),
  CONSTRAINT ck_candidate_record_reject CHECK (status <> 'REJECTED' OR COALESCE(reject_code ~ '^ERR-06-0[0-9]{2}$' OR reject_code = 'DQ_GATE', false)),
  CONSTRAINT ck_candidate_record_birth CHECK (birth_year IS NULL OR birth_year BETWEEN 1850 AND 2100),
  CONSTRAINT ck_candidate_record_key CHECK (char_length(source_key) >= 1)
) PARTITION BY RANGE (received_at);
CALL ph06_mdm.p_ensure_partitions('ph06_mdm.candidate_record', current_date, 3);
CREATE INDEX ix_candidate_record_queue ON ph06_mdm.candidate_record (tenant_id, domain_code, status, received_at);
CREATE INDEX ix_candidate_record_source ON ph06_mdm.candidate_record (tenant_id, source_code, source_key, source_version);
CREATE INDEX ix_candidate_record_idhash ON ph06_mdm.candidate_record (tenant_id, domain_code, identifier_hash) WHERE identifier_hash IS NOT NULL;
CREATE INDEX ix_candidate_record_blocks ON ph06_mdm.candidate_record USING gin (block_keys);
CREATE INDEX ix_candidate_record_name_trgm ON ph06_mdm.candidate_record USING gin (name_norm gin_trgm_ops);
CREATE INDEX ix_candidate_record_golden ON ph06_mdm.candidate_record (tenant_id, golden_id) WHERE golden_id IS NOT NULL;
CALL ph06_mdm.p_enable_rls('ph06_mdm.candidate_record');
COMMENT ON TABLE ph06_mdm.candidate_record IS 'EN-06-09 Bản ghi ứng viên nhận từ nguồn (FR-06-010…017). Dữ liệu gốc mã hóa envelope ở raw_enc; số định danh chỉ ở dạng HMAC identifier_hash; khóa gom nhóm là HMAC (BR-06-016). Phân vùng tháng theo received_at; giữ 365 ngày sau xử lý (retention_policy, khớp SRS cũ), sau đó ẩn danh hóa raw_enc.';
COMMENT ON COLUMN ph06_mdm.candidate_record.raw_enc IS 'Bản ghi gốc, mã hóa envelope (ADR-032); NULL sau khi dọn lưu giữ.';
COMMENT ON COLUMN ph06_mdm.candidate_record.reject_code IS 'Mã ERR-06-0nn, hoặc DQ_GATE khi cổng chất lượng PH-08 từ chối (FR-06-010, FR-08-035).';
COMMENT ON COLUMN ph06_mdm.candidate_record.identifier_hash IS 'HMAC-SHA256 của số định danh đã chuẩn hóa; dùng đối sánh xác định (FR-06-020).';
COMMENT ON COLUMN ph06_mdm.candidate_record.block_keys IS 'Khóa gom nhóm dạng HMAC có tiền tố tên khóa (FR-06-019).';
COMMENT ON COLUMN ph06_mdm.candidate_record.name_norm IS 'Họ tên không dấu, chữ thường (pg_trgm, FR-06-021).';
COMMENT ON COLUMN ph06_mdm.candidate_record.golden_id IS 'Bản ghi vàng liên kết; không khóa ngoại để giữ khi bảng vàng đổi.';
--rollback DROP TABLE IF EXISTS ph06_mdm.candidate_record CASCADE;
