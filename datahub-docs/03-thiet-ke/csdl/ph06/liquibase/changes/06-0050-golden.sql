--liquibase formatted sql
-- Nguồn: ddl/ph06_mdm.sql · 06-0050-golden.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph06:ph06-0300-golden-record
CREATE TABLE ph06_mdm.golden_record (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  domain_code        varchar(32) NOT NULL,
  model_version      integer NOT NULL,
  status             varchar(8) NOT NULL DEFAULT 'ACTIVE',
  merged_into        uuid,
  confidence         numeric(5,4),
  display_name       varchar(255),
  name_norm          varchar(255),
  birth_year         smallint,
  admin_unit_code    varchar(16),
  link_count         integer NOT NULL DEFAULT 0,
  block_keys         varchar(72)[] NOT NULL DEFAULT '{}',
  restricted         boolean NOT NULL DEFAULT false,
  lock_reason        varchar(500),
  retire_reason      varchar(16),
  retire_note        varchar(2000),
  retired_at         timestamptz,
  retired_by         varchar(64),
  national_synced_at timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 1,
  CONSTRAINT pk_golden_record PRIMARY KEY (id),
  CONSTRAINT uq_golden_record_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_golden_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_golden_record_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT fk_golden_record_merged FOREIGN KEY (tenant_id, merged_into) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT ck_golden_record_status CHECK (status IN ('ACTIVE', 'LOCKED', 'MERGED', 'RETIRED')),
  CONSTRAINT ck_golden_record_merged CHECK ((status = 'MERGED') = (merged_into IS NOT NULL) AND merged_into IS DISTINCT FROM id),
  CONSTRAINT ck_golden_record_retired CHECK ((status = 'RETIRED') = (retire_reason IS NOT NULL)),
  CONSTRAINT ck_golden_record_retire CHECK (retire_reason IS NULL OR retire_reason IN ('ORPHANED', 'DISSOLVED', 'DECEASED', 'TEST_DATA', 'OTHER')),
  CONSTRAINT ck_golden_record_locked CHECK (status <> 'LOCKED' OR lock_reason IS NOT NULL),
  CONSTRAINT ck_golden_record_restricted CHECK (NOT restricted OR status = 'LOCKED'),
  CONSTRAINT ck_golden_record_confidence CHECK (confidence IS NULL OR confidence BETWEEN 0 AND 1),
  CONSTRAINT ck_golden_record_birth CHECK (birth_year IS NULL OR birth_year BETWEEN 1850 AND 2100)
);
CREATE INDEX ix_golden_record_domain ON ph06_mdm.golden_record (tenant_id, domain_code, status);
CREATE INDEX ix_golden_record_name_trgm ON ph06_mdm.golden_record USING gin (domain_code, name_norm gin_trgm_ops);
CREATE INDEX ix_golden_record_blocks ON ph06_mdm.golden_record USING gin (block_keys);
CREATE INDEX ix_golden_record_area ON ph06_mdm.golden_record (tenant_id, domain_code, admin_unit_code, birth_year) WHERE status = 'ACTIVE';
CREATE INDEX ix_golden_record_merged ON ph06_mdm.golden_record (tenant_id, merged_into) WHERE merged_into IS NOT NULL;
CREATE TRIGGER tg_golden_record_touch BEFORE UPDATE ON ph06_mdm.golden_record FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_golden_record_immutable BEFORE UPDATE ON ph06_mdm.golden_record FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code');
CALL ph06_mdm.p_enable_rls('ph06_mdm.golden_record');
COMMENT ON TABLE ph06_mdm.golden_record IS 'EN-06-01 Bản ghi vàng (FR-06-034…042). goldenId là id (UUIDv7); version bắt đầu 1 và tăng mỗi thay đổi, là số phiên bản trong lịch sử. Không xóa (BR-06-007): chỉ MERGED hoặc RETIRED. Cột display_name, name_norm, birth_year, admin_unit_code là bản sao có chỉ mục để tìm nhanh bằng pg_trgm.';
COMMENT ON COLUMN ph06_mdm.golden_record.model_version IS 'Phiên bản mô hình domain áp khi tạo hoặc cập nhật gần nhất.';
COMMENT ON COLUMN ph06_mdm.golden_record.name_norm IS 'Họ tên hoặc tên tổ chức không dấu, chữ thường; chỉ mục GIN gin_trgm_ops (cần btree_gin cho domain_code).';
COMMENT ON COLUMN ph06_mdm.golden_record.version IS 'Phiên bản bản ghi vàng, ETag; ghi ảnh chụp golden_history trước khi tăng (BR-06-005).';
--rollback DROP TABLE IF EXISTS ph06_mdm.golden_record CASCADE;

--changeset ph06:ph06-0310-golden-attribute
CREATE TABLE ph06_mdm.golden_attribute (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  golden_id          uuid NOT NULL,
  attribute_name     varchar(63) NOT NULL,
  seq                smallint NOT NULL DEFAULT 0,
  data_class         varchar(16) NOT NULL,
  value_json         jsonb,
  value_enc          bytea,
  value_kid          varchar(64),
  value_hash         bytea,
  source_code        varchar(32) NOT NULL,
  source_key         varchar(120),
  source_updated_at  timestamptz,
  strategy           varchar(24) NOT NULL,
  confidence         numeric(5,4),
  manual_valid_until timestamptz,
  national_authority boolean NOT NULL DEFAULT false,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_golden_attribute PRIMARY KEY (id),
  CONSTRAINT ck_golden_attribute_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_golden_attribute UNIQUE (tenant_id, golden_id, attribute_name, seq),
  CONSTRAINT fk_golden_attribute_golden FOREIGN KEY (tenant_id, golden_id) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT ck_golden_attribute_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_golden_attribute_strategy CHECK (strategy IN ('NATIONAL_AUTHORITY', 'MANUAL_OVERRIDE', 'SOURCE_PRIORITY', 'MOST_RECENT', 'MOST_COMPLETE', 'MOST_FREQUENT', 'FIRST_VALUE')),
  CONSTRAINT ck_golden_attribute_name CHECK (attribute_name ~ '^[a-z][a-zA-Z0-9]{1,62}$'),
  CONSTRAINT ck_golden_attribute_sensitive CHECK ((data_class = 'SENSITIVE' AND value_json IS NULL AND value_enc IS NOT NULL AND value_hash IS NOT NULL AND value_kid IS NOT NULL) OR (data_class <> 'SENSITIVE' AND value_enc IS NULL AND value_hash IS NULL)),
  CONSTRAINT ck_golden_attribute_hash CHECK (value_hash IS NULL OR octet_length(value_hash) = 32),
  CONSTRAINT ck_golden_attribute_manual CHECK (strategy <> 'MANUAL_OVERRIDE' OR manual_valid_until IS NOT NULL),
  CONSTRAINT ck_golden_attribute_authority CHECK (NOT national_authority OR strategy = 'NATIONAL_AUTHORITY')
);
CREATE INDEX ix_golden_attribute_hash ON ph06_mdm.golden_attribute (tenant_id, attribute_name, value_hash) WHERE value_hash IS NOT NULL;
CREATE INDEX ix_golden_attribute_source ON ph06_mdm.golden_attribute (tenant_id, source_code, source_key);
CREATE TRIGGER tg_golden_attribute_touch BEFORE UPDATE ON ph06_mdm.golden_attribute FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CALL ph06_mdm.p_enable_rls('ph06_mdm.golden_attribute');
COMMENT ON TABLE ph06_mdm.golden_attribute IS 'EN-06-02 Giá trị thuộc tính vàng kèm nguồn ở cấp thuộc tính (FR-06-034, 035, BR-06-009). SENSITIVE chỉ ở value_enc kèm value_hash, không ở value_json (CHECK, NFR-06-016). Thuộc tính đa trị dùng seq. Sửa tay tạm thời có hạn manual_valid_until (BR-06-014).';
COMMENT ON COLUMN ph06_mdm.golden_attribute.value_hash IS 'HMAC-SHA256 giá trị đã chuẩn hóa; đối sánh bằng, không giải mã (BR-06-016).';
COMMENT ON COLUMN ph06_mdm.golden_attribute.manual_valid_until IS 'Sửa tay có hạn ≤ 90 ngày, mặc định 30 (FR-06-036).';
COMMENT ON COLUMN ph06_mdm.golden_attribute.national_authority IS 'Thuộc tính thẩm quyền quốc gia: không sửa tay (BR-06-025).';
--rollback DROP TABLE IF EXISTS ph06_mdm.golden_attribute CASCADE;

--changeset ph06:ph06-0320-golden-identifier
CREATE TABLE ph06_mdm.golden_identifier (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  golden_id       uuid NOT NULL,
  domain_code     varchar(32) NOT NULL,
  identifier_type varchar(16) NOT NULL,
  value_hash      bytea NOT NULL,
  value_enc       bytea NOT NULL,
  value_kid       varchar(64) NOT NULL,
  active          boolean NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_golden_identifier PRIMARY KEY (id),
  CONSTRAINT ck_golden_identifier_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_golden_identifier_golden FOREIGN KEY (tenant_id, golden_id) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT ck_golden_identifier_type CHECK (identifier_type IN ('CCCD_12', 'CMND_9', 'MST_10_13', 'MSDN', 'MA_BHXH_10', 'MA_DVQHNS', 'DVHC_CODE', 'PASSPORT')),
  CONSTRAINT ck_golden_identifier_hash CHECK (octet_length(value_hash) = 32)
);
CREATE UNIQUE INDEX uq_golden_identifier_active ON ph06_mdm.golden_identifier (tenant_id, domain_code, identifier_type, value_hash) WHERE active;
CREATE INDEX ix_golden_identifier_golden ON ph06_mdm.golden_identifier (tenant_id, golden_id);
CREATE TRIGGER tg_golden_identifier_touch BEFORE UPDATE ON ph06_mdm.golden_identifier FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_golden_identifier_immutable BEFORE UPDATE ON ph06_mdm.golden_identifier FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('golden_id', 'domain_code', 'identifier_type', 'value_hash');
CALL ph06_mdm.p_enable_rls('ph06_mdm.golden_identifier');
COMMENT ON TABLE ph06_mdm.golden_identifier IS 'EN-06-02, EN-06-28 Chỉ mục số định danh của bản ghi vàng (FR-06-020, 046, BR-06-001, 006). Một giá trị định danh hiệu lực chỉ thuộc một bản ghi vàng trong domain (chỉ mục duy nhất một phần), nên hai bản ghi vàng cùng CCCD không tồn tại (ERR-06-112 là lỗi bất biến). Giá trị rõ không lưu; value_enc mã hóa envelope, value_hash HMAC.';
--rollback DROP TABLE IF EXISTS ph06_mdm.golden_identifier CASCADE;

--changeset ph06:ph06-0330-source-xref
CREATE TABLE ph06_mdm.source_xref (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  domain_code          varchar(32) NOT NULL,
  golden_id            uuid NOT NULL,
  source_code          varchar(32) NOT NULL,
  source_key           varchar(120) NOT NULL,
  status               varchar(8) NOT NULL DEFAULT 'ACTIVE',
  match_method         varchar(24) NOT NULL,
  score                numeric(5,4),
  candidate_id         uuid,
  confirmed_by_steward boolean NOT NULL DEFAULT false,
  linked_by            varchar(64) NOT NULL,
  linked_at            timestamptz NOT NULL DEFAULT now(),
  detached_at          timestamptz,
  detached_by          varchar(64),
  detach_reason        varchar(16),
  detach_note          varchar(2000),
  moved_to_golden_id   uuid,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_source_xref PRIMARY KEY (id),
  CONSTRAINT uq_source_xref_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_source_xref_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_source_xref_golden FOREIGN KEY (tenant_id, golden_id) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT fk_source_xref_source FOREIGN KEY (tenant_id, source_code) REFERENCES ph06_mdm.mdm_source (tenant_id, source_code),
  CONSTRAINT ck_source_xref_status CHECK (status IN ('ACTIVE', 'DETACHED', 'MOVED')),
  CONSTRAINT ck_source_xref_method CHECK (match_method IN ('DETERMINISTIC', 'PROBABILISTIC_ONLINE', 'PROBABILISTIC_BATCH', 'MANUAL', 'NATIONAL_SYNC')),
  CONSTRAINT ck_source_xref_detach CHECK (detach_reason IS NULL OR detach_reason IN ('MANUAL', 'SOURCE_DELETED', 'SPLIT')),
  CONSTRAINT ck_source_xref_detached CHECK ((status = 'ACTIVE') = (detached_at IS NULL AND detach_reason IS NULL AND moved_to_golden_id IS NULL) OR (status = 'MOVED' AND detached_at IS NOT NULL)),
  CONSTRAINT ck_source_xref_moved CHECK ((status = 'MOVED') = (moved_to_golden_id IS NOT NULL)),
  CONSTRAINT ck_source_xref_manual CHECK (detach_reason IS DISTINCT FROM 'MANUAL' OR COALESCE(char_length(detach_note) >= 20, false))
);
CREATE UNIQUE INDEX uq_source_xref_active ON ph06_mdm.source_xref (tenant_id, domain_code, source_code, source_key) WHERE status = 'ACTIVE';
CREATE INDEX ix_source_xref_golden ON ph06_mdm.source_xref (tenant_id, golden_id, status);
CREATE TRIGGER tg_source_xref_touch BEFORE UPDATE ON ph06_mdm.source_xref FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_source_xref_immutable BEFORE UPDATE ON ph06_mdm.source_xref FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'source_code', 'source_key');
CALL ph06_mdm.p_enable_rls('ph06_mdm.source_xref');
COMMENT ON TABLE ph06_mdm.source_xref IS 'EN-06-03 Liên kết chéo nguồn (sourceCode, sourceKey) với bản ghi vàng (FR-06-044, 045, BR-06-018). Một bản ghi nguồn chỉ có một liên kết ACTIVE tại một thời điểm (chỉ mục duy nhất một phần). Gỡ ghi lý do; liên kết do người xác nhận không bị tự tách (BR-06-023).';
--rollback DROP TABLE IF EXISTS ph06_mdm.source_xref CASCADE;

--changeset ph06:ph06-0340-golden-operation
CREATE TABLE ph06_mdm.golden_operation (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  domain_code       varchar(32) NOT NULL,
  change_type       varchar(24) NOT NULL,
  status            varchar(20) NOT NULL DEFAULT 'APPLIED',
  risk_level        varchar(4) NOT NULL DEFAULT 'LOW',
  golden_ids        uuid[] NOT NULL,
  survivor_id       uuid,
  result_golden_ids uuid[] NOT NULL DEFAULT '{}',
  reason            varchar(2000) NOT NULL,
  evidence_ref      varchar(255),
  payload           jsonb NOT NULL DEFAULT '{}',
  requested_by      varchar(64) NOT NULL,
  requested_at      timestamptz NOT NULL DEFAULT now(),
  decision          varchar(8),
  approved_by       varchar(64),
  approved_at       timestamptz,
  decision_comment  varchar(2000),
  applied_at        timestamptz,
  undo_of           uuid,
  batch_job_id      uuid,
  source_item_id    uuid,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_golden_operation PRIMARY KEY (id),
  CONSTRAINT uq_golden_operation_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_golden_operation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_golden_operation_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT fk_golden_operation_undo FOREIGN KEY (tenant_id, undo_of) REFERENCES ph06_mdm.golden_operation (tenant_id, id),
  CONSTRAINT ck_golden_operation_type CHECK (change_type IN ('CREATE', 'UPDATE', 'MANUAL_EDIT', 'MERGE', 'SPLIT', 'UNDO', 'RETIRE', 'RESTORE', 'NATIONAL_SYNC', 'SURVIVORSHIP_REAPPLY', 'DSR_CORRECTION', 'XREF_DETACH')),
  CONSTRAINT ck_golden_operation_status CHECK (status IN ('PENDING_APPROVAL', 'APPLIED', 'REJECTED', 'UNDONE')),
  CONSTRAINT ck_golden_operation_risk CHECK (risk_level IN ('LOW', 'HIGH')),
  CONSTRAINT ck_golden_operation_decision CHECK (decision IS NULL OR decision IN ('APPROVE', 'REJECT')),
  CONSTRAINT ck_golden_operation_reason20 CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_golden_operation_four_eyes CHECK (approved_by IS NULL OR requested_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_golden_operation_pending CHECK (status <> 'PENDING_APPROVAL' OR risk_level = 'HIGH'),
  CONSTRAINT ck_golden_operation_applied CHECK (status NOT IN ('APPLIED', 'UNDONE') OR applied_at IS NOT NULL),
  CONSTRAINT ck_golden_operation_undo CHECK ((change_type = 'UNDO') = (undo_of IS NOT NULL)),
  CONSTRAINT ck_golden_operation_merge CHECK (change_type <> 'MERGE' OR (cardinality(golden_ids) BETWEEN 2 AND 10 AND survivor_id IS NOT NULL))
);
CREATE INDEX ix_golden_operation_golden ON ph06_mdm.golden_operation USING gin (golden_ids);
CREATE INDEX ix_golden_operation_pending ON ph06_mdm.golden_operation (tenant_id, domain_code, requested_at) WHERE status = 'PENDING_APPROVAL';
CREATE UNIQUE INDEX uq_golden_operation_undo ON ph06_mdm.golden_operation (tenant_id, undo_of) WHERE undo_of IS NOT NULL AND status <> 'REJECTED';
CREATE TRIGGER tg_golden_operation_touch BEFORE UPDATE ON ph06_mdm.golden_operation FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_golden_operation_immutable BEFORE UPDATE ON ph06_mdm.golden_operation FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'change_type', 'golden_ids', 'reason', 'requested_by', 'requested_at', 'undo_of');
CALL ph06_mdm.p_enable_rls('ph06_mdm.golden_operation');
COMMENT ON TABLE ph06_mdm.golden_operation IS 'EN-06-13 Thao tác trên bản ghi vàng: hợp nhất, tách, sửa tay, hoàn tác, ngừng, khôi phục, áp lại sống sót (FR-06-036…042). Mọi thay đổi bản ghi vàng đi qua một thao tác (BR-06-005). Lý do ≥ 20 ký tự (BR-06-008); rủi ro cao chờ DA duyệt khác người yêu cầu (BR-06-019). Hoàn tác là thao tác mới trỏ undo_of, không xóa lịch sử (BR-06-024).';
COMMENT ON COLUMN ph06_mdm.golden_operation.batch_job_id IS 'batchOperationId của job lô (NFR, tiêu chí 9).';
--rollback DROP TABLE IF EXISTS ph06_mdm.golden_operation CASCADE;

--changeset ph06:ph06-0350-golden-history
CREATE TABLE ph06_mdm.golden_history (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  changed_at         timestamptz NOT NULL DEFAULT now(),
  golden_id          uuid NOT NULL,
  version_no         integer NOT NULL,
  change_type        varchar(24) NOT NULL,
  operation_id       uuid,
  snapshot_enc       bytea NOT NULL,
  snapshot_kid       varchar(64) NOT NULL,
  snapshot_sha256    bytea NOT NULL,
  changed_attributes varchar(63)[] NOT NULL DEFAULT '{}',
  changed_by         varchar(64) NOT NULL,
  CONSTRAINT pk_golden_history PRIMARY KEY (id, changed_at),
  CONSTRAINT ck_golden_history_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_golden_history_golden FOREIGN KEY (tenant_id, golden_id) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT ck_golden_history_type CHECK (change_type IN ('CREATE', 'UPDATE', 'MANUAL_EDIT', 'MERGE', 'SPLIT', 'UNDO', 'RETIRE', 'RESTORE', 'NATIONAL_SYNC', 'SURVIVORSHIP_REAPPLY', 'DSR_CORRECTION', 'XREF_DETACH')),
  CONSTRAINT ck_golden_history_sha CHECK (octet_length(snapshot_sha256) = 32),
  CONSTRAINT ck_golden_history_version CHECK (version_no >= 1),
  CONSTRAINT ck_golden_history_snapshot CHECK (octet_length(snapshot_enc) BETWEEN 29 AND 4194304)
) PARTITION BY RANGE (changed_at);
CALL ph06_mdm.p_ensure_partitions('ph06_mdm.golden_history', current_date, 3);
CREATE INDEX ix_golden_history_golden ON ph06_mdm.golden_history (tenant_id, golden_id, version_no DESC);
CREATE INDEX ix_golden_history_operation ON ph06_mdm.golden_history (tenant_id, operation_id) WHERE operation_id IS NOT NULL;
CREATE TRIGGER tg_golden_history_append_only BEFORE UPDATE OR DELETE ON ph06_mdm.golden_history FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_append_only();
CALL ph06_mdm.p_enable_rls('ph06_mdm.golden_history');
COMMENT ON TABLE ph06_mdm.golden_history IS 'EN-06-06 Ảnh chụp đầy đủ bản ghi vàng (thuộc tính, liên kết) trước mỗi thay đổi, cùng giao dịch (BR-06-005). Phục vụ xem phiên bản, so sánh, hoàn tác. snapshot_enc mã hóa envelope vì chứa DLCN. Chỉ thêm, không sửa (trigger). Phân vùng tháng theo changed_at; chuyển lưu trữ lạnh sau 5 năm, không xóa (BR-06-007, SRS cũ: vĩnh viễn).';
--rollback DROP TABLE IF EXISTS ph06_mdm.golden_history CASCADE;

--changeset ph06:ph06-0360-attribute-lineage
CREATE TABLE ph06_mdm.attribute_lineage (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  recorded_at       timestamptz NOT NULL DEFAULT now(),
  golden_id         uuid NOT NULL,
  golden_version    integer NOT NULL,
  attribute_name    varchar(63) NOT NULL,
  seq               smallint NOT NULL DEFAULT 0,
  operation_id      uuid,
  source_code       varchar(32) NOT NULL,
  source_key        varchar(120),
  source_version    bigint,
  source_updated_at timestamptz,
  strategy          varchar(24) NOT NULL,
  selected          boolean NOT NULL DEFAULT true,
  data_class        varchar(16) NOT NULL,
  value_enc         bytea,
  value_kid         varchar(64),
  value_hash        bytea,
  CONSTRAINT pk_attribute_lineage PRIMARY KEY (id, recorded_at),
  CONSTRAINT ck_attribute_lineage_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_attribute_lineage_golden FOREIGN KEY (tenant_id, golden_id) REFERENCES ph06_mdm.golden_record (tenant_id, id),
  CONSTRAINT ck_attribute_lineage_strategy CHECK (strategy IN ('NATIONAL_AUTHORITY', 'MANUAL_OVERRIDE', 'SOURCE_PRIORITY', 'MOST_RECENT', 'MOST_COMPLETE', 'MOST_FREQUENT', 'FIRST_VALUE')),
  CONSTRAINT ck_attribute_lineage_class CHECK (data_class IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_attribute_lineage_hash CHECK (value_hash IS NULL OR octet_length(value_hash) = 32),
  CONSTRAINT ck_attribute_lineage_enc CHECK (value_enc IS NULL OR value_kid IS NOT NULL)
) PARTITION BY RANGE (recorded_at);
CALL ph06_mdm.p_ensure_partitions('ph06_mdm.attribute_lineage', current_date, 3);
CREATE INDEX ix_attribute_lineage_golden ON ph06_mdm.attribute_lineage (tenant_id, golden_id, attribute_name, recorded_at DESC);
CREATE TRIGGER tg_attribute_lineage_append_only BEFORE UPDATE OR DELETE ON ph06_mdm.attribute_lineage FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_append_only();
CALL ph06_mdm.p_enable_rls('ph06_mdm.attribute_lineage');
COMMENT ON TABLE ph06_mdm.attribute_lineage IS 'EN-06-14 Lịch sử giá trị và nguồn của từng thuộc tính vàng (FR-06-043, BR-06-009): giá trị nào, từ nguồn nào, chiến lược nào chọn, lúc nào. Giá trị mã hóa envelope; value_hash để so khớp. Chỉ thêm. Phân vùng tháng theo recorded_at; chuyển lưu trữ lạnh sau 5 năm, không xóa.';
--rollback DROP TABLE IF EXISTS ph06_mdm.attribute_lineage CASCADE;

--changeset ph06:ph06-0370-survivorship-rule-set
CREATE TABLE ph06_mdm.survivorship_rule_set (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  domain_code      varchar(32) NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  comment          varchar(2000),
  approval_ref     varchar(255),
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decision         varchar(8),
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_survivorship_rule_set PRIMARY KEY (id),
  CONSTRAINT uq_survivorship_rule_set_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_survivorship_rule_set_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_survivorship_rule_set_version UNIQUE (tenant_id, domain_code, version_no),
  CONSTRAINT fk_survivorship_rule_set_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_survivorship_rule_set_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED')),
  CONSTRAINT ck_survivorship_rule_set_decision CHECK (decision IS NULL OR decision IN ('APPROVE', 'REJECT')),
  CONSTRAINT ck_survivorship_rule_set_four_eyes CHECK (decided_by IS NULL OR submitted_by IS NULL OR decided_by <> submitted_by),
  CONSTRAINT ck_survivorship_rule_set_active CHECK (status <> 'ACTIVE' OR (decision = 'APPROVE' AND activated_at IS NOT NULL AND approval_ref IS NOT NULL))
);
CREATE UNIQUE INDEX uq_survivorship_rule_set_active ON ph06_mdm.survivorship_rule_set (tenant_id, domain_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_survivorship_rule_set_touch BEFORE UPDATE ON ph06_mdm.survivorship_rule_set FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_survivorship_rule_set_immutable BEFORE UPDATE ON ph06_mdm.survivorship_rule_set FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'version_no');
CALL ph06_mdm.p_enable_rls('ph06_mdm.survivorship_rule_set');
COMMENT ON TABLE ph06_mdm.survivorship_rule_set IS 'EN-06-17 Phiên bản bộ quy tắc sống sót của domain (FR-06-033, 042). Vòng đời 4.6 (không TESTING); một phiên bản ACTIVE mỗi domain; duyệt bốn mắt có căn cứ văn bản (BR-06-004).';
--rollback DROP TABLE IF EXISTS ph06_mdm.survivorship_rule_set CASCADE;

--changeset ph06:ph06-0380-survivorship-rule
CREATE TABLE ph06_mdm.survivorship_rule (
  id                         uuid NOT NULL,
  tenant_id                  varchar(16) NOT NULL,
  domain_code                varchar(32) NOT NULL,
  version_no                 integer NOT NULL,
  attribute_name             varchar(63) NOT NULL,
  strategies                 varchar(24)[] NOT NULL,
  critical_conflict_to_queue boolean NOT NULL DEFAULT false,
  national_authority         boolean NOT NULL DEFAULT false,
  created_at                 timestamptz NOT NULL DEFAULT now(),
  created_by                 varchar(64) NOT NULL,
  updated_at                 timestamptz NOT NULL DEFAULT now(),
  updated_by                 varchar(64) NOT NULL,
  version                    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_survivorship_rule PRIMARY KEY (id),
  CONSTRAINT ck_survivorship_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_survivorship_rule_attr UNIQUE (tenant_id, domain_code, version_no, attribute_name),
  CONSTRAINT fk_survivorship_rule_set FOREIGN KEY (tenant_id, domain_code, version_no) REFERENCES ph06_mdm.survivorship_rule_set (tenant_id, domain_code, version_no),
  CONSTRAINT ck_survivorship_rule_strategies CHECK (cardinality(strategies) BETWEEN 1 AND 7 AND strategies <@ ARRAY['NATIONAL_AUTHORITY', 'MANUAL_OVERRIDE', 'SOURCE_PRIORITY', 'MOST_RECENT', 'MOST_COMPLETE', 'MOST_FREQUENT', 'FIRST_VALUE']::varchar[]),
  CONSTRAINT ck_survivorship_rule_authority CHECK (NOT national_authority OR strategies[1] = 'NATIONAL_AUTHORITY')
);
CREATE TRIGGER tg_survivorship_rule_touch BEFORE UPDATE ON ph06_mdm.survivorship_rule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_survivorship_rule_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph06_mdm.survivorship_rule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_child_frozen('survivorship_rule_set');
CALL ph06_mdm.p_enable_rls('ph06_mdm.survivorship_rule');
COMMENT ON TABLE ph06_mdm.survivorship_rule IS 'EN-06-17 Chiến lược sống sót theo thuộc tính trong một phiên bản (FR-06-033). strategies là chuỗi SurvivorshipStrategy theo thứ tự áp; thuộc tính thẩm quyền quốc gia bắt đầu bằng NATIONAL_AUTHORITY (BR-06-003, 025).';
--rollback DROP TABLE IF EXISTS ph06_mdm.survivorship_rule CASCADE;
