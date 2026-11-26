#!/usr/bin/env python3
"""Kiểm hợp đồng PH-16.

- OpenAPI 3.1 hợp lệ (openapi-spec-validator); mọi ví dụ (thân yêu cầu, phản hồi thành công, phản hồi lỗi) khớp lược đồ (jsonschema 2020-12).
- Mỗi operation có x-datahub-id (duy nhất), x-datahub-fr, x-datahub-permission, x-datahub-errors; có ví dụ yêu cầu khi có thân JSON và ví dụ phản hồi JSON.
- Lệnh sửa, hành động trên tài nguyên có If-Match (trừ danh sách miễn); lệnh tạo có Idempotency-Key; mã lỗi trong x-datahub-errors có ở FRS 9.1
  và có ít nhất một mã HTTP của nó trong responses; mã ERR-16-105…125 không có mã HTTP (chỉ ghi ở nhật ký hoặc thông báo) không xuất hiện ở operation nào.
- Không lược đồ nào có trường bí mật (secret, password, token) và không trường nào mang giá trị khóa định danh trên đường dẫn.
- AsyncAPI: cấu trúc 3.0, mọi ví dụ thông điệp khớp payload; đủ 14 sự kiện phát EVT-08 đúng topic và 8 kênh tiêu thụ EVT-06, EVT-07.

Chạy: python3 tools/check_contracts.py   (từ thư mục api/ph16). Cần: openapi-spec-validator, jsonschema ≥ 4.18, PyYAML.
"""
import os, re, sys, yaml, jsonschema
from openapi_spec_validator import validate
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import spec

ROOT = spec.ROOT
ERRS = spec.ERR
NOIFM = {r[0] for r in spec.ROWS if "noifm" in spec.OPS[r[0]]["flags"]}


def fix(x, base):
    if isinstance(x, dict):
        return {k: (base + v if k == "$ref" and isinstance(v, str) and v.startswith("#/") else fix(v, base)) for k, v in x.items()}
    if isinstance(x, list):
        return [fix(i, base) for i in x]
    return x


bad = 0


def err(msg):
    global bad
    bad += 1
    print("LỖI", msg)


def checker(components, base):
    reg = Registry().with_resource(base, Resource.from_contents(fix({"components": components}, base), default_specification=DRAFT202012))

    def check(schema, inst, where):
        errs = list(jsonschema.Draft202012Validator(fix(schema, base), registry=reg, format_checker=jsonschema.FormatChecker()).iter_errors(inst))
        if errs:
            err(f"{where}: {errs[0].message[:240]} tại {list(errs[0].absolute_path)}")
    return check


fn = "openapi-kpi.yaml"
d = yaml.safe_load(open(os.path.join(ROOT, fn), encoding="utf-8"))
validate(d)
check = checker(d["components"], "urn:oa")


def media_examples(c):
    out = []
    if "example" in c:
        out.append(c["example"])
    for k, e in c.get("examples", {}).items():
        if "$ref" in e:
            e = d["components"]["examples"][e["$ref"].split("/")[-1]]
        out.append(e["value"])
    return out


n_ex = n_op = 0
ids = set()
opids = set()
for p, item in d["paths"].items():
    for meth, o in item.items():
        if meth in ("servers", "parameters"):
            continue
        n_op += 1
        oid = o.get("x-datahub-id", "?")
        code = oid[-3:]
        for k in ("x-datahub-id", "x-datahub-fr", "x-datahub-permission", "x-datahub-errors"):
            if k not in o:
                err(f"{o['operationId']}: thiếu {k}")
        if oid in ids:
            err(f"{oid} trùng")
        ids.add(oid)
        if o["operationId"] in opids:
            err(f"operationId {o['operationId']} trùng")
        opids.add(o["operationId"])
        names = {pp.get("$ref", "").split("/")[-1] for pp in o.get("parameters", [])}
        action = meth in ("put", "patch", "delete") or (meth == "post" and re.search(r"\}?:[a-z-]+$", p) is not None)
        if action and "IfMatch" not in names and code not in NOIFM:
            err(f"{oid}: lệnh ghi thiếu If-Match")
        if o.get("x-datahub-idempotent") == "required" and "IdempotencyKey" not in names:
            err(f"{oid}: thiếu Idempotency-Key")
        if meth == "post" and o["responses"].get("201") and "IdempotencyKey" not in names:
            err(f"{oid}: tạo (201) thiếu Idempotency-Key")
        if meth == "post" and o["responses"].get("202") and "IdempotencyKey" not in names and "IfMatch" not in names and not o["x-datahub-id"].endswith(("050", "111", "125")):
            err(f"{oid}: lệnh bất đồng bộ (202) thiếu Idempotency-Key hoặc If-Match")
        if "IfMatch" in names and "428" not in o["responses"]:
            err(f"{oid}: If-Match thiếu phản hồi 428")
        for e in o.get("x-datahub-errors", []):
            if e not in ERRS:
                err(f"{oid}: {e} không có ở FRS 9.1")
                continue
            sts = ERRS[e][0]
            if not sts:
                err(f"{oid}: {e} không có mã HTTP, không trả cho người gọi")
            elif not any(str(s) in o["responses"] for s in sts):
                err(f"{oid}: {e} ({sts}) không có trong responses")
        rb = o.get("requestBody", {}).get("content", {})
        for ct, c in rb.items():
            exs = media_examples(c)
            for ex in exs:
                check(c["schema"], ex, f"{oid} yêu cầu {ct}")
                n_ex += 1
            if not exs:
                err(f"{oid}: thân {ct} thiếu ví dụ")
        has_resp_ex, has_json = False, False
        for st, r in o["responses"].items():
            if "$ref" in r or not st.startswith("2"):
                continue
            for ct, c in r.get("content", {}).items():
                for ex in media_examples(c):
                    has_resp_ex = True
                    check(c["schema"], ex, f"{oid} phản hồi {st}")
                    n_ex += 1
                has_json = has_json or "json" in ct
        if has_json and not has_resp_ex:
            err(f"{oid}: thiếu ví dụ phản hồi")
for name, r in d["components"]["responses"].items():
    for ct, c in r.get("content", {}).items():
        for k, e in c.get("examples", {}).items():
            check(c["schema"], e["value"], f"{name}/{k}")
            n_ex += 1
for k, sch in d["components"]["schemas"].items():
    for pk in sch.get("properties", {}):
        if re.search(r"secret|password|token$", pk, re.I):
            err(f"{k}.{pk}: trường bí mật")
want = {f"API-16-{r[0]}" for r in spec.ROWS}
if ids != want:
    err(f"mã API lệch: thiếu {sorted(want - ids)}, thừa {sorted(ids - want)}")
print(f"{fn}: hợp lệ OpenAPI 3.1; {n_op} operation, {len(ids)} mã API; {len(d['components']['schemas'])} lược đồ; {n_ex} ví dụ đã kiểm")

fn = "asyncapi-kpi.yaml"
p = os.path.join(ROOT, fn)
if os.path.exists(p):
    a = yaml.safe_load(open(p, encoding="utf-8"))
    if a.get("asyncapi") != "3.0.0":
        err("AsyncAPI không phải 3.0.0")
    checka = checker(a["components"], "urn:aa")
    n_ax = 0
    for mk, msg in a["components"]["messages"].items():
        for i, ex in enumerate(msg.get("examples", [])):
            if "payload" in ex:
                checka(msg["payload"], ex["payload"], f"{mk} ví dụ {i} payload")
                n_ax += 1
            if "headers" in ex and "headers" in msg:
                checka(msg["headers"], ex["headers"], f"{mk} ví dụ {i} headers")
                n_ax += 1
        if not msg.get("examples"):
            err(f"{mk}: thiếu ví dụ")
    for ck, ch in a["channels"].items():
        for mk, mr in ch.get("messages", {}).items():
            if mr["$ref"].split("/")[-1] not in a["components"]["messages"]:
                err(f"kênh {ck}: thiếu thông điệp")
    for ok, op in a["operations"].items():
        if op["channel"]["$ref"].split("/")[-1] not in a["channels"]:
            err(f"operation {ok}: kênh không có")
    evs = {ch["title"]: ch["address"] for ch in a["channels"].values()}
    for code, topic, _w, _c in spec.EVT:
        if evs.get(code) != topic.replace("t68.", "{tenant}.", 1):
            err(f"{code}: topic {evs.get(code)} lệch FRS {topic}")
    import glob
    other = {}
    for f in glob.glob(os.path.join(ROOT, "..", "ph*", "asyncapi*.yaml")):
        if os.path.abspath(f) == os.path.abspath(p):
            continue
        od = yaml.safe_load(open(f, encoding="utf-8"))
        for c_ in od.get("channels", {}).values():
            other.setdefault(c_.get("title"), c_["address"])
    for code in spec.EVT_IN_CODES:
        if code not in evs:
            err(f"{code}: thiếu kênh tiêu thụ")
        elif code in other and other[code] != evs[code]:
            err(f"{code}: kênh tiêu thụ {evs[code]} lệch bên phát {other[code]}")
    print(f"{fn}: {len(a['channels'])} kênh, {len(a['operations'])} operation, {len(a['components']['messages'])} thông điệp; {n_ax} ví dụ đã kiểm")
sys.exit(1 if bad else 0)
