#!/usr/bin/env python3
"""Sinh danh sách bảng và mô tả cột (Markdown) từ ddl/ph02_[0-9][0-9]_*.sql của schema ph02_catalog.

Chạy (từ datahub-docs):
  python3 03-thiet-ke/csdl/ph02/tools/gen_tables_md.py 03-thiet-ke/csdl/D03-03-PH02-csdl-danh-muc-dich-vu.md
Thay nội dung giữa hai cặp dấu trong tệp đích:
  <!-- gen:list:start --> … <!-- gen:list:end -->     bảng danh sách bảng (3.1)
  <!-- gen:tables:start --> … <!-- gen:tables:end --> từng bảng: mô tả (COMMENT ON TABLE), cột, kiểu, mặc định, ghi chú
Không đối số: in ra màn hình. Sau bước này chạy them_dac_ta_bang.py để thêm khối đặc tả 10 mục.
Cột không có COMMENT lấy ghi chú chuẩn (cột ngữ cảnh D00-01 §5.1) hoặc để trống.
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = sorted(f for f in glob.glob(os.path.join(ROOT, "ddl", "ph02_[0-9][0-9]_*.sql")) if "_90_" not in f)
sql = "\n".join(open(f, encoding="utf-8").read() for f in FILES)

TYPE_RE = re.compile(r"^(varchar\(\d+\)(?:\[\])?|char\(\d+\)|numeric\(\d+,\d+\)|[a-z]+(?:\[\])?)")


def strip_quotes(s):
    return re.sub(r"'(?:[^']|'')*'", "''", s)


def parse_tables():
    out = []
    for m in re.finditer(r"CREATE TABLE ph02_catalog\.(\w+) \((.*?)\n\)( PARTITION BY RANGE \((\w+)\))?;", sql, re.S):
        name, body, part = m.group(1), m.group(2), m.group(4)
        cols, depth = [], 0
        for line in body.split("\n"):
            raw = line.strip()
            start_depth = depth
            depth += strip_quotes(raw).count("(") - strip_quotes(raw).count(")")
            if start_depth != 0 or not raw or raw.startswith("CONSTRAINT") or raw.startswith("--"):
                continue
            raw = raw.rstrip(",")
            cm = re.match(r"(\w+)\s+(.+)$", raw)
            if not cm:
                continue
            col, rest = cm.group(1), re.sub(r"\s+", " ", cm.group(2))
            tm = TYPE_RE.match(rest)
            typ = tm.group(1) if tm else rest.split(" ")[0]
            gen = "GENERATED ALWAYS" in rest
            dm = re.search(r"DEFAULT (.+?)(?: GENERATED|$)", rest) if not gen else None
            cols.append((col, typ, "x" if "NOT NULL" in rest else "", dm.group(1).strip() if dm else "", gen))
        out.append((name, cols, part))
    return out


tables = parse_tables()
tcomment = dict(re.findall(r"COMMENT ON TABLE ph02_catalog\.(\w+) IS '((?:[^']|'')*)';", sql))
ccomment = {(t, c): v for t, c, v in re.findall(r"COMMENT ON COLUMN ph02_catalog\.(\w+)\.(\w+) IS '((?:[^']|'')*)';", sql)}
STD = {
    "id": "Khóa chính, UUID v7 sinh ở ứng dụng (D00-01 §5).",
    "tenant_id": "Mã tenant `T{nn}` (hoặc `COMMON` ở bảng dùng chung); khóa RLS và thành phần khóa ngoại kép.",
    "created_at": "Thời điểm tạo.", "created_by": "Người tạo (mã người dùng hoặc `system:*`).",
    "updated_at": "Thời điểm sửa cuối (trigger `tg_touch`).", "updated_by": "Người sửa cuối.",
    "version": "Khóa lạc quan; thành phần của ETag (`If-Match`).",
}
# Nhóm hiển thị ở bảng danh sách (theo tệp DDL)
NHOM = {
    "category": "Danh mục", "code_registry": "Danh mục", "api": "Danh mục", "api_tag": "Danh mục", "api_version": "Danh mục",
    "api_spec": "Danh mục", "api_operation": "Danh mục", "api_search_doc": "Danh mục", "context_path_reservation": "Danh mục",
    "api_owner_transfer": "Danh mục", "diff_result": "Danh mục",
    "lint_rule": "Kiểm tra, backend, gói", "lint_rule_override": "Kiểm tra, backend, gói", "lint_finding": "Kiểm tra, backend, gói",
    "backend": "Kiểm tra, backend, gói", "plan": "Kiểm tra, backend, gói", "plan_operation_scope": "Kiểm tra, backend, gói",
    "subscription": "Vòng đời, duyệt, đăng ký", "subscription_state_history": "Vòng đời, duyệt, đăng ký",
    "version_state_history": "Vòng đời, duyệt, đăng ký", "grant_job": "Vòng đời, duyệt, đăng ký",
    "review_request": "Vòng đời, duyệt, đăng ký", "version_contributor": "Vòng đời, duyệt, đăng ký",
    "review_decision": "Vòng đời, duyệt, đăng ký", "deprecation_reminder": "Vòng đời, duyệt, đăng ký",
    "change_notice": "Công bố, SLA, đồng bộ", "change_notice_recipient": "Công bố, SLA, đồng bộ",
    "sla_commitment": "Công bố, SLA, đồng bộ", "sla_maintenance_window": "Công bố, SLA, đồng bộ", "sla_period": "Công bố, SLA, đồng bộ",
    "usage_daily": "Công bố, SLA, đồng bộ", "national_sync_record": "Công bố, SLA, đồng bộ", "national_sync_run": "Công bố, SLA, đồng bộ",
    "config_epoch": "Công bố, SLA, đồng bộ", "config_change_log": "Công bố, SLA, đồng bộ", "publish_job": "Công bố, SLA, đồng bộ",
    "gateway_drift": "Công bố, SLA, đồng bộ",
}
EN = {  # thực thể mức logic của FRS §4.2
    "api": "EN-02-01", "api_version": "EN-02-02", "api_spec": "EN-02-03", "lint_finding": "EN-02-04", "backend": "EN-02-05",
    "plan": "EN-02-06", "subscription": "EN-02-07", "sla_commitment": "EN-02-08", "sla_period": "EN-02-08", "review_request": "EN-02-09",
    "national_sync_record": "EN-02-10", "change_notice": "EN-02-11", "category": "EN-02-12", "api_tag": "EN-02-12", "lint_rule": "EN-02-13",
    "lint_rule_override": "EN-02-13",
}
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def rls_mode(t):
    m = re.search(r"p_enable_rls\('ph02_catalog\.%s', '([PS])'\)" % t, sql)
    return m.group(1) if m else None


def build_tables():
    out = []
    for i, (t, cols, part) in enumerate(tables, 1):
        out.append(f"### 3.{i}. `{t}`\n")
        if t in tcomment:
            out.append(tcomment[t].replace("''", "'") + "\n")
        if part:
            out.append(f"Phân vùng: `RANGE ({part})` theo tháng, tên phân vùng `{t}_YYYYMM`.\n")
        out.append("| Cột | Kiểu | Bắt buộc | Mặc định | Ghi chú |")
        out.append("|---|---|---|---|---|")
        for c, typ, nn, d, gen in cols:
            note = ccomment.get((t, c), STD.get(c, "")).replace("''", "'").replace("|", "\\|")
            if gen and not note:
                note = "Cột sinh tự động (GENERATED … STORED)."
            out.append(f"| `{c}` | `{typ}` | {nn} | {('`' + d + '`') if d else ''} | {note} |")
        out.append("")
    return "\n".join(out)


def build_list():
    revoked = set()
    for m in re.finditer(r"REVOKE UPDATE, DELETE ON ([^;]*?) FROM ph02_app;", sql, re.S):
        revoked |= set(re.findall(r"ph02_catalog\.(\w+)", m.group(1)))
    out = ["| STT | Bảng | Nhóm | Thực thể | RLS | Số cột | Ghi chú |", "|---|---|---|---|---|---|---|"]
    for i, (t, cols, part) in enumerate(tables, 1):
        ghi = []
        if part:
            ghi.append("phân vùng tháng")
        if t in revoked or re.search(r"BEFORE UPDATE OR DELETE ON ph02_catalog\.%s " % t, sql):
            ghi.append("chỉ thêm")
        mode = rls_mode(t)
        nhom = NHOM.get(t) or ("Nền tảng" if i >= 38 else "")
        out.append(f"| {i} | `{t}` | {nhom} | {EN.get(t, '—')} | {('mẫu ' + mode) if mode else 'không'} | {len(cols)} | {', '.join(ghi) or '—'} |")
    return "\n".join(out) + "\n"


def replace_block(text, tag, body):
    pat = re.compile(r"(<!-- gen:%s:start -->\n).*?(<!-- gen:%s:end -->)" % (tag, tag), re.S)
    if not pat.search(text):
        raise SystemExit("Thiếu dấu gen:%s trong tệp đích" % tag)
    return pat.sub(lambda m: m.group(1) + body + "\n" + m.group(2), text)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.stdout.write(build_list() + "\n" + build_tables())
    else:
        f = sys.argv[1]
        s = open(f, encoding="utf-8").read()
        s = replace_block(s, "list", build_list() + "\n: Danh sách bảng của schema ph02_catalog\n")
        s = replace_block(s, "tables", build_tables())
        open(f, "w", encoding="utf-8").write(s)
        print("đã sinh danh sách và", len(tables), "bảng cho", f)
