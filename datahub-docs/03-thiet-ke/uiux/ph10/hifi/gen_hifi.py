#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-10-01…20 (D03-06-PH10, mục "Bản hi-fi" của từng màn).

Chạy: python3 gen_hifi.py; chụp ảnh: node shot.js
Dữ liệu là giả định của tỉnh thí điểm T68. Topic nghiệp vụ theo quy ước {tenant}.{miền}.{thực thể}.{sự kiện}.v{n}
(FR-10-008); topic hệ thống của chính PH-10 có dạng t68.event.*.v1 (FRS A.7), miền `event` là miền dành riêng.
Menu theo D03-06-PH10 §4.3: nhóm Tích hợp có ba mục "Dự án sự kiện", "Topic sự kiện", "Sơ đồ kết nối";
UI-10-13 nằm ở "Việc của tôi". Phong cách Liquid Glass của D03-05: kính chỉ ở lớp điều hướng và lớp nổi.
"""
import pathlib

OUT = pathlib.Path(__file__).parent

NAV = [("|Tích hợp", None), ("Luồng tích hợp", "x4"), ("Bộ điều hợp", "x5"), ("Dự án sự kiện", "da"),
       ("Topic sự kiện", "tp"), ("Sơ đồ kết nối", "sd"), ("|Cá nhân", None), ("Việc của tôi", "vc")]
BADGE = {"vc": "<span class='tag t-info'>7</span>", "tp": "<span class='tag t-warn'>2</span>"}
ACTIVE = {c: "da" for c in ("01", "02", "03", "04", "19", "20")}
ACTIVE.update({c: "tp" for c in ("05", "06", "07", "08", "09", "10", "11", "12", "15", "16", "17", "18")})
ACTIVE.update({"13": "vc", "14": "sd"})
SUB_DA = ["Tổng quan", "Dự án", "Nhập khai báo", "Di trú"]
SUB_TP = ["Topic", "Bên phát", "Bên nhận", "Phát lại", "Độ trễ", "Cài đặt"]


def shell(code, title, crumb, body, extra=""):
    nav = ""
    for n, c in NAV:
        if n.startswith("|"):
            nav += f'<div class="grp">{n[1:]}</div>'
            continue
        nav += f'<a class="{"on" if ACTIVE[code] == c else ""}" href="#">{n} {BADGE.get(c, "")}</a>'
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-10-{code} · {title}</title><link rel="stylesheet" href="hifi.css"></head><body>
<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Điều hành</div><div class="search">Tìm topic, đăng ký nhận, bên phát, bên nhận…  ⌘K</div><div class="sp"></div>
<span class="tray">⟳ 1 tác vụ nền</span><span class="tray">T68 · Tỉnh thí điểm</span><div class="avatar">NA</div></header>
<nav class="side" aria-label="Điều hướng chính">{nav}</nav>
<main><div class="crumb">{crumb}</div>{body}</main></div>{extra}<div class="hint">Bản hi-fi minh họa · D03-06-PH10 · UI-10-{code} · dữ liệu giả định T68</div></body></html>"""


def table(head, data, label=""):
    th = "".join(f"<th>{h}</th>" for h in head)
    tr = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in data)
    return f'<table aria-label="{label}"><thead><tr>{th}</tr></thead><tbody>{tr}</tbody></table>'


def tag(kind, text):
    return f"<span class='tag t-{kind}'>{text}</span>"


def tabs(items, on):
    return '<div class="tabs" role="tablist">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def subtabs(items, on):
    return '<div class="subtabs" role="tablist">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def facets(items, on=0):
    return '<div class="facets">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def kpis(items, n=None):
    n = n or len(items)
    cells = "".join(f'<div class="kpi {c}"><span>{a}</span><b>{b}</b><small>{d}</small></div>' for a, b, d, c in items)
    return f'<div class="kpis" style="--n:{n}">{cells}</div>'


def foot(text="Hiển thị 1–20"):
    return f'<div class="foot" style="justify-content:space-between"><span class="muted">{text}</span><span class="muted">‹ 1 2 › · 20 / trang</span></div>'


def drawer(title, inner, width=480):
    return f'<div class="drawer" role="dialog" aria-label="{title}" style="width:{width}px"><h3 style="margin:0 0 10px">{title}</h3>{inner}</div>'


def mono(t):
    return f"<span class='mono'>{t}</span>"


def spark(vals, color="#0b5cd5"):
    return '<span class="spark">' + "".join(f'<i style="height:{v}px;background:{color}"></i>' for v in vals) + "</span>"


def card(title, inner, style=""):
    return f'<div class="card" style="{style}"><h3 style="margin:0 0 8px;font-size:15px">{title}</h3>{inner}</div>'


OK, WA, ER, IN, MU = "ok", "warn", "err", "info", "mute"
T1 = "t68.dkkd.doanh-nghiep.da-cap-phep.v1"
T2 = "t68.dkkd.doanh-nghiep.da-giai-the.v1"
T3 = "t68.hotich.khai-sinh.da-dang-ky.v1"
T4 = "t68.datdai.thua-dat.da-bien-dong.v1"
T5 = "t68.cdc.dkkd.public.doanh_nghiep.v1"
T6 = "t68.event.subscription.state-changed.v1"
T7 = "t68.event.delivery.dead-lettered.v1"
S1, S2, S3 = "ht-thue-dn-cap-phep", "ht-bhxh-dn-cap-phep", "dkkd-thue-dong-bo"
P = {}

# 01 Tổng quan sự kiện
line_in = "M0,90 L40,84 L80,70 L120,52 L160,40 L200,46 L240,58 L280,66 L320,60 L360,48 L400,34 L440,22 L480,30 L520,42 L560,50 L600,44 L640,38 L680,46"
line_out = "M0,70 L40,62 L80,50 L120,34 L160,22 L200,26 L240,36 L280,44 L320,40 L360,28 L400,16 L440,8 L480,14 L520,24 L560,30 L600,26 L640,20 L680,28"
chart = f'<svg viewBox="0 0 680 110" style="width:100%;height:130px" role="img" aria-label="Lưu lượng vào, ra mỗi phút 24 giờ"><path d="{line_in}" fill="none" stroke="#0b5cd5" stroke-width="2"/><path d="{line_out}" fill="none" stroke="#2f9e5b" stroke-width="2" stroke-dasharray="6 3"/></svg>'


def cnt(title, n, rows):
    r = "".join(f"<div class='muted' style='margin-top:3px'>{x}</div>" for x in rows)
    return f'<div class="kpi"><span>{title}</span><b>{n}</b>{r}</div>'


qrow = lambda n, u, c, pct, k="": f'<div class="qrow"><span>{n}</span><div class="prog"><i style="width:{pct}%;{k}"></i></div><span class="num">{u}/{c} · {pct}%</span></div>'
P["01"] = ("Tổng quan sự kiện", "Tích hợp › Dự án sự kiện › Tổng quan", f"""
<div class="head"><h1>Dự án sự kiện</h1><div class="sp"></div><span class="input">Dự án: Tất cả dự án ▾</span><span class="seg"><span>1 giờ</span><span class="on">24 giờ</span><span>7 ngày</span></span><span class="muted">Cập nhật 14:02:31</span><span class="btn">⟳</span></div>
{subtabs(SUB_DA, 0)}
<div class="kpis" style="--n:4">{cnt("Bên phát","42",["● 40 đang hoạt động","◐ 2 tạm ngừng"])}{cnt("Bên nhận","67",["● 63 đang hoạt động","◐ 3 tạm ngừng · ○ 1 ngừng dùng"])}{cnt("Dự án","12",["● 11 đang hoạt động","○ 1 đã lưu trữ"])}{cnt("Topic","138",["● 121 đang hoạt động","◐ 9 chờ duyệt · ✕ 1 cấp phát lỗi"])}</div>
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 380px">{card("Lưu lượng sự kiện (vào, ra mỗi phút)", chart + '<div class="legend"><span><i style="background:#0b5cd5"></i>Vào 1.240/phút</span><span><i style="background:#2f9e5b"></i>Ra 3.105/phút (nét đứt)</span><span class="sp" style="flex:1"></span><span>10 topic nhiều nhất ▸ · Xem dạng bảng</span></div>')}
{card("Độ trễ tiêu thụ", kpis([("Bình thường","58","","") ,("Cảnh báo","4","⚠",""),("Nghiêm trọng","1","✕",""),("Ngừng tiến","1","⏸","")],4) + table(["Đăng ký nhận","Mức","Độ trễ"],[[mono(S2),tag(ER,"⏸ Ngừng tiến"),"41 ph"],[mono(S1),tag(WA,"⚠ Cảnh báo"),"12 ph 30 g"]],"Đăng ký nhận trễ nhất"))}</div>
<div class="grid-2e" style="grid-template-columns:1fr 1fr 1fr;margin-top:12px">{card("DLQ · 212 mục mới", '<div class="vbars" style="height:70px">' + "".join(f'<div><i style="height:{h}px;background:#a11a1a"></i></div>' for h in [8,10,14,16,24,40,60]) + '</div><div class="muted">7 ngày gần nhất · theo topic ▸</div>')}
{card("Việc chờ duyệt · 7", '<div class="dl" style="grid-template-columns:1fr auto"><dt>Tạo topic</dt><dd>3 →</dd><dt>Quyền phát</dt><dd>2 →</dd><dt>Đăng ký nhận</dt><dd>2 →</dd></div>')}
{card("Cần chú ý", '<div class="alert w" style="margin:0 0 6px">⚠ 2 topic ngừng khuyến nghị hết hạn trong 14 ngày</div><div class="alert e" style="margin:0">✕ 1 topic cấp phát lỗi: ' + mono(T4) + '</div>')}</div>
{card("Hạn mức tenant T68", qrow("Topic",138,500,28) + qrow("Phân vùng",812,3000,27) + qrow("Đăng ký nhận",67,2000,3) + qrow("Worker đẩy",96,400,24) + qrow("Phát (MiB/giây)","3,1",10,31) + '<div class="muted">Tài nguyên cụm Kafka (CPU, bộ nhớ) xem ở Giám sát PH-13 ↗</div>', "margin-top:12px")}""")

# 02 Danh sách dự án
proj_rows = [
    ["☐", mono("dang-ky-kinh-doanh") + "<br>Liên thông đăng ký kinh doanh", "SO-KHDT", tag(OK, "● Đang hoạt động"), "14 (2◐)", "3", "9", "45 g", "10 phút trước", "⋯"],
    ["☐", mono("ho-tich-dien-tu") + "<br>Hộ tịch điện tử liên thông", "SO-TP", tag(OK, "● Đang hoạt động"), "6", "2", "5", "12 ph ⚠", "1 giờ trước", "⋯"],
    ["☐", mono("dat-dai-bien-dong") + "<br>Biến động đất đai", "SO-TNMT", tag(OK, "● Đang hoạt động"), "4 (1✕)", "1", "3", "8 g", "hôm qua", "⋯"],
    ["☐", mono("bhxh-lien-thong") + "<br>Liên thông bảo hiểm xã hội", "BHXH-T68", tag(OK, "● Đang hoạt động"), "5", "2", "4", "20 g", "22/11/2026 09:15", "⋯"],
    ["☐", mono("y-te-co-so") + "<br>Y tế cơ sở", "SO-YT", tag(OK, "● Đang hoạt động"), "3", "1", "2", "—", "20/11/2026 16:40", "⋯"],
    ["☐", mono("thu-nghiem-2025") + "<br>Thử nghiệm Hub cũ 2025", "SO-TTTT", tag(MU, "○ Đã lưu trữ"), "0", "0", "0", "—", "02/10/2026 08:00", "⋯"]]
P["02"] = ("Danh sách dự án", "Tích hợp › Dự án sự kiện › Dự án", f"""
<div class="head"><h1>Dự án sự kiện</h1><div class="sp"></div><span class="btn">Xuất khai báo</span><span class="btn pri">+ Tạo dự án</span></div>
{subtabs(SUB_DA, 1)}
<div class="card"><div class="toolbar"><span class="input" style="min-width:280px">Tìm mã, tên, mô tả…</span><span class="input">Trạng thái: Đang hoạt động ▾</span><span class="input">Tổ chức ▾</span><span class="input">Nhãn ▾</span><div style="flex:1"></div><span class="muted">⚙ Cột · ≡ Mật độ</span></div>
{table(["","Mã · Tên","Tổ chức","Trạng thái","Topic","Phát","Nhận","Trễ lớn nhất","Cập nhật",""], proj_rows, "Danh sách dự án")}
<div class="alert i" style="margin:10px 0 0">Đã chọn 0 · Chọn dự án để xuất khai báo EventManifest</div>{foot("1–6 / 6")}</div>""")

# 03 Chi tiết dự án
mini = f"""<svg viewBox="0 0 900 150" style="width:100%;height:160px" role="img" aria-label="Sơ đồ thu gọn: 2 bên phát, 3 topic, 4 bên nhận">
<g font-size="12" font-family="JetBrains Mono,Consolas,monospace"><rect x="10" y="20" width="150" height="36" rx="8" fill="#fff" stroke="#b9c0ca"/><text x="22" y="43">ht-dkkd</text>
<rect x="10" y="90" width="150" height="36" rx="8" fill="#fff" stroke="#7146c7"/><text x="22" y="113">dkkd-dong-bo</text>
<rect x="300" y="10" width="300" height="36" rx="16" fill="#fff" stroke="#b9c0ca"/><text x="312" y="33">{T1}</text>
<rect x="300" y="60" width="300" height="36" rx="16" fill="#fff" stroke="#b9c0ca"/><text x="312" y="83">{T2}</text>
<rect x="300" y="110" width="300" height="36" rx="16" fill="#fff" stroke="#b9c0ca"/><text x="312" y="133">{T5}</text>
<rect x="740" y="10" width="150" height="30" rx="8" fill="#fff" stroke="#c98a00" stroke-width="2"/><text x="752" y="30">ht-thue ⚠</text>
<rect x="740" y="50" width="150" height="30" rx="8" fill="#fff" stroke="#b9c0ca"/><text x="752" y="70">ht-bhxh</text>
<rect x="740" y="90" width="150" height="30" rx="8" fill="#fff" stroke="#b9c0ca"/><text x="752" y="110">ht-thongke</text></g>
<g stroke="#6b7480" stroke-width="1.5" fill="none"><path d="M160,38 L300,28"/><path d="M160,108 L300,78"/><path d="M160,108 L300,128"/><path d="M600,28 L740,25" stroke="#c98a00" stroke-width="3"/><path d="M600,28 L740,65"/><path d="M600,78 L740,105"/><path d="M600,128 L740,105" stroke-dasharray="4 4"/></g></svg>"""
P["03"] = ("Chi tiết dự án", "Tích hợp › Dự án sự kiện › Liên thông đăng ký kinh doanh", f"""
<div class="chrome"><h1>‹ Liên thông đăng ký kinh doanh {tag(OK,"● Đang hoạt động")} {mono("dang-ky-kinh-doanh")} ⧉</h1>
<div style="display:flex;align-items:center;gap:8px"><span class="muted">Sở Kế hoạch và Đầu tư · Phụ trách Nguyễn An · Nhãn doanh-nghiep</span><span style="flex:1"></span><span class="btn pri">+ Tạo topic ▾</span><span class="btn">Sửa</span><span class="btn">⋯</span></div></div>
{tabs(["Tổng quan","Topic 14","Bên tham gia 12","Sơ đồ","Lịch sử"],0)}
<div class="card" style="margin-bottom:12px"><span class="muted">Mô tả</span><div>Gom các topic phát khi Sở KH-ĐT cấp, thay đổi, giải thể doanh nghiệp để cơ quan thuế, BHXH, thống kê nhận ngay thay vì đồng bộ theo lô.</div></div>
{kpis([("Sự kiện vào 24 giờ","18.420","▲ 6% so với hôm qua",""),("Đăng ký nhận cảnh báo","1","Nghiêm trọng",""),("Mục DLQ mới","37","→ Xem DLQ",""),("Topic chờ duyệt","2","→ Việc của tôi","")])}
{card("Sơ đồ thu gọn · 5 topic lưu lượng lớn nhất", mini + '<div style="text-align:right"><span class="btn">Mở sơ đồ đầy đủ ↗</span></div>')}""")

# 04 Tạo dự án (Drawer trên UI-10-02)
P["04"] = ("Tạo, sửa dự án", "Tích hợp › Dự án sự kiện › Dự án", P["02"][2], drawer("Tạo dự án sự kiện", """
<div class="field"><label>Tên dự án *</label><div class="input">Liên thông bảo trợ xã hội</div></div>
<div class="field"><label>Mã dự án *</label><div class="input mono">bao-tro-xa-hoi</div><div class="muted" style="color:#0b6b3a">✓ Mã còn trống · dùng trong đường dẫn, không đổi được</div></div>
<div class="field"><label>Tổ chức chủ quản *</label><div class="input">Sở Lao động, Thương binh và Xã hội ▾</div></div>
<div class="field"><label>Người phụ trách</label><div class="input">Nguyễn An (bạn) ▾</div></div>
<div class="field"><label>Nhãn</label><div class="input"><span class="tag t-mute">an-sinh ×</span>&nbsp;<span class="tag t-mute">doi-tuong ×</span>&nbsp; + thêm</div></div>
<div class="field"><label>Mô tả</label><div class="input" style="height:80px;align-items:flex-start;padding-top:6px">Gom topic phát khi xét duyệt, thay đổi, chấm dứt trợ cấp xã hội để UBND cấp xã và BHXH nhận.</div><div class="muted" style="text-align:right">96 / 2.000</div></div>
<div class="foot"><span class="btn">Hủy</span><span class="btn pri">Tạo dự án</span></div>""", 560))

# 05 Danh sách topic
trow = lambda n, p, k, st, pv, lg, ph, nh, v: [mono(n) + " ⧉<br><span class='muted'>" + p + "</span>", k, st, pv, lg, ph, nh, v, "⋯"]
P["05"] = ("Danh sách topic", "Tích hợp › Topic sự kiện › Topic", f"""
<div class="head"><h1>Topic sự kiện</h1><div class="sp"></div><span class="btn pri">+ Tạo topic</span></div>
{subtabs(SUB_TP, 0)}
<div class="card"><div class="toolbar"><span class="input" style="min-width:260px">Tìm tên topic, mô tả, loại sự kiện…</span><span class="input">Dự án ▾</span><span class="input">Trạng thái ▾</span><span class="input">Loại ▾</span><span class="input">Phân loại ▾</span><span class="input">Định tuyến ▾</span><span class="input">Bên phát ▾</span><span class="input">Bên nhận ▾</span></div>
{facets(["Có cảnh báo lag 3","Chờ duyệt 9","Cấp phát lỗi 1","Ngừng khuyến nghị 4"], -1)}
{table(["Tên topic · Dự án","Loại","Trạng thái","Phân vùng","Lưu giữ","Phát","Nhận","Vào/phút",""],[
trow(T1,"dang-ky-kinh-doanh · 🔒 Nội bộ · lược đồ v3","Nghiệp vụ",tag(OK,"● Đang hoạt động")+"<br><span class='muted' style='color:#7a5200'>trễ 12 ph ⚠</span>","6","7 ngày","1","4","320"),
trow(T2,"dang-ky-kinh-doanh · 🔒 Nội bộ · lược đồ v1","Nghiệp vụ",tag(WA,"◐ Ngừng khuyến nghị"),"6","7 ngày","1","2","4"),
trow(T3,"ho-tich-dien-tu · 🔒 Hạn chế · lược đồ v2","Nghiệp vụ",tag(OK,"● Đang hoạt động"),"3","30 ngày","1","3","85"),
trow(T4,"dat-dai-bien-dong · Nội bộ · lược đồ v1","Nghiệp vụ",tag(ER,"✕ Cấp phát lỗi"),"6","7 ngày","0","0","<span class='muted'>Chưa có số liệu</span>"),
trow(T5,"dang-ky-kinh-doanh · ⚙ do dh-integration đăng ký","CDC",tag(OK,"● Đang hoạt động"),"3","7 ngày","1","1","14"),
trow(T6,"— · ⚙ topic hệ thống PH-10","Hệ thống",tag(OK,"● Đang hoạt động"),"3","7 ngày","1","2","2"),
trow(T7,"— · ⚙ topic hệ thống PH-10","Hệ thống",tag(OK,"● Đang hoạt động"),"3","7 ngày","1","1","1")],"Danh sách topic")}
{foot("1–7 / 138")}</div>""")

# 06 Chi tiết topic
pbars = "".join(f'<div class="hbar"><span>Phân vùng {i}</span><i style="width:{v}%"></i><span class="num">{n}</span></div>' for i, (v, n) in enumerate([(92, "1.410"), (64, "980"), (88, "1.350"), (30, "460"), (70, "1.070"), (61, "940")]))
P["06"] = ("Chi tiết topic", "Tích hợp › Topic sự kiện › t68.dkkd…da-cap-phep.v1", f"""
<div class="chrome"><h1>‹ {mono(T1)} ⧉ {tag(OK,"● Đang hoạt động")} {tag(MU,"Nghiệp vụ")} {tag(IN,"🔒 Nội bộ")}</h1>
<div style="display:flex;align-items:center;gap:8px"><span class="muted">Dự án Liên thông đăng ký kinh doanh · Lược đồ v3 (Avro, tương thích lùi) · 6 phân vùng · lưu 7 ngày · theo khóa maDoanhNghiep</span><span style="flex:1"></span><span class="btn pri">Đăng ký nhận</span><span class="btn">Đề nghị quyền phát</span><span class="btn">Đổi cấu hình ▾</span><span class="btn">⋯</span></div></div>
{tabs(["Tổng quan","Cấu hình","Lược đồ","Quyền phát 1","Đăng ký nhận 4","DLQ 37","Cách kết nối","Chuyển đổi phiên bản","Lịch sử"],0)}
{kpis([("Sự kiện vào 24 giờ","7.680","",""),("Byte vào 24 giờ","21 MiB","",""),("Đăng ký nhận","4","1 cảnh báo",""),("Trễ lớn nhất","12 ph 30 g","<span style='color:#7a5200'>⚠ vượt ngưỡng 5 phút</span>","")])}
<div class="grid3" style="grid-template-columns:420px minmax(0,1fr)">{card("Lưu lượng theo phân vùng (24 giờ)", pbars + '<div class="muted" style="text-align:right">Xem dạng bảng</div>')}
{card("Bên phát, bên nhận", table(["Bên","Vai trò","Chế độ","Trạng thái","Độ trễ","DLQ mới"],[
[mono("ht-dkkd")+" · HTTT ĐKKD","Bên phát","API HTTP",tag(OK,"● Đang hiệu lực"),"—","—"],
[mono("ht-thue")+" · HTTT thuế tỉnh","Bên nhận","Đẩy webhook",tag(OK,"● Đang nhận"),tag(WA,"⚠ 12 ph 30 g"),"37"],
[mono("ht-bhxh")+" · BHXH tỉnh","Bên nhận","Kéo qua API",tag(OK,"● Đang nhận"),"40 g","0"],
[mono("ht-thongke")+" · Cục Thống kê","Bên nhận","Kéo qua API",tag(MU,"Ⅱ Tạm dừng"),"—","0"],
[mono("dkkd-thue-dong-bo")+" · Luồng PH-04","Bên nhận","Nội bộ",tag(OK,"● Đang nhận"),"3 g","—"]],"Bên phát và bên nhận của topic"))}</div>""")

# 07 Tạo topic, bước 1
P["07"] = ("Tạo topic", "Tích hợp › Topic sự kiện › Tạo topic", f"""
<div class="head"><h1>Tạo topic</h1></div>
<div class="steps"><div class="on">① Dự án và tên</div><div>② Cấu hình</div><div>③ Định tuyến và thứ tự</div><div>④ Lược đồ</div><div>⑤ Kiểm tra</div><div>⑥ Rà soát và gửi</div></div>
<div class="card" style="max-width:980px">
<div class="field"><label>Dự án *</label><div class="input">Liên thông đăng ký kinh doanh ▾</div></div>
<div class="row"><div class="field"><label>Miền *</label><div class="input mono">dkkd</div><div class="muted">Nhóm nghiệp vụ, ví dụ dkkd, hotich</div></div>
<div class="field"><label>Thực thể *</label><div class="input mono">doanh-nghiep</div><div class="muted">Đối tượng thay đổi</div></div>
<div class="field"><label>Sự kiện *</label><div class="input mono">da-tam-ngung</div><div class="muted">Động từ quá khứ: da-cap-phep, da-cap-nhat</div></div></div>
<div class="field"><label>Tên topic</label><div style="display:flex;gap:10px;align-items:center"><span class="mono" style="font-size:15px">t68.dkkd.doanh-nghiep.da-tam-ngung.v1</span> ⧉ {tag(OK,"✓ Còn trống")}<span class="muted">38/200 ký tự</span></div></div>
<div class="field"><label>Mô tả *</label><div class="input" style="height:70px;align-items:flex-start;padding-top:6px">Phát khi Sở KH-ĐT chấp thuận hồ sơ tạm ngừng kinh doanh của doanh nghiệp.</div><div class="muted" style="text-align:right">72 / 2.000</div></div>
<div class="alert w">ⓘ Miền <span class="mono">event</span>, <span class="mono">cdc</span>, <span class="mono">audit</span>… là miền dành riêng cho hệ thống và không dùng được ở đây.</div>
<div class="foot"><span class="btn">Hủy</span><span style="flex:1"></span><span class="btn">Lưu nháp</span><span class="btn pri">Tiếp tục ›</span></div></div>""")

# 08 Soạn và so sánh lược đồ
code = ['{', '  "type": "record",', '  "name": "DoanhNghiepDaCapPhep",', '  "namespace": "vn.datahub.t68.dkkd",', '  "fields": [',
        '    {"name": "maDoanhNghiep", "type": "string"},', '    {"name": "tenDoanhNghiep", "type": "string"},',
        '    {"name": "ngayCap", "type": {"type": "int", "logicalType": "date"}},', '    {"name": "vonDieuLe", "type": ["null", "long"], "default": null},',
        '    {"name": "soDienThoai", "type": ["null", "string"], "default": null}', '  ]', '}']
tx = "".join(f'<div class="{"add" if i in (8, 9) else ""}">{l}</div>' for i, l in enumerate(code))
P["08"] = ("Soạn và so sánh lược đồ", "Tích hợp › Topic sự kiện › t68.dkkd…da-cap-phep.v1 › Lược đồ", f"""
<div class="chrome"><h1>{mono(T1)} {tag(OK,"● Đang hoạt động")}</h1><div style="display:flex;gap:8px;align-items:center"><span class="muted">Avro · Tương thích lùi</span><span class="btn">Đổi</span><span style="flex:1"></span><span class="seg"><span class="on">Soạn</span><span>So sánh</span></span><span class="btn">+ Phiên bản mới</span></div></div>
{tabs(["Tổng quan","Cấu hình","Lược đồ","Quyền phát 1","Đăng ký nhận 4","DLQ 37","Cách kết nối","Lịch sử"],2)}
<div style="display:grid;grid-template-columns:250px minmax(0,1fr) 300px;gap:12px">
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Phiên bản</h3><div class="vtl"><div><b>v4</b> {tag(MU,"○ Nháp")}<br><span class="muted">Nguyễn An · hôm nay</span></div><div><b>v3</b> {tag(OK,"● Đang dùng")}<br><span class="muted">duyệt 12/11 · Lê Bình</span></div><div><b>v2</b> {tag(WA,"◐ Ngừng khuyến nghị")}<br><span class="muted">02/10</span></div><div><b>v1</b> {tag(MU,"Đã vô hiệu")}<br><span class="muted">01/09</span></div></div>
<div class="grp-t">Bên nhận đang đọc</div><div class="muted">v3: 3 bên · v2: 1 bên</div></div>
<div class="card" style="padding:10px"><div class="muted" style="margin-bottom:6px">Nội dung v4 (Nháp) · Avro</div><div class="ed"><div class="ln">{chr(10).join(str(i+1) for i in range(len(code)))}</div><div class="tx">{tx}</div></div>
<div class="foot" style="justify-content:flex-start"><span class="muted">Ghi chú thay đổi *</span><span class="input" style="flex:1;min-width:0;overflow:hidden">Thêm trường vonDieuLe, soDienThoai (tùy chọn)</span><span class="btn">Lưu nháp</span><span class="btn pri">Gửi duyệt</span></div></div>
<div class="card"><div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px"><h3 style="margin:0;font-size:15px">Kiểm tra</h3><span class="btn">Chạy kiểm tra</span></div>
<div class="verify"><div>{tag(OK,"✓")} Cú pháp</div><div>{tag(WA,"⚠ 1")} Quy ước: trường <span class="mono">vonDieuLe</span> thiếu <span class="mono">doc</span></div><div>{tag(OK,"✓")} Trường khóa <span class="mono">maDoanhNghiep</span></div><div>{tag(OK,"✓")} Tương thích lùi với v3</div><div>{tag(WA,"⚠ 1")} Dữ liệu cá nhân: <span class="mono">soDienThoai</span> (Cảnh báo)</div></div>
<div class="muted" style="margin-top:8px">Kiểm tra lúc 14:10 trên băm nội dung hiện tại; hiệu lực 24 giờ. Người duyệt phải xác nhận cảnh báo dữ liệu cá nhân.</div></div></div>""")

# 09 Bên phát
P["09"] = ("Bên phát", "Tích hợp › Topic sự kiện › Bên phát", f"""
<div class="head"><h1>Topic sự kiện</h1><div class="sp"></div><span class="btn pri">+ Đăng ký bên phát</span></div>
{subtabs(SUB_TP, 1)}
<div class="card"><div class="toolbar"><span class="input" style="min-width:280px">Tìm mã, tên, khóa tham chiếu, HTTT…</span><span class="input">Loại ▾</span><span class="input">Kiểu giao tiếp ▾</span><span class="input">Trạng thái ▾</span><span class="input">Dự án ▾</span></div>
{table(["Mã · Tên","Loại","Gắn với","Kiểu giao tiếp","Quyền phát","Trạng thái","Hoạt động gần nhất",""],[
[mono("ht-dkkd")+"<br>HTTT đăng ký kinh doanh","HTTT","HT-DKKD ●","Phát qua API HTTP","3 ●",tag(OK,"● Đang hoạt động"),"2 phút trước","⋯"],
[mono("dkkd-dong-bo-thue")+"<br>Luồng đồng bộ thuế","Luồng tích hợp","luồng PH-04 ●","Kafka nội bộ","1 ●",tag(OK,"● Đang hoạt động"),"10 giây trước","⋯"],
[mono("ht-hotich")+"<br>HTTT hộ tịch điện tử","HTTT","HT-HOTICH ●","Kafka trực tiếp","1 ●",tag(OK,"● Đang hoạt động"),"1 phút trước","⋯"],
[mono("ht-datdai")+"<br>HTTT đất đai","HTTT","HT-DATDAI ◐","Phát qua API HTTP","1 ◐",tag(WA,"◐ Tạm ngừng")+"<br><span class='muted'>Theo trạng thái HTTT ở PH-01</span>","3 ngày trước","⋯"],
[mono("dh-integration-cdc")+"<br>CDC của PH-05","Dịch vụ nội bộ","dh-integration","Outbox của DU","4 ●",tag(OK,"● Đang hoạt động"),"5 giây trước","⋯"],
[mono("hub-bridge-dkkd")+" "+tag(MU,"Hệ cũ")+"<br>Cầu nối Pulsar ĐKKD","Cầu nối hệ cũ","bridge-dkkd-01","Cầu nối Pulsar","1 ●",tag(OK,"● Đang hoạt động"),"30 giây trước","⋯"]],"Danh sách bên phát")}
{foot("1–6 / 42")}</div>""")

# 10 Bên nhận, chi tiết với tab Đăng ký nhận
P["10"] = ("Bên nhận", "Tích hợp › Topic sự kiện › Bên nhận › HTTT thuế tỉnh", f"""
<div class="chrome"><h1>‹ HTTT thuế tỉnh {tag(OK,"● Đang hoạt động")} {mono("ht-thue")}</h1><div style="display:flex;gap:8px;align-items:center"><span class="muted">HTTT HT-THUE (PH-01 ●) · Nhận đẩy webhook · Cục Thuế tỉnh T68</span><span style="flex:1"></span><span class="btn pri">Đăng ký nhận topic khác</span><span class="btn">Sửa</span><span class="btn">⋯ Tạm ngừng</span></div></div>
{tabs(["Tổng quan","Đăng ký nhận 3","Lịch sử"],1)}
<div class="card">{table(["Đăng ký nhận","Topic","Chế độ","Trạng thái","Mức cảnh báo","Độ trễ","DLQ mới"],[
[mono(S1),mono(T1),"Đẩy webhook",tag(OK,"● Đang nhận"),tag(WA,"⚠ Cảnh báo"),"12 ph 30 g","37"],
[mono("ht-thue-dn-giai-the"),mono(T2),"Đẩy webhook",tag(OK,"● Đang nhận"),tag(OK,"✓ Bình thường"),"4 g","0"],
[mono("ht-thue-dat-bien-dong"),mono(T4),"Đẩy webhook",tag(WA,"◐ Chờ duyệt"),"—","—","—"]],"Đăng ký nhận của bên nhận")}
<div class="alert i" style="margin:10px 0 0">ⓘ Tạm ngừng bên nhận làm mọi đăng ký nhận đang hiệu lực của bên này tạm ngừng; bộ giao nhận dừng gửi.</div></div>""")

# 11 Đăng ký nhận, bước 3 Đẩy webhook
sched = "".join(f'<i style="height:{h}px" title="lần {i+1}"></i>' for i, h in enumerate([2, 3, 5, 8, 14, 24, 40, 60]))
P["11"] = ("Đăng ký nhận sự kiện", "Tích hợp › Topic sự kiện › t68.dkkd…da-cap-phep.v1 › Đăng ký nhận", f"""
<div class="head"><h1>Đăng ký nhận · {mono(T1)}</h1></div>
<div class="steps"><div class="done">✓ Bên nhận</div><div class="done">✓ Chế độ: Đẩy webhook</div><div class="on">③ Cấu hình giao nhận</div><div>④ Điểm bắt đầu</div><div>⑤ Mục đích</div><div>⑥ Rà soát và gửi</div></div>
<div class="card" style="max-width:1040px">
<div class="grp-t" style="margin-top:0">Địa chỉ nhận</div>
<div style="display:flex;gap:8px"><div class="input mono" style="flex:1">https://thue.t68.gov.vn/hooks/dh</div><span class="btn">Xác minh</span></div>
<div class="verify" style="margin-top:8px"><div><b>Xác minh lúc 14:05</b> {tag(OK,"✓ Đạt")} <span class="muted">· hiệu lực tới 14:05 ngày 27/11</span></div>
<div>{tag(OK,"✓")} Phân giải DNS: 10.68.4.21, không thuộc dải nội bộ nền tảng</div><div>{tag(OK,"✓")} TLS 1.3, chứng thư hợp lệ tới 03/2027</div>
<div>{tag(OK,"✓")} Bắt tay OPTIONS: 204, WebHook-Allowed-Origin: event.t68.datahub</div><div>{tag(OK,"✓")} Trong danh sách egress</div></div>
<div class="grp-t">Song song và thời gian chờ</div>
<div class="row"><div class="field"><label>Số worker</label><div class="input">3</div><div class="muted">1…6: tối đa bằng số phân vùng 6 và trần 16</div></div><div class="field"><label>Thời gian chờ (ms)</label><div class="input">10000</div><div class="muted">1.000…30.000</div></div></div>
<div class="grp-t">Thử lại</div>
<div class="row"><div class="field"><label>Số lần thử lại</label><div class="input">8</div></div><div class="field"><label>Giãn cách đầu (ms)</label><div class="input">1000</div></div><div class="field"><label>Hệ số</label><div class="input">2</div></div><div class="field"><label>Giãn cách tối đa (ms)</label><div class="input">300000</div></div></div>
<div class="muted">Lịch thử lại: 1 g · 2 g · 4 g · 8 g · 16 g · 32 g · 64 g · 128 g, tổng khoảng 4 ph 15 g (±20%)</div><div class="sched">{sched}</div>
<div class="grp-t">Khi hết lượt thử</div>
<div class="rcards" style="grid-template-columns:1fr 1fr"><div class="rcard on"><b>◉ Dừng lại chờ khắc phục {tag(IN,"Khuyến nghị")}</b>Đăng ký nhận tạm ngừng khi một bản tin hết lượt thử; tiếp tục sau khắc phục, giao lại từ vị trí cũ.</div><div class="rcard"><b>○ Chuyển vào DLQ và giao tiếp</b>Bản tin lỗi vào hàng đợi lỗi; bản tin kế tiếp vẫn được giao. Thứ tự cùng khóa có thể bị phá.</div></div>
<div class="row"><span class="muted">Định dạng</span><span class="seg"><span class="on">CloudEvents có cấu trúc</span><span>CloudEvents nhị phân</span></span><span class="btn">Xem mẫu yêu cầu ▾</span><span class="muted">Hạn mức tiêu thụ: để trống, chia đều phần còn lại (còn 13,2 MiB/giây)</span></div>
<div class="foot"><span class="btn">Hủy</span><span style="flex:1"></span><span class="btn">‹ Quay lại</span><span class="btn pri">Tiếp tục ›</span></div></div>""")

# 12 Chi tiết subscription
lag = "M0,100 L60,98 L120,99 L180,96 L240,97 L300,92 L360,95 L420,90 L480,88 L540,76 L600,62 L660,56 L720,50"
lchart = f"""<svg viewBox="0 0 720 120" style="width:100%;height:150px" role="img" aria-label="Độ trễ 24 giờ với hai đường ngưỡng">
<rect x="600" y="20" width="120" height="42" fill="#fff4d6"/><line x1="0" y1="62" x2="720" y2="62" stroke="#c98a00"/><line x1="0" y1="20" x2="720" y2="20" stroke="#d64545" stroke-dasharray="6 4"/>
<path d="{lag}" fill="none" stroke="#0b5cd5" stroke-width="2"/><text x="6" y="58" font-size="11" fill="#7a5200">ngưỡng cảnh báo 5 phút</text><text x="6" y="16" font-size="11" fill="#a11a1a">ngưỡng nghiêm trọng 30 phút</text></svg>"""
P["12"] = ("Chi tiết subscription", "Tích hợp › Topic sự kiện › t68.dkkd…da-cap-phep.v1 › ht-thue-dn-cap-phep", f"""
<div class="chrome"><h1>‹ {mono(S1)} {tag(OK,"● Đang nhận")} {tag(MU,"Đẩy webhook")} {tag(WA,"⚠ Cảnh báo lag")}</h1>
<div style="display:flex;gap:8px;align-items:center"><span class="muted">Bên nhận HTTT thuế tỉnh (ht-thue) · Nhóm {mono("dh-sub-t68-ht-thue-dn-cap-phep")} ⧉</span><span style="flex:1"></span><span class="btn">Tạm dừng</span><span class="btn">Sửa tham số</span><span class="btn">Đề nghị phát lại</span><span class="btn">⋯</span></div></div>
{tabs(["Tổng quan","Giao nhận","Độ trễ","Lượt lỗi 12","Worker","Khóa ký","Cấu hình","Phát lại","Lịch sử"],0)}
<div class="alert w">⚠ Cảnh báo từ 13:52: độ trễ vượt 5 phút. Lỗi nhiều nhất ERR-10-112 (đầu nhận trả 503).<span class="sp"></span><span class="btn">Xác nhận cảnh báo</span></div>
<div class="kpis" style="--n:5"><div class="kpi" style="border-left:3px solid #c98a00"><span>Độ trễ</span><b>12 ph 30 g ⚠</b><small style="color:#7a5200">mức Cảnh báo</small></div><div class="kpi"><span>Tồn</span><b>4.210</b><small>bản tin</small></div><div class="kpi"><span>Thời gian còn lại</span><b>6 ng 23 g</b><small>trước khi bị xóa khỏi topic</small></div><div class="kpi"><span>Giao 1 giờ</span><b>98,7%</b><small>đạt</small></div><div class="kpi"><span>DLQ mới</span><b>37</b><small>→ Mở DLQ</small></div></div>
{card("Độ trễ 24 giờ", lchart + '<div class="legend"><span><i style="background:#0b5cd5"></i>Độ trễ</span><span><i style="background:#c98a00"></i>Ngưỡng cảnh báo (nét liền)</span><span><i style="background:#d64545"></i>Ngưỡng nghiêm trọng (nét đứt)</span><span class="sp" style="flex:1"></span><span>Xem dạng bảng</span></div>')}
<div class="card" style="margin-top:12px"><div class="dl"><dt>URL nhận</dt><dd class="mono">https://thue.t68.gov.vn/hooks/dh</dd><dt>Xác minh</dt><dd>{tag(OK,"✓ Đạt")} 14:05 hôm qua</dd><dt>Khóa ký</dt><dd>{mono("k_2026_11")} {tag(OK,"Đang dùng")}</dd><dt>Worker · thử lại</dt><dd>3 worker · 8 lần, giãn 1 g → 300 g · Dừng lại chờ khắc phục</dd></div></div>""")

# 13 Duyệt yêu cầu sự kiện
P["13"] = ("Duyệt yêu cầu sự kiện", "Việc của tôi › Sự kiện", f"""
<div class="head"><h1>Việc của tôi · Sự kiện</h1><div class="sp"></div><span class="input">Loại: Tất cả ▾</span><span class="input">Sắp xếp: Hạn gần ▾</span></div>
{facets(["Tất cả 7","Tạo topic 3","Quyền phát 2","Đăng ký nhận 2"],0)}
<div class="grid2" style="grid-template-columns:330px minmax(0,1fr)"><div class="card tree">
<div class="on"><b>Tạo topic</b><br>{mono(T3[:26]+"…")}<br><span class="muted">Nguyễn An · 1 ngày · hạn còn 29 ngày</span></div>
<div><b>Đăng ký nhận</b><br>{mono("ht-bhxh-hotich-khai-sinh")}<br><span class="muted">Trần Bình · 3 giờ</span></div>
<div><b>Quyền phát</b><br>{mono("ht-hotich → "+T3[:18]+"…")}<br><span class="muted">Nguyễn An · 5 giờ</span></div>
<div><b>Phát lại</b><br>{mono("rpl-01jd8k2")} · 37 mục DLQ<br><span class="muted">Phạm Cường · 20 phút</span></div>
<div><b>Tạo topic</b><br>{mono("t68.dkkd.doanh-nghiep.da-tam-ngung.v1")}<br><span class="muted">Nguyễn An · 10 phút</span></div></div>
<div class="card"><h3 style="margin:0 0 4px">Tạo topic {mono(T3)}</h3><div class="muted">Yêu cầu {mono("apr-01jd7x4m")} · gửi bởi Nguyễn An 25/11 09:12 · hạn 25/12 (còn 29 ngày)</div>
{tabs(["Khác biệt","Kiểm tra","Tác động","Lịch sử"],0)}
<div class="dl"><dt>Dự án</dt><dd>ho-tich-dien-tu</dd><dt>Phân loại</dt><dd>{tag(WA,"🔒 Hạn chế")}</dd><dt>Phân vùng · lưu giữ</dt><dd>3 · 30 ngày</dd><dt>Định tuyến</dt><dd>Theo khóa <span class="mono">soDinhDanh</span>, giữ thứ tự</dd><dt>Lược đồ</dt><dd>v1 Avro, tương thích lùi ▸ xem</dd><dt>Dọn</dt><dd>Xóa theo thời gian</dd></div>
<div class="alert w" style="margin-top:12px">⚠ Dữ liệu cá nhân: trường <span class="mono">hoTenMe</span>, <span class="mono">ngaySinh</span> (Cảnh báo). Topic Hạn chế, bên nhận phải đạt cấp độ ATTT.</div>
<div style="margin:6px 0">☑ Tôi đã xem các cảnh báo dữ liệu cá nhân *</div>
<div class="field"><label>Ý kiến *</label><div class="input" style="height:56px;align-items:flex-start;padding-top:6px">Đồng ý; lược đồ đúng quy ước, trường cá nhân cần thiết cho nghiệp vụ liên thông khai sinh.</div></div>
<div class="foot"><span class="btn danger">Từ chối</span><span class="btn pri">Duyệt</span></div></div></div>""")

# 14 Sơ đồ kết nối
nodes = [("ht-dkkd", "HTTT ĐKKD ●", 40, 70, ""), ("dkkd-dong-bo", "⟲ Luồng PH-04 ●", 40, 250, "flow"), ("ht-hotich", "HTTT hộ tịch ●", 40, 420, ""),
         (T1, "Nghiệp vụ ● · DLQ 37", 360, 70, "topic sel"), (T2, "Nghiệp vụ ◐ Ngừng khuyến nghị", 360, 250, "topic"), (T3, "Nghiệp vụ ● · 🔒 Hạn chế", 360, 420, "topic dim"),
         ("ht-thue", "HTTT thuế tỉnh ⚠", 740, 40, "susp"), ("ht-bhxh", "BHXH tỉnh ●", 740, 150, ""), ("ht-thongke", "Cục Thống kê Ⅱ", 740, 260, ""),
         ("dkkd-thue", "⟲ Luồng PH-04 ●", 740, 360, "flow"), ("ht-ubnd-xa", "UBND cấp xã ●", 740, 470, "dim")]
nh = "".join(f'<div class="node {k}" style="left:{x}px;top:{y}px"><b>{c}</b><span class="muted">{s}</span></div>' for c, s, x, y, k in nodes)
edges = f"""<svg viewBox="0 0 1162 600" aria-hidden="true"><defs><marker id="a" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 z" fill="#6b7480"/></marker></defs>
<g fill="none" stroke="#6b7480" stroke-width="1.5" marker-end="url(#a)"><path d="M240,98 L360,102"/><path d="M240,278 L360,282"/><path d="M240,278 C300,278 300,110 360,110" stroke-dasharray="2 0"/><path d="M240,448 L360,452" opacity=".35"/>
<path d="M630,95 C690,95 720,68 740,68" stroke="#c98a00" stroke-width="3"/><path d="M630,102 C690,102 720,178 740,178"/><path d="M630,108 C690,108 720,288 740,288" stroke-dasharray="3 4"/><path d="M630,282 C690,282 720,388 740,388"/><path d="M630,452 C690,452 720,498 740,498" opacity=".35"/></g></svg>"""
labels = '<span class="elabel" style="left:276px;top:84px">API</span><span class="elabel" style="left:262px;top:264px">Kafka nội bộ</span><span class="elabel" style="left:640px;top:58px;border-color:#c98a00;color:#7a5200">Đẩy ⚠ 12 ph 30 g</span><span class="elabel" style="left:650px;top:150px">Kéo API ✓ 40 g</span><span class="elabel" style="left:640px;top:232px">Ⅱ Kéo API · Tạm dừng</span><span class="elabel" style="left:650px;top:338px">Nội bộ ✓ 3 g</span>'
P["14"] = ("Sơ đồ kết nối", "Tích hợp › Sơ đồ kết nối", f"""
<div class="head"><h1>Sơ đồ kết nối · Liên thông đăng ký kinh doanh</h1><div class="sp"></div><span class="btn">⟳ 14:02</span><span class="seg"><span class="on">Đồ thị</span><span>Danh sách</span></span><span class="btn">Xuất ▾</span><span class="btn">⛶</span></div>
<div class="toolbar" style="margin:0 0 10px;border:1px solid var(--color-border);border-radius:10px"><span class="input">Dự án: Liên thông ĐKKD ▾</span><span class="input">Topic ▾</span><span class="input">HTTT ▾</span><span class="input" style="min-width:200px">Tìm nút: maDN, ht-thue…</span><span class="input">Trạng thái: Mọi ▾</span><span class="muted">☐ Gồm đã ngừng</span></div>
<div class="canvas"><span class="layer" style="left:40px">BÊN PHÁT</span><span class="layer" style="left:360px">TOPIC</span><span class="layer" style="left:740px">BÊN NHẬN</span>{edges}{nh}{labels}
<div class="glassbox" style="right:14px;top:14px;width:150px"><div class="muted" style="margin-bottom:4px">Lớp phủ</div><div class="tree"><div>Không phủ</div><div class="on">Độ trễ</div><div>Lưu lượng</div><div>DLQ</div></div></div>
<div class="glassbox" style="left:14px;bottom:42px"><span class="seg"><span>−</span><span>85%</span><span>+</span><span>⤢</span><span>⌖</span><span>🔒</span><span>?</span></span></div>
<div class="glassbox" style="right:14px;bottom:42px;width:200px;height:110px"><div style="background:#e6efff;border:1px solid #bcd2fb;width:120px;height:70px;margin:12px 30px"></div></div>
<div class="statusbar">11 nút · 9 cạnh · 1 cảnh báo · đang làm nổi đường đi qua {mono(T1)} · độ trễ cập nhật 14:02:01 · bố cục tự động</div></div>""")

# 15 DLQ tầng sự kiện
dl = lambda t, s, o, e, a, sub, st: ["☐", t, mono(s), o, e, a, mono(sub), st]
P["15"] = ("DLQ tầng sự kiện", "Tích hợp › Topic sự kiện › t68.dkkd…da-cap-phep.v1 › DLQ", f"""
<div class="chrome"><h1>{mono(T1)} {tag(OK,"● Đang hoạt động")}</h1><span class="muted">Hàng đợi lỗi của topic · 37 mục mới</span></div>
{tabs(["Tổng quan","Cấu hình","Lược đồ","Quyền phát 1","Đăng ký nhận 4","DLQ 37","Cách kết nối","Lịch sử"],5)}
<div class="card"><div class="toolbar"><span class="input">Đăng ký nhận: Tất cả ▾</span><span class="input">Trạng thái: Mới ▾</span><span class="input">Mã lỗi ▾</span><span class="input">Từ 20/11 đến 26/11</span><span class="input" style="min-width:180px">Mã sự kiện</span></div>
{table(["","Lỗi đầu","Đăng ký nhận","Nguồn","Mã lỗi","Lần","Subject","Trạng thái"],[
dl("25/11 21:04",S1,"Giao đẩy","Đầu nhận lỗi tạm thời (ERR-10-112)","9","0312456789",tag(ER,"● Mới")),
dl("25/11 21:03",S1,"Giao đẩy","Đầu nhận lỗi tạm thời (ERR-10-112)","9","0312987001",tag(ER,"● Mới")),
dl("25/11 18:47",S1,"Giao đẩy","Đầu nhận từ chối (ERR-10-113)","1","0315550123",tag(ER,"● Mới")),
dl("24/11 10:12","ht-bhxh-dn-cap-phep","Bên nhận kéo báo lỗi","Đầu nhận từ chối (ERR-10-113)","1","0310001234",tag(IN,"⟳ Đang phát lại")),
dl("23/11 08:30",S1,"Giao đẩy","Quá thời gian chờ (ERR-10-111)","9","0319876543",tag(MU,"Đã loại bỏ"))],"Danh sách mục DLQ")}
<div class="alert i" style="margin:10px 0 0">Đã chọn 3 <span class="btn">Phát lại</span><span class="btn">Loại bỏ</span><span class="sp"></span>Xuất danh sách (không gồm nội dung)</div></div>""", drawer("Mục DLQ dlq-01jd9a7", f"""
<div class="dl" style="grid-template-columns:130px 1fr"><dt>Đăng ký nhận</dt><dd class="mono">{S1}</dd><dt>Phân vùng, offset</dt><dd class="mono">p2 · 118.204</dd><dt>Loại sự kiện</dt><dd class="mono">vn.t68.dkkd.doanh-nghiep.da-cap-phep</dd><dt>Mã lỗi</dt><dd>ERR-10-112 · HTTP 503</dd><dt>Số lần thử</dt><dd>9</dd><dt>Lỗi đầu, lỗi cuối</dt><dd>21:04 · 21:08</dd></div>
<div class="alert w" style="margin-top:12px">Topic Nội bộ: xem nội dung được ghi kiểm toán. Topic Hạn chế, Nhạy cảm phải nhập lý do.</div>
<div class="foot"><span class="btn">Loại bỏ</span><span class="btn pri">Xem nội dung</span></div>""", 440))

# 16 Phát lại sự kiện
pr = lambda d, f: f'<div class="prog" style="width:120px"><i style="width:{d}%"></i></div><span class="muted">{f}</span>'
P["16"] = ("Phát lại sự kiện", "Tích hợp › Topic sự kiện › Phát lại", f"""
<div class="head"><h1>Topic sự kiện</h1><div class="sp"></div><span class="btn pri">+ Đề nghị phát lại</span></div>
{subtabs(SUB_TP, 3)}
<div class="card"><div class="toolbar"><span class="input">Đăng ký nhận ▾</span><span class="input">Kiểu ▾</span><span class="input">Trạng thái ▾</span><span class="input">Người đề nghị ▾</span></div>
{table(["Mã","Đăng ký nhận","Kiểu","Phạm vi","Ước lượng","Tiến độ","Trạng thái","Người đề nghị","Bắt đầu",""],[
[mono("rpl-01jd8k2"),mono(S1),"Phát lại mục DLQ","37 mục DLQ","37","—",tag(WA,"◐ Chờ duyệt"),"Phạm Cường","—",""],
[mono("rpl-01jd6p1"),mono(S2),"Giao lại một khoảng","24/11 08:00 → 24/11 12:00","2.140",pr(62,"1.327 / 2.140 · 0 lỗi"),tag(IN,"▶ Đang chạy"),"Phạm Cường","14:01","<span class='btn'>Hủy</span>"],
[mono("rpl-01jd2c9"),mono("ht-thongke-dn-cap-phep"),"Đặt lại vị trí đọc","từ 20/11 00:00","9.800",pr(100,"9.800 / 9.800"),tag(OK,"✓ Hoàn tất"),"Lê Dung","21/11 09:30",""],
[mono("rpl-01jcz77"),mono(S1),"Giao lại một khoảng","p0…p5 · offset 110.000 → 112.500","2.500",pr(100,"2.497 / 2.500 · 3 lỗi"),tag(OK,"✓ Hoàn tất"),"Phạm Cường","18/11 15:10","Xem 3 mục vào DLQ"],
[mono("rpl-01jcy10"),mono(S2),"Giao lại một khoảng","10/11 → 12/11","15.000","—",tag(ER,"✕ Bị từ chối"),"Lê Dung","—",""]],"Danh sách lượt phát lại")}
{foot("1–5 / 5")}</div>""")

# 17 Độ trễ tiêu thụ
P["17"] = ("Theo dõi độ trễ tiêu thụ", "Tích hợp › Topic sự kiện › Độ trễ", f"""
<div class="head"><h1>Topic sự kiện</h1><div class="sp"></div><span class="muted">Cập nhật 14:02:01</span><span class="btn">⟳</span><span class="muted">Tự làm mới ●</span></div>
{subtabs(SUB_TP, 4)}
<div class="card"><div class="toolbar">{facets(["⏸ Ngừng tiến 1","✕ Nghiêm trọng 1","⚠ Cảnh báo 4","✓ Bình thường 58"],-1).replace('class="facets"','class="facets" style="margin:0"')}<div style="flex:1"></div><span class="input">Dự án ▾</span><span class="input">Chế độ ▾</span></div>
{table(["Đăng ký nhận","Topic","Bên nhận","Chế độ","Mức","Độ trễ","Tồn","Còn lại","1 giờ","Xác nhận"],[
[mono(S2),mono("t68.dkkd…da-cap-phep.v1"),"BHXH tỉnh","Kéo API",tag(ER,"⏸ Ngừng tiến"),"41 ph","9.802","6 ng 23 g",spark([4,5,6,8,10,12,14,16,18]),"<span class='btn'>Xác nhận</span>"],
[mono("ht-ubnd-xa-khai-sinh"),mono("t68.hotich…da-dang-ky.v1"),"UBND cấp xã","Đẩy webhook",tag(ER,"✕ Nghiêm trọng"),"38 ph","1.204","29 ng 23 g",spark([3,5,8,10,12,13,15,16,17]),"<span class='btn'>Xác nhận</span>"],
[mono(S1),mono("t68.dkkd…da-cap-phep.v1"),"HTTT thuế tỉnh","Đẩy webhook",tag(WA,"⚠ Cảnh báo"),"12 ph 30 g","4.210","6 ng 23 g",spark([2,3,3,4,6,8,9,10,11]),"Trần Bình 13:55<br><span class='muted'>tắt nhắc 4 giờ</span>"],
[mono("ht-thongke-dat-bien-dong"),mono("t68.datdai…da-bien-dong.v1"),"Cục Thống kê","Kéo API",tag(WA,"⚠ Cảnh báo"),"7 ph","310","6 ng 23 g",spark([2,2,3,3,4,4,5,5,6]),"<span class='btn'>Xác nhận</span>"],
[mono("ht-bhxh-hotich"),mono("t68.hotich…da-dang-ky.v1"),"BHXH tỉnh","Kéo API",tag(WA,"⚠ Cảnh báo"),"6 ph 10 g","96","29 ng 23 g",spark([1,2,2,3,3,4,4,4,5]),"<span class='btn'>Xác nhận</span>"],
[mono("ht-tnmt-dkkd"),mono("t68.dkkd…da-cap-phep.v1"),"Sở TN-MT","Đẩy webhook",tag(WA,"⚠ Cảnh báo"),"5 ph 20 g","88","6 ng 23 g",spark([1,1,2,2,3,3,4,4,4]),"<span class='btn'>Xác nhận</span>"]],"Đăng ký nhận theo mức cảnh báo")}
<div class="muted" style="margin-top:8px">Sắp xếp mức nặng trước rồi theo độ trễ giảm dần. Xác nhận không tắt việc đánh giá, chỉ tắt nhắc 4 giờ.</div></div>""")

# 18 Cài đặt sự kiện
P["18"] = ("Cài đặt sự kiện", "Tích hợp › Topic sự kiện › Cài đặt", f"""
<div class="head"><h1>Topic sự kiện</h1></div>
{subtabs(SUB_TP, 5)}
{tabs(["Kiểu giao tiếp","Chế độ định tuyến","Hạn mức","Tham số"],3)}
<div class="grid2" style="grid-template-columns:200px minmax(0,1fr)"><div class="card tree"><div>topic</div><div>schema</div><div class="on">push</div><div>pull</div><div>lag</div><div>dlq</div><div>replay</div><div>quota</div><div>migration</div></div>
<div class="card">{table(["Khóa","Giá trị","Mặc định","Miền","Phạm vi","Ý nghĩa"],[
[mono("10.push.default-workers"),"3","3","1…16","T","Số worker mặc định của đăng ký nhận đẩy"],
[mono("10.push.max-workers"),"16","16","1…64","N (PA)","Trần worker mỗi đăng ký nhận"],
[mono("10.push.timeout-ms"),"10000","10000","1.000…30.000","T","Thời gian chờ đầu nhận"],
[mono("10.push.max-retries"),"<span class='input' style='min-width:70px;border-color:#0b5cd5'>8</span>","8","0…20","T","Số lần thử lại mặc định"],
[mono("10.push.backoff-initial-ms"),"1000","1000","100…60.000","T","Giãn cách lần thử đầu"],
[mono("10.push.backoff-multiplier"),"2","2","1…5","T","Hệ số giãn cách"],
[mono("10.push.backoff-max-ms"),"300000","300000","1.000…3.600.000","T","Giãn cách tối đa"],
[mono("10.push.key-max-age-days"),"180","180","30…730","T","Tuổi tối đa của khóa ký trước khi nhắc xoay"]],"Tham số nhóm push")}
<div class="muted" style="margin-top:8px">Thay đổi áp dụng cho đối tượng tạo mới; ngưỡng lag mặc định áp dụng ngay. Tham số phạm vi N chỉ quản trị nền tảng sửa.</div>
<div class="foot"><span class="muted" style="flex:1">1 thay đổi chưa lưu</span><span class="btn">Hủy</span><span class="btn pri">Lưu (cần lý do)</span></div></div></div>""")

# 19 Nhập khai báo
ck = {"CREATE": ("d-add", "Thêm"), "UPDATE": ("d-chg", "Sửa"), "UNCHANGED": ("", "Không đổi"), "CONFLICT": ("d-del", "Xung đột"), "SKIP": ("", "Bỏ qua")}
rows19 = [("Dự án", "bao-tro-xa-hoi", "CREATE", ""), ("Topic", "t68.btxh.tro-cap.da-phe-duyet.v1", "CREATE", ""), ("Topic", "t68.btxh.tro-cap.da-cham-dut.v1", "CREATE", ""),
          ("Bên phát", "ht-btxh", "UPDATE", "commType: HTTP_PUBLISH → KAFKA_NATIVE"), ("Quyền phát", "ht-btxh → t68.btxh.tro-cap.da-phe-duyet.v1", "CREATE", ""),
          ("Đăng ký nhận", "ht-ubnd-xa-tro-cap", "CONFLICT", "ERR-10-050: bên nhận ht-ubnd-xa không có ở tenant đích"), ("Bên nhận", "ht-bhxh", "UNCHANGED", "")]
tb = "".join(f'<tr class="{ck[k][0]}"><td>{a}</td><td class="mono">{b}</td><td>{ck[k][1]}</td><td>{c}</td></tr>' for a, b, k, c in rows19)
P["19"] = ("Nhập khai báo", "Tích hợp › Dự án sự kiện › Nhập khai báo", f"""
<div class="head"><h1>Dự án sự kiện</h1></div>
{subtabs(SUB_DA, 2)}
<div class="alert i">ⓘ Chức năng Đợt sau (FR-10-071). Màn này minh họa thiết kế, chưa bật trên môi trường thật.</div>
<div class="steps"><div class="done">✓ Tải tệp: bao-tro-xa-hoi.manifest.yaml</div><div class="on">② Xem trước khác biệt</div><div>③ Xác nhận áp dụng</div></div>
<div class="card">{facets(["Tất cả 7","Thêm 4","Sửa 1","Xung đột 1","Không đổi 1"],0)}
<table aria-label="Xem trước khác biệt"><thead><tr><th>Loại đối tượng</th><th>Mã</th><th>Thay đổi</th><th>Chi tiết</th></tr></thead><tbody>{tb}</tbody></table>
<div class="alert e" style="margin:10px 0 0">1 xung đột phải xử lý (sửa tệp hoặc bỏ qua dòng) trước khi áp dụng.</div>
<div class="muted">Mọi topic, quyền phát, đăng ký nhận được tạo ở trạng thái đầu và vẫn qua duyệt.</div>
<div class="foot"><span class="btn">Hủy tác vụ</span><span style="flex:1"></span><span class="btn">‹ Tải tệp khác</span><span class="btn pri" style="opacity:.45">Áp dụng ›</span></div></div>""")

# 20 Di trú từ Pulsar
P["20"] = ("Di trú từ Pulsar", "Tích hợp › Dự án sự kiện › Di trú", f"""
<div class="head"><h1>Dự án sự kiện</h1><div class="sp"></div><span class="btn">Xuất Excel</span></div>
{subtabs(SUB_DA, 3)}
{tabs(["Tiến độ","Ánh xạ 64","Cầu nối 5","Đối chiếu"],2)}
{kpis([("Ánh xạ đã chuyển hẳn","18 / 64","28%",""),("Đang chạy song song","5","cầu nối",""),("HTTT còn qua Pulsar","11","",""),("Ngày dự kiến tắt Hub","31/03/2027","giả định","")])}
<div class="alert w">⚠ Cầu nối {mono("bridge-hotich-01")} có độ trễ 9 phút, vượt ngưỡng 5 phút của tham số 10.migration.bridge-max-lag-seconds.</div>
<div class="card"><div class="toolbar"><span class="input">Trạng thái ▾</span><span class="input">Chiều ▾</span><div style="flex:1"></div><span class="btn pri">+ Tạo cầu nối</span></div>
{table(["Mã","Chiều","Topic Pulsar","Topic Kafka","Trạng thái","Đã chuyển","Độ trễ","Hết hạn",""],[
[mono("bridge-dkkd-01"),"Pulsar sang Kafka",mono("persistent://t68/dkkd/dn-cap-phep"),mono(T1),tag(OK,"● Đang chạy"),"1.204.330","4 g","15/12/2026","Dừng · Chuyển hẳn"],
[mono("bridge-hotich-01"),"Pulsar sang Kafka",mono("persistent://t68/hotich/khai-sinh"),mono(T3),tag(WA,"● Đang chạy · trễ"),"402.118","9 ph","20/12/2026","Dừng"],
[mono("bridge-datdai-01"),"Pulsar sang Kafka",mono("persistent://t68/datdai/bien-dong"),mono(T4),tag(ER,"✕ Lỗi"),"88.010","—","20/12/2026","Tiếp tục"],
[mono("bridge-dkkd-02"),"Kafka sang Pulsar",mono("persistent://t68/dkkd/dn-giai-the"),mono(T2),tag(WA,"◐ Chờ duyệt"),"0","—","30/12/2026",""],
[mono("bridge-thue-01"),"Pulsar sang Kafka",mono("persistent://t68/thue/to-khai"),mono("t68.thue.to-khai.da-nop.v1"),tag(MU,"Đã dừng"),"2.010.554","—","01/12/2026","Tiếp tục"]],"Danh sách cầu nối di trú")}</div>""")


for code, (title, crumb, body, *extra) in P.items():
    (OUT / f"ui-10-{code}.html").write_text(shell(code, title, crumb, body, extra[0] if extra else ""), encoding="utf-8")
print("Đã sinh", len(P), "trang")
