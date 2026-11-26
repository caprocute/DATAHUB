#!/usr/bin/env python3
"""Đo kích thước đầu ra và ngữ cảnh nạp của một bộ tài liệu phân hệ, để so sánh hiệu suất token.

    python3 datahub-docs/build/tools/do_hieu_suat.py PH07 PH04            # in bảng Markdown
    python3 datahub-docs/build/tools/do_hieu_suat.py PH19 --json out.json  # ghi số liệu máy đọc

Ước lượng token = số byte UTF-8 / 3 (giả định cho văn bản tiếng Việt có mã kỹ thuật, sai số khoảng ±25%).
Dùng cùng một công thức cho mọi phân hệ nên phép so sánh giữa các bộ vẫn có nghĩa dù giá trị tuyệt đối lệch.
"""
from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path

DOCS = Path(__file__).resolve().parents[2]
BYTES_PER_TOKEN = 3

TAP = [
    ("FRS", "02-yeu-cau/frs/D02-03-{ph}-*.md"),
    ("Use case", "02-yeu-cau/use-case/D02-04-{ph}-*.md"),
    ("SDD", "03-thiet-ke/sdd/D03-02-{ph}-*.md"),
    ("CSDL", "03-thiet-ke/csdl/D03-03-{ph}-*.md"),
    ("API", "03-thiet-ke/api/D03-04-{ph}-*.md"),
    ("Màn hình", "03-thiet-ke/uiux/D03-06-{ph}-*.md"),
    ("Test case", "05-kiem-thu/test-case/D05-02-{ph}-*.md"),
]

# Ngữ cảnh một luồng phân hệ phải nạp theo cách cũ: tài liệu chung + nguyên bộ mẫu PH-07.
NAP_CU = [
    "00-chung/D00-01-thuat-ngu-quy-uoc.md",
    "00-chung/D00-02-so-adr.md",
    "02-yeu-cau/D02-02-srs.md",
    "03-thiet-ke/D03-01-sad.md",
    "03-thiet-ke/uiux/D03-06-00-ia-layout-mau-man-hinh.md",
] + [p.format(ph="PH07") for _, p in TAP]
# Theo cách mới: sổ tra cứu gọn + khuôn rỗng.
NAP_MOI = ["00-chung/D00-04-so-tra-cuu-gon.md", "00-chung/khuon/*.md"]


def files(pattern: str):
    return sorted(DOCS.glob(pattern))


def size(paths) -> tuple[int, int]:
    b = w = 0
    for p in paths:
        t = p.read_text(encoding="utf-8")
        b += len(t.encode("utf-8"))
        w += len(t.split())
    return b, w


def git_stats(paths) -> dict:
    if not paths:
        return {}
    rel = [str(p) for p in paths]
    try:
        out = subprocess.run(["git", "log", "--format=%ad", "--date=iso-strict", "--", *rel],
                             cwd=DOCS, capture_output=True, text=True, check=True).stdout.split()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return {}
    return {"commits": len(out), "dau": min(out) if out else None, "cuoi": max(out) if out else None}


def measure(ph: str) -> dict:
    rows, all_paths = [], []
    for name, pat in TAP:
        ps = files(pat.format(ph=ph))
        all_paths += ps
        b, w = size(ps)
        rows.append({"tap": name, "tep": [p.relative_to(DOCS).as_posix() for p in ps], "byte": b, "tu": w,
                     "token_uoc": b // BYTES_PER_TOKEN})
    kem = [p for d in DOCS.rglob(ph.lower()) if d.is_dir() for p in d.rglob("*") if p.is_file()]
    kem_b = sum(p.stat().st_size for p in kem)
    tong_b = sum(r["byte"] for r in rows)
    return {
        "phan_he": ph,
        "tap": rows,
        "tong_byte": tong_b,
        "tong_tu": sum(r["tu"] for r in rows),
        "tong_token_uoc": tong_b // BYTES_PER_TOKEN,
        "tep_kem": len(kem),
        "tep_kem_byte": kem_b,
        "git": git_stats(all_paths),
    }


def context_cost() -> dict:
    cu = [p for pat in NAP_CU for p in files(pat)]
    moi = [p for pat in NAP_MOI for p in files(pat)]
    bc, _ = size(cu)
    bm, _ = size(moi)
    return {"cu_byte": bc, "cu_token_uoc": bc // BYTES_PER_TOKEN, "moi_byte": bm, "moi_token_uoc": bm // BYTES_PER_TOKEN}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("phan_he", nargs="+", help="ví dụ PH07 PH04 PH19")
    ap.add_argument("--json", help="ghi số liệu ra tệp JSON")
    a = ap.parse_args()
    data = {"phan_he": [measure(ph.upper()) for ph in a.phan_he], "ngu_canh_nap": context_cost(),
            "cong_thuc": f"token ≈ byte UTF-8 / {BYTES_PER_TOKEN}"}
    if a.json:
        Path(a.json).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    head = "| Tập | " + " | ".join(f"{m['phan_he']} (KB / ~k token)" for m in data["phan_he"]) + " |"
    print(head)
    print("|---|" + "---|" * len(data["phan_he"]))
    for i, (name, _) in enumerate(TAP):
        print(f"| {name} | " + " | ".join(f"{m['tap'][i]['byte']/1024:.0f} / {m['tap'][i]['token_uoc']/1000:.0f}" for m in data["phan_he"]) + " |")
    print("| **Tổng bảy tập** | " + " | ".join(f"**{m['tong_byte']/1024:.0f} / {m['tong_token_uoc']/1000:.0f}**" for m in data["phan_he"]) + " |")
    print("| Tệp kèm (số tệp, KB) | " + " | ".join(f"{m['tep_kem']}, {m['tep_kem_byte']/1024:.0f}" for m in data["phan_he"]) + " |")
    print("| Commit chạm bộ tài liệu | " + " | ".join(str(m["git"].get("commits", "—")) for m in data["phan_he"]) + " |")
    c = data["ngu_canh_nap"]
    print(f"\nNgữ cảnh nạp trước khi viết: cách cũ {c['cu_byte']/1024:.0f} KB (~{c['cu_token_uoc']/1000:.0f}k token), "
          f"cách mới {c['moi_byte']/1024:.0f} KB (~{c['moi_token_uoc']/1000:.0f}k token).")


if __name__ == "__main__":
    main()
