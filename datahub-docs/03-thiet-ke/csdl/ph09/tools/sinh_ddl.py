#!/usr/bin/env python3
"""Sinh ddl/ph09_privacy.sql (schema ph09_privacy, D03-03-PH09) từ danh mục bảng khai báo ở tệp này.

Chạy từ thư mục csdl/ph09:  python3 tools/sinh_ddl.py
Chép từ tools/sinh_ddl.py của PH-06, chỉnh cho PH-09. Enum lấy trực tiếp từ Phụ lục A của D02-03-PH09 (hàm E),
khóa tham số 09.* lấy từ FRS 8.2, topic outbox lấy từ FRS 9.3; đổi enum thì sửa FRS trước.
Kết quả có dấu @file, @changeset, @rollback để tools/gen_liquibase.py sinh changelog. DDL là nguồn chuẩn cho
gen_tables_md.py, them_dac_ta_bang.py, gen_anh_xa.py, check_frs.py; không sửa tay tệp sinh ra.
Quy ước: snake_case của tên trường API; định danh chủ thể chỉ ở cột *_enc (envelope, ADR-032) kèm *_hash
(HMAC-SHA256 32 byte theo khóa tenant); không cột nào giữ giá trị DLCN rõ, không bảng ánh xạ bí danh (BR-09-030).
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRS_PATH = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH09-frs-quyen-rieng-tu.md")
FRS = open(FRS_PATH, encoding="utf-8").read()
APPX = FRS[FRS.index("## Phụ lục A."):]
S = "ph09_privacy"


def enum_values(name):
    m = re.search(r"^\| `%s`[^|]*\| ([^|]+) \|" % name, APPX, re.M)
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


def settings():
    """Khóa 09.* của FRS 8.2: (khóa, mặc định jsonb, sàn, trần)."""
    sec = FRS[FRS.index("### 8.2. Tham số theo tenant"):FRS.index("## 9. Mã lỗi")]
    out = []

    def num(s):
        s = s.strip().replace(" ", "")
        if "," in s:
            s = s.replace(".", "").replace(",", ".")
        else:
            s = s.replace(".", "")
        return float(s) if "." in s else int(s)

    for m in re.finditer(r"^\| `(09\.[a-z0-9.\-]+)` \| ([^|]+) \| ([^|]+) \|", sec, re.M):
        k, d, dom = m.group(1), m.group(2).strip(), m.group(3).strip()
        d = d.strip("`")
        if d in ("true", "false"):
            dv = d
        elif re.fullmatch(r"\d+(, \d+)+", d):
            dv = "[" + ", ".join(x.strip() for x in d.split(",")) + "]"
        elif re.fullmatch(r"[\d.,]+", d):
            dv = str(num(d))
        else:
            dv = '"%s"' % d
        r = re.match(r"([\d.,]+)…([\d.,]+)", dom)
        lo, hi = (str(num(r.group(1))), str(num(r.group(2)))) if r else (None, None)
        out.append((k, dv, lo, hi))
    return out


def topics():
    sec = FRS[FRS.index("### 9.3. Sự kiện"):FRS.index("### 9.4. Danh mục API")]
    return re.findall(r"`\{tenant\}\.(privacy\.[a-z\-.]+\.v1)`", sec)


SETTINGS = settings()
TOPICS = topics() + ["audit.recorded.v1"]
assert len(SETTINGS) == 43 and len(TOPICS) == 33, (len(SETTINGS), len(TOPICS))

TENANT_RE = "^T[0-9]{2}$"
CODE41 = "^[A-Z][A-Z0-9-]{2,40}$"
CODE32 = "^[A-Z][A-Z0-9_]{1,31}$"
FIELD_RE = "^[a-z][a-zA-Z0-9]{1,62}$"

TABLES = []


def T(name, comment, cols, cons=(), idx=(), part=None, std=True, tid=False, trig=(), post=(), pk=None, ccomment=None, nopk=False, rls=True):
    return dict(name=name, comment=comment, cols=cols, cons=list(cons), idx=list(idx), part=part, std=std, tid=tid,
                trig=list(trig), post=list(post), pk=pk, cc=ccomment or {}, nopk=nopk, rls=rls)


def chk(table, what, expr):
    return (f"ck_{table}_{what}", f"CHECK ({expr})")


def fk(table, col, target, tcol="id", cascade=False):
    return (f"fk_{table}_{col.replace('_id', '').replace(', ', '_')}",
            f"FOREIGN KEY (tenant_id, {col}) REFERENCES {S}.{target} (tenant_id, {tcol})" + (" ON DELETE CASCADE" if cascade else ""))


def reason20(col="reason"):
    return f"char_length({col}) >= 20"


VER_COLS = ["version_no integer NOT NULL", "status varchar(20) NOT NULL DEFAULT 'DRAFT'", "submitted_by varchar(64)", "submitted_at timestamptz",
            "decided_by varchar(64)", "decided_at timestamptz", "decision_comment varchar(2000)", "activated_at timestamptz", "superseded_at timestamptz"]


def ver(table, code_col, status_expr=None, extra_cons=()):
    """Ràng buộc chung của đối tượng có phiên bản (VersionStatus, BR-09-011, 023): bốn mắt, kích hoạt có người duyệt, một ACTIVE."""
    se = status_expr or f"status IN {E('VersionStatus')}"
    cons = [(f"uq_{table}_version", f"UNIQUE (tenant_id, {code_col}, version_no)"),
            chk(table, "version", "version_no >= 1"), chk(table, "status", se),
            chk(table, "four_eyes", "decided_by IS NULL OR (decided_by <> created_by AND decided_by IS DISTINCT FROM submitted_by)"),
            chk(table, "active", "status <> 'ACTIVE' OR (activated_at IS NOT NULL AND decided_by IS NOT NULL)"),
            chk(table, "reject", "status <> 'REJECTED' OR COALESCE(char_length(decision_comment) >= 20, false)")]
    idx = [f"CREATE UNIQUE INDEX uq_{table}_active ON {S}.{table} (tenant_id, {code_col}) WHERE status = 'ACTIVE';"]
    return cons + list(extra_cons), idx


# ---------------------------------------------------------------------------------------------
# 09-0010 Phân loại dữ liệu
# ---------------------------------------------------------------------------------------------
G_CLASS = []
_c, _i = [], []

G_CLASS.append(T("data_class",
    "EN-09-01 Mức phân loại DD-08 (FR-09-001): PUBLIC, INTERNAL, RESTRICTED, SENSITIVE, thứ hạng 1 đến 4 theo bảng D03-07 3.2. SENSITIVE luôn NO_VALUE ở log, MASK_DEFAULT ở hiển thị, mã hóa ở ứng dụng (ERR-09-003). Mỗi tenant có bản nạp sẵn bốn dòng; không xóa.",
    ["code varchar(16) NOT NULL", "rank smallint NOT NULL", "name varchar(100) NOT NULL", "log_policy varchar(16) NOT NULL", "display_policy varchar(16) NOT NULL",
     "encrypt_at_app boolean NOT NULL DEFAULT false"],
    [("uq_data_class_code", "UNIQUE (tenant_id, code)"), ("uq_data_class_rank", "UNIQUE (tenant_id, rank)"),
     chk("data_class", "code", f"code IN {E('DataClass')}"),
     chk("data_class", "rank", "rank = CASE code WHEN 'PUBLIC' THEN 1 WHEN 'INTERNAL' THEN 2 WHEN 'RESTRICTED' THEN 3 ELSE 4 END"),
     chk("data_class", "log", "log_policy IN ('FULL', 'PARTIAL_MASK', 'NO_VALUE')"),
     chk("data_class", "display", "display_policy IN ('FULL', 'MASK_BY_ROLE', 'MASK_DEFAULT')"),
     chk("data_class", "sensitive", "code <> 'SENSITIVE' OR (log_policy = 'NO_VALUE' AND display_policy = 'MASK_DEFAULT' AND encrypt_at_app)")],
    trig=[("immutable", ["code", "rank"])], tid=True,
    ccomment={"log_policy": "Cách ghi giá trị vào log vận hành (D03-07 3.2).", "encrypt_at_app": "Mã hóa envelope ở tầng ứng dụng (ADR-032)."}))

G_CLASS.append(T("block_label",
    "EN-09-02 Nhãn chặn STATE_SECRET gắn vào phần tử hoặc hợp đồng (FR-09-007, BR-09-005). Gỡ nhãn cần văn bản giải mật và hai người khác nhau (ERR-09-019); không xóa dòng, gỡ ghi released_*. Mọi thao tác ghi kiểm toán, bị từ chối nếu không ghi được (BR-09-057).",
    ["label varchar(16) NOT NULL DEFAULT 'STATE_SECRET'", "target_kind varchar(16) NOT NULL", "target_id varchar(128) NOT NULL", "legal_doc varchar(255) NOT NULL",
     "assigned_by varchar(64) NOT NULL", "release_requested_by varchar(64)", "release_requested_at timestamptz", "release_doc varchar(255)",
     "released_by varchar(64)", "released_at timestamptz"],
    [chk("block_label", "label", f"label IN {E('BlockLabel')}"),
     chk("block_label", "target", "target_kind IN ('ELEMENT', 'API', 'TOPIC', 'FLOW')"),
     chk("block_label", "release_req", "(release_requested_by IS NULL) = (release_requested_at IS NULL) AND (release_requested_by IS NULL OR release_doc IS NOT NULL)"),
     chk("block_label", "released", "(released_by IS NULL) = (released_at IS NULL) AND (released_by IS NULL OR (release_requested_by IS NOT NULL AND released_by <> release_requested_by))")],
    idx=[f"CREATE UNIQUE INDEX uq_block_label_active ON {S}.block_label (tenant_id, target_kind, target_id) WHERE released_at IS NULL;"],
    trig=[("immutable", ["target_kind", "target_id", "legal_doc", "assigned_by"])],
    ccomment={"released_by": "Người duyệt gỡ, khác người đề nghị gỡ (BR-09-005)."}))

G_CLASS.append(T("personal_data_category",
    "EN-09-03 Loại dữ liệu cá nhân (FR-09-002): 9 loại cơ bản và 9 loại nhạy cảm của Luật 91/2025, NĐ 356/2025, nạp sẵn; tenant thêm loại mới. Loại SENSITIVE mặc định mức SENSITIVE; hạ loại cần bốn mắt (BR-09-002). Ngừng bằng retired_at.",
    ["code varchar(32) NOT NULL", "name varchar(255) NOT NULL", "personal_data_type varchar(16) NOT NULL", "legal_ref varchar(16)", "default_class varchar(16) NOT NULL",
     "default_mask_pattern varchar(24)", "identifiability varchar(16) NOT NULL DEFAULT 'NONE'", "builtin boolean NOT NULL DEFAULT false", "retired_at timestamptz"],
    [("uq_personal_data_category_code", "UNIQUE (tenant_id, code)"),
     chk("personal_data_category", "code", f"code ~ '{CODE32}'"),
     chk("personal_data_category", "type", f"personal_data_type IN {E('PersonalDataType', skip=('NONE',))}"),
     chk("personal_data_category", "legal", "legal_ref IS NULL OR legal_ref ~ '^CMP-LAW-[0-9]{2}$'"),
     chk("personal_data_category", "class", f"default_class IN {E('DataClass')}"),
     chk("personal_data_category", "pattern", f"default_mask_pattern IS NULL OR default_mask_pattern IN {E('MaskPatternKind')}"),
     chk("personal_data_category", "ident", f"identifiability IN {E('IdentifiabilityType')}"),
     chk("personal_data_category", "sensitive", "personal_data_type <> 'SENSITIVE' OR default_class = 'SENSITIVE'")],
    trig=[("immutable", ["code", "builtin"])], tid=True))

G_CLASS.append(T("data_element",
    "EN-09-04 Phần tử dữ liệu (trường) đăng ký từ phân hệ, lược đồ API, topic, khai báo MVP (FR-09-003, BR-09-007). target là tên đầy đủ (ph06_mdm.CITIZEN.nationalId) hoặc JSON Pointer. Không xóa; ngừng bằng element_status RETIRED. Phân loại hiện hành ở element_classification.",
    ["scope varchar(16) NOT NULL", "target varchar(512) NOT NULL", "owner_org_id varchar(63) NOT NULL", "contract_ref varchar(255)", "declared_class varchar(16)",
     "source varchar(16) NOT NULL", "element_status varchar(12) NOT NULL DEFAULT 'ACTIVE'", "retired_at timestamptz"],
    [("uq_data_element_target", "UNIQUE (tenant_id, scope, target)"),
     chk("data_element", "scope", f"scope IN {E('ElementScope')}"),
     chk("data_element", "declared", f"declared_class IS NULL OR declared_class IN {E('DataClass')}"),
     chk("data_element", "source", f"source IN {E('ClassificationSource')}"),
     chk("data_element", "status", f"element_status IN {E('ElementStatus')}"),
     chk("data_element", "retired", "(element_status = 'RETIRED') = (retired_at IS NOT NULL)")],
    idx=[f"CREATE INDEX ix_data_element_owner ON {S}.data_element (tenant_id, owner_org_id, element_status);",
         f"CREATE INDEX ix_data_element_contract ON {S}.data_element (tenant_id, contract_ref) WHERE contract_ref IS NOT NULL;",
         f"CREATE INDEX ix_data_element_target_trgm ON {S}.data_element USING gin (lower(target) gin_trgm_ops);"],
    trig=[("immutable", ["scope", "target"])], tid=True,
    ccomment={"owner_org_id": "Mã tổ chức ở PH-01 (không khóa ngoại, khác schema); chỉ TA, SO, DO của tổ chức này xác nhận (BR-09-003).",
              "declared_class": "Mức khai báo trong mã (@Classified, x-dh-classification) khi nhập MVP (FR-09-003)."}))

G_CLASS.append(T("element_classification",
    "EN-09-05 Phân loại hiện hành của phần tử, một dòng mỗi phần tử (DD-09, FR-09-004). Chưa CONFIRMED thì xử lý như SENSITIVE (BR-09-001). Loại DLCN khác NONE phải có categoryCode; SENSITIVE kéo theo mức SENSITIVE. Đổi qua classification_change.",
    ["element_id uuid NOT NULL", "data_class varchar(16) NOT NULL", "personal_data_type varchar(16) NOT NULL DEFAULT 'NONE'", "category_code varchar(32)",
     "identifiability varchar(16) NOT NULL DEFAULT 'NONE'", "mask_pattern varchar(24)", "never_reveal boolean NOT NULL DEFAULT false", "basis varchar(255)",
     "status varchar(12) NOT NULL DEFAULT 'PROPOSED'", "source varchar(16) NOT NULL", "confirmed_by varchar(64)", "confirmed_at timestamptz"],
    [("uq_element_classification_element", "UNIQUE (tenant_id, element_id)"),
     fk("element_classification", "element_id", "data_element"),
     ("fk_element_classification_category", f"FOREIGN KEY (tenant_id, category_code) REFERENCES {S}.personal_data_category (tenant_id, code)"),
     chk("element_classification", "class", f"data_class IN {E('DataClass')}"),
     chk("element_classification", "type", f"personal_data_type IN {E('PersonalDataType')}"),
     chk("element_classification", "ident", f"identifiability IN {E('IdentifiabilityType')}"),
     chk("element_classification", "pattern", f"mask_pattern IS NULL OR mask_pattern IN {E('MaskPatternKind')}"),
     chk("element_classification", "status", f"status IN {E('ClassificationStatus')}"),
     chk("element_classification", "source", f"source IN {E('ClassificationSource')}"),
     chk("element_classification", "category", "(personal_data_type = 'NONE') = (category_code IS NULL)"),
     chk("element_classification", "sensitive", "personal_data_type <> 'SENSITIVE' OR data_class = 'SENSITIVE'"),
     chk("element_classification", "direct", "identifiability NOT IN ('DIRECT', 'SENSITIVE_ATTR') OR personal_data_type <> 'NONE'"),
     chk("element_classification", "confirmed", "status <> 'CONFIRMED' OR (confirmed_by IS NOT NULL AND confirmed_at IS NOT NULL)")],
    idx=[f"CREATE INDEX ix_element_classification_class ON {S}.element_classification (tenant_id, data_class, status);",
         f"CREATE INDEX ix_element_classification_category ON {S}.element_classification (tenant_id, category_code) WHERE category_code IS NOT NULL;"],
    trig=[("immutable", ["element_id"])], tid=True,
    ccomment={"never_reveal": "Trường không có đường xem đầy đủ (BR-09-026).", "mask_pattern": "Mẫu che mặc định của trường (MaskPatternKind).",
              "basis": "Số văn bản căn cứ của phân loại."}))

G_CLASS.append(T("classification_change",
    "EN-09-06 Đề xuất, thay đổi phân loại (FR-09-004, 005, BR-09-002, 003, 007). Người xác nhận khác người đề xuất. Hạ mức hoặc hạ loại DLCN từ SENSITIVE cần số văn bản căn cứ và người xác nhận thứ hai khác hai người kia. Lịch sử tuyến tính, không sửa sau khi chốt.",
    ["element_id uuid NOT NULL", "from_class varchar(16)", "to_class varchar(16) NOT NULL", "from_personal_data_type varchar(16)", "to_personal_data_type varchar(16) NOT NULL",
     "proposed jsonb NOT NULL", "status varchar(12) NOT NULL DEFAULT 'PROPOSED'", "basis varchar(255)", "reason varchar(2000) NOT NULL", "proposed_by varchar(64) NOT NULL",
     "confirmed_by varchar(64)", "confirmed_at timestamptz", "confirmed_by_2 varchar(64)", "confirmed_at_2 timestamptz", "reject_comment varchar(2000)", "source varchar(16) NOT NULL"],
    [fk("classification_change", "element_id", "data_element"),
     chk("classification_change", "class", f"to_class IN {E('DataClass')} AND (from_class IS NULL OR from_class IN {E('DataClass')})"),
     chk("classification_change", "type", f"to_personal_data_type IN {E('PersonalDataType')} AND (from_personal_data_type IS NULL OR from_personal_data_type IN {E('PersonalDataType')})"),
     chk("classification_change", "status", f"status IN {E('ClassificationStatus')}"),
     chk("classification_change", "source", f"source IN {E('ClassificationSource')}"),
     chk("classification_change", "reason", reason20()),
     chk("classification_change", "four_eyes", "confirmed_by IS NULL OR confirmed_by <> proposed_by"),
     chk("classification_change", "confirmed", "status <> 'CONFIRMED' OR (confirmed_by IS NOT NULL AND confirmed_at IS NOT NULL)"),
     chk("classification_change", "downgrade",
         f"status <> 'CONFIRMED' OR from_class IS NULL OR {S}.class_rank(to_class) >= {S}.class_rank(from_class) "
         "OR (basis IS NOT NULL AND confirmed_by_2 IS NOT NULL AND confirmed_at_2 IS NOT NULL AND confirmed_by_2 <> confirmed_by AND confirmed_by_2 <> proposed_by)"),
     chk("classification_change", "type_down",
         "status <> 'CONFIRMED' OR from_personal_data_type IS DISTINCT FROM 'SENSITIVE' OR to_personal_data_type = 'SENSITIVE' "
         "OR (basis IS NOT NULL AND confirmed_by_2 IS NOT NULL AND confirmed_by_2 <> confirmed_by AND confirmed_by_2 <> proposed_by)"),
     chk("classification_change", "rejected", "status <> 'REJECTED' OR COALESCE(char_length(reject_comment) >= 20, false)")],
    idx=[f"CREATE INDEX ix_classification_change_element ON {S}.classification_change (tenant_id, element_id, created_at DESC);",
         f"CREATE INDEX ix_classification_change_open ON {S}.classification_change (tenant_id, status, created_at) WHERE status = 'PROPOSED';"],
    trig=[("immutable", ["element_id", "from_class", "to_class", "proposed", "proposed_by"])], tid=True,
    ccomment={"proposed": "Trạng thái phân loại đề xuất (dataClass, personalDataType, categoryCode, identifiability, maskPattern, neverReveal).",
              "confirmed_by_2": "Người xác nhận thứ hai khi hạ mức (BR-09-002)."}))

G_CLASS.append(T("detector_rule",
    "EN-09-07 Mẫu phát hiện DLCN (FR-09-005, ADR đề xuất 093): số định danh 12 chữ số, mã số thuế, thẻ (Luhn), điện thoại, thư điện tử, mã BHXH, gợi ý theo tên trường. Bộ mẫu và kiểm tổng, không dùng học máy ở đợt 2.",
    ["detector_code varchar(24) NOT NULL", "name varchar(255) NOT NULL", "pattern varchar(500) NOT NULL", "has_checksum boolean NOT NULL DEFAULT false",
     "confidence_threshold numeric(3,2) NOT NULL DEFAULT 0.80", "enabled boolean NOT NULL DEFAULT true", "builtin boolean NOT NULL DEFAULT false"],
    [("uq_detector_rule_code", "UNIQUE (tenant_id, detector_code)"),
     chk("detector_rule", "code", f"detector_code IN {E('DetectorType')}"),
     chk("detector_rule", "threshold", "confidence_threshold BETWEEN 0.50 AND 0.99")],
    trig=[("immutable", ["detector_code"])], ccomment={"pattern": "Biểu thức chính quy hoặc danh sách gợi ý tên trường; kiểm tổng (Luhn, mod 11) ở mã."}))

G_CLASS.append(T("scan_run",
    "EN-09-08 Lượt quét phát hiện trường nghi DLCN (FR-09-005, NFR-09-009): phạm vi, số dòng mẫu, mẫu phát hiện, trạng thái ScanStatus. Chỉ đọc mẫu, không lưu giá trị mẫu (BR-09-025). Giữ 365 ngày.",
    ["scope jsonb NOT NULL", "sample_rows integer NOT NULL DEFAULT 10000", "detectors varchar(24)[] NOT NULL", "status varchar(12) NOT NULL DEFAULT 'QUEUED'",
     "requested_by varchar(64) NOT NULL", "started_at timestamptz", "finished_at timestamptz", "suspect_count integer NOT NULL DEFAULT 0", "error_code varchar(10)"],
    [chk("scan_run", "rows", "sample_rows BETWEEN 1000 AND 100000"),
     chk("scan_run", "detectors", f"cardinality(detectors) >= 1 AND {arr_in('detectors', 'DetectorType')}"),
     chk("scan_run", "status", f"status IN {E('ScanStatus')}"),
     chk("scan_run", "finished", "status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED') OR finished_at IS NOT NULL"),
     chk("scan_run", "error", "error_code IS NULL OR error_code ~ '^ERR-09-[0-9]{3}$'"),
     chk("scan_run", "failed", "status <> 'FAILED' OR error_code IS NOT NULL"),
     chk("scan_run", "suspect", "suspect_count >= 0")],
    idx=[f"CREATE INDEX ix_scan_run_list ON {S}.scan_run (tenant_id, created_at DESC);"], tid=True,
    ccomment={"scope": "Hệ thống, hợp đồng cần quét (FR-09-005)."}))

G_CLASS.append(T("scan_finding",
    "EN-09-09 Kết quả phát hiện một cột hoặc trường (FR-09-005, BR-09-006): mẫu khớp, độ tin cậy, trạng thái FindingStatus. Chỉ là gợi ý, không tự đổi phân loại. Chỉ lưu số lượt khớp, không lưu giá trị.",
    ["scan_id uuid NOT NULL", "element_id uuid", "target varchar(512) NOT NULL", "detector_code varchar(24) NOT NULL", "confidence numeric(4,3) NOT NULL",
     "hit_count integer NOT NULL", "status varchar(16) NOT NULL DEFAULT 'OPEN'", "resolved_by varchar(64)", "resolved_at timestamptz", "resolution_note varchar(2000)"],
    [fk("scan_finding", "scan_id", "scan_run"), fk("scan_finding", "element_id", "data_element"),
     ("uq_scan_finding_target", "UNIQUE (tenant_id, scan_id, target, detector_code)"),
     chk("scan_finding", "detector", f"detector_code IN {E('DetectorType')}"),
     chk("scan_finding", "confidence", "confidence BETWEEN 0 AND 1 AND hit_count >= 0"),
     chk("scan_finding", "status", f"status IN {E('FindingStatus')}"),
     chk("scan_finding", "resolved", "status = 'OPEN' OR (resolved_by IS NOT NULL AND resolved_at IS NOT NULL)")],
    idx=[f"CREATE INDEX ix_scan_finding_open ON {S}.scan_finding (tenant_id, status, confidence DESC) WHERE status = 'OPEN';"]))

G_CLASS.append(T("contract_level",
    "EN-09-10 Mức phân loại tính được của hợp đồng API, topic, luồng (FR-09-006, BR-09-001, 004): mức cao nhất của các trường; provisional khi còn phần tử chưa CONFIRMED (tạm SENSITIVE); blocked khi có nhãn STATE_SECRET. Tính lại khi phân loại đổi (NFR-09-010).",
    ["contract_kind varchar(8) NOT NULL", "contract_id varchar(128) NOT NULL", "data_class varchar(16) NOT NULL", "provisional boolean NOT NULL DEFAULT false",
     "blocked boolean NOT NULL DEFAULT false", "element_count integer NOT NULL DEFAULT 0", "computed_at timestamptz NOT NULL DEFAULT now()", "basis jsonb"],
    [("uq_contract_level_contract", "UNIQUE (tenant_id, contract_kind, contract_id)"),
     chk("contract_level", "kind", f"contract_kind IN {E('ContractKind')}"),
     chk("contract_level", "class", f"data_class IN {E('DataClass')}"),
     chk("contract_level", "count", "element_count >= 0"),
     chk("contract_level", "provisional", "NOT provisional OR data_class = 'SENSITIVE'")],
    idx=[f"CREATE INDEX ix_contract_level_class ON {S}.contract_level (tenant_id, data_class);"],
    ccomment={"basis": "Phần tử quyết định mức (mã phần tử, không giá trị)."}))

# ---------------------------------------------------------------------------------------------
# 09-0020 Sổ hoạt động xử lý
# ---------------------------------------------------------------------------------------------
G_ROPA = []
G_ROPA.append(T("legal_document",
    "EN-09-14 Văn bản căn cứ (FR-09-012): loại, số, ngày ban hành, hiệu lực, liên kết CMP-LAW. Văn bản hết hiệu lực không dùng cho hoạt động mới (kiểm ở dịch vụ).",
    ["doc_type varchar(32) NOT NULL", "number varchar(64) NOT NULL", "title varchar(500) NOT NULL", "issued_on date NOT NULL", "effective_from date NOT NULL",
     "effective_to date", "cmp_law_code varchar(16)"],
    [("uq_legal_document_number", "UNIQUE (tenant_id, doc_type, number)"),
     chk("legal_document", "type", "doc_type ~ '^[A-Z][A-Z0-9_]{1,31}$'"),
     chk("legal_document", "period", "effective_from >= issued_on AND (effective_to IS NULL OR effective_to > effective_from)"),
     chk("legal_document", "law", "cmp_law_code IS NULL OR cmp_law_code ~ '^CMP-LAW-[0-9]{2}$'")],
    trig=[("immutable", ["doc_type", "number"])], tid=True))

G_ROPA.append(T("legal_basis",
    "EN-09-13 Cơ sở pháp lý (FR-09-012, BR-09-009): bảy LegalBasisType nạp sẵn kèm quy tắc áp dụng. CONSENT chỉ cho tiện ích không bắt buộc; cơ quan nhà nước dùng STATE_TASK hoặc LEGAL_OBLIGATION.",
    ["code varchar(32) NOT NULL", "basis_type varchar(32) NOT NULL", "name varchar(255) NOT NULL", "mandatory boolean NOT NULL DEFAULT false", "rule varchar(2000)", "retired_at timestamptz"],
    [("uq_legal_basis_code", "UNIQUE (tenant_id, code)"),
     chk("legal_basis", "code", f"code ~ '{CODE32}'"),
     chk("legal_basis", "type", f"basis_type IN {E('LegalBasisType')}")],
    trig=[("immutable", ["code", "basis_type"])], tid=True))

_c, _i = ver("processing_activity", "code")
G_ROPA.append(T("processing_activity",
    "EN-09-11 Hoạt động xử lý DLCN theo phiên bản (FR-09-009, 010, BR-09-009…012): mục đích, cơ sở pháp lý chính, loại dữ liệu, nhóm chủ thể, bên nhận, thời hạn lưu (số tháng hoặc điều kiện kết thúc cùng hành động), vai trò, biện pháp. ACTIVE không sửa tại chỗ, duyệt bốn mắt.",
    ["code varchar(41) NOT NULL"] + VER_COLS + [
     "purpose_text varchar(1000) NOT NULL", "legal_basis_code varchar(32) NOT NULL", "legal_doc_ids uuid[] NOT NULL DEFAULT '{}'", "categories varchar(32)[] NOT NULL",
     "subject_groups varchar(255)[] NOT NULL", "recipients varchar(255)[] NOT NULL DEFAULT '{}'", "retention jsonb NOT NULL", "controller_role varchar(20) NOT NULL",
     "measures varchar(500)[] NOT NULL"],
    [chk("processing_activity", "code", f"code ~ '{CODE41}'"),
     ("fk_processing_activity_basis", f"FOREIGN KEY (tenant_id, legal_basis_code) REFERENCES {S}.legal_basis (tenant_id, code)"),
     chk("processing_activity", "purpose", "char_length(purpose_text) >= 20"),
     chk("processing_activity", "role", f"controller_role IN {E('ControllerRole')}"),
     chk("processing_activity", "retention",
         f"jsonb_typeof(retention) = 'object' AND retention->>'action' IN ('DELETE', 'PSEUDONYMIZE', 'ANONYMIZE', 'ARCHIVE') AND (retention ? 'months' OR retention ? 'endCondition')"),
     chk("processing_activity", "lists", "cardinality(categories) >= 1 AND cardinality(subject_groups) >= 1 AND cardinality(measures) >= 1")] + _c,
    idx=_i, tid=True,
    trig=[("immutable", ["code", "version_no"]), ("frozen", ["purpose_text", "legal_basis_code", "categories", "subject_groups", "recipients", "retention", "controller_role", "measures", "legal_doc_ids"])],
    ccomment={"categories": "Mã loại DLCN (personal_data_category.code); kiểm tồn tại ở dịch vụ khi gửi duyệt.", "legal_doc_ids": "Mã legal_document; mảng nên kiểm ở dịch vụ.",
              "retention": "{months, endCondition, action}, action là RetentionAction (BR-09-012)."}))

G_ROPA.append(T("activity_link",
    "EN-09-12 Liên kết hoạt động xử lý với phần tử, API, topic hoặc luồng (FR-09-011, BR-09-008). Chỉ sửa khi hoạt động ở DRAFT hoặc REJECTED (trigger). Mỗi trường DLCN CONFIRMED phải thuộc ít nhất một hoạt động ACTIVE (kiểm ở dịch vụ, SEC-37).",
    ["activity_id uuid NOT NULL", "target_kind varchar(8) NOT NULL", "target_id varchar(128) NOT NULL"],
    [fk("activity_link", "activity_id", "processing_activity"),
     ("uq_activity_link_target", "UNIQUE (tenant_id, activity_id, target_kind, target_id)"),
     chk("activity_link", "kind", "target_kind IN ('ELEMENT', 'API', 'TOPIC', 'FLOW')")],
    idx=[f"CREATE INDEX ix_activity_link_target ON {S}.activity_link (tenant_id, target_kind, target_id);"],
    trig=[("child_frozen", ["processing_activity", "activity_id"])]))

# ---------------------------------------------------------------------------------------------
# 09-0030 Mục đích và chấp thuận
# ---------------------------------------------------------------------------------------------
G_PURPOSE = []
G_PURPOSE.append(T("purpose",
    "EN-09-15 Mục đích khai thác (FR-09-014, BR-09-015, 047): mã dạng TTHC-HO-TICH, THONG-KE, cơ sở pháp lý, loại DLCN được phép, cờ statutory (mục đích bắt buộc theo luật vẫn truy cập được khi chủ thể bị hạn chế), thời hạn tối đa. Trường được phép ở purpose_element.",
    ["code varchar(41) NOT NULL", "name varchar(255) NOT NULL", "description varchar(2000)", "legal_basis_code varchar(32) NOT NULL", "allowed_categories varchar(32)[] NOT NULL DEFAULT '{}'",
     "statutory boolean NOT NULL DEFAULT false", "max_days integer NOT NULL DEFAULT 365", "status varchar(8) NOT NULL DEFAULT 'ACTIVE'"],
    [("uq_purpose_code", "UNIQUE (tenant_id, code)"),
     ("fk_purpose_basis", f"FOREIGN KEY (tenant_id, legal_basis_code) REFERENCES {S}.legal_basis (tenant_id, code)"),
     chk("purpose", "code", f"code ~ '{CODE41}'"),
     chk("purpose", "days", "max_days BETWEEN 1 AND 730"),
     chk("purpose", "status", f"status IN {E('PurposeStatus')}")],
    trig=[("immutable", ["code"])], tid=True,
    ccomment={"max_days": "Trần cứng 730 ngày; trần tenant 09.grant.max-days mặc định 365 (BR-09-015)."}))

G_PURPOSE.append(T("purpose_element",
    "EN-09-52 Trường được phép theo mục đích, bảng con của Purpose (FR-09-014, BR-09-016): phạm vi tối đa mà một chấp thuận của mục đích đó được bao.",
    ["purpose_id uuid NOT NULL", "element_id uuid NOT NULL"],
    [fk("purpose_element", "purpose_id", "purpose"), fk("purpose_element", "element_id", "data_element"),
     ("uq_purpose_element", "UNIQUE (tenant_id, purpose_id, element_id)")],
    idx=[f"CREATE INDEX ix_purpose_element_element ON {S}.purpose_element (tenant_id, element_id);"]))

G_PURPOSE.append(T("access_request",
    "EN-09-16 Yêu cầu khai thác của HTTT cho một mục đích (FR-09-015, 016, BR-09-013, 014, 016). Máy trạng thái AccessRequestStatus; chủ quản không duyệt yêu cầu do chính mình lập. Hợp đồng phải mức từ RESTRICTED (kiểm ở dịch vụ).",
    ["httt_id varchar(63) NOT NULL", "registration_ref varchar(63)", "purpose_code varchar(41) NOT NULL", "contract_kind varchar(8) NOT NULL", "contract_id varchar(128) NOT NULL",
     "fields varchar(63)[] NOT NULL", "expected_volume integer NOT NULL", "requested_days integer NOT NULL", "justification varchar(2000) NOT NULL", "owner_org_id varchar(63) NOT NULL",
     "status varchar(16) NOT NULL DEFAULT 'DRAFT'", "submitted_at timestamptz", "reviewer varchar(64)", "decision varchar(24)", "decision_reason varchar(2000)",
     "decided_by varchar(64)", "decided_at timestamptz", "due_at timestamptz",
     "request_kind varchar(8) NOT NULL DEFAULT 'NEW'", "renews_grant_id uuid"],
    [("fk_access_request_purpose", f"FOREIGN KEY (tenant_id, purpose_code) REFERENCES {S}.purpose (tenant_id, code)"),
     chk("access_request", "kind", f"contract_kind IN {E('ContractKind')}"),
     chk("access_request", "req_kind", f"request_kind IN {E('AccessRequestKind')}"),
     chk("access_request", "renews", "(request_kind = 'RENEWAL') = (renews_grant_id IS NOT NULL)"),
     chk("access_request", "fields", "cardinality(fields) >= 1"),
     chk("access_request", "volume", "expected_volume BETWEEN 1 AND 10000000 AND requested_days BETWEEN 1 AND 730"),
     chk("access_request", "justification", "char_length(justification) >= 20"),
     chk("access_request", "status", f"status IN {E('AccessRequestStatus')}"),
     chk("access_request", "decision", f"decision IS NULL OR decision IN {E('AccessDecision')}"),
     chk("access_request", "four_eyes", "decided_by IS NULL OR decided_by <> created_by"),
     chk("access_request", "decided", "(status IN ('APPROVED', 'REJECTED')) = (decided_by IS NOT NULL AND decided_at IS NOT NULL AND decision IS NOT NULL)"),
     chk("access_request", "outcome", "(status <> 'APPROVED' OR decision IN ('APPROVE', 'APPROVE_WITH_CONDITIONS')) AND (status <> 'REJECTED' OR (decision = 'REJECT' AND COALESCE(char_length(decision_reason) >= 20, false)))"),
     chk("access_request", "submitted", "status IN ('DRAFT', 'WITHDRAWN') OR submitted_at IS NOT NULL")],
    idx=[f"CREATE INDEX ix_access_request_inbox ON {S}.access_request (tenant_id, owner_org_id, status, due_at) WHERE status IN ('SUBMITTED', 'UNDER_REVIEW', 'NEEDS_INFO');",
         f"CREATE INDEX ix_access_request_httt ON {S}.access_request (tenant_id, httt_id, created_at DESC);"],
    trig=[("immutable", ["httt_id", "purpose_code", "contract_kind", "contract_id"])], tid=True,
    ccomment={"httt_id": "Mã HTTT ở PH-01 (không khóa ngoại).", "registration_ref": "Đăng ký sử dụng ở PH-02.",
              "owner_org_id": "Tổ chức chủ quản dữ liệu, đích hộp việc của DO.",
              "request_kind": "AccessRequestKind: NEW (mặc định) hoặc RENEWAL, yêu cầu gia hạn chấp thuận hiện có (FR-09-015).",
              "renews_grant_id": "Chấp thuận ACTIVE được gia hạn; bắt buộc khi RENEWAL, rỗng khi NEW; cùng HTTT và mục đích kiểm ở dịch vụ (FR-09-015, 016)."}))

G_PURPOSE.append(T("purpose_grant",
    "EN-09-17 Chấp thuận khai thác: bộ ba (HTTT, mục đích, hợp đồng), không chuyển nhượng (BR-09-013, FR-09-016, 017). Máy trạng thái GrantStatus; tối đa 3 lần gia hạn mặc định; thu hồi cần lý do 20 ký tự; một chấp thuận hiệu lực mỗi bộ ba. Nguồn của purpose_grants trong bundle OPA (FR-09-018).",
    ["request_id uuid NOT NULL", "httt_id varchar(63) NOT NULL", "purpose_code varchar(41) NOT NULL", "contract_kind varchar(8) NOT NULL", "contract_id varchar(128) NOT NULL",
     "valid_from timestamptz NOT NULL", "valid_to timestamptz NOT NULL", "status varchar(12) NOT NULL", "fields varchar(63)[] NOT NULL", "quota_per_day integer",
     "renew_count smallint NOT NULL DEFAULT 0", "approved_by varchar(64) NOT NULL", "approved_at timestamptz NOT NULL DEFAULT now()", "suspended_at timestamptz", "suspend_reason varchar(2000)",
     "revoked_by varchar(64)", "revoked_at timestamptz", "revoke_reason varchar(2000)", "expired_at timestamptz", "expiry_notified_at timestamptz"],
    [fk("purpose_grant", "request_id", "access_request"),
     ("fk_purpose_grant_purpose", f"FOREIGN KEY (tenant_id, purpose_code) REFERENCES {S}.purpose (tenant_id, code)"),
     chk("purpose_grant", "kind", f"contract_kind IN {E('ContractKind')}"),
     chk("purpose_grant", "period", "valid_to > valid_from AND valid_to <= valid_from + interval '730 days'"),
     chk("purpose_grant", "status", f"status IN {E('GrantStatus')}"),
     chk("purpose_grant", "fields", "cardinality(fields) >= 1"),
     chk("purpose_grant", "quota", "quota_per_day IS NULL OR quota_per_day BETWEEN 1 AND 100000000"),
     chk("purpose_grant", "renew", "renew_count BETWEEN 0 AND 10"),
     chk("purpose_grant", "suspended", "status <> 'SUSPENDED' OR (suspended_at IS NOT NULL AND suspend_reason IS NOT NULL)"),
     chk("purpose_grant", "revoked", "status <> 'REVOKED' OR (revoked_by IS NOT NULL AND revoked_at IS NOT NULL AND COALESCE(char_length(revoke_reason) >= 20, false))"),
     chk("purpose_grant", "expired", "status <> 'EXPIRED' OR expired_at IS NOT NULL")],
    idx=[f"CREATE UNIQUE INDEX uq_purpose_grant_live ON {S}.purpose_grant (tenant_id, httt_id, purpose_code, contract_kind, contract_id) WHERE status IN ('SCHEDULED', 'ACTIVE', 'SUSPENDED');",
         f"CREATE INDEX ix_purpose_grant_expiry ON {S}.purpose_grant (tenant_id, valid_to) WHERE status IN ('SCHEDULED', 'ACTIVE', 'SUSPENDED');",
         f"CREATE INDEX ix_purpose_grant_httt ON {S}.purpose_grant (tenant_id, httt_id, status);"],
    trig=[("immutable", ["request_id", "httt_id", "purpose_code", "contract_kind", "contract_id", "approved_by"])], tid=True,
    post=[f"ALTER TABLE {S}.access_request ADD CONSTRAINT fk_access_request_renews FOREIGN KEY (tenant_id, renews_grant_id) REFERENCES {S}.purpose_grant (tenant_id, id);"]))

G_PURPOSE.append(T("grant_condition",
    "EN-09-18 Điều kiện của chấp thuận (FR-09-016, BR-09-016): FIELD_SUBSET, DAILY_QUOTA, TIME_WINDOW, NO_EXPORT, MASK_REQUIRED, tham số jsonb. Ghi vào bundle OPA; mỗi loại tối đa một dòng mỗi chấp thuận.",
    ["grant_id uuid NOT NULL", "condition_type varchar(16) NOT NULL", "params jsonb NOT NULL DEFAULT '{}'"],
    [fk("grant_condition", "grant_id", "purpose_grant"),
     ("uq_grant_condition_type", "UNIQUE (tenant_id, grant_id, condition_type)"),
     chk("grant_condition", "type", f"condition_type IN {E('ConditionType')}"),
     chk("grant_condition", "params", "jsonb_typeof(params) = 'object'")]))

G_PURPOSE.append(T("policy_bundle",
    "EN-09-19 Bundle purpose_grants, mask_policies, classification_index đã ký (FR-09-018, BR-09-018): băm nội dung, chữ ký bằng khóa transit không xuất được, validUntil = phát hành cộng 60 phút mặc định, kết quả kiểm thử. Nội dung bundle ở Garage (object_ref), ≤ 5 MB. Chỉ phát hành khi kiểm thử đạt.",
    ["bundle_no bigint NOT NULL", "content_hash bytea NOT NULL", "signature bytea", "signing_key_ref varchar(128)", "object_ref varchar(512) NOT NULL", "size_bytes integer NOT NULL",
     "counts jsonb NOT NULL DEFAULT '{}'", "test_passed boolean NOT NULL DEFAULT false", "test_result jsonb", "published_at timestamptz", "valid_until timestamptz"],
    [("uq_policy_bundle_no", "UNIQUE (tenant_id, bundle_no)"),
     chk("policy_bundle", "hash", "octet_length(content_hash) = 32"),
     chk("policy_bundle", "size", "size_bytes BETWEEN 1 AND 5242880"),
     chk("policy_bundle", "published", "published_at IS NULL OR (test_passed AND signature IS NOT NULL AND signing_key_ref IS NOT NULL AND valid_until IS NOT NULL)"),
     chk("policy_bundle", "valid", "valid_until IS NULL OR (published_at IS NOT NULL AND valid_until > published_at AND valid_until <= published_at + interval '240 minutes')")],
    idx=[f"CREATE INDEX ix_policy_bundle_published ON {S}.policy_bundle (tenant_id, published_at DESC) WHERE published_at IS NOT NULL;"],
    trig=[("immutable", ["bundle_no", "content_hash", "object_ref"])], tid=True))

G_PURPOSE.append(T("usage_counter",
    "EN-09-20 Bộ đếm khai thác theo (HTTT, mục đích, hợp đồng, phút) do điểm thực thi báo (FR-09-019, 020, BR-09-020). Cập nhật cộng dồn (upsert); phân vùng tháng theo bucket_at; giữ 13 tháng. Không chứa giá trị dữ liệu.",
    ["bucket_at timestamptz NOT NULL", "httt_id varchar(63) NOT NULL", "purpose_code varchar(41) NOT NULL", "contract_kind varchar(8) NOT NULL", "contract_id varchar(128) NOT NULL",
     "reporter varchar(64) NOT NULL", "allowed_count integer NOT NULL DEFAULT 0", "denied_count integer NOT NULL DEFAULT 0", "off_purpose_count integer NOT NULL DEFAULT 0",
     "updated_at timestamptz NOT NULL DEFAULT now()"],
    [("uq_usage_counter_key", "UNIQUE (tenant_id, httt_id, purpose_code, contract_kind, contract_id, reporter, bucket_at)"),
     chk("usage_counter", "kind", f"contract_kind IN {E('ContractKind')}"),
     chk("usage_counter", "minute", "bucket_at = date_trunc('minute', bucket_at)"),
     chk("usage_counter", "counts", "allowed_count >= 0 AND denied_count >= 0 AND off_purpose_count >= 0")],
    idx=[f"CREATE INDEX ix_usage_counter_purpose ON {S}.usage_counter (tenant_id, purpose_code, bucket_at DESC);"],
    part=("bucket_at", "month", 3), pk=("id", "bucket_at"), std=False,
    ccomment={"reporter": "Điểm thực thi báo số đếm (APISIX, PH-04, PH-06, PH-14, PH-19)."}))

G_PURPOSE.append(T("usage_anomaly",
    "EN-09-21 Cảnh báo khai thác bất thường (FR-09-020, THR-51): AnomalyType, mức RiskLevel, trạng thái AnomalyStatus; phát hiện trong 5 phút (BR-09-020). Xử lý phải có người và thời điểm.",
    ["anomaly_type varchar(16) NOT NULL", "severity varchar(8) NOT NULL", "status varchar(16) NOT NULL DEFAULT 'OPEN'", "httt_id varchar(63) NOT NULL", "purpose_code varchar(41)",
     "contract_kind varchar(8)", "contract_id varchar(128)", "grant_id uuid", "detected_at timestamptz NOT NULL DEFAULT now()", "window_from timestamptz NOT NULL", "window_to timestamptz NOT NULL",
     "observed bigint NOT NULL", "threshold bigint", "handled_by varchar(64)", "handled_at timestamptz", "handle_note varchar(2000)"],
    [fk("usage_anomaly", "grant_id", "purpose_grant"),
     chk("usage_anomaly", "type", f"anomaly_type IN {E('AnomalyType')}"),
     chk("usage_anomaly", "severity", f"severity IN {E('RiskLevel')}"),
     chk("usage_anomaly", "status", f"status IN {E('AnomalyStatus')}"),
     chk("usage_anomaly", "kind", f"contract_kind IS NULL OR contract_kind IN {E('ContractKind')}"),
     chk("usage_anomaly", "window", "window_to >= window_from AND observed >= 0"),
     chk("usage_anomaly", "handled", "status = 'OPEN' OR (handled_by IS NOT NULL AND handled_at IS NOT NULL)")],
    idx=[f"CREATE INDEX ix_usage_anomaly_open ON {S}.usage_anomaly (tenant_id, severity, detected_at DESC) WHERE status = 'OPEN';",
         f"CREATE INDEX ix_usage_anomaly_httt ON {S}.usage_anomaly (tenant_id, httt_id, detected_at DESC);"]))

# ---------------------------------------------------------------------------------------------
# 09-0040 Chính sách che
# ---------------------------------------------------------------------------------------------
G_MASK = []
G_MASK.append(T("mask_type",
    "EN-09-22 Kiểu che MaskType và mẫu che MaskPatternKind có tham số (FR-09-023, BR-09-021, 024): NONE, PARTIAL (KEEP_*), REPLACE, KEYED_HASH, TOKENIZE, GENERALIZE (YEAR_ONLY, ADMIN_LEVEL), DROP. Nạp sẵn; tenant sửa tham số mặc định, thêm mẫu không đổi bộ kiểu.",
    ["code varchar(48) NOT NULL", "mask_type varchar(12) NOT NULL", "pattern_kind varchar(24)", "name varchar(255) NOT NULL", "default_params jsonb NOT NULL DEFAULT '{}'",
     "reversible boolean NOT NULL DEFAULT false", "builtin boolean NOT NULL DEFAULT false"],
    [("uq_mask_type_code", "UNIQUE (tenant_id, code)"),
     chk("mask_type", "type", f"mask_type IN {E('MaskType')}"),
     chk("mask_type", "pattern", f"pattern_kind IS NULL OR pattern_kind IN {E('MaskPatternKind')}"),
     chk("mask_type", "pairing", "(mask_type IN ('PARTIAL', 'GENERALIZE')) = (pattern_kind IS NOT NULL) AND (pattern_kind IS NULL OR (mask_type = 'PARTIAL') = (pattern_kind LIKE 'KEEP\\_%'))"),
     chk("mask_type", "reversible", "NOT reversible OR mask_type = 'TOKENIZE'")],
    trig=[("immutable", ["code", "mask_type", "pattern_kind"])], tid=True,
    ccomment={"default_params": "Tham số mặc định n, m, char, level (FR-09-023)."}))

_c, _i = ver("mask_policy", "policy_code")
G_MASK.append(T("mask_policy",
    "EN-09-23 Chính sách che theo phiên bản (FR-09-024, 026, BR-09-022, 023): phạm vi TENANT hoặc CONTRACT. Kích hoạt cần mô phỏng đạt (passed_simulation_id) và người duyệt khác người soạn (ADR-046). Quay lại bản cũ là tạo phiên bản mới.",
    ["policy_code varchar(63) NOT NULL"] + VER_COLS + ["scope varchar(8) NOT NULL DEFAULT 'TENANT'", "contract_kind varchar(8)", "contract_id varchar(128)", "description varchar(2000)", "passed_simulation_id uuid"],
    [chk("mask_policy", "code", "policy_code ~ '^[A-Za-z][A-Za-z0-9-]{2,62}$'"),
     chk("mask_policy", "scope", "scope IN ('TENANT', 'CONTRACT') AND ((scope = 'CONTRACT') = (contract_id IS NOT NULL AND contract_kind IS NOT NULL))"),
     chk("mask_policy", "kind", f"contract_kind IS NULL OR contract_kind IN {E('ContractKind')}"),
     chk("mask_policy", "simulated", "status NOT IN ('PENDING_APPROVAL', 'ACTIVE') OR passed_simulation_id IS NOT NULL")] + _c,
    idx=_i, tid=True,
    trig=[("immutable", ["policy_code", "version_no", "scope", "contract_id"]), ("frozen", ["passed_simulation_id"])]))

G_MASK.append(T("mask_rule",
    "EN-09-24 Quy tắc che trong chính sách (FR-09-024, BR-09-021, 022): điều kiện (mức, loại DLCN, vai trò, mục đích, kênh), kiểu che, tham số, độ ưu tiên; quy tắc cụ thể hơn thắng, trùng thì kiểu chặt hơn thắng. Mức SENSITIVE không được NONE. Chỉ sửa khi chính sách DRAFT hoặc REJECTED.",
    ["policy_id uuid NOT NULL", "seq smallint NOT NULL", "priority smallint NOT NULL DEFAULT 100", "cond_class varchar(16)", "cond_category varchar(32)", "cond_roles varchar(16)[]",
     "cond_purpose varchar(41)", "cond_channel varchar(8)", "mask_type varchar(12) NOT NULL", "pattern_kind varchar(24)", "params jsonb NOT NULL DEFAULT '{}'"],
    [fk("mask_rule", "policy_id", "mask_policy"),
     ("uq_mask_rule_seq", "UNIQUE (tenant_id, policy_id, seq)"),
     chk("mask_rule", "priority", "priority BETWEEN 1 AND 999"),
     chk("mask_rule", "class", f"cond_class IS NULL OR cond_class IN {E('DataClass')}"),
     chk("mask_rule", "channel", f"cond_channel IS NULL OR cond_channel IN {E('MaskChannel')}"),
     chk("mask_rule", "type", f"mask_type IN {E('MaskType')}"),
     chk("mask_rule", "pattern", f"pattern_kind IS NULL OR pattern_kind IN {E('MaskPatternKind')}"),
     chk("mask_rule", "pairing", "(mask_type IN ('PARTIAL', 'GENERALIZE')) = (pattern_kind IS NOT NULL)"),
     chk("mask_rule", "sensitive", "cond_class IS DISTINCT FROM 'SENSITIVE' OR mask_type <> 'NONE'")],
    idx=[f"CREATE INDEX ix_mask_rule_policy ON {S}.mask_rule (tenant_id, policy_id, priority DESC);"],
    trig=[("child_frozen", ["mask_policy", "policy_id"])],
    ccomment={"cond_roles": "Mã vai trò viết tắt (PA, TA, DS, VW...); rỗng là mọi vai trò."}))

G_MASK.append(T("mask_simulation",
    "EN-09-25 Lần mô phỏng chính sách che trên bộ mẫu dữ liệu giả ≤ 1.000 dòng (FR-09-025, NFR-09-023): bộ mẫu ở Garage, kết quả tóm tắt, passed. Không lưu giá trị mẫu trong bảng (BR-09-025).",
    ["policy_id uuid NOT NULL", "policy_version integer NOT NULL", "sample_ref varchar(512) NOT NULL", "sample_rows integer NOT NULL", "role varchar(16)", "purpose_code varchar(41)",
     "channel varchar(8)", "result jsonb NOT NULL DEFAULT '{}'", "passed boolean NOT NULL DEFAULT false", "run_by varchar(64) NOT NULL", "run_at timestamptz NOT NULL DEFAULT now()"],
    [fk("mask_simulation", "policy_id", "mask_policy"),
     chk("mask_simulation", "rows", "sample_rows BETWEEN 1 AND 1000"),
     chk("mask_simulation", "channel", f"channel IS NULL OR channel IN {E('MaskChannel')}")],
    idx=[f"CREATE INDEX ix_mask_simulation_policy ON {S}.mask_simulation (tenant_id, policy_id, run_at DESC);"],
    post=[f"ALTER TABLE {S}.mask_policy ADD CONSTRAINT fk_mask_policy_simulation FOREIGN KEY (tenant_id, passed_simulation_id) REFERENCES {S}.mask_simulation (tenant_id, id);"],
    tid=True, trig=[("immutable", ["policy_id", "policy_version", "sample_ref", "passed"])]))

G_MASK.append(T("reveal_grant",
    "EN-09-26 Phiếu xem giá trị đầy đủ (FR-09-029, BR-09-026): người xin, đối tượng, trường, lý do ≥ 20 ký tự, hết hạn đúng ≤ 60 giây, tối đa 20 lần mỗi giờ. Chỉ lưu băm phiếu; giá trị rõ không ghi đĩa; trường never_reveal bị chặn ở dịch vụ. Thao tác bị từ chối nếu không ghi được kiểm toán (BR-09-057).",
    ["requested_by varchar(64) NOT NULL", "target_ref varchar(255) NOT NULL", "fields varchar(63)[] NOT NULL", "reason varchar(2000) NOT NULL", "status varchar(8) NOT NULL DEFAULT 'ISSUED'",
     "issued_at timestamptz NOT NULL DEFAULT now()", "expires_at timestamptz NOT NULL", "verified_at timestamptz", "token_hash bytea NOT NULL"],
    [chk("reveal_grant", "reason", reason20()),
     chk("reveal_grant", "status", f"status IN {E('RevealStatus')}"),
     chk("reveal_grant", "ttl", "expires_at > issued_at AND expires_at <= issued_at + interval '60 seconds'"),
     chk("reveal_grant", "fields", "cardinality(fields) BETWEEN 1 AND 50"),
     chk("reveal_grant", "hash", "octet_length(token_hash) = 32"),
     chk("reveal_grant", "verified", "(status = 'VERIFIED') = (verified_at IS NOT NULL)")],
    idx=[f"CREATE INDEX ix_reveal_grant_user ON {S}.reveal_grant (tenant_id, requested_by, issued_at DESC);"],
    trig=[("immutable", ["requested_by", "target_ref", "fields", "reason", "issued_at", "expires_at", "token_hash"])]))

G_MASK.append(T("log_mask_config",
    "EN-09-27 Cấu hình che log, trace (FR-09-030, SEC-32): danh sách thuộc tính được phép, mẫu quét, cửa sổ quét. Một dòng mỗi tenant.",
    ["allow_attributes varchar(63)[] NOT NULL DEFAULT '{}'", "patterns varchar(24)[] NOT NULL", "scan_window_hours smallint NOT NULL DEFAULT 24"],
    [("uq_log_mask_config_tenant", "UNIQUE (tenant_id)"),
     chk("log_mask_config", "patterns", f"cardinality(patterns) >= 1 AND {arr_in('patterns', 'DetectorType')}"),
     chk("log_mask_config", "window", "scan_window_hours BETWEEN 1 AND 168")]))

G_MASK.append(T("leak_finding",
    "EN-09-28 Kết quả quét rò rỉ DLCN trong log, trace (FR-09-030, NFR-09-014): nguồn, mẫu khớp, số lần, dấu vân HMAC của vị trí. Không lưu đoạn log khớp. Trạng thái FindingStatus.",
    ["source varchar(128) NOT NULL", "detector_code varchar(24) NOT NULL", "match_count integer NOT NULL", "fingerprint bytea NOT NULL", "first_seen_at timestamptz NOT NULL",
     "last_seen_at timestamptz NOT NULL", "status varchar(16) NOT NULL DEFAULT 'OPEN'", "resolved_by varchar(64)", "resolved_at timestamptz"],
    [("uq_leak_finding_fp", "UNIQUE (tenant_id, source, detector_code, fingerprint)"),
     chk("leak_finding", "detector", f"detector_code IN {E('DetectorType')}"),
     chk("leak_finding", "status", f"status IN {E('FindingStatus')}"),
     chk("leak_finding", "count", "match_count >= 1 AND last_seen_at >= first_seen_at AND octet_length(fingerprint) = 32"),
     chk("leak_finding", "resolved", "status = 'OPEN' OR (resolved_by IS NOT NULL AND resolved_at IS NOT NULL)")],
    idx=[f"CREATE INDEX ix_leak_finding_open ON {S}.leak_finding (tenant_id, last_seen_at DESC) WHERE status = 'OPEN';"]))

# ---------------------------------------------------------------------------------------------
# 09-0050 Giả danh hóa, ẩn danh hóa
# ---------------------------------------------------------------------------------------------
G_PSEUDO = []
G_PSEUDO.append(T("pseudonym_domain",
    "EN-09-29 Miền giả danh hóa theo tenant và mục đích (FR-09-031, BR-09-028, 031): phương pháp PseudonymMethod, chu kỳ xoay 90 đến 730 ngày, trạng thái. Khóa riêng mỗi miền nên hai tập cho hai mục đích không nối được. Không có bảng ánh xạ bí danh (BR-09-030).",
    ["domain_code varchar(41) NOT NULL", "purpose_code varchar(41) NOT NULL", "method varchar(16) NOT NULL", "rotate_days smallint NOT NULL DEFAULT 365", "description varchar(2000)",
     "status varchar(12) NOT NULL DEFAULT 'ACTIVE'", "key_name varchar(128) NOT NULL", "current_key_version integer NOT NULL DEFAULT 1", "last_rotated_at timestamptz"],
    [("uq_pseudonym_domain_code", "UNIQUE (tenant_id, domain_code)"),
     ("fk_pseudonym_domain_purpose", f"FOREIGN KEY (tenant_id, purpose_code) REFERENCES {S}.purpose (tenant_id, code)"),
     chk("pseudonym_domain", "code", f"domain_code ~ '{CODE41}'"),
     chk("pseudonym_domain", "method", f"method IN {E('PseudonymMethod')}"),
     chk("pseudonym_domain", "rotate", "rotate_days BETWEEN 90 AND 730"),
     chk("pseudonym_domain", "status", f"status IN {E('PseudonymDomainStatus')}"),
     chk("pseudonym_domain", "version", "current_key_version >= 1")],
    trig=[("immutable", ["domain_code", "purpose_code", "method", "key_name"])], tid=True,
    ccomment={"key_name": "Tên khóa transit OpenBao dh-{tenant}-pseudo-{miền}; không chứa vật liệu khóa."}))

G_PSEUDO.append(T("pseudonym_key",
    "EN-09-30 Siêu dữ liệu phiên bản khóa giả danh hóa (FR-09-034, BR-09-029, 033): ACTIVE, DECRYPT_ONLY, DISABLED, DESTROYED. Không chứa vật liệu khóa. Hủy cần hai người duyệt khác nhau và chờ ≥ 7 ngày; mỗi miền một phiên bản ACTIVE.",
    ["domain_id uuid NOT NULL", "key_version integer NOT NULL", "status varchar(12) NOT NULL DEFAULT 'ACTIVE'", "openbao_ref varchar(255) NOT NULL", "activated_at timestamptz NOT NULL DEFAULT now()",
     "disabled_at timestamptz", "destroy_requested_by varchar(64)", "destroy_approved_by varchar(64)", "destroy_not_before timestamptz", "destroyed_at timestamptz", "reason varchar(2000)"],
    [fk("pseudonym_key", "domain_id", "pseudonym_domain"),
     ("uq_pseudonym_key_version", "UNIQUE (tenant_id, domain_id, key_version)"),
     chk("pseudonym_key", "version", "key_version >= 1"),
     chk("pseudonym_key", "status", f"status IN {E('KeyVersionStatus')}"),
     chk("pseudonym_key", "ref", "openbao_ref ~ '^transit/keys/[a-z0-9-]+$'"),
     chk("pseudonym_key", "destroyed",
         "status <> 'DESTROYED' OR (destroyed_at IS NOT NULL AND destroy_requested_by IS NOT NULL AND destroy_approved_by IS NOT NULL AND destroy_approved_by <> destroy_requested_by "
         "AND destroy_not_before IS NOT NULL AND destroyed_at >= destroy_not_before)"),
     chk("pseudonym_key", "disabled", "status NOT IN ('DISABLED', 'DESTROYED') OR disabled_at IS NOT NULL")],
    idx=[f"CREATE UNIQUE INDEX uq_pseudonym_key_active ON {S}.pseudonym_key (tenant_id, domain_id) WHERE status = 'ACTIVE';"],
    trig=[("immutable", ["domain_id", "key_version", "openbao_ref"])], tid=True))

G_PSEUDO.append(T("reidentification_request",
    "EN-09-31 Đề nghị khôi phục giá trị gốc từ token (FR-09-033, BR-09-032, 057): ≤ 100 giá trị, mục đích, căn cứ, MFA, hai cấp duyệt khác nhau và khác người đề nghị, hạn duyệt 24 giờ, cửa sổ thực hiện 30 phút. Không lưu token hay giá trị, chỉ số lượng và băm danh sách. Kiểm toán WORM vĩnh viễn.",
    ["domain_id uuid NOT NULL", "token_count smallint NOT NULL", "tokens_digest bytea NOT NULL", "purpose_code varchar(41) NOT NULL", "basis varchar(500) NOT NULL", "reason varchar(2000) NOT NULL",
     "status varchar(12) NOT NULL DEFAULT 'PENDING_L1'", "requested_by varchar(64) NOT NULL", "mfa_verified boolean NOT NULL DEFAULT false", "l1_by varchar(64)", "l1_at timestamptz",
     "l2_by varchar(64)", "l2_at timestamptz", "approval_expires_at timestamptz NOT NULL", "exec_deadline_at timestamptz", "executed_by varchar(64)", "executed_at timestamptz", "reject_reason varchar(2000)"],
    [fk("reidentification_request", "domain_id", "pseudonym_domain"),
     ("fk_reidentification_request_purpose", f"FOREIGN KEY (tenant_id, purpose_code) REFERENCES {S}.purpose (tenant_id, code)"),
     chk("reidentification_request", "count", "token_count BETWEEN 1 AND 100 AND octet_length(tokens_digest) = 32"),
     chk("reidentification_request", "reason", reason20()),
     chk("reidentification_request", "status", f"status IN {E('ReidStatus')}"),
     chk("reidentification_request", "l1", "l1_by IS NULL OR (l1_by <> requested_by AND l1_at IS NOT NULL)"),
     chk("reidentification_request", "l2", "l2_by IS NULL OR (l1_by IS NOT NULL AND l2_by <> l1_by AND l2_by <> requested_by AND l2_at IS NOT NULL)"),
     chk("reidentification_request", "approved", "status NOT IN ('APPROVED', 'EXECUTED') OR (l1_by IS NOT NULL AND l2_by IS NOT NULL AND mfa_verified AND exec_deadline_at IS NOT NULL)"),
     chk("reidentification_request", "executed", "status <> 'EXECUTED' OR (executed_by IS NOT NULL AND executed_at IS NOT NULL AND executed_at <= exec_deadline_at)"),
     chk("reidentification_request", "rejected", "status <> 'REJECTED' OR reject_reason IS NOT NULL")],
    idx=[f"CREATE INDEX ix_reidentification_request_open ON {S}.reidentification_request (tenant_id, status, created_at DESC) WHERE status IN ('PENDING_L1', 'PENDING_L2', 'APPROVED');"],
    trig=[("immutable", ["domain_id", "token_count", "tokens_digest", "purpose_code", "basis", "requested_by"])],
    ccomment={"tokens_digest": "Băm SHA-256 danh sách token để đối chiếu khi thực hiện; không lưu token."}))

_c, _i = ver("anonymization_config", "config_code")
G_PSEUDO.append(T("anonymization_config",
    "EN-09-32 Cấu hình ẩn danh hóa theo phiên bản (FR-09-035, BR-09-035, 036): k ≥ 10 (sàn 09.anon.k-min, SEC-38), l-đa dạng tùy chọn, quy tắc theo trường với AnonTransform, phân cấp tổng quát hóa, mục đích. Định danh trực tiếp bị loại, bán định danh được tổng quát hóa.",
    ["config_code varchar(41) NOT NULL"] + VER_COLS + ["privacy_model varchar(16) NOT NULL DEFAULT 'K_ANONYMITY'", "k smallint NOT NULL DEFAULT 10", "l smallint", "rules jsonb NOT NULL",
     "hierarchies jsonb NOT NULL DEFAULT '{}'", "purpose_code varchar(41) NOT NULL"],
    [chk("anonymization_config", "code", f"config_code ~ '{CODE41}'"),
     ("fk_anonymization_config_purpose", f"FOREIGN KEY (tenant_id, purpose_code) REFERENCES {S}.purpose (tenant_id, code)"),
     chk("anonymization_config", "model", f"privacy_model IN {E('PrivacyModel')}"),
     chk("anonymization_config", "k", "k BETWEEN 10 AND 100"),
     chk("anonymization_config", "l", "(privacy_model = 'L_DIVERSITY') = (l IS NOT NULL) AND (l IS NULL OR l BETWEEN 2 AND k)"),
     chk("anonymization_config", "rules", "jsonb_typeof(rules) = 'array' AND jsonb_array_length(rules) BETWEEN 1 AND 200")] + _c,
    idx=_i, tid=True,
    trig=[("immutable", ["config_code", "version_no"]), ("frozen", ["privacy_model", "k", "l", "rules", "hierarchies", "purpose_code"])],
    ccomment={"rules": "Mảng {field, transform, params}; transform là AnonTransform (kiểm ở dịch vụ khi gửi duyệt)."}))

G_PSEUDO.append(T("anonymization_job",
    "EN-09-33 Job ẩn danh hóa (FR-09-036, 038, BR-09-034, 035): tập nguồn, cấu hình, trạng thái AnonJobStatus, số bản ghi trước và sau (còn ≥ 30%), k thực tế, tối đa 3 vòng tổng quát hóa. Không lưu ánh xạ, không giữ khóa giải. Tập ra ở Garage mã hóa SSE-C.",
    ["config_id uuid NOT NULL", "source_ref varchar(512) NOT NULL", "purpose_code varchar(41) NOT NULL", "target varchar(16)", "status varchar(24) NOT NULL DEFAULT 'QUEUED'",
     "requested_by varchar(64) NOT NULL", "rows_before bigint", "rows_after bigint", "k_actual smallint", "generalization_rounds smallint NOT NULL DEFAULT 0",
     "output_ref varchar(512)", "started_at timestamptz", "finished_at timestamptz", "error_code varchar(10)"],
    [fk("anonymization_job", "config_id", "anonymization_config"),
     ("fk_anonymization_job_purpose", f"FOREIGN KEY (tenant_id, purpose_code) REFERENCES {S}.purpose (tenant_id, code)"),
     chk("anonymization_job", "target", f"target IS NULL OR target IN {E('DataPrepTarget')}"),
     chk("anonymization_job", "status", f"status IN {E('AnonJobStatus')}"),
     chk("anonymization_job", "rows", "rows_before >= 0 AND rows_after >= 0 AND rows_after <= rows_before"),
     chk("anonymization_job", "keep", "rows_before IS NULL OR rows_before = 0 OR rows_after IS NULL OR rows_after * 10 >= rows_before * 3 OR status IN ('REJECTED_RISK', 'FAILED', 'CANCELLED', 'RUNNING', 'QUEUED')"),
     chk("anonymization_job", "rounds", "generalization_rounds BETWEEN 0 AND 3"),
     chk("anonymization_job", "k", "k_actual IS NULL OR k_actual >= 1"),
     chk("anonymization_job", "done", "status NOT IN ('COMPLETED') OR (k_actual >= 10 AND output_ref IS NOT NULL AND finished_at IS NOT NULL)"),
     chk("anonymization_job", "error", "error_code IS NULL OR error_code ~ '^ERR-09-[0-9]{3}$'")],
    idx=[f"CREATE INDEX ix_anonymization_job_status ON {S}.anonymization_job (tenant_id, status, created_at DESC);"], tid=True))

G_PSEUDO.append(T("risk_report",
    "EN-09-34 Báo cáo rủi ro tái định danh (FR-09-037, BR-09-035): mô hình RiskModel, kActual, tỷ lệ nhóm nhỏ, mức RiskLevel (MEDIUM từ 0,05, HIGH từ 0,10 mặc định), trường gây rủi ro, khuyến nghị. Mức MEDIUM cần SO duyệt trước khi phát hành.",
    ["job_id uuid", "dataset_ref varchar(512) NOT NULL", "risk_model varchar(12) NOT NULL", "quasi_identifiers varchar(63)[] NOT NULL", "k_actual smallint NOT NULL",
     "small_group_ratio numeric(6,5) NOT NULL", "risk_value numeric(6,5) NOT NULL", "level varchar(8) NOT NULL", "risk_fields varchar(63)[] NOT NULL DEFAULT '{}'",
     "recommendation varchar(2000)", "computed_at timestamptz NOT NULL DEFAULT now()", "approved_by varchar(64)", "approved_at timestamptz"],
    [fk("risk_report", "job_id", "anonymization_job"),
     chk("risk_report", "model", f"risk_model IN {E('RiskModel')}"),
     chk("risk_report", "level", f"level IN {E('RiskLevel')}"),
     chk("risk_report", "ratio", "small_group_ratio BETWEEN 0 AND 1 AND risk_value BETWEEN 0 AND 1 AND k_actual >= 1"),
     chk("risk_report", "approval", "(approved_by IS NULL) = (approved_at IS NULL)")],
    idx=[f"CREATE INDEX ix_risk_report_job ON {S}.risk_report (tenant_id, job_id, computed_at DESC);"], tid=True))

G_PSEUDO.append(T("anonymized_dataset",
    "EN-09-35 Tập đã ẩn danh (FR-09-038, 039, BR-09-034, 035, 037): vị trí lưu, mục đích, điều kiện sử dụng (mục đích được phép, bên nhận, cấm tái định danh), hạn dùng, DatasetStatus. PUBLISHED cần k ≥ 10, rủi ro không HIGH, MEDIUM thì có người duyệt.",
    ["job_id uuid NOT NULL", "risk_report_id uuid NOT NULL", "name varchar(255) NOT NULL", "storage_ref varchar(512) NOT NULL", "purpose_code varchar(41) NOT NULL", "target varchar(16) NOT NULL",
     "terms jsonb NOT NULL", "k_actual smallint NOT NULL", "risk_level varchar(8) NOT NULL", "approved_by varchar(64)", "status varchar(10) NOT NULL DEFAULT 'READY'",
     "expires_on date", "published_at timestamptz", "withdrawn_at timestamptz", "withdraw_reason varchar(2000)"],
    [fk("anonymized_dataset", "job_id", "anonymization_job"), fk("anonymized_dataset", "risk_report_id", "risk_report"),
     ("fk_anonymized_dataset_purpose", f"FOREIGN KEY (tenant_id, purpose_code) REFERENCES {S}.purpose (tenant_id, code)"),
     chk("anonymized_dataset", "target", f"target IN {E('DataPrepTarget')}"),
     chk("anonymized_dataset", "status", f"status IN {E('DatasetStatus')}"),
     chk("anonymized_dataset", "risk", f"risk_level IN {E('RiskLevel')}"),
     chk("anonymized_dataset", "terms", "jsonb_typeof(terms) = 'object'"),
     chk("anonymized_dataset", "published",
         "status <> 'PUBLISHED' OR (k_actual >= 10 AND risk_level <> 'HIGH' AND (risk_level <> 'MEDIUM' OR approved_by IS NOT NULL) AND published_at IS NOT NULL AND expires_on IS NOT NULL)"),
     chk("anonymized_dataset", "withdrawn", "status <> 'WITHDRAWN' OR (withdrawn_at IS NOT NULL AND withdraw_reason IS NOT NULL)")],
    idx=[f"CREATE INDEX ix_anonymized_dataset_status ON {S}.anonymized_dataset (tenant_id, status, expires_on);"], tid=True,
    trig=[("immutable", ["job_id", "storage_ref", "k_actual"])]))

# ---------------------------------------------------------------------------------------------
# 09-0060 Lưu giữ và xóa
# ---------------------------------------------------------------------------------------------
G_RET = []
_c, _i = ver("retention_schedule", "schedule_code")
G_RET.append(T("retention_schedule",
    "EN-09-36 Lịch lưu giữ theo phiên bản (FR-09-040, BR-09-038): mỗi dòng ở retention_schedule_line. ACTIVE không sửa; duyệt bốn mắt. Chính sách lưu giữ của chính PH-09 là lịch PH09-OWN nạp sẵn (chương 7 của tập CSDL).",
    ["schedule_code varchar(41) NOT NULL"] + VER_COLS + ["description varchar(2000)"],
    [chk("retention_schedule", "code", f"schedule_code ~ '{CODE41}'")] + _c, idx=_i, tid=True,
    trig=[("immutable", ["schedule_code", "version_no"])]))

G_RET.append(T("retention_schedule_line",
    "EN-09-53 Dòng lịch lưu giữ, bảng con của RetentionSchedule (FR-09-040): bảng hoặc loại dữ liệu, loại DLCN, số ngày lưu, hành động RetentionAction, người chịu trách nhiệm. Nhật ký kiểm toán WORM không thuộc lịch này (BR-09-038). Chỉ sửa khi lịch DRAFT hoặc REJECTED.",
    ["schedule_id uuid NOT NULL", "entity varchar(128) NOT NULL", "category varchar(32)", "retain_days integer NOT NULL", "action varchar(12) NOT NULL", "owner varchar(64) NOT NULL"],
    [fk("retention_schedule_line", "schedule_id", "retention_schedule"),
     chk("retention_schedule_line", "days", "retain_days BETWEEN 1 AND 36500"),
     chk("retention_schedule_line", "action", f"action IN {E('RetentionAction')}")],
    idx=[f"CREATE UNIQUE INDEX uq_retention_schedule_line ON {S}.retention_schedule_line (tenant_id, schedule_id, entity, COALESCE(category, '*'));"],
    tid=True, trig=[("child_frozen", ["retention_schedule", "schedule_id"])]))

G_RET.append(T("retention_task",
    "EN-09-37 Tác vụ xóa hoặc giả danh hóa khi hết hạn (FR-09-041, 044, NFR-09-018): phạm vi, số bản ghi quét, xử lý, bỏ qua do giữ pháp lý (kèm hold_ids), kết quả. Chạy lại không nhân bản (khóa schedule_id, line_id, run_date).",
    ["schedule_id uuid NOT NULL", "line_id uuid", "entity varchar(128) NOT NULL", "run_date date NOT NULL", "dry_run boolean NOT NULL DEFAULT false", "status varchar(12) NOT NULL DEFAULT 'QUEUED'",
     "requested_by varchar(64) NOT NULL", "started_at timestamptz", "finished_at timestamptz", "rows_scanned bigint NOT NULL DEFAULT 0", "rows_affected bigint NOT NULL DEFAULT 0",
     "rows_skipped_hold bigint NOT NULL DEFAULT 0", "hold_ids uuid[] NOT NULL DEFAULT '{}'", "skipped_reason varchar(2000)", "error_code varchar(10)"],
    [fk("retention_task", "schedule_id", "retention_schedule"), fk("retention_task", "line_id", "retention_schedule_line"),
     chk("retention_task", "status", f"status IN {E('RetentionTaskStatus')}"),
     chk("retention_task", "rows", "rows_scanned >= 0 AND rows_affected >= 0 AND rows_skipped_hold >= 0 AND rows_affected + rows_skipped_hold <= rows_scanned"),
     chk("retention_task", "hold", "rows_skipped_hold = 0 OR cardinality(hold_ids) >= 1"),
     chk("retention_task", "finished", "status NOT IN ('COMPLETED', 'FAILED', 'CANCELLED') OR finished_at IS NOT NULL"),
     chk("retention_task", "error", "error_code IS NULL OR error_code ~ '^ERR-09-[0-9]{3}$'")],
    idx=[f"CREATE UNIQUE INDEX uq_retention_task_run ON {S}.retention_task (tenant_id, schedule_id, COALESCE(line_id, '00000000-0000-0000-0000-000000000000'::uuid), run_date) WHERE NOT dry_run;",
         f"CREATE INDEX ix_retention_task_status ON {S}.retention_task (tenant_id, status, run_date DESC);"], tid=True))

G_RET.append(T("legal_hold",
    "EN-09-38 Giữ pháp lý, tạm hoãn xóa (FR-09-042, BR-09-039): phạm vi (băm chủ thể, bảng, khoảng thời gian), số văn bản, cơ quan, ngày rà soát, LegalHoldStatus. Chặn mọi tác vụ xóa liên quan (ERR-09-058). Gỡ do người có quyền, có kiểm toán.",
    ["scope jsonb NOT NULL", "basis_doc varchar(255) NOT NULL", "basis_date date NOT NULL", "authority varchar(255) NOT NULL", "review_on date NOT NULL", "status varchar(8) NOT NULL DEFAULT 'ACTIVE'",
     "placed_by varchar(64) NOT NULL", "released_by varchar(64)", "released_at timestamptz", "release_reason varchar(2000)"],
    [chk("legal_hold", "scope", "jsonb_typeof(scope) = 'object'"),
     chk("legal_hold", "status", f"status IN {E('LegalHoldStatus')}"),
     chk("legal_hold", "review", "review_on >= basis_date"),
     chk("legal_hold", "released", "(status = 'RELEASED') = (released_by IS NOT NULL AND released_at IS NOT NULL AND release_reason IS NOT NULL)")],
    idx=[f"CREATE INDEX ix_legal_hold_active ON {S}.legal_hold (tenant_id, review_on) WHERE status = 'ACTIVE';",
         f"CREATE INDEX ix_legal_hold_scope ON {S}.legal_hold USING gin (scope jsonb_path_ops) WHERE status = 'ACTIVE';"],
    trig=[("immutable", ["scope", "basis_doc", "basis_date", "authority", "placed_by"])], tid=True,
    ccomment={"scope": "{subjectHashes[], entities[], from, to}; chỉ băm chủ thể, không định danh rõ."}))

G_RET.append(T("tenant_shred_request",
    "EN-09-39 Đề nghị xóa mật mã tenant, hủy KEK dh-{tenant}-pii (FR-09-043, BR-09-041, 033): chỉ sau bàn giao dữ liệu theo PH-20, hai người duyệt khác nhau và khác người đề nghị, chờ ≥ 7 ngày, không hoàn tác. Một đề nghị đang mở mỗi tenant.",
    ["status varchar(10) NOT NULL DEFAULT 'REQUESTED'", "export_confirmed boolean NOT NULL DEFAULT false", "reason varchar(2000) NOT NULL", "requested_by varchar(64) NOT NULL",
     "approver_1 varchar(64)", "approver_2 varchar(64)", "approved_at timestamptz", "wait_until timestamptz", "executed_at timestamptz", "kek_destroy_ref varchar(255)",
     "cancelled_by varchar(64)", "cancelled_at timestamptz"],
    [chk("tenant_shred_request", "status", f"status IN {E('CryptoShredStatus')}"),
     chk("tenant_shred_request", "reason", reason20()),
     chk("tenant_shred_request", "approvers", "approver_1 IS NULL OR (approver_1 <> requested_by AND (approver_2 IS NULL OR (approver_2 <> approver_1 AND approver_2 <> requested_by)))"),
     chk("tenant_shred_request", "approved", "status NOT IN ('APPROVED', 'WAITING', 'EXECUTED') OR (export_confirmed AND approver_1 IS NOT NULL AND approver_2 IS NOT NULL AND approved_at IS NOT NULL AND wait_until >= approved_at + interval '7 days')"),
     chk("tenant_shred_request", "executed", "status <> 'EXECUTED' OR (executed_at IS NOT NULL AND executed_at >= wait_until AND kek_destroy_ref IS NOT NULL)"),
     chk("tenant_shred_request", "cancelled", "(status = 'CANCELLED') = (cancelled_by IS NOT NULL AND cancelled_at IS NOT NULL)")],
    idx=[f"CREATE UNIQUE INDEX uq_tenant_shred_request_open ON {S}.tenant_shred_request (tenant_id) WHERE status IN ('REQUESTED', 'APPROVED', 'WAITING');"],
    trig=[("immutable", ["requested_by", "reason"])]))

# ---------------------------------------------------------------------------------------------
# 09-0070 Quyền chủ thể và đồng ý
# ---------------------------------------------------------------------------------------------
G_DSR = []
G_DSR.append(T("subject_request",
    "EN-09-40 Yêu cầu của chủ thể dữ liệu (FR-09-045…050, BR-09-042…048, 061): loại DsrType, băm chủ thể HMAC theo khóa tenant, định danh và nội dung mã hóa envelope. Chưa xác minh thì không IN_PROGRESS (BR-09-042). Cờ overdue, cờ hạn chế xử lý; lưu 5 năm (BR-09-048); Idempotency-Key duy nhất.",
    ["request_type varchar(20) NOT NULL", "status varchar(12) NOT NULL DEFAULT 'RECEIVED'", "channel varchar(16) NOT NULL", "identifier_type varchar(24) NOT NULL", "subject_hash bytea NOT NULL",
     "identifier_enc bytea NOT NULL", "identifier_kid varchar(64) NOT NULL", "content_enc bytea NOT NULL", "content_kid varchar(64) NOT NULL", "idempotency_key varchar(64) NOT NULL",
     "received_at timestamptz NOT NULL DEFAULT now()", "due_at timestamptz NOT NULL", "overdue boolean NOT NULL DEFAULT false", "verified_at timestamptz", "assigned_to varchar(64)",
     "outcome varchar(10)", "refusal_basis varchar(500)", "response_ref varchar(512)", "responded_at timestamptz", "closed_at timestamptz", "reject_reason varchar(2000)",
     "restriction_active boolean NOT NULL DEFAULT false", "restriction_lifted_at timestamptz"],
    [("uq_subject_request_idem", "UNIQUE (tenant_id, idempotency_key)"),
     chk("subject_request", "type", f"request_type IN {E('DsrType')}"),
     chk("subject_request", "status", f"status IN {E('DsrStatus')}"),
     chk("subject_request", "channel", f"channel IN {E('DsrChannel')}"),
     chk("subject_request", "idtype", f"identifier_type IN {E('SubjectIdentifierType')}"),
     chk("subject_request", "hash", "octet_length(subject_hash) = 32"),
     chk("subject_request", "enc", "octet_length(identifier_enc) >= 29 AND octet_length(content_enc) >= 29"),
     chk("subject_request", "due", "due_at >= received_at"),
     chk("subject_request", "verified", "status NOT IN ('IN_PROGRESS', 'RESPONDED', 'CLOSED') OR verified_at IS NOT NULL"),
     chk("subject_request", "outcome", f"outcome IS NULL OR outcome IN {E('DsrOutcome')}"),
     chk("subject_request", "responded", "status NOT IN ('RESPONDED', 'CLOSED') OR (outcome IS NOT NULL AND responded_at IS NOT NULL)"),
     chk("subject_request", "refused", "outcome IS DISTINCT FROM 'REFUSED' OR refusal_basis IS NOT NULL"),
     chk("subject_request", "closed", "(status = 'CLOSED') = (closed_at IS NOT NULL)"),
     chk("subject_request", "rejected", "status <> 'REJECTED' OR reject_reason IS NOT NULL"),
     chk("subject_request", "restriction", "NOT restriction_active OR request_type = 'RESTRICT'")],
    idx=[f"CREATE INDEX ix_subject_request_inbox ON {S}.subject_request (tenant_id, status, due_at);",
         f"CREATE INDEX ix_subject_request_subject ON {S}.subject_request (tenant_id, subject_hash);",
         f"CREATE INDEX ix_subject_request_restricted ON {S}.subject_request (tenant_id, subject_hash) WHERE restriction_active;"],
    trig=[("immutable", ["request_type", "subject_hash", "received_at", "idempotency_key", "identifier_enc"])], tid=True,
    ccomment={"subject_hash": "HMAC-SHA256 số định danh đã chuẩn hóa, khóa theo tenant (BR-09-045); tra bản ghi của chủ thể ở PH-06, PH-19, PH-13, PH-14.",
              "identifier_enc": "Định danh rõ chỉ ở đây, mã hóa envelope (ADR-032).", "content_enc": "Nội dung yêu cầu ≤ 4.000 ký tự, mã hóa envelope.",
              "overdue": "Cờ, không phải trạng thái (FRS 4.5).", "due_at": "Ngày làm việc theo 09.dsr.sla-days (Q09-02)."}))

G_DSR.append(T("subject_verification",
    "EN-09-41 Kết quả xác minh danh tính chủ thể (FR-09-046, BR-09-042): phương pháp VerificationMethod, đạt hoặc không, bằng chứng chỉ lưu băm và tham chiếu Garage mã hóa. Người xác minh khác người nhận yêu cầu (kiểm ở dịch vụ).",
    ["request_id uuid NOT NULL", "method varchar(20) NOT NULL", "passed boolean NOT NULL", "evidence_hash bytea", "evidence_ref varchar(512)", "verified_by varchar(64) NOT NULL",
     "verified_at timestamptz NOT NULL DEFAULT now()"],
    [fk("subject_verification", "request_id", "subject_request"),
     chk("subject_verification", "method", f"method IN {E('VerificationMethod')}"),
     chk("subject_verification", "hash", "evidence_hash IS NULL OR octet_length(evidence_hash) = 32"),
     chk("subject_verification", "evidence", "NOT passed OR evidence_hash IS NOT NULL OR method IN ('VNEID', 'OTP')")],
    idx=[f"CREATE INDEX ix_subject_verification_request ON {S}.subject_verification (tenant_id, request_id, verified_at DESC);"], trig=[("immutable", ["request_id", "method", "passed"])]))

G_DSR.append(T("subject_task",
    "EN-09-42 Tác vụ chuyển cho PH-06, PH-19, PH-13, PH-14 hoặc bên kiểm soát (FR-09-047, 048, BR-09-044, 046): đích DsrTarget, hành động theo DsrType, DsrTaskStatus. Kết quả chỉ số lượng và tham chiếu, không giá trị. Dữ liệu đi qua chuyển cho bên kiểm soát.",
    ["request_id uuid NOT NULL", "target varchar(16) NOT NULL", "action varchar(20) NOT NULL", "status varchar(10) NOT NULL DEFAULT 'OPEN'", "assignee varchar(64)", "external_ref varchar(255)",
     "result jsonb", "refusal_reason varchar(2000)", "done_at timestamptz"],
    [fk("subject_task", "request_id", "subject_request"),
     chk("subject_task", "target", f"target IN {E('DsrTarget')}"),
     chk("subject_task", "action", f"action IN {E('DsrType')}"),
     chk("subject_task", "status", f"status IN {E('DsrTaskStatus')}"),
     chk("subject_task", "refused", "status <> 'REFUSED' OR refusal_reason IS NOT NULL"),
     chk("subject_task", "done", "status = 'OPEN' OR done_at IS NOT NULL")],
    idx=[f"CREATE INDEX ix_subject_task_request ON {S}.subject_task (tenant_id, request_id, status);",
         f"CREATE INDEX ix_subject_task_open ON {S}.subject_task (tenant_id, target, created_at) WHERE status = 'OPEN';"]))

_c, _i = ver("consent_template", "template_code")
G_DSR.append(T("consent_template",
    "EN-09-43 Mẫu sự đồng ý theo phiên bản (FR-09-052, BR-09-049): nội dung, mục đích, dữ liệu xử lý, hạn hiệu lực, cách rút. Nội dung bất biến khi ACTIVE. Đồng ý chỉ là cơ sở cho tiện ích không bắt buộc, không là điều kiện của thủ tục hành chính.",
    ["template_code varchar(41) NOT NULL"] + VER_COLS + ["purpose_code varchar(41) NOT NULL", "data_scope varchar(2000) NOT NULL", "body_text varchar(20000) NOT NULL", "valid_days integer", "withdrawal_guide varchar(2000) NOT NULL"],
    [chk("consent_template", "code", f"template_code ~ '{CODE41}'"),
     ("fk_consent_template_purpose", f"FOREIGN KEY (tenant_id, purpose_code) REFERENCES {S}.purpose (tenant_id, code)"),
     chk("consent_template", "valid", "valid_days IS NULL OR valid_days BETWEEN 1 AND 3650"),
     chk("consent_template", "body", "char_length(body_text) >= 20")] + _c,
    idx=_i, tid=True,
    trig=[("immutable", ["template_code", "version_no"]), ("frozen", ["purpose_code", "data_scope", "body_text", "valid_days", "withdrawal_guide"])]))

G_DSR.append(T("consent_record",
    "EN-09-44 Bản ghi đồng ý hoặc rút (FR-09-053, 054, BR-09-050, 051): băm chủ thể, mẫu và phiên bản, băm nội dung đã hiển thị, kênh, thời điểm, bằng chứng; rút ghi trên cùng dòng (withdrawn_*) và có hiệu lực trong 60 giây. Một đồng ý GIVEN mỗi (chủ thể, mẫu). Không xóa.",
    ["template_id uuid NOT NULL", "template_code varchar(41) NOT NULL", "template_version integer NOT NULL", "subject_hash bytea NOT NULL", "status varchar(10) NOT NULL DEFAULT 'GIVEN'",
     "channel varchar(10) NOT NULL", "text_hash bytea NOT NULL", "given_at timestamptz NOT NULL DEFAULT now()", "evidence jsonb NOT NULL DEFAULT '{}'", "recorded_by varchar(64) NOT NULL",
     "expires_at timestamptz", "withdrawn_at timestamptz", "withdrawn_channel varchar(10)", "withdrawn_by varchar(64)", "withdraw_evidence jsonb"],
    [fk("consent_record", "template_id", "consent_template"),
     chk("consent_record", "status", f"status IN {E('ConsentStatus')}"),
     chk("consent_record", "channel", f"channel IN {E('ConsentChannel')} AND (withdrawn_channel IS NULL OR withdrawn_channel IN {E('ConsentChannel')})"),
     chk("consent_record", "hash", "octet_length(subject_hash) = 32 AND octet_length(text_hash) = 32"),
     chk("consent_record", "withdrawn", "(status = 'WITHDRAWN') = (withdrawn_at IS NOT NULL AND withdrawn_channel IS NOT NULL AND withdrawn_by IS NOT NULL) AND (withdrawn_at IS NULL OR withdrawn_at >= given_at)"),
     chk("consent_record", "expired", "status <> 'EXPIRED' OR (expires_at IS NOT NULL AND expires_at <= now() + interval '1 minute')")],
    idx=[f"CREATE UNIQUE INDEX uq_consent_record_given ON {S}.consent_record (tenant_id, template_code, subject_hash) WHERE status = 'GIVEN';",
         f"CREATE INDEX ix_consent_record_subject ON {S}.consent_record (tenant_id, subject_hash, given_at DESC);"],
    trig=[("immutable", ["template_id", "template_code", "template_version", "subject_hash", "text_hash", "given_at", "channel", "recorded_by"])], tid=True,
    ccomment={"text_hash": "Băm nội dung mẫu đã hiển thị cho chủ thể (bằng chứng, BR-09-050)."}))

# ---------------------------------------------------------------------------------------------
# 09-0080 DPIA và vi phạm
# ---------------------------------------------------------------------------------------------
G_DPIA = []
_c, _i = ver("dpia_record", "dpia_code", status_expr=f"status IN {E('VersionStatus')[:-1]}, 'SUBMITTED_A05')")
G_DPIA.append(T("dpia_record",
    "EN-09-45 Hồ sơ đánh giá tác động xử lý DLCN theo phiên bản (FR-09-055…057, BR-09-052, 053): DpiaKind, hoạt động liên kết, rủi ro, biện pháp, hạn rà soát ≤ 12 tháng; trạng thái DpiaStatus gồm SUBMITTED_A05 khi đã gửi Cục A05. Nhắc trước 30 ngày.",
    ["dpia_code varchar(41) NOT NULL"] + VER_COLS + ["activity_id uuid NOT NULL", "dpia_kind varchar(16) NOT NULL", "description varchar(4000) NOT NULL", "risks jsonb NOT NULL", "measures jsonb NOT NULL",
     "review_on date NOT NULL", "submitted_a05_at timestamptz", "a05_ref varchar(128)"],
    [chk("dpia_record", "code", f"dpia_code ~ '{CODE41}'"),
     fk("dpia_record", "activity_id", "processing_activity"),
     chk("dpia_record", "kind", f"dpia_kind IN {E('DpiaKind')}"),
     chk("dpia_record", "risks", "jsonb_typeof(risks) = 'array' AND jsonb_array_length(risks) >= 1 AND jsonb_typeof(measures) = 'array' AND jsonb_array_length(measures) >= 1"),
     chk("dpia_record", "a05", "(status = 'SUBMITTED_A05') = (submitted_a05_at IS NOT NULL)")] + _c,
    idx=_i + [f"CREATE INDEX ix_dpia_record_review ON {S}.dpia_record (tenant_id, review_on) WHERE status IN ('ACTIVE', 'SUBMITTED_A05');"], tid=True,
    trig=[("immutable", ["dpia_code", "version_no", "activity_id"]), ("frozen", ["dpia_kind", "description", "risks", "measures", "review_on"])],
    ccomment={"status": "VersionStatus cộng SUBMITTED_A05 (Phụ lục A, DpiaStatus)."}))

G_DPIA.append(T("breach_case",
    "EN-09-46 Vụ việc vi phạm DLCN (FR-09-058…060, BR-09-054…056): BreachSource, BreachStatus, BreachSeverity, đồng hồ 72 giờ từ detected_at không dừng, hạn deadline_at cố định. Thông báo A05 hoặc căn cứ miễn trừ trước khi NOTIFIED trở đi; NOT_A_BREACH cần SO duyệt. Không chứa giá trị DLCN, chỉ số lượng, loại, băm.",
    ["detected_at timestamptz NOT NULL", "deadline_at timestamptz NOT NULL", "source varchar(16) NOT NULL", "description varchar(4000) NOT NULL", "data_types varchar(32)[] NOT NULL",
     "estimated_subjects integer", "incident_ref varchar(64)", "status varchar(12) NOT NULL DEFAULT 'REPORTED'", "severity varchar(8)", "reported_by varchar(64) NOT NULL",
     "assessed_by varchar(64)", "assessed_at timestamptz", "notified_a05_at timestamptz", "exempt_basis varchar(2000)", "not_breach_reason varchar(2000)", "not_breach_approved_by varchar(64)",
     "affected_ref varchar(512)", "affected_count integer", "lessons varchar(4000)", "closed_at timestamptz"],
    [chk("breach_case", "source", f"source IN {E('BreachSource')}"),
     chk("breach_case", "status", f"status IN {E('BreachStatus')}"),
     chk("breach_case", "severity", f"severity IS NULL OR severity IN {E('BreachSeverity')}"),
     chk("breach_case", "types", f"cardinality(data_types) >= 1 AND {arr_in('data_types', 'PersonalDataCategory')}"),
     chk("breach_case", "clock", "deadline_at = detected_at + interval '72 hours'"),
     chk("breach_case", "counts", "(estimated_subjects IS NULL OR estimated_subjects >= 0) AND (affected_count IS NULL OR affected_count >= 0)"),
     chk("breach_case", "assessed", "status IN ('REPORTED', 'ASSESSING') OR (assessed_by IS NOT NULL AND assessed_at IS NOT NULL)"),
     chk("breach_case", "notified", "status NOT IN ('NOTIFIED', 'REMEDIATING', 'CLOSED') OR notified_a05_at IS NOT NULL OR exempt_basis IS NOT NULL"),
     chk("breach_case", "not_breach", "status <> 'NOT_A_BREACH' OR (COALESCE(char_length(not_breach_reason) >= 20, false) AND not_breach_approved_by IS NOT NULL AND not_breach_approved_by <> assessed_by)"),
     chk("breach_case", "closed", "(status = 'CLOSED') = (closed_at IS NOT NULL)")],
    idx=[f"CREATE INDEX ix_breach_case_open ON {S}.breach_case (tenant_id, deadline_at) WHERE status NOT IN ('NOT_A_BREACH', 'CLOSED') AND notified_a05_at IS NULL;",
         f"CREATE INDEX ix_breach_case_detected ON {S}.breach_case (tenant_id, detected_at DESC);"],
    trig=[("immutable", ["detected_at", "deadline_at", "reported_by", "source"])], tid=True,
    ccomment={"affected_ref": "Danh sách băm chủ thể bị ảnh hưởng, tệp mã hóa ở Garage; không giữ định danh rõ (BR-09-056)."}))

G_DPIA.append(T("breach_notification",
    "EN-09-47 Thông báo vi phạm cho Cục A05, chủ thể hoặc bên kiểm soát (FR-09-059, BR-09-055): NotificationRecipient, nội dung không chứa DLCN, trạng thái NotificationStatus, bằng chứng gửi (băm và tham chiếu).",
    ["case_id uuid NOT NULL", "recipient varchar(12) NOT NULL", "status varchar(6) NOT NULL DEFAULT 'DRAFT'", "content varchar(20000) NOT NULL", "sent_at timestamptz", "sent_by varchar(64)",
     "evidence_ref varchar(512)", "evidence_hash bytea"],
    [fk("breach_notification", "case_id", "breach_case"),
     chk("breach_notification", "recipient", f"recipient IN {E('NotificationRecipient')}"),
     chk("breach_notification", "status", f"status IN {E('NotificationStatus')}"),
     chk("breach_notification", "sent", "(status = 'SENT') = (sent_at IS NOT NULL AND sent_by IS NOT NULL AND evidence_ref IS NOT NULL)"),
     chk("breach_notification", "hash", "evidence_hash IS NULL OR octet_length(evidence_hash) = 32")],
    idx=[f"CREATE INDEX ix_breach_notification_case ON {S}.breach_notification (tenant_id, case_id, recipient);"]))

G_DPIA.append(T("breach_action",
    "EN-09-48 Biện pháp khắc phục và bài học của vụ việc (FR-09-060): người phụ trách, hạn, kết quả; is_lesson phân biệt bài học với biện pháp. Hoàn thành ghi done_at.",
    ["case_id uuid NOT NULL", "is_lesson boolean NOT NULL DEFAULT false", "description varchar(2000) NOT NULL", "owner varchar(64) NOT NULL", "due_on date", "done_at timestamptz", "result varchar(2000)"],
    [fk("breach_action", "case_id", "breach_case"),
     chk("breach_action", "lesson", "NOT is_lesson OR (due_on IS NULL AND owner <> '')")],
    idx=[f"CREATE INDEX ix_breach_action_case ON {S}.breach_action (tenant_id, case_id);"]))

# ---------------------------------------------------------------------------------------------
# 09-0090 Giám sát, tham số, thông điệp
# ---------------------------------------------------------------------------------------------
G_OPS = []
G_OPS.append(T("privacy_audit_event",
    "EN-09-49 Chỉ mục kiểm toán thao tác bảo vệ dữ liệu (FR-09-061, BR-09-057, 058, NFR-09-013): ai, thao tác, đối tượng, API-09, kết quả; chuyển bản ghi đầy đủ sang PH-13 (forwarded_at). Không ghi giá trị SENSITIVE. Chỉ thêm; phân vùng tháng; 13 tháng trực tuyến, bản gốc ở WORM của PH-13.",
    ["occurred_at timestamptz NOT NULL DEFAULT now()", "actor varchar(64) NOT NULL", "action varchar(64) NOT NULL", "target_kind varchar(32) NOT NULL", "target_id varchar(128)",
     "api_code varchar(10)", "success boolean NOT NULL", "privileged boolean NOT NULL DEFAULT false", "details jsonb", "trace_id char(32) NOT NULL", "audit_ref varchar(64)", "forwarded_at timestamptz"],
    [chk("privacy_audit_event", "api", "api_code IS NULL OR api_code ~ '^API-09-[0-9]{3}$'"),
     chk("privacy_audit_event", "trace", "trace_id ~ '^[0-9a-f]{32}$'"),
     chk("privacy_audit_event", "no_value", "details IS NULL OR NOT (details ?| ARRAY['value', 'values', 'identifier', 'identifierValue', 'plaintext', 'token', 'tokens'])"),
     chk("privacy_audit_event", "forwarded", "forwarded_at IS NULL OR audit_ref IS NOT NULL")],
    idx=[f"CREATE INDEX ix_privacy_audit_event_actor ON {S}.privacy_audit_event (tenant_id, actor, occurred_at DESC);",
         f"CREATE INDEX ix_privacy_audit_event_target ON {S}.privacy_audit_event (tenant_id, target_kind, target_id, occurred_at DESC);",
         f"CREATE INDEX ix_privacy_audit_event_pending ON {S}.privacy_audit_event (tenant_id, occurred_at) WHERE forwarded_at IS NULL;"],
    part=("occurred_at", "month", 3), pk=("id", "occurred_at"), std=False, trig=[("append_only", [])]))

G_OPS.append(T("compliance_report",
    "EN-09-50 Báo cáo tuân thủ theo kỳ (FR-09-062, 063): kỳ, các mục, chỉ số, tệp (Garage) và băm. Lập tự động theo 09.report.schedule-cron hoặc theo yêu cầu.",
    ["period_from date NOT NULL", "period_to date NOT NULL", "sections varchar(32)[] NOT NULL", "report_format varchar(8) NOT NULL", "metrics jsonb NOT NULL", "file_ref varchar(512)",
     "file_sha256 char(64)", "generated_by varchar(64) NOT NULL"],
    [chk("compliance_report", "period", "period_to >= period_from"),
     chk("compliance_report", "format", "report_format IN ('PDF', 'XLSX', 'DOCX')"),
     chk("compliance_report", "sections", "cardinality(sections) >= 1"),
     chk("compliance_report", "sha", "file_sha256 IS NULL OR file_sha256 ~ '^[0-9a-f]{64}$'"),
     chk("compliance_report", "file", "(file_ref IS NULL) = (file_sha256 IS NULL)")],
    idx=[f"CREATE INDEX ix_compliance_report_period ON {S}.compliance_report (tenant_id, period_to DESC);"]))

_keys = ", ".join("'%s'" % k for k, _, _, _ in SETTINGS)
G_OPS.append(T("tenant_setting",
    "EN-09-51 Tham số 09.* của tenant (FR-09-064, FRS 8.2, BR-09-059): khóa, giá trị jsonb, sàn và trần do PA đặt, người sửa là updated_by. Miền hợp lệ kiểm ở dịch vụ (ERR-09-078); CHECK giữ danh sách khóa và buộc giá trị số nằm trong sàn, trần.",
    ["setting_key varchar(48) NOT NULL", "value jsonb NOT NULL", "floor_value jsonb", "ceiling_value jsonb"],
    [("uq_tenant_setting_key", "UNIQUE (tenant_id, setting_key)"),
     chk("tenant_setting", "key", f"setting_key IN ({_keys})"),
     chk("tenant_setting", "bounds", "jsonb_typeof(value) <> 'number' OR ((floor_value IS NULL OR value >= floor_value) AND (ceiling_value IS NULL OR value <= ceiling_value))")],
    trig=[("immutable", ["setting_key"])]))

OUTBOX = ", ".join("'%s'" % t for t in TOPICS)
G_OPS.append(T("outbox_event",
    "EN-09-54 Outbox (DD-11, ADR-042) cho EVT-09-01…32 và bản ghi kiểm toán gửi PH-13. Ghi cùng giao dịch với thay đổi; Debezium Outbox Event Router đọc WAL. Sự kiện không mang giá trị DLCN (BR-09-025): CHECK chặn khóa giá trị và định danh. Dọn sau 3 ngày.",
    ["event_id uuid NOT NULL", "tenant_id varchar(16) NOT NULL", "event_type varchar(128) NOT NULL", "topic varchar(249) NOT NULL", "aggregate_type varchar(64) NOT NULL",
     "aggregate_id varchar(255) NOT NULL", "partition_key varchar(255) NOT NULL", "payload jsonb NOT NULL", "trace_id char(32) NOT NULL", "occurred_at timestamptz NOT NULL DEFAULT now()"],
    [("pk_outbox_event", "PRIMARY KEY (event_id)"),
     chk("outbox_event", "tenant", f"tenant_id ~ '{TENANT_RE}'"),
     chk("outbox_event", "prefix", "split_part(topic, '.', 1) = lower(tenant_id)"),
     chk("outbox_event", "topic", f"substr(topic, length(split_part(topic, '.', 1)) + 2) IN ({OUTBOX})"),
     chk("outbox_event", "trace", "trace_id ~ '^[0-9a-f]{32}$'"),
     chk("outbox_event", "no_value", "NOT (payload ?| ARRAY['value', 'values', 'identifier', 'identifierValue', 'fullName', 'nationalId', 'phone', 'email', 'token', 'tokens', 'subjectIdentifier'])")],
    idx=[f"CREATE INDEX ix_outbox_event_occurred ON {S}.outbox_event (occurred_at);"], std=False, nopk=True))

G_OPS.append(T("inbox_event",
    "EN-09-55 Inbox chống xử lý trùng cho sự kiện PH-09 tiêu thụ (at-least-once): đổi phân loại từ PH-06 (FR-06-004), sự kiện đăng ký HTTT PH-02, báo lượt khai thác PH-14, sự cố PH-18. Khóa (consumer, event_id). Dọn sau 7 ngày.",
    ["tenant_id varchar(16) NOT NULL", "consumer varchar(64) NOT NULL", "event_id varchar(255) NOT NULL", "source_topic varchar(249) NOT NULL", "event_type varchar(255) NOT NULL",
     "received_at timestamptz NOT NULL DEFAULT now()", "processed_at timestamptz", "outcome varchar(2000)"],
    [("pk_inbox_event", "PRIMARY KEY (tenant_id, consumer, event_id)"),
     chk("inbox_event", "tenant", f"tenant_id ~ '{TENANT_RE}'"),
     chk("inbox_event", "consumer", "consumer ~ '^[A-Z][A-Za-z0-9]+$'"),
     chk("inbox_event", "prefix", "split_part(source_topic, '.', 1) = lower(tenant_id)")],
    idx=[f"CREATE INDEX ix_inbox_event_received ON {S}.inbox_event (received_at);"], std=False, nopk=True))

FILE_GROUPS = [
    ("09-0010-classification.sql", G_CLASS), ("09-0020-ropa.sql", G_ROPA), ("09-0030-purpose.sql", G_PURPOSE), ("09-0040-masking.sql", G_MASK),
    ("09-0050-pseudonym.sql", G_PSEUDO), ("09-0060-retention.sql", G_RET), ("09-0070-dsr-consent.sql", G_DSR), ("09-0080-dpia-breach.sql", G_DPIA),
    ("09-0090-ops.sql", G_OPS),
]

# ---------------------------------------------------------------------------------------------
# Dữ liệu nạp sẵn mỗi tenant (p_seed_tenant)
# ---------------------------------------------------------------------------------------------
SEED_CLASS = [("PUBLIC", 1, "Công khai", "FULL", "FULL", "false"), ("INTERNAL", 2, "Nội bộ", "FULL", "FULL", "false"),
              ("RESTRICTED", 3, "Hạn chế", "PARTIAL_MASK", "MASK_BY_ROLE", "false"), ("SENSITIVE", 4, "Nhạy cảm", "NO_VALUE", "MASK_DEFAULT", "true")]
# (mã, tên, loại, luật, mức mặc định, mẫu che, định danh)
SEED_CAT = [
    ("FULL_NAME", "Họ và tên", "BASIC", "CMP-LAW-05", "RESTRICTED", "KEEP_FIRST_TOKEN", "DIRECT"),
    ("DATE_OF_BIRTH", "Ngày tháng năm sinh", "BASIC", "CMP-LAW-05", "RESTRICTED", "YEAR_ONLY", "QUASI"),
    ("GENDER", "Giới tính", "BASIC", "CMP-LAW-05", "INTERNAL", None, "QUASI"),
    ("NATIONAL_ID", "Số định danh cá nhân", "BASIC", "CMP-LAW-05", "RESTRICTED", "KEEP_LAST_N", "DIRECT"),
    ("PHONE", "Số điện thoại", "BASIC", "CMP-LAW-05", "RESTRICTED", "KEEP_LAST_N", "DIRECT"),
    ("EMAIL", "Thư điện tử", "BASIC", "CMP-LAW-05", "RESTRICTED", "KEEP_DOMAIN", "DIRECT"),
    ("ADDRESS", "Địa chỉ", "BASIC", "CMP-LAW-05", "RESTRICTED", "ADMIN_LEVEL", "QUASI"),
    ("TAX_ID", "Mã số thuế cá nhân", "BASIC", "CMP-LAW-05", "RESTRICTED", "KEEP_LAST_N", "DIRECT"),
    ("SOCIAL_INSURANCE_ID", "Số bảo hiểm xã hội", "BASIC", "CMP-LAW-05", "RESTRICTED", "KEEP_LAST_N", "DIRECT"),
    ("HEALTH", "Tình trạng sức khỏe", "SENSITIVE", "CMP-LAW-05", "SENSITIVE", None, "SENSITIVE_ATTR"),
    ("BIOMETRIC", "Đặc điểm sinh trắc học", "SENSITIVE", "CMP-LAW-05", "SENSITIVE", None, "DIRECT"),
    ("GENETIC", "Dữ liệu di truyền", "SENSITIVE", "CMP-LAW-05", "SENSITIVE", None, "SENSITIVE_ATTR"),
    ("POLITICAL_RELIGIOUS", "Quan điểm chính trị, tôn giáo", "SENSITIVE", "CMP-LAW-05", "SENSITIVE", None, "SENSITIVE_ATTR"),
    ("CRIMINAL_RECORD", "Tiền án, tiền sự", "SENSITIVE", "CMP-LAW-05", "SENSITIVE", None, "SENSITIVE_ATTR"),
    ("FINANCIAL_ACCOUNT", "Tài khoản, thông tin tài chính", "SENSITIVE", "CMP-LAW-05", "SENSITIVE", "KEEP_LAST_N", "DIRECT"),
    ("LOCATION_TRACKING", "Vị trí, lịch sử di chuyển", "SENSITIVE", "CMP-LAW-05", "SENSITIVE", None, "SENSITIVE_ATTR"),
    ("MINOR", "Dữ liệu của trẻ em", "SENSITIVE", "CMP-LAW-05", "SENSITIVE", None, "SENSITIVE_ATTR"),
    ("ETHNICITY", "Nguồn gốc dân tộc, chủng tộc", "SENSITIVE", "CMP-LAW-05", "SENSITIVE", None, "SENSITIVE_ATTR"),
]
SEED_DET = [("NATIONAL_ID_12", "Số định danh 12 chữ số", r"^[0-9]{12}$", "true"), ("TAX_ID_10_13", "Mã số thuế 10 hoặc 13 chữ số", r"^[0-9]{10}(-[0-9]{3})?$", "true"),
            ("BANK_CARD_LUHN", "Số thẻ ngân hàng (Luhn)", r"^[0-9]{13,19}$", "true"), ("PHONE_VN", "Số điện thoại Việt Nam", r"^(\+84|0)[0-9]{9}$", "false"),
            ("EMAIL", "Thư điện tử", r"^[^@\s]+@[^@\s]+\.[^@\s]+$", "false"), ("SOCIAL_INSURANCE_10", "Số bảo hiểm xã hội 10 chữ số", r"^[0-9]{10}$", "true"),
            ("FIELD_NAME_HINT", "Gợi ý theo tên trường", "(?i)(cccd|cmnd|dienthoai|phone|email|diachi|hoten|ngaysinh|mst|bhxh|sdt)", "false")]
SEED_BASIS = [("CONSENT", "Sự đồng ý", "false", "Chỉ cho tiện ích không bắt buộc; không là điều kiện của thủ tục hành chính (BR-09-049)."),
              ("STATE_TASK", "Nhiệm vụ của cơ quan nhà nước", "false", "Cơ sở chính của cơ quan nhà nước (BR-09-009)."),
              ("LEGAL_OBLIGATION", "Nghĩa vụ pháp lý", "true", "Có điều khoản pháp luật quy định bắt buộc."),
              ("CONTRACT", "Thực hiện hợp đồng", "false", "Cần cho việc thực hiện hợp đồng với chủ thể."),
              ("VITAL_INTEREST", "Bảo vệ lợi ích sống còn", "false", "Bảo vệ tính mạng, sức khỏe của chủ thể hoặc người khác."),
              ("EMERGENCY_PUBLIC_INTEREST", "Tình huống khẩn cấp, lợi ích công cộng", "false", "Theo quyết định của cơ quan có thẩm quyền."),
              ("STATISTICS_RESEARCH", "Thống kê, nghiên cứu", "false", "Dữ liệu đã giả danh hóa hoặc ẩn danh hóa.")]
SEED_MASK = [("NONE", "NONE", None, "Giữ nguyên", "{}", "false"), ("PARTIAL.KEEP_FIRST_N", "PARTIAL", "KEEP_FIRST_N", "Giữ n ký tự đầu", '{"n": 3, "char": "*"}', "false"),
             ("PARTIAL.KEEP_LAST_N", "PARTIAL", "KEEP_LAST_N", "Giữ n ký tự cuối", '{"n": 4, "char": "*"}', "false"),
             ("PARTIAL.KEEP_FIRST_LAST", "PARTIAL", "KEEP_FIRST_LAST", "Giữ n ký tự đầu và m ký tự cuối", '{"n": 2, "m": 2, "char": "*"}', "false"),
             ("PARTIAL.KEEP_FIRST_TOKEN", "PARTIAL", "KEEP_FIRST_TOKEN", "Giữ từ đầu của họ tên", '{"char": "*"}', "false"),
             ("PARTIAL.KEEP_DOMAIN", "PARTIAL", "KEEP_DOMAIN", "Giữ tên miền thư điện tử", '{"char": "*"}', "false"),
             ("REPLACE", "REPLACE", None, "Thay bằng chuỗi cố định", '{"value": "[REDACTED]"}', "false"), ("KEYED_HASH", "KEYED_HASH", None, "Băm có khóa HMAC-SHA256", "{}", "false"),
             ("TOKENIZE", "TOKENIZE", None, "Token hóa đảo ngược qua transit", "{}", "true"),
             ("GENERALIZE.YEAR_ONLY", "GENERALIZE", "YEAR_ONLY", "Chỉ giữ năm", "{}", "false"), ("GENERALIZE.ADMIN_LEVEL", "GENERALIZE", "ADMIN_LEVEL", "Tổng quát hóa đến cấp hành chính", '{"level": "PROVINCE"}', "false"),
             ("DROP", "DROP", None, "Bỏ trường", "{}", "false")]
# Lịch lưu giữ của chính PH-09 (PH09-OWN): (thực thể, loại, ngày, hành động, người chịu trách nhiệm)
SEED_RET = [("subject_request", None, 1825, "ARCHIVE", "SO"), ("subject_verification", None, 1825, "ARCHIVE", "SO"), ("subject_task", None, 1825, "ARCHIVE", "SO"),
            ("consent_record", None, 1825, "ARCHIVE", "SO"), ("breach_case", None, 3650, "ARCHIVE", "SO"), ("breach_notification", None, 3650, "ARCHIVE", "SO"),
            ("reveal_grant", None, 365, "DELETE", "TA"), ("usage_counter", None, 400, "DELETE", "TA"), ("usage_anomaly", None, 730, "ARCHIVE", "SO"),
            ("scan_run", None, 365, "DELETE", "TA"), ("scan_finding", None, 365, "DELETE", "TA"), ("leak_finding", None, 365, "DELETE", "TA"),
            ("mask_simulation", None, 180, "DELETE", "TA"), ("privacy_audit_event", None, 395, "ARCHIVE", "SO"), ("policy_bundle", None, 90, "DELETE", "TA"),
            ("outbox_event", None, 3, "DELETE", "TA"), ("inbox_event", None, 7, "DELETE", "TA")]


def seed_sql():
    L = []
    L.append("  INSERT INTO ph09_privacy.data_class (id, tenant_id, code, rank, name, log_policy, display_policy, encrypt_at_app, created_by, updated_by)\n  SELECT md5('ph09-class:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.r, s.n, s.l, s.d, s.e, 'system:seed', 'system:seed'\n  FROM (VALUES "
             + ", ".join("('%s', %d, '%s', '%s', '%s', %s)" % x for x in SEED_CLASS) + ") AS s(c, r, n, l, d, e)\n  ON CONFLICT (tenant_id, code) DO NOTHING;")
    L.append("  INSERT INTO ph09_privacy.personal_data_category (id, tenant_id, code, name, personal_data_type, legal_ref, default_class, default_mask_pattern, identifiability, builtin, created_by, updated_by)\n  SELECT md5('ph09-cat:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.n, s.t, s.l, s.k, s.m, s.i, true, 'system:seed', 'system:seed'\n  FROM (VALUES "
             + ", ".join("('%s', '%s', '%s', '%s', '%s', %s, '%s')" % (c, n, t, l, k, ("'%s'" % m if m else "NULL::varchar"), i) for c, n, t, l, k, m, i in SEED_CAT)
             + ") AS s(c, n, t, l, k, m, i)\n  ON CONFLICT (tenant_id, code) DO NOTHING;")
    L.append("  INSERT INTO ph09_privacy.detector_rule (id, tenant_id, detector_code, name, pattern, has_checksum, builtin, created_by, updated_by)\n  SELECT md5('ph09-det:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.n, s.p, s.k, true, 'system:seed', 'system:seed'\n  FROM (VALUES "
             + ", ".join("('%s', '%s', '%s', %s)" % (c, n, p.replace("'", "''"), k) for c, n, p, k in SEED_DET) + ") AS s(c, n, p, k)\n  ON CONFLICT (tenant_id, detector_code) DO NOTHING;")
    L.append("  INSERT INTO ph09_privacy.legal_basis (id, tenant_id, code, basis_type, name, mandatory, rule, created_by, updated_by)\n  SELECT md5('ph09-basis:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.c, s.n, s.m, s.r, 'system:seed', 'system:seed'\n  FROM (VALUES "
             + ", ".join("('%s', '%s', %s, '%s')" % x for x in SEED_BASIS) + ") AS s(c, n, m, r)\n  ON CONFLICT (tenant_id, code) DO NOTHING;")
    L.append("  INSERT INTO ph09_privacy.mask_type (id, tenant_id, code, mask_type, pattern_kind, name, default_params, reversible, builtin, created_by, updated_by)\n  SELECT md5('ph09-mask:' || p_tenant || ':' || s.c)::uuid, p_tenant, s.c, s.t, s.p, s.n, s.d::jsonb, s.r, true, 'system:seed', 'system:seed'\n  FROM (VALUES "
             + ", ".join("('%s', '%s', %s, '%s', '%s', %s)" % (c, t, ("'%s'" % p if p else "NULL::varchar"), n, d, r) for c, t, p, n, d, r in SEED_MASK)
             + ") AS s(c, t, p, n, d, r)\n  ON CONFLICT (tenant_id, code) DO NOTHING;")
    L.append("  INSERT INTO ph09_privacy.tenant_setting (id, tenant_id, setting_key, value, floor_value, ceiling_value, created_by, updated_by)\n  SELECT md5('ph09-setting:' || p_tenant || ':' || s.k)::uuid, p_tenant, s.k, s.v::jsonb, s.lo::jsonb, s.hi::jsonb, 'system:seed', 'system:seed'\n  FROM (VALUES "
             + ", ".join("('%s', '%s', %s, %s)" % (k, v.replace("'", "''"), ("'%s'" % lo if lo is not None else "NULL::text"), ("'%s'" % hi if hi is not None else "NULL::text")) for k, v, lo, hi in SETTINGS)
             + ") AS s(k, v, lo, hi)\n  ON CONFLICT (tenant_id, setting_key) DO NOTHING;")
    L.append("  INSERT INTO ph09_privacy.log_mask_config (id, tenant_id, patterns, created_by, updated_by)\n  VALUES (md5('ph09-logmask:' || p_tenant)::uuid, p_tenant, ARRAY['NATIONAL_ID_12', 'PHONE_VN', 'BANK_CARD_LUHN', 'EMAIL'], 'system:seed', 'system:seed')\n  ON CONFLICT (tenant_id) DO NOTHING;")
    L.append("  -- Lịch lưu giữ của chính PH-09: tạo DRAFT, thêm dòng, rồi kích hoạt (người duyệt khác người soạn).\n"
             "  INSERT INTO ph09_privacy.retention_schedule (id, tenant_id, schedule_code, version_no, status, description, created_by, updated_by)\n"
             "  VALUES (md5('ph09-ret:' || p_tenant)::uuid, p_tenant, 'PH09-OWN', 1, 'DRAFT', 'Lịch lưu giữ của chính PH-09 (chương 7 D03-03-PH09)', 'system:seed', 'system:seed')\n  ON CONFLICT DO NOTHING;")
    L.append("  INSERT INTO ph09_privacy.retention_schedule_line (id, tenant_id, schedule_id, entity, category, retain_days, action, owner, created_by, updated_by)\n  SELECT md5('ph09-retline:' || p_tenant || ':' || s.e)::uuid, p_tenant, md5('ph09-ret:' || p_tenant)::uuid, s.e, s.c, s.d, s.a, s.o, 'system:seed', 'system:seed'\n  FROM (VALUES "
             + ", ".join("('%s', %s, %d, '%s', '%s')" % (e, ("'%s'" % c if c else "NULL::varchar"), d, a, o) for e, c, d, a, o in SEED_RET)
             + ") AS s(e, c, d, a, o)\n  WHERE EXISTS (SELECT 1 FROM ph09_privacy.retention_schedule WHERE id = md5('ph09-ret:' || p_tenant)::uuid AND status = 'DRAFT')\n  ON CONFLICT DO NOTHING;")
    L.append("  UPDATE ph09_privacy.retention_schedule SET status = 'ACTIVE', decided_by = 'system:policy', decided_at = now(), activated_at = now(), submitted_by = 'system:seed'\n  WHERE id = md5('ph09-ret:' || p_tenant)::uuid AND status = 'DRAFT';")
    return "\n".join(L)


HEAD = r"""-- =============================================================================
-- D03-03-PH09 · DDL schema ph09_privacy — PH-09 Quyền riêng tư (bảo vệ dữ liệu cá nhân)
-- Phiên bản 0.2 · 2026-11-26 · Dự thảo
-- TỆP SINH bởi tools/sinh_ddl.py từ danh mục bảng và Phụ lục A của D02-03-PH09; sửa ở đó rồi sinh lại.
--
-- Chạy độc lập (phát triển):  psql -v ON_ERROR_STOP=1 -U postgres -d ph09_test -f ph09_privacy.sql
-- Môi trường thật: Liquibase, changelog sinh bằng ../tools/gen_liquibase.py từ dấu
-- -- @file / -- @changeset / -- @rollback trong tệp này (không sửa tay changelog).
--
-- Nguồn chuẩn enum, tên trường: D02-03-PH09 phụ lục A. Định danh chủ thể chỉ ở dạng *_enc (envelope, OpenBao
-- transit, ADR-032) và *_hash (HMAC-SHA256 theo khóa tenant); không bảng ánh xạ bí danh (BR-09-030); sự kiện,
-- kiểm toán không mang giá trị DLCN (BR-09-025, 058). Đối tượng nghiệp vụ không xóa cứng: ph09_app bị thu hồi DELETE.
-- =============================================================================

\set ON_ERROR_STOP on

-- @file 09-0000-bootstrap.sql
-- @changeset ph09-0000-roles splitStatements:false context:bootstrap
DO $roles$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph09_owner') THEN
    CREATE ROLE ph09_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph09_app') THEN
    CREATE ROLE ph09_app NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph09_readonly') THEN
    CREATE ROLE ph09_readonly NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ph09_decide') THEN
    CREATE ROLE ph09_decide NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
  END IF;
END
$roles$;
-- @rollback -- Không xóa vai trò khi rollback.

-- @changeset ph09-0001-schema context:bootstrap
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE SCHEMA IF NOT EXISTS ph09_privacy AUTHORIZATION ph09_owner;
COMMENT ON SCHEMA ph09_privacy IS 'PH-09 Quyền riêng tư (dh-data, package vn.datahub.data.privacy): phân loại dữ liệu, sổ hoạt động xử lý, mục đích và chấp thuận, chính sách che, giả danh hóa và ẩn danh hóa, lưu giữ, quyền chủ thể, đồng ý, DPIA, vi phạm DLCN. Không lưu giá trị DLCN rõ, không bảng ánh xạ bí danh.';
GRANT USAGE ON SCHEMA ph09_privacy TO ph09_app, ph09_readonly, ph09_decide;
-- @rollback DROP SCHEMA IF EXISTS ph09_privacy CASCADE;

SET ROLE ph09_owner;

-- @changeset ph09-0002-session-tenant runAlways:true
SET app.tenant_id = 'PLATFORM';
-- @rollback -- Không cần.

-- @file 09-0001-functions.sql
-- @changeset ph09-0010-fn-touch splitStatements:false
CREATE OR REPLACE FUNCTION ph09_privacy.tg_touch() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  NEW.updated_at := now();
  IF NEW.version IS NOT DISTINCT FROM OLD.version THEN
    NEW.version := OLD.version + 1;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph09_privacy.tg_touch() IS 'Cập nhật updated_at, tăng version (khóa lạc quan, ETag).';
-- @rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_touch();

-- @changeset ph09-0011-fn-immutable splitStatements:false
CREATE OR REPLACE FUNCTION ph09_privacy.tg_immutable() RETURNS trigger
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
COMMENT ON FUNCTION ph09_privacy.tg_immutable() IS 'Chặn sửa các cột truyền qua tham số trigger: mã nghiệp vụ, khóa tham chiếu, bằng chứng đã chốt.';
-- @rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_immutable();

-- @changeset ph09-0012-fn-append-only splitStatements:false
CREATE OR REPLACE FUNCTION ph09_privacy.tg_append_only() RETURNS trigger
  LANGUAGE plpgsql AS $f$
BEGIN
  RAISE EXCEPTION 'Bảng % chỉ thêm, không sửa, xóa dòng (nhật ký kiểm toán)', TG_TABLE_NAME USING ERRCODE = '55000';
END
$f$;
COMMENT ON FUNCTION ph09_privacy.tg_append_only() IS 'Chặn UPDATE, DELETE dòng của bảng chỉ thêm (privacy_audit_event). Dọn bằng DETACH, DROP phân vùng dưới ph09_owner.';
-- @rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_append_only();

-- @changeset ph09-0013-fn-frozen splitStatements:false
-- Phiên bản ACTIVE hoặc SUPERSEDED bất biến nội dung (BR-09-011): chặn sửa cột nội dung (đối số).
CREATE OR REPLACE FUNCTION ph09_privacy.tg_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  c text;
BEGIN
  IF OLD.status IN ('ACTIVE', 'SUPERSEDED', 'SUBMITTED_A05') THEN
    FOREACH c IN ARRAY TG_ARGV LOOP
      IF (to_jsonb(NEW) -> c) IS DISTINCT FROM (to_jsonb(OLD) -> c) THEN
        RAISE EXCEPTION 'Phiên bản % không sửa được cột % (BR-09-011)', OLD.status, c USING ERRCODE = '55000';
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph09_privacy.tg_frozen() IS 'Hoạt động, chính sách che, lịch lưu giữ, mẫu đồng ý, DPIA, cấu hình ẩn danh đã ACTIVE không đổi nội dung; thay đổi cần phiên bản mới.';
-- @rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_frozen();

-- @changeset ph09-0014-fn-child-frozen splitStatements:false
-- Bảng con của đối tượng có phiên bản (liên kết, quy tắc che, dòng lịch lưu): chỉ ghi khi cha là DRAFT hoặc REJECTED.
-- Đối số: tên bảng cha, tên cột khóa ngoại tới cha.
CREATE OR REPLACE FUNCTION ph09_privacy.tg_child_frozen() RETURNS trigger
  LANGUAGE plpgsql AS $f$
DECLARE
  parent text := TG_ARGV[0];
  fkcol text := TG_ARGV[1];
  st text;
  rec jsonb;
BEGIN
  IF TG_OP = 'DELETE' THEN rec := to_jsonb(OLD); ELSE rec := to_jsonb(NEW); END IF;
  EXECUTE format('SELECT status FROM ph09_privacy.%I WHERE tenant_id = $1 AND id = $2::uuid', parent)
    INTO st USING rec ->> 'tenant_id', rec ->> fkcol;
  IF st IN ('ACTIVE', 'SUPERSEDED', 'PENDING_APPROVAL', 'RETIRED') THEN
    RAISE EXCEPTION 'Không sửa dòng con của % khi cha là % (BR-09-011)', parent, st USING ERRCODE = '55000';
  END IF;
  IF TG_OP = 'DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END
$f$;
COMMENT ON FUNCTION ph09_privacy.tg_child_frozen() IS 'Chặn thêm, sửa, xóa dòng con khi phiên bản cha đã gửi duyệt, ACTIVE, SUPERSEDED hoặc RETIRED (BR-09-011).';
-- @rollback DROP FUNCTION IF EXISTS ph09_privacy.tg_child_frozen();

-- @changeset ph09-0015-fn-class-rank splitStatements:false
CREATE OR REPLACE FUNCTION ph09_privacy.class_rank(p_class text) RETURNS smallint
  LANGUAGE sql IMMUTABLE PARALLEL SAFE AS $f$
  SELECT CASE p_class WHEN 'PUBLIC' THEN 1 WHEN 'INTERNAL' THEN 2 WHEN 'RESTRICTED' THEN 3 WHEN 'SENSITIVE' THEN 4 END::smallint
$f$;
COMMENT ON FUNCTION ph09_privacy.class_rank(text) IS 'Thứ hạng DataClass 1 đến 4 (DD-08) dùng trong CHECK hạ mức (BR-09-002).';
-- @rollback DROP FUNCTION IF EXISTS ph09_privacy.class_rank(text);

-- @changeset ph09-0016-fn-rls splitStatements:false
-- Một mẫu cho mọi bảng nghiệp vụ: chỉ thấy, ghi dòng của tenant phiên; tenant_id đúng dạng Tnn (không có dòng COMMON).
CREATE OR REPLACE PROCEDURE ph09_privacy.p_enable_rls(p_table regclass)
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
COMMENT ON PROCEDURE ph09_privacy.p_enable_rls(regclass) IS 'Bật FORCE RLS và 4 chính sách theo tenant (D03-10 §4, ADR-003, BR-09-060).';
-- @rollback DROP PROCEDURE IF EXISTS ph09_privacy.p_enable_rls(regclass);

-- @changeset ph09-0017-fn-partitions splitStatements:false
CREATE OR REPLACE PROCEDURE ph09_privacy.p_ensure_partitions(p_table regclass, p_from date, p_count integer)
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
COMMENT ON PROCEDURE ph09_privacy.p_ensure_partitions(regclass, date, integer) IS 'Tạo trước phân vùng tháng cho usage_counter, privacy_audit_event. PartitionMaintenanceJob gọi hằng ngày; dọn bằng DETACH, DROP dưới ph09_owner.';
-- @rollback DROP PROCEDURE IF EXISTS ph09_privacy.p_ensure_partitions(regclass, date, integer);

-- @changeset ph09-0018-fn-seed-tenant splitStatements:false
-- Khởi tạo tenant (PH-20): danh mục nạp sẵn, tham số 09.*, lịch lưu giữ của PH-09. Chạy lại không nhân bản.
CREATE OR REPLACE PROCEDURE ph09_privacy.p_seed_tenant(p_tenant text)
  LANGUAGE plpgsql AS $p$
BEGIN
  PERFORM set_config('app.tenant_id', p_tenant, true);
@@SEED@@
END
$p$;
COMMENT ON PROCEDURE ph09_privacy.p_seed_tenant(text) IS 'Gọi khi khởi tạo tenant: 4 mức, 18 loại DLCN, 7 mẫu phát hiện, 7 cơ sở pháp lý, 12 kiểu che, 36 tham số 09.*, cấu hình log, lịch lưu giữ PH09-OWN.';
-- @rollback DROP PROCEDURE IF EXISTS ph09_privacy.p_seed_tenant(text);
"""

STD_COLS = ["id uuid NOT NULL", "tenant_id varchar(16) NOT NULL"]
AUDIT_COLS = ["created_at timestamptz NOT NULL DEFAULT now()", "created_by varchar(64) NOT NULL", "updated_at timestamptz NOT NULL DEFAULT now()", "updated_by varchar(64) NOT NULL"]


def render_table(t, seq):
    n = t["name"]
    cols = []
    if t["std"] or t["part"] or not t["nopk"]:
        cols += STD_COLS
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
    if n not in ("outbox_event", "inbox_event"):
        cons.append((f"ck_{n}_tenant", f"CHECK (tenant_id ~ '{TENANT_RE}')"))
    cons += t["cons"]
    w = max(len(c.split()[0]) for c in cols)
    lines = [f"  {c.split()[0]:<{w}} {c[len(c.split()[0]) + 1:]}" for c in cols]
    for cn, cd in cons:
        lines.append(f"  CONSTRAINT {cn} {cd}")
    o = [f"-- @changeset ph09-{seq:04d}-{n.replace('_', '-')}", f"CREATE TABLE {S}.{n} (", ",\n".join(lines),
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
        elif kind == "child_frozen":
            o.append(f"CREATE TRIGGER tg_{n}_child_frozen BEFORE INSERT OR UPDATE OR DELETE ON {S}.{n} FOR EACH ROW EXECUTE FUNCTION {S}.tg_child_frozen({a});")
    if t.get("rls", True):
        o.append(f"CALL {S}.p_enable_rls('{S}.{n}');")
    q = lambda s: s.replace("'", "''")
    o.append(f"COMMENT ON TABLE {S}.{n} IS '{q(t['comment'])}';")
    for c, txt in t["cc"].items():
        o.append(f"COMMENT ON COLUMN {S}.{n}.{c} IS '{q(txt)}';")
    o += t["post"]
    o.append(f"-- @rollback DROP TABLE IF EXISTS {S}.{n} CASCADE;")
    return "\n".join(o)


# Bảng ứng dụng được xóa dòng (dữ liệu tạm, bảng con sửa khi DRAFT, dọn theo lịch lưu giữ); còn lại bị thu hồi DELETE
APP_DELETE = ["scan_finding", "scan_run", "mask_simulation", "leak_finding", "reveal_grant", "usage_counter", "purpose_element", "activity_link", "mask_rule",
              "retention_schedule_line", "grant_condition", "outbox_event", "inbox_event", "policy_bundle"]
# Bảng ghi sau khi chốt: ứng dụng không UPDATE (chỉ thêm)
DECIDE_SELECT = ["data_class", "data_element", "element_classification", "contract_level", "purpose", "purpose_element", "purpose_grant", "grant_condition", "mask_type", "mask_policy",
                 "mask_rule", "policy_bundle", "personal_data_category", "block_label", "legal_hold"]


def main():
    all_t = {t["name"]: t for _, g in FILE_GROUPS for t in g}
    for t in all_t.values():
        for cn, cd in t["cons"]:
            for m in re.finditer(r"REFERENCES %s\.(\w+) \(tenant_id, id\)" % S, cd):
                if not all_t[m.group(1)]["tid"]:
                    raise SystemExit(f"{t['name']} -> {m.group(1)} cần tid=True")
    out = [HEAD.replace("@@SEED@@", seed_sql())]
    seq = 100
    for fname, grp in FILE_GROUPS:
        out.append(f"\n-- @file {fname}")
        for t in grp:
            out.append(render_table(t, seq))
            out.append("")
            seq += 10
    revoke = ", ".join(f"{S}.{n}" for n in all_t if n not in APP_DELETE)
    out.append(f"""-- @file 09-0900-grants.sql
-- @changeset ph09-0990-grants runAlways:true
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA {S} TO ph09_app;
-- Đối tượng nghiệp vụ không xóa cứng (nhãn, phân loại, hoạt động, chấp thuận, chính sách, khóa, yêu cầu chủ thể, đồng ý, vi phạm): chỉ dọn bảng tạm, bảng con DRAFT, bảng theo lịch lưu giữ.
REVOKE DELETE ON {revoke} FROM ph09_app;
-- Nhật ký kiểm toán chỉ thêm: ứng dụng không UPDATE, DELETE (trigger là lớp chặn thứ hai); dọn bằng DETACH phân vùng dưới ph09_owner.
REVOKE UPDATE, DELETE ON {S}.privacy_audit_event FROM ph09_app;
REVOKE UPDATE ON {S}.outbox_event FROM ph09_app;
GRANT SELECT ON ALL TABLES IN SCHEMA {S} TO ph09_readonly;
-- Báo cáo không đọc cột mã hóa của phiếu yêu cầu chủ thể, nội dung thông báo vi phạm.
REVOKE SELECT ON {S}.subject_request, {S}.breach_notification, {S}.reveal_grant FROM ph09_readonly;
GRANT SELECT (id, tenant_id, request_type, status, channel, identifier_type, received_at, due_at, overdue, verified_at, assigned_to, outcome, responded_at, closed_at, restriction_active)
  ON {S}.subject_request TO ph09_readonly;
-- Vai data plane /privacy/v1 (quyết định mục đích, kế hoạch che): chỉ đọc chính sách và chỉ mục, ghi bộ đếm; không đọc định danh chủ thể, bằng chứng, hồ sơ vi phạm.
GRANT SELECT ON {", ".join(f"{S}.{n}" for n in DECIDE_SELECT)} TO ph09_decide;
GRANT SELECT (tenant_id, subject_hash, restriction_active) ON {S}.subject_request TO ph09_decide;
GRANT SELECT (tenant_id, subject_hash, template_code, status, expires_at) ON {S}.consent_record TO ph09_decide;
GRANT SELECT, INSERT, UPDATE ON {S}.usage_counter TO ph09_decide;
GRANT INSERT ON {S}.privacy_audit_event TO ph09_decide;
GRANT EXECUTE ON PROCEDURE {S}.p_ensure_partitions(regclass, date, integer) TO ph09_app;
GRANT EXECUTE ON PROCEDURE {S}.p_seed_tenant(text) TO ph09_app;
-- @rollback -- Không thu hồi tự động.

RESET ROLE;
""")
    open(os.path.join(ROOT, "ddl", "ph09_privacy.sql"), "w", encoding="utf-8").write("\n".join(out))
    print(f"{len(all_t)} bảng → ddl/ph09_privacy.sql")


if __name__ == "__main__":
    main()
