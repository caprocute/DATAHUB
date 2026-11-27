--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0050-task.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0370-task-type splitStatements:false
CREATE TABLE ph18_ops.task_type (
  id                     uuid NOT NULL,
  tenant_id              varchar(16) NOT NULL,
  type_code              varchar(64) NOT NULL,
  owner_module           varchar(8) NOT NULL,
  title                  varchar(255) NOT NULL,
  description            varchar(1000),
  default_due_hours      integer,
  reminder_offsets_hours integer[] NOT NULL DEFAULT '{}',
  required_permission    varchar(64) NOT NULL,
  deep_link_pattern      varchar(500) NOT NULL,
  four_eyes              boolean NOT NULL DEFAULT false,
  enabled                boolean NOT NULL DEFAULT true,
  created_at             timestamptz NOT NULL DEFAULT now(),
  created_by             varchar(64) NOT NULL,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  updated_by             varchar(64) NOT NULL,
  version                integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_task_type PRIMARY KEY (id),
  CONSTRAINT uq_task_type_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_task_type_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_task_type_code UNIQUE (tenant_id, type_code),
  CONSTRAINT ck_task_type_code CHECK (type_code ~ '^ph[0-9]{2}\.[a-z0-9-]+$' AND upper(left(type_code, 4)) = owner_module),
  CONSTRAINT ck_task_type_module CHECK (owner_module ~ '^PH[0-9]{2}$'),
  CONSTRAINT ck_task_type_perm CHECK (required_permission ~ '^PERM-[0-9]{2}-[a-z0-9-]+$'),
  CONSTRAINT ck_task_type_link CHECK (deep_link_pattern ~ '^/[a-z0-9/_{}?=&.-]*$'),
  CONSTRAINT ck_task_type_due CHECK (default_due_hours IS NULL OR default_due_hours BETWEEN 1 AND 8760)
);
CREATE TRIGGER tg_task_type_touch BEFORE UPDATE ON ph18_ops.task_type FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_task_type_immutable BEFORE UPDATE ON ph18_ops.task_type FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('type_code', 'owner_module');
CALL ph18_ops.p_enable_rls('ph18_ops.task_type', true);
COMMENT ON TABLE ph18_ops.task_type IS 'EN-18-26 Loại việc do PH đăng ký qua TaskInboxApi (ph01.approve-onboarding, ph02.review-subscription, ph16.approve-report…): tiêu đề, hạn mặc định, mốc nhắc, quyền cần có, mẫu liên kết sâu, cờ bốn mắt. Dòng COMMON; tenant có thể tắt loại việc bằng dòng riêng.';
--rollback DROP TABLE IF EXISTS ph18_ops.task_type CASCADE;

--changeset ph18:ph18-0380-task-item splitStatements:false
CREATE TABLE ph18_ops.task_item (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  type_id             uuid NOT NULL,
  type_code           varchar(64) NOT NULL,
  task_key            varchar(128) NOT NULL,
  title               varchar(255) NOT NULL,
  subject_ref         varchar(255) NOT NULL,
  assignee_kind       varchar(8) NOT NULL,
  assignee_ref        varchar(128) NOT NULL,
  required_permission varchar(64) NOT NULL,
  requested_by        varchar(64),
  four_eyes           boolean NOT NULL DEFAULT false,
  priority            varchar(8) NOT NULL DEFAULT 'NORMAL',
  status              varchar(12) NOT NULL DEFAULT 'OPEN',
  due_at              timestamptz,
  claimed_by          varchar(64),
  started_at          timestamptz,
  closed_at           timestamptz,
  closed_by           varchar(64),
  outcome             varchar(32),
  link                varchar(500),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_task_item PRIMARY KEY (id),
  CONSTRAINT uq_task_item_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_task_item_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_task_item_key UNIQUE (tenant_id, type_code, task_key),
  CONSTRAINT fk_task_item_type FOREIGN KEY (type_id) REFERENCES ph18_ops.task_type (id),
  CONSTRAINT ck_task_item_assignee CHECK (assignee_kind IN ('USER', 'ROLE', 'GROUP')),
  CONSTRAINT ck_task_item_priority CHECK (priority IN ('NORMAL', 'HIGH', 'URGENT')),
  CONSTRAINT ck_task_item_status CHECK (status IN ('OPEN', 'IN_PROGRESS', 'DONE', 'CANCELLED', 'EXPIRED')),
  CONSTRAINT ck_task_item_closed CHECK ((status IN ('DONE', 'CANCELLED', 'EXPIRED')) = (closed_at IS NOT NULL)),
  CONSTRAINT ck_task_item_four_eyes CHECK (NOT four_eyes OR closed_by IS NULL OR closed_by IS DISTINCT FROM requested_by),
  CONSTRAINT ck_task_item_link CHECK (link IS NULL OR link ~ '^/[a-z0-9/_{}?=&.-]*$')
);
CREATE INDEX ix_task_item_inbox ON ph18_ops.task_item (tenant_id, assignee_kind, assignee_ref, status, due_at) WHERE status IN ('OPEN', 'IN_PROGRESS');
CREATE INDEX ix_task_item_due ON ph18_ops.task_item (due_at) WHERE status IN ('OPEN', 'IN_PROGRESS');
CREATE TRIGGER tg_task_item_touch BEFORE UPDATE ON ph18_ops.task_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_task_item_immutable BEFORE UPDATE ON ph18_ops.task_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('type_id', 'type_code', 'task_key', 'requested_by');
CREATE TRIGGER tg_task_item_fsm_status BEFORE UPDATE ON ph18_ops.task_item FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'OPEN>IN_PROGRESS,OPEN>DONE,OPEN>CANCELLED,OPEN>EXPIRED,IN_PROGRESS>OPEN,IN_PROGRESS>DONE,IN_PROGRESS>CANCELLED,IN_PROGRESS>EXPIRED');
CALL ph18_ops.p_enable_rls('ph18_ops.task_item', false);
COMMENT ON TABLE ph18_ops.task_item IS 'EN-18-27 Việc trong "Việc của tôi" (FR-00-070…072): loại việc, khóa lũy đẳng của PH tạo việc, tiêu đề không chứa dữ liệu Hạn chế, đối tượng, người hoặc vai trò được giao, hạn, trạng thái; việc bốn mắt thì người đóng khác người đề nghị. Phụ thuộc mềm: PH nguồn vẫn giữ hàng đợi duyệt riêng khi PH-18 vắng.';
--rollback DROP TABLE IF EXISTS ph18_ops.task_item CASCADE;

--changeset ph18:ph18-0390-task-reminder splitStatements:false
CREATE TABLE ph18_ops.task_reminder (
  id                      uuid NOT NULL,
  tenant_id               varchar(16) NOT NULL,
  task_id                 uuid NOT NULL,
  kind                    varchar(12) NOT NULL,
  remind_at               timestamptz NOT NULL,
  sent_at                 timestamptz,
  notification_message_id uuid,
  created_at              timestamptz NOT NULL DEFAULT now(),
  created_by              varchar(64) NOT NULL,
  updated_at              timestamptz NOT NULL DEFAULT now(),
  updated_by              varchar(64) NOT NULL,
  version                 integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_task_reminder PRIMARY KEY (id),
  CONSTRAINT uq_task_reminder_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_task_reminder_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_task_reminder UNIQUE (tenant_id, task_id, kind, remind_at),
  CONSTRAINT fk_task_reminder_task FOREIGN KEY (tenant_id, task_id) REFERENCES ph18_ops.task_item (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_task_reminder_message FOREIGN KEY (tenant_id, notification_message_id) REFERENCES ph18_ops.notification_message (tenant_id, id),
  CONSTRAINT ck_task_reminder_kind CHECK (kind IN ('BEFORE_DUE', 'OVERDUE', 'ESCALATION'))
);
CREATE INDEX ix_task_reminder_due ON ph18_ops.task_reminder (remind_at) WHERE sent_at IS NULL;
CREATE TRIGGER tg_task_reminder_touch BEFORE UPDATE ON ph18_ops.task_reminder FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CALL ph18_ops.p_enable_rls('ph18_ops.task_reminder', false);
COMMENT ON TABLE ph18_ops.task_reminder IS 'EN-18-28 Lịch nhắc việc: trước hạn, quá hạn, leo thang; thời điểm gửi và thông báo đã tạo. Mỗi việc, loại nhắc, thời điểm một dòng.';
--rollback DROP TABLE IF EXISTS ph18_ops.task_reminder CASCADE;

--changeset ph18:ph18-0400-work-calendar splitStatements:false
CREATE TABLE ph18_ops.work_calendar (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  calendar_code  varchar(32) NOT NULL DEFAULT 'DEFAULT',
  name           varchar(255) NOT NULL,
  timezone       varchar(64) NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  working_days   smallint[] NOT NULL DEFAULT '{1,2,3,4,5}',
  work_start     time NOT NULL DEFAULT '07:30',
  work_end       time NOT NULL DEFAULT '17:00',
  inherit_common boolean NOT NULL DEFAULT true,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_work_calendar PRIMARY KEY (id),
  CONSTRAINT uq_work_calendar_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_work_calendar_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_work_calendar_code UNIQUE (tenant_id, calendar_code),
  CONSTRAINT ck_work_calendar_days CHECK (cardinality(working_days) BETWEEN 1 AND 7 AND working_days <@ ARRAY[1, 2, 3, 4, 5, 6, 7]::smallint[]),
  CONSTRAINT ck_work_calendar_hours CHECK (work_end > work_start),
  CONSTRAINT ck_work_calendar_code CHECK (calendar_code ~ '^[A-Z0-9_]+$')
);
CREATE TRIGGER tg_work_calendar_touch BEFORE UPDATE ON ph18_ops.work_calendar FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_work_calendar_immutable BEFORE UPDATE ON ph18_ops.work_calendar FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('calendar_code');
CALL ph18_ops.p_enable_rls('ph18_ops.work_calendar', true);
COMMENT ON TABLE ph18_ops.work_calendar IS 'EN-18-29 Lịch ngày làm việc theo tenant (WorkingCalendarApi, khóa 18.calendar.*): múi giờ, ngày làm việc trong tuần, giờ làm việc; dòng COMMON là lịch quốc gia, tenant kế thừa và bổ sung.';
--rollback DROP TABLE IF EXISTS ph18_ops.work_calendar CASCADE;

--changeset ph18:ph18-0410-calendar-holiday splitStatements:false
CREATE TABLE ph18_ops.calendar_holiday (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  calendar_id  uuid NOT NULL,
  holiday_date date NOT NULL,
  name         varchar(255) NOT NULL,
  kind         varchar(16) NOT NULL DEFAULT 'HOLIDAY',
  legal_basis  varchar(255),
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_calendar_holiday PRIMARY KEY (id),
  CONSTRAINT uq_calendar_holiday_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_calendar_holiday_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_calendar_holiday_date UNIQUE (tenant_id, calendar_id, holiday_date),
  CONSTRAINT fk_calendar_holiday_calendar FOREIGN KEY (tenant_id, calendar_id) REFERENCES ph18_ops.work_calendar (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT ck_calendar_holiday_kind CHECK (kind IN ('HOLIDAY', 'COMPENSATORY_OFF', 'WORKING_SWAP'))
);
CREATE TRIGGER tg_calendar_holiday_touch BEFORE UPDATE ON ph18_ops.calendar_holiday FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CALL ph18_ops.p_enable_rls('ph18_ops.calendar_holiday', true);
COMMENT ON TABLE ph18_ops.calendar_holiday IS 'EN-18-30 Ngày lễ, ngày nghỉ bù, ngày làm bù của một lịch; căn cứ pháp lý (thông báo nghỉ lễ). Dòng COMMON cho lịch quốc gia.';
--rollback DROP TABLE IF EXISTS ph18_ops.calendar_holiday CASCADE;

--changeset ph18:ph18-0420-maintenance-window splitStatements:false
CREATE TABLE ph18_ops.maintenance_window (
  id                     uuid NOT NULL,
  tenant_id              varchar(16) NOT NULL,
  window_code            varchar(64) NOT NULL,
  kind                   varchar(12) NOT NULL,
  scope_module           varchar(8),
  environment            varchar(8) NOT NULL DEFAULT 'PROD',
  starts_at              timestamptz NOT NULL,
  ends_at                timestamptz NOT NULL,
  reason                 text NOT NULL,
  announce_template_code varchar(64),
  release_ref            varchar(64),
  status                 varchar(12) NOT NULL DEFAULT 'PLANNED',
  approved_by            varchar(64),
  approved_at            timestamptz,
  created_at             timestamptz NOT NULL DEFAULT now(),
  created_by             varchar(64) NOT NULL,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  updated_by             varchar(64) NOT NULL,
  version                integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_maintenance_window PRIMARY KEY (id),
  CONSTRAINT uq_maintenance_window_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_maintenance_window_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_maintenance_window_code UNIQUE (tenant_id, window_code),
  CONSTRAINT ck_maintenance_window_kind CHECK (kind IN ('MAINTENANCE', 'FREEZE')),
  CONSTRAINT ck_maintenance_window_module CHECK (scope_module IS NULL OR scope_module ~ '^PH[0-9]{2}$'),
  CONSTRAINT ck_maintenance_window_env CHECK (environment IN ('PROD', 'STAGING', 'ALL')),
  CONSTRAINT ck_maintenance_window_period CHECK (ends_at > starts_at),
  CONSTRAINT ck_maintenance_window_reason CHECK (coalesce(char_length(btrim(reason)), 0) >= 10),
  CONSTRAINT ck_maintenance_window_status CHECK (status IN ('PLANNED', 'ACTIVE', 'COMPLETED', 'CANCELLED')),
  CONSTRAINT ck_maintenance_window_four_eyes CHECK (approved_by IS NULL OR approved_by <> created_by),
  CONSTRAINT ck_maintenance_window_approved CHECK (status IN ('PLANNED', 'CANCELLED') OR approved_by IS NOT NULL)
);
CREATE INDEX ix_maintenance_window_time ON ph18_ops.maintenance_window (tenant_id, kind, starts_at, ends_at) WHERE status IN ('PLANNED', 'ACTIVE');
CREATE TRIGGER tg_maintenance_window_touch BEFORE UPDATE ON ph18_ops.maintenance_window FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_maintenance_window_immutable BEFORE UPDATE ON ph18_ops.maintenance_window FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('window_code', 'kind');
CREATE TRIGGER tg_maintenance_window_fsm_status BEFORE UPDATE ON ph18_ops.maintenance_window FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'PLANNED>ACTIVE,PLANNED>CANCELLED,ACTIVE>COMPLETED,ACTIVE>CANCELLED');
CALL ph18_ops.p_enable_rls('ph18_ops.maintenance_window', true);
COMMENT ON TABLE ph18_ops.maintenance_window IS 'EN-18-31 Cửa sổ bảo trì và cửa sổ đóng băng thay đổi (PH-02 đọc cờ đóng băng môi trường thật; PH-04 giữ 04.freeze.windows riêng, đề nghị hợp nhất): phạm vi PH, môi trường, thời gian, lý do, mẫu thông báo, duyệt bốn mắt. Dòng COMMON áp cho mọi tenant (phát hành nền tảng).';
--rollback DROP TABLE IF EXISTS ph18_ops.maintenance_window CASCADE;
