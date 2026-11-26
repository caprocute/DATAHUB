#!/usr/bin/env python3
"""Sinh chương 3 (danh sách bảng, bảng đặc tả 10 mục, bảng cột) của D03-03-PH04 từ ddl/ph04_int.sql.

Chạy (từ thư mục csdl/ph04):
  python3 tools/gen_tables_md.py            # in ra stdout
  python3 tools/gen_tables_md.py --write    # thay phần giữa <!-- gen:tables:start/end --> của D03-03-PH04
Khóa chính, duy nhất, khóa ngoại, CHECK, chỉ mục, RLS, trigger, quyền chỉ thêm đọc từ DDL;
mục đích lấy từ COMMENT ON TABLE; FR phục vụ và lưu giữ ở bảng META dưới đây (không có trong DDL).
Sửa ở DDL hoặc META rồi sinh lại, không sửa tay tài liệu.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(ROOT), "D03-03-PH04-csdl-tich-hop.md")
sql = open(os.path.join(ROOT, "ddl", "ph04_int.sql"), encoding="utf-8").read()

# Thông tin không suy được từ DDL: FR phục vụ, lưu giữ (D03-03-PH04 §7).
META = {
    "workspace": ("FR-04-007", "Suốt vòng đời tenant; không xóa khi còn luồng, chuyển `ARCHIVED`."),
    "workspace_member": ("FR-04-007; BR-04-021", "Xóa khi gỡ thành viên hoặc xóa không gian (CASCADE)."),
    "flow": ("FR-04-001…006", "Suốt vòng đời luồng và 5 năm sau khi gỡ."),
    "flow_version": ("FR-04-010, 011, 017, 024, 027, 040…045", "Suốt vòng đời luồng và 5 năm sau khi gỡ; `ph04_readonly` chỉ đọc cột siêu dữ liệu."),
    "flow_version_contributor": ("FR-04-024, 041; BR-04-005", "Theo phiên bản (CASCADE)."),
    "flow_mapping": ("FR-04-020", "Theo phiên bản (CASCADE)."),
    "flow_route_index": ("FR-04-001, 002, 023 (VR-08)", "Tính lại toàn bộ mỗi lần lưu; theo phiên bản (CASCADE)."),
    "flow_endpoint_index": ("FR-04-001, 023 (VR-18), 052", "Tính lại toàn bộ mỗi lần lưu; theo phiên bản (CASCADE)."),
    "flow_reference": ("FR-04-006", "Tính lại toàn bộ mỗi lần lưu; theo phiên bản (CASCADE)."),
    "review": ("FR-04-040, 041, 043", "Suốt vòng đời luồng và 5 năm sau khi gỡ."),
    "deployment": ("FR-04-042, 044, 045, 050, 051", "Suốt vòng đời luồng và 5 năm sau khi gỡ."),
    "test_case": ("FR-04-031", "Theo luồng; ngừng dùng bằng `active = false`."),
    "test_run": ("FR-04-030, 032, 040 (BR-04-004)", "90 ngày (`04.test.retention-days`), `TestRunRetentionJob` 02:30 hằng ngày."),
    "test_run_step": ("FR-04-030, 032, 033", "Theo lần chạy (CASCADE); `ph04_readonly` không đọc được."),
    "runtime_command": ("FR-04-050", "Suốt vòng đời luồng và 5 năm sau khi gỡ."),
    "command_ack": ("FR-04-050, 051", "Theo lệnh (CASCADE)."),
    "heartbeat_latest": ("FR-04-051, 052", "Chỉ bản mới nhất (UPSERT); dòng quá 10 phút bị dọn."),
    "component_policy": ("FR-04-080", "Theo phiên bản chính sách; không xóa cứng."),
    "component_proposal": ("FR-04-080", "Không xóa; kết thúc bằng trạng thái cuối."),
    "template": ("FR-04-003, 025", "Ngừng dùng bằng `DEPRECATED`."),
    "palette_group_rule": ("FR-04-012", "Giữ mọi bản; một bản `active`."),
    "catalog_change": ("FR-04-081", "Không xóa, để tra lịch sử nâng catalog."),
    "external_system": ("FR-04-003, 023", "Cập nhật theo sự kiện PH-01; không xóa cứng."),
    "legacy_import_job": ("FR-04-082", "Giữ hết giai đoạn di trú; tệp gốc không lưu."),
    "outbox": ("FR-04-083; EVT-04-01…10", "3 ngày, dọn sau khi Debezium đã gửi."),
    "shedlock": ("Không (kỹ thuật cho tác vụ nền)", "Ghi đè theo tên khóa."),
}
STD = {
    "id": "Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5).",
    "tenant_id": "Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS.",
    "created_at": "Thời điểm tạo.", "created_by": "Người tạo (mã người dùng hoặc `system:*`).",
    "updated_at": "Thời điểm sửa cuối (trigger `tg_touch`).", "updated_by": "Người sửa cuối.",
    "version": "Khóa lạc quan; thành phần của ETag (`If-Match`).",
}


def cols_of(s):
    return re.sub(r"\s+", " ", s.strip())


tables = []
for m in re.finditer(r"CREATE TABLE ph04\.(\w+) \((.*?)\n\);", sql, re.S):
    name, body = m.group(1), m.group(2)
    cols, cons = [], []
    for line in body.split("\n"):
        line = line.strip().rstrip(",")
        if not line or line.startswith("--"):
            continue
        if line.startswith("CONSTRAINT"):
            cons.append(line)
            continue
        cm = re.match(r"(\w+)\s+(.+)$", line)
        if not cm:
            continue
        col, rest = cm.group(1), re.sub(r"\s+", " ", cm.group(2))
        nn = "NOT NULL" in rest
        default = re.search(r"DEFAULT (.+)$", rest)
        typ = re.sub(r" (NOT NULL|DEFAULT .+)$", "", rest).replace(" NOT NULL", "")
        cols.append((col, typ.strip(), "x" if nn else "", default.group(1) if default else ""))
    tables.append((name, cols, cons))

tcomment = dict(re.findall(r"COMMENT ON TABLE ph04\.(\w+) IS '((?:[^']|'')*)';", sql))
ccomment = {(t, c): v for t, c, v in re.findall(r"COMMENT ON COLUMN ph04\.(\w+)\.(\w+) IS '((?:[^']|'')*)';", sql)}
rls = dict(re.findall(r"CALL ph04\.p_enable_rls\('ph04\.(\w+)', '([PS])'\);", sql))
indexes = re.findall(r"CREATE (UNIQUE )?INDEX (\w+) ON ph04\.(\w+)(?: USING (\w+))? \((.*?)\)( WHERE [^;]+)?;", sql)
triggers = re.findall(r"CREATE TRIGGER (\w+) BEFORE UPDATE ON ph04\.(\w+)", sql)
revokes = re.findall(r"REVOKE ([A-Z, ]+) ON ph04\.(\w+) FROM ph04_app;", sql)
grants_extra = re.findall(r"GRANT (INSERT) ON ph04\.(\w+) TO ph04_app;", sql)


def q(x):
    return x.replace("''", "'")


def block(t, cols, cons):
    pk = None
    uqs, fks, cks = [], [], []
    for c in cons:
        mm = re.match(r"CONSTRAINT (\w+) (PRIMARY KEY|UNIQUE|FOREIGN KEY|CHECK) ?(.*)$", c)
        n, kind, rest = mm.groups()
        if kind == "PRIMARY KEY":
            pk = re.match(r"\((.*?)\)", rest).group(1)
        elif kind == "UNIQUE":
            uqs.append(f"`{n}` ({re.match(r'[(](.*?)[)]', rest).group(1)})")
        elif kind == "FOREIGN KEY":
            fm = re.match(r"\((.*?)\) REFERENCES ph04\.(\w+) \((.*?)\)(.*)$", rest)
            od = fm.group(4).strip()
            od = {"ON DELETE CASCADE": ", xóa theo", "": ""}.get(od, ", " + od.replace("ON DELETE SET NULL", "xóa thì đặt NULL"))
            fks.append(f"`{n}` ({fm.group(1)}) → `{fm.group(2)}`{od}")
        else:
            cks.append(f"`{n}`")
    for u, n, tt, using, colsx, where in indexes:
        if tt == t and u:
            uqs.append(f"`{n}` ({colsx}){' có điều kiện' if where else ''}")
    ixs = [f"`{n}`" + (f" ({using.upper()})" if using else "") + (" có điều kiện" if where else "")
           for u, n, tt, using, colsx, where in indexes if tt == t and not u]
    mode = rls.get(t)
    iso = {"P": "RLS mẫu P (FORCE): chỉ dòng của tenant phiên.",
           "S": "RLS mẫu S (FORCE): đọc dòng của tenant phiên và `COMMON`; ghi `COMMON` chỉ dưới `PLATFORM`.",
           None: "Không RLS; bảng kỹ thuật không có `tenant_id`, không chứa dữ liệu nghiệp vụ."}[mode]
    app = []
    if any(tt == t for _, tt in grants_extra):
        app.append("`ph04_app` chỉ có INSERT")
    else:
        app += [f"`ph04_app` bị thu hồi {privs.strip()}" for privs, tt in revokes if tt == t]
    trg = [n for n, tt in triggers if tt == t]
    part = "Không phân vùng" + ("; chỉ thêm (" + ", ".join(app) + ")" if app else "") + "."
    com = q(tcomment.get(t, ""))
    en = re.match(r"(EN-04-\w+) (.*)$", com)
    muc = f"{en.group(1)} · {en.group(2)}" if en else com
    fr, keep = META[t]
    note = f"Lưu giữ: {keep[0].lower() + keep[1:]}" + (f" Trigger: {', '.join('`' + x + '`' for x in trg)}." if trg else "")
    L = ["::: dac-ta",
         f"**Mục đích.** {muc}", "",
         f"**FR phục vụ.** {fr}.", "",
         f"**Khóa chính.** ({pk}).", "",
         f"**Duy nhất.** {'; '.join(uqs) if uqs else 'Không ngoài khóa chính'}.", "",
         f"**Khóa ngoại.** {'; '.join(fks) if fks else 'Không'}.", "",
         f"**Ràng buộc CHECK.** {', '.join(cks) if cks else 'Không'}.", "",
         f"**Chỉ mục.** {', '.join(ixs) if ixs else 'Chỉ khóa chính và khóa duy nhất'}.", "",
         f"**Cách ly tenant.** {iso}", "",
         f"**Phân vùng, chỉ thêm.** {part}", "",
         f"**Ghi chú.** {note}",
         ":::"]
    return "\n".join(L)


out = []
# Danh sách bảng
out.append("| TT | Bảng | Thực thể | RLS | Số cột | FR phục vụ |")
out.append("|---|---|---|---|---|---|")
for i, (t, cols, cons) in enumerate(tables, 1):
    en = re.match(r"(EN-04-\w+)", tcomment.get(t, ""))
    out.append(f"| {i} | `{t}` | {en.group(1) if en else 'Kỹ thuật'} | {rls.get(t, 'Không')} | {len(cols)} | {META[t][0]} |")
out.append("")
out.append(": Danh sách bảng của schema `ph04`")
out.append("")
for i, (t, cols, cons) in enumerate(tables, 1):
    out.append(f"### 3.{i}. `{t}`\n")
    out.append(block(t, cols, cons))
    out.append("")
    out.append("| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |")
    out.append("|---|---|---|---|---|")
    for c, typ, nn, d in cols:
        note = q(ccomment.get((t, c), STD.get(c, ""))).replace("|", "\\|")
        out.append(f"| `{c}` | `{typ}` | {nn} | {('`' + d + '`') if d else ''} | {note} |")
    out.append("")
    out.append(f": Cột của bảng `{t}`")
    out.append("")
text = "\n".join(out)

if "--write" in sys.argv:
    doc = open(DOC, encoding="utf-8").read()
    a, b = "<!-- gen:tables:start -->\n", "<!-- gen:tables:end -->"
    i, j = doc.index(a) + len(a), doc.index(b)
    open(DOC, "w", encoding="utf-8").write(doc[:i] + text + doc[j:])
    print(f"Đã ghi {len(tables)} bảng vào {DOC}")
else:
    sys.stdout.write(text)
