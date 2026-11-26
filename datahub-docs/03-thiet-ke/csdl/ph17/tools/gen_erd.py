#!/usr/bin/env python3
"""Sinh sơ đồ thực thể quan hệ Mermaid (erDiagram) cho D03-03-PH17 chương 2 từ khóa ngoại trong ddl/ph17_assist.sql.

Chạy từ thư mục csdl/ph17:  python3 tools/gen_erd.py [--write]
Khóa ngoại thật lấy từ DDL (FOREIGN KEY ... REFERENCES); quan hệ logic (không có khóa ngoại: tham chiếu theo mã hoặc
sang schema khác) ghi ở LOGIC bên dưới và vẽ nét đứt. Với --write thay đoạn giữa <!-- gen:erd:start --> và <!-- gen:erd:end -->
trong ../D03-03-PH17-csdl-tro-ly-ai.md.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(ROOT), "D03-03-PH17-csdl-tro-ly-ai.md")
sql = open(os.path.join(ROOT, "ddl", "ph17_assist.sql"), encoding="utf-8").read()

GROUPS = [
    ("Nền tảng, tệp, tham số và hộp thư", ["file_object", "tenant_setting", "outbox_event", "inbox_event"]),
    ("Chính sách, điều khoản và hạn mức", ["ai_notice", "notice_acceptance", "policy_change", "tenant_policy", "capability_policy", "quota_usage", "kill_switch_record"]),
    ("Nhà cung cấp, mô hình và tuyến", ["model_provider", "provider_commitment", "model", "model_version", "model_route", "route_sync_run", "tenant_model", "provider_grant", "invocation_log", "model_health_probe", "model_breaker"]),
    ("Kho tri thức và lập chỉ mục", ["knowledge_source", "knowledge_document", "knowledge_chunk", "index_job", "knowledge_deletion"]),
    ("Hội thoại, công cụ và gợi ý", ["conversation", "message", "citation", "tool_definition", "tool_call", "suggestion", "explanation", "suggested_question"]),
    ("Chặn an toàn, prompt, đánh giá và quản trị", ["guardrail_rule", "link_allowlist", "prompt_template", "prompt_version", "eval_set", "eval_dataset_link", "eval_case", "eval_run", "eval_result", "redteam_case", "feedback", "quality_metric", "ai_system_record", "log_access_grant", "compliance_export"]),
]
# (cha, con, nhãn): tham chiếu logic, vẽ nét đứt
LOGIC = [("model_version", "invocation_log", "logic, model_version_id"), ("message", "invocation_log", "logic, message_id"),
         ("model_version", "message", "logic, model_version_id"), ("knowledge_chunk", "citation", "logic, chunk_id"),
         ("prompt_version", "eval_run", "logic, subject_id"), ("model_version", "eval_run", "logic, subject_id"),
         ("message", "feedback", "logic, message_id"), ("message", "log_access_grant", "logic, conversation_id"),
         ("model_version", "model_health_probe", "logic, version_id"), ("model_route", "model_breaker", "logic, route_id"),
         ("tool_definition", "tool_call", "logic, tool_code"), ("policy_change", "kill_switch_record", "logic, change_id")]

fks = []
for m in re.finditer(r"CREATE TABLE ph17_assist\.(\w+) \((.*?)\n\)", sql, re.S):
    t, body = m.group(1), m.group(2)
    for col, tgt in re.findall(r"FOREIGN KEY \(tenant_id, (\w+)\) REFERENCES ph17_assist\.(\w+)", body):
        nullable = not re.search(r"^\s+%s\s+\S+(?: \S+)*? NOT NULL" % col, body, re.M)
        fks.append((tgt, t, col, nullable))
for m in re.finditer(r"ALTER TABLE ph17_assist\.(\w+) ADD CONSTRAINT \w+ FOREIGN KEY \(tenant_id, (\w+)\) REFERENCES ph17_assist\.(\w+)", sql):
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
