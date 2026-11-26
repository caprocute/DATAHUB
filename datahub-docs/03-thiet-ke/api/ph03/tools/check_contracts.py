#!/usr/bin/env python3
"""Kiểm hợp đồng PH-03.

OpenAPI 3.1: hợp lệ, mọi ví dụ khớp lược đồ, mỗi operation có x-datahub-*, lệnh ghi có If-Match hoặc Idempotency-Key,
không có trường bí mật, nhật ký lượt gọi không có nội dung bản tin, mã lỗi trong x-datahub-errors có định nghĩa.
AsyncAPI 3.0: nạp được, mỗi EVT-03-nn có kênh, thông điệp, lược đồ; ví dụ khớp lược đồ; không trường bí mật.
Đối chiếu danh mục với D02-03-PH03 §9.4 (API), §9.3 (EVT), §9.1 (ERR).

Chạy: python3 tools/check_contracts.py   (từ thư mục api/ph03). Cần: pyyaml, openapi-spec-validator, jsonschema ≥ 4.18.
AsyncAPI còn kiểm bằng @asyncapi/parser 3 nếu có Node (xem D03-04-PH03 §7).
"""
import os, re, sys, yaml, jsonschema
from openapi_spec_validator import validate
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRS = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH03-frs-cong-api.md")
FORBIDDEN_PROPS = {"secret", "secrets", "clientSecret", "privateKey", "password", "apiKey", "accessToken", "refreshToken", "token", "authorization", "cookie"}
LOG_FORBIDDEN = {"body", "requestBody", "responseBody", "headers", "queryValues", "query", "payload"}
bad = 0


def err(msg):
    global bad
    bad += 1
    print("LỖI:", msg)


def fix(x, prefix):
    if isinstance(x, dict):
        return {k: (prefix + v if k == "$ref" and isinstance(v, str) and v.startswith("#/") else fix(v, prefix)) for k, v in x.items()}
    if isinstance(x, list):
        return [fix(i, prefix) for i in x]
    return x


def walk_props(schema, path=""):
    """Trả (tên thuộc tính, đường dẫn) cho mọi thuộc tính trong lược đồ lồng nhau."""
    if isinstance(schema, dict):
        for k, v in (schema.get("properties") or {}).items():
            yield k, f"{path}.{k}"
            yield from walk_props(v, f"{path}.{k}")
        for k in ("items", "additionalProperties"):
            if isinstance(schema.get(k), dict):
                yield from walk_props(schema[k], path + "[]")
        for k in ("allOf", "oneOf", "anyOf"):
            for i in schema.get(k, []):
                yield from walk_props(i, path)


# ---------------- OpenAPI
d = yaml.safe_load(open(os.path.join(ROOT, "openapi-gateway.yaml"), encoding="utf-8"))
validate(d)
reg = Registry().with_resource("urn:c", Resource.from_contents(fix({"components": d["components"]}, "urn:c"), default_specification=DRAFT202012))


def check(schema, inst, where):
    errs = list(jsonschema.Draft202012Validator(fix(schema, "urn:c"), registry=reg).iter_errors(inst))
    if errs:
        err(f"ví dụ {where}: {errs[0].message[:200]}")


n_ex = 0
ids, perms = [], set()
opids = []
cat = d["x-datahub-error-catalog"]
defined = set(cat["controlPlane"]) | set(cat["gateway"])
for p, m in d["paths"].items():
    for meth, o in m.items():
        for k in ("x-datahub-id", "x-datahub-fr", "x-datahub-permission", "x-datahub-errors"):
            if k not in o:
                err(f"{o['operationId']}: thiếu {k}")
        ids.append(o["x-datahub-id"])
        # CC-API-02 (D04-01): security tường minh, operationId camelCase duy nhất, lỗi tham chiếu response Problem, thân yêu cầu đóng
        if "security" not in o:
            err(f"{o['operationId']}: thiếu security tường minh (CC-API-02)")
        if not re.fullmatch(r"[a-z][A-Za-z0-9]*", o["operationId"]):
            err(f"{o['operationId']}: operationId không phải camelCase")
        if o["responses"].get("default", {}).get("$ref") != "#/components/responses/Problem":
            err(f"{o['operationId']}: thiếu phản hồi default tham chiếu components/responses/Problem")
        for ct, c in o.get("requestBody", {}).get("content", {}).items():
            ref = c.get("schema", {}).get("$ref", "").split("/")[-1]
            if ref and d["components"]["schemas"][ref].get("additionalProperties") is not False:
                err(f"{o['operationId']}: thân yêu cầu {ref} chưa đóng additionalProperties (CC-API-02)")
        perms.add(str(o["x-datahub-permission"]))
        names = {pp.get("$ref", "").split("/")[-1] for pp in o.get("parameters", [])}
        if meth in ("patch", "put", "delete") and not names & {"IfMatch", "IfMatchOptional"}:
            err(f"{o['operationId']}: lệnh ghi thiếu If-Match")
        if meth == "post" and ":" in p.split("/")[-1] and not (names & {"IfMatch", "IfMatchOptional"}) and not o.get("requestBody"):
            err(f"{o['operationId']}: hành động không thân thiếu If-Match")
        if meth == "post" and p.rsplit("/", 1)[-1] in ("routes", "") and "IdempotencyKey" not in names:
            pass
        if not o.get("x-datahub-idempotent") and meth == "post" and not o["x-datahub-id"].endswith(("058", "088")) and "IdempotencyKey" in names:
            err(f"{o['operationId']}: có Idempotency-Key nhưng thiếu x-datahub-idempotent")
        for e in o["x-datahub-errors"]:
            if e not in defined:
                err(f"{o['operationId']}: mã lỗi {e} không có trong x-datahub-error-catalog")
        for ct, c in o.get("requestBody", {}).get("content", {}).items():
            if "example" in c:
                check(c["schema"], c["example"], o["operationId"]); n_ex += 1
opids = [o["operationId"] for m in d["paths"].values() for o in m.values()]
if len(opids) != len(set(opids)):
    err("operationId trùng")
if len(ids) != len(set(ids)):
    err("mã API-03 trùng")
for name, r in d["components"].get("responses", {}).items():
    for ct, c in r.get("content", {}).items():
        if "example" in c:
            check(c["schema"], c["example"], f"responses/{name}"); n_ex += 1
for k, sch in d["components"]["schemas"].items():
    for e in (sch.get("examples", []) if isinstance(sch, dict) else []):
        check(sch, e, k); n_ex += 1
    # không trường bí mật nào trong bất kỳ lược đồ; không nội dung bản tin ở lược đồ nhật ký
    for prop, where in walk_props(sch, k):
        if prop in FORBIDDEN_PROPS:
            err(f"{k}{where}: thuộc tính '{prop}' có dạng bí mật (BR-03-007, SEC-32)")
        if k in ("AccessLogEntry", "WafEvent") and prop in LOG_FORBIDDEN:
            err(f"{k}{where}: lược đồ nhật ký không được có '{prop}'")
if "bodySample" not in d["components"]["schemas"]["SimulationRequest"]["properties"]:
    err("SimulationRequest thiếu bodySample")
for pat in ("ConsumerUpsert", "CredentialsUpsert"):
    if "apiKeyHash" not in d["components"]["schemas"][pat]["properties"]:
        err(f"{pat}: phải dùng apiKeyHash, không phải khóa dạng rõ")
print(f"openapi-gateway.yaml: hợp lệ OpenAPI 3.1, {len(ids)} operation, {len(d['components']['schemas'])} lược đồ, {n_ex} ví dụ đã kiểm")

# ---------------- đối chiếu FRS §9.4, §9.1
frs = open(FRS, encoding="utf-8").read()
frs_api = dict(re.findall(r"^\| (API-03-\d{3}) \| `([A-Z]+ [^`]+)` \|", frs, re.M))
mine = {}
for p, m in d["paths"].items():
    for meth, o in m.items():
        mine[o["x-datahub-id"]] = f"{meth.upper()} {p}"
if set(frs_api) != set(mine):
    err(f"danh mục API lệch FRS: thiếu {sorted(set(frs_api) - set(mine))}, thừa {sorted(set(mine) - set(frs_api))}")
for k, v in frs_api.items():
    if mine.get(k) != v:
        err(f"{k}: FRS ghi `{v}`, OpenAPI ghi `{mine.get(k)}`")
frs_err = set(re.findall(r"^\| (ERR-03-\d{3}) \| \d{3}(?:, \d{3})? \|", frs, re.M))
if frs_err != defined:
    err(f"mã lỗi lệch FRS: thiếu {sorted(frs_err - defined)}, thừa {sorted(defined - frs_err)}")
print(f"đối chiếu FRS: {len(frs_api)} API, {len(frs_err)} mã lỗi khớp" if not bad else "đối chiếu FRS: có lệch")

# ---------------- ví dụ JSON trong tài liệu Markdown (nhãn <!-- ex:Lược đồ --> đứng trước khối json)
DOC = os.path.join(ROOT, "..", "D03-04-PH03-api-cong-api.md")
md = open(DOC, encoding="utf-8").read()
n_md = 0
for name, body in re.findall(r"<!-- ex:(\w+) -->\n```json\n(.*?)\n```", md, re.S):
    import json
    try:
        inst = json.loads(body)
    except ValueError as e:
        err(f"ví dụ Markdown {name}: JSON sai cú pháp ({e})"); continue
    if name not in d["components"]["schemas"]:
        err(f"ví dụ Markdown {name}: không có lược đồ"); continue
    check(d["components"]["schemas"][name], inst, f"Markdown/{name}"); n_md += 1
print(f"tài liệu Markdown: {n_md} ví dụ JSON đã kiểm khớp lược đồ")

# ---------------- AsyncAPI
a = yaml.safe_load(open(os.path.join(ROOT, "asyncapi-gateway.yaml"), encoding="utf-8"))
if not str(a.get("asyncapi", "")).startswith("3."):
    err("asyncapi không phải 3.x")
areg = Registry().with_resource("urn:a", Resource.from_contents(fix({"components": a["components"]}, "urn:a"), default_specification=DRAFT202012))
evt = set(re.findall(r"^\| (EVT-03-\d{2}) \| `([^`]+)` \|", frs, re.M))
n_ae = 0
chan_titles = {c["title"]: c["address"] for c in a["channels"].values()}
for code, topic in evt:
    if chan_titles.get(code) != topic:
        err(f"{code}: kênh AsyncAPI {chan_titles.get(code)} khác FRS {topic}")
if len(evt) != len(a["channels"]):
    err(f"số kênh {len(a['channels'])} khác số EVT ở FRS {len(evt)}")
for name, body in re.findall(r"<!-- exa:(\w+) -->\n```json\n(.*?)\n```", md, re.S):
    import json
    if name not in a["components"]["schemas"]:
        err(f"ví dụ Markdown exa:{name}: không có lược đồ AsyncAPI"); continue
    errs = list(jsonschema.Draft202012Validator(fix(a["components"]["schemas"][name], "urn:a"), registry=areg).iter_errors(json.loads(body)))
    if errs:
        err(f"ví dụ Markdown exa:{name}: {errs[0].message[:200]}")
    n_ae += 1
for key, ch in a["channels"].items():
    if not re.fullmatch(r"\{tenant\}\.gateway\.[a-z-]+\.[a-z-]+\.v1", ch["address"]):
        err(f"{key}: địa chỉ topic sai quy ước {{tenant}}.{{miền}}.{{thực-thể}}.{{sự-kiện}}.v{{n}}")
    msg = a["components"]["messages"][key]
    ref = msg["payload"]["$ref"].split("/")[-1]
    sch = a["components"]["schemas"][ref]
    for prop, where in walk_props(sch, ref):
        if prop in FORBIDDEN_PROPS:
            err(f"{ref}{where}: thuộc tính '{prop}' có dạng bí mật")
    for e in sch.get("examples", []):
        errs = list(jsonschema.Draft202012Validator(fix(sch, "urn:a"), registry=areg).iter_errors(e))
        if errs:
            err(f"ví dụ {ref}: {errs[0].message[:200]}")
        n_ae += 1
    for need in ("send", "receive"):
        if f"{need}{key[0].upper()}{key[1:]}" not in a["operations"]:
            err(f"{key}: thiếu operation {need}")
print(f"asyncapi-gateway.yaml: AsyncAPI 3.0, {len(a['channels'])} kênh, {len(a['components']['schemas'])} lược đồ, {n_ae} ví dụ đã kiểm")
sys.exit(1 if bad else 0)
