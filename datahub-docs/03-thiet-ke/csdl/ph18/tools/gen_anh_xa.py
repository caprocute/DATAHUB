#!/usr/bin/env python3
"""Sinh bảng danh sách bảng (D03-03-PH18 §3) và bảng ánh xạ EN-18 → bảng (§8.1) từ danh mục bảng của sinh_ddl.py.

Chạy từ thư mục csdl/ph18:  python3 tools/gen_anh_xa.py [--write]
Thay đoạn giữa <!-- gen:list:start --> … <!-- gen:list:end --> và <!-- gen:en:start --> … <!-- gen:en:end -->.
Thứ tự EN-18-01…54 theo BRIEF-PH18 §5 (FRS §4.2 dùng cùng thứ tự), EN-18-55 theo BRIEF §7 (hợp đồng PH-20).
"""
import os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DOC = os.path.join(os.path.dirname(ROOT), "D03-03-PH18-csdl-van-hanh.md")
sys.path.insert(0, HERE)
from sinh_ddl import FILE_GROUPS, ALL

KHOI = {"18-0010-core.sql": "Kỹ thuật", "18-0020-param.sql": "A", "18-0030-dlq.sql": "B, C, D", "18-0040-notify.sql": "E", "18-0050-task.sql": "F",
        "18-0060-incident.sql": "G", "18-0070-backup.sql": "H", "18-0080-migration.sql": "I", "18-0090-report.sql": "J"}


def first_sentence(t):
    c = t["comment"]
    m = re.match(r"(.+?[^0-9A-Z]\.)(\s|$)", c)
    out = (m.group(1) if m else c).rstrip(".")
    out = out.split(": ")[0] if len(out) > 90 and ": " in out else out
    return out.split(" (")[0] if len(out) > 110 else out


def danh_sach():
    L = ["| STT | Bảng | Khối | EN | Phân vùng | Chỉ thêm | Dùng chung `COMMON` | Nội dung |", "|---|---|---|---|---|---|---|---|"]
    i = 0
    for f, g in FILE_GROUPS:
        for t in g:
            i += 1
            en = t["en"] if t["en"].startswith("EN-") else "Kỹ thuật"
            common = "Chỉ `COMMON`" if t["only_common"] else ("Đọc chung" if t["rls"] == "common" else ("Dòng nền tảng" if t["common_ok"] else "Không"))
            L.append(f"| {i} | `{t['name']}` | {KHOI[f]} | {en} | {'`' + t['part'][0] + '`' if t['part'] else 'Không'} | {'Có' if t['append_only'] else 'Không'} | {common} | {first_sentence(t).replace('|', '/')} |")
    L.append("")
    L.append(": Danh sách 57 bảng của schema `ph18_ops` theo khối chức năng")
    return "\n".join(L)


def anh_xa():
    rows = sorted([t for t in ALL if t["en"].startswith("EN-")], key=lambda t: t["en"])
    L = ["| EN | Thực thể | Bảng | Ghi chú thiết kế |", "|---|---|---|---|"]
    for t in rows:
        ghi = []
        if t["part"]:
            ghi.append(f"phân vùng tháng `{t['part'][0]}`")
        if t["append_only"]:
            ghi.append("chỉ thêm")
        if t["only_common"]:
            ghi.append("chỉ dòng `COMMON`")
        elif t["rls"] == "common":
            ghi.append("đọc thêm dòng `COMMON`")
        if t["name"] == "merge_transfer":
            ghi.append("thêm theo BRIEF §7, hợp đồng PH-20")
        L.append(f"| {t['en']} | {first_sentence(t).replace('|', '/')} | `{t['name']}` | {', '.join(ghi) or 'Bảng theo tenant'} |")
    L.append("")
    L.append(": Ánh xạ 55 thực thể EN-18 sang bảng của `ph18_ops`")
    return "\n".join(L)


if __name__ == "__main__":
    a, b = danh_sach(), anh_xa()
    if "--write" in sys.argv:
        doc = open(DOC, encoding="utf-8").read()
        doc, n1 = re.subn(r"(<!-- gen:list:start -->\n).*?(<!-- gen:list:end -->)", lambda m: m.group(1) + a + "\n" + m.group(2), doc, flags=re.S)
        doc, n2 = re.subn(r"(<!-- gen:en:start -->\n).*?(<!-- gen:en:end -->)", lambda m: m.group(1) + b + "\n" + m.group(2), doc, flags=re.S)
        open(DOC, "w", encoding="utf-8").write(doc)
        print("danh sách", n1, "ánh xạ EN", n2)
    else:
        print(a)
        print()
        print(b)
