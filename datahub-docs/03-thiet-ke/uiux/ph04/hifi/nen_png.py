#!/usr/bin/env python3
"""Nén ảnh ui-04-*.png về bảng màu 256 màu (không hòa sắc) để tổng dung lượng ảnh PH-04 ≤ 10 MB. Chạy sau node shot.js."""
import pathlib
from PIL import Image

d = pathlib.Path(__file__).parent
tong = 0
for f in sorted(d.glob("ui-04-*.png")):
    im = Image.open(f).convert("RGB").quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    im.save(f, optimize=True)
    tong += f.stat().st_size
print(f"Tổng dung lượng ảnh: {tong / 1e6:.2f} MB")
