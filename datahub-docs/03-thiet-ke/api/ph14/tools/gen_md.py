#!/usr/bin/env python3
"""Sinh bảng §3 (endpoint), §4 (sự kiện), §6 (mã lỗi) của D03-04-PH14 từ spec.py và OpenAPI, chèn giữa các cặp <!-- gen:... -->.

Chạy: python3 tools/gen_md.py   (từ thư mục api/ph14).
"""
import os, re, sys, yaml
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec
import gen_openapi as g

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(HERE), "D03-04-PH14-api-ket-noi-quoc-gia.md")
oa = yaml.safe_load(open(os.path.join(HERE, "openapi-national.yaml"), encoding="utf-8"))
ops = {}
for p, m in oa["paths"].items():
    for meth, o in m.items():
        ops[o["x-datahub-id"]] = (meth.upper(), p, o)


def put(tag, block, s):
    pat = rf"<!-- gen:{tag}:start -->.*?<!-- gen:{tag}:end -->"
    new = f"<!-- gen:{tag}:start -->\n{block}\n<!-- gen:{tag}:end -->"
    if not re.search(pat, s, flags=re.S):
        raise SystemExit(f"thiếu cặp đánh dấu gen:{tag} trong {DOC}")
    return re.sub(pat, lambda _: new, s, flags=re.S)


def perm_txt(perm):
    if perm.startswith("svc:"):
        return f"`{perm[4:]}` (dịch vụ)"
    if perm == "edge":
        return "mTLS nguồn được phép"
    out = f"`PERM-14-{perm}`"
    return out


# ---- §3
rows, cur = [], None
for code, method, path, summary, fr, perm, idem, success, group in sorted(spec.OPS, key=lambda o: (list(spec.TAGS).index(o[8]), o[0])):
    if group != cur:
        cur = group
        rows.append(f"\n**{spec.TAGS[group]}**\n\n| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |\n|---|---|---|---|---|---|---|")
    p = perm_txt(perm)
    if code in g.SVC_ALSO:
        p += f" hoặc `{g.SVC_ALSO[code]}` (dịch vụ)"
    idm = {"x": "bắt buộc", "o": "tùy chọn"}.get(idem, "")
    short = path.replace(spec.C, "").replace("/api/national/v1", "") if path.startswith(spec.C) else path
    rows.append(f"| API-14-{code} | `{method} {short}` | {summary} | {fr} | {p} | {idm} | {success} |")
# đóng bảng bằng chú thích: chèn dòng ": ..." sau mỗi bảng
blk = "\n".join(rows).lstrip("\n")
parts = re.split(r"(\n\*\*[^\n]+\*\*\n)", "\n" + blk)
out = []
for i, part in enumerate(parts):
    out.append(part)
blk = "".join(out).strip("\n")
# thêm chú thích cho từng bảng
tables = re.split(r"\n\n(?=\*\*)", blk)
blk = "\n\n".join(t.rstrip("\n") + "\n\n: Danh mục endpoint · " + re.match(r"\*\*([^*]+)\*\*", t).group(1) for t in tables)

s = open(DOC, encoding="utf-8").read()
s = put("endpoints", blk, s)

# ---- §4
ev = ["| Mã | Chủ đề | Người phát | Qua | Khóa phân vùng | Giữ | Người nhận |", "|---|---|---|---|---|---|---|"]
for key, code, addr, payload, summ, days, parts_, sender, via, kdesc, recv in spec.EVTS:
    ev.append(f"| {code} | `{addr}` | `{sender}` | {via} | {kdesc} | {days} ngày | {recv} |")
ev.append("\n: Danh mục sự kiện của PH-14")
s = put("events", "\n".join(ev), s)

# ---- §6
uses = {}
for aid, (m, p, o) in ops.items():
    for e in o["x-datahub-errors"]:
        uses.setdefault(e, []).append(aid.replace("API-14-", ""))


def fmt(lst):
    lst = sorted(set(lst))
    return ", ".join(lst) if len(lst) <= 8 else ", ".join(lst[:8]) + f" và {len(lst) - 8} API khác"


CLS = {"101": "Tạm thời, thử lại", "102": "Nghiệp vụ, không thử lại", "103": "Tạm thời, thử lại", "104": "Hoãn, không thử lại ngay", "105": "Cấu hình", "106": "An ninh, nghiệp vụ",
       "107": "Nghiệp vụ", "108": "Dữ liệu", "109": "An ninh, mở sự cố chữ ký", "110": "An ninh, mở sự cố chữ ký", "111": "An ninh, mở sự cố chữ ký", "112": "Tạm thời, thử lại",
       "113": "Chặn ký, cảnh báo cao nhất", "114": "Tạm thời, cảnh báo SO", "115": "Tạm thời, thử lại thao tác đọc", "116": "Nghiệp vụ", "117": "Nghiệp vụ", "118": "Tạm thời",
       "119": "An ninh, cảnh báo SO", "120": "An ninh", "121": "Dữ liệu", "122": "An ninh, chống phát lại", "123": "Hoãn", "124": "Tạm thời", "125": "Dữ liệu", "126": "An ninh, nghiệp vụ",
       "127": "Nội bộ", "128": "Dữ liệu, cảnh báo", "129": "Nghiệp vụ", "130": "Nghiệp vụ", "131": "Tạm thời, dùng bản đã lưu", "132": "An ninh, đóng an toàn", "133": "Tạm thời, đóng an toàn"}
r1 = ["| Mã | HTTP | Ý nghĩa | API phát sinh (API-14-) |", "|---|---|---|---|"]
r2 = ["| Mã | HTTP | Ý nghĩa | Lớp lỗi | API phát sinh (API-14-) |", "|---|---|---|---|---|"]
for c, http, m in spec.ERRS:
    code = f"ERR-14-{c}"
    if c.startswith("1"):
        r2.append(f"| {code} | {http} | {m} | {CLS.get(c, '')} | {fmt(uses.get(code, [])) or 'Mặt phẳng dữ liệu'} |")
    else:
        r1.append(f"| {code} | {http} | {m} | {fmt(uses.get(code, [])) or 'Chung'} |")
blk = ("### 6.1. Lỗi mặt phẳng điều khiển (ERR-14-001…099)\n\n" + "\n".join(r1) + "\n\n: Mã lỗi mặt phẳng điều khiển ERR-14\n\n" +
       "### 6.2. Lỗi mặt phẳng dữ liệu (ERR-14-101…199)\n\nTrả cho HTTT, luồng PH-04, PH-07 qua API-14-075…083 và cho nền tảng quốc gia qua API-14-084, 085. Cột \"Lớp lỗi\" cho cổng và PH-04 biết có thử lại hay mở sự cố.\n\n" +
       "\n".join(r2) + "\n\n: Mã lỗi mặt phẳng dữ liệu ERR-14")
s = put("errors", blk, s)
open(DOC, "w", encoding="utf-8").write(s)

# ---- §11 phủ FR
FRS = os.path.join(os.path.dirname(HERE), "..", "..", "02-yeu-cau", "frs", "D02-03-PH14-frs-ket-noi-quoc-gia.md")
frows = re.findall(r"^\| (FR-14-\d{3}) \| ([^|]+) \| ([^|]+) \| ([MSC]) \| ([^|]+) \|", open(FRS, encoding="utf-8").read(), re.M)
cov = {}
for code, m, p_, sm, fr, *_ in spec.OPS:
    for part in fr.split(","):
        part = part.strip()
        a, b = (part.split("-") if "-" in part else (part, part))
        for i in range(int(a), int(b) + 1):
            cov.setdefault(i, []).append(code)
NOAPI = {
    11: "Hiện thực ở chặng `purpose` của API-14-075, 076 (ERR-14-106, 107, 132); cờ `purposeRequired` khai ở API-14-011, 013",
    14: "Hiện thực ở chặng chuyển đổi bản tin trong cổng; hợp đồng và đặc tả khai ở API-14-011, 019",
    15: "Hiện thực ở chặng `normalize` trong cổng; lỗi trả ERR-14-102, 128 ở phản hồi API-14-075",
    26: "Hiện thực ở chặng gửi của API-14-075; chứng thư và khóa quản lý ở API-14-030…034, kiểm khớp khóa ở API-14-030",
    27: "Hiện thực ở chặng `verify` của API-14-075, 084; sự cố chữ ký xem ở API-14-037, 038",
    37: "Dùng đệm quá hạn qua tiêu đề `X-DH-Accept-Stale` ở API-14-075; cờ `staleAllowed` khai ở API-14-011",
}
fr_rows = ["| FR | Chức năng | Mức, đợt | API |", "|---|---|---|---|"]
for code, grp, name, lvl, wave in frows:
    n = int(code[-3:])
    apis = ", ".join(sorted(cov.get(n, []))) if n in cov else ""
    cell = ("API-14-" + apis.replace(", ", ", ")) if apis else NOAPI[n]
    fr_rows.append(f"| {code} | {name.strip()} | {lvl}, {wave.strip()} | {cell} |")
fr_rows.append("\n: Phủ FR bằng API")
s = open(DOC, encoding="utf-8").read()
s = put("fr-cover", "\n".join(fr_rows), s)
open(DOC, "w", encoding="utf-8").write(s)

print(len(spec.OPS), "dòng endpoint,", len(spec.ERRS), "mã lỗi,", len(spec.EVTS), "sự kiện")
