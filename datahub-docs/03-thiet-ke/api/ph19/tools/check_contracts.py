#!/usr/bin/env python3
"""Kiểm hợp đồng PH-19: OpenAPI 3.1 hợp lệ, mọi ví dụ khớp lược đồ, mỗi operation có x-datahub-*, lệnh ghi có If-Match hoặc Idempotency-Key.

Chạy: python3 tools/check_contracts.py   (từ thư mục api/ph19). Cần: openapi-spec-validator, jsonschema ≥ 4.18.
AsyncAPI kiểm bằng @asyncapi/parser 3 (D03-04-PH19 §7).
"""
import os, sys, yaml, jsonschema
from openapi_spec_validator import validate
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = ["openapi-payment-admin.yaml", "openapi-payment-partner.yaml", "openapi-payment-callback.yaml"]

def fix(x):
    if isinstance(x, dict): return {k: ("urn:c" + v if k == "$ref" and isinstance(v, str) and v.startswith("#/") else fix(v)) for k, v in x.items()}
    if isinstance(x, list): return [fix(i) for i in x]
    return x

bad = 0
for fn in FILES:
    d = yaml.safe_load(open(os.path.join(ROOT, fn), encoding="utf-8"))
    validate(d)
    reg = Registry().with_resource("urn:c", Resource.from_contents(fix({"components": d["components"]}), default_specification=DRAFT202012))
    def check(schema, inst, where):
        global bad
        errs = list(jsonschema.Draft202012Validator(fix(schema), registry=reg).iter_errors(inst))
        if errs: bad += 1; print(f"{fn} {where}: {errs[0].message[:200]}")
    n = 0
    for p, m in d["paths"].items():
        for meth, o in m.items():
            for k in ("x-datahub-id", "x-datahub-fr"):
                if k not in o: bad += 1; print(f"{fn} {o['operationId']}: thiếu {k}")
            if fn != FILES[2] and "x-datahub-permission" not in o: bad += 1; print(f"{fn} {o['operationId']}: thiếu x-datahub-permission")
            names = {pp.get("$ref", "").split("/")[-1] for pp in o.get("parameters", [])}
            if meth in ("patch", "put", "delete") and not names & {"IfMatch"} and o["operationId"] not in ("putServiceGrant", "revokePartnerClient"):
                bad += 1; print(f"{fn} {o['operationId']}: lệnh ghi thiếu If-Match")
            if fn == FILES[1] and meth == "post" and "IdempotencyKey" not in names and "IdempotencyKeyOpt" not in names:
                bad += 1; print(f"{fn} {o['operationId']}: POST đối tác thiếu Idempotency-Key")
            for ct, c in o.get("requestBody", {}).get("content", {}).items():
                if "example" in c: check(c["schema"], c["example"], o["operationId"]); n += 1
    for name, r in d["components"].get("responses", {}).items():
        for ct, c in r.get("content", {}).items():
            for k, e in c.get("examples", {}).items(): check(c["schema"], e["value"], f"{name}/{k}"); n += 1
    for k, s in d["components"]["schemas"].items():
        for e in (s.get("examples", []) if isinstance(s, dict) else []): check(s, e, k); n += 1
    print(f"{fn}: hợp lệ OpenAPI 3.1, {n} ví dụ đã kiểm")
sys.exit(1 if bad else 0)
