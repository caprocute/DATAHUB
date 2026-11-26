#!/usr/bin/env python3
"""Sinh các bảng của D03-04-PH19 từ cùng nguồn với hợp đồng: §3 endpoint, §4 sự kiện, §6 mã lỗi.
Chèn giữa các cặp <!-- gen:endpoints|events|errors:start/end -->. Chạy: python3 tools/gen_md.py (từ api/ph19)."""
import os, re, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import gen_openapi as g  # noqa: E402
import gen_asyncapi as ga  # noqa: E402
DOC = os.path.join(os.path.dirname(os.path.dirname(HERE)), "D03-04-PH19-api-thanh-toan.md")

def endpoints():
    rows, cur, curg = [], None, None
    names = {"admin": "API quản trị `/api/payment/v1`", "partner": "API đối tác `/api/payment-partner/v1`", "callback": "API callback `/api/payment-callback/v1`"}
    for e in sorted(g.ENDPOINTS, key=lambda e: e["aid"]):
        det = g.D[e["aid"]]; grp = g.group(e)
        if grp != curg:
            curg = grp; rows.append(f"\n#### {names[grp]}\n"); cur = None
        if det["tag"] != cur:
            cur = det["tag"]
            rows.append(f"\n**{cur}**\n\n| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền `PERM-19-` | Khóa | Thành công |\n|---|---|---|---|---|---|---|")
        path = e["path"].replace(g.INFO[grp][1], "") if grp != "admin" else e["path"]
        lock = ", ".join(x for x in [("If-Match" if det["ifm"] else ""), ({"req": "Idem bắt buộc", "opt": "Idem"}.get(det["idem"], ""))] if x)
        frs = ", ".join(x.replace("FR-19-", "") for x in g.expand_fr(e["fr"]))
        perm = e["perm"].replace("|", "\\|") if grp != "callback" else "—"
        rows.append(f"| {e['aid']} | `{e['method'].upper()} {path}` | {e['summary']} | {frs} | {perm} | {lock} | {det['ok'][0]} |")
    return "\n".join(rows).lstrip("\n")

def events():
    doc = ga.build()
    out = ["| Mã | Topic | Thân | Giữ, phân vùng | Webhook |", "|---|---|---|---|---|"]
    for key, ch in doc["channels"].items():
        m = doc["components"]["messages"][key]
        b = ch["bindings"]["kafka"]
        out.append(f"| {ch['title']} | `{ch['address']}` | `{m['payload']['$ref'].split('/')[-1]}` | {b['topicConfiguration']['retention.ms'] // 86400000} ngày, {b['partitions']} | {'có' if m['x-datahub-webhook'] else ''} |")
    return "\n".join(out)

def errors():
    out = ["| Mã | HTTP | Tiêu đề | Khi nào | Thử lại |", "|---|---|---|---|---|"]
    for c, (st, t, w, r) in g.ERRS.items():
        out.append(f"| {c} | {st} | {t} | {w} | {r} |")
    return "\n".join(out)

s = open(DOC, encoding="utf-8").read()
for tag, fn in [("endpoints", endpoints), ("events", events), ("errors", errors)]:
    block = f"<!-- gen:{tag}:start -->\n" + fn() + f"\n<!-- gen:{tag}:end -->"
    s = re.sub(rf"<!-- gen:{tag}:start -->.*?<!-- gen:{tag}:end -->", lambda m: block, s, flags=re.S)
open(DOC, "w", encoding="utf-8").write(s)
print("đã sinh bảng §3, §4, §6:", len(g.ENDPOINTS), "API,", len(g.ERRS), "mã lỗi")
