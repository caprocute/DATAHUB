--liquibase formatted sql
-- Nguồn: ddl/ph20_tenant.sql · 20-0050-quota.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph20:ph20-0290-tenant-quota
CREATE TABLE ph20_tenant.tenant_quota (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  resource_code          varchar(24)    NOT NULL,
  limit_value            numeric(20,3)  NOT NULL,
  unit                   varchar(16)    NOT NULL,
  source                 varchar(10)    NOT NULL DEFAULT 'TEMPLATE',
  warn_percent           smallint       NOT NULL DEFAULT 80,
  effective_from         timestamptz    NOT NULL DEFAULT now(),
  push_status            varchar(8)     NOT NULL DEFAULT 'PENDING',
  pushed_at              timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_quota PRIMARY KEY (id),
  CONSTRAINT uq_tenant_quota_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_quota_resource UNIQUE (tenant_id, resource_code),
  CONSTRAINT ck_tenant_quota_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_quota_resource_code CHECK (resource_code IN ('API_RPS', 'ACTIVE_FLOWS', 'KAFKA_PRODUCE_MBPS', 'KAFKA_CONSUME_MBPS', 'OBJECT_STORAGE_GB', 'DATABASE_GB', 'USERS', 'MEMBER_SYSTEMS', 'PUBLISHED_APIS', 'TOPICS', 'RUNTIME_CPU', 'RUNTIME_MEMORY_GB')),
  CONSTRAINT ck_tenant_quota_limit CHECK (limit_value >= 0),
  CONSTRAINT ck_tenant_quota_source CHECK (source IN ('TEMPLATE', 'CONTRACT', 'OVERRIDE')),
  CONSTRAINT ck_tenant_quota_push_status CHECK (push_status IN ('PENDING', 'PUSHED', 'FAILED')),
  CONSTRAINT ck_tenant_quota_warn CHECK (warn_percent BETWEEN 1 AND 99),
  CONSTRAINT fk_tenant_quota_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE TRIGGER tg_tenant_quota_touch BEFORE UPDATE ON ph20_tenant.tenant_quota FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_quota', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_quota IS 'EN-20-13 Hạn mức hợp đồng của tenant (FR-20-026, 027): mỗi tenant một dòng cho mỗi tài nguyên (12 loại). PH-20 giữ giá trị và đẩy xuống nơi thực thi (APISIX, Kafka, PH-04…), không tự thực thi (ADR 204).';
COMMENT ON COLUMN ph20_tenant.tenant_quota.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_quota.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.resource_code IS 'Tài nguyên: 12 giá trị `QuotaResource`.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.limit_value IS 'Giá trị hạn mức hợp đồng.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.unit IS 'Đơn vị: `rps`, `MB/s`, `GB`, `user`, `vCPU`…';
COMMENT ON COLUMN ph20_tenant.tenant_quota.source IS 'Nguồn giá trị: `TEMPLATE`, `CONTRACT`, `OVERRIDE`.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.warn_percent IS 'Ngưỡng cảnh báo, phần trăm (`20.quota.warn-percent`).';
COMMENT ON COLUMN ph20_tenant.tenant_quota.effective_from IS 'Hiệu lực từ.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.push_status IS 'Trạng thái đẩy xuống nơi thực thi: `PENDING`, `PUSHED`, `FAILED`.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.pushed_at IS 'Lần đẩy thành công gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_quota.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_quota.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_quota.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.tenant_quota CASCADE;

--changeset ph20:ph20-0300-quota-change-request
CREATE TABLE ph20_tenant.quota_change_request (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  resource_code          varchar(24)    NOT NULL,
  current_value          numeric(20,3)  NOT NULL,
  requested_value        numeric(20,3)  NOT NULL,
  current_usage          numeric(20,3),
  status                 varchar(16)    NOT NULL DEFAULT 'DRAFT',
  reason                 varchar(1000)  NOT NULL,
  ticket_code            varchar(32)    NOT NULL,
  requested_by           varchar(64)    NOT NULL,
  requested_at           timestamptz    NOT NULL DEFAULT now(),
  approved_by            varchar(64),
  approved_at            timestamptz,
  decision_note          varchar(1000),
  executed_at            timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_quota_change_request PRIMARY KEY (id),
  CONSTRAINT uq_quota_change_request_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_quota_change_request_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_quota_change_request_resource_code CHECK (resource_code IN ('API_RPS', 'ACTIVE_FLOWS', 'KAFKA_PRODUCE_MBPS', 'KAFKA_CONSUME_MBPS', 'OBJECT_STORAGE_GB', 'DATABASE_GB', 'USERS', 'MEMBER_SYSTEMS', 'PUBLISHED_APIS', 'TOPICS', 'RUNTIME_CPU', 'RUNTIME_MEMORY_GB')),
  CONSTRAINT ck_quota_change_request_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'EXECUTING', 'DONE', 'CANCELLED')),
  CONSTRAINT ck_quota_change_request_values CHECK (current_value >= 0 AND requested_value >= 0 AND requested_value <> current_value),
  CONSTRAINT ck_quota_change_request_four_eyes CHECK (approved_by IS NULL OR approved_by <> requested_by),
  CONSTRAINT ck_quota_change_request_approved CHECK (status NOT IN ('APPROVED', 'EXECUTING', 'DONE') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)),
  CONSTRAINT fk_quota_change_request_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE UNIQUE INDEX uq_quota_change_request_open ON ph20_tenant.quota_change_request (tenant_id, resource_code) WHERE status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'EXECUTING');
CREATE INDEX ix_quota_change_request_tenant_status ON ph20_tenant.quota_change_request (tenant_id, status);
CREATE TRIGGER tg_quota_change_request_touch BEFORE UPDATE ON ph20_tenant.quota_change_request FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_quota_change_request_transition BEFORE UPDATE ON ph20_tenant.quota_change_request FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_transition('status', '{"DRAFT": ["PENDING_APPROVAL", "CANCELLED"], "PENDING_APPROVAL": ["APPROVED", "REJECTED", "CANCELLED", "DRAFT"], "APPROVED": ["EXECUTING", "CANCELLED"], "EXECUTING": ["DONE", "APPROVED"]}');
CREATE TRIGGER tg_quota_change_request_immutable BEFORE UPDATE ON ph20_tenant.quota_change_request FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('resource_code', 'requested_by', 'requested_value');
CALL ph20_tenant.p_enable_rls('ph20_tenant.quota_change_request', 'CTL');
COMMENT ON TABLE ph20_tenant.quota_change_request IS 'EN-20-14 Đề nghị đổi hạn mức (FR-20-026, 027): có duyệt bốn mắt, người duyệt khác người đề nghị; hạ dưới mức đang dùng cần lý do và duyệt. Duyệt xong thì cập nhật `tenant_quota` và phát EVT-20-05.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.quota_change_request.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.resource_code IS 'Tài nguyên đề nghị đổi.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.current_value IS 'Giá trị hạn mức hiện tại khi đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.requested_value IS 'Giá trị đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.current_usage IS 'Mức đang dùng khi đề nghị (để phát hiện hạ dưới mức dùng).';
COMMENT ON COLUMN ph20_tenant.quota_change_request.status IS 'Trạng thái: `DRAFT`, `PENDING_APPROVAL`, `APPROVED`, `REJECTED`, `EXECUTING`, `DONE`, `CANCELLED`.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.reason IS 'Lý do đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.ticket_code IS 'Mã phiếu đề nghị (SEC-85).';
COMMENT ON COLUMN ph20_tenant.quota_change_request.requested_by IS 'Người đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.requested_at IS 'Thời điểm đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.approved_by IS 'Người duyệt, khác người đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.approved_at IS 'Thời điểm duyệt.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.decision_note IS 'Ghi chú quyết định, lý do từ chối.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.executed_at IS 'Thời điểm áp dụng.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.quota_change_request.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.quota_change_request.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.quota_change_request.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.quota_change_request CASCADE;

--changeset ph20:ph20-0310-quota-override
CREATE TABLE ph20_tenant.quota_override (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  resource_code          varchar(24)    NOT NULL,
  override_value         numeric(20,3)  NOT NULL,
  valid_from             timestamptz    NOT NULL,
  valid_to               timestamptz    NOT NULL,
  status                 varchar(8)     NOT NULL DEFAULT 'ACTIVE',
  reason                 varchar(1000)  NOT NULL,
  ticket_code            varchar(32)    NOT NULL,
  requested_by           varchar(64)    NOT NULL,
  approved_by            varchar(64)    NOT NULL,
  revoked_at             timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_quota_override PRIMARY KEY (id),
  CONSTRAINT uq_quota_override_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_quota_override_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_quota_override_resource_code CHECK (resource_code IN ('API_RPS', 'ACTIVE_FLOWS', 'KAFKA_PRODUCE_MBPS', 'KAFKA_CONSUME_MBPS', 'OBJECT_STORAGE_GB', 'DATABASE_GB', 'USERS', 'MEMBER_SYSTEMS', 'PUBLISHED_APIS', 'TOPICS', 'RUNTIME_CPU', 'RUNTIME_MEMORY_GB')),
  CONSTRAINT ck_quota_override_status CHECK (status IN ('ACTIVE', 'EXPIRED', 'REVOKED')),
  CONSTRAINT ck_quota_override_value CHECK (override_value >= 0),
  CONSTRAINT ck_quota_override_valid CHECK (valid_to > valid_from),
  CONSTRAINT ck_quota_override_four_eyes CHECK (approved_by <> requested_by),
  CONSTRAINT ck_quota_override_revoked CHECK (status <> 'REVOKED' OR revoked_at IS NOT NULL),
  CONSTRAINT fk_quota_override_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE INDEX ix_quota_override_active ON ph20_tenant.quota_override (tenant_id, resource_code, valid_to) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_quota_override_touch BEFORE UPDATE ON ph20_tenant.quota_override FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.quota_override', 'CTL');
COMMENT ON TABLE ph20_tenant.quota_override IS 'EN-20-15 Ghi đè hạn mức tạm thời có thời hạn (FR-20-032): nâng tạm trần cho một tài nguyên trong khoảng ngày, tự hết hạn; thời hạn tối đa `20.quota.override-max-days` kiểm ở dịch vụ. Người phê duyệt khác người đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_override.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.quota_override.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.quota_override.resource_code IS 'Tài nguyên được ghi đè.';
COMMENT ON COLUMN ph20_tenant.quota_override.override_value IS 'Giá trị hạn mức tạm thời.';
COMMENT ON COLUMN ph20_tenant.quota_override.valid_from IS 'Hiệu lực từ.';
COMMENT ON COLUMN ph20_tenant.quota_override.valid_to IS 'Hết hiệu lực, sau `valid_from`.';
COMMENT ON COLUMN ph20_tenant.quota_override.status IS 'Trạng thái: `ACTIVE`, `EXPIRED`, `REVOKED`.';
COMMENT ON COLUMN ph20_tenant.quota_override.reason IS 'Lý do ghi đè.';
COMMENT ON COLUMN ph20_tenant.quota_override.ticket_code IS 'Mã phiếu.';
COMMENT ON COLUMN ph20_tenant.quota_override.requested_by IS 'Người đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_override.approved_by IS 'Người duyệt, khác người đề nghị.';
COMMENT ON COLUMN ph20_tenant.quota_override.revoked_at IS 'Thời điểm thu hồi sớm.';
COMMENT ON COLUMN ph20_tenant.quota_override.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.quota_override.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.quota_override.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.quota_override.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.quota_override.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.quota_override CASCADE;

--changeset ph20:ph20-0320-usage-snapshot
CREATE TABLE ph20_tenant.usage_snapshot (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  resource_code          varchar(24)    NOT NULL,
  captured_at            timestamptz    NOT NULL,
  used_value             numeric(20,3)  NOT NULL,
  limit_value            numeric(20,3),
  percent_used           numeric(7,2),
  source                 varchar(14)    NOT NULL DEFAULT 'MIMIR',
  is_estimate            boolean        NOT NULL DEFAULT false,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_usage_snapshot PRIMARY KEY (id, captured_at),
  CONSTRAINT uq_usage_snapshot_point UNIQUE (tenant_id, resource_code, captured_at),
  CONSTRAINT ck_usage_snapshot_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_usage_snapshot_resource_code CHECK (resource_code IN ('API_RPS', 'ACTIVE_FLOWS', 'KAFKA_PRODUCE_MBPS', 'KAFKA_CONSUME_MBPS', 'OBJECT_STORAGE_GB', 'DATABASE_GB', 'USERS', 'MEMBER_SYSTEMS', 'PUBLISHED_APIS', 'TOPICS', 'RUNTIME_CPU', 'RUNTIME_MEMORY_GB')),
  CONSTRAINT ck_usage_snapshot_source CHECK (source IN ('MIMIR', 'APISIX', 'KAFKA', 'OBJECT_STORE', 'DATABASE', 'IAM', 'CATALOG', 'RUNTIME', 'OTHER')),
  CONSTRAINT ck_usage_snapshot_used CHECK (used_value >= 0),
  CONSTRAINT ck_usage_snapshot_limit CHECK (limit_value IS NULL OR limit_value >= 0),
  CONSTRAINT fk_usage_snapshot_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
) PARTITION BY RANGE (captured_at);
CREATE INDEX ix_usage_snapshot_tenant_time ON ph20_tenant.usage_snapshot (tenant_id, captured_at DESC);
CREATE TRIGGER tg_usage_snapshot_touch BEFORE UPDATE ON ph20_tenant.usage_snapshot FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.usage_snapshot', 'CTL');
CREATE TABLE ph20_tenant.usage_snapshot_default PARTITION OF ph20_tenant.usage_snapshot DEFAULT;
CALL ph20_tenant.p_ensure_partitions('ph20_tenant.usage_snapshot', date '2026-11-01', 6);
COMMENT ON TABLE ph20_tenant.usage_snapshot IS 'EN-20-16 Ảnh chụp sử dụng tài nguyên (FR-20-028, 030): mỗi giờ mỗi tài nguyên một dòng lấy từ nơi thực thi (Mimir, APISIX, Kafka, kho đối tượng, CSDL…). Phân vùng theo tháng trên `captured_at`, giữ `20.usage.retention-months` tháng.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.resource_code IS 'Tài nguyên: 12 giá trị `QuotaResource`.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.captured_at IS 'Thời điểm chụp (đầu giờ), khóa phân vùng.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.used_value IS 'Mức đang dùng.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.limit_value IS 'Hạn mức hiệu lực tại thời điểm chụp (gồm ghi đè).';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.percent_used IS 'Phần trăm đã dùng so với hạn mức.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.source IS 'Nơi lấy số liệu: `MIMIR`, `APISIX`, `KAFKA`, `OBJECT_STORE`, `DATABASE`, `IAM`, `CATALOG`, `RUNTIME`, `OTHER`.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.is_estimate IS 'Số liệu ước tính khi nguồn tạm không đọc được.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.usage_snapshot.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.usage_snapshot CASCADE;

--changeset ph20:ph20-0330-quota-alert
CREATE TABLE ph20_tenant.quota_alert (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  resource_code          varchar(24)    NOT NULL,
  alert_level            varchar(10)    NOT NULL,
  state                  varchar(12)    NOT NULL DEFAULT 'OPEN',
  used_value             numeric(20,3)  NOT NULL,
  limit_value            numeric(20,3)  NOT NULL,
  percent_used           numeric(7,2)   NOT NULL,
  raised_at              timestamptz    NOT NULL DEFAULT now(),
  acknowledged_by        varchar(64),
  acknowledged_at        timestamptz,
  resolved_at            timestamptz,
  event_id               uuid,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_quota_alert PRIMARY KEY (id),
  CONSTRAINT uq_quota_alert_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_quota_alert_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_quota_alert_resource_code CHECK (resource_code IN ('API_RPS', 'ACTIVE_FLOWS', 'KAFKA_PRODUCE_MBPS', 'KAFKA_CONSUME_MBPS', 'OBJECT_STORAGE_GB', 'DATABASE_GB', 'USERS', 'MEMBER_SYSTEMS', 'PUBLISHED_APIS', 'TOPICS', 'RUNTIME_CPU', 'RUNTIME_MEMORY_GB')),
  CONSTRAINT ck_quota_alert_alert_level CHECK (alert_level IN ('WARN_80', 'LIMIT_100')),
  CONSTRAINT ck_quota_alert_state CHECK (state IN ('OPEN', 'ACKNOWLEDGED', 'RESOLVED')),
  CONSTRAINT ck_quota_alert_limit CHECK (limit_value > 0),
  CONSTRAINT ck_quota_alert_resolved CHECK (state <> 'RESOLVED' OR resolved_at IS NOT NULL),
  CONSTRAINT fk_quota_alert_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE UNIQUE INDEX uq_quota_alert_open ON ph20_tenant.quota_alert (tenant_id, resource_code, alert_level) WHERE state IN ('OPEN', 'ACKNOWLEDGED');
CREATE INDEX ix_quota_alert_raised ON ph20_tenant.quota_alert (tenant_id, raised_at DESC);
CREATE TRIGGER tg_quota_alert_touch BEFORE UPDATE ON ph20_tenant.quota_alert FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.quota_alert', 'CTL');
COMMENT ON TABLE ph20_tenant.quota_alert IS 'EN-20-17 Cảnh báo hạn mức (FR-20-029): chạm 80% (`WARN_80`) hoặc 100% (`LIMIT_100`), phát EVT-20-06 cho PH-13, PH-18; mỗi (tenant, tài nguyên, mức) tối đa một cảnh báo đang mở.';
COMMENT ON COLUMN ph20_tenant.quota_alert.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.quota_alert.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.quota_alert.resource_code IS 'Tài nguyên.';
COMMENT ON COLUMN ph20_tenant.quota_alert.alert_level IS 'Mức: `WARN_80` hoặc `LIMIT_100`.';
COMMENT ON COLUMN ph20_tenant.quota_alert.state IS 'Trạng thái: `OPEN`, `ACKNOWLEDGED`, `RESOLVED`.';
COMMENT ON COLUMN ph20_tenant.quota_alert.used_value IS 'Mức dùng khi phát cảnh báo.';
COMMENT ON COLUMN ph20_tenant.quota_alert.limit_value IS 'Hạn mức hiệu lực khi phát cảnh báo.';
COMMENT ON COLUMN ph20_tenant.quota_alert.percent_used IS 'Phần trăm đã dùng.';
COMMENT ON COLUMN ph20_tenant.quota_alert.raised_at IS 'Thời điểm phát.';
COMMENT ON COLUMN ph20_tenant.quota_alert.acknowledged_by IS 'Người xác nhận đã xem.';
COMMENT ON COLUMN ph20_tenant.quota_alert.acknowledged_at IS 'Thời điểm xác nhận.';
COMMENT ON COLUMN ph20_tenant.quota_alert.resolved_at IS 'Thời điểm hết cảnh báo.';
COMMENT ON COLUMN ph20_tenant.quota_alert.event_id IS 'Sự kiện outbox EVT-20-06 đã phát.';
COMMENT ON COLUMN ph20_tenant.quota_alert.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.quota_alert.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.quota_alert.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.quota_alert.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.quota_alert.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.quota_alert CASCADE;

--changeset ph20:ph20-0340-usage-report
CREATE TABLE ph20_tenant.usage_report (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  report_scope           varchar(8)     NOT NULL DEFAULT 'TENANT',
  period_from            date           NOT NULL,
  period_to              date           NOT NULL,
  granularity            varchar(8)     NOT NULL DEFAULT 'MONTH',
  format                 varchar(4)     NOT NULL DEFAULT 'XLSX',
  status                 varchar(12)    NOT NULL DEFAULT 'REQUESTED',
  file_id                uuid,
  row_count              integer,
  requested_by           varchar(64)    NOT NULL,
  expires_at             timestamptz,
  error_message          varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_usage_report PRIMARY KEY (id),
  CONSTRAINT uq_usage_report_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_usage_report_tenant CHECK (tenant_id ~ '^T[0-9]{2}$' OR tenant_id = 'PLATFORM'),
  CONSTRAINT ck_usage_report_report_scope CHECK (report_scope IN ('TENANT', 'PLATFORM')),
  CONSTRAINT ck_usage_report_format CHECK (format IN ('XLSX', 'CSV', 'PDF')),
  CONSTRAINT ck_usage_report_status CHECK (status IN ('REQUESTED', 'GENERATING', 'READY', 'FAILED', 'EXPIRED')),
  CONSTRAINT ck_usage_report_period CHECK (period_to >= period_from),
  CONSTRAINT ck_usage_report_granularity CHECK (granularity IN ('HOUR', 'DAY', 'MONTH')),
  CONSTRAINT ck_usage_report_scope_tenant CHECK ((report_scope = 'PLATFORM') = (tenant_id = 'PLATFORM')),
  CONSTRAINT ck_usage_report_ready CHECK (status <> 'READY' OR file_id IS NOT NULL),
  CONSTRAINT fk_usage_report_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_usage_report_file FOREIGN KEY (file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id)
);
CREATE INDEX ix_usage_report_tenant_period ON ph20_tenant.usage_report (tenant_id, period_from DESC);
CREATE INDEX ix_usage_report_fk_file ON ph20_tenant.usage_report (tenant_id, file_id);
CREATE TRIGGER tg_usage_report_touch BEFORE UPDATE ON ph20_tenant.usage_report FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.usage_report', 'CTL');
COMMENT ON TABLE ph20_tenant.usage_report IS 'EN-20-37 Báo cáo sử dụng (FR-20-031): báo cáo theo kỳ cho một tenant hoặc toàn nền tảng (`tenant_id = PLATFORM`), xuất `XLSX`, `CSV`, `PDF`; tệp lưu ở `file_object`, hết hạn tự dọn.';
COMMENT ON COLUMN ph20_tenant.usage_report.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.usage_report.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.usage_report.report_scope IS 'Phạm vi: `TENANT` hoặc `PLATFORM`.';
COMMENT ON COLUMN ph20_tenant.usage_report.period_from IS 'Kỳ báo cáo từ ngày.';
COMMENT ON COLUMN ph20_tenant.usage_report.period_to IS 'Kỳ báo cáo đến ngày, không nhỏ hơn `period_from`.';
COMMENT ON COLUMN ph20_tenant.usage_report.granularity IS 'Độ mịn: `HOUR`, `DAY`, `MONTH`.';
COMMENT ON COLUMN ph20_tenant.usage_report.format IS 'Định dạng: `XLSX`, `CSV`, `PDF`.';
COMMENT ON COLUMN ph20_tenant.usage_report.status IS 'Trạng thái: `REQUESTED`, `GENERATING`, `READY`, `FAILED`, `EXPIRED`.';
COMMENT ON COLUMN ph20_tenant.usage_report.file_id IS 'Tệp kết quả.';
COMMENT ON COLUMN ph20_tenant.usage_report.row_count IS 'Số dòng của báo cáo.';
COMMENT ON COLUMN ph20_tenant.usage_report.requested_by IS 'Người yêu cầu.';
COMMENT ON COLUMN ph20_tenant.usage_report.expires_at IS 'Hạn tải tệp.';
COMMENT ON COLUMN ph20_tenant.usage_report.error_message IS 'Thông điệp lỗi.';
COMMENT ON COLUMN ph20_tenant.usage_report.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.usage_report.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.usage_report.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.usage_report.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.usage_report.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.usage_report CASCADE;
