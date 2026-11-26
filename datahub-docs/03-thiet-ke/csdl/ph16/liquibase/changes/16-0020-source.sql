--liquibase formatted sql
-- Nguồn: ddl/ph16_kpi.sql · 16-0020-source.sql
-- TỆP SINH TỰ ĐỘNG bởi tools/gen_liquibase.py. Không sửa tay.

--changeset ph16:ph16-0200-fn-observation-ref splitStatements:false
-- Duy nhất idempotency_ref theo (tenant, nguồn) trên bảng phân vùng: chỉ mục duy nhất phải kèm cột phân vùng period_start, nên trigger chặn cùng mã tham chiếu ở kỳ khác.
CREATE OR REPLACE FUNCTION ph16_kpi.f_observation_ref() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF EXISTS (SELECT 1 FROM ph16_kpi.kpi_observation
              WHERE tenant_id = NEW.tenant_id AND source_id = NEW.source_id AND idempotency_ref = NEW.idempotency_ref AND period_start <> NEW.period_start) THEN
    RAISE EXCEPTION 'idempotency_ref % của nguồn đã dùng cho kỳ khác', NEW.idempotency_ref USING ERRCODE = '23505';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.f_observation_ref() IS 'Bổ sung cho chỉ mục duy nhất (tenant_id, source_id, idempotency_ref, period_start): cùng mã tham chiếu không được xuất hiện ở hai kỳ.';
--rollback DROP FUNCTION IF EXISTS ph16_kpi.f_observation_ref();

--changeset ph16:ph16-0140-kpi-data-source
CREATE TABLE ph16_kpi.kpi_data_source (
  id                   uuid NOT NULL,
  tenant_id            varchar(16) NOT NULL,
  source_code          varchar(63) NOT NULL,
  name                 varchar(255) NOT NULL,
  source_type          varchar(8) NOT NULL,
  state                varchar(8) NOT NULL DEFAULT 'ACTIVE',
  state_reason         varchar(2000),
  owner_phase          varchar(5),
  topic_pattern        varchar(255),
  api_ref              varchar(255),
  schedule_cron        varchar(64),
  stale_after_hours    smallint,
  consecutive_failures integer NOT NULL DEFAULT 0,
  last_attempt_at      timestamptz,
  last_success_at      timestamptz,
  last_error_code      varchar(11),
  description          varchar(2000),
  created_at           timestamptz NOT NULL DEFAULT now(),
  created_by           varchar(64) NOT NULL,
  updated_at           timestamptz NOT NULL DEFAULT now(),
  updated_by           varchar(64) NOT NULL,
  version              integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_data_source PRIMARY KEY (id),
  CONSTRAINT uq_kpi_data_source_tid UNIQUE (tenant_id, id),
  CONSTRAINT ck_kpi_data_source_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_data_source_code UNIQUE (tenant_id, source_code),
  CONSTRAINT ck_kpi_data_source_code CHECK (source_code ~ '^[a-z][a-z0-9-]{2,62}$'),
  CONSTRAINT ck_kpi_data_source_type CHECK (source_type IN ('EVENT', 'PULL_API', 'PUSH_API', 'MANUAL')),
  CONSTRAINT ck_kpi_data_source_state CHECK (state IN ('ACTIVE', 'STALE', 'FAILED', 'PAUSED', 'RETIRED')),
  CONSTRAINT ck_kpi_data_source_phase CHECK (owner_phase IS NULL OR owner_phase ~ '^PH-[0-9]{2}$'),
  CONSTRAINT ck_kpi_data_source_event CHECK (source_type <> 'EVENT' OR topic_pattern IS NOT NULL),
  CONSTRAINT ck_kpi_data_source_topic CHECK (topic_pattern IS NULL OR topic_pattern ~ '^\{tenant\}\.[a-z0-9.*-]+$'),
  CONSTRAINT ck_kpi_data_source_pull CHECK (source_type <> 'PULL_API' OR (api_ref IS NOT NULL AND schedule_cron IS NOT NULL)),
  CONSTRAINT ck_kpi_data_source_stale CHECK (stale_after_hours IS NULL OR stale_after_hours BETWEEN 1 AND 744),
  CONSTRAINT ck_kpi_data_source_failures CHECK (consecutive_failures >= 0),
  CONSTRAINT ck_kpi_data_source_error CHECK (last_error_code IS NULL OR last_error_code ~ '^ERR-16-[0-9]{3}$'),
  CONSTRAINT ck_kpi_data_source_reason CHECK (state NOT IN ('PAUSED', 'RETIRED') OR COALESCE(char_length(state_reason) >= 20, false))
);
CREATE INDEX ix_kpi_data_source_state ON ph16_kpi.kpi_data_source (tenant_id, state, source_type);
CREATE TRIGGER tg_kpi_data_source_touch BEFORE UPDATE ON ph16_kpi.kpi_data_source FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_data_source_immutable BEFORE UPDATE ON ph16_kpi.kpi_data_source FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'source_code', 'source_type');
CREATE TRIGGER tg_kpi_data_source_transition BEFORE UPDATE ON ph16_kpi.kpi_data_source FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('state', '{"ACTIVE":["STALE","FAILED","PAUSED"],"STALE":["ACTIVE","FAILED","PAUSED"],"FAILED":["ACTIVE","PAUSED"],"PAUSED":["ACTIVE","RETIRED"]}');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_data_source');
COMMENT ON TABLE ph16_kpi.kpi_data_source IS 'EN-16-06 Nguồn số liệu: phân hệ hoặc kênh cung cấp quan sát, bốn loại EVENT (Kafka), PULL_API (kéo API chỉ số theo lịch), PUSH_API (scope `kpi.ingest`), MANUAL; theo dõi độ tươi và số lần kéo lỗi liên tiếp (FR-16-009, 013). Không xóa, chỉ tạm dừng hoặc ngừng.';
COMMENT ON COLUMN ph16_kpi.kpi_data_source.stale_after_hours IS 'NULL thì lấy tham số 16.source.stale-hours (mặc định 26 giờ); quá hạn chuyển STALE.';
COMMENT ON COLUMN ph16_kpi.kpi_data_source.consecutive_failures IS 'Số lần kéo lỗi liên tiếp; đạt 16.source.fail-after (mặc định 3) thì chuyển FAILED và phát EVT-16-03.';
COMMENT ON COLUMN ph16_kpi.kpi_data_source.topic_pattern IS 'Mẫu topic Kafka dạng `{tenant}.dq.kpi.published.v1`.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_data_source CASCADE;

--changeset ph16:ph16-0150-kpi-source-contract
CREATE TABLE ph16_kpi.kpi_source_contract (
  id               uuid NOT NULL,
  tenant_id        varchar(16) NOT NULL,
  source_id        uuid NOT NULL,
  metric_code      varchar(128) NOT NULL,
  kind             varchar(10) NOT NULL,
  unit             varchar(32) NOT NULL,
  dimension_schema jsonb NOT NULL DEFAULT '{}',
  schema_version   varchar(16) NOT NULL DEFAULT '1',
  period_type      varchar(8),
  required         boolean NOT NULL DEFAULT true,
  state            varchar(8) NOT NULL DEFAULT 'ACTIVE',
  created_at       timestamptz NOT NULL DEFAULT now(),
  created_by       varchar(64) NOT NULL,
  updated_at       timestamptz NOT NULL DEFAULT now(),
  updated_by       varchar(64) NOT NULL,
  version          integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_source_contract PRIMARY KEY (id),
  CONSTRAINT ck_kpi_source_contract_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT uq_kpi_source_contract UNIQUE (tenant_id, source_id, metric_code, schema_version),
  CONSTRAINT fk_kpi_source_contract_source FOREIGN KEY (tenant_id, source_id) REFERENCES ph16_kpi.kpi_data_source (tenant_id, id),
  CONSTRAINT ck_kpi_source_contract_metric CHECK (metric_code ~ '^ph[0-9]{2}\.[a-z][a-z0-9-]*\.[a-z][a-z0-9-]*$'),
  CONSTRAINT ck_kpi_source_contract_kind CHECK (kind IN ('RATIO', 'COUNT', 'DURATION', 'SCORE', 'BOOLEAN')),
  CONSTRAINT ck_kpi_source_contract_schema_version CHECK (schema_version ~ '^[0-9]+(\.[0-9]+)*$'),
  CONSTRAINT ck_kpi_source_contract_period CHECK (period_type IS NULL OR period_type IN ('MONTH', 'QUARTER', 'YEAR')),
  CONSTRAINT ck_kpi_source_contract_state CHECK (state IN ('ACTIVE', 'RETIRED'))
);
CREATE INDEX ix_kpi_source_contract_metric ON ph16_kpi.kpi_source_contract (tenant_id, metric_code, state);
CREATE TRIGGER tg_kpi_source_contract_touch BEFORE UPDATE ON ph16_kpi.kpi_source_contract FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_source_contract_immutable BEFORE UPDATE ON ph16_kpi.kpi_source_contract FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'source_id', 'metric_code', 'schema_version');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_source_contract');
COMMENT ON TABLE ph16_kpi.kpi_source_contract IS 'EN-16-05, EN-16-07 Hợp đồng chỉ số của nguồn: mỗi dòng là một `metric_code` dạng `ph{nn}.{đối-tượng}.{chỉ-số}` nguồn cam kết cung cấp, kiểu giá trị, đơn vị, chiều phân tách, phiên bản lược đồ (`kpiSchemaVersion`) và kỳ mong đợi (FR-16-009). Quan sát có `metric_code` ngoài hợp đồng bị loại.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_source_contract CASCADE;

--changeset ph16:ph16-0160-kpi-observation
CREATE TABLE ph16_kpi.kpi_observation (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  source_id       uuid NOT NULL,
  metric_code     varchar(128) NOT NULL,
  value           numeric(24,6) NOT NULL,
  unit            varchar(32),
  period_start    timestamptz NOT NULL,
  period_end      timestamptz NOT NULL,
  dimensions      jsonb NOT NULL DEFAULT '{}',
  source_ref      varchar(255),
  idempotency_ref varchar(128) NOT NULL,
  schema_version  varchar(16),
  channel         varchar(8) NOT NULL,
  late            boolean NOT NULL DEFAULT false,
  received_at     timestamptz NOT NULL DEFAULT now(),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_observation PRIMARY KEY (id, period_start),
  CONSTRAINT ck_kpi_observation_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_kpi_observation_source FOREIGN KEY (tenant_id, source_id) REFERENCES ph16_kpi.kpi_data_source (tenant_id, id),
  CONSTRAINT ck_kpi_observation_metric CHECK (metric_code ~ '^ph[0-9]{2}\.[a-z][a-z0-9-]*\.[a-z][a-z0-9-]*$'),
  CONSTRAINT ck_kpi_observation_period CHECK (period_end > period_start),
  CONSTRAINT ck_kpi_observation_idem CHECK (idempotency_ref ~ '^[A-Za-z0-9._:-]{1,128}$'),
  CONSTRAINT ck_kpi_observation_channel CHECK (channel IN ('EVENT', 'PULL_API', 'PUSH_API')),
  CONSTRAINT ck_kpi_observation_dimensions CHECK (jsonb_typeof(dimensions) = 'object')
) PARTITION BY RANGE (period_start);
CALL ph16_kpi.p_ensure_partitions('ph16_kpi.kpi_observation', date '2026-01-01', 24);
CREATE UNIQUE INDEX uq_kpi_observation_idem ON ph16_kpi.kpi_observation (tenant_id, source_id, idempotency_ref, period_start);
CREATE INDEX ix_kpi_observation_metric ON ph16_kpi.kpi_observation (tenant_id, metric_code, period_start DESC);
CREATE INDEX ix_kpi_observation_source ON ph16_kpi.kpi_observation (tenant_id, source_id, received_at DESC);
CREATE TRIGGER tg_kpi_observation_touch BEFORE UPDATE ON ph16_kpi.kpi_observation FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_observation_append_only BEFORE UPDATE OR DELETE ON ph16_kpi.kpi_observation FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_append_only();
CREATE TRIGGER tg_kpi_observation_ref BEFORE INSERT ON ph16_kpi.kpi_observation FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_observation_ref();
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_observation');
COMMENT ON TABLE ph16_kpi.kpi_observation IS 'EN-16-08 Quan sát: số liệu đã tổng hợp nhận từ phân hệ nguồn qua sự kiện, API kéo hoặc API đẩy, đã chuẩn hóa (FR-16-010, 011, 012). Chỉ thêm. Phân vùng tháng theo `period_start` (giờ Việt Nam). Idempotent: `idempotency_ref` (mã sự kiện hoặc `snapshotId`) duy nhất theo tenant và nguồn, nhận lại bản trùng không tạo dòng mới.';
COMMENT ON COLUMN ph16_kpi.kpi_observation.idempotency_ref IS 'Mã sự kiện (EVT-xx-yy) hoặc `snapshotId`; ERR-16-1xx khi trùng mã nhưng khác kỳ (trigger `tg_kpi_observation_ref`).';
COMMENT ON COLUMN ph16_kpi.kpi_observation.period_start IS 'Khóa phân vùng, tháng theo giờ Việt Nam; PartitionMaintenanceJob tạo trước phân vùng.';
COMMENT ON COLUMN ph16_kpi.kpi_observation.dimensions IS 'Chiều phân tách (tỉnh, loại HTTT…) dạng đối tượng JSON; không chứa dữ liệu cá nhân.';
COMMENT ON COLUMN ph16_kpi.kpi_observation.late IS 'Quan sát đến sau khi kỳ COLLECTING kết thúc; kích hoạt tính lại LATE_DATA khi 16.late-data.recompute bật.';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_observation CASCADE;

--changeset ph16:ph16-0170-kpi-ingest-log
CREATE TABLE ph16_kpi.kpi_ingest_log (
  id              uuid NOT NULL,
  tenant_id       varchar(16) NOT NULL,
  source_id       uuid NOT NULL,
  channel         varchar(8) NOT NULL,
  outcome         varchar(11) NOT NULL,
  metric_code     varchar(128),
  idempotency_ref varchar(128),
  payload_hash    bytea,
  payload         jsonb,
  reject_code     varchar(11),
  detail          varchar(2000),
  observation_id  uuid,
  received_at     timestamptz NOT NULL DEFAULT now(),
  reprocessed_at  timestamptz,
  reprocessed_by  varchar(64),
  created_at      timestamptz NOT NULL DEFAULT now(),
  created_by      varchar(64) NOT NULL,
  updated_at      timestamptz NOT NULL DEFAULT now(),
  updated_by      varchar(64) NOT NULL,
  version         integer NOT NULL DEFAULT 0,
  CONSTRAINT pk_kpi_ingest_log PRIMARY KEY (id, received_at),
  CONSTRAINT ck_kpi_ingest_log_tenant CHECK (tenant_id ~ '^T[0-9]{2}$'),
  CONSTRAINT fk_kpi_ingest_log_source FOREIGN KEY (tenant_id, source_id) REFERENCES ph16_kpi.kpi_data_source (tenant_id, id),
  CONSTRAINT ck_kpi_ingest_log_channel CHECK (channel IN ('EVENT', 'PULL_API', 'PUSH_API')),
  CONSTRAINT ck_kpi_ingest_log_outcome CHECK (outcome IN ('ACCEPTED', 'DUPLICATE', 'REJECTED', 'REPROCESSED')),
  CONSTRAINT ck_kpi_ingest_log_hash CHECK (payload_hash IS NULL OR octet_length(payload_hash) = 32),
  CONSTRAINT ck_kpi_ingest_log_reject CHECK (reject_code IS NULL OR reject_code ~ '^ERR-16-1[0-9]{2}$'),
  CONSTRAINT ck_kpi_ingest_log_rejected CHECK ((outcome IN ('REJECTED', 'REPROCESSED')) = (reject_code IS NOT NULL) AND (outcome <> 'REJECTED' OR payload IS NOT NULL)),
  CONSTRAINT ck_kpi_ingest_log_payload CHECK (payload IS NULL OR octet_length(payload::text) <= 65536),
  CONSTRAINT ck_kpi_ingest_log_accepted CHECK (outcome NOT IN ('ACCEPTED', 'REPROCESSED') OR observation_id IS NOT NULL),
  CONSTRAINT ck_kpi_ingest_log_reprocessed CHECK (outcome <> 'REPROCESSED' OR (reprocessed_at IS NOT NULL AND reprocessed_by IS NOT NULL))
) PARTITION BY RANGE (received_at);
CALL ph16_kpi.p_ensure_partitions('ph16_kpi.kpi_ingest_log', date '2026-01-01', 24);
CREATE INDEX ix_kpi_ingest_log_source ON ph16_kpi.kpi_ingest_log (tenant_id, source_id, received_at DESC);
CREATE INDEX ix_kpi_ingest_log_rejected ON ph16_kpi.kpi_ingest_log (tenant_id, received_at DESC) WHERE outcome = 'REJECTED';
CREATE INDEX ix_kpi_ingest_log_ref ON ph16_kpi.kpi_ingest_log (tenant_id, source_id, idempotency_ref);
CREATE TRIGGER tg_kpi_ingest_log_touch BEFORE UPDATE ON ph16_kpi.kpi_ingest_log FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_touch();
CREATE TRIGGER tg_kpi_ingest_log_immutable BEFORE UPDATE ON ph16_kpi.kpi_ingest_log FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_immutable('tenant_id', 'source_id', 'channel', 'metric_code', 'idempotency_ref', 'payload_hash', 'payload', 'reject_code', 'received_at');
CREATE TRIGGER tg_kpi_ingest_log_transition BEFORE UPDATE ON ph16_kpi.kpi_ingest_log FOR EACH ROW EXECUTE FUNCTION ph16_kpi.tg_transition('outcome', '{"REJECTED":["REPROCESSED"]}');
CALL ph16_kpi.p_enable_rls('ph16_kpi.kpi_ingest_log');
COMMENT ON TABLE ph16_kpi.kpi_ingest_log IS 'EN-16-09, EN-16-10 Nhật ký tiếp nhận và loại bỏ: mỗi lần nhận quan sát ghi kết quả ACCEPTED, DUPLICATE hoặc REJECTED kèm mã lỗi ERR-16-101…199 và băm thân yêu cầu; bản tin bị loại xử lý lại đạt thì chuyển REPROCESSED, giữ mã lỗi cũ làm lịch sử (FR-16-010, 016). Phân vùng tháng theo `received_at`.';
COMMENT ON COLUMN ph16_kpi.kpi_ingest_log.payload_hash IS 'SHA-256 của thân yêu cầu (32 byte).';
COMMENT ON COLUMN ph16_kpi.kpi_ingest_log.payload IS 'Bản tin quan sát đã tổng hợp, chỉ giữ với dòng REJECTED (tối đa 64 KB) để xử lý lại sau khi sửa hợp đồng; không chứa bản ghi giao dịch hay dữ liệu cá nhân (BR-16-028).';
--rollback DROP TABLE IF EXISTS ph16_kpi.kpi_ingest_log CASCADE;
