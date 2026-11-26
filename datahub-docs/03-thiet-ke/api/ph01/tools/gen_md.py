#!/usr/bin/env python3
"""Sinh các khối bảng của D03-04-PH01 từ OpenAPI, AsyncAPI, spec.py, errors.py; chèn giữa các cặp đánh dấu:
  <!-- gen:endpoints:start/end -->  §3 danh mục endpoint
  <!-- gen:examples:start/end -->   §3.1 ví dụ yêu cầu và phản hồi
  <!-- gen:events:start/end -->     §4.1 bảng sự kiện, §4.2 cấu trúc nội dung
  <!-- gen:errors:start/end -->     §6 bảng mã lỗi
  <!-- gen:perm:start/end -->       §2.2 quyền → API
  <!-- gen:stepup:start/end -->     §2.3 thao tác cần xác thực lại hai yếu tố
  <!-- gen:conc:start/end -->       §1 cơ chế khóa lạc quan và lũy đẳng theo API
Chạy: python3 tools/gen_md.py   (từ thư mục api/ph01). Sửa nguồn rồi chạy lại, không sửa tay phần sinh.
"""
import json, os, re, sys, yaml
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import spec
from errors import ERRORS

ROOT = os.path.dirname(HERE)
DOC = os.path.join(os.path.dirname(ROOT), "D03-04-PH01-api-ket-nap-httt.md")
oa = yaml.safe_load(open(os.path.join(ROOT, "openapi-onboarding.yaml"), encoding="utf-8"))
aa = yaml.safe_load(open(os.path.join(ROOT, "asyncapi-onboarding.yaml"), encoding="utf-8"))
OPS = {}
for path, item in oa["paths"].items():
    for m, op in item.items():
        OPS[op["x-datahub-id"][-3:]] = (m.upper(), path, op)
TAGS = {}
for c, mth, path, summary, fr, perm, idem, success, group in spec.OPS:
    TAGS.setdefault(group, []).append((c, mth, path, summary, fr, perm, idem, success))
GROUP_NAME = {}
for c, (m, p, op) in OPS.items():
    GROUP_NAME[[o for o in spec.OPS if o[0] == c][0][8]] = op["tags"][0]


def perm_txt(code, perm):
    op = OPS[code][2]
    t = op["x-datahub-permission"]["permission"]
    if perm == "service":
        return f"Token dịch vụ `{spec.SERVICE_SCOPE[code]}`"
    if perm == "base":
        return "Quyền cơ sở (người dùng nội bộ)"
    if perm == "assigned":
        return "`PERM-01-read` + được phân công"
    if perm == "link":
        return "Người nhận liên kết (đăng nhập, MFA)"
    if code in spec.ANY_PERM:
        return t
    return f"`{t}`"


def sub(s, name, block):
    pat = rf"<!-- gen:{name}:start -->.*?<!-- gen:{name}:end -->"
    new = f"<!-- gen:{name}:start -->\n{block}\n<!-- gen:{name}:end -->"
    if not re.search(pat, s, re.S):
        raise SystemExit(f"Thiếu cặp đánh dấu gen:{name} trong {DOC}")
    return re.sub(pat, lambda m: new, s, flags=re.S)


# ---- §3 danh mục
def endpoints():
    out = []
    for g, rows in TAGS.items():
        out.append(f"**{GROUP_NAME[g]}**\n")
        out.append("| Mã | Phương thức, đường dẫn | Nội dung | FR | Quyền | Chống trùng | Thành công |\n|---|---|---|---|---|---|---|")
        for c, mth, path, summary, fr, perm, idem, success in rows:
            ok = success.replace("|", "/")
            out.append(f"| API-01-{c} | `{mth} {path}` | {summary} | {fr} | {perm_txt(c, perm)} | {'có' if idem else ''} | {ok} |")
        out.append("")
        out.append(f": Danh mục endpoint, nhóm {GROUP_NAME[g]}")
        out.append("")
    return "\n".join(out).rstrip()


# ---- §3.1 ví dụ
_SC = r'(?:"(?:[^"\\\n]|\\.)*"|-?\d+(?:\.\d+)?|true|false|null)'
_ARR = re.compile(r'\[\s*(' + _SC + r'(?:,\s*' + _SC + r')*)\s*\]')
_OBJ = re.compile(r'\{\s*("(?:[^"\\\n]|\\.)*":\s*' + _SC + r'(?:,\s*"(?:[^"\\\n]|\\.)*":\s*' + _SC + r')*)\s*\}')


def jd(x):
    """JSON thụt 2 ký tự; mảng và đối tượng chỉ chứa giá trị đơn giản được gộp một dòng nếu ≤ 100 ký tự."""
    t = json.dumps(x, ensure_ascii=False, indent=2)
    for _ in range(4):
        t = _ARR.sub(lambda m: "[" + re.sub(r",\s*\n\s*", ", ", m.group(1)) + "]" if len(m.group(0)) < 4000 else m.group(0), t)
        t = _OBJ.sub(lambda m: ("{ " + re.sub(r",\s*\n\s*", ", ", m.group(1)) + " }") if len(re.sub(r",\s*\n\s*", ", ", m.group(1))) <= 100 else m.group(0), t)
    return t


def examples():
    seen = {}
    out = []
    for g, rows in TAGS.items():
        out.append(f"**{GROUP_NAME[g]}**\n")
        for c, mth, path, summary, fr, perm, idem, success in rows:
            m, p, op = OPS[c]
            hdr = []
            if any("If-Match" in str(x) for x in op["parameters"]):
                hdr.append("If-Match: \"14\"" + ("  (tùy chọn)" if c in spec.IF_MATCH_OPTIONAL else ""))
            if idem:
                hdr.append("Idempotency-Key: 7c9e6679-7425-40de-944b-e07fc1f90ae7")
            ex_path = re.sub(r"\{(\w+)\}", lambda mm: {"systemCode": "HT-TUPHAP", "credentialId": "cr-0194f2c6", "cycleCode": "RS-2026-02",
                "attachmentId": "0194f2c2-7a10-7c3e-9b44-5d1f0a2b3c4d", "contactId": "0194f2c4-2c30-7e22-9b66-3f4a5b6c7d8e", "handoverId": "0194f2c7-4e50-7044-8d88-5b6c7d8e9fa0",
                "actionId": "0194f2c9-6070-7266-8faa-7d8e9fa0b1c2", "changeRequestId": "0194f2ca-7180-7377-90bb-8e9fa0b1c2d3", "token": "VIDU000000000000000000000000000000000000000",
                "orgId": "SO-TUPHAP", "jobId": "0194f2cd-a4b0-76aa-93ee-b1c2d3e4f506", "templateCode": "VAN-BAN-DE-NGHI-KET-NOI", "key": "onboarding.review.slaWorkingDays",
                "reviewKind": "legal"}.get(mm.group(1), mm.group(1)), p)
            lines = [f"**API-01-{c} · {summary}**\n", "```http"]
            qs = {"001": "?status=SUBMITTED&page=0&size=20", "027": "?mine=true&overdue=false", "048": "?withinDays=30", "063": "?updatedSince=2026-12-10T00:00:00Z&size=200",
                  "076": "?q=nguyen&contactType=TECHNICAL"}.get(c, "")
            lines.append(f"{m} {spec.BASE}{ex_path}{qs}")
            lines += hdr
            rb = op.get("requestBody")
            if rb:
                ct, cc = next(iter(rb["content"].items()))
                if "example" in cc and not ct.startswith("multipart"):
                    lines.append(f"Content-Type: {ct}\n")
                    lines.append(jd(cc["example"]))
                elif ct.startswith("multipart"):
                    lines.append(f"Content-Type: {ct}  (phần `file`" + (", `kind`, `title`)" if c == "007" else ", `source`)"))
            lines.append("```\n")
            main = spec.OPS and [o for o in spec.OPS if o[0] == c][0][7].split("|")[0]
            r = op["responses"].get(main, {})
            cont = (r.get("content") or {}).get("application/json")
            if cont and "example" in cont:
                key = cont["schema"]["$ref"].split("/")[-1]
                if key in seen:
                    lines.append(f"Phản hồi `{main}`: cùng cấu trúc `{key}` như ở API-01-{seen[key]}.\n")
                else:
                    seen[key] = c
                    hh = ", ".join(f"`{h}`" for h in (r.get("headers") or {}))
                    lines += [f"Phản hồi `{main}`" + (f" (tiêu đề {hh})" if hh else "") + ":\n", "```json", jd(cont["example"]), "```\n"]
            else:
                lines.append(f"Phản hồi `{main}`" + (": tệp nhị phân." if c in ("008", "021") else ": không có thân.") + "\n")
            out += lines
    return "\n".join(out).rstrip()


# ---- §4 sự kiện
def events():
    ev = []
    for key, ch in aa["channels"].items():
        code = ch["title"]
        msg = aa["components"]["messages"][key]
        bind = ch["bindings"]["kafka"]
        ev.append((code, key, ch, msg, bind))
    out = ["| Mã | Topic | Khi nào | Khóa | Phân vùng, giữ | Bên tiêu thụ |", "|---|---|---|---|---|---|"]
    for code, key, ch, msg, bind in ev:
        recv = aa["operations"]["receive" + key[0].upper() + key[1:]]["title"].replace(" nhận", "")
        out.append(f"| {code} | `{ch['address']}` | {ch['description']} | {msg['bindings']['kafka']['key']['description']} | "
                   f"{bind['partitions']}, {bind['topicConfiguration']['retention.ms'] // 86400000} ngày | {recv} |")
    out += ["", ": Sự kiện phát ra của PH-01 (EVT-01-01…15)", "", "### 4.2. Nội dung từng sự kiện", ""]
    out.append("Bảng dưới liệt kê trường của từng sự kiện (dấu * là bắt buộc), lấy từ [`asyncapi-onboarding.yaml`](ph01/asyncapi-onboarding.yaml); ví dụ JSON dùng dữ liệu giả lập.\n")
    for code, key, ch, msg, bind in ev:
        sch = aa["components"]["schemas"][msg["payload"]["$ref"].split("/")[-1]]
        req = set(sch.get("required", []))
        fields = ", ".join(f"`{k}`{'*' if k in req else ''}" for k in sch["properties"])
        out.append(f"**{code} · `{ch['address'].replace('{tenant}.connect.', '')}`.** {fields}.\n")
        out += ["```json", jd(msg["examples"][0]["payload"]), "```\n"]
    return "\n".join(out).rstrip()


# ---- §6 lỗi
def errors():
    uses = {}
    for c, (m, p, op) in OPS.items():
        for e in op["x-datahub-errors"]:
            uses.setdefault(e[-3:], []).append(c)
    desc_use = {}
    for c, (m, p, op) in OPS.items():
        for e in set(re.findall(r"ERR-01-(\d{3})", op.get("description") or "")):
            desc_use.setdefault(e, set()).add(c)

    def fmt(lst):
        lst = sorted(set(lst))
        return ", ".join(lst) if len(lst) <= 8 else ", ".join(lst[:8]) + f" và {len(lst) - 8} API khác"
    out = ["| Mã | HTTP | Ý nghĩa | API phát sinh (API-01-) |", "|---|---|---|---|"]
    for c, http, mean, _ in ERRORS:
        generic = {"001": "Mọi API có tham số đường dẫn", "003": "Mọi API có thân hoặc tham số", "007": "Mọi lệnh có `If-Match`", "052": "Mọi API"}
        a = fmt(uses.get(c, []) + list(desc_use.get(c, []))) if c not in generic else generic[c]
        if not a:
            a = "Lỗi trong thân kết quả kiểm tra (API-01-022) hoặc phát từ nền"
        out.append(f"| ERR-01-{c} | {http} | {mean} | {a} |")
    out += ["", ": Bảng mã lỗi ERR-01 (001…054)"]
    return "\n".join(out)


def short(codes):
    return ", ".join(sorted(codes))


def perms():
    rows = {}
    for c, (m, p, op) in OPS.items():
        pm = op["x-datahub-permission"]
        if "anyOf" in pm:
            for x in pm["anyOf"]:
                rows.setdefault(f"`{x}`" + (" (hoặc được phân công)" if "read" in x else ""), []).append(c)
        elif "kind" in pm:
            lbl = {"base": "Quyền cơ sở người dùng nội bộ tenant", "assigned": "`PERM-01-read` kèm phân công bước thẩm định", "link": "Đầu mối nhận liên kết (đăng nhập, MFA)"}[pm["kind"]]
            rows.setdefault(lbl, []).append(c)
        elif "serviceScope" in pm:
            rows.setdefault(f"Token dịch vụ `{pm['serviceScope']}`", []).append(c)
        else:
            rows.setdefault(f"`{pm['permission']}`", []).append(c)
    order = ["`PERM-01-read`", "`PERM-01-create`", "`PERM-01-submit`", "`PERM-01-approve`", "`PERM-01-credential`", "`PERM-01-suspend`", "`PERM-18-config`", "`PERM-18-migration`"]
    keys = [k for k in order if k in rows] + [k for k in rows if k not in order]
    out = ["| Quyền hoặc điều kiện | Số API | API-01- |", "|---|---|---|"]
    for k in keys:
        out.append(f"| {k} | {len(set(rows[k]))} | {short(set(rows[k]))} |")
    out += ["", ": Quyền và điều kiện của từng API"]
    return "\n".join(out)


def stepup():
    ids = [c for c, (m, p, op) in OPS.items() if "ERR-01-035" in op["x-datahub-errors"]]
    always = ["040"]
    out = ["| Cách xác thực lại | API-01- | Ghi chú |", "|---|---|---|",
            f"| `authCode` trong thân hoặc `acr` hai yếu tố còn trong `mfa.stepUpMinutes` | {short(ids)} | Thiếu thì ERR-01-035 (403); giao diện mở hộp xác thực lại rồi gửi lại cùng `Idempotency-Key` hoặc `If-Match` |",
            f"| Đăng nhập mới có hai yếu tố, không dựa phiên cũ | {short(always)} | Mở bàn giao; chưa đạt thì ERR-01-035 trước khi chiếm liên kết |",
           "", ": Thao tác cần xác thực lại hai yếu tố"]
    return "\n".join(out)


def conc():
    idem = [c for c, (m, p, op) in OPS.items() if op.get("x-datahub-idempotent")]
    req, opt, none = [], [], []
    for c, (m, p, op) in OPS.items():
        names = " ".join(str(x) for x in op["parameters"])
        if "IfMatchOptional" in names:
            opt.append(c)
        elif "IfMatch" in names:
            req.append(c)
        elif m in ("POST", "PUT", "PATCH", "DELETE") and "security" not in op and not op.get("x-datahub-idempotent"):
            none.append(c)
    out = ["| Cơ chế | Số API | API-01- |", "|---|---|---|",
           f"| `Idempotency-Key` bắt buộc | {len(idem)} | {short(idem)} |",
           f"| `If-Match` bắt buộc | {len(req)} | {short(req)} |",
           f"| `If-Match` tùy chọn (thao tác khẩn) | {len(opt)} | {short(opt)} |",
           f"| Lệnh ghi không dùng cả hai (tính toán, việc của người thẩm định, mở một lần, phản hồi phiếu) | {len(none)} | {short(none)} |",
           "", ": Cơ chế khóa lạc quan và lũy đẳng theo API"]
    return "\n".join(out)


if __name__ == "__main__":
    s = open(DOC, encoding="utf-8").read()
    s = sub(s, "endpoints", endpoints())
    s = sub(s, "examples", examples())
    s = sub(s, "events", events())
    s = sub(s, "errors", errors())
    s = sub(s, "perm", perms())
    s = sub(s, "stepup", stepup())
    s = sub(s, "conc", conc())
    open(DOC, "w", encoding="utf-8").write(s)
    n_idem = sum(1 for o in spec.OPS if o[6])
    print(len(spec.OPS), "dòng,", len(ERRORS), "mã lỗi,", len(aa["channels"]), "sự kiện,", n_idem, "lệnh chống trùng")
