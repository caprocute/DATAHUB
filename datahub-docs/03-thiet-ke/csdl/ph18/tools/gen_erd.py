#!/usr/bin/env python3
"""Sinh sơ đồ thực thể quan hệ Mermaid (erDiagram) cho D03-03-PH18 chương 2 từ khóa ngoại trong ddl/ph18_ops.sql.

Chép từ csdl/ph17/tools/gen_erd.py, sửa cho ph18: nhóm theo khối chức năng (tệp changeset), nhận khóa ngoại một cột tới bảng dùng
chung và khóa ngoại kèm cột phân vùng. Quan hệ logic (tham chiếu theo mã, không khóa ngoại) ở LOGIC, vẽ nét đứt.
Chạy từ thư mục csdl/ph18:  python3 tools/gen_erd.py [--write]   (thay đoạn giữa <!-- gen:erd:start --> và <!-- gen:erd:end -->).
"""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DOC = os.path.join(os.path.dirname(ROOT), "D03-03-PH18-csdl-van-hanh.md")
sql = open(os.path.join(ROOT, "ddl", "ph18_ops.sql"), encoding="utf-8").read()
sys.path.insert(0, HERE)
from sinh_ddl import FILE_GROUPS

TITLES = {"18-0010-core.sql": "hạ tầng outbox, inbox", "18-0020-param.sql": "kho tham số và cờ tính năng (khối A)",
          "18-0030-dlq.sql": "DLQ, phân loại và phát lại (khối B, C, D)", "18-0040-notify.sql": "thông báo (khối E)",
          "18-0050-task.sql": "Việc của tôi và lịch (khối F)", "18-0060-incident.sql": "sự cố vận hành (khối G)",
          "18-0070-backup.sql": "sao lưu, khôi phục, xuất và sáp nhập tenant (khối H)", "18-0080-migration.sql": "di trú hệ cũ và chạy song song (khối I)",
          "18-0090-report.sql": "báo cáo vận hành (khối J)"}
GIAI = {
    "18-0020-param.sql": "Hình cho thấy lược đồ khóa (`param_definition`) chỉ có ở dòng `COMMON` và là gốc của mọi giá trị, phiên bản, đề nghị duyệt; giá trị của tenant tham chiếu lược đồ bằng khóa ngoại một cột nên tenant không cần chép lược đồ. Cờ tính năng, danh sách egress và gói tham số đứng riêng vì chỉ liên hệ với lược đồ qua mã khóa.",
    "18-0030-dlq.sql": "Hình cho thấy `dlq_message` là tâm của khối: bản sửa, tham chiếu payload Garage, gán người và mục phát lại đều khóa ngoại kèm `received_at` (cột phân vùng) và xóa theo khi mục hết hạn, còn nhật ký `dlq_audit` chỉ tham chiếu logic để sống lâu hơn mục. Đăng ký nguồn và sổ tay lỗi là bảng dùng chung, liên hệ theo mã.",
    "18-0040-notify.sql": "Hình cho thấy mẫu có phiên bản, quy tắc và thông báo trỏ tới mẫu theo mã (không khóa ngoại để mẫu `COMMON` và mẫu tenant cùng mã dùng được), lần gửi là con của thông báo và xóa theo khi thông báo hết hạn giữ. Tùy chọn người dùng và danh sách chặn đứng riêng, được đọc khi phân giải người nhận.",
    "18-0050-task.sql": "Hình cho thấy việc tham chiếu loại việc dùng chung bằng khóa ngoại một cột, lịch nhắc là con của việc và có thể trỏ tới thông báo đã tạo; lịch làm việc là cha của ngày lễ, cửa sổ bảo trì đứng riêng.",
    "18-0060-incident.sql": "Hình cho thấy hồ sơ sự cố có mốc thời gian chỉ thêm và các liên kết tới đối tượng ở khối khác (mục DLQ, bản sao lưu, lần di trú) bằng mã tham chiếu.",
    "18-0070-backup.sql": "Hình cho thấy đối tượng sao lưu là cha của bản sao lưu và kết quả kiểm tra khôi phục; yêu cầu khôi phục tenant có tám bước con; lần sáp nhập có thể trỏ tới lần xuất tenant đã dùng.",
    "18-0080-migration.sql": "Hình cho thấy chuỗi nguồn hệ cũ, kế hoạch, mục kế hoạch, lần chạy, kết quả, bản ghi lỗi, đối chiếu; nhóm chạy song song có mẫu so sánh phân vùng tháng, danh sách kiểm tra và sổ cắt chuyển.",
}
SKIP = {"18-0010-core.sql", "18-0090-report.sql"}
LOGIC = [("dlq_message", "dlq_audit", "logic, dlq_id"), ("replay_job", "dlq_audit", "logic, replay_job_id"),
         ("notification_template", "notification_rule", "logic, template_code"), ("notification_template", "notification_message", "logic, template_code"),
         ("dlq_source", "dlq_message", "logic, source_code"), ("error_guide", "dlq_message", "logic, error_code"),
         ("task_type", "notification_rule", "logic, create_task_type"), ("incident", "dlq_group", "logic, incident_link")]
LOGIC = [x for x in LOGIC if x[2] != "logic, incident_link"]

fks = []
for m in re.finditer(r"CREATE TABLE ph18_ops\.(\w+) \((.*?)\n\)", sql, re.S):
    t, body = m.group(1), m.group(2)
    for cols, tgt in re.findall(r"FOREIGN KEY \(([^)]*)\) REFERENCES ph18_ops\.(\w+)", body):
        col = [c.strip() for c in cols.split(",") if c.strip() != "tenant_id"][0]
        nullable = not re.search(r"^\s+%s\s+\S+(?: \S+)*? NOT NULL" % col, body, re.M)
        fks.append((tgt, t, col, nullable))


def render():
    out = []
    for fname, grp in FILE_GROUPS:
        if fname in SKIP:
            continue
        members = [t["name"] for t in grp]
        ms = set(members)
        title = TITLES[fname]
        L = ["Nhóm %s gồm %d bảng (%s). Nét liền là khóa ngoại thật, nét đứt là tham chiếu logic theo mã." % (title, len(members), ", ".join("`%s`" % m for m in members)), "",
             "```{.mermaid caption=\"ERD nhóm %s\"}" % title, "erDiagram"]
        used, seen = set(), set()
        for p, c, col, nul in fks:
            if c in ms and (p, c, col) not in seen:
                seen.add((p, c, col))
                L.append(f'  {p} {"|o" if nul else "||"}--o{{ {c} : "{col}"')
                used |= {p, c}
        for p, c, lab in LOGIC:
            if c in ms:
                L.append(f'  {p} ||..o{{ {c} : "{lab}"')
                used |= {p, c}
        for a in [m for m in members if m not in used]:
            L.append(f"  {a} {{\n    uuid id PK\n    varchar tenant_id\n  }}")
        L.append("```")
        L.append("")
        L.append(GIAI[fname])
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
