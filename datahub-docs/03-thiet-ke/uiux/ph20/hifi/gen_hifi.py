#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-20-01…22 (D03-06-PH20, mục "Bản hi-fi" của từng màn).

Chạy: python3 gen_hifi.py && node shot.js && python3 nen.py
Dữ liệu là giả định: tenant T68 (Tỉnh Lâm Viên, giả định), T01 (Tỉnh Mẫu A), T90 (kiểm thử); tên người, mã, số đều là dữ liệu giả.
Khung dh-console: vai trò nền tảng (`/nen-tang/*`, tenant PLATFORM) và quản trị tỉnh (`/quan-tri/*`).
Phong cách Liquid Glass của D03-05 (ADR-020): kính chỉ ở lớp điều hướng và lớp nổi, nội dung nền đặc.
"""
import pathlib
import kit
import s1
import s2
import s3

OUT = pathlib.Path(__file__).parent
P = {}
for m in (s1, s2, s3):
    P.update(m.P)
for code, v in sorted(P.items()):
    title, crumb, body = v[0], v[1], v[2]
    extra = v[3] if len(v) > 3 else ""
    kw = v[4] if len(v) > 4 else {}
    (OUT / f"ui-20-{code}.html").write_text(kit.shell(code, title, crumb, body, extra, **kw), encoding="utf-8")
print(len(P), "màn:", " ".join(sorted(P)))
