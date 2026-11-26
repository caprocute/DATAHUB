#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-08-01…20 và ba biến thể 01b, 07b, 12b (D03-06-PH08, mục "Bản hi-fi" của từng màn).

Chạy: python3 gen_hifi.py && node shot.js && python3 nen.py
Dữ liệu là giả định của tỉnh thí điểm T68: tổ chức, người, mã, số đều là dữ liệu giả; số định danh luôn che.
Menu theo D03-06-00 mục 22 (Dữ liệu dùng chung › Chất lượng dữ liệu); hàng tab phụ theo D03-06-PH08 mục 4.
Phong cách Liquid Glass của D03-05 (ADR-020): kính chỉ ở lớp điều hướng và lớp nổi, nội dung nền đặc; biểu đồ vẽ SVG theo kiểu ECharts (ADR-023).
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
    (OUT / f"ui-08-{code}.html").write_text(kit.shell(code, title, crumb, body, extra), encoding="utf-8")
print(len(P), "màn:", " ".join(sorted(P)))
