--liquibase formatted sql
-- Nguồn: ddl/ph20_tenant.sql · 20-0080-release.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph20:ph20-0450-product-release
CREATE TABLE ph20_tenant.product_release (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  version_code           varchar(32)    NOT NULL,
  name                   varchar(255),
  status                 varchar(12)    NOT NULL DEFAULT 'DRAFT',
  release_notes          text,
  breaking_change        boolean        NOT NULL DEFAULT false,
  min_from_version       varchar(32),
  preview_at             timestamptz,
  stable_at              timestamptz,
  deprecated_at          timestamptz,
  withdrawn_at           timestamptz,
  withdrawn_reason       varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_product_release PRIMARY KEY (id),
  CONSTRAINT uq_product_release_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_product_release_version UNIQUE (version_code),
  CONSTRAINT ck_product_release_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_product_release_status CHECK (status IN ('DRAFT', 'PREVIEW', 'STABLE', 'DEPRECATED', 'WITHDRAWN')),
  CONSTRAINT ck_product_release_version CHECK (version_code ~ '^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$'),
  CONSTRAINT ck_product_release_preview CHECK (status NOT IN ('PREVIEW', 'STABLE', 'DEPRECATED') OR preview_at IS NOT NULL),
  CONSTRAINT ck_product_release_stable CHECK (status <> 'STABLE' OR (stable_at IS NOT NULL AND preview_at IS NOT NULL AND stable_at >= preview_at)),
  CONSTRAINT ck_product_release_withdrawn CHECK (status <> 'WITHDRAWN' OR (withdrawn_at IS NOT NULL AND withdrawn_reason IS NOT NULL))
);
CREATE TRIGGER tg_product_release_touch BEFORE UPDATE ON ph20_tenant.product_release FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_product_release_transition BEFORE UPDATE ON ph20_tenant.product_release FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_transition('status', '{"DRAFT": ["PREVIEW", "WITHDRAWN"], "PREVIEW": ["STABLE", "DEPRECATED", "WITHDRAWN"], "STABLE": ["DEPRECATED", "WITHDRAWN"], "DEPRECATED": ["WITHDRAWN"]}');
CREATE TRIGGER tg_product_release_immutable BEFORE UPDATE ON ph20_tenant.product_release FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('version_code');
CALL ph20_tenant.p_enable_rls('ph20_tenant.product_release', 'PLATR');
COMMENT ON TABLE ph20_tenant.product_release IS 'EN-20-31 Phiên bản sản phẩm (FR-20-059, 060): danh mục phiên bản Datahub với ghi chú phát hành, qua `PREVIEW` rồi `STABLE` (ADR 203). Dữ liệu nền tảng, mọi tenant đọc được để xem phiên bản và ghi chú (FR-20-064).';
COMMENT ON COLUMN ph20_tenant.product_release.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.product_release.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.product_release.version_code IS 'Số phiên bản, dạng `1.0.0` hoặc `1.1.0-rc.1`.';
COMMENT ON COLUMN ph20_tenant.product_release.name IS 'Tên bản phát hành.';
COMMENT ON COLUMN ph20_tenant.product_release.status IS 'Trạng thái: `DRAFT`, `PREVIEW`, `STABLE`, `DEPRECATED`, `WITHDRAWN`.';
COMMENT ON COLUMN ph20_tenant.product_release.release_notes IS 'Ghi chú phát hành (Markdown).';
COMMENT ON COLUMN ph20_tenant.product_release.breaking_change IS 'Có thay đổi phá vỡ tương thích.';
COMMENT ON COLUMN ph20_tenant.product_release.min_from_version IS 'Phiên bản thấp nhất được nâng cấp thẳng lên bản này.';
COMMENT ON COLUMN ph20_tenant.product_release.preview_at IS 'Thời điểm sang kênh `PREVIEW`.';
COMMENT ON COLUMN ph20_tenant.product_release.stable_at IS 'Thời điểm sang kênh `STABLE` (sau thời gian chạy thử, `20.release.stable-soak-days`).';
COMMENT ON COLUMN ph20_tenant.product_release.deprecated_at IS 'Thời điểm ngừng khuyến nghị.';
COMMENT ON COLUMN ph20_tenant.product_release.withdrawn_at IS 'Thời điểm rút bản.';
COMMENT ON COLUMN ph20_tenant.product_release.withdrawn_reason IS 'Lý do rút bản.';
COMMENT ON COLUMN ph20_tenant.product_release.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.product_release.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.product_release.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.product_release.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.product_release.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.product_release CASCADE;

--changeset ph20:ph20-0460-release-component
CREATE TABLE ph20_tenant.release_component (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  release_id             uuid           NOT NULL,
  component_code         varchar(64)    NOT NULL,
  component_type         varchar(10)    NOT NULL,
  image_ref              varchar(255),
  chart_version          varchar(32),
  digest                 varchar(71),
  migration_required     boolean        NOT NULL DEFAULT false,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_release_component PRIMARY KEY (id),
  CONSTRAINT uq_release_component_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_release_component_component UNIQUE (release_id, component_code),
  CONSTRAINT ck_release_component_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_release_component_component_type CHECK (component_type IN ('SERVICE', 'CONSOLE', 'CHART', 'SCHEMA', 'CONFIG')),
  CONSTRAINT ck_release_component_digest CHECK (digest IS NULL OR digest ~ '^sha256:[0-9a-f]{64}$'),
  CONSTRAINT fk_release_component_release FOREIGN KEY (release_id, tenant_id) REFERENCES ph20_tenant.product_release (id, tenant_id) ON DELETE CASCADE
);
CREATE INDEX ix_release_component_fk_release ON ph20_tenant.release_component (tenant_id, release_id);
CREATE TRIGGER tg_release_component_touch BEFORE UPDATE ON ph20_tenant.release_component FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.release_component', 'PLATR');
COMMENT ON TABLE ph20_tenant.release_component IS 'EN-20-31 Thành phần của phiên bản (FR-20-059): dịch vụ, giao diện, chart, schema CSDL, cấu hình thuộc một bản phát hành, kèm mã băm ảnh. Không chứa thông tin xác thực kho ảnh.';
COMMENT ON COLUMN ph20_tenant.release_component.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.release_component.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.release_component.release_id IS 'Phiên bản sản phẩm.';
COMMENT ON COLUMN ph20_tenant.release_component.component_code IS 'Mã thành phần, ví dụ `dh-platform`, `dh-console`, `ph20_tenant`.';
COMMENT ON COLUMN ph20_tenant.release_component.component_type IS 'Loại: `SERVICE`, `CONSOLE`, `CHART`, `SCHEMA`, `CONFIG`.';
COMMENT ON COLUMN ph20_tenant.release_component.image_ref IS 'Tham chiếu ảnh, gói (không kèm thông tin xác thực).';
COMMENT ON COLUMN ph20_tenant.release_component.chart_version IS 'Phiên bản Helm chart.';
COMMENT ON COLUMN ph20_tenant.release_component.digest IS 'Mã băm ảnh `sha256:...`.';
COMMENT ON COLUMN ph20_tenant.release_component.migration_required IS 'Cần chạy migration CSDL khi nâng cấp.';
COMMENT ON COLUMN ph20_tenant.release_component.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.release_component.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.release_component.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.release_component.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.release_component.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.release_component CASCADE;

--changeset ph20:ph20-0470-tenant-release-subscription
CREATE TABLE ph20_tenant.tenant_release_subscription (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  channel                varchar(8)     NOT NULL DEFAULT 'STABLE',
  pinned_release_id      uuid,
  current_release_id     uuid,
  is_pilot               boolean        NOT NULL DEFAULT false,
  subscribed_at          timestamptz    NOT NULL DEFAULT now(),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_release_subscription PRIMARY KEY (id),
  CONSTRAINT uq_tenant_release_subscription_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_release_subscription_tenant UNIQUE (tenant_id),
  CONSTRAINT ck_tenant_release_subscription_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_release_subscription_channel CHECK (channel IN ('STABLE', 'PREVIEW')),
  CONSTRAINT fk_tenant_release_subscription_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_tenant_release_subscription_pinned_release FOREIGN KEY (pinned_release_id) REFERENCES ph20_tenant.product_release (id),
  CONSTRAINT fk_tenant_release_subscription_current_release FOREIGN KEY (current_release_id) REFERENCES ph20_tenant.product_release (id)
);
CREATE TRIGGER tg_tenant_release_subscription_touch BEFORE UPDATE ON ph20_tenant.tenant_release_subscription FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_release_subscription', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_release_subscription IS 'EN-20-32 Đăng ký kênh phát hành của tenant (FR-20-060): tenant theo kênh `STABLE` hoặc `PREVIEW`, có thể ghim phiên bản, đánh dấu tenant thí điểm nhận bản trước (ADR 203). Một dòng mỗi tenant.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.channel IS 'Kênh: `STABLE` hoặc `PREVIEW`.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.pinned_release_id IS 'Phiên bản được ghim (không tự nâng cấp lên bản mới hơn).';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.current_release_id IS 'Phiên bản đang chạy của tenant.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.is_pilot IS 'Tenant thí điểm, nhận bản `PREVIEW` và là nơi chạy thử đủ thời gian trước khi sang `STABLE`.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.subscribed_at IS 'Thời điểm đăng ký kênh.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_release_subscription.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.tenant_release_subscription CASCADE;

--changeset ph20:ph20-0480-maintenance-window
CREATE TABLE ph20_tenant.maintenance_window (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  name                   varchar(255)   NOT NULL,
  window_type            varchar(10)    NOT NULL DEFAULT 'RECURRING',
  day_of_week            smallint,
  start_time             time,
  duration_minutes       integer        NOT NULL DEFAULT 240,
  starts_at              timestamptz,
  ends_at                timestamptz,
  timezone               varchar(40)    NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  enabled                boolean        NOT NULL DEFAULT true,
  note                   varchar(500),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_maintenance_window PRIMARY KEY (id),
  CONSTRAINT uq_maintenance_window_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_maintenance_window_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_maintenance_window_window_type CHECK (window_type IN ('RECURRING', 'ONE_OFF')),
  CONSTRAINT ck_maintenance_window_duration CHECK (duration_minutes BETWEEN 120 AND 360),
  CONSTRAINT ck_maintenance_window_day CHECK (day_of_week IS NULL OR day_of_week BETWEEN 1 AND 7),
  CONSTRAINT ck_maintenance_window_recurring CHECK (window_type <> 'RECURRING' OR (day_of_week IS NOT NULL AND start_time IS NOT NULL)),
  CONSTRAINT ck_maintenance_window_one_off CHECK (window_type <> 'ONE_OFF' OR (starts_at IS NOT NULL AND ends_at IS NOT NULL AND ends_at > starts_at)),
  CONSTRAINT fk_maintenance_window_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE INDEX ix_maintenance_window_enabled ON ph20_tenant.maintenance_window (tenant_id, enabled);
CREATE TRIGGER tg_maintenance_window_touch BEFORE UPDATE ON ph20_tenant.maintenance_window FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.maintenance_window', 'OWN');
COMMENT ON TABLE ph20_tenant.maintenance_window IS 'EN-20-33 Cửa sổ bảo trì của tenant (FR-20-061, 063, 064): khung giờ định kỳ hoặc một lần mà nâng cấp được phép chạy; tỉnh tự khai báo, kế hoạch nâng cấp tôn trọng cửa sổ.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.name IS 'Tên cửa sổ.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.window_type IS 'Loại: `RECURRING` (hằng tuần) hoặc `ONE_OFF` (một lần).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.day_of_week IS 'Thứ trong tuần theo ISO, 1 là thứ Hai (cửa sổ `RECURRING`).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.start_time IS 'Giờ bắt đầu theo múi giờ của cửa sổ (cửa sổ `RECURRING`).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.duration_minutes IS 'Thời lượng, phút, từ 120 đến 360 (2…6 giờ, FR-20-018).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.starts_at IS 'Bắt đầu (cửa sổ `ONE_OFF`).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.ends_at IS 'Kết thúc (cửa sổ `ONE_OFF`).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.timezone IS 'Múi giờ.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.enabled IS 'Cửa sổ đang áp dụng.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.note IS 'Ghi chú.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.maintenance_window.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.maintenance_window.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.maintenance_window CASCADE;

--changeset ph20:ph20-0490-upgrade-plan
CREATE TABLE ph20_tenant.upgrade_plan (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  plan_code              varchar(48)    NOT NULL,
  release_id             uuid           NOT NULL,
  channel                varchar(8)     NOT NULL DEFAULT 'STABLE',
  status                 varchar(12)    NOT NULL DEFAULT 'DRAFT',
  error_threshold_percent numeric(5,2)   NOT NULL DEFAULT 2,
  scheduled_at           timestamptz,
  started_at             timestamptz,
  completed_at           timestamptz,
  pause_reason           varchar(1000),
  ticket_code            varchar(32),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_upgrade_plan PRIMARY KEY (id),
  CONSTRAINT uq_upgrade_plan_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_upgrade_plan_code UNIQUE (plan_code),
  CONSTRAINT ck_upgrade_plan_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_upgrade_plan_status CHECK (status IN ('DRAFT', 'SCHEDULED', 'RUNNING', 'PAUSED', 'COMPLETED', 'ROLLED_BACK', 'CANCELLED')),
  CONSTRAINT ck_upgrade_plan_channel CHECK (channel IN ('STABLE', 'PREVIEW')),
  CONSTRAINT ck_upgrade_plan_code CHECK (plan_code ~ '^[a-z0-9][a-z0-9-]{2,47}$'),
  CONSTRAINT ck_upgrade_plan_threshold CHECK (error_threshold_percent BETWEEN 0 AND 100),
  CONSTRAINT ck_upgrade_plan_running CHECK (status NOT IN ('RUNNING', 'PAUSED', 'COMPLETED', 'ROLLED_BACK') OR started_at IS NOT NULL),
  CONSTRAINT fk_upgrade_plan_release FOREIGN KEY (release_id, tenant_id) REFERENCES ph20_tenant.product_release (id, tenant_id)
);
CREATE INDEX ix_upgrade_plan_status ON ph20_tenant.upgrade_plan (status);
CREATE INDEX ix_upgrade_plan_fk_release ON ph20_tenant.upgrade_plan (tenant_id, release_id);
CREATE TRIGGER tg_upgrade_plan_touch BEFORE UPDATE ON ph20_tenant.upgrade_plan FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_upgrade_plan_immutable BEFORE UPDATE ON ph20_tenant.upgrade_plan FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('plan_code', 'release_id');
CALL ph20_tenant.p_enable_rls('ph20_tenant.upgrade_plan', 'PLAT');
COMMENT ON TABLE ph20_tenant.upgrade_plan IS 'EN-20-34 Kế hoạch nâng cấp theo sóng (FR-20-061, 062): đưa một phiên bản lên các tenant theo từng sóng; tự dừng khi tỷ lệ lỗi vượt `error_threshold_percent` (`20.release.wave-error-threshold-percent`).';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.plan_code IS 'Mã kế hoạch, dạng `nang-cap-1-1-0`.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.release_id IS 'Phiên bản đích.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.channel IS 'Kênh áp dụng: `STABLE` hoặc `PREVIEW`.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.status IS 'Trạng thái: `DRAFT`, `SCHEDULED`, `RUNNING`, `PAUSED`, `COMPLETED`, `ROLLED_BACK`, `CANCELLED`.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.error_threshold_percent IS 'Ngưỡng lỗi dừng sóng, phần trăm.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.scheduled_at IS 'Thời điểm bắt đầu dự kiến.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.started_at IS 'Bắt đầu thực tế.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.completed_at IS 'Kết thúc.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.pause_reason IS 'Lý do dừng.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.ticket_code IS 'Mã phiếu thay đổi.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.upgrade_plan.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.upgrade_plan CASCADE;

--changeset ph20:ph20-0500-upgrade-wave
CREATE TABLE ph20_tenant.upgrade_wave (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  plan_id                uuid           NOT NULL,
  wave_no                smallint       NOT NULL,
  name                   varchar(255),
  status                 varchar(10)    NOT NULL DEFAULT 'PENDING',
  tenant_selector        jsonb          NOT NULL DEFAULT '{}',
  tenant_count           integer        NOT NULL DEFAULT 0,
  planned_start          timestamptz,
  started_at             timestamptz,
  finished_at            timestamptz,
  error_percent          numeric(5,2),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_upgrade_wave PRIMARY KEY (id),
  CONSTRAINT uq_upgrade_wave_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_upgrade_wave_wave UNIQUE (plan_id, wave_no),
  CONSTRAINT ck_upgrade_wave_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_upgrade_wave_status CHECK (status IN ('PENDING', 'RUNNING', 'PAUSED', 'DONE', 'STOPPED')),
  CONSTRAINT ck_upgrade_wave_wave CHECK (wave_no >= 1),
  CONSTRAINT ck_upgrade_wave_selector CHECK (jsonb_typeof(tenant_selector) = 'object'),
  CONSTRAINT ck_upgrade_wave_count CHECK (tenant_count >= 0),
  CONSTRAINT ck_upgrade_wave_error CHECK (error_percent IS NULL OR error_percent BETWEEN 0 AND 100),
  CONSTRAINT fk_upgrade_wave_plan FOREIGN KEY (plan_id, tenant_id) REFERENCES ph20_tenant.upgrade_plan (id, tenant_id) ON DELETE CASCADE
);
CREATE INDEX ix_upgrade_wave_fk_plan ON ph20_tenant.upgrade_wave (tenant_id, plan_id);
CREATE TRIGGER tg_upgrade_wave_touch BEFORE UPDATE ON ph20_tenant.upgrade_wave FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.upgrade_wave', 'PLAT');
COMMENT ON TABLE ph20_tenant.upgrade_wave IS 'EN-20-34 Sóng nâng cấp (FR-20-061, 062): nhóm tenant nâng cấp cùng lúc, thường sóng 1 là tenant thí điểm; dừng sóng tự động khi vượt ngưỡng lỗi.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.plan_id IS 'Kế hoạch nâng cấp.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.wave_no IS 'Số thứ tự sóng, bắt đầu từ 1.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.name IS 'Tên sóng.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.status IS 'Trạng thái: `PENDING`, `RUNNING`, `PAUSED`, `DONE`, `STOPPED`.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.tenant_selector IS 'Điều kiện chọn tenant (danh sách mã, cờ thí điểm, hồ sơ quy mô).';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.tenant_count IS 'Số tenant trong sóng.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.planned_start IS 'Bắt đầu dự kiến.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.started_at IS 'Bắt đầu thực tế.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.finished_at IS 'Kết thúc.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.error_percent IS 'Tỷ lệ lỗi hiện tại của sóng.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.upgrade_wave.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.upgrade_wave CASCADE;

--changeset ph20:ph20-0510-tenant-upgrade
CREATE TABLE ph20_tenant.tenant_upgrade (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  plan_id                uuid           NOT NULL,
  wave_id                uuid           NOT NULL,
  release_id             uuid           NOT NULL,
  status                 varchar(12)    NOT NULL DEFAULT 'PENDING',
  maintenance_window_id  uuid,
  scheduled_for          timestamptz,
  started_at             timestamptz,
  verified_at            timestamptz,
  finished_at            timestamptz,
  attempt                integer        NOT NULL DEFAULT 1,
  rollback_release_id    uuid,
  error_code             varchar(16),
  error_message          varchar(1000),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_upgrade PRIMARY KEY (id),
  CONSTRAINT uq_tenant_upgrade_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_upgrade_wave UNIQUE (wave_id, tenant_id),
  CONSTRAINT ck_tenant_upgrade_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_upgrade_status CHECK (status IN ('PENDING', 'IN_WINDOW', 'UPGRADING', 'VERIFYING', 'DONE', 'FAILED', 'ROLLED_BACK', 'SKIPPED')),
  CONSTRAINT ck_tenant_upgrade_attempt CHECK (attempt >= 1),
  CONSTRAINT ck_tenant_upgrade_done CHECK (status <> 'DONE' OR finished_at IS NOT NULL),
  CONSTRAINT ck_tenant_upgrade_rollback CHECK (status <> 'ROLLED_BACK' OR rollback_release_id IS NOT NULL),
  CONSTRAINT fk_tenant_upgrade_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_tenant_upgrade_plan FOREIGN KEY (plan_id) REFERENCES ph20_tenant.upgrade_plan (id),
  CONSTRAINT fk_tenant_upgrade_wave FOREIGN KEY (wave_id) REFERENCES ph20_tenant.upgrade_wave (id),
  CONSTRAINT fk_tenant_upgrade_release FOREIGN KEY (release_id) REFERENCES ph20_tenant.product_release (id),
  CONSTRAINT fk_tenant_upgrade_window FOREIGN KEY (maintenance_window_id, tenant_id) REFERENCES ph20_tenant.maintenance_window (id, tenant_id),
  CONSTRAINT fk_tenant_upgrade_rollback_release FOREIGN KEY (rollback_release_id) REFERENCES ph20_tenant.product_release (id)
);
CREATE INDEX ix_tenant_upgrade_tenant_status ON ph20_tenant.tenant_upgrade (tenant_id, status);
CREATE INDEX ix_tenant_upgrade_plan ON ph20_tenant.tenant_upgrade (plan_id);
CREATE INDEX ix_tenant_upgrade_fk_window ON ph20_tenant.tenant_upgrade (tenant_id, maintenance_window_id);
CREATE TRIGGER tg_tenant_upgrade_touch BEFORE UPDATE ON ph20_tenant.tenant_upgrade FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_upgrade', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_upgrade IS 'EN-20-35 Nâng cấp theo tenant (FR-20-062, 064): trạng thái nâng cấp của từng tenant trong một sóng, gắn cửa sổ bảo trì; mỗi đổi trạng thái phát EVT-20-15.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.plan_id IS 'Kế hoạch nâng cấp.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.wave_id IS 'Sóng chứa tenant.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.release_id IS 'Phiên bản đích.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.status IS 'Trạng thái: `PENDING`, `IN_WINDOW`, `UPGRADING`, `VERIFYING`, `DONE`, `FAILED`, `ROLLED_BACK`, `SKIPPED`.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.maintenance_window_id IS 'Cửa sổ bảo trì được dùng.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.scheduled_for IS 'Thời điểm dự kiến trong cửa sổ.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.started_at IS 'Bắt đầu nâng cấp.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.verified_at IS 'Kiểm tra sau nâng cấp xong.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.finished_at IS 'Kết thúc.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.attempt IS 'Lần thử.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.rollback_release_id IS 'Phiên bản quay lui khi `ROLLED_BACK`.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.error_code IS 'Mã lỗi.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.error_message IS 'Thông điệp lỗi.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_upgrade.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.tenant_upgrade CASCADE;

--changeset ph20:ph20-0520-leak-test-run
CREATE TABLE ph20_tenant.leak_test_run (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  trigger_type           varchar(14)    NOT NULL DEFAULT 'SCHEDULE',
  status                 varchar(8)     NOT NULL DEFAULT 'RUNNING',
  tenant_codes           text[]         NOT NULL DEFAULT '{}',
  tenants_tested         integer        NOT NULL DEFAULT 0,
  cases_total            integer        NOT NULL DEFAULT 0,
  cases_failed           integer        NOT NULL DEFAULT 0,
  failures               jsonb          NOT NULL DEFAULT '[]',
  report_file_id         uuid,
  started_at             timestamptz    NOT NULL DEFAULT now(),
  finished_at            timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_leak_test_run PRIMARY KEY (id),
  CONSTRAINT uq_leak_test_run_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_leak_test_run_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_leak_test_run_trigger_type CHECK (trigger_type IN ('SCHEDULE', 'MANUAL', 'PRE_ACTIVATION')),
  CONSTRAINT ck_leak_test_run_status CHECK (status IN ('RUNNING', 'PASSED', 'FAILED', 'ERROR')),
  CONSTRAINT ck_leak_test_run_counts CHECK (tenants_tested >= 0 AND cases_total >= 0 AND cases_failed >= 0 AND cases_failed <= cases_total),
  CONSTRAINT ck_leak_test_run_failures CHECK (jsonb_typeof(failures) = 'array'),
  CONSTRAINT ck_leak_test_run_passed CHECK (status <> 'PASSED' OR cases_failed = 0),
  CONSTRAINT ck_leak_test_run_finished CHECK (status = 'RUNNING' OR finished_at IS NOT NULL),
  CONSTRAINT fk_leak_test_run_report_file FOREIGN KEY (report_file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id)
);
CREATE INDEX ix_leak_test_run_started ON ph20_tenant.leak_test_run (started_at DESC);
CREATE INDEX ix_leak_test_run_fk_report_file ON ph20_tenant.leak_test_run (tenant_id, report_file_id);
CREATE TRIGGER tg_leak_test_run_touch BEFORE UPDATE ON ph20_tenant.leak_test_run FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.leak_test_run', 'PLAT');
COMMENT ON TABLE ph20_tenant.leak_test_run IS 'EN-20-36 Lần kiểm thử rò rỉ chéo tenant (FR-20-070, SEC-87): chạy hằng đêm hoặc trước khi kích hoạt tenant mới; ghi số ca, số ca lỗi, danh sách lỗi. Ca lỗi là sự cố an ninh mức cao.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.leak_test_run.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.trigger_type IS 'Nguồn kích hoạt: `SCHEDULE`, `MANUAL`, `PRE_ACTIVATION`.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.status IS 'Trạng thái: `RUNNING`, `PASSED`, `FAILED`, `ERROR`.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.tenant_codes IS 'Các tenant được kiểm trong lần chạy.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.tenants_tested IS 'Số tenant đã kiểm.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.cases_total IS 'Tổng số ca.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.cases_failed IS 'Số ca phát hiện rò rỉ.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.failures IS 'Danh sách ca lỗi (tầng, bên đọc, bên bị đọc, mô tả), không chứa dữ liệu thật.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.report_file_id IS 'Tệp báo cáo chi tiết.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.started_at IS 'Bắt đầu.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.finished_at IS 'Kết thúc.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.leak_test_run.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.leak_test_run.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.leak_test_run.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.leak_test_run CASCADE;
