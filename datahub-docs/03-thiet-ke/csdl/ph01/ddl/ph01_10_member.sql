-- =============================================================================
-- D03-03-PH01 · Tệp 10: HTTT thành viên, hồ sơ kỹ thuật, đầu mối, tài liệu, mẫu văn bản,
-- lịch sử trạng thái, thao tác khẩn, yêu cầu thay đổi.
-- Chạy sau ph01_00_bootstrap.sql.
-- =============================================================================
\set ON_ERROR_STOP on
SET ROLE ph01_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 01-0010-member.sql
-- @changeset ph01-0100-fn-member-rules splitStatements:false
-- Bảng chuyển trạng thái HTTT (D02-07 DD-03, FRS §4.3). Nguồn chính ở TransitionTable trong mã (ADR-058);
-- bản này là lớp phòng thủ thứ hai ở CSDL, kiểm thử bằng ph01_isolation_test.sql.
CREATE OR REPLACE FUNCTION ph01_onboarding.fn_member_transition_ok(p_old text, p_new text) RETURNS boolean
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT (p_old, p_new) IN (VALUES
    ('DRAFT', 'SUBMITTED'), ('SUBMITTED', 'DRAFT'), ('SUBMITTED', 'REJECTED'), ('SUBMITTED', 'APPROVED'),
    ('APPROVED', 'ACTIVE'), ('APPROVED', 'TERMINATED'),
    ('ACTIVE', 'SUSPENDED'), ('SUSPENDED', 'ACTIVE'), ('ACTIVE', 'TERMINATED'), ('SUSPENDED', 'TERMINATED'))
$f$;
COMMENT ON FUNCTION ph01_onboarding.fn_member_transition_ok(text, text) IS 'Chuyển trạng thái HTTT hợp lệ (FRS §4.3): 10 cặp (từ, đến).';

-- Điều kiện nộp: hồ sơ kỹ thuật đủ, có đầu mối kỹ thuật, căn cứ pháp lý đủ cho mọi dòng CONSUME,
-- tổ chức không còn HTTT ACTIVE thiếu đầu mối kỹ thuật (BR-01-001, BR-01-013; ERR-01-008, 010, 015).
CREATE OR REPLACE FUNCTION ph01_onboarding.fn_assert_submittable(p_id uuid, p_org text) RETURNS void
  LANGUAGE plpgsql AS $f$
DECLARE tp record;
BEGIN
  SELECT * INTO tp FROM ph01_onboarding.technical_profile WHERE member_system_id = p_id;
  IF NOT FOUND OR tp.system_kind IS NULL OR tp.technology IS NULL OR tp.has_api IS NULL
     OR cardinality(tp.protocols) = 0 OR tp.under_maintenance IS NULL OR tp.replacement_planned IS NULL
     OR (tp.has_api AND tp.api_spec_kind IS NULL) OR (NOT tp.has_api AND tp.db_type IS NULL) THEN
    RAISE EXCEPTION 'Hồ sơ năng lực kỹ thuật chưa đủ, không nộp được (ERR-01-008)' USING ERRCODE = '23514';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ph01_onboarding.contact c
                  WHERE c.member_system_id = p_id AND c.contact_type = 'TECHNICAL' AND c.status = 'ACTIVE') THEN
    RAISE EXCEPTION 'Thiếu đầu mối kỹ thuật đang hoạt động (BR-01-013, ERR-01-008)' USING ERRCODE = '23514';
  END IF;
  IF EXISTS (SELECT 1 FROM ph01_onboarding.data_demand d
              WHERE d.member_system_id = p_id AND d.direction = 'CONSUME' AND d.origin = 'ONBOARDING'
                AND (d.legal_doc_no IS NULL OR d.legal_issued_on IS NULL OR d.legal_issuer IS NULL OR d.legal_attachment_id IS NULL)) THEN
    RAISE EXCEPTION 'Có mục nhu cầu khai thác thiếu căn cứ pháp lý (BR-01-001, ERR-01-015)' USING ERRCODE = '23514';
  END IF;
  IF EXISTS (SELECT 1 FROM ph01_onboarding.member_system m
              WHERE m.id <> p_id AND m.owner_org_id = p_org AND m.status = 'ACTIVE'
                AND NOT EXISTS (SELECT 1 FROM ph01_onboarding.contact c
                                 WHERE c.member_system_id = m.id AND c.contact_type = 'TECHNICAL' AND c.status = 'ACTIVE')) THEN
    RAISE EXCEPTION 'Tổ chức còn HTTT đang hoạt động thiếu đầu mối kỹ thuật (BR-01-013, ERR-01-010)' USING ERRCODE = '23514';
  END IF;
END
$f$;
COMMENT ON FUNCTION ph01_onboarding.fn_assert_submittable(uuid, text) IS 'Điều kiện chuyển DRAFT → SUBMITTED ở CSDL (lớp phòng thủ thứ hai của bộ kiểm tra FR-01-011).';

-- Điều kiện phê duyệt: đủ ba bước của vòng hiện tại, mọi nhu cầu có kết luận, nhóm đã xác nhận,
-- người duyệt chưa tham gia thẩm định (BR-01-017; ERR-01-017, 018, 019, 020).
CREATE OR REPLACE FUNCTION ph01_onboarding.fn_assert_approvable(p_id uuid, p_by text, p_rev integer) RETURNS void
  LANGUAGE plpgsql AS $f$
BEGIN
  IF (SELECT count(*) FROM ph01_onboarding.review_step s
       WHERE s.member_system_id = p_id AND s.revision_no = p_rev AND s.status IN ('DONE', 'CARRIED')) <> 3 THEN
    RAISE EXCEPTION 'Chưa đủ ba bước thẩm định của vòng nộp %, không phê duyệt được (ERR-01-020)', p_rev USING ERRCODE = '23514';
  END IF;
  IF EXISTS (SELECT 1 FROM ph01_onboarding.data_demand d
              WHERE d.member_system_id = p_id AND d.origin = 'ONBOARDING' AND d.verdict IS NULL) THEN
    RAISE EXCEPTION 'Còn mục nhu cầu khai thác chưa có kết luận (ERR-01-018)' USING ERRCODE = '23514';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ph01_onboarding.technical_profile t WHERE t.member_system_id = p_id AND t.confirmed_group IS NOT NULL) THEN
    RAISE EXCEPTION 'Nhóm HTTT chưa được xác nhận (ERR-01-019)' USING ERRCODE = '23514';
  END IF;
  IF EXISTS (SELECT 1 FROM ph01_onboarding.review_step s
              WHERE s.member_system_id = p_id AND (s.finished_by = p_by OR s.assignee_id = p_by)) THEN
    RAISE EXCEPTION 'Người đã thẩm định không được phê duyệt cùng hồ sơ (BR-01-017, ERR-01-017)' USING ERRCODE = '23514';
  END IF;
END
$f$;
COMMENT ON FUNCTION ph01_onboarding.fn_assert_approvable(uuid, text, integer) IS 'Điều kiện chuyển SUBMITTED → APPROVED ở CSDL, gồm bốn mắt giữa người thẩm định và người duyệt.';

-- Điều kiện kích hoạt: đã qua kiểm thử SANDBOX, có đầu mối kỹ thuật (BR-01-008, BR-01-013; ERR-01-031, 032).
CREATE OR REPLACE FUNCTION ph01_onboarding.fn_assert_activatable(p_id uuid, p_sandbox_passed timestamptz) RETURNS void
  LANGUAGE plpgsql AS $f$
BEGIN
  IF p_sandbox_passed IS NULL THEN
    RAISE EXCEPTION 'Chưa qua kiểm thử SANDBOX, không kích hoạt được (BR-01-008, ERR-01-031)' USING ERRCODE = '23514';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM ph01_onboarding.contact c
                  WHERE c.member_system_id = p_id AND c.contact_type = 'TECHNICAL' AND c.status = 'ACTIVE') THEN
    RAISE EXCEPTION 'Thiếu đầu mối kỹ thuật đang hoạt động (BR-01-013, ERR-01-032)' USING ERRCODE = '23514';
  END IF;
END
$f$;
COMMENT ON FUNCTION ph01_onboarding.fn_assert_activatable(uuid, timestamptz) IS 'Điều kiện chuyển APPROVED → ACTIVE ở CSDL.';

CREATE OR REPLACE FUNCTION ph01_onboarding.tg_member_system_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE v_ignore text[] := ARRAY['enforcement', 'updated_at', 'updated_by', 'version'];
BEGIN
  IF NEW.tenant_id <> OLD.tenant_id THEN
    RAISE EXCEPTION 'tenant_id không đổi được' USING ERRCODE = '23514';
  END IF;
  IF NEW.code <> OLD.code THEN
    RAISE EXCEPTION 'Mã HTTT bất biến (BR-01-018, ERR-01-002)' USING ERRCODE = '23514';
  END IF;
  IF OLD.status IN ('REJECTED', 'TERMINATED') AND (to_jsonb(NEW) - v_ignore) IS DISTINCT FROM (to_jsonb(OLD) - v_ignore) THEN
    RAISE EXCEPTION 'Hồ sơ ở trạng thái cuối % không sửa được (BR-01-018)', OLD.status USING ERRCODE = '55000';
  END IF;
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NOT ph01_onboarding.fn_member_transition_ok(OLD.status, NEW.status) THEN
      RAISE EXCEPTION 'Chuyển trạng thái % → % không hợp lệ (ERR-01-005)', OLD.status, NEW.status USING ERRCODE = '55000';
    END IF;
    IF NEW.status = 'SUBMITTED' THEN
      IF NEW.revision_no <> OLD.revision_no + 1 THEN
        RAISE EXCEPTION 'Nộp hồ sơ phải tăng revision_no thêm 1 (BR-01-032)' USING ERRCODE = '23514';
      END IF;
      PERFORM ph01_onboarding.fn_assert_submittable(NEW.id, NEW.owner_org_id);
    ELSIF NEW.status = 'APPROVED' THEN
      PERFORM ph01_onboarding.fn_assert_approvable(NEW.id, NEW.approved_by, NEW.revision_no);
    ELSIF NEW.status = 'ACTIVE' AND OLD.status = 'APPROVED' THEN
      PERFORM ph01_onboarding.fn_assert_activatable(NEW.id, NEW.sandbox_passed_at);
    END IF;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph01_onboarding.tg_member_system_guard() IS 'Mã bất biến, trạng thái cuối đóng băng, bảng chuyển trạng thái và điều kiện nộp, duyệt, kích hoạt (BR-01-008, 013, 017, 018).';

CREATE OR REPLACE FUNCTION ph01_onboarding.tg_member_system_no_delete() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF OLD.status = 'DRAFT' AND OLD.revision_no = 0 AND OLD.deleted_at IS NOT NULL AND OLD.deleted_at < now() - interval '30 days' THEN
    RETURN OLD;
  END IF;
  RAISE EXCEPTION 'Chỉ xóa cứng nháp chưa từng nộp đã xóa mềm quá 30 ngày; hồ sơ khác giữ vĩnh viễn (BR-01-011, BR-01-018)' USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph01_onboarding.tg_member_system_no_delete() IS 'Chặn xóa cứng HTTT trừ nháp chưa từng nộp đã xóa mềm quá 30 ngày (FR-01-009).';
-- @rollback DROP FUNCTION IF EXISTS ph01_onboarding.tg_member_system_no_delete(), ph01_onboarding.tg_member_system_guard(), ph01_onboarding.fn_assert_activatable(uuid, timestamptz), ph01_onboarding.fn_assert_approvable(uuid, text, integer), ph01_onboarding.fn_assert_submittable(uuid, text), ph01_onboarding.fn_member_transition_ok(text, text);

-- @changeset ph01-0110-member-system
CREATE TABLE ph01_onboarding.member_system (
  id                    uuid          NOT NULL,
  tenant_id             varchar(16)   NOT NULL,
  code                  varchar(64)   NOT NULL,
  name                  varchar(255)  NOT NULL,
  description           varchar(2000),
  owner_org_id          varchar(64)   NOT NULL,
  operator_name         varchar(255),
  security_level        varchar(2)    NOT NULL,
  security_approval_ref varchar(255),
  system_type           varchar(10)   NOT NULL,
  roles                 varchar(10)[] NOT NULL,
  status                varchar(10)   NOT NULL DEFAULT 'DRAFT',
  review_stage          varchar(18),
  provision_stage       varchar(18),
  enforcement           varchar(7)    NOT NULL DEFAULT 'NONE',
  revision_no           integer       NOT NULL DEFAULT 0,
  return_reason         varchar(1000),
  status_reason         varchar(1000),
  suspend_reason_code   varchar(16),
  base_urls             jsonb         NOT NULL DEFAULT '[]',
  ip_allowlist          jsonb         NOT NULL DEFAULT '[]',
  legacy_ref            varchar(255),
  origin_tenant_id      varchar(16),
  submitted_by          varchar(64),
  submitted_at          timestamptz,
  approved_by           varchar(64),
  approved_at           timestamptz,
  sandbox_passed_at     timestamptz,
  activated_by          varchar(64),
  activated_at          timestamptz,
  terminated_at         timestamptz,
  last_access_review_at timestamptz,
  deleted_at            timestamptz,
  archived_at           timestamptz,
  created_at            timestamptz   NOT NULL DEFAULT now(),
  created_by            varchar(64)   NOT NULL,
  updated_at            timestamptz   NOT NULL DEFAULT now(),
  updated_by            varchar(64)   NOT NULL,
  version               integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_member_system PRIMARY KEY (id),
  CONSTRAINT uq_member_system_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_member_system_code UNIQUE (tenant_id, code),
  CONSTRAINT ck_member_system_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_member_system_code CHECK (code ~ '^[A-Z][A-Z0-9-]{2,63}$'),
  CONSTRAINT ck_member_system_name CHECK (char_length(name) >= 3),
  CONSTRAINT ck_member_system_level CHECK (security_level IN ('L1', 'L2', 'L3', 'L4', 'L5')),
  CONSTRAINT ck_member_system_type CHECK (system_type IN ('PROVINCIAL', 'NATIONAL', 'MINISTRY', 'LEGACY', 'EXTERNAL')),
  CONSTRAINT ck_member_system_roles CHECK (cardinality(roles) >= 1 AND roles <@ ARRAY['CONSUMER', 'PROVIDER', 'PUBLISHER', 'SUBSCRIBER']::varchar[]),
  CONSTRAINT ck_member_system_status CHECK (status IN ('DRAFT', 'SUBMITTED', 'APPROVED', 'ACTIVE', 'SUSPENDED', 'TERMINATED', 'REJECTED')),
  CONSTRAINT ck_member_system_review_stage CHECK ((status = 'SUBMITTED') = (review_stage IS NOT NULL)
                                              AND (review_stage IS NULL OR review_stage IN ('WAITING_ASSIGN', 'IN_REVIEW', 'CONSULTING', 'WAITING_APPROVAL'))),
  CONSTRAINT ck_member_system_provision_stage CHECK ((status = 'APPROVED') = (provision_stage IS NOT NULL)
                                              AND (provision_stage IS NULL OR provision_stage IN ('PROVISIONING', 'AWAITING_KEY', 'SANDBOX_READY', 'PROVISION_FAILED'))),
  CONSTRAINT ck_member_system_enforcement CHECK (enforcement IN ('NONE', 'PENDING', 'DONE')),
  CONSTRAINT ck_member_system_revision CHECK (revision_no >= 0),
  CONSTRAINT ck_member_system_security_ref CHECK (status = 'DRAFT' OR security_level IN ('L1', 'L2') OR security_approval_ref IS NOT NULL),
  CONSTRAINT ck_member_system_base_urls CHECK (ph01_onboarding.fn_urls_https(base_urls)),
  CONSTRAINT ck_member_system_ip_allowlist CHECK (ph01_onboarding.fn_cidr_array(ip_allowlist)),
  CONSTRAINT ck_member_system_submitted CHECK (status = 'DRAFT' OR revision_no = 0 OR submitted_by IS NOT NULL),
  CONSTRAINT ck_member_system_approved CHECK (status NOT IN ('APPROVED', 'ACTIVE', 'SUSPENDED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT ck_member_system_activated CHECK (status NOT IN ('ACTIVE', 'SUSPENDED') OR (activated_by IS NOT NULL AND activated_at IS NOT NULL)),
  CONSTRAINT ck_member_system_four_eyes CHECK ((approved_by IS NULL OR (approved_by <> created_by AND approved_by IS DISTINCT FROM submitted_by))
                                           AND (activated_by IS NULL OR activated_by IS DISTINCT FROM submitted_by)),
  CONSTRAINT ck_member_system_reason CHECK (status NOT IN ('SUSPENDED', 'TERMINATED', 'REJECTED') OR coalesce(char_length(status_reason), 0) >= 10),
  CONSTRAINT ck_member_system_suspend_code CHECK (suspend_reason_code IS NULL OR suspend_reason_code IN ('SECURITY_SUSPECT', 'LEGAL_EXPIRED', 'INACTIVITY', 'OTHER')),
  CONSTRAINT ck_member_system_suspended CHECK (status <> 'SUSPENDED' OR suspend_reason_code IS NOT NULL),
  CONSTRAINT ck_member_system_terminated CHECK ((status = 'TERMINATED') = (terminated_at IS NOT NULL)),
  CONSTRAINT ck_member_system_deleted CHECK (deleted_at IS NULL OR (status = 'DRAFT' AND revision_no = 0)),
  CONSTRAINT ck_member_system_archived CHECK (archived_at IS NULL OR revision_no >= 1),
  CONSTRAINT ck_member_system_origin CHECK (origin_tenant_id IS NULL OR (origin_tenant_id ~ '^T[0-9]{2}$' AND origin_tenant_id <> tenant_id))
);
CREATE UNIQUE INDEX uq_member_system_legacy_ref ON ph01_onboarding.member_system (tenant_id, legacy_ref) WHERE legacy_ref IS NOT NULL;
CREATE INDEX ix_member_system_status_org ON ph01_onboarding.member_system (tenant_id, status, owner_org_id);
CREATE INDEX ix_member_system_updated ON ph01_onboarding.member_system (tenant_id, updated_at, id);
CREATE INDEX ix_member_system_name_trgm ON ph01_onboarding.member_system USING gin (lower(name) gin_trgm_ops);
CREATE INDEX ix_member_system_review_due ON ph01_onboarding.member_system (tenant_id, last_access_review_at NULLS FIRST) WHERE status = 'ACTIVE';
CREATE INDEX ix_member_system_draft_stale ON ph01_onboarding.member_system (tenant_id, updated_at) WHERE status = 'DRAFT' AND deleted_at IS NULL;
CREATE INDEX ix_member_system_enforcement ON ph01_onboarding.member_system (tenant_id) WHERE enforcement = 'PENDING';
CREATE TRIGGER tg_member_system_guard BEFORE UPDATE ON ph01_onboarding.member_system FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_member_system_guard();
CREATE TRIGGER tg_member_system_touch BEFORE UPDATE ON ph01_onboarding.member_system FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CREATE TRIGGER tg_member_system_no_delete BEFORE DELETE ON ph01_onboarding.member_system FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_member_system_no_delete();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.member_system', 'P');
COMMENT ON TABLE ph01_onboarding.member_system IS 'EN-01-01 HTTT thành viên (DD-03), cũng là hồ sơ kết nạp ở giai đoạn đầu đời (FR-01-003). Mã bất biến, không dùng lại (BR-01-018); trạng thái chuyển theo bảng chuyển, bốn mắt khóa ở CSDL (BR-01-017).';
COMMENT ON COLUMN ph01_onboarding.member_system.code IS 'Mã HTTT, duy nhất trong tenant kể cả REJECTED, TERMINATED; bất biến (BR-01-018).';
COMMENT ON COLUMN ph01_onboarding.member_system.owner_org_id IS 'Mã tổ chức chủ quản ở PH-20 (DD-02); không khóa ngoại vì khác schema, kiểm ở dịch vụ qua Ph20Port.';
COMMENT ON COLUMN ph01_onboarding.member_system.security_level IS 'Cấp độ ATTT được phê duyệt L1…L5; từ L3 trở lên phải có security_approval_ref khi nộp (FR-01-003).';
COMMENT ON COLUMN ph01_onboarding.member_system.roles IS 'Vai trò: CONSUMER, PROVIDER, PUBLISHER, SUBSCRIBER; hợp nhất Application của APIM và publisher, subscriber của Hub cũ.';
COMMENT ON COLUMN ph01_onboarding.member_system.review_stage IS 'Giai đoạn khi SUBMITTED: WAITING_ASSIGN, IN_REVIEW, CONSULTING, WAITING_APPROVAL; NULL ở trạng thái khác.';
COMMENT ON COLUMN ph01_onboarding.member_system.provision_stage IS 'Giai đoạn khi APPROVED: PROVISIONING, AWAITING_KEY, SANDBOX_READY, PROVISION_FAILED; NULL ở trạng thái khác.';
COMMENT ON COLUMN ph01_onboarding.member_system.enforcement IS 'Tiến độ cắt quyền: NONE, PENDING (còn việc enforcement_task chưa xong), DONE (BR-01-023).';
COMMENT ON COLUMN ph01_onboarding.member_system.revision_no IS 'Số lần đã nộp; nộp lại tăng 1 (BR-01-032). 0 là chưa từng nộp, cho phép xóa nháp.';
COMMENT ON COLUMN ph01_onboarding.member_system.base_urls IS 'Mảng địa chỉ backend, chỉ https (SEC-43).';
COMMENT ON COLUMN ph01_onboarding.member_system.ip_allowlist IS 'Mảng CIDR được phép gọi; dữ liệu mức Hạn chế (HC).';
COMMENT ON COLUMN ph01_onboarding.member_system.legacy_ref IS 'Mã ở hệ cũ (ví dụ APIM-APP-0042, w1:ph01.application/{id}); chỉ mục duy nhất trong tenant để nhập lại không nhân đôi.';
COMMENT ON COLUMN ph01_onboarding.member_system.origin_tenant_id IS 'Tenant nguồn khi hồ sơ được chuyển vào tenant đích do sáp nhập tenant, giữ id gốc để truy vết (D03-10 §5.4); NULL với hồ sơ tạo tại chỗ.';
COMMENT ON COLUMN ph01_onboarding.member_system.sandbox_passed_at IS 'Thời điểm kiểm thử SANDBOX đạt tiêu chí; điều kiện của APPROVED → ACTIVE (BR-01-008).';
COMMENT ON COLUMN ph01_onboarding.member_system.deleted_at IS 'Xóa mềm nháp chưa từng nộp; giữ 30 ngày để khôi phục rồi xóa cứng, giải phóng mã (FR-01-009).';
COMMENT ON COLUMN ph01_onboarding.member_system.archived_at IS 'Ẩn khỏi danh sách mặc định với nháp đã từng nộp không hoạt động 90 ngày; không xóa (BR-01-011).';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.member_system CASCADE;

-- @changeset ph01-0120-technical-profile
CREATE TABLE ph01_onboarding.technical_profile (
  id                        uuid          NOT NULL,
  tenant_id                 varchar(16)   NOT NULL,
  member_system_id          uuid          NOT NULL,
  system_kind               varchar(14),
  technology                varchar(255),
  has_api                   boolean,
  api_spec_kind             varchar(8),
  protocols                 varchar(8)[]  NOT NULL DEFAULT '{}',
  db_type                   varchar(10),
  cdc_log_enabled           varchar(7),
  under_maintenance         boolean,
  replacement_planned       boolean,
  replacement_date          date,
  criticality               varchar(8)    NOT NULL DEFAULT 'NORMAL',
  max_concurrent_connections integer      NOT NULL DEFAULT 10,
  expected_daily_calls      bigint        NOT NULL DEFAULT 0,
  operating_hours           varchar(255),
  proposed_group            smallint,
  confirmed_group           smallint,
  confirmed_by              varchar(64),
  confirmed_at              timestamptz,
  quota_impact              varchar(10)   NOT NULL DEFAULT 'UNASSESSED',
  quota_impact_note         varchar(1000),
  created_at                timestamptz   NOT NULL DEFAULT now(),
  created_by                varchar(64)   NOT NULL,
  updated_at                timestamptz   NOT NULL DEFAULT now(),
  updated_by                varchar(64)   NOT NULL,
  version                   integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_technical_profile PRIMARY KEY (id),
  CONSTRAINT uq_technical_profile_system UNIQUE (tenant_id, member_system_id),
  CONSTRAINT fk_technical_profile_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_technical_profile_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_technical_profile_kind CHECK (system_kind IS NULL OR system_kind IN ('WEB', 'DESKTOP', 'MOBILE_BACKEND', 'BATCH', 'OTHER')),
  CONSTRAINT ck_technical_profile_spec CHECK (api_spec_kind IS NULL OR api_spec_kind IN ('OPENAPI', 'WSDL', 'NONE', 'OTHER')),
  CONSTRAINT ck_technical_profile_protocols CHECK (protocols <@ ARRAY['REST', 'SOAP', 'JMS', 'AMQP', 'MQTT', 'SFTP', 'DB', 'OTHER']::varchar[]),
  CONSTRAINT ck_technical_profile_db CHECK (db_type IS NULL OR db_type IN ('POSTGRESQL', 'MYSQL', 'SQLSERVER', 'ORACLE', 'OTHER', 'NONE')),
  CONSTRAINT ck_technical_profile_cdc CHECK (cdc_log_enabled IS NULL OR cdc_log_enabled IN ('YES', 'NO', 'UNKNOWN')),
  CONSTRAINT ck_technical_profile_replacement CHECK (replacement_planned IS DISTINCT FROM true OR replacement_date IS NOT NULL),
  CONSTRAINT ck_technical_profile_criticality CHECK (criticality IN ('NORMAL', 'CRITICAL')),
  CONSTRAINT ck_technical_profile_conn CHECK (max_concurrent_connections >= 1),
  CONSTRAINT ck_technical_profile_calls CHECK (expected_daily_calls >= 0),
  CONSTRAINT ck_technical_profile_groups CHECK ((proposed_group IS NULL OR proposed_group BETWEEN 1 AND 4) AND (confirmed_group IS NULL OR confirmed_group BETWEEN 1 AND 4)),
  CONSTRAINT ck_technical_profile_confirmed CHECK ((confirmed_group IS NULL) = (confirmed_by IS NULL) AND (confirmed_group IS NULL) = (confirmed_at IS NULL)),
  CONSTRAINT ck_technical_profile_quota CHECK (quota_impact IN ('UNASSESSED', 'LOW', 'MEDIUM', 'HIGH'))
);
CREATE TRIGGER tg_technical_profile_touch BEFORE UPDATE ON ph01_onboarding.technical_profile FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CREATE TRIGGER tg_technical_profile_draft_delete BEFORE DELETE ON ph01_onboarding.technical_profile FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_draft_only_delete('member_system_id');
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.technical_profile', 'P');
COMMENT ON TABLE ph01_onboarding.technical_profile IS 'EN-01-02 Hồ sơ năng lực kỹ thuật, một dòng mỗi HTTT (FR-01-006, FR-01-013, FR-01-015). Cột có thể NULL khi còn nháp; điều kiện đủ kiểm ở fn_assert_submittable.';
COMMENT ON COLUMN ph01_onboarding.technical_profile.has_api IS 'Yếu tố chính xác định nhóm HTTT; true thì cần api_spec_kind, false thì cần db_type; kiểm khi nộp ở fn_assert_submittable.';
COMMENT ON COLUMN ph01_onboarding.technical_profile.proposed_group IS 'Nhóm HTTT 1…4 do hệ thống tính từ hồ sơ; người dùng không sửa.';
COMMENT ON COLUMN ph01_onboarding.technical_profile.confirmed_group IS 'Nhóm do người thẩm định kỹ thuật xác nhận; điều kiện của phê duyệt (ERR-01-019).';
COMMENT ON COLUMN ph01_onboarding.technical_profile.criticality IS 'CRITICAL: HTTT thiết yếu, bắt buộc xác nhận tác động khi tạm ngừng, chấm dứt (ERR-01-034).';
COMMENT ON COLUMN ph01_onboarding.technical_profile.max_concurrent_connections IS 'Dùng cấu hình nhóm kết nối ở PH-05.';
COMMENT ON COLUMN ph01_onboarding.technical_profile.quota_impact IS 'Kết quả QuotaImpactEvaluator theo quotaImpact.mediumPct, highPct (FR-01-015); UNASSESSED khi PH-14 không khả dụng.';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.technical_profile CASCADE;

-- @changeset ph01-0130-contact
CREATE TABLE ph01_onboarding.contact (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  member_system_id  uuid          NOT NULL,
  contact_type      varchar(9)    NOT NULL,
  full_name         varchar(255)  NOT NULL,
  job_title         varchar(255)  NOT NULL,
  email             varchar(255)  NOT NULL,
  phone             varchar(16),
  user_account_id   varchar(64),
  is_public         boolean       NOT NULL DEFAULT true,
  status            varchar(8)    NOT NULL DEFAULT 'ACTIVE',
  inactive_reason   varchar(16),
  replaced_by_id    uuid,
  last_confirmed_at timestamptz,
  search_text       text GENERATED ALWAYS AS (ph01_onboarding.fn_unaccent(full_name || ' ' || job_title || ' ' || email)) STORED,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        varchar(64)   NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_contact PRIMARY KEY (id),
  CONSTRAINT uq_contact_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_contact_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT fk_contact_replaced_by FOREIGN KEY (replaced_by_id, tenant_id) REFERENCES ph01_onboarding.contact (id, tenant_id),
  CONSTRAINT ck_contact_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_contact_type CHECK (contact_type IN ('BUSINESS', 'TECHNICAL', 'SECURITY')),
  CONSTRAINT ck_contact_email CHECK (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  CONSTRAINT ck_contact_phone CHECK (phone IS NULL OR phone ~ '^\+[1-9][0-9]{7,14}$'),
  CONSTRAINT ck_contact_security_private CHECK (contact_type <> 'SECURITY' OR is_public = false),
  CONSTRAINT ck_contact_status CHECK (status IN ('ACTIVE', 'INACTIVE')),
  CONSTRAINT ck_contact_inactive CHECK ((status = 'INACTIVE') = (inactive_reason IS NOT NULL)
                                    AND (inactive_reason IS NULL OR inactive_reason IN ('REPLACED', 'REMOVED', 'MAIL_BOUNCED', 'ACCOUNT_DISABLED', 'ORG_CHANGED')))
);
CREATE UNIQUE INDEX uq_contact_active_email ON ph01_onboarding.contact (tenant_id, member_system_id, contact_type, lower(email)) WHERE status = 'ACTIVE';
CREATE INDEX ix_contact_system ON ph01_onboarding.contact (tenant_id, member_system_id, contact_type) WHERE status = 'ACTIVE';
CREATE INDEX ix_contact_user ON ph01_onboarding.contact (tenant_id, user_account_id) WHERE user_account_id IS NOT NULL;
CREATE INDEX ix_contact_search_trgm ON ph01_onboarding.contact USING gin (search_text gin_trgm_ops) WHERE status = 'ACTIVE' AND is_public;
CREATE INDEX ix_contact_stale ON ph01_onboarding.contact (tenant_id, last_confirmed_at NULLS FIRST) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_contact_touch BEFORE UPDATE ON ph01_onboarding.contact FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CREATE TRIGGER tg_contact_draft_delete BEFORE DELETE ON ph01_onboarding.contact FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_draft_only_delete('member_system_id');
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.contact', 'P');
COMMENT ON TABLE ph01_onboarding.contact IS 'EN-01-05 Đầu mối liên hệ (DD-04), dữ liệu cá nhân mức Hạn chế (FR-01-008, BR-01-027). Đầu mối SECURITY luôn không công khai. Không đưa họ tên, thư, điện thoại vào sự kiện (EVT-01-13).';
COMMENT ON COLUMN ph01_onboarding.contact.job_title IS 'Chức vụ (trường position của FRS; tránh trùng từ khóa POSITION).';
COMMENT ON COLUMN ph01_onboarding.contact.user_account_id IS 'Tài khoản Keycloak ở PH-12 (DD-06) nếu đầu mối có tài khoản; điều kiện nhận bàn giao (FR-01-022); không khóa ngoại.';
COMMENT ON COLUMN ph01_onboarding.contact.is_public IS 'Công khai trong danh bạ phạm vi tenant; mặc định true với BUSINESS, TECHNICAL.';
COMMENT ON COLUMN ph01_onboarding.contact.inactive_reason IS 'Lý do không hoạt động; MAIL_BOUNCED theo BR-01-028, ACCOUNT_DISABLED, ORG_CHANGED theo sự kiện của PH-12.';
COMMENT ON COLUMN ph01_onboarding.contact.search_text IS 'Cột sinh: họ tên, chức vụ, thư điện tử bỏ dấu, hạ chữ thường; chỉ mục GIN pg_trgm cho tra danh bạ (FR-01-045). Chứa dữ liệu cá nhân, cùng mức bảo vệ với cột nguồn (Q01-29).';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.contact CASCADE;

-- @changeset ph01-0140-attachment
CREATE TABLE ph01_onboarding.attachment (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  member_system_id  uuid          NOT NULL,
  kind              varchar(18)   NOT NULL,
  title             varchar(255),
  file_name         varchar(255)  NOT NULL,
  content_type      varchar(128)  NOT NULL,
  size_bytes        bigint        NOT NULL,
  object_key        varchar(512)  NOT NULL,
  sha256            char(64)      NOT NULL,
  scan_status       varchar(8)    NOT NULL DEFAULT 'PENDING',
  scanned_at        timestamptz,
  classification    varchar(10)   NOT NULL DEFAULT 'INTERNAL',
  uploaded_by       varchar(64)   NOT NULL,
  deleted_at        timestamptz,
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        varchar(64)   NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_attachment PRIMARY KEY (id),
  CONSTRAINT uq_attachment_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_attachment_object_key UNIQUE (tenant_id, object_key),
  CONSTRAINT fk_attachment_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_attachment_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_attachment_kind CHECK (kind IN ('REQUEST_LETTER', 'LEGAL_BASIS', 'SECURITY_APPROVAL', 'TECH_DOC', 'OTHER')),
  CONSTRAINT ck_attachment_size CHECK (size_bytes > 0 AND size_bytes <= 52428800),
  CONSTRAINT ck_attachment_sha CHECK (sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_attachment_key CHECK (object_key !~ '^staging/' AND object_key !~ '\.\.'),
  CONSTRAINT ck_attachment_scan CHECK (scan_status IN ('PENDING', 'CLEAN')),
  CONSTRAINT ck_attachment_scanned CHECK ((scan_status = 'CLEAN') = (scanned_at IS NOT NULL)),
  CONSTRAINT ck_attachment_class CHECK (classification IN ('PUBLIC', 'INTERNAL', 'RESTRICTED', 'SENSITIVE'))
);
CREATE INDEX ix_attachment_system ON ph01_onboarding.attachment (tenant_id, member_system_id, kind) WHERE deleted_at IS NULL;
CREATE INDEX ix_attachment_pending ON ph01_onboarding.attachment (created_at) WHERE scan_status = 'PENDING';
CREATE TRIGGER tg_attachment_touch BEFORE UPDATE ON ph01_onboarding.attachment FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CREATE TRIGGER tg_attachment_draft_delete BEFORE DELETE ON ph01_onboarding.attachment FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_draft_only_delete('member_system_id');
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.attachment', 'P');
COMMENT ON TABLE ph01_onboarding.attachment IS 'EN-01-06 Tài liệu đính kèm (DD-12), chỉ siêu dữ liệu; nội dung ở bucket dh-{tenant}-onboarding, mã hóa SSE-C (FR-01-005, NFR-01-011). Sau nộp không xóa (BR-01-011).';
COMMENT ON COLUMN ph01_onboarding.attachment.object_key IS 'Khóa đối tượng {systemCode}/{attachmentId}; khóa tạm staging/ không lưu ở bảng này.';
COMMENT ON COLUMN ph01_onboarding.attachment.size_bytes IS 'Trần cứng 50 MB theo SEC-45; trần mềm theo tham số attachment.maxSizeMb (mặc định 20 MB) kiểm ở dịch vụ.';
COMMENT ON COLUMN ph01_onboarding.attachment.scan_status IS 'PENDING (đang quét hoặc quá hạn quét đồng bộ) hoặc CLEAN; tệp nhiễm mã độc bị xóa và không có dòng (ERR-01-014).';
COMMENT ON COLUMN ph01_onboarding.attachment.deleted_at IS 'Xóa mềm cùng nháp chưa từng nộp (FR-01-009).';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.attachment CASCADE;

-- @changeset ph01-0150-template
CREATE TABLE ph01_onboarding.template (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  template_code    varchar(64)   NOT NULL,
  title            varchar(255)  NOT NULL,
  content_version  varchar(16)   NOT NULL,
  status           varchar(9)    NOT NULL DEFAULT 'DRAFT',
  file_name        varchar(255)  NOT NULL,
  content_type     varchar(128)  NOT NULL,
  file_ref         varchar(512)  NOT NULL,
  file_sha256      char(64)      NOT NULL,
  guide_md         text,
  published_at     timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_template PRIMARY KEY (id),
  CONSTRAINT uq_template_version UNIQUE (tenant_id, template_code, content_version),
  CONSTRAINT ck_template_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_template_code CHECK (template_code ~ '^[a-z][a-z0-9-]{2,63}$'),
  CONSTRAINT ck_template_status CHECK (status IN ('DRAFT', 'PUBLISHED', 'RETIRED')),
  CONSTRAINT ck_template_published CHECK ((status = 'PUBLISHED') = (published_at IS NOT NULL) OR status = 'RETIRED'),
  CONSTRAINT ck_template_sha CHECK (file_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_template_guide CHECK (guide_md IS NULL OR octet_length(guide_md) <= 102400)
);
CREATE UNIQUE INDEX uq_template_published ON ph01_onboarding.template (tenant_id, template_code) WHERE status = 'PUBLISHED';
CREATE TRIGGER tg_template_touch BEFORE UPDATE ON ph01_onboarding.template FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.template', 'S');
COMMENT ON TABLE ph01_onboarding.template IS 'EN-01-18 Mẫu văn bản đề nghị và hướng dẫn kết nối (FR-01-010). Mẫu mặc định ở tenant COMMON (chỉ phiên PLATFORM ghi); tenant đặt mẫu riêng thì mẫu tenant được dùng trước.';
COMMENT ON COLUMN ph01_onboarding.template.content_version IS 'Phiên bản nội dung mẫu, ví dụ 1.0 (khác cột version là khóa lạc quan).';
COMMENT ON COLUMN ph01_onboarding.template.file_ref IS 'Khóa tệp mẫu ở kho đối tượng (bucket nền tảng cho COMMON, bucket tenant cho mẫu riêng); tải qua liên kết ký ngắn hạn.';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.template CASCADE;

-- @changeset ph01-0160-state-history splitStatements:false
CREATE OR REPLACE FUNCTION ph01_onboarding.tg_state_history_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF TG_OP = 'DELETE' AND NOT EXISTS (SELECT 1 FROM ph01_onboarding.member_system WHERE id = OLD.member_system_id) THEN
    RETURN OLD;  -- xóa theo tầng khi cứng-xóa nháp chưa từng nộp
  END IF;
  RAISE EXCEPTION 'Bảng state_history chỉ cho thêm (BR-01-011, BR-01-031)' USING ERRCODE = '55000';
END
$f$;
CREATE TABLE ph01_onboarding.state_history (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  member_system_id uuid          NOT NULL,
  subject_type     varchar(10)   NOT NULL DEFAULT 'MEMBER',
  subject_id       uuid          NOT NULL,
  from_status      varchar(20),
  to_status        varchar(20)   NOT NULL,
  revision_no      integer       NOT NULL DEFAULT 0,
  reason           varchar(1000),
  actor            varchar(64)   NOT NULL,
  emergency        boolean       NOT NULL DEFAULT false,
  occurred_at      timestamptz   NOT NULL DEFAULT now(),
  trace_id         char(32)      NOT NULL,
  CONSTRAINT pk_state_history PRIMARY KEY (id),
  CONSTRAINT fk_state_history_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_state_history_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_state_history_subject CHECK (subject_type IN ('MEMBER', 'CREDENTIAL', 'CEILING')),
  CONSTRAINT ck_state_history_change CHECK (from_status IS DISTINCT FROM to_status),
  CONSTRAINT ck_state_history_trace CHECK (trace_id ~ '^[0-9a-f]{32}$')
);
CREATE INDEX ix_state_history_system ON ph01_onboarding.state_history (tenant_id, member_system_id, occurred_at DESC);
CREATE INDEX ix_state_history_subject ON ph01_onboarding.state_history (tenant_id, subject_type, subject_id, occurred_at DESC);
CREATE TRIGGER tg_state_history_ro BEFORE UPDATE OR DELETE ON ph01_onboarding.state_history FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_state_history_guard();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.state_history', 'P');
COMMENT ON TABLE ph01_onboarding.state_history IS 'EN-01-11 Lịch sử trạng thái của HTTT, định danh và trần phạm vi, chỉ thêm, giữ vĩnh viễn (BR-01-011, BR-01-031, NFR-01-022). Ghi cùng giao dịch với thay đổi trạng thái.';
COMMENT ON COLUMN ph01_onboarding.state_history.subject_type IS 'MEMBER (HTTT), CREDENTIAL (định danh), CEILING (trần phạm vi); subject_id là id của đối tượng.';
COMMENT ON COLUMN ph01_onboarding.state_history.emergency IS 'true khi chuyển do thao tác khẩn của Cán bộ ATTT (BR-01-010).';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.state_history CASCADE; DROP FUNCTION IF EXISTS ph01_onboarding.tg_state_history_guard();

-- @changeset ph01-0170-emergency-action
CREATE TABLE ph01_onboarding.emergency_action (
  id                     uuid          NOT NULL,
  tenant_id              varchar(16)   NOT NULL,
  member_system_id       uuid          NOT NULL,
  action_type            varchar(8)    NOT NULL,
  reason                 varchar(1000) NOT NULL,
  credential_ids         uuid[]        NOT NULL DEFAULT '{}',
  performed_by           varchar(64)   NOT NULL,
  performed_at           timestamptz   NOT NULL DEFAULT now(),
  confirm_by             timestamptz   NOT NULL,
  confirmed_by           varchar(64),
  confirmed_at           timestamptz,
  status                 varchar(15)   NOT NULL DEFAULT 'PENDING_CONFIRM',
  overdue_at             timestamptz,
  resume_consent_by      varchar(64),
  resume_consent_at      timestamptz,
  created_at             timestamptz   NOT NULL DEFAULT now(),
  created_by             varchar(64)   NOT NULL,
  updated_at             timestamptz   NOT NULL DEFAULT now(),
  updated_by             varchar(64)   NOT NULL,
  version                integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_emergency_action PRIMARY KEY (id),
  CONSTRAINT uq_emergency_action_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_emergency_action_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id),
  CONSTRAINT ck_emergency_action_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_emergency_action_type CHECK (action_type IN ('SUSPEND', 'REVOKE')),
  CONSTRAINT ck_emergency_action_reason CHECK (char_length(reason) >= 10),
  CONSTRAINT ck_emergency_action_status CHECK (status IN ('PENDING_CONFIRM', 'CONFIRMED', 'OVERDUE')),
  CONSTRAINT ck_emergency_action_deadline CHECK (confirm_by > performed_at),
  CONSTRAINT ck_emergency_action_confirmed CHECK ((status = 'CONFIRMED') = (confirmed_by IS NOT NULL AND confirmed_at IS NOT NULL)),
  CONSTRAINT ck_emergency_action_four_eyes CHECK (confirmed_by IS NULL OR confirmed_by <> performed_by),
  CONSTRAINT ck_emergency_action_overdue CHECK ((status = 'OVERDUE') = (overdue_at IS NOT NULL AND confirmed_by IS NULL)),
  CONSTRAINT ck_emergency_action_consent CHECK ((resume_consent_by IS NULL) = (resume_consent_at IS NULL))
);
CREATE INDEX ix_emergency_action_system ON ph01_onboarding.emergency_action (tenant_id, member_system_id, performed_at DESC);
CREATE INDEX ix_emergency_action_due ON ph01_onboarding.emergency_action (confirm_by) WHERE status = 'PENDING_CONFIRM';
CREATE TRIGGER tg_emergency_action_touch BEFORE UPDATE ON ph01_onboarding.emergency_action FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.emergency_action', 'P');
COMMENT ON TABLE ph01_onboarding.emergency_action IS 'EN-01-12 Thao tác khẩn của Cán bộ ATTT: tạm ngừng hoặc thu hồi ngay, TA xác nhận bổ sung trong emergency.confirmHours; quá hạn thì OVERDUE, không tự hoàn tác (FR-01-032, BR-01-010).';
COMMENT ON COLUMN ph01_onboarding.emergency_action.credential_ids IS 'Định danh bị thu hồi khi action_type = REVOKE; rỗng nghĩa là mọi định danh của HTTT.';
COMMENT ON COLUMN ph01_onboarding.emergency_action.confirmed_by IS 'Người xác nhận bổ sung; phải khác performed_by (BR-01-017, ERR-01-036).';
COMMENT ON COLUMN ph01_onboarding.emergency_action.resume_consent_by IS 'SO đồng ý khôi phục HTTT bị tạm ngừng vì nghi lộ bí mật; điều kiện của FR-01-030 (BR-01-010).';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.emergency_action CASCADE;

-- @changeset ph01-0180-change-request
CREATE TABLE ph01_onboarding.change_request (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL,
  member_system_id    uuid          NOT NULL,
  change_class        varchar(12)   NOT NULL,
  reason              varchar(1000) NOT NULL,
  diff                jsonb         NOT NULL DEFAULT '{}',
  new_owner_org_id    varchar(64),
  owner_confirmed_by  varchar(64),
  owner_confirmed_at  timestamptz,
  impact_report       jsonb,
  impact_confirmed    boolean       NOT NULL DEFAULT false,
  status              varchar(9)    NOT NULL DEFAULT 'PENDING',
  requested_by        varchar(64)   NOT NULL,
  requested_at        timestamptz   NOT NULL DEFAULT now(),
  decided_by          varchar(64),
  decided_at          timestamptz,
  decision_note       varchar(1000),
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_change_request PRIMARY KEY (id),
  CONSTRAINT uq_change_request_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_change_request_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id),
  CONSTRAINT ck_change_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_change_request_class CHECK (change_class IN ('TECHNICAL', 'OWNER_CHANGE', 'FULL', 'TERMINATE')),
  CONSTRAINT ck_change_request_reason CHECK (char_length(reason) >= 10),
  CONSTRAINT ck_change_request_diff CHECK (jsonb_typeof(diff) = 'object'),
  CONSTRAINT ck_change_request_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED')),
  CONSTRAINT ck_change_request_decided CHECK ((status IN ('APPROVED', 'REJECTED')) = (decided_by IS NOT NULL AND decided_at IS NOT NULL)),
  CONSTRAINT ck_change_request_four_eyes CHECK (decided_by IS NULL OR decided_by <> requested_by),
  CONSTRAINT ck_change_request_owner CHECK ((change_class = 'OWNER_CHANGE') = (new_owner_org_id IS NOT NULL)),
  CONSTRAINT ck_change_request_owner_confirm CHECK (change_class <> 'OWNER_CHANGE' OR status <> 'APPROVED' OR owner_confirmed_by IS NOT NULL),
  CONSTRAINT ck_change_request_terminate_impact CHECK (change_class <> 'TERMINATE' OR status <> 'APPROVED' OR impact_report IS NOT NULL)
);
CREATE UNIQUE INDEX uq_change_request_pending ON ph01_onboarding.change_request (tenant_id, member_system_id) WHERE status = 'PENDING';
CREATE INDEX ix_change_request_system ON ph01_onboarding.change_request (tenant_id, member_system_id, requested_at DESC);
CREATE TRIGGER tg_change_request_touch BEFORE UPDATE ON ph01_onboarding.change_request FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.change_request', 'P');
COMMENT ON TABLE ph01_onboarding.change_request IS 'EN-01-13 Yêu cầu thay đổi hồ sơ HTTT đã kết nạp theo mức duyệt: TECHNICAL, OWNER_CHANGE, FULL (mở rộng phạm vi), TERMINATE (chấm dứt). Mỗi HTTT tối đa một yêu cầu PENDING (FR-01-034, 035, 031; BR-01-012, 025, 029).';
COMMENT ON COLUMN ph01_onboarding.change_request.diff IS 'Phần thay đổi dạng JSON đối tượng; áp vào hồ sơ khi duyệt, trong một giao dịch (EVT-01-04).';
COMMENT ON COLUMN ph01_onboarding.change_request.decided_by IS 'Người duyệt; phải khác người đề nghị (BR-01-017).';
COMMENT ON COLUMN ph01_onboarding.change_request.owner_confirmed_by IS 'Người của tổ chức mới xác nhận nhận chủ quản; điều kiện duyệt OWNER_CHANGE (BR-01-029).';
COMMENT ON COLUMN ph01_onboarding.change_request.impact_report IS 'Báo cáo phân tích tác động (FR-01-033) lưu kèm để chứng minh người quyết định đã thấy tác động; bắt buộc khi duyệt TERMINATE.';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.change_request CASCADE;
