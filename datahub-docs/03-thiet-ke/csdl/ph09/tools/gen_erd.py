#!/usr/bin/env python3
"""Sinh sơ đồ thực thể quan hệ Mermaid (erDiagram) cho D03-03-PH09 chương 2 từ khóa ngoại trong ddl/ph09_privacy.sql.

Chạy từ thư mục csdl/ph09:  python3 tools/gen_erd.py [--write]
Khóa ngoại thật lấy từ DDL (FOREIGN KEY ... REFERENCES); quan hệ logic (không có khóa ngoại: tham chiếu theo mã hoặc
sang schema khác) ghi ở LOGIC bên dưới và vẽ nét đứt. Với --write thay đoạn giữa <!-- gen:erd:start --> và <!-- gen:erd:end -->
trong ../D03-03-PH09-csdl-quyen-rieng-tu.md.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(ROOT), "D03-03-PH09-csdl-quyen-rieng-tu.md")
sql = open(os.path.join(ROOT, "ddl", "ph09_privacy.sql"), encoding="utf-8").read()

GROUPS = [
    ("Phân loại dữ liệu và quét phát hiện", ["data_class", "block_label", "personal_data_category", "data_element", "element_classification", "classification_change", "detector_rule", "scan_run", "scan_finding", "contract_level"]),
    ("Sổ hoạt động xử lý, mục đích và chấp thuận", ["legal_document", "legal_basis", "processing_activity", "activity_link", "purpose", "purpose_element", "access_request", "purpose_grant", "grant_condition", "policy_bundle", "usage_counter", "usage_anomaly"]),
    ("Chính sách che, xem đầy đủ, log", ["mask_type", "mask_policy", "mask_rule", "mask_simulation", "reveal_grant", "log_mask_config", "leak_finding"]),
    ("Giả danh hóa và ẩn danh hóa", ["pseudonym_domain", "pseudonym_key", "reidentification_request", "anonymization_config", "anonymization_job", "risk_report", "anonymized_dataset"]),
    ("Lưu giữ, quyền chủ thể, đồng ý", ["retention_schedule", "retention_schedule_line", "retention_task", "legal_hold", "tenant_shred_request", "subject_request", "subject_verification", "subject_task", "consent_template", "consent_record"]),
    ("Đánh giá tác động, vi phạm, giám sát", ["dpia_record", "breach_case", "breach_notification", "breach_action", "privacy_audit_event", "compliance_report", "tenant_setting", "outbox_event", "inbox_event"]),
]
# (cha, con, nhãn): tham chiếu logic, vẽ nét đứt
LOGIC = [("data_element", "contract_level", "logic, contract_id"), ("data_element", "block_label", "logic, target_id"), ("data_element", "activity_link", "logic, target_id"),
         ("purpose_grant", "usage_counter", "logic, bộ ba HTTT, mục đích, hợp đồng"), ("purpose", "usage_counter", "logic, purpose_code"),
         ("legal_hold", "retention_task", "logic, hold_ids"), ("subject_request", "legal_hold", "logic, băm chủ thể"),
         ("subject_request", "consent_record", "logic, subject_hash"), ("breach_case", "privacy_audit_event", "logic, target_id"),
         ("policy_bundle", "purpose_grant", "logic, bundle chứa chấp thuận")]

fks = []
for m in re.finditer(r"CREATE TABLE ph09_privacy\.(\w+) \((.*?)\n\)", sql, re.S):
    t, body = m.group(1), m.group(2)
    for col, tgt in re.findall(r"FOREIGN KEY \(tenant_id, (\w+)\) REFERENCES ph09_privacy\.(\w+)", body):
        nullable = not re.search(r"^\s+%s\s+\S+(?: \S+)*? NOT NULL" % col, body, re.M)
        fks.append((tgt, t, col, nullable))
for m in re.finditer(r"ALTER TABLE ph09_privacy\.(\w+) ADD CONSTRAINT \w+ FOREIGN KEY \(tenant_id, (\w+)\) REFERENCES ph09_privacy\.(\w+)", sql):
    fks.append((m.group(3), m.group(1), m.group(2), True))


def render():
    out = []
    for title, members in GROUPS:
        ms = set(members)
        L = ["Nhóm %s gồm %d bảng (%s). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic." % (title.lower(), len(members), ", ".join("`%s`" % m for m in members)), "",
             "```{.mermaid caption=\"ERD nhóm %s\"}" % title.lower(), "erDiagram"]
        used = set()
        seen = set()
        for p, c, col, nul in fks:
            if c in ms:
                key = (p, c, col)
                if key in seen:
                    continue
                seen.add(key)
                a = "|o" if nul else "||"
                L.append(f'  {p} {a}--o{{ {c} : "{col}"')
                used |= {p, c}
        for p, c, lab in LOGIC:
            if c in ms:
                L.append(f'  {p} ||..o{{ {c} : "{lab}"')
                used |= {p, c}
        alone = [m for m in members if m not in used]
        for a in alone:
            L.append(f"  {a} {{\n    uuid id PK\n    varchar tenant_id\n  }}")
        L.append("```")
        out.append("\n".join(L))
        out.append("")
    return "\n".join(out)


if __name__ == "__main__":
    md = render()
    if "--write" in sys.argv:
        doc = open(DOC, encoding="utf-8").read()
        doc, n = re.subn(r"(<!-- gen:erd:start -->\n).*?(<!-- gen:erd:end -->)", lambda m: m.group(1) + md + "\n" + m.group(2), doc, flags=re.S)
        open(DOC, "w", encoding="utf-8").write(doc)
        print("erd", "đã chèn" if n else "THIẾU cặp đánh dấu")
    else:
        sys.stdout.write(md)
