--liquibase formatted sql
-- Nguồn: ddl/ph18_ops.sql · 18-0060-incident.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph18:ph18-0430-incident splitStatements:false
CREATE TABLE ph18_ops.incident (
  id                     uuid NOT NULL,
  tenant_id              varchar(16) NOT NULL,
  incident_no            varchar(20) NOT NULL,
  title                  varchar(255) NOT NULL,
  severity               varchar(4) NOT NULL,
  category               varchar(24) NOT NULL,
  origin                 varchar(8) NOT NULL,
  source_event_ref       varchar(255),
  status                 varchar(16) NOT NULL DEFAULT 'OPEN',
  commander              varchar(64),
  assignee               varchar(64),
  detected_at            timestamptz NOT NULL DEFAULT now(),
  acknowledged_at        timestamptz,
  mitigated_at           timestamptz,
  resolved_at            timestamptz,
  closed_at              timestamptz,
  involves_personal_data boolean NOT NULL DEFAULT false,
  ph09_breach_ref        varchar(64),
  ph09_reported_at       timestamptz,
  impact_summary         text,
  root_cause             text,
  lessons_learned        text,
  created_at             timestamptz NOT NULL DEFAULT now(),
  created_by             varchar(64) NOT NULL,
  updated_at             timestamptz NOT NULL DEFAULT now(),
  updated_by             varchar(64) NOT NULL,
  version                integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_incident PRIMARY KEY (id),
  CONSTRAINT uq_incident_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_incident_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_incident_no UNIQUE (tenant_id, incident_no),
  CONSTRAINT ck_incident_no CHECK (incident_no ~ '^INC-[0-9]{4}-[0-9]{6}$'),
  CONSTRAINT ck_incident_severity CHECK (severity IN ('SEV1', 'SEV2', 'SEV3', 'SEV4')),
  CONSTRAINT ck_incident_category CHECK (category IN ('DLQ_THRESHOLD', 'BACKUP_FAILURE', 'SECURITY_ALERT', 'AUDIT_CHAIN', 'SERVICE_DEGRADATION', 'MIGRATION', 'RESTORE', 'OTHER')),
  CONSTRAINT ck_incident_origin CHECK (origin IN ('EVENT', 'MANUAL')),
  CONSTRAINT ck_incident_event CHECK (origin <> 'EVENT' OR source_event_ref IS NOT NULL),
  CONSTRAINT ck_incident_status CHECK (status IN ('OPEN', 'INVESTIGATING', 'MITIGATED', 'RESOLVED', 'CLOSED')),
  CONSTRAINT ck_incident_closed CHECK (status <> 'CLOSED' OR (closed_at IS NOT NULL AND coalesce(char_length(btrim(root_cause)), 0) >= 20 AND coalesce(char_length(btrim(lessons_learned)), 0) >= 20)),
  CONSTRAINT ck_incident_resolved CHECK (status NOT IN ('RESOLVED', 'CLOSED') OR resolved_at IS NOT NULL),
  CONSTRAINT ck_incident_ph09 CHECK (NOT involves_personal_data OR status <> 'CLOSED' OR ph09_breach_ref IS NOT NULL)
);
CREATE INDEX ix_incident_open ON ph18_ops.incident (tenant_id, status, severity, detected_at DESC) WHERE status <> 'CLOSED';
CREATE TRIGGER tg_incident_touch BEFORE UPDATE ON ph18_ops.incident FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_incident_immutable BEFORE UPDATE ON ph18_ops.incident FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_immutable('incident_no', 'origin', 'detected_at');
CREATE TRIGGER tg_incident_fsm_status BEFORE UPDATE ON ph18_ops.incident FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_transition('status', 'OPEN>INVESTIGATING,OPEN>RESOLVED,INVESTIGATING>MITIGATED,INVESTIGATING>RESOLVED,MITIGATED>RESOLVED,MITIGATED>INVESTIGATING,RESOLVED>INVESTIGATING,RESOLVED>CLOSED');
CALL ph18_ops.p_enable_rls('ph18_ops.incident', false);
COMMENT ON TABLE ph18_ops.incident IS 'EN-18-32 Hồ sơ sự cố vận hành mở từ sự kiện (EVT-13-04, 05, DLQ vượt ngưỡng, sao lưu lỗi) hoặc tạo tay: mức độ, nhóm, chỉ huy, người xử lý, mốc thời gian, cờ dữ liệu cá nhân và tham chiếu PH-09 (INCIDENT_PH18, PH-09 giữ đồng hồ 72 giờ), nguyên nhân gốc và bài học khi đóng. Dòng COMMON là sự cố nền tảng.';
--rollback DROP TABLE IF EXISTS ph18_ops.incident CASCADE;

--changeset ph18:ph18-0440-incident-timeline splitStatements:false
CREATE TABLE ph18_ops.incident_timeline (
  id          uuid NOT NULL,
  tenant_id   varchar(16) NOT NULL,
  incident_id uuid NOT NULL,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  entry_kind  varchar(16) NOT NULL,
  actor       varchar(64) NOT NULL,
  from_status varchar(16),
  to_status   varchar(16),
  note        text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  created_by  varchar(64) NOT NULL,
  updated_at  timestamptz NOT NULL DEFAULT now(),
  updated_by  varchar(64) NOT NULL,
  version     integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_incident_timeline PRIMARY KEY (id),
  CONSTRAINT uq_incident_timeline_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_incident_timeline_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT fk_incident_timeline_incident FOREIGN KEY (tenant_id, incident_id) REFERENCES ph18_ops.incident (tenant_id, id),
  CONSTRAINT ck_incident_timeline_kind CHECK (entry_kind IN ('STATUS_CHANGE', 'NOTE', 'ASSIGNMENT', 'NOTIFICATION', 'ESCALATION_PH09', 'LINK', 'ACTION')),
  CONSTRAINT ck_incident_timeline_status_change CHECK (entry_kind <> 'STATUS_CHANGE' OR (from_status IS NOT NULL AND to_status IS NOT NULL))
);
CREATE INDEX ix_incident_timeline_incident ON ph18_ops.incident_timeline (tenant_id, incident_id, occurred_at);
CREATE TRIGGER tg_incident_timeline_touch BEFORE UPDATE ON ph18_ops.incident_timeline FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CREATE TRIGGER tg_incident_timeline_append_only BEFORE UPDATE OR DELETE ON ph18_ops.incident_timeline FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_append_only();
CALL ph18_ops.p_enable_rls('ph18_ops.incident_timeline', false);
COMMENT ON TABLE ph18_ops.incident_timeline IS 'EN-18-33 Mốc thời gian của sự cố: đổi trạng thái, ghi chú, gán, thông báo, chuyển PH-09, liên kết, hành động. Chỉ thêm.';
--rollback DROP TABLE IF EXISTS ph18_ops.incident_timeline CASCADE;

--changeset ph18:ph18-0450-incident-link splitStatements:false
CREATE TABLE ph18_ops.incident_link (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  incident_id   uuid NOT NULL,
  link_kind     varchar(16) NOT NULL,
  target_module varchar(8) NOT NULL,
  target_ref    varchar(255) NOT NULL,
  note          varchar(500),
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_incident_link PRIMARY KEY (id),
  CONSTRAINT uq_incident_link_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_incident_link_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_incident_link UNIQUE (tenant_id, incident_id, link_kind, target_ref),
  CONSTRAINT fk_incident_link_incident FOREIGN KEY (tenant_id, incident_id) REFERENCES ph18_ops.incident (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT ck_incident_link_kind CHECK (link_kind IN ('DLQ_MESSAGE', 'DLQ_GROUP', 'ALERT', 'BACKUP_RUN', 'MIGRATION_RUN', 'TRACE', 'PH09_BREACH', 'EXTERNAL')),
  CONSTRAINT ck_incident_link_module CHECK (target_module ~ '^PH[0-9]{2}$' OR target_module = 'EXT')
);
CREATE TRIGGER tg_incident_link_touch BEFORE UPDATE ON ph18_ops.incident_link FOR EACH ROW EXECUTE FUNCTION ph18_ops.tg_touch();
CALL ph18_ops.p_enable_rls('ph18_ops.incident_link', false);
COMMENT ON TABLE ph18_ops.incident_link IS 'EN-18-34 Liên kết sự cố với đối tượng: mục DLQ, nhóm lỗi, cảnh báo PH-13, bản sao lưu, lần di trú, trace, hồ sơ vi phạm PH-09, tham chiếu ngoài.';
--rollback DROP TABLE IF EXISTS ph18_ops.incident_link CASCADE;
