#!/usr/bin/env python3
"""Cổng G1 · Đặc tả (K-GOI-DAC-TA §5). Kiểm một gói đặc tả máy đọc chạy được thật.

  python3 datahub/tools/g1_dac_ta.py datahub/spec/PH07/goi.yaml [--bo-ddl]

Kiểm: (1) bản kê và tệp nguồn tồn tại; (2) OpenAPI toàn phân hệ đã vá qua Redocly
không lỗi; (3) mỗi lát cắt khớp bản sinh lại (không cũ) và qua lint; (4) features.json
đúng lược đồ, đủ FR của FRS; (5) Gherkin phân tích được; (6) DDL + seed + kiểm RLS chạy
trên PostgreSQL thật (biến môi trường PGHOST/PGPORT/PGUSER/PGPASSWORD); (7) giới hạn
độ dài tóm tắt ≤300 dòng, AGENTS.md ≤150 dòng.
Cần: python3 + pyyaml, jsonschema, gherkin-official; node (npx @redocly/cli); psql.
"""
import json, os, subprocess, sys, tempfile, filecmp
import yaml

GOC = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
TOOLS = os.path.join(GOC, "datahub", "tools")
REDOCLY = ["npx", "--yes", "@redocly/cli@2.11.1", "lint", "--config", os.path.join(GOC, "datahub/spec/redocly.yaml"), "--format=summary"]
loi = []

def buoc(ten, ok, chi_tiet=""):
    print(("  ✓ " if ok else "  ✗ ") + ten + (f" — {chi_tiet}" if chi_tiet and not ok else ""))
    if not ok:
        loi.append(ten)

def chay(cmd, **kw):
    return subprocess.run(cmd, cwd=GOC, capture_output=True, text=True, **kw)

def main():
    goi_path = sys.argv[1]
    bo_ddl = "--bo-ddl" in sys.argv
    g = yaml.safe_load(open(goi_path, encoding="utf-8"))
    thu_muc = os.path.dirname(os.path.abspath(goi_path))
    ph = g["phan_he"].split("-")[1]
    print(f"G1 · gói đặc tả {g['phan_he']}")
    # (1)
    thieu = [p for k, p in g["nguon"].items() if k != "seed" and not os.path.exists(os.path.join(GOC, p))]
    thieu += [p for p in g["nguon"].get("seed", []) if not os.path.exists(os.path.join(GOC, p))]
    buoc("bản kê và tệp nguồn tồn tại", not thieu, ", ".join(thieu))
    # (2)
    tmp = tempfile.mkdtemp()
    va = ["--va", g["openapi"]["va"]] if g["openapi"].get("va") else []
    stk = ["--sua-trung-khoa"] if g["openapi"].get("sua_trung_khoa") else []
    full = os.path.join(tmp, "full.yaml")
    r = chay(["python3", os.path.join(TOOLS, "cat_lat_openapi.py"), g["nguon"]["openapi"], full, *stk, *va, "--day-du"])
    if r.returncode:
        buoc("áp vá OpenAPI", False, r.stdout + r.stderr)
    else:
        r = chay(REDOCLY + [full])
        buoc("OpenAPI toàn phân hệ (đã vá) qua Redocly", r.returncode == 0, (r.stdout + r.stderr).strip().splitlines()[-1] if r.returncode else "")
    # (3)
    for fid, lc in (g.get("lat_cat") or {}).items():
        moi = os.path.join(tmp, fid + ".yaml")
        r = chay(["python3", os.path.join(TOOLS, "cat_lat_openapi.py"), g["nguon"]["openapi"], moi, *stk, *va, *lc["operations"]])
        cu = os.path.join(GOC, lc["openapi"])
        buoc(f"lát cắt {fid} khớp bản sinh lại", r.returncode == 0 and os.path.exists(cu) and filecmp.cmp(moi, cu, shallow=False),
             "chạy lại cat_lat_openapi.py rồi commit" if r.returncode == 0 else r.stderr)
        r = chay(REDOCLY + [cu])
        buoc(f"lát cắt {fid} qua Redocly", r.returncode == 0)
    # (4)
    import jsonschema
    fj = os.path.join(thu_muc, "features.json")
    d = json.load(open(fj, encoding="utf-8"))
    try:
        jsonschema.validate(d, json.load(open(os.path.join(TOOLS, "features.schema.json"))))
        buoc("features.json đúng lược đồ", True)
    except jsonschema.ValidationError as e:
        buoc("features.json đúng lược đồ", False, e.message)
    sinh = os.path.join(tmp, "features.json")
    r = chay(["python3", os.path.join(TOOLS, "sinh_features.py"), "--ph", ph, "--frs", g["nguon"]["frs"], "--openapi", g["nguon"]["openapi"],
              "--ddl", g["nguon"]["ddl"], "--tc", g["nguon"]["tc"], "--ra", sinh])
    ids_moi = {x["id"] for x in json.load(open(sinh))["features"]} if r.returncode == 0 else set()
    ids_cu = {x["id"] for x in d["features"]}
    buoc("features.json đủ FR của FRS", ids_moi == ids_cu, f"thiếu {sorted(ids_moi - ids_cu)}, thừa {sorted(ids_cu - ids_moi)}")
    for x in d["features"]:
        for k in ("lat_cat", "gherkin"):
            if k in x and not os.path.exists(os.path.join(GOC, x[k])):
                buoc(f"{x['id']}.{k} tồn tại", False, x[k])
    # (5)
    from gherkin.parser import Parser
    from gherkin.token_scanner import TokenScanner
    for lc in (g.get("lat_cat") or {}).values():
        try:
            doc = Parser().parse(TokenScanner(open(os.path.join(GOC, lc["gherkin"]), encoding="utf-8").read()))
            buoc(f"Gherkin {os.path.basename(lc['gherkin'])} ({len(doc['feature']['children'])} khối)", True)
        except Exception as e:  # noqa: BLE001
            buoc(f"Gherkin {lc['gherkin']}", False, str(e)[:200])
    # (6)
    if bo_ddl:
        print("  - bỏ qua DDL (--bo-ddl)")
    else:
        db = f"g1_ph{ph}"
        chay(["psql", "-d", "postgres", "-qc", f"DROP DATABASE IF EXISTS {db}"])
        r = chay(["psql", "-d", "postgres", "-qc", f"CREATE DATABASE {db}"])
        ok = r.returncode == 0
        tep = [g["nguon"]["ddl"], *g["nguon"].get("seed", []), *g.get("ddl_kiem", [])]
        for t in tep if ok else []:
            r = chay(["psql", "-d", db, "-v", "ON_ERROR_STOP=1", "-q", "-f", t])
            if r.returncode:
                buoc(f"DDL chạy: {t}", False, r.stderr.strip()[-300:])
                ok = False
                break
        v = chay(["psql", "-d", db, "-Atc", "show server_version"]).stdout.strip()
        buoc(f"DDL + seed + kiểm RLS chạy trên PostgreSQL {v}", ok, "" if ok else r.stderr.strip()[-200:])
    # (7)
    for ten, gh in (("tom-tat.md", 300), ("AGENTS.md", 150)):
        p = os.path.join(thu_muc, ten)
        n = sum(1 for _ in open(p, encoding="utf-8")) if os.path.exists(p) else -1
        buoc(f"{ten} có và ≤ {gh} dòng", 0 < n <= gh, f"{n} dòng")
    p = os.path.join(GOC, "datahub", "AGENTS.md")
    n = sum(1 for _ in open(p, encoding="utf-8")) if os.path.exists(p) else -1
    buoc("datahub/AGENTS.md có và ≤ 150 dòng", 0 < n <= 150, f"{n} dòng")
    print("G1 " + ("XANH" if not loi else f"ĐỎ ({len(loi)} lỗi)"))
    sys.exit(1 if loi else 0)

if __name__ == "__main__":
    main()
