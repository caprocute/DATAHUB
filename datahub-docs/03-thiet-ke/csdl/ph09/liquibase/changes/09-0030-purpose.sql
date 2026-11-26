--liquibase formatted sql
-- Nguồn: ddl/ph09_privacy.sql · 09-0030-purpose.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph09:ph09-0240-purpose
CREATE TABLE ph09_privacy.purpose (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  code               varchar(41) NOT NULL,
  name               varchar(255) NOT NULL,
  description        varchar(2000),
  legal_basis_code   varchar(32) NOT NULL,
  allowed_categories varchar(32)[] NOT NULL DEFAULT '{}',
  statutory          boolean NOT NULL DEFAULT false,
  max_days           integer NOT NULL DEFAULT 365,
  status             varchar(8) NOT NULL DEFAULT 'ACTIVE',
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_purpose PRIMARY KEY (id),
  CONSTRAINT uq_purpose_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_purpose_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_purpose_code UNIQUE (tenant_id, code),
  CONSTRAINT fk_purpose_basis FOREIGN KEY (tenant_id, legal_basis_code) REFERENCES ph09_privacy.legal_basis (tenant_id, code),
  CONSTRAINT ck_purpose_code CHECK (code ~ '^[A-Z][A-Z0-9-]{2,40}$'),
  CONSTRAINT ck_purpose_days CHECK (max_days BETWEEN 1 AND 730),
  CONSTRAINT ck_purpose_status CHECK (status IN ('ACTIVE', 'RETIRED'))
);
CREATE TRIGGER tg_purpose_touch BEFORE UPDATE ON ph09_privacy.purpose FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_purpose_immutable BEFORE UPDATE ON ph09_privacy.purpose FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('code');
CALL ph09_privacy.p_enable_rls('ph09_privacy.purpose');
COMMENT ON TABLE ph09_privacy.purpose IS 'EN-09-15 Mục đích khai thác (FR-09-014, BR-09-015, 047): mã dạng TTHC-HO-TICH, THONG-KE, cơ sở pháp lý, loại DLCN được phép, cờ statutory (mục đích bắt buộc theo luật vẫn truy cập được khi chủ thể bị hạn chế), thời hạn tối đa. Trường được phép ở purpose_element.';
COMMENT ON COLUMN ph09_privacy.purpose.max_days IS 'Trần cứng 730 ngày; trần tenant 09.grant.max-days mặc định 365 (BR-09-015).';
--rollback DROP TABLE IF EXISTS ph09_privacy.purpose CASCADE;

--changeset ph09:ph09-0250-purpose-element
CREATE TABLE ph09_privacy.purpose_element (
  id         uuid NOT NULL,
  tenant_id  varchar(16) NOT NULL,
  purpose_id uuid NOT NULL,
  element_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by varchar(64) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by varchar(64) NOT NULL,
  version    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_purpose_element PRIMARY KEY (id),
  CONSTRAINT ck_purpose_element_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_purpose_element_purpose FOREIGN KEY (tenant_id, purpose_id) REFERENCES ph09_privacy.purpose (tenant_id, id),
  CONSTRAINT fk_purpose_element_element FOREIGN KEY (tenant_id, element_id) REFERENCES ph09_privacy.data_element (tenant_id, id),
  CONSTRAINT uq_purpose_element UNIQUE (tenant_id, purpose_id, element_id)
);
CREATE INDEX ix_purpose_element_element ON ph09_privacy.purpose_element (tenant_id, element_id);
CREATE TRIGGER tg_purpose_element_touch BEFORE UPDATE ON ph09_privacy.purpose_element FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.purpose_element');
COMMENT ON TABLE ph09_privacy.purpose_element IS 'EN-09-52 Trường được phép theo mục đích, bảng con của Purpose (FR-09-014, BR-09-016): phạm vi tối đa mà một chấp thuận của mục đích đó được bao.';
--rollback DROP TABLE IF EXISTS ph09_privacy.purpose_element CASCADE;

--changeset ph09:ph09-0260-access-request
CREATE TABLE ph09_privacy.access_request (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  httt_id          varchar(63) NOT NULL,
  registration_ref varchar(63),
  purpose_code     varchar(41) NOT NULL,
  contract_kind    varchar(8) NOT NULL,
  contract_id      varchar(128) NOT NULL,
  fields           varchar(63)[] NOT NULL,
  expected_volume  integer NOT NULL,
  requested_days   integer NOT NULL,
  justification    varchar(2000) NOT NULL,
  owner_org_id     varchar(63) NOT NULL,
  status           varchar(16) NOT NULL DEFAULT 'DRAFT',
  submitted_at     timestamptz,
  reviewer         varchar(64),
  decision         varchar(24),
  decision_reason  varchar(2000),
  decided_by       varchar(64),
  decided_at       timestamptz,
  due_at           timestamptz,
  request_kind     varchar(8) NOT NULL DEFAULT 'NEW',
  renews_grant_id  uuid,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_access_request PRIMARY KEY (id),
  CONSTRAINT uq_access_request_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_access_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_access_request_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_access_request_kind CHECK (contract_kind IN ('API', 'TOPIC', 'FLOW')),
  CONSTRAINT ck_access_request_req_kind CHECK (request_kind IN ('NEW', 'RENEWAL')),
  CONSTRAINT ck_access_request_renews CHECK ((request_kind = 'RENEWAL') = (renews_grant_id IS NOT NULL)),
  CONSTRAINT ck_access_request_fields CHECK (cardinality(fields) >= 1),
  CONSTRAINT ck_access_request_volume CHECK (expected_volume BETWEEN 1 AND 10000000 AND requested_days BETWEEN 1 AND 730),
  CONSTRAINT ck_access_request_justification CHECK (char_length(justification) >= 20),
  CONSTRAINT ck_access_request_status CHECK (status IN ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'NEEDS_INFO', 'APPROVED', 'REJECTED', 'WITHDRAWN')),
  CONSTRAINT ck_access_request_decision CHECK (decision IS NULL OR decision IN ('APPROVE', 'APPROVE_WITH_CONDITIONS', 'REJECT')),
  CONSTRAINT ck_access_request_four_eyes CHECK (decided_by IS NULL OR decided_by <> created_by),
  CONSTRAINT ck_access_request_decided CHECK ((status IN ('APPROVED', 'REJECTED')) = (decided_by IS NOT NULL AND decided_at IS NOT NULL AND decision IS NOT NULL)),
  CONSTRAINT ck_access_request_outcome CHECK ((status <> 'APPROVED' OR decision IN ('APPROVE', 'APPROVE_WITH_CONDITIONS')) AND (status <> 'REJECTED' OR (decision = 'REJECT' AND COALESCE(char_length(decision_reason) >= 20, false)))),
  CONSTRAINT ck_access_request_submitted CHECK (status IN ('DRAFT', 'WITHDRAWN') OR submitted_at IS NOT NULL)
);
CREATE INDEX ix_access_request_inbox ON ph09_privacy.access_request (tenant_id, owner_org_id, status, due_at) WHERE status IN ('SUBMITTED', 'UNDER_REVIEW', 'NEEDS_INFO');
CREATE INDEX ix_access_request_httt ON ph09_privacy.access_request (tenant_id, httt_id, created_at DESC);
CREATE TRIGGER tg_access_request_touch BEFORE UPDATE ON ph09_privacy.access_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_access_request_immutable BEFORE UPDATE ON ph09_privacy.access_request FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('httt_id', 'purpose_code', 'contract_kind', 'contract_id');
CALL ph09_privacy.p_enable_rls('ph09_privacy.access_request');
COMMENT ON TABLE ph09_privacy.access_request IS 'EN-09-16 Yêu cầu khai thác của HTTT cho một mục đích (FR-09-015, 016, BR-09-013, 014, 016). Máy trạng thái AccessRequestStatus; chủ quản không duyệt yêu cầu do chính mình lập. Hợp đồng phải mức từ RESTRICTED (kiểm ở dịch vụ).';
COMMENT ON COLUMN ph09_privacy.access_request.httt_id IS 'Mã HTTT ở PH-01 (không khóa ngoại).';
COMMENT ON COLUMN ph09_privacy.access_request.registration_ref IS 'Đăng ký sử dụng ở PH-02.';
COMMENT ON COLUMN ph09_privacy.access_request.owner_org_id IS 'Tổ chức chủ quản dữ liệu, đích hộp việc của DO.';
COMMENT ON COLUMN ph09_privacy.access_request.request_kind IS 'AccessRequestKind: NEW (mặc định) hoặc RENEWAL, yêu cầu gia hạn chấp thuận hiện có (FR-09-015).';
COMMENT ON COLUMN ph09_privacy.access_request.renews_grant_id IS 'Chấp thuận ACTIVE được gia hạn; bắt buộc khi RENEWAL, rỗng khi NEW; cùng HTTT và mục đích kiểm ở dịch vụ (FR-09-015, 016).';
--rollback DROP TABLE IF EXISTS ph09_privacy.access_request CASCADE;

--changeset ph09:ph09-0270-purpose-grant
CREATE TABLE ph09_privacy.purpose_grant (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  request_id         uuid NOT NULL,
  httt_id            varchar(63) NOT NULL,
  purpose_code       varchar(41) NOT NULL,
  contract_kind      varchar(8) NOT NULL,
  contract_id        varchar(128) NOT NULL,
  valid_from         timestamptz NOT NULL,
  valid_to           timestamptz NOT NULL,
  status             varchar(12) NOT NULL,
  fields             varchar(63)[] NOT NULL,
  quota_per_day      integer,
  renew_count        smallint NOT NULL DEFAULT 0,
  approved_by        varchar(64) NOT NULL,
  approved_at        timestamptz NOT NULL DEFAULT now(),
  suspended_at       timestamptz,
  suspend_reason     varchar(2000),
  revoked_by         varchar(64),
  revoked_at         timestamptz,
  revoke_reason      varchar(2000),
  expired_at         timestamptz,
  expiry_notified_at timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_purpose_grant PRIMARY KEY (id),
  CONSTRAINT uq_purpose_grant_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_purpose_grant_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_purpose_grant_request FOREIGN KEY (tenant_id, request_id) REFERENCES ph09_privacy.access_request (tenant_id, id),
  CONSTRAINT fk_purpose_grant_purpose FOREIGN KEY (tenant_id, purpose_code) REFERENCES ph09_privacy.purpose (tenant_id, code),
  CONSTRAINT ck_purpose_grant_kind CHECK (contract_kind IN ('API', 'TOPIC', 'FLOW')),
  CONSTRAINT ck_purpose_grant_period CHECK (valid_to > valid_from AND valid_to <= valid_from + interval '730 days'),
  CONSTRAINT ck_purpose_grant_status CHECK (status IN ('SCHEDULED', 'ACTIVE', 'SUSPENDED', 'REVOKED', 'EXPIRED')),
  CONSTRAINT ck_purpose_grant_fields CHECK (cardinality(fields) >= 1),
  CONSTRAINT ck_purpose_grant_quota CHECK (quota_per_day IS NULL OR quota_per_day BETWEEN 1 AND 100000000),
  CONSTRAINT ck_purpose_grant_renew CHECK (renew_count BETWEEN 0 AND 10),
  CONSTRAINT ck_purpose_grant_suspended CHECK (status <> 'SUSPENDED' OR (suspended_at IS NOT NULL AND suspend_reason IS NOT NULL)),
  CONSTRAINT ck_purpose_grant_revoked CHECK (status <> 'REVOKED' OR (revoked_by IS NOT NULL AND revoked_at IS NOT NULL AND COALESCE(char_length(revoke_reason) >= 20, false))),
  CONSTRAINT ck_purpose_grant_expired CHECK (status <> 'EXPIRED' OR expired_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_purpose_grant_live ON ph09_privacy.purpose_grant (tenant_id, httt_id, purpose_code, contract_kind, contract_id) WHERE status IN ('SCHEDULED', 'ACTIVE', 'SUSPENDED');
CREATE INDEX ix_purpose_grant_expiry ON ph09_privacy.purpose_grant (tenant_id, valid_to) WHERE status IN ('SCHEDULED', 'ACTIVE', 'SUSPENDED');
CREATE INDEX ix_purpose_grant_httt ON ph09_privacy.purpose_grant (tenant_id, httt_id, status);
CREATE TRIGGER tg_purpose_grant_touch BEFORE UPDATE ON ph09_privacy.purpose_grant FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_purpose_grant_immutable BEFORE UPDATE ON ph09_privacy.purpose_grant FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('request_id', 'httt_id', 'purpose_code', 'contract_kind', 'contract_id', 'approved_by');
CALL ph09_privacy.p_enable_rls('ph09_privacy.purpose_grant');
COMMENT ON TABLE ph09_privacy.purpose_grant IS 'EN-09-17 Chấp thuận khai thác: bộ ba (HTTT, mục đích, hợp đồng), không chuyển nhượng (BR-09-013, FR-09-016, 017). Máy trạng thái GrantStatus; tối đa 3 lần gia hạn mặc định; thu hồi cần lý do 20 ký tự; một chấp thuận hiệu lực mỗi bộ ba. Nguồn của purpose_grants trong bundle OPA (FR-09-018).';
ALTER TABLE ph09_privacy.access_request ADD CONSTRAINT fk_access_request_renews FOREIGN KEY (tenant_id, renews_grant_id) REFERENCES ph09_privacy.purpose_grant (tenant_id, id);
--rollback DROP TABLE IF EXISTS ph09_privacy.purpose_grant CASCADE;

--changeset ph09:ph09-0280-grant-condition
CREATE TABLE ph09_privacy.grant_condition (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  grant_id       uuid NOT NULL,
  condition_type varchar(16) NOT NULL,
  params         jsonb NOT NULL DEFAULT '{}',
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_grant_condition PRIMARY KEY (id),
  CONSTRAINT ck_grant_condition_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_grant_condition_grant FOREIGN KEY (tenant_id, grant_id) REFERENCES ph09_privacy.purpose_grant (tenant_id, id),
  CONSTRAINT uq_grant_condition_type UNIQUE (tenant_id, grant_id, condition_type),
  CONSTRAINT ck_grant_condition_type CHECK (condition_type IN ('FIELD_SUBSET', 'DAILY_QUOTA', 'TIME_WINDOW', 'NO_EXPORT', 'MASK_REQUIRED')),
  CONSTRAINT ck_grant_condition_params CHECK (jsonb_typeof(params) = 'object')
);
CREATE TRIGGER tg_grant_condition_touch BEFORE UPDATE ON ph09_privacy.grant_condition FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.grant_condition');
COMMENT ON TABLE ph09_privacy.grant_condition IS 'EN-09-18 Điều kiện của chấp thuận (FR-09-016, BR-09-016): FIELD_SUBSET, DAILY_QUOTA, TIME_WINDOW, NO_EXPORT, MASK_REQUIRED, tham số jsonb. Ghi vào bundle OPA; mỗi loại tối đa một dòng mỗi chấp thuận.';
--rollback DROP TABLE IF EXISTS ph09_privacy.grant_condition CASCADE;

--changeset ph09:ph09-0290-policy-bundle
CREATE TABLE ph09_privacy.policy_bundle (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  bundle_no       bigint NOT NULL,
  content_hash    bytea NOT NULL,
  signature       bytea,
  signing_key_ref varchar(128),
  object_ref      varchar(512) NOT NULL,
  size_bytes      integer NOT NULL,
  counts          jsonb NOT NULL DEFAULT '{}',
  test_passed     boolean NOT NULL DEFAULT false,
  test_result     jsonb,
  published_at    timestamptz,
  valid_until     timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_policy_bundle PRIMARY KEY (id),
  CONSTRAINT uq_policy_bundle_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_policy_bundle_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_policy_bundle_no UNIQUE (tenant_id, bundle_no),
  CONSTRAINT ck_policy_bundle_hash CHECK (octet_length(content_hash) = 32),
  CONSTRAINT ck_policy_bundle_size CHECK (size_bytes BETWEEN 1 AND 5242880),
  CONSTRAINT ck_policy_bundle_published CHECK (published_at IS NULL OR (test_passed AND signature IS NOT NULL AND signing_key_ref IS NOT NULL AND valid_until IS NOT NULL)),
  CONSTRAINT ck_policy_bundle_valid CHECK (valid_until IS NULL OR (published_at IS NOT NULL AND valid_until > published_at AND valid_until <= published_at + interval '240 minutes'))
);
CREATE INDEX ix_policy_bundle_published ON ph09_privacy.policy_bundle (tenant_id, published_at DESC) WHERE published_at IS NOT NULL;
CREATE TRIGGER tg_policy_bundle_touch BEFORE UPDATE ON ph09_privacy.policy_bundle FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CREATE TRIGGER tg_policy_bundle_immutable BEFORE UPDATE ON ph09_privacy.policy_bundle FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_immutable('bundle_no', 'content_hash', 'object_ref');
CALL ph09_privacy.p_enable_rls('ph09_privacy.policy_bundle');
COMMENT ON TABLE ph09_privacy.policy_bundle IS 'EN-09-19 Bundle purpose_grants, mask_policies, classification_index đã ký (FR-09-018, BR-09-018): băm nội dung, chữ ký bằng khóa transit không xuất được, validUntil = phát hành cộng 60 phút mặc định, kết quả kiểm thử. Nội dung bundle ở Garage (object_ref), ≤ 5 MB. Chỉ phát hành khi kiểm thử đạt.';
--rollback DROP TABLE IF EXISTS ph09_privacy.policy_bundle CASCADE;

--changeset ph09:ph09-0300-usage-counter
CREATE TABLE ph09_privacy.usage_counter (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  bucket_at         timestamptz NOT NULL,
  httt_id           varchar(63) NOT NULL,
  purpose_code      varchar(41) NOT NULL,
  contract_kind     varchar(8) NOT NULL,
  contract_id       varchar(128) NOT NULL,
  reporter          varchar(64) NOT NULL,
  allowed_count     integer NOT NULL DEFAULT 0,
  denied_count      integer NOT NULL DEFAULT 0,
  off_purpose_count integer NOT NULL DEFAULT 0,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pk_usage_counter PRIMARY KEY (id, bucket_at),
  CONSTRAINT ck_usage_counter_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_usage_counter_key UNIQUE (tenant_id, httt_id, purpose_code, contract_kind, contract_id, reporter, bucket_at),
  CONSTRAINT ck_usage_counter_kind CHECK (contract_kind IN ('API', 'TOPIC', 'FLOW')),
  CONSTRAINT ck_usage_counter_minute CHECK (bucket_at = date_trunc('minute', bucket_at)),
  CONSTRAINT ck_usage_counter_counts CHECK (allowed_count >= 0 AND denied_count >= 0 AND off_purpose_count >= 0)
) PARTITION BY RANGE (bucket_at);
CALL ph09_privacy.p_ensure_partitions('ph09_privacy.usage_counter', current_date, 3);
CREATE INDEX ix_usage_counter_purpose ON ph09_privacy.usage_counter (tenant_id, purpose_code, bucket_at DESC);
CALL ph09_privacy.p_enable_rls('ph09_privacy.usage_counter');
COMMENT ON TABLE ph09_privacy.usage_counter IS 'EN-09-20 Bộ đếm khai thác theo (HTTT, mục đích, hợp đồng, phút) do điểm thực thi báo (FR-09-019, 020, BR-09-020). Cập nhật cộng dồn (upsert); phân vùng tháng theo bucket_at; giữ 13 tháng. Không chứa giá trị dữ liệu.';
COMMENT ON COLUMN ph09_privacy.usage_counter.reporter IS 'Điểm thực thi báo số đếm (APISIX, PH-04, PH-06, PH-14, PH-19).';
--rollback DROP TABLE IF EXISTS ph09_privacy.usage_counter CASCADE;

--changeset ph09:ph09-0310-usage-anomaly
CREATE TABLE ph09_privacy.usage_anomaly (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  anomaly_type  varchar(16) NOT NULL,
  severity      varchar(8) NOT NULL,
  status        varchar(16) NOT NULL DEFAULT 'OPEN',
  httt_id       varchar(63) NOT NULL,
  purpose_code  varchar(41),
  contract_kind varchar(8),
  contract_id   varchar(128),
  grant_id      uuid,
  detected_at   timestamptz NOT NULL DEFAULT now(),
  window_from   timestamptz NOT NULL,
  window_to     timestamptz NOT NULL,
  observed      bigint NOT NULL,
  threshold     bigint,
  handled_by    varchar(64),
  handled_at    timestamptz,
  handle_note   varchar(2000),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_usage_anomaly PRIMARY KEY (id),
  CONSTRAINT ck_usage_anomaly_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_usage_anomaly_grant FOREIGN KEY (tenant_id, grant_id) REFERENCES ph09_privacy.purpose_grant (tenant_id, id),
  CONSTRAINT ck_usage_anomaly_type CHECK (anomaly_type IN ('QUOTA_EXCEEDED', 'BULK_ACCESS', 'OFF_PURPOSE', 'OFF_HOURS', 'DORMANT_REUSE')),
  CONSTRAINT ck_usage_anomaly_severity CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH')),
  CONSTRAINT ck_usage_anomaly_status CHECK (status IN ('OPEN', 'ACKNOWLEDGED', 'DISMISSED', 'ESCALATED')),
  CONSTRAINT ck_usage_anomaly_kind CHECK (contract_kind IS NULL OR contract_kind IN ('API', 'TOPIC', 'FLOW')),
  CONSTRAINT ck_usage_anomaly_window CHECK (window_to >= window_from AND observed >= 0),
  CONSTRAINT ck_usage_anomaly_handled CHECK (status = 'OPEN' OR (handled_by IS NOT NULL AND handled_at IS NOT NULL))
);
CREATE INDEX ix_usage_anomaly_open ON ph09_privacy.usage_anomaly (tenant_id, severity, detected_at DESC) WHERE status = 'OPEN';
CREATE INDEX ix_usage_anomaly_httt ON ph09_privacy.usage_anomaly (tenant_id, httt_id, detected_at DESC);
CREATE TRIGGER tg_usage_anomaly_touch BEFORE UPDATE ON ph09_privacy.usage_anomaly FOR EACH ROW EXECUTE FUNCTION ph09_privacy.tg_touch();
CALL ph09_privacy.p_enable_rls('ph09_privacy.usage_anomaly');
COMMENT ON TABLE ph09_privacy.usage_anomaly IS 'EN-09-21 Cảnh báo khai thác bất thường (FR-09-020, THR-51): AnomalyType, mức RiskLevel, trạng thái AnomalyStatus; phát hiện trong 5 phút (BR-09-020). Xử lý phải có người và thời điểm.';
--rollback DROP TABLE IF EXISTS ph09_privacy.usage_anomaly CASCADE;
