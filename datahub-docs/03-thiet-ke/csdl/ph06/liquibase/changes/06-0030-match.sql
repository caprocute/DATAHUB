--liquibase formatted sql
-- Nguồn: ddl/ph06_mdm.sql · 06-0030-match.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph06:ph06-0200-evaluation-report
CREATE TABLE ph06_mdm.evaluation_report (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  domain_code      varchar(32) NOT NULL,
  rule_set_version integer NOT NULL,
  label_set_code   varchar(63) NOT NULL,
  pair_count       integer NOT NULL,
  precision_pct    numeric(6,3) NOT NULL,
  recall_pct       numeric(6,3) NOT NULL,
  verdict          varchar(8) NOT NULL,
  job_id           uuid,
  confusion        jsonb NOT NULL DEFAULT '{}',
  evaluated_at     timestamptz NOT NULL DEFAULT now(),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_evaluation_report PRIMARY KEY (id),
  CONSTRAINT uq_evaluation_report_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_evaluation_report_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_evaluation_report_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_evaluation_report_verdict CHECK (verdict IN ('PASSED', 'FAILED')),
  CONSTRAINT ck_evaluation_report_pct CHECK (precision_pct BETWEEN 0 AND 100 AND recall_pct BETWEEN 0 AND 100 AND pair_count >= 0),
  CONSTRAINT ck_evaluation_report_pass CHECK (verdict <> 'PASSED' OR (pair_count >= 1000 AND precision_pct >= 99.9 AND recall_pct >= 98))
);
CREATE INDEX ix_evaluation_report_rule ON ph06_mdm.evaluation_report (tenant_id, domain_code, rule_set_version, evaluated_at DESC);
CREATE TRIGGER tg_evaluation_report_touch BEFORE UPDATE ON ph06_mdm.evaluation_report FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CALL ph06_mdm.p_enable_rls('ph06_mdm.evaluation_report');
COMMENT ON TABLE ph06_mdm.evaluation_report IS 'FR-06-026 Báo cáo đánh giá chính xác (precision, recall) của một phiên bản bộ quy tắc trên tập nhãn (BR-06-021). Là căn cứ kích hoạt bộ quy tắc; tham chiếu bộ quy tắc theo (domain_code, rule_set_version) để tránh vòng khóa ngoại.';
COMMENT ON COLUMN ph06_mdm.evaluation_report.verdict IS 'PASSED chỉ khi ≥ 1.000 cặp, precision ≥ 99,9%, recall ≥ 98% (BR-06-021).';
--rollback DROP TABLE IF EXISTS ph06_mdm.evaluation_report CASCADE;

--changeset ph06:ph06-0210-match-rule-set
CREATE TABLE ph06_mdm.match_rule_set (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  domain_code          varchar(32) NOT NULL,
  version_no           integer NOT NULL,
  status               varchar(20) NOT NULL DEFAULT 'DRAFT',
  blocking_keys        jsonb NOT NULL DEFAULT '[]',
  auto_merge_threshold numeric(3,2) NOT NULL DEFAULT 0.95,
  review_threshold     numeric(3,2) NOT NULL DEFAULT 0.60,
  auto_merge_enabled   boolean NOT NULL DEFAULT false,
  min_attributes       smallint NOT NULL DEFAULT 3,
  splink_params        jsonb,
  evaluation_report_id uuid,
  submitted_by         varchar(64),
  submitted_at         timestamptz,
  decision             varchar(8),
  decided_by           varchar(64),
  decided_at           timestamptz,
  decision_comment     varchar(2000),
  activated_at         timestamptz,
  superseded_at        timestamptz,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_match_rule_set PRIMARY KEY (id),
  CONSTRAINT uq_match_rule_set_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_match_rule_set_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_match_rule_set_version UNIQUE (tenant_id, domain_code, version_no),
  CONSTRAINT fk_match_rule_set_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT fk_match_rule_set_eval FOREIGN KEY (tenant_id, evaluation_report_id) REFERENCES ph06_mdm.evaluation_report (tenant_id, id),
  CONSTRAINT ck_match_rule_set_status CHECK (status IN ('DRAFT', 'TESTING', 'PENDING_APPROVAL', 'ACTIVE', 'SUPERSEDED', 'REJECTED')),
  CONSTRAINT ck_match_rule_set_decision CHECK (decision IS NULL OR decision IN ('APPROVE', 'REJECT')),
  CONSTRAINT ck_match_rule_set_threshold CHECK (auto_merge_threshold >= 0.90 AND review_threshold >= 0 AND auto_merge_threshold - review_threshold >= 0.10),
  CONSTRAINT ck_match_rule_set_four_eyes CHECK (decided_by IS NULL OR submitted_by IS NULL OR decided_by <> submitted_by),
  CONSTRAINT ck_match_rule_set_active CHECK (status <> 'ACTIVE' OR (evaluation_report_id IS NOT NULL AND decision = 'APPROVE' AND activated_at IS NOT NULL)),
  CONSTRAINT ck_match_rule_set_minattr CHECK (min_attributes BETWEEN 1 AND 20)
);
CREATE UNIQUE INDEX uq_match_rule_set_active ON ph06_mdm.match_rule_set (tenant_id, domain_code) WHERE status = 'ACTIVE';
CREATE TRIGGER tg_match_rule_set_touch BEFORE UPDATE ON ph06_mdm.match_rule_set FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_match_rule_set_immutable BEFORE UPDATE ON ph06_mdm.match_rule_set FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('domain_code', 'version_no');
CREATE TRIGGER tg_match_rule_set_frozen BEFORE UPDATE ON ph06_mdm.match_rule_set FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_frozen('blocking_keys', 'auto_merge_threshold', 'review_threshold', 'min_attributes', 'splink_params');
CALL ph06_mdm.p_enable_rls('ph06_mdm.match_rule_set');
COMMENT ON TABLE ph06_mdm.match_rule_set IS 'EN-06-10 Phiên bản bộ quy tắc đối sánh (FR-06-018, 019, 023). Ngưỡng ba vùng chốt ở CHECK (BR-06-020); ACTIVE phải có báo cáo đánh giá đạt (BR-06-021) và bất biến nội dung (BR-06-017). Duyệt bốn mắt.';
COMMENT ON COLUMN ph06_mdm.match_rule_set.blocking_keys IS 'Biểu thức khóa gom nhóm, ví dụ prefix(nameAscii.given,3)+year(dateOfBirth) (FR-06-019).';
COMMENT ON COLUMN ph06_mdm.match_rule_set.splink_params IS 'Tham số m, u của Splink sau huấn luyện (FR-06-022).';
--rollback DROP TABLE IF EXISTS ph06_mdm.match_rule_set CASCADE;

--changeset ph06:ph06-0220-match-rule
CREATE TABLE ph06_mdm.match_rule (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  domain_code    varchar(32) NOT NULL,
  version_no     integer NOT NULL,
  seq            smallint NOT NULL,
  rule_type      varchar(16) NOT NULL,
  attribute_name varchar(63) NOT NULL,
  comparator     varchar(16) NOT NULL,
  weight         numeric(5,4),
  params         jsonb NOT NULL DEFAULT '{}',
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_match_rule PRIMARY KEY (id),
  CONSTRAINT ck_match_rule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_match_rule_seq UNIQUE (tenant_id, domain_code, version_no, seq),
  CONSTRAINT fk_match_rule_set FOREIGN KEY (tenant_id, domain_code, version_no) REFERENCES ph06_mdm.match_rule_set (tenant_id, domain_code, version_no),
  CONSTRAINT ck_match_rule_type CHECK (rule_type IN ('DETERMINISTIC', 'PROBABILISTIC', 'EXCLUSION')),
  CONSTRAINT ck_match_rule_comparator CHECK (comparator IN ('EXACT', 'TRIGRAM', 'JARO_WINKLER', 'NAME_VN', 'DATE_TOLERANCE', 'ADMIN_UNIT', 'PHONE')),
  CONSTRAINT ck_match_rule_weight CHECK (weight IS NULL OR weight BETWEEN 0 AND 1),
  CONSTRAINT ck_match_rule_prob CHECK (rule_type <> 'PROBABILISTIC' OR weight IS NOT NULL)
);
CREATE TRIGGER tg_match_rule_touch BEFORE UPDATE ON ph06_mdm.match_rule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_match_rule_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON ph06_mdm.match_rule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_child_frozen('match_rule_set');
CALL ph06_mdm.p_enable_rls('ph06_mdm.match_rule');
COMMENT ON TABLE ph06_mdm.match_rule IS 'EN-06-10 Quy tắc con của bộ quy tắc: xác định, xác suất, loại trừ (FR-06-018). Quy tắc EXCLUSION cho khóa định danh khác nhau không tắt được (BR-06-006). Tổng trọng số PROBABILISTIC bằng 1,00 kiểm ở dịch vụ khi gửi duyệt.';
--rollback DROP TABLE IF EXISTS ph06_mdm.match_rule CASCADE;

--changeset ph06:ph06-0230-match-job
CREATE TABLE ph06_mdm.match_job (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  domain_code      varchar(32) NOT NULL DEFAULT '*',
  job_type         varchar(24) NOT NULL,
  status           varchar(24) NOT NULL DEFAULT 'QUEUED',
  scope            varchar(24),
  since            timestamptz,
  train_only       boolean NOT NULL DEFAULT false,
  dry_run          boolean NOT NULL DEFAULT false,
  rule_set_version integer,
  requested_by     varchar(64) NOT NULL,
  parent_job_id    uuid,
  counts           jsonb NOT NULL DEFAULT '{}',
  parameters       jsonb,
  k8s_job_name     varchar(63),
  started_at       timestamptz,
  finished_at      timestamptz,
  confirmed_by     varchar(64),
  confirmed_at     timestamptz,
  cancel_reason    varchar(2000),
  error_code       varchar(16),
  error_detail     varchar(2000),
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_match_job PRIMARY KEY (id),
  CONSTRAINT uq_match_job_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_match_job_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_match_job_domain CHECK (domain_code = '*' OR domain_code ~ '^[A-Z][A-Z0-9_]{1,31}$'),
  CONSTRAINT ck_match_job_type CHECK (job_type IN ('BATCH_MATCH', 'RULE_DRY_RUN', 'ACCURACY_EVAL', 'SURVIVORSHIP_REAPPLY', 'REENCRYPT', 'FILE_INGEST', 'EXPORT', 'NATIONAL_SYNC_DOWN', 'NATIONAL_SYNC_UP', 'NATIONAL_RECONCILE', 'RETENTION_PURGE')),
  CONSTRAINT ck_match_job_status CHECK (status IN ('QUEUED', 'PREPARING', 'RUNNING', 'AWAITING_CONFIRMATION', 'APPLYING', 'SUCCEEDED', 'PARTIALLY_SUCCEEDED', 'FAILED', 'CANCELLED')),
  CONSTRAINT ck_match_job_scope CHECK (scope IS NULL OR scope IN ('GOLDEN_VS_GOLDEN', 'CANDIDATES_SINCE', 'FULL_INITIAL')),
  CONSTRAINT ck_match_job_error CHECK (error_code IS NULL OR error_code ~ '^ERR-06-1[0-9]{2}$'),
  CONSTRAINT ck_match_job_failed CHECK (status <> 'FAILED' OR error_code IS NOT NULL),
  CONSTRAINT ck_match_job_cancel CHECK (status <> 'CANCELLED' OR cancel_reason IS NOT NULL),
  CONSTRAINT ck_match_job_confirm CHECK (confirmed_by IS NULL OR confirmed_by <> requested_by),
  CONSTRAINT ck_match_job_finished CHECK (status NOT IN ('SUCCEEDED', 'PARTIALLY_SUCCEEDED', 'FAILED', 'CANCELLED') OR finished_at IS NOT NULL)
);
CREATE UNIQUE INDEX uq_match_job_running ON ph06_mdm.match_job (tenant_id, domain_code, job_type) WHERE status IN ('QUEUED', 'PREPARING', 'RUNNING', 'AWAITING_CONFIRMATION', 'APPLYING');
CREATE INDEX ix_match_job_list ON ph06_mdm.match_job (tenant_id, created_at DESC);
CREATE TRIGGER tg_match_job_touch BEFORE UPDATE ON ph06_mdm.match_job FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_match_job_immutable BEFORE UPDATE ON ph06_mdm.match_job FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('job_type', 'domain_code', 'requested_by');
CALL ph06_mdm.p_enable_rls('ph06_mdm.match_job');
COMMENT ON TABLE ph06_mdm.match_job IS 'EN-06-12 Job theo lô và job nền (FR-06-022, 056): đối sánh Splink, chạy thử, đánh giá, áp lại sống sót, mã hóa lại, nạp tệp, xuất, đồng bộ quốc gia, dọn lưu giữ. Máy trạng thái 4.5. Một job đang chạy mỗi (domain, loại) (ERR-06-025). Job lô vượt safety-ratio dừng ở AWAITING_CONFIRMATION (BR-06-022).';
COMMENT ON COLUMN ph06_mdm.match_job.confirmed_by IS 'DA xác nhận job vượt ngưỡng an toàn, khác người yêu cầu.';
COMMENT ON COLUMN ph06_mdm.match_job.counts IS 'input, pairs, match, possible, noMatch, applied, skipped (FR-06-022).';
--rollback DROP TABLE IF EXISTS ph06_mdm.match_job CASCADE;

--changeset ph06:ph06-0240-job-schedule
CREATE TABLE ph06_mdm.job_schedule (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  job_type             varchar(24) NOT NULL,
  cron                 varchar(64) NOT NULL,
  enabled              boolean NOT NULL DEFAULT true,
  params               jsonb NOT NULL DEFAULT '{}',
  max_duration_minutes integer NOT NULL DEFAULT 240,
  next_run_at          timestamptz,
  last_run_at          timestamptz,
  last_job_id          uuid,
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_job_schedule PRIMARY KEY (id),
  CONSTRAINT ck_job_schedule_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_job_schedule_type UNIQUE (tenant_id, job_type),
  CONSTRAINT ck_job_schedule_type CHECK (job_type IN ('BATCH_MATCH', 'RULE_DRY_RUN', 'ACCURACY_EVAL', 'SURVIVORSHIP_REAPPLY', 'REENCRYPT', 'FILE_INGEST', 'EXPORT', 'NATIONAL_SYNC_DOWN', 'NATIONAL_SYNC_UP', 'NATIONAL_RECONCILE', 'RETENTION_PURGE')),
  CONSTRAINT ck_job_schedule_duration CHECK (max_duration_minutes BETWEEN 5 AND 1440),
  CONSTRAINT ck_job_schedule_cron CHECK (cron ~ '^[0-9*/,-]+( [0-9*/,?LW#-]+){4,5}$')
);
CREATE TRIGGER tg_job_schedule_touch BEFORE UPDATE ON ph06_mdm.job_schedule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_job_schedule_immutable BEFORE UPDATE ON ph06_mdm.job_schedule FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('job_type');
CALL ph06_mdm.p_enable_rls('ph06_mdm.job_schedule');
COMMENT ON TABLE ph06_mdm.job_schedule IS 'FR-06-056 Lịch job tự động theo loại (cron giờ Việt Nam). Mỗi tenant một dòng cho mỗi JobType; ScheduleJob (ShedLock) đọc next_run_at.';
--rollback DROP TABLE IF EXISTS ph06_mdm.job_schedule CASCADE;

--changeset ph06:ph06-0250-match-staging
CREATE TABLE ph06_mdm.match_staging (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  job_id         uuid NOT NULL,
  candidate_id   uuid,
  golden_id      uuid,
  source_version bigint,
  fields         jsonb NOT NULL,
  block_keys     varchar(72)[] NOT NULL DEFAULT '{}',
  exported_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT pk_match_staging PRIMARY KEY (id),
  CONSTRAINT ck_match_staging_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_match_staging_job FOREIGN KEY (tenant_id, job_id) REFERENCES ph06_mdm.match_job (tenant_id, id) ON DELETE CASCADE,
  CONSTRAINT ck_match_staging_ref CHECK ((candidate_id IS NULL) <> (golden_id IS NULL))
);
CREATE INDEX ix_match_staging_job ON ph06_mdm.match_staging (tenant_id, job_id);
CALL ph06_mdm.p_enable_rls('ph06_mdm.match_staging');
COMMENT ON TABLE ph06_mdm.match_staging IS 'FR-06-022 Bảng trung gian xuất cho Job K8s Splink đọc (SAD: đối sánh lô qua staging). Chỉ chứa trường chuẩn hóa không SENSITIVE và HMAC; xóa sau job (retention 7 ngày, BR-06-031). Job Splink đọc bằng vai trò ph06_readonly, ghi kết quả qua dh-data, không ghi thẳng vào bản ghi vàng.';
COMMENT ON COLUMN ph06_mdm.match_staging.fields IS 'Thuộc tính chuẩn hóa; trường SENSITIVE chỉ dạng HMAC, không bao giờ bản rõ (BR-06-016).';
--rollback DROP TABLE IF EXISTS ph06_mdm.match_staging CASCADE;

--changeset ph06:ph06-0260-match-result
CREATE TABLE ph06_mdm.match_result (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  scored_at            timestamptz NOT NULL DEFAULT now(),
  domain_code          varchar(32) NOT NULL,
  left_candidate_id    uuid,
  left_golden_id       uuid,
  right_golden_id      uuid NOT NULL,
  method               varchar(24) NOT NULL,
  outcome              varchar(16) NOT NULL,
  score                numeric(5,4),
  attribute_scores     jsonb NOT NULL DEFAULT '{}',
  rule_set_version     integer,
  job_id               uuid,
  queue_item_id        uuid,
  applied              boolean NOT NULL DEFAULT false,
  applied_operation_id uuid,
  skip_code            varchar(16),
  CONSTRAINT pk_match_result PRIMARY KEY (id, scored_at),
  CONSTRAINT ck_match_result_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT ck_match_result_method CHECK (method IN ('DETERMINISTIC', 'PROBABILISTIC_ONLINE', 'PROBABILISTIC_BATCH', 'MANUAL', 'NATIONAL_SYNC')),
  CONSTRAINT ck_match_result_outcome CHECK (outcome IN ('MATCH', 'POSSIBLE_MATCH', 'NO_MATCH', 'CONFLICT')),
  CONSTRAINT ck_match_result_left CHECK ((left_candidate_id IS NULL) <> (left_golden_id IS NULL)),
  CONSTRAINT ck_match_result_score CHECK (score IS NULL OR score BETWEEN 0 AND 1),
  CONSTRAINT ck_match_result_skip CHECK (skip_code IS NULL OR skip_code = 'ERR-06-104'),
  CONSTRAINT ck_match_result_deterministic CHECK (method <> 'DETERMINISTIC' OR score = 1)
) PARTITION BY RANGE (scored_at);
CALL ph06_mdm.p_ensure_partitions('ph06_mdm.match_result', current_date, 3);
CREATE INDEX ix_match_result_candidate ON ph06_mdm.match_result (tenant_id, left_candidate_id) WHERE left_candidate_id IS NOT NULL;
CREATE INDEX ix_match_result_golden ON ph06_mdm.match_result (tenant_id, right_golden_id, scored_at DESC);
CREATE INDEX ix_match_result_job ON ph06_mdm.match_result (tenant_id, job_id) WHERE job_id IS NOT NULL;
CALL ph06_mdm.p_enable_rls('ph06_mdm.match_result');
COMMENT ON TABLE ph06_mdm.match_result IS 'EN-06-11 Kết quả đối sánh một cặp (ứng viên hoặc bản ghi vàng với bản ghi vàng) (FR-06-020…023). Lưu điểm từng thuộc tính theo ComparisonLevel để giải thích. Phân vùng tháng theo scored_at; giữ 2 năm để hiệu chỉnh thuật toán (SRS cũ 4.3).';
--rollback DROP TABLE IF EXISTS ph06_mdm.match_result CASCADE;

--changeset ph06:ph06-0270-label-set
CREATE TABLE ph06_mdm.label_set (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  label_set_code varchar(63) NOT NULL,
  domain_code    varchar(32) NOT NULL,
  purpose        varchar(16) NOT NULL,
  description    varchar(2000),
  pair_count     integer NOT NULL DEFAULT 0,
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_label_set PRIMARY KEY (id),
  CONSTRAINT uq_label_set_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_label_set_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_label_set_code UNIQUE (tenant_id, label_set_code),
  CONSTRAINT fk_label_set_domain FOREIGN KEY (tenant_id, domain_code) REFERENCES ph06_mdm.mdm_domain (tenant_id, domain_code),
  CONSTRAINT ck_label_set_code CHECK (label_set_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_label_set_purpose CHECK (purpose IN ('EVALUATION', 'TRAINING')),
  CONSTRAINT ck_label_set_count CHECK (pair_count >= 0)
);
CREATE TRIGGER tg_label_set_touch BEFORE UPDATE ON ph06_mdm.label_set FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_label_set_immutable BEFORE UPDATE ON ph06_mdm.label_set FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('label_set_code', 'domain_code', 'purpose');
CALL ph06_mdm.p_enable_rls('ph06_mdm.label_set');
COMMENT ON TABLE ph06_mdm.label_set IS 'EN-06-15 Tập nhãn kiểm chứng (FR-06-025): EVALUATION để đo precision, recall; TRAINING để huấn luyện Splink. Nghiệm thu cần ≥ 10.000 cặp (NFR-06-008).';
--rollback DROP TABLE IF EXISTS ph06_mdm.label_set CASCADE;

--changeset ph06:ph06-0280-label-pair
CREATE TABLE ph06_mdm.label_pair (
  id             uuid NOT NULL,
  tenant_id      varchar(16) NOT NULL,
  label_set_id   uuid NOT NULL,
  left_id        uuid NOT NULL,
  right_id       uuid NOT NULL,
  label          varchar(8) NOT NULL,
  labeled_by     varchar(64) NOT NULL,
  source_item_id uuid,
  snapshot_enc   bytea,
  snapshot_kid   varchar(64),
  created_at     timestamptz NOT NULL DEFAULT now(),
  created_by     varchar(64) NOT NULL,
  updated_at     timestamptz NOT NULL DEFAULT now(),
  updated_by     varchar(64) NOT NULL,
  version        integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_label_pair PRIMARY KEY (id),
  CONSTRAINT ck_label_pair_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_label_pair UNIQUE (tenant_id, label_set_id, left_id, right_id),
  CONSTRAINT fk_label_pair_set FOREIGN KEY (tenant_id, label_set_id) REFERENCES ph06_mdm.label_set (tenant_id, id),
  CONSTRAINT ck_label_pair_label CHECK (label IN ('MATCH', 'NO_MATCH')),
  CONSTRAINT ck_label_pair_order CHECK (left_id < right_id),
  CONSTRAINT ck_label_pair_snapshot CHECK (snapshot_enc IS NULL OR snapshot_kid IS NOT NULL)
);
CREATE TRIGGER tg_label_pair_touch BEFORE UPDATE ON ph06_mdm.label_pair FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_touch();
CREATE TRIGGER tg_label_pair_immutable BEFORE UPDATE ON ph06_mdm.label_pair FOR EACH ROW EXECUTE FUNCTION ph06_mdm.tg_immutable('label_set_id', 'left_id', 'right_id');
CALL ph06_mdm.p_enable_rls('ph06_mdm.label_pair');
COMMENT ON TABLE ph06_mdm.label_pair IS 'EN-06-15 Cặp có nhãn MATCH, NO_MATCH của tập nhãn (FR-06-025, 030 addToLabelSet). Hai đầu theo thứ tự chuẩn left_id < right_id; ảnh chụp thuộc tính hai bên mã hóa để đánh giá lặp lại ổn định.';
--rollback DROP TABLE IF EXISTS ph06_mdm.label_pair CASCADE;
