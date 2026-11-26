#!/usr/bin/env python3
"""Cắt một lát OpenAPI tự chứa theo danh sách operationId (kèm mọi $ref bắc cầu).

Dùng cho gói đặc tả máy đọc (K-GOI-DAC-TA): tác nhân viết mã chỉ đọc lát cắt
của tính năng đang làm, không đọc nguyên tệp 8.000 dòng.

  python3 cat_lat_openapi.py NGUON.yaml RA.yaml opId1 opId2 ...
  python3 cat_lat_openapi.py NGUON.yaml RA.yaml --sua-trung-khoa opId...

--va VA.yaml: áp danh sách vá (set/remove/add theo con trỏ JSON) trước khi cắt.
--day-du: bỏ qua opId, ghi toàn bộ hợp đồng đã vá (để lint toàn phân hệ).
--sua-trung-khoa: nếu YAML nguồn có khóa trùng (lỗi cú pháp), giữ khóa XUẤT HIỆN
SAU (theo cách PyYAML) và in cảnh báo để ghi vào báo cáo sẵn sàng.
"""
import sys, copy, yaml

def tai(path, sua):
    class L(yaml.SafeLoader):
        pass
    trung = []
    def cm(loader, node, deep=False):
        keys = {}
        for k, _ in node.value:
            kk = loader.construct_object(k, deep=deep)
            if kk in keys:
                trung.append(f"dòng {k.start_mark.line+1}: khóa trùng `{kk}`")
            keys[kk] = 1
        return yaml.SafeLoader.construct_mapping(loader, node, deep)
    L.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, cm)
    with open(path, encoding="utf-8") as f:
        d = yaml.load(f, Loader=L)
    if trung and not sua:
        sys.exit("Khóa trùng (dùng --sua-trung-khoa để bỏ qua):\n" + "\n".join(trung))
    for t in trung:
        print("CẢNH BÁO", t, file=sys.stderr)
    return d

def refs(o, out):
    if isinstance(o, dict):
        for k, v in o.items():
            if k == "$ref" and isinstance(v, str) and v.startswith("#/"):
                out.add(v)
            else:
                refs(v, out)
    elif isinstance(o, list):
        for v in o:
            refs(v, out)

def lay(d, ptr):
    cur = d
    for p in ptr[2:].split("/"):
        cur = cur[p.replace("~1", "/").replace("~0", "~")]
    return cur

def ap_va(d, va_path):
    with open(va_path, encoding="utf-8") as f:
        va = yaml.safe_load(f) or []
    for v in va:
        parts = [p.replace("~1", "/").replace("~0", "~") for p in v["ptr"][1:].split("/")]
        cur = d
        for p in parts[:-1]:
            cur = cur[int(p)] if isinstance(cur, list) else cur.setdefault(p, {})
        k = parts[-1]
        if isinstance(cur, list):
            k = int(k)
        if v["op"] == "set":
            cur[k] = v["value"]
        elif v["op"] == "remove":
            if k not in cur:
                sys.exit(f"Vá {v['ss']}: không có khóa để xóa {v['ptr']} (nguồn đã sửa? xóa mục vá)")
            del cur[k]
        elif v["op"] == "add":
            cur.setdefault(k, []).append(v["value"])
        else:
            sys.exit(f"op lạ: {v['op']}")
    print(f"Đã áp {len(va)} vá từ {va_path}", file=sys.stderr)

def main():
    a = sys.argv[1:]
    sua = "--sua-trung-khoa" in a
    day_du = "--day-du" in a
    va = None
    if "--va" in a:
        i = a.index("--va"); va = a[i + 1]; del a[i:i + 2]
    a = [x for x in a if x not in ("--sua-trung-khoa", "--day-du")]
    src, dst, ops = a[0], a[1], set(a[2:])
    d = tai(src, sua)
    if va:
        ap_va(d, va)
    if day_du:
        with open(dst, "w", encoding="utf-8") as f:
            f.write("# TỆP SINH bởi datahub/tools/cat_lat_openapi.py --day-du — không sửa tay.\n")
            yaml.safe_dump(d, f, allow_unicode=True, sort_keys=False, width=110)
        print(f"{dst}: toàn bộ hợp đồng đã vá")
        return
    # Lát cắt gọn: bỏ ví dụ của response dùng chung (chỉ giữ ví dụ gắn trực tiếp vào operation)
    for r in d.get("components", {}).get("responses", {}).values():
        for c in (r.get("content") or {}).values():
            c.pop("examples", None)
    paths = {}
    found = set()
    for p, item in d["paths"].items():
        keep = {}
        for m, op in item.items():
            if m == "parameters":
                continue
            if isinstance(op, dict) and op.get("operationId") in ops:
                keep[m] = op
                found.add(op["operationId"])
        if keep:
            if "parameters" in item:
                keep = {"parameters": item["parameters"], **keep}
            paths[p] = keep
    miss = ops - found
    if miss:
        sys.exit(f"Không thấy operationId: {sorted(miss)}")
    out = {k: copy.deepcopy(v) for k, v in d.items() if k not in ("paths", "components", "tags", "x-datahub-notes")}
    out["paths"] = paths
    need, seen = set(), set()
    refs(paths, need)
    refs(d.get("security", []), need)
    while need - seen:
        r = sorted(need - seen)[0]
        seen.add(r)
        refs(lay(d, r), need)
    comps = {}
    for r in sorted(seen):
        parts = r[2:].split("/")
        if parts[0] != "components":
            continue
        comps.setdefault(parts[1], {})[parts[2]] = lay(d, "#/components/" + parts[1] + "/" + parts[2])
    # securitySchemes luôn kèm theo
    comps["securitySchemes"] = d["components"].get("securitySchemes", {})
    out["components"] = comps
    out["info"] = dict(out["info"], title=out["info"]["title"] + " · lát cắt " + ",".join(sorted(ops)))
    with open(dst, "w", encoding="utf-8") as f:
        f.write("# TỆP SINH bởi datahub/tools/cat_lat_openapi.py — không sửa tay; sửa nguồn rồi cắt lại.\n")
        yaml.safe_dump(out, f, allow_unicode=True, sort_keys=False, width=110)
    print(f"{dst}: {len(paths)} path, {sum(len(v) for v in comps.values())} component")

if __name__ == "__main__":
    main()
