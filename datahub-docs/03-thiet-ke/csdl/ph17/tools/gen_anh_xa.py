#!/usr/bin/env python3
"""Sinh ba bảng của D03-03-PH17 từ DDL: danh mục bảng (mục 1.6), ánh xạ EN → bảng, ánh xạ FR → bảng (mục 8).

Chạy từ thư mục csdl/ph17:  python3 tools/gen_anh_xa.py [--write]
Đọc COMMENT ON TABLE (mã EN-17-nn, FR-17-nnn, kể cả danh sách "FR-17-018, 019" và dải "FR-17-036…042") và PARTITION BY.
Với --write thay đoạn giữa các cặp <!-- gen:danh-muc:start/end -->, <!-- gen:en:start/end -->, <!-- gen:fr:start/end -->
trong ../D03-03-PH17-csdl-tro-ly-ai.md. FR không có bảng nào nhắc trong COMMENT dùng bảng ghi tay ở FR_TAY.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOC = os.path.join(os.path.dirname(ROOT), "D03-03-PH17-csdl-tro-ly-ai.md")
FRS = os.path.join(ROOT, "..", "..", "..", "02-yeu-cau", "frs", "D02-03-PH17-frs-tro-ly-ai.md")
sql = open(os.path.join(ROOT, "ddl", "ph17_assist.sql"), encoding="utf-8").read()
frs = open(FRS, encoding="utf-8").read()

order = re.findall(r"CREATE TABLE ph17_assist\.(\w+) \(", sql)
cm = dict(re.findall(r"COMMENT ON TABLE ph17_assist\.(\w+) IS '((?:[^']|'')*)';", sql))
part = dict(re.findall(r"CREATE TABLE ph17_assist\.(\w+) \(.*?\n\) PARTITION BY RANGE \((\w+)\);", sql, re.S))
en_name = dict(re.findall(r"^\| (EN-17-\d{2}) \| `(\w+)` \|", frs, re.M))
FR_TAY = {29: ["conversation", "message", "suggested_question"], 41: ["message", "tool_call", "guardrail_rule"], 48: ["message", "citation", "suggestion", "explanation"], 60: ["invocation_log", "model_version", "quota_usage"]}


def expand(text):
    out = []
    for m in re.finditer(r"(?<![A-Z])FR-17-(\d{3})((?:(?:, |…)\d{3})*)", text):
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
    for e in dict.fromkeys(re.findall(r"EN-17-\d{2}", cm[t])):
        en_tables.setdefault(e, []).append(t)
FR_THEM = {}
for n, ts in FR_TAY.items():
    fr_tables.setdefault(n, ts)
for n, ts in FR_THEM.items():
    cur = fr_tables.setdefault(n, [])
    cur += [t for t in ts if t not in cur]


def code(ts):
    return ", ".join("`%s`" % t for t in ts)


def danh_muc():
    L = ["| Mục | Bảng | Thực thể | Phân vùng | FR chính |", "|---|---|---|---|---|"]
    for i, t in enumerate(order, 1):
        ens = ", ".join(dict.fromkeys(re.findall(r"EN-17-\d{2}", cm[t]))) or "Bổ sung"
        frs_ = sorted(n for n, ts in fr_tables.items() if t in ts)
        fr_txt = ", ".join("%03d" % n for n in frs_[:5]) + ("…" if len(frs_) > 5 else "") if frs_ else "Hạ tầng"
        L.append(f"| 3.{i} | `{t}` | {ens} | {'Tháng, ' + part[t] if t in part else 'Không'} | {fr_txt} |")
    L += ["", ": Danh mục bảng của schema ph17_assist", ""]
    return "\n".join(L)


def en():
    L = ["| Thực thể | Tên ở FRS 4.2 | Bảng hiện thực |", "|---|---|---|"]
    for e in sorted(en_name):
        L.append(f"| {e} | `{en_name[e]}` | {code(en_tables.get(e, []))} |")
    extra = [t for t in order if not re.search(r"EN-17-\d{2}", cm[t])]
    L += ["", ": Ánh xạ thực thể EN-17 sang bảng"]
    if extra:
        L += ["", "Bảng không có mã EN ở FRS 4.2 (bổ sung để hiện thực chức năng): " + code(extra) + "."]
    return "\n".join(L)


def fr():
    L = ["| FR-17 | Bảng hiện thực | FR-17 | Bảng hiện thực |", "|---|---|---|---|"]
    for n in range(1, 32):
        r = n + 31
        L.append(f"| {n:03d} | {code(fr_tables[n])} | {r:03d} | {code(fr_tables[r]) if r <= 62 else ''} |")
    L += ["", ": Ánh xạ FR-17-001…062 sang bảng (hai cột song song: 001 đến 031 và 032 đến 062)", ""]
    return "\n".join(L)


BLOCKS = {"en": en, "fr": fr}
if __name__ == "__main__":
    miss = [n for n in range(1, 63) if n not in fr_tables]
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
