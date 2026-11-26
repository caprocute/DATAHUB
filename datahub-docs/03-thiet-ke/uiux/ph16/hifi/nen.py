#!/usr/bin/env python3
"""Nén ảnh PNG hi-fi về dưới 400 KB bằng lượng tử hóa màu (không đổi kích thước). Chạy sau shot.js."""
import pathlib
from PIL import Image
d = pathlib.Path(__file__).parent
for f in sorted(d.glob("ui-16-*.png")):
    im = Image.open(f).convert("RGB")
    for n in (256, 160, 96, 64):
        q = im.quantize(colors=n, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
        q.save(f, optimize=True)
        if f.stat().st_size <= 380_000:
            break
    print(f.name, f.stat().st_size // 1024, "KB", im.size, n)
