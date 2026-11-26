#!/usr/bin/env python3
"""Sinh các khối giữa <!-- gen:NAME:start --> và <!-- gen:NAME:end --> của D03-04-PH02:
endpoints (§3), fr-api (§3.3), events (§4), errors (§6.1). Nguồn: spec.OPS, gen_asyncapi.EVENTS, FRS §9.1.
Chạy: python3 tools/gen_md.py (sau gen_openapi.py, gen_asyncapi.py)."""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_asyncapi as ga  # noqa: E402
import gen_openapi as g  # noqa: E402
import spec  # noqa: E402

DOC = os.path.join(os.path.dirname(HERE), "..", "D03-04-PH02-api-danh-muc-dich-vu.md")


def perm_txt(code, perm, x):
    if perm == "service":
        return f"Token dịch vụ `{x.get('svc')}`"
    p = g.ANY_PERM.get(code, g.PERM[perm])
    if perm == "admin":
        return p
    p = " hoặc ".join(f"`{q.strip()}`" for q in p.split(" hoặc "))
    if x.get("svc") and code in ("004", "005", "007", "079"):
        p += f"; hoặc token máy `{x['svc']}`"
    return p


def replace(s, name, block):
    pat = re.compile(rf"<!-- gen:{name}:start -->.*?<!-- gen:{name}:end -->", re.S)
    assert pat.search(s), f"thiếu cặp đánh dấu gen:{name}"
    return pat.sub(lambda m: f"<!-- gen:{name}:start -->\n{block}\n<!-- gen:{name}:end -->", s)


def endpoints():
    out = []
    for gk, gname in spec.TAGS.items():
        rows = [o for o in spec.OPS if o[8] == gk]
        if not rows:
            continue
        out.append(f"**{gname}**\n\n| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |\n|---|---|---|---|---|---|---|")
        for code, method, path, summary, fr, perm, idem, success, group, x in rows:
            ok = "/".join([success] + list(x.get("ok2", [])))
            wave = " (Đợt 2)" if x.get("wave") else ""
            out.append(f"| API-02-{code} | `{method} {path}` | {summary}{wave} | {fr} | {perm_txt(code, perm, x)} | {'có' if idem else ''} | {ok} |")
        out.append(f"\n: Danh mục endpoint · {gname}\n")
    return "\n".join(out).rstrip()


def fr_api():
    m = {}
    for code, method, path, summary, fr, *_ in spec.OPS:
        for n in re.findall(r"\d+", fr):
            m.setdefault(int(n), []).append(code)
    miss = [n for n in range(1, 63) if n not in m]
    out = ["| FR | API |", "|---|---|"]
    for n in range(1, 63):
        out.append(f"| FR-02-{n:03d} | " + (", ".join(f"API-02-{c}" for c in sorted(m[n])) if n in m else "không có API (chỉ giao diện)") + " |")
    out.append("\n: Truy vết FR → API")
    print("FR không có API:", miss)
    return "\n".join(out)


def events():
    out = ["| Mã | Topic | Người phát | Khóa | Giữ | Người nhận | FR |", "|---|---|---|---|---|---|---|"]
    for n, key, ev, fr, cons, pkey, days, desc, schema in ga.EVENTS:
        out.append(f"| EVT-02-{n} | `{{tenant}}.catalog.{ev}.v1` | `dh-connect` (outbox) | `{pkey}` | {days} ngày | {cons} | {fr} |")
    out.append("\n: Danh mục sự kiện phát ra")
    return "\n".join(out)


def errors():
    frs_lines = open(g.FRS, encoding="utf-8").read()
    errs = re.findall(r"^\| (ERR-02-\d{3}) \| (\d{3}) \| ([^|]+) \|$", frs_lines, re.M)
    uses = {}
    for code, method, path, summary, fr, perm, idem, success, group, x in spec.OPS:
        for e in x.get("errs", []):
            uses.setdefault("ERR-02-" + e, []).append(code)
    ALL = {"ERR-02-001": "Chung (mọi API có tham số đường dẫn)", "ERR-02-003": "Chung (mọi API có thân hoặc tham số truy vấn)", "ERR-02-014": "Chung",
           "ERR-02-015": "Chung (mọi lệnh có `If-Match`)", "ERR-02-042": "Chung (mọi `POST` có `Idempotency-Key`)"}

    def fmt(lst):
        lst = sorted(set(lst))
        return ", ".join(lst) if len(lst) <= 8 else ", ".join(lst[:8]) + f" và {len(lst) - 8} API khác"
    out = ["| Mã | HTTP | Ý nghĩa | API phát sinh (API-02-) |", "|---|---|---|---|"]
    unused = []
    for c, http, m in errs:
        a = ALL.get(c) or fmt(uses.get(c, []))
        if not a:
            unused.append(c)
            a = "Runtime của PH-02 (tác vụ nền, không qua API)"
        out.append(f"| {c} | {http} | {m.strip()} | {a} |")
    out.append("\n: Mã lỗi ERR-02")
    print("ERR không gắn API:", unused)
    return "\n".join(out)


def main():
    s = open(DOC, encoding="utf-8").read()
    s = replace(s, "endpoints", endpoints())
    s = replace(s, "fr-api", fr_api())
    s = replace(s, "events", events())
    s = replace(s, "errors", errors())
    open(DOC, "w", encoding="utf-8").write(s)
    print(len(spec.OPS), "operation vào tài liệu")


if __name__ == "__main__":
    main()
