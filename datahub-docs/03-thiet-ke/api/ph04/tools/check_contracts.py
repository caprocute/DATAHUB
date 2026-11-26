#!/usr/bin/env python3
"""Kiểm hợp đồng PH-04 (D03-04-PH04 §7), chép từ ph05/tools/check_contracts.py và chỉnh cho PH-04.

OpenAPI: hợp lệ 3.1; mỗi operation có x-datahub-id, x-datahub-fr, x-datahub-permission, summary, description;
lệnh ghi (POST, PUT, PATCH, DELETE) có If-Match hoặc Idempotency-Key, trừ lệnh không đổi dữ liệu (danh sách MIEN);
mỗi operation có ví dụ yêu cầu (thân, hoặc chỉ dòng yêu cầu khi không có thân) và ví dụ phản hồi thành công;
mọi ví dụ (thân, tham số, phản hồi) khớp lược đồ.
AsyncAPI: mỗi message có x-datahub-fr, x-datahub-receivers và ví dụ payload khớp lược đồ; cú pháp AsyncAPI 3.0
kiểm thêm bằng @asyncapi/parser 3 nếu có Node (đặt DH_ASYNCAPI_PARSER trỏ tới thư mục node_modules chứa nó).

Chạy: python3 tools/check_contracts.py   (từ bất kỳ đâu). Cần: openapi-spec-validator, jsonschema ≥ 4.18.
"""
import json, os, subprocess, sys, yaml, jsonschema
from openapi_spec_validator import validate
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Lệnh POST không đổi tài nguyên hoặc chỉ tính toán (kiểm tra, xem trước): không cần If-Match, Idempotency-Key
MIEN = {"validateVersion", "validateYaml", "checkExpression", "previewMapping", "cancelTestRun", "decideProposal",
        "heartbeatSession", "endSession", "resendCommand"}
bad = 0


def loi(msg):
    global bad
    bad += 1
    print("LỖI", msg)


def fix(x):
    if isinstance(x, dict): return {k: ("urn:c" + v if k == "$ref" and isinstance(v, str) and v.startswith("#/") else fix(v)) for k, v in x.items()}
    if isinstance(x, list): return [fix(i) for i in x]
    return x


def checker(components):
    reg = Registry().with_resource("urn:c", Resource.from_contents(fix({"components": components}), default_specification=DRAFT202012))
    def check(schema, inst, where):
        errs = list(jsonschema.Draft202012Validator(fix(schema), registry=reg).iter_errors(inst))
        if errs: loi(f"{where}: {errs[0].message[:200]} tại {list(errs[0].absolute_path)}")
        return 1
    return check


# ---------------------------------------------------------------- OpenAPI
fn = "openapi-integration.yaml"
d = yaml.safe_load(open(os.path.join(ROOT, fn), encoding="utf-8"))
validate(d)
C = d["components"]
check = checker(C)
n_ex = n_op = 0
for p, m in d["paths"].items():
    for meth, o in m.items():
        n_op += 1
        oid = o["operationId"]
        for k in ("x-datahub-id", "x-datahub-fr", "x-datahub-permission", "summary", "description"):
            if not o.get(k): loi(f"{oid}: thiếu {k}")
        prm = [C["parameters"][x["$ref"].split("/")[-1]] if "$ref" in x else x for x in o.get("parameters", [])]
        names = {x["name"] for x in prm}
        if meth in ("post", "put", "patch", "delete") and not names & {"If-Match", "Idempotency-Key"} and oid not in MIEN:
            loi(f"{oid}: lệnh ghi thiếu If-Match hoặc Idempotency-Key")
        for x in prm:
            if x.get("required") and x["in"] in ("path", "header") and x["name"] not in ("traceparent",) and "example" not in x:
                loi(f"{oid}: tham số {x['name']} thiếu ví dụ")
            if "example" in x: n_ex += check(x["schema"], x["example"], f"{oid} tham số {x['name']}")
        rb = o.get("requestBody")
        if rb:
            for ct, c in rb["content"].items():
                if "example" not in c or c["example"] is None: loi(f"{oid}: thân yêu cầu {ct} thiếu ví dụ")
                else: n_ex += check(c["schema"], c["example"], f"{oid} yêu cầu")
        ok = [(code, r) for code, r in o["responses"].items() if code.startswith("2")]
        for code, r in ok:
            if code == "204": continue
            cs = r.get("content", {})
            if not any(c.get("example") is not None for c in cs.values()): loi(f"{oid}: phản hồi {code} thiếu ví dụ")
            for ct, c in cs.items():
                if c.get("example") is not None and ct != "text/event-stream": n_ex += check(c["schema"], c["example"], f"{oid} phản hồi {code}")
            for h, hv in (r.get("headers") or {}).items():
                if not hv.get("example"): loi(f"{oid}: tiêu đề phản hồi {h} thiếu ví dụ")
for name, r in C["responses"].items():
    for ct, c in (r.get("content") or {}).items():
        if "example" in c: n_ex += check(c["schema"], c["example"], f"responses/{name}")
print(f"{fn}: hợp lệ OpenAPI 3.1, {n_op} operation, {n_ex} ví dụ đã kiểm khớp lược đồ")

# ---------------------------------------------------------------- AsyncAPI
fn = "asyncapi-integration.yaml"
a = yaml.safe_load(open(os.path.join(ROOT, fn), encoding="utf-8"))
check = checker(a["components"])
n_ex = 0
for k, msg in a["components"]["messages"].items():
    for f in ("x-datahub-fr", "x-datahub-receivers", "examples"):
        if not msg.get(f): loi(f"{fn} {k}: thiếu {f}")
    for e in msg.get("examples", []):
        n_ex += check(msg["payload"], e["payload"], f"{fn} {k} payload")
        if "headers" in e: n_ex += check(msg["headers"], e["headers"], f"{fn} {k} headers")
codes = sorted(ch["title"] for ch in a["channels"].values())
if codes != [f"EVT-04-{i:02d}" for i in range(1, 15)]: loi(f"{fn}: dải kênh không đủ EVT-04-01…14: {codes}")
print(f"{fn}: {len(a['channels'])} kênh, {n_ex} ví dụ đã kiểm khớp lược đồ")

nm = os.environ.get("DH_ASYNCAPI_PARSER")
if nm:
    js = ("const {Parser}=require('@asyncapi/parser');const fs=require('fs');"
          "new Parser().validate(fs.readFileSync(process.argv[1],'utf8')).then(r=>{const e=r.filter(x=>x.severity<=1);"
          "r.filter(x=>x.severity<=1).forEach(x=>console.log((x.severity===0?'LỖI ':'CẢNH BÁO ')+x.code+' '+x.message+' '+JSON.stringify(x.path)));"
          "console.log('@asyncapi/parser: '+r.filter(x=>x.severity===0).length+' lỗi, '+r.filter(x=>x.severity===1).length+' cảnh báo');process.exit(r.some(x=>x.severity===0)?1:0)})")
    rc = subprocess.run(["node", "-e", js, os.path.join(ROOT, fn)], env={**os.environ, "NODE_PATH": nm}).returncode
    if rc: loi(f"{fn}: @asyncapi/parser báo lỗi")
sys.exit(1 if bad else 0)
