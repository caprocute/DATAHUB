#!/usr/bin/env python3
"""Sinh các bảng của D03-04-PH10 từ spec.OPS, gen_openapi, gen_asyncapi và FRS; chèn giữa cặp dấu <!-- gen:{tên}:start/end -->.

Bảng sinh: endpoints (§3), split (§3.1), events (§4.1), errors (§6), fr (§9), proposals (§10.1). Không sửa tay các bảng này.
"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec, gen_openapi as g, gen_asyncapi as ga

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(HERE), "D03-04-PH10-api-su-kien.md")
FRS_TXT = open(g.FRS, encoding="utf-8").read()

def perm_md(code, perm):
    if code in g.ANY_PERM:
        return " hoặc ".join(f"`{x[6:]}` (dịch vụ)" if x.startswith("scope:") else f"`{x}`" for x in g.ANY_PERM[code])
    if perm.startswith("svc:"): return f"`{perm[4:]}` (dịch vụ)"
    if perm == "topic:publish": return "`topic:{topicName}:publish`"
    if perm == "topic:subscribe": return "`topic:{topicName}:subscribe`"
    if perm == "topic:any": return "`topic:{topicName}:publish` hoặc `:subscribe`"
    return f"`PERM-10-{perm}`"

def full_path(group, path):
    return (spec.DATA_BASE if group in g.DATA_GROUPS else "") + path

def own_errs(own):
    return ", ".join(own.split()) if own else ""

blocks = {}
# ---- §3 endpoints
rows, cur = [], None
for code, method, path, summary, fr, perm, idem, success, group, own in spec.OPS:
    if group != cur:
        cur = group
        rows.append(f"\n**{g.TAGS[group]}**\n\n| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Idem. | Thành công | Lỗi riêng (ERR-10-) |\n|---|---|---|---|---|---|---|---|")
    idm = {"x": "bắt buộc", "o": "tùy chọn"}.get(idem, "")
    rows.append(f"| API-10-{code} | `{method} {full_path(group, path)}` | {summary} | {fr} | {perm_md(code, perm)} | {idm} | {success} | {own_errs(own)} |")
blocks["endpoints"] = "\n".join(rows).lstrip("\n")
# ---- §3.1 tách mã
sec83 = FRS_TXT[FRS_TXT.index("### 9.4."):FRS_TXT.index("## 10.")]
frs_rows = dict(re.findall(r"^\| (API-10-\d{3}) \| (.+?) \| [^|]+ \|$", sec83, re.M))
ops = {o[0]: o for o in spec.OPS}
r = ["| Dòng FRS §8.3 | Nội dung gộp ở FRS | Giữ mã cho | Mã cấp mới |", "|---|---|---|---|"]
for k, new in spec.SPLIT.items():
    o = ops[k]
    news = "; ".join(f"API-10-{n} `{ops[n][1]} {full_path(ops[n][8], ops[n][2])}`" for n in new)
    r.append(f"| API-10-{k} | {frs_rows['API-10-' + k]} | `{o[1]} {full_path(o[8], o[2])}` | {news} |")
blocks["split"] = "\n".join(r)
# ---- §4.1 sự kiện
r = ["| Mã | Topic | Khi nào | Khóa | Payload | Bên nhận | FR |", "|---|---|---|---|---|---|---|"]
for key, code, entity, ev, payload, summ, kfield, receivers, fr, _ in ga.EV:
    r.append(f"| {code} | `{{tenant}}.event.{entity}.{ev}.v1` | {summ} | `{kfield}` | `{payload}` | {receivers} | {fr.replace('FR-10-', '')} |")
blocks["events"] = "\n".join(r)
# ---- §6 lỗi
uses = {}
for code, method, path, summary, fr, perm, idem, success, group, own in spec.OPS:
    opid, body, resp, desc, extra = g.X[code]
    for e in g.errs_of(code, method, path, body or code in ("075", "079"), own, idem, None):
        uses.setdefault("ERR-10-" + e, set()).add(code)
def fmt(lst):
    lst = sorted(lst)
    if not lst: return ""
    if len(lst) > 12: return f"{len(lst)} API"
    return ", ".join(lst)
CLS = {"111": "Tạm thời, thử lại", "112": "Tạm thời, thử lại", "113": "Vĩnh viễn, DLQ ngay", "114": "Tạm thời; lặp lại thì cảnh báo ATTT",
       "115": "An ninh, DLQ ngay", "116": "Giải tuần tự, DLQ ngay", "117": "Tạm dừng phân vùng, không gửi không ký", "118": "DLQ của cầu nối",
       "119": "Tuân thủ lược đồ (chỉ số, EVT-10-14)", "120": "Chỉ số theo principal"}
r1 = ["| Mã | HTTP | Ý nghĩa | API phát sinh (API-10-) |", "|---|---|---|---|"]
r2 = ["| Mã | HTTP | Ý nghĩa | Nơi phát sinh |", "|---|---|---|---|"]
for c, (http, m) in sorted(g.ERRS.items()):
    n = c[-3:]
    if n.startswith("0"): r1.append(f"| {c} | {http} | {m} | {fmt(uses.get(c, [])) or 'Chung'} |")
    else:
        where = fmt(uses.get(c, [])) or CLS.get(n, "")
        if n in CLS: where = f"Lượt giao, DLQ (`errorCode`): {CLS[n]}"
        r2.append(f"| {c} | {http} | {m} | {where} |")
blocks["errors"] = ("### 6.1. Control plane (ERR-10-001…054)\n\n" + "\n".join(r1) +
    "\n\n### 6.2. Data plane và runtime (ERR-10-101…121)\n\nMã có HTTP trả qua cổng sự kiện hoặc API nội bộ; mã không có HTTP (111…120) không trả cho bên gọi mà ghi ở `DeliveryFailure.errorCode`, `DlqEntry.errorCode`, tiêu đề `dh_dlq_error_code` và chỉ số.\n\n" + "\n".join(r2))
# ---- §9 FR → API
frs = re.findall(r"^#### (FR-10-\d{3}) · (.+)$", FRS_TXT, re.M)
fr_api = {}
for code, method, path, summary, fr, *_ in spec.OPS:
    for part in fr.split(","):
        fr_api.setdefault("FR-10-" + part.strip(), []).append(code)
NOTE = {"FR-10-029": "Tiêu thụ sự kiện PH-01, EVT-04-09 (§5); kết quả thấy qua API-10-034, 039 (`suspendSource = PH01`)",
        "FR-10-034": "Kafka trực tiếp: kênh `businessTopic` ở AsyncAPI; cấu hình mẫu qua API-10-020",
        "FR-10-038": "Kênh `webhookDelivery` ở AsyncAPI; cấu hình qua API-10-073",
        "FR-10-040": "Trường `startPosition`, `startAt` của API-10-047; đổi sau khi chạy bằng API-10-064 (`RESET_OFFSET`)",
        "FR-10-044": "Kênh `businessTopic` qua listener `external`; báo lỗi qua API-10-083",
        "FR-10-045": "Subscription `INTERNAL` qua API-10-047, 072",
        "FR-10-048": "Đợt sau; chưa có trường ở FRS (§10.2)",
        "FR-10-049": "Kênh `deadLetterTopic`; xem qua API-10-060, 061; EVT-10-11",
        "FR-10-059": "Chỉ số OTLP sang PH-13, không qua API này",
        "FR-10-064": "Tiền tố tenant kiểm ở mọi API (ERR-10-005, 103)",
        "FR-10-065": "Kiểm toán qua outbox sang PH-13; tab Lịch sử đọc API của PH-13 (FR-00-043)"}
r = ["| FR | Tên | API (API-10-) |", "|---|---|---|"]
for f, name in frs:
    apis = ", ".join(sorted(set(fr_api.get(f, []))))
    note = NOTE.get(f, "")
    cell = "; ".join(x for x in (apis, note) if x) or "Chỉ giao diện"
    r.append(f"| {f} | {name.strip()} | {cell} |")
blocks["fr"] = "\n".join(r)
# ---- §10.1 trường, enum chỉ có ở API
import yaml
oa = yaml.safe_load(open(os.path.join(HERE, "openapi-event.yaml"), encoding="utf-8"))
aa = yaml.safe_load(open(os.path.join(HERE, "asyncapi-event.yaml"), encoding="utf-8"))
TOKENS = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*(?:-[A-Za-z0-9_]+)*", FRS_TXT)) | set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", FRS_TXT))
where = {}
def collect(schemas, src):
    for name, sch in schemas.items():
        def w(x):
            if isinstance(x, dict):
                for k, v in (x.get("properties") or {}).items():
                    if "-" in k or k.startswith("ce_") or k.startswith("dh_dlq") or k[0].isupper(): continue
                    if k not in TOKENS: where.setdefault(("trường", k), set()).add(name)
                for v in x.get("enum", []) if isinstance(x.get("enum"), list) else []:
                    if isinstance(v, str) and v not in TOKENS and f"`{v}`" not in FRS_TXT: where.setdefault(("enum", v), set()).add(name)
                for v in x.values(): w(v)
            elif isinstance(x, list):
                for v in x: w(v)
        w(sch)
collect(oa["components"]["schemas"], "oa")
collect(aa["components"]["schemas"], "aa")
r = ["| Loại | Tên | Lược đồ dùng | Đề nghị |", "|---|---|---|---|"]
for (kind, nm), sch in sorted(where.items(), key=lambda x: (x[0][0], x[0][1].lower())):
    r.append(f"| {kind} | `{nm}` | {', '.join(sorted(sch)[:4])}{' …' if len(sch) > 4 else ''} | Thêm vào A.3 (trường chỉ ở API) hoặc A.2.15 (enum chỉ ở API) |" )
blocks["proposals"] = "\n".join(r) if len(r) > 2 else "Không còn trường, enum nào chỉ có ở API: FRS bản 0.3 đã hấp thụ đủ vào A.2.15, A.3."

s = open(DOC, encoding="utf-8").read()
for k, v in blocks.items():
    pat = re.compile(rf"<!-- gen:{k}:start -->.*?<!-- gen:{k}:end -->", re.S)
    if not pat.search(s): print("thiếu dấu", k); continue
    s = pat.sub(lambda m: f"<!-- gen:{k}:start -->\n{v}\n<!-- gen:{k}:end -->", s)
open(DOC, "w", encoding="utf-8").write(s)
print(len(spec.OPS), "operation;", len(where), "trường, enum đề nghị;", len(frs), "FR")
