#!/usr/bin/env python3
"""Kiểm hợp đồng PH-02: OpenAPI 3.1 hợp lệ, ví dụ khớp lược đồ, mỗi operation có x-datahub-*, lệnh ghi có If-Match hoặc Idempotency-Key,
đủ API-02-001…098 của FRS, đủ EVT-02-01…16 và ERR-02 trong tài liệu, AsyncAPI nạp được và payload ví dụ khớp.

Chạy: python3 tools/check_contracts.py   (cần pyyaml, openapi-spec-validator, jsonschema >= 4.18, referencing).
AsyncAPI kiểm thêm bằng @asyncapi/parser 3 trong CI (CI-5)."""
import os
import re
import sys

import jsonschema
import yaml
from openapi_spec_validator import validate
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(ROOT, "..", "..", "..")
FRS = os.path.join(DOCS, "02-yeu-cau", "frs", "D02-03-PH02-frs-danh-muc-dich-vu.md")
MAIN = os.path.join(ROOT, "..", "D03-04-PH02-api-danh-muc-dich-vu.md")


def fix(x):
    if isinstance(x, dict):
        return {k: ("urn:c" + v if k == "$ref" and isinstance(v, str) and v.startswith("#/") else fix(v)) for k, v in x.items()}
    if isinstance(x, list):
        return [fix(i) for i in x]
    return x


bad = 0


def err(msg):
    global bad
    bad += 1
    print("LỖI:", msg)


# ---------- OpenAPI
d = yaml.safe_load(open(os.path.join(ROOT, "openapi-catalog.yaml"), encoding="utf-8"))
validate(d)
reg = Registry().with_resource("urn:c", Resource.from_contents(fix({"components": d["components"]}), default_specification=DRAFT202012))


def check(schema, inst, where):
    es = list(jsonschema.Draft202012Validator(fix(schema), registry=reg).iter_errors(inst))
    if es:
        err(f"{where}: {es[0].message[:200]}")


n = 0
ids, opids = [], set()
for p, m in d["paths"].items():
    for meth, o in m.items():
        i = o.get("x-datahub-id")
        ids.append(i)
        if o["operationId"] in opids:
            err(f"operationId trùng {o['operationId']}")
        opids.add(o["operationId"])
        for k in ("x-datahub-id", "x-datahub-fr", "x-datahub-permission"):
            if k not in o:
                err(f"{o['operationId']}: thiếu {k}")
        names = {pp.get("$ref", "").split("/")[-1] for pp in o.get("parameters", [])}
        if meth in ("patch", "put", "delete") and "IfMatch" not in names and i not in ("API-02-017",):
            err(f"{i}: lệnh ghi thiếu If-Match")
        if meth == "post" and p.startswith("/internal") is False and "IdempotencyKey" not in names and i not in (
                "API-02-015", "API-02-021", "API-02-022", "API-02-085", "API-02-092", "API-02-093", "API-02-094"):
            err(f"{i}: POST thiếu Idempotency-Key")
        for ct, c in o.get("requestBody", {}).get("content", {}).items():
            if "example" in c:
                check(c["schema"], c["example"], i)
                n += 1
        if "default" in o["responses"]:
            err(f"{i}: dùng phản hồi default")
for name, r in d["components"].get("responses", {}).items():
    for ct, c in r.get("content", {}).items():
        if "example" in c:
            check(c["schema"], c["example"], f"responses/{name}")
            n += 1
for k, s in d["components"]["schemas"].items():
    for e in (s.get("examples", []) if isinstance(s, dict) else []):
        check(s, e, k)
        n += 1
# mã API
dup = {x for x in ids if ids.count(x) > 1}
if dup:
    err(f"mã API trùng: {sorted(dup)}")
frs_txt = open(FRS, encoding="utf-8").read()
need = {f"API-02-{i:03d}" for i in range(1, 99)}
miss = need - set(ids)
if miss:
    err(f"thiếu API theo FRS: {sorted(miss)}")
extra = sorted(set(ids) - need)
# không operation nào trả hoặc nhận giá trị bí mật
for k, s in d["components"]["schemas"].items():
    t = str(s)
    for bad_key in ("'password'", "'secret'", "'privateKey'", "'clientSecret'", "'apiKey'"):
        if bad_key in t:
            err(f"{k}: lược đồ có trường bí mật {bad_key}")
# mọi ERR-02 dùng trong OpenAPI phải có ở FRS §9.1
frs_err = set(re.findall(r"^\| (ERR-02-\d{3}) \|", frs_txt, re.M))
used = set(re.findall(r"ERR-02-\d{3}", yaml.safe_dump(d, allow_unicode=True)))
for e in sorted(used - frs_err):
    err(f"{e} dùng ở OpenAPI nhưng không có ở FRS §9.1")
print(f"openapi-catalog.yaml: hợp lệ OpenAPI 3.1, {len(ids)} operation (thêm ngoài FRS: {', '.join(extra)}), {n} ví dụ đã kiểm, {len(d['components']['schemas'])} lược đồ")

# ---------- AsyncAPI
af = os.path.join(ROOT, "asyncapi-catalog.yaml")
if os.path.exists(af):
    a = yaml.safe_load(open(af, encoding="utf-8"))
    if not str(a.get("asyncapi", "")).startswith("3."):
        err("asyncapi không phải 3.x")
    areg = Registry().with_resource("urn:a", Resource.from_contents(fix2 := {"components": a["components"]}, default_specification=DRAFT202012)) if False else None
    evts = [c.get("title", "") for c in a["channels"].values()]
    need_e = {f"EVT-02-{i:02d}" for i in range(1, 17)}
    got = {t.split(" ")[0] for t in evts}
    if need_e - got:
        err(f"thiếu sự kiện: {sorted(need_e - got)}")
    # payload ví dụ khớp lược đồ
    def fixa(x):
        if isinstance(x, dict):
            return {k: ("urn:a" + v if k == "$ref" and isinstance(v, str) and v.startswith("#/components") else fixa(v)) for k, v in x.items()}
        if isinstance(x, list):
            return [fixa(i) for i in x]
        return x
    rega = Registry().with_resource("urn:a", Resource.from_contents(fixa({"components": a["components"]}), default_specification=DRAFT202012))
    m_ = 0
    for name, sch in a["components"]["schemas"].items():
        for e in sch.get("examples", []):
            es = list(jsonschema.Draft202012Validator(fixa(sch), registry=rega).iter_errors(e))
            if es:
                err(f"asyncapi {name}: {es[0].message[:200]}")
            m_ += 1
    print(f"asyncapi-catalog.yaml: AsyncAPI {a['asyncapi']}, {len(a['channels'])} kênh, {m_} payload ví dụ đã kiểm")
else:
    err("thiếu asyncapi-catalog.yaml")

# ---------- Tài liệu chính khớp
if os.path.exists(MAIN):
    t = open(MAIN, encoding="utf-8").read()
    for e in sorted(frs_err - set(re.findall(r"^\| (ERR-02-\d{3}) \|", t, re.M))):
        err(f"ERR chưa có ở §6 của tài liệu chính: {e}")
    for i in ids:
        if i not in t:
            err(f"{i} chưa có trong tài liệu chính")
sys.exit(1 if bad else 0)
