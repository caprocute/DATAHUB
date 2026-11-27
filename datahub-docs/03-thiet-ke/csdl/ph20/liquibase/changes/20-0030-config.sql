--liquibase formatted sql
-- Nguồn: ddl/ph20_tenant.sql · 20-0030-config.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph20:ph20-0210-tenant-platform-config
CREATE TABLE ph20_tenant.tenant_platform_config (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  realm_code             varchar(64)    NOT NULL,
  api_host               varchar(253),
  api_path_prefix        varchar(64),
  deployment_profile     varchar(4)     NOT NULL DEFAULT 'HT-A',
  dr_zone                varchar(32),
  kafka_prefix           varchar(16)    NOT NULL,
  bucket_prefix          varchar(32)    NOT NULL,
  db_route_ref           varchar(128),
  cluster_ref            varchar(64),
  config_version_no      integer        NOT NULL DEFAULT 0,
  last_commit_sha        char(40),
  drift_status           varchar(12)    NOT NULL DEFAULT 'UNKNOWN',
  last_applied_at        timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_platform_config PRIMARY KEY (id),
  CONSTRAINT uq_tenant_platform_config_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_platform_config_tenant UNIQUE (tenant_id),
  CONSTRAINT uq_tenant_platform_config_realm UNIQUE (realm_code),
  CONSTRAINT ck_tenant_platform_config_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_platform_config_drift_status CHECK (drift_status IN ('IN_SYNC', 'DRIFTED', 'RECONCILING', 'UNKNOWN')),
  CONSTRAINT ck_tenant_platform_config_profile CHECK (deployment_profile IN ('HT-A', 'HT-B')),
  CONSTRAINT ck_tenant_platform_config_sha CHECK (last_commit_sha IS NULL OR last_commit_sha ~ '^[0-9a-f]{40}$'),
  CONSTRAINT ck_tenant_platform_config_host CHECK (api_host IS NULL OR api_host ~ '^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$'),
  CONSTRAINT ck_tenant_platform_config_version CHECK (config_version_no >= 0),
  CONSTRAINT fk_tenant_platform_config_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE UNIQUE INDEX uq_tenant_platform_config_api_host ON ph20_tenant.tenant_platform_config (api_host) WHERE api_host IS NOT NULL;
CREATE TRIGGER tg_tenant_platform_config_touch BEFORE UPDATE ON ph20_tenant.tenant_platform_config FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_platform_config', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_platform_config IS 'EN-20-05 Cấu hình nền tảng của tenant (FR-20-019): realm, host và tiền tố API công bố, hồ sơ triển khai, vùng DR, tham chiếu cụm riêng. Một dòng mỗi tenant; cấu hình mong muốn nằm ở kho Git `dh-tenant-config`, bảng giữ bản chiếu và trạng thái áp.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.realm_code IS 'Realm Keycloak của tenant.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.api_host IS 'Host API công bố của tenant.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.api_path_prefix IS 'Tiền tố đường dẫn API công bố.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.deployment_profile IS 'Hồ sơ triển khai: `HT-A` hoặc `HT-B`.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.dr_zone IS 'Vùng khôi phục thảm họa.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.kafka_prefix IS 'Tiền tố topic Kafka (mã tenant viết thường, `t68.`).';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.bucket_prefix IS 'Tiền tố bucket kho đối tượng (`dh-t68-`).';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.db_route_ref IS 'Tham chiếu bảng định tuyến CSDL khi `DEDICATED_DB`; không chứa chuỗi kết nối.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.cluster_ref IS 'Tên cụm riêng khi `DEDICATED_CLUSTER`.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.config_version_no IS 'Phiên bản cấu hình hiện hành (khớp `tenant_config_version`).';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.last_commit_sha IS 'Mã commit Git đã áp gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.drift_status IS 'Trạng thái đồng bộ: `IN_SYNC`, `DRIFTED`, `RECONCILING`, `UNKNOWN`.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.last_applied_at IS 'Lần áp cấu hình xuống gần nhất.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_platform_config.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.tenant_platform_config CASCADE;

--changeset ph20:ph20-0220-tenant-settings
CREATE TABLE ph20_tenant.tenant_settings (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  display_name           varchar(255)   NOT NULL,
  logo_file_id           uuid,
  it_owner_org_id        uuid,
  hotline                varchar(20),
  support_email          varchar(254),
  idle_session_minutes   smallint       NOT NULL DEFAULT 30,
  mfa_required           boolean        NOT NULL DEFAULT true,
  password_min_length    smallint       NOT NULL DEFAULT 12,
  lockout_attempts       smallint       NOT NULL DEFAULT 5,
  ip_allowlist           text[]         NOT NULL DEFAULT '{}',
  notify_emails          text[]         NOT NULL DEFAULT '{}',
  locale                 varchar(10)    NOT NULL DEFAULT 'vi-VN',
  timezone               varchar(40)    NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  extra                  jsonb          NOT NULL DEFAULT '{}',
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_settings PRIMARY KEY (id),
  CONSTRAINT uq_tenant_settings_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_settings_tenant UNIQUE (tenant_id),
  CONSTRAINT ck_tenant_settings_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_settings_idle CHECK (idle_session_minutes BETWEEN 5 AND 480),
  CONSTRAINT ck_tenant_settings_password CHECK (password_min_length BETWEEN 8 AND 128),
  CONSTRAINT ck_tenant_settings_lockout CHECK (lockout_attempts BETWEEN 3 AND 20),
  CONSTRAINT ck_tenant_settings_extra CHECK (jsonb_typeof(extra) = 'object'),
  CONSTRAINT ck_tenant_settings_email CHECK (support_email IS NULL OR support_email ~ '^[^@[:space:]]+@[^@[:space:]]+$'),
  CONSTRAINT fk_tenant_settings_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code),
  CONSTRAINT fk_tenant_settings_logo FOREIGN KEY (logo_file_id, tenant_id) REFERENCES ph20_tenant.file_object (id, tenant_id),
  CONSTRAINT fk_tenant_settings_it_owner FOREIGN KEY (it_owner_org_id, tenant_id) REFERENCES ph20_tenant.organization (id, tenant_id)
);
CREATE INDEX ix_tenant_settings_fk_logo ON ph20_tenant.tenant_settings (tenant_id, logo_file_id);
CREATE INDEX ix_tenant_settings_fk_it_owner ON ph20_tenant.tenant_settings (tenant_id, it_owner_org_id);
CREATE TRIGGER tg_tenant_settings_touch BEFORE UPDATE ON ph20_tenant.tenant_settings FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_settings', 'OWN');
COMMENT ON TABLE ph20_tenant.tenant_settings IS 'EN-20-06 Cài đặt tỉnh do quản trị tỉnh tự quản (FR-20-018): thông tin hiển thị, chủ quản CNTT, an toàn đăng nhập trong giới hạn nền tảng, địa chỉ nhận thông báo. Một dòng mỗi tenant; giới hạn nền tảng kiểm ở dịch vụ.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_settings.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.display_name IS 'Tên hiển thị của tỉnh trên cổng, thư thông báo.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.logo_file_id IS 'Tệp logo.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.it_owner_org_id IS 'Tổ chức chủ quản CNTT của tỉnh.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.hotline IS 'Đường dây hỗ trợ.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.support_email IS 'Thư điện tử hỗ trợ.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.idle_session_minutes IS 'Thời gian rảnh tối đa của phiên, phút.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.mfa_required IS 'Bắt buộc xác thực nhiều lớp.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.password_min_length IS 'Độ dài tối thiểu của mật khẩu.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.lockout_attempts IS 'Số lần đăng nhập sai trước khi khóa.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.ip_allowlist IS 'Dải IP được phép đăng nhập quản trị (rỗng là không giới hạn).';
COMMENT ON COLUMN ph20_tenant.tenant_settings.notify_emails IS 'Địa chỉ nhận thông báo phát hành, bảo trì.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.locale IS 'Ngôn ngữ mặc định.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.timezone IS 'Múi giờ hiển thị.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.extra IS 'Cài đặt mở rộng theo hồ sơ triển khai.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_settings.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_settings.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_settings.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.tenant_settings CASCADE;

--changeset ph20:ph20-0230-tenant-config-version
CREATE TABLE ph20_tenant.tenant_config_version (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  version_no             integer        NOT NULL,
  config_scope           varchar(16)    NOT NULL DEFAULT 'ALL',
  git_commit_sha         char(40)       NOT NULL,
  commit_message         varchar(500),
  content_hash           char(64)       NOT NULL,
  snapshot               jsonb          NOT NULL,
  change_source          varchar(12)    NOT NULL DEFAULT 'API',
  reason                 varchar(500),
  apply_status           varchar(10)    NOT NULL DEFAULT 'PENDING',
  applied_at             timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_tenant_config_version PRIMARY KEY (id),
  CONSTRAINT uq_tenant_config_version_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_tenant_config_version_version UNIQUE (tenant_id, version_no),
  CONSTRAINT ck_tenant_config_version_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_tenant_config_version_version CHECK (version_no >= 1),
  CONSTRAINT ck_tenant_config_version_config_scope CHECK (config_scope IN ('PLATFORM_CONFIG', 'SETTINGS', 'QUOTA', 'MODULES', 'ALL')),
  CONSTRAINT ck_tenant_config_version_change_source CHECK (change_source IN ('API', 'SAGA', 'RESTORE', 'DRIFT_FIX')),
  CONSTRAINT ck_tenant_config_version_apply_status CHECK (apply_status IN ('PENDING', 'APPLIED', 'FAILED')),
  CONSTRAINT ck_tenant_config_version_sha CHECK (git_commit_sha ~ '^[0-9a-f]{40}$'),
  CONSTRAINT ck_tenant_config_version_hash CHECK (content_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_tenant_config_version_snapshot CHECK (jsonb_typeof(snapshot) = 'object'),
  CONSTRAINT fk_tenant_config_version_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE TRIGGER tg_tenant_config_version_touch BEFORE UPDATE ON ph20_tenant.tenant_config_version FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CREATE TRIGGER tg_tenant_config_version_immutable BEFORE UPDATE ON ph20_tenant.tenant_config_version FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_immutable('version_no', 'git_commit_sha', 'content_hash', 'snapshot', 'config_scope', 'change_source');
CALL ph20_tenant.p_enable_rls('ph20_tenant.tenant_config_version', 'CTL');
COMMENT ON TABLE ph20_tenant.tenant_config_version IS 'EN-20-07 Phiên bản cấu hình (FR-20-020, 021): bản chiếu mỗi commit cấu hình ở kho Git, giữ ảnh chụp để so sánh và khôi phục. Chỉ thêm; cột nội dung bất biến, chỉ trạng thái áp được cập nhật.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.version_no IS 'Số phiên bản tăng dần trong tenant.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.config_scope IS 'Phạm vi: `PLATFORM_CONFIG`, `SETTINGS`, `QUOTA`, `MODULES`, `ALL`.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.git_commit_sha IS 'Mã commit trong kho `dh-tenant-config`.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.commit_message IS 'Nội dung commit.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.content_hash IS 'Mã băm SHA-256 của nội dung cấu hình.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.snapshot IS 'Ảnh chụp cấu hình (không chứa bí mật), dùng so sánh và khôi phục.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.change_source IS 'Nguồn thay đổi: `API`, `SAGA`, `RESTORE`, `DRIFT_FIX`.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.reason IS 'Lý do, mã phiếu.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.apply_status IS 'Trạng thái áp xuống: `PENDING`, `APPLIED`, `FAILED`.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.applied_at IS 'Thời điểm áp xong.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.tenant_config_version.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.tenant_config_version CASCADE;

--changeset ph20:ph20-0240-config-drift
CREATE TABLE ph20_tenant.config_drift (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  status                 varchar(12)    NOT NULL DEFAULT 'DRIFTED',
  detected_at            timestamptz    NOT NULL DEFAULT now(),
  detected_by            varchar(12)    NOT NULL DEFAULT 'PERIODIC',
  desired_version_no     integer,
  desired_hash           char(64),
  actual_hash            char(64),
  differences            jsonb          NOT NULL DEFAULT '[]',
  resolution             varchar(10),
  resolved_by            varchar(64),
  resolved_at            timestamptz,
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_config_drift PRIMARY KEY (id),
  CONSTRAINT uq_config_drift_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT ck_config_drift_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_config_drift_status CHECK (status IN ('IN_SYNC', 'DRIFTED', 'RECONCILING', 'UNKNOWN')),
  CONSTRAINT ck_config_drift_resolution CHECK (resolution IN ('RECONCILED', 'ACCEPTED', 'IGNORED')),
  CONSTRAINT ck_config_drift_detected_by CHECK (detected_by IN ('PERIODIC', 'ARGOCD')),
  CONSTRAINT ck_config_drift_diff CHECK (jsonb_typeof(differences) = 'array'),
  CONSTRAINT ck_config_drift_resolved CHECK (resolution IS NULL OR (resolved_at IS NOT NULL AND resolved_by IS NOT NULL)),
  CONSTRAINT fk_config_drift_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE UNIQUE INDEX uq_config_drift_open ON ph20_tenant.config_drift (tenant_id) WHERE status IN ('DRIFTED', 'RECONCILING');
CREATE INDEX ix_config_drift_detected ON ph20_tenant.config_drift (tenant_id, detected_at DESC);
CREATE TRIGGER tg_config_drift_touch BEFORE UPDATE ON ph20_tenant.config_drift FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.config_drift', 'CTL');
COMMENT ON TABLE ph20_tenant.config_drift IS 'EN-20-08 Lệch cấu hình (FR-20-022): kết quả đối chiếu định kỳ giữa kho Git và thực tế; mỗi tenant tối đa một lệch đang mở. Số liệu so sánh chỉ là băm và danh sách khác biệt, không chứa giá trị bí mật.';
COMMENT ON COLUMN ph20_tenant.config_drift.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.config_drift.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.config_drift.status IS 'Trạng thái: `IN_SYNC`, `DRIFTED`, `RECONCILING`, `UNKNOWN`.';
COMMENT ON COLUMN ph20_tenant.config_drift.detected_at IS 'Thời điểm phát hiện.';
COMMENT ON COLUMN ph20_tenant.config_drift.detected_by IS 'Nguồn phát hiện: `PERIODIC` hoặc `ARGOCD`.';
COMMENT ON COLUMN ph20_tenant.config_drift.desired_version_no IS 'Phiên bản cấu hình mong muốn.';
COMMENT ON COLUMN ph20_tenant.config_drift.desired_hash IS 'Băm cấu hình mong muốn.';
COMMENT ON COLUMN ph20_tenant.config_drift.actual_hash IS 'Băm cấu hình thực tế.';
COMMENT ON COLUMN ph20_tenant.config_drift.differences IS 'Danh sách khác biệt (đường dẫn, loại), không chứa giá trị bí mật.';
COMMENT ON COLUMN ph20_tenant.config_drift.resolution IS 'Cách xử lý: `RECONCILED`, `ACCEPTED`, `IGNORED`.';
COMMENT ON COLUMN ph20_tenant.config_drift.resolved_by IS 'Người xử lý.';
COMMENT ON COLUMN ph20_tenant.config_drift.resolved_at IS 'Thời điểm xử lý xong.';
COMMENT ON COLUMN ph20_tenant.config_drift.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.config_drift.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.config_drift.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.config_drift.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.config_drift.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.config_drift CASCADE;

--changeset ph20:ph20-0250-cross-tenant-policy
CREATE TABLE ph20_tenant.cross_tenant_policy (
  id                     uuid           NOT NULL,
  tenant_id              varchar(16)    NOT NULL,
  allow_write            boolean        NOT NULL DEFAULT false,
  preapproved_roles      text[]         NOT NULL DEFAULT '{}',
  max_hours              smallint       NOT NULL DEFAULT 4,
  require_reason         boolean        NOT NULL DEFAULT true,
  notify_emails          text[]         NOT NULL DEFAULT '{}',
  notify_contact_types   text[]         NOT NULL DEFAULT '{SECURITY}',
  effective_from         timestamptz    NOT NULL DEFAULT now(),
  created_at             timestamptz    NOT NULL DEFAULT now(),
  created_by             varchar(64)    NOT NULL,
  updated_at             timestamptz    NOT NULL DEFAULT now(),
  updated_by             varchar(64)    NOT NULL,
  version                integer        NOT NULL DEFAULT 0,
  CONSTRAINT pk_cross_tenant_policy PRIMARY KEY (id),
  CONSTRAINT uq_cross_tenant_policy_id_tenant UNIQUE (id, tenant_id),
  CONSTRAINT uq_cross_tenant_policy_tenant UNIQUE (tenant_id),
  CONSTRAINT ck_cross_tenant_policy_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_cross_tenant_policy_hours CHECK (max_hours BETWEEN 1 AND 24),
  CONSTRAINT fk_cross_tenant_policy_tenant FOREIGN KEY (tenant_id) REFERENCES ph20_tenant.tenant (code)
);
CREATE TRIGGER tg_cross_tenant_policy_touch BEFORE UPDATE ON ph20_tenant.cross_tenant_policy FOR EACH ROW EXECUTE FUNCTION ph20_tenant.tg_touch();
CALL ph20_tenant.p_enable_rls('ph20_tenant.cross_tenant_policy', 'OWN');
COMMENT ON TABLE ph20_tenant.cross_tenant_policy IS 'EN-20-29 Chính sách tiếp nhận truy cập liên tenant của tỉnh (FR-20-023): có cho phép ghi hay không, chấp thuận trước, thời hạn tối đa, người nhận thông báo. PH-12 đọc khi cấp quyền liên tenant (FR-00-012); thời hạn không vượt trần nền tảng `20.cross-tenant.max-hours` (kiểm ở dịch vụ).';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.id IS 'Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5.1).';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.tenant_id IS 'Mã tenant (`Tnn`, `PLATFORM`), khóa RLS và khóa ngoại kép.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.allow_write IS 'Cho phép phiên liên tenant ghi (mặc định chỉ đọc).';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.preapproved_roles IS 'Vai trò nền tảng được chấp thuận trước, không cần phê duyệt từng lần.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.max_hours IS 'Thời hạn tối đa một phiên liên tenant, giờ.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.require_reason IS 'Bắt buộc nêu lý do và mã phiếu.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.notify_emails IS 'Địa chỉ nhận thông báo mỗi lần có truy cập liên tenant.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.notify_contact_types IS 'Loại đầu mối nhận thông báo.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.effective_from IS 'Hiệu lực từ.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.created_at IS 'Thời điểm tạo.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.created_by IS 'Người tạo (mã người dùng hoặc `system:*`).';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.updated_at IS 'Thời điểm sửa cuối (trigger `tg_touch`).';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.updated_by IS 'Người sửa cuối.';
COMMENT ON COLUMN ph20_tenant.cross_tenant_policy.version IS 'Khóa lạc quan, thành phần của ETag (`If-Match`).';
--rollback DROP TABLE IF EXISTS ph20_tenant.cross_tenant_policy CASCADE;
