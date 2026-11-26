#!/usr/bin/env python3
"""Đối chiếu DDL ph06_mdm (và tài liệu D03-03-PH06) với D02-03-PH06 (FRS), Phụ lục A và mục 4.2, 7, 9.1.

Chạy từ thư mục csdl/ph06:  python3 tools/check_frs.py
Kiểm, in LỆCH khi sai, mã thoát 1 nếu có lệch:
  1. Mỗi enum Phụ lục A ánh xạ tới cột: tập giá trị CHECK trong DDL bằng đúng tập ở FRS (trừ ngoại lệ ghi rõ: tập con).
  2. Không có giá trị CHECK dạng UPPER_SNAKE nào trong DDL mà FRS không có (chống tự đặt enum).
  3. Mã ERR-06-nnn, BR-06-nnn, FR-06-nnn, EN-06-nn nhắc trong DDL, tài liệu đều có ở FRS; đủ 21 EN và 60 FR có mặt ở tài liệu.
  4. Mọi bảng có tenant_id (trừ shedlock) bật FORCE RLS; mọi bảng có COMMENT ON TABLE.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.dirname(os.path.dirname(os.path.dirname(ROOT)))
FRS = open(os.path.join(DOCS, "02-yeu-cau", "frs", "D02-03-PH06-frs-du-lieu-chu.md"), encoding="utf-8").read()
DOC_PATH = os.path.join(os.path.dirname(ROOT), "D03-03-PH06-csdl-du-lieu-chu.md")
DOC = open(DOC_PATH, encoding="utf-8").read() if os.path.exists(DOC_PATH) else ""
sql = open(os.path.join(ROOT, "ddl", "ph06_mdm.sql"), encoding="utf-8").read()
appx = FRS[FRS.index("## Phụ lục A."):FRS.index("## Phụ lục B.")]
problems = []


def enum_vals(name):
    m = re.search(r"^\| `%s` \| ([^|]+) \|" % name, appx, re.M)
    if not m:
        problems.append(f"Không có enum {name} ở Phụ lục A")
        return set()
    return set(re.findall(r"`([A-Z][A-Z0-9_]+)`", re.sub(r"\([^()]*\)", "", m.group(1))))


# (enum FRS, bảng, cột, giá trị được phép thiếu trong DDL)
E = [
    ("DomainStatus", "mdm_domain", "status", ()),
    ("VersionStatus", "domain_model", "status", ("TESTING",)),
    ("VersionStatus", "match_rule_set", "status", ()),
    ("VersionStatus", "survivorship_rule_set", "status", ("TESTING",)),
    ("VersionStatus", "source_priority_proposal", "status", ("TESTING", "DRAFT", "SUPERSEDED")),
    ("CompatLevel", "domain_model", "compat_level", ()),
    ("ApprovalDecision", "domain_model", "decision", ()),
    ("ApprovalDecision", "match_rule_set", "decision", ()),
    ("ApprovalDecision", "survivorship_rule_set", "decision", ()),
    ("ApprovalDecision", "steward_item", "approval_decision", ()),
    ("ApprovalDecision", "golden_operation", "decision", ()),
    ("AttributeType", "model_attribute", "attribute_type", ()),
    ("DataClass", "model_attribute", "data_class", ()),
    ("DataClass", "golden_attribute", "data_class", ()),
    ("DataClass", "attribute_lineage", "data_class", ()),
    ("ClassificationStatus", "model_attribute", "classification_status", ()),
    ("IdentifierType", "identifier_rule", "identifier_type", ()),
    ("IdentifierType", "candidate_record", "identifier_type", ()),
    ("IdentifierType", "golden_identifier", "identifier_type", ()),
    ("IdentifierType", "subject_request", "identifier_type", ()),
    ("IdentifierStatus", "candidate_record", "identifier_status", ()),
    ("SourceKind", "mdm_source", "source_kind", ()),
    ("SourceStatus", "mdm_source", "status", ()),
    ("IngestChannel", "mdm_source", "channels", ()),
    ("IngestChannel", "candidate_record", "channel", ()),
    ("CandidateOperation", "candidate_record", "operation", ()),
    ("CandidateStatus", "candidate_record", "status", ()),
    ("NormalizationWarning", "candidate_record", "warnings", ()),
    ("MatchOutcome", "candidate_record", "match_outcome", ()),
    ("MatchOutcome", "match_result", "outcome", ()),
    ("MatchRuleType", "match_rule", "rule_type", ()),
    ("Comparator", "match_rule", "comparator", ()),
    ("MatchMethod", "match_result", "method", ()),
    ("MatchMethod", "source_xref", "match_method", ()),
    ("JobType", "match_job", "job_type", ()),
    ("JobType", "job_schedule", "job_type", ()),
    ("JobStatus", "match_job", "status", ()),
    ("BatchScope", "match_job", "scope", ()),
    ("LabelSetPurpose", "label_set", "purpose", ()),
    ("PairLabel", "label_pair", "label", ()),
    ("EvaluationVerdict", "evaluation_report", "verdict", ()),
    ("QueueItemStatus", "steward_item", "status", ()),
    ("QueueReason", "steward_item", "reason", ()),
    ("StewardDecision", "steward_item", "decision", ()),
    ("RiskLevel", "steward_item", "risk_level", ()),
    ("RiskLevel", "golden_operation", "risk_level", ()),
    ("GoldenStatus", "golden_record", "status", ()),
    ("RetireReason", "golden_record", "retire_reason", ()),
    ("GoldenChangeType", "golden_operation", "change_type", ()),
    ("GoldenChangeType", "golden_history", "change_type", ()),
    ("GoldenChangeType", "source_correction", "origin", ("CREATE", "UPDATE", "MERGE", "SPLIT", "UNDO", "RETIRE", "RESTORE", "SURVIVORSHIP_REAPPLY", "XREF_DETACH")),
    ("OperationStatus", "golden_operation", "status", ()),
    ("SurvivorshipStrategy", "golden_attribute", "strategy", ()),
    ("SurvivorshipStrategy", "attribute_lineage", "strategy", ()),
    ("SurvivorshipStrategy", "survivorship_rule", "strategies", ()),
    ("XrefStatus", "source_xref", "status", ()),
    ("XrefDetachReason", "source_xref", "detach_reason", ()),
    ("SubscriptionScope", "update_subscription", "scope", ()),
    ("SubscriptionStatus", "update_subscription", "status", ()),
    ("ExportFormat", "export_request", "format", ()),
    ("ExportStatus", "export_request", "status", ()),
    ("SyncDirection", "national_sync_run", "direction", ()),
    ("SyncState", "national_sync_state", "state", ()),
    ("DiscrepancySeverity", "national_discrepancy", "severity", ()),
    ("DiscrepancyStatus", "national_discrepancy", "status", ()),
    ("DiscrepancyResolution", "national_discrepancy", "resolution", ()),
    ("DsrType", "subject_request", "request_type", ()),
    ("DsrStatus", "subject_request", "status", ()),
    ("RetentionAction", "retention_policy", "action", ()),
]
tables = {m.group(1): m.group(2) for m in re.finditer(r"CREATE TABLE ph06_mdm\.(\w+) \((.*?)\n\)( PARTITION BY [^;]+)?;", sql, re.S)}


def ddl_enum(table, col):
    body = tables[table]
    m = re.search(r"CHECK \((?:\w+ IS NULL OR )?(?:cardinality\(\w+\)[^()]*? AND )?%s (?:IN|<@ ARRAY)\s*[\(\[]([^\)\]]*)[\)\]]" % col, body)
    return set(re.findall(r"'([A-Z][A-Z0-9_]+)'", m.group(1))) if m else None


seen_cols = set()
for name, t, c, miss in E:
    seen_cols.add((t, c))
    want = enum_vals(name)
    got = ddl_enum(t, c)
    if got is None:
        problems.append(f"LỆCH enum: {t}.{c} không có CHECK theo {name}")
    elif got - want:
        problems.append(f"LỆCH enum {t}.{c}: DDL có giá trị không thuộc {name}: {sorted(got - want)}")
    elif want - got - set(miss):
        problems.append(f"LỆCH enum {t}.{c}: DDL thiếu {sorted(want - got - set(miss))} của {name}")
# 2. mọi giá trị UPPER_SNAKE trong CHECK phải có ở FRS (bất kỳ chỗ nào: enum hoặc danh sách đầu vào)
tokens = set(re.findall(r"[A-Z][A-Z0-9_]{2,}", FRS))
for t, body in tables.items():
    for ck in re.findall(r"CHECK \((.*?)\)(?:,\n|\n$)", body + "\n", re.S):
        for v in re.findall(r"'([A-Z][A-Z0-9_]{2,})'", ck):
            if v not in tokens and v not in ("INFO", "WARN", "ERROR"):  # mức nhật ký chuẩn, không phải enum nghiệp vụ
                problems.append(f"LỆCH: {t} có giá trị CHECK '{v}' không có ở FRS")
# 3. mã tham chiếu
frs_err = set(re.findall(r"^\| (ERR-06-\d{3}) \|", FRS, re.M))
frs_br = set(re.findall(r"^\| (BR-06-\d{3}) \|", FRS, re.M))
frs_en = set(re.findall(r"^\| (EN-06-\d{2}) \|", FRS, re.M))
frs_fr = set(re.findall(r"^\| (FR-06-\d{3}) \|", FRS, re.M))
for label, text in (("DDL", sql), ("tài liệu", DOC)):
    for e in sorted(set(re.findall(r"ERR-06-\d{3}", text)) - frs_err):
        problems.append(f"LỆCH {label}: {e} không có ở FRS 9.1")
    for e in sorted(set(re.findall(r"BR-06-\d{3}", text)) - frs_br):
        problems.append(f"LỆCH {label}: {e} không có ở FRS mục 7")
    for e in sorted(set(re.findall(r"EN-06-\d{2}", text)) - frs_en):
        problems.append(f"LỆCH {label}: {e} không có ở FRS 4.2")
    for e in sorted(set(re.findall(r"FR-06-\d{3}", text)) - frs_fr):
        problems.append(f"LỆCH {label}: {e} không có ở FRS mục 5")
if DOC:
    for e in sorted(frs_en - set(re.findall(r"EN-06-\d{2}", DOC))):
        problems.append(f"Tài liệu thiếu {e}")
    miss_fr = sorted(f for f in frs_fr if f not in DOC and f[-3:] not in " ".join(re.findall(r"(?<=FR-06-)\d{3}(?:(?:, |…|–)\d{3})*", DOC)))
    if miss_fr:
        problems.append("Tài liệu thiếu FR: " + ", ".join(miss_fr))
# 4. RLS, comment
for t, body in tables.items():
    if t == "shedlock":
        continue
    if not re.search(r"CALL ph06_mdm\.p_enable_rls\('ph06_mdm\.%s'\)" % t, sql):
        problems.append(f"LỆCH: {t} chưa bật RLS")
    if not re.search(r"COMMENT ON TABLE ph06_mdm\.%s IS" % t, sql):
        problems.append(f"LỆCH: {t} thiếu COMMENT ON TABLE")
    for c in ("tenant_id",):
        if not re.search(r"\b%s\b" % c, body):
            problems.append(f"LỆCH: {t} thiếu {c}")
n_enum = len(E)
print(f"{len(tables)} bảng; {n_enum} cột enum đối chiếu Phụ lục A; {len(frs_err)} ERR, {len(frs_br)} BR, {len(frs_en)} EN, {len(frs_fr)} FR ở FRS")
for p in problems:
    print(p)
print("Kết quả:", "LỆCH" if problems else "khớp")
sys.exit(1 if problems else 0)
