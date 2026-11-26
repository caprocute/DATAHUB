--liquibase formatted sql
-- Nguồn: ddl/ph11_bpm.sql · 11-0040-sla.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph11:ph11-0400-business-calendar
CREATE TABLE ph11_bpm.business_calendar (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  year           smallint NOT NULL,
  work_week      varchar(3)[] NOT NULL DEFAULT '{MON,TUE,WED,THU,FRI}',
  work_hours     jsonb NOT NULL DEFAULT '{"start": "07:30", "end": "17:00", "breakStart": "11:30", "breakEnd": "13:30"}',
  inherited_from varchar(16),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_business_calendar PRIMARY KEY (id),
  CONSTRAINT uq_business_calendar_tid UNIQUE (tenant_id, id),
  CONSTRAINT uq_business_calendar_year UNIQUE (tenant_id, year),
  CONSTRAINT ck_business_calendar_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT ck_business_calendar_year CHECK (year BETWEEN 2000 AND 2100),
  CONSTRAINT ck_business_calendar_week CHECK (cardinality(work_week) BETWEEN 1 AND 7 AND work_week <@ ARRAY['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']::varchar[]),
  CONSTRAINT ck_business_calendar_hours CHECK (jsonb_typeof(work_hours) = 'object' AND work_hours ?& ARRAY['start', 'end'] AND (work_hours ->> 'start') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' AND (work_hours ->> 'end') ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' AND (work_hours ->> 'end') > (work_hours ->> 'start')),
  CONSTRAINT ck_business_calendar_break CHECK (((work_hours ? 'breakStart') = (work_hours ? 'breakEnd')) AND (NOT (work_hours ? 'breakStart') OR ((work_hours ->> 'breakEnd') > (work_hours ->> 'breakStart') AND (work_hours ->> 'breakStart') >= (work_hours ->> 'start') AND (work_hours ->> 'breakEnd') <= (work_hours ->> 'end')))),
  CONSTRAINT ck_business_calendar_inherited CHECK (inherited_from IS NULL OR (inherited_from = 'COMMON' AND tenant_id <> 'COMMON'))
);
CREATE TRIGGER tg_business_calendar_touch BEFORE UPDATE ON ph11_bpm.business_calendar FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_business_calendar_immutable BEFORE UPDATE ON ph11_bpm.business_calendar FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('year', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.business_calendar', 'S');
COMMENT ON TABLE ph11_bpm.business_calendar IS 'EN-11-13 Lịch làm việc của tenant theo năm (FR-11-045, ADR 114): thứ làm việc trong tuần, giờ làm việc, nghỉ trưa, múi giờ cố định Asia/Ho_Chi_Minh (BR-11-017). Mỗi tenant một dòng mỗi năm; PA khai lịch nền quốc gia ở tenant COMMON (mẫu S: tenant đọc được), tenant chưa khai năm nào thì dịch vụ dùng lịch COMMON hoặc lịch mặc định và ghi ERR-11-116. Không xóa (due_tracking tính theo lịch).';
COMMENT ON COLUMN ph11_bpm.business_calendar.year IS 'Năm dương lịch của lịch.';
COMMENT ON COLUMN ph11_bpm.business_calendar.work_week IS 'Các thứ làm việc trong tuần (API workDays): MON, TUE, WED, THU, FRI, SAT, SUN; mặc định thứ Hai đến thứ Sáu.';
COMMENT ON COLUMN ph11_bpm.business_calendar.work_hours IS 'Giờ làm việc (API workHours): start, end, breakStart, breakEnd dạng HH:MM; breakStart và breakEnd cùng có hoặc cùng không, nằm trong khoảng start đến end. Mặc định 07:30 đến 17:00, nghỉ trưa 11:30 đến 13:30.';
COMMENT ON COLUMN ph11_bpm.business_calendar.inherited_from IS 'COMMON khi lịch năm này sao chép từ lịch nền quốc gia ("Nhập từ lịch quốc gia"); rỗng khi tenant tự khai.';
--rollback DROP TABLE IF EXISTS ph11_bpm.business_calendar CASCADE;

--changeset ph11:ph11-0410-calendar-day
CREATE TABLE ph11_bpm.calendar_day (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  calendar_id uuid NOT NULL,
  date        date NOT NULL,
  type        varchar(16) NOT NULL,
  name        varchar(255) NOT NULL,
  legal_ref   varchar(255),
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_calendar_day PRIMARY KEY (id),
  CONSTRAINT uq_calendar_day_date UNIQUE (tenant_id, calendar_id, date),
  CONSTRAINT ck_calendar_day_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_calendar_day_calendar FOREIGN KEY (tenant_id, calendar_id) REFERENCES ph11_bpm.business_calendar (tenant_id, id),
  CONSTRAINT ck_calendar_day_type CHECK (type IN ('HOLIDAY', 'MAKEUP_WORKDAY', 'SPECIAL_OFF'))
);
CREATE INDEX ix_calendar_day_date ON ph11_bpm.calendar_day (tenant_id, date);
CREATE TRIGGER tg_calendar_day_touch BEFORE UPDATE ON ph11_bpm.calendar_day FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_calendar_day_immutable BEFORE UPDATE ON ph11_bpm.calendar_day FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('calendar_id', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.calendar_day', 'S');
COMMENT ON TABLE ph11_bpm.calendar_day IS 'EN-11-14 Ngày nghỉ lễ (HOLIDAY), ngày làm bù (MAKEUP_WORKDAY, rơi vào ngày không làm việc trong tuần) và ngày nghỉ đột xuất (SPECIAL_OFF) của một lịch năm (FR-11-045, CalendarDayType). Mỗi ngày một dòng trong một lịch; ngày phải thuộc năm của lịch (dịch vụ kiểm, ERR-11-028). legal_ref ghi văn bản (ví dụ quyết định nghỉ Tết của Thủ tướng). Cùng mẫu S với business_calendar: ngày lễ nền quốc gia ở COMMON. Sửa, xóa ngày có kiểm toán.';
COMMENT ON COLUMN ph11_bpm.calendar_day.date IS 'Ngày dương lịch (API date).';
COMMENT ON COLUMN ph11_bpm.calendar_day.type IS 'CalendarDayType: HOLIDAY, MAKEUP_WORKDAY, SPECIAL_OFF.';
COMMENT ON COLUMN ph11_bpm.calendar_day.legal_ref IS 'Số, ngày văn bản quy định nghỉ hoặc làm bù.';
--rollback DROP TABLE IF EXISTS ph11_bpm.calendar_day CASCADE;

--changeset ph11:ph11-0420-due-tracking
CREATE TABLE ph11_bpm.due_tracking (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  subject              varchar(8) NOT NULL,
  subject_id           uuid NOT NULL,
  instance_id          uuid NOT NULL,
  task_id              uuid GENERATED ALWAYS AS (CASE WHEN subject = 'TASK' THEN subject_id END) STORED,
  due_value            integer NOT NULL,
  due_unit             varchar(16) NOT NULL,
  start_at             timestamptz NOT NULL,
  due_at               timestamptz NOT NULL,
  due_soon_at          timestamptz,
  status               varchar(8) NOT NULL DEFAULT 'ON_TIME',
  paused_at            timestamptz,
  pause_reason         varchar(24),
  paused_duration      interval NOT NULL DEFAULT '0',
  escalation_level     smallint NOT NULL DEFAULT 0,
  due_soon_notified_at timestamptz,
  overdue_notified_at  timestamptz,
  result               varchar(8),
  closed_at            timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_due_tracking PRIMARY KEY (id),
  CONSTRAINT ck_due_tracking_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_due_tracking_instance FOREIGN KEY (tenant_id, instance_id) REFERENCES ph11_bpm.instance_index (tenant_id, id),
  CONSTRAINT fk_due_tracking_task FOREIGN KEY (tenant_id, task_id) REFERENCES ph11_bpm.task_index (tenant_id, id),
  CONSTRAINT ck_due_tracking_subject CHECK (subject IN ('INSTANCE', 'TASK') AND (subject <> 'INSTANCE' OR subject_id = instance_id)),
  CONSTRAINT ck_due_tracking_unit CHECK (due_unit IN ('WORKING_DAY', 'WORKING_HOUR', 'CALENDAR_DAY', 'CALENDAR_HOUR') AND due_value BETWEEN 1 AND 3650),
  CONSTRAINT ck_due_tracking_status CHECK (status IN ('ON_TIME', 'DUE_SOON', 'OVERDUE', 'PAUSED')),
  CONSTRAINT ck_due_tracking_pause CHECK ((status = 'PAUSED') = (paused_at IS NOT NULL) AND (paused_at IS NULL OR pause_reason IS NOT NULL)),
  CONSTRAINT ck_due_tracking_reason CHECK (pause_reason IS NULL OR pause_reason IN ('WAITING_SUPPLEMENT', 'LEGAL_SUSPENSION')),
  CONSTRAINT ck_due_tracking_due CHECK (due_at > start_at AND (due_soon_at IS NULL OR (due_soon_at >= start_at AND due_soon_at <= due_at))),
  CONSTRAINT ck_due_tracking_paused_duration CHECK (paused_duration >= interval '0'),
  CONSTRAINT ck_due_tracking_level CHECK (escalation_level BETWEEN 0 AND 3),
  CONSTRAINT ck_due_tracking_result CHECK (result IS NULL OR result IN ('MET', 'MISSED')),
  CONSTRAINT ck_due_tracking_closed CHECK ((closed_at IS NULL) = (result IS NULL))
);
CREATE UNIQUE INDEX uq_due_tracking_subject ON ph11_bpm.due_tracking (tenant_id, subject, subject_id);
CREATE INDEX ix_due_tracking_instance ON ph11_bpm.due_tracking (tenant_id, instance_id);
CREATE INDEX ix_due_tracking_scan ON ph11_bpm.due_tracking (due_at) WHERE closed_at IS NULL AND status <> 'PAUSED';
CREATE INDEX ix_due_tracking_report ON ph11_bpm.due_tracking (tenant_id, subject, closed_at) WHERE closed_at IS NOT NULL;
CREATE TRIGGER tg_due_tracking_touch BEFORE UPDATE ON ph11_bpm.due_tracking FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_touch();
CREATE TRIGGER tg_due_tracking_immutable BEFORE UPDATE ON ph11_bpm.due_tracking FOR EACH ROW EXECUTE FUNCTION ph11_bpm.tg_immutable('subject', 'subject_id', 'instance_id', 'start_at', 'tenant_id');
CALL ph11_bpm.p_enable_rls('ph11_bpm.due_tracking', 'P');
COMMENT ON TABLE ph11_bpm.due_tracking IS 'EN-11-15 Theo dõi hạn xử lý của phiên và của việc (FR-11-046…050, ADR 114). Hạn due_at tính theo lịch làm việc của tenant (BR-11-017); PAUSED khi chờ bổ sung hoặc tạm dừng pháp lý, cộng dồn paused_duration và dời due_at khi tiếp tục (BR-11-018). Tác vụ nền quét theo due_at, ghi mốc nhắc và mức leo thang một lần (BR-11-019). Khi đóng ghi closed_at và result (MET, MISSED) để báo cáo đúng hạn, trễ hạn.';
COMMENT ON COLUMN ph11_bpm.due_tracking.subject IS 'DueSubject: INSTANCE hạn cả phiên (subject_id là mã phiên), TASK hạn một việc (subject_id là mã việc).';
COMMENT ON COLUMN ph11_bpm.due_tracking.subject_id IS 'Mã phiên (instance_index.id) hoặc mã việc (task_index.id) theo subject.';
COMMENT ON COLUMN ph11_bpm.due_tracking.instance_id IS 'Phiên chứa đối tượng bị theo dõi (với INSTANCE bằng subject_id), giữ khóa ngoại và lọc theo phiên.';
COMMENT ON COLUMN ph11_bpm.due_tracking.task_id IS 'Cột sinh: bằng subject_id khi subject = TASK, để có khóa ngoại tới task_index.';
COMMENT ON COLUMN ph11_bpm.due_tracking.due_value IS 'Số lượng của hạn (T-DUE, 1…3.650), lưu để tính lại hạn khi lịch đổi (FR-11-045).';
COMMENT ON COLUMN ph11_bpm.due_tracking.due_unit IS 'DueUnit: WORKING_DAY, WORKING_HOUR, CALENDAR_DAY, CALENDAR_HOUR.';
COMMENT ON COLUMN ph11_bpm.due_tracking.pause_reason IS 'PauseReason: WAITING_SUPPLEMENT (chờ bổ sung hồ sơ), LEGAL_SUSPENSION (tạm dừng theo quy định).';
COMMENT ON COLUMN ph11_bpm.due_tracking.paused_duration IS 'Tổng thời gian đã tạm dừng tính hạn, quy theo giờ làm việc (API pausedDuration).';
COMMENT ON COLUMN ph11_bpm.due_tracking.escalation_level IS 'Mức leo thang đã gửi: 0 chưa, 1 người quản lý trực tiếp, 2 lãnh đạo đơn vị, 3 quản trị tenant (EscalationAction ghi ở chính sách bước).';
COMMENT ON COLUMN ph11_bpm.due_tracking.result IS 'DueResult khi đóng: MET hoàn thành trong hạn, MISSED sau hạn; rỗng khi còn mở.';
--rollback DROP TABLE IF EXISTS ph11_bpm.due_tracking CASCADE;
