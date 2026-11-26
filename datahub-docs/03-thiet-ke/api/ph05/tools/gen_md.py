#!/usr/bin/env python3
"""Sinh bảng endpoint (§3) của D03-04-PH05 từ spec.OPS và gen_openapi.X, chèn giữa <!-- gen:endpoints:start/end -->."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec, gen_openapi as g
DOC = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "D03-04-PH05-api-bo-dieu-hop.md")
rows, cur = [], None
for code, method, path, summary, fr, perm, idem, success, group in spec.OPS:
    if group != cur:
        cur = group
        rows.append(f"\n**{g.TAGS[group]}**\n\n| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |\n|---|---|---|---|---|---|---|")
    p = f"`{g.SERVICE_SCOPE[code]}` (dịch vụ)" if perm == "service" else f"`PERM-05-{perm}`"
    rows.append(f"| API-05-{code} | `{method} {path}` | {summary} | {fr} | {p} | {'có' if idem else ''} | {success} |")
block = "<!-- gen:endpoints:start -->\n" + "\n".join(rows).lstrip("\n") + "\n<!-- gen:endpoints:end -->"
s = open(DOC, encoding="utf-8").read()
s2 = re.sub(r"<!-- gen:endpoints:start -->.*?<!-- gen:endpoints:end -->", lambda m: block, s, flags=re.S)
open(DOC, "w", encoding="utf-8").write(s2)
print(len(spec.OPS), "dòng")

# ---- §6 bảng lỗi: lấy từ FRS §8.1, thêm cột "API phát sinh" quét từ mô tả và ERR mặc định
FRS = os.path.join(os.path.dirname(DOC), "..", "..", "02-yeu-cau", "frs", "D02-03-PH05-frs-bo-dieu-hop.md")
errs = re.findall(r"^\| (ERR-05-\d{3}) \| ([^|]+) \| ([^|]+) \|$", open(FRS, encoding="utf-8").read(), re.M)
uses = {}
for code, *_ in spec.OPS:
    opid, body, resp, el, desc, extra = g.X[code]
    for e in set(re.findall(r"ERR-05-(\d{3})", desc or "")):
        uses.setdefault("ERR-05-" + e, []).append(code)
    for name in el:
        uses.setdefault(g.ERR[name][1], []).append(code)
def fmt(lst):
    lst = sorted(set(lst))
    return ", ".join(lst) if len(lst) <= 8 else ", ".join(lst[:8]) + f" và {len(lst) - 8} API khác"
r1 = ["| Mã | HTTP | Ý nghĩa | API phát sinh (API-05-) |", "|---|---|---|---|"]
r2 = ["| Mã | Ý nghĩa | Lớp lỗi ở PH-04 (SDD §8.4) |", "|---|---|---|"]
CLS = {"101": "Tạm thời", "103": "Tạm thời", "104": "Tạm thời", "105": "Tạm thời", "106": "Tạm thời", "114": "Tạm thời",
       "102": "Nghiệp vụ, không thử lại", "107": "Theo `faultMapping`", "108": "Dữ liệu (DLQ)", "109": "Dữ liệu (DLQ)", "110": "Dữ liệu (DLQ)",
       "111": "Dữ liệu (DLQ)", "113": "Dữ liệu (DLQ)", "112": "Thông tin, không lỗi", "115": "Nghiệp vụ, sự kiện an ninh", "119": "Nghiệp vụ, sự kiện an ninh",
       "116": "CDC: trạng thái PAUSED_SCHEMA", "117": "CDC: trạng thái FAILED", "118": "Nghiệp vụ, không thử lại", "120": "Nghiệp vụ, không thử lại"}
for c, http, m in errs:
    n = c[-3:]
    if n.startswith("1"): r2.append(f"| {c} | {m.strip()} | {CLS.get(n, '')} |")
    else: r1.append(f"| {c} | {http.strip()} | {m.strip()} | {fmt(uses.get(c, [])) or 'Chung'} |")
blk = "<!-- gen:errors:start -->\n### 6.1. Lỗi API điều khiển (ERR-05-001…040)\n\n" + "\n".join(r1) + \
      "\n\n### 6.2. Lỗi runtime (ERR-05-101…120)\n\nKhông trả qua API này; Kamelet giao thức ném ngoại lệ mang mã, PH-04 ánh xạ sang lớp lỗi và ERR-04-1xx trả cho bên gọi luồng.\n\n" + \
      "\n".join(r2) + "\n<!-- gen:errors:end -->"
s = open(DOC, encoding="utf-8").read()
open(DOC, "w", encoding="utf-8").write(re.sub(r"<!-- gen:errors:start -->.*?<!-- gen:errors:end -->", lambda m: blk, s, flags=re.S))
print(len(errs), "mã lỗi")
