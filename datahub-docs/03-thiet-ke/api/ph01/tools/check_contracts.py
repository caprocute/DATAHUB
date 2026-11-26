#!/usr/bin/env python3
"""Kiểm hợp đồng PH-01: OpenAPI 3.1 hợp lệ, mọi ví dụ khớp lược đồ, mỗi operation có x-datahub-*, lệnh ghi có If-Match hoặc lý do miễn,
mã API/ERR/EVT đủ và không trùng, bảng ERR khớp FRS §9.1, chỉ API-01-040 trả giá trị bí mật, AsyncAPI nạp được.

Chạy: python3 tools/check_contracts.py   (từ thư mục api/ph01). Cần: openapi-spec-validator, jsonschema ≥ 4.18, pyyaml.
AsyncAPI kiểm thêm bằng @asyncapi/parser 3 (D03-04-PH01 §7).
"""
import os, re, sys, yaml, jsonschema
from openapi_spec_validator import validate
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import spec
from errors import ERRORS

ROOT = os.path.dirname(HERE)
DOCS = os.path.dirname(os.path.dirname(os.path.dirname(ROOT)))  # datahub-docs
FRS = os.path.join(DOCS, "02-yeu-cau", "frs", "D02-03-PH01-frs-ket-nap-httt.md")


def fix(x):
    if isinstance(x, dict):
        return {k: ("urn:c" + v if k == "$ref" and isinstance(v, str) and v.startswith("#/") else fix(v)) for k, v in x.items()}
    if isinstance(x, list):
        return [fix(i) for i in x]
    return x


bad = 0


def fail(msg):
    global bad
    bad += 1
    print("LỖI:", msg)


d = yaml.safe_load(open(os.path.join(ROOT, "openapi-onboarding.yaml"), encoding="utf-8"))
validate(d)
reg = Registry().with_resource("urn:c", Resource.from_contents(fix({"components": d["components"]}), default_specification=DRAFT202012))


def check(schema, inst, where):
    errs = list(jsonschema.Draft202012Validator(fix(schema), registry=reg).iter_errors(inst))
    if errs:
        fail(f"{where}: {errs[0].message[:220]} @ {list(errs[0].absolute_path)}")


n = 0
ids = []
for p, m in d["paths"].items():
    for meth, o in m.items():
        for k in ("x-datahub-id", "x-datahub-fr", "x-datahub-permission", "x-datahub-errors"):
            if k not in o:
                fail(f"{o['operationId']}: thiếu {k}")
        ids.append(o["x-datahub-id"])
        names = {pp.get("$ref", "").split("/")[-1] for pp in o.get("parameters", [])}
        code = o["x-datahub-id"][-3:]
        if meth in ("patch", "put", "delete") and not names & {"IfMatch", "IfMatchOptional"}:
            fail(f"{o['operationId']}: lệnh ghi thiếu If-Match")
        if meth == "post" and o.get("x-datahub-idempotent") and "IdempotencyKey" not in names:
            fail(f"{o['operationId']}: thiếu Idempotency-Key")
        for e in o["x-datahub-errors"]:
            if e[-3:] not in {c for c, *_ in ERRORS}:
                fail(f"{o['operationId']}: mã lỗi lạ {e}")
        for ct, c in o.get("requestBody", {}).get("content", {}).items():
            if "example" in c:
                check(c["schema"], c["example"], f"{o['operationId']} yêu cầu"); n += 1
        for st, r in o["responses"].items():
            for ct, c in (r.get("content") or {}).items():
                if "example" in c and "schema" in c:
                    check(c["schema"], c["example"], f"{o['operationId']} {st}"); n += 1
for name, r in d["components"].get("responses", {}).items():
    for ct, c in r.get("content", {}).items():
        if "example" in c:
            check(c["schema"], c["example"], f"responses/{name}"); n += 1
for k, s in d["components"]["schemas"].items():
    for e in (s.get("examples", []) if isinstance(s, dict) else []):
        check(s, e, f"schemas/{k}"); n += 1

# mã API đủ, không trùng, khớp spec.py
want = [f"API-01-{o[0]}" for o in spec.OPS]
if sorted(ids) != sorted(want) or len(set(ids)) != len(ids):
    fail("danh sách API-01 trong OpenAPI khác spec.py hoặc có mã trùng")
nums = sorted(int(i[-3:]) for i in ids)
miss = [f"{i:03d}" for i in range(1, nums[-1] + 1) if i not in nums]
if miss:
    fail(f"thiếu mã API-01: {miss}")

# Chỉ API-01-040 trả giá trị bí mật; mọi lược đồ khác không có trường bí mật
for k, sch in d["components"]["schemas"].items():
    txt = str(sch)
    if re.search(r"'(clientSecret|client_secret|secret|secrets|password|privateKey|private_key)'", txt) and k != "HandoverOpenResult":
        fail(f"{k}: có trường bí mật ngoài lược đồ bàn giao")
    if "secret_ref" in txt.replace("secret_ref`", "") and "không có `secret_ref`" not in txt and "Không có" not in txt and "không có" not in txt and "Không trả" not in txt:
        fail(f"{k}: nhắc secret_ref")
if not d["components"]["schemas"]["HandoverOpenResult"]["properties"]["thongTinKetNoi"]["properties"]["clientSecret"].get("readOnly"):
    fail("clientSecret thiếu readOnly")
for path, m in d["paths"].items():
    for meth, o in m.items():
        if o["x-datahub-id"] != "API-01-040":
            for st, r in o["responses"].items():
                if "Cache-Control" in str(r.get("headers", {})) and o["x-datahub-id"] not in ("API-01-070",):
                    fail(f"{o['operationId']}: Cache-Control lạ")

# Bảng ERR khớp FRS §9.1
frs = open(FRS, encoding="utf-8").read()
rows = dict((c, h) for c, h, _ in re.findall(r"^\| (ERR-01-\d{3}) \| (\d{3}) \| ([^|]+) \|$", frs, re.M))
for c, h, mean, _ in ERRORS:
    if c <= "050":
        if rows.get(f"ERR-01-{c}") != h:
            fail(f"ERR-01-{c}: HTTP {h} khác FRS ({rows.get(f'ERR-01-{c}')})")
if len([c for c in rows if c[-3:] <= "050"]) != 50:
    fail("FRS không đủ 50 mã lỗi")
used = set()
for p, m in d["paths"].items():
    for o in m.values():
        used |= {e[-3:] for e in o["x-datahub-errors"]}
unused = [c for c, *_ in ERRORS if c not in used]
if unused:
    print("Cảnh báo: mã lỗi chưa gắn thao tác nào (phát từ nền hoặc từ luồng phi API):", unused)
print(f"openapi-onboarding.yaml: hợp lệ OpenAPI 3.1, {len(ids)} operation, {n} ví dụ đã kiểm")

# AsyncAPI: nạp được, đủ EVT-01-01…15, ví dụ khớp lược đồ
a = yaml.safe_load(open(os.path.join(ROOT, "asyncapi-onboarding.yaml"), encoding="utf-8"))
if a.get("asyncapi") != "3.0.0":
    fail("asyncapi không phải 3.0.0")
evt = sorted(re.findall(r"EVT-01-\d{2}", " ".join(c.get("title", "") for c in a["channels"].values())))
if evt != [f"EVT-01-{i:02d}" for i in range(1, 16)]:
    fail(f"AsyncAPI thiếu hoặc thừa EVT-01: {evt}")
areg = Registry().with_resource("urn:a", Resource.from_contents(fix({"components": a["components"]}) if False else
        {"components": {"schemas": {k: yaml.safe_load(yaml.safe_dump(v).replace("#/components/schemas/", "urn:a#/components/schemas/")) for k, v in a["components"]["schemas"].items()}}},
        default_specification=DRAFT202012))
na = 0
for k, msg in a["components"]["messages"].items():
    sch = yaml.safe_load(yaml.safe_dump(msg["payload"]).replace("#/components/schemas/", "urn:a#/components/schemas/"))
    for ex in msg.get("examples", []):
        errs = list(jsonschema.Draft202012Validator(sch, registry=areg).iter_errors(ex["payload"]))
        na += 1
        if errs:
            fail(f"asyncapi {k}: {errs[0].message[:200]} @ {list(errs[0].absolute_path)}")
for k, s in a["components"]["schemas"].items():
    if re.search(r"'(secret|clientSecret|password|token)'", str(s)):
        fail(f"asyncapi {k}: có trường bí mật")
print(f"asyncapi-onboarding.yaml: AsyncAPI 3.0, {len(a['channels'])} kênh, {na} ví dụ đã kiểm")
sys.exit(1 if bad else 0)
