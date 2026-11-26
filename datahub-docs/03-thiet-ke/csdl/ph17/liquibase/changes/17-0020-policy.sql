--liquibase formatted sql
-- Nguồn: ddl/ph17_assist.sql · 17-0020-policy.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph17:ph17-0140-ai-notice
CREATE TABLE ph17_assist.ai_notice (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  version_no   integer NOT NULL,
  title        varchar(255) NOT NULL,
  body_text    text NOT NULL,
  locale       varchar(8) NOT NULL DEFAULT 'vi',
  status       varchar(12) NOT NULL DEFAULT 'DRAFT',
  published_at timestamptz,
  published_by varchar(64),
  retired_at   timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_ai_notice PRIMARY KEY (id),
  CONSTRAINT uq_ai_notice_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_ai_notice_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_ai_notice_version UNIQUE (tenant_id, version_no),
  CONSTRAINT ck_ai_notice_version CHECK (version_no >= 1),
  CONSTRAINT ck_ai_notice_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
  CONSTRAINT ck_ai_notice_published CHECK ((status = 'DRAFT') OR (published_at IS NOT NULL AND published_by IS NOT NULL)),
  CONSTRAINT ck_ai_notice_retired CHECK ((status = 'RETIRED') = (retired_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_ai_notice_current ON ph17_assist.ai_notice (tenant_id) WHERE status = 'PUBLISHED';
CREATE TRIGGER tg_ai_notice_touch BEFORE UPDATE ON ph17_assist.ai_notice FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_ai_notice_frozen BEFORE UPDATE ON ph17_assist.ai_notice FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_frozen('PUBLISHED,RETIRED', 'title', 'body_text', 'locale', 'version_no');
CREATE TRIGGER tg_ai_notice_fsm_status BEFORE UPDATE ON ph17_assist.ai_notice FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('status', 'DRAFT>PUBLISHED,PUBLISHED>RETIRED');
CALL ph17_assist.p_enable_rls('ph17_assist.ai_notice');
COMMENT ON TABLE ph17_assist.ai_notice IS 'EN-17-05 Phiên bản điều khoản và thông báo minh bạch dùng AI (FR-17-005, BR-17-007). Phiên bản đã công bố (PUBLISHED) không sửa nội dung (ERR-17-024); công bố bản mới thì bản cũ chuyển RETIRED. Người dùng xác nhận bản đang PUBLISHED.';
COMMENT ON COLUMN ph17_assist.ai_notice.status IS 'DRAFT, PUBLISHED, RETIRED (NoticeStatus, Phụ lục A).';
--rollback DROP TABLE IF EXISTS ph17_assist.ai_notice CASCADE;

--changeset ph17:ph17-0150-notice-acceptance
CREATE TABLE ph17_assist.notice_acceptance (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  notice_id   uuid NOT NULL,
  user_id     varchar(64) NOT NULL,
  accepted_at timestamptz NOT NULL DEFAULT now(),
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_notice_acceptance PRIMARY KEY (id),
  CONSTRAINT ck_notice_acceptance_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_notice_acceptance_notice FOREIGN KEY (tenant_id, notice_id) REFERENCES ph17_assist.ai_notice (tenant_id, id),
  CONSTRAINT uq_notice_acceptance_user UNIQUE (tenant_id, notice_id, user_id)
);
CREATE INDEX ix_notice_acceptance_user ON ph17_assist.notice_acceptance (tenant_id, user_id, accepted_at DESC);
CREATE TRIGGER tg_notice_acceptance_touch BEFORE UPDATE ON ph17_assist.notice_acceptance FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_notice_acceptance_append_only BEFORE UPDATE OR DELETE ON ph17_assist.notice_acceptance FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_append_only();
CALL ph17_assist.p_enable_rls('ph17_assist.notice_acceptance');
COMMENT ON TABLE ph17_assist.notice_acceptance IS 'EN-17-06 Người dùng đã xác nhận phiên bản điều khoản nào, lúc nào (FR-17-005, BR-17-007). Chỉ thêm. Hết 17.notice.reaccept-days hoặc có phiên bản mới thì xác nhận lại bằng dòng mới.';
--rollback DROP TABLE IF EXISTS ph17_assist.notice_acceptance CASCADE;

--changeset ph17:ph17-0160-policy-change
CREATE TABLE ph17_assist.policy_change (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  change_type      varchar(16) NOT NULL,
  state            varchar(12) NOT NULL DEFAULT 'PENDING',
  payload          jsonb NOT NULL DEFAULT '{}',
  reason           varchar(2000) NOT NULL,
  decision_no      varchar(64),
  requested_by     varchar(64) NOT NULL,
  requested_at     timestamptz NOT NULL DEFAULT now(),
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  expires_at       timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_policy_change PRIMARY KEY (id),
  CONSTRAINT uq_policy_change_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_policy_change_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_policy_change_type CHECK (change_type IN ('ENABLE', 'EXTERNAL_ON', 'RESUME', 'SENSITIVE_PARAM')),
  CONSTRAINT ck_policy_change_state CHECK (state IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED', 'EXPIRED')),
  CONSTRAINT ck_policy_change_four_eyes CHECK (decided_by IS NULL OR (decided_by <> requested_by)),
  CONSTRAINT ck_policy_change_decided CHECK ((state IN ('APPROVED', 'REJECTED')) = (decided_by IS NOT NULL AND decided_at IS NOT NULL)),
  CONSTRAINT ck_policy_change_reject CHECK (state <> 'REJECTED' OR char_length(COALESCE(decision_comment, '')) >= 20),
  CONSTRAINT ck_policy_change_enable CHECK (change_type NOT IN ('ENABLE', 'RESUME') OR (decision_no IS NOT NULL AND char_length(reason) >= 20)),
  CONSTRAINT ck_policy_change_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_policy_change_payload CHECK (payload::text !~* '(bearer |openbao://|private key|password)')
);
CREATE UNIQUE INDEX uq_policy_change_pending ON ph17_assist.policy_change (tenant_id, change_type) WHERE state = 'PENDING';
CREATE INDEX ix_policy_change_state ON ph17_assist.policy_change (tenant_id, state, requested_at DESC);
CREATE TRIGGER tg_policy_change_touch BEFORE UPDATE ON ph17_assist.policy_change FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_policy_change_fsm_state BEFORE UPDATE ON ph17_assist.policy_change FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('state', 'PENDING>APPROVED,PENDING>REJECTED,PENDING>CANCELLED,PENDING>EXPIRED');
CREATE TRIGGER tg_policy_change_immutable BEFORE UPDATE ON ph17_assist.policy_change FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('change_type', 'requested_by', 'reason');
CALL ph17_assist.p_enable_rls('ph17_assist.policy_change');
COMMENT ON TABLE ph17_assist.policy_change IS 'EN-17-02 Đề nghị đổi chính sách cần bốn mắt (FR-17-001, 003, 006, 059; BR-17-002, 004, 008, 010): ENABLE, EXTERNAL_ON, RESUME, SENSITIVE_PARAM. Người duyệt khác người đề nghị (ERR-17-005); mỗi loại chỉ một đề nghị PENDING (ERR-17-013); bật cần số quyết định và lý do (ERR-17-014).';
COMMENT ON COLUMN ph17_assist.policy_change.decision_no IS 'Số quyết định của lãnh đạo tỉnh (bắt buộc khi ENABLE, RESUME).';
COMMENT ON COLUMN ph17_assist.policy_change.payload IS 'Giá trị đề nghị (ví dụ khóa 17.* và giá trị mới); không bí mật.';
--rollback DROP TABLE IF EXISTS ph17_assist.policy_change CASCADE;

--changeset ph17:ph17-0170-tenant-policy
CREATE TABLE ph17_assist.tenant_policy (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  assist_state       varchar(12) NOT NULL DEFAULT 'DISABLED',
  enable_decision_no varchar(64),
  enable_reason      varchar(2000),
  enabled_change_id  uuid,
  enabled_at         timestamptz,
  enabled_by         varchar(64),
  disabled_at        timestamptz,
  external_allowed   boolean NOT NULL DEFAULT false,
  external_change_id uuid,
  current_notice_id  uuid,
  killed_at          timestamptz,
  killed_by          varchar(64),
  kill_reason        varchar(2000),
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_policy PRIMARY KEY (id),
  CONSTRAINT uq_tenant_policy_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_tenant_policy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_tenant_policy_tenant UNIQUE (tenant_id),
  CONSTRAINT ck_tenant_policy_state CHECK (assist_state IN ('DISABLED', 'ENABLED', 'KILLED')),
  CONSTRAINT fk_tenant_policy_enabled_change FOREIGN KEY (tenant_id, enabled_change_id) REFERENCES ph17_assist.policy_change (tenant_id, id),
  CONSTRAINT fk_tenant_policy_external_change FOREIGN KEY (tenant_id, external_change_id) REFERENCES ph17_assist.policy_change (tenant_id, id),
  CONSTRAINT fk_tenant_policy_current_notice FOREIGN KEY (tenant_id, current_notice_id) REFERENCES ph17_assist.ai_notice (tenant_id, id),
  CONSTRAINT ck_tenant_policy_enabled CHECK (assist_state <> 'ENABLED' OR (enable_decision_no IS NOT NULL AND enabled_at IS NOT NULL AND enabled_by IS NOT NULL AND enabled_change_id IS NOT NULL)),
  CONSTRAINT ck_tenant_policy_killed CHECK ((assist_state = 'KILLED') = (killed_at IS NOT NULL)),
  CONSTRAINT ck_tenant_policy_external CHECK (NOT external_allowed OR external_change_id IS NOT NULL)
);
CREATE TRIGGER tg_tenant_policy_touch BEFORE UPDATE ON ph17_assist.tenant_policy FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_tenant_policy_fsm_assist_state BEFORE UPDATE ON ph17_assist.tenant_policy FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_transition('assist_state', 'DISABLED>ENABLED,ENABLED>DISABLED,ENABLED>KILLED,DISABLED>KILLED,KILLED>DISABLED');
CALL ph17_assist.p_enable_rls('ph17_assist.tenant_policy');
COMMENT ON TABLE ph17_assist.tenant_policy IS 'EN-17-01 Chính sách của tenant, một dòng mỗi tenant (FR-17-001, 003, 006; BR-17-001, 002, 004, 008). assist_state DISABLED mặc định; ENABLED cần số quyết định; KILLED chỉ gỡ về DISABLED (máy trạng thái FRS 4.7). Cho phép mô hình ngoài cần đề nghị EXTERNAL_ON đã duyệt.';
COMMENT ON COLUMN ph17_assist.tenant_policy.enabled_change_id IS 'Đề nghị ENABLE đã duyệt bốn mắt (BR-17-002).';
COMMENT ON COLUMN ph17_assist.tenant_policy.external_change_id IS 'Đề nghị EXTERNAL_ON đã duyệt bốn mắt (BR-17-004).';
--rollback DROP TABLE IF EXISTS ph17_assist.tenant_policy CASCADE;

--changeset ph17:ph17-0180-capability-policy
CREATE TABLE ph17_assist.capability_policy (
  id         uuid NOT NULL,
  tenant_id  varchar(16) NOT NULL,
  capability varchar(16) NOT NULL,
  role_group varchar(32) NOT NULL DEFAULT 'ALL_READERS',
  enabled    boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by varchar(64) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by varchar(64) NOT NULL,
  version    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_capability_policy PRIMARY KEY (id),
  CONSTRAINT ck_capability_policy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_capability_policy UNIQUE (tenant_id, capability, role_group),
  CONSTRAINT ck_capability_policy_capability CHECK (capability IN ('SEARCH', 'MAPPING', 'EXPLAIN')),
  CONSTRAINT ck_capability_policy_role_group CHECK (role_group ~ '^[A-Z][A-Z0-9_]{1,31}$')
);
CREATE TRIGGER tg_capability_policy_touch BEFORE UPDATE ON ph17_assist.capability_policy FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls('ph17_assist.capability_policy');
COMMENT ON TABLE ph17_assist.capability_policy IS 'EN-17-03 Năng lực bật cho từng nhóm vai trò (FR-17-002, BR-17-003): SEARCH, MAPPING, EXPLAIN. Dùng được khi trợ lý bật, 17.feature.* bật và nhóm vai trò được phép (ERR-17-011).';
--rollback DROP TABLE IF EXISTS ph17_assist.capability_policy CASCADE;

--changeset ph17:ph17-0190-quota-usage
CREATE TABLE ph17_assist.quota_usage (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  usage_date       date NOT NULL,
  scope_kind       varchar(8) NOT NULL,
  subject_ref      varchar(64) NOT NULL,
  capability       varchar(24) NOT NULL DEFAULT 'ALL',
  model_version_id uuid,
  turns            integer NOT NULL DEFAULT 0,
  blocked_turns    integer NOT NULL DEFAULT 0,
  tokens_in        bigint NOT NULL DEFAULT 0,
  tokens_out       bigint NOT NULL DEFAULT 0,
  est_cost         numeric(14,2) NOT NULL DEFAULT 0,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_quota_usage PRIMARY KEY (id),
  CONSTRAINT ck_quota_usage_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_quota_usage_scope CHECK (scope_kind IN ('USER', 'TENANT', 'DU')),
  CONSTRAINT ck_quota_usage_counts CHECK (turns >= 0 AND blocked_turns >= 0 AND tokens_in >= 0 AND tokens_out >= 0 AND est_cost >= 0),
  CONSTRAINT ck_quota_usage_capability CHECK (capability = 'ALL' OR capability IN ('SEARCH', 'MAPPING', 'EXPLAIN') OR capability IN ('CLASSIFY_TEXT', 'EXTRACT_FIELDS', 'SUGGEST_STEP', 'EMBED', 'RERANK'))
);
CREATE UNIQUE INDEX uq_quota_usage_bucket ON ph17_assist.quota_usage (tenant_id, usage_date, scope_kind, subject_ref, capability, COALESCE(model_version_id, '00000000-0000-0000-0000-000000000000'::uuid));
CREATE INDEX ix_quota_usage_date ON ph17_assist.quota_usage (usage_date);
CREATE TRIGGER tg_quota_usage_touch BEFORE UPDATE ON ph17_assist.quota_usage FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls('ph17_assist.quota_usage');
COMMENT ON TABLE ph17_assist.quota_usage IS 'EN-17-07 Số lượt và token đã dùng theo ngày (FR-17-004, 058; BR-17-005, 024): theo người dùng, theo tenant, theo DU gọi data plane. dh-assist cộng dồn trước và sau lời gọi mô hình; vượt hạn mức thì 429 không gọi mô hình. Giữ 400 ngày.';
COMMENT ON COLUMN ph17_assist.quota_usage.subject_ref IS 'Mã người dùng (sub), mã tenant hoặc mã DU gọi; không tên người.';
COMMENT ON COLUMN ph17_assist.quota_usage.est_cost IS 'Ước tính token nhân đơn giá phiên bản (BR-17-024), không dùng thanh toán.';
--rollback DROP TABLE IF EXISTS ph17_assist.quota_usage CASCADE;

--changeset ph17:ph17-0200-kill-switch-record
CREATE TABLE ph17_assist.kill_switch_record (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  scope                varchar(8) NOT NULL,
  target_tenants       varchar(16)[],
  reason               varchar(2000) NOT NULL,
  activated_by         varchar(64) NOT NULL,
  activated_at         timestamptz NOT NULL DEFAULT now(),
  propagated_at        timestamptz,
  release_requested_by varchar(64),
  release_requested_at timestamptz,
  release_reason       varchar(2000),
  released_by          varchar(64),
  released_at          timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kill_switch_record PRIMARY KEY (id),
  CONSTRAINT ck_kill_switch_record_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_kill_switch_record_scope CHECK (scope IN ('TENANT', 'PLATFORM')),
  CONSTRAINT ck_kill_switch_record_scope_tenant CHECK ((scope = 'PLATFORM') = (tenant_id = 'COMMON')),
  CONSTRAINT ck_kill_switch_record_reason CHECK (char_length(reason) >= 20),
  CONSTRAINT ck_kill_switch_record_release_req CHECK ((release_requested_by IS NULL) = (release_requested_at IS NULL)),
  CONSTRAINT ck_kill_switch_record_released CHECK ((released_by IS NULL) = (released_at IS NULL) AND (released_by IS NULL OR (release_requested_by IS NOT NULL AND released_by <> release_requested_by))),
  CONSTRAINT ck_kill_switch_record_propagation CHECK (propagated_at IS NULL OR propagated_at <= activated_at + interval '60 seconds')
);
CREATE UNIQUE INDEX uq_kill_switch_active ON ph17_assist.kill_switch_record (tenant_id, scope) WHERE released_at IS NULL;
CREATE TRIGGER tg_kill_switch_record_touch BEFORE UPDATE ON ph17_assist.kill_switch_record FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_kill_switch_record_immutable BEFORE UPDATE ON ph17_assist.kill_switch_record FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('scope', 'reason', 'activated_by', 'activated_at');
CALL ph17_assist.p_enable_rls_common('ph17_assist.kill_switch_record');
COMMENT ON TABLE ph17_assist.kill_switch_record IS 'EN-17-08 Một lần tắt khẩn (FR-17-006, BR-17-008): phạm vi TENANT hoặc PLATFORM (tenant_id COMMON), lý do, người kích hoạt. Chỉ cần lý do để tắt; gỡ cần người đề nghị và người duyệt khác nhau. Gỡ đưa tenant về DISABLED, không tự ENABLED.';
COMMENT ON COLUMN ph17_assist.kill_switch_record.propagated_at IS 'Thời điểm mọi thành phần xác nhận đã chặn; chỉ tiêu ≤ 60 giây (NFR-17-004).';
COMMENT ON COLUMN ph17_assist.kill_switch_record.target_tenants IS 'Nhóm tenant của lần tắt nền tảng; NULL là toàn bộ.';
--rollback DROP TABLE IF EXISTS ph17_assist.kill_switch_record CASCADE;
