--liquibase formatted sql
-- Nguồn: ddl/ph08_dq.sql · 08-0020-rule.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph08:ph08-0150-dq-rule-template
CREATE TABLE ph08_dq.dq_rule_template (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  template_code       varchar(64) NOT NULL,
  name                varchar(255) NOT NULL,
  dimension           varchar(16) NOT NULL,
  operator            varchar(24) NOT NULL,
  default_severity    varchar(8) NOT NULL DEFAULT 'MAJOR',
  params              jsonb NOT NULL DEFAULT '{}',
  expression_template text,
  description         varchar(2000),
  status              varchar(16) NOT NULL DEFAULT 'ACTIVE',
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_rule_template PRIMARY KEY (id),
  CONSTRAINT ck_dq_rule_template_tenant CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$'),
  CONSTRAINT uq_dq_rule_template_code UNIQUE (tenant_id, template_code),
  CONSTRAINT ck_dq_rule_template_code CHECK (template_code ~ '^[A-Z][A-Z0-9_-]{2,63}$'),
  CONSTRAINT ck_dq_rule_template_dimension CHECK (dimension IN ('COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'TIMELINESS', 'UNIQUENESS', 'VALIDITY')),
  CONSTRAINT ck_dq_rule_template_operator CHECK (operator IN ('NOT_NULL', 'NOT_EMPTY', 'REQUIRED_IF', 'REGEX', 'LENGTH', 'RANGE', 'CHECKSUM', 'TYPE', 'EQ_SOURCE', 'EQ_FIELDS', 'CROSS_ENTITY', 'MAX_AGE_DAYS', 'UPDATED_AFTER', 'UNIQUE_IN_ASSET', 'UNIQUE_COMPOSITE', 'IN_RDM', 'IN_RDM_VERSION', 'CEL_EXPRESSION', 'SQL_PREDICATE')),
  CONSTRAINT ck_dq_rule_template_severity CHECK (default_severity IN ('CRITICAL', 'MAJOR', 'MINOR')),
  CONSTRAINT ck_dq_rule_template_status CHECK (status IN ('ACTIVE', 'RETIRED')),
  CONSTRAINT ck_dq_rule_template_expr CHECK ((operator IN ('CEL_EXPRESSION', 'SQL_PREDICATE')) = (expression_template IS NOT NULL))
);
CREATE TRIGGER tg_dq_rule_template_touch BEFORE UPDATE ON ph08_dq.dq_rule_template FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls_shared('ph08_dq.dq_rule_template');
COMMENT ON TABLE ph08_dq.dq_rule_template IS 'EN-08-09 Quy tắc mẫu dùng lại: CCCD, mã số thuế, số điện thoại, email, đơn vị hành chính (FR-08-015). Dòng tenant COMMON do PLATFORM quản, mọi tenant đọc được (mẫu RLS S, cách PH-07); tenant có thể thêm mẫu riêng.';
COMMENT ON COLUMN ph08_dq.dq_rule_template.tenant_id IS 'Dạng Tnn hoặc COMMON (bộ mẫu dùng chung).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_rule_template CASCADE;

--changeset ph08:ph08-0160-dq-weight-config
CREATE TABLE ph08_dq.dq_weight_config (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  config_code      varchar(63) NOT NULL,
  version_no       integer NOT NULL DEFAULT 1,
  domain_code      varchar(32),
  asset_id         uuid,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  w_completeness   numeric(5,4) NOT NULL DEFAULT 0.20,
  w_accuracy       numeric(5,4) NOT NULL DEFAULT 0.20,
  w_consistency    numeric(5,4) NOT NULL DEFAULT 0.15,
  w_timeliness     numeric(5,4) NOT NULL DEFAULT 0.10,
  w_uniqueness     numeric(5,4) NOT NULL DEFAULT 0.15,
  w_validity       numeric(5,4) NOT NULL DEFAULT 0.20,
  pass_min         numeric(5,2) NOT NULL DEFAULT 90,
  warn_min         numeric(5,2) NOT NULL DEFAULT 75,
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
  CONSTRAINT pk_dq_weight_config PRIMARY KEY (id),
  CONSTRAINT uq_dq_weight_config_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_weight_config_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_weight_config_version UNIQUE (tenant_id, config_code, version_no),
  CONSTRAINT fk_dq_weight_config_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_weight_config_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph08_dq.dq_domain (tenant_id, domain_code),
  CONSTRAINT ck_dq_weight_config_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'RETIRED')),
  CONSTRAINT ck_dq_weight_config_sum CHECK (abs(w_completeness + w_accuracy + w_consistency + w_timeliness + w_uniqueness + w_validity - 1.0) <= 0.001),
  CONSTRAINT ck_dq_weight_config_range CHECK (w_completeness >= 0 AND w_accuracy >= 0 AND w_consistency >= 0 AND w_timeliness >= 0 AND w_uniqueness >= 0 AND w_validity >= 0),
  CONSTRAINT ck_dq_weight_config_threshold CHECK (pass_min <= 100 AND warn_min >= 0 AND warn_min <= pass_min),
  CONSTRAINT ck_dq_weight_config_scope CHECK (asset_id IS NULL OR domain_code IS NULL),
  CONSTRAINT ck_dq_weight_config_four_eyes CHECK (decided_by IS NULL OR submitted_by IS NULL OR decided_by <> submitted_by),
  CONSTRAINT ck_dq_weight_config_active CHECK (status <> 'ACTIVE' OR activated_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_dq_weight_config_active ON ph08_dq.dq_weight_config (tenant_id, COALESCE(domain_code, ''), COALESCE(asset_id, '00000000-0000-0000-0000-000000000000'::uuid)) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_dq_weight_config_touch BEFORE UPDATE ON ph08_dq.dq_weight_config FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_weight_config_immutable BEFORE UPDATE ON ph08_dq.dq_weight_config FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'config_code', 'version_no');
CREATE TRIGGER tg_dq_weight_config_frozen BEFORE UPDATE ON ph08_dq.dq_weight_config FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_frozen('ACTIVE,SUPERSEDED', 'w_completeness', 'w_accuracy', 'w_consistency', 'w_timeliness', 'w_uniqueness', 'w_validity', 'pass_min', 'warn_min');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_weight_config');
COMMENT ON TABLE ph08_dq.dq_weight_config IS 'EN-08-10 Cấu hình trọng số sáu chiều và ngưỡng điểm, có phiên bản và duyệt bốn mắt (FR-08-021, 028). Phạm vi tenant, miền hoặc đối tượng đo; mặc định 0,20/0,20/0,15/0,10/0,15/0,20. Tổng trọng số bằng 1,000 với dung sai 0,001.';
COMMENT ON COLUMN ph08_dq.dq_weight_config.w_completeness IS 'Cột w_* theo thứ tự COMPLETENESS, ACCURACY, CONSISTENCY, TIMELINESS, UNIQUENESS, VALIDITY.';
COMMENT ON COLUMN ph08_dq.dq_weight_config.pass_min IS 'Điểm từ ngưỡng này trở lên: PASS; từ warn_min: WARN; dưới: FAIL (giả định 90 và 75, FR-08-021).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_weight_config CASCADE;

--changeset ph08:ph08-0170-dq-rule-set
CREATE TABLE ph08_dq.dq_rule_set (
  id                 uuid NOT NULL,
  tenant_id          varchar(16) NOT NULL,
  set_code           varchar(63) NOT NULL,
  name               varchar(255) NOT NULL,
  asset_id           uuid NOT NULL,
  description        varchar(2000),
  current_version_no integer NOT NULL DEFAULT 0,
  created_at         timestamptz NOT NULL DEFAULT now(),
  created_by         varchar(64) NOT NULL,
  updated_at         timestamptz NOT NULL DEFAULT now(),
  updated_by         varchar(64) NOT NULL,
  version            integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_rule_set PRIMARY KEY (id),
  CONSTRAINT uq_dq_rule_set_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_rule_set_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_rule_set_code UNIQUE (tenant_id, set_code),
  CONSTRAINT fk_dq_rule_set_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT ck_dq_rule_set_code CHECK (set_code ~ '^[A-Za-z][A-Za-z0-9_.-]{1,62}$'),
  CONSTRAINT ck_dq_rule_set_current CHECK (current_version_no >= 0)
);
CREATE INDEX ix_dq_rule_set_asset ON ph08_dq.dq_rule_set (tenant_id, asset_id);
CREATE TRIGGER tg_dq_rule_set_touch BEFORE UPDATE ON ph08_dq.dq_rule_set FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_rule_set_immutable BEFORE UPDATE ON ph08_dq.dq_rule_set FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'set_code', 'asset_id');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_rule_set');
COMMENT ON TABLE ph08_dq.dq_rule_set IS 'EN-08-06 Bộ quy tắc của một đối tượng đo (FR-08-012, 018, 020, 022). Nội dung nằm ở các phiên bản dq_rule_set_version; mỗi bộ có đúng một phiên bản ACTIVE.';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_rule_set CASCADE;

--changeset ph08:ph08-0180-dq-rule-set-version
CREATE TABLE ph08_dq.dq_rule_set_version (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  rule_set_id      uuid NOT NULL,
  version_no       integer NOT NULL,
  status           varchar(20) NOT NULL DEFAULT 'DRAFT',
  weight_config_id uuid,
  content_hash     bytea,
  rule_count       integer NOT NULL DEFAULT 0,
  change_note      varchar(2000),
  submitted_by     varchar(64),
  submitted_at     timestamptz,
  decision         varchar(8),
  decided_by       varchar(64),
  decided_at       timestamptz,
  decision_comment varchar(2000),
  activated_at     timestamptz,
  superseded_at    timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_rule_set_version PRIMARY KEY (id),
  CONSTRAINT uq_dq_rule_set_version_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_rule_set_version_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_rule_set_version_no UNIQUE (tenant_id, rule_set_id, version_no),
  CONSTRAINT fk_dq_rule_set_version_set FOREIGN KEY (tenant_id, rule_set_id) REFERENCES ph08_dq.dq_rule_set (tenant_id, id),
  CONSTRAINT fk_dq_rule_set_version_weight FOREIGN KEY (tenant_id, weight_config_id) REFERENCES ph08_dq.dq_weight_config (tenant_id, id),
  CONSTRAINT ck_dq_rule_set_version_no CHECK (version_no >= 1),
  CONSTRAINT ck_dq_rule_set_version_status CHECK (status IN ('DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'RETIRED')),
  CONSTRAINT ck_dq_rule_set_version_hash CHECK (content_hash IS NULL OR octet_length(content_hash) = 32),
  CONSTRAINT ck_dq_rule_set_version_decision CHECK (decision IS NULL OR decision IN ('APPROVE', 'REJECT')),
  CONSTRAINT ck_dq_rule_set_version_four_eyes CHECK (decided_by IS NULL OR submitted_by IS NULL OR decided_by <> submitted_by),
  CONSTRAINT ck_dq_rule_set_version_active CHECK (status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decision = 'APPROVE' AND content_hash IS NOT NULL AND rule_count > 0)),
  CONSTRAINT ck_dq_rule_set_version_reject CHECK (decision IS DISTINCT FROM 'REJECT' OR COALESCE(char_length(decision_comment) >= 20, false))
);
CREATE UNIQUE INDEX uq_dq_rule_set_version_active ON ph08_dq.dq_rule_set_version (tenant_id, rule_set_id) WHERE status = 'ACTIVE';
CREATE INDEX ix_dq_rule_set_version_status ON ph08_dq.dq_rule_set_version (tenant_id, status, submitted_at);
CREATE TRIGGER tg_dq_rule_set_version_touch BEFORE UPDATE ON ph08_dq.dq_rule_set_version FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_rule_set_version_immutable BEFORE UPDATE ON ph08_dq.dq_rule_set_version FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'rule_set_id', 'version_no');
CREATE TRIGGER tg_dq_rule_set_version_frozen BEFORE UPDATE ON ph08_dq.dq_rule_set_version FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_frozen('ACTIVE,SUPERSEDED', 'weight_config_id', 'content_hash', 'rule_count');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_rule_set_version');
COMMENT ON TABLE ph08_dq.dq_rule_set_version IS 'EN-08-07 Phiên bản bộ quy tắc, vòng đời DRAFT, PENDING_APPROVAL, ACTIVE, SUPERSEDED, RETIRED, duyệt bốn mắt (FR-08-012, 017, 018, 019). Phiên bản ACTIVE hoặc SUPERSEDED bất biến; quy tắc con chỉ sửa khi phiên bản là DRAFT.';
COMMENT ON COLUMN ph08_dq.dq_rule_set_version.content_hash IS 'SHA-256 nội dung quy tắc tại lúc gửi duyệt; ACTIVE bắt buộc có (bất biến, FR-08-018, 019).';
COMMENT ON COLUMN ph08_dq.dq_rule_set_version.rule_count IS 'Số quy tắc; ACTIVE phải lớn hơn 0.';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_rule_set_version CASCADE;

--changeset ph08:ph08-0190-dq-rule
CREATE TABLE ph08_dq.dq_rule (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  rule_set_version_id uuid NOT NULL,
  rule_code           varchar(63) NOT NULL,
  name                varchar(255) NOT NULL,
  description         varchar(2000),
  dimension           varchar(16) NOT NULL,
  operator            varchar(24) NOT NULL,
  severity            varchar(8) NOT NULL DEFAULT 'MAJOR',
  exec_mode           varchar(8) NOT NULL DEFAULT 'BATCH',
  inline_mode         varchar(10),
  field_name          varchar(63),
  params              jsonb NOT NULL DEFAULT '{}',
  expression          text,
  message             varchar(500),
  weight              numeric(6,3) NOT NULL DEFAULT 1,
  template_code       varchar(64),
  enabled             boolean NOT NULL DEFAULT true,
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_rule PRIMARY KEY (id),
  CONSTRAINT uq_dq_rule_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_rule_code UNIQUE (tenant_id, rule_set_version_id, rule_code),
  CONSTRAINT fk_dq_rule_version FOREIGN KEY (tenant_id, rule_set_version_id) REFERENCES ph08_dq.dq_rule_set_version (tenant_id, id),
  CONSTRAINT ck_dq_rule_code CHECK (rule_code ~ '^[A-Za-z][A-Za-z0-9_.-]{1,62}$'),
  CONSTRAINT ck_dq_rule_dimension CHECK (dimension IN ('COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'TIMELINESS', 'UNIQUENESS', 'VALIDITY')),
  CONSTRAINT ck_dq_rule_operator CHECK (operator IN ('NOT_NULL', 'NOT_EMPTY', 'REQUIRED_IF', 'REGEX', 'LENGTH', 'RANGE', 'CHECKSUM', 'TYPE', 'EQ_SOURCE', 'EQ_FIELDS', 'CROSS_ENTITY', 'MAX_AGE_DAYS', 'UPDATED_AFTER', 'UNIQUE_IN_ASSET', 'UNIQUE_COMPOSITE', 'IN_RDM', 'IN_RDM_VERSION', 'CEL_EXPRESSION', 'SQL_PREDICATE')),
  CONSTRAINT ck_dq_rule_severity CHECK (severity IN ('CRITICAL', 'MAJOR', 'MINOR')),
  CONSTRAINT ck_dq_rule_exec CHECK (exec_mode IN ('BATCH', 'INLINE', 'BOTH')),
  CONSTRAINT ck_dq_rule_inline CHECK ((exec_mode = 'BATCH') = (inline_mode IS NULL) AND (inline_mode IS NULL OR inline_mode IN ('STRICT', 'ADVISORY'))),
  CONSTRAINT ck_dq_rule_operator_dimension CHECK ((operator NOT IN ('NOT_NULL', 'NOT_EMPTY', 'REQUIRED_IF') OR dimension = 'COMPLETENESS') AND (operator NOT IN ('UNIQUE_IN_ASSET', 'UNIQUE_COMPOSITE') OR dimension = 'UNIQUENESS') AND (operator NOT IN ('IN_RDM', 'IN_RDM_VERSION') OR dimension = 'VALIDITY') AND (operator NOT IN ('MAX_AGE_DAYS', 'UPDATED_AFTER') OR dimension = 'TIMELINESS')),
  CONSTRAINT ck_dq_rule_expression CHECK ((operator IN ('CEL_EXPRESSION', 'SQL_PREDICATE')) = (expression IS NOT NULL)),
  CONSTRAINT ck_dq_rule_sql_batch CHECK (operator <> 'SQL_PREDICATE' OR exec_mode = 'BATCH'),
  CONSTRAINT ck_dq_rule_rdm CHECK (operator NOT IN ('IN_RDM', 'IN_RDM_VERSION') OR params ? 'catalogCode'),
  CONSTRAINT ck_dq_rule_weight CHECK (weight > 0)
);
CREATE INDEX ix_dq_rule_version ON ph08_dq.dq_rule (tenant_id, rule_set_version_id, dimension);
CREATE INDEX ix_dq_rule_inline ON ph08_dq.dq_rule (tenant_id, rule_set_version_id) WHERE exec_mode <> 'BATCH' AND enabled;
CREATE TRIGGER tg_dq_rule_touch BEFORE UPDATE ON ph08_dq.dq_rule FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_rule_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph08_dq.dq_rule FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_child_frozen();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_rule');
COMMENT ON TABLE ph08_dq.dq_rule IS 'EN-08-08 Quy tắc chất lượng: chiều, toán tử, mức nghiêm trọng, chế độ chạy (lô, trực tuyến, cả hai) và tham số (FR-08-013, 014, 016, 022). Biểu thức CEL hoặc vị từ SQL có kiểm soát nằm ở cột expression; vị từ SQL chỉ chạy theo lô.';
COMMENT ON COLUMN ph08_dq.dq_rule.message IS 'Thông điệp hiển thị ở bản ghi lỗi khi quy tắc không đạt (thay cột thong_diep của SRS cũ).';
COMMENT ON COLUMN ph08_dq.dq_rule.inline_mode IS 'STRICT chặn bản ghi lỗi, ADVISORY chỉ cảnh báo; rỗng khi exec_mode = BATCH (FR-08-032, 033).';
COMMENT ON COLUMN ph08_dq.dq_rule.operator IS '19 toán tử theo FRS; ràng buộc operator_dimension khóa quan hệ toán tử với chiều (ví dụ IN_RDM chỉ thuộc VALIDITY).';
COMMENT ON COLUMN ph08_dq.dq_rule.expression IS 'CEL (cel-java) hoặc vị từ SQL có kiểm soát; chỉ khi operator là CEL_EXPRESSION hoặc SQL_PREDICATE (FR-08-014).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_rule CASCADE;
