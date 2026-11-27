--liquibase formatted sql
-- Nguồn: ddl/ph20_tenant.sql · 20-0020-module.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph20:ph20-0170-platform-module
CREATE TABLE ph20_tenant.platform_module (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  module_code            varchar(8)     NOT NULL,
  name                   varchar(255)   NOT NULL,
  wave                   smallint       NOT NULL,
  du_code                varchar(32)    NOT NULL,
  is_core                boolean        NOT NULL DEFAULT false,
  default_enabled        boolean        NOT NULL DEFAULT false,
  status                 varchar(12)    NOT NULL DEFAULT 'AVAILABLE',
  display_order          smallint       NOT NULL DEFAULT 0,
  description            varchar(500),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_platform_module PRIMARY KEY (id),
  CONSTRAINT uq_platform_module_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_platform_module_code UNIQUE (module_code),
  CONSTRAINT ck_platform_module_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_platform_module_code CHECK (module_code ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_platform_module_wave CHECK (wave BETWEEN 1 AND 3),
  CONSTRAINT ck_platform_module_status CHECK (status IN ('AVAILABLE', 'PLANNED', 'DEPRECATED'))
);
CREATE TRIGGER tg_platform_module_touch BEFORE UPDATE ON ph20_tenant.platform_module FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_platform_module_immutable BEFORE UPDATE ON ph20_tenant.platform_module FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('module_code');
CALL ph20_tenant.p_enable_rls('ph20_tenant.platform_module', 'PLATR');
COMMENT ON TABLE ph20_tenant.platform_module IS 'EN-20-18 Phân hệ của nền tảng (FR-20-033): danh mục 20 phân hệ PH-01…20 với đợt, đơn vị triển khai, cờ lõi. Dữ liệu nền tảng, mọi tenant đọc được để dựng menu (FR-20-037), chỉ PLATFORM ghi.';
COMMENT ON COLUMN ph20_tenant.platform_module.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.platform_module.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.platform_module.module_code IS 'Mã phân hệ `PH-nn`, bất biến.';
COMMENT ON COLUMN ph20_tenant.platform_module.name IS 'Tên phân hệ.';
COMMENT ON COLUMN ph20_tenant.platform_module.wave IS 'Đợt phát triển: 1 (MVP), 2 hoặc 3 (D02-01 §8.3).';
COMMENT ON COLUMN ph20_tenant.platform_module.du_code IS 'Đơn vị triển khai (DU), ví dụ `dh-platform`.';
COMMENT ON COLUMN ph20_tenant.platform_module.is_core IS 'Phân hệ lõi, luôn bật, không tắt được cho tenant.';
COMMENT ON COLUMN ph20_tenant.platform_module.default_enabled IS 'Bật mặc định khi khởi tạo tenant theo mẫu.';
COMMENT ON COLUMN ph20_tenant.platform_module.status IS 'Trạng thái trong danh mục: `AVAILABLE`, `PLANNED`, `DEPRECATED`.';
COMMENT ON COLUMN ph20_tenant.platform_module.display_order IS 'Thứ tự hiển thị.';
COMMENT ON COLUMN ph20_tenant.platform_module.description IS 'Mô tả ngắn.';
COMMENT ON COLUMN ph20_tenant.platform_module.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.platform_module.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.platform_module.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.platform_module.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.platform_module.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.platform_module CASCADE;

--changeset ph20:ph20-0180-module-dependency
CREATE TABLE ph20_tenant.module_dependency (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  module_code            varchar(8)     NOT NULL,
  depends_on_code        varchar(8)     NOT NULL,
  dependency_type        varchar(10)    NOT NULL DEFAULT 'REQUIRED',
  reason                 varchar(500),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_module_dependency PRIMARY KEY (id),
  CONSTRAINT uq_module_dependency_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_module_dependency_pair UNIQUE (module_code, depends_on_code),
  CONSTRAINT ck_module_dependency_tenant CHECK (tenant_id = 'PLATFORM'),
  CONSTRAINT ck_module_dependency_dependency_type CHECK (dependency_type IN ('REQUIRED', 'OPTIONAL')),
  CONSTRAINT ck_module_dependency_not_self CHECK (module_code <> depends_on_code),
  CONSTRAINT fk_module_dependency_module FOREIGN KEY (module_code) REFERENCES ph20_tenant.platform_module (module_code),
  CONSTRAINT fk_module_dependency_depends_on FOREIGN KEY (depends_on_code) REFERENCES ph20_tenant.platform_module (module_code)
);
CREATE INDEX ix_module_dependency_depends_on ON ph20_tenant.module_dependency (depends_on_code);
CREATE TRIGGER tg_module_dependency_touch BEFORE UPDATE ON ph20_tenant.module_dependency FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.module_dependency', 'PLATR');
COMMENT ON TABLE ph20_tenant.module_dependency IS 'EN-20-19 Phụ thuộc phân hệ (FR-20-033): ma trận phân hệ cần phân hệ nào, bắt buộc hay tùy chọn; chặn bật phân hệ khi thiếu phân hệ bắt buộc. Chu trình do dịch vụ kiểm khi lưu.';
COMMENT ON COLUMN ph20_tenant.module_dependency.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.module_dependency.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.module_dependency.module_code IS 'Phân hệ phụ thuộc.';
COMMENT ON COLUMN ph20_tenant.module_dependency.depends_on_code IS 'Phân hệ được cần.';
COMMENT ON COLUMN ph20_tenant.module_dependency.dependency_type IS 'Loại: `REQUIRED` hoặc `OPTIONAL`.';
COMMENT ON COLUMN ph20_tenant.module_dependency.reason IS 'Lý do phụ thuộc.';
COMMENT ON COLUMN ph20_tenant.module_dependency.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.module_dependency.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.module_dependency.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.module_dependency.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.module_dependency.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.module_dependency CASCADE;

--changeset ph20:ph20-0190-tenant-module
CREATE TABLE ph20_tenant.tenant_module (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  module_code            varchar(8)     NOT NULL,
  state                  varchar(10)    NOT NULL DEFAULT 'DISABLED',
  enabled_at             timestamptz,
  disabled_at            timestamptz,
  state_reason           varchar(500),
  config                 jsonb          NOT NULL DEFAULT '{}',
  last_report_at         timestamptz,
  last_event_id          uuid,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_module PRIMARY KEY (id),
  CONSTRAINT uq_tenant_module_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_module_module UNIQUE (tenant_id, module_code),
  CONSTRAINT ck_tenant_module_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_module_state CHECK (state IN ('DISABLED', 'ENABLING', 'ENABLED', 'DISABLING', 'SUSPENDED', 'FAILED')),
  CONSTRAINT ck_tenant_module_config CHECK (jsonb_typeof(config) = 'object'),
  CONSTRAINT ck_tenant_module_enabled CHECK (state NOT IN ('ENABLED') OR enabled_at IS NOT NULL),
  CONSTRAINT fk_tenant_module_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_tenant_module_module FOREIGN KEY (module_code) REFERENCES ph20_tenant.platform_module (module_code)
);
CREATE INDEX ix_tenant_module_state ON ph20_tenant.tenant_module (tenant_id, state);
CREATE TRIGGER tg_tenant_module_touch BEFORE UPDATE ON ph20_tenant.tenant_module FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_module', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_module IS 'EN-20-20 Phân hệ theo tenant (FR-20-034, 035, 037): trạng thái bật, tắt, tạm ngừng của từng phân hệ đối với tenant; phân hệ báo kết quả bất đồng bộ qua EVT-20-07, 08. Nguồn cho menu và ERR-20-103.';
COMMENT ON COLUMN ph20_tenant.tenant_module.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_module.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_module.module_code IS 'Phân hệ.';
COMMENT ON COLUMN ph20_tenant.tenant_module.state IS 'Trạng thái: `DISABLED`, `ENABLING`, `ENABLED`, `DISABLING`, `SUSPENDED`, `FAILED`.';
COMMENT ON COLUMN ph20_tenant.tenant_module.enabled_at IS 'Lần bật gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant_module.disabled_at IS 'Lần tắt gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant_module.state_reason IS 'Lý do đổi trạng thái (bắt buộc khi tắt, tạm ngừng).';
COMMENT ON COLUMN ph20_tenant.tenant_module.config IS 'Cấu hình riêng của phân hệ cho tenant (ví dụ PH-17 `enabled`).';
COMMENT ON COLUMN ph20_tenant.tenant_module.last_report_at IS 'Lần phân hệ báo tiến độ gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant_module.last_event_id IS 'Sự kiện outbox gần nhất đã phát.';
COMMENT ON COLUMN ph20_tenant.tenant_module.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_module.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_module.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_module.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_module.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.tenant_module CASCADE;

--changeset ph20:ph20-0200-tenant-feature-flag
CREATE TABLE ph20_tenant.tenant_feature_flag (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  module_code            varchar(8),
  flag_code              varchar(64)    NOT NULL,
  enabled                boolean        NOT NULL DEFAULT false,
  rollout_percent        numeric(5,2)   NOT NULL DEFAULT 100,
  valid_from             timestamptz,
  valid_to               timestamptz,
  description            varchar(500),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_feature_flag PRIMARY KEY (id),
  CONSTRAINT uq_tenant_feature_flag_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_feature_flag_flag UNIQUE (tenant_id, flag_code),
  CONSTRAINT ck_tenant_feature_flag_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_feature_flag_code CHECK (flag_code ~ '^[a-z0-9][a-z0-9._-]{2,63}$'),
  CONSTRAINT ck_tenant_feature_flag_rollout CHECK (rollout_percent BETWEEN 0 AND 100),
  CONSTRAINT ck_tenant_feature_flag_valid CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to > valid_from),
  CONSTRAINT fk_tenant_feature_flag_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_tenant_feature_flag_module FOREIGN KEY (module_code) REFERENCES ph20_tenant.platform_module (module_code)
);
CREATE TRIGGER tg_tenant_feature_flag_touch BEFORE UPDATE ON ph20_tenant.tenant_feature_flag FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_feature_flag', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_feature_flag IS 'EN-20-21 Cờ tính năng theo tenant (FR-20-036): bật, tắt tính năng cụ thể, có tỷ lệ phát hành và thời hạn. Mã cờ dùng cột `flag_code`.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.module_code IS 'Phân hệ chứa tính năng (nếu có).';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.flag_code IS 'Mã cờ tính năng, dạng `{phân-hệ}.{tính-năng}`.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.enabled IS 'Cờ đang bật.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.rollout_percent IS 'Tỷ lệ phát hành dần, 0 đến 100.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.valid_from IS 'Cờ có hiệu lực từ.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.valid_to IS 'Cờ hết hiệu lực.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.description IS 'Mô tả.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_feature_flag.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.tenant_feature_flag CASCADE;
