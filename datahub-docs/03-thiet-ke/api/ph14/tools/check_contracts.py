#!/usr/bin/env python3
"""Kiểm hợp đồng PH-14: OpenAPI 3.1 hợp lệ, ví dụ khớp lược đồ, mỗi operation đủ x-datahub-*, mã API/ERR/EVT khớp tài liệu.

Chạy: python3 tools/check_contracts.py   (từ thư mục api/ph14). Cần: openapi-spec-validator, jsonschema ≥ 4.18, pyyaml.
AsyncAPI kiểm thêm bằng @asyncapi/parser 3 (nếu có) ở CI-5.
"""
import os, re, sys, yaml, jsonschema
from openapi_spec_validator import validate
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bad = 0


def fix(x):
    if isinstance(x, dict): return {k: ("urn:c" + v if k == "$ref" and isinstance(v, str) and v.startswith("#/") else fix(v)) for k, v in x.items()}
    if isinstance(x, list): return [fix(i) for i in x]
    return x


def err(msg):
    global bad
    bad += 1
    print(msg)


d = yaml.safe_load(open(os.path.join(ROOT, "openapi-national.yaml"), encoding="utf-8"))
validate(d)
reg = Registry().with_resource("urn:c", Resource.from_contents(fix({"components": d["components"]}), default_specification=DRAFT202012))


def check(schema, inst, where):
    errs = list(jsonschema.Draft202012Validator(fix(schema), registry=reg).iter_errors(inst))
    if errs: err(f"openapi {where}: {errs[0].message[:200]}")


n, ids, refs = 0, [], set()
for p, m in d["paths"].items():
    for meth, o in m.items():
        for k in ("x-datahub-id", "x-datahub-fr", "x-datahub-permission", "x-datahub-errors", "operationId", "summary"):
            if k not in o: err(f"{o.get('operationId')}: thiếu {k}")
        ids.append(o["x-datahub-id"])
        names = {pp.get("$ref", "").split("/")[-1] for pp in o.get("parameters", [])}
        if meth in ("patch", "put", "delete") and "IfMatch" not in names and o["x-datahub-id"] not in ("API-14-022",):
            err(f"{o['operationId']}: lệnh ghi thiếu If-Match")
        if meth == "post" and o.get("x-datahub-idempotent") and not names & {"IdempotencyKey", "IdempotencyKeyOpt"}:
            err(f"{o['operationId']}: thiếu Idempotency-Key")
        for e in o["x-datahub-errors"]:
            refs.add(e)
        for ct, c in o.get("requestBody", {}).get("content", {}).items():
            if "example" in c: check(c["schema"], c["example"], o["operationId"]); n += 1
for name, r in d["components"].get("responses", {}).items():
    for ct, c in r.get("content", {}).items():
        if "example" in c: check(c["schema"], c["example"], f"response {name}"); n += 1
for k, s in d["components"]["schemas"].items():
    for e in (s.get("examples", []) if isinstance(s, dict) else []): check(s, e, k); n += 1
# Không lược đồ nào trả khóa riêng hoặc bí mật
for k, sch in d["components"]["schemas"].items():
    txt = str(sch).lower()
    for bad_key in ("'privatekey'", "'clientsecret'", "'password'", "'secret'"):
        if bad_key in txt: err(f"{k}: có trường {bad_key} (cấm trả hoặc nhận bí mật ở API này)")
# Mã API: đủ và không trùng
want = {f"API-14-{o[0]}" for o in spec.OPS}
if len(ids) != len(set(ids)): err("mã API trùng")
if set(ids) != want: err(f"mã API lệch: {sorted(set(ids) ^ want)}")
# Mã lỗi dùng phải có ở bảng
known = {f"ERR-14-{c}" for c, _, _ in spec.ERRS}
if refs - known: err(f"mã lỗi chưa định nghĩa: {sorted(refs - known)}")
print(f"openapi-national.yaml: hợp lệ OpenAPI 3.1, {len(ids)} operation, {n} ví dụ đã kiểm, {len(refs)} mã lỗi tham chiếu")

# AsyncAPI: nạp được, đủ EVT, mỗi kênh có message và schema tồn tại
a = yaml.safe_load(open(os.path.join(ROOT, "asyncapi-national.yaml"), encoding="utf-8"))
if not str(a.get("asyncapi", "")).startswith("3."): err("asyncapi không phải 3.x")
titles = {c.get("title") for c in a["channels"].values()}
need = {e[1] for e in spec.EVTS if e[1].startswith("EVT")}
if need - titles: err(f"thiếu EVT: {sorted(need - titles)}")
sch = a["components"]["schemas"]
for k, msg in a["components"]["messages"].items():
    t = msg["payload"]["$ref"].split("/")[-1]
    if t not in sch: err(f"message {k}: thiếu schema {t}")
areg = Registry().with_resource("urn:c", Resource.from_contents(fix({"components": a["components"]}), default_specification=DRAFT202012))
for k, s in sch.items():
    if "examples" in s:
        for e in s["examples"]:
            es = list(jsonschema.Draft202012Validator(fix(s), registry=areg).iter_errors(e))
            if es: err(f"asyncapi {k}: ví dụ không khớp: {es[0].message[:150]}")
        n += 1
print(f"asyncapi-national.yaml: AsyncAPI {a['asyncapi']}, {len(a['channels'])} kênh, {len(need)} EVT công bố")
sys.exit(1 if bad else 0)
