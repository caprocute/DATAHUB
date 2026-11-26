"""Sinh reference.docx theo thể thức NĐ 30/2020/NĐ-CP (khổ A4, lề trên/dưới 20 mm,
trái 30 mm, phải 15 mm; Times New Roman 13 pt, cách dòng 1,15). Chạy: python3 build/make_reference.py"""
import subprocess, docx
from docx.shared import Pt, Mm
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml.ns import qn

out = "build/reference.docx"
subprocess.run(["pandoc", "-o", out, "--print-default-data-file", "reference.docx"], check=True)
d = docx.Document(out)
for s in d.sections:
    s.page_height, s.page_width = Mm(297), Mm(210)
    s.top_margin = s.bottom_margin = Mm(20)
    s.left_margin, s.right_margin = Mm(30), Mm(15)

by_id = {s.style_id: s for s in d.styles}
def font(style, size, bold=None, align=None):
    st = by_id.get(style.replace(" ", ""))
    if st is None:
        return
    st.font.name = "Times New Roman"
    st.font.size = Pt(size)
    st.font.color.rgb = None
    if bold is not None: st.font.bold = bold
    pf = st.paragraph_format
    pf.line_spacing = 1.15
    pf.space_after = Pt(6)
    if align: pf.alignment = align

for name in ["Normal", "Body Text", "First Paragraph", "Compact"]:
    font(name, 13, align=WD_ALIGN_PARAGRAPH.JUSTIFY if name != "Compact" else None)
font("Title", 16, True, WD_ALIGN_PARAGRAPH.CENTER)
for lvl, size in [(1, 14), (2, 13), (3, 13), (4, 13)]:
    font(f"Heading {lvl}", size, True)
    if f"Heading{lvl}" in by_id: by_id[f"Heading{lvl}"].font.italic = lvl == 4
d.save(out)
print("Đã tạo", out)
