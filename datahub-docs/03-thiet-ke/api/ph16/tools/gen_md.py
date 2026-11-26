#!/usr/bin/env python3
"""Sinh các khối bảng của D03-04-PH16 từ spec.py, OpenAPI và AsyncAPI: danh mục endpoint, sự kiện, mã lỗi, thông báo, FR → API, đặc tả từng endpoint.
Chạy từ thư mục api/ph16:  python3 tools/gen_md.py [--write]
Với --write thay đoạn giữa <!-- gen:X:start --> và <!-- gen:X:end --> trong ../D03-04-PH16-api-bao-cao-chi-tieu.md.

Chương đặc tả từng endpoint dùng build/tools/sinh_dac_ta_api.py trên bản rút gọn của OpenAPI (ví dụ chỉ giữ trường bắt buộc và vài trường đầu).
Ví dụ đầy đủ của mọi endpoint nằm ở openapi-kpi.yaml; tập .md in ví dụ theo thứ tự ưu tiên cho tới hết ngân sách DAC_TA_BUDGET để giữ tập ≤ 240 KB."""
import copy, os, re, subprocess, sys, tempfile, yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

ROOT = spec.ROOT
DOC = os.path.join(ROOT, "..", "D03-04-PH16-api-bao-cao-chi-tieu.md")
TOOL = os.path.join(ROOT, "..", "..", "..", "build", "tools", "sinh_dac_ta_api.py")
DAC_TA_BUDGET = int(os.environ.get("DAC_TA_BUDGET", "900000"))
oa = yaml.safe_load(open(os.path.join(ROOT, "openapi-kpi.yaml"), encoding="utf-8"))
aa = yaml.safe_load(open(os.path.join(ROOT, "asyncapi-kpi.yaml"), encoding="utf-8"))
OPS = {}
for path, item in oa["paths"].items():
    for m, o in item.items():
        OPS[o["x-datahub-id"][-3:]] = (m.upper(), path, o)
GENERIC = {"ERR-16-001", "ERR-16-003", "ERR-16-004", "ERR-16-006", "ERR-16-057", "ERR-16-058"}  # mã chung, nêu ở mục 1 thay vì lặp ở từng endpoint
NO_API = {10: "Hệ thống tiêu thụ sự kiện Kafka, ghi nhật ký tiếp nhận; xem qua API-16-042, 043, 044", 46: "Hệ thống tiêu thụ trạng thái từ PH-13; xem qua API-16-096", 58: "Chỉ số Prometheus ở `/actuator/prometheus`, ngoài `/api/kpi/v1`"}


def endpoints():
    L = ["| Mã | Phương thức, đường dẫn | Quyền (PERM-16-) | FR | Khóa | HTTP |", "|---|---|---|---|---|---|"]
    for c in sorted(OPS):
        m, p, o = OPS[c]
        q = o["x-datahub-permission"]["permission"].replace("PERM-16-", "").replace(" hoặc scope ", " hoặc ").replace(" hoặc PERM-16-", " hoặc ").replace("scope ", "")
        ok = ",".join(k for k in o["responses"] if k.startswith("2"))
        fl = "+".join((["I"] if o.get("x-datahub-idempotent") else []) + (["M"] if o.get("x-datahub-if-match") else [])) or "-"
        L.append(f"| API-16-{c} | `{m} {p}` | {q} | {', '.join(x[-3:] for x in o['x-datahub-fr'])} | {fl} | {ok} |")
    L += ["", ": Danh mục endpoint PH-16", ""]
    return "\n".join(L).rstrip()


def events():
    L = ["| Mã | Topic | Khi nào | Khóa | Payload `data` | Bên nhận |", "|---|---|---|---|---|---|"]
    chs = [(k, c) for k, c in aa["channels"].items() if c["title"].startswith("EVT-16")]
    for (code, topic, when, who), (ck, ch) in zip(spec.EVT, chs):
        msg = aa["components"]["messages"][ck]
        key = re.search(r"`(\w+)`", msg["bindings"]["kafka"]["key"]["description"]).group(1)
        data = aa["components"]["schemas"][ck + "Event"]["properties"]["data"]["$ref"].split("/")[-1]
        L.append(f"| {code} | `{ch['address']}` | {when} | `{key}` | `{data}` | {who} |")
    L += ["", ": Sự kiện PH-16 phát ra", ""]
    L += ["| Mã | Topic | Hành động của PH-16 | Payload `data` |", "|---|---|---|---|"]
    for ck, ch in [(k, c) for k, c in aa["channels"].items() if not c["title"].startswith("EVT-16")]:
        msg = aa["components"]["messages"][ck]
        data = aa["components"]["schemas"][ck + "Event"]["properties"]["data"]["$ref"].split("/")[-1]
        L.append(f"| {ch['title']} | `{ch['address']}` | {msg['summary']} | `{data}` |")
    L += ["", ": Sự kiện PH-16 tiêu thụ", ""]
    return "\n".join(L).rstrip()


def errors():
    """Bảng mã lỗi kèm câu thông báo hiển thị (FRS 9.1 và 9.2)."""
    L = ["| Mã | HTTP | Ý nghĩa | Câu hiển thị | Vị trí |", "|---|---|---|---|---|"]
    for e, (st, txt) in spec.ERR.items():
        L.append(f"| {e} | {', '.join(map(str, st)) or '-'} | {txt} | \"{spec.MSG[e]}\" | {spec.MSG_POS[e]} |")
    L += ["", ": Mã lỗi ERR-16 và thông báo hiển thị", ""]
    return "\n".join(L).rstrip()


def notify():
    return ""


def fr():
    m = {}
    for c in sorted(OPS):
        for f in OPS[c][2]["x-datahub-fr"]:
            m.setdefault(f, []).append(c)
    L = ["| FR | Tên | API (API-16-) |", "|---|---|---|"]
    for n in range(1, 59):
        f = "FR-16-%03d" % n
        L.append(f"| {f} | {spec.FR_TITLE[f]} | {', '.join(m[f]) if f in m else NO_API[n]} |")
    L += ["", ": Truy vết FR-16 sang API", ""]
    return "\n".join(L).rstrip()


# ---------------------------------------------------------------- đặc tả từng endpoint
def trim(v, sch, comps, depth=0):
    """Rút gọn ví dụ: giữ trường bắt buộc và tối đa 6 trường, mảng một phần tử."""
    while isinstance(sch, dict) and "$ref" in sch:
        sch = comps[sch["$ref"].split("/")[-1]]
    if isinstance(v, list):
        it = sch.get("items", {}) if isinstance(sch, dict) else {}
        return [trim(v[0], it, comps, depth + 1)] if v else []
    if isinstance(v, dict) and isinstance(sch, dict) and "properties" in sch:
        req = [k for k in sch.get("required", []) if k in v]
        keep = req + [k for k in v if k not in req]
        out = {}
        for k in keep[: 5 if depth else 7]:
            out[k] = trim(v[k], sch["properties"].get(k, {}), comps, depth + 1)
        return out
    return v


def view():
    d = copy.deepcopy(oa)
    C = d["components"]["schemas"]
    PP = d["components"]["parameters"]
    resp_types = {o["res"] for o in spec.OPS.values() if o["res"]}
    for p, item in d["paths"].items():
        for m, o in item.items():
            for c in (o.get("requestBody", {}).get("content", {}) or {}).values():
                c["example"] = trim(c["example"], c["schema"], C)
            for st, r in o["responses"].items():
                for c in (r.get("content") or {}).values():
                    if "example" in c:
                        c["example"] = trim(c["example"], c["schema"], C)
    for n in C:
        if "required" in C[n]:
            if n in resp_types:
                del C[n]["required"]
            else:
                C[n]["required"] = C[n]["required"][:3]
    for p, item in d["paths"].items():
        for m, o in item.items():
            o["parameters"] = [x for x in o["parameters"] if x.get("$ref", "").split("/")[-1] != "IfMatch" and not (x.get("name") in ("page", "size") and "$ref" not in x)
                               and PP.get(x.get("$ref", "").split("/")[-1], {}).get("in") != "path"]
            for st in ("401", "403", "428"):
                o["responses"].pop(st, None)
            if o.get("description") == "Theo FRS 9.4.":
                o["description"] = ""
            o["x-datahub-errors"] = [e for e in o["x-datahub-errors"] if e not in GENERIC]
            if not o["x-datahub-errors"]:
                del o["x-datahub-errors"]
    return d


def dac_ta():
    tmp = tempfile.mkdtemp(prefix="kpi-md-")
    y, md = os.path.join(tmp, "v.yaml"), os.path.join(tmp, "v.md")
    yaml.dump(view(), open(y, "w", encoding="utf-8"), allow_unicode=True, sort_keys=False, width=200)
    open(md, "w", encoding="utf-8").write("# t\n\n## Lịch sử phiên bản\n")
    subprocess.run([sys.executable, TOOL, y, md, "--vi-du"], check=True, stdout=subprocess.DEVNULL)
    txt = open(md, encoding="utf-8").read()
    txt = txt[txt.index("<!-- gen:dac-ta-api:start -->") + len("<!-- gen:dac-ta-api:start -->"):txt.index("<!-- gen:dac-ta-api:end -->")]
    parts = re.split(r"(?m)^(?=#### API-16-)", txt)
    head, secs = parts[0], parts[1:]
    EX = "**Ví dụ yêu cầu và phản hồi.**"
    items = []
    for s_ in secs:
        code = re.match(r"#### API-16-(\d{3})", s_).group(1)
        base, _, ex = s_.partition(EX)
        o = spec.OPS[code]
        trivial = (o["req"] in (None, "CommentBody", "ReasonBody", "RejectBody", "Reason50Body", "SubmitNote"))
        pri = (0 if o["req"] and not trivial else 1 if o["status"] in (201, 202) or code in ("030", "074") else 2 if not trivial else 3 if o["res"] and not o["res"].endswith("Page") else 4, int(code))
        items.append([code, base, EX + ex if ex else "", pri])
    total = len(head.encode()) + sum(len(b.encode()) + 1 for _, b, _, _ in items)
    for it in sorted(items, key=lambda x: x[3]):
        if it[2] and total + len(it[2].encode()) <= DAC_TA_BUDGET:
            total += len(it[2].encode())
            it.append(True)
        else:
            it.append(False)
    out = head + "".join(b.rstrip("\n") + "\n\n" + (e if kept else "") for _, b, e, _, kept in items)
    # chú thích cho các endpoint không in ví dụ ở .md
    out = re.sub(r"\n{3,}", "\n\n", out)
    kept = sum(1 for it in items if it[4])
    sys.stderr.write(f"dac-ta: {len(out.encode())} byte, {kept}/{len(items)} endpoint có ví dụ in trong .md\n")
    return out.rstrip() + "\n"


FLOWS = [("030", "Đẩy quan sát vào qua kpi.ingest"), ("009", "Thử tính công thức trên kỳ trước"), ("074", "Công bố báo cáo chính thức"), ("118", "Lập gói báo cáo gửi quốc gia")]


def gon(v):
    import json
    one = json.dumps(v, ensure_ascii=False)
    if len(one) <= 96 or not isinstance(v, dict):
        return one
    return "{\n" + ",\n".join(" " + json.dumps(k, ensure_ascii=False) + ": " + json.dumps(x, ensure_ascii=False) for k, x in v.items()) + "\n}"


def flows():
    """Ví dụ HTTP của vài luồng chính, dựng từ ví dụ trong OpenAPI (đã rút gọn)."""
    import json
    d = view()
    C = d["components"]["schemas"]
    PP = d["components"]["parameters"]
    L = []
    for code, title in FLOWS:
        m, path, _ = OPS[code]
        o = d["paths"][path][m.lower()]
        url = path
        hdr = []
        for p in oa["paths"][path][m.lower()]["parameters"]:
            n = p["$ref"].split("/")[-1] if "$ref" in p else None
            pr = PP.get(n) if n else None
            if not pr:
                continue
            if pr["in"] == "path":
                url = url.replace("{" + pr["name"] + "}", str(pr["example"]))
            elif pr["name"] in ("Idempotency-Key", "If-Match"):
                hdr.append(f"{pr['name']}: {pr['example']}")
        rq = []
        for c in (o.get("requestBody", {}).get("content", {}) or {}).values():
            rq = ["", gon(c["example"])]
        ok = next(k for k in o["responses"] if k.startswith("2"))
        rsp = next(iter((o["responses"][ok].get("content") or {}).values()), None)
        L += [f"**API-16-{code} · {title}**", "", "```http", f"{m} /api/kpi/v1{url}", *hdr, *rq, "```", "", "```http", f"HTTP/1.1 {ok}", "",
              gon(rsp["example"]) if rsp else "", "```", ""]
    return "\n".join(L).rstrip()


def api_only():
    """Tên trường và giá trị liệt kê chỉ có ở API (không có ở FRS và DDL)."""
    toks = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", spec.FRS))
    ddl = open(os.path.join(ROOT, "..", "..", "csdl", "ph16", "ddl", "ph16_kpi.sql"), encoding="utf-8").read()
    for w in set(re.findall(r"[a-z][a-z0-9_]*", ddl)):
        toks.add(re.sub(r"_([a-z0-9])", lambda m: m.group(1).upper(), w))
    toks |= set(re.findall(r"'([A-Z][A-Z0-9_]+)'", ddl))
    ign = {"items", "page", "size", "totalElements", "type", "title", "status", "detail", "instance", "code", "traceId", "errors", "field", "message", "createdAt", "updatedAt",
           "version", "id", "specversion", "source", "time", "subject", "datacontenttype", "data", "reason", "comment", "name", "label", "value", "key"}
    props, enums = set(), set()

    def walk(x):
        if isinstance(x, dict):
            if isinstance(x.get("properties"), dict):
                props.update(x["properties"])
            if isinstance(x.get("enum"), list):
                enums.update(v for v in x["enum"] if isinstance(v, str))
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    walk(oa["components"]["schemas"])
    walk(aa["components"]["schemas"])
    np_ = sorted(k for k in props if k not in toks and k not in ign)
    ne = sorted(v for v in enums if v not in toks and v not in {"vi", "en"})
    return "Trường: " + ", ".join(f"`{k}`" for k in np_) + ".\n\nGiá trị liệt kê: " + (", ".join(f"`{k}`" for k in ne) + "." if ne else "không có, mọi giá trị đều ở FRS Phụ lục A.")


BLOCKS = {"api-only": api_only, "flows": flows, "endpoints": endpoints, "events": events, "errors": errors, "fr": fr}
if __name__ == "__main__":
    miss = [n for n in range(1, 59) if "FR-16-%03d" % n not in {f for c in OPS for f in OPS[c][2]["x-datahub-fr"]} and n not in NO_API]
    if miss:
        print("FR chưa có API:", miss); sys.exit(1)
    if "--write" in sys.argv:
        doc = open(DOC, encoding="utf-8").read()
        allb = dict(BLOCKS)
        allb["dac-ta-api"] = dac_ta
        for k, f in allb.items():
            body = f()
            doc, n = re.subn(r"(<!-- gen:%s:start -->\n?).*?(<!-- gen:%s:end -->)" % (k, k), lambda mm: mm.group(1) + body.strip("\n") + "\n" + mm.group(2), doc, flags=re.S)
            print(k, "đã chèn" if n else "THIẾU cặp đánh dấu")
        open(DOC, "w", encoding="utf-8").write(doc)
    else:
        for k, f in BLOCKS.items():
            print("---", k, len(f().encode()))
        dac_ta()
