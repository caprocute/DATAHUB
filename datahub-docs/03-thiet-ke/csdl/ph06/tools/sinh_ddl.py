#!/usr/bin/env python3
"""Sinh ddl/ph06_mdm.sql (schema ph06_mdm, D03-03-PH06) từ danh mục bảng khai báo ở tệp này.

Chạy từ thư mục csdl/ph06:  python3 tools/sinh_ddl.py
Mọi enum lấy trực tiếp từ Phụ lục A của D02-03-PH06 (hàm E), nên CHECK luôn khớp FRS; đổi enum thì sửa FRS trước.
Kết quả có dấu @file, @changeset, @rollback để tools/gen_liquibase.py sinh changelog. DDL là nguồn chuẩn cho
gen_tables_md.py, them_dac_ta_bang.py, check_frs.py; không sửa tay tệp sinh ra, sửa ở đây rồi sinh lại.
Quy ước cột: snake_case của tên trường API; số định danh và giá trị SENSITIVE chỉ ở cột *_enc (envelope, ADR-032)
kèm *_hash (HMAC-SHA256, 32 byte) để đối sánh xác định; *_kid là mã khóa OpenBao transit.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRS = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH06-frs-du-lieu-chu.md")
APPX = open(FRS, encoding="utf-8").read()
APPX = APPX[APPX.index("## Phụ lục A."):]
S = "ph06_mdm"


def enum_values(name):
    m = re.search(r"^\| `%s` \| ([^|]+) \|" % name, APPX, re.M)
    if not m:
        raise SystemExit("Không có enum " + name)
    return re.findall(r"`([A-Z][A-Z0-9_]+)`", re.sub(r"\([^()]*\)", "", m.group(1)))


def E(name, only=None, skip=()):
    v = [x for x in enum_values(name) if x not in skip and (only is None or x in only)]
    if only:
        assert set(only) <= set(enum_values(name)), (name, only)
    return "(" + ", ".join("'%s'" % x for x in v) + ")"


def arr_in(col, name, skip=()):
    v = [x for x in enum_values(name) if x not in skip]
    return "%s <@ ARRAY[%s]::varchar[]" % (col, ", ".join("'%s'" % x for x in v))


TENANT_RE = "^T[0-9]{2}$"
DOMAIN_RE = "^[A-Z][A-Z0-9_]{1,31}$"
SRC_RE = "^[A-Z][A-Z0-9-]{2,31}$"
ATTR_RE = "^[a-z][a-zA-Z0-9]{1,62}$"
CODE_RE = "^[a-z][a-z0-9-]{2,62}$"

TABLES = []   # (file, changeset_id, table dict)
FILES = []


def T(name, comment, cols, cons=(), idx=(), part=None, std=True, tid=False, trig=(), post=(), pk=None, ccomment=None, version_start=0, nopk=False, rls=True):
    return dict(name=name, comment=comment, cols=cols, cons=list(cons), idx=list(idx), part=part, std=std, tid=tid,
                trig=list(trig), post=list(post), pk=pk, cc=ccomment or {}, vs=version_start, nopk=nopk, rls=rls)


def ENC(col, comment_nullable=True):
    """Cặp cột mã hóa envelope: <col>_enc bytea, <col>_kid."""
    return [f"{col}_enc bytea", f"{col}_kid varchar(64)"]


def chk(table, what, expr):
    return (f"ck_{table}_{what}", f"CHECK ({expr})")


def reason20(col="reason"):
    return f"char_length({col}) >= 20"


def four_eyes(a, b):
    return f"{a} IS NULL OR {b} IS NULL OR {a} <> {b}"


# ---------------------------------------------------------------------------------------------
# 06-0010 Mô hình domain, nguồn, ưu tiên nguồn
# ---------------------------------------------------------------------------------------------
G_MODEL = [
    T("mdm_domain",
      "EN-06-07 Domain dữ liệu chủ (FR-06-001, 006, 007): CITIZEN, ORGANIZATION, ADDRESS và domain tỉnh tự tạo (FR-06-002). Trạng thái DomainStatus. Không xóa; ngừng cần không còn bản ghi vàng ACTIVE (ERR-06-011). Giữ vĩnh viễn.",
      ["domain_code varchar(32) NOT NULL", "name varchar(255) NOT NULL", "description varchar(2000)",
       "status varchar(16) NOT NULL DEFAULT 'DRAFT'", "baseline boolean NOT NULL DEFAULT false", "baseline_package varchar(32)",
       "status_reason varchar(2000)"],
      [("uq_mdm_domain_code", "UNIQUE (tenant_id, domain_code)"),
       chk("mdm_domain", "code", f"domain_code ~ '{DOMAIN_RE}'"),
       chk("mdm_domain", "status", f"status IN {E('DomainStatus')}"),
       chk("mdm_domain", "reason", "status NOT IN ('SUSPENDED', 'RETIRED') OR status_reason IS NOT NULL")],
      trig=[("immutable", ["domain_code", "tenant_id", "baseline"])],
      ccomment={"baseline": "Có khi cài từ gói domain nền (FR-06-007); gói nền do PA phát hành.",
                "status_reason": "Bắt buộc khi SUSPENDED hoặc RETIRED."}),
    T("domain_model",
      "EN-06-07 Phiên bản mô hình domain (FR-06-002, 005, 006, BR-06-017). Máy trạng thái 4.6 không có TESTING. Mỗi domain đúng một phiên bản ACTIVE; ACTIVE không sửa nội dung, kể cả thuộc tính và khóa con. Duyệt bốn mắt (BR-06-004).",
      ["domain_code varchar(32) NOT NULL", "version_no integer NOT NULL", "status varchar(20) NOT NULL DEFAULT 'DRAFT'",
       "normalization jsonb NOT NULL DEFAULT '{}'", "compat_level varchar(16)", "diff_summary jsonb",
       "submitted_by varchar(64)", "submitted_at timestamptz", "submit_comment varchar(2000)",
       "decision varchar(8)", "decided_by varchar(64)", "decided_at timestamptz", "decision_comment varchar(2000)",
       "activated_at timestamptz", "superseded_at timestamptz"],
      [("uq_domain_model_version", "UNIQUE (tenant_id, domain_code, version_no)"),
       ("fk_domain_model_domain", f"FOREIGN KEY (tenant_id, domain_code) REFERENCES {S}.mdm_domain (tenant_id, domain_code)"),
       chk("domain_model", "version", "version_no >= 1"),
       chk("domain_model", "status", f"status IN {E('VersionStatus', skip=('TESTING',))}"),
       chk("domain_model", "compat", f"compat_level IS NULL OR compat_level IN {E('CompatLevel')}"),
       chk("domain_model", "decision", f"decision IS NULL OR decision IN {E('ApprovalDecision')}"),
       chk("domain_model", "four_eyes", four_eyes("decided_by", "submitted_by")),
       chk("domain_model", "active", "status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decision = 'APPROVE')"),
       chk("domain_model", "reject", "decision IS DISTINCT FROM 'REJECT' OR COALESCE(char_length(decision_comment) >= 20, false)")],
      idx=[f"CREATE UNIQUE INDEX uq_domain_model_active ON {S}.domain_model (tenant_id, domain_code) WHERE status = 'ACTIVE';"],
      tid=True, trig=[("immutable", ["domain_code", "version_no", "tenant_id"]), ("frozen", ["normalization"])],
      ccomment={"normalization": "Quy tắc chuẩn hóa theo thuộc tính (FR-06-014, 015), JSON có phiên bản.",
                "decision_comment": "Từ chối bắt buộc ≥ 20 ký tự (FR-06-006)."}),
    T("model_attribute",
      "EN-06-07 Thuộc tính của một phiên bản mô hình (FR-06-002, 004). Giá trị DataClass, ClassificationStatus; thuộc tính DLCN cần phân loại CONFIRMED trước khi kích hoạt (BR-06-016, kiểm ở dịch vụ, ERR-06-010). Phiên bản ACTIVE chặn thêm, sửa, xóa (trigger).",
      ["domain_code varchar(32) NOT NULL", "version_no integer NOT NULL", "attribute_name varchar(63) NOT NULL",
       "label varchar(255) NOT NULL", "attribute_type varchar(16) NOT NULL", "code_list_ref varchar(63)",
       "required boolean NOT NULL DEFAULT false", "multi_valued boolean NOT NULL DEFAULT false",
       "critical boolean NOT NULL DEFAULT false", "matchable boolean NOT NULL DEFAULT false",
       "data_class varchar(16) NOT NULL DEFAULT 'INTERNAL'", "classification_status varchar(16) NOT NULL DEFAULT 'PROPOSED'",
       "personal_data boolean NOT NULL DEFAULT false", "legal_basis varchar(2000)", "sort_order smallint NOT NULL DEFAULT 0"],
      [("uq_model_attribute_name", "UNIQUE (tenant_id, domain_code, version_no, attribute_name)"),
       ("fk_model_attribute_model", f"FOREIGN KEY (tenant_id, domain_code, version_no) REFERENCES {S}.domain_model (tenant_id, domain_code, version_no)"),
       chk("model_attribute", "name", f"attribute_name ~ '{ATTR_RE}'"),
       chk("model_attribute", "type", f"attribute_type IN {E('AttributeType')}"),
       chk("model_attribute", "class", f"data_class IN {E('DataClass')}"),
       chk("model_attribute", "classification", f"classification_status IN {E('ClassificationStatus')}"),
       chk("model_attribute", "personal", "(NOT personal_data OR legal_basis IS NOT NULL) AND (data_class <> 'SENSITIVE' OR personal_data)"),
       chk("model_attribute", "coderef", "(attribute_type = 'CODE_REF') = (code_list_ref IS NOT NULL)")],
      trig=[("child_frozen", [])],
      ccomment={"data_class": "Phân loại theo DD-08; SENSITIVE bắt buộc personal_data.",
                "matchable": "Dùng được trong quy tắc đối sánh (FR-06-018)."}),
    T("identifier_rule",
      "EN-06-07 Khóa định danh và bộ kiểm tra của phiên bản mô hình (FR-06-003, BR-06-001). Mỗi domain cần ít nhất một khóa hoặc tổ hợp đối sánh (ERR-06-009, kiểm ở dịch vụ khi gửi duyệt).",
      ["domain_code varchar(32) NOT NULL", "version_no integer NOT NULL", "identifier_type varchar(16) NOT NULL",
       "attribute_name varchar(63) NOT NULL", "validator varchar(16) NOT NULL", "pattern varchar(500)",
       "deterministic boolean NOT NULL DEFAULT false", "unique_among_active boolean NOT NULL DEFAULT true"],
      [("uq_identifier_rule", "UNIQUE (tenant_id, domain_code, version_no, identifier_type)"),
       ("fk_identifier_rule_model", f"FOREIGN KEY (tenant_id, domain_code, version_no) REFERENCES {S}.domain_model (tenant_id, domain_code, version_no)"),
       chk("identifier_rule", "type", f"identifier_type IN {E('IdentifierType')}"),
       chk("identifier_rule", "validator", "validator IN ('CCCD_12', 'CMND_9', 'MST_10_13', 'MSDN', 'MA_BHXH_10', 'DVHC_CODE', 'REGEX')"),
       chk("identifier_rule", "regex", "(validator = 'REGEX') = (pattern IS NOT NULL)")],
      trig=[("child_frozen", [])],
      ccomment={"validator": "Danh sách ở đầu vào FR-06-003; chữ số kiểm tra theo Q06-09."}),
    T("mdm_source",
      "EN-06-08 Nguồn dữ liệu chủ gắn HTTT (FR-06-008, BR-06-032). trust_level 1…5; nguồn NATIONAL_DB chỉ nhận qua PH-14, không kết nối thẳng. Chỉ nguồn ACTIVE cho domain mới được nạp (ERR-06-014).",
      ["source_code varchar(32) NOT NULL", "name varchar(255) NOT NULL", "system_code varchar(63)", "source_kind varchar(24) NOT NULL",
       "status varchar(16) NOT NULL DEFAULT 'DRAFT'", "domains varchar(32)[] NOT NULL", "channels varchar(16)[] NOT NULL",
       "attribute_scope varchar(63)[] NOT NULL DEFAULT '{}'", "owner_org_code varchar(63) NOT NULL",
       "trust_level smallint NOT NULL DEFAULT 3", "status_reason varchar(2000)"],
      [("uq_mdm_source_code", "UNIQUE (tenant_id, source_code)"),
       chk("mdm_source", "code", f"source_code ~ '{SRC_RE}'"),
       chk("mdm_source", "kind", f"source_kind IN {E('SourceKind')}"),
       chk("mdm_source", "status", f"status IN {E('SourceStatus')}"),
       chk("mdm_source", "channels", f"cardinality(channels) >= 1 AND {arr_in('channels', 'IngestChannel')}"),
       chk("mdm_source", "domains", "cardinality(domains) >= 1"),
       chk("mdm_source", "trust", "trust_level BETWEEN 1 AND 5"),
       chk("mdm_source", "system", "source_kind IN ('MANUAL_ENTRY', 'FILE_BATCH', 'NATIONAL_DB') OR system_code IS NOT NULL")],
      trig=[("immutable", ["source_code", "tenant_id"])],
      ccomment={"system_code": "Mã HTTT ở PH-01 (không khóa ngoại, khác schema); HTTT phải ACTIVE khi đăng ký (ERR-06-012).",
                "domains": "Mã domain ACTIVE được phép gửi; kiểm ở dịch vụ."}),
    T("source_priority_proposal",
      "EN-06-04, EN-06-22 Đề nghị thứ tự ưu tiên nguồn chờ duyệt (FR-06-009, BR-06-004). Cần căn cứ văn bản approval_ref; DA duyệt khác người đề nghị (ERR-06-005, 013).",
      ["domain_code varchar(32) NOT NULL", "entries jsonb NOT NULL", "approval_ref varchar(255) NOT NULL", "justification varchar(2000) NOT NULL",
       "status varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL'", "proposed_by varchar(64) NOT NULL", "decided_by varchar(64)",
       "decided_at timestamptz", "decision_comment varchar(2000)"],
      [("fk_source_priority_proposal_domain", f"FOREIGN KEY (tenant_id, domain_code) REFERENCES {S}.mdm_domain (tenant_id, domain_code)"),
       chk("source_priority_proposal", "status", f"status IN {E('VersionStatus', only=('PENDING_APPROVAL', 'ACTIVE', 'REJECTED'))}"),
       chk("source_priority_proposal", "four_eyes", four_eyes("decided_by", "proposed_by")),
       chk("source_priority_proposal", "entries", "jsonb_typeof(entries) = 'array' AND jsonb_array_length(entries) BETWEEN 1 AND 500"),
       chk("source_priority_proposal", "decided", "(status = 'PENDING_APPROVAL') = (decided_by IS NULL)")],
      tid=True, trig=[("immutable", ["domain_code", "entries", "approval_ref", "proposed_by"])],
      ccomment={"entries": "Mảng {sourceCode, attribute, priority} theo FR-06-009; áp vào source_priority khi duyệt."}),
    T("source_priority",
      "EN-06-04 Mức ưu tiên nguồn theo domain và thuộc tính đang hiệu lực (FR-06-009, 033). attribute_name = '*' là mọi thuộc tính. Nguồn quốc gia luôn ưu tiên 1 với thuộc tính thẩm quyền quốc gia (BR-06-003). Bản cũ đóng bằng effective_to.",
      ["domain_code varchar(32) NOT NULL", "source_code varchar(32) NOT NULL", "attribute_name varchar(63) NOT NULL DEFAULT '*'",
       "priority smallint NOT NULL", "approval_ref varchar(255) NOT NULL", "proposal_id uuid NOT NULL",
       "effective_from timestamptz NOT NULL DEFAULT now()", "effective_to timestamptz"],
      [("fk_source_priority_source", f"FOREIGN KEY (tenant_id, source_code) REFERENCES {S}.mdm_source (tenant_id, source_code)"),
       ("fk_source_priority_proposal", f"FOREIGN KEY (tenant_id, proposal_id) REFERENCES {S}.source_priority_proposal (tenant_id, id)"),
       chk("source_priority", "priority", "priority BETWEEN 1 AND 99"),
       chk("source_priority", "attr", f"attribute_name = '*' OR attribute_name ~ '{ATTR_RE}'"),
       chk("source_priority", "period", "effective_to IS NULL OR effective_to > effective_from")],
      idx=[f"CREATE UNIQUE INDEX uq_source_priority_current ON {S}.source_priority (tenant_id, domain_code, source_code, attribute_name) WHERE effective_to IS NULL;",
           f"CREATE INDEX ix_source_priority_domain ON {S}.source_priority (tenant_id, domain_code, attribute_name, priority) WHERE effective_to IS NULL;"],
      ccomment={"priority": "1 cao nhất … 99 (FR-06-009)."}),
]

# ---------------------------------------------------------------------------------------------
# 06-0020 Nạp ứng viên
# ---------------------------------------------------------------------------------------------
G_INGEST = [
    T("candidate_file",
      "EN-06-25 FR-06-013 Tệp lô nạp ứng viên: tải lên, xem trước, xác nhận. Tệp ≤ 50 MB, ≤ 200.000 dòng (ERR-06-018, 019). Nội dung tệp nằm ở Ceph RGW (object_ref), không trong PostgreSQL; báo cáo xem trước ở preview jsonb, không chứa giá trị SENSITIVE.",
      ["domain_code varchar(32) NOT NULL", "source_code varchar(32) NOT NULL", "file_name varchar(255) NOT NULL", "size_bytes bigint NOT NULL",
       "row_count integer", "object_ref varchar(512) NOT NULL", "sha256 char(64) NOT NULL", "column_mapping jsonb NOT NULL DEFAULT '{}'",
       "preview jsonb", "previewed_at timestamptz", "confirmed_by varchar(64)", "confirmed_at timestamptz", "job_id uuid", "expires_at timestamptz NOT NULL"],
      [("fk_candidate_file_domain", f"FOREIGN KEY (tenant_id, domain_code) REFERENCES {S}.mdm_domain (tenant_id, domain_code)"),
       ("fk_candidate_file_source", f"FOREIGN KEY (tenant_id, source_code) REFERENCES {S}.mdm_source (tenant_id, source_code)"),
       chk("candidate_file", "size", "size_bytes BETWEEN 1 AND 52428800 AND (row_count IS NULL OR row_count BETWEEN 0 AND 200000)"),
       chk("candidate_file", "sha", "sha256 ~ '^[0-9a-f]{64}$'"),
       chk("candidate_file", "confirm", "(confirmed_at IS NULL) = (confirmed_by IS NULL)")],
      idx=[f"CREATE INDEX ix_candidate_file_domain ON {S}.candidate_file (tenant_id, domain_code, created_at DESC);"],
      trig=[("immutable", ["domain_code", "source_code", "sha256"])]),
    T("source_record_head",
      "EN-06-26 FR-06-016 Trạng thái mới nhất của mỗi bản ghi nguồn (sourceCode, sourceKey): phiên bản cao nhất đã nhận, ứng viên cuối, bản ghi vàng đang liên kết. Thực thi BR-06-028 (xử lý một lần theo sourceVersion) và BR-06-029 (bản đến trễ không ghi đè); là bảng nhỏ, khóa duy nhất không phải phân vùng.",
      ["domain_code varchar(32) NOT NULL", "source_code varchar(32) NOT NULL", "source_key varchar(120) NOT NULL",
       "last_version bigint NOT NULL", "last_candidate_id uuid NOT NULL", "last_source_updated_at timestamptz NOT NULL",
       "deleted boolean NOT NULL DEFAULT false", "golden_id uuid"],
      [("uq_source_record_head", "UNIQUE (tenant_id, domain_code, source_code, source_key)"),
       ("fk_source_record_head_source", f"FOREIGN KEY (tenant_id, source_code) REFERENCES {S}.mdm_source (tenant_id, source_code)"),
       chk("source_record_head", "version", "last_version >= 0")],
      idx=[f"CREATE INDEX ix_source_record_head_golden ON {S}.source_record_head (tenant_id, golden_id) WHERE golden_id IS NOT NULL;"],
      ccomment={"golden_id": "Bản ghi vàng đang liên kết; tham chiếu logic để không khóa chéo khi hợp nhất."}),
    T("candidate_record",
      "EN-06-09 Bản ghi ứng viên nhận từ nguồn (FR-06-010…017). Dữ liệu gốc mã hóa envelope ở raw_enc; số định danh chỉ ở dạng HMAC identifier_hash; khóa gom nhóm là HMAC (BR-06-016). Phân vùng tháng theo received_at; giữ 365 ngày sau xử lý (retention_policy, khớp SRS cũ), sau đó ẩn danh hóa raw_enc.",
      ["received_at timestamptz NOT NULL DEFAULT now()", "domain_code varchar(32) NOT NULL", "source_code varchar(32) NOT NULL",
       "source_key varchar(120) NOT NULL", "source_version bigint NOT NULL", "source_updated_at timestamptz NOT NULL",
       "operation varchar(8) NOT NULL", "channel varchar(16) NOT NULL", "status varchar(24) NOT NULL DEFAULT 'RECEIVED'",
       "model_version integer", "raw_enc bytea", "raw_kid varchar(64)", "attrs_norm jsonb", "name_norm varchar(255)", "birth_year smallint",
       "admin_unit_code varchar(16)", "identifier_type varchar(16)", "identifier_status varchar(20)", "identifier_hash bytea",
       "block_keys varchar(72)[]", "warnings varchar(24)[] NOT NULL DEFAULT '{}'", "attribute_count smallint NOT NULL DEFAULT 0",
       "golden_id uuid", "match_outcome varchar(16)", "file_id uuid", "flow_code varchar(63)", "exchange_id varchar(64)",
       "idempotency_key varchar(128)", "reject_code varchar(16)", "reject_detail varchar(2000)", "processed_at timestamptz"],
      [chk("candidate_record", "op", f"operation IN {E('CandidateOperation')}"),
       chk("candidate_record", "channel", f"channel IN {E('IngestChannel')}"),
       chk("candidate_record", "status", f"status IN {E('CandidateStatus')}"),
       chk("candidate_record", "idstatus", f"identifier_status IS NULL OR identifier_status IN {E('IdentifierStatus')}"),
       chk("candidate_record", "idtype", f"identifier_type IS NULL OR identifier_type IN {E('IdentifierType')}"),
       chk("candidate_record", "outcome", f"match_outcome IS NULL OR match_outcome IN {E('MatchOutcome')}"),
       chk("candidate_record", "warnings", arr_in("warnings", "NormalizationWarning")),
       chk("candidate_record", "hash", "identifier_hash IS NULL OR octet_length(identifier_hash) = 32"),
       chk("candidate_record", "raw", "raw_enc IS NULL OR (raw_kid IS NOT NULL AND octet_length(raw_enc) BETWEEN 29 AND 1048576)"),
       chk("candidate_record", "reject", "status <> 'REJECTED' OR COALESCE(reject_code ~ '^ERR-06-0[0-9]{2}$', false)"),
       chk("candidate_record", "birth", "birth_year IS NULL OR birth_year BETWEEN 1850 AND 2100"),
       chk("candidate_record", "key", "char_length(source_key) >= 1")],
      idx=[f"CREATE INDEX ix_candidate_record_queue ON {S}.candidate_record (tenant_id, domain_code, status, received_at);",
           f"CREATE INDEX ix_candidate_record_source ON {S}.candidate_record (tenant_id, source_code, source_key, source_version);",
           f"CREATE INDEX ix_candidate_record_idhash ON {S}.candidate_record (tenant_id, domain_code, identifier_hash) WHERE identifier_hash IS NOT NULL;",
           f"CREATE INDEX ix_candidate_record_blocks ON {S}.candidate_record USING gin (block_keys);",
           f"CREATE INDEX ix_candidate_record_name_trgm ON {S}.candidate_record USING gin (name_norm gin_trgm_ops);",
           f"CREATE INDEX ix_candidate_record_golden ON {S}.candidate_record (tenant_id, golden_id) WHERE golden_id IS NOT NULL;"],
      part=("received_at", "month", 3), pk=("id", "received_at"), std=False,
      ccomment={"raw_enc": "Bản ghi gốc, mã hóa envelope (ADR-032); NULL sau khi dọn lưu giữ.",
                "identifier_hash": "HMAC-SHA256 của số định danh đã chuẩn hóa; dùng đối sánh xác định (FR-06-020).",
                "block_keys": "Khóa gom nhóm dạng HMAC có tiền tố tên khóa (FR-06-019).",
                "name_norm": "Họ tên không dấu, chữ thường (pg_trgm, FR-06-021).",
                "golden_id": "Bản ghi vàng liên kết; không khóa ngoại để giữ khi bảng vàng đổi."}),
]

# ---------------------------------------------------------------------------------------------
# 06-0030 Đối sánh
# ---------------------------------------------------------------------------------------------
G_MATCH = [
    T("evaluation_report",
      "EN-06-23 FR-06-026 Báo cáo đánh giá chính xác (precision, recall) của một phiên bản bộ quy tắc trên tập nhãn (BR-06-021). Là căn cứ kích hoạt bộ quy tắc; tham chiếu bộ quy tắc theo (domain_code, rule_set_version) để tránh vòng khóa ngoại.",
      ["domain_code varchar(32) NOT NULL", "rule_set_version integer NOT NULL", "label_set_code varchar(63) NOT NULL", "pair_count integer NOT NULL",
       "precision_pct numeric(6,3) NOT NULL", "recall_pct numeric(6,3) NOT NULL", "verdict varchar(8) NOT NULL", "job_id uuid",
       "confusion jsonb NOT NULL DEFAULT '{}'", "evaluated_at timestamptz NOT NULL DEFAULT now()"],
      [("fk_evaluation_report_domain", f"FOREIGN KEY (tenant_id, domain_code) REFERENCES {S}.mdm_domain (tenant_id, domain_code)"),
       chk("evaluation_report", "verdict", f"verdict IN {E('EvaluationVerdict')}"),
       chk("evaluation_report", "pct", "precision_pct BETWEEN 0 AND 100 AND recall_pct BETWEEN 0 AND 100 AND pair_count >= 0"),
       chk("evaluation_report", "pass", "verdict <> 'PASSED' OR (pair_count >= 1000 AND precision_pct >= 99.9 AND recall_pct >= 98)")],
      idx=[f"CREATE INDEX ix_evaluation_report_rule ON {S}.evaluation_report (tenant_id, domain_code, rule_set_version, evaluated_at DESC);"],
      tid=True, ccomment={"verdict": "PASSED chỉ khi ≥ 1.000 cặp, precision ≥ 99,9%, recall ≥ 98% (BR-06-021)."}),
    T("match_rule_set",
      "EN-06-10 Phiên bản bộ quy tắc đối sánh (FR-06-018, 019, 023). Ngưỡng ba vùng chốt ở CHECK (BR-06-020); ACTIVE phải có báo cáo đánh giá đạt (BR-06-021) và bất biến nội dung (BR-06-017). Duyệt bốn mắt.",
      ["domain_code varchar(32) NOT NULL", "version_no integer NOT NULL", "status varchar(20) NOT NULL DEFAULT 'DRAFT'",
       "blocking_keys jsonb NOT NULL DEFAULT '[]'", "auto_merge_threshold numeric(3,2) NOT NULL DEFAULT 0.95",
       "review_threshold numeric(3,2) NOT NULL DEFAULT 0.60", "auto_merge_enabled boolean NOT NULL DEFAULT false",
       "min_attributes smallint NOT NULL DEFAULT 3", "splink_params jsonb", "evaluation_report_id uuid",
       "submitted_by varchar(64)", "submitted_at timestamptz", "decision varchar(8)", "decided_by varchar(64)", "decided_at timestamptz",
       "decision_comment varchar(2000)", "activated_at timestamptz", "superseded_at timestamptz"],
      [("uq_match_rule_set_version", "UNIQUE (tenant_id, domain_code, version_no)"),
       ("fk_match_rule_set_domain", f"FOREIGN KEY (tenant_id, domain_code) REFERENCES {S}.mdm_domain (tenant_id, domain_code)"),
       ("fk_match_rule_set_eval", f"FOREIGN KEY (tenant_id, evaluation_report_id) REFERENCES {S}.evaluation_report (tenant_id, id)"),
       chk("match_rule_set", "status", f"status IN {E('VersionStatus')}"),
       chk("match_rule_set", "decision", f"decision IS NULL OR decision IN {E('ApprovalDecision')}"),
       chk("match_rule_set", "threshold", "auto_merge_threshold >= 0.90 AND review_threshold >= 0 AND auto_merge_threshold - review_threshold >= 0.10"),
       chk("match_rule_set", "four_eyes", four_eyes("decided_by", "submitted_by")),
       chk("match_rule_set", "active", "status <> 'ACTIVE' OR (evaluation_report_id IS NOT NULL AND decision = 'APPROVE' AND activated_at IS NOT NULL)"),
       chk("match_rule_set", "minattr", "min_attributes BETWEEN 1 AND 20")],
      idx=[f"CREATE UNIQUE INDEX uq_match_rule_set_active ON {S}.match_rule_set (tenant_id, domain_code) WHERE status = 'ACTIVE';"],
      tid=True, trig=[("immutable", ["domain_code", "version_no"]), ("frozen", ["blocking_keys", "auto_merge_threshold", "review_threshold", "min_attributes", "splink_params"])],
      ccomment={"blocking_keys": "Biểu thức khóa gom nhóm, ví dụ prefix(nameAscii.given,3)+year(dateOfBirth) (FR-06-019).",
                "splink_params": "Tham số m, u của Splink sau huấn luyện (FR-06-022)."}),
    T("match_rule",
      "EN-06-10 Quy tắc con của bộ quy tắc: xác định, xác suất, loại trừ (FR-06-018). Quy tắc EXCLUSION cho khóa định danh khác nhau không tắt được (BR-06-006). Tổng trọng số PROBABILISTIC bằng 1,00 kiểm ở dịch vụ khi gửi duyệt.",
      ["domain_code varchar(32) NOT NULL", "version_no integer NOT NULL", "seq smallint NOT NULL", "rule_type varchar(16) NOT NULL",
       "attribute_name varchar(63) NOT NULL", "comparator varchar(16) NOT NULL", "weight numeric(5,4)", "params jsonb NOT NULL DEFAULT '{}'"],
      [("uq_match_rule_seq", "UNIQUE (tenant_id, domain_code, version_no, seq)"),
       ("fk_match_rule_set", f"FOREIGN KEY (tenant_id, domain_code, version_no) REFERENCES {S}.match_rule_set (tenant_id, domain_code, version_no)"),
       chk("match_rule", "type", f"rule_type IN {E('MatchRuleType')}"),
       chk("match_rule", "comparator", f"comparator IN {E('Comparator')}"),
       chk("match_rule", "weight", "weight IS NULL OR weight BETWEEN 0 AND 1"),
       chk("match_rule", "prob", "rule_type <> 'PROBABILISTIC' OR weight IS NOT NULL")],
      trig=[("child_frozen_rules", [])]),
    T("match_job",
      "EN-06-12 Job theo lô và job nền (FR-06-022, 056): đối sánh Splink, chạy thử, đánh giá, áp lại sống sót, mã hóa lại, nạp tệp, xuất, đồng bộ quốc gia, dọn lưu giữ. Máy trạng thái 4.5. Một job đang chạy mỗi (domain, loại) (ERR-06-025). Job lô vượt safety-ratio dừng ở AWAITING_CONFIRMATION (BR-06-022).",
      ["domain_code varchar(32) NOT NULL DEFAULT '*'", "job_type varchar(24) NOT NULL", "status varchar(24) NOT NULL DEFAULT 'QUEUED'",
       "scope varchar(24)", "since timestamptz", "train_only boolean NOT NULL DEFAULT false", "dry_run boolean NOT NULL DEFAULT false",
       "rule_set_version integer", "requested_by varchar(64) NOT NULL", "parent_job_id uuid", "counts jsonb NOT NULL DEFAULT '{}'",
       "parameters jsonb", "k8s_job_name varchar(63)", "started_at timestamptz", "finished_at timestamptz", "confirmed_by varchar(64)",
       "confirmed_at timestamptz", "cancel_reason varchar(2000)", "error_code varchar(16)", "error_detail varchar(2000)"],
      [chk("match_job", "domain", f"domain_code = '*' OR domain_code ~ '{DOMAIN_RE}'"),
       chk("match_job", "type", f"job_type IN {E('JobType')}"),
       chk("match_job", "status", f"status IN {E('JobStatus')}"),
       chk("match_job", "scope", f"scope IS NULL OR scope IN {E('BatchScope')}"),
       chk("match_job", "error", "error_code IS NULL OR error_code ~ '^ERR-06-1[0-9]{2}$'"),
       chk("match_job", "failed", "status <> 'FAILED' OR error_code IS NOT NULL"),
       chk("match_job", "cancel", "status <> 'CANCELLED' OR cancel_reason IS NOT NULL"),
       chk("match_job", "confirm", "confirmed_by IS NULL OR confirmed_by <> requested_by"),
       chk("match_job", "finished", "status NOT IN ('SUCCEEDED', 'PARTIALLY_SUCCEEDED', 'FAILED', 'CANCELLED') OR finished_at IS NOT NULL")],
      idx=[f"CREATE UNIQUE INDEX uq_match_job_running ON {S}.match_job (tenant_id, domain_code, job_type) WHERE status IN ('QUEUED', 'PREPARING', 'RUNNING', 'AWAITING_CONFIRMATION', 'APPLYING');",
           f"CREATE INDEX ix_match_job_list ON {S}.match_job (tenant_id, created_at DESC);"],
      tid=True, trig=[("immutable", ["job_type", "domain_code", "requested_by"])],
      ccomment={"confirmed_by": "DA xác nhận job vượt ngưỡng an toàn, khác người yêu cầu.",
                "counts": "input, pairs, match, possible, noMatch, applied, skipped (FR-06-022)."}),
    T("job_schedule",
      "EN-06-24 FR-06-056 Lịch job tự động theo loại (cron giờ Việt Nam). Mỗi tenant một dòng cho mỗi JobType; ScheduleJob (ShedLock) đọc next_run_at.",
      ["job_type varchar(24) NOT NULL", "cron varchar(64) NOT NULL", "enabled boolean NOT NULL DEFAULT true", "params jsonb NOT NULL DEFAULT '{}'",
       "max_duration_minutes integer NOT NULL DEFAULT 240", "next_run_at timestamptz", "last_run_at timestamptz", "last_job_id uuid"],
      [("uq_job_schedule_type", "UNIQUE (tenant_id, job_type)"),
       chk("job_schedule", "type", f"job_type IN {E('JobType')}"),
       chk("job_schedule", "duration", "max_duration_minutes BETWEEN 5 AND 1440"),
       chk("job_schedule", "cron", "cron ~ '^[0-9*/,-]+( [0-9*/,?LW#-]+){4,5}$'")],
      trig=[("immutable", ["job_type"])]),
    T("match_staging",
      "EN-06-27 FR-06-022 Bảng trung gian xuất cho Job K8s Splink đọc (SAD: đối sánh lô qua staging). Chỉ chứa trường chuẩn hóa không SENSITIVE và HMAC; xóa sau job (retention 7 ngày, BR-06-031). Job Splink đọc bằng vai trò ph06_splink (chỉ SELECT match_staging, chỉ INSERT match_result), không ghi thẳng vào bản ghi vàng.",
      ["job_id uuid NOT NULL", "candidate_id uuid", "golden_id uuid", "source_version bigint", "fields jsonb NOT NULL",
       "block_keys varchar(72)[] NOT NULL DEFAULT '{}'", "exported_at timestamptz NOT NULL DEFAULT now()"],
      [("fk_match_staging_job", f"FOREIGN KEY (tenant_id, job_id) REFERENCES {S}.match_job (tenant_id, id) ON DELETE CASCADE"),
       chk("match_staging", "ref", "(candidate_id IS NULL) <> (golden_id IS NULL)")],
      idx=[f"CREATE INDEX ix_match_staging_job ON {S}.match_staging (tenant_id, job_id);"], std=False,
      ccomment={"fields": "Thuộc tính chuẩn hóa; trường SENSITIVE chỉ dạng HMAC, không bao giờ bản rõ (BR-06-016)."}),
    T("match_result",
      "EN-06-11 Kết quả đối sánh một cặp (ứng viên hoặc bản ghi vàng với bản ghi vàng) (FR-06-020…023). Lưu điểm từng thuộc tính theo ComparisonLevel để giải thích. Phân vùng tháng theo scored_at; giữ 2 năm để hiệu chỉnh thuật toán (SRS cũ 4.3).",
      ["scored_at timestamptz NOT NULL DEFAULT now()", "domain_code varchar(32) NOT NULL", "left_candidate_id uuid", "left_golden_id uuid",
       "right_golden_id uuid NOT NULL", "method varchar(24) NOT NULL", "outcome varchar(16) NOT NULL", "score numeric(5,4)",
       "attribute_scores jsonb NOT NULL DEFAULT '{}'", "rule_set_version integer", "job_id uuid", "queue_item_id uuid",
       "applied boolean NOT NULL DEFAULT false", "applied_operation_id uuid", "skip_code varchar(16)"],
      [chk("match_result", "method", f"method IN {E('MatchMethod')}"),
       chk("match_result", "outcome", f"outcome IN {E('MatchOutcome')}"),
       chk("match_result", "left", "(left_candidate_id IS NULL) <> (left_golden_id IS NULL)"),
       chk("match_result", "score", "score IS NULL OR score BETWEEN 0 AND 1"),
       chk("match_result", "skip", "skip_code IS NULL OR skip_code = 'ERR-06-104'"),
       chk("match_result", "deterministic", "method <> 'DETERMINISTIC' OR score = 1")],
      idx=[f"CREATE INDEX ix_match_result_candidate ON {S}.match_result (tenant_id, left_candidate_id) WHERE left_candidate_id IS NOT NULL;",
           f"CREATE INDEX ix_match_result_golden ON {S}.match_result (tenant_id, right_golden_id, scored_at DESC);",
           f"CREATE INDEX ix_match_result_job ON {S}.match_result (tenant_id, job_id) WHERE job_id IS NOT NULL;"],
      part=("scored_at", "month", 3), pk=("id", "scored_at"), std=False),
    T("label_set",
      "EN-06-15 Tập nhãn kiểm chứng (FR-06-025): EVALUATION để đo precision, recall; TRAINING để huấn luyện Splink. Nghiệm thu cần ≥ 10.000 cặp (NFR-06-008).",
      ["label_set_code varchar(63) NOT NULL", "domain_code varchar(32) NOT NULL", "purpose varchar(16) NOT NULL", "description varchar(2000)",
       "pair_count integer NOT NULL DEFAULT 0", "locked boolean NOT NULL DEFAULT false", "locked_at timestamptz", "locked_by varchar(64)"],
      [("uq_label_set_code", "UNIQUE (tenant_id, label_set_code)"),
       ("fk_label_set_domain", f"FOREIGN KEY (tenant_id, domain_code) REFERENCES {S}.mdm_domain (tenant_id, domain_code)"),
       chk("label_set", "code", f"label_set_code ~ '{CODE_RE}'"),
       chk("label_set", "purpose", f"purpose IN {E('LabelSetPurpose')}"),
       chk("label_set", "count", "pair_count >= 0"),
       chk("label_set", "locked", "locked = (locked_at IS NOT NULL AND locked_by IS NOT NULL)")],
      tid=True, trig=[("immutable", ["label_set_code", "domain_code", "purpose"])]),
    T("label_pair",
      "EN-06-15 Cặp có nhãn MATCH, NO_MATCH của tập nhãn (FR-06-025, 030 addToLabelSet). Hai đầu theo thứ tự chuẩn left_id < right_id; ảnh chụp thuộc tính hai bên mã hóa để đánh giá lặp lại ổn định.",
      ["label_set_id uuid NOT NULL", "left_id uuid NOT NULL", "right_id uuid NOT NULL", "label varchar(8) NOT NULL", "labeled_by varchar(64) NOT NULL",
       "source_item_id uuid", "snapshot_enc bytea", "snapshot_kid varchar(64)"],
      [("uq_label_pair", "UNIQUE (tenant_id, label_set_id, left_id, right_id)"),
       ("fk_label_pair_set", f"FOREIGN KEY (tenant_id, label_set_id) REFERENCES {S}.label_set (tenant_id, id)"),
       chk("label_pair", "label", f"label IN {E('PairLabel')}"),
       chk("label_pair", "order", "left_id < right_id"),
       chk("label_pair", "snapshot", "snapshot_enc IS NULL OR snapshot_kid IS NOT NULL")],
      trig=[("immutable", ["label_set_id", "left_id", "right_id"])]),
]

# ---------------------------------------------------------------------------------------------
# 06-0040 Hàng đợi người quản lý dữ liệu
# ---------------------------------------------------------------------------------------------
G_STEWARD = [
    T("steward_item",
      "EN-06-05 Mục hàng đợi người quản lý dữ liệu (FR-06-027…032). Máy trạng thái 4.4. Quyết định cần lý do ≥ 20 ký tự (BR-06-008); MATCH rủi ro cao chờ DA duyệt khác người quyết định (BR-06-019, ERR-06-005). Mỗi cặp một mục mở.",
      ["domain_code varchar(32) NOT NULL", "reason varchar(24) NOT NULL", "status varchar(20) NOT NULL DEFAULT 'OPEN'",
       "risk_level varchar(4) NOT NULL DEFAULT 'LOW'", "priority smallint NOT NULL DEFAULT 50", "left_candidate_id uuid", "left_golden_id uuid",
       "right_golden_id uuid", "match_result_id uuid", "score numeric(5,4)", "attribute_scores jsonb NOT NULL DEFAULT '{}'",
       "source_codes varchar(32)[] NOT NULL DEFAULT '{}'", "assignee varchar(64)", "claimed_at timestamptz", "hold_until timestamptz",
       "due_at timestamptz NOT NULL", "escalated_at timestamptz", "defer_until timestamptz", "decision varchar(8)", "decision_reason varchar(2000)",
       "decided_by varchar(64)", "decided_at timestamptz", "survivor_id uuid", "approval_decision varchar(8)", "approved_by varchar(64)",
       "approved_at timestamptz", "approval_comment varchar(2000)", "operation_id uuid", "cancel_reason varchar(500)",
       "reopen_count smallint NOT NULL DEFAULT 0", "reopened_at timestamptz", "reopened_by varchar(64)", "reopen_reason varchar(2000)", "decision_history jsonb NOT NULL DEFAULT '[]'"],
      [("fk_steward_item_domain", f"FOREIGN KEY (tenant_id, domain_code) REFERENCES {S}.mdm_domain (tenant_id, domain_code)"),
       chk("steward_item", "reason", f"reason IN {E('QueueReason')}"),
       chk("steward_item", "status", f"status IN {E('QueueItemStatus')}"),
       chk("steward_item", "risk", f"risk_level IN {E('RiskLevel')}"),
       chk("steward_item", "decision", f"decision IS NULL OR decision IN {E('StewardDecision')}"),
       chk("steward_item", "approval", f"approval_decision IS NULL OR approval_decision IN {E('ApprovalDecision')}"),
       chk("steward_item", "priority", "priority BETWEEN 1 AND 100"),
       chk("steward_item", "left", "(left_candidate_id IS NULL) <> (left_golden_id IS NULL) OR status = 'CANCELLED'"),
       chk("steward_item", "reason20", "decision_reason IS NULL OR char_length(decision_reason) >= 20"),
       chk("steward_item", "four_eyes", four_eyes("approved_by", "decided_by")),
       chk("steward_item", "pending", "status <> 'PENDING_APPROVAL' OR (decision = 'MATCH' AND risk_level = 'HIGH' AND decided_by IS NOT NULL)"),
       chk("steward_item", "resolved", "status <> 'RESOLVED' OR (decision IN ('MATCH', 'NO_MATCH') AND decided_by IS NOT NULL AND decided_at IS NOT NULL)"),
       chk("steward_item", "assigned", "status NOT IN ('ASSIGNED', 'PENDING_APPROVAL') OR assignee IS NOT NULL"),
       chk("steward_item", "defer", "(status = 'DEFERRED') = (defer_until IS NOT NULL)")],
      idx=[f"CREATE UNIQUE INDEX uq_steward_item_open_pair ON {S}.steward_item (tenant_id, domain_code, COALESCE(left_candidate_id, left_golden_id), right_golden_id) WHERE status NOT IN ('RESOLVED', 'CANCELLED') AND right_golden_id IS NOT NULL;",
           f"CREATE INDEX ix_steward_item_queue ON {S}.steward_item (tenant_id, domain_code, status, priority DESC, due_at);",
           f"CREATE INDEX ix_steward_item_assignee ON {S}.steward_item (tenant_id, assignee, status) WHERE assignee IS NOT NULL;",
           f"CREATE INDEX ix_steward_item_nomatch ON {S}.steward_item (tenant_id, domain_code, left_golden_id, right_golden_id) WHERE decision = 'NO_MATCH' AND status = 'RESOLVED';"],
      tid=True, trig=[("immutable", ["domain_code", "left_candidate_id", "left_golden_id", "right_golden_id"])],
      ccomment={"hold_until": "Hết hạn giữ 30 phút (06.queue.hold-minutes) thì trả OPEN.",
                "left_golden_id": "Cặp NO_MATCH đã RESOLVED là liên kết âm (BR-06-023): không đề xuất lại; chỉ mục ix_steward_item_nomatch."}),
]

# ---------------------------------------------------------------------------------------------
# 06-0050 Bản ghi vàng
# ---------------------------------------------------------------------------------------------
G_GOLDEN = [
    T("golden_record",
      "EN-06-01 Bản ghi vàng (FR-06-034…042). goldenId là id (UUIDv7); version bắt đầu 1 và tăng mỗi thay đổi, là số phiên bản trong lịch sử. Không xóa (BR-06-007): chỉ MERGED hoặc RETIRED. Cột display_name, name_norm, birth_year, admin_unit_code là bản sao có chỉ mục để tìm nhanh bằng pg_trgm.",
      ["domain_code varchar(32) NOT NULL", "model_version integer NOT NULL", "status varchar(8) NOT NULL DEFAULT 'ACTIVE'", "merged_into uuid",
       "confidence numeric(5,4)", "display_name varchar(255)", "name_norm varchar(255)", "birth_year smallint", "admin_unit_code varchar(16)",
       "link_count integer NOT NULL DEFAULT 0", "block_keys varchar(72)[] NOT NULL DEFAULT '{}'", "restricted boolean NOT NULL DEFAULT false", "lock_reason varchar(500)", "retire_reason varchar(16)", "retire_note varchar(2000)",
       "retired_at timestamptz", "retired_by varchar(64)", "national_synced_at timestamptz"],
      [("fk_golden_record_domain", f"FOREIGN KEY (tenant_id, domain_code) REFERENCES {S}.mdm_domain (tenant_id, domain_code)"),
       ("fk_golden_record_merged", f"FOREIGN KEY (tenant_id, merged_into) REFERENCES {S}.golden_record (tenant_id, id)"),
       chk("golden_record", "status", f"status IN {E('GoldenStatus')}"),
       chk("golden_record", "merged", "(status = 'MERGED') = (merged_into IS NOT NULL) AND merged_into IS DISTINCT FROM id"),
       chk("golden_record", "retired", "(status = 'RETIRED') = (retire_reason IS NOT NULL)"),
       chk("golden_record", "retire", f"retire_reason IS NULL OR retire_reason IN {E('RetireReason')}"),
       chk("golden_record", "locked", "status <> 'LOCKED' OR lock_reason IS NOT NULL"),
       chk("golden_record", "restricted", "NOT restricted OR status = 'LOCKED'"),
       chk("golden_record", "confidence", "confidence IS NULL OR confidence BETWEEN 0 AND 1"),
       chk("golden_record", "birth", "birth_year IS NULL OR birth_year BETWEEN 1850 AND 2100")],
      idx=[f"CREATE INDEX ix_golden_record_domain ON {S}.golden_record (tenant_id, domain_code, status);",
           f"CREATE INDEX ix_golden_record_name_trgm ON {S}.golden_record USING gin (domain_code, name_norm gin_trgm_ops);",
           f"CREATE INDEX ix_golden_record_blocks ON {S}.golden_record USING gin (block_keys);",
           f"CREATE INDEX ix_golden_record_area ON {S}.golden_record (tenant_id, domain_code, admin_unit_code, birth_year) WHERE status = 'ACTIVE';",
           f"CREATE INDEX ix_golden_record_merged ON {S}.golden_record (tenant_id, merged_into) WHERE merged_into IS NOT NULL;"],
      tid=True, trig=[("immutable", ["domain_code"])], version_start=1,
      ccomment={"model_version": "Phiên bản mô hình domain áp khi tạo hoặc cập nhật gần nhất.",
                "name_norm": "Họ tên hoặc tên tổ chức không dấu, chữ thường; chỉ mục GIN gin_trgm_ops (cần btree_gin cho domain_code).",
                "version": "Phiên bản bản ghi vàng, ETag; ghi ảnh chụp golden_history trước khi tăng (BR-06-005)."}),
    T("golden_attribute",
      "EN-06-02 Giá trị thuộc tính vàng kèm nguồn ở cấp thuộc tính (FR-06-034, 035, BR-06-009). SENSITIVE chỉ ở value_enc kèm value_hash, không ở value_json (CHECK, NFR-06-016). Thuộc tính đa trị dùng seq. Sửa tay tạm thời có hạn manual_valid_until (BR-06-014).",
      ["golden_id uuid NOT NULL", "attribute_name varchar(63) NOT NULL", "seq smallint NOT NULL DEFAULT 0", "data_class varchar(16) NOT NULL",
       "value_json jsonb", "value_enc bytea", "value_kid varchar(64)", "value_hash bytea", "source_code varchar(32) NOT NULL",
       "source_key varchar(120)", "source_updated_at timestamptz", "strategy varchar(24) NOT NULL", "confidence numeric(5,4)",
       "manual_valid_until timestamptz", "national_authority boolean NOT NULL DEFAULT false"],
      [("uq_golden_attribute", "UNIQUE (tenant_id, golden_id, attribute_name, seq)"),
       ("fk_golden_attribute_golden", f"FOREIGN KEY (tenant_id, golden_id) REFERENCES {S}.golden_record (tenant_id, id)"),
       chk("golden_attribute", "class", f"data_class IN {E('DataClass')}"),
       chk("golden_attribute", "strategy", f"strategy IN {E('SurvivorshipStrategy')}"),
       chk("golden_attribute", "name", f"attribute_name ~ '{ATTR_RE}'"),
       chk("golden_attribute", "sensitive", "(data_class = 'SENSITIVE' AND value_json IS NULL AND value_enc IS NOT NULL AND value_hash IS NOT NULL AND value_kid IS NOT NULL) "
                                           "OR (data_class <> 'SENSITIVE' AND value_enc IS NULL AND value_hash IS NULL)"),
       chk("golden_attribute", "hash", "value_hash IS NULL OR octet_length(value_hash) = 32"),
       chk("golden_attribute", "manual", "strategy <> 'MANUAL_OVERRIDE' OR manual_valid_until IS NOT NULL"),
       chk("golden_attribute", "authority", "NOT national_authority OR strategy = 'NATIONAL_AUTHORITY'")],
      idx=[f"CREATE INDEX ix_golden_attribute_hash ON {S}.golden_attribute (tenant_id, attribute_name, value_hash) WHERE value_hash IS NOT NULL;",
           f"CREATE INDEX ix_golden_attribute_source ON {S}.golden_attribute (tenant_id, source_code, source_key);"],
      ccomment={"value_hash": "HMAC-SHA256 giá trị đã chuẩn hóa; đối sánh bằng, không giải mã (BR-06-016).",
                "manual_valid_until": "Sửa tay có hạn ≤ 90 ngày, mặc định 30 (FR-06-036).",
                "national_authority": "Thuộc tính thẩm quyền quốc gia: không sửa tay (BR-06-025)."}),
    T("golden_identifier",
      "EN-06-02, EN-06-28 Chỉ mục số định danh của bản ghi vàng (FR-06-020, 046, BR-06-001, 006). Một giá trị định danh hiệu lực chỉ thuộc một bản ghi vàng trong domain (chỉ mục duy nhất một phần), nên hai bản ghi vàng cùng CCCD không tồn tại (ERR-06-112 là lỗi bất biến). Giá trị rõ không lưu; value_enc mã hóa envelope, value_hash HMAC.",
      ["golden_id uuid NOT NULL", "domain_code varchar(32) NOT NULL", "identifier_type varchar(16) NOT NULL", "value_hash bytea NOT NULL",
       "value_enc bytea NOT NULL", "value_kid varchar(64) NOT NULL", "active boolean NOT NULL DEFAULT true"],
      [("fk_golden_identifier_golden", f"FOREIGN KEY (tenant_id, golden_id) REFERENCES {S}.golden_record (tenant_id, id)"),
       chk("golden_identifier", "type", f"identifier_type IN {E('IdentifierType')}"),
       chk("golden_identifier", "hash", "octet_length(value_hash) = 32")],
      idx=[f"CREATE UNIQUE INDEX uq_golden_identifier_active ON {S}.golden_identifier (tenant_id, domain_code, identifier_type, value_hash) WHERE active;",
           f"CREATE INDEX ix_golden_identifier_golden ON {S}.golden_identifier (tenant_id, golden_id);"],
      trig=[("immutable", ["golden_id", "domain_code", "identifier_type", "value_hash"])]),
    T("source_xref",
      "EN-06-03 Liên kết chéo nguồn (sourceCode, sourceKey) với bản ghi vàng (FR-06-044, 045, BR-06-018). Một bản ghi nguồn chỉ có một liên kết ACTIVE tại một thời điểm (chỉ mục duy nhất một phần). Gỡ ghi lý do; liên kết do người xác nhận không bị tự tách (BR-06-023).",
      ["domain_code varchar(32) NOT NULL", "golden_id uuid NOT NULL", "source_code varchar(32) NOT NULL", "source_key varchar(120) NOT NULL",
       "status varchar(8) NOT NULL DEFAULT 'ACTIVE'", "match_method varchar(24) NOT NULL", "score numeric(5,4)", "candidate_id uuid",
       "confirmed_by_steward boolean NOT NULL DEFAULT false", "linked_by varchar(64) NOT NULL", "linked_at timestamptz NOT NULL DEFAULT now()",
       "detached_at timestamptz", "detached_by varchar(64)", "detach_reason varchar(16)", "detach_note varchar(2000)", "moved_to_golden_id uuid"],
      [("fk_source_xref_golden", f"FOREIGN KEY (tenant_id, golden_id) REFERENCES {S}.golden_record (tenant_id, id)"),
       ("fk_source_xref_source", f"FOREIGN KEY (tenant_id, source_code) REFERENCES {S}.mdm_source (tenant_id, source_code)"),
       chk("source_xref", "status", f"status IN {E('XrefStatus')}"),
       chk("source_xref", "method", f"match_method IN {E('MatchMethod')}"),
       chk("source_xref", "detach", f"detach_reason IS NULL OR detach_reason IN {E('XrefDetachReason')}"),
       chk("source_xref", "detached", "(status = 'ACTIVE') = (detached_at IS NULL AND detach_reason IS NULL AND moved_to_golden_id IS NULL) OR (status = 'MOVED' AND detached_at IS NOT NULL)"),
       chk("source_xref", "moved", "(status = 'MOVED') = (moved_to_golden_id IS NOT NULL)"),
       chk("source_xref", "manual", "detach_reason IS DISTINCT FROM 'MANUAL' OR COALESCE(char_length(detach_note) >= 20, false)")],
      idx=[f"CREATE UNIQUE INDEX uq_source_xref_active ON {S}.source_xref (tenant_id, domain_code, source_code, source_key) WHERE status = 'ACTIVE';",
           f"CREATE INDEX ix_source_xref_golden ON {S}.source_xref (tenant_id, golden_id, status);"],
      tid=True, trig=[("immutable", ["domain_code", "source_code", "source_key"])]),
    T("golden_operation",
      "EN-06-13 Thao tác trên bản ghi vàng: hợp nhất, tách, sửa tay, hoàn tác, ngừng, khôi phục, áp lại sống sót (FR-06-036…042). Mọi thay đổi bản ghi vàng đi qua một thao tác (BR-06-005). Lý do ≥ 20 ký tự (BR-06-008); rủi ro cao chờ DA duyệt khác người yêu cầu (BR-06-019). Hoàn tác là thao tác mới trỏ undo_of, không xóa lịch sử (BR-06-024).",
      ["domain_code varchar(32) NOT NULL", "change_type varchar(24) NOT NULL", "status varchar(20) NOT NULL DEFAULT 'APPLIED'",
       "risk_level varchar(4) NOT NULL DEFAULT 'LOW'", "golden_ids uuid[] NOT NULL", "survivor_id uuid", "result_golden_ids uuid[] NOT NULL DEFAULT '{}'",
       "reason varchar(2000) NOT NULL", "evidence_ref varchar(255)", "payload jsonb NOT NULL DEFAULT '{}'", "requested_by varchar(64) NOT NULL",
       "requested_at timestamptz NOT NULL DEFAULT now()", "decision varchar(8)", "approved_by varchar(64)", "approved_at timestamptz",
       "decision_comment varchar(2000)", "applied_at timestamptz", "undo_of uuid", "batch_job_id uuid", "source_item_id uuid"],
      [("fk_golden_operation_domain", f"FOREIGN KEY (tenant_id, domain_code) REFERENCES {S}.mdm_domain (tenant_id, domain_code)"),
       ("fk_golden_operation_undo", f"FOREIGN KEY (tenant_id, undo_of) REFERENCES {S}.golden_operation (tenant_id, id)"),
       chk("golden_operation", "type", f"change_type IN {E('GoldenChangeType')}"),
       chk("golden_operation", "status", f"status IN {E('OperationStatus')}"),
       chk("golden_operation", "risk", f"risk_level IN {E('RiskLevel')}"),
       chk("golden_operation", "decision", f"decision IS NULL OR decision IN {E('ApprovalDecision')}"),
       chk("golden_operation", "reason20", reason20()),
       chk("golden_operation", "four_eyes", four_eyes("approved_by", "requested_by")),
       chk("golden_operation", "pending", "status <> 'PENDING_APPROVAL' OR risk_level = 'HIGH'"),
       chk("golden_operation", "applied", "status NOT IN ('APPLIED', 'UNDONE') OR applied_at IS NOT NULL"),
       chk("golden_operation", "undo", "(change_type = 'UNDO') = (undo_of IS NOT NULL)"),
       chk("golden_operation", "merge", "change_type <> 'MERGE' OR (cardinality(golden_ids) BETWEEN 2 AND 10 AND survivor_id IS NOT NULL)")],
      idx=[f"CREATE INDEX ix_golden_operation_golden ON {S}.golden_operation USING gin (golden_ids);",
           f"CREATE INDEX ix_golden_operation_pending ON {S}.golden_operation (tenant_id, domain_code, requested_at) WHERE status = 'PENDING_APPROVAL';",
           f"CREATE UNIQUE INDEX uq_golden_operation_undo ON {S}.golden_operation (tenant_id, undo_of) WHERE undo_of IS NOT NULL AND status <> 'REJECTED';"],
      tid=True, trig=[("immutable", ["domain_code", "change_type", "golden_ids", "reason", "requested_by", "requested_at", "undo_of"])],
      ccomment={"batch_job_id": "batchOperationId của job lô (NFR, tiêu chí 9)."}),
    T("golden_history",
      "EN-06-06 Ảnh chụp đầy đủ bản ghi vàng (thuộc tính, liên kết) trước mỗi thay đổi, cùng giao dịch (BR-06-005). Phục vụ xem phiên bản, so sánh, hoàn tác. snapshot_enc mã hóa envelope vì chứa DLCN. Chỉ thêm, không sửa (trigger). Phân vùng tháng theo changed_at; chuyển lưu trữ lạnh sau 5 năm, không xóa (BR-06-007, SRS cũ: vĩnh viễn).",
      ["changed_at timestamptz NOT NULL DEFAULT now()", "golden_id uuid NOT NULL", "version_no integer NOT NULL", "change_type varchar(24) NOT NULL",
       "operation_id uuid", "snapshot_enc bytea NOT NULL", "snapshot_kid varchar(64) NOT NULL", "snapshot_sha256 bytea NOT NULL",
       "changed_attributes varchar(63)[] NOT NULL DEFAULT '{}'", "changed_by varchar(64) NOT NULL"],
      [("fk_golden_history_golden", f"FOREIGN KEY (tenant_id, golden_id) REFERENCES {S}.golden_record (tenant_id, id)"),
       chk("golden_history", "type", f"change_type IN {E('GoldenChangeType')}"),
       chk("golden_history", "sha", "octet_length(snapshot_sha256) = 32"),
       chk("golden_history", "version", "version_no >= 1"),
       chk("golden_history", "snapshot", "octet_length(snapshot_enc) BETWEEN 29 AND 4194304")],
      idx=[f"CREATE INDEX ix_golden_history_golden ON {S}.golden_history (tenant_id, golden_id, version_no DESC);",
           f"CREATE INDEX ix_golden_history_operation ON {S}.golden_history (tenant_id, operation_id) WHERE operation_id IS NOT NULL;"],
      part=("changed_at", "month", 3), pk=("id", "changed_at"), std=False, trig=[("append_only", [])]),
    T("attribute_lineage",
      "EN-06-14 Lịch sử giá trị và nguồn của từng thuộc tính vàng (FR-06-043, BR-06-009): giá trị nào, từ nguồn nào, chiến lược nào chọn, lúc nào. Giá trị mã hóa envelope; value_hash để so khớp. Chỉ thêm. Phân vùng tháng theo recorded_at; chuyển lưu trữ lạnh sau 5 năm, không xóa.",
      ["recorded_at timestamptz NOT NULL DEFAULT now()", "golden_id uuid NOT NULL", "golden_version integer NOT NULL", "attribute_name varchar(63) NOT NULL",
       "seq smallint NOT NULL DEFAULT 0", "operation_id uuid", "source_code varchar(32) NOT NULL", "source_key varchar(120)", "source_version bigint",
       "source_updated_at timestamptz", "strategy varchar(24) NOT NULL", "selected boolean NOT NULL DEFAULT true", "data_class varchar(16) NOT NULL",
       "value_enc bytea", "value_kid varchar(64)", "value_hash bytea"],
      [("fk_attribute_lineage_golden", f"FOREIGN KEY (tenant_id, golden_id) REFERENCES {S}.golden_record (tenant_id, id)"),
       chk("attribute_lineage", "strategy", f"strategy IN {E('SurvivorshipStrategy')}"),
       chk("attribute_lineage", "class", f"data_class IN {E('DataClass')}"),
       chk("attribute_lineage", "hash", "value_hash IS NULL OR octet_length(value_hash) = 32"),
       chk("attribute_lineage", "enc", "value_enc IS NULL OR value_kid IS NOT NULL")],
      idx=[f"CREATE INDEX ix_attribute_lineage_golden ON {S}.attribute_lineage (tenant_id, golden_id, attribute_name, recorded_at DESC);"],
      part=("recorded_at", "month", 3), pk=("id", "recorded_at"), std=False, trig=[("append_only", [])]),
    T("survivorship_rule_set",
      "EN-06-17 Phiên bản bộ quy tắc sống sót của domain (FR-06-033, 042). Vòng đời 4.6 (không TESTING); một phiên bản ACTIVE mỗi domain; duyệt bốn mắt có căn cứ văn bản (BR-06-004).",
      ["domain_code varchar(32) NOT NULL", "version_no integer NOT NULL", "status varchar(20) NOT NULL DEFAULT 'DRAFT'", "comment varchar(2000)",
       "approval_ref varchar(255)", "submitted_by varchar(64)", "submitted_at timestamptz", "decision varchar(8)", "decided_by varchar(64)",
       "decided_at timestamptz", "decision_comment varchar(2000)", "activated_at timestamptz"],
      [("uq_survivorship_rule_set_version", "UNIQUE (tenant_id, domain_code, version_no)"),
       ("fk_survivorship_rule_set_domain", f"FOREIGN KEY (tenant_id, domain_code) REFERENCES {S}.mdm_domain (tenant_id, domain_code)"),
       chk("survivorship_rule_set", "status", f"status IN {E('VersionStatus', skip=('TESTING',))}"),
       chk("survivorship_rule_set", "decision", f"decision IS NULL OR decision IN {E('ApprovalDecision')}"),
       chk("survivorship_rule_set", "four_eyes", four_eyes("decided_by", "submitted_by")),
       chk("survivorship_rule_set", "active", "status <> 'ACTIVE' OR (decision = 'APPROVE' AND activated_at IS NOT NULL AND approval_ref IS NOT NULL)")],
      idx=[f"CREATE UNIQUE INDEX uq_survivorship_rule_set_active ON {S}.survivorship_rule_set (tenant_id, domain_code) WHERE status = 'ACTIVE';"],
      tid=True, trig=[("immutable", ["domain_code", "version_no"])]),
    T("survivorship_rule",
      "EN-06-17 Chiến lược sống sót theo thuộc tính trong một phiên bản (FR-06-033). strategies là chuỗi SurvivorshipStrategy theo thứ tự áp; thuộc tính thẩm quyền quốc gia bắt đầu bằng NATIONAL_AUTHORITY (BR-06-003, 025).",
      ["domain_code varchar(32) NOT NULL", "version_no integer NOT NULL", "attribute_name varchar(63) NOT NULL", "strategies varchar(24)[] NOT NULL",
       "critical_conflict_to_queue boolean NOT NULL DEFAULT false", "national_authority boolean NOT NULL DEFAULT false"],
      [("uq_survivorship_rule_attr", "UNIQUE (tenant_id, domain_code, version_no, attribute_name)"),
       ("fk_survivorship_rule_set", f"FOREIGN KEY (tenant_id, domain_code, version_no) REFERENCES {S}.survivorship_rule_set (tenant_id, domain_code, version_no)"),
       chk("survivorship_rule", "strategies", f"cardinality(strategies) BETWEEN 1 AND 7 AND {arr_in('strategies', 'SurvivorshipStrategy')}"),
       chk("survivorship_rule", "authority", "NOT national_authority OR strategies[1] = 'NATIONAL_AUTHORITY'")],
      trig=[("child_frozen_surv", [])]),
]

# ---------------------------------------------------------------------------------------------
# 06-0060 Cung cấp và đồng bộ
# ---------------------------------------------------------------------------------------------
G_SERVE = [
    T("update_subscription",
      "EN-06-18 Đăng ký nhận cập nhật bản ghi vàng của HTTT (FR-06-051). Cần mục đích khai thác đã được PH-09 chấp thuận (ERR-06-043). Kênh giao qua đăng ký PH-10 (ph10_subscription_code). Duyệt bốn mắt.",
      ["system_code varchar(63) NOT NULL", "domain_code varchar(32) NOT NULL", "scope varchar(16) NOT NULL", "event_types varchar(32)[] NOT NULL",
       "delivery varchar(4) NOT NULL", "purpose_code varchar(63) NOT NULL", "status varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL'",
       "ph10_subscription_code varchar(63)", "requested_by varchar(64) NOT NULL", "approved_by varchar(64)", "approved_at timestamptz",
       "status_reason varchar(2000)"],
      [("fk_update_subscription_domain", f"FOREIGN KEY (tenant_id, domain_code) REFERENCES {S}.mdm_domain (tenant_id, domain_code)"),
       chk("update_subscription", "scope", f"scope IN {E('SubscriptionScope')}"),
       chk("update_subscription", "status", f"status IN {E('SubscriptionStatus')}"),
       chk("update_subscription", "delivery", "delivery IN ('PUSH', 'PULL')"),
       chk("update_subscription", "events", "cardinality(event_types) >= 1"),
       chk("update_subscription", "four_eyes", four_eyes("approved_by", "requested_by")),
       chk("update_subscription", "active", "status NOT IN ('ACTIVE') OR approved_by IS NOT NULL")],
      idx=[f"CREATE UNIQUE INDEX uq_update_subscription_live ON {S}.update_subscription (tenant_id, system_code, domain_code, scope) WHERE status <> 'REVOKED';"],
      trig=[("immutable", ["system_code", "domain_code", "requested_by"])]),
    T("export_request",
      "EN-06-19 Yêu cầu xuất dữ liệu chủ có duyệt (FR-06-049, BR-06-027): cần chấp thuận của DO các nguồn liên quan và DA; tệp mã hóa, có thủy vân, hạn tải 24 giờ. Tệp ở Ceph RGW (file_ref), không trong PostgreSQL. Giới hạn dòng theo 06.export.max-rows (ERR-06-041).",
      ["domain_code varchar(32) NOT NULL", "filter jsonb NOT NULL DEFAULT '{}'", "fields varchar(63)[] NOT NULL", "format varchar(8) NOT NULL",
       "purpose_code varchar(63) NOT NULL", "legal_basis varchar(2000) NOT NULL", "recipient varchar(255) NOT NULL",
       "pseudonymize boolean NOT NULL DEFAULT false", "status varchar(20) NOT NULL DEFAULT 'PENDING_APPROVAL'", "row_count integer",
       "requested_by varchar(64) NOT NULL", "owner_approved_by varchar(64)", "owner_approved_at timestamptz", "approved_by varchar(64)",
       "approved_at timestamptz", "reject_reason varchar(2000)", "file_ref varchar(512)", "file_sha256 char(64)", "watermark_id varchar(64)",
       "ready_at timestamptz", "expires_at timestamptz", "downloaded_at timestamptz"],
      [("fk_export_request_domain", f"FOREIGN KEY (tenant_id, domain_code) REFERENCES {S}.mdm_domain (tenant_id, domain_code)"),
       chk("export_request", "format", f"format IN {E('ExportFormat')}"),
       chk("export_request", "status", f"status IN {E('ExportStatus')}"),
       chk("export_request", "four_eyes", four_eyes("approved_by", "requested_by")),
       chk("export_request", "owner", "owner_approved_by IS NULL OR owner_approved_by <> requested_by"),
       chk("export_request", "approved", "status NOT IN ('APPROVED', 'GENERATING', 'READY') OR (approved_by IS NOT NULL AND owner_approved_by IS NOT NULL)"),
       chk("export_request", "ready", "status <> 'READY' OR (file_ref IS NOT NULL AND file_sha256 IS NOT NULL AND watermark_id IS NOT NULL AND expires_at IS NOT NULL)"),
       chk("export_request", "rejected", "status <> 'REJECTED' OR reject_reason IS NOT NULL"),
       chk("export_request", "rows", "row_count IS NULL OR row_count BETWEEN 0 AND 1000000")],
      idx=[f"CREATE INDEX ix_export_request_status ON {S}.export_request (tenant_id, status, created_at DESC);"],
      tid=True, trig=[("immutable", ["domain_code", "filter", "fields", "format", "purpose_code", "requested_by"])],
      ccomment={"expires_at": "ready_at + 24 giờ (BR-06-027); sau đó EXPIRED, ERR-06-042."}),
    T("national_sync_state",
      "EN-06-29 FR-06-053, 054 Trạng thái đồng bộ quốc gia mỗi domain: RUNNING hoặc PAUSED. Lệch > 06.sync.pause-ratio tạm dừng tự động (BR-06-011, ERR-06-107); tiếp tục cần người có PERM-06-sync.",
      ["domain_code varchar(32) NOT NULL", "state varchar(8) NOT NULL DEFAULT 'RUNNING'", "paused_reason varchar(2000)", "paused_at timestamptz",
       "paused_by varchar(64)", "last_run_id uuid", "last_ratio numeric(6,5)"],
      [("uq_national_sync_state_domain", "UNIQUE (tenant_id, domain_code)"),
       ("fk_national_sync_state_domain", f"FOREIGN KEY (tenant_id, domain_code) REFERENCES {S}.mdm_domain (tenant_id, domain_code)"),
       chk("national_sync_state", "state", f"state IN {E('SyncState')}"),
       chk("national_sync_state", "paused", "(state = 'PAUSED') = (paused_at IS NOT NULL AND paused_reason IS NOT NULL)"),
       chk("national_sync_state", "ratio", "last_ratio IS NULL OR last_ratio BETWEEN 0 AND 1")],
      trig=[("immutable", ["domain_code"])]),
    T("national_sync_run",
      "EN-06-16 Nhật ký một lượt đồng bộ với CSDL tổng hợp quốc gia qua PH-14 (FR-06-053). Tỷ lệ lệch ratio so với ngưỡng BR-06-011. PH-06 không gọi trực tiếp CSDL quốc gia (BR-06-032); ph14_ref là mã giao dịch PH-14.",
      ["domain_code varchar(32) NOT NULL", "direction varchar(12) NOT NULL", "job_id uuid", "scope jsonb NOT NULL DEFAULT '{}'", "checked_count integer NOT NULL DEFAULT 0",
       "discrepancy_count integer NOT NULL DEFAULT 0", "applied_count integer NOT NULL DEFAULT 0", "ratio numeric(6,5)", "paused boolean NOT NULL DEFAULT false",
       "ph14_ref varchar(64)", "requested_by varchar(64) NOT NULL", "started_at timestamptz NOT NULL DEFAULT now()", "finished_at timestamptz",
       "error_code varchar(16)"],
      [("fk_national_sync_run_domain", f"FOREIGN KEY (tenant_id, domain_code) REFERENCES {S}.mdm_domain (tenant_id, domain_code)"),
       chk("national_sync_run", "direction", f"direction IN {E('SyncDirection')}"),
       chk("national_sync_run", "counts", "checked_count >= 0 AND discrepancy_count >= 0 AND applied_count >= 0 AND discrepancy_count <= checked_count"),
       chk("national_sync_run", "error", "error_code IS NULL OR error_code ~ '^ERR-06-10[6-8]$'"),
       chk("national_sync_run", "ratio", "ratio IS NULL OR ratio BETWEEN 0 AND 1")],
      idx=[f"CREATE INDEX ix_national_sync_run_domain ON {S}.national_sync_run (tenant_id, domain_code, started_at DESC);"], tid=True),
    T("national_discrepancy",
      "EN-06-30 FR-06-053, 054 Lệch giữa bản ghi vàng và CSDL quốc gia trên thuộc tính đồng bộ. Giá trị hai phía mã hóa envelope kèm HMAC. Một lệch OPEN mỗi (bản ghi vàng, thuộc tính). Thuộc tính thẩm quyền quốc gia không giữ giá trị địa phương khi lệch (BR-06-025).",
      ["run_id uuid NOT NULL", "domain_code varchar(32) NOT NULL", "golden_id uuid NOT NULL", "attribute_name varchar(63) NOT NULL",
       "severity varchar(8) NOT NULL", "status varchar(24) NOT NULL DEFAULT 'OPEN'", "local_enc bytea", "national_enc bytea", "value_kid varchar(64)",
       "local_hash bytea", "national_hash bytea", "resolution varchar(24)", "resolved_by varchar(64)", "resolved_at timestamptz", "resolve_reason varchar(2000)"],
      [("fk_national_discrepancy_run", f"FOREIGN KEY (tenant_id, run_id) REFERENCES {S}.national_sync_run (tenant_id, id)"),
       ("fk_national_discrepancy_golden", f"FOREIGN KEY (tenant_id, golden_id) REFERENCES {S}.golden_record (tenant_id, id)"),
       chk("national_discrepancy", "severity", f"severity IN {E('DiscrepancySeverity')}"),
       chk("national_discrepancy", "status", f"status IN {E('DiscrepancyStatus')}"),
       chk("national_discrepancy", "resolution", f"resolution IS NULL OR resolution IN {E('DiscrepancyResolution')}"),
       chk("national_discrepancy", "resolved", "(status = 'OPEN') = (resolution IS NULL AND resolved_by IS NULL)"),
       chk("national_discrepancy", "hash", "(local_hash IS NULL OR octet_length(local_hash) = 32) AND (national_hash IS NULL OR octet_length(national_hash) = 32)"),
       chk("national_discrepancy", "enc", "(local_enc IS NULL AND national_enc IS NULL) OR value_kid IS NOT NULL")],
      idx=[f"CREATE UNIQUE INDEX uq_national_discrepancy_open ON {S}.national_discrepancy (tenant_id, golden_id, attribute_name) WHERE status = 'OPEN';",
           f"CREATE INDEX ix_national_discrepancy_run ON {S}.national_discrepancy (tenant_id, run_id, severity);"],
      trig=[("immutable", ["run_id", "golden_id", "attribute_name"])]),
    T("source_correction",
      "EN-06-31 BR-06-014, EVT-06-15 Yêu cầu sửa tại nguồn: phát sinh khi sửa tay bản ghi vàng (FR-06-036), yêu cầu sửa của chủ thể (FR-06-058) hoặc lệch quốc gia (FR-06-054). Dữ liệu sai phải sửa ở nguồn; sửa tay ở bản ghi vàng chỉ tạm thời.",
      ["domain_code varchar(32) NOT NULL", "golden_id uuid NOT NULL", "attribute_name varchar(63) NOT NULL", "source_code varchar(32) NOT NULL",
       "source_key varchar(120)", "origin varchar(24) NOT NULL", "origin_ref uuid", "due_at timestamptz NOT NULL", "closed_at timestamptz",
       "closed_by varchar(64)", "close_note varchar(2000)"],
      [("fk_source_correction_golden", f"FOREIGN KEY (tenant_id, golden_id) REFERENCES {S}.golden_record (tenant_id, id)"),
       ("fk_source_correction_source", f"FOREIGN KEY (tenant_id, source_code) REFERENCES {S}.mdm_source (tenant_id, source_code)"),
       chk("source_correction", "origin", f"origin IN {E('GoldenChangeType', only=('MANUAL_EDIT', 'DSR_CORRECTION', 'NATIONAL_SYNC'))}"),
       chk("source_correction", "closed", "(closed_at IS NULL) = (closed_by IS NULL)")],
      idx=[f"CREATE INDEX ix_source_correction_open ON {S}.source_correction (tenant_id, source_code, due_at) WHERE closed_at IS NULL;"]),
]

# ---------------------------------------------------------------------------------------------
# 06-0070 Vận hành, nhật ký, yêu cầu chủ thể
# ---------------------------------------------------------------------------------------------
G_OPS = [
    T("subject_request",
      "EN-06-20 Yêu cầu của chủ thể dữ liệu: biết, sửa, hạn chế (FR-06-058, BR-06-030; Luật BVDLCN, NĐ 356/2025). Số định danh chủ thể mã hóa envelope kèm HMAC để tra bản ghi vàng. Trả lời trong 06.dsr.sla-days (Q06-01); sửa thực hiện tại nguồn (BR-06-014). Yêu cầu hạn chế chuyển bản ghi vàng sang LOCKED.",
      ["request_type varchar(16) NOT NULL", "status varchar(24) NOT NULL DEFAULT 'RECEIVED'", "identifier_type varchar(16) NOT NULL",
       "subject_enc bytea NOT NULL", "subject_kid varchar(64) NOT NULL", "subject_hash bytea NOT NULL", "verification_ref varchar(255) NOT NULL",
       "details_enc bytea", "channel varchar(32) NOT NULL", "received_at timestamptz NOT NULL", "due_at timestamptz NOT NULL", "golden_id uuid",
       "forwarded_source_code varchar(32)", "handled_by varchar(64)", "completed_at timestamptz", "result_ref varchar(512)", "reject_reason varchar(2000)",
       "lifted_at timestamptz", "lifted_by varchar(64)", "lift_reason varchar(2000)"],
      [chk("subject_request", "type", f"request_type IN {E('DsrType')}"),
       chk("subject_request", "status", f"status IN {E('DsrStatus')}"),
       chk("subject_request", "idtype", f"identifier_type IN {E('IdentifierType')}"),
       chk("subject_request", "hash", "octet_length(subject_hash) = 32"),
       chk("subject_request", "due", "due_at >= received_at"),
       chk("subject_request", "completed", "status NOT IN ('COMPLETED', 'REJECTED') OR completed_at IS NOT NULL"),
       chk("subject_request", "rejected", "status <> 'REJECTED' OR reject_reason IS NOT NULL"),
       chk("subject_request", "lifted", "(lifted_at IS NULL) = (lifted_by IS NULL) AND (lifted_at IS NULL) = (lift_reason IS NULL) AND (lifted_at IS NULL OR (request_type = 'RESTRICTION' AND status = 'COMPLETED' AND char_length(lift_reason) >= 20))"),
       chk("subject_request", "forward", "status <> 'FORWARDED_TO_SOURCE' OR forwarded_source_code IS NOT NULL")],
      idx=[f"CREATE INDEX ix_subject_request_status ON {S}.subject_request (tenant_id, status, due_at);",
           f"CREATE INDEX ix_subject_request_subject ON {S}.subject_request (tenant_id, subject_hash);"],
      trig=[("immutable", ["request_type", "subject_hash", "received_at"])]),
    T("access_log",
      "EN-06-21 Nhật ký truy cập dữ liệu chủ: ai, tra bản ghi nào, mục đích gì, trả thuộc tính nào (FR-06-057, BR-06-010, NFR-06-015). Không ghi được thì không trả dữ liệu (ERR-06-039). Chỉ thêm, trigger chặn sửa, xóa (RB-06-04); không chứa giá trị thuộc tính. Phân vùng tháng; 12 tháng trực tuyến, 5 năm WORM (BR-06-031).",
      ["accessed_at timestamptz NOT NULL DEFAULT now()", "actor varchar(64) NOT NULL", "system_code varchar(63)", "domain_code varchar(32) NOT NULL",
       "golden_id uuid", "api_code varchar(10) NOT NULL", "purpose_code varchar(63)", "attributes varchar(63)[] NOT NULL DEFAULT '{}'",
       "unmasked varchar(63)[] NOT NULL DEFAULT '{}'", "unmask_reason varchar(500)", "result_count integer NOT NULL DEFAULT 1", "criteria_hash bytea",
       "bulk_flag boolean NOT NULL DEFAULT false", "trace_id char(32) NOT NULL", "gateway_request_id varchar(64)"],
      [chk("access_log", "api", "api_code ~ '^API-06-[0-9]{3}$'"),
       chk("access_log", "trace", "trace_id ~ '^[0-9a-f]{32}$'"),
       chk("access_log", "criteria", "criteria_hash IS NULL OR octet_length(criteria_hash) = 32"),
       chk("access_log", "unmask", "cardinality(unmasked) = 0 OR COALESCE(char_length(unmask_reason) >= 20, false)"),
       chk("access_log", "count", "result_count >= 0")],
      idx=[f"CREATE INDEX ix_access_log_golden ON {S}.access_log (tenant_id, golden_id, accessed_at DESC) WHERE golden_id IS NOT NULL;",
           f"CREATE INDEX ix_access_log_actor ON {S}.access_log (tenant_id, actor, accessed_at DESC);",
           f"CREATE INDEX ix_access_log_system ON {S}.access_log (tenant_id, system_code, purpose_code, accessed_at DESC) WHERE system_code IS NOT NULL;"],
      part=("accessed_at", "month", 3), pk=("id", "accessed_at"), std=False, trig=[("append_only", [])],
      ccomment={"gateway_request_id": "Mã yêu cầu của APISIX để đối chiếu số lượt (NFR-06-015).",
                "criteria_hash": "HMAC tiêu chí tìm kiếm; không lưu tiêu chí rõ."}),
    T("processing_log",
      "EN-06-32 FR-06-057 Nhật ký xử lý (job, ứng viên, đồng bộ, dọn lưu giữ) cho vận hành: mức, mã lỗi ERR-06-1nn, thông điệp ngắn, chi tiết đã che DLCN. Chỉ thêm; phân vùng tháng theo logged_at; giữ 90 ngày.",
      ["logged_at timestamptz NOT NULL DEFAULT now()", "level varchar(5) NOT NULL", "component varchar(32) NOT NULL", "job_id uuid", "candidate_id uuid",
       "domain_code varchar(32)", "code varchar(16)", "message varchar(1000) NOT NULL", "details jsonb", "trace_id char(32)"],
      [chk("processing_log", "level", "level IN ('INFO', 'WARN', 'ERROR')"),
       chk("processing_log", "code", "code IS NULL OR code ~ '^ERR-06-[01][0-9]{2}$'"),
       chk("processing_log", "trace", "trace_id IS NULL OR trace_id ~ '^[0-9a-f]{32}$'")],
      idx=[f"CREATE INDEX ix_processing_log_job ON {S}.processing_log (tenant_id, job_id, logged_at) WHERE job_id IS NOT NULL;",
           f"CREATE INDEX ix_processing_log_level ON {S}.processing_log (tenant_id, level, logged_at DESC);"],
      part=("logged_at", "month", 3), pk=("id", "logged_at"), std=False, trig=[("append_only", [])]),
    T("retention_policy",
      "EN-06-33 FR-06-059 Chính sách lưu giữ theo loại đối tượng (BR-06-031). Nhật ký truy cập tối thiểu 365 ngày trực tuyến (ERR-06-049); legal_hold chặn dọn (ERR-06-114). retention_days = 0 không cho phép.",
      ["object_type varchar(24) NOT NULL", "retention_days integer NOT NULL", "action varchar(16) NOT NULL", "legal_hold boolean NOT NULL DEFAULT false",
       "hold_reason varchar(2000)", "last_purge_at timestamptz"],
      [("uq_retention_policy_type", "UNIQUE (tenant_id, object_type)"),
       chk("retention_policy", "type", "object_type IN ('candidate_record', 'match_result', 'match_staging', 'golden_history', 'attribute_lineage', 'access_log', 'processing_log', 'export_request', 'subject_request', 'steward_item')"),
       chk("retention_policy", "action", f"action IN {E('RetentionAction')}"),
       chk("retention_policy", "days", "retention_days >= 7 AND (object_type <> 'access_log' OR retention_days >= 365)"),
       chk("retention_policy", "hold", "NOT legal_hold OR hold_reason IS NOT NULL")],
      trig=[("immutable", ["object_type"])]),
    T("tenant_setting",
      "EN-06-34 FR-06-060 Tham số phân hệ theo tenant (FRS 8.2, khóa 06.*). Giá trị jsonb; miền kiểm ở dịch vụ (ERR-06-047), CHECK chỉ giữ danh sách khóa hợp lệ. Khóa thiếu thì dùng mặc định của FRS.",
      ["setting_key varchar(48) NOT NULL", "value jsonb NOT NULL"],
      [("uq_tenant_setting_key", "UNIQUE (tenant_id, setting_key)"),
       chk("tenant_setting", "key", "setting_key IN ('06.queue.sla-days', '06.queue.max-open', '06.queue.escalate-after-days', '06.queue.hold-minutes', '06.match.auto-disable-on-fail', '06.batch.safety-ratio', '06.undo.window-days', '06.export.max-rows', '06.access.bulk-threshold', '06.ingest.rate-per-source', '06.sync.pause-ratio', '06.sync.up-attributes', '06.dsr.sla-days', '06.mask.reveal-seconds', '06.ingest.max-file-mb', '06.ingest.max-rows', '06.batch.max-hours', '06.match.timeout-ms', '06.sync.reconcile-batch-size', '06.xref.batch-max', '06.queue.reopen-hours', '06.queue.reason-templates')")],
      trig=[("immutable", ["setting_key"])]),
]

OUTBOX_TOPICS = ["mdm.golden.created.v1", "mdm.golden.updated.v1", "mdm.golden.merged.v1", "mdm.golden.split.v1", "mdm.golden.retired.v1",
                 "mdm.golden.restored.v1", "mdm.candidate.ingested.v1", "mdm.steward.item-created.v1", "mdm.job.finished.v1",
                 "mdm.model.activated.v1", "mdm.ruleset.activated.v1", "mdm.national-sync.discrepancy-detected.v1",
                 "mdm.national-sync.paused.v1", "mdm.xref.changed.v1", "mdm.source-correction.requested.v1", "audit.recorded.v1"]

G_MSG = [
    T("outbox_event",
      "Outbox (DD-11, SAD 7.3) cho EVT-06-01…15 và bản ghi kiểm toán gửi PH-13. Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL, định tuyến theo topic. Sự kiện không chứa giá trị thuộc tính (BR-06-012): CHECK chặn khóa value, attributes, identifier. Dọn sau 3 ngày.",
      ["event_id uuid NOT NULL", "tenant_id varchar(16) NOT NULL", "event_type varchar(128) NOT NULL", "topic varchar(249) NOT NULL", "aggregate_type varchar(64) NOT NULL",
       "aggregate_id varchar(255) NOT NULL", "partition_key varchar(255) NOT NULL", "payload jsonb NOT NULL", "trace_id char(32) NOT NULL",
       "occurred_at timestamptz NOT NULL DEFAULT now()"],
      [("pk_outbox_event", "PRIMARY KEY (event_id)"),
       chk("outbox_event", "tenant", f"tenant_id ~ '{TENANT_RE}'"),
       chk("outbox_event", "prefix", "split_part(topic, '.', 1) = lower(tenant_id)"),
       chk("outbox_event", "topic", "substr(topic, length(split_part(topic, '.', 1)) + 2) IN (" + ", ".join("'%s'" % t for t in OUTBOX_TOPICS) + ")"),
       chk("outbox_event", "trace", "trace_id ~ '^[0-9a-f]{32}$'"),
       chk("outbox_event", "no_value", "NOT (payload ?| ARRAY['value', 'values', 'attributes', 'identifier', 'identifierValue', 'name', 'dateOfBirth'])")],
      idx=[f"CREATE INDEX ix_outbox_event_occurred ON {S}.outbox_event (occurred_at);"], std=False, nopk=True),
    T("inbox_event",
      "Inbox chống xử lý trùng cho sự kiện PH-06 tiêu thụ (at-least-once): trạng thái HTTT PH-01 (FR-06-008), thay đổi quốc gia từ PH-14 (FR-06-053), sự kiện nguồn PH-10 (FR-06-012). Khóa (consumer, event_id). Dọn sau 7 ngày.",
      ["tenant_id varchar(16) NOT NULL", "consumer varchar(64) NOT NULL", "event_id varchar(255) NOT NULL", "source_topic varchar(249) NOT NULL",
       "event_type varchar(255) NOT NULL", "received_at timestamptz NOT NULL DEFAULT now()", "processed_at timestamptz", "outcome varchar(2000)"],
      [("pk_inbox_event", "PRIMARY KEY (tenant_id, consumer, event_id)"),
       chk("inbox_event", "tenant", f"tenant_id ~ '{TENANT_RE}'"),
       chk("inbox_event", "consumer", "consumer ~ '^[A-Z][A-Za-z0-9]+$'"),
       chk("inbox_event", "prefix", "split_part(source_topic, '.', 1) = lower(tenant_id)")],
      idx=[f"CREATE INDEX ix_inbox_event_received ON {S}.inbox_event (received_at);"], std=False, nopk=True),
    T("shedlock",
      "Khóa tác vụ nền (CandidateNormalizer, MatchJobScheduler, SteerQueueEscalator, SyncScheduler, RetentionPurgeJob, PartitionMaintenanceJob, OutboxCleaner, ExportExpiryJob); bảng kỹ thuật của ShedLock, không có tenant_id.",
      ["name varchar(64) NOT NULL", "lock_until timestamptz NOT NULL", "locked_at timestamptz NOT NULL", "locked_by varchar(255) NOT NULL"],
      [("pk_shedlock", "PRIMARY KEY (name)")], std=False, nopk=True, rls=False),
]

FILE_GROUPS = [
    ("06-0010-model.sql", G_MODEL), ("06-0020-ingest.sql", G_INGEST), ("06-0030-match.sql", G_MATCH),
    ("06-0040-steward.sql", G_STEWARD), ("06-0050-golden.sql", G_GOLDEN), ("06-0060-serve.sql", G_SERVE),
    ("06-0070-ops.sql", G_OPS), ("06-0080-messaging.sql", G_MSG),
]

# ---------------------------------------------------------------------------------------------
HEAD = r"""-- =============================================================================
-- D03-03-PH06 · DDL schema ph06_mdm — PH-06 Dữ liệu chủ (Master Data Management)
-- Phiên bản 0.1 · 2026-11-26 · Dự thảo
-- TỆP SINH bởi tools/sinh_ddl.py từ danh mục bảng và Phụ lục A của D02-03-PH06; sửa ở đó rồi sinh lại.
--
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d datahub -f ph06_mdm.sql
-- Môi trường thật: Liquibase, changelog sinh bằng ../tools/gen_liquibase.py từ dấu
-- -- @file / -- @changeset / -- @rollback trong tệp này (không sửa tay changelog).
--
-- Nguồn chuẩn enum, tên trường: D02-03-PH06 phụ lục A. Số định danh, giá trị SENSITIVE: chỉ *_enc (envelope,
-- OpenBao transit, ADR-032) kèm *_hash (HMAC-SHA256) để đối sánh xác định, không bản rõ (BR-06-016, NFR-06-016).
-- Bản ghi vàng không bị xóa (BR-06-007): vai trò ph06_app không có DELETE trên bảng nghiệp vụ.
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 06-0000-bootstrap.sql
-- @changeset ph06-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph06_owner') THEN
    CREATE ROLE ph06_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph06_app') THEN
    CREATE ROLE ph06_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph06_readonly') THEN
    CREATE ROLE ph06_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph06_splink') THEN
    CREATE ROLE ph06_splink NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph06-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE SCHEMA IF NOT EXISTS ph06_mdm AUTHORIZATION ph06_owner;
COMMENT ON SCHEMA ph06_mdm IS 'PH-06 Dữ liệu chủ (dh-data, package vn.datahub.data.mdm): domain, nguồn, ứng viên, đối sánh, hàng đợi, bản ghi vàng, liên kết chéo, lịch sử, nguồn gốc, đồng bộ quốc gia, yêu cầu chủ thể, nhật ký truy cập. Số định danh và giá trị SENSITIVE chỉ ở dạng mã hóa envelope và HMAC.';
GRANT USAGE ON SCHEMA ph06_mdm TO ph06_app, ph06_readonly, ph06_splink;
-- @rollback DROP SCHEMA IF EXISTS ph06_mdm CASCADE;

SET ROLE ph06_owner;

-- @changeset ph06-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 06-0001-functions.sql
-- @changeset ph06-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph06_mdm.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph06_mdm.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag; số phiên bản bản ghi vàng).';
-- @rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_touch();

-- @changeset ph06-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph06_mdm.tg_immutable() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
BEGIN
  FOREACH c IN ARRAY TG_ARGV LOOP
    IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
      RAISE EXCEPTION 'Cột %.% bất biến', TG_TABLE_NAME, c USING ERRCODE = '55000';
    END IF;
  END LOOP;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph06_mdm.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, khóa tham chiếu, nội dung đã chốt.';
-- @rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_immutable();

-- @changeset ph06-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph06_mdm.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng (nhật ký, lịch sử)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph06_mdm.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (golden_history, attribute_lineage, access_log, processing_log). Dọn bằng DETACH, DROP phân vùng dưới ph06_owner.';
-- @rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_append_only();

-- @changeset ph06-0013-fn-frozen splitStatements:false
-- Phiên bản ACTIVE bất biến (BR-06-017): chặn sửa cột nội dung (đối số) khi dòng cũ đang ACTIVE hoặc SUPERSEDED.
CREATE OR REPLACE FUNCTION ph06_mdm.tg_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
BEGIN
  IF OLD.status IN ('ACTIVE', 'SUPERSEDED') THEN
    FOREACH c IN ARRAY TG_ARGV LOOP
      IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
        RAISE EXCEPTION 'Phiên bản % không sửa được cột % (BR-06-017)', OLD.status, c USING ERRCODE = '55000';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph06_mdm.tg_frozen() IS 'Phiên bản mô hình, bộ quy tắc đã ACTIVE hoặc SUPERSEDED không đổi nội dung (BR-06-017); thay đổi cần phiên bản mới.';
-- @rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_frozen();

-- @changeset ph06-0014-fn-child-frozen splitStatements:false
-- Bảng con của phiên bản (thuộc tính, khóa định danh, quy tắc con): chỉ ghi khi phiên bản cha là DRAFT, TESTING hoặc REJECTED.
-- Tham số: tên bảng cha, tên cột trạng thái cha mặc định 'status'.
CREATE OR REPLACE FUNCTION ph06_mdm.tg_child_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  parent text := TG_ARGV[0];
  st text;
  tn text;
  dc text;
  vn integer;
BEGIN
  IF TG_OP = 'DELETE' THEN
    tn := OLD.tenant_id; dc := OLD.domain_code; vn := OLD.version_no;
  ELSE
    tn := NEW.tenant_id; dc := NEW.domain_code; vn := NEW.version_no;
  END IF;
  EXECUTE format('SELECT status FROM ph06_mdm.%I WHERE tenant_id = $1 AND domain_code = $2 AND version_no = $3', parent)
    INTO st USING tn, dc, vn;
  IF st IN ('ACTIVE', 'SUPERSEDED', 'PENDING_APPROVAL') THEN
    RAISE EXCEPTION 'Phiên bản % của %: không sửa nội dung con khi % (BR-06-017)', vn, parent, st USING ERRCODE = '55000';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph06_mdm.tg_child_frozen() IS 'Chặn thêm, sửa, xóa dòng con khi phiên bản cha đã gửi duyệt, ACTIVE hoặc SUPERSEDED (BR-06-017).';
-- @rollback DROP FUNCTION IF EXISTS ph06_mdm.tg_child_frozen();

-- @changeset ph06-0015-fn-rls splitStatements:false
-- Một mẫu cho mọi bảng nghiệp vụ: chỉ thấy, ghi dòng của tenant phiên; tenant_id đúng dạng Tnn (không có dòng COMMON, mỗi tenant tự cài gói domain nền).
CREATE OR REPLACE PROCEDURE ph06_mdm.p_enable_rls(p_table regclass)
  LANGUAGE plpgsql AS $p$
DECLARE
  t text := p_table::text;
  n text := split_part(p_table::text, '.', 2);
  w text := $w$(tenant_id = current_setting('app.tenant_id', false) AND tenant_id ~ '^T[0-9]{2}$')$w$;
BEGIN
  EXECUTE format('ALTER TABLE %s ENABLE ROW LEVEL SECURITY', t);
  EXECUTE format('ALTER TABLE %s FORCE ROW LEVEL SECURITY', t);
  EXECUTE format('CREATE POLICY rls_%s_select ON %s FOR SELECT USING %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_insert ON %s FOR INSERT WITH CHECK %s', n, t, w);
  EXECUTE format('CREATE POLICY rls_%s_update ON %s FOR UPDATE USING %s WITH CHECK %s', n, t, w, w);
  EXECUTE format('CREATE POLICY rls_%s_delete ON %s FOR DELETE USING %s', n, t, w);
END
$p$;
COMMENT ON PROCEDURE ph06_mdm.p_enable_rls(regclass) IS 'Bật FORCE RLS và 4 chính sách theo tenant (D03-10 §4, ADR-003).';
-- @rollback DROP PROCEDURE IF EXISTS ph06_mdm.p_enable_rls(regclass);

-- @changeset ph06-0016-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph06_mdm.p_ensure_partitions(p_table regclass, p_from date, p_count integer)
  LANGUAGE plpgsql AS $p$
DECLARE
  d timestamptz := date_trunc('month', p_from::timestamptz);
  i integer;
  part text;
BEGIN
  FOR i IN 0 .. p_count - 1 LOOP
    part := format('%s_%s', p_table::text, to_char(d + interval '1 month' * i, 'YYYYMM'));
    IF to_regclass(part) IS NULL THEN
      EXECUTE format('CREATE TABLE %s PARTITION OF %s FOR VALUES FROM (%L) TO (%L)',
                     part, p_table, d + interval '1 month' * i, d + interval '1 month' * (i + 1));
    END IF;
  END LOOP;
END
$p$;
COMMENT ON PROCEDURE ph06_mdm.p_ensure_partitions(regclass, date, integer) IS 'Tạo trước phân vùng tháng cho candidate_record, match_result, golden_history, attribute_lineage, access_log, processing_log. PartitionMaintenanceJob gọi hằng ngày; dọn bằng DETACH, DROP dưới ph06_owner.';
-- @rollback DROP PROCEDURE IF EXISTS ph06_mdm.p_ensure_partitions(regclass, date, integer);

-- @changeset ph06-0017-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant (BP-08): tham số mặc định FRS 8.2, chính sách lưu giữ, lịch job. Domain nền cài qua FR-06-007 (gói do ứng dụng quản).
CREATE OR REPLACE PROCEDURE ph06_mdm.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
  INSERT INTO ph06_mdm.tenant_setting (id, tenant_id, setting_key, value, created_by, updated_by)
  SELECT md5('ph06-setting:' || p_tenant || ':' || s.k)::uuid, p_tenant, s.k, s.v::jsonb, 'system:seed', 'system:seed'
  FROM (VALUES ('06.queue.sla-days', '7'), ('06.queue.max-open', '500'), ('06.queue.escalate-after-days', '14'), ('06.queue.hold-minutes', '30'),
               ('06.match.auto-disable-on-fail', 'true'), ('06.batch.safety-ratio', '0.05'), ('06.undo.window-days', '90'),
               ('06.export.max-rows', '100000'), ('06.access.bulk-threshold', '100'), ('06.ingest.rate-per-source', '6000'),
               ('06.sync.pause-ratio', '0.05'), ('06.sync.up-attributes', '[]'), ('06.dsr.sla-days', '10'),
               ('06.mask.reveal-seconds', '60'), ('06.ingest.max-file-mb', '50'), ('06.ingest.max-rows', '200000'), ('06.batch.max-hours', '4'), ('06.match.timeout-ms', '800'), ('06.sync.reconcile-batch-size', '1000'), ('06.xref.batch-max', '500'), ('06.queue.reopen-hours', '24')) AS s(k, v)
  ON CONFLICT (tenant_id, setting_key) DO NOTHING;
  INSERT INTO ph06_mdm.retention_policy (id, tenant_id, object_type, retention_days, action, created_by, updated_by)
  SELECT md5('ph06-retention:' || p_tenant || ':' || r.t)::uuid, p_tenant, r.t, r.d, r.a, 'system:seed', 'system:seed'
  FROM (VALUES ('candidate_record', 365, 'ANONYMIZE'), ('match_result', 730, 'DELETE'), ('match_staging', 7, 'DELETE'),
               ('golden_history', 1825, 'ARCHIVE_COLD'), ('attribute_lineage', 1825, 'ARCHIVE_COLD'), ('access_log', 365, 'ARCHIVE_COLD'),
               ('processing_log', 90, 'DELETE'), ('export_request', 90, 'DELETE'), ('subject_request', 1825, 'ARCHIVE_COLD'),
               ('steward_item', 730, 'ARCHIVE_COLD')) AS r(t, d, a)
  ON CONFLICT (tenant_id, object_type) DO NOTHING;
  INSERT INTO ph06_mdm.job_schedule (id, tenant_id, job_type, cron, enabled, created_by, updated_by)
  SELECT md5('ph06-schedule:' || p_tenant || ':' || j.t)::uuid, p_tenant, j.t, j.c, j.e, 'system:seed', 'system:seed'
  FROM (VALUES ('BATCH_MATCH', '0 0 2 * * *', true), ('ACCURACY_EVAL', '0 0 3 1 * *', true), ('NATIONAL_SYNC_DOWN', '0 */15 * * * *', true),
               ('NATIONAL_RECONCILE', '0 0 1 * * 0', true), ('RETENTION_PURGE', '0 30 3 * * *', true)) AS j(t, c, e)
  ON CONFLICT (tenant_id, job_type) DO NOTHING;
END
$p$;
COMMENT ON PROCEDURE ph06_mdm.p_seed_tenant(text) IS 'Gọi khi khởi tạo tenant (PH-20): tham số 06.* mặc định, 10 chính sách lưu giữ, 5 lịch job. Chạy lại không nhân bản.';
-- @rollback DROP PROCEDURE IF EXISTS ph06_mdm.p_seed_tenant(text);
"""

STD_COLS = ["id uuid NOT NULL", "tenant_id varchar(16) NOT NULL"]
AUDIT_COLS = ["created_at timestamptz NOT NULL DEFAULT now()", "created_by varchar(64) NOT NULL", "updated_at timestamptz NOT NULL DEFAULT now()",
              "updated_by varchar(64) NOT NULL"]


def render_table(t, seq):
    n = t["name"]
    cols = []
    if t["std"] or t["part"] or not t["nopk"]:
        cols += STD_COLS
    cols += t["cols"]
    if t["std"]:
        cols += AUDIT_COLS + [f"version integer NOT NULL DEFAULT {t['vs']}"]
    cons = []
    if t["part"]:
        cons.append((f"pk_{n}", f"PRIMARY KEY ({t['pk'][0]}, {t['pk'][1]})"))
    elif not t["nopk"]:
        cons.append((f"pk_{n}", "PRIMARY KEY (id)"))
    if t["tid"]:
        cons.append((f"uq_{n}_tid", "UNIQUE (tenant_id, id)"))
    if n not in ("outbox_event", "inbox_event", "shedlock"):
        cons.append((f"ck_{n}_tenant", f"CHECK (tenant_id ~ '{TENANT_RE}')"))
    cons += t["cons"]
    w = max(len(c.split()[0]) for c in cols)
    lines = [f"  {c.split()[0]:<{w}} {c[len(c.split()[0]) + 1:]}" for c in cols]
    for cn, cd in cons:
        lines.append(f"  CONSTRAINT {cn} {cd}")
    o = [f"-- @changeset ph06-{seq:04d}-{n.replace('_', '-')}", f"CREATE TABLE {S}.{n} (", ",\n".join(lines),
         ")" + (f" PARTITION BY RANGE ({t['part'][0]})" if t["part"] else "") + ";"]
    if t["part"]:
        o.append(f"CALL {S}.p_ensure_partitions('{S}.{n}', current_date, {t['part'][2]});")
    o += t["idx"]
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
        elif kind.startswith("child_frozen"):
            parent = {"child_frozen": "domain_model", "child_frozen_rules": "match_rule_set", "child_frozen_surv": "survivorship_rule_set"}[kind]
            o.append(f"CREATE TRIGGER tg_{n}_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_child_frozen('{parent}');")
    if t.get("rls", True):
        o.append(f"CALL {S}.p_enable_rls('{S}.{n}');")
    q = lambda s: s.replace("'", "''")
    o.append(f"COMMENT ON TABLE {S}.{n} IS '{q(t['comment'])}';")
    for c, txt in t["cc"].items():
        o.append(f"COMMENT ON COLUMN {S}.{n}.{c} IS '{q(txt)}';")
    o.append(f"-- @rollback DROP TABLE IF EXISTS {S}.{n} CASCADE;")
    return "\n".join(o)


def main():
    # bảng được tham chiếu bằng FK (tenant_id, id) cần UNIQUE (tenant_id, id): tự thêm khi dùng cờ tid; kiểm tra nhất quán
    all_t = {t["name"]: t for _, g in FILE_GROUPS for t in g}
    for t in all_t.values():
        for cn, cd in t["cons"]:
            m = re.search(r"REFERENCES %s\.(\w+) \(tenant_id, id\)" % S, cd)
            if m and not all_t[m.group(1)]["tid"]:
                raise SystemExit(f"{t['name']} -> {m.group(1)} cần tid=True")
    out = [HEAD]
    seq = 100
    for fname, grp in FILE_GROUPS:
        out.append(f"\n-- @file {fname}")
        for t in grp:
            out.append(render_table(t, seq))
            out.append("")
            seq += 10
    out.append(r"""-- @file 06-0900-grants.sql
-- @changeset ph06-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ph06_mdm TO ph06_app;
-- Bản ghi vàng và đối tượng nghiệp vụ không xóa cứng (BR-06-007): chỉ dọn bảng trung gian, nhật ký quá hạn theo retention_policy.
REVOKE DELETE ON ph06_mdm.mdm_domain, ph06_mdm.domain_model, ph06_mdm.model_attribute, ph06_mdm.identifier_rule, ph06_mdm.mdm_source,
  ph06_mdm.source_priority_proposal, ph06_mdm.source_priority, ph06_mdm.match_rule_set, ph06_mdm.match_rule, ph06_mdm.evaluation_report,
  ph06_mdm.golden_record, ph06_mdm.golden_attribute, ph06_mdm.golden_identifier, ph06_mdm.source_xref, ph06_mdm.golden_operation,
  ph06_mdm.survivorship_rule_set, ph06_mdm.survivorship_rule, ph06_mdm.steward_item, ph06_mdm.update_subscription, ph06_mdm.export_request,
  ph06_mdm.national_sync_state, ph06_mdm.national_sync_run, ph06_mdm.national_discrepancy, ph06_mdm.source_correction, ph06_mdm.subject_request,
  ph06_mdm.label_set, ph06_mdm.job_schedule, ph06_mdm.retention_policy, ph06_mdm.tenant_setting, ph06_mdm.match_job FROM ph06_app;
-- Bảng chỉ thêm: ứng dụng không UPDATE, DELETE (trigger là lớp chặn thứ hai); dọn bằng DETACH phân vùng dưới ph06_owner.
REVOKE UPDATE, DELETE ON ph06_mdm.golden_history, ph06_mdm.attribute_lineage, ph06_mdm.access_log, ph06_mdm.processing_log FROM ph06_app;
REVOKE UPDATE ON ph06_mdm.outbox_event FROM ph06_app;
GRANT SELECT ON ALL TABLES IN SCHEMA ph06_mdm TO ph06_readonly;
-- Báo cáo, Job Splink không đọc dữ liệu mã hóa và nhật ký truy cập: cột *_enc bị thu hồi ở bảng nhạy cảm.
REVOKE SELECT ON ph06_mdm.access_log, ph06_mdm.golden_history, ph06_mdm.subject_request, ph06_mdm.golden_identifier FROM ph06_readonly;
GRANT SELECT (id, tenant_id, accessed_at, actor, system_code, domain_code, golden_id, api_code, purpose_code, result_count, bulk_flag, trace_id)
  ON ph06_mdm.access_log TO ph06_readonly;
-- Vai Job Splink (FR-06-022): chỉ đọc match_staging, chỉ thêm match_result; không đọc bảng nào khác.
GRANT SELECT ON ph06_mdm.match_staging TO ph06_splink;
GRANT INSERT ON ph06_mdm.match_result TO ph06_splink;
GRANT EXECUTE ON PROCEDURE ph06_mdm.p_ensure_partitions(regclass, date, integer) TO ph06_app;
GRANT EXECUTE ON PROCEDURE ph06_mdm.p_seed_tenant(text) TO ph06_app;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;
""")
    path = os.path.join(ROOT, "ddl", "ph06_mdm.sql")
    open(path, "w", encoding="utf-8").write("\n".join(out))
    n = len(all_t)
    print(f"{n} bảng → {path}")


if __name__ == "__main__":
    main()
