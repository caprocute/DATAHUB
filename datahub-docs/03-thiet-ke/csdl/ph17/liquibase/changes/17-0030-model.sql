--liquibase formatted sql
-- Nguồn: ddl/ph17_assist.sql · 17-0030-model.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph17:ph17-0210-model-provider
CREATE TABLE ph17_assist.model_provider (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  provider_code       varchar(32) NOT NULL,
  name                varchar(255) NOT NULL,
  provider_kind       varchar(8) NOT NULL,
  protocol            varchar(24) NOT NULL DEFAULT 'OPENAI_COMPATIBLE',
  endpoint_url        varchar(512) NOT NULL,
  data_region         varchar(8) NOT NULL DEFAULT 'VN',
  secret_ref          varchar(255),
  status              varchar(12) NOT NULL DEFAULT 'DRAFT',
  commitment_valid_to date,
  suspended_reason    varchar(2000),
  retired_at          timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_model_provider PRIMARY KEY (id),
  CONSTRAINT ck_model_provider_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_model_provider_code UNIQUE (tenant_id, provider_code),
  CONSTRAINT ck_model_provider_common CHECK (tenant_id = 'COMMON'),
  CONSTRAINT ck_model_provider_code CHECK (provider_code ~ '^[A-Z][A-Z0-9-]{2,31}$'),
  CONSTRAINT ck_model_provider_kind CHECK (provider_kind IN ('INTERNAL', 'EXTERNAL')),
  CONSTRAINT ck_model_provider_status CHECK (status IN ('DRAFT', 'ACTIVE', 'SUSPENDED', 'RETIRED')),
  CONSTRAINT ck_model_provider_protocol CHECK (protocol IN ('OPENAI_COMPATIBLE', 'ANTHROPIC_MESSAGES', 'CUSTOM_HTTP')),
  CONSTRAINT ck_model_provider_secret_ref CHECK (secret_ref IS NULL OR secret_ref ~ '^openbao://kv/[A-Za-z0-9/_.-]{3,200}$'),
  CONSTRAINT ck_model_provider_external_https CHECK (provider_kind <> 'EXTERNAL' OR (endpoint_url ~ '^https://[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+(:[0-9]{2,5})?(/.*)?$' AND endpoint_url !~ '^https://[0-9.]+([:/]|$)' AND endpoint_url !~ '(localhost|169\.254|\.internal|\.local)')),
  CONSTRAINT ck_model_provider_external_region CHECK (provider_kind <> 'EXTERNAL' OR (data_region = 'VN' AND secret_ref IS NOT NULL)),
  CONSTRAINT ck_model_provider_external_active CHECK (provider_kind <> 'EXTERNAL' OR status NOT IN ('ACTIVE') OR commitment_valid_to IS NOT NULL),
  CONSTRAINT ck_model_provider_suspended CHECK (status <> 'SUSPENDED' OR suspended_reason IS NOT NULL),
  CONSTRAINT ck_model_provider_retired CHECK ((status = 'RETIRED') = (retired_at IS NOT NULL))
);
CREATE TRIGGER tg_model_provider_touch BEFORE UPDATE ON ph17_assist.model_provider FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_model_provider_immutable BEFORE UPDATE ON ph17_assist.model_provider FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('provider_code', 'provider_kind');
CREATE TRIGGER tg_model_provider_fsm_status BEFORE UPDATE ON ph17_assist.model_provider FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'DRAFT>ACTIVE,ACTIVE>SUSPENDED,SUSPENDED>ACTIVE,ACTIVE>RETIRED,SUSPENDED>RETIRED,DRAFT>RETIRED');
CALL ph17_assist.p_enable_rls_common('ph17_assist.model_provider');
COMMENT ON TABLE ph17_assist.model_provider IS 'EN-17-09 Nhà cung cấp mô hình dùng chung do PA khai báo, tenant_id COMMON (FR-17-007; BR-17-011, 012, 013). INTERNAL (vLLM trong cụm) hoặc EXTERNAL: điểm cuối HTTPS theo tên miền, vùng lưu dữ liệu VN, có secret_ref tới OpenBao, không lưu bí mật. ACTIVE với EXTERNAL cần cam kết còn hiệu lực.';
COMMENT ON COLUMN ph17_assist.model_provider.secret_ref IS 'Tham chiếu OpenBao dạng openbao://kv/... ; không lưu giá trị bí mật (BR-17-011).';
COMMENT ON COLUMN ph17_assist.model_provider.data_region IS 'Vùng lưu dữ liệu của nhà cung cấp; EXTERNAL phải là VN (SEC-49, Luật An ninh mạng 116/2025).';
COMMENT ON COLUMN ph17_assist.model_provider.commitment_valid_to IS 'Ngày hết hạn của cam kết hiện hành (bản sao từ provider_commitment); hết hạn thì tự SUSPENDED (BR-17-013).';
--rollback DROP TABLE IF EXISTS ph17_assist.model_provider CASCADE;

--changeset ph17:ph17-0220-provider-commitment
CREATE TABLE ph17_assist.provider_commitment (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  provider_id      uuid NOT NULL,
  doc_no           varchar(64) NOT NULL,
  doc_date         date NOT NULL,
  valid_from       date NOT NULL,
  valid_to         date NOT NULL,
  domestic_storage boolean NOT NULL,
  no_training      boolean NOT NULL,
  file_id          uuid NOT NULL,
  state            varchar(12) NOT NULL DEFAULT 'ACTIVE',
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_provider_commitment PRIMARY KEY (id),
  CONSTRAINT ck_provider_commitment_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_provider_commitment_provider FOREIGN KEY (provider_id) REFERENCES ph17_assist.model_provider (id),
  CONSTRAINT fk_provider_commitment_file FOREIGN KEY (tenant_id, file_id) REFERENCES ph17_assist.file_object (tenant_id, id),
  CONSTRAINT ck_provider_commitment_pledge CHECK (domestic_storage AND no_training),
  CONSTRAINT ck_provider_commitment_period CHECK (valid_to > valid_from),
  CONSTRAINT ck_provider_commitment_state CHECK (state IN ('ACTIVE', 'EXPIRED', 'SUPERSEDED'))
);
CREATE INDEX ix_provider_commitment_provider ON ph17_assist.provider_commitment (provider_id, valid_to DESC);
CREATE TRIGGER tg_provider_commitment_touch BEFORE UPDATE ON ph17_assist.provider_commitment FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_provider_commitment_immutable BEFORE UPDATE ON ph17_assist.provider_commitment FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('provider_id', 'doc_no', 'file_id');
CALL ph17_assist.p_enable_rls_common('ph17_assist.provider_commitment');
COMMENT ON TABLE ph17_assist.provider_commitment IS 'EN-17-42 (FR-17-003, 007; BR-17-013). Cam kết của nhà cung cấp ngoài về lưu dữ liệu trong nước và không dùng dữ liệu huấn luyện: số văn bản, tệp đính kèm, hiệu lực. Cả hai cam kết phải đúng (ERR-17-026).';
COMMENT ON COLUMN ph17_assist.provider_commitment.state IS 'ACTIVE, EXPIRED, SUPERSEDED (CommitmentState, Phụ lục A).';
--rollback DROP TABLE IF EXISTS ph17_assist.provider_commitment CASCADE;

--changeset ph17:ph17-0230-model
CREATE TABLE ph17_assist.model (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  model_code   varchar(64) NOT NULL,
  name         varchar(255) NOT NULL,
  model_kind   varchar(12) NOT NULL,
  scope        varchar(8) NOT NULL,
  provider_id  uuid NOT NULL,
  capabilities varchar(24)[] NOT NULL,
  description  varchar(2000),
  retired_at   timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_model PRIMARY KEY (id),
  CONSTRAINT uq_model_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_model_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_model_code UNIQUE (tenant_id, model_code),
  CONSTRAINT ck_model_code CHECK (model_code ~ '^[a-z0-9][a-z0-9._-]{2,63}$'),
  CONSTRAINT ck_model_kind CHECK (model_kind IN ('CHAT', 'EMBEDDING', 'RERANK')),
  CONSTRAINT ck_model_scope CHECK (scope IN ('COMMON', 'TENANT')),
  CONSTRAINT ck_model_scope_tenant CHECK ((scope = 'COMMON') = (tenant_id = 'COMMON')),
  CONSTRAINT ck_model_caps CHECK (cardinality(capabilities) >= 1 AND capabilities <@ ARRAY['SEARCH', 'MAPPING', 'EXPLAIN', 'CLASSIFY_TEXT', 'EXTRACT_FIELDS', 'SUGGEST_STEP', 'EMBED', 'RERANK']::varchar[]),
  CONSTRAINT ck_model_kind_caps CHECK ((model_kind <> 'EMBEDDING' OR capabilities = ARRAY['EMBED']::varchar[]) AND (model_kind <> 'RERANK' OR capabilities = ARRAY['RERANK']::varchar[])),
  CONSTRAINT fk_model_provider FOREIGN KEY (provider_id) REFERENCES ph17_assist.model_provider (id)
);
CREATE TRIGGER tg_model_touch BEFORE UPDATE ON ph17_assist.model FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_model_immutable BEFORE UPDATE ON ph17_assist.model FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('model_code', 'model_kind', 'scope', 'provider_id');
CALL ph17_assist.p_enable_rls_common('ph17_assist.model');
COMMENT ON TABLE ph17_assist.model IS 'EN-17-10 Mô hình: CHAT, EMBEDDING, RERANK; phạm vi COMMON (PA khai báo, tenant_id COMMON) hoặc TENANT (FR-17-008). Một nhà cung cấp có nhiều mô hình; năng lực hỗ trợ gồm SEARCH, MAPPING, EXPLAIN và nhiệm vụ data plane.';
COMMENT ON COLUMN ph17_assist.model.capabilities IS 'SEARCH, MAPPING, EXPLAIN (Capability) và CLASSIFY_TEXT, EXTRACT_FIELDS, SUGGEST_STEP (data plane, BR-17-082), EMBED, RERANK (ModelCapability, Phụ lục A).';
--rollback DROP TABLE IF EXISTS ph17_assist.model CASCADE;

--changeset ph17:ph17-0240-model-version
CREATE TABLE ph17_assist.model_version (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  model_id         uuid NOT NULL,
  version_no       integer NOT NULL,
  version_label    varchar(64) NOT NULL,
  upstream_name    varchar(128) NOT NULL,
  status           varchar(12) NOT NULL DEFAULT 'DRAFT',
  context_tokens   integer NOT NULL,
  embedding_dim    smallint,
  price_in_per_1k  numeric(12,4) NOT NULL DEFAULT 0,
  price_out_per_1k numeric(12,4) NOT NULL DEFAULT 0,
  gen_params       jsonb NOT NULL DEFAULT '{}',
  eval_run_id      uuid,
  redteam_run_id   uuid,
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  approved_at      timestamptz,
  retired_at       timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_model_version PRIMARY KEY (id),
  CONSTRAINT uq_model_version_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_model_version_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_model_version_model FOREIGN KEY (tenant_id, model_id) REFERENCES ph17_assist.model (tenant_id, id),
  CONSTRAINT uq_model_version_no UNIQUE (tenant_id, model_id, version_no),
  CONSTRAINT ck_model_version_version CHECK (version_no >= 1),
  CONSTRAINT ck_model_version_status CHECK (status IN ('DRAFT', 'EVALUATING', 'APPROVED', 'RETIRED')),
  CONSTRAINT ck_model_version_context CHECK (context_tokens BETWEEN 256 AND 2000000),
  CONSTRAINT ck_model_version_dim CHECK (embedding_dim IS NULL OR embedding_dim BETWEEN 64 AND 4096),
  CONSTRAINT ck_model_version_price CHECK (price_in_per_1k >= 0 AND price_out_per_1k >= 0),
  CONSTRAINT ck_model_version_params CHECK (gen_params::text !~* '(bearer |openbao://|password|api[_-]?key)'),
  CONSTRAINT ck_model_version_four_eyes CHECK (decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_model_version_approved CHECK (status <> 'APPROVED' OR (decided_by IS NOT NULL AND approved_at IS NOT NULL AND eval_run_id IS NOT NULL AND redteam_run_id IS NOT NULL)),
  CONSTRAINT ck_model_version_reject CHECK (decision_comment IS NULL OR char_length(decision_comment) >= 20),
  CONSTRAINT ck_model_version_retired CHECK ((status = 'RETIRED') = (retired_at IS NOT NULL)),
  CONSTRAINT ck_model_version_submitted CHECK (status NOT IN ('EVALUATING', 'APPROVED') OR submitted_by IS NOT NULL)
);
CREATE INDEX ix_model_version_status ON ph17_assist.model_version (tenant_id, status);
CREATE TRIGGER tg_model_version_touch BEFORE UPDATE ON ph17_assist.model_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_model_version_immutable BEFORE UPDATE ON ph17_assist.model_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('model_id', 'version_no');
CREATE TRIGGER tg_model_version_frozen BEFORE UPDATE ON ph17_assist.model_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_frozen('EVALUATING,APPROVED,RETIRED', 'version_label', 'upstream_name', 'context_tokens', 'embedding_dim', 'price_in_per_1k', 'price_out_per_1k', 'gen_params');
CREATE TRIGGER tg_model_version_fsm_status BEFORE UPDATE ON ph17_assist.model_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'DRAFT>EVALUATING,EVALUATING>DRAFT,EVALUATING>APPROVED,APPROVED>RETIRED,DRAFT>RETIRED');
CREATE TRIGGER tg_model_version_gate BEFORE UPDATE ON ph17_assist.model_version FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_release_gate('MODEL');
CALL ph17_assist.p_enable_rls_common('ph17_assist.model_version');
COMMENT ON TABLE ph17_assist.model_version IS 'EN-17-11 Phiên bản mô hình, đối tượng được duyệt (FR-17-008, 009; BR-14, 15, 16, 24). DRAFT, EVALUATING, APPROVED, RETIRED (FRS 4.3); chỉ APPROVED định tuyến được. Duyệt bốn mắt và qua cổng phát hành: đánh giá chuẩn đạt, ca đỏ 100%, bộ ca đỏ từ 50 ca đang hoạt động. Nội dung khóa từ EVALUATING.';
COMMENT ON COLUMN ph17_assist.model_version.embedding_dim IS 'Số chiều vector của mô hình nhúng (1024 theo mặc định); chỉ EMBEDDING có giá trị.';
COMMENT ON COLUMN ph17_assist.model_version.eval_run_id IS 'Lượt đánh giá chuẩn đạt ngưỡng 17.eval.min-score (BR-17-015).';
COMMENT ON COLUMN ph17_assist.model_version.redteam_run_id IS 'Lượt bộ ca đỏ không lọt ca nào (BR-17-067).';
--rollback DROP TABLE IF EXISTS ph17_assist.model_version CASCADE;

--changeset ph17:ph17-0250-model-route
CREATE TABLE ph17_assist.model_route (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  version_id      uuid NOT NULL,
  route_ref       varchar(128) NOT NULL,
  egress_host     varchar(255) NOT NULL,
  priority        smallint NOT NULL DEFAULT 0,
  status          varchar(10) NOT NULL DEFAULT 'PENDING',
  snapshot_ref    varchar(128),
  last_synced_at  timestamptz,
  drift           boolean NOT NULL DEFAULT false,
  last_error_code varchar(16),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_model_route PRIMARY KEY (id),
  CONSTRAINT uq_model_route_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_model_route_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_model_route_version FOREIGN KEY (tenant_id, version_id) REFERENCES ph17_assist.model_version (tenant_id, id),
  CONSTRAINT uq_model_route_priority UNIQUE (tenant_id, version_id, priority),
  CONSTRAINT uq_model_route_ref UNIQUE (tenant_id, route_ref),
  CONSTRAINT ck_model_route_status CHECK (status IN ('PENDING', 'SYNCED', 'FAILED', 'DISABLED')),
  CONSTRAINT ck_model_route_priority CHECK (priority BETWEEN 0 AND 9),
  CONSTRAINT ck_model_route_host CHECK (egress_host !~ '^[0-9.]+$' AND (egress_host ~ '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$' OR egress_host ~ '^[a-z0-9-]+\.svc(\.cluster\.local)?$')),
  CONSTRAINT ck_model_route_synced CHECK (status <> 'SYNCED' OR (snapshot_ref IS NOT NULL AND last_synced_at IS NOT NULL))
);
CREATE TRIGGER tg_model_route_touch BEFORE UPDATE ON ph17_assist.model_route FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_model_route_fsm_status BEFORE UPDATE ON ph17_assist.model_route FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'PENDING>SYNCED,PENDING>FAILED,SYNCED>PENDING,FAILED>PENDING,PENDING>DISABLED,SYNCED>DISABLED,FAILED>DISABLED,DISABLED>PENDING');
CALL ph17_assist.p_enable_rls_common('ph17_assist.model_route');
COMMENT ON TABLE ph17_assist.model_route IS 'EN-17-12 Tuyến từ phiên bản mô hình tới đích egress APISIX ai-proxy (FR-17-010, 011; BR-17-018, 019, 020). priority 0 là tuyến chính, lớn hơn là dự phòng. PH-03 áp cấu hình; tuyến chưa SYNCED thì mô hình chưa gọi được.';
COMMENT ON COLUMN ph17_assist.model_route.egress_host IS 'Tên miền trong nước đã khai báo (EXTERNAL) hoặc tên dịch vụ trong cụm (INTERNAL); không IP trần (BR-17-012).';
COMMENT ON COLUMN ph17_assist.model_route.drift IS 'Cấu hình thực ở APISIX lệch cấu hình mong muốn (BR-17-020).';
--rollback DROP TABLE IF EXISTS ph17_assist.model_route CASCADE;

--changeset ph17:ph17-0260-route-sync-run
CREATE TABLE ph17_assist.route_sync_run (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  requested_by     varchar(64) NOT NULL,
  status           varchar(10) NOT NULL DEFAULT 'PENDING',
  route_count      integer NOT NULL DEFAULT 0,
  request_event_id uuid,
  result_event_id  uuid,
  snapshot_ref     varchar(128),
  started_at       timestamptz NOT NULL DEFAULT now(),
  finished_at      timestamptz,
  error_code       varchar(16),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_route_sync_run PRIMARY KEY (id),
  CONSTRAINT ck_route_sync_run_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_route_sync_run_status CHECK (status IN ('PENDING', 'SYNCED', 'FAILED', 'DISABLED')),
  CONSTRAINT ck_route_sync_run_count CHECK (route_count >= 0),
  CONSTRAINT ck_route_sync_run_finished CHECK ((status IN ('SYNCED', 'FAILED')) = (finished_at IS NOT NULL))
);
CREATE INDEX ix_route_sync_run_started ON ph17_assist.route_sync_run (tenant_id, started_at DESC);
CREATE TRIGGER tg_route_sync_run_touch BEFORE UPDATE ON ph17_assist.route_sync_run FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_route_sync_run_fsm_status BEFORE UPDATE ON ph17_assist.route_sync_run FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'PENDING>SYNCED,PENDING>FAILED');
CALL ph17_assist.p_enable_rls_common('ph17_assist.route_sync_run');
COMMENT ON TABLE ph17_assist.route_sync_run IS 'EN-17-13 Một lượt đồng bộ cấu hình tuyến sang PH-03 và kết quả (FR-17-011): phát EVT-17-08, nhận EVT-17-09 (gateway.snapshot.published hoặc rejected). Bản ghi chỉ mang mã và số đếm.';
--rollback DROP TABLE IF EXISTS ph17_assist.route_sync_run CASCADE;

--changeset ph17:ph17-0270-tenant-model
CREATE TABLE ph17_assist.tenant_model (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  version_id          uuid NOT NULL,
  model_kind          varchar(12) NOT NULL,
  enabled             boolean NOT NULL DEFAULT false,
  is_default          boolean NOT NULL DEFAULT false,
  fallback_version_id uuid,
  enabled_by          varchar(64),
  enabled_at          timestamptz,
  disabled_at         timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_model PRIMARY KEY (id),
  CONSTRAINT ck_tenant_model_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_tenant_model_version FOREIGN KEY (version_id) REFERENCES ph17_assist.model_version (id),
  CONSTRAINT uq_tenant_model_version UNIQUE (tenant_id, version_id),
  CONSTRAINT ck_tenant_model_kind CHECK (model_kind IN ('CHAT', 'EMBEDDING', 'RERANK')),
  CONSTRAINT ck_tenant_model_default CHECK (NOT is_default OR enabled),
  CONSTRAINT ck_tenant_model_fallback CHECK (fallback_version_id IS NULL OR fallback_version_id <> version_id),
  CONSTRAINT ck_tenant_model_enabled CHECK (NOT enabled OR (enabled_by IS NOT NULL AND enabled_at IS NOT NULL)),
  CONSTRAINT fk_tenant_model_fallback_version FOREIGN KEY (fallback_version_id) REFERENCES ph17_assist.model_version (id)
);
CREATE UNIQUE INDEX uq_tenant_model_default ON ph17_assist.tenant_model (tenant_id, model_kind) WHERE is_default AND enabled;
CREATE TRIGGER tg_tenant_model_touch BEFORE UPDATE ON ph17_assist.tenant_model FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_tenant_model_rules BEFORE INSERT OR UPDATE ON ph17_assist.tenant_model FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_tenant_model_rules();
CALL ph17_assist.p_enable_rls('ph17_assist.tenant_model');
COMMENT ON TABLE ph17_assist.tenant_model IS 'EN-17-43 (FR-17-010; BR-17-004, 017, 018). Phiên bản mô hình tenant đã bật, mô hình mặc định và dự phòng theo loại. Bật được khi phiên bản APPROVED; nhà cung cấp EXTERNAL cần chính sách cho phép và danh sách trắng; dự phòng cùng loại, đã duyệt, không từ INTERNAL sang EXTERNAL (ERR-17-016, 017, 030, 034).';
--rollback DROP TABLE IF EXISTS ph17_assist.tenant_model CASCADE;

--changeset ph17:ph17-0280-provider-grant
CREATE TABLE ph17_assist.provider_grant (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  provider_id    uuid NOT NULL,
  change_id      uuid NOT NULL,
  granted_by     varchar(64) NOT NULL,
  effective_from date NOT NULL DEFAULT current_date,
  effective_to   date,
  revoked_at     timestamptz,
  revoked_by     varchar(64),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_provider_grant PRIMARY KEY (id),
  CONSTRAINT ck_provider_grant_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_provider_grant_provider FOREIGN KEY (provider_id) REFERENCES ph17_assist.model_provider (id),
  CONSTRAINT fk_provider_grant_change FOREIGN KEY (tenant_id, change_id) REFERENCES ph17_assist.policy_change (tenant_id, id),
  CONSTRAINT ck_provider_grant_period CHECK (effective_to IS NULL OR effective_to >= effective_from),
  CONSTRAINT ck_provider_grant_revoked CHECK ((revoked_at IS NULL) = (revoked_by IS NULL))
);
CREATE UNIQUE INDEX uq_provider_grant_active ON ph17_assist.provider_grant (tenant_id, provider_id) WHERE revoked_at IS NULL;
CREATE TRIGGER tg_provider_grant_touch BEFORE UPDATE ON ph17_assist.provider_grant FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_provider_grant_immutable BEFORE UPDATE ON ph17_assist.provider_grant FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('provider_id', 'change_id', 'granted_by');
CALL ph17_assist.p_enable_rls('ph17_assist.provider_grant');
COMMENT ON TABLE ph17_assist.provider_grant IS 'EN-17-04 Nhà cung cấp ngoài trong danh sách trắng của tenant (FR-17-003; BR-17-004). Chỉ thêm khi có đề nghị EXTERNAL_ON đã duyệt; gỡ ghi revoked_at, không xóa dòng. Mỗi nhà cung cấp một dòng còn hiệu lực.';
--rollback DROP TABLE IF EXISTS ph17_assist.provider_grant CASCADE;

--changeset ph17:ph17-0290-invocation-log
CREATE TABLE ph17_assist.invocation_log (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  occurred_at      timestamptz NOT NULL DEFAULT now(),
  capability       varchar(24) NOT NULL,
  model_version_id uuid NOT NULL,
  route_id         uuid,
  caller_kind      varchar(4) NOT NULL,
  caller_ref       varchar(64) NOT NULL,
  message_id       uuid,
  request_ref      varchar(64) NOT NULL,
  tokens_in        integer NOT NULL DEFAULT 0,
  tokens_out       integer NOT NULL DEFAULT 0,
  latency_ms       integer NOT NULL,
  first_token_ms   integer,
  result           varchar(10) NOT NULL,
  error_code       varchar(16),
  fallback_from_id uuid,
  est_cost         numeric(14,4) NOT NULL DEFAULT 0,
  trace_id         char(32) NOT NULL,
  CONSTRAINT pk_invocation_log PRIMARY KEY (id, occurred_at),
  CONSTRAINT ck_invocation_log_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_invocation_log_caller CHECK (caller_kind IN ('USER', 'DU')),
  CONSTRAINT ck_invocation_log_result CHECK (result IN ('OK', 'TIMEOUT', 'ERROR', 'BLOCKED', 'FALLBACK')),
  CONSTRAINT ck_invocation_log_counts CHECK (tokens_in >= 0 AND tokens_out >= 0 AND latency_ms >= 0 AND est_cost >= 0),
  CONSTRAINT ck_invocation_log_trace CHECK (trace_id ~ '^[0-9a-f]{32}$'),
  CONSTRAINT ck_invocation_log_fallback CHECK ((result = 'FALLBACK') = (fallback_from_id IS NOT NULL)),
  CONSTRAINT ck_invocation_log_error CHECK (result IN ('OK', 'FALLBACK') OR error_code IS NOT NULL OR result = 'BLOCKED')
) PARTITION BY RANGE (occurred_at);
CALL ph17_assist.p_ensure_partitions('ph17_assist.invocation_log', current_date, 3);
CREATE INDEX ix_invocation_log_model ON ph17_assist.invocation_log (tenant_id, model_version_id, occurred_at DESC);
CREATE INDEX ix_invocation_log_caller ON ph17_assist.invocation_log (tenant_id, caller_kind, caller_ref, occurred_at DESC);
CREATE INDEX ix_invocation_log_message ON ph17_assist.invocation_log (tenant_id, message_id) WHERE message_id IS NOT NULL;
CREATE TRIGGER tg_invocation_log_append_only BEFORE UPDATE OR DELETE ON ph17_assist.invocation_log FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_append_only();
CALL ph17_assist.p_enable_rls('ph17_assist.invocation_log');
COMMENT ON TABLE ph17_assist.invocation_log IS 'EN-17-14 Vết một lời gọi mô hình (FR-17-013; BR-17-022, 024, NFR-17-026): mô hình, phiên bản, năng lực, token vào ra, độ trễ, kết quả, người gọi. Không có cột nội dung (nội dung ở message đã che). Chỉ thêm; phân vùng tháng; giữ 13 tháng (giả định, Q17-50).';
COMMENT ON COLUMN ph17_assist.invocation_log.message_id IS 'Tham chiếu logic tới message (không khóa ngoại: nhật ký tồn tại lâu hơn hội thoại).';
COMMENT ON COLUMN ph17_assist.invocation_log.caller_ref IS 'Mã người dùng (sub) hoặc mã DU gọi data plane.';
--rollback DROP TABLE IF EXISTS ph17_assist.invocation_log CASCADE;

--changeset ph17:ph17-0300-model-health-probe
CREATE TABLE ph17_assist.model_health_probe (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  probed_at            timestamptz NOT NULL DEFAULT now(),
  version_id           uuid NOT NULL,
  probe_kind           varchar(10) NOT NULL DEFAULT 'SCHEDULED',
  state                varchar(14) NOT NULL,
  latency_ms           integer,
  consecutive_failures smallint NOT NULL DEFAULT 0,
  consecutive_ok       smallint NOT NULL DEFAULT 0,
  error_code           varchar(16),
  CONSTRAINT pk_model_health_probe PRIMARY KEY (id, probed_at),
  CONSTRAINT ck_model_health_probe_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_model_health_probe_kind CHECK (probe_kind IN ('SCHEDULED', 'MANUAL')),
  CONSTRAINT ck_model_health_probe_state CHECK (state IN ('HEALTHY', 'DEGRADED', 'DOWN', 'BREAKER_OPEN')),
  CONSTRAINT ck_model_health_probe_counts CHECK (consecutive_failures >= 0 AND consecutive_ok >= 0),
  CONSTRAINT ck_model_health_probe_down CHECK (state <> 'DOWN' OR consecutive_failures >= 3)
) PARTITION BY RANGE (probed_at);
CALL ph17_assist.p_ensure_partitions('ph17_assist.model_health_probe', current_date, 3);
CREATE INDEX ix_model_health_probe_version ON ph17_assist.model_health_probe (tenant_id, version_id, probed_at DESC);
CREATE TRIGGER tg_model_health_probe_append_only BEFORE UPDATE OR DELETE ON ph17_assist.model_health_probe FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_append_only();
CALL ph17_assist.p_enable_rls_common('ph17_assist.model_health_probe');
COMMENT ON TABLE ph17_assist.model_health_probe IS 'EN-17-15 Kết quả thăm dò sức khỏe mô hình (FR-17-014; BR-17-023): ba lần lỗi liên tiếp thì DOWN và mở cầu dao, hai lần đạt liên tiếp mới trở lại. Chỉ thêm; phân vùng tháng; giữ 3 tháng.';
COMMENT ON COLUMN ph17_assist.model_health_probe.state IS 'HEALTHY, DEGRADED, DOWN, BREAKER_OPEN theo Phụ lục A; FRS 9.3 và BR-17-023 còn dùng UP (Đề nghị đồng bộ).';
--rollback DROP TABLE IF EXISTS ph17_assist.model_health_probe CASCADE;

--changeset ph17:ph17-0310-model-breaker
CREATE TABLE ph17_assist.model_breaker (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  version_id    uuid NOT NULL,
  breaker_state varchar(10) NOT NULL DEFAULT 'CLOSED',
  error_rate    numeric(5,2),
  opened_at     timestamptz,
  retry_at      timestamptz,
  reset_by      varchar(64),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_model_breaker PRIMARY KEY (id),
  CONSTRAINT ck_model_breaker_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_model_breaker_version UNIQUE (tenant_id, version_id),
  CONSTRAINT ck_model_breaker_state CHECK (breaker_state IN ('CLOSED', 'OPEN', 'HALF_OPEN')),
  CONSTRAINT ck_model_breaker_rate CHECK (error_rate IS NULL OR error_rate BETWEEN 0 AND 100),
  CONSTRAINT ck_model_breaker_open CHECK (breaker_state = 'CLOSED' OR opened_at IS NOT NULL)
);
CREATE TRIGGER tg_model_breaker_touch BEFORE UPDATE ON ph17_assist.model_breaker FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls('ph17_assist.model_breaker');
COMMENT ON TABLE ph17_assist.model_breaker IS 'EN-17-44 (FR-17-012, 014; BR-17-021). Trạng thái cầu dao hiện hành của mỗi phiên bản mô hình: mở khi tỷ lệ lỗi vượt 17.breaker.error-rate trong cửa sổ 30 giây, tự thử lại sau 17.breaker.open-seconds; đóng thủ công qua API-17-055.';
--rollback DROP TABLE IF EXISTS ph17_assist.model_breaker CASCADE;
