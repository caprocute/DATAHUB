#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-06-01…18 (D03-06-PH06, mục "Bản hi-fi" của từng màn) và bốn biến thể (03b, 05b, 06b, 11b).

Chạy: python3 gen_hifi.py; chụp ảnh: node shot.js
Dữ liệu là giả định của tỉnh thí điểm T68: người, số định danh, tổ chức đều là dữ liệu giả; số định danh luôn che.
Menu theo D03-06-00 mục 21 (Dữ liệu dùng chung › Dữ liệu chủ); hàng tab phụ theo D03-06-PH06 mục 4.
Phong cách Liquid Glass của D03-05: kính chỉ ở lớp điều hướng và lớp nổi, nội dung nền đặc.
"""
import pathlib

OUT = pathlib.Path(__file__).parent

NAV = [("|Dữ liệu dùng chung", None), ("Danh mục dùng chung", "dm"), ("Đồng bộ danh mục quốc gia", "ds"),
       ("Dữ liệu chủ", "mdm"), ("Chất lượng dữ liệu", "cl"), ("Quyền riêng tư", "qr"), ("|Cá nhân", None), ("Việc của tôi", "vc")]
BADGE = {"mdm": "<span class='tag t-warn'>3</span>", "vc": "<span class='tag t-info'>5</span>"}
TABS = ["Tổng quan", "Bản ghi", "Ứng viên", "Hàng đợi", "Cấu hình", "Job", "Độ chính xác", "Đồng bộ QG", "Cung cấp", "Yêu cầu chủ thể", "Nhật ký"]
TABON = {"01": 0, "02": 1, "03": 1, "03b": 1, "06": 1, "06b": 1, "11": 2, "11b": 2, "04": 3, "05": 3, "05b": 3, "07": 4, "08": 4, "09": 4, "10": 4,
         "17": 4, "12": 5, "13": 6, "14": 7, "15": 8, "16": 9, "18": 10}


def shell(code, title, crumb, body, extra=""):
    nav = ""
    for n, c in NAV:
        if n.startswith("|"):
            nav += f'<div class="grp">{n[1:]}</div>'
            continue
        on = (c == "vc" and code in ("05",) and False) or c == "mdm"
        nav += f'<a class="{"on" if on else ""}" href="#">{n} {BADGE.get(c, "")}</a>'
    tb = '<div class="subtabs" role="tablist" style="flex-wrap:wrap">' + "".join(
        f'<span class="{"on" if i == TABON[code] else ""}">{t}</span>' for i, t in enumerate(TABS)) + "</div>"
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-06-{code} · {title}</title><link rel="stylesheet" href="hifi.css"></head><body>
<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Điều hành</div><div class="search">Tìm bản ghi vàng, nguồn, job, yêu cầu…  ⌘K</div><div class="sp"></div>
<span class="tray">⟳ 2 tác vụ nền</span><span class="tray">T68 · Tỉnh thí điểm</span><div class="avatar">LT</div></header>
<nav class="side" aria-label="Điều hướng chính">{nav}</nav>
<main><div class="crumb">{crumb}</div>{tb}{body}</main></div>{extra}<div class="hint">Bản hi-fi minh họa · D03-06-PH06 · UI-06-{code} · dữ liệu giả định T68</div></body></html>"""


def table(head, data, label="", cls=None):
    th = "".join(f"<th>{h}</th>" for h in head)
    tr = ""
    for i, r in enumerate(data):
        c = f' class="{cls[i]}"' if cls and cls[i] else ""
        tr += f"<tr{c}>" + "".join(f"<td>{x}</td>" for x in r) + "</tr>"
    return f'<table aria-label="{label}"><thead><tr>{th}</tr></thead><tbody>{tr}</tbody></table>'


def tag(kind, text):
    return f"<span class='tag t-{kind}'>{text}</span>"


def tabs(items, on):
    return '<div class="tabs" role="tablist">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def facets(items, on=0):
    return '<div class="facets">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def kpi(a, b, d="", cls=""):
    return f'<div class="kpi {cls}"><span>{a}</span><b>{b}</b><small>{d}</small></div>'


def kpis(items, n=None):
    n = n or len(items)
    return f'<div class="kpis" style="--n:{n}">' + "".join(items) + "</div>"


def foot(text="Hiển thị 1–20"):
    return f'<div class="foot" style="justify-content:space-between"><span class="muted">{text}</span><span class="muted">‹ 1 2 3 › · 20 / trang</span></div>'


def drawer(title, inner, width=480):
    return f'<div class="drawer" role="dialog" aria-label="{title}" style="width:{width}px"><h3 style="margin:0 0 10px">{title}</h3>{inner}</div>'


def mono(t):
    return f"<span class='mono'>{t}</span>"


def card(title, inner, style=""):
    return f'<div class="card" style="{style}"><h3 style="margin:0 0 8px;font-size:15px">{title}</h3>{inner}</div>'


def head(title, *right):
    return f'<div class="head"><h1>{title}</h1><div class="sp"></div>{"".join(right)}</div>'


def btn(t, k=""):
    return f'<span class="btn {k}">{t}</span>'


def inp(t, w=""):
    return f'<span class="input" style="{w}">{t}</span>'


def conf(v):
    c = "h" if v >= 0.9 else ("m" if v >= 0.7 else "l")
    t = {"h": "cao", "m": "TB", "l": "thấp"}[c]
    return f'<span style="white-space:nowrap"><span class="dot {c}"></span>{str(v).replace(".", ",")} <span class="muted">{t}</span></span>'


def src(code, kind):
    return tag({"NAT": "nat", "SEC": "com", "REL": "hyb", "OTH": "mute", "MAN": "warn", "FILE": "mute"}[kind], code)


def banner(kind, text, action=""):
    ico = "✕" if kind == "e" else "⚠"
    a = f'<span class="sp"></span>{btn(action)}' if action else ""
    return f'<div class="banner {kind}" role="alert"><span>{ico}</span><span>{text}</span>{a}</div>'


def line_chart(series, w=640, h=150, thr=None, labels=("T9", "T10", "T11")):
    out = f'<svg viewBox="0 0 {w} {h}" class="line" role="img" aria-label="Xu hướng">'
    if thr is not None:
        out += f'<line x1="0" y1="{thr}" x2="{w}" y2="{thr}" stroke="#a11a1a" stroke-dasharray="4 4"/><text x="{w-4}" y="{thr-4}" font-size="11" text-anchor="end" fill="#a11a1a">ngưỡng 5%</text>'
    for pts, col, dash in series:
        out += f'<polyline fill="none" stroke="{col}" stroke-width="2.2" {"stroke-dasharray=%r" % dash if dash else ""} points="{pts}"/>'
    return out + "</svg>"


def pts(vals, w=640, h=150, mx=None, lo=None, hi=None):
    lo = min(vals) * 0.9 if lo is None else lo
    hi = max(vals) * 1.05 if hi is None else hi
    n = len(vals) - 1
    return " ".join(f"{int(i * w / n)},{int(h - 10 - (v - lo) / (hi - lo) * (h - 24))}" for i, v in enumerate(vals))


OK, WA, ER, IN, MU = "ok", "warn", "err", "info", "mute"
P = {}

# ---------------------------------------------------------------- 01 Tổng quan
trend_a = pts([78, 80, 81, 83, 84, 84, 85, 86, 87, 87, 88, 88], mx=100)
trend_d = pts([9.2, 9.0, 8.6, 8.1, 7.7, 7.4, 7.0, 6.6, 6.4, 6.1, 5.9, 5.6], mx=12)
P["01"] = ("Tổng quan dữ liệu chủ", "Dữ liệu dùng chung › Dữ liệu chủ › Tổng quan", f"""
{banner("e", "Phát hiện 2 bản ghi vàng cùng số định danh. Cần xử lý ngay.", "Xem 2 bản ghi")}
{banner("w", "Đồng bộ quốc gia đang chạy, tỷ lệ lệch lượt gần nhất 0,4% (ngưỡng tạm dừng 5%).")}
{head("Tổng quan dữ liệu chủ", inp("Domain: Tất cả ▾"), '<span class="seg"><span>24 giờ</span><span>7 ngày</span><span class="on">30 ngày</span><span>90 ngày</span></span>', '<span class="muted">Số liệu cập nhật 14:02</span>', btn("⟳"))}
{kpis([
    kpi("Bản ghi vàng", "1.623.590", "CITIZEN 1.186.420 · ORGANIZATION 24.870 · ADDRESS 412.300"),
    kpi("Tỷ lệ tự động 30 ngày", "88%", "● Đạt (xanh khi ≥ 85%) · vàng 80–85% · đỏ dưới 80%", ""),
    kpi("Hàng đợi mở", "142", "⚠ 3 mục quá hạn SLA 7 ngày"),
    kpi("Precision · Recall", "99,93% · 98,4%", "Lần đánh giá 01/11/2026 · bộ quy tắc v4"),
    kpi("Đồng bộ quốc gia", "Đang chạy", "Lệch 0,4% · lần cuối 06:00"),
], 5)}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 420px">
{card("Xu hướng 12 tuần: tỷ lệ tự động và tỷ lệ trùng", line_chart([(trend_a, "#0b5cd5", ""), (trend_d, "#a8320f", "6 3")]) + '<div class="legend"><span><i style="background:#0b5cd5"></i>Tỷ lệ tự động (%)</span><span><i style="background:#a8320f"></i>Tỷ lệ trùng còn lại (%, nét đứt)</span><span style="flex:1"></span><span>Xem dạng bảng</span></div>')}
{card("Hàng đợi theo lý do", "".join(f'<div class="hbar"><span>{n}</span><i style="width:{w}%"></i><span class="num">{c}</span></div>' for n, w, c in [("Có thể khớp", 100, 71), ("Nhiều ứng viên", 52, 37), ("Thiếu thuộc tính", 28, 20), ("Xung đột nghiêm trọng", 10, 8), ("Mâu thuẫn định danh", 6, 6)]))}
</div>
{card("Chất lượng theo nguồn (30 ngày)", table(["Nguồn", "Loại", "Bản ghi nhận", "Từ chối", "Định danh sai", "Trùng", "Đóng góp thuộc tính", "Việc cần làm"], [
    [mono("QG-DANCU"), src("NAT", "NAT"), "412.806", "0,1%", "0,0%", "—", "Tên, ngày sinh, số định danh", "—"],
    [mono("HT-YTE"), src("REL", "REL"), "538.211", "1,9%", tag(WA, "3,4%"), "6,2%", "Điện thoại, địa chỉ", tag(WA, "Làm việc với Sở Y tế")],
    [mono("HT-TUPHAP"), src("SEC", "SEC"), "251.040", "0,7%", "0,6%", "2,1%", "Quan hệ, nơi sinh", "—"],
    [mono("HT-BHXH"), src("SEC", "SEC"), "389.552", tag(ER, "6,8%"), tag(ER, "5,1%"), "4,0%", "Mã BHXH, địa chỉ", tag(ER, "Nguồn cần xử lý")],
    [mono("TEP-LO"), src("FILE", "FILE"), "18.400", "2,2%", "1,0%", "9,5%", "Nhiều thuộc tính", "—"]], "Chất lượng theo nguồn"), "margin-top:12px")}""")

# ---------------------------------------------------------------- 02 Tìm kiếm bản ghi vàng
srows = [
    ['☑', mono("0193a0c2…5e6f"), "Nguyễn Văn An", "<span class='mk'>*********345</span>", "12/03/1985", "Phường Hòa Cường, Q. Hải Châu", "3", conf(0.96), tag(OK, "● Hoạt động")],
    ['☑', mono("0193a1f7…91bc"), "Nguyễn Văn An", "<span class='mk'>*********345</span>", "12/03/1985", "P. Hòa Cường, Hải Châu", "1", conf(0.82), tag(OK, "● Hoạt động")],
    ['☐', mono("0193a2d0…07aa"), "Nguyễn Văn Ân", "<span class='mk'>*********871</span>", "1985", "Xã Hòa Châu, H. Hòa Vang", "2", conf(0.74), tag(OK, "● Hoạt động")],
    ['☐', mono("0193a3b9…c410"), "Nguyễn Văn An", "<span class='mk'>*********012</span>", "03/07/1992", "P. An Hải Bắc, Q. Sơn Trà", "4", conf(0.93), tag(WA, "◐ Khóa chờ duyệt")],
    ['☐', mono("0193a44e…12d3"), "Nguyễn V. An", "—", "12/03/1985", "—", "1", conf(0.55), tag(MU, "○ Đã hợp nhất")],
]
P["02"] = ("Tìm kiếm bản ghi vàng", "Dữ liệu dùng chung › Dữ liệu chủ › Bản ghi › CITIZEN", f"""
{head("Bản ghi vàng", '<span class="seg"><span class="on">CITIZEN</span><span>ORGANIZATION</span><span>ADDRESS</span></span>', btn("Tra theo ID nguồn"), btn("Hợp nhất 2 bản ghi đã chọn", "pri"))}
<div class="card"><div class="toolbar"><span class="seg"><span class="on">Họ tên</span><span>Số định danh</span><span>ID vàng</span><span>ID nguồn</span></span>{inp("Nguyễn Văn An", "min-width:230px")}{inp("Ngày hoặc năm sinh: 1985", "min-width:170px")}{inp("Xã, phường ▾")}{inp("Trạng thái: Hoạt động ▾")}{btn("Tìm", "pri")}<div style="flex:1"></div><span class="muted">Mục đích truy cập: Giải quyết khiếu nại ▾</span></div>
<div class="alert i" style="margin:0 0 10px">ⓘ Họ tên cần đi kèm ngày sinh, năm sinh hoặc xã (ERR-06-040). Giá trị Nhạy cảm luôn che; xem đầy đủ cần quyền bỏ che và lý do. Truy cập được ghi nhật ký.</div>
{table(["", "ID vàng", "Họ tên", "Số định danh", "Ngày sinh", "Địa chỉ", "Nguồn", "Tin cậy", "Trạng thái"], srows, "Kết quả tìm kiếm")}
<div class="alert w" style="margin:10px 0 0">⚠ Anh/chị đã xem 74 bản ghi trong 10 phút. Truy cập hàng loạt vượt 100 bản ghi cần phê duyệt.</div>{foot("5 kết quả · đã chọn 2")}</div>""")

# ---------------------------------------------------------------- 03 Chi tiết bản ghi vàng (Thuộc tính + nguồn gốc)
attr_rows = [
    ["Số định danh", "<span class='mk'>*********345</span> " + tag(IN, "Hiện…"), tag(MU, "SENSITIVE"), src("QG-DANCU", "NAT"), "NATIONAL_AUTHORITY", conf(1.0), "26/06/2026", "⋯"],
    ["Họ tên", "Nguyễn Văn An", tag(IN, "INTERNAL"), src("QG-DANCU", "NAT"), "NATIONAL_AUTHORITY", conf(1.0), "15/06/2026", "⋯"],
    ["Ngày sinh", "12/03/1985", tag(MU, "RESTRICTED"), src("QG-DANCU", "NAT"), "NATIONAL_AUTHORITY", conf(1.0), "15/06/2026", "⋯"],
    ["Điện thoại", "<span class='mk'>091*****78</span>", tag(MU, "SENSITIVE"), src("HT-YTE", "REL"), "MOST_RECENT", conf(0.75), "20/10/2026", "⋯"],
    ["Địa chỉ thường trú", "Số 15 Lê Duẩn, P. Hải Châu 1, Q. Hải Châu", tag(IN, "INTERNAL"), src("HT-BHXH", "SEC"), "SOURCE_PRIORITY", conf(0.88), "03/09/2026", "⋯"],
    ["Mã BHXH", "<span class='mk'>*******456</span>", tag(MU, "SENSITIVE"), src("HT-BHXH", "SEC"), "SOURCE_PRIORITY", conf(0.92), "03/09/2026", "⋯"],
    ["Nơi sinh", "Đà Nẵng", tag(IN, "INTERNAL"), src("HT-TUPHAP", "SEC"), "MOST_COMPLETE", conf(0.66), "11/08/2026", "⋯"],
]
gold_head = lambda tabon, extra="": f"""
<div class="chrome"><h1 style="white-space:nowrap">Nguyễn Văn An {tag(OK, "● Hoạt động")} <span class="muted" style="font-size:13px;font-weight:400">CITIZEN · v7 · tin cậy 0,96</span><span style="flex:1"></span>{btn("Sửa tay")}{btn("Hợp nhất…")}{btn("Tách…")}{btn("Hoàn tác")}{btn("Ngừng…", "danger")}</h1>
<div class="muted">ID vàng {mono("0193a0c2-5b1e-7c4a-9e0f-1b2d3c4a5e6f")} {btn("Sao chép")} · Đồng bộ quốc gia 25/11/2026 06:00 · 3 nguồn liên kết {extra}</div></div>
{tabs(["Thuộc tính", "Nguồn liên kết (3)", "Nguồn gốc", "Lịch sử (7)", "Thao tác (0)"], tabon)}"""
lineage = card("Nguồn gốc · Ngày sinh", """
<div class="muted" style="margin-bottom:6px">Giá trị hiện tại <b>12/03/1985</b> lấy từ <b>QG-DANCU</b> theo chiến lược <b>NATIONAL_AUTHORITY</b> (BR-06-003).</div>
<div class="grp-t">Giá trị theo từng nguồn đang liên kết</div>
""" + table(["Nguồn", "Giá trị", "Cập nhật nguồn", "Ghi chú"], [
    [src("QG-DANCU", "NAT"), "12/03/1985", "15/06/2026", tag(OK, "✓ đang dùng")],
    [src("HT-YTE", "REL"), "12/03/1986", "20/10/2026", tag(ER, "≠ khác")],
    [src("HT-BHXH", "SEC"), "12/03/1985", "03/09/2026", tag(OK, "✓ trùng")]], "Giá trị theo nguồn") + """
<div class="grp-t">Lịch sử giá trị</div><div class="vtl"><div><b>26/06/2026 08:00</b> · 1985-03-12 · QG-DANCU · ghi đè giá trị từ HT-YTE (mức 3) · thao tác <span class="mono">op-71f2</span></div><div><b>02/04/2026 10:12</b> · 1986-03-12 · HT-YTE · lần đầu nạp</div></div>
<div style="margin-top:8px">""" + btn("Đề nghị sửa tại nguồn HT-YTE") + "</div>", "")
P["03"] = ("Chi tiết bản ghi vàng", "Dữ liệu dùng chung › Dữ liệu chủ › CITIZEN › Nguyễn Văn An", gold_head(0) + f"""
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 370px"><div class="card">
{table(["Thuộc tính", "Giá trị", "Phân loại", "Nguồn", "Chiến lược thắng", "Tin cậy", "Cập nhật nguồn", ""], attr_rows, "Thuộc tính bản ghi vàng", ["", "", "", "", "", "", ""])}
<div class="muted" style="margin-top:8px">Chấm tin cậy: cao ≥ 0,9 · trung bình 0,7–0,9 · thấp dưới 0,7; luôn kèm số. Giá trị Nhạy cảm che theo PH-09; nút "Hiện…" yêu cầu quyền bỏ che và lý do, ghi nhật ký riêng.</div></div>
{lineage}</div>""")

# 03b: tab Nguồn gốc đầy đủ
P["03b"] = ("Nguồn gốc thuộc tính", "Dữ liệu dùng chung › Dữ liệu chủ › CITIZEN › Nguyễn Văn An › Nguồn gốc", gold_head(2) + f"""
<div class="grid2" style="grid-template-columns:240px minmax(0,1fr)"><div class="card tree"><div class="muted" style="margin-bottom:6px">Thuộc tính</div><div>Số định danh</div><div>Họ tên</div><div class="on">Ngày sinh · 2 giá trị</div><div>Điện thoại · 3 giá trị</div><div>Địa chỉ thường trú · 4</div><div>Mã BHXH</div><div>Nơi sinh</div></div>
<div><div class="card">{table(["Thời điểm đưa vào", "Giá trị trước", "Giá trị sau", "Nguồn · khóa nguồn", "Cập nhật nguồn", "Chiến lược", "Ghi chú", "Thao tác"], [
    ["26/06/2026 08:00", "12/03/1986", "<b>12/03/1985</b>", src("QG-DANCU", "NAT") + " <span class='mono'>…8812</span>", "15/06/2026", "NATIONAL_AUTHORITY", "Nguồn mức 1 ghi đè giá trị từ HT-YTE mức 3", mono("op-71f2")],
    ["02/04/2026 10:12", "—", "12/03/1986", src("HT-YTE", "REL") + " <span class='mono'>…0041</span>", "02/04/2026", "FIRST_VALUE", "Lần đầu nạp", mono("op-1a09")]], "Lineage ngày sinh")}</div>
<div class="card" style="margin-top:12px"><h3 style="margin:0 0 8px;font-size:15px">Giá trị hiện tại của từng nguồn đang liên kết</h3>{table(["Nguồn", "Giá trị", "Cập nhật", "So với giá trị vàng"], [[src("QG-DANCU", "NAT"), "12/03/1985", "15/06/2026", tag(OK, "✓ trùng")], [src("HT-YTE", "REL"), "12/03/1986", "20/10/2026", tag(ER, "≠ khác · đề nghị sửa tại nguồn")], [src("HT-BHXH", "SEC"), "12/03/1985", "03/09/2026", tag(OK, "✓ trùng")]], "Giá trị theo nguồn")}</div></div></div>""")

# ---------------------------------------------------------------- 04 Hàng đợi
qrows = [
    ["☐", tag(ER, "Cao 92"), "CITIZEN", "Mâu thuẫn định danh", "0,93", "Nguyễn Văn An · Nguyễn V. An", "9 ngày", tag(ER, "Quá hạn 2 ngày"), "—", tag(IN, "OPEN")],
    ["☐", tag(ER, "Cao 88"), "ORGANIZATION", "Xung đột nghiêm trọng", "0,91", "Cty TNHH Biển Xanh · Cty Biển Xanh", "8 ngày", tag(ER, "Quá hạn 1 ngày"), "Phạm T. Hoa", tag(IN, "ASSIGNED")],
    ["☐", tag(WA, "TB 61"), "CITIZEN", "Có thể khớp", "0,86", "Trần Thị Bích · Trần Thị Bích", "5 ngày", "còn 2 ngày", "Lê T. Thu (tôi)", tag(IN, "ASSIGNED")],
    ["☐", tag(WA, "TB 55"), "ADDRESS", "Nhiều ứng viên", "0,84", "15 Lê Duẩn · 15 Lê Duẩn, P. Hải Châu", "4 ngày", "còn 3 ngày", "—", tag(IN, "OPEN")],
    ["☐", tag(MU, "Thấp 30"), "CITIZEN", "Thiếu thuộc tính", "0,80", "Lê Văn Cường · Lê Văn Cương", "2 ngày", "còn 5 ngày", "—", tag(IN, "OPEN")],
    ["☐", tag(WA, "TB 70"), "CITIZEN", "Có thể khớp", "0,92", "Đỗ Minh Quân · Đỗ M. Quân", "6 ngày", "còn 1 ngày", "Lê T. Thu (tôi)", tag(WA, "PENDING_APPROVAL")],
]
P["04"] = ("Hàng đợi người quản lý dữ liệu", "Dữ liệu dùng chung › Dữ liệu chủ › Hàng đợi", f"""
{head("Hàng đợi người quản lý dữ liệu", btn("Nhận việc tiếp theo ⏎", "pri"), btn("Phân công…"))}
{kpis([kpi("Đang mở", "142", "ngưỡng cảnh báo 500"), kpi("Của tôi", "9", "1 chờ DA duyệt"), kpi("Quá hạn", "3", "⚠ SLA 7 ngày"), kpi("Đã xử lý hôm nay", "37", "trung bình 44 giây/mục")], 4)}
<div class="card"><div class="toolbar">{facets(["Của tôi 9", "Chưa nhận 118", "Quá hạn 3", "Chờ duyệt 4", "Tất cả 142"], 0)}<div style="flex:1"></div>{inp("Domain ▾")}{inp("Lý do ▾")}{inp("Mức rủi ro ▾")}{inp("Sắp xếp: ưu tiên giảm ▾")}</div>
{table(["", "Ưu tiên", "Domain", "Lý do", "Điểm", "Cặp bản ghi", "Tuổi", "SLA", "Người nhận", "Trạng thái"], qrows, "Hàng đợi")}
{foot("1–6 / 142 · Phím J K di chuyển, Enter mở, N nhận việc tiếp theo")}</div>""")


# ---------------------------------------------------------------- 05 So sánh và quyết định
def compare(variant=""):
    conflict = variant == "b"
    r = [
        ("Số định danh", "<span class='mk'>*********345</span>" if not conflict else "<span class='mk'>*********345</span>", "<span class='mk'>*********871</span>" if conflict else "<span class='mk'>— (thiếu)</span>", "Khác" if conflict else "Thiếu", "lv-diff" if conflict else "lv-miss", "0,00" if conflict else "—"),
        ("Họ tên", "Nguyễn Văn An", "Nguyễn V. An", "Gần giống cao", "lv-hi", "0,94"),
        ("Ngày sinh", "12/03/1985", "12/03/1985", "Trùng", "lv-exact", "1,00"),
        ("Điện thoại", "<span class='mk'>091*****78</span>", "<span class='mk'>091*****78</span>", "Trùng", "lv-exact", "1,00"),
        ("Địa chỉ", "Số 15 Lê Duẩn, P. Hải Châu 1, Q. Hải Châu", "15 Lê Duẩn, P. Hải Châu, Đà Nẵng", "Gần giống thấp", "lv-lo", "0,72"),
        ("Nơi sinh", "Đà Nẵng", "Quảng Nam", "Khác", "lv-diff", "0,00"),
        ("Tên cha, mẹ", "—", "Nguyễn Văn Bảy", "Thiếu", "lv-miss", "—"),
    ]
    rows = [[a, f"{b}", f"{c}", d, e] for a, b, c, d, cl, e in r]
    cls = [x[4] for x in r]
    body = ""
    for i, row in enumerate(rows):
        body += f'<tr class="{cls[i]}"><td>{row[0]}</td><td class="c">{row[1]}</td><td class="c">{row[2]}</td><td>{row[3]}</td><td class="num">{row[4]}</td></tr>'
    tbl = f'<table aria-label="So sánh hai bản ghi"><thead><tr><th>Thuộc tính</th><th>Bản ghi A · QG-DANCU, HT-BHXH</th><th>Bản ghi B · HT-YTE</th><th>Mức so sánh</th><th>Điểm</th></tr></thead><tbody>{body}</tbody></table>'
    score = "0,91"
    sb = f'<div class="scorebar"><div><div class="muted">Điểm tổng</div><div class="big">{score}</div></div><div class="meter" aria-label="Điểm 0,91 trong vùng xem xét"><i style="left:82%"></i><u style="left:60%">0,80 xem xét</u><u style="left:90%">0,95 tự hợp nhất</u></div><div class="muted" style="width:260px">Vùng xem xét 0,80–0,95 · Có thể khớp · bộ quy tắc v4 · rủi ro {tag(WA, "Cao")}</div></div>'
    left = f'''{tag(ER, "✕ Hai số định danh khác nhau") + " " + '<span class="muted">Không được hợp nhất (BR-06-006).</span>' if conflict else ""}'''
    ctx = card("Ngữ cảnh", """<div class="grp-t" style="margin-top:0">Bản ghi nguồn của A</div><div class="muted">QG-DANCU <span class="mono">…8812</span> · 15/06/2026<br>HT-BHXH <span class="mono">…3390</span> · 03/09/2026</div>
<div class="grp-t">Bản ghi nguồn của B</div><div class="muted">HT-YTE <span class="mono">…0041</span> · 20/10/2026</div>
<div class="grp-t">Cảnh báo chuẩn hóa</div><div>""" + tag(WA, "ADMIN_UNIT_CONVERTED") + """</div><div class="grp-t">Quyết định tương tự trước đây</div><div class="muted">12 cặp họ tên, ngày sinh giống · 11 Khớp, 1 Khác</div>""", "")
    reasons = "".join(f'<span class="chip">{t}</span>' for t in ["Trùng ngày sinh, điện thoại", "Cùng người, viết tắt tên", "Khác nơi sinh, giữ hai bản ghi", "Cần xác minh thêm"])
    if conflict:
        btns = f'{btn("Cùng một thực thể", "dis wide")}<span class="muted" style="max-width:300px">Hai bản ghi có số định danh khác nhau nên không được hợp nhất. Kiểm tra lại dữ liệu nguồn.</span>{btn("Khác nhau", "wide")}{btn("Hoãn", "wide")}'
    else:
        btns = f'{btn("Cùng một thực thể", "ok wide")}{btn("Khác nhau", "wide")}{btn("Hoãn", "wide")}<span class="muted">Rủi ro cao: sau khi chọn "Cùng một thực thể", mục chuyển DA duyệt (bốn mắt).</span>'
    return f"""
<div class="head"><h1>So sánh và quyết định</h1><span class="tag t-info">ASSIGNED · giữ còn 24 phút</span><div class="sp"></div><span class="muted">Mục 3 / 9 của tôi · còn 142 trong hàng đợi</span>{btn("‹")}{btn("›")}</div>
{sb}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 330px"><div class="card">{tbl}<div class="muted" style="margin-top:6px">Màu nền chỉ là phụ: mỗi dòng đều có chữ mức so sánh. {left}</div></div>{ctx}</div>
<div class="decide"><div style="flex:1"><div class="field" style="margin:0"><label>Lý do (bắt buộc, tối thiểu 20 ký tự) · 0 / 500</label><div class="input" style="width:100%;height:46px;align-items:flex-start;padding-top:6px">Nhập lý do hoặc chọn mẫu câu…</div></div><div style="margin-top:6px">{reasons}</div></div><div style="display:flex;flex-direction:column;gap:6px">{btns}</div></div>"""


P["05"] = ("So sánh và quyết định", "Dữ liệu dùng chung › Dữ liệu chủ › Hàng đợi › Mục #QI-20261126-0042", compare())
P["05b"] = ("So sánh, định danh khác nhau", "Dữ liệu dùng chung › Dữ liệu chủ › Hàng đợi › Mục #QI-20261126-0043", compare("b"))

# ---------------------------------------------------------------- 06 Hợp nhất, tách
steps = lambda on, names: '<div class="steps">' + "".join(f'<div class="{"on" if i == on else ("done" if i < on else "")}">{"✓ " if i < on else ""}{i + 1}. {n}</div>' for i, n in enumerate(names)) + "</div>"
P["06"] = ("Hợp nhất thủ công", "Dữ liệu dùng chung › Dữ liệu chủ › CITIZEN › Nguyễn Văn An › Hợp nhất", f"""
{head("Hợp nhất bản ghi vàng", btn("Hủy"), btn("‹ Quay lại"), btn("Gửi duyệt ›", "pri"))}
{steps(2, ["Chọn bản ghi", "Chọn bản sống sót", "Giá trị từng thuộc tính", "Xem trước và lý do"])}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 340px"><div class="card"><div class="muted" style="margin-bottom:8px">Bản sống sót: <b>0193a0c2…5e6f</b> (3 liên kết). Với thuộc tính xung đột, chọn giá trị giữ lại; mặc định theo quy tắc sống sót.</div>
{table(["Thuộc tính", "Sống sót (A)", "Bị gộp (B)", "Giá trị sau hợp nhất", "Lý do chọn"], [
    ["Họ tên", "Nguyễn Văn An", "Nguyễn V. An", "<b>Nguyễn Văn An</b>", "NATIONAL_AUTHORITY"],
    ["Ngày sinh", "12/03/1985", "12/03/1985", "12/03/1985", "Trùng"],
    ["Điện thoại", "<span class='mk'>091*****78</span>", "<span class='mk'>091*****90</span>", "<span class='mk'>091*****90</span>", "MOST_RECENT"],
    ["Địa chỉ", "Số 15 Lê Duẩn, P. Hải Châu 1", "15 Lê Duẩn, P. Hải Châu", "<b>Số 15 Lê Duẩn, P. Hải Châu 1</b> ◉ A ○ B", "Ghi đè tay (có lý do)"],
    ["Nơi sinh", "Đà Nẵng", "Quảng Nam", "Đà Nẵng ○ A ◉ B", tag(WA, "Xung đột: chọn")]], "Giá trị sau hợp nhất", ["", "", "", "d-chg", "d-chg"])}</div>
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Xem trước tác động</h3><div class="dl" style="grid-template-columns:150px 1fr"><dt>Liên kết chuyển</dt><dd>1 (HT-YTE …0041)</dd><dt>Thuộc tính đổi</dt><dd>2 trên 9</dd><dt>Mã định danh</dt><dd>{tag(OK, "✓ Không xung đột")}</dd><dt>Rủi ro</dt><dd>{tag(WA, "Cao")} · có thuộc tính quan trọng khác nhau (BR-06-019)</dd><dt>Duyệt</dt><dd>Cần DA khác người đề nghị</dd><dt>HTTT sẽ nhận</dt><dd>EVT golden.merged; ID cũ chuyển hướng</dd></div><div class="alert i" style="margin:10px 0 0">ⓘ Hai bản ghi sẽ bị khóa tới khi DA duyệt (ERR-06-031 nếu có thao tác khác).</div></div></div>""")

P["06b"] = ("Tách bản ghi vàng", "Dữ liệu dùng chung › Dữ liệu chủ › CITIZEN › Nguyễn Văn An › Tách", f"""
{head("Tách bản ghi vàng", btn("Hủy"), btn("Gửi duyệt ›", "pri"))}
{steps(1, ["Chọn bản ghi", "Phân bổ liên kết", "Xem trước và lý do"])}
<div class="alert i">ⓘ Gợi ý theo bản ghi vàng cũ: HT-YTE …0041 trước đây thuộc bản ghi 0193a44e…12d3 (đã hợp nhất ngày 14/10/2026). Mỗi liên kết thuộc đúng một nhóm.</div>
<div class="grid-2e"><div class="grp-box"><b>Nhóm 1 · ở lại bản ghi gốc</b> <span class="muted">0193a0c2…5e6f</span>
<div class="node2 on" style="margin-top:8px"><b>QG-DANCU</b> <span class="mono">…8812</span><br><span class="muted">Nguyễn Văn An · 12/03/1985 · 15/06/2026</span></div>
<div class="node2"><b>HT-BHXH</b> <span class="mono">…3390</span><br><span class="muted">Nguyễn Văn An · 12/03/1985 · 03/09/2026</span></div></div>
<div class="grp-box b"><b>Nhóm 2 · tạo hoặc khôi phục bản ghi</b> <span class="muted">khôi phục 0193a44e…12d3</span>
<div class="node2" style="margin-top:8px"><b>HT-YTE</b> <span class="mono">…0041</span><br><span class="muted">Nguyễn Văn Ân · 12/03/1986 · 20/10/2026</span></div>
<div class="muted" style="margin-top:10px">Kéo thả hoặc dùng nút "Chuyển sang nhóm" cho từng liên kết.</div></div></div>
<div class="card" style="margin-top:12px"><div class="field"><label>Lý do (bắt buộc, tối thiểu 20 ký tự)</label><div class="input" style="height:44px;align-items:flex-start;padding-top:6px;width:100%">Hai người khác nhau bị trộn do trùng họ tên, kiểm tra CCCD khác nhau.</div></div>
<div class="dl" style="grid-template-columns:150px 1fr 150px 1fr"><dt>Số nhóm</dt><dd>2</dd><dt>Duyệt</dt><dd>Cần DA duyệt (bản ghi có 3 liên kết, BR-06-019)</dd><dt>Ghi nhận</dt><dd>Ghi liên kết phủ định giữa hai nhóm (BR-06-023)</dd><dt>Sự kiện</dt><dd>golden.split</dd></div></div>""")

# ---------------------------------------------------------------- 07 Mô hình domain
P["07"] = ("Mô hình domain", "Dữ liệu dùng chung › Dữ liệu chủ › Cấu hình › Domain", f"""
{banner("w", "Phiên bản 4 đang chờ duyệt (người gửi: Lê Thị Thu). Người gửi không được tự duyệt (ERR-06-005).")}
{head("Mô hình domain", btn("Nạp gói domain nền"), btn("+ Tạo domain"), btn("Gửi duyệt", "pri"))}
<div class="grid2" style="grid-template-columns:260px minmax(0,1fr)"><div class="card tree"><div class="muted" style="margin-bottom:6px">Domain</div>
<div class="on">CITIZEN {tag(OK, "ACTIVE")}<br><span class="muted">v3 hiệu lực · v4 chờ duyệt</span></div><div>ORGANIZATION {tag(OK, "ACTIVE")}<br><span class="muted">v2 hiệu lực</span></div><div>ADDRESS {tag(OK, "ACTIVE")}<br><span class="muted">v1 hiệu lực</span></div><div class="muted" style="margin-top:10px">Domain khác (tỉnh tự tạo)</div><div>CAN-BO {tag(MU, "DRAFT")}</div></div>
<div class="card">{tabs(["Thuộc tính", "Khóa định danh", "Phiên bản", "So sánh v3 → v4"], 0)}
<div class="row" style="margin-bottom:8px"><span class="muted">CITIZEN · Phiên bản 4 {tag(WA, "PENDING_APPROVAL")} · tương thích {tag(OK, "NON_BREAKING")}</span><span style="flex:1"></span>{btn("+ Thêm thuộc tính")}</div>
{table(["Mã", "Nhãn", "Kiểu", "Bắt buộc", "Khóa", "Phân loại PH-09", "Chuẩn hóa", "Thay đổi v4", ""], [
    [mono("nationalId"), "Số định danh", "IDENTIFIER", "Có", "CCCD_12 · xác định", tag(MU, "SENSITIVE") + " " + tag(OK, "CONFIRMED"), "Số, kiểm tra", "—", "⋯"],
    [mono("fullName"), "Họ tên", "NAME_VN", "Có", "Đối sánh xác suất", tag(IN, "INTERNAL") + " " + tag(OK, "CONFIRMED"), "Bỏ dấu, viết tắt", "—", "⋯"],
    [mono("birthDate"), "Ngày sinh", "DATE", "Có", "Đối sánh", tag(MU, "RESTRICTED") + " " + tag(OK, "CONFIRMED"), "Độ chính xác ngày", "—", "⋯"],
    [mono("phone"), "Điện thoại", "PHONE", "Không", "—", tag(MU, "SENSITIVE") + " " + tag(OK, "CONFIRMED"), "E.164", "—", "⋯"],
    [mono("permAddress"), "Địa chỉ thường trú", "ADDRESS_REF", "Không", "Đối sánh", tag(IN, "INTERNAL") + " " + tag(OK, "CONFIRMED"), "ĐVHC PH-07", "—", "⋯"],
    [mono("ethnicity"), "Dân tộc", "CODE_REF", "Không", "—", tag(WA, "SENSITIVE") + " " + tag(WA, "PROPOSED"), "—", tag(OK, "+ Mới"), "⋯"],
    [mono("motherName"), "Họ tên mẹ", "NAME_VN", "Không", "—", tag(IN, "INTERNAL") + " " + tag(OK, "CONFIRMED"), "Bỏ dấu", tag(WA, "~ Đổi"), "⋯"]], "Thuộc tính của domain", ["", "", "", "", "", "d-add", "d-chg"])}
<div class="alert e" style="margin:10px 0 0">✕ Thuộc tính Dân tộc là dữ liệu cá nhân nhưng chưa có phân loại được PH-09 xác nhận (ERR-06-010). Chưa gửi duyệt được.</div></div></div>""")

# ---------------------------------------------------------------- 08 Nguồn và ưu tiên nguồn
P["08"] = ("Nguồn và ưu tiên nguồn", "Dữ liệu dùng chung › Dữ liệu chủ › Cấu hình › Nguồn", f"""
{head("Nguồn và ưu tiên nguồn", btn("+ Đăng ký nguồn"), btn("Đề nghị phê duyệt thứ tự", "pri"))}
<div class="card">{table(["Mã nguồn", "HTTT (PH-01)", "Loại nguồn", "Kênh nạp", "Domain", "Trạng thái", "Nạp 24 giờ", "Tỷ lệ từ chối"], [
    [mono("QG-DANCU"), "CSDL quốc gia về dân cư (qua PH-14)", src("NATIONAL_DB", "NAT"), "NATIONAL_SYNC", "CITIZEN", tag(OK, "● ACTIVE"), "12.480", "0,1%"],
    [mono("HT-BHXH"), "Hệ thống BHXH tỉnh", src("SECTOR_AUTHORITATIVE", "SEC"), "FLOW", "CITIZEN", tag(OK, "● ACTIVE"), "9.020", tag(ER, "6,8%")],
    [mono("HT-YTE"), "Hệ thống y tế cơ sở", src("SECTOR_RELATED", "REL"), "API", "CITIZEN", tag(OK, "● ACTIVE"), "14.300", "1,9%"],
    [mono("HT-DKKD"), "Đăng ký kinh doanh tỉnh", src("SECTOR_AUTHORITATIVE", "SEC"), "EVENT", "ORGANIZATION", tag(OK, "● ACTIVE"), "310", "0,3%"],
    [mono("TEP-LO"), "Nhập tệp lô", src("FILE_BATCH", "FILE"), "FILE", "CITIZEN", tag(MU, "◐ SUSPENDED"), "—", "—"]], "Danh sách nguồn")}</div>
<div class="card" style="margin-top:12px"><div class="row" style="margin-bottom:8px"><h3 style="margin:0;font-size:15px">Thứ tự ưu tiên cho CITIZEN (kéo thả hoặc nút ▲ ▼)</h3><span style="flex:1"></span>{tag(WA, "Bản nháp chưa gửi")}</div>
{table(["Thuộc tính", "Mức 1", "Mức 2", "Mức 3", "Mức 4"], [
    ["Họ tên, ngày sinh, số định danh", "⠿ QG-DANCU 🔒", "⠿ HT-BHXH", "⠿ HT-YTE", "⠿ TEP-LO"],
    ["Mã BHXH", "⠿ HT-BHXH", "⠿ QG-DANCU", "—", "—"],
    ["Điện thoại, địa chỉ", "⠿ HT-YTE", "⠿ HT-BHXH", "⠿ QG-DANCU", "⠿ TEP-LO"]], "Thứ tự ưu tiên")}
<div class="row" style="margin-top:10px"><div class="field"><label>Số văn bản phê duyệt *</label><div class="input cell-err">—</div><div class="muted" style="color:#a11a1a">Nhập số, ngày văn bản phê duyệt thứ tự ưu tiên nguồn.</div></div><div class="field"><label>Ngày văn bản *</label>{inp("dd/mm/yyyy")}</div><div class="field" style="flex:2"><label>Căn cứ, giải trình</label>{inp("Quyết định của Sở KH&CN theo ủy quyền của UBND tỉnh…")}</div></div>
<div class="alert i" style="margin:6px 0 0">ⓘ Xem trước tác động trên mẫu 10.000 bản ghi: <b>1.842</b> bản ghi dự kiến đổi giá trị · Điện thoại 1.210 · Địa chỉ 632. Nguồn quốc gia luôn mức 1 với thuộc tính thẩm quyền quốc gia (khóa).</div></div>""")

# ---------------------------------------------------------------- 09 Quy tắc đối sánh
hist = "".join(f'<i class="{"n" if i < 40 else ("r" if i < 80 else "a")}" style="height:{h}px"></i>' for i, h in enumerate(
    [4, 4, 5, 6, 8, 10, 12, 14, 18, 22, 26, 30, 34, 38, 40, 36, 30, 24, 18, 14, 10, 8, 7, 6, 5, 4, 3, 3, 2, 2, 2, 3, 3, 4, 4, 5, 5, 4, 4, 3,
     4, 5, 6, 8, 10, 12, 14, 18, 22, 28, 30, 26, 22, 18, 14, 10, 7, 5, 4, 3, 3, 2, 2, 2, 2, 2, 2, 3, 4, 6, 9, 14, 22, 36, 52, 70, 64, 44, 26, 12, 6, 3, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1]))
P["09"] = ("Quy tắc đối sánh", "Dữ liệu dùng chung › Dữ liệu chủ › Cấu hình › Quy tắc đối sánh", f"""
{banner("e", "Phiên bản 5 chưa đạt: precision 99,71%, recall 97,8%. Không thể gửi duyệt (BR-06-021).")}
{head("Quy tắc đối sánh · CITIZEN", '<span class="seg"><span>v3 SUPERSEDED</span><span>v4 ACTIVE</span><span class="on">v5 TESTING</span></span>', btn("Chạy thử trên mẫu"), btn("Đánh giá"), btn("Gửi duyệt", "dis"))}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 420px"><div>
<div class="card">{tabs(["Quy tắc", "Khóa gom nhóm", "Ngưỡng"], 0)}
{table(["#", "Loại", "Thuộc tính", "So sánh", "Trọng số", "Bật"], [
    ["1", tag(IN, "DETERMINISTIC"), "nationalId", "EXACT", "tuyệt đối", "◉"],
    ["2", tag(ER, "EXCLUSION"), "nationalId khác nhau", "EXACT", "loại trừ (không tắt được)", "🔒"],
    ["3", tag(MU, "PROBABILISTIC"), "fullName", "NAME_VN", "m 0,93 · u 0,004", "◉"],
    ["4", tag(MU, "PROBABILISTIC"), "birthDate", "DATE_TOLERANCE", "m 0,97 · u 0,010", "◉"],
    ["5", tag(MU, "PROBABILISTIC"), "permAddress", "ADMIN_UNIT, TRIGRAM", "m 0,80 · u 0,020", "◉"],
    ["6", tag(MU, "PROBABILISTIC"), "phone", "PHONE", "m 0,88 · u 0,001", "◉"]], "Quy tắc đối sánh")}
<div class="grp-t">Khóa gom nhóm (blocking)</div><div class="row"><span class="chip">fullName: 3 ký tự đầu + năm sinh · 41.200 nhóm · lớn nhất 612</span><span class="chip">Mã xã + ngày sinh · 18.900 nhóm · lớn nhất 3.040</span></div></div>
<div class="card" style="margin-top:12px"><h3 style="margin:0 0 8px;font-size:15px">Ngưỡng theo phân bố điểm 30 ngày</h3><div class="hist" style="height:90px">{hist}<span class="thr" style="left:80%"></span><span class="thr" style="left:50%;background:#7a5200"></span></div>
<div class="legend"><span><i style="background:#e3a0a0"></i>Khác biệt (tạo bản ghi mới)</span><span><i style="background:#f0c26a"></i>Xem xét (hàng đợi)</span><span><i style="background:#7fc8a0"></i>Tự hợp nhất</span></div>
<div class="row" style="margin-top:8px"><div class="field"><label>Ngưỡng xem xét: 0,80</label><div class="slider"><b style="left:50%"></b></div></div><div class="field"><label>Ngưỡng tự hợp nhất: 0,95</label><div class="slider"><b style="left:80%"></b></div></div></div>
<div class="muted">Ngưỡng tự hợp nhất phải từ 0,90 trở lên và cao hơn ngưỡng xem xét ít nhất 0,10. Ước tính hàng đợi: ~46 mục/ngày (11% số ứng viên).</div></div></div>
<div><div class="card"><h3 style="margin:0 0 8px;font-size:15px">Đánh giá trên tập nhãn LBL-2026-10 (12.400 cặp)</h3>{kpis([kpi("Precision", "99,71%", "✕ cần ≥ 99,9%", ""), kpi("Recall", "97,8%", "✕ cần ≥ 98%", "")], 2)}
{table(["", "Dự đoán Khớp", "Dự đoán Khác"], [["Thực Khớp", "6.071", tag(WA, "FN 136")], ["Thực Khác", tag(ER, "FP 18"), "6.175"]], "Ma trận nhầm lẫn")}<div class="muted" style="margin-top:6px">{btn("Xem cặp FP, FN")} {btn("So với v4")}</div></div>
<div class="card" style="margin-top:12px"><h3 style="margin:0 0 8px;font-size:15px">Chạy thử (mẫu 20.000 bản ghi)</h3><div class="dl" style="grid-template-columns:150px 1fr"><dt>Tự hợp nhất</dt><dd>9.240 (+3,1%)</dd><dt>Xem xét</dt><dd>2.210 (+0,4%)</dd><dt>Khác biệt</dt><dd>8.550</dd><dt>Cặp đổi kết luận</dt><dd>412 so với v4 ▸</dd></div></div></div></div>""")

# ---------------------------------------------------------------- 10 Quy tắc sống sót
P["10"] = ("Quy tắc sống sót", "Dữ liệu dùng chung › Dữ liệu chủ › Cấu hình › Sống sót", f"""
{head("Quy tắc sống sót · CITIZEN", tag(WA, "Bản nháp v6"), btn("Xem trước tác động"), btn("Gửi duyệt", "pri"))}
<div class="card">{table(["Thuộc tính", "Chiến lược", "Tham số", "Thẩm quyền quốc gia", "Thay đổi", "Tác động ước tính"], [
    ["Số định danh", "NATIONAL_AUTHORITY 🔒", "QG-DANCU", "Có", "—", "0"],
    ["Họ tên", "NATIONAL_AUTHORITY 🔒", "QG-DANCU", "Có", "—", "0"],
    ["Ngày sinh", "NATIONAL_AUTHORITY 🔒", "QG-DANCU", "Có", "—", "0"],
    ["Điện thoại", "MOST_RECENT ▾", "Bỏ giá trị rỗng", "Không", tag(OK, "đổi từ SOURCE_PRIORITY"), "1.210"],
    ["Địa chỉ thường trú", "SOURCE_PRIORITY ▾", "Theo bảng ưu tiên nguồn", "Không", "—", "0"],
    ["Mã BHXH", "SOURCE_PRIORITY ▾", "HT-BHXH mức 1", "Không", "—", "0"],
    ["Nơi sinh", "MOST_COMPLETE ▾", "—", "Không", "—", "0"],
    ["Ghi chú", "FIRST_VALUE ▾", "—", "Không", "—", "0"]], "Chiến lược sống sót")}
<div class="muted" style="margin-top:6px">Thuộc tính thẩm quyền quốc gia khóa chiến lược, không chọn MANUAL_OVERRIDE (BR-06-025).</div></div>
<div class="grid-2e" style="margin-top:12px">{card("Xem trước tác động trên mẫu 10.000 bản ghi", '<div class="dl" style="grid-template-columns:170px 1fr"><dt>Bản ghi đổi giá trị</dt><dd><b>1.210</b> (12,1%)</dd><dt>Thuộc tính đổi</dt><dd>Điện thoại 1.210</dd><dt>Ví dụ</dt><dd><del>091*****78</del> → <ins>091*****90</ins></dd><dt>Áp lại hàng loạt</dt><dd>Quá 1.000 bản ghi: tạo job chờ xác nhận (DA khác người đề nghị)</dd></div>')}{card("Phiên bản", table(["Phiên bản", "Trạng thái", "Hiệu lực", "Người duyệt"], [["v5", tag(OK, "ACTIVE"), "01/10/2026", "Nguyễn Hữu Đức (DA)"], ["v4", tag(MU, "SUPERSEDED"), "02/07/2026", "Nguyễn Hữu Đức (DA)"]], "Phiên bản sống sót"))}</div>""")

# ---------------------------------------------------------------- 11 Ứng viên và nạp tệp
crow = [
    [mono("QG-DANCU/…8812"), "UPDATE", "API", tag(OK, "LINKED"), "<span class='mk'>*********345</span> " + tag(OK, "VALID"), "—", "Nguyễn Văn An", "26/11 13:55"],
    [mono("HT-YTE/…0041"), "CREATE", "API", tag(IN, "QUEUED"), "<span class='mk'>—</span> " + tag(MU, "MISSING"), tag(WA, "ADMIN_UNIT_CONVERTED"), "Nguyễn V. An", "26/11 13:52"],
    [mono("HT-BHXH/…3390"), "CREATE", "FLOW", tag(ER, "REJECTED"), "<span class='mk'>*********9</span> " + tag(ER, "INVALID_FORMAT"), tag(WA, "IDENTIFIER_INVALID"), "Trần Thị Bích", "26/11 13:40"],
    [mono("TEP-LO/L0042"), "CREATE", "FILE", tag(WA, "NORMALIZED"), "<span class='mk'>*********012</span> " + tag(OK, "VALID"), tag(WA, "DATE_PLACEHOLDER"), "Lê Văn Cường", "26/11 11:10"],
    [mono("HT-YTE/…0102"), "DELETE", "EVENT", tag(MU, "SUPERSEDED"), "—", "—", "—", "26/11 10:02"],
]
P["11"] = ("Ứng viên", "Dữ liệu dùng chung › Dữ liệu chủ › CITIZEN › Ứng viên", f"""
{head("Bản ghi ứng viên · CITIZEN", btn("Nhập tệp lô…", "pri"), btn("Xử lý lại các mục đã chọn"))}
<div class="card"><div class="toolbar">{facets(["Tất cả", "Lỗi 214", "Cảnh báo chuẩn hóa 1.030", "Đang chờ 0"], 1)}<div style="flex:1"></div>{inp("Nguồn ▾")}{inp("Kênh ▾")}{inp("Ngày nhận ▾")}</div>
{table(["Khóa nguồn", "Thao tác", "Kênh", "Trạng thái", "Số định danh", "Cảnh báo chuẩn hóa", "Họ tên (đã chuẩn hóa)", "Nhận lúc"], crow, "Ứng viên")}
<div class="alert e" style="margin:10px 0 0">✕ Bản ghi không đúng mô hình CITIZEN phiên bản 3: nationalId, birthDate. (ERR-06-017, mẫu báo lỗi)</div>{foot("1–5 / 214")}</div>""",
          )
P["11"] = (P["11"][0], P["11"][1], P["11"][2] + "")
ex11 = drawer("Ứng viên HT-BHXH/…3390 · chuẩn hóa", f"""<div class="muted">Trước, sau chuẩn hóa (giá trị DLCN che)</div>{table(["Trường", "Gốc", "Sau chuẩn hóa"], [["nationalId", "<span class='mk'>*********9</span>", tag(ER, "INVALID_FORMAT")], ["fullName", "TRẦN THỊ  BÍCH", "<b>Trần Thị Bích</b>"], ["birthDate", "00/00/1990", "1990 · DatePrecision YEAR"], ["address", "TP ĐN, Q HC", "Hải Châu · Đà Nẵng · " + tag(WA, "ADDRESS_UNPARSED")]], "Chuẩn hóa")}<div class="foot">{btn("Loại bỏ…", "danger")}{btn("Xử lý lại", "pri")}</div>""", 440)
P["11"] = (P["11"][0], P["11"][1], P["11"][2] + ex11)

P["11b"] = ("Nhập tệp lô", "Dữ liệu dùng chung › Dữ liệu chủ › CITIZEN › Ứng viên › Nhập tệp", f"""
{head("Nhập tệp lô · CITIZEN", btn("Hủy"), btn("Xác nhận nhập 4.862 dòng hợp lệ", "pri"))}
{steps(2, ["Chọn tệp", "Ánh xạ cột", "Xem trước", "Xác nhận"])}
{kpis([kpi("Tổng số dòng", "5.000", "ung-vien-ql-2026-11.csv · 1,9 MB"), kpi("Hợp lệ", "4.862", "97,2%"), kpi("Cảnh báo", "104", "tự chuẩn hóa được"), kpi("Lỗi", "34", "bỏ qua khi nhập")], 4)}
<div class="card">{table(["Dòng", "Họ tên", "Số định danh", "Ngày sinh", "Địa chỉ", "Trạng thái"], [
    ["2", "Nguyễn Văn An", "<span class='mk'>*********345</span> " + tag(OK, "VALID"), "12/03/1985", "Hải Châu · Đà Nẵng", tag(OK, "OK")],
    ["3", "TRẦN THỊ  BÍCH", "<span class='mk'>*********9</span> " + tag(ER, "INVALID_FORMAT"), "00/00/1990", "TP ĐN, Q HC", tag(ER, "Lỗi định danh")],
    ["4", "Lê Văn Cường", "<span class='mk'>*********012</span> " + tag(OK, "VALID"), "01/01/1990 " + tag(WA, "placeholder"), "Xã Hòa Châu", tag(WA, "Cảnh báo ngày")],
    ["5", "Đỗ Minh Quân", "—", "1992", "Phường 5, Q. 3 " + tag(WA, "ĐVHC cũ"), tag(WA, "Chuyển đổi ĐVHC")],
    ["6", "Công thức =SUM(A1)", "—", "—", "—", tag(ER, "Có công thức (ERR-06-019)")]], "Xem trước nhập tệp", ["", "d-del", "d-chg", "d-chg", "d-del"])}
{foot("Xem 5 / 5.000 dòng · Tải báo cáo lỗi (CSV)")}</div>""")

# ---------------------------------------------------------------- 12 Job và lịch
P["12"] = ("Job và lịch", "Dữ liệu dùng chung › Dữ liệu chủ › Job", f"""
{head("Job đối sánh và nền", btn("+ Chạy job đối sánh lô"), btn("Lịch job"))}
<div class="alert w">⚠ Job job-0412 vượt ngưỡng an toàn: 8,1% số bản ghi vào là Khớp (ngưỡng 5%). Chờ xác nhận, chưa áp dụng (ERR-06-105).<span class="sp"></span>{btn("Xem kết quả")}{btn("Xác nhận áp dụng", "pri")}</div>
<div class="card"><div class="toolbar">{facets(["Đang chạy 1", "Chờ xác nhận 1", "Hôm nay 7", "Lỗi 1", "Tất cả"], 4)}<div style="flex:1"></div>{inp("Loại job ▾")}{inp("Domain ▾")}</div>
{table(["Mã job", "Loại", "Domain", "Trạng thái", "Tiến độ", "Bắt đầu", "Thời gian", "Kết quả", ""], [
    [mono("job-0415"), "BATCH_MATCH", "CITIZEN", tag(IN, "● RUNNING"), '<div class="prog" style="width:140px"><i style="width:62%"></i></div> 62%', "14:00", "12 ph", "—", btn("Hủy")],
    [mono("job-0412"), "BATCH_MATCH", "CITIZEN", tag(WA, "◐ AWAITING_CONFIRMATION"), "100% đối sánh", "02:00", "41 ph", "96.410 Khớp (8,1%)", btn("Xác nhận")],
    [mono("job-0411"), "NATIONAL_RECONCILE", "CITIZEN", tag(OK, "✓ SUCCEEDED"), "100%", "06:00", "2 g 10", "lệch 0,4%", "⋯"],
    [mono("job-0409"), "ACCURACY_EVAL", "CITIZEN", tag(OK, "✓ SUCCEEDED"), "100%", "01/11 03:00", "18 ph", "P 99,93% · R 98,4%", "⋯"],
    [mono("job-0407"), "BATCH_MATCH", "ORGANIZATION", tag(ER, "✕ FAILED"), "34%", "25/11 02:00", "1 g", "Lỗi đọc staging (ERR-06-101)", btn("Chạy lại")],
    [mono("job-0402"), "RETENTION_PURGE", "—", tag(OK, "✓ SUCCEEDED"), "100%", "24/11 01:00", "6 ph", "Bỏ qua 12 đối tượng giữ pháp lý", "⋯"]], "Danh sách job")}
{foot("1–6 / 241")}</div>
<div class="grid-2e" style="margin-top:12px">{card("Lịch job", table(["Loại", "Lịch", "Lần sau"], [["BATCH_MATCH CITIZEN", "02:00 hằng ngày", "27/11 02:00"], ["NATIONAL_RECONCILE", "06:00 hằng ngày", "27/11 06:00"], ["ACCURACY_EVAL", "03:00 ngày 1 hằng tháng", "01/12 03:00"], ["RETENTION_PURGE", "01:00 chủ nhật", "29/11 01:00"]], "Lịch job"))}{card("Job đang chạy job-0415", '<div class="dl" style="grid-template-columns:150px 1fr"><dt>Phạm vi</dt><dd>GOLDEN_VS_GOLDEN · 1.186.420 bản ghi</dd><dt>Giai đoạn</dt><dd>Đối sánh · cụm 44 / 71</dd><dt>Tài nguyên</dt><dd>Job K8s Splink · 4 vCPU · 12 GiB</dd><dt>Dự kiến xong</dt><dd>14:21</dd></div>')}</div>""")

# ---------------------------------------------------------------- 13 Độ chính xác
P["13"] = ("Độ chính xác và tập nhãn", "Dữ liệu dùng chung › Dữ liệu chủ › Độ chính xác", f"""
{head("Độ chính xác và tập nhãn · CITIZEN", inp("Bộ quy tắc: v4 ACTIVE ▾"), btn("Chạy đánh giá"), btn("+ Tập nhãn mới"))}
{kpis([kpi("Precision", "99,93%", "✓ đạt (≥ 99,9%)"), kpi("Recall", "98,4%", "✓ đạt (≥ 98%)"), kpi("Tập nhãn LBL-2026-10", "12.400 cặp", "6.200 Khớp · 6.200 Khác · EVALUATION"), kpi("Kết luận", "PASSED", "01/11/2026 03:18")], 4)}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 440px"><div class="card"><h3 style="margin:0 0 8px;font-size:15px">Precision và recall theo tháng</h3>{line_chart([(pts([99.80, 99.84, 99.88, 99.91, 99.93, 99.93], lo=99.7, hi=100), "#0b5cd5", ""), (pts([97.1, 97.4, 97.9, 98.1, 98.3, 98.4], lo=96.5, hi=99), "#2f9e5b", "6 3")])}<div class="legend"><span><i style="background:#0b5cd5"></i>Precision</span><span><i style="background:#2f9e5b"></i>Recall (nét đứt)</span></div>
<div class="grp-t">Cặp nhầm cần xem</div>{table(["Loại", "Cặp", "Điểm", "Nhãn", "Thao tác"], [[tag(ER, "FP"), "Trần Văn Nam · Trần Văn Nam (2 người)", "0,96", "NO_MATCH", btn("Xem so sánh")], [tag(ER, "FP"), "Lê Thị Mai · Lê Thị Mai", "0,95", "NO_MATCH", btn("Xem so sánh")], [tag(WA, "FN"), "Phan V. Hùng · Phan Văn Hùng", "0,78", "MATCH", btn("Xem so sánh")]], "Cặp FP, FN")}</div>
<div><div class="card"><h3 style="margin:0 0 8px;font-size:15px">Tập nhãn</h3>{table(["Mã", "Mục đích", "Số cặp", "Trạng thái"], [[mono("LBL-2026-10"), "EVALUATION", "12.400", tag(OK, "Dùng đánh giá")], [mono("LBL-HUAN-LUYEN"), "TRAINING", "3.200", tag(IN, "Đang gán")]], "Tập nhãn")}</div>
<div class="card" style="margin-top:12px"><h3 style="margin:0 0 8px;font-size:15px">Gán nhãn cặp tiếp theo (3.200 / 10.000)</h3><div class="muted">Nguyễn Văn Hải · Nguyễn Văn Hải · 12/03/1985 · điểm 0,87</div><div style="margin-top:10px">{btn("Khớp", "ok")} {btn("Khác nhau")} {btn("Bỏ qua")}<span class="muted" style="margin-left:10px">M, K, B</span></div></div></div></div>""")

# ---------------------------------------------------------------- 14 Đồng bộ quốc gia
lo = pts([0.2, 0.3, 0.3, 0.4, 0.3, 0.5, 0.6, 1.1, 2.6, 5.8, 6.4, 6.1], lo=0, hi=7)
P["14"] = ("Đồng bộ quốc gia", "Dữ liệu dùng chung › Dữ liệu chủ › Đồng bộ quốc gia", f"""
{banner("e", "Đồng bộ tự động đã tạm dừng: tỷ lệ lệch 6,1% vượt 5%. Điều tra trước khi tiếp tục.", "Tiếp tục đồng bộ…")}
{head("Đồng bộ với CSDL tổng hợp quốc gia (qua PH-14)", btn("Chạy đối chiếu ngay"), btn("Tiếp tục", "dis"), btn("Tạm dừng"))}
{kpis([kpi("Trạng thái", "PAUSED", "từ 25/11 06:12 bởi hệ thống"), kpi("Lệch lượt gần nhất", "6,1%", "✕ vượt 5% (BR-06-011)"), kpi("Danh sách lệch mở", "3.482", "CRITICAL 12 · MAJOR 411 · MINOR 3.059"), kpi("Lần đối chiếu cuối", "26/11 06:00", "1.186.420 bản ghi · 2 g 10")], 4)}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 380px"><div class="card"><h3 style="margin:0 0 8px;font-size:15px">Tỷ lệ lệch theo lượt đối chiếu (12 lượt)</h3>{line_chart([(lo, "#a8320f", "")], thr=50)}<div class="legend"><span>Nguyên nhân dự đoán: lô nhập mới từ HT-BHXH ngày 24/11 · Xem dạng bảng</span></div></div>
{card("Chiều đồng bộ", table(["Chiều", "Trạng thái", "Gần nhất"], [["DOWN (xuống)", tag(ER, "PAUSED"), "25/11 06:00"], ["RECONCILE", tag(WA, "Chạy tay"), "26/11 06:00"], ["UP (lên)", tag(MU, "Tắt · chưa có quy định"), "—"]], "Chiều đồng bộ"))}</div>
<div class="card" style="margin-top:12px"><div class="toolbar">{inp("Mức độ: CRITICAL, MAJOR ▾")}{inp("Thuộc tính ▾")}{inp("Lượt 26/11 ▾")}<div style="flex:1"></div>{btn("Chấp nhận quốc gia (2 đã chọn)", "pri")}{btn("Giữ địa phương")}{btn("Báo quốc gia")}{btn("Bỏ qua…")}</div>
{table(["", "Bản ghi vàng", "Thuộc tính", "Giá trị địa phương", "Giá trị quốc gia", "Nguồn địa phương", "Mức", "Đề xuất", "Trạng thái"], [
    ["☑", mono("0193a0c2…5e6f"), "Ngày sinh", "12/03/1986", "12/03/1985", src("HT-YTE", "REL"), tag(ER, "CRITICAL"), "Chấp nhận quốc gia", tag(IN, "OPEN")],
    ["☑", mono("0193a3b9…c410"), "Họ tên", "Lê Văn Cương", "Lê Văn Cường", src("HT-BHXH", "SEC"), tag(ER, "CRITICAL"), "Chấp nhận quốc gia", tag(IN, "OPEN")],
    ["☐", mono("0193a77d…02e1"), "Địa chỉ", "Số 3 Nguyễn Văn Linh", "3 Nguyễn Văn Linh, Hải Châu", src("HT-YTE", "REL"), tag(WA, "MAJOR"), "Chấp nhận quốc gia", tag(IN, "OPEN")],
    ["☐", mono("0193a8f0…61b7"), "Điện thoại", "<span class='mk'>091*****78</span>", "<span class='mk'>—</span>", src("HT-YTE", "REL"), tag(MU, "MINOR"), "Giữ địa phương", tag(IN, "OPEN")]], "Danh sách lệch")}
<div class="muted" style="margin-top:6px">Giữ giá trị địa phương không áp cho thuộc tính thẩm quyền quốc gia (ERR-06-035). Mọi giá trị DLCN che theo phân loại.</div></div>""")

# ---------------------------------------------------------------- 15 Xuất và đăng ký nhận
P["15"] = ("Xuất và đăng ký nhận", "Dữ liệu dùng chung › Dữ liệu chủ › Cung cấp", f"""
{head("Cung cấp dữ liệu chủ", btn("+ Đề nghị xuất"), btn("+ Đăng ký nhận cập nhật"))}
{tabs(["Đề nghị xuất 6", "Đăng ký nhận cập nhật 9"], 0)}
<div class="card"><div class="toolbar">{facets(["Chờ chấp thuận 2", "Đã chấp thuận", "Sẵn sàng", "Hết hạn", "Tất cả"], 0)}<div style="flex:1"></div>{inp("Domain ▾")}</div>
{table(["Mã", "Domain", "Bộ lọc, trường", "Số bản ghi", "Định dạng", "Mục đích, căn cứ", "Người nhận", "Người đề nghị", "Trạng thái"], [
    [mono("exp-0192"), "ORGANIZATION", "Ngành 62, 63 · 6 trường", "3.120", "XLSX", "Thống kê ngành CNTT · NĐ 278/2025", "Sở TT&TT", "Lê Thị Thu", tag(WA, "PENDING_APPROVAL")],
    [mono("exp-0191"), "CITIZEN", "Q. Hải Châu · 9 trường · mã giả", "88.400", "CSV", "Báo cáo dân số · Luật Dữ liệu", "Cục Thống kê", "Lê Thị Thu", tag(WA, "PENDING_APPROVAL")],
    [mono("exp-0188"), "ADDRESS", "Toàn tỉnh · 5 trường", "412.300", "JSONL", "Đồng bộ bản đồ số", "Sở TN&MT", "Phạm Thị Hoa", tag(OK, "READY") + " còn 21 giờ"],
    [mono("exp-0175"), "CITIZEN", "Toàn tỉnh · 9 trường", "1.186.420", "CSV", "—", "—", "Lê Thị Thu", tag(ER, "REJECTED · vượt 100.000")]], "Đề nghị xuất")}
<div class="alert i" style="margin:10px 0 0">ⓘ Chấp thuận cần DO của các nguồn có thuộc tính trong tệp và DA; người chấp thuận khác người đề nghị. Tệp mã hóa, thủy vân người xuất, tải trong 24 giờ.</div></div>
<div class="card" style="margin-top:12px"><h3 style="margin:0 0 8px;font-size:15px">Đăng ký nhận cập nhật (xem nhanh)</h3>{table(["HTTT", "Domain", "Phạm vi", "Mục đích PH-09", "Kênh", "Trạng thái"], [["Hệ thống BHXH tỉnh", "CITIZEN", "LINKED_ONLY", "Quản lý đối tượng hưởng", "t68.mdm.golden.updated.v1", tag(OK, "ACTIVE")], ["Cổng dịch vụ công", "CITIZEN", "DOMAIN", "—", "t68.mdm.golden.merged.v1", tag(ER, "Chưa có mục đích (ERR-06-043)")]], "Đăng ký nhận")}</div>""")

# ---------------------------------------------------------------- 16 Yêu cầu của chủ thể
P["16"] = ("Yêu cầu của chủ thể dữ liệu", "Dữ liệu dùng chung › Dữ liệu chủ › Yêu cầu chủ thể", f"""
{head("Yêu cầu của chủ thể dữ liệu", btn("+ Tiếp nhận yêu cầu", "pri"), btn("Báo cáo tháng"))}
{kpis([kpi("Đang xử lý", "11", "SLA 10 ngày làm việc (giả định)"), kpi("Sắp đến hạn (≤ 2 ngày)", "2", "⚠ cảnh báo SO"), kpi("Hoàn thành tháng này", "34", "Truy cập 21 · Sửa 11 · Hạn chế 2")], 3)}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 440px"><div class="card"><div class="toolbar">{facets(["Của tôi 5", "Sắp đến hạn 2", "Chuyển nguồn 3", "Tất cả 11"], 0)}</div>
{table(["Mã", "Loại", "Chủ thể", "Nhận lúc", "Hạn", "Trạng thái"], [
    [mono("dsr-0087"), tag(IN, "ACCESS"), "Nguyễn Văn A… (<span class='mk'>*********345</span>)", "18/11", tag(ER, "27/11 · còn 1 ngày"), tag(IN, "IN_PROGRESS")],
    [mono("dsr-0088"), tag(WA, "RECTIFICATION"), "Trần Thị B… (<span class='mk'>*********772</span>)", "19/11", "03/12", tag(WA, "FORWARDED_TO_SOURCE")],
    [mono("dsr-0090"), tag(MU, "RESTRICTION"), "Lê Văn C… (<span class='mk'>*********012</span>)", "24/11", "08/12", tag(IN, "RECEIVED")]], "Yêu cầu chủ thể")}</div>
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">dsr-0087 · Yêu cầu truy cập</h3><div class="dl" style="grid-template-columns:140px 1fr"><dt>Xác minh danh tính</dt><dd>{tag(OK, "✓ Đã xác minh")} verificationRef VN-2026-1187</dd><dt>Bản ghi vàng</dt><dd>{mono("0193a0c2…5e6f")} {btn("Mở")}</dd><dt>Báo cáo</dt><dd>9 thuộc tính · 3 nguồn · 14 lượt truy cập 12 tháng</dd></div>
<div class="grp-t">Truy cập 12 tháng gần nhất</div><div class="vtl"><div><b>20/10/2026</b> · Hệ thống BHXH tỉnh · Mục đích: Quản lý hưởng bảo hiểm</div><div><b>05/09/2026</b> · Sở Y tế · Khám chữa bệnh</div></div>
<div class="foot">{btn("Chuyển nguồn")}{btn("Từ chối…", "danger")}{btn("Duyệt báo cáo và hoàn thành", "pri")}</div></div></div>""")

# ---------------------------------------------------------------- 17 Cài đặt và lưu giữ
P["17"] = ("Cài đặt và lưu giữ", "Dữ liệu dùng chung › Dữ liệu chủ › Cấu hình › Cài đặt", f"""
{head("Cài đặt dữ liệu chủ", btn("Hoàn nguyên"), btn("Lưu thay đổi", "pri"))}
<div class="grid2" style="grid-template-columns:220px minmax(0,1fr)"><div class="card tree"><div class="on">Hàng đợi</div><div>Đối sánh</div><div>Hoàn tác</div><div>Truy cập và xuất</div><div>Đồng bộ quốc gia</div><div>Yêu cầu chủ thể</div><div>Lưu giữ dữ liệu</div></div>
<div><div class="card"><h3 style="margin:0 0 8px;font-size:15px">Hàng đợi và đối sánh</h3>{table(["Tham số", "Khóa", "Giá trị", "Miền", "Mặc định"], [
    ["Hạn xử lý mục hàng đợi (ngày)", mono("06.queue.sla-days"), inp("7", "width:80px"), "1…30", "7"],
    ["Ngưỡng cảnh báo quá tải", mono("06.queue.max-open"), inp("500", "width:80px"), "100…10.000", "500"],
    ["Giữ mục đã nhận (phút)", mono("06.queue.hold-minutes"), inp("30", "width:80px"), "10…120", "30"],
    ["Tắt tự hợp nhất khi đánh giá tháng không đạt", mono("06.match.auto-disable-on-fail"), "◉ Bật", "true, false", "true"],
    ["Ngưỡng an toàn job lô", mono("06.batch.safety-ratio"), inp("0,05", "width:80px"), "0,01…0,20", "0,05"],
    ["Ngưỡng tạm dừng đồng bộ quốc gia", mono("06.sync.pause-ratio"), inp("0,05", "width:80px"), "0,01…0,20", "0,05"]], "Tham số")}</div>
<div class="card" style="margin-top:12px"><h3 style="margin:0 0 8px;font-size:15px">Chính sách lưu giữ</h3>{table(["Loại đối tượng", "Hành động", "Lưu giữ", "Tối thiểu", "Giữ pháp lý"], [
    ["Ứng viên (raw, normalized)", "ANONYMIZE", inp("365 ngày", "width:100px"), "180", "☐"],
    ["Kết quả đối sánh, staging", "DELETE", inp("180 ngày", "width:100px"), "90", "☐"],
    ["Nhật ký truy cập", "ARCHIVE_COLD", "12 tháng trực tuyến · 5 năm WORM", "12 tháng", tag(MU, "khóa")],
    ["Tệp xuất", "DELETE", "24 giờ", "—", "—"]], "Lưu giữ")}
<div class="alert e" style="margin:8px 0 0">✕ Thời hạn lưu giữ dưới mức tối thiểu (ví dụ ứng viên 90 ngày so với tối thiểu 180). Chưa lưu được (ERR-06-049).</div></div></div></div>""")

# ---------------------------------------------------------------- 18 Nhật ký
P["18"] = ("Nhật ký", "Dữ liệu dùng chung › Dữ liệu chủ › Nhật ký", f"""
{head("Nhật ký dữ liệu chủ", btn("Xuất nhật ký"), btn("Làm mới ⟳"))}
{tabs(["Nhật ký truy cập", "Nhật ký xử lý", "Cảnh báo bất thường 2"], 0)}
<div class="alert w">⚠ Người dùng <b>pham.hoa</b> xem 112 bản ghi khác nhau trong 10 phút, vượt ngưỡng 100. Đã chặn và yêu cầu phê duyệt (BR-06-013, ERR-06-038).<span class="sp"></span>{btn("Mở")}</div>
<div class="card"><div class="toolbar">{inp("Người dùng, HTTT ▾")}{inp("Hành động ▾")}{inp("Domain ▾")}{inp("26/11/2026 00:00 – 14:00 ▾")}<div style="flex:1"></div><span class="muted">Giữ 12 tháng trực tuyến, 5 năm WORM</span></div>
{table(["Thời điểm", "Người, hệ thống", "Hành động", "Đối tượng", "Thuộc tính xem", "Mục đích", "Bỏ che", "Mã truy vết"], [
    ["26/11 13:58:12", "lethu (DS)", "Xem bản ghi vàng", mono("0193a0c2…5e6f"), "9 thuộc tính", "Giải quyết khiếu nại", tag(MU, "Không"), mono("tr-9f3a")],
    ["26/11 13:57:40", "lethu (DS)", "Bỏ che giá trị", mono("0193a0c2…5e6f"), "phone", "Giải quyết khiếu nại · lý do ≥ 20 ký tự", tag(WA, "Có · PERM-09-unmask"), mono("tr-9f39")],
    ["26/11 13:41:05", "pham.hoa (DS)", "Tìm kiếm", "CITIZEN · họ tên + năm sinh", "—", "Rà soát trùng", tag(MU, "Không"), mono("tr-9f21")],
    ["26/11 13:20:33", "HT-BHXH (mdm:read)", "Tra cứu ID vàng", mono("0193a3b9…c410"), "3 thuộc tính", "Quản lý đối tượng hưởng", tag(MU, "Không"), mono("tr-9f0e")],
    ["26/11 12:02:10", "lethu (DS)", "Quyết định MATCH", "Mục #QI-0042", "—", "—", tag(MU, "Không"), mono("tr-9ef1")]], "Nhật ký truy cập")}
{foot("1–5 / 18.442")}</div>""")

if __name__ == "__main__":
    for code, (title, crumb, body) in {k: (v[0], v[1], v[2]) for k, v in P.items()}.items():
        pass
    for code, v in P.items():
        title, crumb, body = v[0], v[1], v[2]
        (OUT / f"ui-06-{code}.html").write_text(shell(code, title, crumb, body.split("<div class=\"drawer\"")[0]) if "<div class=\"drawer\"" not in body else
                                                 shell(code, title, crumb, body.split("<div class=\"drawer\"")[0], "<div class=\"drawer\"" + body.split("<div class=\"drawer\"", 1)[1]), encoding="utf-8")
    print("đã sinh", len(P), "trang")
