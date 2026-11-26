"""Hậu xử lý bản .docx do pandoc sinh (bước 2 của build-docx.sh).

- Chuyển mục lục của pandoc vào vị trí dấu [[MUC-LUC]] (sau trang bìa và trang thông tin).
- Kẻ khung mọi bảng, tô nền hàng tiêu đề, lặp hàng tiêu đề khi sang trang; bảng đặc tả
  (cột trái là nhãn) tô nền cột nhãn như bảng đặc tả chức năng của hồ sơ thiết kế.
- Đầu trang: mã và tên tài liệu; chân trang: "Trang x / y"; trang bìa không có đầu, chân trang.
- Đặt Word tự cập nhật trường (mục lục, số trang) khi mở.
Dùng: python3 build/hau_xu_ly.py <tệp.docx> <mã tài liệu> <tên tài liệu>
      python3 build/hau_xu_ly.py --so-trang <tệp.docx> <tệp.so-trang.txt>"""
import copy
import sys

import docx
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Pt, RGBColor

NEN_TIEU_DE = "DCE4F0"
NEN_NHAN = "F1F4F9"
VIEN = "8EA3C2"


def el(tag, **attrs):
    e = OxmlElement(tag)
    for k, v in attrs.items():
        e.set(qn(k), str(v))
    return e


def shade(cell, fill):
    tcPr = cell._tc.get_or_add_tcPr()
    for old in tcPr.findall(qn("w:shd")):
        tcPr.remove(old)
    tcPr.append(el("w:shd", **{"w:val": "clear", "w:color": "auto", "w:fill": fill}))


def ke_khung(tbl):
    tblPr = tbl._tbl.tblPr
    for old in tblPr.findall(qn("w:tblBorders")):
        tblPr.remove(old)
    b = el("w:tblBorders")
    for side in ("top", "left", "bottom", "right", "insideH", "insideV"):
        b.append(el(f"w:{side}", **{"w:val": "single", "w:sz": 4, "w:space": 0, "w:color": VIEN}))
    tblPr.append(b)
    mar = el("w:tblCellMar")
    for side, w in (("top", 40), ("left", 90), ("bottom", 40), ("right", 90)):
        mar.append(el(f"w:{side}", **{"w:w": w, "w:type": "dxa"}))
    for old in tblPr.findall(qn("w:tblCellMar")):
        tblPr.remove(old)
    tblPr.append(mar)
    # rộng 100% vùng chữ
    for old in tblPr.findall(qn("w:tblW")):
        tblPr.remove(old)
    tblPr.append(el("w:tblW", **{"w:w": 5000, "w:type": "pct"}))


def la_bang_dac_ta(tbl):
    try:
        p = tbl.rows[0].cells[0].paragraphs[0]
    except IndexError:
        return False
    return p.style is not None and p.style.name == "Nhãn đặc tả"


def dinh_dang_bang(d):
    for tbl in d.tables:
        ke_khung(tbl)
        if la_bang_dac_ta(tbl):
            for row in tbl.rows:
                shade(row.cells[0], NEN_NHAN)
            continue
        rows = tbl.rows
        if not rows:
            continue
        first = rows[0]
        trPr = first._tr.get_or_add_trPr()
        if trPr.find(qn("w:tblHeader")) is not None or tbl._tbl.find(qn("w:tblPr")) is not None:
            # pandoc đánh dấu hàng tiêu đề bằng tblHeader; bảng không có tiêu đề thì bỏ qua
            if trPr.find(qn("w:tblHeader")) is None:
                continue
            for c in first.cells:
                shade(c, NEN_TIEU_DE)
                for p in c.paragraphs:
                    for r in p.runs:
                        r.font.bold = True


RONG_CHU = 9354  # 165 mm vùng chữ, đơn vị twip


def run_text(text, bold=False):
    r = OxmlElement("w:r")
    if bold:
        rpr = OxmlElement("w:rPr"); rpr.append(OxmlElement("w:b")); r.append(rpr)
    t = OxmlElement("w:t"); t.set(qn("xml:space"), "preserve"); t.text = text
    r.append(t)
    return r


def fld(kind):
    r = OxmlElement("w:r"); r.append(el("w:fldChar", **{"w:fldCharType": kind}))
    return r


def instr(text):
    r = OxmlElement("w:r"); it = OxmlElement("w:instrText"); it.set(qn("xml:space"), "preserve")
    it.text = f" {text} "; r.append(it)
    return r


def chuyen_muc_luc(d):
    """Dựng mục lục có sẵn mục (hyperlink + PAGEREF) để mọi trình đọc đều thấy;
    Word và LibreOffice cập nhật số trang khi mở hoặc khi xuất PDF."""
    body = d.element.body
    for e in list(body.iterchildren(qn("w:sdt"))):
        if e.find(".//" + qn("w:docPartGallery")) is not None:
            body.remove(e)
    dau = None
    for p in d.paragraphs:
        if p.text.strip() == "[[MUC-LUC]]":
            dau = p._p
            break
    if dau is None:
        return
    muc = []
    n = 0
    for p in d.paragraphs:
        sn = p.style.name if p.style is not None else ""
        if sn in ("Heading 1", "Heading 2", "Heading 3") and p.text.strip():
            n += 1
            name = f"_Toc{n:05d}"
            bs = el("w:bookmarkStart", **{"w:id": 90000 + n, "w:name": name})
            be = el("w:bookmarkEnd", **{"w:id": 90000 + n})
            p._p.insert(1 if p._p.pPr is not None else 0, bs)
            p._p.append(be)
            muc.append((int(sn[-1]), p.text.strip(), name))
    if not muc:
        dau.getparent().remove(dau)
        return
    for i, (lvl, text, name) in enumerate(muc):
        p = OxmlElement("w:p")
        pPr = OxmlElement("w:pPr")
        pPr.append(el("w:pStyle", **{"w:val": f"TOC{lvl}" if f"TOC{lvl}" in STYLE_IDS else f"toc{lvl}"}))
        tabs = OxmlElement("w:tabs")
        tabs.append(el("w:tab", **{"w:val": "right", "w:leader": "dot", "w:pos": RONG_CHU}))
        pPr.append(tabs)
        p.append(pPr)
        if i == 0:
            p.append(fld("begin")); p.append(instr('TOC \\o "1-3" \\h \\z \\u')); p.append(fld("separate"))
        h = el("w:hyperlink", **{"w:anchor": name, "w:history": 1})
        h.append(run_text(text, bold=(lvl == 1)))
        tab = OxmlElement("w:r"); tab.append(OxmlElement("w:tab")); h.append(tab)
        h.append(fld("begin")); h.append(instr(f"PAGEREF {name} \\h")); h.append(fld("separate"))
        h.append(run_text("1")); h.append(fld("end"))
        p.append(h)
        if i == len(muc) - 1:
            p.append(fld("end"))
        dau.addprevious(p)
    dau.getparent().remove(dau)


STYLE_IDS = set()


def truong(run_parent, instr):
    r1 = OxmlElement("w:r"); r1.append(el("w:fldChar", **{"w:fldCharType": "begin"}))
    r2 = OxmlElement("w:r"); it = OxmlElement("w:instrText"); it.set(qn("xml:space"), "preserve")
    it.text = f" {instr} "; r2.append(it)
    r3 = OxmlElement("w:r"); r3.append(el("w:fldChar", **{"w:fldCharType": "separate"}))
    r4 = OxmlElement("w:r"); t = OxmlElement("w:t"); t.text = "1"; r4.append(t)
    r5 = OxmlElement("w:r"); r5.append(el("w:fldChar", **{"w:fldCharType": "end"}))
    for r in (r1, r2, r3, r4, r5):
        run_parent.append(r)


def dau_chan_trang(d, ma, ten):
    for s in d.sections:
        s.different_first_page_header_footer = True
        h = s.header
        h.is_linked_to_previous = False
        p = h.paragraphs[0] if h.paragraphs else h.add_paragraph()
        p.text = ""
        p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        r = p.add_run(f"Datahub · {ma} · {ten}")
        r.font.size = Pt(10); r.font.italic = True; r.font.color.rgb = RGBColor(0x59, 0x59, 0x59)
        pPr = p._p.get_or_add_pPr()
        bd = el("w:pBdr"); bd.append(el("w:bottom", **{"w:val": "single", "w:sz": 4, "w:space": 1, "w:color": VIEN}))
        pPr.append(bd)
        f = s.footer
        f.is_linked_to_previous = False
        p = f.paragraphs[0] if f.paragraphs else f.add_paragraph()
        p.text = ""
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run("Trang "); r.font.size = Pt(10)
        truong(p._p, "PAGE")
        r = p.add_run(" / "); r.font.size = Pt(10)
        truong(p._p, "NUMPAGES")
        # trang bìa: đầu, chân trang rỗng
        for part in (s.first_page_header, s.first_page_footer):
            part.is_linked_to_previous = False


def cap_nhat_truong(d):
    st = d.settings.element
    for old in st.findall(qn("w:updateFields")):
        st.remove(old)
    st.append(el("w:updateFields", **{"w:val": "true"}))


def dien_so_trang(path, txt):
    """Điền số trang LibreOffice đã tính vào giá trị hiển thị của các trường PAGEREF."""
    so = []
    for line in open(txt, encoding="utf-8").read().splitlines():
        line = line.rstrip()
        if "\t" in line and line.rsplit("\t", 1)[1].strip().isdigit():
            so.append(line.rsplit("\t", 1)[1].strip())
    d = docx.Document(path)
    i = 0
    for h in d.element.body.iter(qn("w:hyperlink")):
        a = h.get(qn("w:anchor")) or ""
        if not a.startswith("_Toc") or i >= len(so):
            continue
        ts = h.findall(".//" + qn("w:t"))
        if ts:
            ts[-1].text = so[i]
        i += 1
    d.save(path)
    print(f"  mục lục: {i} mục có số trang")


def co_khoi_ma(d):
    """Khối mã: căn trái, không giãn chữ; dòng dài (wireframe) thu nhỏ cỡ chữ để không xuống dòng trong 16 cm."""
    from docx.shared import Pt
    from docx.enum.text import WD_ALIGN_PARAGRAPH
    for p in d.paragraphs:
        if p.style is None or p.style.name != "Source Code":
            continue
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        dong, cur = [], ""
        for r in p.runs:
            for node in r._r:
                if node.tag == qn("w:br"):
                    dong.append(cur)
                    cur = ""
                elif node.tag == qn("w:t"):
                    cur += node.text or ""
                elif node.tag == qn("w:tab"):
                    cur += "    "
        dong.append(cur)
        dai = max((len(x) for x in dong), default=0)
        if dai <= 80:
            continue
        # chữ đơn cách rộng khoảng 0,6 em; vùng chữ 16 cm = 453 pt
        co = max(5.5, min(9.5, 453 / (dai * 0.6)))
        for r in p.runs:
            r.font.size = Pt(round(co * 2) / 2)


def main():
    if sys.argv[1] == "--so-trang":
        dien_so_trang(sys.argv[2], sys.argv[3])
        return
    path, ma, ten = sys.argv[1], sys.argv[2], sys.argv[3]
    d = docx.Document(path)
    STYLE_IDS.update(s.style_id for s in d.styles)
    chuyen_muc_luc(d)
    dinh_dang_bang(d)
    co_khoi_ma(d)
    dau_chan_trang(d, ma, ten)
    cap_nhat_truong(d)
    d.core_properties.title = ten
    d.core_properties.subject = ma
    d.core_properties.author = "Nhóm thiết kế Datahub"
    d.save(path)


if __name__ == "__main__":
    main()
