--liquibase formatted sql
-- Nguồn: ddl/ph08_dq.sql · 08-0030-scan.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph08:ph08-0200-dq-schedule
CREATE TABLE ph08_dq.dq_schedule (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  schedule_code varchar(63) NOT NULL,
  domain_code   varchar(32),
  asset_id      uuid,
  cron          varchar(64) NOT NULL DEFAULT '0 0 2 1 * *',
  timezone      varchar(40) NOT NULL DEFAULT 'Asia/Ho_Chi_Minh',
  scan_mode     varchar(16) NOT NULL DEFAULT 'FULL',
  enabled       boolean NOT NULL DEFAULT true,
  next_run_at   timestamptz,
  last_run_at   timestamptz,
  last_job_id   uuid,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_schedule PRIMARY KEY (id),
  CONSTRAINT uq_dq_schedule_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_schedule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_schedule_code UNIQUE (tenant_id, schedule_code),
  CONSTRAINT fk_dq_schedule_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_schedule_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph08_dq.dq_domain (tenant_id, domain_code),
  CONSTRAINT ck_dq_schedule_code CHECK (schedule_code ~ '^[A-Za-z][A-Za-z0-9_.-]{1,62}$'),
  CONSTRAINT ck_dq_schedule_scope CHECK (asset_id IS NULL OR domain_code IS NULL),
  CONSTRAINT ck_dq_schedule_mode CHECK (scan_mode IN ('FULL', 'SAMPLE', 'INCREMENTAL')),
  CONSTRAINT ck_dq_schedule_cron CHECK (cron ~ '^[-0-9*/,?LW#A-Za-z]+( [-0-9*/,?LW#A-Za-z]+){5,6}$')
);
CREATE INDEX ix_dq_schedule_next ON ph08_dq.dq_schedule (next_run_at) WHERE enabled;
CREATE TRIGGER tg_dq_schedule_touch BEFORE UPDATE ON ph08_dq.dq_schedule FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_schedule');
COMMENT ON TABLE ph08_dq.dq_schedule IS 'EN-08-11 Lịch đo theo lô bằng biểu thức cron (FR-08-023). Phạm vi là một đối tượng, một miền hoặc cả tenant; mặc định ngày 1 hằng tháng lúc 02:00. Lập lịch chạy bằng Quartz có ShedLock.';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_schedule CASCADE;

--changeset ph08:ph08-0210-dq-scan-job
CREATE TABLE ph08_dq.dq_scan_job (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  asset_id            uuid NOT NULL,
  rule_set_version_id uuid NOT NULL,
  weight_config_id    uuid,
  schedule_id         uuid,
  scan_trigger        varchar(12) NOT NULL,
  scan_mode           varchar(16) NOT NULL,
  status              varchar(12) NOT NULL DEFAULT 'QUEUED',
  period_code         varchar(7) NOT NULL,
  requested_by        varchar(64) NOT NULL,
  idempotency_key     varchar(64),
  verify_issue_id     uuid,
  source_event_id     uuid,
  rerun_of            uuid,
  source_snapshot_at  timestamptz,
  started_at          timestamptz,
  finished_at         timestamptz,
  task_total          integer NOT NULL DEFAULT 0,
  task_done           integer NOT NULL DEFAULT 0,
  rows_scanned        bigint NOT NULL DEFAULT 0,
  rows_failed         bigint NOT NULL DEFAULT 0,
  skipped_rules       integer NOT NULL DEFAULT 0,
  sample_size         integer,
  sample_seed         bigint,
  error_code          varchar(16),
  error_message       varchar(2000),
  cancel_reason       varchar(2000),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_scan_job PRIMARY KEY (id),
  CONSTRAINT uq_dq_scan_job_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_scan_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_scan_job_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_scan_job_version FOREIGN KEY (tenant_id, rule_set_version_id) REFERENCES ph08_dq.dq_rule_set_version (tenant_id, id),
  CONSTRAINT fk_dq_scan_job_weight FOREIGN KEY (tenant_id, weight_config_id) REFERENCES ph08_dq.dq_weight_config (tenant_id, id),
  CONSTRAINT fk_dq_scan_job_schedule FOREIGN KEY (tenant_id, schedule_id) REFERENCES ph08_dq.dq_schedule (tenant_id, id),
  CONSTRAINT fk_dq_scan_job_rerun FOREIGN KEY (tenant_id, rerun_of) REFERENCES ph08_dq.dq_scan_job (tenant_id, id),
  CONSTRAINT ck_dq_scan_job_trigger CHECK (scan_trigger IN ('SCHEDULE', 'MANUAL', 'EVENT', 'ANNUAL', 'VERIFY')),
  CONSTRAINT ck_dq_scan_job_mode CHECK (scan_mode IN ('FULL', 'SAMPLE', 'INCREMENTAL')),
  CONSTRAINT ck_dq_scan_job_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'PARTIAL', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_dq_scan_job_period CHECK (period_code ~ '^[0-9]{4}(-(0[1-9]|1[0-2]))?$'),
  CONSTRAINT ck_dq_scan_job_annual_full CHECK (scan_trigger <> 'ANNUAL' OR (scan_mode = 'FULL' AND period_code ~ '^[0-9]{4}$')),
  CONSTRAINT ck_dq_scan_job_verify CHECK ((scan_trigger = 'VERIFY') = (verify_issue_id IS NOT NULL)),
  CONSTRAINT ck_dq_scan_job_event CHECK ((scan_trigger = 'EVENT') = (source_event_id IS NOT NULL) AND (scan_trigger <> 'EVENT' OR scan_mode = 'INCREMENTAL')),
  CONSTRAINT ck_dq_scan_job_done CHECK (status NOT IN ('SUCCEEDED', 'PARTIAL', 'FAILED', 'CANCELLED') OR finished_at IS NOT NULL),
  CONSTRAINT ck_dq_scan_job_cancel CHECK (status <> 'CANCELLED' OR COALESCE(char_length(cancel_reason) >= 20, false)),
  CONSTRAINT ck_dq_scan_job_progress CHECK (task_done >= 0 AND task_done <= task_total AND rows_scanned >= 0 AND rows_failed >= 0 AND rows_failed <= rows_scanned),
  CONSTRAINT ck_dq_scan_job_sample CHECK ((scan_mode = 'SAMPLE') = (sample_size IS NOT NULL) AND (sample_size IS NULL OR sample_size > 0)),
  CONSTRAINT ck_dq_scan_job_error CHECK (error_code IS NULL OR error_code ~ '^ERR-08-[0-9]{3}$')
);
CREATE UNIQUE INDEX uq_dq_scan_job_running ON ph08_dq.dq_scan_job (tenant_id, asset_id) WHERE status = 'RUNNING';
CREATE UNIQUE INDEX uq_dq_scan_job_idem ON ph08_dq.dq_scan_job (tenant_id, idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE INDEX ix_dq_scan_job_asset ON ph08_dq.dq_scan_job (tenant_id, asset_id, created_at DESC);
CREATE INDEX ix_dq_scan_job_period ON ph08_dq.dq_scan_job (tenant_id, period_code, status);
CREATE INDEX ix_dq_scan_job_queue ON ph08_dq.dq_scan_job (tenant_id, created_at) WHERE status IN ('QUEUED', 'RUNNING');
CREATE TRIGGER tg_dq_scan_job_touch BEFORE UPDATE ON ph08_dq.dq_scan_job FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_scan_job_immutable BEFORE UPDATE ON ph08_dq.dq_scan_job FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'asset_id', 'rule_set_version_id', 'scan_trigger', 'scan_mode', 'period_code');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_scan_job');
COMMENT ON TABLE ph08_dq.dq_scan_job IS 'EN-08-12 Lần đo chất lượng của một đối tượng đo với một phiên bản bộ quy tắc (FR-08-023…026, 030, 031). Kích hoạt theo lịch, thủ công, sự kiện, hằng năm (bắt buộc đo đủ) hoặc đo lại kiểm chứng phiếu khắc phục. Mỗi đối tượng chỉ một lần đo đang chạy.';
COMMENT ON COLUMN ph08_dq.dq_scan_job.sample_seed IS 'Hạt giống lấy mẫu để tái lập kết quả khi đo SAMPLE (SRS cũ EN-08-04).';
COMMENT ON COLUMN ph08_dq.dq_scan_job.verify_issue_id IS 'Phiếu khắc phục cần kiểm chứng (trigger VERIFY, FR-08-044); khóa ngoại nằm ở dq_issue.verify_scan_job_id.';
COMMENT ON COLUMN ph08_dq.dq_scan_job.period_code IS 'Kỳ đo: YYYY-MM (tháng) hoặc YYYY (đo chính thức hằng năm, FR-08-054).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_scan_job CASCADE;

--changeset ph08:ph08-0220-dq-scan-task
CREATE TABLE ph08_dq.dq_scan_task (
  id           uuid NOT NULL,
  tenant_id    varchar(16) NOT NULL,
  scan_job_id  uuid NOT NULL,
  shard_no     integer NOT NULL,
  shard_count  integer NOT NULL,
  status       varchar(12) NOT NULL DEFAULT 'QUEUED',
  key_from     varchar(255),
  key_to       varchar(255),
  attempt      smallint NOT NULL DEFAULT 0,
  worker_id    varchar(64),
  rows_scanned bigint NOT NULL DEFAULT 0,
  rows_failed  bigint NOT NULL DEFAULT 0,
  started_at   timestamptz,
  finished_at  timestamptz,
  error_code   varchar(16),
  created_at   timestamptz NOT NULL DEFAULT now(),
  created_by   varchar(64) NOT NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  updated_by   varchar(64) NOT NULL,
  version      integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_scan_task PRIMARY KEY (id),
  CONSTRAINT uq_dq_scan_task_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_scan_task_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_scan_task_shard UNIQUE (tenant_id, scan_job_id, shard_no),
  CONSTRAINT fk_dq_scan_task_job FOREIGN KEY (tenant_id, scan_job_id) REFERENCES ph08_dq.dq_scan_job (tenant_id, id),
  CONSTRAINT ck_dq_scan_task_shard CHECK (shard_no >= 0 AND shard_no < shard_count),
  CONSTRAINT ck_dq_scan_task_status CHECK (status IN ('QUEUED', 'RUNNING', 'SUCCEEDED', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_dq_scan_task_attempt CHECK (attempt >= 0 AND attempt <= 10),
  CONSTRAINT ck_dq_scan_task_error CHECK (error_code IS NULL OR error_code ~ '^ERR-08-[0-9]{3}$')
);
CREATE INDEX ix_dq_scan_task_job ON ph08_dq.dq_scan_task (tenant_id, scan_job_id, status);
CREATE TRIGGER tg_dq_scan_task_touch BEFORE UPDATE ON ph08_dq.dq_scan_task FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_scan_task');
COMMENT ON TABLE ph08_dq.dq_scan_task IS 'EN-08-13 Tác vụ phân mảnh của lần đo: mỗi mảnh là một khoảng khóa của đối tượng, chạy độc lập, thử lại được (FR-08-026, 030). Dọn sau 90 ngày.';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_scan_task CASCADE;

--changeset ph08:ph08-0230-dq-rule-result
CREATE TABLE ph08_dq.dq_rule_result (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  executed_at    timestamptz NOT NULL DEFAULT now(),
  scan_job_id    uuid NOT NULL,
  scan_task_id   uuid,
  asset_id       uuid NOT NULL,
  rule_id        uuid NOT NULL,
  dimension      varchar(16) NOT NULL,
  severity       varchar(8) NOT NULL,
  status         varchar(8) NOT NULL,
  rows_evaluated bigint NOT NULL DEFAULT 0,
  rows_failed    bigint NOT NULL DEFAULT 0,
  pass_rate      numeric(7,6),
  skip_reason    varchar(32),
  error_code     varchar(16),
  duration_ms    integer,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_rule_result PRIMARY KEY (id, executed_at),
  CONSTRAINT ck_dq_rule_result_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_dq_rule_result_job FOREIGN KEY (tenant_id, scan_job_id) REFERENCES ph08_dq.dq_scan_job (tenant_id, id),
  CONSTRAINT fk_dq_rule_result_rule FOREIGN KEY (tenant_id, rule_id) REFERENCES ph08_dq.dq_rule (tenant_id, id),
  CONSTRAINT ck_dq_rule_result_dimension CHECK (dimension IN ('COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'TIMELINESS', 'UNIQUENESS', 'VALIDITY')),
  CONSTRAINT ck_dq_rule_result_severity CHECK (severity IN ('CRITICAL', 'MAJOR', 'MINOR')),
  CONSTRAINT ck_dq_rule_result_status CHECK (status IN ('PASSED', 'FAILED', 'SKIPPED', 'ERROR')),
  CONSTRAINT ck_dq_rule_result_counts CHECK (rows_evaluated >= 0 AND rows_failed >= 0 AND rows_failed <= rows_evaluated),
  CONSTRAINT ck_dq_rule_result_rate CHECK (pass_rate IS NULL OR (pass_rate >= 0 AND pass_rate <= 1)),
  CONSTRAINT ck_dq_rule_result_skipped CHECK ((status = 'SKIPPED') = (skip_reason IS NOT NULL)),
  CONSTRAINT ck_dq_rule_result_skip_reason CHECK (skip_reason IS NULL OR skip_reason IN ('DEPENDENCY_UNAVAILABLE', 'RDM_UNAVAILABLE', 'SOURCE_UNREACHABLE', 'NO_DATA', 'TIMEOUT')),
  CONSTRAINT ck_dq_rule_result_error CHECK (error_code IS NULL OR error_code ~ '^ERR-08-[0-9]{3}$')
) PARTITION BY RANGE (executed_at);
CALL ph08_dq.p_ensure_partitions('ph08_dq.dq_rule_result', current_date, 3);
CREATE INDEX ix_dq_rule_result_job ON ph08_dq.dq_rule_result (tenant_id, scan_job_id, dimension);
CREATE INDEX ix_dq_rule_result_rule ON ph08_dq.dq_rule_result (tenant_id, rule_id, executed_at DESC);
CREATE INDEX ix_dq_rule_result_asset ON ph08_dq.dq_rule_result (tenant_id, asset_id, executed_at DESC);
CREATE TRIGGER tg_dq_rule_result_touch BEFORE UPDATE ON ph08_dq.dq_rule_result FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_rule_result_append_only BEFORE UPDATE OR DELETE ON ph08_dq.dq_rule_result FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_append_only();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_rule_result');
COMMENT ON TABLE ph08_dq.dq_rule_result IS 'EN-08-14 Kết quả từng quy tắc trong một lần đo: số dòng xét, số dòng lỗi, tỷ lệ đạt, trạng thái PASSED, FAILED, SKIPPED, ERROR (FR-08-026, 027, 028, 031). Ghi một lần, không sửa. Phân vùng tháng theo executed_at.';
COMMENT ON COLUMN ph08_dq.dq_rule_result.pass_rate IS '1 - rows_failed / rows_evaluated; rỗng khi SKIPPED hoặc ERROR.';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_rule_result CASCADE;

--changeset ph08:ph08-0240-dq-score-snapshot
CREATE TABLE ph08_dq.dq_score_snapshot (
  id                  uuid NOT NULL,
  tenant_id           varchar(16) NOT NULL,
  scan_job_id         uuid NOT NULL,
  asset_id            uuid NOT NULL,
  domain_code         varchar(32) NOT NULL,
  owner_org_code      varchar(63) NOT NULL,
  period_code         varchar(7) NOT NULL,
  scan_mode           varchar(16) NOT NULL,
  score               numeric(5,2) NOT NULL,
  verdict             varchar(4) NOT NULL,
  trend               varchar(10) NOT NULL DEFAULT 'BASELINE',
  flags               varchar(32)[] NOT NULL DEFAULT '{}',
  prev_snapshot_id    uuid,
  prev_score          numeric(5,2),
  delta               numeric(6,2),
  weight_config_id    uuid,
  rule_set_version_id uuid NOT NULL,
  row_count           bigint NOT NULL DEFAULT 0,
  official            boolean NOT NULL DEFAULT false,
  measured_at         timestamptz NOT NULL DEFAULT now(),
  created_at          timestamptz NOT NULL DEFAULT now(),
  created_by          varchar(64) NOT NULL,
  updated_at          timestamptz NOT NULL DEFAULT now(),
  updated_by          varchar(64) NOT NULL,
  version             integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_score_snapshot PRIMARY KEY (id),
  CONSTRAINT uq_dq_score_snapshot_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_score_snapshot_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_score_snapshot_job UNIQUE (tenant_id, scan_job_id),
  CONSTRAINT fk_dq_score_snapshot_job FOREIGN KEY (tenant_id, scan_job_id) REFERENCES ph08_dq.dq_scan_job (tenant_id, id),
  CONSTRAINT fk_dq_score_snapshot_asset FOREIGN KEY (tenant_id, asset_id) REFERENCES ph08_dq.dq_asset (tenant_id, id),
  CONSTRAINT fk_dq_score_snapshot_prev FOREIGN KEY (tenant_id, prev_snapshot_id) REFERENCES ph08_dq.dq_score_snapshot (tenant_id, id),
  CONSTRAINT ck_dq_score_snapshot_score CHECK (score >= 0 AND score <= 100),
  CONSTRAINT ck_dq_score_snapshot_verdict CHECK (verdict IN ('PASS', 'WARN', 'FAIL')),
  CONSTRAINT ck_dq_score_snapshot_trend CHECK (trend IN ('BASELINE', 'IMPROVED', 'STABLE', 'DEGRADED')),
  CONSTRAINT ck_dq_score_snapshot_mode CHECK (scan_mode IN ('FULL', 'SAMPLE', 'INCREMENTAL')),
  CONSTRAINT ck_dq_score_snapshot_flags CHECK (flags <@ ARRAY['INCOMPLETE_DIMENSIONS', 'WEIGHTS_CHANGED']::varchar[]),
  CONSTRAINT ck_dq_score_snapshot_period CHECK (period_code ~ '^[0-9]{4}(-(0[1-9]|1[0-2]))?$'),
  CONSTRAINT ck_dq_score_snapshot_baseline CHECK ((trend = 'BASELINE') = (prev_snapshot_id IS NULL)),
  CONSTRAINT ck_dq_score_snapshot_official CHECK (NOT official OR (scan_mode = 'FULL' AND NOT (flags && ARRAY['INCOMPLETE_DIMENSIONS']::varchar[])))
);
CREATE INDEX ix_dq_score_snapshot_asset ON ph08_dq.dq_score_snapshot (tenant_id, asset_id, period_code, measured_at DESC);
CREATE INDEX ix_dq_score_snapshot_domain ON ph08_dq.dq_score_snapshot (tenant_id, domain_code, period_code);
CREATE INDEX ix_dq_score_snapshot_org ON ph08_dq.dq_score_snapshot (tenant_id, owner_org_code, period_code);
CREATE INDEX ix_dq_score_snapshot_official ON ph08_dq.dq_score_snapshot (tenant_id, period_code, asset_id) WHERE official;
CREATE TRIGGER tg_dq_score_snapshot_touch BEFORE UPDATE ON ph08_dq.dq_score_snapshot FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_score_snapshot_immutable BEFORE UPDATE ON ph08_dq.dq_score_snapshot FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'scan_job_id', 'asset_id', 'period_code', 'score', 'verdict', 'flags', 'official');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_score_snapshot');
COMMENT ON TABLE ph08_dq.dq_score_snapshot IS 'EN-08-15 Snapshot điểm chất lượng của một đối tượng trong một kỳ: điểm có trọng số, kết luận PASS, WARN, FAIL, xu hướng so kỳ trước, cờ thiếu chiều hoặc đổi trọng số (FR-08-028, 029, 031, 051). Snapshot chính thức (official) phải từ lần đo đủ và không thiếu chiều.';
COMMENT ON COLUMN ph08_dq.dq_score_snapshot.official IS 'Dùng cho báo cáo chính thức hằng năm (FR-08-054): chỉ khi đo FULL và không có cờ INCOMPLETE_DIMENSIONS.';
COMMENT ON COLUMN ph08_dq.dq_score_snapshot.flags IS 'INCOMPLETE_DIMENSIONS: thiếu chiều do SKIPPED; WEIGHTS_CHANGED: trọng số đổi so với kỳ trước.';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_score_snapshot CASCADE;

--changeset ph08:ph08-0250-dq-score-dimension
CREATE TABLE ph08_dq.dq_score_dimension (
  id            uuid NOT NULL,
  tenant_id     varchar(16) NOT NULL,
  snapshot_id   uuid NOT NULL,
  dimension     varchar(16) NOT NULL,
  status        varchar(10) NOT NULL DEFAULT 'MEASURED',
  score         numeric(5,2),
  weight        numeric(5,4) NOT NULL,
  rules_total   integer NOT NULL DEFAULT 0,
  rules_passed  integer NOT NULL DEFAULT 0,
  rules_failed  integer NOT NULL DEFAULT 0,
  rules_skipped integer NOT NULL DEFAULT 0,
  rows_failed   bigint NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now(),
  created_by    varchar(64) NOT NULL,
  updated_at    timestamptz NOT NULL DEFAULT now(),
  updated_by    varchar(64) NOT NULL,
  version       integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_score_dimension PRIMARY KEY (id),
  CONSTRAINT uq_dq_score_dimension_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_dq_score_dimension_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_score_dimension UNIQUE (tenant_id, snapshot_id, dimension),
  CONSTRAINT fk_dq_score_dimension_snapshot FOREIGN KEY (tenant_id, snapshot_id) REFERENCES ph08_dq.dq_score_snapshot (tenant_id, id),
  CONSTRAINT ck_dq_score_dimension_dimension CHECK (dimension IN ('COMPLETENESS', 'ACCURACY', 'CONSISTENCY', 'TIMELINESS', 'UNIQUENESS', 'VALIDITY')),
  CONSTRAINT ck_dq_score_dimension_status CHECK (status IN ('MEASURED', 'SKIPPED')),
  CONSTRAINT ck_dq_score_dimension_score CHECK ((status = 'SKIPPED') = (score IS NULL) AND (score IS NULL OR (score >= 0 AND score <= 100))),
  CONSTRAINT ck_dq_score_dimension_weight CHECK (weight >= 0 AND weight <= 1),
  CONSTRAINT ck_dq_score_dimension_counts CHECK (rules_total >= 0 AND rules_passed + rules_failed + rules_skipped <= rules_total)
);
CREATE TRIGGER tg_dq_score_dimension_touch BEFORE UPDATE ON ph08_dq.dq_score_dimension FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CREATE TRIGGER tg_dq_score_dimension_immutable BEFORE UPDATE ON ph08_dq.dq_score_dimension FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_immutable('tenant_id', 'snapshot_id', 'dimension', 'score', 'status');
CALL ph08_dq.p_enable_rls('ph08_dq.dq_score_dimension');
COMMENT ON TABLE ph08_dq.dq_score_dimension IS 'EN-08-16 Điểm theo từng chiều trong snapshot, kèm trọng số đã áp và số quy tắc đạt, lỗi, bỏ qua (FR-08-028, 029). Chiều bị bỏ qua có điểm rỗng.';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_score_dimension CASCADE;

--changeset ph08:ph08-0260-dq-inline-stat
CREATE TABLE ph08_dq.dq_inline_stat (
  id                uuid NOT NULL,
  tenant_id         varchar(16) NOT NULL,
  bucket_at         timestamptz NOT NULL,
  asset_id          uuid NOT NULL,
  caller_code       varchar(63) NOT NULL,
  mode              varchar(10) NOT NULL DEFAULT 'ADVISORY',
  check_count       integer NOT NULL DEFAULT 0,
  pass_count        integer NOT NULL DEFAULT 0,
  fail_count        integer NOT NULL DEFAULT 0,
  blocked_count     integer NOT NULL DEFAULT 0,
  error_count       integer NOT NULL DEFAULT 0,
  warn_count        integer NOT NULL DEFAULT 0,
  fail_open_count   integer NOT NULL DEFAULT 0,
  fail_closed_count integer NOT NULL DEFAULT 0,
  p50_ms            integer,
  p95_ms            integer,
  max_ms            integer,
  by_rule           jsonb NOT NULL DEFAULT '{}',
  created_at        timestamptz NOT NULL DEFAULT now(),
  created_by        varchar(64) NOT NULL,
  updated_at        timestamptz NOT NULL DEFAULT now(),
  updated_by        varchar(64) NOT NULL,
  version           integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_dq_inline_stat PRIMARY KEY (id, bucket_at),
  CONSTRAINT ck_dq_inline_stat_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_dq_inline_stat_bucket UNIQUE (tenant_id, asset_id, caller_code, mode, bucket_at),
  CONSTRAINT ck_dq_inline_stat_bucket CHECK (date_trunc('minute', bucket_at) = bucket_at),
  CONSTRAINT ck_dq_inline_stat_mode CHECK (mode IN ('STRICT', 'ADVISORY')),
  CONSTRAINT ck_dq_inline_stat_counts CHECK (check_count >= 0 AND pass_count >= 0 AND fail_count >= 0 AND error_count >= 0 AND pass_count + fail_count + error_count <= check_count),
  CONSTRAINT ck_dq_inline_stat_warn CHECK (warn_count >= 0 AND warn_count <= fail_count AND (mode = 'ADVISORY' OR warn_count = 0)),
  CONSTRAINT ck_dq_inline_stat_blocked CHECK (blocked_count >= 0 AND blocked_count <= fail_count AND (mode = 'STRICT' OR blocked_count = 0)),
  CONSTRAINT ck_dq_inline_stat_latency CHECK (p50_ms IS NULL OR (p50_ms >= 0 AND p95_ms >= p50_ms AND max_ms >= p95_ms))
) PARTITION BY RANGE (bucket_at);
CALL ph08_dq.p_ensure_partitions('ph08_dq.dq_inline_stat', current_date, 3);
CREATE INDEX ix_dq_inline_stat_asset ON ph08_dq.dq_inline_stat (tenant_id, asset_id, bucket_at DESC);
CREATE INDEX ix_dq_inline_stat_caller ON ph08_dq.dq_inline_stat (tenant_id, caller_code, bucket_at DESC);
CREATE TRIGGER tg_dq_inline_stat_touch BEFORE UPDATE ON ph08_dq.dq_inline_stat FOR EACH ROW EXECUTE FUNCTION ph08_dq.tg_touch();
CALL ph08_dq.p_enable_rls('ph08_dq.dq_inline_stat');
COMMENT ON TABLE ph08_dq.dq_inline_stat IS 'EN-08-25 Thống kê kiểm tra trực tuyến gộp theo phút, theo đối tượng và bên gọi: số lượt, đạt, lỗi, thời gian p50, p95, số lần mở hoặc đóng khi phụ thuộc lỗi (FR-08-032, 034). Không lưu nội dung bản ghi. Phân vùng tháng theo bucket_at; dọn sau 90 ngày.';
COMMENT ON COLUMN ph08_dq.dq_inline_stat.warn_count IS 'Số lượt lỗi ở chế độ ADVISORY (chỉ cảnh báo, không chặn); chế độ STRICT dùng blocked_count.';
COMMENT ON COLUMN ph08_dq.dq_inline_stat.fail_open_count IS 'Số lượt phụ thuộc lỗi mà bản ghi vẫn đi tiếp; cộng với fail_closed_count là số lượt suy giảm (degraded).';
--rollback DROP TABLE IF EXISTS ph08_dq.dq_inline_stat CASCADE;
