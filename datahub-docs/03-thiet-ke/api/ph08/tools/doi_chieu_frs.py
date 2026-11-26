#!/usr/bin/env python3
"""Đối chiếu openapi-dq.yaml, asyncapi-dq.yaml và D03-04-PH06 với FRS PH-08 (Phụ lục A, mục 3.2, 9).

In ra: giá trị enum, tên trường không có ở FRS (phải ghi ở Phụ lục A "Đề nghị đồng bộ" của tài liệu); mã ERR, EVT, PERM, API lệch.
Mã thoát 1 khi có ERR, EVT, PERM, API lệch hoặc trường, enum mới chưa được liệt kê ở mục Đề nghị.
Chạy: python3 tools/doi_chieu_frs.py   (từ thư mục api/ph08)
"""
import os, re, sys, yaml

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

ROOT = spec.ROOT
FRS = spec.FRS
MD_PATH = os.path.join(ROOT, "..", "D03-04-PH08-api-chat-luong-du-lieu.md")
MD = open(MD_PATH, encoding="utf-8").read() if os.path.exists(MD_PATH) else ""
oa = yaml.safe_load(open(os.path.join(ROOT, "openapi-dq.yaml"), encoding="utf-8"))
aa = yaml.safe_load(open(os.path.join(ROOT, "asyncapi-dq.yaml"), encoding="utf-8"))
TOKENS = set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", FRS))
# tên cột DDL (snake_case) coi như đã có ở nguồn: so theo dạng camelCase và giá trị CHECK IN (...)
DDL = open(os.path.join(ROOT, "..", "..", "csdl", "ph08", "ddl", "ph08_dq.sql"), encoding="utf-8").read()
for _w in set(re.findall(r"[a-z][a-z0-9_]*", DDL)):
    TOKENS.add(re.sub(r"_([a-z0-9])", lambda m: m.group(1).upper(), _w))
TOKENS |= set(re.findall(r"'([A-Z][A-Z0-9_]+)'", DDL))
bad = 0


def walk(x, fn, path=()):
    if isinstance(x, dict):
        fn(x, path)
        for k, v in x.items():
            walk(v, fn, path + (k,))
    elif isinstance(x, list):
        for i, v in enumerate(x):
            walk(v, fn, path + (i,))


enums, props = {}, {}


def collect(node, path):
    if "enum" in node and isinstance(node["enum"], list):
        for v in node["enum"]:
            if isinstance(v, str):
                enums.setdefault(v, set()).add("/".join(map(str, path[-3:])))
    if "properties" in node and isinstance(node["properties"], dict):
        for k in node["properties"]:
            props.setdefault(k, set()).add("/".join(map(str, path[-2:])))


walk(oa["components"]["schemas"], collect)
walk(oa["components"]["parameters"], collect)
walk(aa["components"]["schemas"], collect)
IGNORE_ENUM = {"vi", "en"}
new_enum = sorted(v for v in enums if v not in TOKENS and v not in IGNORE_ENUM)
IGNORE_PROP = {"items", "page", "size", "totalElements", "type", "title", "status", "detail", "instance", "code", "traceId", "errors", "field", "message", "createdAt",
               "updatedAt", "version", "id", "specversion", "source", "time", "subject", "datacontenttype", "data", "reason", "comment", "name", "label", "value", "key"}
new_prop = sorted(k for k in props if k not in TOKENS and k not in IGNORE_PROP)
if "## Phụ lục A." in MD:
    listed = set(re.findall(r"`([A-Za-z_][A-Za-z0-9_.]*)`", MD[MD.index("## Phụ lục A."):]))
else:
    listed = set()
unlisted = [k for k in new_prop + new_enum if k not in listed]
print(f"Enum: {len(enums)} giá trị; {len(new_enum)} không có ở FRS: {', '.join(new_enum)}")
print(f"Trường: {len(props)} tên; {len(new_prop)} không có ở FRS: {', '.join(new_prop)}")
if MD and unlisted:
    bad += 1
    print("CHƯA GHI Ở PHỤ LỤC A:", ", ".join(unlisted))
# ERR
used_err = set(re.findall(r"ERR-08-\d{3}", yaml.safe_dump(oa) + yaml.safe_dump(aa) + MD))
PROPOSED = {"ERR-08-055"}  # mã đề nghị cấp thêm (Phụ lục A, Q08-55), chưa có ở FRS
for e in sorted(used_err - set(spec.ERR) - PROPOSED):
    bad += 1
    print("LỆCH ERR không có ở FRS:", e)
api_err = {e for p in oa["paths"].values() for o in p.values() for e in o["x-datahub-errors"]}
for e in sorted(e for e in spec.ERR if int(e[-3:]) < 100 and e not in api_err):
    print("Lưu ý: ERR không gắn operation nào:", e, "(ghi ở chương mã lỗi là mã dùng chung hoặc do dịch vụ nội bộ)")
if MD:
    miss = sorted(set(spec.ERR) - set(re.findall(r"ERR-08-\d{3}", MD)))
    if miss:
        bad += 1
        print("ERR có ở FRS mà thiếu ở tài liệu:", miss)
# EVT
aa_evt = {ch["title"]: ch["address"] for ch in aa["channels"].values()}
for code, topic, _a in spec.EVT_IN:
    if aa_evt.get(code) != re.sub(r"^t68\.", "{tenant}.", topic):
        bad += 1
        print(f"LỆCH {code}: FRS {topic}, AsyncAPI {aa_evt.get(code)}")
for code, topic, _a, _b in spec.EVT:
    if aa_evt.get(code) != topic.replace("t68.", "{tenant}.", 1):
        bad += 1
        print(f"LỆCH {code}: FRS {topic}, AsyncAPI {aa_evt.get(code)}")
if MD:
    miss = sorted(c for c, *_ in spec.EVT + spec.EVT_IN if c not in MD)
    if miss:
        bad += 1
        print("EVT thiếu ở tài liệu:", miss)
# PERM
used_perm = set(re.findall(r"PERM-08-[a-z]+(?:-[a-z]+)*", yaml.safe_dump(oa) + MD))
for p in sorted(used_perm - set(spec.PERMS)):
    bad += 1
    print("LỆCH PERM không có ở FRS 3.2:", p)
# API
sec = FRS[FRS.index("### 9.4."):FRS.index("## 10. Giao diện")]
frs_api = {m.group(1): (m.group(2), m.group(3)) for m in re.finditer(r"^\| API-08-(\d{3}) \| `([A-Z]+) ([^`]+)`", sec, re.M)}
ops = {}
for path, item in oa["paths"].items():
    for m, o in item.items():
        ops[o["x-datahub-id"][-3:]] = (m.upper(), path, o["x-datahub-fr"])
for c, (meth, path) in frs_api.items():
    o = ops.get(c)
    if not o or o[0] != meth or o[1] != path:
        bad += 1
        print(f"LỆCH API-08-{c}: FRS `{meth} {path}`, API {o[0] + ' ' + o[1] if o else 'không có'}")
frs_fr = {m.group(1): m.group(2) for m in re.finditer(r"^\| API-08-(\d{3}) \| `[^`]+`(?: \([^)]*\))? \| ([^|]+) \|", sec, re.M)}
for c, f in frs_fr.items():
    want = {f"FR-08-{x}" for x in re.findall(r"\d{3}", f)}
    if want != set(ops[c][2]):
        bad += 1
        print(f"LỆCH FR của API-08-{c}: FRS {sorted(want)}, API {ops[c][2]}")
if MD:
    for c in ops:
        if f"API-08-{c}" not in MD:
            bad += 1
            print("API thiếu ở tài liệu:", c)
print(f"API: {len(frs_api)} mã FRS 9.4 đối chiếu (đường dẫn, phương thức, FR); {len(ops)} operation, {len([c for c in ops if int(c) > 132])} mã cấp mới")
print("Kết quả:", "LỆCH" if bad else "khớp")
sys.exit(1 if bad else 0)
