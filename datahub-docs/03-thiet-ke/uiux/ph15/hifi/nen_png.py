#!/usr/bin/env python3
"""Nén ảnh hi-fi (giảm số màu về bảng 128 màu, giữ chữ đọc được) để tổng PNG của ph15 ≤ 8 MB. Chạy sau node shot.js."""
import pathlib
from PIL import Image

for p in sorted(pathlib.Path(__file__).parent.glob("ui-15-*.png")):
    im = Image.open(p).convert("RGB")
    im.quantize(colors=128, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).save(p, optimize=True)
print("Đã nén")
