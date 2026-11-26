--liquibase formatted sql
-- Nguồn: ddl/ph15_portal.sql · 15-0060-notify-support.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph15:ph15-0600-watch-subscription
CREATE TABLE ph15_portal.notification_subscription (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  account_id          uuid          NOT NULL,
  api_id            uuid          NOT NULL,
  channel             varchar(6)    NOT NULL,
  kind                varchar(9)    NOT NULL DEFAULT 'INFO',
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_notification_subscription PRIMARY KEY (id),
  CONSTRAINT uq_notification_subscription UNIQUE (account_id, api_id, channel, kind),
  CONSTRAINT fk_notification_subscription_account FOREIGN KEY (account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT fk_notification_subscription_entry FOREIGN KEY (api_id, tenant_id) REFERENCES ph15_portal.catalog_api (id, tenant_id),
  CONSTRAINT ck_notification_subscription_channel CHECK (channel IN ('IN_APP', 'EMAIL')),
  CONSTRAINT ck_notification_subscription_kind CHECK (kind IN ('MANDATORY', 'INFO'))
);
CREATE INDEX ix_notification_subscription_entry ON ph15_portal.notification_subscription (tenant_id, api_id, kind);
CREATE TRIGGER tg_notification_subscription_touch BEFORE UPDATE ON ph15_portal.notification_subscription FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CALL ph15_portal.p_enable_rls('ph15_portal.notification_subscription');
COMMENT ON TABLE ph15_portal.notification_subscription IS 'EN-15-14 Theo dõi thay đổi API (FR-15-051): INFO do người dùng bật tắt; MANDATORY (ngừng khuyến nghị, tạm ngừng, ngừng hẳn, SLA kém đi, thay đổi phá vỡ) hệ thống tạo và không xóa được (BR-15-027).';
--rollback DROP TABLE IF EXISTS ph15_portal.notification_subscription CASCADE;

--changeset ph15:ph15-0601-mandatory-guard splitStatements:false
CREATE OR REPLACE FUNCTION ph15_portal.tg_mandatory_watch_guard() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF OLD.kind = 'MANDATORY' THEN
    RAISE EXCEPTION 'Đăng ký nhận thông báo bắt buộc không tắt được (BR-15-027)' USING ERRCODE = 'P1504';
  END IF;
  RETURN OLD;
END
$f$;
CREATE TRIGGER tg_notification_subscription_mandatory BEFORE DELETE ON ph15_portal.notification_subscription FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_mandatory_watch_guard();
--rollback DROP FUNCTION IF EXISTS ph15_portal.tg_mandatory_watch_guard() CASCADE;

--changeset ph15:ph15-0610-inbox-notification
CREATE TABLE ph15_portal.inbox_message (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  account_id          uuid          NOT NULL,
  channel             varchar(6)    NOT NULL DEFAULT 'IN_APP',
  kind                varchar(9)    NOT NULL DEFAULT 'INFO',
  api_id            uuid,
  title               varchar(255)  NOT NULL,
  body                varchar(2000),
  link_path           varchar(512),
  source_event_id     uuid,
  delivered_at        timestamptz,
  read_at             timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  CONSTRAINT pk_inbox_message PRIMARY KEY (id),
  CONSTRAINT fk_inbox_message_account FOREIGN KEY (account_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT fk_inbox_message_entry FOREIGN KEY (api_id, tenant_id) REFERENCES ph15_portal.catalog_api (id, tenant_id),
  CONSTRAINT ck_inbox_message_channel CHECK (channel IN ('IN_APP', 'EMAIL')),
  CONSTRAINT ck_inbox_message_kind CHECK (kind IN ('MANDATORY', 'INFO'))
);
CREATE UNIQUE INDEX uq_inbox_message_event ON ph15_portal.inbox_message (account_id, source_event_id, channel) WHERE source_event_id IS NOT NULL;
CREATE INDEX ix_inbox_message_unread ON ph15_portal.inbox_message (tenant_id, account_id, created_at DESC) WHERE read_at IS NULL;
CALL ph15_portal.p_enable_rls('ph15_portal.inbox_message');
COMMENT ON TABLE ph15_portal.inbox_message IS 'Hộp thông báo (FR-15-052): một dòng cho mỗi người nhận và kênh; chống gửi trùng nhờ khóa duy nhất theo sự kiện nguồn (EVT-02-12).';
--rollback DROP TABLE IF EXISTS ph15_portal.inbox_message CASCADE;

--changeset ph15:ph15-0620-support-ticket
CREATE TABLE ph15_portal.support_ticket (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  ticket_code         varchar(16)   NOT NULL,
  kind                varchar(16)   NOT NULL,
  status              varchar(8)    NOT NULL DEFAULT 'OPEN',
  api_id            uuid,
  page_id             uuid,
  requester_id        uuid          NOT NULL,
  assignee_org_code   varchar(64),
  assignee_user_id    varchar(64),
  subject             varchar(255)  NOT NULL,
  body                varchar(4000) NOT NULL,
  rating              smallint,
  first_response_due_at timestamptz,
  first_responded_at  timestamptz,
  resolved_at         timestamptz,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  updated_at          timestamptz   NOT NULL DEFAULT now(),
  updated_by          varchar(64)   NOT NULL,
  version             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_support_ticket PRIMARY KEY (id),
  CONSTRAINT uq_support_ticket_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_support_ticket_code UNIQUE (tenant_id, ticket_code),
  CONSTRAINT fk_support_ticket_entry FOREIGN KEY (api_id, tenant_id) REFERENCES ph15_portal.catalog_api (id, tenant_id),
  CONSTRAINT fk_support_ticket_page FOREIGN KEY (page_id, tenant_id) REFERENCES ph15_portal.content_page (id, tenant_id),
  CONSTRAINT fk_support_ticket_requester FOREIGN KEY (requester_id, tenant_id) REFERENCES ph15_portal.dev_account (id, tenant_id),
  CONSTRAINT ck_support_ticket_code CHECK (ticket_code ~ '^HT-[0-9]{4}-[0-9]{4,}$'),
  CONSTRAINT ck_support_ticket_kind CHECK (kind IN ('QUESTION', 'DOC_ERROR', 'SUPPORT_REQUEST', 'ACCESS_REQUEST', 'FEEDBACK')),
  CONSTRAINT ck_support_ticket_status CHECK (status IN ('OPEN', 'ANSWERED', 'RESOLVED', 'CLOSED')),
  CONSTRAINT ck_support_ticket_rating CHECK (rating IS NULL OR (kind = 'FEEDBACK' AND rating BETWEEN 1 AND 5)),
  CONSTRAINT ck_support_ticket_resolved CHECK (status NOT IN ('RESOLVED', 'CLOSED') OR resolved_at IS NOT NULL)
);
CREATE INDEX ix_support_ticket_inbox ON ph15_portal.support_ticket (tenant_id, assignee_org_code, status, created_at);
CREATE INDEX ix_support_ticket_requester ON ph15_portal.support_ticket (tenant_id, requester_id, created_at DESC);
CREATE INDEX ix_support_ticket_sla ON ph15_portal.support_ticket (tenant_id, first_response_due_at) WHERE first_responded_at IS NULL AND status = 'OPEN';
CREATE TRIGGER tg_support_ticket_touch BEFORE UPDATE ON ph15_portal.support_ticket FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_touch();
CREATE TRIGGER tg_support_ticket_immutable BEFORE UPDATE ON ph15_portal.support_ticket FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_immutable_cols('ticket_code', 'tenant_id');
CALL ph15_portal.p_enable_rls('ph15_portal.support_ticket');
COMMENT ON TABLE ph15_portal.support_ticket IS 'EN-15-15 Phiếu hỗ trợ: hỏi đáp theo API, báo lỗi tài liệu, yêu cầu hỗ trợ, yêu cầu truy cập, đánh giá (FR-15-053…055). Văn bản thuần ≤ 4.000 ký tự (BR-15-030).';
COMMENT ON COLUMN ph15_portal.support_ticket.assignee_org_code IS 'Đầu mối của chủ dịch vụ (owner_org_code của API); phiếu không gắn API chuyển quản trị cổng.';
COMMENT ON COLUMN ph15_portal.support_ticket.first_response_due_at IS 'Hạn phản hồi đầu = tạo + 15.support.sla-hours; quá hạn thì nhắc và báo quản trị.';
--rollback DROP TABLE IF EXISTS ph15_portal.support_ticket CASCADE;

--changeset ph15:ph15-0621-support-message
CREATE TABLE ph15_portal.support_message (
  id                  uuid          NOT NULL,
  tenant_id           ph15_portal.t_tenant NOT NULL,
  ticket_id           uuid          NOT NULL,
  author_id           varchar(64)   NOT NULL,
  author_side         varchar(9)    NOT NULL,
  body                varchar(4000) NOT NULL,
  created_at          timestamptz   NOT NULL DEFAULT now(),
  created_by          varchar(64)   NOT NULL,
  CONSTRAINT pk_support_message PRIMARY KEY (id),
  CONSTRAINT fk_support_message_ticket FOREIGN KEY (ticket_id, tenant_id) REFERENCES ph15_portal.support_ticket (id, tenant_id),
  CONSTRAINT ck_support_message_side CHECK (author_side IN ('REQUESTER', 'HANDLER'))
);
CREATE INDEX ix_support_message_ticket ON ph15_portal.support_message (tenant_id, ticket_id, created_at);
CREATE TRIGGER tg_support_message_ro BEFORE UPDATE OR DELETE ON ph15_portal.support_message FOR EACH ROW EXECUTE FUNCTION ph15_portal.tg_append_only();
CALL ph15_portal.p_enable_rls('ph15_portal.support_message');
COMMENT ON TABLE ph15_portal.support_message IS 'Chuỗi tin trong phiếu hỗ trợ; chỉ thêm, giữ nguyên lịch sử xử lý (FR-15-054, 055).';
--rollback DROP TABLE IF EXISTS ph15_portal.support_message CASCADE;

--changeset ph15:ph15-0622-ticket-counter splitStatements:false
CREATE TABLE ph15_portal.ticket_counter (
  tenant_id           ph15_portal.t_tenant NOT NULL,
  year                smallint      NOT NULL,
  last_no             integer       NOT NULL DEFAULT 0,
  CONSTRAINT pk_ticket_counter PRIMARY KEY (tenant_id, year),
  CONSTRAINT ck_ticket_counter_no CHECK (last_no >= 0)
);
CALL ph15_portal.p_enable_rls('ph15_portal.ticket_counter');
COMMENT ON TABLE ph15_portal.ticket_counter IS 'Bộ đếm số phiếu theo tenant và năm cho ticketCode HT-{năm}-{số}; tăng trong cùng giao dịch tạo phiếu.';
CREATE OR REPLACE FUNCTION ph15_portal.next_ticket_code() RETURNS varchar
  LANGUAGE plpgsql AS $f$
DECLARE
  y smallint := extract(year FROM now())::smallint;
  n integer;
BEGIN
  INSERT INTO ph15_portal.ticket_counter (tenant_id, year, last_no)
  VALUES (current_setting('app.tenant_id', false), y, 1)
  ON CONFLICT (tenant_id, year) DO UPDATE SET last_no = ph15_portal.ticket_counter.last_no + 1
  RETURNING last_no INTO n;
  RETURN format('HT-%s-%s', y, lpad(n::text, 4, '0'));
END
$f$;
COMMENT ON FUNCTION ph15_portal.next_ticket_code() IS 'Cấp mã phiếu kế tiếp cho tenant của phiên (RLS áp dụng); đồng thời an toàn nhờ khóa dòng của ON CONFLICT.';
--rollback DROP FUNCTION IF EXISTS ph15_portal.next_ticket_code(); DROP TABLE IF EXISTS ph15_portal.ticket_counter;
