#!/usr/bin/env python3
"""Sinh các bảng tổng hợp của FRS PH-19 (mục 6, 7.2, 8, 9) từ khung truy vết.

Chạy: python3 gen_frs_tables.py <phần>   với phần ∈ br, nfr, map, lgc, trace, mvp
In Markdown ra stdout; người viết dán vào FRS giữa các đoạn văn viết tay.
Bổ sung đề xuất của FRS (FR-19-069, API-19-091/092, EN-19-26) khai báo ở EXTRA.
"""
import re, sys
from collections import defaultdict
from khung import load

k = load()

def expand(text, prefix):
    """'FR-19-001, 002, 038…041' -> ['FR-19-001', 'FR-19-002', 'FR-19-038', ...]."""
    out = []
    for m in re.finditer(prefix + r"-(\d+)((?:\s*(?:,|…)\s*\d+)*)", text):
        nums = [m.group(1)] + re.findall(r"(,|…)\s*(\d+)", m.group(2))
        first, w = int(m.group(1)), len(m.group(1))
        out.append(first); last = first
        for sep, n in nums[1:]:
            n = int(n)
            if sep == "…":
                out += list(range(last + 1, n + 1))
            else:
                out.append(n)
            last = n
    return [f"{prefix}-{n:0{w}d}" for n in out]

FR = {r["Mã"]: r for r in k.fr()}
FR["FR-19-069"] = {"Mã": "FR-19-069", "Tên": "Quản lý bảng ánh xạ mã kết quả nhà cung cấp (đề xuất)",
                   "ƯT": "M", "UC": "UC-19-05", "LGC": "—", "REQ": "REQ-91, REQ-94"}

# Phát hành do FRS quyết định (mục 9.3); mặc định MVP.
RELEASE = {
    "FR-19-012": ("Đ2b", "MVP thay khóa bằng FR-19-002"),
    "FR-19-026": ("Đ2b", "MVP: giao dịch tự hết hạn"),
    "FR-19-032": ("MVP một phần", "Xử lý lại IPN ở Đ2b"),
    "FR-19-037": ("Đ2b", "MVP dựa vào truy vấn tự động và đối soát"),
    "FR-19-040": ("MVP một phần", "Chế độ `API` ở Đ2b"),
    "FR-19-048": ("MVP một phần", "API-19-107 ở Đ2b"),
    "FR-19-052": ("Đ2b", "MVP chỉ xuất báo cáo, biên bản"),
    "FR-19-058": ("Đ2b", "Lập lịch gửi: sau"),
    "FR-19-067": ("Sau", "Chỉ khi OQ-19-17 xác nhận"),
}

def fr3(code):
    return code.replace("FR-19-", "")

def api_rows():
    for sec in ("10.2", "10.3"):
        for r in k.rows(sec):
            yield r
    yield {"Mã": "API-19-091", "FR": "FR-19-069"}
    yield {"Mã": "API-19-092", "FR": "FR-19-069"}

def by_fr(rows, col="FR"):
    d = defaultdict(list)
    for r in rows:
        for f in expand(r[col], "FR-19"):
            d[f].append(r["Mã"])
    return d

def short(codes, prefix):
    if not codes:
        return "—"
    nums = sorted({int(c.split("-")[-1]) for c in codes})
    w = len(codes[0].split("-")[-1])
    parts, i = [], 0
    while i < len(nums):
        j = i
        while j + 1 < len(nums) and nums[j + 1] == nums[j] + 1:
            j += 1
        a, b = nums[i], nums[j]
        if j - i >= 2:
            parts.append(f"{a:0{w}d}…{b:0{w}d}")
        else:
            parts += [f"{n:0{w}d}" for n in nums[i:j + 1]]
        i = j + 1
    return f"{prefix}-" + ", ".join(parts)

def table(header, rows):
    print("| " + " | ".join(header) + " |")
    print("|" + "---|" * len(header))
    for r in rows:
        print("| " + " | ".join(r) + " |")

def part_br():
    for sec in ["6.1", "6.2", "6.3", "6.4", "6.5", "6.6"]:
        title = k.lines[k.sections[sec][0]].split(". ", 1)[1]
        print(f"#### 6.{sec.split('.')[1]}. {title}\n")
        table(["Mã", "Quy tắc", "Tham số mặc định", "FR"],
              [[r["Mã"], r["Quy tắc"], r["Tham số mặc định"], r["FR"]] for r in k.rows(sec)])
        print()

def part_nfr():
    for sec in ["5.1", "5.2", "5.3", "5.4", "5.5"]:
        title = k.lines[k.sections[sec][0]].split(". ", 1)[1]
        print(f"#### 7.2.{sec.split('.')[1]}. {title}\n")
        table(["Mã", "Yêu cầu (đo được)", "Cách kiểm chứng", "Truy vết"],
              [[r["Mã"], r["Yêu cầu (đo được)"], r["Cách kiểm chứng"], r["Truy vết"]] for r in k.rows(sec)])
        print()

def part_map():
    apis = by_fr(api_rows())
    evts = by_fr(k.rows("10.4"))
    rows = []
    for code in sorted(FR):
        rows.append([code, FR[code]["Tên"], short(apis.get(code, []), "API-19"),
                     short(evts.get(code, []), "EVT-19")])
    table(["FR", "Tên", "API", "Sự kiện"], rows)

def part_lgc():
    rows = []
    for r in k.rows("2"):
        rows.append([r["Mã"], r["Chức năng hệ cũ (rút gọn)"], r["Kết luận"], r["FR phủ"], r["UI mới"]])
    for r in k.tables("2")[1]["rows"]:
        rows.append([r["Mã (đề xuất)"] + " (đề xuất)", r["Chức năng hệ cũ"], r["Kết luận đề xuất"], r["FR phủ"], "—"])
    table(["LGC", "Chức năng hệ cũ", "Kết luận", "FR phủ", "Màn mới"], rows)

def part_trace():
    uis = by_fr(k.tables("11")[1]["rows"])
    uis["FR-19-069"].append("UI-19-04")
    tss = defaultdict(list)
    for r in k.rows("14"):
        for f in expand(r["FR / NFR chính"], "FR-19"):
            tss[f].append(r["Mã"])
    tss["FR-19-069"].append("TS-19-05")
    rows = []
    for code in sorted(FR):
        r = FR[code]
        rows.append([code, r["ƯT"], r.get("LGC", "—") or "—", r["UC"],
                     short(uis.get(code, []), "UI-19"), short(tss.get(code, []), "TS-19")])
    table(["FR", "ƯT", "LGC-PAY", "UC", "Màn hình", "Kịch bản kiểm thử"], rows)
    miss = [c for c in FR if not tss.get(c)]
    if miss:
        print(f"\nFR chưa có kịch bản kiểm thử trong khung: {', '.join(miss)}.", file=sys.stderr)

def part_mvp():
    rows, cnt = [], defaultdict(int)
    for code in sorted(FR):
        rel, note = RELEASE.get(code, ("MVP", ""))
        cnt[rel] += 1
        rows.append([code, FR[code]["Tên"], FR[code]["ƯT"], rel, note or "—"])
    table(["FR", "Tên", "ƯT", "Phát hành", "Ghi chú"], rows)
    print("\nTổng: " + ", ".join(f"{k_} {v}" for k_, v in sorted(cnt.items())) + ".")

def part_ui():
    legacy = defaultdict(list)
    for r in k.rows("2"):
        for u in expand(r["UI mới"], "UI-19"):
            legacy[u].append(r["Mã"])
    rows = []
    for r in k.tables("11")[1]["rows"]:
        fr = r["FR"] + (", 069" if r["Mã"] == "UI-19-04" else "")
        rows.append([r["Mã"], r["Màn hình"], fr, short(legacy.get(r["Mã"], []), "LGC-PAY"),
                     "Giữ, nâng cấp" if legacy.get(r["Mã"]) else "Mới"])
    table(["Mã", "Màn hình", "FR", "Màn, chức năng hệ cũ được giữ", "Loại"], rows)

if __name__ == "__main__":
    {"br": part_br, "nfr": part_nfr, "map": part_map, "lgc": part_lgc,
     "trace": part_trace, "mvp": part_mvp, "ui": part_ui}[sys.argv[1]]()
