#!/usr/bin/env python3
"""Sinh các khối bảng của D03-04-PH11 từ spec.py, OpenAPI và AsyncAPI: danh mục endpoint, sự kiện, mã lỗi, FR → API.
Chạy từ thư mục api/ph11:  python3 tools/gen_md.py [--write]
Với --write thay đoạn giữa <!-- gen:X:start --> và <!-- gen:X:end --> trong ../D03-04-PH11-api-quy-trinh.md."""
import os, re, sys, yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

ROOT = spec.ROOT
DOC = os.path.join(ROOT, "..", "D03-04-PH11-api-quy-trinh.md")
oa = yaml.safe_load(open(os.path.join(ROOT, "openapi-bpm.yaml"), encoding="utf-8"))
aa = yaml.safe_load(open(os.path.join(ROOT, "asyncapi-bpm.yaml"), encoding="utf-8"))
OPS = {}
for path, item in oa["paths"].items():
    for m, o in item.items():
        OPS[o["x-datahub-id"][-3:]] = (m.upper(), path, o)
FR_TITLE = dict(re.findall(r"^#### (FR-11-\d{3}) · ([^\n]+)", spec.FRS, re.M))
NO_API = {31: "Hệ thống: hẹn giờ chạy trong engine (EVT-11-11, 12)", 32: "Hệ thống: gửi thông báo qua EVT-11-20", 33: "Hệ thống: quy trình con chạy trong engine, cấu hình ở API-11-011",
          47: "Hệ thống: quét hạn theo `11.due.scanMinutes`, phát EVT-11-11", 48: "Hệ thống: leo thang theo cấu hình bước, phát EVT-11-12",
          56: "Hệ thống: phát EVT-11-04 qua outbox (mục 4)"}
NO_API.update({19: None, 28: None, 29: None, 30: None, 34: None, 35: None})


def endpoints():
    L = []
    for tag in spec.TAGS:
        L += ["**%s**" % tag, "", "| Mã | Phương thức, đường dẫn | Quyền, scope | FR | Idem. | If-Match | Thành công |", "|---|---|---|---|---|---|---|"]
        for c in sorted(OPS):
            m, p, o = OPS[c]
            if o["tags"][0] != tag:
                continue
            q = o["x-datahub-permission"]["permission"].replace("PERM-11-", "").replace(" hoặc scope ", " hoặc ").replace("scope ", "")
            ok = ",".join(k for k in o["responses"] if k.startswith("2"))
            L.append(f"| API-11-{c} | `{m} {p}` | {q} | {', '.join(x[-3:] for x in o['x-datahub-fr'])} | {'Có' if o.get('x-datahub-idempotent') else '-'} | {'Có' if o.get('x-datahub-if-match') else '-'} | {ok} |")
        L += ["", ": Danh mục endpoint · %s" % tag, ""]
    return "\n".join(L).rstrip()


def events():
    L = ["| Mã | Topic | Khóa | Payload `data` | Hướng | Bên nhận |", "|---|---|---|---|---|---|"]
    for (code, topic, key, fields, who), (ck, ch) in zip(spec.EVT, aa["channels"].items()):
        data = aa["components"]["schemas"][ck + "Event"]["properties"]["data"]["$ref"].split("/")[-1]
        hd = "PH-04 phát, PH-11 nhận" if code in ("EVT-11-18", "EVT-11-19") else "PH-11 phát"
        L.append(f"| {code} | `{ch['address']}` | `{key}` | `{data}` | {hd} | {who} |")
    L += ["", ": Sự kiện của PH-11", ""]
    return "\n".join(L).rstrip()


def errors():
    used = {}
    for c in sorted(OPS):
        for e in OPS[c][2]["x-datahub-errors"]:
            used.setdefault(e, []).append(c)
    L = ["| Mã | HTTP | Ý nghĩa | Thông báo hiển thị | API phát sinh (API-11-) |", "|---|---|---|---|---|"]
    for e, (st, txt) in spec.ERR.items():
        u = used.get(e, [])
        if int(e[-3:]) > 100:
            ref = "Không trả cho người gọi"
        elif not u:
            ref = "Dự phòng, chưa có API" if "Dự phòng" in txt else "Do engine hoặc dịch vụ nội bộ"
        elif len(u) > 6:
            ref = f"{len(u)} API"
        else:
            ref = ", ".join(u)
        msg = spec.MSG.get(e, "Theo FR").replace("|", "/")
        L.append(f"| {e} | {', '.join(map(str, st)) or '-'} | {txt} | {msg} | {ref} |")
    L += ["", ": Mã lỗi ERR-11", ""]
    return "\n".join(L).rstrip()


def fr():
    m = {}
    for c in sorted(OPS):
        for f in OPS[c][2]["x-datahub-fr"]:
            m.setdefault(f, []).append(c)
    L = ["| FR | Tên | API (API-11-) |", "|---|---|---|"]
    for n in range(1, 67):
        f = "FR-11-%03d" % n
        L.append(f"| {f} | {FR_TITLE[f]} | {', '.join(m[f]) if f in m else (NO_API.get(n) or 'Hệ thống: qua sự kiện Kafka (mục 4), không có API')} |")
    L += ["", ": Truy vết FR-11 sang API", ""]
    return "\n".join(L).rstrip()


ROLES = {"read": "PA ○, PO ○, TA, TO, IE, IA, AU, VW, CB ○", "model": "PA ○, TA, IE", "publish": "TA, IA", "task": "TA, TO, IE, IA, CB",
         "instance": "TA, TO", "instance-admin": "TA", "task-admin": "TA, TO", "compensate": "PO ○, TA, TO", "config": "PA, TA", "audit-read": "TA, AU"}
MEANING = {"read": "Xem mô hình, phiên, việc, bảng điều khiển trong phạm vi", "model": "Tạo, thiết kế, cấu hình, chạy thử, gửi duyệt mô hình và tài nguyên",
           "publish": "Duyệt, từ chối phát hành; ngừng dùng, thu hồi phiên bản", "task": "Xử lý việc được giao", "instance": "Khởi tạo thủ công, tạm dừng, tiếp tục, hủy phiên",
           "instance-admin": "Đề nghị, duyệt sửa biến, chuyển bước, di trú phiên", "task-admin": "Phân công lại, giao lại hàng loạt",
           "compensate": "Kích hoạt bù trừ, xử lý bước Saga, sự cố engine, gửi lại lệnh", "config": "Lịch làm việc, tham số, lưu giữ, quy tắc cảnh báo",
           "audit-read": "Lịch sử bước đầy đủ, nhật ký kiểm toán, xuất bằng chứng"}


def rng(codes):
    codes = sorted(codes)
    out, i = [], 0
    while i < len(codes):
        j = i
        while j + 1 < len(codes) and int(codes[j + 1]) == int(codes[j]) + 1:
            j += 1
        out.append(codes[i] if j - i < 2 else f"{codes[i]}…{codes[j]}")
        i = j + 1 if j - i >= 2 else i + 1
    return ", ".join(out)


def perms():
    L = ["| Quyền | Ý nghĩa | Vai trò (FRS 3.2) | Operation (API-11-) |", "|---|---|---|---|"]
    for p in ROLES:
        cs = [c for c in OPS if "PERM-11-" + p in re.findall(r"PERM-11-[a-z-]+", OPS[c][2]["x-datahub-permission"]["permission"]) and OPS[c][2]["x-datahub-permission"]["permission"].count("PERM-11-" + p + " ") + OPS[c][2]["x-datahub-permission"]["permission"].count("PERM-11-" + p + "-") * 0 >= 0]
        cs = [c for c in OPS if re.search(r"PERM-11-%s(?![a-z-])" % re.escape(p), OPS[c][2]["x-datahub-permission"]["permission"])]
        L.append(f"| `PERM-11-{p}` | {MEANING[p]} | {ROLES[p]} | {rng(cs)} |")
    L += ["", ": Quyền người dùng của PH-11", ""]
    return "\n".join(L).rstrip()


SCOPE_WHO = {"bpm.instance.start": "Cổng DVC, HTTT một cửa, PH-01, PH-07, PH-19", "bpm.instance.read": "Như trên, PH-13", "bpm.task.read": "HTTT một cửa có hộp việc riêng",
             "bpm.progress.read": "Cổng DVC qua PH-03", "bpm.service.worker": "PH-04"}


def scopes():
    L = ["| Scope | Cấp cho | Operation (API-11-) | Ghi chú |", "|---|---|---|---|"]
    for sc in SCOPE_WHO:
        cs = [c for c in OPS if sc in OPS[c][2]["x-datahub-permission"]["permission"].replace("scope ", "").split(" hoặc ") or ("scope " + sc) in OPS[c][2]["x-datahub-permission"]["permission"]]
        note = "Chỉ qua Kafka (EVT-11-17, 18, 19), không có REST" if sc == "bpm.service.worker" else ("Chỉ scope, không có quyền người dùng" if all(not OPS[c][2]["x-datahub-permission"]["permission"].startswith("PERM") for c in cs) and cs else "Hoặc quyền người dùng ở mục 2.1")
        L.append(f"| `{sc}` | {SCOPE_WHO[sc]} | {rng(cs) or '-'} | {note} |")
    L += ["", ": Scope máy của PH-11", ""]
    return "\n".join(L).rstrip()


IGNORE_PROP = {"items", "page", "size", "totalElements", "type", "title", "status", "detail", "instance", "code", "traceId", "errors", "field", "message", "createdAt", "updatedAt", "version", "id",
               "specversion", "source", "time", "subject", "datacontenttype", "data", "reason", "comment", "name", "label", "value", "key"}


def newfields():
    toks = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", spec.FRS))
    props = set()

    def walk(x):
        if isinstance(x, dict):
            if isinstance(x.get("properties"), dict):
                props.update(x["properties"])
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    walk(oa["components"]["schemas"])
    walk(aa["components"]["schemas"])
    new = sorted(k for k in props if k not in toks and k not in IGNORE_PROP)
    return ", ".join("`%s`" % k for k in new)


BLOCKS = {"perms": perms, "scopes": scopes, "newfields": newfields, "endpoints": endpoints, "events": events, "errors": errors, "fr": fr}
if __name__ == "__main__":
    miss = [n for n in range(1, 67) if "FR-11-%03d" % n not in {f for c in OPS for f in OPS[c][2]["x-datahub-fr"]} and n not in NO_API]
    if miss:
        print("FR chưa có API và chưa ghi lý do:", miss)
        sys.exit(1)
    if "--write" in sys.argv:
        doc = open(DOC, encoding="utf-8").read()
        for k, f in BLOCKS.items():
            doc, n = re.subn(r"(<!-- gen:%s:start -->\n).*?(<!-- gen:%s:end -->)" % (k, k), lambda mm: mm.group(1) + f() + "\n" + mm.group(2), doc, flags=re.S)
            print(k, "đã chèn" if n else "THIẾU cặp đánh dấu")
        open(DOC, "w", encoding="utf-8").write(doc)
    else:
        for k, f in BLOCKS.items():
            print("---", k)
            print(f())
