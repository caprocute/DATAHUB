#!/usr/bin/env python3
"""Sinh bảng mô tả cột (Markdown) từ ddl/ph03_gateway.sql, nhóm theo chủ đề.

Chạy: python3 tools/gen_tables_md.py > /tmp/tables.md (từ thư mục csdl/ph03).
Đọc CREATE TABLE và COMMENT ON TABLE/COLUMN; cột không có COMMENT lấy mô tả chuẩn (STD) hoặc để trống.
Kết quả được dán vào D03-03-PH03 §3 giữa hai dấu <!-- gen:tables:start/end -->; sau đó chạy
tools/them_dac_ta_bang.py để chèn khối đặc tả 10 mục cho từng bảng.
In thêm ra stderr danh sách bảng không có trong ORDER (để cập nhật khi thêm bảng).
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sql = open(os.path.join(ROOT, "ddl", "ph03_gateway.sql"), encoding="utf-8").read()

# Thứ tự trình bày theo nhóm (khác thứ tự tạo trong DDL, vì DDL phải tạo change_request trước route).
ORDER = [
    # A. Định tuyến
    "edge_host", "upstream", "upstream_node", "route", "route_state_event",
    # B. Consumer và chặn nhanh
    "consumer", "consumer_credential", "idempotency_key", "revoked_token", "emergency_block",
    # C. Chính sách chiếu từ gói và hạn mức
    "plan_policy", "subscription_ref", "rate_limit_override", "policy_template_setting",
    # D. Lớp biên và WAF
    "waf_exception", "waf_virtual_patch", "waf_mode", "ip_block", "edge_certificate", "client_ca",
    "tls_exception", "tenant_redirect",
    # E. Ảnh chụp cấu hình
    "snapshot_counter", "config_snapshot", "snapshot_violation", "tenant_hold", "source_cursor",
    # F. Yêu cầu thay đổi, tham số, vận hành
    "change_request", "param_definition", "tenant_param", "synthetic_check", "legacy_import_job",
    # G. Kỹ thuật
    "state_transition", "outbox", "shedlock",
]

tables = {}
hints = {}   # (bảng, cột) -> gợi ý lấy từ CHECK khi cột không có COMMENT
for m in re.finditer(r"CREATE TABLE ph03_gateway\.(\w+) \((.*?)\n\);", sql, re.S):
    name, body = m.group(1), m.group(2)
    for c in re.finditer(r"CHECK \(\(?(\w+) IN \(([^)]*)\)", body):
        hints[(name, c.group(1))] = "Một trong: " + ", ".join("`%s`" % v for v in re.findall(r"'([^']*)'", c.group(2))) + "."
    for c in re.finditer(r"CHECK \((?:[^()]*? AND )?\(?(\w+) ~ '([^']*)'\)", body):
        if c.group(1) != "tenant_id":
            hints.setdefault((name, c.group(1)), "Mẫu `%s`." % c.group(2).replace("|", "\\|"))
    cols = []
    for line in body.split("\n"):
        line = line.strip().rstrip(",")
        if not line or line.startswith("CONSTRAINT") or line.startswith("--"):
            continue
        cm = re.match(r"(\w+)\s+(.+)$", line)
        if not cm:
            continue
        col, rest = cm.group(1), re.sub(r"\s+", " ", cm.group(2))
        nn = "NOT NULL" in rest
        default = re.search(r"DEFAULT (.+)$", rest)
        typ = re.sub(r" (NOT NULL|DEFAULT .+)$", "", rest).replace(" NOT NULL", "")
        cols.append((col, typ.strip(), "x" if nn else "", default.group(1) if default else ""))
    tables[name] = cols

missing = [t for t in tables if t not in ORDER]
extra = [t for t in ORDER if t not in tables]
if missing or extra:
    sys.stderr.write("CẢNH BÁO: bảng chưa có trong ORDER: %s; có trong ORDER nhưng không có ở DDL: %s\n" % (missing, extra))

tcomment = dict(re.findall(r"COMMENT ON TABLE ph03_gateway\.(\w+) IS '((?:[^']|'')*)';", sql))
ccomment = {(t, c): v for t, c, v in re.findall(r"COMMENT ON COLUMN ph03_gateway\.(\w+)\.(\w+) IS '((?:[^']|'')*)';", sql)}
STD = {
    "id": "Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5).",
    "tenant_id": "Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung hoặc phần nền tảng); khóa RLS và khóa ngoại kép.",
    "created_at": "Thời điểm tạo.", "created_by": "Người tạo (mã người dùng hoặc `system:*`).",
    "updated_at": "Thời điểm sửa cuối (trigger `tg_touch`).", "updated_by": "Người sửa cuối.",
    "version": "Khóa lạc quan; thành phần của ETag (`If-Match`).",
}

GROUPS = [("A", 0, 5), ("B", 5, 10), ("C", 10, 14), ("D", 14, 22), ("E", 22, 27), ("F", 27, 32), ("G", 32, 35)]
EN = {"route": "EN-03-01", "upstream": "EN-03-02", "upstream_node": "EN-03-02", "consumer": "EN-03-03",
      "consumer_credential": "EN-03-04", "plan_policy": "EN-03-05", "rate_limit_override": "EN-03-06",
      "waf_exception": "EN-03-07", "waf_virtual_patch": "EN-03-08", "config_snapshot": "EN-03-09",
      "snapshot_violation": "EN-03-09", "edge_certificate": "EN-03-11", "emergency_block": "EN-03-12",
      "tenant_redirect": "EN-03-13", "ip_block": "EN-03-14", "change_request": "EN-03-15",
      "edge_host": "EN-03-16 (đề xuất)", "subscription_ref": "EN-03-17 (đề xuất)",
      "policy_template_setting": "EN-03-18 (đề xuất)", "client_ca": "EN-03-19 (đề xuất)", "tls_exception": "EN-03-20 (đề xuất)"}

if "--chi-muc" in sys.argv:   # bảng danh sách cho đầu chương 3
    fr_src = open(os.path.join(ROOT, "tools", "them_dac_ta_bang.py"), encoding="utf-8").read().split("FR_BANG = {")[1].split("\n}")[0]
    fr = dict(re.findall(r"'(\w+)': '([^']*)'", fr_src))
    print("| Nhóm | Mục, bảng | Thực thể | Số cột | FR phục vụ |\n|---|---|---|---|---|")
    n = 0
    for g, a, b in GROUPS:
        for t in ORDER[a:b]:
            n += 1
            print("| %s | 3.%d `%s` | %s | %d | %s |" % (g, n, t, EN.get(t, "Phụ trợ"), len(tables[t]), fr.get(t, "")))
    print("\n: Danh sách %d bảng của schema ph03_gateway theo nhóm A đến G" % n)
    sys.exit(0)

out = []
for i, t in enumerate([t for t in ORDER if t in tables], 1):
    out.append(f"### 3.{i}. `{t}`\n")
    if t in tcomment:
        out.append(tcomment[t].replace("''", "'") + "\n")
    out.append("| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |")
    out.append("|---|---|---|---|---|")
    for c, typ, nn, d in tables[t]:
        note = ccomment.get((t, c), STD.get(c, hints.get((t, c), ""))).replace("''", "'").replace("|", "\\|")
        out.append(f"| `{c}` | `{typ}` | {nn} | {('`' + d + '`') if d else ''} | {note} |")
    out.append("")
sys.stdout.write("\n".join(out))
