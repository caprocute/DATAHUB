#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-03-01…18 (D03-06-PH03, ảnh sau bảng đặc tả của từng màn).

Chạy: python3 gen_hifi.py ; chụp ảnh: node shot.js
Dữ liệu là giả định của tỉnh thí điểm T68. Phong cách Liquid Glass của D03-05: kính chỉ ở lớp điều hướng
và lớp nổi (thanh trên, sidebar, drawer), nội dung dày dùng nền đặc. Cách làm chép từ ph19/hifi/gen_hifi.py.
"""
import pathlib

OUT = pathlib.Path(__file__).parent

NAV = [("|Quan sát", None), ("Tổng quan", "01"), ("Nhật ký lượt gọi", "09"), ("WAF", "07"), ("Ngoại lệ WAF", "08"),
       ("|Cấu hình", None), ("Route", "02"), ("Consumer", "04"), ("Hạn mức", "06"), ("Mẫu chính sách", "13"),
       ("Địa chỉ bị chặn", "15"), ("Tham số", "16"),
       ("|Phát hành và nút", None), ("Cấu hình đã phát", "10"), ("Nút gateway", "11"), ("Chứng thư và TLS", "12"),
       ("Nhập từ gateway cũ", "18")]
BADGE = {"01": "<span class='tag t-err'>1</span>", "08": "<span class='tag t-warn'>2</span>",
         "04": "<span class='tag t-warn'>1</span>", "11": "<span class='tag t-err'>1</span>",
         "12": "<span class='tag t-warn'>1</span>", "10": "<span class='tag t-err'>1</span>"}
ACTIVE = {"01": "01", "02": "02", "03": "02", "04": "04", "05": "04", "06": "06", "07": "07", "08": "08", "09": "09",
          "10": "10", "11": "11", "12": "12", "13": "13", "14": "02", "15": "15", "16": "16", "17": "", "18": "18"}


def shell(code, title, crumb, body, extra=""):
    nav = ""
    if code == "17":
        nav += '<div class="grp">Việc của tôi</div><a class="on" href="#">Hộp việc <span class="tag t-info">3</span></a>'
    for n, c in NAV:
        if n.startswith("|"):
            nav += f'<div class="grp">{n[1:]}</div>'
            continue
        nav += f'<a class="{"on" if ACTIVE[code] == c else ""}" href="#">{n} {BADGE.get(c, "")}</a>'
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-03-{code} · {title}</title><link rel="stylesheet" href="hifi.css"></head><body>
<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Cổng API</div><div class="search">Tìm route, consumer, mã lỗi…  Ctrl K</div><div class="sp"></div>
<span class="tray">⟳ 1 tác vụ nền</span><span class="tray">T68 · Tỉnh thí điểm</span><div class="avatar">TA</div></header>
<nav class="side" aria-label="Điều hướng chính">{nav}</nav>
<main><div class="crumb">{crumb}</div>{body}</main></div>{extra}<div class="hint">Bản hi-fi minh họa · D03-06-PH03 · UI-03-{code} · dữ liệu giả định</div></body></html>"""


def table(head, data, label=""):
    th = "".join(f"<th>{h}</th>" for h in head)
    tr = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in data)
    return f'<table aria-label="{label}"><thead><tr>{th}</tr></thead><tbody>{tr}</tbody></table>'


def tag(kind, text):
    return f"<span class='tag t-{kind}'>{text}</span>"


def tabs(items, on):
    return '<div class="tabs" role="tablist">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def facets(items, on=0):
    return '<div class="facets">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def kpis(items, n=None):
    n = n or len(items)
    cells = "".join(f'<div class="kpi {c}"><span>{a}</span><b>{b}</b><small>{d}</small></div>' for a, b, d, c in items)
    return f'<div class="kpis" style="--n:{n}">{cells}</div>'


def foot(text="Hiển thị 1–20"):
    return f'<div class="foot" style="justify-content:space-between"><span class="muted">{text}</span><span class="muted">‹ 1 2 3 › · 20 / trang</span></div>'


def drawer(title, inner, width=480):
    return f'<div class="drawer" role="dialog" aria-label="{title}" style="width:{width}px"><h3 style="margin:0 0 10px">{title}</h3>{inner}</div>'


def mono(t):
    return f"<span class='mono'>{t}</span>"


def num(t):
    return f"<span class='num'>{t}</span>"


def prog(p, warn=False):
    col = "#d08a00" if warn else "#0b5cd5"
    return f"<div class='prog' style='width:110px;display:inline-block;vertical-align:middle'><i style='width:{p}%;background:{col}'></i></div>"


def field(label, val, mono_=False, hint=""):
    h = f'<div class="muted">{hint}</div>' if hint else ""
    return f'<div class="field"><label>{label}</label><div class="input{" mono" if mono_ else ""}">{val}</div>{h}</div>'


def toolbar(*parts, right=""):
    return '<div class="toolbar">' + "".join(f'<span class="input">{p}</span>' for p in parts) + f'<div style="flex:1"></div>{right}</div>'


OK, WA, ER, IN, MU = "ok", "warn", "err", "info", "mute"
P = {}
RUN, STOP, SUSP, SUN, PEND = tag(OK, "✓ Đang chạy"), tag(WA, "⏸ Đã dừng"), tag(ER, "⛔ Tạm ngừng khẩn cấp"), tag(WA, "⚠ Sắp ngừng phục vụ"), tag(MU, "◔ Chờ nạp")
INT, EXT = tag(MU, "Nội bộ"), tag(IN, "🌐 Internet")

# ---------------------------------------------------------------- 01 Tổng quan lưu lượng
pts = [180, 210, 260, 310, 420, 520, 610, 700, 760, 842, 790, 720, 650, 700, 780, 830, 900, 1050, 1120, 980, 860, 800, 760, 842]
mx = 1200
w, h = 900, 150


def poly(vals, base=None):
    n = len(vals)
    top = [(i * w / (n - 1), h - v / mx * h) for i, v in enumerate(vals)]
    bot = [(i * w / (n - 1), h - (base[i] / mx * h if base else 0)) for i in range(n - 1, -1, -1)]
    return " ".join(f"{x:.0f},{y:.0f}" for x, y in top + bot), top


s2 = [v * .93 for v in pts]
s4 = [v * .05 for v in pts]
s5 = [v * .006 for v in pts]
a1, _ = poly([a + b + c for a, b, c in zip(s2, s4, s5)], [a + b for a, b in zip(s2, s4)])
a2, _ = poly([a + b for a, b in zip(s2, s4)], s2)
a3, _ = poly(s2)
area = f"""<svg class="area" viewBox="0 0 {w} {h}" preserveAspectRatio="none" role="img" aria-label="Lưu lượng 24 giờ, đỉnh 1.120 lượt/giây lúc 10:14">
<defs><pattern id="p4" width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><rect width="6" height="6" fill="#f3c969"/><line x1="0" y1="0" x2="0" y2="6" stroke="#b47f00" stroke-width="2"/></pattern>
<pattern id="p5" width="6" height="6" patternUnits="userSpaceOnUse"><rect width="6" height="6" fill="#f4a3a3"/><circle cx="3" cy="3" r="1.4" fill="#a11a1a"/></pattern></defs>
<polygon points="{a3}" fill="#7fc9a0"/><polygon points="{a2}" fill="url(#p4)"/><polygon points="{a1}" fill="url(#p5)"/></svg>"""
rank = [("Trục tích hợp NDXP", "ESSENTIAL", 310, "0,2%", 71), ("Cổng DVC tỉnh", "ESSENTIAL", 208, "0,4%", 64), ("Một cửa điện tử", "NORMAL", 141, "0,6%", 83),
        ("Hộ tịch điện tử, Sở Tư pháp", "NORMAL", 96, "0,3%", 38), ("Quản lý cấp phép xây dựng", "NORMAL", 52, "1,1%", 22)]
hb = "".join(f'<div class="hbar" style="grid-template-columns:190px 1fr 120px"><span>{n} {tag(IN, "Thiết yếu") if g == "ESSENTIAL" else ""}</span>'
             f'<span><div class="prog"><i style="width:{p}%;background:{"#d08a00" if p >= 80 else "#0b5cd5"}"></i></div></span><span class="num">{l}/s · lỗi {e} · {p}%{" ⚠" if p >= 80 else ""}</span></div>' for n, g, l, e, p in rank)
P["01"] = ("Tổng quan lưu lượng", "Cổng API / Tổng quan", f"""
<div class="head"><h1>Tổng quan lưu lượng</h1><span class="muted">Làm mới 15 giây · 10:41:07</span><div class="sp"></div><span class="facets" style="margin:0">{''.join(f'<span class="{"on" if i == 2 else ""}">{t}</span>' for i, t in enumerate(["15 phút", "1 giờ", "24 giờ", "7 ngày"]))}</span><span class="input">HTTT: Tất cả ▾</span><span class="input">Route: Tất cả ▾</span><span class="btn">⏸</span><span class="btn">⟳</span></div>
<div class="alert w" role="alert">⚠ Valkey không khả dụng từ 10:02: bộ đếm hạn mức đang chạy cục bộ theo số bản sao. Hạn mức vẫn được áp dụng.<span class="sp"></span><span class="btn">Xem nút gateway</span></div>
{kpis([("Lượt gọi mỗi giây", "842", "▲ tăng 3% so với kỳ trước", ""), ("Tỷ lệ lỗi", "0,42 %", "▼ giảm 0,1 điểm", ""), ("Độ trễ thêm p95 (mục tiêu 50 ms)", "<span style='color:#7a5200'>44 ms ⚠</span>", "<span style='color:#7a5200'>▲ vượt ngưỡng cảnh báo 40 ms</span>", ""), ("Kết nối đang mở", "3.210", "▲ tăng 1%", ""), ("Nút đồng bộ", "6/6 ✓", "Phiên bản 1287", "")])}
<div class="card" style="margin-bottom:12px"><h3 style="margin:0 0 6px;font-size:15px">Lưu lượng theo thời gian, 24 giờ</h3>{area}
<div class="legend"><span><i style="background:#7fc9a0"></i>2xx</span><span><i style="background:#f3c969"></i>4xx (nền sọc)</span><span><i style="background:#f4a3a3"></i>5xx và bị gateway từ chối (nền chấm)</span><span style="flex:1"></span><span>Xem dạng bảng</span></div></div>
<div class="grid-2e"><div class="card"><h3 style="margin:0 0 8px;font-size:15px">HTTT theo lưu lượng, thanh mức dùng so với hạn mức</h3>{hb}</div>
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Route theo lưu lượng, độ trễ</h3>{table(["Route", "Lượt/giây", "p95", "Lỗi"], [[mono("tra-cuu-cong-dan.v1"), num(310), num("41 ms"), num("0,2%")], [mono("cap-phep-xd.v2"), num(142), num("88 ms"), num("1,1%")], [mono("thanh-toan-callback.v1"), num(96), num("52 ms"), num("0,3%")], [mono("danh-muc-dung-chung.v1"), num(88), num("23 ms"), num("0,0%")]], "Xếp hạng route")}</div></div>
<div class="grid-2e" style="margin-top:12px"><div class="card"><h3 style="margin:0 0 8px;font-size:15px">Cảnh báo đang mở</h3>
<div class="alert e" style="margin-bottom:6px">{tag(ER, "Nghiêm trọng")} Chứng thư biên còn 6 ngày · 10:02<span class="sp"></span><span class="btn">Xác nhận</span></div>
<div class="alert w" style="margin-bottom:6px">{tag(WA, "Cao")} Nút apisix-ext-2 chậm 2 phiên bản · 10:30<span class="sp"></span><span class="btn">Xác nhận</span></div>
<div class="alert i" style="margin-bottom:0">{tag(IN, "Trung bình")} HTTT Một cửa điện tử đạt 83% hạn ngạch tháng · 09:48<span class="sp"></span><span class="btn">Xác nhận</span></div></div>
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Kiểm tra tổng hợp</h3>{table(["API quan trọng", "Trạng thái", "Độ trễ", "Lỗi gần nhất"], [["Tra cứu công dân", f"<span class='dot ok'></span>Lên", num("38 ms"), "—"], ["Cấp phép xây dựng", f"<span class='dot ok'></span>Lên", num("92 ms"), "—"], ["Callback thanh toán", f"<span class='dot er'></span>Xuống", "—", "09:12"], ["Danh mục dùng chung", f"<span class='dot ok'></span>Lên", num("21 ms"), "—"]], "Kiểm tra tổng hợp")}</div></div>""")

# ---------------------------------------------------------------- 02 Danh sách route
menu = '<div style="position:absolute;right:30px;margin-top:-6px;background:var(--color-surface-glass-thick);backdrop-filter:blur(24px);border:1px solid rgba(255,255,255,.9);border-radius:12px;box-shadow:0 12px 32px rgba(20,40,80,.18);padding:6px;width:210px;font-size:13px;z-index:5"><div style="padding:6px 10px">Mở chi tiết</div><div style="padding:6px 10px">Dừng API</div><div style="padding:6px 10px;color:#a11a1a;font-weight:600">Tạm ngừng khẩn cấp</div><div style="padding:6px 10px">Xem nhật ký lượt gọi</div></div>'
rows02 = [[mono("tra-cuu-cong-dan.v1") + "<br><span class='muted'>Tra cứu công dân</span>", mono("api.t68… /cong-dan/v1/*"), "GET", INT, RUN, num("41 ms"), num(5), "⋯"],
          [mono("cap-phep-xd.v2") + "<br><span class='muted'>Cấp phép xây dựng</span>", mono("api.t68… /cap-phep/v2/*"), "GET, POST", INT, RUN, num("88 ms"), num(3), "⋯" + menu],
          [mono("thanh-toan-callback.v1") + "<br><span class='muted'>Callback thanh toán</span>", mono("pay.t68… /callback/*"), "POST", EXT, RUN, num("52 ms"), num(1), "⋯"],
          [mono("dkkd-doanh-nghiep.v1") + "<br><span class='muted'>Đăng ký kinh doanh</span>", mono("api.t68… /dkkd/v1/*"), "GET", INT, SUSP, "—", num(0), "⋯"],
          [mono("tra-cuu-ho-tich.v1") + "<br><span class='muted'>Tra cứu hộ tịch</span>", mono("api.t68… /ho-tich/v1/*"), "GET", INT, STOP, "—", num(0), "⋯"],
          [mono("tra-cuu-cong-dan.v0") + "<br><span class='muted'>Tra cứu công dân (cũ)</span>", mono("api.t68… /cong-dan/v0/*"), "GET", INT, SUN + " <span class='muted'>đến 30/05/2027</span>", num("57 ms"), num(1), "⋯"],
          [mono("dat-dai-thua.v1") + "<br><span class='muted'>Dữ liệu thửa đất</span>", mono("api.t68… /dat-dai/v1/*"), "GET", INT, PEND, "—", num(0), "⋯"]]
P["02"] = ("Danh sách route", "Cổng API / Route", f"""
<div class="head"><h1>Route</h1><span class="muted">Route do Danh mục API sinh ra, không có nút tạo</span><div class="sp"></div><span class="btn">Xuất CSV</span></div>
{facets(["Đang chạy 112", "Đã dừng 4", "Tạm ngừng 1", "Sắp ngừng 3", "Chờ nạp 2"], 0)}
<div class="card"><div class="toolbar"><span class="input" style="min-width:280px">Tìm mã, host, đường dẫn</span><span class="input">Trạng thái ▾</span><span class="input">Cửa vào ▾</span><span class="input">Phiên bản ▾</span><div style="flex:1"></div><span class="muted">⚙ Cột · ≡ Mật độ</span></div>
{table(["☐", "Mã route · API", "Host · Đường dẫn", "Phương thức", "Cửa vào", "Trạng thái", "p95 15 phút", "HTTT gọi 15 phút", ""], [[("☑" if i == 1 else "☐")] + r for i, r in enumerate(rows02)], "Danh sách route")}
{foot("1–7 / 122")}</div>""")

# ---------------------------------------------------------------- 03 Chi tiết route (tab Backend và sức khỏe)
P["03"] = ("Chi tiết route", "Cổng API / Route / tra-cuu-cong-dan.v1", f"""
<div class="chrome"><h1>{mono("tra-cuu-cong-dan.v1")} {RUN} {INT} {tag(MU, "v1")}</h1>
<div style="display:flex;align-items:center;gap:8px"><span class="muted">API: Tra cứu công dân (Danh mục API ↗) · host api.t68… · /cong-dan/v1/*</span><span style="flex:1"></span><span class="btn">Dừng API</span><span class="btn danger">Tạm ngừng khẩn cấp</span><span class="btn">⋯</span></div></div>
<div class="alert i" role="status">ⓘ Có 2 thay đổi đã lưu, chờ phát ở phiên bản 1288.<span class="sp"></span><span class="btn">Xem ảnh chụp cấu hình</span></div>
{tabs(["Tổng quan", "Chính sách", "Backend và sức khỏe ●", "Phiên bản", "Cửa vào", "Lịch sử"], 2)}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 300px"><div><div class="card" style="margin-bottom:12px"><div class="toolbar"><b>Backend · upstream ndxp-cd · 3 nút</b><div style="flex:1"></div><span class="muted">Kiểm tra chủ động 5 giây · thụ động 5 phút</span></div>
{table(["Địa chỉ và cổng", "Trọng số", "Sức khỏe chủ động", "Sức khỏe thụ động", "p95", "Trong cân bằng tải"], [
 [mono("10.20.1.11:8443"), num(100), "<span class='dot ok'></span>Khỏe", "<span class='dot ok'></span>lỗi 0,1%", num("38 ms"), tag(OK, "Nhận lưu lượng")],
 [mono("10.20.1.12:8443"), num(100), "<span class='dot ok'></span>Khỏe", "<span class='dot ok'></span>lỗi 0,2%", num("44 ms"), tag(OK, "Nhận lưu lượng")],
 [mono("10.20.1.13:8443"), num(50), "<span class='dot er'></span>Đã loại 10:09", "<span class='dot wa'></span>lỗi 38%", num("1,9 s"), tag(WA, "Đang thăm dò lại")]], "Backend của route")}
<div class="muted" style="margin-top:8px">Địa chỉ backend do Danh mục API quản lý nên không sửa ở đây.</div></div>
<div class="grid-2e"><div class="card"><h4 style="margin:0 0 8px">Thời hạn chờ <span class="btn" style="float:right;height:26px">Sửa</span></h4><div class="field"><label>Thời hạn nối (ms)</label><div class="input">3000</div></div><div class="field"><label>Thời hạn đọc (ms) · trần 30.000</label><div class="input cell-edit">12000 <span class="pill" style="margin-left:8px">đã đổi</span></div></div></div>
<div class="card"><h4 style="margin:0 0 8px">Ngắt mạch</h4><div class="dl" style="grid-template-columns:130px 1fr"><dt>Sau số lỗi</dt><dd>5</dd><dt>Mở trong</dt><dd>10 giây</dd><dt>Trạng thái</dt><dd>{tag(OK, "Đóng")}</dd></div></div></div></div>
<div class="card raised"><h4 style="margin:0 0 10px">Tóm tắt</h4><div class="dl" style="grid-template-columns:120px 1fr"><dt>p95</dt><dd>41 ms</dd><dt>Tỷ lệ lỗi</dt><dd>0,3%</dd><dt>HTTT 15 phút</dt><dd>5</dd><dt>Ảnh chụp</dt><dd>1287</dd></div><div style="margin-top:12px" class="btn">Xem nhật ký lượt gọi ›</div></div></div>
<div style="height:60px"></div>
<div class="savebar"><span class="muted">1 trường đã đổi (thời hạn đọc)</span><span class="sp"></span><span class="btn">Hủy thay đổi</span><span class="btn pri">Lưu</span></div>""")

# ---------------------------------------------------------------- 04 Danh sách consumer
rows04 = [[mono("ndxp-gateway"), "Trục tích hợp NDXP", tag(IN, "Thiết yếu"), tag(MU, "mTLS"), tag(OK, "214 ngày"), num("26.800.000"), tag(OK, "✓ Đang hoạt động"), "⋯"],
          [mono("dvc-t68-portal"), "Cổng dịch vụ công tỉnh", tag(IN, "Thiết yếu"), tag(MU, "OAuth 2.1"), "—", num("17.950.000"), tag(OK, "✓ Đang hoạt động"), "⋯"],
          [mono("mc-t68"), "Một cửa điện tử", tag(MU, "Thường"), tag(MU, "mTLS"), tag(WA, "26 ngày"), num("12.130.000"), tag(OK, "✓ Đang hoạt động"), "⋯"],
          [mono("sotp-hotich"), "Hộ tịch điện tử, Sở Tư pháp", tag(MU, "Thường"), tag(MU, "OAuth 2.1"), "—", num("8.300.000"), tag(OK, "✓ Đang hoạt động"), "⋯"],
          [mono("sokh-dkkd-cu"), "Đăng ký kinh doanh (cũ)", tag(MU, "Thường"), tag(MU, "API key") + " " + tag(WA, "Giai đoạn chuyển đổi"), "—", num("120.000"), tag(ER, "⛔ Tạm ngừng") + " ⓘ", "⋯"],
          [mono("soxd-qlcp"), "Quản lý cấp phép xây dựng", tag(MU, "Thường"), tag(MU, "mTLS"), tag(ER, "6 ngày"), num("4.510.000"), tag(OK, "✓ Đang hoạt động"), "⋯"]]
P["04"] = ("Danh sách consumer", "Cổng API / Consumer", f"""
<div class="head"><h1>Consumer <span class="muted" style="font-size:14px;font-weight:400">· HTTT gọi API</span></h1><div class="sp"></div><span class="muted">Consumer do Kết nạp HTTT tạo, không có nút tạo</span></div>
<div class="card"><div class="toolbar"><span class="input" style="min-width:260px">Tìm mã consumer, HTTT</span><span class="input">Trạng thái ▾</span><span class="input">Nhóm ưu tiên ▾</span><span class="input">Xác thực ▾</span><div style="flex:1"></div><span class="muted">≡ Mật độ</span></div>
{table(["Mã consumer", "HTTT", "Nhóm ưu tiên", "Xác thực", "Hạn chứng thư", "Lượt gọi 24 giờ", "Trạng thái", ""], rows04, "Danh sách consumer")}
{foot("1–6 / 34")}</div>""")

# ---------------------------------------------------------------- 05 Chi tiết consumer (tab Hạn mức và mức dùng)
P["05"] = ("Chi tiết consumer", "Cổng API / Consumer / ndxp-gateway", f"""
<div class="chrome"><h1>{mono("ndxp-gateway")} {tag(OK, "✓ Đang hoạt động")} {tag(IN, "Thiết yếu")} {tag(MU, "mTLS")}</h1>
<div style="display:flex;align-items:center;gap:8px"><span class="muted">HTTT: Trục tích hợp NDXP ↗ · 12 API đã đăng ký</span><span style="flex:1"></span><span class="btn danger">Tạm ngừng khẩn cấp</span></div></div>
{tabs(["Xác thực công khai", "Đăng ký", "Hạn mức và mức dùng", "Thu hồi", "Nhật ký", "Lịch sử"], 2)}
<div class="card" style="margin-bottom:12px"><h3 style="margin:0 0 10px;font-size:15px">Hạn ngạch theo chu kỳ</h3>
<div class="hbar" style="grid-template-columns:140px 1fr 330px"><span>Giờ</span><div class="prog"><i style="width:34%"></i></div><span class="num">41.000 / 120.000 · 34%</span></div>
<div class="hbar" style="grid-template-columns:140px 1fr 330px"><span>Ngày</span><div class="prog"><i style="width:57%"></i></div><span class="num">1.370.000 / 2.400.000 · 57%</span></div>
<div class="hbar" style="grid-template-columns:140px 1fr 330px"><span>Tháng</span><div class="prog"><i style="width:82%;background:#d08a00"></i></div><span class="num"><b style="color:#7a5200">⚠ 4.100.000 / 5.000.000 · 82%</b> · đặt lại 01/12/2026</span></div></div>
<div class="grid-2e"><div class="card"><h3 style="margin:0 0 8px;font-size:15px">Hạn mức theo giây, phút (từ gói Thiết yếu)</h3>{table(["Cửa sổ", "Giới hạn", "Dung sai", "Nguồn"], [["1 giây", num("100 lượt"), num("2×"), "Gói Thiết yếu"], ["1 phút", num("3.000 lượt"), "—", "Gói Thiết yếu"], ["1 giờ", num("120.000 lượt"), "—", "Gói Thiết yếu"]], "Hạn mức")}
<div class="muted" style="margin-top:8px">Hệ số nới tần suất nhóm Thiết yếu: 1,5. Ghi đè đang có: không.</div></div>
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Mức dùng 24 giờ</h3><div class="vbars">{''.join(f'<div title="{i}h"><i style="height:{h_}px;background:#2f9e5b"></i><i style="height:{max(1, h_ // 30)}px;background:#d64545"></i></div>' for i, h_ in enumerate([40, 52, 66, 80, 95, 110, 128, 120, 112, 100, 108, 125, 132, 120, 105, 98, 92, 88, 76, 68, 60, 52, 48, 44]))}</div>
<div class="legend"><span><i style="background:#2f9e5b"></i>Thành công</span><span><i style="background:#d64545"></i>Lỗi</span><span style="flex:1"></span><span>Xem dạng bảng</span></div></div></div>""")

# ---------------------------------------------------------------- 06 Hạn mức, tab Ghi đè
rows06 = [["HTTT và route", mono("mc-t68") + " · " + mono("cap-phep-xd.v2"), num("40 lượt"), "1 giây", "20%", "31/12/2026", "Đợt cao điểm nộp hồ sơ", "⋯"],
          ["HTTT", mono("dvc-t68-portal"), num("150 lượt"), "1 giây", "20%", "—", "Chuẩn bị cao điểm cuối năm", "⋯"],
          ["Route", mono("tra-cuu-cong-dan.v1"), num("400 lượt"), "1 giây", "10%", "02/12/2026 <span class='tag t-warn'>⚠ còn 6 ngày</span>", "Kiểm thử tải", "⋯"],
          ["Tenant", "Toàn tỉnh", num("500 lượt"), "1 giây", "20%", "—", "Mặc định theo hợp đồng", "⋯"]]
P["06"] = ("Hạn mức và hạn ngạch", "Cổng API / Hạn mức", f"""
<div class="head"><h1>Hạn mức và hạn ngạch</h1></div>
<div class="card" style="margin-bottom:12px;display:flex;align-items:center;gap:18px"><div><span class="muted">Hạn mức toàn tenant</span><div style="font-size:24px;font-weight:700">500 lượt/giây</div></div><div class="muted">Dung sai đột biến 20% · đỉnh 24 giờ: 312 lượt/giây · trần hợp đồng 800</div><div style="flex:1"></div><span class="btn">Sửa</span></div>
{tabs(["Hạn mức tenant", "Ghi đè (4)", "Cảnh báo hạn ngạch (3)"], 1)}
<div class="card"><div class="toolbar"><span class="input">Phạm vi ▾</span><span class="input">Route ▾</span><span class="input">HTTT ▾</span><div style="flex:1"></div><span class="btn pri">+ Thêm ghi đè</span></div>
<div class="alert i" style="margin-bottom:10px">Thứ tự ưu tiên khi áp dụng: HTTT và route › HTTT › route › tenant › gói sử dụng</div>
{table(["Phạm vi", "Đối tượng", "Giới hạn", "Cửa sổ", "Dung sai", "Hết hạn", "Lý do", ""], rows06, "Ghi đè hạn mức")}
{foot("1–4 / 4")}</div>""")

# ---------------------------------------------------------------- 07 Nhật ký WAF (chế độ phát hiện, Drawer sự kiện)
vb = "".join(f'<div title="{i}h"><i style="height:{a_}px;background:#d64545"></i><i style="height:{b_}px;background:repeating-linear-gradient(45deg,#7aa7f0 0 3px,#cfe0ff 3px 6px)"></i></div>' for i, (a_, b_) in enumerate([(2, 18), (1, 12), (0, 8), (3, 30), (1, 22), (4, 40), (2, 35), (5, 52), (3, 44), (2, 38), (6, 60), (4, 48)]))
rows07 = [["10:14:07", mono("942100") + " SQLi", num(8), tag(MU, "Chỉ ghi"), mono("cap-phep-xd.v2"), mono("203.0.113.***"), mono("q=…' OR 1=1 --…")],
          ["10:13:52", mono("941100") + " XSS", num(6), tag(MU, "Chỉ ghi"), mono("tra-cuu-cong-dan.v1"), mono("198.51.100.***"), mono("hoTen=&lt;script&gt;…")],
          ["10:12:30", mono("930100") + " Đường dẫn", num(5), tag(MU, "Chỉ ghi"), mono("cap-phep-xd.v2"), mono("203.0.113.***"), mono("/tai-lieu/../..…")],
          ["10:11:05", mono("942100") + " SQLi", num(8), tag(MU, "Chỉ ghi"), mono("cap-phep-xd.v2"), mono("10.30.4.***"), mono("tuKhoa=… UNION SELECT…")]]
P["07"] = ("Nhật ký WAF và sự kiện chặn", "Cổng API / WAF", f"""
<div class="head"><h1>Nhật ký WAF</h1><div class="sp"></div><span class="muted">Theo dõi trực tiếp</span><span class="sw off"></span><span class="btn">Xuất</span></div>
<div class="card" style="margin-bottom:12px;display:flex;align-items:center;gap:16px"><div><span class="muted">Chế độ WAF</span><div style="font-size:18px;font-weight:700">{tag(IN, "Phát hiện")}</div></div>
<div style="flex:1"><div class="muted">Đã chạy phát hiện 9/14 ngày · cảnh báo giả chưa xử lý 7/20</div><div class="prog" style="margin-top:6px"><i style="width:64%"></i></div></div>
<div class="muted" style="max-width:300px">Chưa đủ điều kiện sang chế độ chặn (cần 14 ngày).</div><span class="btn">Đề nghị chuyển sang chế độ chặn</span></div>
<div class="card"><div class="toolbar"><span class="input">24 giờ ▾</span><span class="input">Luật ▾</span><span class="input">Route ▾</span><span class="input">Địa chỉ nguồn</span><span class="input">Hành động ▾</span><div style="flex:1"></div><span class="muted">Khoảng 1.204 sự kiện</span></div>
<div class="vbars" style="height:80px">{vb}</div><div class="legend"><span><i style="background:#d64545"></i>Đã chặn</span><span><i style="background:repeating-linear-gradient(45deg,#7aa7f0 0 3px,#cfe0ff 3px 6px)"></i>Chỉ ghi</span><span style="flex:1"></span><span>Xem dạng bảng</span></div>
{table(["Thời điểm", "Mã luật", "Điểm", "Hành động", "Route", "Địa chỉ nguồn", "Mẫu trích đã che"], rows07, "Sự kiện WAF")}
<div class="foot" style="justify-content:space-between"><span class="muted">‹ Trước · Sau ›</span><span class="muted">100 / lần</span></div></div>""",
                     drawer("Sự kiện WAF 01JD7K…", f"""<div class="card"><div class="dl" style="grid-template-columns:120px 1fr"><dt>Luật</dt><dd>{mono("942100")} SQL injection (libinjection)</dd><dt>Điểm bất thường</dt><dd>8 (ngưỡng 5)</dd><dt>Hành động</dt><dd>Chỉ ghi (chế độ phát hiện)</dd><dt>Route</dt><dd>{mono("cap-phep-xd.v2")}</dd><dt>Địa chỉ</dt><dd>{mono("203.0.113.***")}</dd></div></div>
<div class="card raised"><h4 style="margin:0 0 6px">Mẫu yêu cầu (đã che)</h4><div class="code">GET /cap-phep/v2/ho-so?q=***&amp;trang=1
Luật khớp tại tham số: q
Giá trị tham số đã bị bỏ ở nguồn</div></div>
<div class="muted" style="margin-bottom:8px">Số lần chặn cùng luật và route trong 7 ngày: 31</div><div class="foot" style="justify-content:flex-start"><span class="btn pri">Đề nghị ngoại lệ</span><span class="btn">Chặn địa chỉ</span></div>""", 440))

# ---------------------------------------------------------------- 08 Ngoại lệ WAF
rows08 = [[mono("cap-phep-xd.v2"), mono("942100"), "Ô tìm kiếm hồ sơ chứa dấu nháy hợp lệ", "Lê A (TO)", "—", "20/12/2026", tag(IN, "Chờ duyệt"), "⋯"],
          [mono("tra-cuu-cong-dan.v1"), mono("941100"), "Trường ghi chú cho phép thẻ định dạng", "Trần B (TA)", "Phạm C (SO)", "28/02/2027", tag(OK, "Hiệu lực"), "⋯"],
          [mono("cap-phep-xd.v2"), mono("930100"), "Đường dẫn tệp đính kèm có dấu chấm", "Lê A (TO)", "Phạm C (SO)", "03/12/2026 <span class='tag t-warn'>⚠ còn 7 ngày</span>", tag(WA, "Sắp hết hạn"), "⋯"],
          [mono("danh-muc-dung-chung.v1"), mono("920350"), "Máy khách cũ không gửi tiêu đề Host", "Trần B (TA)", "Phạm C (SO)", "15/11/2026", tag(MU, "Hết hạn"), "⋯"]]
P["08"] = ("Ngoại lệ luật WAF và luật vá ảo", "Cổng API / WAF / Ngoại lệ", f"""
<div class="head"><h1>Ngoại lệ luật WAF</h1><div class="sp"></div><span class="btn pri">+ Đề nghị ngoại lệ</span></div>
<div class="alert i" role="status">ⓘ 2 ngoại lệ sẽ hết hạn trong 7 ngày tới. Đề nghị lại nếu vẫn cần.<span class="sp"></span><span class="btn">Lọc sắp hết hạn</span></div>
{tabs(["Ngoại lệ (4)", "Luật vá ảo (1)"], 0)}
<div class="card"><div class="toolbar"><span class="input">Trạng thái ▾</span><span class="input">Route ▾</span><span class="input">Mã luật ▾</span><div style="flex:1"></div></div>
{table(["Route", "Mã luật", "Lý do", "Người đề nghị", "Người duyệt", "Hạn", "Trạng thái", ""], rows08, "Ngoại lệ luật WAF")}{foot("1–4 / 4")}</div>""",
                     drawer("Duyệt ngoại lệ", f"""<div class="card"><div class="dl" style="grid-template-columns:120px 1fr"><dt>Route</dt><dd>{mono("cap-phep-xd.v2")}</dd><dt>Mã luật</dt><dd>{mono("942100")}</dd><dt>Hạn đề nghị</dt><dd>20/12/2026 (24 ngày)</dd><dt>Người đề nghị</dt><dd>Lê A (TO)</dd><dt>Số lần chặn 7 ngày</dt><dd>31</dd></div></div>
<div class="card raised"><h4 style="margin:0 0 6px">Mẫu yêu cầu (đã che)</h4><div class="code">GET /cap-phep/v2/ho-so?q=***</div></div>
<div class="field"><label>Ý kiến</label><div class="input" style="height:64px;align-items:flex-start;padding-top:6px">Chờ người duyệt nhập…</div></div>
<div class="warn" role="note">Bạn đã đề nghị ngoại lệ này nên không thể tự duyệt.</div>
<div class="foot"><span class="btn danger">Từ chối</span><span class="btn pri" style="opacity:.45">Duyệt</span></div>""", 440))

# ---------------------------------------------------------------- 09 Nhật ký lượt gọi
vb9 = "".join(f'<div><i style="height:{a_}px;background:#2f9e5b"></i><i style="height:{b_}px;background:#d64545"></i></div>' for a_, b_ in [(30, 1), (42, 1), (55, 2), (60, 1), (72, 3), (80, 2), (75, 2), (68, 6), (62, 14), (70, 8), (66, 3), (58, 2), (50, 1), (46, 1), (52, 2), (60, 2)])
rows09 = [["10:14:07.412", "Một cửa điện tử", mono("cap-phep-xd.v2"), mono("GET /cap-phep/v2/ho-so?trang=***"), tag(WA, "429"), mono("ERR-03-117"), num("2 ms"), mono("apisix-int-1"), mono("01JD7K3M…")],
          ["10:14:07.201", "Trục tích hợp NDXP", mono("tra-cuu-cong-dan.v1"), mono("GET /cong-dan/v1/ho-so?soDinhDanh=***"), tag(OK, "200"), "—", num("41 ms"), mono("apisix-int-0"), mono("01JD7K3H…")],
          ["10:14:06.987", "Cổng DVC tỉnh", mono("thanh-toan-callback.v1"), mono("POST /callback/v1/ket-qua"), tag(ER, "503"), mono("ERR-03-120"), num("3 ms"), mono("apisix-ext-0"), mono("01JD7K3F…")],
          ["10:14:06.640", "Hộ tịch điện tử", mono("tra-cuu-ho-tich.v1"), mono("GET /ho-tich/v1/khai-sinh?ma=***"), tag(WA, "403"), mono("ERR-03-109"), num("1 ms"), mono("apisix-int-2"), mono("01JD7K3B…")],
          ["10:14:06.330", "Trục tích hợp NDXP", mono("tra-cuu-cong-dan.v1"), mono("GET /cong-dan/v1/ho-so?soDinhDanh=***"), tag(OK, "200"), "—", num("39 ms"), mono("apisix-int-1"), mono("01JD7K39…")]]
P["09"] = ("Nhật ký lượt gọi", "Cổng API / Nhật ký lượt gọi", f"""
<div class="head"><h1>Nhật ký lượt gọi</h1><div class="sp"></div><span class="muted">Theo dõi trực tiếp</span><span class="sw off"></span><span class="btn">Xuất</span></div>
<div class="card"><div class="toolbar"><span class="input">1 giờ ▾</span><span class="input">HTTT ▾</span><span class="input">Route ▾</span><span class="input">Mã lỗi ▾</span><span class="input">Mã HTTP ▾</span><span class="input" style="min-width:190px">traceId</span><div style="flex:1"></div><span class="muted">≡ Mật độ gọn</span></div>
<div class="vbars" style="height:70px">{vb9}</div><div class="legend"><span><i style="background:#2f9e5b"></i>Thành công</span><span><i style="background:#d64545"></i>Lỗi</span><span style="flex:1"></span><span>Xem dạng bảng</span></div>
{table(["Thời điểm", "HTTT", "Route", "Phương thức, đường dẫn", "HTTP", "Mã lỗi", "Độ trễ", "Nút", "traceId"], rows09, "Nhật ký lượt gọi")}
<div class="foot" style="justify-content:space-between"><span class="muted">Khoảng 1,2 triệu dòng</span><span class="muted">‹ Trước · Sau › · 100 / lần</span></div></div>""",
                     drawer("Lượt gọi 01JD7K3M…", f"""<div class="alert w" style="margin-bottom:10px"><b>429</b> {mono("ERR-03-117")} Vượt hạn ngạch theo chu kỳ</div>
<div class="card"><h4 style="margin:0 0 6px">Kết quả bên gọi nhận</h4><div class="muted">title: Vượt hạn ngạch · detail: HTTT đã dùng hết hạn ngạch tháng. Chờ tới thời điểm đặt lại.</div></div>
<div class="card raised"><h4 style="margin:0 0 6px">Gợi ý cho vận hành</h4><div>Xem mức dùng ở <u>Consumer mc-t68 › Hạn mức</u>; cân nhắc ghi đè ở <u>Hạn mức</u>.</div></div>
<div class="card"><div class="dl" style="grid-template-columns:120px 1fr"><dt>HTTT</dt><dd>Một cửa điện tử</dd><dt>Route</dt><dd>{mono("cap-phep-xd.v2")}</dd><dt>Địa chỉ nguồn</dt><dd>{mono("10.30.4.18")}</dd><dt>Độ trễ</dt><dd>2 ms (gateway 2 ms, backend 0)</dd><dt>Nút</dt><dd>{mono("apisix-int-1")} · cấu hình 1287</dd><dt>traceId</dt><dd>{mono("01JD7K3M8Q2VX…")} ⧉</dd></div></div>""", 440))

# ---------------------------------------------------------------- 10 Ảnh chụp cấu hình
rows10 = [[num(1288), "Tự động", "Danh mục API", tag(ER, "Bị từ chối"), "—", "10:20", "Xem lỗi"], [num(1287), "Tự động", "Danh mục API", tag(OK, "Đã áp dụng 6/6"), num("+2 −0 ~5"), "10:12", "So sánh · Quay lui"],
          [num(1286), "Thủ công", "Trần B (TA)", tag(MU, "Đã được thay thế"), num("+0 −1 ~2"), "09:30", "So sánh · Quay lui"], [num(1285), "Tự động", "Kết nạp HTTT", tag(MU, "Đã được thay thế"), num("+1 −0 ~0"), "09:04", "So sánh · Quay lui"]]
P["10"] = ("Ảnh chụp cấu hình và phát hành", "Cổng API / Cấu hình đã phát", f"""
<div class="head"><h1>Cấu hình đã phát</h1><div class="sp"></div><span class="btn">Kiểm tra thử</span><span class="btn pri">Xây và phát thủ công</span></div>
<div class="alert e" role="alert">⛔ Phiên bản 1288 bị từ chối: 2 lỗi. Route thiếu lược đồ OpenAPI đã duyệt (ERR-03-012), plugin ngoài danh mục (ERR-03-013). Cấu hình đang chạy không đổi.<span class="sp"></span><span class="btn">Xem lỗi</span></div>
<div class="card" style="margin-bottom:12px;display:flex;gap:18px;align-items:center"><div><span class="muted">Hiện hành</span><div style="font-size:22px;font-weight:700">Phiên bản 1287 {tag(OK, "Đã áp dụng 6/6 nút")}</div></div><div class="muted">Ký lúc 10:12:44 · chữ ký hợp lệ · Tổng hợp tự động: Bật</div></div>
<div class="card"><div class="toolbar"><span class="input">Trạng thái ▾</span><div style="flex:1"></div></div>{table(["Phiên bản", "Kích hoạt", "Nguồn", "Trạng thái", "Route thêm, bớt, đổi", "Giờ", ""], rows10, "Danh sách phiên bản")}</div>
<div class="card" style="margin-top:12px"><h3 style="margin:0 0 8px;font-size:15px">So sánh phiên bản 1287 với 1286 <span class="muted" style="font-weight:400">· +2 route, 5 thay đổi</span></h3><div class="diff">
<div class="a">+ route  dat-dai-thua.v1   upstream: dat-dai-cd   cửa vào: INT</div><div class="a">+ route  danh-muc-dung-chung.v2   upstream: dmdc-cd   cửa vào: INT</div>
<div class="c">~ route  cap-phep-xd.v2   timeouts.readMs: 10000 → 12000</div><div class="c">~ route  tra-cuu-cong-dan.v1   bodyMaxBytes: 1048576 → 2097152</div>
<div class="d">− cors   tra-cuu-ho-tich.v1   allowedOrigins: https://old.t68.gov.vn</div></div></div>""")

# ---------------------------------------------------------------- 11 Nút gateway
rows11 = [[mono("apisix-ext-2"), tag(IN, "Internet"), "Site chính", f"{num(1285)} <span class='muted'>mong muốn 1287 · chậm 2 phiên bản</span>", tag(WA, "⚠ Chậm phiên bản"), "12 giây trước", "9 phút", "Suy giảm", "46% · 61%"],
          [mono("apisix-ext-0"), tag(IN, "Internet"), "Site chính", num(1287), tag(OK, "✓ Đồng bộ"), "4 giây trước", "7 phút", "Suy giảm", "38% · 57%"],
          [mono("apisix-ext-1"), tag(IN, "Internet"), "Site chính", num(1287), tag(OK, "✓ Đồng bộ"), "6 giây trước", "7 phút", "Suy giảm", "41% · 55%"],
          [mono("apisix-int-0"), tag(MU, "Nội bộ"), "Site chính", num(1287), tag(OK, "✓ Đồng bộ"), "3 giây trước", "8 phút", "Suy giảm", "52% · 63%"],
          [mono("apisix-int-1"), tag(MU, "Nội bộ"), "Site chính", num(1287), tag(OK, "✓ Đồng bộ"), "5 giây trước", "8 phút", "Suy giảm", "49% · 60%"],
          [mono("apisix-int-2"), tag(MU, "Nội bộ"), "Site chính", num(1287), tag(OK, "✓ Đồng bộ"), "8 giây trước", "8 phút", "Suy giảm", "47% · 58%"]]
P["11"] = ("Nút gateway", "Cổng API / Nút gateway", f"""
<div class="head"><h1>Nút gateway</h1><span class="muted">Làm mới 10 giây</span><div class="sp"></div></div>
{kpis([("Số nút", "6", "3 Internet · 3 Nội bộ", ""), ("Đồng bộ", "5/6", "<span style='color:#7a5200'>1 nút chậm</span>", ""), ("JWKS làm mới gần nhất", "10:36", "chu kỳ 10 phút", ""), ("Valkey", "<span style='color:#7a5200'>Suy giảm</span>", "từ 10:02", "")])}
<div class="card"><div class="toolbar"><span class="input">Cửa ▾</span><span class="input">Site ▾</span><span class="input">Trạng thái đồng bộ ▾</span><div style="flex:1"></div></div>
{table(["Nút", "Cửa", "Site", "Phiên bản chạy", "Đồng bộ", "Tín hiệu cuối", "JWKS", "Valkey", "CPU · Bộ nhớ"], rows11, "Nút gateway")}</div>""",
                     drawer("Nút apisix-ext-2", f"""<div class="card"><div class="dl" style="grid-template-columns:130px 1fr"><dt>Phiên bản chạy</dt><dd>1285 (mong muốn 1287)</dd><dt>Nạp lần cuối</dt><dd>10:02:11</dd><dt>JWKS</dt><dd>9 phút, kid 2026-11</dd><dt>Valkey</dt><dd>Không nối được từ 10:02</dd><dt>Kết nối đang mở</dd><dd style="margin:0">612</dd></div></div>
<div class="card raised"><h4 style="margin:0 0 6px">CPU, bộ nhớ 1 giờ</h4><div class="vbars" style="height:70px">{''.join(f'<div><i style="height:{h_}px;background:#7aa7f0"></i></div>' for h_ in [30, 32, 35, 38, 40, 44, 46, 45, 47, 46, 48, 46])}</div></div>
<div class="alert w">Nút chậm 2 phiên bản quá 60 giây. Kiểm tra bộ đồng bộ của nút.</div>""", 420))

# ---------------------------------------------------------------- 12 Chứng thư và TLS
rows12 = [[mono("edge-ext-2026"), "*.api.t68.datahub.vn", "Internet", "CA nhà nước", "02/12/2026", tag(ER, "Nghiêm trọng · 6 ngày"), "<span class='btn' style='height:26px'>Gia hạn</span>"],
          [mono("edge-int-2026"), "*.api.t68.datahub.local", "Nội bộ", "CA nội bộ OpenBao", "30/06/2027", tag(OK, "Còn hạn · 216 ngày"), "<span class='btn' style='height:26px'>Gia hạn</span>"],
          [mono("pay-callback-2026"), "pay.t68.datahub.vn", "Internet", "CA nhà nước", "20/12/2026", tag(WA, "Sắp hết hạn · 24 ngày"), "<span class='btn' style='height:26px'>Gia hạn</span>"]]
P["12"] = ("Chứng thư và TLS", "Cổng API / Chứng thư và TLS", f"""
<div class="head"><h1>Chứng thư và TLS</h1></div>
<div class="alert i">ⓘ 24 giờ qua có 37 lần bắt tay TLS bị từ chối: 31 do phiên bản thấp hơn TLS 1.2, 6 do bộ mã yếu. Liên hệ chủ HTTT cũ nếu cần.</div>
{tabs(["Chứng thư (3)", "Hồ sơ TLS", "Ngoại lệ TLS 1.2 (1)", "Bộ CA khách (2)"], 0)}
<div class="card">{table(["Mã", "Host phủ", "Cửa vào", "Nhà phát hành", "Hết hạn", "Còn lại", ""], rows12, "Chứng thư biên")}
<div class="muted" style="margin-top:10px">Khóa riêng nằm ở OpenBao, giao diện không có và không tải khóa riêng.</div></div>""")

# ---------------------------------------------------------------- 13 Mẫu chính sách
rows13 = [[mono("tpl-oauth21-standard"), "Xác thực OAuth 2.1 tiêu chuẩn", "Bảo mật", num("v3"), "<span class='sw'></span>", num(88), tag(MU, "Thấp")],
          [mono("tpl-mtls-sensitive"), "mTLS cho dữ liệu Nhạy cảm", "Bảo mật", num("v2"), "<span class='sw'></span>", num(21), tag(WA, "Trung bình")],
          [mono("tpl-rate-essential"), "Tần suất nhóm Thiết yếu", "Hạn mức", num("v1"), "<span class='sw'></span>", num(14), tag(MU, "Thấp")],
          [mono("tpl-cors-strict"), "CORS nguồn liệt kê đầy đủ", "An ninh", num("v1"), "<span class='sw'></span>", num(9), tag(MU, "Thấp")],
          [mono("tpl-grpc-rest"), "Chuyển đổi gRPC sang REST", "Chuyển đổi", num("v1"), "<span class='sw off'></span>", num(0), tag(WA, "Trung bình")]]
P["13"] = ("Mẫu chính sách", "Cổng API / Mẫu chính sách", f"""
<div class="head"><h1>Mẫu chính sách</h1><span class="muted">Chỉ mẫu trong danh mục được duyệt mới dùng được</span><div class="sp"></div></div>
<div class="card"><div class="toolbar"><span class="input" style="min-width:240px">Tìm tên, mã mẫu</span><span class="input">Loại ▾</span><span class="input">Bật hoặc tắt ▾</span><div style="flex:1"></div></div>
{table(["Mã mẫu", "Tên", "Loại", "Phiên bản", "Bật cho tỉnh", "Route đang dùng", "Mức rủi ro"], rows13, "Mẫu chính sách")}</div>""",
                     drawer("Mẫu tpl-mtls-sensitive", f"""<div class="card"><div class="dl" style="grid-template-columns:120px 1fr"><dt>Loại</dt><dd>Bảo mật</dd><dt>Phiên bản</dt><dd>2 (đã duyệt 12/11/2026)</dd><dt>Route đang dùng</dt><dd>21</dd></div></div>
<div class="card raised"><h4 style="margin:0 0 6px">Plugin và tham số (chỉ đọc)</h4><div class="code">plugins:
  - dh-mtls-bind      # ràng buộc token với chứng thư
      requireCnf: true
  - dh-path-acl
      mode: allow-list
  - limit-count
      window: 1s</div></div><div class="muted">Mẫu đang dùng không tắt được khi còn route tham chiếu (ERR-03-019).</div>""", 440))

# ---------------------------------------------------------------- 14 Chạy thử chính sách
chk = [("ok", "1", "TLS", "Đạt: TLS 1.3, chứng thư khách hợp lệ"), ("ok", "2", "WAF", "Đạt: không khớp luật nào"), ("ok", "3", "Xác thực", "Đạt: token hợp lệ, tenant T68"),
       ("ok", "4", "Đăng ký sử dụng", "Đạt: đăng ký hiệu lực đến 31/12/2027"), ("ok", "5", "Phạm vi quyền", "Đạt: cap-phep:read"),
       ("er", "6", "Hạn mức, hạn ngạch", "Không đạt: vượt hạn ngạch tháng · <span class='mono'>ERR-03-117</span> · HTTP 429"), ("mu", "7", "Ủy quyền OPA", "Không đánh giá"), ("mu", "8", "Danh sách đường dẫn", "Không đánh giá"), ("mu", "9", "Định tuyến", "Không đánh giá")]
chkh = "".join(f'<div class="chk {k}"><span class="n">{"✓" if k == "ok" else ("✗" if k == "er" else n)}</span><span><b>{t}</b> · {d}</span><span></span></div>' for k, n, t, d in chk)
P["14"] = ("Chạy thử chính sách", "Cổng API / Route", P["02"][2].replace(menu, ""), drawer("Chạy thử chính sách", f"""<div class="grid-2e" style="gap:8px"><div class="field"><label>Route *</label><div class="input mono">cap-phep-xd.v2</div></div><div class="field"><label>Consumer *</label><div class="input mono">mc-t68</div></div>
<div class="field"><label>Phương thức *</label><div class="input">GET</div></div><div class="field"><label>Cửa vào *</label><div class="input">Nội bộ</div></div></div>
<div class="field"><label>Đường dẫn *</label><div class="input mono">/cap-phep/v2/ho-so/123</div><div class="muted">Dùng dữ liệu giả. Chạy thử không tăng bộ đếm hạn mức và không gọi backend.</div></div>
<div class="field"><label>Phạm vi (scope)</label><div class="input">☑ cap-phep:read</div></div><div class="foot" style="margin-top:0;border:0;padding:0 0 8px"><span class="btn pri">Chạy thử</span></div>
<h4 style="margin:6px 0">Kết quả theo chốt</h4>{chkh}<div class="alert e" style="margin-top:10px">Kết luận: sẽ bị từ chối ở chốt 6 · HTTP 429</div>""", 640))

# ---------------------------------------------------------------- 15 Địa chỉ bị chặn
rows15 = [[mono("203.0.113.0/24"), tag(MU, "Tự động"), "Vi phạm WAF 14 lần trong 60 giây", "Hệ thống", "10:09", "10:24 (còn 12 phút)", "<span class='btn' style='height:26px'>Bỏ chặn</span>"],
          [mono("198.51.100.17/32"), tag(IN, "Thủ công"), "Quét dò đường dẫn quản trị", "Phạm C (SO)", "26/11 08:40", "27/11 08:40", "<span class='btn' style='height:26px'>Bỏ chặn</span>"],
          [mono("2001:db8:4f::/64"), tag(IN, "Thủ công"), "Nguồn tấn công thử mật khẩu đã biết", "Phạm C (SO)", "24/11 15:02", "Vô thời hạn", "<span class='btn' style='height:26px'>Bỏ chặn</span>"]]
P["15"] = ("Địa chỉ bị chặn", "Cổng API / Địa chỉ bị chặn", f"""
<div class="head"><h1>Địa chỉ bị chặn</h1><div class="sp"></div><span class="btn pri">+ Chặn địa chỉ</span></div>
{tabs(["Đang chặn (3)", "Danh sách tin cậy (4)"], 0)}
<div class="card"><div class="toolbar"><span class="input" style="min-width:240px">Tìm địa chỉ</span><span class="input">Nguồn chặn ▾</span><div style="flex:1"></div></div>
{table(["Địa chỉ hoặc CIDR", "Nguồn", "Lý do", "Người chặn", "Từ lúc", "Hết hạn", ""], rows15, "Địa chỉ đang chặn")}</div>""",
                     drawer("Chặn địa chỉ", f"""{field("Địa chỉ hoặc CIDR *", "192.0.2.64/28", True, "IPv4 từ /24, IPv6 từ /64; không thuộc danh sách tin cậy.")}
{field("Lý do *", "Quét dò cổng quản trị từ nhiều địa chỉ liên tiếp")}{field("Thời hạn chặn *", "24 giờ ▾")}
<div class="warn" role="note">Nhiều sở có thể dùng chung một địa chỉ sau NAT. Chặn theo địa chỉ ảnh hưởng mọi HTTT dùng địa chỉ này.</div>
<div class="foot"><span class="btn">Hủy</span><span class="btn pri">Chặn</span></div>""", 440))

# ---------------------------------------------------------------- 16 Tham số
prm = [("Số kết nối đồng thời tối đa mỗi địa chỉ", "gw.ip.maxConnections", "100", "10…1.000", "100", False), ("Yêu cầu mỗi giây mỗi IP, đường dẫn giao diện", "gw.ip.uiReqPerSecond", "50", "5…500", "50", False),
       ("Yêu cầu mỗi giây mỗi IP, API máy", "gw.ip.apiReqPerSecond", "250", "20…2.000", "200", True), ("Số lần vi phạm trong 60 giây để tự chặn", "gw.ip.autoBlock.threshold", "10", "3…100", "10", False),
       ("Thời gian chặn tự động (phút)", "gw.ip.autoBlock.minutes", "15", "1…1.440", "15", False)]
prh = "".join(f'<div class="field" style="display:grid;grid-template-columns:1fr 150px 140px;gap:12px;align-items:center;border-bottom:1px solid #eef0f3;padding-bottom:8px"><div><b>{n}</b> {"<span class=pill>Giả định</span>" if a else ""}<br><span class="mono muted">{k}</span></div><div class="input{" cell-edit" if v != d else ""}">{v}</div><span class="muted">Miền {r} · mặc định {d}</span></div>' for n, k, v, r, d, a in prm)
P["16"] = ("Tham số, chuyển tiếp tenant", "Cổng API / Tham số", f"""
<div class="head"><h1>Tham số gateway</h1><span class="muted">Trần hợp đồng của tỉnh áp lên mọi miền</span><div class="sp"></div></div>
{tabs(["Giới hạn theo địa chỉ nguồn", "WAF và TLS", "Tiêu đề bảo mật", "Chuyển tiếp tenant"], 0)}
<div class="card">{prh}</div><div style="height:60px"></div>
<div class="savebar"><span class="muted">1 trường đã đổi</span><span class="sp"></span><span class="btn">Hủy thay đổi</span><span class="btn pri">Lưu</span></div>""")

# ---------------------------------------------------------------- 17 Duyệt thay đổi
P["17"] = ("Duyệt thay đổi gateway", "Việc của tôi / Hộp việc", f"""
<div class="head"><h1>Hộp việc</h1><div class="sp"></div></div>
{tabs(["Chờ tôi (3)", "Nhóm của tôi (1)", "Đã xử lý"], 0)}
<div class="split"><div class="card"><div class="toolbar"><span class="input">Loại ▾</span><span class="input">Hạn ▾</span><span class="input">Phân hệ: Cổng API ▾</span></div>
<div style="border:2px solid var(--color-primary);border-radius:10px;padding:8px 10px;margin-bottom:8px"><b>Mở route ra cửa Internet</b> {tag(IN, "Cổng API")}<br><span class="mono">thanh-toan-callback.v1</span><br><span class="muted">Trần B (TA) · hạn 28/11/2026 · còn 2 ngày</span></div>
<div style="border:1px solid var(--color-border);border-radius:10px;padding:8px 10px;margin-bottom:8px"><b>Ngoại lệ luật WAF</b> {tag(IN, "Cổng API")}<br><span class="mono">cap-phep-xd.v2 · 942100</span><br><span class="muted">Lê A (TO) · hạn 28/11/2026</span></div>
<div style="border:1px solid var(--color-border);border-radius:10px;padding:8px 10px;margin-bottom:8px"><b>Hạ hạn mức toàn tenant</b> {tag(IN, "Cổng API")}<br><span class="muted">500 → 400 lượt/giây · Trần B (TA) · {tag(ER, "Quá hạn 1 ngày")}</span></div></div>
<div class="card"><h3 style="margin:0 0 8px">Mở route <span class="mono">thanh-toan-callback.v1</span> ra cửa Internet</h3><div class="muted" style="margin-bottom:10px">Đề nghị bởi Trần B (TA) · 26/11/2026 09:12 · hạn 28/11/2026</div>
<div class="card raised" style="margin-bottom:10px"><h4 style="margin:0 0 6px">Điều kiện</h4><div class="chk ok"><span class="n">✓</span><span>WAF ở chế độ chặn</span><span></span></div><div class="chk ok"><span class="n">✓</span><span>Bắt buộc xác thực (mTLS)</span><span></span></div><div class="chk ok"><span class="n">✓</span><span>Lược đồ OpenAPI đã duyệt, chính sách OPA tồn tại</span><span></span></div></div>
<div class="card raised" style="margin-bottom:10px"><h4 style="margin:0 0 6px">Lý do của người đề nghị</h4>Nhà cung cấp thanh toán gọi callback từ Internet. Chỉ nhận từ dải địa chỉ đã đăng ký.</div>
<div class="field"><label>Ý kiến</label><div class="input" style="height:54px"></div></div>
<div class="warn" role="note">Bạn đã đề nghị thay đổi này nên không thể tự duyệt.</div>
<div class="foot"><span class="btn danger">Từ chối</span><span class="btn pri" style="opacity:.45">Duyệt</span></div></div></div>""")

# ---------------------------------------------------------------- 18 Nhập từ gateway cũ (bước 3)
rows18 = [[mono("gravitee: cong-dan-v1"), mono("tra-cuu-cong-dan.v1"), "Gói Thiết yếu", "OAuth 2.1", tag(OK, "Khớp")],
          [mono("gravitee: ho-tich-api"), mono("tra-cuu-ho-tich.v1"), "Gói Thường", "API key → OAuth 2.1", tag(OK, "Khớp")],
          [mono("gravitee: thanh-toan-cb"), "<span class='input' style='min-width:200px'>Chọn route ▾</span>", "Gói Thiết yếu", "mTLS", tag(WA, "Cần chọn")],
          [mono("gravitee: test-sandbox"), "—", "—", "—", tag(MU, "Bỏ qua")]]
P["18"] = ("Nhập cấu hình từ gateway cũ", "Cổng API / Nhập từ gateway cũ", f"""
<div class="head"><h1>Nhập cấu hình từ gateway cũ</h1><div class="sp"></div></div>
<div class="wiz"><div class="done">✓ 1. Tải gói</div><div class="done">✓ 2. Xem phân tích</div><div class="on">3. Sửa ánh xạ</div><div>4. Áp dụng</div></div>
<div class="alert i">ⓘ Phân tích gói <span class="mono">gravitee-t68-20261120.zip</span>: 50 route, 11 plan. Tự khớp 41, cần xử lý 7, bỏ qua 2. Bí mật trong gói đã bị bỏ và không hiển thị.</div>
<div class="card"><div class="toolbar"><span class="input">Trạng thái ▾</span><div style="flex:1"></div><span class="muted">Hiển thị 4 / 50</span></div>
{table(["Route cũ", "Route mới (Danh mục API)", "Gói", "Chế độ bảo mật", "Trạng thái"], rows18, "Ánh xạ route")}
<div class="foot"><span class="btn">Quay lại</span><span class="btn pri">Tiếp tục</span></div></div>""")

for code, (title, crumb, body, *extra) in P.items():
    (OUT / f"ui-03-{code}.html").write_text(shell(code, title, crumb, body, extra[0] if extra else ""), encoding="utf-8")
print("Đã sinh", len(P), "trang")
