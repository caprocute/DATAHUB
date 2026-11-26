#!/usr/bin/env python3
"""Sinh ba bảng của D03-03-PH06 từ DDL: danh mục bảng (mục 1.6), ánh xạ EN → bảng, ánh xạ FR → bảng (mục 8).

Chạy từ thư mục csdl/ph06:  python3 tools/gen_anh_xa.py [--write]
Đọc COMMENT ON TABLE (mã EN-06-nn, FR-06-nnn, kể cả danh sách "FR-06-018, 019" và dải "FR-06-036…042") và PARTITION BY.
Với --write thay đoạn giữa các cặp <!-- gen:danh-muc:start/end -->, <!-- gen:en:start/end -->, <!-- gen:fr:start/end -->
trong ../D03-03-PH06-csdl-du-lieu-chu.md. FR không có bảng nào nhắc trong COMMENT dùng bảng ghi tay ở FR_TAY.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(ROOT), "D03-03-PH06-csdl-du-lieu-chu.md")
FRS = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH06-frs-du-lieu-chu.md")
sql = open(os.path.join(ROOT, "ddl", "ph06_mdm.sql"), encoding="utf-8").read()
frs = open(FRS, encoding="utf-8").read()

order = re.findall(r"CREATE TABLE ph06_mdm\.(\w+) \(", sql)
cm = dict(re.findall(r"COMMENT ON TABLE ph06_mdm\.(\w+) IS '((?:[^']|'')*)';", sql))
part = dict(re.findall(r"CREATE TABLE ph06_mdm\.(\w+) \(.*?\n\) PARTITION BY RANGE \((\w+)\);", sql, re.S))
en_name = dict(re.findall(r"^\| (EN-06-\d{2}) \| `(\w+)` \|", frs, re.M))
FR_TAY = {  # chức năng không có bảng riêng: ghi bảng phục vụ
    24: ["match_job", "match_result", "match_rule_set"],
    47: ["golden_identifier", "golden_record", "match_result", "steward_item", "access_log"],
    48: ["golden_record", "access_log"],
    50: ["outbox_event"],
    52: ["model_attribute", "golden_attribute", "access_log"],
    55: ["steward_item", "match_job", "match_result", "national_discrepancy", "access_log", "candidate_record"],
}


def expand(text):
    out = []
    for m in re.finditer(r"FR-06-(\d{3})((?:(?:, |…)\d{3})*)", text):
        nums, prev = [int(m.group(1))], int(m.group(1))
        for sep, n in re.findall(r"(, |…)(\d{3})", m.group(2)):
            n = int(n)
            nums += list(range(prev + 1, n + 1)) if sep == "…" else [n]
            prev = n
        out += nums
    return out


fr_tables, en_tables = {}, {}
for t in order:
    for n in expand(cm[t]):
        fr_tables.setdefault(n, []).append(t)
    for e in dict.fromkeys(re.findall(r"EN-06-\d{2}", cm[t])):
        en_tables.setdefault(e, []).append(t)
for n, ts in FR_TAY.items():
    fr_tables.setdefault(n, ts)


def code(ts):
    return ", ".join("`%s`" % t for t in ts)


def danh_muc():
    L = ["| Mục | Bảng | Thực thể | Phân vùng | FR chính |", "|---|---|---|---|---|"]
    for i, t in enumerate(order, 1):
        ens = ", ".join(dict.fromkeys(re.findall(r"EN-06-\d{2}", cm[t]))) or "Bổ sung"
        frs_ = sorted(n for n, ts in fr_tables.items() if t in ts)
        fr_txt = ", ".join("%03d" % n for n in frs_[:5]) + ("…" if len(frs_) > 5 else "") if frs_ else "Hạ tầng"
        L.append(f"| 3.{i} | `{t}` | {ens} | {'Tháng, ' + part[t] if t in part else 'Không'} | {fr_txt} |")
    L += ["", ": Danh mục bảng của schema ph06_mdm", ""]
    return "\n".join(L)


def en():
    L = ["| Thực thể | Tên ở FRS 4.2 | Bảng hiện thực |", "|---|---|---|"]
    for e in sorted(en_name):
        L.append(f"| {e} | `{en_name[e]}` | {code(en_tables.get(e, []))} |")
    extra = [t for t in order if not re.search(r"EN-06-\d{2}", cm[t])]
    L += ["", ": Ánh xạ thực thể EN-06 sang bảng", "",
          "Bảng không có mã EN ở FRS 4.2 (bổ sung để hiện thực chức năng): " + code(extra) + "."]
    return "\n".join(L)


def fr():
    nhom = {}
    for n in range(1, 61):
        nhom.setdefault(re.search(r"^\| FR-06-%03d \| ([A-H]) \|" % n, frs, re.M).group(1), []).append(n)
    L = ["| Nhóm | FR | Bảng hiện thực |", "|---|---|---|"]
    for g, ns in nhom.items():
        for n in ns:
            L.append(f"| {g} | FR-06-{n:03d} | {code(fr_tables[n])} |")
    L += ["", ": Ánh xạ FR-06 sang bảng", ""]
    return "\n".join(L)


BLOCKS = {"danh-muc": danh_muc, "en": en, "fr": fr}
if __name__ == "__main__":
    miss = [n for n in range(1, 61) if n not in fr_tables]
    if miss:
        print("FR chưa có bảng:", miss)
        sys.exit(1)
    if "--write" in sys.argv:
        doc = open(DOC, encoding="utf-8").read()
        for k, f in BLOCKS.items():
            doc, n = re.subn(r"(<!-- gen:%s:start -->\n).*?(<!-- gen:%s:end -->)" % (k, k), lambda m: m.group(1) + f() + "\n" + m.group(2), doc, flags=re.S)
            print(k, "đã chèn" if n else "THIẾU cặp đánh dấu")
        open(DOC, "w", encoding="utf-8").write(doc)
    else:
        for k, f in BLOCKS.items():
            print(f"--- {k}\n{f()}")
