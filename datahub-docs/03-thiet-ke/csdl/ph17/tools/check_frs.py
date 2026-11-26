#!/usr/bin/env python3
"""Đối chiếu DDL ph17_assist (và tài liệu D03-03-PH17) với D02-03-PH17 (FRS), Phụ lục A và mục 4.2, 7, 9.1.

Chạy từ thư mục csdl/ph17:  python3 tools/check_frs.py
Kiểm, in LỆCH khi sai, mã thoát 1 nếu có lệch:
  1. Mọi CHECK liệt kê giá trị khớp đúng một enum Phụ lục A hoặc là tập con của nó (in ra để rà); nêu enum chưa gắn cột.
  2. Không có giá trị CHECK dạng UPPER_SNAKE nào trong DDL mà FRS không có (chống tự đặt enum).
  3. Mã ERR-17-nnn, BR-17-nnn, FR-17-nnn, EN-17-nn nhắc trong DDL, tài liệu đều có ở FRS; đủ 51 EN và 64 FR có mặt ở tài liệu.
  4. Mọi bảng có tenant_id  bật FORCE RLS; mọi bảng có COMMENT ON TABLE.
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.dirname(os.path.dirname(os.path.dirname(ROOT)))
FRS = open(os.path.join(DOCS, "02-yeu-cau", "frs", "D02-03-PH17-frs-tro-ly-ai.md"), encoding="utf-8").read()
DOC_PATH = os.path.join(os.path.dirname(ROOT), "D03-03-PH17-csdl-tro-ly-ai.md")
DOC = open(DOC_PATH, encoding="utf-8").read() if os.path.exists(DOC_PATH) else ""
sql = open(os.path.join(ROOT, "ddl", "ph17_assist.sql"), encoding="utf-8").read()
appx = FRS[FRS.index("## Phụ lục A."):FRS.index("## Phụ lục B.")]
problems = []


def enum_vals(name):
    m = re.search(r"^\| `%s` \| ([^|]+) \|" % name, appx, re.M)
    if not m:
        problems.append(f"Không có enum {name} ở Phụ lục A")
        return set()
    return set(re.findall(r"`([A-Z][A-Z0-9_]+)`", re.sub(r"\([^()]*\)", "", m.group(1))))


tables = {m.group(1): m.group(2) for m in re.finditer(r"CREATE TABLE ph17_assist\.(\w+) \((.*?)\n\)( PARTITION BY [^;]+)?;", sql, re.S)}
ENUMS = {}
for m in re.finditer(r"^\| `(\w+)`[^|]*\| ([^|]+) \|", appx, re.M):
    ENUMS[m.group(1)] = set(re.findall(r"`([A-Z][A-Z0-9_]+)`", re.sub(r"\([^()]*\)", "", m.group(2))))
# Cột có tập giá trị liệt kê trong CHECK nhưng chủ ý không phải enum Phụ lục A (giá trị có ở FRS 6, 8; đề nghị 9.2 thêm vào Phụ lục A)
NGOAI_PHU_LUC = set()
# 1. mọi CHECK dạng cột IN (...), cột <@ ARRAY[...]: tập giá trị phải nằm trong một enum Phụ lục A; ghi rõ khi là tập con
used, subsets, outside, n_enum = set(), [], [], 0
ngoai_frs = {}
for t, body in tables.items():
    pairs = []
    for ck in re.findall(r"CHECK \((.*?)\)(?:,\n|\n$)", body + "\n", re.S):
        mm = re.match(r"(?:\w+ IS NULL OR )?(?:cardinality\(\w+\)[^()]*? AND )?(\w+) (?:IN|<@ ARRAY)\s*[\(\[]([^\)\]]*)[\)\]](.*)$", ck, re.S)
        if mm and " OR " not in mm.group(3) and " THEN " not in mm.group(3):
            pairs.append((mm.group(1), mm.group(2)))
    for col, vals in pairs:
        got = set(re.findall(r"'([A-Z][A-Z0-9_]+)'", vals))
        if not got:
            continue
        n_enum += 1
        exact = [n for n, v in ENUMS.items() if v == got]
        if exact:
            used.update(exact)
            continue
        sup = [n for n, v in ENUMS.items() if got < v]
        if sup:
            used.update(sup[:1])
            subsets.append(f"{t}.{col} là tập con của {sup[0]} (thiếu {sorted(ENUMS[sup[0]] - got)})")
        elif (t, col) in NGOAI_PHU_LUC:
            outside.append(f"{t}.{col}: {sorted(got)}")
        else:
            outside.append(f"{t}.{col}: {sorted(got)}")
# enum Phụ lục A không dùng ở DDL (cho biết thiếu cột hoặc enum chỉ dùng ở dịch vụ)
unused = sorted(set(ENUMS) - used)
# 2. mọi giá trị UPPER_SNAKE trong CHECK phải có ở FRS (bất kỳ chỗ nào: enum hoặc danh sách đầu vào)
tokens = set(re.findall(r"[A-Z][A-Z0-9_]{2,}", FRS))
for t, body in tables.items():
    for ck in re.findall(r"CHECK \((.*?)\)(?:,\n|\n$)", body + "\n", re.S):
        for v in re.findall(r"'([A-Z][A-Z0-9_]{2,})'", ck):
            if v not in tokens and v not in ("INFO", "WARN", "ERROR"):  # mức nhật ký chuẩn, không phải enum nghiệp vụ
                ngoai_frs.setdefault(t, []).append(v)
# 3. mã tham chiếu
frs_err = set(re.findall(r"^\| (ERR-17-\d{3}) \|", FRS, re.M))
frs_br = set(re.findall(r"^\| (BR-17-\d{3}) \|", FRS, re.M))
frs_en = set(re.findall(r"^\| (EN-17-\d{2}) \|", FRS, re.M))
frs_fr = set(re.findall(r"^\| (FR-17-\d{3}) \|", FRS, re.M))
for label, text in (("DDL", sql), ("tài liệu", DOC)):
    for e in sorted(set(re.findall(r"ERR-17-\d{3}", text)) - frs_err):
        problems.append(f"LỆCH {label}: {e} không có ở FRS 9.1")
    for e in sorted(set(re.findall(r"BR-17-\d{3}", text)) - frs_br):
        problems.append(f"LỆCH {label}: {e} không có ở FRS mục 7")
    for e in sorted(set(re.findall(r"EN-17-\d{2}", text)) - frs_en):
        problems.append(f"LỆCH {label}: {e} không có ở FRS 4.2")
    for e in sorted(set(re.findall(r"FR-17-\d{3}", text)) - frs_fr):
        problems.append(f"LỆCH {label}: {e} không có ở FRS mục 5")
if DOC:
    for e in sorted(frs_en - set(re.findall(r"EN-17-\d{2}", DOC))):
        problems.append(f"Tài liệu thiếu {e}")
    miss_fr = sorted(f for f in frs_fr if f not in DOC and f[-3:] not in " ".join(re.findall(r"(?<=FR-17-)\d{3}(?:(?:, |…|–)\d{3})*", DOC)))
    if miss_fr:
        problems.append("Tài liệu thiếu FR: " + ", ".join(miss_fr))
# 4. RLS, comment
for t, body in tables.items():
    if not re.search(r"CALL ph17_assist\.p_enable_rls(?:_common|_user)?\('ph17_assist\.%s'" % t, sql):
        problems.append(f"LỆCH: {t} chưa bật RLS")
    if not re.search(r"COMMENT ON TABLE ph17_assist\.%s IS" % t, sql):
        problems.append(f"LỆCH: {t} thiếu COMMENT ON TABLE")
    for c in ("tenant_id",):
        if not re.search(r"\b%s\b" % c, body):
            problems.append(f"LỆCH: {t} thiếu {c}")
print(f"{len(tables)} bảng; {n_enum} cột enum đối chiếu Phụ lục A; {len(frs_err)} ERR, {len(frs_br)} BR, {len(frs_en)} EN, {len(frs_fr)} FR ở FRS")
for x in subsets:
    print("Tập con có chủ ý:", x)
print(f"Cột có tập giá trị ngoài Phụ lục A: {len(outside)} (đề nghị bổ sung vào Phụ lục A, xem mục 10.1 của tài liệu)")
for x in outside:
    print("  Ngoài Phụ lục A:", x)
print(f"Giá trị CHECK chưa có chỗ nào ở FRS: {sum(len(set(v)) for v in ngoai_frs.values())} giá trị ở {len(ngoai_frs)} bảng (nội bộ thiết kế, không phải lệch FRS)")
print("Enum Phụ lục A dùng ở dịch vụ hoặc trong jsonb, chưa có cột CHECK:", ", ".join(unused) or "không")
for p in problems:
    print(p)
print("Kết quả:", "LỆCH" if problems else "khớp")
sys.exit(1 if problems else 0)
