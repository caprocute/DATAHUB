#!/usr/bin/env python3
"""Sinh ddl/ph08_dq.sql (schema ph08_dq, D03-03-PH08) từ danh mục bảng khai báo ở tệp này (chép khung từ ph06/tools/sinh_ddl.py).

Chạy từ thư mục csdl/ph08:  python3 tools/sinh_ddl.py
Enum lấy từ brief PH-08 §5, trùng Phụ lục A của FRS PH-08 (EN: chỉ được thêm, không đổi tên); đổi enum thì sửa ở dict ENUM.
Kết quả có dấu @file, @changeset, @rollback để tools/gen_liquibase.py sinh changelog. DDL là nguồn chuẩn cho
gen_tables_md.py, them_dac_ta_bang.py; không sửa tay tệp sinh ra, sửa ở đây rồi sinh lại.
Không lưu giá trị gốc của trường Nhạy cảm: chỉ masked_value (đã che) và value_hash (băm có khóa).
"""
import os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S = "ph08_dq"

ENUM = {
    "dimension": "COMPLETENESS ACCURACY CONSISTENCY TIMELINESS UNIQUENESS VALIDITY",
    "severity": "CRITICAL MAJOR MINOR",
    "asset_type": "MDM_DOMAIN RDM_CATALOG SOURCE_DATASET FLOW_MESSAGE",
    "asset_status": "DRAFT ACTIVE SUSPENDED RETIRED",
    "version_status": "DRAFT PENDING_APPROVAL APPROVED ACTIVE SUPERSEDED RETIRED",
    "weight_status": "DRAFT PENDING_APPROVAL ACTIVE SUPERSEDED RETIRED",
    "domain_status": "ACTIVE INACTIVE",
    "exec_mode": "BATCH INLINE BOTH",
    "operator": "NOT_NULL NOT_EMPTY REQUIRED_IF REGEX LENGTH RANGE CHECKSUM TYPE EQ_SOURCE EQ_FIELDS CROSS_ENTITY MAX_AGE_DAYS UPDATED_AFTER UNIQUE_IN_ASSET UNIQUE_COMPOSITE IN_RDM IN_RDM_VERSION CEL_EXPRESSION SQL_PREDICATE",
    "scan_mode": "FULL SAMPLE INCREMENTAL",
    "scan_trigger": "SCHEDULE MANUAL EVENT ANNUAL VERIFY",
    "scan_status": "QUEUED RUNNING SUCCEEDED PARTIAL FAILED CANCELLED",
    "rule_result_status": "PASSED FAILED SKIPPED ERROR",
    "verdict": "PASS WARN FAIL",
    "trend": "BASELINE IMPROVED STABLE DEGRADED",
    "finding_status": "OPEN IN_REMEDIATION RESOLVED WAIVED",
    "waiver_status": "PENDING_APPROVAL ACTIVE EXPIRED REVOKED REJECTED",
    "issue_status": "OPEN ASSIGNED IN_PROGRESS FIXED VERIFIED REOPENED REJECTED CANCELLED",
    "inline_mode": "STRICT ADVISORY",
    "on_dependency_failure": "FAIL_OPEN FAIL_CLOSED",
    "alert_severity": "HIGH MEDIUM LOW",
    "alert_status": "FIRING ACKNOWLEDGED RESOLVED SILENCED",
    "report_type": "PERIODIC ANNUAL AD_HOC",
    "report_status": "DRAFT IN_REVIEW PUBLISHED WITHDRAWN",
    "profile_status": "QUEUED RUNNING SUCCEEDED FAILED",
    "data_class": "PUBLIC INTERNAL RESTRICTED SENSITIVE",
    "classification_status": "PROPOSED CONFIRMED",
}
FLAGS = "INCOMPLETE_DIMENSIONS WEIGHTS_CHANGED TRUNCATED INCREMENTAL"
DIMS = ENUM["dimension"].split()


def E(name, skip=()):
    return "(" + ", ".join("'%s'" % x for x in ENUM[name].split() if x not in skip) + ")"


TENANT_RE = "^T[0-9]{2}$"
CODE_RE = "^[A-Za-z][A-Za-z0-9_.-]{1,62}$"
FIELD_RE = "^[A-Za-z_][A-Za-z0-9_]{0,62}$"
ORG_RE = "^[A-Za-z0-9][A-Za-z0-9._-]{1,62}$"
FILE_GROUPS = []


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


def ix(name, table, cols, where=None, unique=False, using=None):
    return f"CREATE {'UNIQUE ' if unique else ''}INDEX {name} ON {S}.{table}{' USING ' + using if using else ''} ({cols})" + (f" WHERE {where}" if where else "") + ";"


H32 = lambda c: f"{c} IS NULL OR octet_length({c}) = 32"
ERRC = lambda c: f"{c} IS NULL OR {c} ~ '^ERR-08-[0-9]{{3}}$'"

# ---------------------------------------------------------------------------------------------
# 08-0010 Miền, đối tượng đo, hồ sơ dữ liệu
# ---------------------------------------------------------------------------------------------
G_ASSET = [
    T("dq_domain",
      "EN-08-01 Miền chất lượng dữ liệu: nhóm đối tượng đo theo lĩnh vực quản lý, gắn tổ chức chủ quản (DO) và cán bộ phụ trách (FR-08-001). Mang chế độ xử lý khi dịch vụ phụ thuộc lỗi lúc kiểm tra trực tuyến (FAIL_OPEN, FAIL_CLOSED). Không xóa, chỉ chuyển INACTIVE.",
      ["domain_code varchar(32) NOT NULL", "name varchar(255) NOT NULL", "description varchar(2000)", "owner_org_code varchar(63) NOT NULL",
       "steward_user varchar(64)", "status varchar(16) NOT NULL DEFAULT 'ACTIVE'", "status_reason varchar(2000)",
       "on_dependency_failure varchar(16) NOT NULL DEFAULT 'FAIL_OPEN'"],
      [("uq_dq_domain_code", "UNIQUE (tenant_id, domain_code)"),
       chk("dq_domain", "code", "domain_code ~ '^[A-Z][A-Z0-9_]{1,31}$'"),
       chk("dq_domain", "owner", f"owner_org_code ~ '{ORG_RE}'"),
       chk("dq_domain", "status", f"status IN {E('domain_status')}"),
       chk("dq_domain", "failure", f"on_dependency_failure IN {E('on_dependency_failure')}"),
       chk("dq_domain", "reason", "status <> 'INACTIVE' OR COALESCE(" + reason20("status_reason") + ", false)")],
      tid=True, trig=[("immutable", ["tenant_id", "domain_code"])],
      ccomment={"owner_org_code": "Mã tổ chức chủ quản (DO) ở PH-01; kiểm ở dịch vụ, không khóa ngoại liên schema.",
                "on_dependency_failure": "FAIL_OPEN cho phép bản ghi đi tiếp khi PH-07, PH-05 không khả dụng; FAIL_CLOSED chặn (FR-08-031, 032)."}),
    T("dq_asset",
      "EN-08-02 Đối tượng đo chất lượng, bốn loại: miền dữ liệu chủ PH-06, danh mục PH-07, bảng hoặc khung nhìn nguồn qua kết nối PH-05 chỉ đọc, bản tin luồng PH-04 (FR-08-002, 003, 004, 006, 007). Cột tham chiếu bắt buộc đúng theo loại. Không xóa, chỉ ngừng hoặc khôi phục.",
      ["domain_code varchar(32) NOT NULL", "asset_code varchar(63) NOT NULL", "name varchar(255) NOT NULL", "asset_type varchar(16) NOT NULL",
       "status varchar(16) NOT NULL DEFAULT 'DRAFT'", "status_reason varchar(2000)", "owner_org_code varchar(63) NOT NULL",
       "mdm_domain_code varchar(32)", "rdm_catalog_code varchar(64)", "connection_id uuid", "object_name varchar(255)", "flow_code varchar(63)",
       "key_columns varchar(63)[] NOT NULL DEFAULT '{}'", "default_scan_mode varchar(16) NOT NULL DEFAULT 'FULL'",
       "sample_ratio numeric(5,4)", "highest_data_class varchar(16) NOT NULL DEFAULT 'INTERNAL'", "description varchar(2000)",
       "incremental_enabled boolean NOT NULL DEFAULT false", "updated_at_field varchar(63)", "inline_enabled boolean NOT NULL DEFAULT false", "inline_mode varchar(10)",
       "on_dependency_failure varchar(16)", "inline_timeout_ms smallint NOT NULL DEFAULT 40", "gate_enabled boolean NOT NULL DEFAULT false"],
      [("uq_dq_asset_code", "UNIQUE (tenant_id, asset_code)"),
       fk("dq_asset", "domain", "tenant_id, domain_code", "dq_domain"),
       chk("dq_asset", "code", f"asset_code ~ '{CODE_RE}'"),
       chk("dq_asset", "type", f"asset_type IN {E('asset_type')}"),
       chk("dq_asset", "status", f"status IN {E('asset_status')}"),
       chk("dq_asset", "scan_mode", f"default_scan_mode IN {E('scan_mode')}"),
       chk("dq_asset", "class", f"highest_data_class IN {E('data_class')}"),
       chk("dq_asset", "ref", "(asset_type = 'MDM_DOMAIN') = (mdm_domain_code IS NOT NULL) AND (asset_type = 'RDM_CATALOG') = (rdm_catalog_code IS NOT NULL) "
           "AND (asset_type = 'SOURCE_DATASET') = (connection_id IS NOT NULL AND object_name IS NOT NULL) AND (asset_type = 'FLOW_MESSAGE') = (flow_code IS NOT NULL)"),
       chk("dq_asset", "inline_mode", f"inline_mode IS NULL OR inline_mode IN {E('inline_mode')}"),
       chk("dq_asset", "inline_on", "NOT inline_enabled OR inline_mode IS NOT NULL"),
       chk("dq_asset", "failure", f"on_dependency_failure IS NULL OR on_dependency_failure IN {E('on_dependency_failure')}"),
       chk("dq_asset", "timeout", "inline_timeout_ms BETWEEN 10 AND 50"),
       chk("dq_asset", "gate", "NOT gate_enabled OR (asset_type = 'MDM_DOMAIN' AND inline_enabled)"),
       chk("dq_asset", "incremental", "NOT incremental_enabled OR (asset_type <> 'FLOW_MESSAGE' AND (asset_type <> 'SOURCE_DATASET' OR updated_at_field IS NOT NULL))"),
       chk("dq_asset", "updated_field", "updated_at_field IS NULL OR updated_at_field ~ '" + FIELD_RE + "'"),
       chk("dq_asset", "sample", "(default_scan_mode = 'SAMPLE') = (sample_ratio IS NOT NULL) AND (sample_ratio IS NULL OR (sample_ratio > 0 AND sample_ratio <= 1))"),
       chk("dq_asset", "reason", "status NOT IN ('SUSPENDED', 'RETIRED') OR COALESCE(" + reason20("status_reason") + ", false)")],
      idx=[ix("ix_dq_asset_domain", "dq_asset", "tenant_id, domain_code, status"), ix("ix_dq_asset_owner", "dq_asset", "tenant_id, owner_org_code, status"),
           ix("ix_dq_asset_mdm", "dq_asset", "tenant_id, mdm_domain_code", "mdm_domain_code IS NOT NULL"),
           ix("ix_dq_asset_rdm", "dq_asset", "tenant_id, rdm_catalog_code", "rdm_catalog_code IS NOT NULL")],
      tid=True, trig=[("immutable", ["tenant_id", "asset_code", "asset_type"])],
      ccomment={"connection_id": "Mã kết nối PH-05 (tài khoản chỉ đọc, Q359, ADR-067); kiểm ở dịch vụ, không khóa ngoại.",
                "mdm_domain_code": "Domain PH-06; đọc qua view hợp đồng chỉ đọc do PH-06 cấp, không đọc bảng nghiệp vụ.",
                "highest_data_class": "Phân loại cao nhất trong các trường, lấy từ PH-09; điều khiển cách lưu giá trị lỗi.",
                "incremental_enabled": "Bật đo tăng dần theo sự kiện PH-06, PH-07 (FR-08-025, API-08-130, 131); không áp cho FLOW_MESSAGE, SOURCE_DATASET cần updated_at_field.",
                "inline_enabled": "Cấu hình kiểm tra trực tuyến của đối tượng (FR-08-032, 035): bật, chế độ STRICT hay ADVISORY, hành vi khi phụ thuộc lỗi (rỗng thì theo miền), ngân sách ms, cổng chất lượng cho PH-06.",
                "gate_enabled": "Cổng chất lượng đầu vào cho PH-06, chỉ MDM_DOMAIN đã bật trực tuyến (FR-08-035)."}),
    T("dq_asset_field",
      "EN-08-03 Trường của đối tượng đo, kèm cờ phần tử dữ liệu trọng yếu (CDE) và phân loại PH-09 (FR-08-005, 006, 009). Cột value_mode quyết định cách lưu giá trị lỗi: trường Nhạy cảm chỉ được băm, trường Hạn chế phải che.",
      ["asset_id uuid NOT NULL", "field_name varchar(63) NOT NULL", "label varchar(255)", "field_type varchar(16) NOT NULL DEFAULT 'STRING'",
       "cde boolean NOT NULL DEFAULT false", "data_class varchar(16) NOT NULL DEFAULT 'INTERNAL'", "classification_status varchar(16) NOT NULL DEFAULT 'PROPOSED'",
       "value_mode varchar(16) NOT NULL DEFAULT 'MASKED'", "rdm_catalog_code varchar(64)", "sort_order smallint NOT NULL DEFAULT 0"],
      [("uq_dq_asset_field_name", "UNIQUE (tenant_id, asset_id, field_name)"),
       fk("dq_asset_field", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       chk("dq_asset_field", "name", f"field_name ~ '{FIELD_RE}'"),
       chk("dq_asset_field", "type", "field_type IN ('STRING', 'INTEGER', 'DECIMAL', 'DATE', 'TIMESTAMP', 'BOOLEAN', 'CODE', 'JSON')"),
       chk("dq_asset_field", "class", f"data_class IN {E('data_class')}"),
       chk("dq_asset_field", "classification", f"classification_status IN {E('classification_status')}"),
       chk("dq_asset_field", "mode", "value_mode IN ('MASKED', 'HASH_ONLY', 'PLAIN')"),
       chk("dq_asset_field", "mode_class", "(data_class <> 'SENSITIVE' OR value_mode = 'HASH_ONLY') AND (data_class <> 'RESTRICTED' OR value_mode <> 'PLAIN')")],
      idx=[ix("ix_dq_asset_field_cde", "dq_asset_field", "tenant_id, asset_id", "cde")],
      ccomment={"value_mode": "MASKED lưu giá trị đã che, HASH_ONLY chỉ lưu băm, PLAIN chỉ cho PUBLIC, INTERNAL. SENSITIVE bắt buộc HASH_ONLY, RESTRICTED không được PLAIN (BR giá trị lỗi, FR-08-036).",
                "cde": "Phần tử dữ liệu trọng yếu: lỗi CRITICAL bắt buộc ở CDE theo cấu hình (FR-08-005)."}),
    T("dq_profile_run",
      "EN-08-04 Lần chạy hồ sơ dữ liệu (profiling) cho một đối tượng đo, theo mẫu hoặc toàn bộ (FR-08-008, 011). Kết quả theo cột ở dq_profile_column.",
      ["asset_id uuid NOT NULL", "status varchar(16) NOT NULL DEFAULT 'QUEUED'", "scan_mode varchar(16) NOT NULL DEFAULT 'SAMPLE'", "sample_rows bigint",
       "row_count bigint", "requested_by varchar(64) NOT NULL", "started_at timestamptz", "finished_at timestamptz", "source_snapshot_at timestamptz",
       "error_code varchar(16)", "error_message varchar(2000)"],
      [fk("dq_profile_run", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       chk("dq_profile_run", "status", f"status IN {E('profile_status')}"),
       chk("dq_profile_run", "mode", "scan_mode IN ('FULL', 'SAMPLE', 'EXTERNAL')"),
       chk("dq_profile_run", "done", "status NOT IN ('SUCCEEDED', 'FAILED') OR finished_at IS NOT NULL"),
       chk("dq_profile_run", "error", ERRC("error_code"))],
      idx=[ix("ix_dq_profile_run_asset", "dq_profile_run", "tenant_id, asset_id, created_at DESC")], tid=True),
    T("dq_profile_column",
      "EN-08-05 Thống kê hồ sơ theo cột: số rỗng, số giá trị khác nhau ước lượng bằng HyperLogLog, phân vị (Apache DataSketches), mẫu định dạng thường gặp (FR-08-009, 010). Cột Nhạy cảm không lưu giá trị mẫu, nhỏ nhất, lớn nhất.",
      ["profile_run_id uuid NOT NULL", "asset_id uuid NOT NULL", "field_name varchar(63) NOT NULL", "inferred_type varchar(16)", "sensitive boolean NOT NULL DEFAULT false",
       "row_count bigint NOT NULL", "null_count bigint NOT NULL DEFAULT 0", "empty_count bigint NOT NULL DEFAULT 0", "distinct_estimate bigint",
       "min_masked varchar(255)", "max_masked varchar(255)", "quantiles jsonb", "top_values jsonb NOT NULL DEFAULT '[]'", "pattern_stats jsonb NOT NULL DEFAULT '[]'"],
      [("uq_dq_profile_column", "UNIQUE (tenant_id, profile_run_id, field_name)"),
       fk("dq_profile_column", "run", "tenant_id, profile_run_id", "dq_profile_run", "tenant_id, id"),
       chk("dq_profile_column", "name", f"field_name ~ '{FIELD_RE}'"),
       chk("dq_profile_column", "counts", "row_count >= 0 AND null_count >= 0 AND empty_count >= 0 AND null_count <= row_count"),
       chk("dq_profile_column", "sensitive", "NOT sensitive OR (min_masked IS NULL AND max_masked IS NULL AND top_values = '[]'::jsonb)")],
      idx=[ix("ix_dq_profile_column_asset", "dq_profile_column", "tenant_id, asset_id, field_name")],
      ccomment={"sensitive": "Sao chép từ dq_asset_field.value_mode = HASH_ONLY; khi true, CHECK cấm lưu giá trị mẫu."}),
]

# ---------------------------------------------------------------------------------------------
# 08-0020 Quy tắc, phiên bản, trọng số
# ---------------------------------------------------------------------------------------------
OP_DIM = ("(operator NOT IN ('NOT_NULL', 'NOT_EMPTY', 'REQUIRED_IF') OR dimension = 'COMPLETENESS') "
          "AND (operator NOT IN ('UNIQUE_IN_ASSET', 'UNIQUE_COMPOSITE') OR dimension = 'UNIQUENESS') "
          "AND (operator NOT IN ('IN_RDM', 'IN_RDM_VERSION') OR dimension = 'VALIDITY') "
          "AND (operator NOT IN ('MAX_AGE_DAYS', 'UPDATED_AFTER') OR dimension = 'TIMELINESS')")
G_RULE = [
    T("dq_rule_template",
      "EN-08-09 Quy tắc mẫu dùng lại: CCCD, mã số thuế, số điện thoại, email, đơn vị hành chính (FR-08-015). Dòng tenant COMMON do PLATFORM quản, mọi tenant đọc được (mẫu RLS S, cách PH-07); tenant có thể thêm mẫu riêng.",
      ["template_code varchar(64) NOT NULL", "name varchar(255) NOT NULL", "dimension varchar(16) NOT NULL", "operator varchar(24) NOT NULL",
       "default_severity varchar(8) NOT NULL DEFAULT 'MAJOR'", "params jsonb NOT NULL DEFAULT '{}'", "expression_template text",
       "description varchar(2000)", "status varchar(16) NOT NULL DEFAULT 'ACTIVE'"],
      [("uq_dq_rule_template_code", "UNIQUE (tenant_id, template_code)"),
       chk("dq_rule_template", "code", "template_code ~ '^[A-Z][A-Z0-9_-]{2,63}$'"),
       chk("dq_rule_template", "dimension", f"dimension IN {E('dimension')}"),
       chk("dq_rule_template", "operator", f"operator IN {E('operator')}"),
       chk("dq_rule_template", "severity", f"default_severity IN {E('severity')}"),
       chk("dq_rule_template", "status", "status IN ('ACTIVE', 'RETIRED')"),
       chk("dq_rule_template", "expr", "(operator IN ('CEL_EXPRESSION', 'SQL_PREDICATE')) = (expression_template IS NOT NULL)")],
      rls="S", ccomment={"tenant_id": "Dạng Tnn hoặc COMMON (bộ mẫu dùng chung)."}),
    T("dq_weight_config",
      "EN-08-10 Cấu hình trọng số sáu chiều và ngưỡng điểm, có phiên bản và duyệt bốn mắt (FR-08-021, 028). Phạm vi tenant, miền hoặc đối tượng đo; mặc định 0,20/0,20/0,15/0,10/0,15/0,20. Tổng trọng số bằng 1,000 với dung sai 0,001.",
      ["config_code varchar(63) NOT NULL", "version_no integer NOT NULL DEFAULT 1", "domain_code varchar(32)", "asset_id uuid", "status varchar(20) NOT NULL DEFAULT 'DRAFT'",
       "w_completeness numeric(5,4) NOT NULL DEFAULT 0.20", "w_accuracy numeric(5,4) NOT NULL DEFAULT 0.20", "w_consistency numeric(5,4) NOT NULL DEFAULT 0.15",
       "w_timeliness numeric(5,4) NOT NULL DEFAULT 0.10", "w_uniqueness numeric(5,4) NOT NULL DEFAULT 0.15", "w_validity numeric(5,4) NOT NULL DEFAULT 0.20",
       "pass_min numeric(5,2) NOT NULL DEFAULT 80", "warn_min numeric(5,2) NOT NULL DEFAULT 70", "effective_from timestamptz",
       "submitted_by varchar(64)", "submitted_at timestamptz", "decided_by varchar(64)", "decided_at timestamptz", "decision_comment varchar(2000)",
       "activated_at timestamptz", "superseded_at timestamptz", "change_note varchar(2000)"],
      [("uq_dq_weight_config_version", "UNIQUE (tenant_id, config_code, version_no)"),
       fk("dq_weight_config", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       fk("dq_weight_config", "domain", "tenant_id, domain_code", "dq_domain"),
       chk("dq_weight_config", "status", f"status IN {E('weight_status')}"),
       chk("dq_weight_config", "sum", "abs(w_completeness + w_accuracy + w_consistency + w_timeliness + w_uniqueness + w_validity - 1.0) <= 0.001"),
       chk("dq_weight_config", "range", "w_completeness >= 0 AND w_accuracy >= 0 AND w_consistency >= 0 AND w_timeliness >= 0 AND w_uniqueness >= 0 AND w_validity >= 0"),
       chk("dq_weight_config", "threshold", "pass_min <= 100 AND warn_min >= 0 AND warn_min <= pass_min"),
       chk("dq_weight_config", "scope", "asset_id IS NULL OR domain_code IS NULL"),
       chk("dq_weight_config", "four_eyes", four_eyes("decided_by", "submitted_by")),
       chk("dq_weight_config", "active", "status <> 'ACTIVE' OR activated_at IS NOT NULL")],
      idx=[ix("uq_dq_weight_config_active", "dq_weight_config", "tenant_id, COALESCE(domain_code, ''), COALESCE(asset_id, '00000000-0000-0000-0000-000000000000'::uuid)", "status = 'ACTIVE'", unique=True)],
      tid=True, trig=[("immutable", ["tenant_id", "config_code", "version_no"]), ("frozen", ["ACTIVE,SUPERSEDED", "w_completeness", "w_accuracy", "w_consistency", "w_timeliness", "w_uniqueness", "w_validity", "pass_min", "warn_min"])],
      ccomment={"w_completeness": "Cột w_* theo thứ tự COMPLETENESS, ACCURACY, CONSISTENCY, TIMELINESS, UNIQUENESS, VALIDITY.",
                "pass_min": "Điểm từ ngưỡng này trở lên: PASS; từ warn_min: WARN; dưới: FAIL (mặc định 80 và 70, FR-08-021).",
                "effective_from": "Thời điểm cấu hình có hiệu lực khi được duyệt; lần đo sau thời điểm này chấm theo cấu hình mới (FR-08-021)."}),
    T("dq_rule_set",
      "EN-08-06 Bộ quy tắc của một đối tượng đo (FR-08-012, 018, 020, 022). Nội dung nằm ở các phiên bản dq_rule_set_version; mỗi bộ có đúng một phiên bản ACTIVE.",
      ["set_code varchar(63) NOT NULL", "name varchar(255) NOT NULL", "asset_id uuid NOT NULL", "description varchar(2000)", "current_version_no integer NOT NULL DEFAULT 0"],
      [("uq_dq_rule_set_code", "UNIQUE (tenant_id, set_code)"),
       fk("dq_rule_set", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       chk("dq_rule_set", "code", f"set_code ~ '{CODE_RE}'"),
       chk("dq_rule_set", "current", "current_version_no >= 0")],
      idx=[ix("ix_dq_rule_set_asset", "dq_rule_set", "tenant_id, asset_id")], tid=True, trig=[("immutable", ["tenant_id", "set_code", "asset_id"])]),
    T("dq_rule_set_version",
      "EN-08-07 Phiên bản bộ quy tắc, vòng đời DRAFT, PENDING_APPROVAL, ACTIVE, SUPERSEDED, RETIRED, duyệt bốn mắt (FR-08-012, 017, 018, 019). Phiên bản ACTIVE hoặc SUPERSEDED bất biến; quy tắc con chỉ sửa khi phiên bản là DRAFT.",
      ["rule_set_id uuid NOT NULL", "version_no integer NOT NULL", "status varchar(20) NOT NULL DEFAULT 'DRAFT'", "weight_config_id uuid", "content_hash bytea",
       "rule_count integer NOT NULL DEFAULT 0", "change_note varchar(2000)", "submitted_by varchar(64)", "submitted_at timestamptz",
       "decision varchar(8)", "decided_by varchar(64)", "decided_at timestamptz", "decision_comment varchar(2000)", "activated_at timestamptz", "superseded_at timestamptz",
       "effective_from timestamptz", "last_dry_run_id uuid", "dry_run_content_hash bytea", "dry_run_at timestamptz"],
      [("uq_dq_rule_set_version_no", "UNIQUE (tenant_id, rule_set_id, version_no)"),
       fk("dq_rule_set_version", "set", "tenant_id, rule_set_id", "dq_rule_set", "tenant_id, id"),
       fk("dq_rule_set_version", "weight", "tenant_id, weight_config_id", "dq_weight_config", "tenant_id, id"),
       chk("dq_rule_set_version", "no", "version_no >= 1"),
       chk("dq_rule_set_version", "status", f"status IN {E('version_status')}"),
       chk("dq_rule_set_version", "hash", H32("content_hash")),
       chk("dq_rule_set_version", "dry_hash", H32("dry_run_content_hash")),
       chk("dq_rule_set_version", "dry_run", "status NOT IN ('PENDING_APPROVAL', 'APPROVED', 'ACTIVE') OR (dry_run_content_hash IS NOT NULL AND dry_run_at IS NOT NULL)"),
       chk("dq_rule_set_version", "approved", "status <> 'APPROVED' OR (decision = 'APPROVE' AND effective_from IS NOT NULL)"),
       chk("dq_rule_set_version", "decision", "decision IS NULL OR decision IN ('APPROVE', 'REJECT')"),
       chk("dq_rule_set_version", "four_eyes", four_eyes("decided_by", "submitted_by")),
       chk("dq_rule_set_version", "active", "status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decision = 'APPROVE' AND content_hash IS NOT NULL AND rule_count > 0)"),
       chk("dq_rule_set_version", "reject", "decision IS DISTINCT FROM 'REJECT' OR COALESCE(" + reason20("decision_comment") + ", false)")],
      idx=[ix("uq_dq_rule_set_version_active", "dq_rule_set_version", "tenant_id, rule_set_id", "status = 'ACTIVE'", unique=True),
           ix("ix_dq_rule_set_version_status", "dq_rule_set_version", "tenant_id, status, submitted_at")],
      tid=True, trig=[("immutable", ["tenant_id", "rule_set_id", "version_no"]), ("frozen", ["APPROVED,ACTIVE,SUPERSEDED", "weight_config_id", "content_hash", "rule_count", "dry_run_content_hash"])],
      ccomment={"content_hash": "SHA-256 nội dung quy tắc tại lúc gửi duyệt; ACTIVE bắt buộc có (bất biến, FR-08-018, 019).",
                "rule_count": "Số quy tắc; ACTIVE phải lớn hơn 0.",
                "dry_run_content_hash": "Băm phần nội dung ảnh hưởng kết quả đo tại lần chạy thử cuối (FR-08-016); gửi duyệt cần bằng content_hash. Sửa tên, mô tả, thông điệp quy tắc không đổi băm này.",
                "effective_from": "Giờ hiệu lực khi duyệt; tương lai thì APPROVED chờ kích hoạt, hiện tại thì ACTIVE ngay (FR-08-017, 018)."}),
    T("dq_rule",
      "EN-08-08 Quy tắc chất lượng: chiều, toán tử, mức nghiêm trọng, chế độ chạy (lô, trực tuyến, cả hai) và tham số (FR-08-013, 014, 016, 022). Biểu thức CEL hoặc vị từ SQL có kiểm soát nằm ở cột expression; vị từ SQL chỉ chạy theo lô.",
      ["rule_set_version_id uuid NOT NULL", "rule_code varchar(63) NOT NULL", "name varchar(255) NOT NULL", "description varchar(2000)", "dimension varchar(16) NOT NULL",
       "operator varchar(24) NOT NULL", "severity varchar(8) NOT NULL DEFAULT 'MAJOR'", "exec_mode varchar(8) NOT NULL DEFAULT 'BATCH'", "inline_mode varchar(10)",
       "field_name varchar(63)", "params jsonb NOT NULL DEFAULT '{}'", "expression text", "message varchar(500)", "weight numeric(6,3) NOT NULL DEFAULT 1", "template_code varchar(64)",
       "enabled boolean NOT NULL DEFAULT true", "source varchar(12) NOT NULL DEFAULT 'MANUAL'"],
      [("uq_dq_rule_code", "UNIQUE (tenant_id, rule_set_version_id, rule_code)"),
       fk("dq_rule", "version", "tenant_id, rule_set_version_id", "dq_rule_set_version", "tenant_id, id"),
       chk("dq_rule", "code", f"rule_code ~ '{CODE_RE}'"),
       chk("dq_rule", "dimension", f"dimension IN {E('dimension')}"),
       chk("dq_rule", "operator", f"operator IN {E('operator')}"),
       chk("dq_rule", "severity", f"severity IN {E('severity')}"),
       chk("dq_rule", "exec", f"exec_mode IN {E('exec_mode')}"),
       chk("dq_rule", "inline", f"(exec_mode = 'BATCH') = (inline_mode IS NULL) AND (inline_mode IS NULL OR inline_mode IN {E('inline_mode')})"),
       chk("dq_rule", "operator_dimension", OP_DIM),
       chk("dq_rule", "expression", "(operator IN ('CEL_EXPRESSION', 'SQL_PREDICATE')) = (expression IS NOT NULL)"),
       chk("dq_rule", "sql_batch", "operator <> 'SQL_PREDICATE' OR exec_mode = 'BATCH'"),
       chk("dq_rule", "rdm", "operator NOT IN ('IN_RDM', 'IN_RDM_VERSION') OR params ? 'catalogCode'"),
       chk("dq_rule", "weight", "weight > 0"),
       chk("dq_rule", "source", "source IN ('MANUAL', 'TEMPLATE', 'SUGGESTED', 'IMPORTED', 'COPIED') AND (source <> 'TEMPLATE' OR template_code IS NOT NULL)")],
      idx=[ix("ix_dq_rule_version", "dq_rule", "tenant_id, rule_set_version_id, dimension"), ix("ix_dq_rule_inline", "dq_rule", "tenant_id, rule_set_version_id", "exec_mode <> 'BATCH' AND enabled")],
      tid=True, trig=[("child_frozen", [])],
      ccomment={"message": "Thông điệp hiển thị ở bản ghi lỗi khi quy tắc không đạt (thay cột thong_diep của SRS cũ).",
                "source": "Nguồn gốc quy tắc: nhập tay, từ quy tắc mẫu, gợi ý từ hồ sơ, nhập tệp, sao chép (FR-08-010, 015, 020).",
                "inline_mode": "STRICT chặn bản ghi lỗi, ADVISORY chỉ cảnh báo; rỗng khi exec_mode = BATCH (FR-08-032, 033).",
                "operator": "19 toán tử theo FRS; ràng buộc operator_dimension khóa quan hệ toán tử với chiều (ví dụ IN_RDM chỉ thuộc VALIDITY).",
                "expression": "CEL (cel-java) hoặc vị từ SQL có kiểm soát; chỉ khi operator là CEL_EXPRESSION hoặc SQL_PREDICATE (FR-08-014)."}),
]

# ---------------------------------------------------------------------------------------------
# 08-0030 Lịch, lần đo, kết quả, điểm, kiểm tra trực tuyến
# ---------------------------------------------------------------------------------------------
G_SCAN = [
    T("dq_schedule",
      "EN-08-11 Lịch đo theo lô bằng biểu thức cron (FR-08-023). Phạm vi là một đối tượng, một miền hoặc cả tenant; mặc định ngày 1 hằng tháng lúc 02:00. Lập lịch chạy bằng Quartz có ShedLock.",
      ["schedule_code varchar(63) NOT NULL", "domain_code varchar(32)", "asset_id uuid", "cron varchar(64) NOT NULL DEFAULT '0 0 2 1 * ?'", "timezone varchar(40) NOT NULL DEFAULT 'Asia/Ho_Chi_Minh'",
       "scan_mode varchar(16) NOT NULL DEFAULT 'FULL'", "enabled boolean NOT NULL DEFAULT true", "next_run_at timestamptz", "last_run_at timestamptz", "last_job_id uuid"],
      [("uq_dq_schedule_code", "UNIQUE (tenant_id, schedule_code)"),
       fk("dq_schedule", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       fk("dq_schedule", "domain", "tenant_id, domain_code", "dq_domain"),
       chk("dq_schedule", "code", f"schedule_code ~ '{CODE_RE}'"),
       chk("dq_schedule", "scope", "asset_id IS NULL OR domain_code IS NULL"),
       chk("dq_schedule", "mode", f"scan_mode IN {E('scan_mode')}"),
       chk("dq_schedule", "cron", "cron ~ '^[-0-9*/,?LW#A-Za-z]+( [-0-9*/,?LW#A-Za-z]+){5,6}$'")],
      idx=[ix("ix_dq_schedule_next", "dq_schedule", "next_run_at", "enabled")], tid=True),
    T("dq_scan_job",
      "EN-08-12 Lần đo chất lượng của một đối tượng đo với một phiên bản bộ quy tắc (FR-08-023…026, 030, 031). Kích hoạt theo lịch, thủ công, sự kiện, hằng năm (bắt buộc đo đủ) hoặc đo lại kiểm chứng phiếu khắc phục. Mỗi đối tượng chỉ một lần đo đang chạy.",
      ["asset_id uuid NOT NULL", "rule_set_version_id uuid NOT NULL", "weight_config_id uuid", "schedule_id uuid", "scan_trigger varchar(12) NOT NULL", "scan_mode varchar(16) NOT NULL",
       "status varchar(12) NOT NULL DEFAULT 'QUEUED'", "period_code varchar(7) NOT NULL", "requested_by varchar(64) NOT NULL", "idempotency_key varchar(64)",
       "verify_issue_id uuid", "source_event_id uuid", "rerun_of uuid", "source_snapshot_at timestamptz", "started_at timestamptz", "finished_at timestamptz",
       "task_total integer NOT NULL DEFAULT 0", "task_done integer NOT NULL DEFAULT 0", "rows_scanned bigint NOT NULL DEFAULT 0", "rows_failed bigint NOT NULL DEFAULT 0",
       "skipped_rules integer NOT NULL DEFAULT 0", "sample_size integer", "sample_seed bigint", "error_code varchar(16)", "error_message varchar(2000)", "cancel_reason varchar(2000)",
       "flags varchar(32)[] NOT NULL DEFAULT '{}'", "idempotency_hash bytea"],
      [fk("dq_scan_job", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       fk("dq_scan_job", "version", "tenant_id, rule_set_version_id", "dq_rule_set_version", "tenant_id, id"),
       fk("dq_scan_job", "weight", "tenant_id, weight_config_id", "dq_weight_config", "tenant_id, id"),
       fk("dq_scan_job", "schedule", "tenant_id, schedule_id", "dq_schedule", "tenant_id, id"),
       fk("dq_scan_job", "rerun", "tenant_id, rerun_of", "dq_scan_job", "tenant_id, id"),
       chk("dq_scan_job", "trigger", f"scan_trigger IN {E('scan_trigger')}"),
       chk("dq_scan_job", "mode", f"scan_mode IN {E('scan_mode')}"),
       chk("dq_scan_job", "status", f"status IN {E('scan_status')}"),
       chk("dq_scan_job", "period", "period_code ~ '^[0-9]{4}(-(0[1-9]|1[0-2]))?$'"),
       chk("dq_scan_job", "annual_full", "scan_trigger <> 'ANNUAL' OR (scan_mode = 'FULL' AND period_code ~ '^[0-9]{4}$')"),
       chk("dq_scan_job", "verify", "(scan_trigger = 'VERIFY') = (verify_issue_id IS NOT NULL)"),
       chk("dq_scan_job", "event", "(scan_trigger = 'EVENT') = (source_event_id IS NOT NULL) AND (scan_trigger <> 'EVENT' OR scan_mode = 'INCREMENTAL')"),
       chk("dq_scan_job", "done", "status NOT IN ('SUCCEEDED', 'PARTIAL', 'FAILED', 'CANCELLED') OR finished_at IS NOT NULL"),
       chk("dq_scan_job", "cancel", "status <> 'CANCELLED' OR COALESCE(" + reason20("cancel_reason") + ", false)"),
       chk("dq_scan_job", "progress", "task_done >= 0 AND task_done <= task_total AND rows_scanned >= 0 AND rows_failed >= 0 AND rows_failed <= rows_scanned"),
       chk("dq_scan_job", "sample", "(scan_mode = 'SAMPLE') = (sample_size IS NOT NULL) AND (sample_size IS NULL OR sample_size > 0)"),
       chk("dq_scan_job", "error", ERRC("error_code")),
       chk("dq_scan_job", "flags", "flags <@ ARRAY['%s']::varchar[]" % "', '".join(FLAGS.split())),
       chk("dq_scan_job", "idem", "(idempotency_key IS NULL) = (idempotency_hash IS NULL) AND (idempotency_hash IS NULL OR octet_length(idempotency_hash) = 32)")],
      idx=[ix("uq_dq_scan_job_running", "dq_scan_job", "tenant_id, asset_id", "status = 'RUNNING'", unique=True),
           ix("uq_dq_scan_job_idem", "dq_scan_job", "tenant_id, idempotency_key", "idempotency_key IS NOT NULL", unique=True),
           ix("ix_dq_scan_job_asset", "dq_scan_job", "tenant_id, asset_id, created_at DESC"),
           ix("ix_dq_scan_job_period", "dq_scan_job", "tenant_id, period_code, status"),
           ix("ix_dq_scan_job_queue", "dq_scan_job", "tenant_id, created_at", "status IN ('QUEUED', 'RUNNING')")],
      tid=True, trig=[("immutable", ["tenant_id", "asset_id", "rule_set_version_id", "scan_trigger", "scan_mode", "period_code"])],
      ccomment={"sample_seed": "Hạt giống lấy mẫu để tái lập kết quả khi đo SAMPLE (SRS cũ EN-08-04).",
                "flags": "Cờ lần đo: TRUNCATED (vượt trần bản ghi lỗi), INCREMENTAL, INCOMPLETE_DIMENSIONS, WEIGHTS_CHANGED; sao sang ảnh chụp điểm (FR-08-026, 031).",
                "idempotency_hash": "SHA-256 thân yêu cầu; cùng Idempotency-Key mà băm khác thì trả ERR-08-055 (409), cùng băm thì trả lại lần đo cũ.",
                "verify_issue_id": "Phiếu khắc phục cần kiểm chứng (trigger VERIFY, FR-08-044); khóa ngoại nằm ở dq_issue.verify_scan_job_id.",
                "period_code": "Kỳ đo: YYYY-MM (tháng) hoặc YYYY (đo chính thức hằng năm, FR-08-054)."}),
    T("dq_scan_task",
      "EN-08-13 Tác vụ phân mảnh của lần đo: mỗi mảnh là một khoảng khóa của đối tượng, chạy độc lập, thử lại được (FR-08-026, 030). Dọn sau 90 ngày.",
      ["scan_job_id uuid NOT NULL", "shard_no integer NOT NULL", "shard_count integer NOT NULL", "status varchar(12) NOT NULL DEFAULT 'QUEUED'", "key_from varchar(255)", "key_to varchar(255)",
       "attempt smallint NOT NULL DEFAULT 0", "worker_id varchar(64)", "rows_scanned bigint NOT NULL DEFAULT 0", "rows_failed bigint NOT NULL DEFAULT 0",
       "started_at timestamptz", "finished_at timestamptz", "error_code varchar(16)", "heartbeat_at timestamptz", "not_before timestamptz"],
      [("uq_dq_scan_task_shard", "UNIQUE (tenant_id, scan_job_id, shard_no)"),
       fk("dq_scan_task", "job", "tenant_id, scan_job_id", "dq_scan_job", "tenant_id, id"),
       chk("dq_scan_task", "shard", "shard_no >= 0 AND shard_no < shard_count"),
       chk("dq_scan_task", "status", f"status IN {E('scan_status', skip=('PARTIAL',))}"),
       chk("dq_scan_task", "attempt", "attempt >= 0 AND attempt <= 10"),
       chk("dq_scan_task", "error", ERRC("error_code")),
       chk("dq_scan_task", "running", "status <> 'RUNNING' OR (worker_id IS NOT NULL AND heartbeat_at IS NOT NULL)")],
      idx=[ix("ix_dq_scan_task_job", "dq_scan_task", "tenant_id, scan_job_id, status"),
           ix("ix_dq_scan_task_heartbeat", "dq_scan_task", "heartbeat_at", "status = 'RUNNING'"),
           ix("ix_dq_scan_task_queue", "dq_scan_task", "tenant_id, not_before NULLS FIRST, created_at", "status = 'QUEUED'")], tid=True,
      ccomment={"heartbeat_at": "Nhịp cuối của bộ thực thi; quá 08.scan.heartbeat-timeout-seconds thì ScanWatchdog thu hồi tác vụ.",
                "not_before": "Không giao tác vụ trước thời điểm này (lùi thử lại, cửa sổ giờ đo)."}),
    T("dq_rule_result",
      "EN-08-14 Kết quả từng quy tắc trong một lần đo: số dòng xét, số dòng lỗi, tỷ lệ đạt, trạng thái PASSED, FAILED, SKIPPED, ERROR (FR-08-026, 027, 028, 031). Ghi một lần, không sửa. Phân vùng tháng theo executed_at.",
      ["executed_at timestamptz NOT NULL DEFAULT now()", "scan_job_id uuid NOT NULL", "scan_task_id uuid", "asset_id uuid NOT NULL", "rule_id uuid NOT NULL",
       "dimension varchar(16) NOT NULL", "severity varchar(8) NOT NULL", "status varchar(8) NOT NULL", "rows_evaluated bigint NOT NULL DEFAULT 0",
       "rows_failed bigint NOT NULL DEFAULT 0", "pass_rate numeric(7,6)", "skip_reason varchar(32)", "error_code varchar(16)", "duration_ms integer"],
      [fk("dq_rule_result", "job", "tenant_id, scan_job_id", "dq_scan_job", "tenant_id, id"),
       fk("dq_rule_result", "rule", "tenant_id, rule_id", "dq_rule", "tenant_id, id"),
       chk("dq_rule_result", "dimension", f"dimension IN {E('dimension')}"),
       chk("dq_rule_result", "severity", f"severity IN {E('severity')}"),
       chk("dq_rule_result", "status", f"status IN {E('rule_result_status')}"),
       chk("dq_rule_result", "counts", "rows_evaluated >= 0 AND rows_failed >= 0 AND rows_failed <= rows_evaluated"),
       chk("dq_rule_result", "rate", "pass_rate IS NULL OR (pass_rate >= 0 AND pass_rate <= 1)"),
       chk("dq_rule_result", "skipped", "(status = 'SKIPPED') = (skip_reason IS NOT NULL)"),
       chk("dq_rule_result", "skip_reason", "skip_reason IS NULL OR skip_reason IN ('DEPENDENCY_UNAVAILABLE', 'RDM_UNAVAILABLE', 'SOURCE_UNREACHABLE', 'NO_DATA', 'TIMEOUT')"),
       chk("dq_rule_result", "error", ERRC("error_code"))],
      idx=[ix("ix_dq_rule_result_job", "dq_rule_result", "tenant_id, scan_job_id, dimension"), ix("ix_dq_rule_result_rule", "dq_rule_result", "tenant_id, rule_id, executed_at DESC"),
           ix("ix_dq_rule_result_asset", "dq_rule_result", "tenant_id, asset_id, executed_at DESC")],
      part=("executed_at", 3), pk=("id", "executed_at"), trig=[("append_only", [])], nopk=False,
      ccomment={"pass_rate": "1 - rows_failed / rows_evaluated; rỗng khi SKIPPED hoặc ERROR."}),
    T("dq_score_snapshot",
      "EN-08-15 Snapshot điểm chất lượng của một đối tượng trong một kỳ: điểm có trọng số, kết luận PASS, WARN, FAIL, xu hướng so kỳ trước, cờ thiếu chiều hoặc đổi trọng số (FR-08-028, 029, 031, 051). Snapshot chính thức (official) phải từ lần đo đủ và không thiếu chiều.",
      ["scan_job_id uuid NOT NULL", "asset_id uuid NOT NULL", "domain_code varchar(32) NOT NULL", "owner_org_code varchar(63) NOT NULL", "period_code varchar(7) NOT NULL",
       "scan_mode varchar(16) NOT NULL", "score numeric(5,2) NOT NULL", "verdict varchar(4) NOT NULL", "trend varchar(10) NOT NULL DEFAULT 'BASELINE'",
       "flags varchar(32)[] NOT NULL DEFAULT '{}'", "prev_snapshot_id uuid", "prev_score numeric(5,2)", "delta numeric(6,2)", "weight_config_id uuid", "rule_set_version_id uuid NOT NULL",
       "row_count bigint NOT NULL DEFAULT 0", "official boolean NOT NULL DEFAULT false", "measured_at timestamptz NOT NULL DEFAULT now()"],
      [("uq_dq_score_snapshot_job", "UNIQUE (tenant_id, scan_job_id)"),
       fk("dq_score_snapshot", "job", "tenant_id, scan_job_id", "dq_scan_job", "tenant_id, id"),
       fk("dq_score_snapshot", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       fk("dq_score_snapshot", "prev", "tenant_id, prev_snapshot_id", "dq_score_snapshot", "tenant_id, id"),
       chk("dq_score_snapshot", "score", "score >= 0 AND score <= 100"),
       chk("dq_score_snapshot", "verdict", f"verdict IN {E('verdict')}"),
       chk("dq_score_snapshot", "trend", f"trend IN {E('trend')}"),
       chk("dq_score_snapshot", "mode", f"scan_mode IN {E('scan_mode')}"),
       chk("dq_score_snapshot", "flags", "flags <@ ARRAY['%s']::varchar[]" % "', '".join(FLAGS.split())),
       chk("dq_score_snapshot", "period", "period_code ~ '^[0-9]{4}(-(0[1-9]|1[0-2]))?$'"),
       chk("dq_score_snapshot", "baseline", "(trend = 'BASELINE') = (prev_snapshot_id IS NULL)"),
       chk("dq_score_snapshot", "official", "NOT official OR (scan_mode = 'FULL' AND NOT (flags && ARRAY['INCOMPLETE_DIMENSIONS']::varchar[]))")],
      idx=[ix("ix_dq_score_snapshot_asset", "dq_score_snapshot", "tenant_id, asset_id, period_code, measured_at DESC"),
           ix("ix_dq_score_snapshot_domain", "dq_score_snapshot", "tenant_id, domain_code, period_code"),
           ix("ix_dq_score_snapshot_org", "dq_score_snapshot", "tenant_id, owner_org_code, period_code"),
           ix("ix_dq_score_snapshot_official", "dq_score_snapshot", "tenant_id, period_code, asset_id", "official")],
      tid=True, trig=[("immutable", ["tenant_id", "scan_job_id", "asset_id", "period_code", "score", "verdict", "flags", "official"])],
      ccomment={"official": "Dùng cho báo cáo chính thức hằng năm (FR-08-054): chỉ khi đo FULL và không có cờ INCOMPLETE_DIMENSIONS.",
                "flags": "INCOMPLETE_DIMENSIONS: thiếu chiều do SKIPPED; WEIGHTS_CHANGED: trọng số đổi so với kỳ trước."}),
    T("dq_score_dimension",
      "EN-08-16 Điểm theo từng chiều trong snapshot, kèm trọng số đã áp và số quy tắc đạt, lỗi, bỏ qua (FR-08-028, 029). Chiều bị bỏ qua có điểm rỗng.",
      ["snapshot_id uuid NOT NULL", "dimension varchar(16) NOT NULL", "status varchar(10) NOT NULL DEFAULT 'MEASURED'", "score numeric(5,2)", "weight numeric(5,4) NOT NULL",
       "rules_total integer NOT NULL DEFAULT 0", "rules_passed integer NOT NULL DEFAULT 0", "rules_failed integer NOT NULL DEFAULT 0", "rules_skipped integer NOT NULL DEFAULT 0",
       "rows_failed bigint NOT NULL DEFAULT 0"],
      [("uq_dq_score_dimension", "UNIQUE (tenant_id, snapshot_id, dimension)"),
       fk("dq_score_dimension", "snapshot", "tenant_id, snapshot_id", "dq_score_snapshot", "tenant_id, id"),
       chk("dq_score_dimension", "dimension", f"dimension IN {E('dimension')}"),
       chk("dq_score_dimension", "status", "status IN ('MEASURED', 'SKIPPED')"),
       chk("dq_score_dimension", "score", "(status = 'SKIPPED') = (score IS NULL) AND (score IS NULL OR (score >= 0 AND score <= 100))"),
       chk("dq_score_dimension", "weight", "weight >= 0 AND weight <= 1"),
       chk("dq_score_dimension", "counts", "rules_total >= 0 AND rules_passed + rules_failed + rules_skipped <= rules_total")],
      tid=True, trig=[("immutable", ["tenant_id", "snapshot_id", "dimension", "score", "status"])]),
    T("dq_incremental_buffer",
      "EN-08-31 Bộ đệm gom khóa bản ghi đổi theo cửa sổ để đo tăng dần theo sự kiện PH-06, PH-07 (FR-08-025). Mỗi đối tượng đúng một bộ đệm COLLECTING; vượt 100.000 khóa thì OVERFLOW và chờ lần đo FULL.",
      ["asset_id uuid NOT NULL", "window_start timestamptz NOT NULL", "window_end timestamptz NOT NULL", "status varchar(12) NOT NULL DEFAULT 'COLLECTING'",
       "keys text[] NOT NULL DEFAULT '{}'", "event_count integer NOT NULL DEFAULT 0", "scan_job_id uuid"],
      [fk("dq_incremental_buffer", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       fk("dq_incremental_buffer", "job", "tenant_id, scan_job_id", "dq_scan_job", "tenant_id, id"),
       chk("dq_incremental_buffer", "status", "status IN ('COLLECTING', 'OVERFLOW', 'SCHEDULED', 'DONE')"),
       chk("dq_incremental_buffer", "window", "window_end > window_start"),
       chk("dq_incremental_buffer", "keys", "cardinality(keys) <= 100000 AND event_count >= 0"),
       chk("dq_incremental_buffer", "scheduled", "status NOT IN ('SCHEDULED', 'DONE') OR scan_job_id IS NOT NULL")],
      idx=[ix("uq_dq_incremental_buffer_open", "dq_incremental_buffer", "tenant_id, asset_id", "status = 'COLLECTING'", unique=True),
           ix("ix_dq_incremental_buffer_due", "dq_incremental_buffer", "window_end", "status = 'COLLECTING'")], tid=True,
      ccomment={"keys": "Khóa bản ghi đổi đã khử trùng (text, tối đa 100.000 mỗi cửa sổ, BR-08-033); đo xong thì xóa khóa, giữ dòng để kiểm toán."}),
    T("dq_score_current",
      "EN-08-32 Điểm hiện hành của một đối tượng: ảnh chụp đầy đủ gần nhất gộp với các lần đo tăng dần sau đó, nhãn INCREMENTAL, không dùng cho báo cáo năm (FR-08-025, 050, 051). Một dòng mỗi đối tượng.",
      ["asset_id uuid NOT NULL", "full_snapshot_id uuid NOT NULL", "incremental_scan_job_id uuid", "current_score numeric(5,2) NOT NULL", "verdict varchar(4) NOT NULL",
       "flags varchar(32)[] NOT NULL DEFAULT '{}'", "as_of timestamptz NOT NULL DEFAULT now()"],
      [("uq_dq_score_current_asset", "UNIQUE (tenant_id, asset_id)"),
       fk("dq_score_current", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       fk("dq_score_current", "full", "tenant_id, full_snapshot_id", "dq_score_snapshot", "tenant_id, id"),
       fk("dq_score_current", "job", "tenant_id, incremental_scan_job_id", "dq_scan_job", "tenant_id, id"),
       chk("dq_score_current", "score", "current_score >= 0 AND current_score <= 100"),
       chk("dq_score_current", "verdict", f"verdict IN {E('verdict')}"),
       chk("dq_score_current", "flags", "flags <@ ARRAY['%s']::varchar[]" % "', '".join(FLAGS.split()))],
      tid=True, ccomment={"current_score": "Điểm hiển thị ở bảng điều khiển; ảnh chụp đầy đủ vẫn là nguồn cho báo cáo (BR-08-033)."}),
    T("dq_inline_stat",
      "EN-08-25 Thống kê kiểm tra trực tuyến gộp theo phút, theo đối tượng và bên gọi: số lượt, đạt, lỗi, thời gian p50, p95, số lần mở hoặc đóng khi phụ thuộc lỗi (FR-08-032, 034). Không lưu nội dung bản ghi. Phân vùng tháng theo bucket_at; dọn sau 90 ngày.",
      ["bucket_at timestamptz NOT NULL", "asset_id uuid NOT NULL", "caller_code varchar(63) NOT NULL", "mode varchar(10) NOT NULL DEFAULT 'ADVISORY'",
       "check_count integer NOT NULL DEFAULT 0", "pass_count integer NOT NULL DEFAULT 0", "fail_count integer NOT NULL DEFAULT 0", "blocked_count integer NOT NULL DEFAULT 0",
       "error_count integer NOT NULL DEFAULT 0", "warn_count integer NOT NULL DEFAULT 0", "fail_open_count integer NOT NULL DEFAULT 0", "fail_closed_count integer NOT NULL DEFAULT 0",
       "p50_ms integer", "p95_ms integer", "max_ms integer", "by_rule jsonb NOT NULL DEFAULT '{}'"],
      [("uq_dq_inline_stat_bucket", "UNIQUE (tenant_id, asset_id, caller_code, mode, bucket_at)"),
       chk("dq_inline_stat", "bucket", "date_trunc('minute', bucket_at) = bucket_at"),
       chk("dq_inline_stat", "mode", f"mode IN {E('inline_mode')}"),
       chk("dq_inline_stat", "counts", "check_count >= 0 AND pass_count >= 0 AND fail_count >= 0 AND error_count >= 0 AND pass_count + fail_count + error_count <= check_count"),
       chk("dq_inline_stat", "warn", "warn_count >= 0 AND warn_count <= fail_count AND (mode = 'ADVISORY' OR warn_count = 0)"),
       chk("dq_inline_stat", "blocked", "blocked_count >= 0 AND blocked_count <= fail_count AND (mode = 'STRICT' OR blocked_count = 0)"),
       chk("dq_inline_stat", "latency", "p50_ms IS NULL OR (p50_ms >= 0 AND p95_ms >= p50_ms AND max_ms >= p95_ms)")],
      idx=[ix("ix_dq_inline_stat_asset", "dq_inline_stat", "tenant_id, asset_id, bucket_at DESC"), ix("ix_dq_inline_stat_caller", "dq_inline_stat", "tenant_id, caller_code, bucket_at DESC")],
      part=("bucket_at", 3), pk=("id", "bucket_at"),
      ccomment={"warn_count": "Số lượt lỗi ở chế độ ADVISORY (chỉ cảnh báo, không chặn); chế độ STRICT dùng blocked_count.",
                "fail_open_count": "Số lượt phụ thuộc lỗi mà bản ghi vẫn đi tiếp; cộng với fail_closed_count là số lượt suy giảm (degraded)."}),
]

# ---------------------------------------------------------------------------------------------
# 08-0040 Bản ghi lỗi, ngoại lệ
# ---------------------------------------------------------------------------------------------
G_FIND = [
    T("dq_finding",
      "EN-08-17 Bản ghi lỗi: một dòng cho mỗi lỗi còn tồn tại, nhận dạng bằng dấu vân tay fingerprint (băm khóa bản ghi và mã quy tắc) để biết mới, còn, hết qua các kỳ (FR-08-036, 037, 038, 039). Không lưu giá trị gốc: chỉ masked_value (đã che) và value_hash (băm có khóa); trường Nhạy cảm chỉ có băm. Phân vùng tháng theo last_seen_at, mỗi lần thấy lại dòng chuyển sang phân vùng mới.",
      ["last_seen_at timestamptz NOT NULL DEFAULT now()", "asset_id uuid NOT NULL", "rule_id uuid NOT NULL", "dimension varchar(16) NOT NULL", "severity varchar(8) NOT NULL",
       "fingerprint bytea NOT NULL", "record_key_hash bytea NOT NULL", "record_key_masked varchar(255)", "field_name varchar(63)", "data_class varchar(16) NOT NULL DEFAULT 'INTERNAL'",
       "value_mode varchar(16) NOT NULL DEFAULT 'MASKED'", "masked_value varchar(255)", "value_hash bytea", "expected_hint varchar(255)", "status varchar(16) NOT NULL DEFAULT 'OPEN'",
       "owner_org_code varchar(63) NOT NULL", "first_seen_at timestamptz NOT NULL DEFAULT now()", "first_scan_job_id uuid NOT NULL", "last_scan_job_id uuid NOT NULL",
       "seen_count integer NOT NULL DEFAULT 1", "resolved_at timestamptz", "resolved_scan_job_id uuid", "issue_id uuid", "waiver_id uuid",
       "resolution_reason varchar(16)"],
      [fk("dq_finding", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       fk("dq_finding", "rule", "tenant_id, rule_id", "dq_rule", "tenant_id, id"),
       chk("dq_finding", "dimension", f"dimension IN {E('dimension')}"),
       chk("dq_finding", "severity", f"severity IN {E('severity')}"),
       chk("dq_finding", "status", f"status IN {E('finding_status')}"),
       chk("dq_finding", "class", f"data_class IN {E('data_class')}"),
       chk("dq_finding", "mode", "value_mode IN ('MASKED', 'HASH_ONLY', 'PLAIN')"),
       chk("dq_finding", "fingerprint", "octet_length(fingerprint) = 32"),
       chk("dq_finding", "key_hash", "octet_length(record_key_hash) = 32"),
       chk("dq_finding", "value_hash", H32("value_hash")),
       chk("dq_finding", "no_raw", "(data_class <> 'SENSITIVE' OR (value_mode = 'HASH_ONLY' AND masked_value IS NULL AND record_key_masked IS NULL AND expected_hint IS NULL)) "
           "AND (data_class <> 'RESTRICTED' OR value_mode <> 'PLAIN') AND (value_mode <> 'HASH_ONLY' OR masked_value IS NULL)"),
       chk("dq_finding", "seen", "seen_count >= 1 AND last_seen_at >= first_seen_at"),
       chk("dq_finding", "resolved", "(status = 'RESOLVED') = (resolved_at IS NOT NULL) AND (status = 'RESOLVED') = (resolution_reason IS NOT NULL)"),
       chk("dq_finding", "reason", "resolution_reason IS NULL OR resolution_reason IN ('CLEARED', 'RECORD_REMOVED', 'RULE_RETIRED', 'MANUAL_CONFIRMED')"),
       chk("dq_finding", "remediation", "status <> 'IN_REMEDIATION' OR issue_id IS NOT NULL"),
       chk("dq_finding", "waived", "(status = 'WAIVED') = (waiver_id IS NOT NULL)")],
      idx=[ix("ix_dq_finding_asset", "dq_finding", "tenant_id, asset_id, status, last_seen_at DESC"),
           ix("ix_dq_finding_rule", "dq_finding", "tenant_id, rule_id, status"),
           ix("ix_dq_finding_open", "dq_finding", "tenant_id, status, severity, last_seen_at DESC", "status IN ('OPEN', 'IN_REMEDIATION')"),
           ix("ix_dq_finding_fp", "dq_finding", "tenant_id, fingerprint"),
           ix("ix_dq_finding_key", "dq_finding", "tenant_id, asset_id, record_key_hash"),
           ix("ix_dq_finding_issue", "dq_finding", "tenant_id, issue_id", "issue_id IS NOT NULL"),
           ix("ix_dq_finding_owner", "dq_finding", "tenant_id, owner_org_code, status, severity"),
           ix("ix_dq_finding_scan", "dq_finding", "tenant_id, last_scan_job_id")],
      part=("last_seen_at", 3), pk=("id", "last_seen_at"), trig=[("immutable", ["tenant_id", "asset_id", "rule_id", "fingerprint", "record_key_hash", "first_seen_at", "first_scan_job_id", "data_class"])],
      ccomment={"fingerprint": "HMAC-SHA256 (khóa riêng từng tenant) của asset, mã quy tắc, khóa bản ghi; ổn định qua các kỳ (ADR đề xuất dải 085-089).",
                "record_key_hash": "Băm có khóa của khóa bản ghi nguồn; tra theo đối tượng mà không lộ khóa.",
                "masked_value": "Giá trị đã che theo chính sách PH-09, tối đa 255 ký tự; luôn rỗng với trường SENSITIVE. Không bao giờ chứa giá trị gốc.",
                "value_hash": "Băm có khóa của giá trị gốc để biết giá trị có đổi giữa hai kỳ mà không lưu bản rõ.",
                "last_seen_at": "Khóa phân vùng; cập nhật mỗi lần lỗi được thấy lại nên dòng có thể chuyển phân vùng (row movement)."}),
    T("dq_waiver",
      "EN-08-18 Ngoại lệ chấp nhận (waiver): cho phép bỏ qua một lỗi hoặc một quy tắc có thời hạn, DA duyệt, lý do tối thiểu 20 ký tự (FR-08-040). Hết hạn thì lỗi mở lại.",
      ["asset_id uuid NOT NULL", "rule_id uuid", "fingerprint bytea", "status varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL'", "reason varchar(2000) NOT NULL",
       "requested_by varchar(64) NOT NULL", "decided_by varchar(64)", "decided_at timestamptz", "decision_comment varchar(2000)", "valid_from date", "valid_to date",
       "revoked_by varchar(64)", "revoked_at timestamptz", "revoke_reason varchar(2000)", "expired_at timestamptz",
       "scope varchar(12) NOT NULL DEFAULT 'FINDINGS'", "filter jsonb"],
      [fk("dq_waiver", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       fk("dq_waiver", "rule", "tenant_id, rule_id", "dq_rule", "tenant_id, id"),
       chk("dq_waiver", "status", f"status IN {E('waiver_status')}"),
       chk("dq_waiver", "reason", reason20("reason")),
       chk("dq_waiver", "fingerprint", H32("fingerprint")),
       chk("dq_waiver", "scope", "scope IN ('FINDINGS', 'RULE_FILTER') AND (scope <> 'RULE_FILTER' OR (rule_id IS NOT NULL AND filter IS NOT NULL))"),
       chk("dq_waiver", "four_eyes", four_eyes("decided_by", "requested_by")),
       chk("dq_waiver", "period", "valid_to IS NULL OR valid_from IS NULL OR (valid_to > valid_from AND valid_to <= valid_from + 366)"),
       chk("dq_waiver", "active", "status NOT IN ('ACTIVE', 'EXPIRED') OR (decided_by IS NOT NULL AND decided_at IS NOT NULL AND valid_from IS NOT NULL AND valid_to IS NOT NULL)"),
       chk("dq_waiver", "reject", "status <> 'REJECTED' OR COALESCE(" + reason20("decision_comment") + ", false)"),
       chk("dq_waiver", "revoke", "status <> 'REVOKED' OR (revoked_by IS NOT NULL AND COALESCE(" + reason20("revoke_reason") + ", false))")],
      idx=[ix("ix_dq_waiver_asset", "dq_waiver", "tenant_id, asset_id, status"), ix("ix_dq_waiver_expiry", "dq_waiver", "valid_to", "status = 'ACTIVE'"),
           ix("ix_dq_waiver_fp", "dq_waiver", "tenant_id, fingerprint", "fingerprint IS NOT NULL AND status = 'ACTIVE'")],
      tid=True, trig=[("immutable", ["tenant_id", "asset_id", "rule_id", "fingerprint", "reason", "requested_by", "scope"])],
      ccomment={"scope": "FINDINGS: nhóm dấu vân tay (một dấu ở cột fingerprint, nhiều dấu ở dq_waiver_item); RULE_FILTER: một quy tắc kèm điều kiện lọc CEL ở filter (FR-08-040).",
                "valid_to": "Tối đa 366 ngày sau valid_from; thời hạn tối đa theo tham số 08.waiver.max-days kiểm ở dịch vụ."}),
    T("dq_waiver_item",
      "EN-08-33 Dấu vân tay thuộc một ngoại lệ phạm vi FINDINGS (tối đa 100.000 mỗi ngoại lệ, FR-08-040). Không sửa sau khi tạo.",
      ["waiver_id uuid NOT NULL", "fingerprint bytea NOT NULL"],
      [("uq_dq_waiver_item", "UNIQUE (tenant_id, waiver_id, fingerprint)"),
       fk("dq_waiver_item", "waiver", "tenant_id, waiver_id", "dq_waiver", "tenant_id, id"),
       chk("dq_waiver_item", "fingerprint", "octet_length(fingerprint) = 32")],
      idx=[ix("ix_dq_waiver_item_fp", "dq_waiver_item", "tenant_id, fingerprint")], trig=[("immutable", ["tenant_id", "waiver_id", "fingerprint"])]),
]

# ---------------------------------------------------------------------------------------------
# 08-0050 Khắc phục
# ---------------------------------------------------------------------------------------------
OPEN_ISSUE = "status NOT IN ('VERIFIED', 'REJECTED', 'CANCELLED')"
G_ISSUE = [
    T("dq_issue",
      "EN-08-19 Phiếu khắc phục: nhóm lỗi của một đối tượng và quy tắc giao cho tổ chức chủ quản, hạn xử lý theo mức nghiêm trọng (CRITICAL 5 ngày làm việc, MAJOR 15, MINOR 30, giả định), vòng đời OPEN đến VERIFIED (FR-08-041…046). PH-08 không sửa dữ liệu nguồn; lỗi bản ghi vàng chuyển sang hàng đợi steward PH-06.",
      ["issue_code varchar(24) NOT NULL", "asset_id uuid NOT NULL", "rule_id uuid", "group_key varchar(160) NOT NULL", "title varchar(255) NOT NULL", "description varchar(4000)",
       "severity varchar(8) NOT NULL", "finding_count integer NOT NULL DEFAULT 0", "owner_org_code varchar(63) NOT NULL", "assignee varchar(64)",
       "status varchar(12) NOT NULL DEFAULT 'OPEN'", "sla_days smallint NOT NULL", "sla_due_at timestamptz NOT NULL", "escalation_level smallint NOT NULL DEFAULT 0", "escalated_at timestamptz",
       "assigned_at timestamptz", "fixed_at timestamptz", "fix_note varchar(2000)", "verified_at timestamptz", "verify_scan_job_id uuid", "reopen_count smallint NOT NULL DEFAULT 0",
       "reject_reason varchar(2000)", "reject_type varchar(16)", "steward_item_ref uuid", "forwarded_to_steward_at timestamptz", "cancel_reason varchar(2000)"],
      [("uq_dq_issue_code", "UNIQUE (tenant_id, issue_code)"),
       fk("dq_issue", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       fk("dq_issue", "rule", "tenant_id, rule_id", "dq_rule", "tenant_id, id"),
       fk("dq_issue", "verify", "tenant_id, verify_scan_job_id", "dq_scan_job", "tenant_id, id"),
       chk("dq_issue", "code", "issue_code ~ '^DQ-[0-9]{4}-[0-9]{6}$'"),
       chk("dq_issue", "severity", f"severity IN {E('severity')}"),
       chk("dq_issue", "status", f"status IN {E('issue_status')}"),
       chk("dq_issue", "sla", "sla_days BETWEEN 1 AND 365"),
       chk("dq_issue", "assigned", "status NOT IN ('ASSIGNED', 'IN_PROGRESS', 'FIXED', 'VERIFIED') OR assigned_at IS NOT NULL"),
       chk("dq_issue", "fixed", "status NOT IN ('FIXED', 'VERIFIED') OR fixed_at IS NOT NULL"),
       chk("dq_issue", "verified", "(status = 'VERIFIED') = (verified_at IS NOT NULL AND verify_scan_job_id IS NOT NULL)"),
       chk("dq_issue", "reject", "status <> 'REJECTED' OR (COALESCE(" + reason20("reject_reason") + ", false) AND reject_type IS NOT NULL)"),
       chk("dq_issue", "reject_type", "reject_type IS NULL OR reject_type IN ('WRONG_OWNER', 'NOT_A_DEFECT', 'CANNOT_FIX')"),
       chk("dq_issue", "cancel", "status <> 'CANCELLED' OR COALESCE(" + reason20("cancel_reason") + ", false)"),
       chk("dq_issue", "count", "finding_count >= 0 AND reopen_count >= 0 AND escalation_level BETWEEN 0 AND 3")],
      idx=[ix("uq_dq_issue_open_group", "dq_issue", "tenant_id, group_key", OPEN_ISSUE, unique=True),
           ix("ix_dq_issue_inbox", "dq_issue", "tenant_id, owner_org_code, status, sla_due_at"),
           ix("ix_dq_issue_assignee", "dq_issue", "tenant_id, assignee, status", "assignee IS NOT NULL"),
           ix("ix_dq_issue_sla", "dq_issue", "sla_due_at", "status IN ('OPEN', 'ASSIGNED', 'IN_PROGRESS', 'REOPENED')"),
           ix("ix_dq_issue_asset", "dq_issue", "tenant_id, asset_id, status")],
      tid=True, trig=[("immutable", ["tenant_id", "issue_code", "asset_id", "rule_id", "group_key", "severity", "owner_org_code"])],
      ccomment={"group_key": "asset_code | rule_code | owner_org_code; mỗi nhóm một phiếu đang mở (chỉ mục duy nhất một phần).",
                "steward_item_ref": "Mã mục hàng đợi steward PH-06 khi lỗi ở bản ghi vàng (FR-08-046); kiểm ở dịch vụ, không khóa ngoại.",
                "reject_type": "Lý do từ chối của DO: sai chủ quản, không phải lỗi, không sửa được (FR-08-045).",
                "verify_scan_job_id": "Lần đo lại kiểm chứng (trigger VERIFY); phiếu VERIFIED bắt buộc có (FR-08-044)."}),
    T("dq_issue_activity",
      "EN-08-20 Hoạt động trên phiếu khắc phục: tạo, phân công, bình luận, đổi trạng thái, leo thang, chuyển steward, xác nhận (FR-08-043, 045). Chỉ thêm, không sửa, không xóa.",
      ["issue_id uuid NOT NULL", "activity_type varchar(24) NOT NULL", "actor varchar(64) NOT NULL", "from_status varchar(12)", "to_status varchar(12)",
       "comment varchar(4000)", "payload jsonb NOT NULL DEFAULT '{}'", "occurred_at timestamptz NOT NULL DEFAULT now()"],
      [fk("dq_issue_activity", "issue", "tenant_id, issue_id", "dq_issue", "tenant_id, id"),
       chk("dq_issue_activity", "type", "activity_type IN ('COMMENT', 'ATTACHMENT', 'STATUS_CHANGE', 'ASSIGNMENT', 'ESCALATION', 'VERIFY_RESULT', 'CREATED', 'TRANSFER', 'STEWARD_FORWARD')"),
       chk("dq_issue_activity", "status", f"(from_status IS NULL OR from_status IN {E('issue_status')}) AND (to_status IS NULL OR to_status IN {E('issue_status')})"),
       chk("dq_issue_activity", "change", "activity_type <> 'STATUS_CHANGE' OR (from_status IS NOT NULL AND to_status IS NOT NULL AND from_status <> to_status)")],
      idx=[ix("ix_dq_issue_activity_issue", "dq_issue_activity", "tenant_id, issue_id, occurred_at")], trig=[("append_only", [])]),
]

# ---------------------------------------------------------------------------------------------
# 08-0060 Cảnh báo, báo cáo
# ---------------------------------------------------------------------------------------------
G_ALERT = [
    T("dq_alert_rule",
      "EN-08-21 Quy tắc cảnh báo: điều kiện điểm thấp, điểm giảm, lần đo thất bại, thiếu chiều, phiếu quá hạn, tỷ lệ lỗi trực tuyến, lỗi CRITICAL mới; kênh gửi qua PH-13 (FR-08-047, 048).",
      ["alert_rule_code varchar(63) NOT NULL", "name varchar(255) NOT NULL", "domain_code varchar(32)", "asset_id uuid", "condition_type varchar(24) NOT NULL", "dimension varchar(16)",
       "threshold numeric(8,3)", "severity varchar(8) NOT NULL DEFAULT 'MEDIUM'", "channels jsonb NOT NULL DEFAULT '[]'", "recipients jsonb NOT NULL DEFAULT '[]'",
       "cooldown_minutes integer NOT NULL DEFAULT 60", "enabled boolean NOT NULL DEFAULT true"],
      [("uq_dq_alert_rule_code", "UNIQUE (tenant_id, alert_rule_code)"),
       fk("dq_alert_rule", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       fk("dq_alert_rule", "domain", "tenant_id, domain_code", "dq_domain"),
       chk("dq_alert_rule", "code", f"alert_rule_code ~ '{CODE_RE}'"),
       chk("dq_alert_rule", "scope", "asset_id IS NULL OR domain_code IS NULL"),
       chk("dq_alert_rule", "condition", "condition_type IN ('SCORE_BELOW', 'SCORE_DROP', 'SCAN_FAILED', 'INCOMPLETE_DIMENSIONS', 'ISSUE_OVERDUE', 'INLINE_FAIL_RATE', 'NEW_CRITICAL_FINDINGS')"),
       chk("dq_alert_rule", "dimension", f"dimension IS NULL OR dimension IN {E('dimension')}"),
       chk("dq_alert_rule", "severity", f"severity IN {E('alert_severity')}"),
       chk("dq_alert_rule", "threshold", "condition_type NOT IN ('SCORE_BELOW', 'SCORE_DROP', 'INLINE_FAIL_RATE') OR threshold IS NOT NULL"),
       chk("dq_alert_rule", "cooldown", "cooldown_minutes BETWEEN 1 AND 10080")],
      idx=[ix("ix_dq_alert_rule_scope", "dq_alert_rule", "tenant_id, condition_type", "enabled")], tid=True),
    T("dq_alert",
      "EN-08-22 Cảnh báo đã phát: trạng thái FIRING, ACKNOWLEDGED, RESOLVED, SILENCED, khóa chống trùng, tham chiếu thông báo PH-13 (FR-08-048, 049).",
      ["alert_rule_id uuid NOT NULL", "asset_id uuid", "scan_job_id uuid", "snapshot_id uuid", "severity varchar(8) NOT NULL", "status varchar(14) NOT NULL DEFAULT 'FIRING'",
       "dedup_key varchar(160) NOT NULL", "message varchar(1000) NOT NULL", "fired_at timestamptz NOT NULL DEFAULT now()", "notified_at timestamptz", "notification_ref varchar(64)",
       "acknowledged_by varchar(64)", "acknowledged_at timestamptz", "silenced_until timestamptz", "silence_reason varchar(500)", "resolved_at timestamptz"],
      [fk("dq_alert", "rule", "tenant_id, alert_rule_id", "dq_alert_rule", "tenant_id, id"),
       fk("dq_alert", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       chk("dq_alert", "severity", f"severity IN {E('alert_severity')}"),
       chk("dq_alert", "status", f"status IN {E('alert_status')}"),
       chk("dq_alert", "ack", "status <> 'ACKNOWLEDGED' OR (acknowledged_by IS NOT NULL AND acknowledged_at IS NOT NULL)"),
       chk("dq_alert", "silence", "status <> 'SILENCED' OR (silenced_until IS NOT NULL AND COALESCE(" + reason20("silence_reason") + ", false))"),
       chk("dq_alert", "resolved", "(status = 'RESOLVED') = (resolved_at IS NOT NULL)")],
      idx=[ix("uq_dq_alert_open", "dq_alert", "tenant_id, dedup_key", "status IN ('FIRING', 'ACKNOWLEDGED', 'SILENCED')", unique=True),
           ix("uq_dq_alert_unresolved", "dq_alert", "tenant_id, alert_rule_id, COALESCE(asset_id, '00000000-0000-0000-0000-000000000000'::uuid)", "status <> 'RESOLVED'", unique=True),
           ix("ix_dq_alert_status", "dq_alert", "tenant_id, status, fired_at DESC"), ix("ix_dq_alert_asset", "dq_alert", "tenant_id, asset_id, fired_at DESC", "asset_id IS NOT NULL")],
      tid=True),
    T("dq_report",
      "EN-08-23 Báo cáo chất lượng: kỳ (tháng), chính thức hằng năm, theo yêu cầu; soạn, duyệt bốn mắt, công bố; tệp PDF, XLSX trên Ceph RGW kèm SHA-256, ký số tùy chọn (FR-08-052…056). Báo cáo ANNUAL không được dựa trên snapshot thiếu chiều. Đã công bố thì bất biến.",
      ["report_code varchar(24) NOT NULL", "report_type varchar(10) NOT NULL", "period_code varchar(7) NOT NULL", "title varchar(255) NOT NULL", "status varchar(10) NOT NULL DEFAULT 'DRAFT'",
       "scope jsonb NOT NULL DEFAULT '{}'", "summary jsonb NOT NULL DEFAULT '{}'", "snapshot_count integer NOT NULL DEFAULT 0", "incomplete_snapshot_count integer NOT NULL DEFAULT 0",
       "generated_at timestamptz", "submitted_by varchar(64)", "submitted_at timestamptz", "reviewed_by varchar(64)", "reviewed_at timestamptz", "review_comment varchar(2000)",
       "published_by varchar(64)", "published_at timestamptz", "withdrawn_reason varchar(2000)", "pdf_object_key varchar(512)", "xlsx_object_key varchar(512)",
       "content_sha256 bytea", "signed boolean NOT NULL DEFAULT false", "signature_ref varchar(255)"],
      [("uq_dq_report_code", "UNIQUE (tenant_id, report_code)"),
       chk("dq_report", "code", "report_code ~ '^BC-DQ-[0-9]{4}-[A-Z0-9]{2,4}-T[0-9]{2}(-R[0-9]{1,2})?$'"),
       chk("dq_report", "type", f"report_type IN {E('report_type')}"),
       chk("dq_report", "status", f"status IN {E('report_status')}"),
       chk("dq_report", "period", "period_code ~ '^[0-9]{4}(-(0[1-9]|1[0-2]))?$' AND (report_type <> 'ANNUAL' OR period_code ~ '^[0-9]{4}$')"),
       chk("dq_report", "hash", H32("content_sha256")),
       chk("dq_report", "annual_full", "report_type <> 'ANNUAL' OR incomplete_snapshot_count = 0"),
       chk("dq_report", "four_eyes", four_eyes("reviewed_by", "submitted_by")),
       chk("dq_report", "publisher", four_eyes("published_by", "submitted_by")),
       chk("dq_report", "published", "status <> 'PUBLISHED' OR (published_at IS NOT NULL AND published_by IS NOT NULL AND reviewed_by IS NOT NULL AND content_sha256 IS NOT NULL AND pdf_object_key IS NOT NULL)"),
       chk("dq_report", "withdrawn", "status <> 'WITHDRAWN' OR COALESCE(" + reason20("withdrawn_reason") + ", false)"),
       chk("dq_report", "signed", "NOT signed OR signature_ref IS NOT NULL"),
       chk("dq_report", "counts", "snapshot_count >= 0 AND incomplete_snapshot_count >= 0 AND incomplete_snapshot_count <= snapshot_count")],
      idx=[ix("ix_dq_report_period", "dq_report", "tenant_id, report_type, period_code, status"), ix("ix_dq_report_published", "dq_report", "tenant_id, published_at DESC", "status = 'PUBLISHED'")],
      tid=True, trig=[("immutable", ["tenant_id", "report_code", "report_type", "period_code"]), ("frozen", ["PUBLISHED,WITHDRAWN", "scope", "summary", "snapshot_count", "incomplete_snapshot_count", "content_sha256", "pdf_object_key", "xlsx_object_key"])],
      ccomment={"summary": "Số liệu tổng hợp (điểm theo miền, theo tổ chức, xu hướng); không chứa giá trị bản ghi.",
                "pdf_object_key": "Khóa đối tượng trên Ceph RGW, bucket dq-reports; không lưu tệp trong PostgreSQL."}),
    T("dq_report_subscription",
      "EN-08-24 Đăng ký nhận báo cáo: người dùng, vai trò hoặc tổ chức nhận báo cáo công bố qua PH-13 (FR-08-056).",
      ["report_type varchar(10) NOT NULL", "domain_code varchar(32)", "recipient_type varchar(8) NOT NULL", "recipient_ref varchar(128) NOT NULL", "format varchar(4) NOT NULL DEFAULT 'PDF'",
       "enabled boolean NOT NULL DEFAULT true"],
      [fk("dq_report_subscription", "domain", "tenant_id, domain_code", "dq_domain"),
       chk("dq_report_subscription", "type", f"report_type IN {E('report_type')}"),
       chk("dq_report_subscription", "recipient", "recipient_type IN ('USER', 'ROLE', 'ORG')"),
       chk("dq_report_subscription", "format", "format IN ('PDF', 'XLSX')")],
      idx=[ix("uq_dq_report_subscription", "dq_report_subscription", "tenant_id, report_type, COALESCE(domain_code, ''), recipient_type, recipient_ref, format", unique=True)]),
]

# ---------------------------------------------------------------------------------------------
# 08-0070 Vận hành
# ---------------------------------------------------------------------------------------------
SETTINGS = [
    ("08.scan.default-cron", '"0 0 2 1 * ?"'), ("08.scan.timezone", '"Asia/Ho_Chi_Minh"'), ("08.scan.window", '"22:00-05:00"'),
    ("08.scan.min-interval-hours", '{"FULL":24,"INCREMENTAL":1}'), ("08.scan.max-duration-hours", "6"), ("08.scan.queue-timeout-hours", "24"),
    ("08.scan.duplicate-policy", '"QUEUE"'), ("08.scan.manual-per-hour", "10"), ("08.scan.max-concurrent-per-connection", "2"),
    ("08.scan.heartbeat-timeout-seconds", "180"), ("08.scan.task-max-attempts", "3"), ("08.scan.min-coverage", "95"), ("08.scan.task-size", "200000"),
    ("08.incremental.batch-window-minutes", "15"), ("08.profile.on-activate", "true"), ("08.profile.max-columns", "200"), ("08.dryrun.max-rows", "10000"),
    ("08.rule.sql-predicate-enabled", "false"), ("08.rdm.snapshot-max-items", "200000"), ("08.score.dimension-method", '"POOLED"'),
    ("08.trend.stable-band", "1.0"), ("08.trend.degraded-alert", "5.0"), ("08.finding.max-per-scan", "1000000"), ("08.finding.max-per-rule-task", "50000"),
    ("08.finding.retention-months", "13"), ("08.snapshot.retention-years", "5"), ("08.report.official-retention-years", "10"), ("08.report.auto-draft", "true"),
    ("08.annual.snapshot-method", '"FULL_DECEMBER"'), ("08.issue.sla-days", '{"CRITICAL":5,"MAJOR":15,"MINOR":30}'), ("08.issue.auto-open-critical", "100"),
    ("08.issue.escalate-after-overdue-days", "5"), ("08.verify.wait-mdm-minutes", "60"), ("08.verify.wait-source-minutes", "0"), ("08.waiver.max-days", "180"),
    ("08.inline.timeout-ms", "40"), ("08.inline.default-mode", '"ADVISORY"'), ("08.inline.on-dependency-failure", '"FAIL_OPEN"'), ("08.inline.persist-findings", "false"),
    ("08.alert.repeat-hours", "4"), ("08.export.link-hours", "24"), ("08.benchmark.opt-in", "false"), ("08.benchmark.min-group", "5"),
]
assert len(SETTINGS) == 43
SETTING_KEYS = [k for k, _ in SETTINGS]
SETTING_VALUES = [v for _, v in SETTINGS]
RET = [("dq_finding", 395, "DROP_PARTITION"), ("dq_rule_result", 395, "DROP_PARTITION"), ("dq_inline_stat", 90, "DROP_PARTITION"), ("dq_scan_task", 90, "DELETE"),
       ("dq_profile_column", 395, "DELETE"), ("dq_score_snapshot", 1825, "ARCHIVE_COLD"), ("dq_issue", 1825, "ARCHIVE_COLD"), ("dq_alert", 395, "DELETE"),
       ("dq_report", 3650, "ARCHIVE_COLD"), ("dq_export_request", 30, "DELETE"), ("outbox_event", 3, "DELETE"), ("inbox_event", 30, "DELETE")]
G_OPS = [
    T("dq_export_request",
      "EN-08-29 Yêu cầu xuất bản ghi lỗi ra CSV hoặc XLSX trên Ceph RGW; khi có trường Nhạy cảm hoặc Hạn chế cần DO chấp thuận khác người yêu cầu (FR-08-039). Tệp có hạn tải và thủy vân.",
      ["kind varchar(10) NOT NULL DEFAULT 'FINDINGS'", "report_code varchar(24)", "asset_id uuid", "filter jsonb NOT NULL DEFAULT '{}'", "format varchar(4) NOT NULL DEFAULT 'CSV'", "status varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL'", "contains_restricted boolean NOT NULL DEFAULT false",
       "requested_by varchar(64) NOT NULL", "decided_by varchar(64)", "decided_at timestamptz", "decision_comment varchar(2000)", "row_count bigint", "object_key varchar(512)",
       "content_sha256 bytea", "watermark_id varchar(64)", "expires_at timestamptz", "download_count integer NOT NULL DEFAULT 0", "error_code varchar(16)"],
      [fk("dq_export_request", "asset", "tenant_id, asset_id", "dq_asset", "tenant_id, id"),
       fk("dq_export_request", "report", "tenant_id, report_code", "dq_report", "tenant_id, report_code"),
       chk("dq_export_request", "format", "format IN ('CSV', 'XLSX', 'PDF')"),
       chk("dq_export_request", "kind", "kind IN ('FINDINGS', 'REPORT') AND (kind = 'REPORT') = (report_code IS NOT NULL) AND (format <> 'PDF' OR kind = 'REPORT')"),
       chk("dq_export_request", "status", "status IN ('PENDING_APPROVAL', 'APPROVED', 'RUNNING', 'READY', 'FAILED', 'EXPIRED', 'REJECTED')"),
       chk("dq_export_request", "four_eyes", four_eyes("decided_by", "requested_by")),
       chk("dq_export_request", "approval", "NOT contains_restricted OR status IN ('PENDING_APPROVAL', 'REJECTED') OR decided_by IS NOT NULL"),
       chk("dq_export_request", "ready", "status <> 'READY' OR (object_key IS NOT NULL AND expires_at IS NOT NULL AND watermark_id IS NOT NULL AND content_sha256 IS NOT NULL)"),
       chk("dq_export_request", "hash", H32("content_sha256")),
       chk("dq_export_request", "error", ERRC("error_code"))],
      ccomment={"kind": "FINDINGS: xuất bản ghi lỗi (FR-08-039, cần DO chấp thuận khi có trường Hạn chế, Nhạy cảm); REPORT: xuất báo cáo PDF, XLSX (FR-08-055, API-08-116)."},
      idx=[ix("ix_dq_export_request_status", "dq_export_request", "tenant_id, status, created_at DESC"), ix("ix_dq_export_request_expiry", "dq_export_request", "expires_at", "status = 'READY'")], tid=True),
    T("dq_tenant_setting",
      "EN-08-26 Tham số chất lượng theo tenant: 43 khóa 08.* của FRS mục 8.2 (lịch đo, cửa sổ, mẫu, kích thước tác vụ, thời gian chờ, hạn SLA, hạn ngoại lệ, chế độ kiểm tra trực tuyến) (FR-08-058). Chỉ nhận các khóa đã khai báo; ngưỡng điểm và trọng số nằm ở dq_weight_config.",
      ["setting_key varchar(64) NOT NULL", "value jsonb NOT NULL", "description varchar(500)"],
      [("uq_dq_tenant_setting_key", "UNIQUE (tenant_id, setting_key)"),
       chk("dq_tenant_setting", "key", "setting_key IN (%s)" % ", ".join("'%s'" % k for k in SETTING_KEYS))]),
    T("dq_retention_policy",
      "EN-08-30 Chính sách lưu giữ và dọn dữ liệu đo theo loại đối tượng: số ngày giữ và hành động (xóa phân vùng, xóa dòng, lưu lạnh) (FR-08-059). Bản ghi lỗi giữ mặc định 13 tháng (395 ngày), có thể đổi theo tenant.",
      ["object_type varchar(40) NOT NULL", "retention_days integer NOT NULL", "action varchar(16) NOT NULL"],
      [("uq_dq_retention_policy", "UNIQUE (tenant_id, object_type)"),
       chk("dq_retention_policy", "object", "object_type IN (%s)" % ", ".join("'%s'" % r[0] for r in RET)),
       chk("dq_retention_policy", "action", "action IN ('DROP_PARTITION', 'DELETE', 'ARCHIVE_COLD', 'ANONYMIZE')"),
       chk("dq_retention_policy", "days", "retention_days >= 1 AND (object_type NOT IN ('dq_score_snapshot', 'dq_report') OR retention_days >= 1095)")]),
    T("dq_retention_run",
      "EN-08-30 Lịch sử chạy dọn dữ liệu đo theo chính sách lưu giữ: loại dữ liệu, hành động, số dòng và phân vùng đã dọn, chạy xem trước hay chạy thật (FR-08-059, API-08-125, 126).",
      ["object_type varchar(40) NOT NULL", "action varchar(16) NOT NULL", "status varchar(10) NOT NULL DEFAULT 'RUNNING'", "dry_run boolean NOT NULL DEFAULT false",
       "requested_by varchar(64) NOT NULL", "cutoff_at timestamptz", "started_at timestamptz NOT NULL DEFAULT now()", "finished_at timestamptz",
       "rows_affected bigint NOT NULL DEFAULT 0", "partitions_dropped integer NOT NULL DEFAULT 0", "error_code varchar(16)", "error_message varchar(2000)"],
      [chk("dq_retention_run", "object", "object_type IN (%s)" % ", ".join("'%s'" % r[0] for r in RET)),
       chk("dq_retention_run", "action", "action IN ('DROP_PARTITION', 'DELETE', 'ARCHIVE_COLD', 'ANONYMIZE')"),
       chk("dq_retention_run", "status", "status IN ('RUNNING', 'SUCCEEDED', 'FAILED')"),
       chk("dq_retention_run", "done", "status = 'RUNNING' OR finished_at IS NOT NULL"),
       chk("dq_retention_run", "counts", "rows_affected >= 0 AND partitions_dropped >= 0"),
       chk("dq_retention_run", "error", ERRC("error_code"))],
      idx=[ix("ix_dq_retention_run_started", "dq_retention_run", "tenant_id, started_at DESC")], tid=True),
    T("outbox_event",
      "EN-08-27 Outbox (SAD 7.3) cho EVT-08-01…14 và bản ghi kiểm toán gửi PH-13 (FR-08-057, 060). Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL và định tuyến theo topic. Sự kiện không chứa giá trị bản ghi lỗi: CHECK chặn các khóa value, maskedValue, record. Dọn sau 3 ngày.",
      ["event_id uuid NOT NULL", "topic varchar(128) NOT NULL", "aggregate_type varchar(32) NOT NULL", "aggregate_id uuid NOT NULL", "payload jsonb NOT NULL", "trace_id char(32) NOT NULL",
       "occurred_at timestamptz NOT NULL DEFAULT now()", "published_at timestamptz"],
      [("pk_outbox_event", "PRIMARY KEY (event_id)"),
       chk("outbox_event", "tenant", f"tenant_id ~ '{TENANT_RE}'"),
       chk("outbox_event", "prefix", "split_part(topic, '.', 1) = lower(tenant_id)"),
       chk("outbox_event", "topic", "substr(topic, length(split_part(topic, '.', 1)) + 2) IN (" + ", ".join("'dq.%s.v1'" % x for x in [
           "ruleset.activated", "scan.completed", "scan.failed", "score.degraded", "score.threshold-breached", "finding.opened", "issue.created", "issue.status-changed",
           "issue.verified", "waiver.approved", "report.published", "alert.fired", "check.failed", "kpi.published"]) + ", 'audit.recorded.v1')"),
       chk("outbox_event", "trace", "trace_id ~ '^[0-9a-f]{32}$'"),
       chk("outbox_event", "no_value", "NOT (payload ?| ARRAY['value', 'values', 'maskedValue', 'valueHash', 'record', 'recordKey', 'fields'])")],
      idx=[ix("ix_outbox_event_occurred", "outbox_event", "occurred_at")], std=False, nopk=True),
    T("inbox_event",
      "EN-08-28 Khử trùng sự kiện nhận: EVT-06-01, 02, 03, 04, 10 của PH-06 và sự kiện phát hành danh mục của PH-07, tiêu thụ lũy đẳng theo event_id (FR-08-025). Dọn sau 30 ngày.",
      ["consumer varchar(64) NOT NULL", "event_id uuid NOT NULL", "source_topic varchar(128) NOT NULL", "received_at timestamptz NOT NULL DEFAULT now()", "processed_at timestamptz"],
      [("pk_inbox_event", "PRIMARY KEY (tenant_id, consumer, event_id)"),
       chk("inbox_event", "tenant", f"tenant_id ~ '{TENANT_RE}'"),
       chk("inbox_event", "consumer", "consumer ~ '^[A-Z][A-Za-z0-9]+$'"),
       chk("inbox_event", "prefix", "split_part(source_topic, '.', 1) = lower(tenant_id)")],
      idx=[ix("ix_inbox_event_received", "inbox_event", "received_at")], std=False, nopk=True),
    T("shedlock",
      "Bảng kỹ thuật của thư viện ShedLock cho các job Quartz (lập lịch đo, dọn, duy trì phân vùng); không chứa dữ liệu nghiệp vụ.",
      ["name varchar(64) NOT NULL", "lock_until timestamptz NOT NULL", "locked_at timestamptz NOT NULL", "locked_by varchar(255) NOT NULL"],
      [("pk_shedlock", "PRIMARY KEY (name)")], std=False, nopk=True, rls=None),
]
FILE_GROUPS += [("08-0010-asset.sql", G_ASSET), ("08-0020-rule.sql", G_RULE), ("08-0030-scan.sql", G_SCAN), ("08-0040-finding.sql", G_FIND),
                ("08-0050-issue.sql", G_ISSUE), ("08-0060-alert-report.sql", G_ALERT), ("08-0070-ops.sql", G_OPS)]

# ---------------------------------------------------------------------------------------------
HEAD = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "dau_ddl.sql"), encoding="utf-8").read()
TAIL = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "cuoi_ddl.sql"), encoding="utf-8").read()
STD_COLS = ["id uuid NOT NULL", "tenant_id varchar(16) NOT NULL"]
AUDIT_COLS = ["created_at timestamptz NOT NULL DEFAULT now()", "created_by varchar(64) NOT NULL", "updated_at timestamptz NOT NULL DEFAULT now()", "updated_by varchar(64) NOT NULL"]


def render_table(t, seq):
    n = t["name"]
    cols = []
    if not t["nopk"] or t["std"]:
        cols += STD_COLS
    elif n in ("inbox_event",):
        cols += ["tenant_id varchar(16) NOT NULL"]
    elif n == "outbox_event":
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
    elif n not in ("outbox_event", "inbox_event", "shedlock"):
        cons.append((f"ck_{n}_tenant", f"CHECK (tenant_id ~ '{TENANT_RE}')"))
    cons += t["cons"]
    w = max(len(c.split()[0]) for c in cols)
    lines = [f"  {c.split()[0]:<{w}} {c[len(c.split()[0]) + 1:]}" for c in cols]
    for cn, cd in cons:
        lines.append(f"  CONSTRAINT {cn} {cd}")
    o = [f"-- @changeset ph08-{seq:04d}-{n.replace('_', '-')}", f"CREATE TABLE {S}.{n} (", ",\n".join(lines),
         ")" + (f" PARTITION BY RANGE ({t['part'][0]})" if t["part"] else "") + ";"]
    if t["part"]:
        o.append(f"CALL {S}.p_ensure_partitions('{S}.{n}', current_date, {t['part'][1]});")
    o += t["idx"]
    if t["std"] or t["part"]:
        if t["std"]:
            o.append(f"CREATE TRIGGER tg_{n}_touch BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_touch();")
    for kind, args in t["trig"]:
        a = ", ".join("'%s'" % x for x in args)
        if kind == "immutable":
            o.append(f"CREATE TRIGGER tg_{n}_immutable BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_immutable({a});")
        elif kind == "frozen":
            o.append(f"CREATE TRIGGER tg_{n}_frozen BEFORE UPDATE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_frozen({a});")
        elif kind == "append_only":
            o.append(f"CREATE TRIGGER tg_{n}_append_only BEFORE UPDATE OR DELETE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_append_only();")
        elif kind == "child_frozen":
            o.append(f"CREATE TRIGGER tg_{n}_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_child_frozen();")
    if t["rls"] == "P":
        o.append(f"CALL {S}.p_enable_rls('{S}.{n}');")
    elif t["rls"] == "S":
        o.append(f"CALL {S}.p_enable_rls_shared('{S}.{n}');")
    q = lambda s: s.replace("'", "''")
    o.append(f"COMMENT ON TABLE {S}.{n} IS '{q(t['comment'])}';")
    for c, txt in t["cc"].items():
        o.append(f"COMMENT ON COLUMN {S}.{n}.{c} IS '{q(txt)}';")
    o.append(f"-- @rollback DROP TABLE IF EXISTS {S}.{n} CASCADE;")
    return "\n".join(o)


def main():
    all_t = {t["name"]: t for _, g in FILE_GROUPS for t in g}
    for t in all_t.values():
        for cn, cd in t["cons"]:
            m = re.search(r"REFERENCES %s\.(\w+) \(tenant_id, id\)" % S, cd)
            if m and not all_t[m.group(1)]["tid"]:
                raise SystemExit(f"{t['name']} -> {m.group(1)} cần tid=True")
    seed = ["-- @changeset ph08-0900-seed-parts runAlways:false", "-- (khởi tạo dữ liệu nằm ở 08-0090-seed.sql)"]
    out = [HEAD]
    seq = 100
    for fname, grp in FILE_GROUPS:
        out.append(f"\n-- @file {fname}")
        for t in grp:
            out.append(render_table(t, seq))
            out.append("")
            seq += 10
    ret_rows = ", ".join("('%s', %d, '%s')" % r for r in RET)
    set_rows = ", ".join("('%s', '%s')" % (k, v) for k, v in zip(SETTING_KEYS, SETTING_VALUES))
    out.append(TAIL.replace("@@RET@@", ret_rows).replace("@@SET@@", set_rows))
    open(os.path.join(ROOT, "ddl", "ph08_dq.sql"), "w", encoding="utf-8").write("\n".join(out))
    print(f"{len(all_t)} bảng → ddl/ph08_dq.sql")


if __name__ == "__main__":
    main()
