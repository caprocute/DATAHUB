#!/usr/bin/env python3
"""Kiểm hợp đồng PH-13: OpenAPI 3.1 hợp lệ, mọi ví dụ khớp lược đồ, mỗi operation có x-datahub-*, lệnh ghi có If-Match hoặc Idempotency-Key,
không có đường ghi kiểm toán cho người dùng, mã API/EVT/ERR đủ so với FRS; AsyncAPI nạp được và ví dụ khớp lược đồ.

Chạy: python3 tools/check_contracts.py   (từ thư mục api/ph13). Cần: openapi-spec-validator, jsonschema ≥ 4.18.
AsyncAPI kiểm thêm bằng @asyncapi/parser 3 khi có mạng (D03-04-PH13 §7).
"""
import os, re, sys, yaml, jsonschema
from openapi_spec_validator import validate
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.abspath(os.path.join(ROOT, "..", "..", ".."))
FRS = os.path.join(DOCS, "02-yeu-cau", "frs", "D02-03-PH13-frs-giam-sat-kiem-toan.md")
bad = 0

def fix(x):
    if isinstance(x, dict): return {k: ("urn:c" + v if k == "$ref" and isinstance(v, str) and v.startswith("#/") else fix(v)) for k, v in x.items()}
    if isinstance(x, list): return [fix(i) for i in x]
    return x

def registry(comp):
    return Registry().with_resource("urn:c", Resource.from_contents(fix({"components": comp}), default_specification=DRAFT202012))

def chk(reg, schema, inst, where):
    global bad
    errs = list(jsonschema.Draft202012Validator(fix(schema), registry=reg).iter_errors(inst))
    if errs: bad += 1; print(f"{where}: {errs[0].message[:200]}")

# ---- OpenAPI
d = yaml.safe_load(open(os.path.join(ROOT, "openapi-giam-sat-kiem-toan.yaml"), encoding="utf-8"))
validate(d)
reg = registry(d["components"])
n = 0; ids = set(); errs_used = set()
for p, m in d["paths"].items():
    for meth, o in m.items():
        oid = o["operationId"]
        for k in ("x-datahub-id", "x-datahub-fr", "x-datahub-permission", "x-datahub-errors"):
            if k not in o: bad += 1; print(f"{oid}: thiếu {k}")
        ids.add(o["x-datahub-id"]); errs_used |= set(o.get("x-datahub-errors", []))
        names = {pp.get("$ref", "").split("/")[-1] for pp in o.get("parameters", [])}
        if meth in ("patch", "put") and "IfMatch" not in names: bad += 1; print(f"{oid}: lệnh ghi thiếu If-Match")
        if meth == "post" and "IdempotencyKey" not in names and o["x-datahub-id"] in ("API-13-028", "API-13-036", "API-13-043", "API-13-046", "API-13-049", "API-13-062", "API-13-065", "API-13-072", "API-13-073", "API-13-077", "API-13-082"):
            bad += 1; print(f"{oid}: lệnh tạo thiếu Idempotency-Key")
        if "/records" in p and meth in ("put", "patch", "delete"): bad += 1; print(f"{oid}: có đường sửa, xóa bản ghi kiểm toán")
        for ct, c in o.get("requestBody", {}).get("content", {}).items():
            if "example" in c: chk(reg, c["schema"], c["example"], oid); n += 1
for name, r in d["components"].get("responses", {}).items():
    for ct, c in r.get("content", {}).items():
        if "example" in c: chk(reg, c["schema"], c["example"], name); n += 1
for k, sch in d["components"]["schemas"].items():
    for e in (sch.get("examples", []) if isinstance(sch, dict) else []): chk(reg, sch, e, k); n += 1
# bí mật chỉ ghi
for k, sch in d["components"]["schemas"].items():
    for fld in ("secret", "clientKey"):
        pr = sch.get("properties", {}).get(fld) if isinstance(sch, dict) else None
        if pr is not None and not pr.get("writeOnly"): bad += 1; print(f"{k}.{fld}: thiếu writeOnly")
        if pr is not None and k not in ("NotificationChannelCreate", "NotificationChannelPatch", "SiemTargetCreate", "SiemTargetPatch"): bad += 1; print(f"{k}: trường bí mật ngoài lược đồ chỉ ghi")
want = {f"API-13-{i:03d}" for i in range(1, 91)}
if ids != want: bad += 1; print("Mã API thiếu/thừa:", sorted(want ^ ids))
frs = open(FRS, encoding="utf-8").read()
frs_err = set(re.findall(r"^\| (ERR-13-\d{3}) \| \d{3} \|", frs, re.M))
if errs_used - frs_err: bad += 1; print("ERR dùng ở OpenAPI nhưng FRS không có:", sorted(errs_used - frs_err))
print(f"openapi: hợp lệ OpenAPI 3.1, {len(ids)} operation, {n} ví dụ đã kiểm, {len(errs_used)} mã ERR dùng")

# ---- AsyncAPI
a = yaml.safe_load(open(os.path.join(ROOT, "asyncapi-giam-sat-kiem-toan.yaml"), encoding="utf-8"))
assert a["asyncapi"].startswith("3.0")
areg = registry(a["components"])
m = 0
for k, sch in a["components"]["schemas"].items():
    for e in sch.get("examples", []): chk(areg, sch, e, "async/" + k); m += 1
codes = {c.get("title") for c in a["channels"].values()}
want_e = {f"EVT-13-{i:02d}" for i in range(1, 15)}
if not want_e <= codes: bad += 1; print("Thiếu EVT:", sorted(want_e - codes))
for ch in a["channels"].values():
    if not ch["address"].startswith("{tenant}.obs."): bad += 1; print("Địa chỉ topic sai quy ước:", ch["address"])
for op in a["operations"].values():
    ref = op["channel"]["$ref"].split("/")[-1]
    if ref not in a["channels"]: bad += 1; print("Operation trỏ kênh không có:", ref)
print(f"asyncapi: nạp được AsyncAPI {a['asyncapi']}, {len(a['channels'])} kênh, {len(a['operations'])} operation, {m} ví dụ đã kiểm")
sys.exit(1 if bad else 0)
