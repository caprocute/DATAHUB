#!/usr/bin/env python3
"""Sinh features.json của gói đặc tả máy đọc từ bộ tài liệu một phân hệ.

Mỗi FR → một tính năng (F-nn-nnn). Nguồn: FRS (tiêu đề, ưu tiên, đợt, màn hình,
API, mã lỗi), OpenAPI (operationId theo x-datahub-fr), DDL (bảng có COMMENT nhắc
FR), TC (TC-nn-nnn có "Truy vết" nhắc FR). Cờ `passes` của tính năng đã có trong
tệp đích được GIỮ NGUYÊN khi sinh lại (chỉ phiên đánh giá được lật cờ).

  python3 sinh_features.py --ph 07 --frs ... --openapi ... --ddl ... --tc ... --ra features.json
"""
import argparse, json, re, sys, os
import yaml

def doc(p):
    with open(p, encoding="utf-8") as f:
        return f.read()

def main():
    ap = argparse.ArgumentParser()
    for k in ("ph", "frs", "openapi", "ddl", "tc", "ra"):
        ap.add_argument("--" + k, required=True)
    a = ap.parse_args()
    ph = a.ph
    frs = doc(a.frs)
    blocks = re.split(r"(?m)^#### (?=FR-%s-\d{3} · )" % ph, frs)[1:]
    feats = []
    try:
        oa = yaml.safe_load(doc(a.openapi))
    except yaml.YAMLError as e:  # khóa trùng không làm safe_load lỗi; lỗi khác thì dừng
        sys.exit(f"OpenAPI không đọc được: {e}")
    ops_by_fr = {}
    for path, item in oa.get("paths", {}).items():
        for m, op in item.items():
            if not isinstance(op, dict) or "operationId" not in op:
                continue
            for fr in op.get("x-datahub-fr", []) or []:
                ops_by_fr.setdefault(fr, []).append({
                    "api": op.get("x-datahub-id"), "operationId": op["operationId"],
                    "method": m.upper(), "path": path})
    ddl = doc(a.ddl)
    bang_by_fr = {}
    for t, cm in re.findall(r"COMMENT ON TABLE (\S+) IS '((?:[^']|'')*)'", ddl):
        for fr in set(re.findall(r"(?<![A-Z])FR-%s-\d{3}" % ph, cm)):
            bang_by_fr.setdefault(fr, []).append(t)
    tc = doc(a.tc)
    tc_by_fr = {}
    for m in re.finditer(r"(?ms)^#### (TC-%s-\d{3}) · .*?(?=^#### |^## |\Z)" % ph, tc):
        tcid, body = m.group(1), m.group(0)
        tv = re.search(r"\*\*Truy vết\.\*\*([^\n]*)", body)
        if tv:
            for fr in set(re.findall(r"(?<![A-Z])FR-%s-\d{3}" % ph, tv.group(1))):
                tc_by_fr.setdefault(fr, []).append(tcid)
    cu = {}
    if os.path.exists(a.ra):
        with open(a.ra, encoding="utf-8") as f:
            for x in json.load(f).get("features", []):
                cu[x["id"]] = x
    for b in blocks:
        m = re.match(r"(FR-%s-(\d{3})) · ([^\n]+)" % ph, b)
        fr, so, ten = m.group(1), m.group(2), m.group(3).strip()
        ut = re.search(r"\*\*Mức ưu tiên, đợt\.\*\* *([MSCW])\w* *· *Đợt *(\d+)", b)
        mh = re.search(r"\*\*Màn hình, API\.\*\*([^\n]*)", b)
        ui = sorted(set(re.findall(r"UI-%s-\d{2}" % ph, mh.group(1) if mh else "")))
        loi = sorted(set(re.findall(r"ERR-%s-\d{3}" % ph, b)))
        fid = f"F-{ph}-{so}"
        ops = ops_by_fr.get(fr, [])
        f = {
            "id": fid, "fr": fr, "ten": ten,
            "uu_tien": ut.group(1) if ut else None, "dot": int(ut.group(2)) if ut else None,
            "api": ops, "bang": sorted(bang_by_fr.get(fr, [])), "ui": ui,
            "loi": loi, "tc": sorted(tc_by_fr.get(fr, [])),
            "co_tac_vu": "S" if len(ops) <= 2 else ("M" if len(ops) <= 5 else "L"),
            "passes": cu.get(fid, {}).get("passes", False),
        }
        for k in ("lat_cat", "gherkin", "ghi_chu", "danh_gia"):
            if k in cu.get(fid, {}):
                f[k] = cu[fid][k]
        feats.append(f)
    out = {"$schema": "../../tools/features.schema.json", "phan_he": f"PH-{ph}",
           "nguon": {"frs": a.frs, "openapi": a.openapi, "ddl": a.ddl, "tc": a.tc},
           "features": feats}
    with open(a.ra, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
        f.write("\n")
    thieu_api = [x["id"] for x in feats if not x["api"]]
    thieu_tc = [x["id"] for x in feats if not x["tc"]]
    print(f"{a.ra}: {len(feats)} tính năng; thiếu API: {len(thieu_api)}; thiếu TC: {len(thieu_tc)}")
    if thieu_tc:
        print("  thiếu TC:", " ".join(thieu_tc))

if __name__ == "__main__":
    main()
