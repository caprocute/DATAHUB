#!/usr/bin/env python3
"""Kiểm hợp đồng PH-10.

- OpenAPI 3.1 hợp lệ (openapi-spec-validator); mọi ví dụ (thân yêu cầu, phản hồi thành công, phản hồi lỗi, lược đồ) khớp lược đồ (jsonschema 2020-12).
- Mỗi operation có x-datahub-id (duy nhất), x-datahub-fr, x-datahub-permission, x-datahub-errors; có ví dụ yêu cầu khi có thân JSON và ví dụ phản hồi JSON.
- Lệnh sửa, hành động control plane có If-Match (trừ danh sách miễn); lệnh tạo có Idempotency-Key; mã lỗi trong x-datahub-errors có ở FRS §8.1
  và mã HTTP của nó có trong responses.
- Không lược đồ nào có trường bí mật ngoài `SigningKeyIssued.secret` (readOnly, chỉ trả một lần).
- AsyncAPI: cấu trúc 3.0, mọi ví dụ thông điệp khớp payload và headers.

Chạy: python3 tools/check_contracts.py   (từ thư mục api/ph10). Cần: openapi-spec-validator, jsonschema ≥ 4.18, PyYAML.
"""
import os, re, sys, yaml, jsonschema
from openapi_spec_validator import validate
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRS = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH10-frs-su-kien.md")
ERRS = dict(re.findall(r"^\| (ERR-10-\d{3}) \| ([^|]+?) \|", open(FRS, encoding="utf-8").read(), re.M))
NO_IFMATCH = {"API-10-026", "API-10-051", "API-10-064", "API-10-071", "API-10-072", "API-10-111", "API-10-113"}

def fix(x, base):
    if isinstance(x, dict): return {k: (base + v if k == "$ref" and isinstance(v, str) and v.startswith("#/") else fix(v, base)) for k, v in x.items()}
    if isinstance(x, list): return [fix(i, base) for i in x]
    return x

bad = 0
def err(msg):
    global bad
    bad += 1; print("LỖI", msg)

def checker(components, base):
    reg = Registry().with_resource(base, Resource.from_contents(fix({"components": components}, base), default_specification=DRAFT202012))
    def check(schema, inst, where):
        errs = list(jsonschema.Draft202012Validator(fix(schema, base), registry=reg, format_checker=jsonschema.FormatChecker()).iter_errors(inst))
        if errs: err(f"{where}: {errs[0].message[:240]} tại {list(errs[0].absolute_path)}")
    return check

# ---------------- OpenAPI
fn = "openapi-event.yaml"
d = yaml.safe_load(open(os.path.join(ROOT, fn), encoding="utf-8"))
validate(d)
check = checker(d["components"], "urn:oa")
def media_examples(c):
    """Ví dụ của một media type: `example` hoặc `examples` (giá trị trực tiếp hoặc $ref tới components/examples)."""
    out = []
    if "example" in c: out.append(c["example"])
    for k, e in c.get("examples", {}).items():
        if "$ref" in e: e = d["components"]["examples"][e["$ref"].split("/")[-1]]
        out.append(e["value"])
    return out
n_ex = n_op = 0
ids = set()
for p, item in d["paths"].items():
    for meth, o in item.items():
        if meth in ("servers", "parameters"): continue
        n_op += 1
        oid = o.get("x-datahub-id", "?")
        for k in ("x-datahub-id", "x-datahub-fr", "x-datahub-permission", "x-datahub-errors"):
            if k not in o: err(f"{o['operationId']}: thiếu {k}")
        if oid in ids: err(f"{oid} trùng")
        ids.add(oid)
        names = {pp.get("$ref", "").split("/")[-1] for pp in o.get("parameters", [])}
        control = not p.startswith("/runtime/") and not o["tags"][0].startswith("Data plane")
        action = meth in ("put", "patch", "delete") or (meth == "post" and ":" in p.split("/")[-1])
        if control and action and "IfMatch" not in names and oid not in NO_IFMATCH: err(f"{oid}: lệnh ghi thiếu If-Match")
        if o.get("x-datahub-idempotent") == "required" and "IdempotencyKey" not in names: err(f"{oid}: thiếu Idempotency-Key")
        if meth == "post" and o["responses"].get("201") and "IdempotencyKey" not in names: err(f"{oid}: tạo (201) thiếu Idempotency-Key")
        for e in o.get("x-datahub-errors", []):
            if e not in ERRS: err(f"{oid}: {e} không có ở FRS §8.1"); continue
            st = ERRS[e].strip()
            if st.isdigit() and st not in o["responses"]: err(f"{oid}: {e} ({st}) không có trong responses")
        rb = o.get("requestBody", {}).get("content", {})
        for ct, c in rb.items():
            exs = media_examples(c)
            for ex in exs:
                if ct != "multipart/form-data": check(c["schema"], ex, f"{oid} yêu cầu {ct}")
                else: check(d["components"]["schemas"]["ImportMeta"], ex["meta"], f"{oid} meta")
                n_ex += 1
            if not exs and "json" in ct: err(f"{oid}: thân {ct} thiếu ví dụ")
        has_resp_ex, has_content = False, False
        for st, r in o["responses"].items():
            if "$ref" in r or not st.startswith("2"): continue
            for ct, c in r.get("content", {}).items():
                has_content = True
                for ex in media_examples(c):
                    has_resp_ex = True
                    if "json" in ct: check(c["schema"], ex, f"{oid} phản hồi {st}")
                    n_ex += 1
        if has_content and not has_resp_ex: err(f"{oid}: thiếu ví dụ phản hồi")
for name, r in d["components"]["responses"].items():
    for ct, c in r.get("content", {}).items():
        for k, e in c.get("examples", {}).items():
            check(c["schema"], e["value"], f"{name}/{k}"); n_ex += 1
for k, s in d["components"]["schemas"].items():
    for e in (s.get("examples", []) if isinstance(s, dict) else []): check(s, e, k); n_ex += 1
for k, sch in d["components"]["schemas"].items():
    props = sch.get("properties", {}) if isinstance(sch, dict) else {}
    for pk in props:
        if re.search(r"secret|password|token$", pk, re.I) and not (k == "SigningKeyIssued" and pk == "secret"):
            err(f"{k}.{pk}: trường bí mật ngoài SigningKeyIssued.secret")
if not d["components"]["schemas"]["SigningKeyIssued"]["properties"]["secret"].get("readOnly"): err("SigningKeyIssued.secret thiếu readOnly")
print(f"{fn}: hợp lệ OpenAPI 3.1; {n_op} operation, {len(ids)} mã API; {n_ex} ví dụ đã kiểm")

# ---------------- AsyncAPI
fn = "asyncapi-event.yaml"
a = yaml.safe_load(open(os.path.join(ROOT, fn), encoding="utf-8"))
if a.get("asyncapi") != "3.0.0": err("AsyncAPI không phải 3.0.0")
checka = checker(a["components"], "urn:aa")
n_ax = 0
for mk, msg in a["components"]["messages"].items():
    for i, ex in enumerate(msg.get("examples", [])):
        if "payload" in ex: checka(msg["payload"], ex["payload"], f"{mk} ví dụ {i} payload"); n_ax += 1
        if "headers" in ex and "headers" in msg: checka(msg["headers"], ex["headers"], f"{mk} ví dụ {i} headers"); n_ax += 1
    if not msg.get("examples"): err(f"{mk}: thiếu ví dụ")
for ck, ch in a["channels"].items():
    for mk, mr in ch.get("messages", {}).items():
        ref = mr["$ref"].split("/")[-1]
        if ref not in a["components"]["messages"]: err(f"kênh {ck}: thiếu thông điệp {ref}")
for ok, op in a["operations"].items():
    if op["channel"]["$ref"].split("/")[-1] not in a["channels"]: err(f"operation {ok}: kênh không có")
print(f"{fn}: {len(a['channels'])} kênh, {len(a['operations'])} operation, {len(a['components']['messages'])} thông điệp; {n_ax} ví dụ đã kiểm")
sys.exit(1 if bad else 0)
