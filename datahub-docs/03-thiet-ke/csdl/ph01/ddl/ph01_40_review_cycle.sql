-- =============================================================================
-- D03-03-PH01 · Tệp 40: rà soát quyền định kỳ, phiếu xác nhận của đơn vị, tác vụ nhập hệ cũ.
-- Chạy sau ph01_30_credential.sql.
-- =============================================================================
\set ON_ERROR_STOP on
SET ROLE ph01_owner;
SET app.tenant_id = 'PLATFORM';

-- @file 01-0040-review-cycle.sql
-- @changeset ph01-0400-access-review-cycle splitStatements:false
CREATE OR REPLACE FUNCTION ph01_onboarding.tg_access_review_cycle_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.tenant_id <> OLD.tenant_id OR NEW.cycle_code <> OLD.cycle_code OR NEW.kind <> OLD.kind THEN
    RAISE EXCEPTION 'Mã kỳ, loại kỳ rà soát bất biến' USING ERRCODE = '23514';
  END IF;
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NOT ((OLD.status, NEW.status) IN (VALUES ('OPEN', 'WAITING'), ('OPEN', 'DECIDING'), ('WAITING', 'DECIDING'), ('DECIDING', 'CLOSED'))) THEN
      RAISE EXCEPTION 'Kỳ rà soát đi một chiều OPEN → WAITING → DECIDING → CLOSED, không đi % → % (FRS §4.4)', OLD.status, NEW.status USING ERRCODE = '55000';
    END IF;
    IF NEW.status = 'CLOSED' AND EXISTS (SELECT 1 FROM ph01_onboarding.access_review_item i WHERE i.cycle_id = NEW.id AND i.decision IS NULL) THEN
      RAISE EXCEPTION 'Còn mục rà soát chưa có quyết định, chưa đóng kỳ được (FR-01-042)' USING ERRCODE = '23514';
    END IF;
  ELSIF OLD.status = 'CLOSED' THEN
    RAISE EXCEPTION 'Kỳ rà soát đã đóng, bằng chứng giữ 5 năm không sửa (NFR-01-022)' USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph01_onboarding.tg_access_review_cycle_guard() IS 'Kỳ rà soát đi một chiều; đóng kỳ khi mọi mục đã có quyết định; kỳ CLOSED bất biến.';

CREATE TABLE ph01_onboarding.access_review_cycle (
  id              uuid          NOT NULL,
  tenant_id       varchar(16)   NOT NULL,
  cycle_code      varchar(16)   NOT NULL,
  kind            varchar(8)    NOT NULL DEFAULT 'PERIODIC',
  period_from     date          NOT NULL,
  period_to       date          NOT NULL,
  status          varchar(8)    NOT NULL DEFAULT 'OPEN',
  scope_org_ids   varchar(64)[],
  opened_by       varchar(64)   NOT NULL,
  opened_at       timestamptz   NOT NULL DEFAULT now(),
  item_count      integer       NOT NULL DEFAULT 0,
  closed_by       varchar(64),
  closed_at       timestamptz,
  evidence_hash   char(64),
  created_at      timestamptz   NOT NULL DEFAULT now(),
  created_by      varchar(64)   NOT NULL,
  updated_at      timestamptz   NOT NULL DEFAULT now(),
  updated_by      varchar(64)   NOT NULL,
  version         integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_access_review_cycle PRIMARY KEY (id),
  CONSTRAINT uq_access_review_cycle_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_access_review_cycle_code UNIQUE (tenant_id, cycle_code),
  CONSTRAINT ck_access_review_cycle_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_access_review_cycle_code CHECK (cycle_code ~ '^RS-[0-9]{4}-[0-9]{2}$'),
  CONSTRAINT ck_access_review_cycle_kind CHECK (kind IN ('PERIODIC', 'TOPIC') AND ((kind = 'TOPIC') = (scope_org_ids IS NOT NULL))),
  CONSTRAINT ck_access_review_cycle_period CHECK (period_to > period_from),
  CONSTRAINT ck_access_review_cycle_status CHECK (status IN ('OPEN', 'WAITING', 'DECIDING', 'CLOSED')),
  CONSTRAINT ck_access_review_cycle_closed CHECK ((status = 'CLOSED') = (closed_at IS NOT NULL AND closed_by IS NOT NULL AND evidence_hash IS NOT NULL)),
  CONSTRAINT ck_access_review_cycle_hash CHECK (evidence_hash IS NULL OR evidence_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_access_review_cycle_items CHECK (item_count >= 0)
);
CREATE UNIQUE INDEX uq_access_review_cycle_open ON ph01_onboarding.access_review_cycle (tenant_id) WHERE status <> 'CLOSED';
CREATE TRIGGER tg_access_review_cycle_guard BEFORE UPDATE ON ph01_onboarding.access_review_cycle FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_access_review_cycle_guard();
CREATE TRIGGER tg_access_review_cycle_touch BEFORE UPDATE ON ph01_onboarding.access_review_cycle FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.access_review_cycle', 'P');
COMMENT ON TABLE ph01_onboarding.access_review_cycle IS 'EN-01-14 Kỳ rà soát quyền định kỳ (mỗi 6 tháng) hoặc theo chuyên đề; mỗi tenant tối đa một kỳ chưa CLOSED; giữ 5 năm (FR-01-039…044; BR-01-014; ERR-01-039).';
COMMENT ON COLUMN ph01_onboarding.access_review_cycle.cycle_code IS 'RS-{năm}-{nn}, duy nhất trong tenant.';
COMMENT ON COLUMN ph01_onboarding.access_review_cycle.kind IS 'PERIODIC (toàn tenant, cập nhật last_access_review_at) hoặc TOPIC (theo danh sách tổ chức scope_org_ids, không cập nhật mốc toàn tenant).';
COMMENT ON COLUMN ph01_onboarding.access_review_cycle.evidence_hash IS 'SHA-256 của bằng chứng đóng kỳ (danh sách quyết định), bắt buộc khi CLOSED.';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.access_review_cycle CASCADE; DROP FUNCTION IF EXISTS ph01_onboarding.tg_access_review_cycle_guard();

-- @changeset ph01-0410-review-confirmation
CREATE TABLE ph01_onboarding.review_confirmation (
  id              uuid          NOT NULL,
  tenant_id       varchar(16)   NOT NULL,
  cycle_id        uuid          NOT NULL,
  org_id          varchar(64)   NOT NULL,
  link_hash       char(64)      NOT NULL,
  status          varchar(9)    NOT NULL DEFAULT 'PENDING',
  sent_at         timestamptz   NOT NULL DEFAULT now(),
  expires_at      timestamptz   NOT NULL,
  reminder_sent_at timestamptz,
  responded_at    timestamptz,
  responder_id    varchar(64),
  created_at      timestamptz   NOT NULL DEFAULT now(),
  created_by      varchar(64)   NOT NULL,
  updated_at      timestamptz   NOT NULL DEFAULT now(),
  updated_by      varchar(64)   NOT NULL,
  version         integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_review_confirmation PRIMARY KEY (id),
  CONSTRAINT uq_review_confirmation_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_review_confirmation_org UNIQUE (tenant_id, cycle_id, org_id),
  CONSTRAINT uq_review_confirmation_link UNIQUE (link_hash),
  CONSTRAINT fk_review_confirmation_cycle FOREIGN KEY (cycle_id, tenant_id) REFERENCES ph01_onboarding.access_review_cycle (id, tenant_id),
  CONSTRAINT ck_review_confirmation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_review_confirmation_hash CHECK (link_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_review_confirmation_status CHECK (status IN ('PENDING', 'RESPONDED', 'EXPIRED')),
  CONSTRAINT ck_review_confirmation_ttl CHECK (expires_at > sent_at AND expires_at <= sent_at + interval '60 days'),
  CONSTRAINT ck_review_confirmation_responded CHECK ((status = 'RESPONDED') = (responded_at IS NOT NULL AND responder_id IS NOT NULL))
);
CREATE INDEX ix_review_confirmation_due ON ph01_onboarding.review_confirmation (tenant_id, expires_at) WHERE status = 'PENDING';
CREATE TRIGGER tg_review_confirmation_touch BEFORE UPDATE ON ph01_onboarding.review_confirmation FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.review_confirmation', 'P');
COMMENT ON TABLE ph01_onboarding.review_confirmation IS 'EN-01-16 Phiếu xác nhận gửi đơn vị chủ quản mỗi kỳ rà soát, mỗi tổ chức một phiếu; chỉ lưu SHA-256 của liên kết, trang xác nhận bắt đăng nhập đúng tổ chức (FR-01-041; BR-01-014).';
COMMENT ON COLUMN ph01_onboarding.review_confirmation.org_id IS 'Mã tổ chức ở PH-20 được hỏi; người mở phải thuộc tổ chức này (ERR-01-025).';
COMMENT ON COLUMN ph01_onboarding.review_confirmation.expires_at IS 'Hạn phiếu = sent_at cộng accessReview.confirmLinkTtlDays (mặc định 30 ngày); trần cứng 60 ngày.';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.review_confirmation CASCADE;

-- @changeset ph01-0420-access-review-item
CREATE TABLE ph01_onboarding.access_review_item (
  id                  uuid          NOT NULL,
  tenant_id           varchar(16)   NOT NULL,
  cycle_id            uuid          NOT NULL,
  member_system_id    uuid          NOT NULL,
  scope_ceiling_id    uuid          NOT NULL,
  org_id              varchar(64)   NOT NULL,
  data_type           varchar(64)   NOT NULL,
  scope_snapshot      varchar(200)  NOT NULL,
  usage_in_period     bigint,
  unused_days         integer,
  flags               varchar(20)[] NOT NULL DEFAULT '{}',
  legal_expired       boolean       NOT NULL DEFAULT false,
  proposal            varchar(12),
  proposal_reason     varchar(500),
  confirmation_id     uuid,
  owner_response      varchar(7),
  owner_scope_proposed varchar(200),
  owner_responded_at  timestamptz,
  responder_id        varchar(64),
  decision            varchar(12),
  decision_reason     varchar(1000),
  scope_after         varchar(200),
  decided_by          varchar(64),
  decided_at          timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_access_review_item PRIMARY KEY (id),
  CONSTRAINT uq_access_review_item UNIQUE (tenant_id, cycle_id, scope_ceiling_id),
  CONSTRAINT fk_access_review_item_cycle FOREIGN KEY (cycle_id, tenant_id) REFERENCES ph01_onboarding.access_review_cycle (id, tenant_id),
  CONSTRAINT fk_access_review_item_system FOREIGN KEY (member_system_id, tenant_id) REFERENCES ph01_onboarding.member_system (id, tenant_id),
  CONSTRAINT fk_access_review_item_ceiling FOREIGN KEY (scope_ceiling_id, tenant_id) REFERENCES ph01_onboarding.scope_ceiling (id, tenant_id),
  CONSTRAINT fk_access_review_item_confirmation FOREIGN KEY (confirmation_id, tenant_id) REFERENCES ph01_onboarding.review_confirmation (id, tenant_id),
  CONSTRAINT ck_access_review_item_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_access_review_item_usage CHECK ((usage_in_period IS NULL OR usage_in_period >= 0) AND (unused_days IS NULL OR unused_days >= 0)),
  CONSTRAINT ck_access_review_item_flags CHECK (flags <@ ARRAY['UNUSED_IN_PERIOD', 'UNUSED_OVER_12M', 'CREDENTIAL_EXPIRING', 'LEGAL_EXPIRED', 'NO_USAGE_DATA']::varchar[]),
  CONSTRAINT ck_access_review_item_proposal CHECK (proposal IS NULL OR proposal IN ('KEEP', 'REDUCE', 'REVOKE_SCOPE')),
  CONSTRAINT ck_access_review_item_response CHECK (owner_response IS NULL OR owner_response IN ('KEEP', 'REDUCE', 'RELEASE')),
  CONSTRAINT ck_access_review_item_response_who CHECK ((owner_response IS NULL) = (owner_responded_at IS NULL AND responder_id IS NULL)),
  CONSTRAINT ck_access_review_item_reduce CHECK (owner_response IS DISTINCT FROM 'REDUCE' OR owner_scope_proposed IS NOT NULL),
  CONSTRAINT ck_access_review_item_decision CHECK (decision IS NULL OR decision IN ('KEEP', 'REDUCE', 'REVOKE_SCOPE')),
  CONSTRAINT ck_access_review_item_decision_who CHECK ((decision IS NULL) = (decided_by IS NULL AND decided_at IS NULL AND decision_reason IS NULL)),
  CONSTRAINT ck_access_review_item_scope_after CHECK (decision IS DISTINCT FROM 'REDUCE' OR scope_after IS NOT NULL),
  CONSTRAINT ck_access_review_item_legal CHECK (NOT (decision = 'KEEP' AND legal_expired))
);
CREATE INDEX ix_access_review_item_cycle ON ph01_onboarding.access_review_item (tenant_id, cycle_id, org_id);
CREATE INDEX ix_access_review_item_open ON ph01_onboarding.access_review_item (tenant_id, cycle_id) WHERE decision IS NULL;
CREATE INDEX ix_access_review_item_system ON ph01_onboarding.access_review_item (tenant_id, member_system_id);
CREATE TRIGGER tg_access_review_item_touch BEFORE UPDATE ON ph01_onboarding.access_review_item FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.access_review_item', 'P');
COMMENT ON TABLE ph01_onboarding.access_review_item IS 'EN-01-15 Mục rà soát: một dòng cho mỗi cặp (HTTT, mục trần) của kỳ, ghi mức dùng thực tế, phản hồi của đơn vị và quyết định; giữ 5 năm (FR-01-040…043; BR-01-014, 015).';
COMMENT ON COLUMN ph01_onboarding.access_review_item.scope_snapshot IS 'Phạm vi của trần tại lúc mở kỳ, để so với scope_after và làm bằng chứng.';
COMMENT ON COLUMN ph01_onboarding.access_review_item.usage_in_period IS 'Số lượt gọi thành công trong kỳ theo PH-13; NULL khi chưa có số liệu (cờ NO_USAGE_DATA, ERR-01-046).';
COMMENT ON COLUMN ph01_onboarding.access_review_item.flags IS 'Cờ cảnh báo: UNUSED_IN_PERIOD, UNUSED_OVER_12M (theo accessReview.unusedDays), CREDENTIAL_EXPIRING, LEGAL_EXPIRED, NO_USAGE_DATA.';
COMMENT ON COLUMN ph01_onboarding.access_review_item.decision IS 'Quyết định KEEP, REDUCE (kèm scope_after), REVOKE_SCOPE; không được KEEP khi legal_expired (ERR-01-041); bắt buộc lý do và người quyết định.';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.access_review_item CASCADE;

-- @changeset ph01-0430-legacy-import-job
CREATE TABLE ph01_onboarding.legacy_import_job (
  id                uuid          NOT NULL,
  tenant_id         varchar(16)   NOT NULL,
  source_kind       varchar(4)    NOT NULL,
  file_name         varchar(255)  NOT NULL,
  file_sha256       char(64)      NOT NULL,
  file_object_key   varchar(512),
  file_deleted_at   timestamptz,
  status            varchar(9)    NOT NULL DEFAULT 'UPLOADED',
  row_count         integer       NOT NULL DEFAULT 0,
  created_count     integer       NOT NULL DEFAULT 0,
  duplicate_count   integer       NOT NULL DEFAULT 0,
  warning_count     integer       NOT NULL DEFAULT 0,
  dropped_columns   integer       NOT NULL DEFAULT 0,
  secrets_dropped   integer       NOT NULL DEFAULT 0,
  preview           jsonb,
  warnings          jsonb         NOT NULL DEFAULT '[]',
  requested_by      varchar(64)   NOT NULL,
  confirmed_by      varchar(64),
  confirmed_at      timestamptz,
  finished_at       timestamptz,
  error_code        varchar(16),
  created_at        timestamptz   NOT NULL DEFAULT now(),
  created_by        varchar(64)   NOT NULL,
  updated_at        timestamptz   NOT NULL DEFAULT now(),
  updated_by        varchar(64)   NOT NULL,
  version           integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_legacy_import_job PRIMARY KEY (id),
  CONSTRAINT ck_legacy_import_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_legacy_import_job_kind CHECK (source_kind IN ('CSV', 'XLSX', 'JSON')),
  CONSTRAINT ck_legacy_import_job_sha CHECK (file_sha256 ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_legacy_import_job_status CHECK (status IN ('UPLOADED', 'PARSING', 'PREVIEWED', 'CONFIRMED', 'DONE', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_legacy_import_job_rows CHECK (row_count BETWEEN 0 AND 20000 AND created_count >= 0 AND duplicate_count >= 0 AND warning_count >= 0
                                          AND dropped_columns >= 0 AND secrets_dropped >= 0 AND created_count + duplicate_count <= row_count),
  CONSTRAINT ck_legacy_import_job_confirmed CHECK (status NOT IN ('CONFIRMED', 'DONE') OR (confirmed_by IS NOT NULL AND confirmed_at IS NOT NULL)),
  CONSTRAINT ck_legacy_import_job_finished CHECK ((status IN ('DONE', 'FAILED', 'CANCELLED')) = (finished_at IS NOT NULL)),
  CONSTRAINT ck_legacy_import_job_file CHECK ((file_object_key IS NULL) = (file_deleted_at IS NOT NULL)),
  CONSTRAINT ck_legacy_import_job_json CHECK (jsonb_typeof(warnings) = 'array' AND (preview IS NULL OR jsonb_typeof(preview) IN ('object', 'array'))),
  CONSTRAINT ck_legacy_import_job_no_secret CHECK (coalesce(preview::text, '') !~* '"(password|passwd|secret|client_?secret|api_?key|token|private_?key|passphrase)"\s*:')
);
CREATE INDEX ix_legacy_import_job_status ON ph01_onboarding.legacy_import_job (tenant_id, status, created_at DESC);
CREATE INDEX ix_legacy_import_job_file ON ph01_onboarding.legacy_import_job (file_deleted_at, created_at) WHERE file_object_key IS NOT NULL;
CREATE TRIGGER tg_legacy_import_job_touch BEFORE UPDATE ON ph01_onboarding.legacy_import_job FOR EACH ROW EXECUTE FUNCTION ph01_onboarding.tg_touch();
CALL ph01_onboarding.p_enable_rls('ph01_onboarding.legacy_import_job', 'P');
COMMENT ON TABLE ph01_onboarding.legacy_import_job IS 'EN-01-17 Tác vụ nhập HTTT từ hệ cũ hai pha: tải và xem trước, rồi xác nhận một giao dịch (FR-01-048, BR-01-033). Không mang thông tin xác thực: cột thông tin xác thực không bao giờ đọc, chỉ đếm; tệp gốc xóa sau 7 ngày, chỉ giữ băm.';
COMMENT ON COLUMN ph01_onboarding.legacy_import_job.secrets_dropped IS 'Số giá trị giống bí mật (độ dài ≥ 20 và entropy ≥ 3,5 bit mỗi ký tự, hoặc khớp mẫu khóa API) đã bỏ ở các cột không khai báo (SecretLikeDetector).';
COMMENT ON COLUMN ph01_onboarding.legacy_import_job.preview IS 'Kết quả xem trước (hồ sơ sẽ tạo, tổ chức đã ghép); ràng buộc chặn khóa có tên bí mật như lớp phòng thủ thứ hai.';
COMMENT ON COLUMN ph01_onboarding.legacy_import_job.file_object_key IS 'Khóa tệp gốc ở kho tạm; đặt NULL cùng file_deleted_at khi xóa sau 7 ngày.';
COMMENT ON COLUMN ph01_onboarding.legacy_import_job.row_count IS 'Số dòng đọc được, tối đa legacyImport.maxRows (trần cứng 20.000); nhập lại cùng tệp bỏ qua HTTT trùng (tenant_id, legacy_ref).';
-- @rollback DROP TABLE IF EXISTS ph01_onboarding.legacy_import_job CASCADE;
