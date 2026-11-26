"""Sinh reference.docx cho bản xuất hồ sơ thiết kế Datahub.

Thể thức theo NĐ 30/2020/NĐ-CP (khổ A4; lề trên, dưới 20 mm, trái 30 mm, phải 15 mm;
Times New Roman 13 pt) cộng các kiểu trình bày của khuôn K-TRINH-BAY: trang bìa, nhãn bảng
đặc tả, chú thích bảng và hình, mục lục ba cấp, đề mục màu xanh đậm, mỗi chương sang trang mới.
Chạy: python3 build/make_reference.py (từ thư mục datahub-docs)."""
import subprocess

import docx
from docx.enum.style import WD_STYLE_TYPE
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Mm, Pt, RGBColor

OUT = "build/reference.docx"
XANH = RGBColor(0x1F, 0x38, 0x64)
XANH_NHAT = RGBColor(0x2E, 0x54, 0x8C)
FONT = "Times New Roman"

subprocess.run(["pandoc", "-o", OUT, "--print-default-data-file", "reference.docx"], check=True)
d = docx.Document(OUT)
for s in d.sections:
    s.page_height, s.page_width = Mm(297), Mm(210)
    s.top_margin = s.bottom_margin = Mm(20)
    s.left_margin, s.right_margin = Mm(30), Mm(15)
    s.header_distance = s.footer_distance = Mm(10)

styles = d.styles
by_id = {s.style_id: s for s in styles}
by_name = {s.name: s for s in styles}


def set_font(st, size=None, bold=None, italic=None, color=None):
    st.font.name = FONT
    rpr = st.element.get_or_add_rPr()
    fonts = rpr.find(qn("w:rFonts"))
    if fonts is None:
        fonts = OxmlElement("w:rFonts")
        rpr.insert(0, fonts)
    for a in ("w:ascii", "w:hAnsi", "w:cs", "w:eastAsia"):
        fonts.set(qn(a), FONT)
    for a in ("w:asciiTheme", "w:hAnsiTheme", "w:cstheme", "w:eastAsiaTheme"):
        if fonts.get(qn(a)) is not None:
            del fonts.attrib[qn(a)]
    if size:
        st.font.size = Pt(size)
    if bold is not None:
        st.font.bold = bold
    if italic is not None:
        st.font.italic = italic
    st.font.color.rgb = color


def para(st, align=None, before=0, after=6, line=1.15, keep_next=None, indent_first=None, page_break=None):
    pf = st.paragraph_format
    if align is not None:
        pf.alignment = align
    pf.space_before, pf.space_after, pf.line_spacing = Pt(before), Pt(after), line
    if keep_next is not None:
        pf.keep_with_next = keep_next
    if indent_first is not None:
        pf.first_line_indent = indent_first
    if page_break is not None:
        pf.page_break_before = page_break


def get_or_add(name, base="Normal", kind=WD_STYLE_TYPE.PARAGRAPH):
    st = by_name.get(name)
    if st is None:
        st = styles.add_style(name, kind)
        st.base_style = by_name.get(base)
        by_name[name] = st
    st.quick_style = True
    return st


# Văn bản thường
for name in ["Normal", "Body Text", "First Paragraph"]:
    st = by_name.get(name)
    if st is not None:
        set_font(st, 13)
        para(st, WD_ALIGN_PARAGRAPH.JUSTIFY, before=4, after=6, line=1.2)
st = by_name.get("Compact")
if st is not None:
    set_font(st, 12)
    para(st, None, before=1, after=1, line=1.1)

# Đề mục
for lvl, size, before, after in [(1, 15, 6, 12), (2, 13.5, 14, 6), (3, 13, 10, 4), (4, 13, 8, 4), (5, 13, 6, 3)]:
    st = by_name.get(f"Heading {lvl}")
    if st is None:
        continue
    set_font(st, size, True, lvl >= 4, XANH if lvl <= 2 else XANH_NHAT)
    para(st, WD_ALIGN_PARAGRAPH.LEFT, before, after, 1.1, keep_next=True, page_break=(lvl == 1))
    if lvl == 1:
        st.font.all_caps = True

# Mã nguồn
st = by_name.get("Source Code")
if st is not None:
    st.font.size = Pt(9.5)
    pPr = st.element.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear"); shd.set(qn("w:color"), "auto"); shd.set(qn("w:fill"), "F3F5F8")
    pPr.append(shd)

# Mục lục
st = get_or_add("TOC Heading", "Heading 1")
for lvl, ind, bold in [(1, 0, True), (2, 5, False), (3, 10, False)]:
    st = get_or_add(f"toc {lvl}")
    set_font(st, 12.5 if lvl == 1 else 12, bold)
    para(st, None, before=4 if lvl == 1 else 0, after=2, line=1.1)
    st.paragraph_format.left_indent = Mm(ind)

# Kiểu riêng của khuôn trình bày
spec = [
    # tên, cỡ, đậm, nghiêng, màu, căn, trước, sau
    ("Bìa cơ quan", 13, True, False, None, WD_ALIGN_PARAGRAPH.CENTER, 0, 4),
    ("Bìa dự án", 13, False, False, None, WD_ALIGN_PARAGRAPH.CENTER, 0, 60),
    ("Bìa loại", 15, True, False, XANH, WD_ALIGN_PARAGRAPH.CENTER, 0, 12),
    ("Bìa tiêu đề", 20, True, False, XANH, WD_ALIGN_PARAGRAPH.CENTER, 0, 12),
    ("Bìa mã", 13, False, True, XANH_NHAT, WD_ALIGN_PARAGRAPH.CENTER, 0, 12),
    ("Bìa mô tả", 12.5, False, True, None, WD_ALIGN_PARAGRAPH.CENTER, 0, 12),
    ("Bìa khoảng", 13, False, False, None, WD_ALIGN_PARAGRAPH.CENTER, 0, 30),
    ("Bìa nơi ngày", 13, False, True, None, WD_ALIGN_PARAGRAPH.CENTER, 80, 0),
    ("Tiêu đề phụ lục đầu", 15, True, False, XANH, WD_ALIGN_PARAGRAPH.CENTER, 0, 12),
    ("Tiêu đề nhỏ", 13, True, False, XANH_NHAT, WD_ALIGN_PARAGRAPH.LEFT, 12, 6),
    ("Chú thích bảng", 12, False, True, None, WD_ALIGN_PARAGRAPH.CENTER, 8, 4),
    ("Chú thích hình", 12, False, True, None, WD_ALIGN_PARAGRAPH.CENTER, 2, 10),
    ("Hình", 12, False, False, None, WD_ALIGN_PARAGRAPH.CENTER, 6, 0),
    ("Nhãn đặc tả", 12, True, False, None, WD_ALIGN_PARAGRAPH.LEFT, 1, 1),
]
for name, size, bold, italic, color, align, before, after in spec:
    st = get_or_add(name)
    set_font(st, size, bold, italic, color)
    para(st, align, before, after, 1.1, keep_next=name in ("Chú thích bảng", "Hình", "Tiêu đề nhỏ"))
    if name in ("Bìa tiêu đề", "Bìa loại"):
        st.font.all_caps = True

d.save(OUT)
print("Đã tạo", OUT)
