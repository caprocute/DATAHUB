#!/usr/bin/env python3
"""Sinh ba khối của D03-04-PH13 từ spec.OPS, gen_asyncapi.EV và FRS §9.2:
chương 3 (bảng endpoint), chương 4 (bảng sự kiện), chương 6 (bảng mã lỗi). Chèn giữa các cặp <!-- gen:...:start/end -->."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec, gen_openapi as go, gen_asyncapi as ga

API = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(API), "D03-04-PH13-api-giam-sat-kiem-toan.md")
FRS = os.path.join(API, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH13-frs-giam-sat-kiem-toan.md")
doc = go.build()
OPSBY = {}
for path, item in doc["paths"].items():
    for m, op in item.items():
        OPSBY[op["x-datahub-id"]] = (m.upper(), path, op)

def perm_txt(op):
    pm = op["x-datahub-permission"]
    if "anyOf" in pm: return " hoặc ".join(f"`{x}`" for x in pm["anyOf"])
    if "permission" in pm: return f"`{pm['permission']}`" + (f" hoặc scope `{pm['serviceScope']}`" if "serviceScope" in pm else "")
    if "serviceScope" in pm: return f"scope `{pm['serviceScope']}`"
    return "mTLS Alertmanager"

# ---- chương 3
groups = {}
for (code, method, path, summary, fr, perm, idem, success, group, *_) in spec.OPS:
    base, tag = spec.GROUPS[group]
    _, _, op = OPSBY[f"API-13-{code}"]
    groups.setdefault((spec.BASES[base], tag), []).append(
        f"| API-13-{code} | `{method} {path}` | {summary} | {fr} | {perm_txt(op)} | {'có' if idem else ''} | {success} |")
res = []
for (base, tag), lines in groups.items():
    res.append(f"**{tag}** (`{base}`)\n\n| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |\n|---|---|---|---|---|---|---|\n"
               + "\n".join(lines) + f"\n\n: Danh mục endpoint · {tag}")
ep_block = "<!-- gen:endpoints:start -->\n" + "\n\n".join(res) + "\n<!-- gen:endpoints:end -->"

# ---- chương 4
ev_rows = ["| Mã | Topic | Khi nào | Khóa | Giữ | Người nhận |", "|---|---|---|---|---|---|"]
for key, code, addr, payload, summ, days, parts, kdesc, recv in ga.EV:
    ev_rows.append(f"| {code} | `{addr}` | {summ} | {kdesc} | {days} ngày | {recv} |")
for key, title, addr, payload, summ, days, parts, kdesc, sender, hdr in ga.IN:
    ev_rows.append(f"| Vào | `{addr}` | {summ} | {kdesc} | {days} ngày | PH-13 (người phát: {sender}) |")
ev_block = "<!-- gen:events:start -->\n" + "\n".join(ev_rows) + "\n\n: Danh mục sự kiện của PH-13\n<!-- gen:events:end -->"

# ---- chương 6
frs = open(FRS, encoding="utf-8").read()
errs = re.findall(r"^\| (ERR-13-\d{3}) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$", frs, re.M)
uses = {}
for aid, (m, p, op) in OPSBY.items():
    for e in op["x-datahub-errors"]: uses.setdefault(e, []).append(aid[-3:])
DEF_ERR = {"ERR-13-009", "ERR-13-010", "ERR-13-001", "ERR-13-003", "ERR-13-007", "ERR-13-016", "ERR-13-037", "ERR-13-036", "ERR-13-038", "ERR-13-014"}
def fmt(lst):
    lst = sorted(set(lst))
    return f"{len(lst)} API (chung)" if len(lst) > 12 else ", ".join(lst)
r1 = ["| Mã | HTTP | Ý nghĩa | API phát sinh (API-13-) |", "|---|---|---|---|"]
r2 = ["| Mã | Ý nghĩa | Nơi người vận hành thấy |", "|---|---|---|"]
WHERE = lambda n: ("Bảng cách ly kiểm toán, cảnh báo `WARNING` cho DU nguồn" if n in (101, 102, 103, 104, 105, 126) else
    "Chỉ số `dh_audit_*`, cảnh báo `WARNING`, UI-13-13" if n in (106, 107, 108) else
    "Cảnh báo Nghiêm trọng, EVT-13-05, UI-13-14" if n in (109, 110) else
    "Cảnh báo, EVT-13-09, UI-13-14" if n == 111 else
    "Kết quả quét, cảnh báo an ninh, UI-13-17" if n == 112 else
    "Chỉ số của bộ thu thập, UI-13-01, UI-13-17" if 113 <= n <= 118 else
    "Cảnh báo về chính hệ thống giám sát, UI-13-01" if 119 <= n <= 122 else
    "EVT-13-13, EVT-13-14, UI-13-01" if n in (123, 124) else "Cảnh báo `WARNING`, UI-13-14")
for c, http, m, cau in errs:
    n = int(c[-3:])
    if n >= 101: r2.append(f"| {c} | {m.strip()} | {WHERE(n)} |")
    else: r1.append(f"| {c} | {http.strip()} | {m.strip()} | {fmt(uses.get(c, [])) or 'Không có API (lỗi chạy nền hoặc dự phòng)'} |")
err_block = ("<!-- gen:errors:start -->\n### 6.1. Lỗi API điều khiển (ERR-13-001…044)\n\nBảng dưới là 44 mã người gọi API có thể nhận; cột cuối cho biết operation nào phát sinh để kiểm thử viên viết ca lỗi đủ.\n\n" + "\n".join(r1) + "\n\n: Mã lỗi ERR-13-001…044 và API phát sinh\n\n"
    "### 6.2. Lỗi chạy nền (ERR-13-101…126)\n\nKhông trả qua API; kết quả ghi ở chỉ số, nhật ký, bảng cách ly hoặc cảnh báo cho người vận hành. Câu hiển thị ở FRS §9.2.\n\n"
    + "\n".join(r2) + "\n\n: Mã lỗi chạy nền ERR-13-101…126\n<!-- gen:errors:end -->")

s = open(DOC, encoding="utf-8").read()
for name, blk in (("endpoints", ep_block), ("events", ev_block), ("errors", err_block)):
    s, k = re.subn(rf"<!-- gen:{name}:start -->.*?<!-- gen:{name}:end -->", lambda m: blk, s, flags=re.S)
    assert k == 1, name
open(DOC, "w", encoding="utf-8").write(s)
print(len(spec.OPS), "endpoint;", len(ga.EV), "sự kiện;", len(errs), "mã lỗi")

# ---- chương 2: số operation theo quyền
from collections import OrderedDict
cnt = OrderedDict()
for aid, (m, p, op) in sorted(OPSBY.items()):
    pm = op["x-datahub-permission"]
    k = " hoặc ".join(f"`{x}`" for x in pm["anyOf"]) if "anyOf" in pm else (f"`{pm['permission']}`" if "permission" in pm else (f"scope `{pm['serviceScope']}`" if "serviceScope" in pm else "mTLS Alertmanager"))
    cnt.setdefault(k, []).append(aid[-3:])
def rng(l):
    return ", ".join(l) if len(l) <= 14 else ", ".join(l[:6]) + " … " + ", ".join(l[-3:])
pm_rows = ["| Quyền hoặc scope | Số API | Mã API-13- |", "|---|---|---|"]
for k, l in sorted(cnt.items(), key=lambda kv: -len(kv[1])):
    pm_rows.append(f"| {k} | {len(l)} | {rng(l)} |")
pm_block = "<!-- gen:perm-matrix:start -->\n" + "\n".join(pm_rows) + "\n\n: Số operation theo quyền hoặc scope\n<!-- gen:perm-matrix:end -->"
s = open(DOC, encoding="utf-8").read()
s, k = re.subn(r"<!-- gen:perm-matrix:start -->.*?<!-- gen:perm-matrix:end -->", lambda m: pm_block, s, flags=re.S)
assert k == 1
open(DOC, "w", encoding="utf-8").write(s)
print("ma trận quyền:", len(cnt), "dòng")
