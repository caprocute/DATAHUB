#!/usr/bin/env python3
"""Sinh bảng endpoint (§3) của D03-04-PH04 từ gen_openapi.E, chèn giữa <!-- gen:endpoints:start/end -->."""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_openapi as g
DOC = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "D03-04-PH04-api-tich-hop.md")
rows, cur = [], None
for e in g.E:
    if e["tag"] != cur:
        cur = e["tag"]; rows.append(f"\n**{cur}**\n\n| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền (mức không gian) | Chống trùng | Thành công |\n|---|---|---|---|---|---|---|")
    perm = f"`{e['perm']}`" + (f" ({e['ws']})" if e["ws"] else "")
    ok = str(e["ok"][0]) + (" SSE" if e["sse"] else "")
    rows.append(f"| {e['aid']} | `{e['method'].upper()} {e['path']}` | {e['summary']} | {', '.join(x.replace('FR-04-', '') for x in e['fr'])} | {perm} | {'có' if e['idem'] else ''} | {ok} |")
block = "<!-- gen:endpoints:start -->\n" + "\n".join(rows).lstrip("\n") + "\n<!-- gen:endpoints:end -->"
s = open(DOC, encoding="utf-8").read()
s2 = re.sub(r"<!-- gen:endpoints:start -->.*?<!-- gen:endpoints:end -->", lambda m: block, s, flags=re.S)
assert s2 != s or block in s
open(DOC, "w", encoding="utf-8").write(s2)
print(len(g.E), "dòng")
