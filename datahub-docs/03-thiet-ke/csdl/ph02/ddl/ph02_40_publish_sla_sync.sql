-- =============================================================================
-- D03-03-PH02 · Tệp 40: thông báo thay đổi, SLA, thống kê, đồng bộ quốc gia,
-- dữ liệu công bố cho gateway, công bố có xác nhận, đối soát cấu hình
-- Chạy sau ph02_30_lifecycle.sql (cùng phiên, đang SET ROLE ph02_owner).
-- =============================================================================

-- @file 02-0040-publish-sla-sync.sql
-- @changeset ph02-0400-change-notice
CREATE TABLE ph02_catalog.change_notice (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_version_id   uuid          NOT NULL,
  kind             varchar(22)   NOT NULL,
  mandatory        boolean       NOT NULL DEFAULT true,
  subject          varchar(255)  NOT NULL,
  body             varchar(4000) NOT NULL,
  template_code    varchar(32),
  template_version smallint,
  recipient_count  integer       NOT NULL DEFAULT 0,
  status           varchar(7)    NOT NULL DEFAULT 'QUEUED',
  issued_by        varchar(64)   NOT NULL,
  issued_at        timestamptz   NOT NULL DEFAULT now(),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_change_notice PRIMARY KEY (id),
  CONSTRAINT uq_change_notice_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT fk_change_notice_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT ck_change_notice_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_change_notice_kind CHECK (kind IN ('BREAKING_VERSION', 'DEPRECATION', 'SUSPENSION', 'RESUMPTION', 'RETIREMENT', 'SLA_WORSEN', 'VISIBILITY_DOWN', 'SUBSCRIPTION_DECISION', 'ANNOUNCEMENT')),
  CONSTRAINT ck_change_notice_mandatory CHECK (kind = 'ANNOUNCEMENT' OR mandatory),
  CONSTRAINT ck_change_notice_status CHECK (status IN ('QUEUED', 'SENDING', 'SENT', 'PARTIAL', 'FAILED')),
  CONSTRAINT ck_change_notice_recipients CHECK (recipient_count >= 0)
);
CREATE INDEX ix_change_notice_version ON ph02_catalog.change_notice (tenant_id, api_version_id, issued_at DESC);
CREATE INDEX ix_change_notice_open ON ph02_catalog.change_notice (tenant_id, status) WHERE status IN ('QUEUED', 'SENDING', 'PARTIAL');
CREATE TRIGGER tg_change_notice_touch BEFORE UPDATE ON ph02_catalog.change_notice FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.change_notice', 'P');
COMMENT ON TABLE ph02_catalog.change_notice IS 'EN-02-11 Thông báo thay đổi gửi bên khai thác (FR-02-057). Loại bắt buộc (phiên bản phá vỡ, ngừng khuyến nghị, tạm ngừng, tiếp tục, ngừng hẳn, SLA kém đi, hạ mức hiển thị, quyết định đăng ký) bên nhận không tắt được (BR-02-029, ck_change_notice_mandatory); chỉ ANNOUNCEMENT (thông báo tay của SV) là không bắt buộc, giới hạn 02.notice.announcement-max-per-day. Giữ 2 năm (NFR-02-017).';
COMMENT ON COLUMN ph02_catalog.change_notice.body IS 'Nội dung đã qua mẫu NoticeTemplates, giá trị chèn đã thoát ký tự và cắt độ dài; không liệt kê các bên khai thác khác.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.change_notice CASCADE;

-- @changeset ph02-0410-change-notice-recipient
CREATE TABLE ph02_catalog.change_notice_recipient (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  notice_id        uuid          NOT NULL,
  recipient_ref    varchar(128)  NOT NULL,
  system_code      varchar(64)   NOT NULL,
  channel          varchar(6)    NOT NULL,
  status           varchar(9)    NOT NULL DEFAULT 'PENDING',
  attempts         smallint      NOT NULL DEFAULT 0,
  error_code       varchar(16),
  delivered_at     timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_change_notice_recipient PRIMARY KEY (id),
  CONSTRAINT uq_change_notice_recipient UNIQUE (notice_id, recipient_ref, channel),
  CONSTRAINT fk_change_notice_recipient_notice FOREIGN KEY (notice_id, tenant_id) REFERENCES ph02_catalog.change_notice (id, tenant_id) ON DELETE CASCADE,
  CONSTRAINT ck_change_notice_recipient_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_change_notice_recipient_channel CHECK (channel IN ('IN_APP', 'EMAIL')),
  CONSTRAINT ck_change_notice_recipient_status CHECK (status IN ('PENDING', 'SENT', 'DELIVERED', 'FAILED')),
  CONSTRAINT ck_change_notice_recipient_delivered CHECK ((status = 'DELIVERED') = (delivered_at IS NOT NULL))
);
CREATE INDEX ix_change_notice_recipient_pending ON ph02_catalog.change_notice_recipient (tenant_id, notice_id) WHERE status IN ('PENDING', 'FAILED');
CREATE INDEX ix_change_notice_recipient_system ON ph02_catalog.change_notice_recipient (tenant_id, system_code, created_at DESC);
CREATE TRIGGER tg_change_notice_recipient_touch BEFORE UPDATE ON ph02_catalog.change_notice_recipient FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.change_notice_recipient', 'P');
COMMENT ON TABLE ph02_catalog.change_notice_recipient IS 'Người nhận và kết quả gửi theo từng kênh (FR-02-057, NFR-02-015). recipient_ref là mã người dùng hoặc đầu mối ở PH-01, không lưu địa chỉ thư; PH-18 phân giải khi gửi. Khóa duy nhất (notice, recipient, channel) tương ứng khóa lũy đẳng {noticeId}:{recipient}:{channel} gọi PH-18, nên gửi lại sau sự cố không tạo thư trùng.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.change_notice_recipient CASCADE;

-- @changeset ph02-0420-sla-commitment
CREATE TABLE ph02_catalog.sla_commitment (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_version_id   uuid          NOT NULL,
  latency_p99_ms   integer       NOT NULL,
  availability_pct numeric(6,3)  NOT NULL,
  hourly_limit     integer,
  service_hours    jsonb         NOT NULL DEFAULT '{"mode":"24x7"}',
  worsening        boolean       NOT NULL DEFAULT false,
  notice_id        uuid,
  effective_from   timestamptz   NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_sla_commitment PRIMARY KEY (id),
  CONSTRAINT uq_sla_commitment_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_sla_commitment_effective UNIQUE (api_version_id, effective_from),
  CONSTRAINT fk_sla_commitment_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT fk_sla_commitment_notice FOREIGN KEY (notice_id, tenant_id) REFERENCES ph02_catalog.change_notice (id, tenant_id),
  CONSTRAINT ck_sla_commitment_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_sla_commitment_latency CHECK (latency_p99_ms BETWEEN 1 AND 600000),
  CONSTRAINT ck_sla_commitment_availability CHECK (availability_pct > 0 AND availability_pct <= 100),
  CONSTRAINT ck_sla_commitment_hourly CHECK (hourly_limit IS NULL OR hourly_limit > 0),
  CONSTRAINT ck_sla_commitment_hours CHECK (jsonb_typeof(service_hours) = 'object'),
  CONSTRAINT ck_sla_commitment_worsen CHECK (NOT worsening OR (notice_id IS NOT NULL AND effective_from >= created_at + interval '7 days'))
);
CREATE INDEX ix_sla_commitment_version ON ph02_catalog.sla_commitment (tenant_id, api_version_id, effective_from DESC);
CREATE TRIGGER tg_sla_commitment_append_only BEFORE UPDATE OR DELETE ON ph02_catalog.sla_commitment FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_append_only();
CALL ph02_catalog.p_enable_rls('ph02_catalog.sla_commitment', 'P');
COMMENT ON TABLE ph02_catalog.sla_commitment IS 'EN-02-08 Cam kết SLA của phiên bản (FR-02-055): độ trễ p99, tỷ lệ sẵn sàng, hạn mức giờ, giờ phục vụ. Chỉ thêm; mỗi lần khai báo là một dòng có effective_from, giữ vĩnh viễn (NFR-02-017). Cam kết kém đi chỉ có hiệu lực sau ít nhất 7 ngày kể từ lúc phát thông báo bắt buộc (worsening, notice_id; 02.sla.worsen-notice-days từ 7 đến 180 kiểm ở dịch vụ, BR-02-029).';
COMMENT ON COLUMN ph02_catalog.sla_commitment.availability_pct IS 'Tỷ lệ sẵn sàng cam kết theo phần trăm, ví dụ 99.500; đo bằng 1 − lượt lỗi hệ thống / tổng lượt gọi (Q02-13).';
COMMENT ON COLUMN ph02_catalog.sla_commitment.service_hours IS '{"mode":"24x7"} hoặc {"mode":"WINDOW","days":[1,2,3,4,5],"from":"07:30","to":"17:00","tz":"Asia/Ho_Chi_Minh"}.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.sla_commitment CASCADE;

-- @changeset ph02-0430-sla-maintenance-window
CREATE TABLE ph02_catalog.sla_maintenance_window (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_version_id   uuid          NOT NULL,
  starts_at        timestamptz   NOT NULL,
  ends_at          timestamptz   NOT NULL,
  reason           varchar(1000) NOT NULL,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_sla_maintenance_window PRIMARY KEY (id),
  CONSTRAINT fk_sla_maintenance_window_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT ck_sla_maintenance_window_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_sla_maintenance_window_range CHECK (ends_at > starts_at AND ends_at - starts_at <= interval '24 hours'),
  CONSTRAINT ex_sla_maintenance_window_overlap EXCLUDE USING gist (tenant_id WITH =, api_version_id WITH =, tstzrange(starts_at, ends_at) WITH &&)
);
CREATE TRIGGER tg_sla_maintenance_window_touch BEFORE UPDATE ON ph02_catalog.sla_maintenance_window FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.sla_maintenance_window', 'P');
COMMENT ON TABLE ph02_catalog.sla_maintenance_window IS 'Cửa sổ bảo trì đã khai báo; SlaEvaluator trừ khoảng này khi tính tỷ lệ sẵn sàng (FR-02-056). Mỗi cửa sổ không quá 24 giờ và không chồng nhau trong một phiên bản (ex_sla_maintenance_window_overlap).';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.sla_maintenance_window CASCADE;

-- @changeset ph02-0440-sla-period
CREATE TABLE ph02_catalog.sla_period (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_version_id   uuid          NOT NULL,
  period           char(7)       NOT NULL,
  result_version   integer       NOT NULL DEFAULT 1,
  is_current       boolean       NOT NULL DEFAULT true,
  commitment_id    uuid,
  status           varchar(12)   NOT NULL DEFAULT 'PENDING',
  met              boolean,
  actual           jsonb         NOT NULL DEFAULT '{}',
  recalculated_at  timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_sla_period PRIMARY KEY (id),
  CONSTRAINT uq_sla_period_result UNIQUE (api_version_id, period, result_version),
  CONSTRAINT fk_sla_period_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT fk_sla_period_commitment FOREIGN KEY (commitment_id, tenant_id) REFERENCES ph02_catalog.sla_commitment (id, tenant_id),
  CONSTRAINT ck_sla_period_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_sla_period_format CHECK (period ~ '^[0-9]{4}-(0[1-9]|1[0-2])$'),
  CONSTRAINT ck_sla_period_status CHECK (status IN ('PENDING', 'MET', 'BREACHED', 'INSUFFICIENT')),
  CONSTRAINT ck_sla_period_met CHECK ((status IN ('MET', 'BREACHED')) = (met IS NOT NULL) AND (met IS NULL OR met = (status = 'MET'))),
  CONSTRAINT ck_sla_period_actual CHECK (jsonb_typeof(actual) = 'object'),
  CONSTRAINT ck_sla_period_result CHECK (result_version >= 1 AND (result_version = 1 OR recalculated_at IS NOT NULL))
);
CREATE UNIQUE INDEX uq_sla_period_current ON ph02_catalog.sla_period (api_version_id, period) WHERE is_current;
CREATE INDEX ix_sla_period_pending ON ph02_catalog.sla_period (tenant_id, period) WHERE status = 'PENDING' AND is_current;
CREATE INDEX ix_sla_period_breach ON ph02_catalog.sla_period (tenant_id, api_version_id, period DESC) WHERE is_current AND status = 'BREACHED';
CREATE TRIGGER tg_sla_period_touch BEFORE UPDATE ON ph02_catalog.sla_period FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.sla_period', 'P');
COMMENT ON TABLE ph02_catalog.sla_period IS 'Kết quả đối chiếu SLA theo kỳ tháng YYYY-MM (FR-02-056). INSUFFICIENT là "Chưa đủ dữ liệu", không tính vào chuỗi không đạt (BR-02-031). "Chốt lại kỳ" tạo dòng result_version mới và hạ is_current của dòng cũ, không xóa kết quả cũ. Giữ 3 năm (NFR-02-017).';
COMMENT ON COLUMN ph02_catalog.sla_period.actual IS 'Số đo từ PH-13: {p99Ms, calls, systemErrors, daysWithData, peakHourly, availabilityPct, excludedMinutes}.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.sla_period CASCADE;

-- @changeset ph02-0450-usage-daily
CREATE TABLE ph02_catalog.usage_daily (
  tenant_id        varchar(16)   NOT NULL,
  api_version_id   uuid          NOT NULL,
  usage_date       date          NOT NULL,
  operation_id     varchar(128)  NOT NULL,
  consumer_system_code varchar(64) NOT NULL,
  calls            bigint        NOT NULL DEFAULT 0,
  errors           bigint        NOT NULL DEFAULT 0,
  p95_ms           integer,
  refreshed_at     timestamptz   NOT NULL DEFAULT now(),
  CONSTRAINT pk_usage_daily PRIMARY KEY (tenant_id, api_version_id, usage_date, operation_id, consumer_system_code),
  CONSTRAINT fk_usage_daily_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT ck_usage_daily_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_usage_daily_counts CHECK (calls >= 0 AND errors >= 0 AND errors <= calls),
  CONSTRAINT ck_usage_daily_p95 CHECK (p95_ms IS NULL OR p95_ms >= 0)
) PARTITION BY RANGE (usage_date);
CREATE INDEX ix_usage_daily_consumer ON ph02_catalog.usage_daily (tenant_id, consumer_system_code, usage_date);
CALL ph02_catalog.p_enable_rls('ph02_catalog.usage_daily', 'P');
CALL ph02_catalog.p_ensure_month_partitions('ph02_catalog.usage_daily', now()::date, 4);
COMMENT ON TABLE ph02_catalog.usage_daily IS 'Thống kê sử dụng theo ngày, thao tác, HTTT khai thác, kéo từ PH-13 mỗi giờ cho ngày hiện tại (FR-02-058, Đợt 2). Khóa tự nhiên, không có id; phân vùng tháng theo usage_date, giữ 2 năm (giả định, Q02-50). SV, CA, TA thấy chi tiết theo HTTT; VW chỉ thấy tổng hợp không tên bên khai thác (tính ở dịch vụ). Không chứa nội dung bản tin.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.usage_daily CASCADE;

-- @changeset ph02-0460-national-sync-record
CREATE TABLE ph02_catalog.national_sync_record (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  api_version_id   uuid          NOT NULL,
  action           varchar(8)    NOT NULL,
  status           varchar(8)    NOT NULL DEFAULT 'QUEUED',
  payload_hash     char(64)      NOT NULL,
  national_ref     varchar(128),
  reject_code      varchar(32),
  reject_reason    varchar(1000),
  attempts         smallint      NOT NULL DEFAULT 0,
  next_attempt_at  timestamptz   NOT NULL DEFAULT now(),
  sent_at          timestamptz,
  acked_at         timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_national_sync_record PRIMARY KEY (id),
  CONSTRAINT fk_national_sync_record_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT ck_national_sync_record_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_national_sync_record_action CHECK (action IN ('UPSERT', 'WITHDRAW')),
  CONSTRAINT ck_national_sync_record_status CHECK (status IN ('QUEUED', 'SENT', 'ACKED', 'REJECTED', 'FAILED')),
  CONSTRAINT ck_national_sync_record_hash CHECK (payload_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_national_sync_record_acked CHECK (status <> 'ACKED' OR (national_ref IS NOT NULL AND acked_at IS NOT NULL)),
  CONSTRAINT ck_national_sync_record_rejected CHECK (status <> 'REJECTED' OR (reject_code IS NOT NULL AND length(btrim(coalesce(reject_reason, ''))) > 0)),
  CONSTRAINT ck_national_sync_record_sent CHECK (status IN ('QUEUED') OR sent_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_national_sync_record_pending ON ph02_catalog.national_sync_record (tenant_id, api_version_id, payload_hash)
  WHERE status IN ('QUEUED', 'SENT', 'FAILED');
CREATE INDEX ix_national_sync_record_due ON ph02_catalog.national_sync_record (next_attempt_at) WHERE status IN ('QUEUED', 'FAILED');
CREATE INDEX ix_national_sync_record_version ON ph02_catalog.national_sync_record (tenant_id, api_version_id, created_at DESC);
CREATE INDEX ix_national_sync_record_acked ON ph02_catalog.national_sync_record (tenant_id, api_version_id, acked_at DESC) WHERE status = 'ACKED';
CREATE TRIGGER tg_national_sync_record_touch BEFORE UPDATE ON ph02_catalog.national_sync_record FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.national_sync_record', 'P');
COMMENT ON TABLE ph02_catalog.national_sync_record IS 'EN-02-10 Hàng đợi bền đồng bộ danh mục lên Nền tảng quốc gia qua PH-14 (FR-02-053, 054; BR-02-009). Xếp hàng trong cùng giao dịch với thay đổi gốc (ADR-042, ADR-057). Khóa duy nhất từng phần (version, payload_hash) khi chưa kết thúc làm cho xếp hàng lặp lại vô hại; sau ACKED hoặc REJECTED cho phép bản ghi mới cùng băm (lệch so với SDD 4.11, ghi ở 3.x của tài liệu). Giữ 5 năm (NFR-02-017). Giao thức còn chờ đặc tả (Q02-08).';
COMMENT ON COLUMN ph02_catalog.national_sync_record.payload_hash IS 'Băm chuẩn của NationalServicePayload (mã dịch vụ, tên, mô tả, đơn vị, mức phân loại, địa chỉ công khai, SLA, trạng thái, đầu mối); đồng thời là Idempotency-Key gọi PH-14. Gói không có backend, địa chỉ nội bộ, danh sách bên đăng ký hay dữ liệu cá nhân.';
COMMENT ON COLUMN ph02_catalog.national_sync_record.status IS 'QUEUED, SENT, ACKED, REJECTED, FAILED; lỗi tạm thời FAILED lùi dần 1, 5, 15, 60 phút rồi mỗi 6 giờ; REJECTED không tự gửi lại khi nội dung không đổi.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.national_sync_record CASCADE;

-- @changeset ph02-0470-national-sync-run
CREATE TABLE ph02_catalog.national_sync_run (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  trigger_kind     varchar(6)    NOT NULL,
  status           varchar(7)    NOT NULL DEFAULT 'RUNNING',
  started_at       timestamptz   NOT NULL DEFAULT now(),
  finished_at      timestamptz,
  eligible_count   integer       NOT NULL DEFAULT 0,
  queued_count     integer       NOT NULL DEFAULT 0,
  overdue_count    integer       NOT NULL DEFAULT 0,
  error_code       varchar(16),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_national_sync_run PRIMARY KEY (id),
  CONSTRAINT ck_national_sync_run_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_national_sync_run_trigger CHECK (trigger_kind IN ('CRON', 'MANUAL', 'EVENT')),
  CONSTRAINT ck_national_sync_run_status CHECK (status IN ('RUNNING', 'DONE', 'FAILED')),
  CONSTRAINT ck_national_sync_run_finished CHECK ((status = 'RUNNING') = (finished_at IS NULL)),
  CONSTRAINT ck_national_sync_run_counts CHECK (eligible_count >= 0 AND queued_count >= 0 AND overdue_count >= 0)
);
CREATE INDEX ix_national_sync_run_started ON ph02_catalog.national_sync_run (tenant_id, started_at DESC);
CREATE TRIGGER tg_national_sync_run_touch BEFORE UPDATE ON ph02_catalog.national_sync_run FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.national_sync_run', 'P');
COMMENT ON TABLE ph02_catalog.national_sync_run IS 'Lần chạy đối chiếu danh mục quốc gia theo 02.sync.cron hoặc lệnh "Đồng bộ ngay" (FR-02-054): số phiên bản đủ điều kiện, số đã xếp hàng, số quá hạn (căn cứ chỉ số catalog_national_sync_overdue_total). Giữ 5 năm cùng national_sync_record.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.national_sync_run CASCADE;

-- @changeset ph02-0480-config-epoch
CREATE TABLE ph02_catalog.config_epoch (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  env              varchar(8)    NOT NULL,
  source_version   bigint        NOT NULL DEFAULT 0,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_config_epoch PRIMARY KEY (id),
  CONSTRAINT uq_config_epoch UNIQUE (tenant_id, env),
  CONSTRAINT ck_config_epoch_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_config_epoch_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_config_epoch_source CHECK (source_version >= 0)
);
CREATE OR REPLACE FUNCTION ph02_catalog.tg_config_epoch_monotonic() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.source_version < OLD.source_version THEN
    RAISE EXCEPTION 'source_version chỉ tăng (NFR-02-005)' USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
CREATE TRIGGER tg_config_epoch_monotonic BEFORE UPDATE ON ph02_catalog.config_epoch FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_config_epoch_monotonic();
CREATE TRIGGER tg_config_epoch_touch BEFORE UPDATE ON ph02_catalog.config_epoch FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.config_epoch', 'P');
COMMENT ON TABLE ph02_catalog.config_epoch IS 'Bộ đếm source_version theo (tenant, môi trường): thay đổi dữ liệu mà gateway cần biết gọi UPDATE … SET source_version = source_version + 1 RETURNING ở câu lệnh cuối của giao dịch, khóa dòng này tuần tự hóa các giao dịch cùng môi trường trong khoảng ngắn nhất (SDD 4.10). Là ETag của giao diện nội bộ API-02-080 (FR-02-059). source_version chỉ tăng (tg_config_epoch_monotonic). Dòng được tạo khi cấp phát tenant.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.config_epoch CASCADE;

-- @changeset ph02-0490-config-change-log
CREATE TABLE ph02_catalog.config_change_log (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  env              varchar(8)    NOT NULL,
  source_version   bigint        NOT NULL,
  change_kind      varchar(24)   NOT NULL,
  subject_kind     varchar(14)   NOT NULL,
  subject_id       uuid          NOT NULL,
  api_code         varchar(63),
  trace_id         char(32),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  CONSTRAINT pk_config_change_log PRIMARY KEY (id, created_at),
  CONSTRAINT ck_config_change_log_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_config_change_log_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_config_change_log_subject CHECK (subject_kind IN ('API_VERSION', 'PLAN', 'SUBSCRIPTION', 'BACKEND', 'SLA')),
  CONSTRAINT ck_config_change_log_trace CHECK (trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$')
) PARTITION BY RANGE (created_at);
CREATE INDEX ix_config_change_log_epoch ON ph02_catalog.config_change_log (tenant_id, env, source_version);
CALL ph02_catalog.p_enable_rls('ph02_catalog.config_change_log', 'P');
CALL ph02_catalog.p_ensure_month_partitions('ph02_catalog.config_change_log', now()::date, 4);
COMMENT ON TABLE ph02_catalog.config_change_log IS 'Nhật ký thay đổi theo source_version để PH-03 gọi changesSince(sourceVersion) (FR-02-059). Giữ 30 ngày (dh.catalog.config.change-log-retention); hỏi quá cũ thì phản hồi gap = true để PH-03 lấy toàn bộ. Phân vùng tháng theo created_at, dọn bằng DETACH PARTITION. Tính duy nhất của (tenant, env, source_version) do khóa dòng config_epoch bảo đảm.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.config_change_log CASCADE;

-- @changeset ph02-0500-publish-job
CREATE TABLE ph02_catalog.publish_job (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  env              varchar(8)    NOT NULL,
  subject_kind     varchar(12)   NOT NULL,
  subject_id       uuid          NOT NULL,
  transition       varchar(24)   NOT NULL,
  policy           varchar(18)   NOT NULL,
  target_source_version bigint   NOT NULL,
  status           varchar(12)   NOT NULL DEFAULT 'QUEUED',
  attempts         smallint      NOT NULL DEFAULT 0,
  next_attempt_at  timestamptz   NOT NULL DEFAULT now(),
  ticket           varchar(64),
  last_error_code  varchar(16),
  confirmed_at     timestamptz,
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_publish_job PRIMARY KEY (id),
  CONSTRAINT ck_publish_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_publish_job_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_publish_job_subject CHECK (subject_kind IN ('API_VERSION', 'PLAN', 'SUBSCRIPTION')),
  CONSTRAINT ck_publish_job_policy CHECK (policy IN ('CONFIRM_THEN_WRITE', 'WRITE_THEN_CONFIRM')),
  CONSTRAINT ck_publish_job_status CHECK (status IN ('QUEUED', 'REQUESTED', 'CONFIRMED', 'FAILED_RETRY', 'FAILED')),
  CONSTRAINT ck_publish_job_attempts CHECK (attempts BETWEEN 0 AND 5),
  CONSTRAINT ck_publish_job_confirmed CHECK ((status = 'CONFIRMED') = (confirmed_at IS NOT NULL))
);
CREATE INDEX ix_publish_job_due ON ph02_catalog.publish_job (next_attempt_at) WHERE status IN ('QUEUED', 'FAILED_RETRY');
CREATE INDEX ix_publish_job_wait ON ph02_catalog.publish_job (tenant_id, env, target_source_version) WHERE status = 'REQUESTED';
CREATE INDEX ix_publish_job_subject ON ph02_catalog.publish_job (tenant_id, subject_kind, subject_id, created_at DESC);
CREATE TRIGGER tg_publish_job_touch BEFORE UPDATE ON ph02_catalog.publish_job FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.publish_job', 'P');
COMMENT ON TABLE ph02_catalog.publish_job IS 'Việc công bố có xác nhận (FR-02-036, 037, 048): tạo cùng giao dịch với quyết định; PublishJobWorker lấy bằng FOR UPDATE SKIP LOCKED, gọi GatewayApplyPort lũy đẳng theo (env, sourceVersion), chờ APISIX báo sourceVersion ≥ mục tiêu. Loại CONFIRM_THEN_WRITE (công bố, tiếp tục, cấp phạm vi) chỉ ghi trạng thái sau khi có xác nhận; WRITE_THEN_CONFIRM (tạm ngừng, ngừng, thu hồi) ghi ngay rồi xác nhận sau. Hết 5 lần thử trong khoảng 15 phút thì FAILED, phiên bản giữ PENDING (ERR-02-033).';
COMMENT ON COLUMN ph02_catalog.publish_job.target_source_version IS 'source_version của config_epoch tại thời điểm quyết định; gom nhiều việc cùng môi trường vào một xác nhận khi ack.sourceVersion ≥ giá trị này.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.publish_job CASCADE;

-- @changeset ph02-0510-gateway-drift
CREATE TABLE ph02_catalog.gateway_drift (
  id               uuid          NOT NULL,
  tenant_id        varchar(16)   NOT NULL,
  env              varchar(8)    NOT NULL,
  kind             varchar(18)   NOT NULL,
  route_ref        varchar(255)  NOT NULL,
  api_version_id   uuid,
  expected_hash    char(64),
  actual_hash      char(64),
  pod              varchar(64),
  status           varchar(12)   NOT NULL DEFAULT 'OPEN',
  detected_at      timestamptz   NOT NULL DEFAULT now(),
  resolved_at      timestamptz,
  resolved_by      varchar(64),
  created_at       timestamptz   NOT NULL DEFAULT now(),
  created_by       varchar(64)   NOT NULL,
  updated_at       timestamptz   NOT NULL DEFAULT now(),
  updated_by       varchar(64)   NOT NULL,
  version          integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_gateway_drift PRIMARY KEY (id),
  CONSTRAINT fk_gateway_drift_version FOREIGN KEY (api_version_id, tenant_id) REFERENCES ph02_catalog.api_version (id, tenant_id),
  CONSTRAINT ck_gateway_drift_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_gateway_drift_env CHECK (env IN ('TEST', 'STAGING', 'PROD')),
  CONSTRAINT ck_gateway_drift_kind CHECK (kind IN ('MISSING_ROUTE', 'EXTRA_ROUTE', 'UPSTREAM_MISMATCH', 'CONSUMER_MISMATCH', 'VERSION_BEHIND')),
  CONSTRAINT ck_gateway_drift_status CHECK (status IN ('OPEN', 'REPAIRED', 'ACKNOWLEDGED', 'RESOLVED')),
  CONSTRAINT ck_gateway_drift_resolved CHECK ((status = 'OPEN') = (resolved_at IS NULL))
);
CREATE UNIQUE INDEX uq_gateway_drift_open ON ph02_catalog.gateway_drift (tenant_id, env, kind, route_ref) WHERE status = 'OPEN';
CREATE INDEX ix_gateway_drift_detected ON ph02_catalog.gateway_drift (tenant_id, detected_at DESC);
CREATE TRIGGER tg_gateway_drift_touch BEFORE UPDATE ON ph02_catalog.gateway_drift FOR EACH ROW EXECUTE FUNCTION ph02_catalog.tg_touch();
CALL ph02_catalog.p_enable_rls('ph02_catalog.gateway_drift', 'P');
COMMENT ON TABLE ph02_catalog.gateway_drift IS 'Lệch cấu hình gateway so với dữ liệu công bố (FR-02-060, Đợt 2, NFR-02-020): DriftReconciler chạy 5 phút một lần, so băm nguồn của từng route. Route thừa (EXTRA_ROUTE) không tự gỡ mà cảnh báo SO vì có thể là tấn công hoặc sửa tay (SEC-65). Mỗi (môi trường, loại, route) chỉ một dòng OPEN.';
-- @rollback DROP TABLE IF EXISTS ph02_catalog.gateway_drift CASCADE;
