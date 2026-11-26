--liquibase formatted sql
-- Nguồn: ddl/ph17_assist.sql · 17-0050-chat.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph17:ph17-0370-conversation
CREATE TABLE ph17_assist.conversation (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  user_id            varchar(64) NOT NULL,
  title              varchar(200),
  state              varchar(16) NOT NULL DEFAULT 'ACTIVE',
  screen_context     jsonb NOT NULL DEFAULT '{}',
  message_count      integer NOT NULL DEFAULT 0,
  last_message_at    timestamptz,
  expires_at         timestamptz NOT NULL,
  deleted_by_user_at timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_conversation PRIMARY KEY (id),
  CONSTRAINT uq_conversation_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_conversation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_conversation_state CHECK (state IN ('ACTIVE', 'DELETED_BY_USER', 'EXPIRED')),
  CONSTRAINT ck_conversation_ctx CHECK (ph17_assist.fn_ctx_ok(screen_context)),
  CONSTRAINT ck_conversation_retention CHECK (expires_at >= created_at + interval '90 days'),
  CONSTRAINT ck_conversation_deleted CHECK ((state = 'DELETED_BY_USER') = (deleted_by_user_at IS NOT NULL)),
  CONSTRAINT ck_conversation_count CHECK (message_count >= 0)
);
CREATE INDEX ix_conversation_user ON ph17_assist.conversation (tenant_id, user_id, last_message_at DESC) WHERE state = 'ACTIVE';
CREATE INDEX ix_conversation_expires ON ph17_assist.conversation (tenant_id, expires_at);
CREATE TRIGGER tg_conversation_touch BEFORE UPDATE ON ph17_assist.conversation FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_conversation_immutable BEFORE UPDATE ON ph17_assist.conversation FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('user_id');
CREATE TRIGGER tg_conversation_fsm_state BEFORE UPDATE ON ph17_assist.conversation FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('state', 'ACTIVE>DELETED_BY_USER,ACTIVE>EXPIRED');
CALL ph17_assist.p_enable_rls_user('ph17_assist.conversation', 'ph17_assist.fn_log_grant_ok(id, created_at)', 'expires_at <= now()');
COMMENT ON TABLE ph17_assist.conversation IS 'EN-17-20 Hội thoại của một người dùng (FR-17-022, 027; BR-17-032, 033, 039). RLS theo người dùng: chỉ chủ hội thoại đọc; SO và AUDITOR đọc khi có phiếu truy cập còn hiệu lực. expires_at tối thiểu 90 ngày; xóa vật lý chỉ khi hết hạn. Ngữ cảnh màn hình chỉ có route, mã đối tượng, mã lỗi, tab.';
COMMENT ON COLUMN ph17_assist.conversation.screen_context IS 'Chỉ khóa route, objectId, errorCode, tab; không giá trị dữ liệu đang hiển thị (BR-17-032, fn_ctx_ok).';
COMMENT ON COLUMN ph17_assist.conversation.expires_at IS 'Hạn xóa vật lý = created_at cộng 17.log.retention-days ngày, sàn 90.';
--rollback DROP TABLE IF EXISTS ph17_assist.conversation CASCADE;

--changeset ph17:ph17-0380-message
CREATE TABLE ph17_assist.message (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  conversation_id   uuid NOT NULL,
  user_id           varchar(64) NOT NULL,
  seq               integer NOT NULL,
  role              varchar(10) NOT NULL,
  content_masked    text NOT NULL,
  masked            boolean NOT NULL DEFAULT true,
  redaction_count   integer NOT NULL DEFAULT 0,
  outcome           varchar(16),
  capability        varchar(16),
  model_version_id  uuid,
  prompt_version_id uuid,
  tokens_in         integer,
  tokens_out        integer,
  truncated         boolean NOT NULL DEFAULT false,
  guardrail_codes   varchar(48)[],
  dedup_id          uuid,
  latency_ms        integer,
  trace_id          char(32),
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_message PRIMARY KEY (id),
  CONSTRAINT uq_message_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_message_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_message_conversation FOREIGN KEY (tenant_id, conversation_id) REFERENCES ph17_assist.conversation (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT uq_message_seq UNIQUE (tenant_id, conversation_id, seq),
  CONSTRAINT ck_message_role CHECK (role IN ('USER', 'ASSISTANT', 'TOOL')),
  CONSTRAINT ck_message_outcome CHECK (outcome IS NULL OR outcome IN ('ANSWERED', 'NO_SOURCE', 'BLOCKED_INPUT', 'BLOCKED_OUTPUT', 'QUOTA', 'CANCELLED', 'ERROR')),
  CONSTRAINT ck_message_outcome_role CHECK ((role = 'ASSISTANT') = (outcome IS NOT NULL)),
  CONSTRAINT ck_message_masked CHECK (masked),
  CONSTRAINT ck_message_seq CHECK (seq >= 1),
  CONSTRAINT ck_message_size CHECK (char_length(content_masked) <= 40000),
  CONSTRAINT ck_message_capability CHECK (capability IS NULL OR capability IN ('SEARCH', 'MAPPING', 'EXPLAIN')),
  CONSTRAINT ck_message_counts CHECK (redaction_count >= 0 AND COALESCE(tokens_in, 0) >= 0 AND COALESCE(tokens_out, 0) >= 0),
  CONSTRAINT ck_message_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_message_no_secret CHECK (content_masked !~* '(bearer +[a-z0-9._~+/=-]{20,}|begin [a-z ]*private key)')
);
CREATE UNIQUE INDEX uq_message_dedup ON ph17_assist.message (tenant_id, conversation_id, dedup_id) WHERE dedup_id IS NOT NULL;
CREATE INDEX ix_message_conversation ON ph17_assist.message (tenant_id, conversation_id, seq);
CREATE INDEX ix_message_outcome ON ph17_assist.message (tenant_id, created_at, outcome) WHERE role = 'ASSISTANT';
CREATE TRIGGER tg_message_touch BEFORE UPDATE ON ph17_assist.message FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_message_immutable BEFORE UPDATE ON ph17_assist.message FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('conversation_id', 'user_id', 'seq', 'role', 'content_masked');
CALL ph17_assist.p_enable_rls_user('ph17_assist.message', 'ph17_assist.fn_log_grant_ok(conversation_id, created_at)', 'false');
COMMENT ON TABLE ph17_assist.message IS 'EN-17-21 Tin nhắn người dùng, trợ lý, công cụ ĐÃ CHE trước khi lưu (FR-17-022…027, 055; BR-17-073). Không lưu token, không lưu nội dung chưa che (cờ masked luôn đúng). outcome ghi kết quả câu trả lời; dedup_id chống gửi trùng trong 5 phút (BR-17-087). RLS theo người dùng.';
COMMENT ON COLUMN ph17_assist.message.masked IS 'Luôn đúng: tầng ứng dụng che DLCN, bí mật trước khi ghi (FR-17-041, 045, 046).';
COMMENT ON COLUMN ph17_assist.message.dedup_id IS 'Từ tiêu đề Idempotency-Key; hiệu lực chống trùng 5 phút do tầng ứng dụng kiểm.';
COMMENT ON COLUMN ph17_assist.message.guardrail_codes IS 'Mã quy tắc bộ lọc đã kích hoạt (guardrail_rule.rule_code).';
--rollback DROP TABLE IF EXISTS ph17_assist.message CASCADE;

--changeset ph17:ph17-0390-citation
CREATE TABLE ph17_assist.citation (
  id         uuid NOT NULL,
  tenant_id  varchar(16) NOT NULL,
  message_id uuid NOT NULL,
  user_id    varchar(64) NOT NULL,
  rank       smallint NOT NULL,
  chunk_id   uuid,
  source_id  uuid,
  object_ref varchar(512) NOT NULL,
  link_route varchar(512) NOT NULL,
  score      numeric(5,4) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by varchar(64) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by varchar(64) NOT NULL,
  version    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_citation PRIMARY KEY (id),
  CONSTRAINT ck_citation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_citation_message FOREIGN KEY (tenant_id, message_id) REFERENCES ph17_assist.message (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT uq_citation_rank UNIQUE (tenant_id, message_id, rank),
  CONSTRAINT ck_citation_rank CHECK (rank >= 1),
  CONSTRAINT ck_citation_route CHECK (link_route ~ '^/[A-Za-z0-9/_.:~%@!$&=+,;-]*(\?[A-Za-z0-9/_.:~%@!$&=+,;-]*)?(#[A-Za-z0-9_.-]*)?$' AND link_route !~ '^//'),
  CONSTRAINT ck_citation_score CHECK (score BETWEEN 0 AND 1)
);
CREATE INDEX ix_citation_message ON ph17_assist.citation (tenant_id, message_id);
CREATE TRIGGER tg_citation_touch BEFORE UPDATE ON ph17_assist.citation FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls_user('ph17_assist.citation', 'false', 'false');
COMMENT ON TABLE ph17_assist.citation IS 'EN-17-22 Trích dẫn của một câu trả lời (FR-17-025; BR-17-036, 037): đoạn, đối tượng, liên kết nội bộ, điểm. Liên kết chỉ là route nội bộ của cổng Datahub; liên kết ngoài bị bỏ. chunk_id là tham chiếu logic vì đoạn có thể bị xóa lan truyền.';
--rollback DROP TABLE IF EXISTS ph17_assist.citation CASCADE;

--changeset ph17:ph17-0400-tool-definition
CREATE TABLE ph17_assist.tool_definition (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  tool_code       varchar(32) NOT NULL,
  name            varchar(255) NOT NULL,
  target_module   varchar(8) NOT NULL,
  target_ref      varchar(128) NOT NULL,
  scope           varchar(64) NOT NULL,
  capabilities    varchar(16)[] NOT NULL,
  enabled         boolean NOT NULL DEFAULT false,
  read_only       boolean NOT NULL DEFAULT true,
  timeout_seconds smallint,
  enabled_by      varchar(64),
  enabled_at      timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tool_definition PRIMARY KEY (id),
  CONSTRAINT uq_tool_definition_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_tool_definition_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_tool_definition_code UNIQUE (tenant_id, tool_code),
  CONSTRAINT ck_tool_definition_code CHECK (tool_code ~ '^[A-Z][A-Z0-9_]{2,31}$'),
  CONSTRAINT ck_tool_definition_module CHECK (target_module ~ '^PH[0-9]{2}$'),
  CONSTRAINT ck_tool_definition_read_only CHECK (read_only),
  CONSTRAINT ck_tool_definition_scope CHECK (scope ~ '^[a-z0-9-]+:read$'),
  CONSTRAINT ck_tool_definition_caps CHECK (cardinality(capabilities) >= 1 AND capabilities <@ ARRAY['SEARCH', 'MAPPING', 'EXPLAIN']::varchar[]),
  CONSTRAINT ck_tool_definition_timeout CHECK (timeout_seconds IS NULL OR timeout_seconds BETWEEN 3 AND 30),
  CONSTRAINT ck_tool_definition_enabled CHECK (NOT enabled OR (enabled_by IS NOT NULL AND enabled_at IS NOT NULL))
);
CREATE TRIGGER tg_tool_definition_touch BEFORE UPDATE ON ph17_assist.tool_definition FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_tool_definition_immutable BEFORE UPDATE ON ph17_assist.tool_definition FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('tool_code', 'target_module', 'target_ref', 'scope', 'read_only');
CALL ph17_assist.p_enable_rls('ph17_assist.tool_definition');
COMMENT ON TABLE ph17_assist.tool_definition IS 'EN-17-23 Công cụ của trợ lý (FR-17-042, 047; BR-17-056, 057): danh mục cố định theo mã nguồn, mỗi tenant chỉ bật hoặc tắt. read_only luôn đúng, scope luôn kết thúc :read, không có công cụ ghi; gọi bằng token của người dùng qua token exchange RFC 8693, không quyền riêng của dh-assist.';
COMMENT ON COLUMN ph17_assist.tool_definition.target_ref IS 'Tên thao tác đọc của phân hệ đích (ví dụ catalog.search-apis); ánh xạ sang mã API-nn khi phân hệ đích công bố (Q17-51).';
--rollback DROP TABLE IF EXISTS ph17_assist.tool_definition CASCADE;

--changeset ph17:ph17-0410-tool-call
CREATE TABLE ph17_assist.tool_call (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  message_id     uuid NOT NULL,
  user_id        varchar(64) NOT NULL,
  tool_code      varchar(32) NOT NULL,
  depth          smallint NOT NULL DEFAULT 1,
  args_masked    jsonb NOT NULL DEFAULT '{}',
  result_summary varchar(4000),
  outcome        varchar(8) NOT NULL,
  duration_ms    integer NOT NULL,
  error_code     varchar(16),
  act_subject    varchar(16) NOT NULL DEFAULT 'dh-assist',
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tool_call PRIMARY KEY (id),
  CONSTRAINT ck_tool_call_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_tool_call_message FOREIGN KEY (tenant_id, message_id) REFERENCES ph17_assist.message (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT ck_tool_call_depth CHECK (depth BETWEEN 1 AND 5),
  CONSTRAINT ck_tool_call_outcome CHECK (outcome IN ('OK', 'TIMEOUT', 'DENIED', 'ERROR')),
  CONSTRAINT ck_tool_call_act CHECK (act_subject = 'dh-assist'),
  CONSTRAINT ck_tool_call_duration CHECK (duration_ms >= 0),
  CONSTRAINT ck_tool_call_no_token CHECK (args_masked::text !~* '(bearer |access_token|refresh_token)')
);
CREATE INDEX ix_tool_call_message ON ph17_assist.tool_call (tenant_id, message_id);
CREATE INDEX ix_tool_call_tool ON ph17_assist.tool_call (tenant_id, tool_code, created_at DESC);
CREATE TRIGGER tg_tool_call_touch BEFORE UPDATE ON ph17_assist.tool_call FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls_user('ph17_assist.tool_call', 'false', 'false');
COMMENT ON TABLE ph17_assist.tool_call IS 'EN-17-24 Một lần gọi công cụ trong lượt (FR-17-043, 047; BR-17-047, 057, 061): tham số đã che, tóm tắt kết quả, thời gian, mã lỗi. Không lưu token trao đổi; act_subject luôn dh-assist. Độ sâu 1…5. RLS theo người dùng.';
--rollback DROP TABLE IF EXISTS ph17_assist.tool_call CASCADE;

--changeset ph17:ph17-0420-suggestion
CREATE TABLE ph17_assist.suggestion (
  id                      uuid NOT NULL,
  tenant_id               varchar(16) NOT NULL,
  user_id                 varchar(64) NOT NULL,
  kind                    varchar(18) NOT NULL,
  status                  varchar(10) NOT NULL DEFAULT 'PROPOSED',
  conversation_id         uuid,
  message_id              uuid,
  host_module             varchar(8),
  host_ref                varchar(255),
  host_etag               varchar(128),
  payload                 jsonb NOT NULL,
  confidence              numeric(3,2) NOT NULL,
  rationale               varchar(4000) NOT NULL,
  diff_masked             jsonb,
  human_decision_required boolean NOT NULL DEFAULT true,
  expires_at              timestamptz NOT NULL,
  decided_by              varchar(64),
  decided_at              timestamptz,
  created_at              timestamptz NOT NULL DEFAULT now(),
  created_by              varchar(64) NOT NULL,
  updated_at              timestamptz NOT NULL DEFAULT now(),
  updated_by              varchar(64) NOT NULL,
  version                 integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_suggestion PRIMARY KEY (id),
  CONSTRAINT uq_suggestion_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_suggestion_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_suggestion_kind CHECK (kind IN ('FIELD_MAPPING', 'CODE_MAPPING', 'REMEDIATION', 'BPM_STEP', 'INCIDENT_SUMMARY')),
  CONSTRAINT ck_suggestion_status CHECK (status IN ('PROPOSED', 'ACCEPTED', 'EDITED', 'REJECTED', 'EXPIRED')),
  CONSTRAINT ck_suggestion_confidence CHECK (confidence BETWEEN 0 AND 1),
  CONSTRAINT ck_suggestion_host CHECK (host_module IS NULL OR host_module IN ('PH04', 'PH07', 'PH11', 'PH18')),
  CONSTRAINT ck_suggestion_human CHECK (human_decision_required),
  CONSTRAINT ck_suggestion_decided CHECK ((status IN ('ACCEPTED', 'EDITED', 'REJECTED')) = (decided_by IS NOT NULL AND decided_at IS NOT NULL)),
  CONSTRAINT ck_suggestion_edited CHECK (status <> 'EDITED' OR diff_masked IS NOT NULL),
  CONSTRAINT ck_suggestion_applied CHECK (status NOT IN ('ACCEPTED', 'EDITED') OR (host_module IS NOT NULL AND host_ref IS NOT NULL AND host_etag IS NOT NULL)),
  CONSTRAINT ck_suggestion_no_apply CHECK (kind NOT IN ('REMEDIATION', 'INCIDENT_SUMMARY') OR status IN ('PROPOSED', 'EXPIRED', 'REJECTED')),
  CONSTRAINT ck_suggestion_ttl CHECK (expires_at > created_at)
);
CREATE INDEX ix_suggestion_user ON ph17_assist.suggestion (tenant_id, user_id, created_at DESC);
CREATE INDEX ix_suggestion_status ON ph17_assist.suggestion (tenant_id, status, expires_at);
CREATE INDEX ix_suggestion_host ON ph17_assist.suggestion (tenant_id, host_module, host_ref);
CREATE TRIGGER tg_suggestion_touch BEFORE UPDATE ON ph17_assist.suggestion FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_suggestion_immutable BEFORE UPDATE ON ph17_assist.suggestion FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('user_id', 'kind', 'payload', 'confidence', 'host_etag');
CREATE TRIGGER tg_suggestion_fsm_status BEFORE UPDATE ON ph17_assist.suggestion FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'PROPOSED>ACCEPTED,PROPOSED>EDITED,PROPOSED>REJECTED,PROPOSED>EXPIRED');
CALL ph17_assist.p_enable_rls_user('ph17_assist.suggestion', 'false', 'false');
COMMENT ON TABLE ph17_assist.suggestion IS 'EN-17-25 Gợi ý của trợ lý (FR-17-030…035, 061; BR-17-043…049, 083): ánh xạ trường, mã, khắc phục, bước quy trình, tóm tắt. PROPOSED, ACCEPTED, EDITED, REJECTED, EXPIRED theo FRS 4.5; chỉ ghi vào phân hệ chủ bằng quyền người dùng; khắc phục và tóm tắt không có áp dụng. Gợi ý bước quy trình luôn cần người quyết định.';
COMMENT ON COLUMN ph17_assist.suggestion.host_etag IS 'ETag của bản nháp ở phân hệ chủ lúc tạo thẻ; bản nháp đổi thì ERR-17-056 (BR-17-048).';
COMMENT ON COLUMN ph17_assist.suggestion.diff_masked IS 'Phần khác biệt đã che khi người dùng sửa (EDITED), chỉ để đo chất lượng, không huấn luyện (BR-17-049).';
COMMENT ON COLUMN ph17_assist.suggestion.payload IS 'Nội dung đề xuất (biểu thức JQ, mã chuẩn, danh sách kiểm); không giá trị dữ liệu thật (BR-17-043).';
--rollback DROP TABLE IF EXISTS ph17_assist.suggestion CASCADE;

--changeset ph17:ph17-0430-explanation
CREATE TABLE ph17_assist.explanation (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  user_id           varchar(64) NOT NULL,
  kind              varchar(16) NOT NULL,
  subject_ref       varchar(255) NOT NULL,
  content_masked    text NOT NULL,
  masked            boolean NOT NULL DEFAULT true,
  sources           jsonb NOT NULL DEFAULT '[]',
  model_version_id  uuid,
  prompt_version_id uuid,
  expires_at        timestamptz NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_explanation PRIMARY KEY (id),
  CONSTRAINT ck_explanation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_explanation_kind CHECK (kind IN ('ERROR_CODE', 'TRACE', 'DLQ_MESSAGE', 'REMEDIATION', 'INCIDENT_SUMMARY')),
  CONSTRAINT ck_explanation_masked CHECK (masked),
  CONSTRAINT ck_explanation_ttl CHECK (expires_at > created_at)
);
CREATE INDEX ix_explanation_user ON ph17_assist.explanation (tenant_id, user_id, created_at DESC);
CREATE TRIGGER tg_explanation_touch BEFORE UPDATE ON ph17_assist.explanation FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls_user('ph17_assist.explanation', 'false', 'expires_at <= now()');
COMMENT ON TABLE ph17_assist.explanation IS 'EN-17-46 (FR-17-036…040, API-17-113…118). Một lần giải thích mã lỗi, trace_id, bản tin DLQ, danh sách kiểm khắc phục hoặc tóm tắt sự cố: nội dung ĐÃ CHE, nguồn trích, mô hình và prompt dùng. Lấy lại được tới hết hạn (API-17-116). RLS theo người dùng.';
COMMENT ON COLUMN ph17_assist.explanation.kind IS 'Đề nghị bổ sung ExplanationKind vào Phụ lục A.';
--rollback DROP TABLE IF EXISTS ph17_assist.explanation CASCADE;

--changeset ph17:ph17-0440-suggested-question
CREATE TABLE ph17_assist.suggested_question (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  question_text varchar(300) NOT NULL,
  route_pattern varchar(255) NOT NULL,
  role_group    varchar(32) NOT NULL DEFAULT 'ALL_READERS',
  capability    varchar(16) NOT NULL,
  enabled       boolean NOT NULL DEFAULT true,
  sort_no       smallint NOT NULL DEFAULT 100,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_suggested_question PRIMARY KEY (id),
  CONSTRAINT ck_suggested_question_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_suggested_question_capability CHECK (capability IN ('SEARCH', 'MAPPING', 'EXPLAIN')),
  CONSTRAINT ck_suggested_question_route CHECK (route_pattern ~ '^/[A-Za-z0-9/_*:{}-]*$'),
  CONSTRAINT ck_suggested_question_text CHECK (char_length(question_text) >= 5)
);
CREATE INDEX ix_suggested_question_route ON ph17_assist.suggested_question (tenant_id, capability, enabled, route_pattern);
CREATE TRIGGER tg_suggested_question_touch BEFORE UPDATE ON ph17_assist.suggested_question FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls('ph17_assist.suggested_question');
COMMENT ON TABLE ph17_assist.suggested_question IS 'EN-17-47 (FR-17-028; BR-17-040). Danh mục câu hỏi mẫu theo route và nhóm vai trò, không sinh bằng mô hình; chỉ hiện câu thuộc năng lực đang bật. TA thêm, sửa, ngừng.';
--rollback DROP TABLE IF EXISTS ph17_assist.suggested_question CASCADE;
