--liquibase formatted sql
-- Nguồn: ddl/ph17_assist.sql · 17-0040-knowledge.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph17:ph17-0320-knowledge-source
CREATE TABLE ph17_assist.knowledge_source (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  source_code     varchar(64) NOT NULL,
  source_type     varchar(16) NOT NULL,
  name            varchar(255) NOT NULL,
  source_state    varchar(8) NOT NULL DEFAULT 'ACTIVE',
  owner_org_id    varchar(63),
  schedule_cron   varchar(64),
  config          jsonb NOT NULL DEFAULT '{}',
  last_indexed_at timestamptz,
  paused_at       timestamptz,
  retired_at      timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_knowledge_source PRIMARY KEY (id),
  CONSTRAINT uq_knowledge_source_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_knowledge_source_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_knowledge_source_code UNIQUE (tenant_id, source_code),
  CONSTRAINT ck_knowledge_source_code CHECK (source_code ~ '^[A-Z][A-Z0-9-]{2,63}$'),
  CONSTRAINT ck_knowledge_source_type CHECK (source_type IN ('API_SPEC', 'RDM_CATALOG', 'FLOW', 'TOPIC', 'ERROR_CODE', 'GUIDE', 'UPLOAD')),
  CONSTRAINT ck_knowledge_source_state CHECK (source_state IN ('ACTIVE', 'PAUSED', 'RETIRED')),
  CONSTRAINT ck_knowledge_source_paused CHECK ((source_state = 'PAUSED') = (paused_at IS NOT NULL)),
  CONSTRAINT ck_knowledge_source_retired CHECK ((source_state = 'RETIRED') = (retired_at IS NOT NULL)),
  CONSTRAINT ck_knowledge_source_config CHECK (config::text !~* '(bearer |openbao://|password)')
);
CREATE INDEX ix_knowledge_source_type ON ph17_assist.knowledge_source (tenant_id, source_type, source_state);
CREATE TRIGGER tg_knowledge_source_touch BEFORE UPDATE ON ph17_assist.knowledge_source FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_knowledge_source_immutable BEFORE UPDATE ON ph17_assist.knowledge_source FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('source_code', 'source_type');
CREATE TRIGGER tg_knowledge_source_fsm_source_state BEFORE UPDATE ON ph17_assist.knowledge_source FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('source_state', 'ACTIVE>PAUSED,PAUSED>ACTIVE,ACTIVE>RETIRED,PAUSED>RETIRED');
CALL ph17_assist.p_enable_rls_common('ph17_assist.knowledge_source');
COMMENT ON TABLE ph17_assist.knowledge_source IS 'EN-17-16 Nguồn tri thức (FR-17-015, 021; BR-17-025, 031): API_SPEC, RDM_CATALOG, FLOW, TOPIC, ERROR_CODE, GUIDE, UPLOAD. Thuộc một tenant hoặc COMMON do PA quản. Chỉ lập chỉ mục siêu dữ liệu và tài liệu, không bản ghi nghiệp vụ. Tạm dừng và ngừng giữ lịch sử.';
COMMENT ON COLUMN ph17_assist.knowledge_source.source_type IS 'Phụ lục A dùng ERROR_CODE và GUIDE; BR-17-025 viết ERR_CATALOG và OPS_GUIDE (Đề nghị đồng bộ).';
COMMENT ON COLUMN ph17_assist.knowledge_source.source_state IS 'ACTIVE, PAUSED, RETIRED (FRS 4.4; SourceState, Phụ lục A).';
--rollback DROP TABLE IF EXISTS ph17_assist.knowledge_source CASCADE;

--changeset ph17:ph17-0330-knowledge-document
CREATE TABLE ph17_assist.knowledge_document (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  source_id        uuid NOT NULL,
  external_ref     varchar(512) NOT NULL,
  title            varchar(500) NOT NULL,
  class_level      varchar(16),
  class_checked_at timestamptz,
  index_status     varchar(16) NOT NULL DEFAULT 'PENDING',
  content_hash     char(64),
  chunk_count      integer NOT NULL DEFAULT 0,
  skip_reason      varchar(255),
  failure_count    smallint NOT NULL DEFAULT 0,
  last_error_code  varchar(16),
  indexed_at       timestamptz,
  delete_reason    varchar(16),
  owner_org_id     varchar(63),
  file_id          uuid,
  upload_status    varchar(20),
  declared_class   varchar(16),
  uploaded_by      varchar(64),
  approved_by      varchar(64),
  approved_at      timestamptz,
  reject_reason    varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_knowledge_document PRIMARY KEY (id),
  CONSTRAINT uq_knowledge_document_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_knowledge_document_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_knowledge_document_source FOREIGN KEY (tenant_id, source_id) REFERENCES ph17_assist.knowledge_source (tenant_id, id),
  CONSTRAINT fk_knowledge_document_file FOREIGN KEY (tenant_id, file_id) REFERENCES ph17_assist.file_object (tenant_id, id),
  CONSTRAINT uq_knowledge_document_ref UNIQUE (tenant_id, source_id, external_ref),
  CONSTRAINT ck_knowledge_document_class CHECK (class_level IS NULL OR class_level IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE')),
  CONSTRAINT ck_knowledge_document_status CHECK (index_status IN ('PENDING', 'CLASSIFYING', 'INDEXED', 'SKIPPED_CLASS', 'FAILED', 'DELETED')),
  CONSTRAINT ck_knowledge_document_indexed_class CHECK (index_status <> 'INDEXED' OR class_level IN ('PUBLIC', 'INTERNAL')),
  CONSTRAINT ck_knowledge_document_skipped CHECK (index_status <> 'SKIPPED_CLASS' OR skip_reason IS NOT NULL),
  CONSTRAINT ck_knowledge_document_failed CHECK (index_status <> 'FAILED' OR (failure_count >= 3 AND last_error_code IS NOT NULL)),
  CONSTRAINT ck_knowledge_document_chunks CHECK (chunk_count >= 0 AND (index_status = 'INDEXED' OR chunk_count = 0)),
  CONSTRAINT ck_knowledge_document_hash CHECK (content_hash IS NULL OR content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_knowledge_document_deleted CHECK ((index_status = 'DELETED') = (delete_reason IS NOT NULL)),
  CONSTRAINT ck_knowledge_document_delete_reason CHECK (delete_reason IS NULL OR delete_reason IN ('SOURCE_DELETED', 'REVOKED', 'CLASS_CHANGED', 'SOURCE_RETIRED', 'UPLOAD_STOPPED', 'PURGE')),
  CONSTRAINT ck_knowledge_document_upload CHECK (upload_status IS NULL OR upload_status IN ('UPLOADED', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'STOPPED')),
  CONSTRAINT ck_knowledge_document_declared CHECK (declared_class IS NULL OR declared_class IN ('PUBLIC', 'INTERNAL')),
  CONSTRAINT ck_knowledge_document_upload_fields CHECK (upload_status IS NULL OR (file_id IS NOT NULL AND declared_class IS NOT NULL AND uploaded_by IS NOT NULL)),
  CONSTRAINT ck_knowledge_document_upload_gate CHECK (upload_status IS NULL OR upload_status = 'APPROVED' OR index_status NOT IN ('CLASSIFYING', 'INDEXED')),
  CONSTRAINT ck_knowledge_document_approved CHECK (upload_status <> 'APPROVED' OR (approved_by IS NOT NULL AND approved_at IS NOT NULL AND approved_by <> uploaded_by)),
  CONSTRAINT ck_knowledge_document_rejected CHECK (upload_status <> 'REJECTED' OR char_length(COALESCE(reject_reason, '')) >= 20)
);
CREATE INDEX ix_knowledge_document_source ON ph17_assist.knowledge_document (tenant_id, source_id, index_status);
CREATE INDEX ix_knowledge_document_skipped ON ph17_assist.knowledge_document (tenant_id, source_id) WHERE index_status = 'SKIPPED_CLASS';
CREATE INDEX ix_knowledge_document_upload ON ph17_assist.knowledge_document (tenant_id, upload_status) WHERE upload_status IS NOT NULL;
CREATE TRIGGER tg_knowledge_document_touch BEFORE UPDATE ON ph17_assist.knowledge_document FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_knowledge_document_immutable BEFORE UPDATE ON ph17_assist.knowledge_document FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('source_id', 'external_ref');
CREATE TRIGGER tg_knowledge_document_fsm_index_status BEFORE UPDATE ON ph17_assist.knowledge_document FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('index_status', 'PENDING>CLASSIFYING,CLASSIFYING>INDEXED,CLASSIFYING>SKIPPED_CLASS,PENDING>FAILED,CLASSIFYING>FAILED,INDEXED>PENDING,INDEXED>DELETED,SKIPPED_CLASS>PENDING,FAILED>PENDING');
CREATE TRIGGER tg_knowledge_document_fsm_upload_status BEFORE UPDATE ON ph17_assist.knowledge_document FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('upload_status', 'UPLOADED>PENDING_APPROVAL,PENDING_APPROVAL>APPROVED,PENDING_APPROVAL>REJECTED,APPROVED>STOPPED,UPLOADED>STOPPED,REJECTED>UPLOADED');
CREATE TRIGGER tg_knowledge_document_purge BEFORE UPDATE ON ph17_assist.knowledge_document FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_doc_purge_chunks();
CALL ph17_assist.p_enable_rls_common('ph17_assist.knowledge_document');
COMMENT ON TABLE ph17_assist.knowledge_document IS 'EN-17-17 Tài liệu hoặc đối tượng trong nguồn tri thức (FR-17-016…021; BR-17-026, 028, 029, 030). index_status theo máy trạng thái FRS 4.4; chỉ INDEXED khi mức PUBLIC hoặc INTERNAL; SKIPPED_CLASS, DELETED xóa hết đoạn ngay trong giao dịch. Tài liệu tải lên đi qua upload_status và duyệt bốn mắt.';
COMMENT ON COLUMN ph17_assist.knowledge_document.class_level IS 'Mức phân loại do PH-09 trả (DD-08); NULL là chưa xác định, xử lý như không được lập chỉ mục (đóng an toàn).';
COMMENT ON COLUMN ph17_assist.knowledge_document.upload_status IS 'UPLOADED, PENDING_APPROVAL, APPROVED, REJECTED, STOPPED theo Phụ lục A; FRS 4.4 còn nêu DRAFT, RETIRED (Đề nghị đồng bộ).';
COMMENT ON COLUMN ph17_assist.knowledge_document.delete_reason IS 'Lý do xóa vật lý đoạn; DB tự chép sang knowledge_deletion.';
--rollback DROP TABLE IF EXISTS ph17_assist.knowledge_document CASCADE;

--changeset ph17:ph17-0340-knowledge-chunk
CREATE TABLE ph17_assist.knowledge_chunk (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  source_id         uuid NOT NULL,
  document_id       uuid NOT NULL,
  chunk_no          integer NOT NULL,
  content           text NOT NULL,
  content_norm      text NOT NULL,
  content_tsv       tsvector GENERATED ALWAYS AS (to_tsvector('simple', content_norm)) STORED,
  embedding         real[] NOT NULL,
  embed_version_id  uuid NOT NULL,
  class_level       varchar(16) NOT NULL,
  acl               jsonb NOT NULL,
  content_hash      char(64) NOT NULL,
  token_count       integer NOT NULL,
  object_ref        varchar(512),
  injection_suspect boolean NOT NULL DEFAULT false,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_knowledge_chunk PRIMARY KEY (id),
  CONSTRAINT uq_knowledge_chunk_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_knowledge_chunk_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_knowledge_chunk_document FOREIGN KEY (tenant_id, document_id) REFERENCES ph17_assist.knowledge_document (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_knowledge_chunk_source FOREIGN KEY (tenant_id, source_id) REFERENCES ph17_assist.knowledge_source (tenant_id, id),
  CONSTRAINT fk_knowledge_chunk_embed_version FOREIGN KEY (embed_version_id) REFERENCES ph17_assist.model_version (id),
  CONSTRAINT uq_knowledge_chunk_no UNIQUE (tenant_id, document_id, chunk_no, embed_version_id),
  CONSTRAINT ck_knowledge_chunk_class CHECK (class_level IN ('PUBLIC', 'INTERNAL')),
  CONSTRAINT ck_knowledge_chunk_no CHECK (chunk_no >= 0 AND token_count BETWEEN 1 AND 2000),
  CONSTRAINT ck_knowledge_chunk_hash CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_knowledge_chunk_acl CHECK (jsonb_typeof(acl) = 'object' AND acl ->> 'visibility' IN ('TENANT', 'ORG', 'ROLE') AND (acl ->> 'visibility' <> 'ORG' OR jsonb_array_length(COALESCE(acl -> 'orgIds', '[]'::jsonb)) >= 1)),
  CONSTRAINT ck_knowledge_chunk_content CHECK (char_length(content) BETWEEN 1 AND 20000)
);
CREATE INDEX ix_knowledge_chunk_source ON ph17_assist.knowledge_chunk (tenant_id, source_id);
CREATE INDEX ix_knowledge_chunk_embed ON ph17_assist.knowledge_chunk (tenant_id, embed_version_id);
CREATE INDEX ix_knowledge_chunk_hash ON ph17_assist.knowledge_chunk (tenant_id, content_hash);
CREATE INDEX ix_knowledge_chunk_tsv ON ph17_assist.knowledge_chunk USING gin (content_tsv);
CREATE TRIGGER tg_knowledge_chunk_touch BEFORE UPDATE ON ph17_assist.knowledge_chunk FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_knowledge_chunk_immutable BEFORE UPDATE ON ph17_assist.knowledge_chunk FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('document_id', 'embed_version_id', 'content_hash');
CREATE TRIGGER tg_knowledge_chunk_gate BEFORE INSERT ON ph17_assist.knowledge_chunk FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_chunk_gate();
CALL ph17_assist.p_enable_rls_common('ph17_assist.knowledge_chunk');
COMMENT ON TABLE ph17_assist.knowledge_chunk IS 'EN-17-18 Đoạn tri thức đã nhúng (FR-17-018, 019, 023, 024; BR-17-016, 026, 027, 034). Mỗi đoạn có tenant_id, nguồn, phạm vi quyền đọc acl, class_level chỉ PUBLIC hoặc INTERNAL, embed_model_version_id, content_hash. embedding là vector(1024) khi có pgvector (ADR-170); trên CI chỉ real[]. Đoạn COMMON chỉ đọc với tenant.';
COMMENT ON COLUMN ph17_assist.knowledge_chunk.embedding IS 'vector(1024) khi có pgvector (đổi kiểu và chỉ mục HNSW vector_cosine_ops ở bước 17-0031-pgvector); real[] chỉ để CI trên postgres:16 không có pgvector.';
COMMENT ON COLUMN ph17_assist.knowledge_chunk.content_norm IS 'Nội dung không dấu, chữ thường, dùng cho tìm từ khóa (tsvector cấu hình simple).';
COMMENT ON COLUMN ph17_assist.knowledge_chunk.acl IS 'Phạm vi quyền đọc: visibility TENANT, ORG (orgIds) hoặc ROLE (roles); truy hồi lọc theo acl rồi xác minh quyền người hỏi (BR-17-035).';
COMMENT ON COLUMN ph17_assist.knowledge_chunk.embed_version_id IS 'Phiên bản mô hình nhúng; không trộn vector của hai phiên bản trong một truy hồi (BR-17-016).';
COMMENT ON COLUMN ph17_assist.knowledge_chunk.injection_suspect IS 'Đoạn bị quét mẫu tiêm lệnh gián tiếp khi lập chỉ mục gắn cờ nghi ngờ (chốt 27/11/2026); đoạn vẫn được giữ và vẫn bọc như dữ liệu không tin cậy khi dùng, cờ chỉ để SO và chủ phân hệ nguồn rà (FR-17-018).';
--rollback DROP TABLE IF EXISTS ph17_assist.knowledge_chunk CASCADE;

--changeset ph17:ph17-0350-index-job
CREATE TABLE ph17_assist.index_job (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  source_id      uuid,
  document_id    uuid,
  job_kind       varchar(8) NOT NULL,
  status         varchar(8) NOT NULL DEFAULT 'QUEUED',
  trigger_ref    varchar(128) NOT NULL,
  attempt        smallint NOT NULL DEFAULT 1,
  docs_added     integer NOT NULL DEFAULT 0,
  docs_deleted   integer NOT NULL DEFAULT 0,
  docs_skipped   integer NOT NULL DEFAULT 0,
  docs_failed    integer NOT NULL DEFAULT 0,
  chunks_added   integer NOT NULL DEFAULT 0,
  chunks_deleted integer NOT NULL DEFAULT 0,
  started_at     timestamptz,
  finished_at    timestamptz,
  error_code     varchar(16),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_index_job PRIMARY KEY (id),
  CONSTRAINT uq_index_job_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_index_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_index_job_source FOREIGN KEY (tenant_id, source_id) REFERENCES ph17_assist.knowledge_source (tenant_id, id),
  CONSTRAINT ck_index_job_kind CHECK (job_kind IN ('EVENT', 'FULL', 'DELETE')),
  CONSTRAINT ck_index_job_status CHECK (status IN ('QUEUED', 'RUNNING', 'DONE', 'FAILED')),
  CONSTRAINT ck_index_job_attempt CHECK (attempt BETWEEN 1 AND 3),
  CONSTRAINT ck_index_job_counts CHECK (docs_added >= 0 AND docs_deleted >= 0 AND docs_skipped >= 0 AND docs_failed >= 0 AND chunks_added >= 0 AND chunks_deleted >= 0),
  CONSTRAINT ck_index_job_finished CHECK ((status IN ('DONE', 'FAILED')) = (finished_at IS NOT NULL)),
  CONSTRAINT ck_index_job_failed CHECK (status <> 'FAILED' OR error_code IS NOT NULL),
  CONSTRAINT ck_index_job_scope CHECK (source_id IS NOT NULL OR job_kind = 'FULL')
);
CREATE UNIQUE INDEX uq_index_job_full_running ON ph17_assist.index_job (tenant_id, source_id) WHERE job_kind = 'FULL' AND status IN ('QUEUED', 'RUNNING') AND source_id IS NOT NULL;
CREATE INDEX ix_index_job_source ON ph17_assist.index_job (tenant_id, source_id, created_at DESC);
CREATE INDEX ix_index_job_status ON ph17_assist.index_job (tenant_id, status, created_at DESC);
CREATE TRIGGER tg_index_job_touch BEFORE UPDATE ON ph17_assist.index_job FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_index_job_fsm_status BEFORE UPDATE ON ph17_assist.index_job FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'QUEUED>RUNNING,RUNNING>DONE,RUNNING>FAILED,QUEUED>FAILED');
CALL ph17_assist.p_enable_rls('ph17_assist.index_job');
COMMENT ON TABLE ph17_assist.index_job IS 'EN-17-19 Lượt lập chỉ mục: theo sự kiện (EVENT), toàn bộ (FULL), xóa (DELETE) (FR-17-017, 021; BR-17-028). Lỗi thử lại ba lần có lùi mũ rồi FAILED, không chặn nguồn khác. Một nguồn chỉ một lượt FULL đang chạy (ERR-17-044).';
COMMENT ON COLUMN ph17_assist.index_job.trigger_ref IS 'Mã sự kiện nguồn (event_id), CRON hoặc mã người yêu cầu.';
--rollback DROP TABLE IF EXISTS ph17_assist.index_job CASCADE;

--changeset ph17:ph17-0360-knowledge-deletion
CREATE TABLE ph17_assist.knowledge_deletion (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  source_id      uuid,
  document_id    uuid,
  reason         varchar(16) NOT NULL,
  chunks_deleted integer NOT NULL,
  trigger_ref    varchar(128),
  requested_at   timestamptz NOT NULL DEFAULT now(),
  completed_at   timestamptz NOT NULL DEFAULT now(),
  latency_ms     integer,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_knowledge_deletion PRIMARY KEY (id),
  CONSTRAINT ck_knowledge_deletion_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_knowledge_deletion_reason CHECK (reason IN ('SOURCE_DELETED', 'REVOKED', 'CLASS_CHANGED', 'SOURCE_RETIRED', 'UPLOAD_STOPPED', 'PURGE')),
  CONSTRAINT ck_knowledge_deletion_count CHECK (chunks_deleted >= 0),
  CONSTRAINT ck_knowledge_deletion_time CHECK (completed_at >= requested_at)
);
CREATE INDEX ix_knowledge_deletion_doc ON ph17_assist.knowledge_deletion (tenant_id, document_id, completed_at DESC);
CREATE TRIGGER tg_knowledge_deletion_touch BEFORE UPDATE ON ph17_assist.knowledge_deletion FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_knowledge_deletion_append_only BEFORE UPDATE OR DELETE ON ph17_assist.knowledge_deletion FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_append_only();
CALL ph17_assist.p_enable_rls_common('ph17_assist.knowledge_deletion');
COMMENT ON TABLE ph17_assist.knowledge_deletion IS 'EN-17-45 (FR-17-019; BR-17-029). Nhật ký xóa lan truyền đoạn khỏi chỉ mục: mỗi lần xóa ghi lý do, số đoạn, độ trễ để chứng minh ≤ 60 giây (đổi phân loại, thu hồi) hoặc ≤ 5 phút (xóa nguồn). Chỉ thêm; không chứa nội dung đoạn.';
COMMENT ON COLUMN ph17_assist.knowledge_deletion.document_id IS 'Tham chiếu logic (tài liệu có thể đã bị xóa vật lý).';
--rollback DROP TABLE IF EXISTS ph17_assist.knowledge_deletion CASCADE;
