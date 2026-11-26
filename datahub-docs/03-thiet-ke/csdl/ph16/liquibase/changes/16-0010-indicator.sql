--liquibase formatted sql
-- Nguồn: ddl/ph16_kpi.sql · 16-0010-indicator.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph16:ph16-0100-kpi-indicator-group
CREATE TABLE ph16_kpi.kpi_indicator_group (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  group_code    varchar(16) NOT NULL,
  name          varchar(255) NOT NULL,
  description   varchar(2000),
  weight        numeric(5,2) NOT NULL DEFAULT 20.00,
  display_order smallint NOT NULL DEFAULT 0,
  enabled       boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_indicator_group PRIMARY KEY (id),
  CONSTRAINT ck_kpi_indicator_group_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_kpi_indicator_group_code UNIQUE (tenant_id, group_code),
  CONSTRAINT ck_kpi_indicator_group_code CHECK (group_code IN ('KET_NOI', 'CHIA_SE', 'DU_LIEU', 'VAN_HANH', 'KIEN_TRUC')),
  CONSTRAINT ck_kpi_indicator_group_weight CHECK (weight >= 0 AND weight <= 100)
);
CREATE TRIGGER tg_kpi_indicator_group_touch BEFORE UPDATE ON ph16_kpi.kpi_indicator_group FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_indicator_group_immutable BEFORE UPDATE ON ph16_kpi.kpi_indicator_group FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'group_code');
CALL ph16_kpi.p_enable_rls_shared('ph16_kpi.kpi_indicator_group');
COMMENT ON TABLE ph16_kpi.kpi_indicator_group IS 'EN-16-01 Nhóm chỉ tiêu: năm nhóm KET_NOI, CHIA_SE, DU_LIEU, VAN_HANH, KIEN_TRUC kế thừa năm nhóm KPI của SRS cũ, có trọng số tính điểm nhóm (FR-16-007). Dòng tenant COMMON do PLATFORM quản, mọi tenant đọc được (mẫu RLS S); tenant nhận bản sao khi khởi tạo.';
COMMENT ON COLUMN ph16_kpi.kpi_indicator_group.tenant_id IS 'Dạng Tnn hoặc COMMON (bộ mẫu dùng chung).';
COMMENT ON COLUMN ph16_kpi.kpi_indicator_group.weight IS 'Trọng số điểm nhóm thang 0…100; tổng trọng số các nhóm đang bật bằng 100 do dịch vụ kiểm (BR-16-016, ERR-16-012, FR-16-007).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_indicator_group CASCADE;

--changeset ph16:ph16-0110-kpi-indicator
CREATE TABLE ph16_kpi.kpi_indicator (
  id                            uuid NOT NULL,
  tenant_id                     varchar(16) NOT NULL,
  indicator_code                varchar(63) NOT NULL,
  group_code                    varchar(16) NOT NULL,
  name                          varchar(255) NOT NULL,
  description                   varchar(2000),
  kind                          varchar(10) NOT NULL,
  direction                     varchar(14) NOT NULL,
  measurement                   varchar(8) NOT NULL,
  unit                          varchar(32) NOT NULL,
  aggregation                   varchar(8) NOT NULL DEFAULT 'LAST',
  scope                         varchar(8) NOT NULL DEFAULT 'TENANT',
  mandatory                     boolean NOT NULL DEFAULT false,
  brd_ref                       varchar(8),
  template_code                 varchar(63),
  state                         varchar(8) NOT NULL DEFAULT 'DRAFT',
  state_reason                  varchar(2000),
  replaced_by_code              varchar(63),
  template_version_no           integer,
  template_dismissed_version_no integer,
  display_order                 smallint NOT NULL DEFAULT 0,
  created_at                    timestamptz NOT NULL DEFAULT now(),
  created_by                    varchar(64) NOT NULL,
  updated_at                    timestamptz NOT NULL DEFAULT now(),
  updated_by                    varchar(64) NOT NULL,
  version                       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_indicator PRIMARY KEY (id),
  CONSTRAINT uq_kpi_indicator_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_indicator_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_kpi_indicator_code UNIQUE (tenant_id, indicator_code),
  CONSTRAINT fk_kpi_indicator_group FOREIGN KEY (tenant_id, group_code) REFERENCES ph16_kpi.kpi_indicator_group (tenant_id, group_code),
  CONSTRAINT ck_kpi_indicator_code CHECK (indicator_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_kpi_indicator_kind CHECK (kind IN ('RATIO', 'COUNT', 'DURATION', 'SCORE', 'BOOLEAN')),
  CONSTRAINT ck_kpi_indicator_direction CHECK (direction IN ('HIGHER_BETTER', 'LOWER_BETTER', 'TARGET_RANGE')),
  CONSTRAINT ck_kpi_indicator_measurement CHECK (measurement IN ('AUTO', 'MANUAL', 'MIXED')),
  CONSTRAINT ck_kpi_indicator_aggregation CHECK (aggregation IN ('LAST', 'SUM', 'AVG', 'P95', 'MAX', 'MIN')),
  CONSTRAINT ck_kpi_indicator_scope CHECK (scope IN ('TENANT', 'COMMON') AND (scope = 'COMMON') = (tenant_id = 'COMMON')),
  CONSTRAINT ck_kpi_indicator_state CHECK (state IN ('DRAFT', 'ACTIVE', 'RETIRED')),
  CONSTRAINT ck_kpi_indicator_brd_ref CHECK (brd_ref IS NULL OR brd_ref ~ '^KPI-[0-9]{2}$'),
  CONSTRAINT ck_kpi_indicator_template CHECK (template_code IS NULL OR (scope = 'TENANT' AND template_code ~ '^[a-z][a-z0-9-]{2,62}$')),
  CONSTRAINT ck_kpi_indicator_replaced CHECK (replaced_by_code IS NULL OR (replaced_by_code <> indicator_code AND state = 'RETIRED')),
  CONSTRAINT ck_kpi_indicator_reason CHECK (state <> 'RETIRED' OR COALESCE(char_length(state_reason) >= 20, false))
);
CREATE INDEX ix_kpi_indicator_group ON ph16_kpi.kpi_indicator (tenant_id, group_code, state, display_order);
CREATE INDEX ix_kpi_indicator_measure ON ph16_kpi.kpi_indicator (tenant_id, measurement, state);
CREATE TRIGGER tg_kpi_indicator_touch BEFORE UPDATE ON ph16_kpi.kpi_indicator FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_indicator_immutable BEFORE UPDATE ON ph16_kpi.kpi_indicator FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'indicator_code', 'scope');
CALL ph16_kpi.p_enable_rls_shared('ph16_kpi.kpi_indicator');
COMMENT ON TABLE ph16_kpi.kpi_indicator IS 'EN-16-02, EN-16-38 Chỉ tiêu: mã T-CODE, nhóm, loại giá trị, chiều tốt, cách đo, đơn vị, cách gộp qua kỳ, cờ bắt buộc cho báo cáo chính thức (FR-16-001, 002, 006, 008). Phạm vi COMMON là chỉ tiêu mẫu toàn quốc do PLATFORM quản, tenant kế thừa bằng bản sao ghi `template_code` (không khóa ngoại). Không xóa, chỉ ngừng hoặc thay thế.';
COMMENT ON COLUMN ph16_kpi.kpi_indicator.brd_ref IS 'Mã KPI-01…18 của BRD (D02-01 §3) nếu chỉ tiêu là KPI đo của BO; NULL với chỉ tiêu bổ sung.';
COMMENT ON COLUMN ph16_kpi.kpi_indicator.template_code IS 'Mã chỉ tiêu mẫu COMMON đã kế thừa (FR-16-008); phục vụ nhận cập nhật mẫu.';
COMMENT ON COLUMN ph16_kpi.kpi_indicator.template_version_no IS 'Số phiên bản mẫu COMMON đã nhận; mẫu có phiên bản ACTIVE mới hơn và chưa bị bỏ qua là cập nhật chờ quyết định (FRS EN-16-38).';
COMMENT ON COLUMN ph16_kpi.kpi_indicator.template_dismissed_version_no IS 'Số phiên bản mẫu COMMON tenant đã quyết định không nhận (DISMISSED).';
COMMENT ON COLUMN ph16_kpi.kpi_indicator.mandatory IS 'Bắt buộc có số để công bố báo cáo chính thức; thiếu nguồn bắt buộc thì chặn công bố (ERR-16-0xx).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_indicator CASCADE;

--changeset ph16:ph16-0120-kpi-indicator-version
CREATE TABLE ph16_kpi.kpi_indicator_version (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  indicator_id     uuid NOT NULL,
  version_no       integer NOT NULL,
  state            varchar(18) NOT NULL DEFAULT 'DRAFT',
  formula_cel      text,
  variables        jsonb NOT NULL DEFAULT '[]',
  rounding_digits  smallint NOT NULL DEFAULT 2,
  baseline_value   numeric(24,6),
  target_value     numeric(24,6),
  target_min       numeric(24,6),
  target_max       numeric(24,6),
  target_due       date,
  effective_from   date,
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  change_note      varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_indicator_version PRIMARY KEY (id),
  CONSTRAINT uq_kpi_indicator_version_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_indicator_version_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_kpi_indicator_version_no UNIQUE (tenant_id, indicator_id, version_no),
  CONSTRAINT fk_kpi_indicator_version_indicator FOREIGN KEY (tenant_id, indicator_id) REFERENCES ph16_kpi.kpi_indicator (tenant_id, id),
  CONSTRAINT ck_kpi_indicator_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_kpi_indicator_version_state CHECK (state IN ('DRAFT', 'PENDING_APPROVAL', 'CHANGES_REQUESTED', 'ACTIVE', 'SUPERSEDED', 'RETIRED')),
  CONSTRAINT ck_kpi_indicator_version_variables CHECK (jsonb_typeof(variables) = 'array' AND jsonb_array_length(variables) <= 50),
  CONSTRAINT ck_kpi_indicator_version_formula CHECK (formula_cel IS NULL OR char_length(formula_cel) BETWEEN 1 AND 4000),
  CONSTRAINT ck_kpi_indicator_version_formula_required CHECK (state IN ('DRAFT', 'CHANGES_REQUESTED') OR formula_cel IS NOT NULL),
  CONSTRAINT ck_kpi_indicator_version_rounding CHECK (rounding_digits BETWEEN 0 AND 6),
  CONSTRAINT ck_kpi_indicator_version_target_range CHECK (target_min IS NULL OR target_max IS NULL OR target_min <= target_max),
  CONSTRAINT ck_kpi_indicator_version_four_eyes CHECK (decided_by IS NULL OR submitted_by IS NULL OR decided_by <> submitted_by),
  CONSTRAINT ck_kpi_indicator_version_submitted CHECK (state = 'DRAFT' OR (submitted_by IS NOT NULL AND submitted_at IS NOT NULL)),
  CONSTRAINT ck_kpi_indicator_version_active CHECK (state NOT IN ('ACTIVE', 'SUPERSEDED') OR (decided_by IS NOT NULL AND decided_at IS NOT NULL AND activated_at IS NOT NULL)),
  CONSTRAINT ck_kpi_indicator_version_changes CHECK (state <> 'CHANGES_REQUESTED' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_kpi_indicator_version_active ON ph16_kpi.kpi_indicator_version (tenant_id, indicator_id) WHERE state = 'ACTIVE';
CREATE UNIQUE INDEX uq_kpi_indicator_version_open ON ph16_kpi.kpi_indicator_version (tenant_id, indicator_id) WHERE state IN ('DRAFT', 'PENDING_APPROVAL', 'CHANGES_REQUESTED');
CREATE INDEX ix_kpi_indicator_version_state ON ph16_kpi.kpi_indicator_version (tenant_id, state, submitted_at);
CREATE TRIGGER tg_kpi_indicator_version_touch BEFORE UPDATE ON ph16_kpi.kpi_indicator_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_indicator_version_immutable BEFORE UPDATE ON ph16_kpi.kpi_indicator_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'indicator_id', 'version_no');
CREATE TRIGGER tg_kpi_indicator_version_frozen BEFORE UPDATE ON ph16_kpi.kpi_indicator_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_frozen('state', 'PENDING_APPROVAL,ACTIVE,SUPERSEDED,RETIRED', 'formula_cel', 'variables', 'rounding_digits', 'target_value', 'target_min', 'target_max', 'target_due', 'baseline_value', 'effective_from', 'submitted_by', 'submitted_at');
CREATE TRIGGER tg_kpi_indicator_version_transition BEFORE UPDATE ON ph16_kpi.kpi_indicator_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('state', '{"DRAFT":["PENDING_APPROVAL"],"PENDING_APPROVAL":["ACTIVE","CHANGES_REQUESTED","DRAFT"],"CHANGES_REQUESTED":["DRAFT"],"ACTIVE":["SUPERSEDED","RETIRED"]}');
CALL ph16_kpi.p_enable_rls_shared('ph16_kpi.kpi_indicator_version');
COMMENT ON TABLE ph16_kpi.kpi_indicator_version IS 'EN-16-03, EN-16-04 Phiên bản định nghĩa chỉ tiêu: công thức CEL trên biến quan sát (ví dụ `obs("ph01.httt.connected") / obs("ph01.httt.total") * 100`), danh sách biến, mục tiêu có hạn, làm tròn; vòng đời DRAFT, PENDING_APPROVAL, ACTIVE, SUPERSEDED, RETIRED, CHANGES_REQUESTED; duyệt bốn mắt (FR-16-002, 003, 004, 005, 006). ACTIVE và SUPERSEDED bất biến; mỗi chỉ tiêu một phiên bản ACTIVE và một phiên bản đang soạn hoặc chờ duyệt.';
COMMENT ON COLUMN ph16_kpi.kpi_indicator_version.variables IS 'Mảng {name, metricCode, aggregation, required, default}: biến CEL ánh xạ tới `metric_code` của quan sát hoặc tới số liệu nhập tay.';
COMMENT ON COLUMN ph16_kpi.kpi_indicator_version.formula_cel IS 'Biểu thức CEL (ADR đề xuất dải 160…164), chỉ đọc quan sát đã chuẩn hóa; đã thử tính trên dữ liệu kỳ trước trước khi gửi duyệt (FR-16-003).';
COMMENT ON COLUMN ph16_kpi.kpi_indicator_version.target_due IS 'Hạn đạt mục tiêu (FR-16-004).';
COMMENT ON COLUMN ph16_kpi.kpi_indicator_version.baseline_value IS 'Giá trị nền để so mục tiêu giảm theo tỷ lệ (ví dụ KPI-02, nền 150).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_indicator_version CASCADE;

--changeset ph16:ph16-0130-kpi-indicator-threshold
CREATE TABLE ph16_kpi.kpi_indicator_threshold (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  version_id      uuid NOT NULL,
  level           varchar(5) NOT NULL,
  lower_bound     numeric(24,6),
  upper_bound     numeric(24,6),
  lower_inclusive boolean NOT NULL DEFAULT true,
  upper_inclusive boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_indicator_threshold PRIMARY KEY (id),
  CONSTRAINT ck_kpi_indicator_threshold_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_kpi_indicator_threshold_level UNIQUE (tenant_id, version_id, level),
  CONSTRAINT fk_kpi_indicator_threshold_version FOREIGN KEY (tenant_id, version_id) REFERENCES ph16_kpi.kpi_indicator_version (tenant_id, id),
  CONSTRAINT ck_kpi_indicator_threshold_level CHECK (level IN ('GREEN', 'AMBER', 'RED')),
  CONSTRAINT ck_kpi_indicator_threshold_bounds CHECK ((lower_bound IS NOT NULL OR upper_bound IS NOT NULL) AND (lower_bound IS NULL OR upper_bound IS NULL OR lower_bound <= upper_bound))
);
CREATE TRIGGER tg_kpi_indicator_threshold_touch BEFORE UPDATE ON ph16_kpi.kpi_indicator_threshold FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_indicator_threshold_immutable BEFORE UPDATE ON ph16_kpi.kpi_indicator_threshold FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'version_id', 'level');
CREATE TRIGGER tg_kpi_indicator_threshold_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph16_kpi.kpi_indicator_threshold FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_child_frozen('kpi_indicator_version', 'version_id', 'DRAFT,CHANGES_REQUESTED');
CALL ph16_kpi.p_enable_rls_shared('ph16_kpi.kpi_indicator_threshold');
COMMENT ON TABLE ph16_kpi.kpi_indicator_threshold IS 'EN-16-04 Ngưỡng ba mức GREEN, AMBER, RED của một phiên bản định nghĩa: khoảng giá trị ứng với mỗi mức, dùng đánh giá trạng thái ON_TRACK, AT_RISK, OFF_TRACK (FR-16-004, 021). Chỉ sửa khi phiên bản cha là DRAFT hoặc CHANGES_REQUESTED.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_indicator_threshold CASCADE;
