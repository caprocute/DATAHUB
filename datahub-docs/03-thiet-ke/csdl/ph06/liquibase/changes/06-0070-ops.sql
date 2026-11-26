--liquibase formatted sql
-- Nguồn: ddl/ph06_mdm.sql · 06-0070-ops.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph06:ph06-0450-subject-request
CREATE TABLE ph06_mdm.subject_request (
  id                    uuid NOT NULL,
  tenant_id             varchar(16) NOT NULL,
  request_type          varchar(16) NOT NULL,
  status                varchar(24) NOT NULL DEFAULT 'RECEIVED',
  identifier_type       varchar(16) NOT NULL,
  subject_enc           bytea NOT NULL,
  subject_kid           varchar(64) NOT NULL,
  subject_hash          bytea NOT NULL,
  verification_ref      varchar(255) NOT NULL,
  details_enc           bytea,
  channel               varchar(32) NOT NULL,
  received_at           timestamptz NOT NULL,
  due_at                timestamptz NOT NULL,
  golden_id             uuid,
  forwarded_source_code varchar(32),
  handled_by            varchar(64),
  completed_at          timestamptz,
  result_ref            varchar(512),
  reject_reason         varchar(2000),
  lifted_at             timestamptz,
  lifted_by             varchar(64),
  lift_reason           varchar(2000),
  created_at            timestamptz NOT NULL DEFAULT now(),
  created_by            varchar(64) NOT NULL,
  updated_at            timestamptz NOT NULL DEFAULT now(),
  updated_by            varchar(64) NOT NULL,
  version               integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_subject_request PRIMARY KEY (id),
  CONSTRAINT ck_subject_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_subject_request_type CHECK (request_type IN ('ACCESS', 'RECTIFICATION', 'RESTRICTION')),
  CONSTRAINT ck_subject_request_status CHECK (status IN ('RECEIVED', 'IN_PROGRESS', 'FORWARDED_TO_SOURCE', 'COMPLETED', 'REJECTED')),
  CONSTRAINT ck_subject_request_idtype CHECK (identifier_type IN ('CCCD_12', 'CMND_9', 'MST_10_13', 'MSDN', 'MA_BHXH_10', 'MA_DVQHNS', 'DVHC_CODE', 'PASSPORT')),
  CONSTRAINT ck_subject_request_hash CHECK (octet_length(subject_hash) = 32),
  CONSTRAINT ck_subject_request_due CHECK (due_at >= received_at),
  CONSTRAINT ck_subject_request_completed CHECK (status NOT IN ('COMPLETED', 'REJECTED') OR completed_at IS NOT NULL),
  CONSTRAINT ck_subject_request_rejected CHECK (status <> 'REJECTED' OR reject_reason IS NOT NULL),
  CONSTRAINT ck_subject_request_lifted CHECK ((lifted_at IS NULL) = (lifted_by IS NULL) AND (lifted_at IS NULL) = (lift_reason IS NULL) AND (lifted_at IS NULL OR (request_type = 'RESTRICTION' AND status = 'COMPLETED' AND char_length(lift_reason) >= 20))),
  CONSTRAINT ck_subject_request_forward CHECK (status <> 'FORWARDED_TO_SOURCE' OR forwarded_source_code IS NOT NULL)
);
CREATE INDEX ix_subject_request_status ON ph06_mdm.subject_request (tenant_id, status, due_at);
CREATE INDEX ix_subject_request_subject ON ph06_mdm.subject_request (tenant_id, subject_hash);
CREATE TRIGGER tg_subject_request_touch BEFORE UPDATE ON ph06_mdm.subject_request FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_subject_request_immutable BEFORE UPDATE ON ph06_mdm.subject_request FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('request_type', 'subject_hash', 'received_at');
CALL ph06_mdm.p_enable_rls('ph06_mdm.subject_request');
COMMENT ON TABLE ph06_mdm.subject_request IS 'EN-06-20 Yêu cầu của chủ thể dữ liệu: biết, sửa, hạn chế (FR-06-058, BR-06-030; Luật BVDLCN, NĐ 356/2025). Số định danh chủ thể mã hóa envelope kèm HMAC để tra bản ghi vàng. Trả lời trong 06.dsr.sla-days (Q06-01); sửa thực hiện tại nguồn (BR-06-014). Yêu cầu hạn chế chuyển bản ghi vàng sang LOCKED.';
--rollback DROP TABLE IF EXISTS ph06_mdm.subject_request CASCADE;

--changeset ph06:ph06-0460-access-log
CREATE TABLE ph06_mdm.access_log (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  accessed_at        timestamptz NOT NULL DEFAULT now(),
  actor              varchar(64) NOT NULL,
  system_code        varchar(63),
  domain_code        varchar(32) NOT NULL,
  golden_id          uuid,
  api_code           varchar(10) NOT NULL,
  purpose_code       varchar(63),
  attributes         varchar(63)[] NOT NULL DEFAULT '{}',
  unmasked           varchar(63)[] NOT NULL DEFAULT '{}',
  unmask_reason      varchar(500),
  result_count       integer NOT NULL DEFAULT 1,
  criteria_hash      bytea,
  bulk_flag          boolean NOT NULL DEFAULT false,
  trace_id           char(32) NOT NULL,
  gateway_request_id varchar(64),
  CONSTRAINT pk_access_log PRIMARY KEY (id, accessed_at),
  CONSTRAINT ck_access_log_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_access_log_api CHECK (api_code ~ '^API-06-[0-9]{3}$'),
  CONSTRAINT ck_access_log_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_access_log_criteria CHECK (criteria_hash IS NULL OR octet_length(criteria_hash) = 32),
  CONSTRAINT ck_access_log_unmask CHECK (cardinality(unmasked) = 0 OR COALESCE(char_length(unmask_reason) >= 20, false)),
  CONSTRAINT ck_access_log_count CHECK (result_count >= 0)
) PARTITION BY RANGE (accessed_at);
CALL ph06_mdm.p_ensure_partitions('ph06_mdm.access_log', current_date, 3);
CREATE INDEX ix_access_log_golden ON ph06_mdm.access_log (tenant_id, golden_id, accessed_at DESC) WHERE golden_id IS NOT NULL;
CREATE INDEX ix_access_log_actor ON ph06_mdm.access_log (tenant_id, actor, accessed_at DESC);
CREATE INDEX ix_access_log_system ON ph06_mdm.access_log (tenant_id, system_code, purpose_code, accessed_at DESC) WHERE system_code IS NOT NULL;
CREATE TRIGGER tg_access_log_append_only BEFORE UPDATE OR DELETE ON ph06_mdm.access_log FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_append_only();
CALL ph06_mdm.p_enable_rls('ph06_mdm.access_log');
COMMENT ON TABLE ph06_mdm.access_log IS 'EN-06-21 Nhật ký truy cập dữ liệu chủ: ai, tra bản ghi nào, mục đích gì, trả thuộc tính nào (FR-06-057, BR-06-010, NFR-06-015). Không ghi được thì không trả dữ liệu (ERR-06-039). Chỉ thêm, trigger chặn sửa, xóa (RB-06-04); không chứa giá trị thuộc tính. Phân vùng tháng; 12 tháng trực tuyến, 5 năm WORM (BR-06-031).';
COMMENT ON COLUMN ph06_mdm.access_log.gateway_request_id IS 'Mã yêu cầu của APISIX để đối chiếu số lượt (NFR-06-015).';
COMMENT ON COLUMN ph06_mdm.access_log.criteria_hash IS 'HMAC tiêu chí tìm kiếm; không lưu tiêu chí rõ.';
--rollback DROP TABLE IF EXISTS ph06_mdm.access_log CASCADE;

--changeset ph06:ph06-0470-processing-log
CREATE TABLE ph06_mdm.processing_log (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  logged_at    timestamptz NOT NULL DEFAULT now(),
  level        varchar(5) NOT NULL,
  component    varchar(32) NOT NULL,
  job_id       uuid,
  candidate_id uuid,
  domain_code  varchar(32),
  code         varchar(16),
  message      varchar(1000) NOT NULL,
  details      jsonb,
  trace_id     char(32),
  CONSTRAINT pk_processing_log PRIMARY KEY (id, logged_at),
  CONSTRAINT ck_processing_log_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_processing_log_level CHECK (level IN ('INFO', 'WARN', 'ERROR')),
  CONSTRAINT ck_processing_log_code CHECK (code IS NULL OR code ~ '^ERR-06-[01][0-9]{2}$'),
  CONSTRAINT ck_processing_log_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$')
) PARTITION BY RANGE (logged_at);
CALL ph06_mdm.p_ensure_partitions('ph06_mdm.processing_log', current_date, 3);
CREATE INDEX ix_processing_log_job ON ph06_mdm.processing_log (tenant_id, job_id, logged_at) WHERE job_id IS NOT NULL;
CREATE INDEX ix_processing_log_level ON ph06_mdm.processing_log (tenant_id, level, logged_at DESC);
CREATE TRIGGER tg_processing_log_append_only BEFORE UPDATE OR DELETE ON ph06_mdm.processing_log FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_append_only();
CALL ph06_mdm.p_enable_rls('ph06_mdm.processing_log');
COMMENT ON TABLE ph06_mdm.processing_log IS 'EN-06-32 FR-06-057 Nhật ký xử lý (job, ứng viên, đồng bộ, dọn lưu giữ) cho vận hành: mức, mã lỗi ERR-06-1nn, thông điệp ngắn, chi tiết đã che DLCN. Chỉ thêm; phân vùng tháng theo logged_at; giữ 90 ngày.';
--rollback DROP TABLE IF EXISTS ph06_mdm.processing_log CASCADE;

--changeset ph06:ph06-0480-retention-policy
CREATE TABLE ph06_mdm.retention_policy (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  object_type    varchar(24) NOT NULL,
  retention_days integer NOT NULL,
  action         varchar(16) NOT NULL,
  legal_hold     boolean NOT NULL DEFAULT false,
  hold_reason    varchar(2000),
  last_purge_at  timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_retention_policy PRIMARY KEY (id),
  CONSTRAINT ck_retention_policy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_retention_policy_type UNIQUE (tenant_id, object_type),
  CONSTRAINT ck_retention_policy_type CHECK (object_type IN ('candidate_record', 'match_result', 'match_staging', 'golden_history', 'attribute_lineage', 'access_log', 'processing_log', 'export_request', 'subject_request', 'steward_item')),
  CONSTRAINT ck_retention_policy_action CHECK (action IN ('DELETE', 'ANONYMIZE', 'ARCHIVE_COLD')),
  CONSTRAINT ck_retention_policy_days CHECK (retention_days >= 7 AND (object_type <> 'access_log' OR retention_days >= 365)),
  CONSTRAINT ck_retention_policy_hold CHECK (NOT legal_hold OR hold_reason IS NOT NULL)
);
CREATE TRIGGER tg_retention_policy_touch BEFORE UPDATE ON ph06_mdm.retention_policy FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_retention_policy_immutable BEFORE UPDATE ON ph06_mdm.retention_policy FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('object_type');
CALL ph06_mdm.p_enable_rls('ph06_mdm.retention_policy');
COMMENT ON TABLE ph06_mdm.retention_policy IS 'EN-06-33 FR-06-059 Chính sách lưu giữ theo loại đối tượng (BR-06-031). Nhật ký truy cập tối thiểu 365 ngày trực tuyến (ERR-06-049); legal_hold chặn dọn (ERR-06-114). retention_days = 0 không cho phép.';
--rollback DROP TABLE IF EXISTS ph06_mdm.retention_policy CASCADE;

--changeset ph06:ph06-0490-tenant-setting
CREATE TABLE ph06_mdm.tenant_setting (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  setting_key varchar(48) NOT NULL,
  value       jsonb NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_setting PRIMARY KEY (id),
  CONSTRAINT ck_tenant_setting_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_tenant_setting_key UNIQUE (tenant_id, setting_key),
  CONSTRAINT ck_tenant_setting_key CHECK (setting_key IN ('06.queue.sla-days', '06.queue.max-open', '06.queue.escalate-after-days', '06.queue.hold-minutes', '06.match.auto-disable-on-fail', '06.batch.safety-ratio', '06.undo.window-days', '06.export.max-rows', '06.access.bulk-threshold', '06.ingest.rate-per-source', '06.sync.pause-ratio', '06.sync.up-attributes', '06.dsr.sla-days', '06.mask.reveal-seconds', '06.ingest.max-file-mb', '06.ingest.max-rows', '06.batch.max-hours', '06.match.timeout-ms', '06.sync.reconcile-batch-size', '06.xref.batch-max', '06.queue.reopen-hours', '06.queue.reason-templates'))
);
CREATE TRIGGER tg_tenant_setting_touch BEFORE UPDATE ON ph06_mdm.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_tenant_setting_immutable BEFORE UPDATE ON ph06_mdm.tenant_setting FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('setting_key');
CALL ph06_mdm.p_enable_rls('ph06_mdm.tenant_setting');
COMMENT ON TABLE ph06_mdm.tenant_setting IS 'EN-06-34 FR-06-060 Tham số phân hệ theo tenant (FRS 8.2, khóa 06.*). Giá trị jsonb; miền kiểm ở dịch vụ (ERR-06-047), CHECK chỉ giữ danh sách khóa hợp lệ. Khóa thiếu thì dùng mặc định của FRS.';
--rollback DROP TABLE IF EXISTS ph06_mdm.tenant_setting CASCADE;
