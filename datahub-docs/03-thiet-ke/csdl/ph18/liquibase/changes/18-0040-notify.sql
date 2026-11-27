--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0040-notify.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0300-notification-template splitStatements:false
CREATE TABLE ph18_ops.notification_template (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  template_code     varchar(64) NOT NULL,
  owner_module      varchar(8) NOT NULL,
  title             varchar(255) NOT NULL,
  description       varchar(1000),
  category          varchar(12) NOT NULL,
  channels          varchar(8)[] NOT NULL,
  mandatory         boolean NOT NULL DEFAULT false,
  urgent            boolean NOT NULL DEFAULT false,
  active_version_no integer,
  retired_at        timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_notification_template PRIMARY KEY (id),
  CONSTRAINT uq_notification_template_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_notification_template_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_notification_template_code UNIQUE (tenant_id, template_code),
  CONSTRAINT ck_notification_template_code CHECK (template_code ~ '^[a-z0-9]+(\.[a-z0-9-]+)+$'),
  CONSTRAINT ck_notification_template_module CHECK (owner_module ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_notification_template_category CHECK (category IN ('TASK', 'JOB_RESULT', 'ALERT', 'INFO')),
  CONSTRAINT ck_notification_template_channels CHECK (cardinality(channels) >= 1 AND channels <@ ARRAY['EMAIL', 'SMS', 'IN_APP']::varchar(8)[])
);
CREATE TRIGGER tg_notification_template_touch BEFORE UPDATE ON ph18_ops.notification_template FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_notification_template_immutable BEFORE UPDATE ON ph18_ops.notification_template FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('template_code', 'owner_module');
CALL ph18_ops.p_enable_rls('ph18_ops.notification_template', true);
COMMENT ON TABLE ph18_ops.notification_template IS 'EN-18-19 Mẫu thông báo (thư, SMS, trong ứng dụng) của các PH: mã mẫu, PH sở hữu, nhóm DD-13, thông báo bắt buộc (không tắt bằng tùy chọn), khẩn (bỏ qua giờ yên lặng). Dòng COMMON là mẫu mặc định nền tảng, tenant ghi đè cùng mã. Nội dung ở notification_template_version.';
--rollback DROP TABLE IF EXISTS ph18_ops.notification_template CASCADE;

--changeset ph18:ph18-0310-notification-template-version splitStatements:false
CREATE TABLE ph18_ops.notification_template_version (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  template_id        uuid NOT NULL,
  version_no         integer NOT NULL,
  locale             varchar(8) NOT NULL DEFAULT 'vi',
  email_subject      varchar(255),
  body_text          text,
  body_html          text,
  sms_text           varchar(480),
  in_app_title       varchar(255),
  in_app_link        varchar(500),
  allowed_fields     varchar(64)[] NOT NULL DEFAULT '{}',
  field_check_passed boolean NOT NULL DEFAULT false,
  field_check_report jsonb,
  status             varchar(12) NOT NULL DEFAULT 'DRAFT',
  submitted_at       timestamptz,
  reviewed_by        varchar(64),
  reviewed_at        timestamptz,
  activated_at       timestamptz,
  retired_at         timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_notification_template_version PRIMARY KEY (id),
  CONSTRAINT uq_notification_template_version_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_notification_template_version_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_notification_template_version_no UNIQUE (tenant_id, template_id, version_no, locale),
  CONSTRAINT fk_notification_template_version_template FOREIGN KEY (tenant_id, template_id) REFERENCES ph18_ops.notification_template (tenant_id, id),
  CONSTRAINT ck_notification_template_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_notification_template_version_status CHECK (status IN ('DRAFT', 'IN_REVIEW', 'ACTIVE', 'RETIRED')),
  CONSTRAINT ck_notification_template_version_content CHECK (body_text IS NOT NULL OR sms_text IS NOT NULL OR in_app_title IS NOT NULL),
  CONSTRAINT ck_notification_template_version_link CHECK (in_app_link IS NULL OR in_app_link ~ '^/[a-z0-9/_{}?=&.-]*$'),
  CONSTRAINT ck_notification_template_version_four_eyes CHECK (reviewed_by IS NULL OR reviewed_by <> created_by),
  CONSTRAINT ck_notification_template_version_active CHECK (status NOT IN ('ACTIVE', 'RETIRED') OR (field_check_passed AND reviewed_by IS NOT NULL AND activated_at IS NOT NULL)),
  CONSTRAINT ck_notification_template_version_no_logic CHECK (coalesce(body_text, '') || coalesce(body_html, '') || coalesce(sms_text, '') !~ '\{\{[#^/>]')
);
CREATE UNIQUE INDEX uq_notification_template_version_active ON ph18_ops.notification_template_version (tenant_id, template_id, locale) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_notification_template_version_touch BEFORE UPDATE ON ph18_ops.notification_template_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_notification_template_version_immutable BEFORE UPDATE ON ph18_ops.notification_template_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('template_id', 'version_no', 'locale');
CREATE TRIGGER tg_notification_template_version_frozen BEFORE UPDATE ON ph18_ops.notification_template_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_frozen('IN_REVIEW,ACTIVE,RETIRED', 'email_subject', 'body_text', 'body_html', 'sms_text', 'in_app_title', 'in_app_link', 'allowed_fields');
CREATE TRIGGER tg_notification_template_version_fsm_status BEFORE UPDATE ON ph18_ops.notification_template_version FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'DRAFT>IN_REVIEW,IN_REVIEW>DRAFT,IN_REVIEW>ACTIVE,ACTIVE>RETIRED');
CALL ph18_ops.p_enable_rls('ph18_ops.notification_template_version', true);
COMMENT ON TABLE ph18_ops.notification_template_version IS 'EN-18-20 Phiên bản nội dung mẫu Mustache không logic: tiêu đề thư, thân, SMS, tiêu đề và liên kết trong ứng dụng, danh sách biến cho phép. Duyệt (IN_REVIEW sang ACTIVE) chỉ khi kiểm tra cấm trường mức Hạn chế, Nhạy cảm đạt (FR-00-062); người duyệt khác người soạn. Từ IN_REVIEW nội dung bất biến; mỗi mẫu, ngôn ngữ một bản ACTIVE.';
COMMENT ON COLUMN ph18_ops.notification_template_version.body_text IS 'Mustache không logic: chỉ biến {{ten}} trong allowed_fields; CHECK chặn khối {{#}}, {{^}}, partial {{>}}.';
COMMENT ON COLUMN ph18_ops.notification_template_version.field_check_report IS 'Kết quả kiểm tra cấm trường mức Hạn chế, Nhạy cảm theo PH-09 (FR-00-062).';
--rollback DROP TABLE IF EXISTS ph18_ops.notification_template_version CASCADE;

--changeset ph18:ph18-0320-notification-rule splitStatements:false
CREATE TABLE ph18_ops.notification_rule (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  rule_code        varchar(64) NOT NULL,
  source_module    varchar(8) NOT NULL,
  event_type       varchar(255) NOT NULL,
  condition        jsonb NOT NULL DEFAULT '{}',
  template_code    varchar(64) NOT NULL,
  recipient_kind   varchar(16) NOT NULL,
  recipient_expr   varchar(255) NOT NULL,
  channels         varchar(8)[] NOT NULL,
  create_task_type varchar(64),
  priority         varchar(8) NOT NULL DEFAULT 'NORMAL',
  enabled          boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_notification_rule PRIMARY KEY (id),
  CONSTRAINT uq_notification_rule_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_notification_rule_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_notification_rule_code UNIQUE (tenant_id, rule_code),
  CONSTRAINT ck_notification_rule_module CHECK (source_module ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_notification_rule_event CHECK (event_type ~ '^[a-z0-9-]+(\.[a-z0-9-]+)+\.v[0-9]+$'),
  CONSTRAINT ck_notification_rule_recipient CHECK (recipient_kind IN ('USER', 'GROUP', 'ROLE', 'SYSTEM_CONTACT', 'EVENT_FIELD', 'ON_CALL')),
  CONSTRAINT ck_notification_rule_channels CHECK (cardinality(channels) >= 1 AND channels <@ ARRAY['EMAIL', 'SMS', 'IN_APP']::varchar(8)[]),
  CONSTRAINT ck_notification_rule_priority CHECK (priority IN ('NORMAL', 'URGENT'))
);
CREATE INDEX ix_notification_rule_event ON ph18_ops.notification_rule (event_type) WHERE enabled;
CREATE TRIGGER tg_notification_rule_touch BEFORE UPDATE ON ph18_ops.notification_rule FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_notification_rule_immutable BEFORE UPDATE ON ph18_ops.notification_rule FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('rule_code');
CALL ph18_ops.p_enable_rls('ph18_ops.notification_rule', true);
COMMENT ON TABLE ph18_ops.notification_rule IS 'EN-18-21 Quy tắc thông báo theo sự kiện của các PH (hợp đồng §1.3): loại sự kiện, điều kiện lọc, mẫu, cách phân giải người nhận, kênh, loại việc tạo kèm. Dòng COMMON là quy tắc nền tảng, tenant thêm hoặc tắt.';
--rollback DROP TABLE IF EXISTS ph18_ops.notification_rule CASCADE;

--changeset ph18:ph18-0330-notification-message splitStatements:false
CREATE TABLE ph18_ops.notification_message (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  caller_module       varchar(8) NOT NULL,
  message_key         varchar(128) NOT NULL,
  template_code       varchar(64) NOT NULL,
  template_version_no integer,
  rule_id             uuid,
  source_event_id     varchar(255),
  recipient_ref       jsonb NOT NULL,
  category            varchar(12) NOT NULL,
  channels            varchar(8)[] NOT NULL,
  params              jsonb NOT NULL DEFAULT '{}',
  link                varchar(500),
  mode                varchar(8) NOT NULL DEFAULT 'ASYNC',
  priority            varchar(8) NOT NULL DEFAULT 'NORMAL',
  status              varchar(12) NOT NULL DEFAULT 'QUEUED',
  requested_at        timestamptz NOT NULL DEFAULT now(),
  dispatched_at       timestamptz,
  expires_at          timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_notification_message PRIMARY KEY (id),
  CONSTRAINT uq_notification_message_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_notification_message_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_notification_message_key UNIQUE (tenant_id, caller_module, message_key),
  CONSTRAINT fk_notification_message_rule FOREIGN KEY (rule_id) REFERENCES ph18_ops.notification_rule (id),
  CONSTRAINT ck_notification_message_module CHECK (caller_module ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_notification_message_recipient CHECK (jsonb_typeof(recipient_ref) = 'array' AND jsonb_array_length(recipient_ref) BETWEEN 1 AND 500),
  CONSTRAINT ck_notification_message_category CHECK (category IN ('TASK', 'JOB_RESULT', 'ALERT', 'INFO')),
  CONSTRAINT ck_notification_message_channels CHECK (cardinality(channels) >= 1 AND channels <@ ARRAY['EMAIL', 'SMS', 'IN_APP']::varchar(8)[]),
  CONSTRAINT ck_notification_message_params CHECK (jsonb_typeof(params) = 'object' AND NOT (params ?| ARRAY['cccd', 'cmnd', 'so_dinh_danh', 'personal_id', 'bank_account', 'so_tai_khoan'])),
  CONSTRAINT ck_notification_message_link CHECK (link IS NULL OR link ~ '^/[a-z0-9/_{}?=&.-]*$'),
  CONSTRAINT ck_notification_message_mode CHECK (mode IN ('ASYNC', 'SYNC')),
  CONSTRAINT ck_notification_message_priority CHECK (priority IN ('NORMAL', 'URGENT')),
  CONSTRAINT ck_notification_message_status CHECK (status IN ('QUEUED', 'SENT', 'DELIVERED', 'BOUNCED', 'FAILED', 'SUPPRESSED'))
);
CREATE INDEX ix_notification_message_status ON ph18_ops.notification_message (tenant_id, status, requested_at);
CREATE INDEX ix_notification_message_requested ON ph18_ops.notification_message (requested_at);
CREATE TRIGGER tg_notification_message_touch BEFORE UPDATE ON ph18_ops.notification_message FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_notification_message_immutable BEFORE UPDATE ON ph18_ops.notification_message FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('caller_module', 'message_key', 'template_code', 'recipient_ref', 'params');
CALL ph18_ops.p_enable_rls('ph18_ops.notification_message', false);
COMMENT ON TABLE ph18_ops.notification_message IS 'EN-18-22 Thông báo logic (outbox của NotificationApi, DD-13): khóa lũy đẳng của bên gọi, mẫu và phiên bản, người nhận recipient_ref (người, nhóm, vai trò, đầu mối HTTT; PH-18 tự phân giải địa chỉ), biến mẫu (CHECK chặn trường định danh), chế độ ASYNC hoặc SYNC (thư mang liên kết, Q01-52), trạng thái tổng hợp từ các lần gửi.';
--rollback DROP TABLE IF EXISTS ph18_ops.notification_message CASCADE;

--changeset ph18:ph18-0340-notification-delivery splitStatements:false
CREATE TABLE ph18_ops.notification_delivery (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  message_id          uuid NOT NULL,
  channel             varchar(8) NOT NULL,
  recipient_user_id   varchar(64),
  recipient_masked    varchar(64),
  recipient_hash      char(64),
  status              varchar(12) NOT NULL DEFAULT 'QUEUED',
  attempts            integer NOT NULL DEFAULT 0,
  provider_message_id varchar(255),
  rendered_title      varchar(255),
  last_error          varchar(1000),
  suppressed_reason   varchar(20),
  queued_at           timestamptz NOT NULL DEFAULT now(),
  sent_at             timestamptz,
  delivered_at        timestamptz,
  bounced_at          timestamptz,
  read_at             timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_notification_delivery PRIMARY KEY (id, queued_at),
  CONSTRAINT uq_notification_delivery_tid UNIQUE (tenant_id, id, queued_at),
  CONSTRAINT ck_notification_delivery_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_notification_delivery_message FOREIGN KEY (tenant_id, message_id) REFERENCES ph18_ops.notification_message (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT ck_notification_delivery_channel CHECK (channel IN ('EMAIL', 'SMS', 'IN_APP')),
  CONSTRAINT ck_notification_delivery_status CHECK (status IN ('QUEUED', 'SENT', 'DELIVERED', 'BOUNCED', 'FAILED', 'SUPPRESSED')),
  CONSTRAINT ck_notification_delivery_attempts CHECK (attempts BETWEEN 0 AND 20),
  CONSTRAINT ck_notification_delivery_recipient CHECK (recipient_user_id IS NOT NULL OR recipient_hash IS NOT NULL),
  CONSTRAINT ck_notification_delivery_hash CHECK (recipient_hash IS NULL OR recipient_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_notification_delivery_in_app CHECK (channel <> 'IN_APP' OR recipient_user_id IS NOT NULL),
  CONSTRAINT ck_notification_delivery_read CHECK (read_at IS NULL OR channel = 'IN_APP'),
  CONSTRAINT ck_notification_delivery_suppressed CHECK ((status = 'SUPPRESSED') = (suppressed_reason IS NOT NULL) AND (suppressed_reason IS NULL OR suppressed_reason IN ('USER_PREF', 'QUIET_HOURS', 'SUPPRESSION_LIST', 'DUPLICATE')))
) PARTITION BY RANGE (queued_at);
CALL ph18_ops.p_ensure_partitions('ph18_ops.notification_delivery', (current_date - interval '1 month')::date, 4);
CREATE INDEX ix_notification_delivery_message ON ph18_ops.notification_delivery (tenant_id, message_id);
CREATE INDEX ix_notification_delivery_inbox ON ph18_ops.notification_delivery (tenant_id, recipient_user_id, queued_at DESC) WHERE channel = 'IN_APP';
CREATE INDEX ix_notification_delivery_pending ON ph18_ops.notification_delivery (status, queued_at) WHERE status = 'QUEUED';
CREATE TRIGGER tg_notification_delivery_touch BEFORE UPDATE ON ph18_ops.notification_delivery FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_notification_delivery_immutable BEFORE UPDATE ON ph18_ops.notification_delivery FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('message_id', 'channel', 'recipient_user_id', 'recipient_hash');
CREATE TRIGGER tg_notification_delivery_fsm_status BEFORE UPDATE ON ph18_ops.notification_delivery FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'QUEUED>SENT,QUEUED>FAILED,QUEUED>SUPPRESSED,SENT>DELIVERED,SENT>BOUNCED,SENT>FAILED,DELIVERED>BOUNCED');
CALL ph18_ops.p_enable_rls('ph18_ops.notification_delivery', false);
COMMENT ON TABLE ph18_ops.notification_delivery IS 'EN-18-23 Lần gửi theo người nhận và kênh (nhật ký gửi): địa chỉ chỉ lưu dạng che và băm, trạng thái QUEUED sang SENT sang DELIVERED, BOUNCED hoặc FAILED; SUPPRESSED khi tùy chọn người dùng, giờ yên lặng, danh sách chặn. Kênh IN_APP là hộp thông báo DD-13 (read_at). Phân vùng tháng theo queued_at, giữ 18.notify.log-retention-days.';
--rollback DROP TABLE IF EXISTS ph18_ops.notification_delivery CASCADE;

--changeset ph18:ph18-0350-user-notification-pref splitStatements:false
CREATE TABLE ph18_ops.user_notification_pref (
  id         uuid NOT NULL,
  tenant_id  varchar(16) NOT NULL,
  user_id    varchar(64) NOT NULL,
  category   varchar(12) NOT NULL,
  channel    varchar(8) NOT NULL,
  enabled    boolean NOT NULL DEFAULT true,
  quiet_from time,
  quiet_to   time,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by varchar(64) NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by varchar(64) NOT NULL,
  version    integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_user_notification_pref PRIMARY KEY (id),
  CONSTRAINT uq_user_notification_pref_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_user_notification_pref_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_user_notification_pref UNIQUE (tenant_id, user_id, category, channel),
  CONSTRAINT ck_user_notification_pref_category CHECK (category IN ('TASK', 'JOB_RESULT', 'ALERT', 'INFO')),
  CONSTRAINT ck_user_notification_pref_channel CHECK (channel IN ('EMAIL', 'SMS', 'IN_APP')),
  CONSTRAINT ck_user_notification_pref_quiet CHECK ((quiet_from IS NULL) = (quiet_to IS NULL))
);
CREATE TRIGGER tg_user_notification_pref_touch BEFORE UPDATE ON ph18_ops.user_notification_pref FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CALL ph18_ops.p_enable_rls('ph18_ops.user_notification_pref', false);
COMMENT ON TABLE ph18_ops.user_notification_pref IS 'EN-18-24 Tùy chọn nhận thông báo của người dùng (FR-00-061) theo nhóm và kênh, giờ yên lặng; thông báo bắt buộc và khẩn không bị tắt bằng tùy chọn.';
--rollback DROP TABLE IF EXISTS ph18_ops.user_notification_pref CASCADE;

--changeset ph18:ph18-0360-suppression-entry splitStatements:false
CREATE TABLE ph18_ops.suppression_entry (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  channel          varchar(8) NOT NULL,
  address_hash     char(64) NOT NULL,
  address_masked   varchar(64) NOT NULL,
  reason           varchar(12) NOT NULL,
  bounce_count     integer NOT NULL DEFAULT 1,
  first_bounced_at timestamptz NOT NULL DEFAULT now(),
  last_bounced_at  timestamptz NOT NULL DEFAULT now(),
  released_at      timestamptz,
  released_by      varchar(64),
  released_reason  varchar(500),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_suppression_entry PRIMARY KEY (id),
  CONSTRAINT uq_suppression_entry_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_suppression_entry_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_suppression_entry_channel CHECK (channel IN ('EMAIL', 'SMS')),
  CONSTRAINT ck_suppression_entry_hash CHECK (address_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_suppression_entry_reason CHECK (reason IN ('HARD_BOUNCE', 'COMPLAINT', 'INVALID', 'MANUAL')),
  CONSTRAINT ck_suppression_entry_count CHECK (bounce_count >= 1),
  CONSTRAINT ck_suppression_entry_released CHECK ((released_at IS NULL) = (released_by IS NULL))
);
CREATE UNIQUE INDEX uq_suppression_entry_active ON ph18_ops.suppression_entry (tenant_id, channel, address_hash) WHERE released_at IS NULL;
CREATE TRIGGER tg_suppression_entry_touch BEFORE UPDATE ON ph18_ops.suppression_entry FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_suppression_entry_immutable BEFORE UPDATE ON ph18_ops.suppression_entry FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('channel', 'address_hash');
CALL ph18_ops.p_enable_rls('ph18_ops.suppression_entry', false);
COMMENT ON TABLE ph18_ops.suppression_entry IS 'EN-18-25 Danh sách chặn gửi do thư trả lại cứng, khiếu nại, địa chỉ sai hoặc chặn tay: địa chỉ che và băm, số lần trả lại; thư trả lại phát ops.notification.bounced để PH-01 cập nhật đầu mối. Mỗi địa chỉ một dòng đang hiệu lực.';
--rollback DROP TABLE IF EXISTS ph18_ops.suppression_entry CASCADE;
