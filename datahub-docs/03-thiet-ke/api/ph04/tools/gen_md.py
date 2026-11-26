#!/usr/bin/env python3
"""Sinh hai phần của D03-04-PH04 từ nguồn hợp đồng:

1. Bảng endpoint (§3) từ gen_openapi.E, chèn giữa <!-- gen:endpoints:start/end -->.
2. Đặc tả từng sự kiện (§4.2) từ gen_asyncapi.build(), chèn giữa <!-- gen:dac-ta-evt:start/end -->:
   mỗi sự kiện một khối `::: dac-ta` gồm mục đích, kênh, khóa, lược đồ, tiêu đề, phân vùng và thời gian giữ,
   bên phát, bên nhận, FR, ví dụ payload.

Chạy: python3 tools/gen_md.py   (sau gen_openapi.py, gen_asyncapi.py). Chương đặc tả từng endpoint sinh riêng bằng
build/tools/sinh_dac_ta_api.py --vi-du.
"""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_openapi as g
import gen_asyncapi as ga
DOC = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "D03-04-PH04-api-tich-hop.md")


def thay(s, ten, khoi):
    a, b = f"<!-- gen:{ten}:start -->", f"<!-- gen:{ten}:end -->"
    block = a + "\n" + khoi.strip("\n") + "\n" + b
    if a not in s: raise SystemExit(f"Thiếu cặp đánh dấu {a}")
    return re.sub(re.escape(a) + ".*?" + re.escape(b), lambda m: block, s, flags=re.S)


# ---------------------------------------------------------------- bảng endpoint
rows, cur = [], None
for e in g.E:
    if e["tag"] != cur:
        cur = e["tag"]; rows.append(f"\n**{cur}**\n\n| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |\n|---|---|---|---|---|---|---|")
    perm = f"`{e['perm']}`" + (f" ({e['ws']})" if e["ws"] else "")
    ok = str(e["ok"][0]) + (" SSE" if e["sse"] else "")
    rows.append(f"| {e['aid']} | `{e['method'].upper()} {e['path']}` | {e['summary']} | {', '.join(x.replace('FR-04-', '') for x in e['fr'])} | {perm} | {'có' if e['idem'] else ''} | {ok} |")
# chú thích bảng theo nhóm (K-TRINH-BAY §2): chèn dòng ": Endpoint nhóm …" sau mỗi bảng
out, nhom = [], None
for r in rows:
    if r.startswith("\n**"):
        if nhom: out.append(f"\n: Endpoint nhóm {nhom}")
        nhom = r.split("**")[1]
    out.append(r)
out.append(f"\n: Endpoint nhóm {nhom}")
endpoints = "\n".join(out).lstrip("\n")

# ---------------------------------------------------------------- đặc tả sự kiện
RONG = 62


def gon(v, thut=0):
    mot = json.dumps(v, ensure_ascii=False)
    if len(mot) + thut <= RONG or not isinstance(v, (dict, list)) or not v:
        return mot
    mo, dong = ("{", "}") if isinstance(v, dict) else ("[", "]")
    cap = [(json.dumps(k, ensure_ascii=False) + ": ", x) for k, x in v.items()] if isinstance(v, dict) else [("", x) for x in v]
    dong_ra, cur = [], mo
    for i, (k, x) in enumerate(cap):
        t = k + gon(x, thut + 1) + (", " if i < len(cap) - 1 else "")
        dau = t.split("\n")[0]
        if cur.strip() != mo and len(cur) + len(dau) > RONG:
            dong_ra.append(cur.rstrip()); cur = " " * (thut + 1)
        if "\n" in t:
            ph = t.split("\n"); dong_ra.append(cur + ph[0]); dong_ra += ph[1:-1]; cur = ph[-1]
        else:
            cur += t
    dong_ra.append(cur.rstrip() + dong)
    return "\n".join(dong_ra)


a = ga.build()
S = a["components"]["schemas"]


def truong(ten):
    sch = S[ten]
    parts = sch.get("allOf", [sch])
    req, props = [], []
    for p in parts:
        if "$ref" in p: p = S[p["$ref"].split("/")[-1]]
        req += p.get("required", []); props += list(p.get("properties", {}))
    return req, props


L = []
for key, code, addr, payload, summ, ten, days, parts in ga.EV:
    ch, msg = a["channels"][key], a["components"]["messages"][key]
    req, props = truong(payload)
    khoa = msg["bindings"]["kafka"]["key"]["description"]
    hdr = "CloudEvents 1.0 nhị phân: " + ", ".join(f"`{h}`" for h in ga.CE_HEADERS["required"]) + f"; `ce_type = vn.datahub.integration.{key}.v1`" \
        if ten and key != "connectionLog" else "`traceparent`, `ce_id` (không qua outbox, không theo CloudEvents đầy đủ)"
    nguon = "Outbox `ph04.outbox`, Debezium đưa lên Kafka" if ten and key != "connectionLog" else (
        "Ghi trực tiếp sau khi lưu `runtime_command` (độ trễ < 5 giây, NFR-04-010)" if key == "runtimeCommand" else "Phát trực tiếp từ runtime")
    rows = [
        ("Mục đích", summ),
        ("Kênh, topic", f"`{addr}`" + (" (tenant chữ thường, ví dụ `t68`)" if ten else " (topic hệ thống, ACL chỉ `dh-integration`, `dh-runtime`)")),
        ("Khóa phân vùng", khoa),
        ("Lược đồ", f"`{payload}` trong `asyncapi-integration.yaml`; trường bắt buộc: " + ", ".join(f"`{x}`" for x in req) + f"; tổng {len(props)} trường"),
        ("Tiêu đề", hdr),
        ("Phân vùng, thời gian giữ", f"{parts} phân vùng, 3 bản sao; giữ {days} ngày; `cleanup.policy = delete`"),
        ("Bên phát", f"`{msg['x-datahub-sender']}`; {nguon}"),
        ("Bên nhận", "; ".join(msg["x-datahub-receivers"])),
        ("FR", ", ".join(msg["x-datahub-fr"])),
    ]
    L += [f"#### {code} · {summ.split(' (')[0].rstrip('.')}", "", "::: dac-ta"]
    L += [f"**{k}.** {v.rstrip('.')}.\n" for k, v in rows]
    L += ["**Ví dụ payload.**", "", "```json", gon(msg["examples"][0]["payload"]), "```", ":::", ""]
events = "\n".join(L)

s = open(DOC, encoding="utf-8").read()
s = thay(s, "endpoints", endpoints)
if "<!-- gen:dac-ta-evt:start -->" in s:
    s = thay(s, "dac-ta-evt", events)
open(DOC, "w", encoding="utf-8").write(s)
print(len(g.E), "dòng endpoint,", len(ga.EV), "sự kiện")
