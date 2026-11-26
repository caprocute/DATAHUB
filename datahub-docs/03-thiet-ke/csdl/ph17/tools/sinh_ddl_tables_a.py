"""Khai báo bảng nhóm A (lõi, chính sách, mô hình) của ph17_assist."""
from sinh_ddl_core import *


def TU(name, comment, cols, grant, jobdel, **kw):
    t = T(name, comment, cols, rls="user", **kw)
    t["user_grant"], t["user_job_delete"] = grant, jobdel
    return t


NOSECRET = "payload::text !~* '(bearer |openbao://|private key|password)'"

# ---------------------------------------------------------------------------------------------
# 17-0010 Lõi: tệp, outbox, inbox, tham số
# ---------------------------------------------------------------------------------------------
G_CORE = []
G_CORE.append(T("file_object",
    "EN-17-39 Tham chiếu đối tượng tệp (DD-12) cho tài liệu tải lên (FR-17-020), hồ sơ cam kết nhà cung cấp (FR-17-003, 007) và gói bằng chứng tuân thủ (FR-17-057). Nội dung nằm ở kho đối tượng; chỉ tệp quét sạch (CLEAN) mới được dùng. Không bí mật, không nội dung hội thoại.",
    ["bucket varchar(64) NOT NULL", "object_key text NOT NULL", "file_name varchar(255) NOT NULL", "content_type varchar(127) NOT NULL", "size_bytes bigint NOT NULL",
     "sha256 char(64) NOT NULL", "scan_status varchar(16) NOT NULL DEFAULT 'PENDING'", "data_class varchar(16) NOT NULL DEFAULT 'INTERNAL'", "purpose varchar(24) NOT NULL",
     "expires_at timestamptz"],
    [("uq_file_object_key", "UNIQUE (bucket, object_key)"),
     chk("file_object", "size", "size_bytes >= 0"), chk("file_object", "sha", "sha256 ~ '^[0-9a-f]{64}$'"),
     chk("file_object", "scan", "scan_status IN ('PENDING', 'CLEAN', 'INFECTED')"),
     chk("file_object", "class", f"data_class IN {E('ClassLevel', only=('PUBLIC', 'INTERNAL'))}"),
     chk("file_object", "purpose", "purpose IN ('UPLOAD_SOURCE', 'COMMITMENT', 'COMPLIANCE_PACK', 'USAGE_REPORT')"),
     chk("file_object", "ctype", "content_type IN ('application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/markdown', 'text/plain', 'application/zip', 'text/csv')")],
    idx=[f"CREATE INDEX ix_file_object_expires ON {S}.file_object (expires_at) WHERE expires_at IS NOT NULL;"],
    tid=True, trig=[("immutable", ["bucket", "object_key", "sha256", "size_bytes"])], rls="common",
    ccomment={"data_class": "Chỉ PUBLIC hoặc INTERNAL: PH-17 không nhận tệp mức cao hơn (BR-17-026, 030).",
              "purpose": "UPLOAD_SOURCE tài liệu tải lên, COMMITMENT hồ sơ cam kết nhà cung cấp, COMPLIANCE_PACK gói bằng chứng, USAGE_REPORT báo cáo sử dụng."}))

# Khóa có chữ "token" xếp cuối danh sách: tránh máy quét bí mật (gitleaks generic-api-key) đọc
# khóa đứng sau thành "giá trị" của một từ khóa token; thứ tự trong CHECK không mang nghĩa.
_keys = ", ".join("'%s'" % k for k in sorted((k for k, *_ in SETTINGS), key=lambda k: "token" in k))
G_CORE.append(T("tenant_setting",
    "EN-17-40 Bản chụp tham số 17.* của tenant (FRS 8.2, FR-17-059, BR-17-078). Nguồn chuẩn là PH-18 (DD-14); dh-assist đọc có đệm 30 giây và giữ bản chụp này để kiểm miền, sàn, trần khi ghi và để cổng phát hành đọc điểm tối thiểu. Khóa đổi bốn mắt đánh dấu four_eyes.",
    ["setting_key varchar(48) NOT NULL", "value jsonb NOT NULL", "floor_value jsonb", "ceiling_value jsonb", "four_eyes boolean NOT NULL DEFAULT false", "synced_at timestamptz"],
    [("uq_tenant_setting_key", "UNIQUE (tenant_id, setting_key)"),
     chk("tenant_setting", "key", f"setting_key IN ({_keys})"),
     chk("tenant_setting", "bounds", "jsonb_typeof(value) <> 'number' OR ((floor_value IS NULL OR value >= floor_value) AND (ceiling_value IS NULL OR value <= ceiling_value))"),
     chk("tenant_setting", "retention_floor", "setting_key <> '17.log.retention-days' OR (jsonb_typeof(value) = 'number' AND value >= '90'::jsonb)"),
     chk("tenant_setting", "redteam_floor", "setting_key <> '17.redteam.min-pass-rate' OR value = '100'::jsonb")],
    trig=[("immutable", ["setting_key"])],
    ccomment={"synced_at": "Lần đồng bộ cuối từ PH-18 DD-14."}))

OUTBOX = ", ".join("'%s'" % t for t in TOPICS)
G_CORE.append(T("outbox_event",
    "EN-17-39 Outbox (DD-11, ADR-042) cho EVT-17-01…28. Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL. Sự kiện chỉ mang mã, trạng thái, số đếm, thời điểm: CHECK chặn khóa nội dung hội thoại, đoạn tri thức, bí mật (BR-17-022, 073). Dọn sau 3 ngày.",
    ["event_id uuid NOT NULL", "tenant_id varchar(16) NOT NULL", "event_type varchar(128) NOT NULL", "topic varchar(249) NOT NULL", "aggregate_type varchar(64) NOT NULL",
     "aggregate_id varchar(255) NOT NULL", "partition_key varchar(255) NOT NULL", "payload jsonb NOT NULL", "trace_id char(32) NOT NULL", "occurred_at timestamptz NOT NULL DEFAULT now()"],
    [("pk_outbox_event", "PRIMARY KEY (event_id)"),
     chk("outbox_event", "tenant", f"tenant_id ~ '{TENANT_RE}'"),
     chk("outbox_event", "prefix", "split_part(topic, '.', 1) = lower(tenant_id)"),
     chk("outbox_event", "topic", f"substr(topic, length(split_part(topic, '.', 1)) + 2) IN ({OUTBOX})"),
     chk("outbox_event", "trace", "trace_id ~ '^[0-9a-f]{32}$'"),
     chk("outbox_event", "no_content", "NOT (payload ?| ARRAY['content', 'prompt', 'answer', 'question', 'text', 'chunk', 'embedding', 'secret', 'secret_ref', 'token', 'tokens', 'message', 'value', 'values'])")],
    idx=[f"CREATE INDEX ix_outbox_event_occurred ON {S}.outbox_event (occurred_at);"], std=False, nopk=True))

G_CORE.append(T("inbox_event",
    "EN-17-41 Inbox chống xử lý trùng cho sự kiện PH-17 tiêu thụ (at-least-once): catalog.api.*, rdm.catalog.*, integration.flow.*, event.publication.*, privacy.classification.changed, privacy.contract-level.changed, privacy.dataset.status-changed, gateway.snapshot.* (FRS 9.3b). Khóa (consumer, event_id). Dọn sau 7 ngày.",
    ["tenant_id varchar(16) NOT NULL", "consumer varchar(64) NOT NULL", "event_id varchar(255) NOT NULL", "source_topic varchar(249) NOT NULL", "event_type varchar(255) NOT NULL",
     "received_at timestamptz NOT NULL DEFAULT now()", "processed_at timestamptz", "outcome varchar(2000)"],
    [("pk_inbox_event", "PRIMARY KEY (tenant_id, consumer, event_id)"),
     chk("inbox_event", "tenant", f"tenant_id ~ '{TENANT_RE}'"),
     chk("inbox_event", "consumer", "consumer ~ '^[A-Z][A-Za-z0-9]+$'"),
     chk("inbox_event", "prefix", "split_part(source_topic, '.', 1) = lower(tenant_id)")],
    idx=[f"CREATE INDEX ix_inbox_event_received ON {S}.inbox_event (received_at);"], std=False, nopk=True))

# ---------------------------------------------------------------------------------------------
# 17-0020 Chính sách theo tenant
# ---------------------------------------------------------------------------------------------
G_POL = []
G_POL.append(T("ai_notice",
    "EN-17-05 Phiên bản điều khoản và thông báo minh bạch dùng AI (FR-17-005, BR-17-007). Phiên bản đã công bố (PUBLISHED) không sửa nội dung (ERR-17-024); công bố bản mới thì bản cũ chuyển RETIRED. Người dùng xác nhận bản đang PUBLISHED.",
    ["version_no integer NOT NULL", "title varchar(255) NOT NULL", "body_text text NOT NULL", "locale varchar(8) NOT NULL DEFAULT 'vi'", "status varchar(12) NOT NULL DEFAULT 'DRAFT'",
     "published_at timestamptz", "published_by varchar(64)", "retired_at timestamptz"],
    [("uq_ai_notice_version", "UNIQUE (tenant_id, version_no)"), chk("ai_notice", "version", "version_no >= 1"),
     chk("ai_notice", "status", f"status IN {X('DRAFT', 'PUBLISHED', 'RETIRED')}"),
     chk("ai_notice", "published", "(status = 'DRAFT') OR (published_at IS NOT NULL AND published_by IS NOT NULL)"),
     chk("ai_notice", "retired", "(status = 'RETIRED') = (retired_at IS NOT NULL)")],
    idx=[f"CREATE UNIQUE INDEX uq_ai_notice_current ON {S}.ai_notice (tenant_id) WHERE status = 'PUBLISHED';"],
    tid=True, trig=[("frozen", ["PUBLISHED,RETIRED", "title", "body_text", "locale", "version_no"]),
                    ("transition", ["status", "DRAFT>PUBLISHED,PUBLISHED>RETIRED"])],
    ccomment={"status": "DRAFT, PUBLISHED, RETIRED (NoticeStatus, Phụ lục A)."}))

G_POL.append(T("notice_acceptance",
    "EN-17-06 Người dùng đã xác nhận phiên bản điều khoản nào, lúc nào (FR-17-005, BR-17-007). Chỉ thêm. Hết 17.notice.reaccept-days hoặc có phiên bản mới thì xác nhận lại bằng dòng mới.",
    ["notice_id uuid NOT NULL", "user_id varchar(64) NOT NULL", "accepted_at timestamptz NOT NULL DEFAULT now()"],
    [fk("notice_acceptance", "notice_id", "ai_notice"), ("uq_notice_acceptance_user", "UNIQUE (tenant_id, notice_id, user_id)")],
    idx=[f"CREATE INDEX ix_notice_acceptance_user ON {S}.notice_acceptance (tenant_id, user_id, accepted_at DESC);"],
    trig=[("append_only", [])]))

G_POL.append(T("policy_change",
    "EN-17-02 Đề nghị đổi chính sách cần bốn mắt (FR-17-001, 003, 006, 059; BR-17-002, 004, 008, 010): ENABLE, EXTERNAL_ON, RESUME, SENSITIVE_PARAM. Người duyệt khác người đề nghị (ERR-17-005); mỗi loại chỉ một đề nghị PENDING (ERR-17-013); bật cần số quyết định và lý do (ERR-17-014).",
    ["change_type varchar(16) NOT NULL", "state varchar(12) NOT NULL DEFAULT 'PENDING'", "payload jsonb NOT NULL DEFAULT '{}'", "reason varchar(2000) NOT NULL", "decision_no varchar(64)",
     "requested_by varchar(64) NOT NULL", "requested_at timestamptz NOT NULL DEFAULT now()", "decided_by varchar(64)", "decided_at timestamptz", "decision_comment varchar(2000)",
     "expires_at timestamptz"],
    [chk("policy_change", "type", f"change_type IN {E('PolicyChangeType')}"), chk("policy_change", "state", f"state IN {E('PolicyChangeState')}"),
     four_eyes("policy_change", "decided_by", "requested_by"),
     chk("policy_change", "decided", "(state IN ('APPROVED', 'REJECTED')) = (decided_by IS NOT NULL AND decided_at IS NOT NULL)"),
     chk("policy_change", "reject", "state <> 'REJECTED' OR char_length(COALESCE(decision_comment, '')) >= 20"),
     chk("policy_change", "enable", "change_type NOT IN ('ENABLE', 'RESUME') OR (decision_no IS NOT NULL AND char_length(reason) >= 20)"),
     chk("policy_change", "reason", "char_length(reason) >= 20"),
     chk("policy_change", "payload", NOSECRET)],
    idx=[f"CREATE UNIQUE INDEX uq_policy_change_pending ON {S}.policy_change (tenant_id, change_type) WHERE state = 'PENDING';",
         f"CREATE INDEX ix_policy_change_state ON {S}.policy_change (tenant_id, state, requested_at DESC);"],
    tid=True, trig=[("transition", ["state", "PENDING>APPROVED,PENDING>REJECTED,PENDING>CANCELLED,PENDING>EXPIRED"]),
                    ("immutable", ["change_type", "requested_by", "reason"])],
    ccomment={"decision_no": "Số quyết định của lãnh đạo tỉnh (bắt buộc khi ENABLE, RESUME).",
              "payload": "Giá trị đề nghị (ví dụ khóa 17.* và giá trị mới); không bí mật."}))

G_POL.append(T("tenant_policy",
    "EN-17-01 Chính sách của tenant, một dòng mỗi tenant (FR-17-001, 003, 006; BR-17-001, 002, 004, 008). assist_state DISABLED mặc định; ENABLED cần số quyết định; KILLED chỉ gỡ về DISABLED (máy trạng thái FRS 4.7). Cho phép mô hình ngoài cần đề nghị EXTERNAL_ON đã duyệt.",
    ["assist_state varchar(12) NOT NULL DEFAULT 'DISABLED'", "enable_decision_no varchar(64)", "enable_reason varchar(2000)", "enabled_change_id uuid", "enabled_at timestamptz",
     "enabled_by varchar(64)", "disabled_at timestamptz", "external_allowed boolean NOT NULL DEFAULT false", "external_change_id uuid", "current_notice_id uuid",
     "killed_at timestamptz", "killed_by varchar(64)", "kill_reason varchar(2000)"],
    [("uq_tenant_policy_tenant", "UNIQUE (tenant_id)"), chk("tenant_policy", "state", f"assist_state IN {E('TenantAssistState')}"),
     fk("tenant_policy", "enabled_change_id", "policy_change"), fk("tenant_policy", "external_change_id", "policy_change"), fk("tenant_policy", "current_notice_id", "ai_notice"),
     chk("tenant_policy", "enabled", "assist_state <> 'ENABLED' OR (enable_decision_no IS NOT NULL AND enabled_at IS NOT NULL AND enabled_by IS NOT NULL AND enabled_change_id IS NOT NULL)"),
     chk("tenant_policy", "killed", "(assist_state = 'KILLED') = (killed_at IS NOT NULL)"),
     chk("tenant_policy", "external", "NOT external_allowed OR external_change_id IS NOT NULL")],
    tid=True, trig=[("transition", ["assist_state", "DISABLED>ENABLED,ENABLED>DISABLED,ENABLED>KILLED,DISABLED>KILLED,KILLED>DISABLED"])],
    ccomment={"enabled_change_id": "Đề nghị ENABLE đã duyệt bốn mắt (BR-17-002).", "external_change_id": "Đề nghị EXTERNAL_ON đã duyệt bốn mắt (BR-17-004)."}))

G_POL.append(T("capability_policy",
    "EN-17-03 Năng lực bật cho từng nhóm vai trò (FR-17-002, BR-17-003): SEARCH, MAPPING, EXPLAIN. Dùng được khi trợ lý bật, 17.feature.* bật và nhóm vai trò được phép (ERR-17-011).",
    ["capability varchar(16) NOT NULL", "role_group varchar(32) NOT NULL DEFAULT 'ALL_READERS'", "enabled boolean NOT NULL DEFAULT false"],
    [("uq_capability_policy", "UNIQUE (tenant_id, capability, role_group)"), chk("capability_policy", "capability", f"capability IN {E('Capability')}"),
     chk("capability_policy", "role_group", "role_group ~ '^[A-Z][A-Z0-9_]{1,31}$'")]))

G_POL.append(T("quota_usage",
    "EN-17-07 Số lượt và token đã dùng theo ngày (FR-17-004, 058; BR-17-005, 024): theo người dùng, theo tenant, theo DU gọi data plane. dh-assist cộng dồn trước và sau lời gọi mô hình; vượt hạn mức thì 429 không gọi mô hình. Giữ 400 ngày.",
    ["usage_date date NOT NULL", "scope_kind varchar(8) NOT NULL", "subject_ref varchar(64) NOT NULL", "capability varchar(24) NOT NULL DEFAULT 'ALL'", "model_version_id uuid",
     "turns integer NOT NULL DEFAULT 0", "blocked_turns integer NOT NULL DEFAULT 0", "tokens_in bigint NOT NULL DEFAULT 0", "tokens_out bigint NOT NULL DEFAULT 0",
     "est_cost numeric(14,2) NOT NULL DEFAULT 0"],
    [chk("quota_usage", "scope", "scope_kind IN ('USER', 'TENANT', 'DU')"),
     chk("quota_usage", "counts", "turns >= 0 AND blocked_turns >= 0 AND tokens_in >= 0 AND tokens_out >= 0 AND est_cost >= 0"),
     chk("quota_usage", "capability", f"capability = 'ALL' OR capability IN {E('Capability')} OR capability IN {X('CLASSIFY_TEXT', 'EXTRACT_FIELDS', 'SUGGEST_STEP', 'EMBED', 'RERANK')}")],
    idx=[f"CREATE UNIQUE INDEX uq_quota_usage_bucket ON {S}.quota_usage (tenant_id, usage_date, scope_kind, subject_ref, capability, COALESCE(model_version_id, '00000000-0000-0000-0000-000000000000'::uuid));",
         f"CREATE INDEX ix_quota_usage_date ON {S}.quota_usage (usage_date);"],
    ccomment={"subject_ref": "Mã người dùng (sub), mã tenant hoặc mã DU gọi; không tên người.", "est_cost": "Ước tính token nhân đơn giá phiên bản (BR-17-024), không dùng thanh toán."}))

G_POL.append(T("kill_switch_record",
    "EN-17-08 Một lần tắt khẩn (FR-17-006, BR-17-008): phạm vi TENANT hoặc PLATFORM (tenant_id COMMON), lý do, người kích hoạt. Chỉ cần lý do để tắt; gỡ cần người đề nghị và người duyệt khác nhau. Gỡ đưa tenant về DISABLED, không tự ENABLED.",
    ["scope varchar(8) NOT NULL", "target_tenants varchar(16)[]", "reason varchar(2000) NOT NULL", "activated_by varchar(64) NOT NULL", "activated_at timestamptz NOT NULL DEFAULT now()",
     "propagated_at timestamptz", "release_requested_by varchar(64)", "release_requested_at timestamptz", "release_reason varchar(2000)", "released_by varchar(64)", "released_at timestamptz"],
    [chk("kill_switch_record", "scope", f"scope IN {E('KillScope')}"),
     chk("kill_switch_record", "scope_tenant", "(scope = 'PLATFORM') = (tenant_id = 'COMMON')"),
     chk("kill_switch_record", "reason", reason20()),
     chk("kill_switch_record", "release_req", "(release_requested_by IS NULL) = (release_requested_at IS NULL)"),
     chk("kill_switch_record", "released", "(released_by IS NULL) = (released_at IS NULL) AND (released_by IS NULL OR (release_requested_by IS NOT NULL AND released_by <> release_requested_by))"),
     chk("kill_switch_record", "propagation", "propagated_at IS NULL OR propagated_at <= activated_at + interval '60 seconds'")],
    idx=[f"CREATE UNIQUE INDEX uq_kill_switch_active ON {S}.kill_switch_record (tenant_id, scope) WHERE released_at IS NULL;"],
    rls="common", trig=[("immutable", ["scope", "reason", "activated_by", "activated_at"])],
    ccomment={"propagated_at": "Thời điểm mọi thành phần xác nhận đã chặn; chỉ tiêu ≤ 60 giây (NFR-17-004).", "target_tenants": "Nhóm tenant của lần tắt nền tảng; NULL là toàn bộ."}))

# ---------------------------------------------------------------------------------------------
# 17-0030 Cổng mô hình và sổ mô hình
# ---------------------------------------------------------------------------------------------
G_MODEL = []
G_MODEL.append(T("model_provider",
    "EN-17-09 Nhà cung cấp mô hình dùng chung do PA khai báo, tenant_id COMMON (FR-17-007; BR-17-011, 012, 013). INTERNAL (vLLM trong cụm) hoặc EXTERNAL: điểm cuối HTTPS theo tên miền, vùng lưu dữ liệu VN, có secret_ref tới OpenBao, không lưu bí mật. ACTIVE với EXTERNAL cần cam kết còn hiệu lực.",
    ["provider_code varchar(32) NOT NULL", "name varchar(255) NOT NULL", "provider_kind varchar(8) NOT NULL", "protocol varchar(24) NOT NULL DEFAULT 'OPENAI_COMPATIBLE'",
     "endpoint_url varchar(512) NOT NULL", "data_region varchar(8) NOT NULL DEFAULT 'VN'", "secret_ref varchar(255)", "status varchar(12) NOT NULL DEFAULT 'DRAFT'",
     "commitment_valid_to date", "suspended_reason varchar(2000)", "retired_at timestamptz"],
    [("uq_model_provider_code", "UNIQUE (tenant_id, provider_code)"), chk("model_provider", "common", "tenant_id = 'COMMON'"),
     chk("model_provider", "code", "provider_code ~ '^[A-Z][A-Z0-9-]{2,31}$'"),
     chk("model_provider", "kind", f"provider_kind IN {E('ProviderKind')}"), chk("model_provider", "status", f"status IN {E('ProviderStatus')}"),
     chk("model_provider", "protocol", "protocol IN ('OPENAI_COMPATIBLE', 'ANTHROPIC_MESSAGES', 'CUSTOM_HTTP')"),
     chk("model_provider", "secret_ref", "secret_ref IS NULL OR secret_ref ~ '^openbao://kv/[A-Za-z0-9/_.-]{3,200}$'"),
     chk("model_provider", "external_https", "provider_kind <> 'EXTERNAL' OR (endpoint_url ~ '^https://[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+(:[0-9]{2,5})?(/.*)?$' AND endpoint_url !~ '^https://[0-9.]+([:/]|$)' AND endpoint_url !~ '(localhost|169\\.254|\\.internal|\\.local)')"),
     chk("model_provider", "external_region", "provider_kind <> 'EXTERNAL' OR (data_region = 'VN' AND secret_ref IS NOT NULL)"),
     chk("model_provider", "external_active", "provider_kind <> 'EXTERNAL' OR status NOT IN ('ACTIVE') OR commitment_valid_to IS NOT NULL"),
     chk("model_provider", "suspended", "status <> 'SUSPENDED' OR suspended_reason IS NOT NULL"),
     chk("model_provider", "retired", "(status = 'RETIRED') = (retired_at IS NOT NULL)")],
    rls="common", trig=[("immutable", ["provider_code", "provider_kind"]),
                        ("transition", ["status", "DRAFT>ACTIVE,ACTIVE>SUSPENDED,SUSPENDED>ACTIVE,ACTIVE>RETIRED,SUSPENDED>RETIRED,DRAFT>RETIRED"])],
    ccomment={"secret_ref": "Tham chiếu OpenBao dạng openbao://kv/... ; không lưu giá trị bí mật (BR-17-011).",
              "data_region": "Vùng lưu dữ liệu của nhà cung cấp; EXTERNAL phải là VN (SEC-49, Luật An ninh mạng 116/2025).",
              "commitment_valid_to": "Ngày hết hạn của cam kết hiện hành (bản sao từ provider_commitment); hết hạn thì tự SUSPENDED (BR-17-013)."}))

G_MODEL.append(T("provider_commitment",
    "EN-17-42 (FR-17-003, 007; BR-17-013). Cam kết của nhà cung cấp ngoài về lưu dữ liệu trong nước và không dùng dữ liệu huấn luyện: số văn bản, tệp đính kèm, hiệu lực. Cả hai cam kết phải đúng (ERR-17-026).",
    ["provider_id uuid NOT NULL", "doc_no varchar(64) NOT NULL", "doc_date date NOT NULL", "valid_from date NOT NULL", "valid_to date NOT NULL", "domestic_storage boolean NOT NULL",
     "no_training boolean NOT NULL", "file_id uuid NOT NULL", "state varchar(12) NOT NULL DEFAULT 'ACTIVE'"],
    [fk1("provider_commitment", "provider_id", "model_provider"), fk("provider_commitment", "file_id", "file_object"),
     chk("provider_commitment", "pledge", "domestic_storage AND no_training"), chk("provider_commitment", "period", "valid_to > valid_from"),
     chk("provider_commitment", "state", f"state IN {X('ACTIVE', 'EXPIRED', 'SUPERSEDED')}")],
    idx=[f"CREATE INDEX ix_provider_commitment_provider ON {S}.provider_commitment (provider_id, valid_to DESC);"],
    rls="common", trig=[("immutable", ["provider_id", "doc_no", "file_id"])],
    ccomment={"state": "ACTIVE, EXPIRED, SUPERSEDED (CommitmentState, Phụ lục A)."}))

G_MODEL.append(T("model",
    "EN-17-10 Mô hình: CHAT, EMBEDDING, RERANK; phạm vi COMMON (PA khai báo, tenant_id COMMON) hoặc TENANT (FR-17-008). Một nhà cung cấp có nhiều mô hình; năng lực hỗ trợ gồm SEARCH, MAPPING, EXPLAIN và nhiệm vụ data plane.",
    ["model_code varchar(64) NOT NULL", "name varchar(255) NOT NULL", "model_kind varchar(12) NOT NULL", "scope varchar(8) NOT NULL", "provider_id uuid NOT NULL",
     "capabilities varchar(24)[] NOT NULL", "description varchar(2000)", "retired_at timestamptz"],
    [("uq_model_code", "UNIQUE (tenant_id, model_code)"), chk("model", "code", "model_code ~ '^[a-z0-9][a-z0-9._-]{2,63}$'"),
     chk("model", "kind", f"model_kind IN {E('ModelKind')}"), chk("model", "scope", f"scope IN {E('ModelScope')}"),
     chk("model", "scope_tenant", "(scope = 'COMMON') = (tenant_id = 'COMMON')"),
     chk("model", "caps", f"cardinality(capabilities) >= 1 AND capabilities <@ ARRAY['SEARCH', 'MAPPING', 'EXPLAIN', 'CLASSIFY_TEXT', 'EXTRACT_FIELDS', 'SUGGEST_STEP', 'EMBED', 'RERANK']::varchar[]"),
     chk("model", "kind_caps", "(model_kind <> 'EMBEDDING' OR capabilities = ARRAY['EMBED']::varchar[]) AND (model_kind <> 'RERANK' OR capabilities = ARRAY['RERANK']::varchar[])"),
     fk1("model", "provider_id", "model_provider")],
    tid=True, rls="common", trig=[("immutable", ["model_code", "model_kind", "scope", "provider_id"])],
    ccomment={"capabilities": "SEARCH, MAPPING, EXPLAIN (Capability) và CLASSIFY_TEXT, EXTRACT_FIELDS, SUGGEST_STEP (data plane, BR-17-082), EMBED, RERANK (ModelCapability, Phụ lục A)."}))

G_MODEL.append(T("model_version",
    "EN-17-11 Phiên bản mô hình, đối tượng được duyệt (FR-17-008, 009; BR-14, 15, 16, 24). DRAFT, EVALUATING, APPROVED, RETIRED (FRS 4.3); chỉ APPROVED định tuyến được. Duyệt bốn mắt và qua cổng phát hành: đánh giá chuẩn đạt, ca đỏ 100%, bộ ca đỏ từ 50 ca đang hoạt động. Nội dung khóa từ EVALUATING.",
    ["model_id uuid NOT NULL", "version_no integer NOT NULL", "version_label varchar(64) NOT NULL", "upstream_name varchar(128) NOT NULL", "status varchar(12) NOT NULL DEFAULT 'DRAFT'",
     "context_tokens integer NOT NULL", "embedding_dim smallint", "price_in_per_1k numeric(12,4) NOT NULL DEFAULT 0", "price_out_per_1k numeric(12,4) NOT NULL DEFAULT 0",
     "gen_params jsonb NOT NULL DEFAULT '{}'", "eval_run_id uuid", "redteam_run_id uuid", "submitted_by varchar(64)", "submitted_at timestamptz", "decided_by varchar(64)",
     "decided_at timestamptz", "decision_comment varchar(2000)", "approved_at timestamptz", "retired_at timestamptz"],
    [fk("model_version", "model_id", "model"), ("uq_model_version_no", "UNIQUE (tenant_id, model_id, version_no)"),
     chk("model_version", "version", "version_no >= 1"), chk("model_version", "status", f"status IN {E('ModelVersionStatus')}"),
     chk("model_version", "context", "context_tokens BETWEEN 256 AND 2000000"),
     chk("model_version", "dim", "embedding_dim IS NULL OR embedding_dim BETWEEN 64 AND 4096"),
     chk("model_version", "price", "price_in_per_1k >= 0 AND price_out_per_1k >= 0"),
     chk("model_version", "params", "gen_params::text !~* '(bearer |openbao://|password|api[_-]?key)'"),
     four_eyes("model_version", "decided_by", "created_by", "submitted_by"),
     chk("model_version", "approved", "status <> 'APPROVED' OR (decided_by IS NOT NULL AND approved_at IS NOT NULL AND eval_run_id IS NOT NULL AND redteam_run_id IS NOT NULL)"),
     chk("model_version", "reject", "decision_comment IS NULL OR char_length(decision_comment) >= 20"),
     chk("model_version", "retired", "(status = 'RETIRED') = (retired_at IS NOT NULL)"),
     chk("model_version", "submitted", "status NOT IN ('EVALUATING', 'APPROVED') OR submitted_by IS NOT NULL")],
    idx=[f"CREATE INDEX ix_model_version_status ON {S}.model_version (tenant_id, status);"],
    tid=True, rls="common",
    trig=[("immutable", ["model_id", "version_no"]),
          ("frozen", ["EVALUATING,APPROVED,RETIRED", "version_label", "upstream_name", "context_tokens", "embedding_dim", "price_in_per_1k", "price_out_per_1k", "gen_params"]),
          ("transition", ["status", "DRAFT>EVALUATING,EVALUATING>DRAFT,EVALUATING>APPROVED,APPROVED>RETIRED,DRAFT>RETIRED"]),
          ("gate", ["MODEL"])],
    ccomment={"embedding_dim": "Số chiều vector của mô hình nhúng (1024 theo mặc định); chỉ EMBEDDING có giá trị.",
              "eval_run_id": "Lượt đánh giá chuẩn đạt ngưỡng 17.eval.min-score (BR-17-015).", "redteam_run_id": "Lượt bộ ca đỏ không lọt ca nào (BR-17-067)."}))

G_MODEL.append(T("model_route",
    "EN-17-12 Tuyến từ phiên bản mô hình tới đích egress APISIX ai-proxy (FR-17-010, 011; BR-17-018, 019, 020). priority 0 là tuyến chính, lớn hơn là dự phòng. PH-03 áp cấu hình; tuyến chưa SYNCED thì mô hình chưa gọi được.",
    ["version_id uuid NOT NULL", "route_ref varchar(128) NOT NULL", "egress_host varchar(255) NOT NULL", "priority smallint NOT NULL DEFAULT 0", "status varchar(10) NOT NULL DEFAULT 'PENDING'",
     "snapshot_ref varchar(128)", "last_synced_at timestamptz", "drift boolean NOT NULL DEFAULT false", "last_error_code varchar(16)"],
    [fk("model_route", "version_id", "model_version"), ("uq_model_route_priority", "UNIQUE (tenant_id, version_id, priority)"),
     ("uq_model_route_ref", "UNIQUE (tenant_id, route_ref)"), chk("model_route", "status", f"status IN {E('RouteStatus')}"),
     chk("model_route", "priority", "priority BETWEEN 0 AND 9"),
     chk("model_route", "host", "egress_host !~ '^[0-9.]+$' AND (egress_host ~ '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$' OR egress_host ~ '^[a-z0-9-]+\\.svc(\\.cluster\\.local)?$')"),
     chk("model_route", "synced", "status <> 'SYNCED' OR (snapshot_ref IS NOT NULL AND last_synced_at IS NOT NULL)")],
    tid=True, rls="common",
    trig=[("transition", ["status", "PENDING>SYNCED,PENDING>FAILED,SYNCED>PENDING,FAILED>PENDING,PENDING>DISABLED,SYNCED>DISABLED,FAILED>DISABLED,DISABLED>PENDING"])],
    ccomment={"egress_host": "Tên miền trong nước đã khai báo (EXTERNAL) hoặc tên dịch vụ trong cụm (INTERNAL); không IP trần (BR-17-012).",
              "drift": "Cấu hình thực ở APISIX lệch cấu hình mong muốn (BR-17-020)."}))

G_MODEL.append(T("route_sync_run",
    "EN-17-13 Một lượt đồng bộ cấu hình tuyến sang PH-03 và kết quả (FR-17-011): phát EVT-17-08, nhận EVT-17-09 (gateway.snapshot.published hoặc rejected). Bản ghi chỉ mang mã và số đếm.",
    ["requested_by varchar(64) NOT NULL", "status varchar(10) NOT NULL DEFAULT 'PENDING'", "route_count integer NOT NULL DEFAULT 0", "request_event_id uuid", "result_event_id uuid",
     "snapshot_ref varchar(128)", "started_at timestamptz NOT NULL DEFAULT now()", "finished_at timestamptz", "error_code varchar(16)"],
    [chk("route_sync_run", "status", f"status IN {E('RouteStatus')}"), chk("route_sync_run", "count", "route_count >= 0"),
     chk("route_sync_run", "finished", "(status IN ('SYNCED', 'FAILED')) = (finished_at IS NOT NULL)")],
    idx=[f"CREATE INDEX ix_route_sync_run_started ON {S}.route_sync_run (tenant_id, started_at DESC);"], rls="common",
    trig=[("transition", ["status", "PENDING>SYNCED,PENDING>FAILED"])]))

G_MODEL.append(T("tenant_model",
    "EN-17-43 (FR-17-010; BR-17-004, 017, 018). Phiên bản mô hình tenant đã bật, mô hình mặc định và dự phòng theo loại. Bật được khi phiên bản APPROVED; nhà cung cấp EXTERNAL cần chính sách cho phép và danh sách trắng; dự phòng cùng loại, đã duyệt, không từ INTERNAL sang EXTERNAL (ERR-17-016, 017, 030, 034).",
    ["version_id uuid NOT NULL", "model_kind varchar(12) NOT NULL", "enabled boolean NOT NULL DEFAULT false", "is_default boolean NOT NULL DEFAULT false", "fallback_version_id uuid",
     "enabled_by varchar(64)", "enabled_at timestamptz", "disabled_at timestamptz"],
    [fk1("tenant_model", "version_id", "model_version"), ("uq_tenant_model_version", "UNIQUE (tenant_id, version_id)"),
     chk("tenant_model", "kind", f"model_kind IN {E('ModelKind')}"), chk("tenant_model", "default", "NOT is_default OR enabled"),
     chk("tenant_model", "fallback", "fallback_version_id IS NULL OR fallback_version_id <> version_id"),
     chk("tenant_model", "enabled", "NOT enabled OR (enabled_by IS NOT NULL AND enabled_at IS NOT NULL)"),
     fk1("tenant_model", "fallback_version_id", "model_version")],
    idx=[f"CREATE UNIQUE INDEX uq_tenant_model_default ON {S}.tenant_model (tenant_id, model_kind) WHERE is_default AND enabled;"],
    trig=[("raw", [f"CREATE TRIGGER tg_tenant_model_rules BEFORE INSERT OR UPDATE ON {S}.tenant_model FOR EACH ROW EXECUTE FUNCTION {S}.tg_tenant_model_rules();"])]))

G_MODEL.append(T("provider_grant",
    "EN-17-04 Nhà cung cấp ngoài trong danh sách trắng của tenant (FR-17-003; BR-17-004). Chỉ thêm khi có đề nghị EXTERNAL_ON đã duyệt; gỡ ghi revoked_at, không xóa dòng. Mỗi nhà cung cấp một dòng còn hiệu lực.",
    ["provider_id uuid NOT NULL", "change_id uuid NOT NULL", "granted_by varchar(64) NOT NULL", "effective_from date NOT NULL DEFAULT current_date", "effective_to date",
     "revoked_at timestamptz", "revoked_by varchar(64)"],
    [fk1("provider_grant", "provider_id", "model_provider"), fk("provider_grant", "change_id", "policy_change"),
     chk("provider_grant", "period", "effective_to IS NULL OR effective_to >= effective_from"),
     chk("provider_grant", "revoked", "(revoked_at IS NULL) = (revoked_by IS NULL)")],
    idx=[f"CREATE UNIQUE INDEX uq_provider_grant_active ON {S}.provider_grant (tenant_id, provider_id) WHERE revoked_at IS NULL;"],
    trig=[("immutable", ["provider_id", "change_id", "granted_by"])]))

G_MODEL.append(T("invocation_log",
    "EN-17-14 Vết một lời gọi mô hình (FR-17-013; BR-17-022, 024, NFR-17-026): mô hình, phiên bản, năng lực, token vào ra, độ trễ, kết quả, người gọi. Không có cột nội dung (nội dung ở message đã che). Chỉ thêm; phân vùng tháng; giữ 13 tháng (giả định, Q17-50).",
    ["occurred_at timestamptz NOT NULL DEFAULT now()", "capability varchar(24) NOT NULL", "model_version_id uuid NOT NULL", "route_id uuid", "caller_kind varchar(4) NOT NULL",
     "caller_ref varchar(64) NOT NULL", "message_id uuid", "request_ref varchar(64) NOT NULL", "tokens_in integer NOT NULL DEFAULT 0", "tokens_out integer NOT NULL DEFAULT 0",
     "latency_ms integer NOT NULL", "first_token_ms integer", "result varchar(10) NOT NULL", "error_code varchar(16)", "fallback_from_id uuid", "est_cost numeric(14,4) NOT NULL DEFAULT 0",
     "trace_id char(32) NOT NULL"],
    [chk("invocation_log", "caller", "caller_kind IN ('USER', 'DU')"), chk("invocation_log", "result", f"result IN {E('InvocationResult')}"),
     chk("invocation_log", "counts", "tokens_in >= 0 AND tokens_out >= 0 AND latency_ms >= 0 AND est_cost >= 0"),
     chk("invocation_log", "trace", "trace_id ~ '^[0-9a-f]{32}$'"),
     chk("invocation_log", "fallback", "(result = 'FALLBACK') = (fallback_from_id IS NOT NULL)"),
     chk("invocation_log", "error", "result IN ('OK', 'FALLBACK') OR error_code IS NOT NULL OR result = 'BLOCKED'")],
    idx=[f"CREATE INDEX ix_invocation_log_model ON {S}.invocation_log (tenant_id, model_version_id, occurred_at DESC);",
         f"CREATE INDEX ix_invocation_log_caller ON {S}.invocation_log (tenant_id, caller_kind, caller_ref, occurred_at DESC);",
         f"CREATE INDEX ix_invocation_log_message ON {S}.invocation_log (tenant_id, message_id) WHERE message_id IS NOT NULL;"],
    part=("occurred_at", "month", 3), pk=("id", "occurred_at"), std=False, trig=[("append_only", [])],
    ccomment={"message_id": "Tham chiếu logic tới message (không khóa ngoại: nhật ký tồn tại lâu hơn hội thoại).", "caller_ref": "Mã người dùng (sub) hoặc mã DU gọi data plane."}))

G_MODEL.append(T("model_health_probe",
    "EN-17-15 Kết quả thăm dò sức khỏe mô hình (FR-17-014; BR-17-023): ba lần lỗi liên tiếp thì DOWN và mở cầu dao, hai lần đạt liên tiếp mới trở lại. Chỉ thêm; phân vùng tháng; giữ 3 tháng.",
    ["probed_at timestamptz NOT NULL DEFAULT now()", "version_id uuid NOT NULL", "probe_kind varchar(10) NOT NULL DEFAULT 'SCHEDULED'", "state varchar(14) NOT NULL", "latency_ms integer",
     "consecutive_failures smallint NOT NULL DEFAULT 0", "consecutive_ok smallint NOT NULL DEFAULT 0", "error_code varchar(16)"],
    [chk("model_health_probe", "kind", "probe_kind IN ('SCHEDULED', 'MANUAL')"), chk("model_health_probe", "state", f"state IN {E('HealthState')}"),
     chk("model_health_probe", "counts", "consecutive_failures >= 0 AND consecutive_ok >= 0"),
     chk("model_health_probe", "down", "state <> 'DOWN' OR consecutive_failures >= 3")],
    idx=[f"CREATE INDEX ix_model_health_probe_version ON {S}.model_health_probe (tenant_id, version_id, probed_at DESC);"],
    part=("probed_at", "month", 3), pk=("id", "probed_at"), std=False, rls="common", trig=[("append_only", [])],
    ccomment={"state": "HEALTHY, DEGRADED, DOWN, BREAKER_OPEN theo Phụ lục A; FRS 9.3 và BR-17-023 còn dùng UP (Đề nghị đồng bộ)."}))

G_MODEL.append(T("model_breaker",
    "EN-17-44 (FR-17-012, 014; BR-17-021). Trạng thái cầu dao hiện hành của mỗi phiên bản mô hình: mở khi tỷ lệ lỗi vượt 17.breaker.error-rate trong cửa sổ 30 giây, tự thử lại sau 17.breaker.open-seconds; đóng thủ công qua API-17-055.",
    ["version_id uuid NOT NULL", "breaker_state varchar(10) NOT NULL DEFAULT 'CLOSED'", "error_rate numeric(5,2)", "opened_at timestamptz", "retry_at timestamptz", "reset_by varchar(64)"],
    [("uq_model_breaker_version", "UNIQUE (tenant_id, version_id)"), chk("model_breaker", "state", f"breaker_state IN {X('CLOSED', 'OPEN', 'HALF_OPEN')}"),
     chk("model_breaker", "rate", "error_rate IS NULL OR error_rate BETWEEN 0 AND 100"),
     chk("model_breaker", "open", "breaker_state = 'CLOSED' OR opened_at IS NOT NULL")]))
