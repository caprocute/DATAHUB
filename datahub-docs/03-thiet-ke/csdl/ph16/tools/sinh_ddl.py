#!/usr/bin/env python3
"""Sinh ddl/ph16_kpi.sql (schema ph16_kpi, D03-03-PH16) từ danh mục bảng khai báo ở tệp này (khung chép từ ph08/tools/sinh_ddl.py).

Chạy từ thư mục csdl/ph16:  python3 tools/sinh_ddl.py
Enum lấy từ brief PH-16 §4, trùng Phụ lục A và mục 4 của FRS PH-16 (chỉ được thêm, không đổi tên); đổi enum thì sửa ở dict ENUM.
Kết quả có dấu @file, @changeset, @rollback để tools/gen_liquibase.py sinh changelog. DDL là nguồn chuẩn cho dung_md.py;
không sửa tay tệp sinh ra, sửa ở đây rồi sinh lại.
Tệp này gồm khung và bảng nhóm chỉ tiêu, nguồn, kỳ; sinh_ddl_b.py gồm báo cáo, sổ kiến trúc, gửi quốc gia, vận hành.
"""
import os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S = "ph16_kpi"

ENUM = {
    "group_code": "KET_NOI CHIA_SE DU_LIEU VAN_HANH KIEN_TRUC",
    "kind": "RATIO COUNT DURATION SCORE BOOLEAN",
    "direction": "HIGHER_BETTER LOWER_BETTER TARGET_RANGE",
    "measurement": "AUTO MANUAL MIXED",
    "aggregation": "LAST SUM AVG P95 MAX MIN",
    "ind_scope": "TENANT COMMON",
    "ind_state": "DRAFT ACTIVE RETIRED",
    "version_state": "DRAFT PENDING_APPROVAL CHANGES_REQUESTED ACTIVE SUPERSEDED RETIRED",
    "level": "GREEN AMBER RED",
    "value_status": "ON_TRACK AT_RISK OFF_TRACK NO_DATA",
    "completeness": "COMPLETE PARTIAL NO_DATA",
    "trend": "UP DOWN FLAT",
    "source_type": "EVENT PULL_API PUSH_API MANUAL",
    "source_state": "ACTIVE STALE FAILED PAUSED RETIRED",
        "ingest_outcome": "ACCEPTED DUPLICATE REJECTED REPROCESSED",
    "contract_state": "ACTIVE RETIRED",
    "manual_state": "DRAFT SUBMITTED ACCEPTED REJECTED",
    "evidence_type": "FILE DOCUMENT_NUMBER",
    "period_type": "MONTH QUARTER YEAR",
    "period_state": "OPEN COLLECTING COMPUTED CLOSED REOPENED",
    "run_state": "QUEUED RUNNING SUCCEEDED PARTIAL FAILED CANCELLED",
    "run_trigger": "SCHEDULE MANUAL RECOMPUTE LATE_DATA",
    "lineage_kind": "OBSERVATION MANUAL_VALUE INDICATOR PERIOD_VALUE",
    "report_type": "PERIODIC AD_HOC NATIONAL",
    "report_state": "DRAFT IN_REVIEW APPROVED PUBLISHED CHANGES_REQUESTED SUPERSEDED WITHDRAWN",
    "section": "SUMMARY GROUP INDICATOR_TABLE CHART NARRATIVE ANNEX",
    "format": "PDF XLSX CSV JSON",
    "template_state": "DRAFT ACTIVE RETIRED",
    "approval_action": "SUBMIT REQUEST_CHANGES APPROVE PUBLISH WITHDRAW CORRECT",
    "export_state": "QUEUED RUNNING SUCCEEDED FAILED EXPIRED",
    "export_subject": "REPORT INDICATOR_VALUES OBSERVATIONS ARCH_REGISTRY ARCH_GRAPH",
    "delivery_state": "PENDING SENT FAILED",
    "recipient_type": "USER GROUP EMAIL",
    "component_type": "HTTT API FLOW TOPIC ADAPTER PLATFORM_SERVICE NATIONAL_LINK",
    "lifecycle": "PLANNED ACTIVE DEPRECATED RETIRED",
    "ops_status": "UP DEGRADED DOWN UNKNOWN",
    "origin": "AUTO MANUAL",
    "compliance_level": "NOT_ASSESSED COMPLIANT PARTIAL NON_COMPLIANT EXEMPTED",
    "assessment_state": "DRAFT SUBMITTED CONFIRMED REJECTED",
    "item_result": "PASS FAIL NA",
    "criteria_state": "DRAFT ACTIVE SUPERSEDED",
    "national_template_state": "DRAFT ACTIVE SUPERSEDED",
    "recon_state": "RUNNING SUCCEEDED PARTIAL FAILED",
    "recon_item_kind": "MISSING ORPHAN MISMATCH",
    "recon_resolution": "OPEN REGISTERED RETIRED UPDATED IGNORED",
    "import_row_status": "VALID INVALID IMPORTED",
    "dep_type": "CALLS PUBLISHES SUBSCRIBES HOSTS DEPENDS_ON",
    "waiver_state": "PENDING_APPROVAL ACTIVE EXPIRED REVOKED REJECTED",
    "submission_type": "KPI_REPORT ARCH_REGISTRY",
    "submission_state": "PENDING SENDING SENT ACKNOWLEDGED REJECTED FAILED",
    "submission_event": "CREATED SENDING SENT ACKNOWLEDGED REJECTED FAILED RETRY",
}
FLAGS = "MISSING_SOURCE STALE_SOURCE MANUAL_PENDING FORMULA_ERROR"


def E(name, skip=()):
    return "(" + ", ".join("'%s'" % x for x in ENUM[name].split() if x not in skip) + ")"


def ARR(name):
    return "ARRAY[" + ", ".join("'%s'" % x for x in ENUM[name].split()) + "]::text[]"


TENANT_RE = "^T[0-9]{2}$"
TCODE_RE = "^[a-z][a-z0-9-]{2,62}$"
METRIC_RE = r"^ph[0-9]{2}\.[a-z][a-z0-9-]*\.[a-z][a-z0-9-]*$"
PHASE_RE = "^PH-[0-9]{2}$"
ORG_RE = "^[A-Za-z0-9][A-Za-z0-9._-]{1,62}$"
FILE_GROUPS = []
PRE = {}


def T(name, comment, cols, cons=(), idx=(), part=None, std=True, tid=False, trig=(), pk=None, ccomment=None, rls="P", nopk=False):
    return dict(name=name, comment=comment, cols=cols, cons=list(cons), idx=list(idx), part=part, std=std, tid=tid,
                trig=list(trig), pk=pk, cc=ccomment or {}, rls=rls, nopk=nopk)


def chk(table, what, expr):
    return (f"ck_{table}_{what}", f"CHECK ({expr})")


def four_eyes(a, b):
    return f"{a} IS NULL OR {b} IS NULL OR {a} <> {b}"


def fk(table, name, cols, ref, rcols=None, extra=""):
    rcols = rcols or cols
    return (f"fk_{table}_{name}", f"FOREIGN KEY ({cols}) REFERENCES {S}.{ref} ({rcols}){extra}")


def reason20(c):
    return f"char_length({c}) >= 20"


def reason50(c):
    return f"char_length({c}) >= 50"


def ix(name, table, cols, where=None, unique=False, using=None):
    return f"CREATE {'UNIQUE ' if unique else ''}INDEX {name} ON {S}.{table}{' USING ' + using if using else ''} ({cols})" + (f" WHERE {where}" if where else "") + ";"


H32 = lambda c: f"{c} IS NULL OR octet_length({c}) = 32"
ERRC = lambda c: f"{c} IS NULL OR {c} ~ '^ERR-16-[0-9]{{3}}$'"


def tmap(m):
    import json
    return json.dumps(m, ensure_ascii=False, separators=(",", ":"))


# ---------------------------------------------------------------------------------------------
# 16-0010 Nhóm chỉ tiêu, chỉ tiêu, phiên bản định nghĩa, ngưỡng
# ---------------------------------------------------------------------------------------------
VERSION_MAP = {"DRAFT": ["PENDING_APPROVAL"], "PENDING_APPROVAL": ["ACTIVE", "CHANGES_REQUESTED", "DRAFT"],
               "CHANGES_REQUESTED": ["DRAFT"], "ACTIVE": ["SUPERSEDED", "RETIRED"]}
G_IND = [
    T("kpi_indicator_group",
      "EN-16-01 Nhóm chỉ tiêu: năm nhóm KET_NOI, CHIA_SE, DU_LIEU, VAN_HANH, KIEN_TRUC kế thừa năm nhóm KPI của SRS cũ, có trọng số tính điểm nhóm (FR-16-007). Dòng tenant COMMON do PLATFORM quản, mọi tenant đọc được (mẫu RLS S); tenant nhận bản sao khi khởi tạo.",
      ["group_code varchar(16) NOT NULL", "name varchar(255) NOT NULL", "description varchar(2000)", "weight numeric(5,2) NOT NULL DEFAULT 20.00",
       "display_order smallint NOT NULL DEFAULT 0", "enabled boolean NOT NULL DEFAULT true"],
      [("uq_kpi_indicator_group_code", "UNIQUE (tenant_id, group_code)"),
       chk("kpi_indicator_group", "code", f"group_code IN {E('group_code')}"),
       chk("kpi_indicator_group", "weight", "weight >= 0 AND weight <= 100")],
      rls="S", trig=[("immutable", ["tenant_id", "group_code"])],
      ccomment={"tenant_id": "Dạng Tnn hoặc COMMON (bộ mẫu dùng chung).", "weight": "Trọng số điểm nhóm thang 0…100; tổng trọng số các nhóm đang bật bằng 100 do dịch vụ kiểm (BR-16-016, ERR-16-012, FR-16-007)."}),
    T("kpi_indicator",
      "EN-16-02, EN-16-38 Chỉ tiêu: mã T-CODE, nhóm, loại giá trị, chiều tốt, cách đo, đơn vị, cách gộp qua kỳ, cờ bắt buộc cho báo cáo chính thức (FR-16-001, 002, 006, 008). Phạm vi COMMON là chỉ tiêu mẫu toàn quốc do PLATFORM quản, tenant kế thừa bằng bản sao ghi `template_code` (không khóa ngoại). Không xóa, chỉ ngừng hoặc thay thế.",
      ["indicator_code varchar(63) NOT NULL", "group_code varchar(16) NOT NULL", "name varchar(255) NOT NULL", "description varchar(2000)",
       "kind varchar(10) NOT NULL", "direction varchar(14) NOT NULL", "measurement varchar(8) NOT NULL", "unit varchar(32) NOT NULL",
       "aggregation varchar(8) NOT NULL DEFAULT 'LAST'", "scope varchar(8) NOT NULL DEFAULT 'TENANT'", "mandatory boolean NOT NULL DEFAULT false",
       "brd_ref varchar(8)", "template_code varchar(63)", "state varchar(8) NOT NULL DEFAULT 'DRAFT'", "state_reason varchar(2000)",
       "replaced_by_code varchar(63)", "template_version_no integer", "template_dismissed_version_no integer", "display_order smallint NOT NULL DEFAULT 0"],
      [("uq_kpi_indicator_code", "UNIQUE (tenant_id, indicator_code)"),
       fk("kpi_indicator", "group", "tenant_id, group_code", "kpi_indicator_group"),
       chk("kpi_indicator", "code", f"indicator_code ~ '{TCODE_RE}'"),
       chk("kpi_indicator", "kind", f"kind IN {E('kind')}"),
       chk("kpi_indicator", "direction", f"direction IN {E('direction')}"),
       chk("kpi_indicator", "measurement", f"measurement IN {E('measurement')}"),
       chk("kpi_indicator", "aggregation", f"aggregation IN {E('aggregation')}"),
       chk("kpi_indicator", "scope", f"scope IN {E('ind_scope')} AND (scope = 'COMMON') = (tenant_id = 'COMMON')"),
       chk("kpi_indicator", "state", f"state IN {E('ind_state')}"),
       chk("kpi_indicator", "brd_ref", "brd_ref IS NULL OR brd_ref ~ '^KPI-[0-9]{2}$'"),
       chk("kpi_indicator", "template", f"template_code IS NULL OR (scope = 'TENANT' AND template_code ~ '{TCODE_RE}')"),
       chk("kpi_indicator", "replaced", "replaced_by_code IS NULL OR (replaced_by_code <> indicator_code AND state = 'RETIRED')"),
       chk("kpi_indicator", "reason", "state <> 'RETIRED' OR COALESCE(" + reason20("state_reason") + ", false)")],
      idx=[ix("ix_kpi_indicator_group", "kpi_indicator", "tenant_id, group_code, state, display_order"),
           ix("ix_kpi_indicator_measure", "kpi_indicator", "tenant_id, measurement, state")],
      tid=True, rls="S", trig=[("immutable", ["tenant_id", "indicator_code", "scope"])],
      ccomment={"brd_ref": "Mã KPI-01…18 của BRD (D02-01 §3) nếu chỉ tiêu là KPI đo của BO; NULL với chỉ tiêu bổ sung.",
                "template_code": "Mã chỉ tiêu mẫu COMMON đã kế thừa (FR-16-008); phục vụ nhận cập nhật mẫu.",
                "template_version_no": "Số phiên bản mẫu COMMON đã nhận; mẫu có phiên bản ACTIVE mới hơn và chưa bị bỏ qua là cập nhật chờ quyết định (FRS EN-16-38).",
                "template_dismissed_version_no": "Số phiên bản mẫu COMMON tenant đã quyết định không nhận (DISMISSED).",
                "mandatory": "Bắt buộc có số để công bố báo cáo chính thức; thiếu nguồn bắt buộc thì chặn công bố (ERR-16-0xx)."}),
    T("kpi_indicator_version",
      "EN-16-03, EN-16-04 Phiên bản định nghĩa chỉ tiêu: công thức CEL trên biến quan sát (ví dụ `obs(\"ph01.httt.connected\") / obs(\"ph01.httt.total\") * 100`), danh sách biến, mục tiêu có hạn, làm tròn; vòng đời DRAFT, PENDING_APPROVAL, ACTIVE, SUPERSEDED, RETIRED, CHANGES_REQUESTED; duyệt bốn mắt (FR-16-002, 003, 004, 005, 006). ACTIVE và SUPERSEDED bất biến; mỗi chỉ tiêu một phiên bản ACTIVE và một phiên bản đang soạn hoặc chờ duyệt.",
      ["indicator_id uuid NOT NULL", "version_no integer NOT NULL", "state varchar(18) NOT NULL DEFAULT 'DRAFT'", "formula_cel text", "variables jsonb NOT NULL DEFAULT '[]'",
       "rounding_digits smallint NOT NULL DEFAULT 2", "baseline_value numeric(24,6)", "target_value numeric(24,6)", "target_min numeric(24,6)", "target_max numeric(24,6)", "target_due date",
       "effective_from date", "submitted_by varchar(64)", "submitted_at timestamptz", "decided_by varchar(64)", "decided_at timestamptz", "decision_comment varchar(2000)",
       "activated_at timestamptz", "superseded_at timestamptz", "change_note varchar(2000)"],
      [("uq_kpi_indicator_version_no", "UNIQUE (tenant_id, indicator_id, version_no)"),
       fk("kpi_indicator_version", "indicator", "tenant_id, indicator_id", "kpi_indicator", "tenant_id, id"),
       chk("kpi_indicator_version", "no", "version_no >= 1"),
       chk("kpi_indicator_version", "state", f"state IN {E('version_state')}"),
       chk("kpi_indicator_version", "variables", "jsonb_typeof(variables) = 'array' AND jsonb_array_length(variables) <= 50"),
       chk("kpi_indicator_version", "formula", "formula_cel IS NULL OR char_length(formula_cel) BETWEEN 1 AND 4000"),
       chk("kpi_indicator_version", "formula_required", "state IN ('DRAFT', 'CHANGES_REQUESTED') OR formula_cel IS NOT NULL"),
       chk("kpi_indicator_version", "rounding", "rounding_digits BETWEEN 0 AND 6"),
       chk("kpi_indicator_version", "target_range", "target_min IS NULL OR target_max IS NULL OR target_min <= target_max"),
       chk("kpi_indicator_version", "four_eyes", four_eyes("decided_by", "submitted_by")),
       chk("kpi_indicator_version", "submitted", "state = 'DRAFT' OR (submitted_by IS NOT NULL AND submitted_at IS NOT NULL)"),
       chk("kpi_indicator_version", "active", "state NOT IN ('ACTIVE', 'SUPERSEDED') OR (decided_by IS NOT NULL AND decided_at IS NOT NULL AND activated_at IS NOT NULL)"),
       chk("kpi_indicator_version", "changes", "state <> 'CHANGES_REQUESTED' OR COALESCE(" + reason20("decision_comment") + ", false)")],
      idx=[ix("uq_kpi_indicator_version_active", "kpi_indicator_version", "tenant_id, indicator_id", "state = 'ACTIVE'", unique=True),
           ix("uq_kpi_indicator_version_open", "kpi_indicator_version", "tenant_id, indicator_id", "state IN ('DRAFT', 'PENDING_APPROVAL', 'CHANGES_REQUESTED')", unique=True),
           ix("ix_kpi_indicator_version_state", "kpi_indicator_version", "tenant_id, state, submitted_at")],
      tid=True, rls="S",
      trig=[("immutable", ["tenant_id", "indicator_id", "version_no"]),
            ("frozen", ["state", "PENDING_APPROVAL,ACTIVE,SUPERSEDED,RETIRED", "formula_cel", "variables", "rounding_digits", "target_value", "target_min", "target_max",
                        "target_due", "baseline_value", "effective_from", "submitted_by", "submitted_at"]),
            ("transition", ["state", tmap(VERSION_MAP)])],
      ccomment={"variables": "Mảng {name, metricCode, aggregation, required, default}: biến CEL ánh xạ tới `metric_code` của quan sát hoặc tới số liệu nhập tay.",
                "formula_cel": "Biểu thức CEL (ADR đề xuất dải 160…164), chỉ đọc quan sát đã chuẩn hóa; đã thử tính trên dữ liệu kỳ trước trước khi gửi duyệt (FR-16-003).",
                "target_due": "Hạn đạt mục tiêu (FR-16-004).",
                "baseline_value": "Giá trị nền để so mục tiêu giảm theo tỷ lệ (ví dụ KPI-02, nền 150)."}),
    T("kpi_indicator_threshold",
      "EN-16-04 Ngưỡng ba mức GREEN, AMBER, RED của một phiên bản định nghĩa: khoảng giá trị ứng với mỗi mức, dùng đánh giá trạng thái ON_TRACK, AT_RISK, OFF_TRACK (FR-16-004, 021). Chỉ sửa khi phiên bản cha là DRAFT hoặc CHANGES_REQUESTED.",
      ["version_id uuid NOT NULL", "level varchar(5) NOT NULL", "lower_bound numeric(24,6)", "upper_bound numeric(24,6)", "lower_inclusive boolean NOT NULL DEFAULT true",
       "upper_inclusive boolean NOT NULL DEFAULT false"],
      [("uq_kpi_indicator_threshold_level", "UNIQUE (tenant_id, version_id, level)"),
       fk("kpi_indicator_threshold", "version", "tenant_id, version_id", "kpi_indicator_version", "tenant_id, id"),
       chk("kpi_indicator_threshold", "level", f"level IN {E('level')}"),
       chk("kpi_indicator_threshold", "bounds", "(lower_bound IS NOT NULL OR upper_bound IS NOT NULL) AND (lower_bound IS NULL OR upper_bound IS NULL OR lower_bound <= upper_bound)")],
      rls="S", trig=[("immutable", ["tenant_id", "version_id", "level"]), ("child_frozen", ["kpi_indicator_version", "version_id", "DRAFT,CHANGES_REQUESTED"])]),
]

# ---------------------------------------------------------------------------------------------
# 16-0020 Nguồn số liệu, hợp đồng, quan sát, nhật ký tiếp nhận, số liệu tay
# ---------------------------------------------------------------------------------------------
PRE["16-0020-source.sql"] = """-- @changeset ph16-0200-fn-observation-ref splitStatements:false
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
-- @rollback DROP FUNCTION IF EXISTS ph16_kpi.f_observation_ref();
"""
SRC_MAP = {"ACTIVE": ["STALE", "FAILED", "PAUSED"], "STALE": ["ACTIVE", "FAILED", "PAUSED"], "FAILED": ["ACTIVE", "PAUSED"], "PAUSED": ["ACTIVE", "RETIRED"]}
MANUAL_MAP = {"DRAFT": ["SUBMITTED"], "SUBMITTED": ["ACCEPTED", "REJECTED", "DRAFT"], "REJECTED": ["DRAFT"]}
G_SRC = [
    T("kpi_data_source",
      "EN-16-06 Nguồn số liệu: phân hệ hoặc kênh cung cấp quan sát, bốn loại EVENT (Kafka), PULL_API (kéo API chỉ số theo lịch), PUSH_API (scope `kpi.ingest`), MANUAL; theo dõi độ tươi và số lần kéo lỗi liên tiếp (FR-16-009, 013). Không xóa, chỉ tạm dừng hoặc ngừng.",
      ["source_code varchar(63) NOT NULL", "name varchar(255) NOT NULL", "source_type varchar(8) NOT NULL", "state varchar(8) NOT NULL DEFAULT 'ACTIVE'", "state_reason varchar(2000)",
       "owner_phase varchar(5)", "topic_pattern varchar(255)", "api_ref varchar(255)", "schedule_cron varchar(64)", "stale_after_hours smallint",
       "consecutive_failures integer NOT NULL DEFAULT 0", "last_attempt_at timestamptz", "last_success_at timestamptz", "last_error_code varchar(11)", "description varchar(2000)"],
      [("uq_kpi_data_source_code", "UNIQUE (tenant_id, source_code)"),
       chk("kpi_data_source", "code", f"source_code ~ '{TCODE_RE}'"),
       chk("kpi_data_source", "type", f"source_type IN {E('source_type')}"),
       chk("kpi_data_source", "state", f"state IN {E('source_state')}"),
       chk("kpi_data_source", "phase", f"owner_phase IS NULL OR owner_phase ~ '{PHASE_RE}'"),
       chk("kpi_data_source", "event", "source_type <> 'EVENT' OR topic_pattern IS NOT NULL"),
       chk("kpi_data_source", "topic", r"topic_pattern IS NULL OR topic_pattern ~ '^\{tenant\}\.[a-z0-9.*-]+$'"),
       chk("kpi_data_source", "pull", "source_type <> 'PULL_API' OR (api_ref IS NOT NULL AND schedule_cron IS NOT NULL)"),
       chk("kpi_data_source", "stale", "stale_after_hours IS NULL OR stale_after_hours BETWEEN 1 AND 744"),
       chk("kpi_data_source", "failures", "consecutive_failures >= 0"),
       chk("kpi_data_source", "error", ERRC("last_error_code")),
       chk("kpi_data_source", "reason", "state NOT IN ('PAUSED', 'RETIRED') OR COALESCE(" + reason20("state_reason") + ", false)")],
      idx=[ix("ix_kpi_data_source_state", "kpi_data_source", "tenant_id, state, source_type")],
      tid=True, trig=[("immutable", ["tenant_id", "source_code", "source_type"]), ("transition", ["state", tmap(SRC_MAP)])],
      ccomment={"stale_after_hours": "NULL thì lấy tham số 16.source.stale-hours (mặc định 26 giờ); quá hạn chuyển STALE.",
                "consecutive_failures": "Số lần kéo lỗi liên tiếp; đạt 16.source.fail-after (mặc định 3) thì chuyển FAILED và phát EVT-16-03.",
                "topic_pattern": "Mẫu topic Kafka dạng `{tenant}.dq.kpi.published.v1`."}),
    T("kpi_source_contract",
      "EN-16-05, EN-16-07 Hợp đồng chỉ số của nguồn: mỗi dòng là một `metric_code` dạng `ph{nn}.{đối-tượng}.{chỉ-số}` nguồn cam kết cung cấp, kiểu giá trị, đơn vị, chiều phân tách, phiên bản lược đồ (`kpiSchemaVersion`) và kỳ mong đợi (FR-16-009). Quan sát có `metric_code` ngoài hợp đồng bị loại.",
      ["source_id uuid NOT NULL", "metric_code varchar(128) NOT NULL", "kind varchar(10) NOT NULL", "unit varchar(32) NOT NULL", "dimension_schema jsonb NOT NULL DEFAULT '{}'",
       "schema_version varchar(16) NOT NULL DEFAULT '1'", "period_type varchar(8)", "required boolean NOT NULL DEFAULT true", "state varchar(8) NOT NULL DEFAULT 'ACTIVE'"],
      [("uq_kpi_source_contract", "UNIQUE (tenant_id, source_id, metric_code, schema_version)"),
       fk("kpi_source_contract", "source", "tenant_id, source_id", "kpi_data_source", "tenant_id, id"),
       chk("kpi_source_contract", "metric", f"metric_code ~ '{METRIC_RE}'"),
       chk("kpi_source_contract", "kind", f"kind IN {E('kind')}"),
       chk("kpi_source_contract", "schema_version", r"schema_version ~ '^[0-9]+(\.[0-9]+)*$'"),
       chk("kpi_source_contract", "period", f"period_type IS NULL OR period_type IN {E('period_type')}"),
       chk("kpi_source_contract", "state", f"state IN {E('contract_state')}")],
      idx=[ix("ix_kpi_source_contract_metric", "kpi_source_contract", "tenant_id, metric_code, state")],
      trig=[("immutable", ["tenant_id", "source_id", "metric_code", "schema_version"])]),
    T("kpi_observation",
      "EN-16-08 Quan sát: số liệu đã tổng hợp nhận từ phân hệ nguồn qua sự kiện, API kéo hoặc API đẩy, đã chuẩn hóa (FR-16-010, 011, 012). Chỉ thêm. Phân vùng tháng theo `period_start` (giờ Việt Nam). Idempotent: `idempotency_ref` (mã sự kiện hoặc `snapshotId`) duy nhất theo tenant và nguồn, nhận lại bản trùng không tạo dòng mới.",
      ["source_id uuid NOT NULL", "metric_code varchar(128) NOT NULL", "value numeric(24,6) NOT NULL", "unit varchar(32)", "period_start timestamptz NOT NULL",
       "period_end timestamptz NOT NULL", "dimensions jsonb NOT NULL DEFAULT '{}'", "source_ref varchar(255)", "idempotency_ref varchar(128) NOT NULL",
       "schema_version varchar(16)", "channel varchar(8) NOT NULL", "late boolean NOT NULL DEFAULT false", "received_at timestamptz NOT NULL DEFAULT now()"],
      [fk("kpi_observation", "source", "tenant_id, source_id", "kpi_data_source", "tenant_id, id"),
       chk("kpi_observation", "metric", f"metric_code ~ '{METRIC_RE}'"),
       chk("kpi_observation", "period", "period_end > period_start"),
       chk("kpi_observation", "idem", "idempotency_ref ~ '^[A-Za-z0-9._:-]{1,128}$'"),
       chk("kpi_observation", "channel", f"channel IN {E('source_type', skip=('MANUAL',))}"),
       chk("kpi_observation", "dimensions", "jsonb_typeof(dimensions) = 'object'")],
      idx=[ix("uq_kpi_observation_idem", "kpi_observation", "tenant_id, source_id, idempotency_ref, period_start", unique=True),
           ix("ix_kpi_observation_metric", "kpi_observation", "tenant_id, metric_code, period_start DESC"),
           ix("ix_kpi_observation_source", "kpi_observation", "tenant_id, source_id, received_at DESC")],
      part=("period_start", 24), pk=("id", "period_start"),
      trig=[("append_only", []), ("raw", "CREATE TRIGGER tg_kpi_observation_ref BEFORE INSERT ON ph16_kpi.kpi_observation FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_observation_ref();")],
      ccomment={"idempotency_ref": "Mã sự kiện (EVT-xx-yy) hoặc `snapshotId`; ERR-16-1xx khi trùng mã nhưng khác kỳ (trigger `tg_kpi_observation_ref`).",
                "period_start": "Khóa phân vùng, tháng theo giờ Việt Nam; PartitionMaintenanceJob tạo trước phân vùng.",
                "dimensions": "Chiều phân tách (tỉnh, loại HTTT…) dạng đối tượng JSON; không chứa dữ liệu cá nhân.",
                "late": "Quan sát đến sau khi kỳ COLLECTING kết thúc; kích hoạt tính lại LATE_DATA khi 16.late-data.recompute bật."}),
    T("kpi_ingest_log",
      "EN-16-09, EN-16-10 Nhật ký tiếp nhận và loại bỏ: mỗi lần nhận quan sát ghi kết quả ACCEPTED, DUPLICATE hoặc REJECTED kèm mã lỗi ERR-16-101…199 và băm thân yêu cầu; bản tin bị loại xử lý lại đạt thì chuyển REPROCESSED, giữ mã lỗi cũ làm lịch sử (FR-16-010, 016). Phân vùng tháng theo `received_at`.",
      ["source_id uuid NOT NULL", "channel varchar(8) NOT NULL", "outcome varchar(11) NOT NULL", "metric_code varchar(128)", "idempotency_ref varchar(128)",
       "payload_hash bytea", "payload jsonb", "reject_code varchar(11)", "detail varchar(2000)", "observation_id uuid", "received_at timestamptz NOT NULL DEFAULT now()",
       "reprocessed_at timestamptz", "reprocessed_by varchar(64)"],
      [fk("kpi_ingest_log", "source", "tenant_id, source_id", "kpi_data_source", "tenant_id, id"),
       chk("kpi_ingest_log", "channel", f"channel IN {E('source_type', skip=('MANUAL',))}"),
       chk("kpi_ingest_log", "outcome", f"outcome IN {E('ingest_outcome')}"),
       chk("kpi_ingest_log", "hash", H32("payload_hash")),
       chk("kpi_ingest_log", "reject", "reject_code IS NULL OR reject_code ~ '^ERR-16-1[0-9]{2}$'"),
       chk("kpi_ingest_log", "rejected", "(outcome IN ('REJECTED', 'REPROCESSED')) = (reject_code IS NOT NULL) AND (outcome <> 'REJECTED' OR payload IS NOT NULL)"),
       chk("kpi_ingest_log", "payload", "payload IS NULL OR octet_length(payload::text) <= 65536"),
       chk("kpi_ingest_log", "accepted", "outcome NOT IN ('ACCEPTED', 'REPROCESSED') OR observation_id IS NOT NULL"),
       chk("kpi_ingest_log", "reprocessed", "outcome <> 'REPROCESSED' OR (reprocessed_at IS NOT NULL AND reprocessed_by IS NOT NULL)")],
      idx=[ix("ix_kpi_ingest_log_source", "kpi_ingest_log", "tenant_id, source_id, received_at DESC"),
           ix("ix_kpi_ingest_log_rejected", "kpi_ingest_log", "tenant_id, received_at DESC", "outcome = 'REJECTED'"),
           ix("ix_kpi_ingest_log_ref", "kpi_ingest_log", "tenant_id, source_id, idempotency_ref")],
      part=("received_at", 24), pk=("id", "received_at"),
      trig=[("immutable", ["tenant_id", "source_id", "channel", "metric_code", "idempotency_ref", "payload_hash", "payload", "reject_code", "received_at"]),
            ("transition", ["outcome", tmap({"REJECTED": ["REPROCESSED"]})])],
      ccomment={"payload_hash": "SHA-256 của thân yêu cầu (32 byte).",
                "payload": "Bản tin quan sát đã tổng hợp, chỉ giữ với dòng REJECTED (tối đa 64 KB) để xử lý lại sau khi sửa hợp đồng; không chứa bản ghi giao dịch hay dữ liệu cá nhân (BR-16-028)."}),
]

# ---------------------------------------------------------------------------------------------
# 16-0030 Kỳ báo cáo, lần tổng hợp, giá trị chỉ tiêu, dòng truy nguồn, điểm nhóm
# ---------------------------------------------------------------------------------------------
PRE["16-0030-period.sql"] = """-- @changeset ph16-0300-fn-period-open splitStatements:false
CREATE OR REPLACE FUNCTION ph16_kpi.f_period_open() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  st text;
BEGIN
  SELECT state INTO st FROM ph16_kpi.kpi_reporting_period WHERE tenant_id = NEW.tenant_id AND id = NEW.period_id;
  IF st = 'CLOSED' THEN
    RAISE EXCEPTION 'Kỳ đã chốt (CLOSED): không ghi giá trị, điểm nhóm; mở lại kỳ có lý do trước' USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.f_period_open() IS 'Chặn ghi giá trị chỉ tiêu, điểm nhóm vào kỳ đã chốt (FR-16-024).';
-- @rollback DROP FUNCTION IF EXISTS ph16_kpi.f_period_open();

-- @changeset ph16-0301-fn-manual-gate splitStatements:false
CREATE OR REPLACE FUNCTION ph16_kpi.f_manual_gate() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.state <> 'DRAFT' THEN
      RAISE EXCEPTION 'Số liệu tay mới phải ở trạng thái DRAFT' USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
  END IF;
  IF NEW.state = 'SUBMITTED' AND OLD.state <> 'SUBMITTED'
     AND ph16_kpi.f_setting_bool(NEW.tenant_id, '16.manual.evidence-required', true)
     AND NOT EXISTS (SELECT 1 FROM ph16_kpi.kpi_manual_evidence WHERE tenant_id = NEW.tenant_id AND manual_value_id = NEW.id) THEN
    RAISE EXCEPTION 'Gửi xác nhận cần bằng chứng (16.manual.evidence-required = true)' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.f_manual_gate() IS 'Số liệu tay: tạo ở DRAFT; gửi xác nhận phải có bằng chứng khi tham số 16.manual.evidence-required bật (FR-16-014).';
-- @rollback DROP FUNCTION IF EXISTS ph16_kpi.f_manual_gate();
"""
PERIOD_MAP = {"OPEN": ["COLLECTING"], "COLLECTING": ["COMPUTED"], "COMPUTED": ["CLOSED"], "CLOSED": ["REOPENED"], "REOPENED": ["COMPUTED", "CLOSED"]}
RUN_MAP = {"QUEUED": ["RUNNING", "CANCELLED"], "RUNNING": ["SUCCEEDED", "PARTIAL", "FAILED", "CANCELLED"]}
G_PERIOD = [
    T("kpi_reporting_period",
      "EN-16-14 Kỳ báo cáo tháng, quý, năm mã `M-2026-10`, `Q-2026-Q3`, `Y-2026`; vòng đời OPEN, COLLECTING, COMPUTED, CLOSED, REOPENED. Kỳ CLOSED không nhận giá trị mới; mở lại phải có lý do và người mở (FR-16-017, 024).",
      ["period_code varchar(16) NOT NULL", "period_type varchar(8) NOT NULL", "start_date date NOT NULL", "end_date date NOT NULL", "state varchar(10) NOT NULL DEFAULT 'OPEN'",
       "close_due_date date", "closed_by varchar(64)", "closed_at timestamptz", "reopen_reason varchar(2000)", "reopened_by varchar(64)", "reopened_at timestamptz",
       "reopen_count smallint NOT NULL DEFAULT 0", "recompute_requested_at timestamptz"],
      [("uq_kpi_reporting_period_code", "UNIQUE (tenant_id, period_code)"),
       chk("kpi_reporting_period", "type", f"period_type IN {E('period_type')}"),
       chk("kpi_reporting_period", "code", "(period_type = 'MONTH' AND period_code ~ '^M-[0-9]{4}-(0[1-9]|1[0-2])$') OR (period_type = 'QUARTER' AND period_code ~ '^Q-[0-9]{4}-Q[1-4]$') OR (period_type = 'YEAR' AND period_code ~ '^Y-[0-9]{4}$')"),
       chk("kpi_reporting_period", "dates", "end_date >= start_date"),
       chk("kpi_reporting_period", "state", f"state IN {E('period_state')}"),
       chk("kpi_reporting_period", "closed", "state <> 'CLOSED' OR (closed_by IS NOT NULL AND closed_at IS NOT NULL)"),
       chk("kpi_reporting_period", "reopened", "state <> 'REOPENED' OR (COALESCE(" + reason50("reopen_reason") + ", false) AND reopened_by IS NOT NULL AND reopened_at IS NOT NULL AND reopen_count >= 1)")],
      idx=[ix("ix_kpi_reporting_period_start", "kpi_reporting_period", "tenant_id, period_type, start_date DESC")],
      tid=True, trig=[("immutable", ["tenant_id", "period_code", "period_type", "start_date", "end_date"]), ("transition", ["state", tmap(PERIOD_MAP)])],
      ccomment={"close_due_date": "Ngày dự kiến chốt, theo tham số 16.period.close-day (mặc định ngày 5 của tháng sau).",
                "reopen_reason": "Lý do mở lại từ 50 ký tự (BR-16-011, ERR-16-007).",
                "recompute_requested_at": "Mốc yêu cầu tính lại đầu tiên trong cửa sổ 16.late-data.debounce-minutes; bộ quét tạo lần LATE_DATA khi quá cửa sổ rồi đặt về NULL (FR-16-023)."}),
    T("kpi_manual_value",
      "EN-16-11 Số liệu nhập tay cho chỉ tiêu đo MANUAL hoặc MIXED: DRAFT, SUBMITTED, ACCEPTED, REJECTED; người nhập khác người xác nhận (FR-16-014, 015). Gửi xác nhận cần bằng chứng khi `16.manual.evidence-required` bật. Số liệu đã gửi hoặc đã quyết định không đổi giá trị.",
      ["indicator_id uuid NOT NULL", "period_id uuid NOT NULL", "variable_name varchar(63) NOT NULL DEFAULT 'value'", "value numeric(24,6) NOT NULL", "unit varchar(32)",
       "state varchar(9) NOT NULL DEFAULT 'DRAFT'", "entered_by varchar(64) NOT NULL", "entered_at timestamptz NOT NULL DEFAULT now()", "submitted_at timestamptz",
       "decided_by varchar(64)", "decided_at timestamptz", "decision_comment varchar(2000)", "note varchar(2000)"],
      [fk("kpi_manual_value", "indicator", "tenant_id, indicator_id", "kpi_indicator", "tenant_id, id"),
       fk("kpi_manual_value", "period", "tenant_id, period_id", "kpi_reporting_period", "tenant_id, id"),
       chk("kpi_manual_value", "state", f"state IN {E('manual_state')}"),
       chk("kpi_manual_value", "four_eyes", four_eyes("decided_by", "entered_by")),
       chk("kpi_manual_value", "submitted", "state = 'DRAFT' OR submitted_at IS NOT NULL"),
       chk("kpi_manual_value", "decided", "state NOT IN ('ACCEPTED', 'REJECTED') OR (decided_by IS NOT NULL AND decided_at IS NOT NULL)"),
       chk("kpi_manual_value", "rejected", "state <> 'REJECTED' OR COALESCE(" + reason20("decision_comment") + ", false)")],
      idx=[ix("uq_kpi_manual_value_open", "kpi_manual_value", "tenant_id, indicator_id, period_id, variable_name", "state <> 'REJECTED'", unique=True),
           ix("ix_kpi_manual_value_inbox", "kpi_manual_value", "tenant_id, state, submitted_at", "state = 'SUBMITTED'")],
      tid=True,
      trig=[("immutable", ["tenant_id", "indicator_id", "period_id", "variable_name", "entered_by"]),
            ("frozen", ["state", "SUBMITTED,ACCEPTED,REJECTED", "value", "unit"]),
            ("transition", ["state", tmap(MANUAL_MAP)]),
            ("raw", "CREATE TRIGGER tg_kpi_manual_value_gate BEFORE INSERT OR UPDATE ON ph16_kpi.kpi_manual_value FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_manual_gate();")],
      ccomment={"variable_name": "Tên biến trong công thức CEL mà số liệu tay cung cấp; mặc định `value` cho chỉ tiêu một biến.",
                "decided_by": "Người xác nhận; CHECK ck_kpi_manual_value_four_eyes buộc khác `entered_by` (cặp loại trừ, PERM-16-manual)."}),
    T("kpi_manual_evidence",
      "EN-16-12 Bằng chứng của số liệu nhập tay: tệp đính kèm (Ceph RGW, kèm SHA-256) hoặc số và ngày văn bản (FR-16-014). Chỉ thêm, sửa, xóa khi số liệu cha còn DRAFT; sau khi gửi xác nhận là bằng chứng cố định.",
      ["manual_value_id uuid NOT NULL", "evidence_type varchar(15) NOT NULL", "object_ref varchar(512)", "file_name varchar(255)", "content_hash bytea",
       "document_no varchar(64)", "document_date date", "description varchar(2000)", "uploaded_by varchar(64) NOT NULL"],
      [fk("kpi_manual_evidence", "manual", "tenant_id, manual_value_id", "kpi_manual_value", "tenant_id, id"),
       chk("kpi_manual_evidence", "type", f"evidence_type IN {E('evidence_type')}"),
       chk("kpi_manual_evidence", "file", "evidence_type <> 'FILE' OR (object_ref IS NOT NULL AND file_name IS NOT NULL AND content_hash IS NOT NULL)"),
       chk("kpi_manual_evidence", "doc", "evidence_type <> 'DOCUMENT_NUMBER' OR (document_no IS NOT NULL AND document_date IS NOT NULL)"),
       chk("kpi_manual_evidence", "hash", H32("content_hash"))],
      idx=[ix("ix_kpi_manual_evidence_value", "kpi_manual_evidence", "tenant_id, manual_value_id")],
      trig=[("child_frozen", ["kpi_manual_value", "manual_value_id", "DRAFT"])],
      ccomment={"object_ref": "Đường dẫn đối tượng trên Ceph RGW (bucket kpi-evidence); không lưu tệp trong PostgreSQL."}),
    T("kpi_manual_import",
      "EN-16-13 Lần nhập số liệu tay từ tệp XLSX theo mẫu (≤ 2.000 dòng): tệp gốc, mã băm, số dòng hợp lệ, lỗi, đã ghi; bản xem trước giữ 24 giờ rồi dọn (FR-16-014). Ghi các dòng hợp lệ tạo số liệu tay DRAFT.",
      ["file_name varchar(255) NOT NULL", "object_ref varchar(512) NOT NULL", "content_hash bytea NOT NULL", "row_total integer NOT NULL", "valid_count integer NOT NULL DEFAULT 0",
       "invalid_count integer NOT NULL DEFAULT 0", "imported_count integer NOT NULL DEFAULT 0", "uploaded_by varchar(64) NOT NULL", "expires_at timestamptz NOT NULL",
       "committed_by varchar(64)", "committed_at timestamptz"],
      [chk("kpi_manual_import", "rows", "row_total BETWEEN 1 AND 2000 AND valid_count >= 0 AND invalid_count >= 0 AND valid_count + invalid_count <= row_total AND imported_count BETWEEN 0 AND valid_count"),
       chk("kpi_manual_import", "hash", H32("content_hash")),
       chk("kpi_manual_import", "expiry", "expires_at > created_at AND expires_at <= created_at + interval '24 hours'"),
       chk("kpi_manual_import", "committed", "(committed_at IS NULL) = (committed_by IS NULL) AND (committed_at IS NULL OR imported_count >= 1)")],
      idx=[ix("ix_kpi_manual_import_expiry", "kpi_manual_import", "expires_at", "committed_at IS NULL")],
      tid=True, trig=[("immutable", ["tenant_id", "file_name", "object_ref", "content_hash", "row_total", "uploaded_by", "expires_at"])],
      ccomment={"object_ref": "Tệp XLSX gốc trên Ceph RGW (bucket kpi-evidence, tiền tố imports/); xóa cùng bản ghi khi quá expires_at."}),
    T("kpi_manual_import_row",
      "EN-16-13 Dòng của lần nhập tệp: chỉ tiêu, kỳ, giá trị đọc được, kết quả kiểm VALID, INVALID (kèm mã lỗi) hoặc IMPORTED khi đã thành số liệu tay (FR-16-014). Bản xem trước UI-16-07 đọc bảng này.",
      ["import_id uuid NOT NULL", "row_no integer NOT NULL", "indicator_code varchar(63)", "period_code varchar(16)", "value numeric(24,6)", "row_status varchar(8) NOT NULL",
       "error_code varchar(11)", "detail varchar(500)", "manual_value_id uuid"],
      [("uq_kpi_manual_import_row_no", "UNIQUE (tenant_id, import_id, row_no)"),
       fk("kpi_manual_import_row", "import", "tenant_id, import_id", "kpi_manual_import", "tenant_id, id", " ON DELETE CASCADE"),
       fk("kpi_manual_import_row", "manual", "tenant_id, manual_value_id", "kpi_manual_value", "tenant_id, id"),
       chk("kpi_manual_import_row", "no", "row_no BETWEEN 1 AND 2000"),
       chk("kpi_manual_import_row", "status", f"row_status IN {E('import_row_status')}"),
       chk("kpi_manual_import_row", "invalid", "(row_status = 'INVALID') = (error_code IS NOT NULL)"),
       chk("kpi_manual_import_row", "imported", "(row_status = 'IMPORTED') = (manual_value_id IS NOT NULL)"),
       chk("kpi_manual_import_row", "error", ERRC("error_code"))],
      trig=[("immutable", ["tenant_id", "import_id", "row_no", "indicator_code", "period_code", "value"]), ("transition", ["row_status", tmap({"VALID": ["IMPORTED"]})])]),
    T("kpi_aggregation_run",
      "EN-16-15 Lần tổng hợp: một lần tính mọi chỉ tiêu của một kỳ, theo lịch, thủ công, tính lại hoặc do số liệu trễ; ghi độ đầy đủ, cờ thiếu nguồn, số chỉ tiêu có số (FR-16-018, 020, 023, 042). SUCCEEDED, PARTIAL, FAILED, CANCELLED là trạng thái cuối. Mỗi kỳ tối đa một lần đang QUEUED hoặc RUNNING.",
      ["period_id uuid NOT NULL", "run_no integer NOT NULL", "run_trigger varchar(9) NOT NULL", "state varchar(9) NOT NULL DEFAULT 'QUEUED'", "requested_by varchar(64) NOT NULL",
       "reason varchar(2000)", "started_at timestamptz", "finished_at timestamptz", "completeness numeric(5,4)", "flags text[] NOT NULL DEFAULT '{}'",
       "indicator_total smallint NOT NULL DEFAULT 0", "indicator_computed smallint NOT NULL DEFAULT 0", "idempotency_ref varchar(128)", "error_code varchar(11)", "error_message varchar(2000)"],
      [("uq_kpi_aggregation_run_no", "UNIQUE (tenant_id, period_id, run_no)"),
       fk("kpi_aggregation_run", "period", "tenant_id, period_id", "kpi_reporting_period", "tenant_id, id"),
       chk("kpi_aggregation_run", "no", "run_no >= 1"),
       chk("kpi_aggregation_run", "trigger", f"run_trigger IN {E('run_trigger')}"),
       chk("kpi_aggregation_run", "state", f"state IN {E('run_state')}"),
       chk("kpi_aggregation_run", "flags", f"flags <@ ARRAY[{', '.join(repr(x) for x in FLAGS.split())}]::text[]"),
       chk("kpi_aggregation_run", "completeness", "completeness IS NULL OR (completeness >= 0 AND completeness <= 1)"),
       chk("kpi_aggregation_run", "counts", "indicator_total >= 0 AND indicator_computed >= 0 AND indicator_computed <= indicator_total"),
       chk("kpi_aggregation_run", "done", "state NOT IN ('SUCCEEDED', 'PARTIAL', 'FAILED', 'CANCELLED') OR finished_at IS NOT NULL"),
       chk("kpi_aggregation_run", "result", "state NOT IN ('SUCCEEDED', 'PARTIAL') OR completeness IS NOT NULL"),
       chk("kpi_aggregation_run", "partial", "state <> 'PARTIAL' OR (cardinality(flags) > 0 OR completeness < 1)"),
       chk("kpi_aggregation_run", "failed", "state <> 'FAILED' OR error_code IS NOT NULL"),
       chk("kpi_aggregation_run", "reason", "run_trigger NOT IN ('RECOMPUTE', 'LATE_DATA') OR COALESCE(" + reason20("reason") + ", false)"),
       chk("kpi_aggregation_run", "error", ERRC("error_code"))],
      idx=[ix("uq_kpi_aggregation_run_active", "kpi_aggregation_run", "tenant_id, period_id", "state IN ('QUEUED', 'RUNNING')", unique=True),
           ix("uq_kpi_aggregation_run_idem", "kpi_aggregation_run", "tenant_id, idempotency_ref", "idempotency_ref IS NOT NULL", unique=True),
           ix("ix_kpi_aggregation_run_state", "kpi_aggregation_run", "tenant_id, state, started_at DESC")],
      tid=True, trig=[("immutable", ["tenant_id", "period_id", "run_no", "run_trigger", "requested_by"]), ("transition", ["state", tmap(RUN_MAP)])],
      ccomment={"idempotency_ref": "Chống chạy lặp theo lịch, ví dụ `agg:M-2026-10:2026-11-05`; NULL với lần chạy tay.",
                "flags": "Cờ: MISSING_SOURCE, STALE_SOURCE, MANUAL_PENDING, FORMULA_ERROR.",
                "completeness": "Tỷ lệ chỉ tiêu có số trên tổng số chỉ tiêu đang ACTIVE của kỳ (0…1)."}),
    T("kpi_indicator_value",
      "EN-16-16 Giá trị chỉ tiêu theo kỳ và lần tổng hợp: số, trạng thái so mục tiêu và ngưỡng (ON_TRACK, AT_RISK, OFF_TRACK, NO_DATA), độ đầy đủ (COMPLETE, PARTIAL, NO_DATA), chênh lệch so kỳ trước và cùng kỳ năm trước, xu hướng; ghi phiên bản công thức đã dùng (FR-16-019, 021, 022, 035, 037, 039, 040, 041). Phân vùng tháng theo `period_start`. Kỳ CLOSED không nhận giá trị mới.",
      ["period_id uuid NOT NULL", "period_code varchar(16) NOT NULL", "period_start date NOT NULL", "run_id uuid NOT NULL", "indicator_id uuid NOT NULL",
       "indicator_code varchar(63) NOT NULL", "group_code varchar(16) NOT NULL", "version_id uuid NOT NULL", "value numeric(24,6)", "status varchar(9) NOT NULL",
       "completeness varchar(9) NOT NULL", "delta numeric(24,6)", "delta_yoy numeric(24,6)", "trend varchar(8)", "is_current boolean NOT NULL DEFAULT true",
       "missing_variables text[] NOT NULL DEFAULT '{}'", "computed_at timestamptz NOT NULL DEFAULT now()"],
      [fk("kpi_indicator_value", "period", "tenant_id, period_id", "kpi_reporting_period", "tenant_id, id"),
       fk("kpi_indicator_value", "run", "tenant_id, run_id", "kpi_aggregation_run", "tenant_id, id"),
       fk("kpi_indicator_value", "indicator", "tenant_id, indicator_id", "kpi_indicator", "tenant_id, id"),
       fk("kpi_indicator_value", "version", "tenant_id, version_id", "kpi_indicator_version", "tenant_id, id"),
       chk("kpi_indicator_value", "status", f"status IN {E('value_status')}"),
       chk("kpi_indicator_value", "completeness", f"completeness IN {E('completeness')}"),
       chk("kpi_indicator_value", "trend", f"trend IS NULL OR trend IN {E('trend')}"),
       chk("kpi_indicator_value", "no_data", "(completeness = 'NO_DATA') = (value IS NULL) AND (completeness = 'NO_DATA') = (status = 'NO_DATA')"),
       chk("kpi_indicator_value", "period_code", "period_code ~ '^(M-[0-9]{4}-[0-9]{2}|Q-[0-9]{4}-Q[1-4]|Y-[0-9]{4})$'"),
       chk("kpi_indicator_value", "group", f"group_code IN {E('group_code')}"),
       chk("kpi_indicator_value", "missing", "completeness <> 'PARTIAL' OR cardinality(missing_variables) > 0")],
      idx=[ix("uq_kpi_indicator_value_run", "kpi_indicator_value", "tenant_id, run_id, indicator_id, period_start", unique=True),
           ix("uq_kpi_indicator_value_current", "kpi_indicator_value", "tenant_id, period_id, indicator_id, period_start", "is_current", unique=True),
           ix("ix_kpi_indicator_value_series", "kpi_indicator_value", "tenant_id, indicator_id, period_start DESC", "is_current"),
           ix("ix_kpi_indicator_value_status", "kpi_indicator_value", "tenant_id, period_id, status", "is_current")],
      part=("period_start", 24), pk=("id", "period_start"), tid=False,
      trig=[("immutable", ["tenant_id", "period_id", "period_code", "period_start", "run_id", "indicator_id", "indicator_code", "version_id"]),
            ("raw", "CREATE TRIGGER tg_kpi_indicator_value_period BEFORE INSERT OR UPDATE ON ph16_kpi.kpi_indicator_value FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_period_open();")],
      ccomment={"is_current": "Dòng của lần tổng hợp mới nhất cho (kỳ, chỉ tiêu); tính lại đặt dòng cũ về false. Mỗi (kỳ, chỉ tiêu) một dòng hiện hành.",
                "version_id": "Phiên bản công thức có hiệu lực lúc tính; cùng `kpi_value_lineage` làm dòng truy nguồn.",
                "period_start": "Khóa phân vùng: ngày bắt đầu của kỳ (kỳ quý, năm nằm ở phân vùng tháng đầu).",
                "missing_variables": "Tên biến thiếu quan sát khi PARTIAL (fail-soft, không bịa số)."}),
    T("kpi_value_lineage",
      "EN-16-16 Dòng truy nguồn: mỗi biến công thức dùng cho một giá trị chỉ tiêu trỏ tới quan sát, số liệu nhập tay hoặc chỉ tiêu khác, kèm giá trị đã dùng (FR-16-019, 039). Chỉ thêm; phân vùng tháng theo `period_start`; tham chiếu tới giá trị và quan sát là logic vì bảng đích phân vùng.",
      ["value_id uuid NOT NULL", "period_start date NOT NULL", "run_id uuid NOT NULL", "seq smallint NOT NULL", "variable_name varchar(63) NOT NULL", "source_kind varchar(12) NOT NULL",
       "metric_code varchar(128)", "observation_id uuid", "manual_value_id uuid", "ref_indicator_id uuid", "ref_value_id uuid", "used_value numeric(24,6)"],
      [fk("kpi_value_lineage", "run", "tenant_id, run_id", "kpi_aggregation_run", "tenant_id, id"),
       fk("kpi_value_lineage", "manual", "tenant_id, manual_value_id", "kpi_manual_value", "tenant_id, id"),
       fk("kpi_value_lineage", "ref", "tenant_id, ref_indicator_id", "kpi_indicator", "tenant_id, id"),
       chk("kpi_value_lineage", "seq", "seq >= 1"),
       chk("kpi_value_lineage", "kind", f"source_kind IN {E('lineage_kind')}"),
       chk("kpi_value_lineage", "ref_one", "(source_kind = 'OBSERVATION') = (observation_id IS NOT NULL) AND (source_kind = 'MANUAL_VALUE') = (manual_value_id IS NOT NULL) AND (source_kind = 'INDICATOR') = (ref_indicator_id IS NOT NULL) AND (source_kind = 'PERIOD_VALUE') = (ref_value_id IS NOT NULL)"),
       chk("kpi_value_lineage", "metric", f"metric_code IS NULL OR metric_code ~ '{METRIC_RE}'")],
      idx=[ix("uq_kpi_value_lineage_seq", "kpi_value_lineage", "tenant_id, value_id, seq, period_start", unique=True),
           ix("ix_kpi_value_lineage_obs", "kpi_value_lineage", "tenant_id, observation_id", "observation_id IS NOT NULL")],
      part=("period_start", 24), pk=("id", "period_start"), trig=[("append_only", [])],
      ccomment={"value_id": "Giá trị chỉ tiêu `kpi_indicator_value.id` (tham chiếu logic, bảng đích phân vùng).",
                "observation_id": "Quan sát `kpi_observation.id` (tham chiếu logic, bảng đích phân vùng).",
                "ref_value_id": "Giá trị chỉ tiêu của kỳ con (tháng) dùng để gộp lên kỳ quý, năm (tham chiếu logic)."}),
    T("kpi_group_score",
      "EN-16-17 Điểm nhóm theo kỳ và lần tổng hợp: điểm 0…100 từ các chỉ tiêu của nhóm theo trọng số, số chỉ tiêu có số, độ đầy đủ, xu hướng và chênh lệch so kỳ trước (FR-16-007, 022, 038). Kỳ CLOSED không nhận điểm mới.",
      ["period_id uuid NOT NULL", "run_id uuid NOT NULL", "group_code varchar(16) NOT NULL", "score numeric(6,2)", "weight numeric(5,2) NOT NULL", "indicator_total smallint NOT NULL",
       "indicator_with_value smallint NOT NULL", "completeness varchar(9) NOT NULL", "delta numeric(6,2)", "trend varchar(8)", "is_current boolean NOT NULL DEFAULT true"],
      [("uq_kpi_group_score_run", "UNIQUE (tenant_id, run_id, group_code)"),
       fk("kpi_group_score", "period", "tenant_id, period_id", "kpi_reporting_period", "tenant_id, id"),
       fk("kpi_group_score", "run", "tenant_id, run_id", "kpi_aggregation_run", "tenant_id, id"),
       fk("kpi_group_score", "group", "tenant_id, group_code", "kpi_indicator_group"),
       chk("kpi_group_score", "score", "score IS NULL OR (score >= 0 AND score <= 100)"),
       chk("kpi_group_score", "weight", "weight >= 0 AND weight <= 100"),
       chk("kpi_group_score", "counts", "indicator_total >= 0 AND indicator_with_value >= 0 AND indicator_with_value <= indicator_total"),
       chk("kpi_group_score", "completeness", f"completeness IN {E('completeness')}"),
       chk("kpi_group_score", "complete", "(completeness = 'COMPLETE') = (indicator_with_value = indicator_total AND indicator_total > 0) AND (completeness = 'NO_DATA') = (score IS NULL)"),
       chk("kpi_group_score", "trend", f"trend IS NULL OR trend IN {E('trend')}")],
      idx=[ix("uq_kpi_group_score_current", "kpi_group_score", "tenant_id, period_id, group_code", "is_current", unique=True),
           ix("ix_kpi_group_score_series", "kpi_group_score", "tenant_id, group_code, period_id", "is_current")],
      trig=[("immutable", ["tenant_id", "period_id", "run_id", "group_code"]),
            ("raw", "CREATE TRIGGER tg_kpi_group_score_period BEFORE INSERT OR UPDATE ON ph16_kpi.kpi_group_score FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_period_open();")]),
]
FILE_GROUPS += [("16-0010-indicator.sql", G_IND), ("16-0020-source.sql", G_SRC), ("16-0030-period.sql", G_PERIOD)]

# Phần B của sinh_ddl.py: báo cáo, sổ kiến trúc, gửi quốc gia, vận hành. Được sinh_ddl.py nạp (exec) sau phần A.

# ---------------------------------------------------------------------------------------------
# 16-0040 Mẫu báo cáo, báo cáo, phiên bản, duyệt, chữ ký, phân phối, xuất
# ---------------------------------------------------------------------------------------------
PRE["16-0040-report.sql"] = """-- @changeset ph16-0400-fn-report-gate splitStatements:false
-- Cổng nghiệp vụ của phiên bản báo cáo: tạo ở DRAFT; duyệt bốn mắt theo tham số 16.report.four-eyes; công bố cần chữ ký số khớp mã băm khi 16.report.signing bật.
CREATE OR REPLACE FUNCTION ph16_kpi.f_report_version_gate() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.state <> 'DRAFT' THEN
      RAISE EXCEPTION 'Phiên bản báo cáo mới phải ở trạng thái DRAFT' USING ERRCODE = '55000';
    END IF;
    RETURN NEW;
  END IF;
  IF NEW.state = 'APPROVED' AND OLD.state = 'IN_REVIEW'
     AND ph16_kpi.f_setting_bool(NEW.tenant_id, '16.report.four-eyes', true)
     AND NEW.approved_by IS NOT DISTINCT FROM NEW.prepared_by THEN
    RAISE EXCEPTION 'Bốn mắt: người duyệt phải khác người lập báo cáo (16.report.four-eyes)' USING ERRCODE = '23514';
  END IF;
  IF NEW.state = 'PUBLISHED' AND OLD.state = 'APPROVED'
     AND ph16_kpi.f_setting_bool(NEW.tenant_id, '16.report.signing', true)
     AND NOT EXISTS (SELECT 1 FROM ph16_kpi.kpi_report_signature s
                      WHERE s.tenant_id = NEW.tenant_id AND s.report_version_id = NEW.id AND s.signed_hash = NEW.content_hash) THEN
    RAISE EXCEPTION 'Công bố cần chữ ký số khớp mã băm nội dung (16.report.signing)' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.f_report_version_gate() IS 'Cổng nghiệp vụ phiên bản báo cáo (FR-16-028, 029).';
-- @rollback DROP FUNCTION IF EXISTS ph16_kpi.f_report_version_gate();

-- @changeset ph16-0401-fn-report-sync splitStatements:false
-- Báo cáo (đầu) phản chiếu trạng thái phiên bản mới nhất và nhớ phiên bản đang công bố.
CREATE OR REPLACE FUNCTION ph16_kpi.f_report_sync() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  UPDATE ph16_kpi.kpi_report r
     SET state = CASE WHEN NEW.version_no >= r.current_version_no THEN NEW.state ELSE r.state END,
         current_version_no = GREATEST(r.current_version_no, NEW.version_no),
         published_version_no = CASE WHEN NEW.state = 'PUBLISHED' THEN NEW.version_no
                                     WHEN NEW.state IN ('SUPERSEDED', 'WITHDRAWN') AND r.published_version_no = NEW.version_no THEN NULL
                                     ELSE r.published_version_no END
   WHERE r.tenant_id = NEW.tenant_id AND r.id = NEW.report_id;
  RETURN NULL;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.f_report_sync() IS 'Đồng bộ kpi_report.state, current_version_no, published_version_no từ kpi_report_version.';
-- @rollback DROP FUNCTION IF EXISTS ph16_kpi.f_report_sync();

-- @changeset ph16-0402-fn-approval-gate splitStatements:false
CREATE OR REPLACE FUNCTION ph16_kpi.f_approval_gate() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NEW.action = 'APPROVE' AND ph16_kpi.f_setting_bool(NEW.tenant_id, '16.report.four-eyes', true)
     AND EXISTS (SELECT 1 FROM ph16_kpi.kpi_report_version v WHERE v.tenant_id = NEW.tenant_id AND v.id = NEW.report_version_id AND v.prepared_by = NEW.actor) THEN
    RAISE EXCEPTION 'Bốn mắt: người lập không được ghi hành động APPROVE cho báo cáo của mình' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.f_approval_gate() IS 'Cặp loại trừ: người lập báo cáo khác người duyệt cùng báo cáo (D02-08).';
-- @rollback DROP FUNCTION IF EXISTS ph16_kpi.f_approval_gate();
"""
TEMPLATE_MAP = {"DRAFT": ["ACTIVE", "RETIRED"], "ACTIVE": ["RETIRED"]}
REPORT_MAP = {"DRAFT": ["IN_REVIEW"], "IN_REVIEW": ["APPROVED", "CHANGES_REQUESTED"], "CHANGES_REQUESTED": ["DRAFT"], "APPROVED": ["PUBLISHED", "CHANGES_REQUESTED"],
              "PUBLISHED": ["SUPERSEDED", "WITHDRAWN"]}
EXPORT_MAP = {"QUEUED": ["RUNNING", "FAILED"], "RUNNING": ["SUCCEEDED", "FAILED"], "SUCCEEDED": ["EXPIRED"]}
FINAL = "PUBLISHED,SUPERSEDED,WITHDRAWN"
G_REPORT = [
    T("kpi_report_template",
      "EN-16-19 Mẫu báo cáo có phiên bản: bố cục phần (SUMMARY, GROUP, INDICATOR_TABLE, CHART, NARRATIVE, ANNEX), định dạng xuất (PDF, XLSX, CSV, JSON) và cấu hình bố cục (FR-16-025). Dòng COMMON do PLATFORM quản, mọi tenant đọc được (mẫu RLS S). ACTIVE bất biến, mỗi mã một phiên bản ACTIVE.",
      ["template_code varchar(63) NOT NULL", "version_no integer NOT NULL DEFAULT 1", "name varchar(255) NOT NULL", "state varchar(8) NOT NULL DEFAULT 'DRAFT'",
       "sections text[] NOT NULL", "formats text[] NOT NULL DEFAULT '{PDF}'", "layout jsonb NOT NULL DEFAULT '{}'", "description varchar(2000)", "activated_at timestamptz"],
      [("uq_kpi_report_template_version", "UNIQUE (tenant_id, template_code, version_no)"),
       chk("kpi_report_template", "code", f"template_code ~ '{TCODE_RE}'"),
       chk("kpi_report_template", "no", "version_no >= 1"),
       chk("kpi_report_template", "state", f"state IN {E('template_state')}"),
       chk("kpi_report_template", "sections", f"cardinality(sections) >= 1 AND sections <@ {ARR('section')}"),
       chk("kpi_report_template", "formats", f"cardinality(formats) >= 1 AND formats <@ {ARR('format')}"),
       chk("kpi_report_template", "layout", "jsonb_typeof(layout) = 'object'"),
       chk("kpi_report_template", "active", "state = 'DRAFT' OR activated_at IS NOT NULL")],
      idx=[ix("uq_kpi_report_template_active", "kpi_report_template", "tenant_id, template_code", "state = 'ACTIVE'", unique=True)],
      tid=True, rls="S",
      trig=[("immutable", ["tenant_id", "template_code", "version_no"]), ("frozen", ["state", "ACTIVE,RETIRED", "name", "sections", "formats", "layout"]),
            ("transition", ["state", tmap(TEMPLATE_MAP)])]),
    T("kpi_report",
      "EN-16-20 Báo cáo (phần đầu): mã `bc-thang-2026-10`, loại PERIODIC, AD_HOC, NATIONAL, kỳ hoặc khoảng thời gian, mẫu; phản chiếu trạng thái phiên bản mới nhất và nhớ phiên bản đang công bố (FR-16-026, 031, 032). Nội dung nằm ở `kpi_report_version`; đính chính tạo phiên bản mới, không sửa bản đã công bố.",
      ["report_code varchar(63) NOT NULL", "report_type varchar(8) NOT NULL", "title varchar(255) NOT NULL", "period_id uuid", "range_from date", "range_to date",
       "template_id uuid NOT NULL", "state varchar(17) NOT NULL DEFAULT 'DRAFT'", "current_version_no integer NOT NULL DEFAULT 1", "published_version_no integer"],
      [("uq_kpi_report_code", "UNIQUE (tenant_id, report_code)"),
       fk("kpi_report", "period", "tenant_id, period_id", "kpi_reporting_period", "tenant_id, id"),
       fk("kpi_report", "template", "tenant_id, template_id", "kpi_report_template", "tenant_id, id"),
       chk("kpi_report", "code", f"report_code ~ '{TCODE_RE}'"),
       chk("kpi_report", "type", f"report_type IN {E('report_type')}"),
       chk("kpi_report", "state", f"state IN {E('report_state')}"),
       chk("kpi_report", "scope", "(report_type IN ('PERIODIC', 'NATIONAL') AND period_id IS NOT NULL) OR (report_type = 'AD_HOC' AND range_from IS NOT NULL AND range_to IS NOT NULL AND range_from <= range_to)"),
       chk("kpi_report", "versions", "current_version_no >= 1 AND (published_version_no IS NULL OR published_version_no <= current_version_no)")],
      idx=[ix("ix_kpi_report_period", "kpi_report", "tenant_id, report_type, period_id"), ix("ix_kpi_report_state", "kpi_report", "tenant_id, state, updated_at DESC")],
      tid=True, trig=[("immutable", ["tenant_id", "report_code", "report_type", "period_id"])],
      ccomment={"state": "Bản sao trạng thái của phiên bản mới nhất, do trigger `tg_kpi_report_version_sync` cập nhật; nguồn chuẩn là `kpi_report_version.state`.",
                "published_version_no": "Phiên bản đang PUBLISHED (NULL nếu chưa công bố hoặc đã SUPERSEDED, WITHDRAWN)."}),
    T("kpi_report_version",
      "EN-16-21, EN-16-22 Phiên bản báo cáo: ảnh chụp giá trị chỉ tiêu, thuyết minh, mẫu, lần tổng hợp nguồn; vòng đời DRAFT, IN_REVIEW, APPROVED, PUBLISHED, CHANGES_REQUESTED, SUPERSEDED, WITHDRAWN (FR-16-026, 027, 028, 029, 030). Khi PUBLISHED bất biến bằng trigger: nội dung, mã băm, tệp PDF ký số (lưu WORM, giữ theo `16.report.retention-years`) không đổi; đính chính bằng phiên bản mới. Người duyệt khác người lập.",
      ["report_id uuid NOT NULL", "version_no integer NOT NULL", "state varchar(17) NOT NULL DEFAULT 'DRAFT'", "template_id uuid NOT NULL", "run_id uuid",
       "snapshot jsonb NOT NULL DEFAULT '{}'", "narrative jsonb NOT NULL DEFAULT '{}'", "completeness varchar(9) NOT NULL DEFAULT 'COMPLETE'", "missing_mandatory boolean NOT NULL DEFAULT false",
       "prepared_by varchar(64) NOT NULL", "prepared_at timestamptz NOT NULL DEFAULT now()", "submitted_at timestamptz", "approved_by varchar(64)", "approved_at timestamptz",
       "published_by varchar(64)", "published_at timestamptz", "content_hash bytea", "object_ref varchar(512)", "retain_until date", "correction_of_version_no integer",
       "correction_reason varchar(2000)", "decision_comment varchar(2000)", "document_number varchar(64)", "recipients_note varchar(2000)", "withdrawn_by varchar(64)", "withdrawn_at timestamptz", "withdraw_reason varchar(2000)"],
      [("uq_kpi_report_version_no", "UNIQUE (tenant_id, report_id, version_no)"),
       fk("kpi_report_version", "report", "tenant_id, report_id", "kpi_report", "tenant_id, id"),
       fk("kpi_report_version", "template", "tenant_id, template_id", "kpi_report_template", "tenant_id, id"),
       fk("kpi_report_version", "run", "tenant_id, run_id", "kpi_aggregation_run", "tenant_id, id"),
       chk("kpi_report_version", "no", "version_no >= 1"),
       chk("kpi_report_version", "state", f"state IN {E('report_state')}"),
       chk("kpi_report_version", "completeness", f"completeness IN {E('completeness')}"),
       chk("kpi_report_version", "snapshot", "jsonb_typeof(snapshot) = 'object' AND jsonb_typeof(narrative) = 'object'"),
       chk("kpi_report_version", "hash", H32("content_hash")),
       chk("kpi_report_version", "review", "state IN ('DRAFT', 'CHANGES_REQUESTED') OR submitted_at IS NOT NULL"),
       chk("kpi_report_version", "approved", "state NOT IN ('APPROVED', 'PUBLISHED', 'SUPERSEDED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)"),
       chk("kpi_report_version", "published", "state NOT IN ('PUBLISHED', 'SUPERSEDED') OR (published_by IS NOT NULL AND published_at IS NOT NULL AND content_hash IS NOT NULL AND object_ref IS NOT NULL AND retain_until IS NOT NULL)"),
       chk("kpi_report_version", "mandatory", "state <> 'PUBLISHED' OR NOT missing_mandatory"),
       chk("kpi_report_version", "correction", "(correction_of_version_no IS NULL) = (correction_reason IS NULL) AND (correction_of_version_no IS NULL OR correction_of_version_no < version_no)"),
       chk("kpi_report_version", "correction_reason", "correction_reason IS NULL OR " + reason50("correction_reason")),
       chk("kpi_report_version", "withdrawn", "state <> 'WITHDRAWN' OR (withdrawn_by IS NOT NULL AND withdrawn_at IS NOT NULL AND COALESCE(" + reason50("withdraw_reason") + ", false))"),
       chk("kpi_report_version", "changes", "state <> 'CHANGES_REQUESTED' OR COALESCE(" + reason20("decision_comment") + ", false)")],
      idx=[ix("uq_kpi_report_version_published", "kpi_report_version", "tenant_id, report_id", "state = 'PUBLISHED'", unique=True),
           ix("ix_kpi_report_version_inbox", "kpi_report_version", "tenant_id, state, submitted_at", "state IN ('IN_REVIEW', 'APPROVED')"),
           ix("ix_kpi_report_version_published", "kpi_report_version", "tenant_id, published_at DESC", "state = 'PUBLISHED'")],
      tid=True,
      trig=[("immutable", ["tenant_id", "report_id", "version_no", "prepared_by"]),
            ("frozen", ["state", "IN_REVIEW,APPROVED", "template_id", "run_id", "snapshot", "narrative", "completeness", "missing_mandatory", "document_number", "recipients_note"], "_review"),
            ("frozen", ["state", FINAL, "template_id", "run_id", "snapshot", "narrative", "completeness", "missing_mandatory", "submitted_at", "approved_by", "approved_at",
                        "published_by", "published_at", "content_hash", "object_ref", "retain_until", "correction_of_version_no", "correction_reason", "document_number", "recipients_note"]),
            ("transition", ["state", tmap(REPORT_MAP)]),
            ("no_delete", ["state", "APPROVED," + FINAL]),
            ("raw", "CREATE TRIGGER tg_kpi_report_version_gate BEFORE INSERT OR UPDATE ON ph16_kpi.kpi_report_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_report_version_gate();"),
            ("raw", "CREATE TRIGGER tg_kpi_report_version_sync AFTER INSERT OR UPDATE OF state ON ph16_kpi.kpi_report_version FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_report_sync();")],
      ccomment={"snapshot": "Ảnh chụp bất biến: giá trị, trạng thái, điểm nhóm, phiên bản công thức của từng chỉ tiêu tại thời điểm gửi duyệt; không đọc lại bảng giá trị khi xem bản đã công bố.",
                "content_hash": "SHA-256 (32 byte) của tệp PDF công bố; chữ ký số trong `kpi_report_signature.signed_hash` phải trùng.",
                "object_ref": "Đối tượng PDF ký số trên Ceph RGW (WORM, ADR đề xuất dải 160…164); không lưu tệp trong PostgreSQL.",
                "retain_until": "Ngày hết hạn giữ = ngày công bố + 16.report.retention-years (mặc định 10 năm).",
                "prepared_by": "Người lập; `approved_by` phải khác khi 16.report.four-eyes bật (trigger `tg_kpi_report_version_gate`).",
                "missing_mandatory": "Còn chỉ tiêu bắt buộc thiếu nguồn: CHECK ck_kpi_report_version_mandatory chặn công bố."}),
    T("kpi_report_approval",
      "EN-16-21 Nhật ký duyệt báo cáo: mỗi hành động SUBMIT, REQUEST_CHANGES, APPROVE, PUBLISH, WITHDRAW, CORRECT của một phiên bản, kèm người làm và ý kiến (FR-16-028, 029, 030). Chỉ thêm. Người lập báo cáo không ghi được APPROVE cho báo cáo của mình khi 16.report.four-eyes bật.",
      ["report_version_id uuid NOT NULL", "action varchar(15) NOT NULL", "actor varchar(64) NOT NULL", "acted_at timestamptz NOT NULL DEFAULT now()", "comment varchar(2000)"],
      [fk("kpi_report_approval", "version", "tenant_id, report_version_id", "kpi_report_version", "tenant_id, id"),
       chk("kpi_report_approval", "action", f"action IN {E('approval_action')}"),
       chk("kpi_report_approval", "comment", "action NOT IN ('REQUEST_CHANGES', 'WITHDRAW', 'CORRECT') OR COALESCE(" + reason20("comment") + ", false)")],
      idx=[ix("ix_kpi_report_approval_version", "kpi_report_approval", "tenant_id, report_version_id, acted_at")],
      trig=[("append_only", []), ("raw", "CREATE TRIGGER tg_kpi_report_approval_gate BEFORE INSERT ON ph16_kpi.kpi_report_approval FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_approval_gate();")]),
    T("kpi_report_signature",
      "EN-16-21 Chữ ký số của bản công bố: người ký, thời điểm, định dạng, số sê-ri chứng thư, tham chiếu tệp ký và mã băm đã ký (FR-16-029, 036). Chỉ thêm; mã băm đã ký phải trùng `content_hash` của phiên bản khi công bố.",
      ["report_version_id uuid NOT NULL", "signer varchar(64) NOT NULL", "signed_at timestamptz NOT NULL DEFAULT now()", "signature_format varchar(16) NOT NULL DEFAULT 'PDF_SIGNED'",
       "certificate_serial varchar(64) NOT NULL", "signature_ref varchar(512) NOT NULL", "signed_hash bytea NOT NULL"],
      [fk("kpi_report_signature", "version", "tenant_id, report_version_id", "kpi_report_version", "tenant_id, id"),
       chk("kpi_report_signature", "format", "signature_format IN ('PDF_SIGNED', 'DETACHED')"),
       chk("kpi_report_signature", "hash", "octet_length(signed_hash) = 32")],
      idx=[ix("ix_kpi_report_signature_version", "kpi_report_signature", "tenant_id, report_version_id, signed_at")],
      trig=[("append_only", [])],
      ccomment={"signature_ref": "Đối tượng chữ ký hoặc PDF đã ký trên Ceph RGW; khóa ký nằm ở PH-12 (OpenBao), PH-16 không giữ.",
                "certificate_serial": "Số sê-ri chứng thư số của người ký (ký số theo NĐ 30/2020 do PH-12 thực hiện)."}),
    T("kpi_distribution",
      "EN-16-24 Danh sách phân phối báo cáo: người nhận (người dùng, nhóm, thư điện tử công vụ qua kênh thông báo PH-13), định dạng, loại báo cáo và kỳ gửi theo lịch (FR-16-034).",
      ["distribution_code varchar(63) NOT NULL", "name varchar(255) NOT NULL", "report_type varchar(8) NOT NULL DEFAULT 'PERIODIC'", "period_type varchar(8)",
       "formats text[] NOT NULL DEFAULT '{PDF}'", "recipients jsonb NOT NULL DEFAULT '[]'", "send_on_publish boolean NOT NULL DEFAULT true", "enabled boolean NOT NULL DEFAULT true"],
      [("uq_kpi_distribution_code", "UNIQUE (tenant_id, distribution_code)"),
       chk("kpi_distribution", "code", f"distribution_code ~ '{TCODE_RE}'"),
       chk("kpi_distribution", "type", f"report_type IN {E('report_type')}"),
       chk("kpi_distribution", "period", f"period_type IS NULL OR period_type IN {E('period_type')}"),
       chk("kpi_distribution", "formats", f"cardinality(formats) >= 1 AND formats <@ {ARR('format')}"),
       chk("kpi_distribution", "recipients", "jsonb_typeof(recipients) = 'array' AND jsonb_array_length(recipients) <= 500")],
      tid=True, trig=[("immutable", ["tenant_id", "distribution_code"])],
      ccomment={"recipients": "Mảng {type: USER|GROUP|EMAIL, ref}; thư điện tử chỉ địa chỉ công vụ; gửi qua PH-13, PH-16 không giữ cấu hình thư."}),
    T("kpi_delivery",
      "EN-16-25 Lần giao báo cáo: mỗi người nhận, định dạng của một phiên bản đã công bố qua một danh sách phân phối; theo dõi PENDING, SENT, FAILED và số lần thử (FR-16-034).",
      ["report_version_id uuid NOT NULL", "distribution_id uuid NOT NULL", "recipient_type varchar(5) NOT NULL", "recipient_ref varchar(255) NOT NULL", "format varchar(4) NOT NULL DEFAULT 'PDF'",
       "state varchar(7) NOT NULL DEFAULT 'PENDING'", "attempt smallint NOT NULL DEFAULT 0", "last_attempt_at timestamptz", "sent_at timestamptz", "error_code varchar(11)"],
      [("uq_kpi_delivery_recipient", "UNIQUE (tenant_id, report_version_id, distribution_id, recipient_type, recipient_ref, format)"),
       fk("kpi_delivery", "version", "tenant_id, report_version_id", "kpi_report_version", "tenant_id, id"),
       fk("kpi_delivery", "distribution", "tenant_id, distribution_id", "kpi_distribution", "tenant_id, id"),
       chk("kpi_delivery", "recipient", f"recipient_type IN {E('recipient_type')}"),
       chk("kpi_delivery", "format", f"format IN {E('format')}"),
       chk("kpi_delivery", "state", f"state IN {E('delivery_state')}"),
       chk("kpi_delivery", "attempt", "attempt >= 0"),
       chk("kpi_delivery", "sent", "state <> 'SENT' OR sent_at IS NOT NULL"),
       chk("kpi_delivery", "failed", "state <> 'FAILED' OR error_code IS NOT NULL"),
       chk("kpi_delivery", "error", ERRC("error_code"))],
      idx=[ix("ix_kpi_delivery_pending", "kpi_delivery", "tenant_id, state, created_at", "state <> 'SENT'")],
      trig=[("immutable", ["tenant_id", "report_version_id", "distribution_id", "recipient_type", "recipient_ref", "format"])]),
    T("kpi_export_job",
      "EN-16-23 Lệnh xuất: xuất bản báo cáo, bảng chỉ tiêu của kỳ hoặc sổ kiến trúc ra PDF, XLSX, CSV, JSON lên Ceph RGW; QUEUED, RUNNING, SUCCEEDED, FAILED, EXPIRED; liên kết tải hết hạn sau `16.export.link-hours` (FR-16-033, 036, 049).",
      ["subject_type varchar(16) NOT NULL", "report_version_id uuid", "period_id uuid", "format varchar(4) NOT NULL", "filter jsonb NOT NULL DEFAULT '{}'", "state varchar(9) NOT NULL DEFAULT 'QUEUED'",
       "requested_by varchar(64) NOT NULL", "started_at timestamptz", "finished_at timestamptz", "row_count bigint", "object_ref varchar(512)", "content_hash bytea",
       "expires_at timestamptz", "download_count integer NOT NULL DEFAULT 0", "error_code varchar(11)"],
      [fk("kpi_export_job", "version", "tenant_id, report_version_id", "kpi_report_version", "tenant_id, id"),
       fk("kpi_export_job", "period", "tenant_id, period_id", "kpi_reporting_period", "tenant_id, id"),
       chk("kpi_export_job", "subject", f"subject_type IN {E('export_subject')} AND (subject_type <> 'REPORT' OR report_version_id IS NOT NULL) AND (subject_type NOT IN ('INDICATOR_VALUES', 'OBSERVATIONS') OR period_id IS NOT NULL)"),
       chk("kpi_export_job", "format", f"format IN {E('format')}"),
       chk("kpi_export_job", "state", f"state IN {E('export_state')}"),
       chk("kpi_export_job", "rows", "row_count IS NULL OR row_count >= 0"),
       chk("kpi_export_job", "hash", H32("content_hash")),
       chk("kpi_export_job", "ready", "state NOT IN ('SUCCEEDED', 'EXPIRED') OR (object_ref IS NOT NULL AND content_hash IS NOT NULL AND expires_at IS NOT NULL AND finished_at IS NOT NULL)"),
       chk("kpi_export_job", "failed", "state <> 'FAILED' OR error_code IS NOT NULL"),
       chk("kpi_export_job", "downloads", "download_count >= 0"),
       chk("kpi_export_job", "error", ERRC("error_code"))],
      idx=[ix("ix_kpi_export_job_state", "kpi_export_job", "tenant_id, state, created_at DESC"), ix("ix_kpi_export_job_expiry", "kpi_export_job", "expires_at", "state = 'SUCCEEDED'")],
      tid=True, trig=[("immutable", ["tenant_id", "subject_type", "report_version_id", "period_id", "format", "requested_by"]), ("transition", ["state", tmap(EXPORT_MAP)])],
      ccomment={"row_count": "Không vượt 16.export.max-rows (mặc định 100000) do dịch vụ kiểm."}),
]

# ---------------------------------------------------------------------------------------------
# 16-0050 Sổ kiến trúc, tuân thủ
# ---------------------------------------------------------------------------------------------
LIFE_MAP = {"PLANNED": ["ACTIVE", "RETIRED"], "ACTIVE": ["DEPRECATED", "RETIRED"], "DEPRECATED": ["ACTIVE", "RETIRED"]}
VERSIONED_MAP = {"DRAFT": ["ACTIVE"], "ACTIVE": ["SUPERSEDED"]}
ASSESS_MAP = {"DRAFT": ["SUBMITTED"], "SUBMITTED": ["CONFIRMED", "REJECTED", "DRAFT"], "REJECTED": ["DRAFT"]}
WAIVER_MAP = {"PENDING_APPROVAL": ["ACTIVE", "REJECTED"], "ACTIVE": ["EXPIRED", "REVOKED"]}
G_ARCH = [
    T("kpi_arch_component",
      "EN-16-26 Thành phần kiến trúc của sổ kiến trúc: HTTT, API, luồng, topic, bộ điều hợp, dịch vụ nền tảng, liên kết quốc gia; vòng đời PLANNED, ACTIVE, DEPRECATED, RETIRED, trạng thái vận hành UP, DEGRADED, DOWN, UNKNOWN, nguồn gốc AUTO hoặc MANUAL, mức tuân thủ hiện hành (FR-16-043, 044, 045, 046, 048). Không xóa, chỉ ngừng.",
      ["component_code varchar(63) NOT NULL", "name varchar(255) NOT NULL", "component_type varchar(16) NOT NULL", "lifecycle varchar(10) NOT NULL DEFAULT 'PLANNED'",
       "ops_status varchar(8) NOT NULL DEFAULT 'UNKNOWN'", "ops_updated_at timestamptz", "origin varchar(6) NOT NULL DEFAULT 'MANUAL'", "owner_org_code varchar(63)",
       "source_phase varchar(5)", "source_ref varchar(255)", "current_version_label varchar(32)", "compliance_level varchar(13) NOT NULL DEFAULT 'NOT_ASSESSED'",
       "last_synced_at timestamptz", "orphaned boolean NOT NULL DEFAULT false", "retire_reason varchar(2000)", "description varchar(2000)"],
      [("uq_kpi_arch_component_code", "UNIQUE (tenant_id, component_code)"),
       chk("kpi_arch_component", "code", f"component_code ~ '{TCODE_RE}'"),
       chk("kpi_arch_component", "type", f"component_type IN {E('component_type')}"),
       chk("kpi_arch_component", "lifecycle", f"lifecycle IN {E('lifecycle')}"),
       chk("kpi_arch_component", "ops", f"ops_status IN {E('ops_status')}"),
       chk("kpi_arch_component", "origin", f"origin IN {E('origin')} AND (origin <> 'AUTO' OR source_phase IS NOT NULL)"),
       chk("kpi_arch_component", "phase", f"source_phase IS NULL OR source_phase ~ '{PHASE_RE}'"),
       chk("kpi_arch_component", "owner", f"owner_org_code IS NULL OR owner_org_code ~ '{ORG_RE}'"),
       chk("kpi_arch_component", "compliance", f"compliance_level IN {E('compliance_level')}"),
       chk("kpi_arch_component", "retire", "lifecycle <> 'RETIRED' OR COALESCE(" + reason20("retire_reason") + ", false)")],
      idx=[ix("ix_kpi_arch_component_type", "kpi_arch_component", "tenant_id, component_type, lifecycle"),
           ix("ix_kpi_arch_component_compliance", "kpi_arch_component", "tenant_id, compliance_level, lifecycle"),
           ix("ix_kpi_arch_component_orphan", "kpi_arch_component", "tenant_id, last_synced_at", "origin = 'AUTO'")],
      tid=True, trig=[("immutable", ["tenant_id", "component_code", "component_type"]), ("transition", ["lifecycle", tmap(LIFE_MAP)])],
      ccomment={"origin": "AUTO: tự đăng ký từ sự kiện phân hệ nguồn hoặc `arch.register`; MANUAL: khai báo tay (FR-16-045).",
                "orphaned": "Đối chiếu với phân hệ nguồn thấy thành phần AUTO không còn ở nguồn (FR-16-048).",
                "compliance_level": "Bản sao mức của đánh giá CONFIRMED mới nhất hoặc EXEMPTED khi có miễn trừ hiệu lực; nguồn chuẩn ở `kpi_compliance_assessment`."}),
    T("kpi_arch_component_version",
      "EN-16-27 Phiên bản thành phần kiến trúc: nhãn phiên bản, trạng thái vòng đời của phiên bản, ngày phát hành, mã băm nội dung mô tả dùng cho gói gửi quốc gia (FR-16-045, 052).",
      ["component_id uuid NOT NULL", "version_label varchar(32) NOT NULL", "lifecycle varchar(10) NOT NULL DEFAULT 'PLANNED'", "released_on date", "spec_ref varchar(255)",
       "content_hash bytea", "origin varchar(6) NOT NULL DEFAULT 'MANUAL'", "change_note varchar(2000)"],
      [("uq_kpi_arch_component_version", "UNIQUE (tenant_id, component_id, version_label)"),
       fk("kpi_arch_component_version", "component", "tenant_id, component_id", "kpi_arch_component", "tenant_id, id"),
       chk("kpi_arch_component_version", "label", "version_label ~ '^[0-9A-Za-z][0-9A-Za-z._+-]{0,31}$'"),
       chk("kpi_arch_component_version", "lifecycle", f"lifecycle IN {E('lifecycle')}"),
       chk("kpi_arch_component_version", "origin", f"origin IN {E('origin')}"),
       chk("kpi_arch_component_version", "hash", H32("content_hash"))],
      tid=True, trig=[("immutable", ["tenant_id", "component_id", "version_label"])]),
    T("kpi_arch_dependency",
      "EN-16-28 Phụ thuộc giữa hai thành phần: gọi, phát, đăng ký nhận, chạy trên, phụ thuộc; phục vụ sơ đồ phụ thuộc và phân tích ảnh hưởng (FR-16-045, 049). Gỡ phụ thuộc bằng cờ `removed`, không xóa dòng.",
      ["from_component_id uuid NOT NULL", "to_component_id uuid NOT NULL", "dependency_type varchar(10) NOT NULL", "origin varchar(6) NOT NULL DEFAULT 'MANUAL'",
       "removed boolean NOT NULL DEFAULT false", "description varchar(2000)"],
      [("uq_kpi_arch_dependency", "UNIQUE (tenant_id, from_component_id, to_component_id, dependency_type)"),
       fk("kpi_arch_dependency", "from", "tenant_id, from_component_id", "kpi_arch_component", "tenant_id, id"),
       fk("kpi_arch_dependency", "to", "tenant_id, to_component_id", "kpi_arch_component", "tenant_id, id"),
       chk("kpi_arch_dependency", "self", "from_component_id <> to_component_id"),
       chk("kpi_arch_dependency", "type", f"dependency_type IN {E('dep_type')}"),
       chk("kpi_arch_dependency", "origin", f"origin IN {E('origin')}")],
      idx=[ix("ix_kpi_arch_dependency_to", "kpi_arch_dependency", "tenant_id, to_component_id", "NOT removed")],
      trig=[("immutable", ["tenant_id", "from_component_id", "to_component_id", "dependency_type"])]),
    T("kpi_arch_reconciliation",
      "EN-16-33 Lần đối chiếu sổ kiến trúc với phân hệ nguồn (hằng tuần hoặc chạy tay): RUNNING, SUCCEEDED, PARTIAL (có phân hệ không trả lời), FAILED; mỗi tenant tối đa một lần đang chạy (ERR-16-056) (FR-16-048).",
      ["state varchar(9) NOT NULL DEFAULT 'RUNNING'", "component_types text[] NOT NULL DEFAULT '{}'", "started_by varchar(64) NOT NULL", "started_at timestamptz NOT NULL DEFAULT now()",
       "finished_at timestamptz", "item_count integer NOT NULL DEFAULT 0", "skipped_phases text[] NOT NULL DEFAULT '{}'"],
      [chk("kpi_arch_reconciliation", "state", f"state IN {E('recon_state')}"),
       chk("kpi_arch_reconciliation", "types", f"component_types <@ {ARR('component_type')}"),
       chk("kpi_arch_reconciliation", "finished", "(state = 'RUNNING') = (finished_at IS NULL)"),
       chk("kpi_arch_reconciliation", "partial", "state <> 'PARTIAL' OR cardinality(skipped_phases) >= 1"),
       chk("kpi_arch_reconciliation", "count", "item_count >= 0")],
      idx=[ix("uq_kpi_arch_reconciliation_running", "kpi_arch_reconciliation", "tenant_id", "state = 'RUNNING'", unique=True),
           ix("ix_kpi_arch_reconciliation_time", "kpi_arch_reconciliation", "tenant_id, started_at DESC")],
      tid=True, trig=[("immutable", ["tenant_id", "component_types", "started_by", "started_at"]), ("transition", ["state", tmap({"RUNNING": ["SUCCEEDED", "PARTIAL", "FAILED"]})])]),
    T("kpi_arch_recon_item",
      "EN-16-33 Mục lệch của lần đối chiếu: MISSING (nguồn có, sổ không), ORPHAN (sổ có, nguồn không), MISMATCH (vòng đời, phiên bản khác); xử lý OPEN, REGISTERED, RETIRED, UPDATED hoặc IGNORED kèm lý do (FR-16-048, ERR-16-120).",
      ["recon_id uuid NOT NULL", "item_kind varchar(8) NOT NULL", "component_code varchar(63) NOT NULL", "component_id uuid", "source_phase varchar(5) NOT NULL", "source_ref varchar(255)",
       "diff jsonb NOT NULL DEFAULT '{}'", "resolution varchar(10) NOT NULL DEFAULT 'OPEN'", "resolution_reason varchar(2000)", "resolved_by varchar(64)", "resolved_at timestamptz"],
      [("uq_kpi_arch_recon_item", "UNIQUE (tenant_id, recon_id, item_kind, component_code)"),
       fk("kpi_arch_recon_item", "recon", "tenant_id, recon_id", "kpi_arch_reconciliation", "tenant_id, id"),
       fk("kpi_arch_recon_item", "component", "tenant_id, component_id", "kpi_arch_component", "tenant_id, id"),
       chk("kpi_arch_recon_item", "kind", f"item_kind IN {E('recon_item_kind')}"),
       chk("kpi_arch_recon_item", "resolution", f"resolution IN {E('recon_resolution')}"),
       chk("kpi_arch_recon_item", "phase", f"source_phase ~ '{PHASE_RE}'"),
       chk("kpi_arch_recon_item", "orphan", "item_kind = 'MISSING' OR component_id IS NOT NULL"),
       chk("kpi_arch_recon_item", "diff", "jsonb_typeof(diff) = 'object'"),
       chk("kpi_arch_recon_item", "resolved", "(resolution = 'OPEN') = (resolved_by IS NULL AND resolved_at IS NULL)"),
       chk("kpi_arch_recon_item", "ignored", "resolution <> 'IGNORED' OR COALESCE(" + reason20("resolution_reason") + ", false)")],
      idx=[ix("ix_kpi_arch_recon_item_open", "kpi_arch_recon_item", "tenant_id, recon_id", "resolution = 'OPEN'")],
      trig=[("immutable", ["tenant_id", "recon_id", "item_kind", "component_code", "source_phase", "source_ref", "diff"]),
            ("transition", ["resolution", tmap({"OPEN": ["REGISTERED", "RETIRED", "UPDATED", "IGNORED"]})])]),
    T("kpi_compliance_criterion",
      "EN-16-29, EN-16-30 Tiêu chí tuân thủ kiến trúc: bộ tiêu chí cấu hình có phiên bản, áp cho loại thành phần, có trọng số và cờ bắt buộc; bộ mẫu COMMON theo Khung kiến trúc CPĐT 3.0 (CMP-LAW-10) và dự thảo Khung kiến trúc tổng thể quốc gia số (CMP-LAW-11) khi ban hành (FR-16-047). ACTIVE bất biến, mỗi mã một phiên bản ACTIVE. Dòng COMMON mọi tenant đọc được (mẫu RLS S).",
      ["criterion_code varchar(32) NOT NULL", "version_no integer NOT NULL DEFAULT 1", "name varchar(255) NOT NULL", "description varchar(2000)", "applies_to text[] NOT NULL",
       "mandatory boolean NOT NULL DEFAULT false", "weight numeric(5,4) NOT NULL DEFAULT 1.0000", "framework_ref varchar(64)", "state varchar(10) NOT NULL DEFAULT 'DRAFT'",
       "activated_at timestamptz"],
      [("uq_kpi_compliance_criterion_version", "UNIQUE (tenant_id, criterion_code, version_no)"),
       chk("kpi_compliance_criterion", "code", "criterion_code ~ '^[A-Z][A-Z0-9-]{2,31}$'"),
       chk("kpi_compliance_criterion", "no", "version_no >= 1"),
       chk("kpi_compliance_criterion", "applies", f"cardinality(applies_to) >= 1 AND applies_to <@ {ARR('component_type')}"),
       chk("kpi_compliance_criterion", "weight", "weight >= 0 AND weight <= 1"),
       chk("kpi_compliance_criterion", "state", f"state IN {E('criteria_state')}"),
       chk("kpi_compliance_criterion", "active", "state = 'DRAFT' OR activated_at IS NOT NULL")],
      idx=[ix("uq_kpi_compliance_criterion_active", "kpi_compliance_criterion", "tenant_id, criterion_code", "state = 'ACTIVE'", unique=True)],
      tid=True, rls="S",
      trig=[("immutable", ["tenant_id", "criterion_code", "version_no"]),
            ("frozen", ["state", "ACTIVE,SUPERSEDED", "applies_to", "mandatory", "weight", "framework_ref"]), ("transition", ["state", tmap(VERSIONED_MAP)])],
      ccomment={"framework_ref": "Mã CMP-LAW hoặc điều khoản khung kiến trúc nếu có; để NULL khi tiêu chí tối thiểu của sổ chưa đối chiếu khung (Q16-53)."}),
    T("kpi_compliance_assessment",
      "EN-16-31 Đánh giá tuân thủ một thành phần (hoặc một phiên bản) theo bộ tiêu chí: DRAFT, SUBMITTED, CONFIRMED, REJECTED, kết quả COMPLIANT, PARTIAL, NON_COMPLIANT; người xác nhận khác người đánh giá (FR-16-047). CONFIRMED và REJECTED không đổi nội dung.",
      ["component_id uuid NOT NULL", "component_version_id uuid", "state varchar(9) NOT NULL DEFAULT 'DRAFT'", "level_result varchar(13)", "score numeric(5,2)", "summary varchar(4000)",
       "assessed_by varchar(64) NOT NULL", "assessed_at timestamptz NOT NULL DEFAULT now()", "submitted_at timestamptz", "confirmed_by varchar(64)", "confirmed_at timestamptz",
       "decision_comment varchar(2000)"],
      [fk("kpi_compliance_assessment", "component", "tenant_id, component_id", "kpi_arch_component", "tenant_id, id"),
       fk("kpi_compliance_assessment", "version", "tenant_id, component_version_id", "kpi_arch_component_version", "tenant_id, id"),
       chk("kpi_compliance_assessment", "state", f"state IN {E('assessment_state')}"),
       chk("kpi_compliance_assessment", "level", "level_result IS NULL OR level_result IN ('COMPLIANT', 'PARTIAL', 'NON_COMPLIANT')"),
       chk("kpi_compliance_assessment", "score", "score IS NULL OR (score >= 0 AND score <= 100)"),
       chk("kpi_compliance_assessment", "four_eyes", four_eyes("confirmed_by", "assessed_by")),
       chk("kpi_compliance_assessment", "submitted", "state = 'DRAFT' OR (submitted_at IS NOT NULL AND level_result IS NOT NULL)"),
       chk("kpi_compliance_assessment", "confirmed", "state <> 'CONFIRMED' OR (confirmed_by IS NOT NULL AND confirmed_at IS NOT NULL)"),
       chk("kpi_compliance_assessment", "rejected", "state <> 'REJECTED' OR (confirmed_by IS NOT NULL AND COALESCE(" + reason20("decision_comment") + ", false))")],
      idx=[ix("ix_kpi_compliance_assessment_component", "kpi_compliance_assessment", "tenant_id, component_id, state, confirmed_at DESC"),
           ix("ix_kpi_compliance_assessment_inbox", "kpi_compliance_assessment", "tenant_id, submitted_at", "state = 'SUBMITTED'")],
      tid=True,
      trig=[("immutable", ["tenant_id", "component_id", "assessed_by"]),
            ("frozen", ["state", "CONFIRMED,REJECTED", "component_version_id", "level_result", "score", "summary", "assessed_at", "submitted_at"]),
            ("transition", ["state", tmap(ASSESS_MAP)])]),
    T("kpi_compliance_item",
      "EN-16-31 Mục đánh giá: kết quả từng tiêu chí của một đánh giá PASS (đạt), FAIL (không đạt), NA (không áp dụng) kèm bằng chứng và ghi chú (FR-16-047). Chỉ sửa khi đánh giá còn DRAFT.",
      ["assessment_id uuid NOT NULL", "criterion_id uuid NOT NULL", "result varchar(4) NOT NULL", "evidence_ref varchar(512)", "note varchar(2000)", "item_score numeric(5,2)"],
      [("uq_kpi_compliance_item", "UNIQUE (tenant_id, assessment_id, criterion_id)"),
       fk("kpi_compliance_item", "assessment", "tenant_id, assessment_id", "kpi_compliance_assessment", "tenant_id, id"),
       fk("kpi_compliance_item", "criterion", "tenant_id, criterion_id", "kpi_compliance_criterion", "tenant_id, id"),
       chk("kpi_compliance_item", "result", f"result IN {E('item_result')}"),
       chk("kpi_compliance_item", "score", "item_score IS NULL OR (item_score >= 0 AND item_score <= 100)"),
       chk("kpi_compliance_item", "note", "result NOT IN ('FAIL', 'NA') OR COALESCE(" + reason20("note") + ", false)")],
      trig=[("immutable", ["tenant_id", "assessment_id", "criterion_id"]), ("child_frozen", ["kpi_compliance_assessment", "assessment_id", "DRAFT"])]),
    T("kpi_compliance_waiver",
      "EN-16-32 Miễn trừ có hạn: miễn một tiêu chí (hoặc toàn bộ) cho một thành phần, lý do từ 50 ký tự, hạn không quá 366 ngày (tham số 16.compliance.waiver-max-days mặc định 180 ngày do dịch vụ kiểm), người duyệt khác người đề nghị (FR-16-047). PENDING_APPROVAL, ACTIVE, EXPIRED, REVOKED, REJECTED.",
      ["component_id uuid NOT NULL", "criterion_id uuid", "reason varchar(2000) NOT NULL", "valid_from date NOT NULL", "valid_to date NOT NULL", "state varchar(16) NOT NULL DEFAULT 'PENDING_APPROVAL'",
       "requested_by varchar(64) NOT NULL", "approved_by varchar(64)", "approved_at timestamptz", "decision_comment varchar(2000)"],
      [fk("kpi_compliance_waiver", "component", "tenant_id, component_id", "kpi_arch_component", "tenant_id, id"),
       fk("kpi_compliance_waiver", "criterion", "tenant_id, criterion_id", "kpi_compliance_criterion", "tenant_id, id"),
       chk("kpi_compliance_waiver", "state", f"state IN {E('waiver_state')}"),
       chk("kpi_compliance_waiver", "period", "valid_to > valid_from AND valid_to - valid_from <= 366"),
       chk("kpi_compliance_waiver", "reason", reason50("reason")),
       chk("kpi_compliance_waiver", "four_eyes", four_eyes("approved_by", "requested_by")),
       chk("kpi_compliance_waiver", "active", "state NOT IN ('ACTIVE', 'EXPIRED', 'REVOKED') OR (approved_by IS NOT NULL AND approved_at IS NOT NULL)"),
       chk("kpi_compliance_waiver", "decision", "state NOT IN ('REJECTED', 'REVOKED') OR COALESCE(" + reason20("decision_comment") + ", false)")],
      idx=[ix("ix_kpi_compliance_waiver_component", "kpi_compliance_waiver", "tenant_id, component_id, state"),
           ix("ix_kpi_compliance_waiver_expiry", "kpi_compliance_waiver", "tenant_id, valid_to", "state = 'ACTIVE'")],
      tid=True,
      trig=[("immutable", ["tenant_id", "component_id", "criterion_id", "requested_by"]),
            ("frozen", ["state", "ACTIVE,EXPIRED,REVOKED,REJECTED", "reason", "valid_from", "valid_to"]), ("transition", ["state", tmap(WAIVER_MAP)])]),
]

# ---------------------------------------------------------------------------------------------
# 16-0060 Gửi quốc gia
# ---------------------------------------------------------------------------------------------
PRE["16-0060-national.sql"] = """-- @changeset ph16-0600-fn-submission-gate splitStatements:false
CREATE OR REPLACE FUNCTION ph16_kpi.f_submission_gate() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  IF NOT ph16_kpi.f_setting_bool(NEW.tenant_id, '16.national.enabled', false) THEN
    RAISE EXCEPTION 'Gửi quốc gia chưa bật (16.national.enabled = false)' USING ERRCODE = '55000';
  END IF;
  IF NEW.state <> 'PENDING' THEN
    RAISE EXCEPTION 'Gói gửi quốc gia mới phải ở trạng thái PENDING' USING ERRCODE = '55000';
  END IF;
  IF NEW.submission_type = 'KPI_REPORT'
     AND NOT EXISTS (SELECT 1 FROM ph16_kpi.kpi_report_version v WHERE v.tenant_id = NEW.tenant_id AND v.id = NEW.report_version_id AND v.state = 'PUBLISHED') THEN
    RAISE EXCEPTION 'Chỉ gửi quốc gia phiên bản báo cáo đã công bố (PUBLISHED)' USING ERRCODE = '55000';
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph16_kpi.f_submission_gate() IS 'Cổng gửi quốc gia: tham số 16.national.enabled bật, gói mới ở PENDING, báo cáo phải PUBLISHED (FR-16-051).';
-- @rollback DROP FUNCTION IF EXISTS ph16_kpi.f_submission_gate();
"""
SUB_MAP = {"PENDING": ["SENDING"], "SENDING": ["SENT", "FAILED"], "SENT": ["ACKNOWLEDGED", "REJECTED"], "FAILED": ["SENDING"]}
G_NATIONAL = [
    T("kpi_national_template",
      "EN-16-34 Mẫu gói quốc gia có phiên bản: cách ánh xạ chỉ tiêu hoặc sổ kiến trúc sang lược đồ của nền tảng quốc gia, là cấu hình ngoài vì khung quốc gia chưa ban hành (CMP-LAW-11 dự thảo, ADR đề xuất dải 160…164); kênh gửi là PH-14 (FR-16-050). ACTIVE bất biến, mỗi mã một phiên bản ACTIVE. Dòng COMMON do PLATFORM quản, mọi tenant đọc được (mẫu RLS S).",
      ["template_code varchar(63) NOT NULL", "version_no integer NOT NULL DEFAULT 1", "submission_type varchar(13) NOT NULL", "name varchar(255) NOT NULL", "state varchar(10) NOT NULL DEFAULT 'DRAFT'",
       "mapping jsonb NOT NULL DEFAULT '{}'", "schema_ref varchar(255)", "channel_ref varchar(64) NOT NULL DEFAULT 'PH-14'", "effective_from date", "approved_by varchar(64)",
       "activated_at timestamptz", "description varchar(2000)"],
      [("uq_kpi_national_template_version", "UNIQUE (tenant_id, template_code, version_no)"),
       chk("kpi_national_template", "code", f"template_code ~ '{TCODE_RE}'"),
       chk("kpi_national_template", "no", "version_no >= 1"),
       chk("kpi_national_template", "type", f"submission_type IN {E('submission_type')}"),
       chk("kpi_national_template", "state", f"state IN {E('national_template_state')}"),
       chk("kpi_national_template", "mapping", "jsonb_typeof(mapping) = 'object'"),
       chk("kpi_national_template", "active", "state = 'DRAFT' OR (activated_at IS NOT NULL AND approved_by IS NOT NULL)")],
      idx=[ix("uq_kpi_national_template_active", "kpi_national_template", "tenant_id, template_code", "state = 'ACTIVE'", unique=True)],
      tid=True, rls="S",
      trig=[("immutable", ["tenant_id", "template_code", "version_no", "submission_type"]), ("frozen", ["state", "ACTIVE,SUPERSEDED", "mapping", "schema_ref", "channel_ref", "effective_from"]),
            ("transition", ["state", tmap(VERSIONED_MAP)])],
      ccomment={"mapping": "Ánh xạ trường nội bộ sang lược đồ nền tảng quốc gia; thay đổi khi khung ban hành chỉ cần phiên bản mẫu mới, không đổi mã."}),
    T("kpi_national_submission",
      "EN-16-35 Gói gửi quốc gia: báo cáo chỉ tiêu (KPI_REPORT) hoặc sổ kiến trúc (ARCH_REGISTRY) gửi qua PH-14; PENDING, SENDING, SENT, ACKNOWLEDGED, REJECTED, FAILED; idempotent theo `report_code` + `report_version_no` hoặc `component_code` + `version_label` + `content_hash` (FR-16-051, 052, 054). Chỉ tạo khi `16.national.enabled` bật; báo cáo phải PUBLISHED.",
      ["submission_type varchar(13) NOT NULL", "template_id uuid NOT NULL", "state varchar(12) NOT NULL DEFAULT 'PENDING'", "report_version_id uuid", "report_code varchar(63)",
       "report_version_no integer", "component_version_id uuid", "component_code varchar(63)", "version_label varchar(32)", "content_hash bytea NOT NULL",
       "submitted_by varchar(64) NOT NULL", "attempt_count smallint NOT NULL DEFAULT 0", "sent_at timestamptz", "channel_ref varchar(128)", "ack_ref varchar(128)", "ack_at timestamptz",
       "last_error_code varchar(11)", "last_error_detail varchar(2000)"],
      [fk("kpi_national_submission", "template", "tenant_id, template_id", "kpi_national_template", "tenant_id, id"),
       fk("kpi_national_submission", "report", "tenant_id, report_version_id", "kpi_report_version", "tenant_id, id"),
       fk("kpi_national_submission", "component", "tenant_id, component_version_id", "kpi_arch_component_version", "tenant_id, id"),
       chk("kpi_national_submission", "type", f"submission_type IN {E('submission_type')}"),
       chk("kpi_national_submission", "state", f"state IN {E('submission_state')}"),
       chk("kpi_national_submission", "subject", "(submission_type = 'KPI_REPORT' AND report_version_id IS NOT NULL AND report_code IS NOT NULL AND report_version_no IS NOT NULL AND component_code IS NULL AND version_label IS NULL) "
           "OR (submission_type = 'ARCH_REGISTRY' AND component_version_id IS NOT NULL AND component_code IS NOT NULL AND version_label IS NOT NULL AND report_code IS NULL AND report_version_no IS NULL)"),
       chk("kpi_national_submission", "hash", "octet_length(content_hash) = 32"),
       chk("kpi_national_submission", "attempt", "attempt_count >= 0"),
       chk("kpi_national_submission", "sent", "state NOT IN ('SENT', 'ACKNOWLEDGED', 'REJECTED') OR sent_at IS NOT NULL"),
       chk("kpi_national_submission", "ack", "state <> 'ACKNOWLEDGED' OR (ack_at IS NOT NULL AND ack_ref IS NOT NULL)"),
       chk("kpi_national_submission", "failed", "state NOT IN ('FAILED', 'REJECTED') OR last_error_code IS NOT NULL"),
       chk("kpi_national_submission", "error", ERRC("last_error_code"))],
      idx=[ix("uq_kpi_national_submission_report", "kpi_national_submission", "tenant_id, report_code, report_version_no", "submission_type = 'KPI_REPORT'", unique=True),
           ix("uq_kpi_national_submission_arch", "kpi_national_submission", "tenant_id, component_code, version_label, content_hash", "submission_type = 'ARCH_REGISTRY'", unique=True),
           ix("ix_kpi_national_submission_state", "kpi_national_submission", "tenant_id, state, updated_at DESC")],
      tid=True,
      trig=[("immutable", ["tenant_id", "submission_type", "template_id", "report_version_id", "report_code", "report_version_no", "component_version_id", "component_code", "version_label",
                           "content_hash", "submitted_by"]),
            ("transition", ["state", tmap(SUB_MAP)]),
            ("raw", "CREATE TRIGGER tg_kpi_national_submission_gate BEFORE INSERT ON ph16_kpi.kpi_national_submission FOR EACH ROW EXECUTE FUNCTION ph16_kpi.f_submission_gate();")],
      ccomment={"channel_ref": "Mã giao dịch của PH-14 (EVT-14-11, 12); PH-16 không giữ thông tin xác thực quốc gia (OpenBao ở PH-14).",
                "attempt_count": "Số lần gửi; không vượt 16.national.retry-max + 1 do dịch vụ kiểm."}),
    T("kpi_national_submission_log",
      "EN-16-36 Nhật ký nộp: bằng chứng từng bước gửi quốc gia (tạo, gửi, biên nhận, từ chối, lỗi, gửi lại) kèm băm yêu cầu, băm phản hồi, mã giao dịch PH-14. Chỉ thêm, không sửa, xóa kể cả chủ schema; giữ như báo cáo công bố (FR-16-053).",
      ["submission_id uuid NOT NULL", "seq integer NOT NULL", "event_type varchar(12) NOT NULL", "state_after varchar(12) NOT NULL", "actor varchar(64) NOT NULL",
       "occurred_at timestamptz NOT NULL DEFAULT now()", "request_hash bytea", "response_hash bytea", "channel_ref varchar(128)", "error_code varchar(11)", "detail varchar(2000)"],
      [("uq_kpi_national_submission_log_seq", "UNIQUE (tenant_id, submission_id, seq)"),
       fk("kpi_national_submission_log", "submission", "tenant_id, submission_id", "kpi_national_submission", "tenant_id, id"),
       chk("kpi_national_submission_log", "seq", "seq >= 1"),
       chk("kpi_national_submission_log", "event", f"event_type IN {E('submission_event')}"),
       chk("kpi_national_submission_log", "state", f"state_after IN {E('submission_state')}"),
       chk("kpi_national_submission_log", "req_hash", H32("request_hash")),
       chk("kpi_national_submission_log", "resp_hash", H32("response_hash")),
       chk("kpi_national_submission_log", "error", ERRC("error_code"))],
      idx=[ix("ix_kpi_national_submission_log_time", "kpi_national_submission_log", "tenant_id, occurred_at DESC")],
      trig=[("append_only", [])]),
]

# ---------------------------------------------------------------------------------------------
# 16-0070 Vận hành
# ---------------------------------------------------------------------------------------------
SETTINGS = [
    ("16.period.types", '"MONTH,QUARTER,YEAR"'), ("16.period.close-day", "5"), ("16.period.auto-close", "true"), ("16.aggregate.cron", '"0 30 1 * * *"'),
    ("16.aggregate.timeout-minutes", "15"), ("16.aggregate.formula-timeout-ms", "50"), ("16.source.stale-hours", "26"), ("16.source.fail-after", "3"),
    ("16.late-data.recompute", "true"), ("16.late-data.debounce-minutes", "5"), ("16.manual.evidence-required", "true"), ("16.manual.max-file-mb", "20"),
    ("16.report.four-eyes", "true"), ("16.report.signing", "true"), ("16.report.retention-years", "10"), ("16.report.auto-draft", "true"),
    ("16.observation.retention-months", "36"), ("16.export.link-hours", "24"), ("16.export.max-rows", "100000"), ("16.national.enabled", "false"),
    ("16.national.retry-max", "5"), ("16.national.arch-schedule", '"0 0 3 1 * ?"'), ("16.compare.min-tenants", "3"), ("16.compliance.waiver-max-days", "180"),
    ("16.overview.pinned-indicators", '""'),
]
assert len(SETTINGS) == 25  # đủ 25 khóa của FRS §8.2
SETTING_CODES = [k for k, _ in SETTINGS]
BOOL_CODES = [k for k, v in SETTINGS if v in ("true", "false")]
NUM_CODES = [k for k, v in SETTINGS if v.isdigit()]
codes_sql = lambda L: ", ".join("'%s'" % x for x in L)
OUTBOX_TOPICS = ["indicator.activated", "indicator.retired", "source.state-changed", "manual-value.decided", "period.computed", "indicator.status-changed", "report.submitted",
                 "report.published", "report.state-changed", "arch-component.changed", "arch-compliance.assessed", "national-submission.state-changed", "export.completed", "period.state-changed"]
G_OPS = [
    T("kpi_tenant_setting",
      "EN-16-39 Tham số phân hệ theo tenant: 25 tham số 16.* của FRS §8.2 (kỳ, lịch tổng hợp, độ tươi nguồn, số liệu trễ, bằng chứng số liệu tay, bốn mắt, ký số, lưu giữ, xuất, gửi quốc gia, so sánh, hạn miễn trừ, ghim Tổng quan) (FR-16-055, 057). Chỉ nhận mã đã khai báo, kiểu giá trị đúng theo mã; trigger của các bảng khác đọc tham số này.",
      ["param_code varchar(64) NOT NULL", "value jsonb NOT NULL", "description varchar(500)"],
      [("uq_kpi_tenant_setting_code", "UNIQUE (tenant_id, param_code)"),
       chk("kpi_tenant_setting", "code", f"param_code IN ({codes_sql(SETTING_CODES)})"),
       chk("kpi_tenant_setting", "type", f"CASE WHEN param_code IN ({codes_sql(BOOL_CODES)}) THEN jsonb_typeof(value) = 'boolean' "
           f"WHEN param_code IN ({codes_sql(NUM_CODES)}) THEN jsonb_typeof(value) = 'number' ELSE jsonb_typeof(value) = 'string' END")],
      trig=[("immutable", ["tenant_id", "param_code"])]),
    T("outbox_event",
      "Hạ tầng. Outbox (SAD 7.3) cho EVT-16-01…14 và bản ghi kiểm toán gửi PH-13 (FR-16-056, 058). Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL và định tuyến theo topic `{tenant}.kpi.{thực-thể}.{sự-kiện}.v1`. Dọn sau 3 ngày.",
      ["event_id uuid NOT NULL", "topic varchar(128) NOT NULL", "aggregate_type varchar(32) NOT NULL", "aggregate_id uuid NOT NULL", "payload jsonb NOT NULL", "trace_id char(32) NOT NULL",
       "occurred_at timestamptz NOT NULL DEFAULT now()", "published_at timestamptz"],
      [("pk_outbox_event", "PRIMARY KEY (event_id)"),
       chk("outbox_event", "tenant", f"tenant_id ~ '{TENANT_RE}'"),
       chk("outbox_event", "prefix", "split_part(topic, '.', 1) = lower(tenant_id)"),
       chk("outbox_event", "topic", "substr(topic, length(split_part(topic, '.', 1)) + 2) IN (" + ", ".join("'kpi.%s.v1'" % x for x in OUTBOX_TOPICS) + ", 'audit.recorded.v1')"),
       chk("outbox_event", "trace", "trace_id ~ '^[0-9a-f]{32}$'"),
       chk("outbox_event", "payload", "jsonb_typeof(payload) = 'object'")],
      idx=[ix("ix_outbox_event_occurred", "outbox_event", "occurred_at")], std=False, nopk=True),
    T("inbox_event",
      "Hạ tầng. Khử trùng sự kiện nhận: sự kiện của phân hệ nguồn (EVT-01-03, EVT-02-05, EVT-04-07, EVT-08-14, EVT-10-01, EVT-14-12, EVT-19-07…) tiêu thụ lũy đẳng theo event_id cho tự đăng ký sổ kiến trúc và nhận quan sát (FR-16-010, 044). Dọn sau 30 ngày.",
      ["consumer varchar(64) NOT NULL", "event_id uuid NOT NULL", "source_topic varchar(128) NOT NULL", "received_at timestamptz NOT NULL DEFAULT now()", "processed_at timestamptz"],
      [("pk_inbox_event", "PRIMARY KEY (tenant_id, consumer, event_id)"),
       chk("inbox_event", "tenant", f"tenant_id ~ '{TENANT_RE}'"),
       chk("inbox_event", "consumer", "consumer ~ '^[A-Z][A-Za-z0-9]+$'"),
       chk("inbox_event", "prefix", "split_part(source_topic, '.', 1) = lower(tenant_id)")],
      idx=[ix("ix_inbox_event_received", "inbox_event", "received_at")], std=False, nopk=True),
]
FILE_GROUPS += [("16-0040-report.sql", G_REPORT), ("16-0050-arch.sql", G_ARCH), ("16-0060-national.sql", G_NATIONAL), ("16-0070-ops.sql", G_OPS)]


# ---------------------------------------------------------------------------------------------
# Hạt giống COMMON
# ---------------------------------------------------------------------------------------------
GROUPS = [("KET_NOI", "Kết nối, tích hợp", "Mức độ HTTT kết nối, tốc độ kết nạp và xây luồng.", 1),
          ("CHIA_SE", "Chia sẻ, khai thác dữ liệu", "Số API công bố, lượt khai thác, nhật ký, đối soát.", 2),
          ("DU_LIEU", "Chất lượng, danh mục dữ liệu", "Điểm chất lượng, quản lý danh mục tập trung.", 3),
          ("VAN_HANH", "Vận hành, an toàn", "Sẵn sàng, độ trễ, sự cố, hồ sơ cấp độ, bí mật ngoài kho.", 4),
          ("KIEN_TRUC", "Tuân thủ kiến trúc, triển khai", "Khởi tạo tenant, giao diện quản trị, hài lòng người dùng, thành phần đã đánh giá.", 5)]
# (mã, nhóm, tên, kind, direction, measurement, unit, aggregation, mandatory, KPI BRD)
IND = [
    ("httt-ket-noi-ty-le", "KET_NOI", "Tỷ lệ HTTT đã kết nối", "RATIO", "HIGHER_BETTER", "AUTO", "%", "LAST", True, "KPI-01"),
    ("ket-noi-diem-diem-con-lai", "KET_NOI", "Số kết nối điểm-điểm còn lại", "COUNT", "LOWER_BETTER", "MANUAL", "kết nối", "LAST", False, "KPI-02"),
    ("san-sang-data-plane", "VAN_HANH", "Độ sẵn sàng của data plane", "RATIO", "HIGHER_BETTER", "AUTO", "%", "LAST", True, "KPI-03"),
    ("tre-gateway-p95", "VAN_HANH", "Độ trễ cổng p95", "DURATION", "LOWER_BETTER", "AUTO", "ms", "P95", True, "KPI-04"),
    ("thoi-gian-ket-nap-httt", "KET_NOI", "Thời gian kết nạp HTTT", "DURATION", "LOWER_BETTER", "AUTO", "ngày", "AVG", False, "KPI-05"),
    ("thoi-gian-xay-luong", "KET_NOI", "Thời gian xây luồng", "DURATION", "LOWER_BETTER", "AUTO", "ngày", "AVG", False, "KPI-06"),
    ("nhat-ky-khai-thac-du", "CHIA_SE", "Tỷ lệ lượt khai thác có nhật ký đủ", "RATIO", "HIGHER_BETTER", "AUTO", "%", "LAST", True, "KPI-07"),
    ("ho-so-cap-do-phe-duyet", "VAN_HANH", "Hồ sơ cấp độ ATTT được phê duyệt", "BOOLEAN", "HIGHER_BETTER", "MANUAL", "đạt/không đạt", "LAST", False, "KPI-08"),
    ("bi-mat-ngoai-kho", "VAN_HANH", "Số thông tin xác thực nằm ngoài kho bảo mật", "COUNT", "LOWER_BETTER", "MIXED", "mục", "LAST", True, "KPI-09"),
    ("danh-muc-quan-ly-tap-trung", "DU_LIEU", "Tỷ lệ danh mục quản lý tập trung", "RATIO", "HIGHER_BETTER", "AUTO", "%", "LAST", False, "KPI-10"),
    ("tre-dong-bo-danh-muc-qg", "DU_LIEU", "Độ trễ đồng bộ danh mục quốc gia", "DURATION", "LOWER_BETTER", "AUTO", "giờ", "AVG", False, "KPI-11"),
    ("thoi-gian-khoi-tao-tenant", "KIEN_TRUC", "Thời gian khởi tạo tenant", "DURATION", "LOWER_BETTER", "AUTO", "ngày", "MAX", False, "KPI-12"),
    ("doi-soat-tu-dong-khop", "CHIA_SE", "Tỷ lệ đối soát tự động khớp", "RATIO", "HIGHER_BETTER", "AUTO", "%", "AVG", False, "KPI-13"),
    ("thoi-gian-phat-hien-lech", "CHIA_SE", "Thời gian phát hiện chênh lệch", "DURATION", "LOWER_BETTER", "AUTO", "ngày", "AVG", False, "KPI-14"),
    ("mttd", "VAN_HANH", "Thời gian trung bình phát hiện sự cố", "DURATION", "LOWER_BETTER", "AUTO", "phút", "AVG", False, "KPI-15"),
    ("mttr-muc-1", "VAN_HANH", "Thời gian trung bình khắc phục sự cố mức 1", "DURATION", "LOWER_BETTER", "AUTO", "giờ", "AVG", False, "KPI-16"),
    ("so-giao-dien-quan-tri", "KIEN_TRUC", "Số giao diện quản trị", "COUNT", "TARGET_RANGE", "MANUAL", "giao diện", "LAST", False, "KPI-17"),
    ("diem-hai-long-sus", "KIEN_TRUC", "Điểm hài lòng người dùng (SUS)", "SCORE", "HIGHER_BETTER", "MANUAL", "điểm", "LAST", False, "KPI-18"),
    ("api-cong-bo", "CHIA_SE", "Số API đã công bố", "COUNT", "HIGHER_BETTER", "AUTO", "API", "LAST", False, None),
    ("luot-khai-thac-thang", "CHIA_SE", "Số lượt khai thác trong kỳ", "COUNT", "HIGHER_BETTER", "AUTO", "lượt", "SUM", False, None),
    ("api-dat-sla-ty-le", "CHIA_SE", "Tỷ lệ API đạt cam kết mức dịch vụ", "RATIO", "HIGHER_BETTER", "AUTO", "%", "AVG", False, None),
    ("diem-chat-luong-du-lieu", "DU_LIEU", "Điểm chất lượng dữ liệu", "SCORE", "HIGHER_BETTER", "AUTO", "điểm", "LAST", False, None),
    ("giao-dich-thanh-toan-truc-tuyen", "CHIA_SE", "Số giao dịch thanh toán trực tuyến", "COUNT", "HIGHER_BETTER", "AUTO", "giao dịch", "SUM", False, None),
    ("thanh-phan-da-danh-gia-tuan-thu", "KIEN_TRUC", "Tỷ lệ thành phần đã đánh giá tuân thủ", "RATIO", "HIGHER_BETTER", "AUTO", "%", "LAST", False, None),
]
assert len(IND) == 24
ALL_TYPES = "{HTTT,API,FLOW,TOPIC,ADAPTER,PLATFORM_SERVICE,NATIONAL_LINK}"
RUNTIME = "{HTTT,API,FLOW,TOPIC,ADAPTER,PLATFORM_SERVICE}"
CRIT = [
    ("AR-REG-01", "Đăng ký đủ mã, tên, loại và vòng đời", "Thành phần có mã, tên, loại và vòng đời xác định trong sổ kiến trúc.", ALL_TYPES, True, 1.0),
    ("AR-OWN-01", "Có tổ chức chủ quản", "Thành phần gắn tổ chức chủ quản (DO) và đầu mối liên hệ.", RUNTIME, True, 1.0),
    ("AR-DEP-01", "Khai báo đủ phụ thuộc", "Phụ thuộc với thành phần khác đã khai báo hoặc tự phát hiện.", ALL_TYPES, False, 0.8),
    ("AR-OPS-01", "Có trạng thái vận hành cập nhật", "Trạng thái vận hành lấy từ PH-13, không quá hạn độ tươi.", RUNTIME, False, 0.6),
    ("AR-SEC-01", "Đã phân loại và đánh giá ATTT", "Có xác nhận của cán bộ ATTT về phân loại và hồ sơ cấp độ.", "{HTTT,API,PLATFORM_SERVICE,NATIONAL_LINK}", True, 1.0),
    ("AR-VER-01", "Có phiên bản và tài liệu mô tả hiện hành", "Có phiên bản đang ACTIVE kèm tham chiếu tài liệu mô tả.", "{HTTT,API,FLOW,ADAPTER,PLATFORM_SERVICE}", False, 0.6),
]
q = lambda s: str(s).replace("'", "''")
GRP_SQL = ", ".join("('%s', '%s', '%s', %d)" % (c, q(n), q(d), o) for c, n, d, o in GROUPS)
IND_SQL = ", ".join("('%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', %s, %s, %d)" % (c, g, q(n), k, d, m, q(u), a, str(mand).lower(), "'%s'" % b if b else "NULL::varchar", i + 1)
                    for i, (c, g, n, k, d, m, u, a, mand, b) in enumerate(IND))
CRIT_SQL = ", ".join("('%s', '%s', '%s', '%s', %s, %s)" % (c, q(n), q(d), t, str(m).lower(), w) for c, n, d, t, m, w in CRIT)

# ---------------------------------------------------------------------------------------------
HERE = os.path.dirname(os.path.abspath(__file__))
HEAD = open(os.path.join(HERE, "dau_ddl.sql"), encoding="utf-8").read()
TAIL = open(os.path.join(HERE, "cuoi_ddl.sql"), encoding="utf-8").read()
STD_COLS = ["id uuid NOT NULL", "tenant_id varchar(16) NOT NULL"]
AUDIT_COLS = ["created_at timestamptz NOT NULL DEFAULT now()", "created_by varchar(64) NOT NULL", "updated_at timestamptz NOT NULL DEFAULT now()", "updated_by varchar(64) NOT NULL"]
INFRA = ("outbox_event", "inbox_event")


def render_table(t, seq):
    n = t["name"]
    cols = []
    if t["std"]:
        cols += STD_COLS
    else:
        cols += ["tenant_id varchar(16) NOT NULL"]
    cols += t["cols"]
    if t["std"]:
        cols += AUDIT_COLS + ["version integer NOT NULL DEFAULT 0"]
    cons = []
    if t["part"]:
        cons.append((f"pk_{n}", f"PRIMARY KEY ({t['pk'][0]}, {t['pk'][1]})"))
    elif not t["nopk"]:
        cons.append((f"pk_{n}", "PRIMARY KEY (id)"))
    if t["tid"]:
        cons.append((f"uq_{n}_tid", "UNIQUE (tenant_id, id)"))
    if t["rls"] == "S":
        cons.append((f"ck_{n}_tenant", "CHECK (tenant_id ~ '^(T[0-9]{2}|COMMON)$')"))
    elif n not in INFRA:
        cons.append((f"ck_{n}_tenant", f"CHECK (tenant_id ~ '{TENANT_RE}')"))
    cons += t["cons"]
    w = max(len(c.split()[0]) for c in cols)
    lines = [f"  {c.split()[0]:<{w}} {c[len(c.split()[0]) + 1:]}" for c in cols]
    for cn, cd in cons:
        lines.append(f"  CONSTRAINT {cn} {cd}")
    o = [f"-- @changeset ph16-{seq:04d}-{n.replace('_', '-')}", f"CREATE TABLE {S}.{n} (", ",\n".join(lines),
         ")" + (f" PARTITION BY RANGE ({t['part'][0]})" if t["part"] else "") + ";"]
    if t["part"]:
        o.append(f"CALL {S}.p_ensure_partitions('{S}.{n}', date '2026-01-01', {t['part'][1]});")
    o += t["idx"]
    if t["std"]:
        o.append(f"CREATE TRIGGER tg_{n}_touch BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_touch();")
    for tr in t["trig"]:
        kind, args = tr[0], tr[1]
        suffix = tr[2] if len(tr) > 2 else ""
        a = ", ".join("'%s'" % x for x in args) if isinstance(args, list) else args
        if kind == "immutable":
            o.append(f"CREATE TRIGGER tg_{n}_immutable BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_immutable({a});")
        elif kind == "frozen":
            o.append(f"CREATE TRIGGER tg_{n}_frozen{suffix} BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_frozen({a});")
        elif kind == "transition":
            o.append(f"CREATE TRIGGER tg_{n}_transition BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_transition({a});")
        elif kind == "append_only":
            o.append(f"CREATE TRIGGER tg_{n}_append_only BEFORE UPDATE OR DELETE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_append_only();")
        elif kind == "child_frozen":
            o.append(f"CREATE TRIGGER tg_{n}_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_child_frozen({a});")
        elif kind == "no_delete":
            o.append(f"CREATE TRIGGER tg_{n}_no_delete BEFORE DELETE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_no_delete_state({a});")
        elif kind == "raw":
            o.append(args)
    if t["rls"] == "P":
        o.append(f"CALL {S}.p_enable_rls('{S}.{n}');")
    elif t["rls"] == "S":
        o.append(f"CALL {S}.p_enable_rls_shared('{S}.{n}');")
    qq = lambda s: s.replace("'", "''")
    o.append(f"COMMENT ON TABLE {S}.{n} IS '{qq(t['comment'])}';")
    for c, txt in t["cc"].items():
        o.append(f"COMMENT ON COLUMN {S}.{n}.{c} IS '{qq(txt)}';")
    o.append(f"-- @rollback DROP TABLE IF EXISTS {S}.{n} CASCADE;")
    return "\n".join(o)


def main():
    all_t = {t["name"]: t for _, g in FILE_GROUPS for t in g}
    seen = set()
    for _, g in FILE_GROUPS:
        for t in g:
            for cn, cd in t["cons"]:
                m = re.search(r"REFERENCES %s\.(\w+) " % S, cd)
                if m:
                    if m.group(1) not in seen:
                        raise SystemExit(f"{t['name']} tham chiếu {m.group(1)} trước khi tạo")
                    if "(tenant_id, id)" in cd and not all_t[m.group(1)]["tid"]:
                        raise SystemExit(f"{t['name']} -> {m.group(1)} cần tid=True")
            seen.add(t["name"])
    out = [HEAD]
    seq = 100
    for fname, grp in FILE_GROUPS:
        out.append(f"\n-- @file {fname}")
        if fname in PRE:
            out.append(PRE[fname])
        for t in grp:
            out.append(render_table(t, seq))
            out.append("")
            seq += 10
    keep = {"kpi_indicator_threshold", "kpi_manual_evidence", "kpi_compliance_item", "kpi_export_job", "outbox_event", "inbox_event"}
    append_only = [t["name"] for t in all_t.values() if any(x[0] == "append_only" for x in t["trig"])]
    nodel = [n for n in all_t if n not in keep and n not in append_only]
    set_rows = ", ".join("('%s', '%s')" % (k, v) for k, v in SETTINGS)
    tail = (TAIL.replace("@@SET@@", set_rows).replace("@@GRP@@", GRP_SQL).replace("@@IND@@", IND_SQL).replace("@@CRIT@@", CRIT_SQL)
            .replace("@@NODEL@@", ",\n  ".join(f"{S}.{n}" for n in nodel)).replace("@@APPEND@@", ", ".join(f"{S}.{n}" for n in append_only)))
    out.append(tail)
    open(os.path.join(ROOT, "ddl", "ph16_kpi.sql"), "w", encoding="utf-8").write("\n".join(out))
    print(f"{len(all_t)} bảng → ddl/ph16_kpi.sql")


if __name__ == "__main__":
    main()
