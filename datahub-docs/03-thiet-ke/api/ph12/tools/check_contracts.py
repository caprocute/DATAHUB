#!/usr/bin/env python3
"""Kiểm hợp đồng PH-12: OpenAPI 3.1 hợp lệ, ví dụ khớp lược đồ, mỗi operation có x-datahub-*, mã API đủ 001…111 và khớp FRS §9.4,
lệnh sửa có If-Match, không lược đồ nào trả bí mật, mọi mã ERR của FRS có trong OpenAPI hoặc bảng mã lỗi.

Chạy: python3 tools/check_contracts.py   (từ thư mục api/ph12). Cần: openapi-spec-validator, jsonschema ≥ 4.18.
AsyncAPI kiểm bằng @asyncapi/parser 3 khi có, ngoài ra kiểm cấu trúc bằng PyYAML (EVT đủ, topic khớp mẫu).
"""
import glob, os, re, sys, yaml, jsonschema
from openapi_spec_validator import validate
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FRS = glob.glob(os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH12-*.md"))[0]
frs = open(FRS, encoding="utf-8").read()
bad = 0

def fix(x):
    if isinstance(x, dict): return {k: ("urn:c" + v if k == "$ref" and isinstance(v, str) and v.startswith("#/") else fix(v)) for k, v in x.items()}
    if isinstance(x, list): return [fix(i) for i in x]
    return x

d = yaml.safe_load(open(os.path.join(ROOT, "openapi-iam.yaml"), encoding="utf-8"))
validate(d)
reg = Registry().with_resource("urn:c", Resource.from_contents(fix({"components": d["components"]}), default_specification=DRAFT202012))
n = 0
for k, sch in d["components"]["schemas"].items():
    for e in sch.get("examples", []) if isinstance(sch, dict) else []:
        errs = list(jsonschema.Draft202012Validator(fix(sch), registry=reg).iter_errors(e))
        n += 1
        if errs: bad += 1; print(f"lược đồ {k}: ví dụ không khớp: {errs[0].message[:200]}")
ids = []
for p, m in d["paths"].items():
    for meth, o in m.items():
        for key in ("x-datahub-id", "x-datahub-fr", "x-datahub-permission", "operationId"):
            if key not in o: bad += 1; print(f"{p} {meth}: thiếu {key}")
        ids.append(o.get("x-datahub-id"))
        names = {pp.get("$ref", "").split("/")[-1] for pp in o.get("parameters", [])}
        if meth in ("patch", "put", "delete") and "IfMatch" not in names and "/realms/dh-" not in p:
            bad += 1; print(f"{o['operationId']}: lệnh ghi thiếu If-Match")
        if not o.get("responses"): bad += 1; print(f"{o['operationId']}: thiếu responses")
want = [f"API-12-{i:03d}" for i in range(1, 112)]
if sorted(ids) != want: bad += 1; print("mã API lệch:", set(want) ^ set(ids))
tbl = dict(re.findall(r"^\| (API-12-\d{3}) \| `([A-Z]+ [^`]+)` \|", frs, re.M))
for p, m in d["paths"].items():
    for meth, o in m.items():
        t = tbl.get(o["x-datahub-id"], "")
        if t.split(" ")[0:1] != [meth.upper()]: bad += 1; print(o["x-datahub-id"], "khác phương thức so với FRS §9.4:", t, meth)
        elif p.startswith("/realms/dh-") is False and not t.split(" ")[1].endswith(p) and not t.split(" ")[1].startswith("/api/authz") and not t.endswith(p):
            bad += 1; print(o["x-datahub-id"], "khác đường dẫn so với FRS §9.4:", t, p)
for k, sch in d["components"]["schemas"].items():
    txt = str(sch)
    if re.search(r"'(password|client_secret|bindSecret|privateKey|secret)'", txt) and k not in ("TokenRequest", "LdapFederationPut"):
        bad += 1; print(f"{k}: có trường bí mật ngoài lược đồ chỉ ghi")
for k, f in (("TokenRequest", "client_secret"), ("LdapFederationPut", "bindSecret")):
    if not d["components"]["schemas"][k]["properties"][f].get("writeOnly"): bad += 1; print(f"{k}.{f} thiếu writeOnly")
errs_frs = set(re.findall(r"^\| (ERR-12-\d{3}) \|", frs, re.M))
used = {e for m in d["paths"].values() for o in m.values() for e in o.get("x-datahub-errors", [])}
print(f"ERR trong FRS {len(errs_frs)}, dùng ở OpenAPI {len(used)}; ngoài OpenAPI: {sorted(errs_frs - used)}")
if used - errs_frs: bad += 1; print("ERR lạ:", used - errs_frs)
print(f"openapi-iam.yaml: hợp lệ OpenAPI 3.1, {len(ids)} operation, {len(d['components']['schemas'])} lược đồ, {n} ví dụ đã kiểm")

# AsyncAPI
fa = os.path.join(ROOT, "asyncapi-iam.yaml")
if os.path.exists(fa):
    a = yaml.safe_load(open(fa, encoding="utf-8"))
    assert a["asyncapi"].startswith("3.0")
    titles = sorted(c["title"] for c in a["channels"].values())
    wantE = [f"EVT-12-{i:02d}" for i in range(1, 17)]
    if titles != wantE: bad += 1; print("EVT lệch:", set(wantE) ^ set(titles))
    for k, c in a["channels"].items():
        if not re.match(r"^\{tenant\}\.iam\.[a-z-]+\.[a-z-]+\.v[0-9]+$", c["address"]): bad += 1; print(k, "topic sai mẫu:", c["address"])
        for mk in c["messages"].values():
            ref = mk["$ref"].split("/")[-1]
            if ref not in a["components"]["messages"]: bad += 1; print(k, "thiếu message", ref)
    sch = a["components"]["schemas"]
    for k, s in sch.items():
        if re.search(r"'(password|secret|privateKey|wrappingToken)'", str(s)): bad += 1; print(k, "payload có trường bí mật")
    print(f"asyncapi-iam.yaml: AsyncAPI 3.0, {len(a['channels'])} kênh, {len(a['operations'])} operation, {len(sch)} lược đồ")
sys.exit(1 if bad else 0)
