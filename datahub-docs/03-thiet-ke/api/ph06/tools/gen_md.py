#!/usr/bin/env python3
"""Sinh các khối bảng của D03-04-PH06 từ spec.py, OpenAPI và AsyncAPI: danh mục endpoint, tách dòng gộp, sự kiện, mã lỗi, FR → API.
Chạy từ thư mục api/ph06:  python3 tools/gen_md.py [--write]
Với --write thay đoạn giữa <!-- gen:X:start --> và <!-- gen:X:end --> trong ../D03-04-PH06-api-du-lieu-chu.md."""
import os, re, sys, yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

ROOT = spec.ROOT
DOC = os.path.join(ROOT, "..", "D03-04-PH06-api-du-lieu-chu.md")
oa = yaml.safe_load(open(os.path.join(ROOT, "openapi-mdm.yaml"), encoding="utf-8"))
aa = yaml.safe_load(open(os.path.join(ROOT, "asyncapi-mdm.yaml"), encoding="utf-8"))
OPS = {}
for path, item in oa["paths"].items():
    for m, o in item.items():
        OPS[o["x-datahub-id"][-3:]] = (m.upper(), path, o)
FR_TITLE = dict(re.findall(r"^\| (FR-06-\d{3}) \| [A-H] \| ([^|]+?) \|", spec.FRS, re.M))
NO_API = {12: "Bên nhận sự kiện PH-10 (module `mdm`), không có API; xem 4.3", 14: "Hệ thống chuẩn hóa; xem trước ở 029", 15: "Hệ thống chuẩn hóa; xem trước ở 029",
          16: "Hệ thống; kết quả theo 021", 20: "Hệ thống; kết quả qua 071", 21: "Hệ thống; kết quả qua 071", 27: "Hệ thống tạo mục; xem ở 045",
          34: "Hệ thống; xem ở 056, 063", 50: "Sự kiện EVT-06-01…06, 14 (mục 4)", 52: "Hệ thống che dữ liệu trong mọi phản hồi (mục 2.3)"}


def endpoints():
    L = []
    for tag in spec.TAGS:
        L += ["**%s**" % tag, "", "| Mã | Phương thức, đường dẫn | Quyền (PERM-06-) | FR | Chống trùng, khóa | HTTP |", "|---|---|---|---|---|---|"]
        for c in sorted(OPS):
            m, p, o = OPS[c]
            if o["tags"][0] != tag:
                continue
            q = o["x-datahub-permission"]["permission"].replace("PERM-06-", "").replace(" hoặc scope ", " hoặc ")
            fl = ", ".join(x for x in (["Idem"] if o.get("x-datahub-idempotent") else []) + (["If-Match"] if o.get("x-datahub-if-match") else []) + (["X-Purpose"] if any(pp.get("$ref", "").endswith("XPurpose") for pp in o["parameters"]) else []))
            ok = ",".join(k for k in o["responses"] if k.startswith("2"))
            L.append(f"| API-06-{c} | `{m} {p}` | {q} | {', '.join(x[-3:] for x in o['x-datahub-fr'])} | {fl or '-'} | {ok} |")
        L += ["", ": Danh mục endpoint · %s" % tag, ""]
    return "\n".join(L).rstrip()


def split():
    byrow = {}
    for c, meth, path, act, frs_, g in spec.ROWS:
        byrow.setdefault(g, []).append((c, meth, path))
    L = ["| Dòng FRS 9.4 | Hành động gộp | Giữ mã cho | Mã cấp mới |", "|---|---|---|---|"]
    for g, xs in byrow.items():
        if len(xs) > 1:
            acts = " · ".join("`:%s`" % x[2].rsplit(":", 1)[1] for x in xs)
            L.append(f"| API-06-{g} | `{xs[0][2].rsplit(':', 1)[0]}` {acts} | `:{xs[0][2].rsplit(':', 1)[1]}` | " + "; ".join(f"API-06-{x[0]} `:{x[2].rsplit(':', 1)[1]}`" for x in xs[1:]) + " |")
    L += ["", ": Tách dòng gộp của FRS", ""]
    return "\n".join(L).rstrip()


def events():
    L = ["| Mã | Topic | Khi nào | Khóa | Payload `data` | Bên nhận |", "|---|---|---|---|---|---|"]
    for (code, topic, when, who), (ck, ch) in zip(spec.EVT, aa["channels"].items()):
        msg = aa["components"]["messages"][ck]
        key = re.search(r"`(\w+)`", msg["bindings"]["kafka"]["key"]["description"]).group(1)
        data = aa["components"]["schemas"][ck + "Event"]["properties"]["data"]["$ref"].split("/")[-1]
        L.append(f"| {code} | `{ch['address']}` | {when} | `{key}` | `{data}` | {who} |")
    L += ["", ": Sự kiện của PH-06", ""]
    return "\n".join(L).rstrip()


def errors():
    used = {}
    for c in sorted(OPS):
        for e in OPS[c][2]["x-datahub-errors"]:
            used.setdefault(e, []).append(c)
    L = ["| Mã | HTTP | Ý nghĩa | API phát sinh (API-06-) |", "|---|---|---|---|"]
    for e, (st, txt) in spec.ERR.items():
        u = used.get(e, [])
        if int(e[-3:]) > 100:
            ref = "Không trả cho người gọi"
        elif not u:
            ref = "Ứng viên mang cảnh báo, không trả lỗi" if e == "ERR-06-020" else "-"
        elif len(u) > 6:
            ref = f"{len(u)} API"
        else:
            ref = ", ".join(u)
        L.append(f"| {e} | {', '.join(map(str, st)) or '-'} | {txt} | {ref} |")
    L += ["", ": Mã lỗi ERR-06", ""]
    return "\n".join(L).rstrip()


def fr():
    m = {}
    for c in sorted(OPS):
        for f in OPS[c][2]["x-datahub-fr"]:
            m.setdefault(f, []).append(c)
    L = ["| FR | Tên | API (API-06-) |", "|---|---|---|"]
    for n in range(1, 61):
        f = "FR-06-%03d" % n
        L.append(f"| {f} | {FR_TITLE[f]} | {', '.join(m[f]) if f in m else NO_API[n]} |")
    L += ["", ": Truy vết FR-06 sang API", ""]
    return "\n".join(L).rstrip()


BLOCKS = {"endpoints": endpoints, "split": split, "events": events, "errors": errors, "fr": fr}
if __name__ == "__main__":
    miss = [n for n in range(1, 61) if "FR-06-%03d" % n not in {f for c in OPS for f in OPS[c][2]["x-datahub-fr"]} and n not in NO_API]
    if miss:
        print("FR chưa có API:", miss); sys.exit(1)
    if "--write" in sys.argv:
        doc = open(DOC, encoding="utf-8").read()
        for k, f in BLOCKS.items():
            doc, n = re.subn(r"(<!-- gen:%s:start -->\n).*?(<!-- gen:%s:end -->)" % (k, k), lambda mm: mm.group(1) + f() + "\n" + mm.group(2), doc, flags=re.S)
            print(k, "đã chèn" if n else "THIẾU cặp đánh dấu")
        open(DOC, "w", encoding="utf-8").write(doc)
    else:
        for k, f in BLOCKS.items():
            print("---", k); print(f())
