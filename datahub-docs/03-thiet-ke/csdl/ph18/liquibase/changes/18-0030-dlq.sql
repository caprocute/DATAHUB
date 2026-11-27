--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0030-dlq.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0200-dlq-source splitStatements:false
CREATE TABLE ph18_ops.dlq_source (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  source_code      varchar(32) NOT NULL,
  source_module    varchar(8) NOT NULL,
  ingest_channel   varchar(12) NOT NULL,
  replay_port      varchar(16) NOT NULL,
  replay_endpoint  varchar(255),
  callback_scope   varchar(64) NOT NULL DEFAULT 'ops:replay-callback',
  payload_viewable boolean NOT NULL DEFAULT true,
  enabled          boolean NOT NULL DEFAULT true,
  description      varchar(500),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_source PRIMARY KEY (id),
  CONSTRAINT uq_dlq_source_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dlq_source_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_dlq_source_code UNIQUE (tenant_id, source_code),
  CONSTRAINT ck_dlq_source_code CHECK (source_code ~ '^PH[0-9]{2}-[A-Z0-9-]+$'),
  CONSTRAINT ck_dlq_source_module CHECK (source_module ~ '^PH[0-9]{2}$' AND left(source_code, 4) = source_module),
  CONSTRAINT ck_dlq_source_channel CHECK (ingest_channel IN ('KAFKA', 'API', 'FEDERATED')),
  CONSTRAINT ck_dlq_source_port CHECK (replay_port IN ('PH04_RUNTIME', 'PH10_EVENT', 'REPLAY_PORT', 'NONE')),
  CONSTRAINT ck_dlq_source_endpoint CHECK (replay_endpoint IS NULL OR replay_endpoint ~ '^/[a-z0-9/_{}.:-]+$'),
  CONSTRAINT ck_dlq_source_federated CHECK (ingest_channel <> 'FEDERATED' OR (source_module = 'PH10' AND NOT payload_viewable))
);
CREATE TRIGGER tg_dlq_source_touch BEFORE UPDATE ON ph18_ops.dlq_source FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dlq_source_immutable BEFORE UPDATE ON ph18_ops.dlq_source FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('source_code', 'source_module');
CALL ph18_ops.p_enable_rls('ph18_ops.dlq_source', true);
COMMENT ON TABLE ph18_ops.dlq_source IS 'EN-18-18 Đăng ký nguồn DLQ: PH nguồn, kênh vào (KAFKA topic {tenant}.ops.dlq.v1, API ops:dlq-write, FEDERATED liên thông DLQ tầng sự kiện PH-10 qua API-10-060, 061 không sao chép nội dung), cổng phát lại (PH04_RUNTIME, PH10_EVENT, REPLAY_PORT, NONE). Dòng COMMON là đăng ký nền tảng, tenant có thể tắt nguồn bằng dòng riêng.';
COMMENT ON COLUMN ph18_ops.dlq_source.replay_endpoint IS 'Đường dẫn nội bộ (mTLS) của cổng phát lại ở PH nguồn; phát lại luôn qua lối vào của nguồn.';
--rollback DROP TABLE IF EXISTS ph18_ops.dlq_source CASCADE;

--changeset ph18:ph18-0210-error-guide splitStatements:false
CREATE TABLE ph18_ops.error_guide (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  error_code         varchar(16) NOT NULL,
  locale             varchar(8) NOT NULL DEFAULT 'vi',
  title              varchar(255) NOT NULL,
  symptom            text NOT NULL,
  cause              text NOT NULL,
  resolution         text NOT NULL,
  recommended_action varchar(16) NOT NULL,
  runbook_path       varchar(500),
  status             varchar(12) NOT NULL DEFAULT 'DRAFT',
  published_at       timestamptz,
  published_by       varchar(64),
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_error_guide PRIMARY KEY (id),
  CONSTRAINT uq_error_guide_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_error_guide_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_error_guide_code UNIQUE (tenant_id, error_code, locale),
  CONSTRAINT ck_error_guide_code CHECK (error_code ~ '^ERR-[0-9]{2}-[0-9]{3}$'),
  CONSTRAINT ck_error_guide_action CHECK (recommended_action IN ('REPLAY', 'FIX_AND_REPLAY', 'DISCARD', 'ESCALATE', 'WAIT_SOURCE')),
  CONSTRAINT ck_error_guide_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
  CONSTRAINT ck_error_guide_published CHECK (status = 'DRAFT' OR (published_at IS NOT NULL AND published_by IS NOT NULL)),
  CONSTRAINT ck_error_guide_runbook CHECK (runbook_path IS NULL OR runbook_path ~ '^/[a-z0-9/_#.-]+$')
);
CREATE TRIGGER tg_error_guide_touch BEFORE UPDATE ON ph18_ops.error_guide FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_error_guide_immutable BEFORE UPDATE ON ph18_ops.error_guide FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('error_code', 'locale');
CREATE TRIGGER tg_error_guide_fsm_status BEFORE UPDATE ON ph18_ops.error_guide FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'DRAFT>PUBLISHED,PUBLISHED>DRAFT,PUBLISHED>RETIRED');
CALL ph18_ops.p_enable_rls('ph18_ops.error_guide', true);
COMMENT ON TABLE ph18_ops.error_guide IS 'EN-18-15 Sổ tay xử lý theo mã lỗi ERR (nguồn tri thức loại ERROR_CODE, GUIDE cho PH-17): triệu chứng, nguyên nhân, cách xử lý, hành động khuyến nghị. Dòng COMMON là sổ tay nền tảng, tenant bổ sung ghi chú riêng. Bản PUBLISHED phát sự kiện đổi hướng dẫn để PH-17 lập chỉ mục lại.';
--rollback DROP TABLE IF EXISTS ph18_ops.error_guide CASCADE;

--changeset ph18:ph18-0220-dlq-group splitStatements:false
CREATE TABLE ph18_ops.dlq_group (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  signature      char(64) NOT NULL,
  source_code    varchar(32) NOT NULL,
  flow_code      varchar(128),
  error_code     varchar(16),
  error_class    varchar(12) NOT NULL,
  sample_message varchar(500) NOT NULL,
  first_seen_at  timestamptz NOT NULL DEFAULT now(),
  last_seen_at   timestamptz NOT NULL DEFAULT now(),
  open_count     integer NOT NULL DEFAULT 0,
  total_count    integer NOT NULL DEFAULT 0,
  guide_id       uuid,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_group PRIMARY KEY (id),
  CONSTRAINT uq_dlq_group_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dlq_group_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dlq_group_signature UNIQUE (tenant_id, signature),
  CONSTRAINT fk_dlq_group_guide FOREIGN KEY (guide_id) REFERENCES ph18_ops.error_guide (id),
  CONSTRAINT ck_dlq_group_signature CHECK (signature ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_dlq_group_class CHECK (error_class IN ('TRANSIENT', 'BUSINESS', 'CONTRACT', 'POISON', 'UNKNOWN')),
  CONSTRAINT ck_dlq_group_counts CHECK (open_count >= 0 AND total_count >= open_count),
  CONSTRAINT ck_dlq_group_seen CHECK (last_seen_at >= first_seen_at)
);
CREATE INDEX ix_dlq_group_open ON ph18_ops.dlq_group (tenant_id, open_count DESC) WHERE open_count > 0;
CREATE TRIGGER tg_dlq_group_touch BEFORE UPDATE ON ph18_ops.dlq_group FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dlq_group_immutable BEFORE UPDATE ON ph18_ops.dlq_group FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('signature', 'source_code');
CALL ph18_ops.p_enable_rls('ph18_ops.dlq_group', false);
COMMENT ON TABLE ph18_ops.dlq_group IS 'EN-18-13 Nhóm dấu hiệu lỗi: băm SHA-256 của (nguồn, luồng, mã lỗi, thông điệp đã chuẩn hóa) để gom mục DLQ giống nhau, đếm mục mở, tổng, lần đầu, lần cuối; gắn hướng dẫn xử lý.';
--rollback DROP TABLE IF EXISTS ph18_ops.dlq_group CASCADE;

--changeset ph18:ph18-0230-dlq-message splitStatements:false
CREATE TABLE ph18_ops.dlq_message (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  dlq_key              varchar(255) NOT NULL,
  source_code          varchar(32) NOT NULL,
  source_module        varchar(8) NOT NULL,
  flow_code            varchar(128),
  flow_version         varchar(32),
  stage                varchar(64),
  reason_code          varchar(64) NOT NULL,
  error_code           varchar(16),
  error_class          varchar(12) NOT NULL DEFAULT 'UNKNOWN',
  error_message        varchar(2000),
  attempts             integer NOT NULL DEFAULT 0,
  trace_id             char(32),
  origin_topic         varchar(249),
  origin_partition     integer,
  origin_offset        bigint,
  dlq_partition        integer,
  dlq_offset           bigint,
  external_ref         varchar(128),
  first_failed_at      timestamptz,
  received_at          timestamptz NOT NULL DEFAULT now(),
  status               varchar(16) NOT NULL DEFAULT 'NEW',
  priority             varchar(2) NOT NULL DEFAULT 'P3',
  group_id             uuid,
  assignee             varchar(64),
  missing_context      varchar(32)[] NOT NULL DEFAULT '{}',
  context_headers      jsonb NOT NULL DEFAULT '{}',
  schema_ref           varchar(255),
  payload_location     varchar(10) NOT NULL,
  payload_inline       jsonb,
  payload_content_type varchar(127),
  payload_size_bytes   integer,
  payload_sha256       char(64),
  current_revision_no  integer NOT NULL DEFAULT 0,
  discard_reason       varchar(2000),
  resolved_at          timestamptz,
  closed_at            timestamptz,
  retention_until      timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_message PRIMARY KEY (id, received_at),
  CONSTRAINT uq_dlq_message_tid UNIQUE (tenant_id, id, received_at),
  CONSTRAINT ck_dlq_message_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dlq_message_group FOREIGN KEY (tenant_id, group_id) REFERENCES ph18_ops.dlq_group (tenant_id, id),
  CONSTRAINT ck_dlq_message_status CHECK (status IN ('NEW', 'TRIAGED', 'REPLAY_PENDING', 'REPLAYING', 'RESOLVED', 'REPLAY_FAILED', 'DISCARDED', 'POISON', 'EXPIRED')),
  CONSTRAINT ck_dlq_message_class CHECK (error_class IN ('TRANSIENT', 'BUSINESS', 'CONTRACT', 'POISON', 'UNKNOWN')),
  CONSTRAINT ck_dlq_message_priority CHECK (priority IN ('P1', 'P2', 'P3', 'P4')),
  CONSTRAINT ck_dlq_message_module CHECK (source_module ~ '^PH[0-9]{2}$'),
  CONSTRAINT ck_dlq_message_attempts CHECK (attempts >= 0),
  CONSTRAINT ck_dlq_message_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_dlq_message_location CHECK (payload_location IN ('INLINE', 'GARAGE', 'FEDERATED', 'PURGED')),
  CONSTRAINT ck_dlq_message_inline CHECK ((payload_location = 'INLINE') = (payload_inline IS NOT NULL)),
  CONSTRAINT ck_dlq_message_inline_size CHECK (payload_inline IS NULL OR (payload_size_bytes IS NOT NULL AND payload_size_bytes <= 262144)),
  CONSTRAINT ck_dlq_message_sha CHECK (payload_sha256 IS NULL OR payload_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_dlq_message_federated CHECK (payload_location <> 'FEDERATED' OR (source_module = 'PH10' AND external_ref IS NOT NULL)),
  CONSTRAINT ck_dlq_message_poison CHECK (status <> 'POISON' OR cardinality(missing_context) > 0),
  CONSTRAINT ck_dlq_message_discard CHECK (status <> 'DISCARDED' OR coalesce(char_length(btrim(discard_reason)), 0) >= 10),
  CONSTRAINT ck_dlq_message_closed CHECK ((status IN ('RESOLVED', 'DISCARDED', 'EXPIRED')) = (closed_at IS NOT NULL)),
  CONSTRAINT ck_dlq_message_expired CHECK (status <> 'EXPIRED' OR payload_location IN ('PURGED', 'FEDERATED')),
  CONSTRAINT ck_dlq_message_headers CHECK (jsonb_typeof(context_headers) = 'object' AND NOT (context_headers ?| ARRAY['authorization', 'cookie', 'x-api-key']))
) PARTITION BY RANGE (received_at);
CALL ph18_ops.p_ensure_partitions('ph18_ops.dlq_message', (current_date - interval '1 month')::date, 4);
CREATE INDEX ix_dlq_message_status ON ph18_ops.dlq_message (tenant_id, status, received_at DESC);
CREATE INDEX ix_dlq_message_key ON ph18_ops.dlq_message (tenant_id, dlq_key);
CREATE INDEX ix_dlq_message_source ON ph18_ops.dlq_message (tenant_id, source_code, flow_code, error_code);
CREATE INDEX ix_dlq_message_group ON ph18_ops.dlq_message (tenant_id, group_id) WHERE group_id IS NOT NULL;
CREATE INDEX ix_dlq_message_trace ON ph18_ops.dlq_message (trace_id) WHERE trace_id IS NOT NULL;
CREATE INDEX ix_dlq_message_retention ON ph18_ops.dlq_message (retention_until) WHERE retention_until IS NOT NULL;
CREATE INDEX ix_dlq_message_assignee ON ph18_ops.dlq_message (tenant_id, assignee) WHERE assignee IS NOT NULL AND closed_at IS NULL;
CREATE TRIGGER tg_dlq_message_touch BEFORE UPDATE ON ph18_ops.dlq_message FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dlq_message_immutable BEFORE UPDATE ON ph18_ops.dlq_message FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('dlq_key', 'source_code', 'source_module', 'flow_code', 'reason_code', 'first_failed_at', 'received_at', 'origin_topic', 'origin_offset', 'payload_sha256');
CREATE TRIGGER tg_dlq_message_payload BEFORE UPDATE ON ph18_ops.dlq_message FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_dlq_payload_guard();
CREATE TRIGGER tg_dlq_message_fsm_status BEFORE UPDATE ON ph18_ops.dlq_message FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'NEW>TRIAGED,NEW>POISON,NEW>REPLAY_PENDING,NEW>DISCARDED,TRIAGED>REPLAY_PENDING,TRIAGED>DISCARDED,REPLAY_PENDING>REPLAYING,REPLAY_PENDING>TRIAGED,REPLAYING>RESOLVED,REPLAYING>REPLAY_FAILED,REPLAY_FAILED>REPLAY_PENDING,REPLAY_FAILED>DISCARDED,DISCARDED>TRIAGED,POISON>DISCARDED,POISON>TRIAGED,RESOLVED>EXPIRED,DISCARDED>EXPIRED');
CALL ph18_ops.p_enable_rls('ph18_ops.dlq_message', false);
COMMENT ON TABLE ph18_ops.dlq_message IS 'EN-18-09 Chỉ mục mục DLQ hợp nhất: hợp đồng ngữ cảnh chuẩn (dh-dlq-reason, dh-dlq-attempts, dh-dlq-stage, dh-dlq-error-code, dh-flow, dh-version, traceparent, dh-tenant, dh-source-ph), lớp lỗi, trạng thái, ưu tiên, nhóm. Payload ≤ 256 KB giữ ở payload_inline (trường nhạy cảm đã mã hóa bằng DEK tenant trước khi vào DLQ), lớn hơn ở Garage (dlq_payload_ref), FEDERATED không sao chép. Payload gốc không sửa; sửa tạo dlq_revision. Phân vùng tháng theo received_at; khử trùng dlqKey qua inbox_event.';
COMMENT ON COLUMN ph18_ops.dlq_message.payload_inline IS 'Payload gốc ≤ 256 KB (18.dlq.payload.inline-max-kb), trường nhạy cảm đã mã hóa ở PH-04; chỉ được đặt NULL khi dọn (PURGED). Vai readonly không đọc.';
COMMENT ON COLUMN ph18_ops.dlq_message.missing_context IS 'Tên header ngữ cảnh bị thiếu khi tiếp nhận; khác rỗng thì mục vào POISON.';
COMMENT ON COLUMN ph18_ops.dlq_message.retention_until IS 'Hạn giữ: đóng + 18.dlq.retention.closed-days; mục mở không có hạn.';
--rollback DROP TABLE IF EXISTS ph18_ops.dlq_message CASCADE;

--changeset ph18:ph18-0240-dlq-payload-ref splitStatements:false
CREATE TABLE ph18_ops.dlq_payload_ref (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  dlq_id          uuid NOT NULL,
  dlq_received_at timestamptz NOT NULL,
  kind            varchar(10) NOT NULL,
  revision_no     integer NOT NULL DEFAULT 0,
  bucket          varchar(63) NOT NULL,
  object_key      text NOT NULL,
  size_bytes      bigint NOT NULL,
  sha256          char(64) NOT NULL,
  content_type    varchar(127) NOT NULL,
  encrypted       boolean NOT NULL DEFAULT true,
  purged_at       timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_payload_ref PRIMARY KEY (id),
  CONSTRAINT uq_dlq_payload_ref_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dlq_payload_ref_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dlq_payload_ref_kind UNIQUE (tenant_id, dlq_id, kind, revision_no),
  CONSTRAINT fk_dlq_payload_ref_dlq FOREIGN KEY (tenant_id, dlq_id, dlq_received_at) REFERENCES ph18_ops.dlq_message (tenant_id, id, received_at) ON DELETE CASCADE,
  CONSTRAINT ck_dlq_payload_ref_kind CHECK (kind IN ('ORIGINAL', 'REVISION')),
  CONSTRAINT ck_dlq_payload_ref_revision CHECK ((kind = 'ORIGINAL') = (revision_no = 0)),
  CONSTRAINT ck_dlq_payload_ref_bucket CHECK (bucket = 'dh-' || lower(tenant_id) || '-ops'),
  CONSTRAINT ck_dlq_payload_ref_size CHECK (size_bytes > 0),
  CONSTRAINT ck_dlq_payload_ref_sha CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_dlq_payload_ref_encrypted CHECK (encrypted)
);
CREATE TRIGGER tg_dlq_payload_ref_touch BEFORE UPDATE ON ph18_ops.dlq_payload_ref FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dlq_payload_ref_immutable BEFORE UPDATE ON ph18_ops.dlq_payload_ref FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('dlq_id', 'kind', 'revision_no', 'bucket', 'object_key', 'sha256', 'size_bytes');
CALL ph18_ops.p_enable_rls('ph18_ops.dlq_payload_ref', false);
COMMENT ON TABLE ph18_ops.dlq_payload_ref IS 'EN-18-10 Tham chiếu payload lớn hơn 256 KB ở Garage bucket dh-{tenant}-ops (không phải MinIO): bản gốc hoặc bản sửa, kích thước, SHA-256, mã hóa phía máy chủ. Xóa đối tượng khi mục DLQ hết hạn (purged_at).';
--rollback DROP TABLE IF EXISTS ph18_ops.dlq_payload_ref CASCADE;

--changeset ph18:ph18-0250-dlq-revision splitStatements:false
CREATE TABLE ph18_ops.dlq_revision (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  dlq_id              uuid NOT NULL,
  dlq_received_at     timestamptz NOT NULL,
  revision_no         integer NOT NULL,
  payload_location    varchar(10) NOT NULL,
  payload             jsonb,
  payload_sha256      char(64) NOT NULL,
  diff                jsonb NOT NULL,
  reason              text NOT NULL,
  contains_restricted boolean NOT NULL DEFAULT false,
  status              varchar(20) NOT NULL DEFAULT 'DRAFT',
  approved_by         varchar(64),
  approved_at         timestamptz,
  rejected_reason     varchar(1000),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_revision PRIMARY KEY (id),
  CONSTRAINT uq_dlq_revision_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dlq_revision_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dlq_revision_no UNIQUE (tenant_id, dlq_id, revision_no),
  CONSTRAINT fk_dlq_revision_dlq FOREIGN KEY (tenant_id, dlq_id, dlq_received_at) REFERENCES ph18_ops.dlq_message (tenant_id, id, received_at) ON DELETE CASCADE,
  CONSTRAINT ck_dlq_revision_no CHECK (revision_no >= 1),
  CONSTRAINT ck_dlq_revision_location CHECK (payload_location IN ('INLINE', 'GARAGE')),
  CONSTRAINT ck_dlq_revision_inline CHECK ((payload_location = 'INLINE') = (payload IS NOT NULL)),
  CONSTRAINT ck_dlq_revision_sha CHECK (payload_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_dlq_revision_diff CHECK (jsonb_typeof(diff) = 'array'),
  CONSTRAINT ck_dlq_revision_reason CHECK (coalesce(char_length(btrim(reason)), 0) >= 10),
  CONSTRAINT ck_dlq_revision_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'CANCELLED')),
  CONSTRAINT ck_dlq_revision_four_eyes CHECK (approved_by IS NULL OR approved_by <> created_by),
  CONSTRAINT ck_dlq_revision_restricted CHECK (NOT contains_restricted OR status IN ('DRAFT', 'PENDING_APPROVAL', 'REJECTED', 'CANCELLED') OR approved_by IS NOT NULL)
);
CREATE TRIGGER tg_dlq_revision_touch BEFORE UPDATE ON ph18_ops.dlq_revision FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dlq_revision_immutable BEFORE UPDATE ON ph18_ops.dlq_revision FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('dlq_id', 'revision_no');
CREATE TRIGGER tg_dlq_revision_frozen BEFORE UPDATE ON ph18_ops.dlq_revision FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_frozen('PENDING_APPROVAL,APPROVED,REJECTED', 'payload', 'payload_sha256', 'diff', 'reason', 'contains_restricted');
CREATE TRIGGER tg_dlq_revision_fsm_status BEFORE UPDATE ON ph18_ops.dlq_revision FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'DRAFT>PENDING_APPROVAL,DRAFT>APPROVED,DRAFT>CANCELLED,PENDING_APPROVAL>APPROVED,PENDING_APPROVAL>REJECTED,PENDING_APPROVAL>CANCELLED');
CALL ph18_ops.p_enable_rls('ph18_ops.dlq_revision', false);
COMMENT ON TABLE ph18_ops.dlq_revision IS 'EN-18-11 Bản sửa payload có kiểm soát: payload mới (inline hoặc Garage), khác biệt JSON Patch so với bản trước, lý do; có dữ liệu mức Hạn chế thì bốn mắt. Từ PENDING_APPROVAL nội dung bất biến. Phát lại dùng khóa lũy đẳng dlqId:revision.';
--rollback DROP TABLE IF EXISTS ph18_ops.dlq_revision CASCADE;

--changeset ph18:ph18-0260-dlq-assignment splitStatements:false
CREATE TABLE ph18_ops.dlq_assignment (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  dlq_id          uuid NOT NULL,
  dlq_received_at timestamptz NOT NULL,
  assignee        varchar(64) NOT NULL,
  assigned_by     varchar(64) NOT NULL,
  assigned_at     timestamptz NOT NULL DEFAULT now(),
  unassigned_at   timestamptz,
  priority        varchar(2) NOT NULL DEFAULT 'P3',
  note            varchar(500),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_assignment PRIMARY KEY (id),
  CONSTRAINT uq_dlq_assignment_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dlq_assignment_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dlq_assignment_dlq FOREIGN KEY (tenant_id, dlq_id, dlq_received_at) REFERENCES ph18_ops.dlq_message (tenant_id, id, received_at) ON DELETE CASCADE,
  CONSTRAINT ck_dlq_assignment_priority CHECK (priority IN ('P1', 'P2', 'P3', 'P4')),
  CONSTRAINT ck_dlq_assignment_period CHECK (unassigned_at IS NULL OR unassigned_at >= assigned_at)
);
CREATE UNIQUE INDEX uq_dlq_assignment_active ON ph18_ops.dlq_assignment (tenant_id, dlq_id) WHERE unassigned_at IS NULL;
CREATE INDEX ix_dlq_assignment_assignee ON ph18_ops.dlq_assignment (tenant_id, assignee) WHERE unassigned_at IS NULL;
CREATE TRIGGER tg_dlq_assignment_touch BEFORE UPDATE ON ph18_ops.dlq_assignment FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dlq_assignment_immutable BEFORE UPDATE ON ph18_ops.dlq_assignment FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('dlq_id', 'assignee', 'assigned_by', 'assigned_at');
CALL ph18_ops.p_enable_rls('ph18_ops.dlq_assignment', false);
COMMENT ON TABLE ph18_ops.dlq_assignment IS 'EN-18-14 Gán người xử lý mục DLQ: người được gán, người gán, ưu tiên, ghi chú; mỗi mục chỉ một lần gán đang hiệu lực (unassigned_at rỗng). Đồng bộ cột assignee của dlq_message.';
--rollback DROP TABLE IF EXISTS ph18_ops.dlq_assignment CASCADE;

--changeset ph18:ph18-0270-replay-job splitStatements:false
CREATE TABLE ph18_ops.replay_job (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  mode              varchar(12) NOT NULL,
  filter            jsonb,
  reason            text NOT NULL,
  total_items       integer NOT NULL,
  succeeded         integer NOT NULL DEFAULT 0,
  failed            integer NOT NULL DEFAULT 0,
  skipped           integer NOT NULL DEFAULT 0,
  rate_per_minute   integer NOT NULL DEFAULT 60,
  approval_required boolean NOT NULL DEFAULT false,
  status            varchar(20) NOT NULL DEFAULT 'DRAFT',
  approved_by       varchar(64),
  approved_at       timestamptz,
  rejected_reason   varchar(1000),
  started_at        timestamptz,
  paused_at         timestamptz,
  finished_at       timestamptz,
  cancelled_by      varchar(64),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_replay_job PRIMARY KEY (id),
  CONSTRAINT uq_replay_job_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_replay_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_replay_job_mode CHECK (mode IN ('SINGLE', 'BATCH_FILTER', 'BATCH_LIST')),
  CONSTRAINT ck_replay_job_single CHECK (mode <> 'SINGLE' OR total_items = 1),
  CONSTRAINT ck_replay_job_filter CHECK (mode <> 'BATCH_FILTER' OR filter IS NOT NULL),
  CONSTRAINT ck_replay_job_reason CHECK (coalesce(char_length(btrim(reason)), 0) >= 10),
  CONSTRAINT ck_replay_job_rate CHECK (rate_per_minute BETWEEN 1 AND 6000),
  CONSTRAINT ck_replay_job_counts CHECK (total_items >= 1 AND succeeded >= 0 AND failed >= 0 AND skipped >= 0 AND succeeded + failed + skipped <= total_items),
  CONSTRAINT ck_replay_job_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'RUNNING', 'PAUSED', 'COMPLETED', 'PARTIAL', 'FAILED', 'CANCELLED', 'REJECTED')),
  CONSTRAINT ck_replay_job_four_eyes CHECK (approved_by IS NULL OR approved_by <> created_by),
  CONSTRAINT ck_replay_job_approved CHECK (NOT approval_required OR status IN ('DRAFT', 'PENDING_APPROVAL', 'REJECTED', 'CANCELLED') OR approved_by IS NOT NULL)
);
CREATE INDEX ix_replay_job_status ON ph18_ops.replay_job (tenant_id, status, created_at DESC);
CREATE TRIGGER tg_replay_job_touch BEFORE UPDATE ON ph18_ops.replay_job FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_replay_job_immutable BEFORE UPDATE ON ph18_ops.replay_job FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('mode', 'filter', 'total_items', 'approval_required');
CREATE TRIGGER tg_replay_job_fsm_status BEFORE UPDATE ON ph18_ops.replay_job FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'DRAFT>PENDING_APPROVAL,DRAFT>APPROVED,DRAFT>CANCELLED,PENDING_APPROVAL>APPROVED,PENDING_APPROVAL>REJECTED,PENDING_APPROVAL>CANCELLED,APPROVED>RUNNING,APPROVED>CANCELLED,RUNNING>PAUSED,PAUSED>RUNNING,RUNNING>COMPLETED,RUNNING>PARTIAL,RUNNING>FAILED,RUNNING>CANCELLED,PAUSED>CANCELLED');
CALL ph18_ops.p_enable_rls('ph18_ops.replay_job', false);
COMMENT ON TABLE ph18_ops.replay_job IS 'EN-18-16 Lượt phát lại đơn hoặc loạt (theo bộ lọc hay danh sách, ≤ 18.dlq.replay.batch-max); vượt 18.dlq.replay.approval-threshold thì bốn mắt; tốc độ giới hạn; tạm dừng, hủy; bộ đếm kết quả. Phát lại luôn qua lối vào của nguồn.';
--rollback DROP TABLE IF EXISTS ph18_ops.replay_job CASCADE;

--changeset ph18:ph18-0280-replay-item splitStatements:false
CREATE TABLE ph18_ops.replay_item (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  job_id            uuid NOT NULL,
  dlq_id            uuid NOT NULL,
  dlq_received_at   timestamptz NOT NULL,
  revision_no       integer NOT NULL DEFAULT 0,
  idempotency_key   varchar(80) NOT NULL,
  status            varchar(20) NOT NULL DEFAULT 'PENDING',
  replay_trace_id   char(32),
  dispatched_at     timestamptz,
  result_at         timestamptz,
  result_error_code varchar(16),
  result_message    varchar(2000),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_replay_item PRIMARY KEY (id),
  CONSTRAINT uq_replay_item_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_replay_item_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_replay_item_dlq UNIQUE (tenant_id, job_id, dlq_id),
  CONSTRAINT fk_replay_item_job FOREIGN KEY (tenant_id, job_id) REFERENCES ph18_ops.replay_job (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_replay_item_dlq FOREIGN KEY (tenant_id, dlq_id, dlq_received_at) REFERENCES ph18_ops.dlq_message (tenant_id, id, received_at) ON DELETE CASCADE,
  CONSTRAINT ck_replay_item_idem CHECK (idempotency_key = dlq_id::text || ':' || revision_no::text),
  CONSTRAINT ck_replay_item_status CHECK (status IN ('PENDING', 'SENT', 'SUCCEEDED', 'FAILED', 'SKIPPED_DUPLICATE', 'CANCELLED')),
  CONSTRAINT ck_replay_item_trace CHECK (replay_trace_id IS NULL OR replay_trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_replay_item_pending ON ph18_ops.replay_item (tenant_id, job_id, status);
CREATE INDEX ix_replay_item_idem ON ph18_ops.replay_item (tenant_id, idempotency_key);
CREATE TRIGGER tg_replay_item_touch BEFORE UPDATE ON ph18_ops.replay_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_replay_item_immutable BEFORE UPDATE ON ph18_ops.replay_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('job_id', 'dlq_id', 'revision_no', 'idempotency_key');
CREATE TRIGGER tg_replay_item_fsm_status BEFORE UPDATE ON ph18_ops.replay_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'PENDING>SENT,PENDING>CANCELLED,PENDING>SKIPPED_DUPLICATE,SENT>SUCCEEDED,SENT>FAILED,SENT>SKIPPED_DUPLICATE');
CALL ph18_ops.p_enable_rls('ph18_ops.replay_item', false);
COMMENT ON TABLE ph18_ops.replay_item IS 'EN-18-17 Một mục trong lượt phát lại: mục DLQ, số bản sửa, khóa lũy đẳng dlqId:revision gửi cho nguồn, trạng thái, trace phát lại, kết quả do nguồn báo (callback ops:replay-callback hoặc EVT-10-12).';
--rollback DROP TABLE IF EXISTS ph18_ops.replay_item CASCADE;

--changeset ph18:ph18-0290-dlq-audit splitStatements:false
CREATE TABLE ph18_ops.dlq_audit (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  dlq_id        uuid,
  replay_job_id uuid,
  action        varchar(20) NOT NULL,
  actor         varchar(64) NOT NULL,
  actor_kind    varchar(8) NOT NULL DEFAULT 'USER',
  reason        text,
  before_status varchar(16),
  after_status  varchar(16),
  details       jsonb NOT NULL DEFAULT '{}',
  trace_id      char(32),
  occurred_at   timestamptz NOT NULL DEFAULT now(),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dlq_audit PRIMARY KEY (id, occurred_at),
  CONSTRAINT uq_dlq_audit_tid UNIQUE (tenant_id, id, occurred_at),
  CONSTRAINT ck_dlq_audit_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_dlq_audit_action CHECK (action IN ('INGEST', 'VIEW_PAYLOAD', 'TRIAGE', 'ASSIGN', 'REVISE', 'APPROVE_REVISION', 'REPLAY_REQUEST', 'REPLAY_APPROVE', 'REPLAY_RESULT', 'DISCARD', 'REOPEN', 'EXPIRE', 'PURGE', 'EXPORT')),
  CONSTRAINT ck_dlq_audit_actor_kind CHECK (actor_kind IN ('USER', 'SERVICE')),
  CONSTRAINT ck_dlq_audit_reason CHECK (action NOT IN ('VIEW_PAYLOAD', 'DISCARD', 'REOPEN', 'REVISE') OR coalesce(char_length(btrim(reason)), 0) >= 10),
  CONSTRAINT ck_dlq_audit_target CHECK (dlq_id IS NOT NULL OR replay_job_id IS NOT NULL),
  CONSTRAINT ck_dlq_audit_no_payload CHECK (NOT (details ?| ARRAY['payload', 'payloadInline', 'value']))
) PARTITION BY RANGE (occurred_at);
CALL ph18_ops.p_ensure_partitions('ph18_ops.dlq_audit', (current_date - interval '1 month')::date, 4);
CREATE INDEX ix_dlq_audit_dlq ON ph18_ops.dlq_audit (tenant_id, dlq_id, occurred_at);
CREATE INDEX ix_dlq_audit_actor ON ph18_ops.dlq_audit (tenant_id, actor, occurred_at);
CREATE TRIGGER tg_dlq_audit_touch BEFORE UPDATE ON ph18_ops.dlq_audit FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_dlq_audit_append_only BEFORE UPDATE OR DELETE ON ph18_ops.dlq_audit FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_append_only();
CALL ph18_ops.p_enable_rls('ph18_ops.dlq_audit', false);
COMMENT ON TABLE ph18_ops.dlq_audit IS 'EN-18-12 Nhật ký thao tác trên DLQ (xem payload có lý do, phân loại, gán, sửa, duyệt, phát lại, bỏ qua, mở lại, hết hạn, dọn): chỉ thêm, đồng thời gửi PH-13 kiểm toán. Phân vùng tháng theo occurred_at, giữ 18.dlq.audit.retention-months (mặc định 60 tháng). Tham chiếu logic tới dlq_message (không khóa ngoại để nhật ký sống lâu hơn mục).';
--rollback DROP TABLE IF EXISTS ph18_ops.dlq_audit CASCADE;
