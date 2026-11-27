#!/usr/bin/env python3
"""Đọc khối đặc tả 17 mục của 20 FRS và khối UC 15 mục; trả về cấu trúc dùng chung cho sinh_backlog.py."""
from __future__ import annotations
import re
from pathlib import Path

DOCS = Path(__file__).resolve().parents[3]
FRS_DIR = DOCS / "02-yeu-cau" / "frs"
UC_DIR = DOCS / "02-yeu-cau" / "use-case"

LABELS = ["Mục đích", "Tác nhân, quyền", "Mức ưu tiên, đợt", "Truy vết", "Tiền điều kiện", "Kích hoạt",
          "Đầu vào", "Luồng xử lý chính", "Luồng thay thế", "Luồng ngoại lệ", "Đầu ra", "Kết quả",
          "Hậu điều kiện", "Sự kiện phát ra", "Kiểm toán", "Quy tắc nghiệp vụ", "Màn hình, API"]
LABEL_RE = re.compile(r"^\*\*(" + "|".join(re.escape(l) for l in LABELS) + r")\.\*\*\s*(.*)$")
GROUP_RE = re.compile(r"^###\s+[\d.]+\s+Nhóm\s+([A-Z])\s+·\s+(.+?)\s*$")
FR_RE = re.compile(r"^####\s+(FR-(\d{2})-\d{3})\s+·\s+(.+?)\s*$")
UC_RE = re.compile(r"^#{3,4}\s+(?:[\d.]+\s+)?(UC-(\d{2})-\d{2})\s+·\s+(.+?)\s*$")
FRCODE = re.compile(r"FR-(\d{2})-(\d{3})(?:\s*(?:…|–|\.\.\.)\s*(?:FR-\d{2}-)?(\d{3}))?")


def ph_name(f: Path) -> str:
    for line in f.read_text(encoding="utf-8").splitlines()[:12]:
        if line.startswith("ten:"):
            return line.split(":", 1)[1].strip()
    return ""


def parse_frs():
    out = {}
    for f in sorted(FRS_DIR.glob("D02-03-PH[0-9][0-9]-frs-*.md")):
        ph = f.name[9:11]
        lines = f.read_text(encoding="utf-8").splitlines()
        groups, frs = {}, []
        group = None
        cur = None
        in_block = False
        label = None
        for ln in lines:
            m = GROUP_RE.match(ln)
            if m:
                group = m.group(1); groups[group] = m.group(2); continue
            m = FR_RE.match(ln)
            if m:
                cur = {"fr": m.group(1), "ph": ph, "title": m.group(3), "group": group, "f": {}}
                frs.append(cur); in_block = False; continue
            if cur is None:
                continue
            if ln.strip() == "::: dac-ta":
                in_block = True; label = None; continue
            if in_block and ln.strip() == ":::":
                in_block = False; cur = None if cur.get("f") else cur; continue
            if in_block:
                m = LABEL_RE.match(ln)
                if m:
                    label = m.group(1); cur["f"][label] = m.group(2).strip()
                elif label:
                    cur["f"][label] = (cur["f"][label] + "\n" + ln).strip("\n")
        out[ph] = {"file": f, "name": ph_name(f), "groups": groups, "frs": frs}
    return out


def expand_fr(text: str, default_ph: str | None = None):
    res = []
    for m in FRCODE.finditer(text):
        ph, a, b = m.group(1), int(m.group(2)), m.group(3)
        if b:
            res += [f"FR-{ph}-{i:03d}" for i in range(a, int(b) + 1)]
        else:
            res.append(f"FR-{ph}-{a:03d}")
    return res


def parse_uc():
    """FR -> [UC] theo trường 'FR hiện thực' của khối UC."""
    m = {}
    for f in sorted(UC_DIR.glob("D02-04-PH*.md")):
        cur = None
        for ln in f.read_text(encoding="utf-8").splitlines():
            u = UC_RE.match(ln)
            if u:
                cur = u.group(1); continue
            if cur and ln.startswith("**FR hiện thực.**"):
                txt = ln.split("**", 2)[2]
                ph = cur[3:5]
                # dạng rút gọn "FR-01-003, 004, 010"
                codes = expand_fr(txt)
                for short in re.findall(r"(?<=[,;] )(\d{3})\b", txt):
                    codes.append(f"FR-{ph}-{short}")
                for c in dict.fromkeys(codes):
                    m.setdefault(c, []).append(cur)
    return m


if __name__ == "__main__":
    d = parse_frs()
    tot = sum(len(v["frs"]) for v in d.values())
    print("FR:", tot)
    miss = [(fr["fr"], [l for l in LABELS if l not in fr["f"]]) for v in d.values() for fr in v["frs"] if len(fr["f"]) < 17]
    print("thiếu mục:", len(miss), miss[:10])
    nog = [fr["fr"] for v in d.values() for fr in v["frs"] if not fr["group"]]
    print("không nhóm:", nog[:10], len(nog))
    uc = parse_uc()
    allfr = {fr["fr"] for v in d.values() for fr in v["frs"]}
    print("FR có UC:", len(allfr & set(uc)), "/", len(allfr))
