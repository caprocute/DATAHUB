--liquibase formatted sql
-- Nguồn: ddl/ph17_assist.sql · 17-0060-guard.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph17:ph17-0450-guardrail-rule
CREATE TABLE ph17_assist.guardrail_rule (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  rule_code      varchar(48) NOT NULL,
  guardrail_kind varchar(8) NOT NULL,
  action         varchar(8) NOT NULL,
  category       varchar(20) NOT NULL,
  pattern_kind   varchar(10) NOT NULL,
  pattern        text NOT NULL,
  description    varchar(1000),
  enabled        boolean NOT NULL DEFAULT true,
  builtin        boolean NOT NULL DEFAULT false,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_guardrail_rule PRIMARY KEY (id),
  CONSTRAINT uq_guardrail_rule_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_guardrail_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_guardrail_rule_code UNIQUE (tenant_id, rule_code),
  CONSTRAINT ck_guardrail_rule_code CHECK (rule_code ~ '^GR-(IN|OUT)-[A-Z0-9-]{3,40}$'),
  CONSTRAINT ck_guardrail_rule_kind CHECK (guardrail_kind IN ('INPUT', 'OUTPUT')),
  CONSTRAINT ck_guardrail_rule_action CHECK (action IN ('BLOCK', 'MASK', 'WARN')),
  CONSTRAINT ck_guardrail_rule_category CHECK (category IN ('PROMPT_INJECTION', 'FORBIDDEN', 'PII', 'SECRET', 'LINK')),
  CONSTRAINT ck_guardrail_rule_pattern_kind CHECK (pattern_kind IN ('REGEX', 'KEYWORD', 'DETECTOR')),
  CONSTRAINT ck_guardrail_rule_kind_code CHECK ((guardrail_kind = 'INPUT') = (rule_code LIKE 'GR-IN-%')),
  CONSTRAINT ck_guardrail_rule_secret_blocks CHECK (category <> 'SECRET' OR (guardrail_kind = 'OUTPUT' AND action = 'BLOCK')),
  CONSTRAINT ck_guardrail_rule_inject_blocks CHECK (category NOT IN ('PROMPT_INJECTION', 'FORBIDDEN') OR (guardrail_kind = 'INPUT' AND action = 'BLOCK')),
  CONSTRAINT ck_guardrail_rule_pattern CHECK (char_length(pattern) BETWEEN 1 AND 4000)
);
CREATE INDEX ix_guardrail_rule_kind ON ph17_assist.guardrail_rule (tenant_id, guardrail_kind, enabled);
CREATE TRIGGER tg_guardrail_rule_touch BEFORE UPDATE ON ph17_assist.guardrail_rule FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CREATE TRIGGER tg_guardrail_rule_immutable BEFORE UPDATE ON ph17_assist.guardrail_rule FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_immutable('rule_code', 'guardrail_kind', 'builtin');
CALL ph17_assist.p_enable_rls('ph17_assist.guardrail_rule');
COMMENT ON TABLE ph17_assist.guardrail_rule IS 'EN-17-38 Quy tắc bộ lọc vào hoặc ra (FR-17-044…046; BR-17-059, 060, 063): loại INPUT hoặc OUTPUT, mẫu (REGEX, KEYWORD hoặc bộ phát hiện), hành động BLOCK, MASK, WARN. Quy tắc dựng sẵn (builtin) không xóa, không đổi mã; chỉ tắt, bật có kiểm toán.';
COMMENT ON COLUMN ph17_assist.guardrail_rule.pattern IS 'REGEX hoặc từ khóa; với DETECTOR là mã bộ phát hiện (injection-classifier, sensitive-pii). Mẫu bí mật chỉ mô tả dạng, không giá trị thật.';
--rollback DROP TABLE IF EXISTS ph17_assist.guardrail_rule CASCADE;

--changeset ph17:ph17-0460-link-allowlist
CREATE TABLE ph17_assist.link_allowlist (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  route_prefix varchar(255) NOT NULL,
  enabled      boolean NOT NULL DEFAULT true,
  note         varchar(255),
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_link_allowlist PRIMARY KEY (id),
  CONSTRAINT ck_link_allowlist_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_link_allowlist_prefix UNIQUE (tenant_id, route_prefix),
  CONSTRAINT ck_link_allowlist_route CHECK (route_prefix ~ '^/[A-Za-z0-9/_.-]*$')
);
CREATE TRIGGER tg_link_allowlist_touch BEFORE UPDATE ON ph17_assist.link_allowlist FOR EACH ROW EXECUTE FUNCTION ph17_assist.tg_touch();
CALL ph17_assist.p_enable_rls('ph17_assist.link_allowlist');
COMMENT ON TABLE ph17_assist.link_allowlist IS 'EN-17-48 (FR-17-046; BR-17-037). Danh sách trắng route nội bộ của cổng Datahub được phép xuất hiện trong câu trả lời; liên kết ngoài danh sách bị bỏ và ghi nhật ký lọc.';
--rollback DROP TABLE IF EXISTS ph17_assist.link_allowlist CASCADE;
