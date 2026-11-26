#!/usr/bin/env python3
"""Sinh chương đặc tả từng endpoint của D03-04-PH11 bằng build/tools/sinh_dac_ta_api.py rồi rút gọn mỗi endpoint để tập không vượt 160 KB.
Rút gọn: bỏ danh sách "trường bắt buộc" ở phản hồi (có trong OpenAPI), bỏ câu chú thích lặp ở dòng Lỗi. Không bỏ endpoint nào.
Chạy từ api/ph11:  python3 tools/gen_dac_ta.py"""
import os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DOC = os.path.join(ROOT, "..", "D03-04-PH11-api-quy-trinh.md")
TOOL = os.path.join(ROOT, "..", "..", "..", "build", "tools", "sinh_dac_ta_api.py")
subprocess.run([sys.executable, TOOL, os.path.join(ROOT, "openapi-bpm.yaml"), DOC], check=True)
s = open(DOC, encoding="utf-8").read()
a, b = s.index("<!-- gen:dac-ta-api:start -->"), s.index("<!-- gen:dac-ta-api:end -->")
g = s[a:b]
g = re.sub(r"(\*\*Phản hồi thành công\.\*\*[^\n]*)", lambda m: re.sub(r"; trường bắt buộc: (`\w+`(, )?)+", "", m.group(1)), g)
g = g.replace("; mã lỗi của thao tác: ", "; mã lỗi: ").replace(" (ý nghĩa ở chương mã lỗi)", "")
g = re.sub(r"`(\d{3})` (thành công|đã tạo|đã nhận, xử lý bất đồng bộ), ", r"`\1`, ", g)
g = re.sub(r"\*\*(Thân yêu cầu|Chống trùng)\.\*\* Không\.\n\n", "", g)  # dòng vắng nghĩa là Không (nêu ở đầu chương)
g = g.replace("\n\n**Ghi chú.** Theo FRS 9.4.\n:::", "\n:::")
g = g.replace("; tiêu đề `ETag`, ", "; tiêu đề ").replace("; tiêu đề `ETag`", "")  # ETag ở mọi phản hồi đối tượng: nêu ở đầu chương
s = s[:a] + g + s[b:]
open(DOC, "w", encoding="utf-8").write(s)
print("kích thước:", len(s.encode()), "byte")
