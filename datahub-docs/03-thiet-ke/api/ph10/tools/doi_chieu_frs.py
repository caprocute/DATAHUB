#!/usr/bin/env python3
"""Đối chiếu openapi-event.yaml, asyncapi-event.yaml và D03-04-PH10 với FRS PH-10 (Phụ lục A, §8).

In ra: giá trị enum không có ở FRS; tên trường không có ở FRS (cần ghi ở mục "Đề nghị bổ sung cho FRS"); mã ERR, EVT, PERM, scope,
API lệch. Mã thoát 1 khi có ERR, EVT, PERM, scope, API lệch hoặc khi trường, enum mới chưa được liệt kê ở §10 của tài liệu.
Chạy: python3 tools/doi_chieu_frs.py   (từ thư mục api/ph10)
"""
import os, re, sys, yaml
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(ROOT, "..", "..", "..")
FRS = open(os.path.join(DOCS, "02-yeu-cau", "frs", "D02-03-PH10-frs-su-kien.md"), encoding="utf-8").read()
MD = open(os.path.join(ROOT, "..", "D03-04-PH10-api-su-kien.md"), encoding="utf-8").read()
APPX = FRS[FRS.index("## Phụ lục A."):]
oa = yaml.safe_load(open(os.path.join(ROOT, "openapi-event.yaml"), encoding="utf-8"))
aa = yaml.safe_load(open(os.path.join(ROOT, "asyncapi-event.yaml"), encoding="utf-8"))
TICK = set()
TOKENS = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*(?:-[A-Za-z0-9_]+)*", FRS)) | set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", FRS))
bad = 0

def walk(x, fn, path=()):
    if isinstance(x, dict):
        fn(x, path)
        for k, v in x.items(): walk(v, fn, path + (k,))
    elif isinstance(x, list):
        for i, v in enumerate(x): walk(v, fn, path + (i,))

# ---- enum
enums, props = {}, {}
def collect(node, path):
    if "enum" in node and isinstance(node["enum"], list):
        for v in node["enum"]:
            if isinstance(v, str): enums.setdefault(v, set()).add("/".join(map(str, path[-3:])))
    if "properties" in node and isinstance(node["properties"], dict):
        for k in node["properties"]: props.setdefault(k, set()).add("/".join(map(str, path[-2:])))
walk(oa["components"]["schemas"], collect)
walk(oa["components"]["parameters"], collect)
walk(aa["components"]["schemas"], collect)
walk(aa["components"]["messages"], collect)
IGNORE_ENUM = {"vi", "en", "1h", "24h", "7d", "internal", "external", "application/cloudevents+json", "application/json"}
new_enum = sorted(v for v in enums if v not in TOKENS and v not in TICK and v not in IGNORE_ENUM)
# ---- trường
IGNORE_PROP = {"items", "page", "size", "totalElements", "facets", "type", "title", "status", "detail", "instance", "code", "traceId", "errors",
               "field", "message", "createdAt", "createdBy", "updatedAt", "updatedBy", "version", "id", "specversion", "source", "time", "subject",
               "dataschema", "datacontenttype", "data", "reason", "comment", "tenantId", "tenant"}
HDR = {k for k in props if "-" in k or k.startswith("ce_") or k.startswith("dh_dlq") or k[0].isupper()}
new_prop = sorted(k for k in props if k not in TOKENS and k not in IGNORE_PROP and k not in HDR)
listed = set(re.findall(r"`([A-Za-z_][A-Za-z0-9_.]*)`", MD[MD.index("## 10."):MD.index("## 11.")])) if "## 10." in MD and "## 11." in MD else set()
unlisted_prop = [k for k in new_prop if k not in listed]
unlisted_enum = [v for v in new_enum if v not in listed]
print(f"Enum: {len(enums)} giá trị; {len(new_enum)} không có ở FRS: {', '.join(new_enum)}")
print(f"Trường: {len(props)} tên; {len(new_prop)} không có ở FRS: {', '.join(new_prop)}")
if unlisted_prop or unlisted_enum:
    bad += 1; print("CHƯA GHI Ở §10:", ", ".join(unlisted_enum + unlisted_prop))
# ---- enum của phụ lục phải có đủ ở API (theo lược đồ cùng tên)
A2 = {"ProjectStatus": "A.2.1", "TopicStatus": "A.2.2", "SchemaVersionStatus": "A.2.4", "PartyType": "A.2.5", "SuspendSource": "A.2.5",
      "PublicationStatus": "A.2.6", "SubscriptionStatus": "A.2.7", "DeliveryMode": "A.2.7", "CommTypeCode": "A.2.8", "RoutingModeCode": "A.2.9",
      "RequestType": "A.2.10", "RequestStatus": "A.2.10", "TargetType": "A.2.10", "DlqStatus": "A.2.11", "DlqOrigin": "A.2.11", "ReplayStatus": "A.2.11",
      "ReplayMode": "A.2.11", "RangeType": "A.2.11", "FailureClass": "A.2.11", "ImportStatus": "A.2.13", "ChangeKind": "A.2.13", "MappingStatus": "A.2.14",
      "BridgeStatus": "A.2.14", "PermissionReason": "A.2.15", "GraphOverlay": "A.2.15", "ServiceCode": "A.2.12"}
for name, sec in A2.items():
    vals = oa["components"]["schemas"][name]["enum"]
    for v in vals:
        if f"`{v}`" not in APPX and v not in APPX: bad += 1; print(f"LỆCH enum {name}={v} không có ở {sec}")
# ---- ERR
frs_err = set(re.findall(r"^\| (ERR-10-\d{3}) \|", FRS, re.M))
used_err = set(re.findall(r"ERR-10-\d{3}", yaml.safe_dump(oa) + yaml.safe_dump(aa) + MD))
for e in sorted(used_err - frs_err): bad += 1; print("LỆCH ERR không có ở FRS:", e)
miss_md = sorted(frs_err - set(re.findall(r"ERR-10-\d{3}", MD)))
if miss_md: bad += 1; print("ERR có ở FRS mà thiếu ở tài liệu:", miss_md)
# ---- EVT
frs_evt = dict(re.findall(r"^\| (EVT-10-\d{2}) \| `([^`]+)` \|", APPX, re.M))
aa_evt = {ch["title"]: ch["address"] for ch in aa["channels"].values() if ch.get("title", "").startswith("EVT-10-")}
for k, v in frs_evt.items():
    if aa_evt.get(k) != v: bad += 1; print(f"LỆCH {k}: FRS {v}, AsyncAPI {aa_evt.get(k)}")
for k in aa_evt:
    if k not in frs_evt: bad += 1; print("EVT thừa:", k)
# ---- PERM, scope
frs_perm = set(re.findall(r"PERM-10-[a-z-]+", APPX))
used_perm = set(re.findall(r"PERM-10-[a-z]+(?:-[a-z]+)*", yaml.safe_dump(oa) + MD))
for p in sorted(used_perm - frs_perm): bad += 1; print("LỆCH PERM không có ở A.4:", p)
frs_scope = set(re.findall(r"`(event:[a-z-]+)`", APPX))
used_scope = set(re.findall(r"event:[a-z]+(?:-[a-z]+)*", yaml.safe_dump(oa["components"]["securitySchemes"]) + yaml.safe_dump(oa["paths"])))
for p in sorted(used_scope - frs_scope): bad += 1; print("LỆCH scope không có ở A.4:", p)
# ---- API: mã 001…091 khớp FRS §8.3 (đường dẫn của operation đầu tiên trong dòng)
sec83 = FRS[FRS.index("### 9.4."):FRS.index("## 10.")]
frs_api = dict(re.findall(r"^\| (API-10-\d{3}) \| `([A-Z]+ [^`]+)`", sec83, re.M))
ops = {o[0]: o for o in spec.OPS}
for a, mp in frs_api.items():
    c = a[-3:]
    meth, path = mp.split(" ", 1)
    path = path.split("?")[0].replace("/event/v1", "", 1) if path.startswith("/event/v1") else path.split("?")[0]
    if path.endswith("/**"): path = path[:-3] + "/{registryPath}"
    o = ops.get(c)
    if not o or o[1] != meth or o[2] != path: bad += 1; print(f"LỆCH {a}: FRS `{mp}`, API {o[1] + ' ' + o[2] if o else 'không có'}")
print(f"API: {len(frs_api)} mã FRS §8.3 đối chiếu; {len([c for c in ops if int(c) > 91])} mã cấp mới")
print("Kết quả:", "LỆCH" if bad else "khớp")
sys.exit(1 if bad else 0)
