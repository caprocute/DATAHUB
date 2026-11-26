#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-19-01…28 (D03-06-PH19, mục "Ảnh hi-fi" của từng màn).

Chạy: python3 gen_hifi.py; chụp ảnh: node shot.js
Dữ liệu là giả định của tỉnh thí điểm T68 (mã giao dịch theo FRS PH-19: T68 + yyMMdd + 10 ký tự Base32).
Phong cách: Liquid Glass của D03-05; kính chỉ ở lớp điều hướng và lớp nổi, nội dung dày dùng nền đặc.
"""
import pathlib

OUT = pathlib.Path(__file__).parent

NAV = [("Tổng quan", "01"), ("Kênh thanh toán", "02"), ("Tra cứu giao dịch", "14"), ("Hộp phê duyệt", "13"),
       ("Hoàn tiền", "17"), ("Đối soát", "19"), ("Chênh lệch", "21"), ("IPN", "16"), ("Webhook", "24"),
       ("Nhật ký tích hợp", "23"), ("Báo cáo", "25"), ("|Danh mục thanh toán", None), ("Nhà cung cấp", "03"),
       ("Nhóm dịch vụ", "07"), ("Dịch vụ", "09"), ("Đối tác", "11"), ("|Quản trị", None), ("Cấu hình", "26"),
       ("Di trú, chạy song song", "27")]
BADGE = {"02": "<span class='tag t-err'>1</span>", "13": "<span class='tag t-info'>3</span>",
         "17": "<span class='tag t-warn'>2</span>", "16": "<span class='tag t-warn'>4</span>",
         "21": "<span class='tag t-err'>1</span>"}
ACTIVE = {"01": "01", "02": "02", "03": "03", "04": "03", "05": "03", "06": "03", "07": "07", "08": "07",
          "09": "09", "10": "09", "11": "11", "12": "11", "13": "13", "14": "14", "15": "14", "16": "16",
          "17": "17", "18": "17", "19": "19", "20": "19", "21": "21", "22": "21", "23": "23", "24": "24",
          "25": "25", "26": "26", "27": "27"}
TITLE = {}


def shell(code, title, crumb, body, extra=""):
    TITLE[code] = title
    nav = ""
    for n, c in NAV:
        if n.startswith("|"):
            nav += f'<div class="grp">{n[1:]}</div>'
            continue
        nav += f'<a class="{"on" if ACTIVE[code] == c else ""}" href="#">{n} {BADGE.get(c, "")}</a>'
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-19-{code} · {title}</title><link rel="stylesheet" href="hifi.css"></head><body>
<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Điều hành</div><div class="search">Tìm mã giao dịch, mã đơn hàng, đối tác…  ⌘K</div><div class="sp"></div>
<span class="tray">⟳ 1 tác vụ nền</span><span class="tray">T68 · Tỉnh thí điểm</span><div class="avatar">NK</div></header>
<nav class="side" aria-label="Điều hướng chính"><div class="grp">Thanh toán</div>{nav}</nav>
<main><div class="crumb">{crumb}</div>{body}</main></div>{extra}<div class="hint">Bản hi-fi minh họa · D03-06-PH19 · UI-19-{code} · dữ liệu giả định</div></body></html>"""


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


OK, WA, ER, IN, MU = "ok", "warn", "err", "info", "mute"
TX1, TX2, TX3, TX4, TX5 = "T68261126K7M2Q9XW4P", "T68261126B3H8D1ZR6N", "T68261126Q4W9M2C7TA", "T68261125V8N3K5Y0PD", "T68261126F2J6R8X1EH"
P = {}

# 01 Dashboard tổng quan
bars = [("Lệ phí hộ tịch", 812), ("Phí cấp phép xây dựng", 545), ("Lệ phí đăng ký kinh doanh", 431), ("Phí thẩm định đất đai", 388),
        ("Lệ phí lý lịch tư pháp", 296), ("Phí chứng thực", 241), ("Lệ phí trước bạ", 198), ("Khác (14 dịch vụ)", 501)]
hb = "".join(f'<div class="hbar"><span>{n}</span><i style="width:{v/812*100:.0f}%"></i><span class="num">{v}</span></div>' for n, v in bars)
hours = [(20, 1, 0), (35, 2, 1), (90, 4, 2), (160, 6, 3), (210, 8, 4), (240, 9, 5), (195, 7, 3), (120, 5, 2), (140, 6, 3), (185, 7, 2), (230, 9, 4), (60, 3, 6)]
vb = "".join(f'<div title="{h+7}h"><i style="height:{s/2.2:.0f}px;background:#2f9e5b"></i><i style="height:{f*2}px;background:#d64545"></i><i style="height:{p*3}px;background:repeating-linear-gradient(45deg,#7aa7f0 0 3px,#cfe0ff 3px 6px)"></i></div>' for h, (s, f, p) in enumerate(hours))
P["01"] = ("Dashboard tổng quan thanh toán", "Thanh toán / Tổng quan", f"""
<div class="head"><h1>Tổng quan thanh toán</h1><span class="muted">Cập nhật lúc 09:41:07 · trễ tối đa 60 giây</span><div class="sp"></div><span class="input">Hôm nay ▾</span><span class="input">Kênh: Tất cả ▾</span><span class="input">Dịch vụ: Tất cả ▾</span><span class="btn">⟳</span></div>
<div class="alert w" role="alert">⚠ Kênh PayGov đang <b>Suy giảm</b> từ 09:12 (tỷ lệ lỗi 18%). Giao dịch mới vẫn được tạo.<span class="sp"></span><span class="btn">Xem kênh</span></div>
{kpis([("Dịch vụ đang hoạt động","48","giữ của hệ cũ","legacy"),("Hệ thống áp dụng","17","giữ của hệ cũ","legacy"),("Tổng giao dịch","1.284.590","giữ của hệ cũ","legacy"),("Giao dịch trong ngày","3.412","▲ tăng 6% so với hôm qua","legacy")])}
{kpis([("Tổng tiền thu hôm nay","1.732.450.000 ₫","▲ tăng 4%",""),("Tỷ lệ thành công","96,8 %","<span style='color:#a11a1a'>▼ giảm 0,9 điểm</span>",""),("Giao dịch treo quá 30 phút","12 →","",""),("Chênh lệch mở","5 →","",""),("Chờ tôi duyệt","2 →","","")])}
<div class="grid-2e"><div class="card"><h3 style="margin:0 0 8px;font-size:15px">Giao dịch trong ngày theo dịch vụ</h3>{hb}<div class="muted" style="text-align:right">Xem dạng bảng</div></div>
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Giao dịch theo giờ, chia trạng thái</h3><div class="vbars">{vb}</div>
<div class="legend"><span><i style="background:#2f9e5b"></i>Thành công</span><span><i style="background:#d64545"></i>Thất bại</span><span><i style="background:repeating-linear-gradient(45deg,#7aa7f0 0 3px,#cfe0ff 3px 6px)"></i>Chờ thanh toán</span><span class="sp"></span><span>Xem dạng bảng</span></div></div></div>
<div class="grid3" style="margin-top:12px;grid-template-columns:340px minmax(0,1fr)"><div class="card"><h3 style="margin:0 0 8px;font-size:15px">Sức khỏe kênh</h3>{table(["Kênh","Sức khỏe","Lỗi","p95"],[["PAYGOV",tag(WA,"⚠ Suy giảm"),"18%","1,4 s"],["MOCK-01",tag(OK,"♥ Khỏe"),"0%","80 ms"]],"Sức khỏe kênh")}</div>
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Giao dịch mới nhất trong ngày <span class="muted">· Tra cứu ›</span></h3>{table(["Mã giao dịch","Dịch vụ","Đối tác","Số tiền","Trạng thái","Lúc"],[
[f"<span class='mono'>{TX1}</span>","Lệ phí hộ tịch","DVC-T68","<span class='num'>50.000 ₫</span>",tag(OK,"✓ Thành công"),"09:40"],
[f"<span class='mono'>{TX2}</span>","Phí cấp phép xây dựng","DVC-T68","<span class='num'>1.500.000 ₫</span>",tag(IN,"⏳ Chờ thanh toán"),"09:39"],
[f"<span class='mono'>{TX3}</span>","Lệ phí trước bạ","MC-T68","<span class='num'>3.200.000 ₫</span>",tag(ER,"✗ Thất bại"),"09:37"]],"Giao dịch mới nhất")}</div></div>""")

# 02 Dashboard kênh
spark = "".join(f'<i style="display:inline-block;width:7px;margin-right:2px;background:#0b5cd5;height:{h}px"></i>' for h in [18,22,25,30,34,40,38,35,28,26,31,36,42,46,44,40,37,33,35,39,43,47,50,48,45,41,44,49,52,55])
def chcard(name, st, h, extra, sp=True):
    return f"""<div class="card"><div style="display:flex;gap:8px;align-items:center"><h3 style="margin:0;font-size:16px">{name}</h3><span class="sp" style="flex:1"></span>{st}</div>
<div class="muted" style="margin:6px 0">{extra}</div><div style="display:flex;gap:8px;margin-bottom:8px">{h}</div>
<div class="muted">Số giao dịch theo ngày, 30 ngày</div><div style="height:58px;display:flex;align-items:flex-end;margin:4px 0 8px">{spark if sp else ''}</div><div style="display:flex;justify-content:space-between"><span class="muted">Xem dạng bảng</span><span class="btn">Chi tiết ›</span></div></div>"""
P["02"] = ("Dashboard kênh thanh toán", "Thanh toán / Kênh thanh toán", f"""
<div class="head"><h1>Kênh thanh toán</h1><div class="sp"></div><span class="muted">Cập nhật lúc 09:41:07</span><span class="btn">⟳</span></div>
<div class="grid-2e">{chcard("PAYGOV · Cổng thanh toán quốc gia", tag(OK,"✓ Đang hoạt động"), tag(WA,"⚠ Suy giảm")+tag(MU,"Mạch ngắt đóng")+"<span class='muted'>p95 24 giờ 1,4 s · lỗi 24 giờ 2,1 %</span>", "Hiệu lực từ 01/03/2027 · Đầu mối Trần T*** B · ☎ 024 **** 5678 · 12 dịch vụ<br><span style='color:#a11a1a'>⚠ Chứng thư ký hết hạn sau 6 ngày</span>")}
{chcard("MOCK-01 · NCC giả lập (môi trường thử)", tag(OK,"✓ Đang hoạt động"), tag(OK,"♥ Khỏe")+"<span class='muted'>p95 24 giờ 80 ms · lỗi 24 giờ 0 %</span>", "Hiệu lực từ 15/11/2026 · Đầu mối Nhóm PH-19 · 3 dịch vụ<br><span class='muted'>Khóa, chứng thư còn hạn 210 ngày</span>")}</div>
<div class="card" style="margin-top:12px"><span class="muted">▸ Kênh đã ngừng (0)</span></div>""")

# 03 Danh sách NCC
P["03"] = ("Danh sách nhà cung cấp", "Thanh toán / Danh mục thanh toán / Nhà cung cấp", f"""
<div class="head"><h1>Nhà cung cấp</h1><div class="sp"></div><span class="btn pri">+ Thêm nhà cung cấp</span></div>
{facets(["Tất cả 3","Nháp 1","Chờ duyệt 0","Đang hoạt động 2","Tạm dừng 0","Đã ngừng hẳn 0"])}
<div class="card"><div class="toolbar"><span class="input" style="min-width:260px">Tìm theo mã, tên</span><span class="input">Sức khỏe ▾</span><span class="btn">Xóa bộ lọc</span><div style="flex:1"></div><span class="muted">⚙ Cột · ≡ Mật độ</span></div>
{table(["Mã","Tên","Loại kết nối","Trạng thái","Sức khỏe","Hiệu lực từ","Dịch vụ hoạt động","GD hôm nay",""],[
["<span class='mono'>PAYGOV</span>","Cổng thanh toán quốc gia","PayGov",tag(OK,"✓ Đang hoạt động")+" ⏳","" + tag(WA,"⚠ Suy giảm"),"01/03/2027","<span class='num'>12</span>","<span class='num'>3.380</span>","⋯"],
["<span class='mono'>MOCK-01</span>","NCC giả lập","Giả lập",tag(OK,"✓ Đang hoạt động"),tag(OK,"♥ Khỏe"),"15/11/2026","<span class='num'>3</span>","<span class='num'>32</span>","⋯"],
["<span class='mono'>PAYGOV-2</span>","Cổng thanh toán quốc gia (kết nối 2)","PayGov",tag(MU,"✎ Nháp"),tag(MU,"? Chưa rõ"),"—","<span class='num'>0</span>","<span class='num'>0</span>","⋯"]],"Danh sách nhà cung cấp")}
{foot("1–3 / 3")}</div>""")

# 04 Chi tiết NCC
P["04"] = ("Chi tiết nhà cung cấp", "Thanh toán / Nhà cung cấp / Cổng thanh toán quốc gia", f"""
<div class="chrome"><h1><span class="mono">PAYGOV</span> · Cổng thanh toán quốc gia {tag(OK,"✓ Đang hoạt động")} {tag(WA,"⚠ Suy giảm")}</h1>
<div style="display:flex;align-items:center;gap:8px"><span class="muted">Hiệu lực 01/03/2027 · 12 dịch vụ · Mạch ngắt đóng · Đầu mối Trần T*** B</span><span style="flex:1"></span><span class="btn">Kiểm tra kết nối</span><span class="btn">Sửa</span><span class="btn">Tạm dừng</span><span class="btn">⋯ Đề nghị ngừng hẳn</span></div></div>
{tabs(["Thông tin","Thông tin xác thực ●2","Kiểm tra","Dịch vụ","Sức khỏe","Ánh xạ mã kết quả","Lịch sử"],1)}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 260px"><div class="card"><div class="toolbar"><span class="input">Môi trường: Thật ▾</span><div style="flex:1"></div><span class="btn">+ Gắn tham chiếu bí mật</span><span class="btn">Xoay khóa (Đ2b)</span></div>
{table(["Mục đích","Tham chiếu kho bí mật","Trạng thái","Vân tay","Hiệu lực đến","Cảnh báo"],[
["Khóa ký (SIGNING_KEY)","<span class='mono'>kv/t68/pay/paygov/sign</span>",tag(OK,"Đang dùng"),"<span class='mono'>3F:9A:…:C2</span>","02/12/2026",tag(ER,"Hết hạn sau 6 ngày")],
["Khóa ký (SIGNING_KEY)","<span class='mono'>kv/t68/pay/paygov/sign-next</span>",tag(IN,"Kế tiếp"),"<span class='mono'>71:0B:…:5E</span>","02/12/2027","—"],
["Chứng thư xác minh (VERIFY_CERT)","<span class='mono'>kv/t68/pay/paygov/verify</span>",tag(OK,"Đang dùng"),"<span class='mono'>A4:12:…:9D</span>","30/06/2028","—"],
["Chứng thư mTLS (MTLS_CLIENT_CERT)","<span class='mono'>kv/t68/pay/paygov/mtls</span>",tag(OK,"Đang dùng"),"<span class='mono'>0E:77:…:B1</span>","15/01/2027",tag(WA,"Hết hạn sau 50 ngày")],
["Thông tin API (API_CREDENTIAL)","<span class='mono'>kv/t68/pay/paygov/api</span>",tag(OK,"Đang dùng"),"—","—","—"]],"Thông tin xác thực")}
<div class="muted" style="margin-top:8px">Giá trị bí mật không bao giờ hiện trên màn; chỉ có tham chiếu và vân tay.</div></div>
<div class="card raised"><h4 style="margin:0 0 10px">Dòng thời gian vòng đời</h4><div class="vtl"><div>01/03 Kích hoạt (duyệt: Lê C)</div><div>27/02 Gửi đề nghị (Phạm D)</div><div>24/02 Giao dịch thử đạt</div><div>20/02 Khai báo</div></div></div></div>""")

# 05 Biểu mẫu NCC (ngăn kéo trên nền danh sách)
P["05"] = ("Biểu mẫu thêm, sửa nhà cung cấp", "Thanh toán / Danh mục thanh toán / Nhà cung cấp", P["03"][2], drawer("Thêm nhà cung cấp", """
<div class="field"><label>Mã nhà cung cấp *</label><div class="input mono">PAYGOV-2</div><div class="muted">Chữ in hoa, số, dấu gạch ngang; 2–32 ký tự; không đổi sau khi kích hoạt.</div></div>
<div class="field"><label>Tên *</label><div class="input">Cổng thanh toán quốc gia (kết nối 2)</div></div>
<div class="field"><label>Loại kết nối *</label><div class="input">PayGov ▾</div></div>
<div class="field"><label>Mã đơn vị tại nhà cung cấp *</label><div class="input mono">T68-UBND-002</div></div>
<div class="field"><label>Địa chỉ API môi trường thử *</label><div class="input mono">https://api-sandbox.paygov.vn/v2</div></div>
<div class="field"><label>Địa chỉ API môi trường thật</label><div class="input mono">https://api.paygov.vn/v2</div></div>
<div class="field"><label>Đầu mối, điện thoại</label><div class="input">Trần Thị B · 024 3xxx 5678</div></div>
<div class="field"><label>Hiệu lực từ</label><div class="input">01/01/2027</div></div>
<div class="foot"><span class="btn">Hủy</span><span class="btn pri">Lưu bản nháp</span></div>""", 640))

# 06 Trình hướng dẫn kích hoạt
P["06"] = ("Trình hướng dẫn kích hoạt nhà cung cấp", "Thanh toán / Nhà cung cấp / Cổng thanh toán quốc gia / Kích hoạt", f"""
<div class="head"><h1>Kích hoạt nhà cung cấp PAYGOV</h1>{tag(MU,"✎ Nháp")}</div>
<div class="steps"><div class="on">① Kiểm tra kết nối</div><div>② Giao dịch thử</div><div>③ Checklist</div><div>④ Gửi duyệt</div></div>
<div class="card" style="max-width:980px"><div style="display:flex;gap:12px;align-items:center;margin-bottom:10px"><span>Môi trường</span>{tag(IN,"● Thử")}{tag(MU,"○ Thật")}<span style="flex:1"></span><span class="btn pri">▶ Chạy kiểm tra kết nối</span></div>
{table(["Bước kiểm tra","Kết quả","Thời gian","Ghi chú"],[
["Phân giải tên miền api-sandbox.paygov.vn",tag(OK,"✓ Đạt"),"12 ms",""],
["Bắt tay TLS 1.3, chứng thư hợp lệ đến 30/06/2028",tag(OK,"✓ Đạt"),"48 ms",""],
["Xác thực mã đơn vị T68-UBND-001",tag(OK,"✓ Đạt"),"210 ms",""],
["Gọi API kiểm tra",tag(ER,"✗ Không đạt"),"95 ms","HTTP 401 · ERR-19-022 · <u>Mở thông tin xác thực</u>"]],"Kết quả kiểm tra kết nối")}
<div class="alert e" style="margin-top:10px">Thông tin xác thực môi trường Thử còn thiếu hoặc đã hết hạn: Khóa ký (SIGNING_KEY).<span class="sp"></span><span class="btn">Mở tab Thông tin xác thực</span></div>
<div class="muted">Lần chạy #4 · 09:12:30 · Phạm D · Xem nhật ký tích hợp</div>
<div class="foot"><span class="btn">Hủy</span><span class="btn">‹ Quay lại</span><span class="btn pri" style="opacity:.45">Tiếp tục ›</span></div></div>""")

# 07 Nhóm dịch vụ
grp = [["<span class='mono'>TU_PHAP</span>","Tư pháp, hộ tịch","<span class='mono'>LV.TP</span> · Tư pháp","8","1","Phạm D · 20/11/2026"],
       ["<span class='mono'>XAY_DUNG</span>","Xây dựng","<span class='mono'>LV.XD</span> · Xây dựng","6","2","Phạm D · 20/11/2026"],
       ["<span class='mono'>DAT_DAI</span>","Đất đai","<span class='mono'>LV.DD</span> · Đất đai","9","3","Phạm D · 19/11/2026"],
       ["<span class='mono'>KINH_DOANH</span>","Đăng ký kinh doanh","<span class='mono'>LV.KD</span> · Kế hoạch đầu tư","5","4","Lê C · 18/11/2026"],
       ["<span class='mono'>THUE_PHI</span>","Thuế, lệ phí trước bạ","<span class='mono'>LV.TC</span> · Tài chính","4","5","Lê C · 18/11/2026"],
       ["<span class='mono'>Y_TE</span>","Y tế","<span class='mono'>LV.YT</span> · Y tế","0","6","Phạm D · 26/11/2026"]]
P["07"] = ("Danh sách nhóm dịch vụ", "Thanh toán / Danh mục thanh toán / Nhóm dịch vụ", f"""
<div class="head"><h1>Nhóm dịch vụ</h1><span class="muted">hệ cũ gọi là "lĩnh vực giao dịch"</span><div class="sp"></div><span class="btn pri">+ Thêm nhóm</span></div>
<div class="card"><div class="toolbar"><span class="input" style="min-width:260px">Tìm theo mã, tên</span><div style="flex:1"></div><span class="muted">Kéo thả hoặc Alt+↑/↓ để đổi thứ tự</span></div>
{table(["⋮⋮ Mã","Tên nhóm","Mã lĩnh vực (PH-07)","Số dịch vụ","Thứ tự","Sửa cuối",""],[r+["Sửa · Xóa"] for r in grp],"Danh sách nhóm dịch vụ")}{foot("1–6 / 6")}</div>""")

# 08 Biểu mẫu nhóm
P["08"] = ("Biểu mẫu nhóm dịch vụ", "Thanh toán / Danh mục thanh toán / Nhóm dịch vụ", P["07"][2], drawer("Thêm nhóm dịch vụ", """
<div class="field"><label>Mã nhóm *</label><div class="input mono">Y_TE</div><div class="muted">Chữ in hoa, số, dấu gạch dưới; duy nhất trong tỉnh.</div></div>
<div class="field"><label>Tên nhóm *</label><div class="input">Y tế</div></div>
<div class="field"><label>Mã lĩnh vực trong danh mục dùng chung *</label><div class="input">LV.YT · Y tế ▾</div><div class="muted">Kiểm tra với PH-07 khi lưu; mã hết hiệu lực sẽ bị từ chối (ERR-19-039).</div></div>
<div class="field"><label>Thứ tự hiển thị</label><div class="input">6</div></div>
<div class="field"><label>Mô tả</label><div class="input" style="height:64px">Lệ phí, phí thuộc lĩnh vực y tế</div></div>
<div class="foot"><span class="btn">Hủy</span><span class="btn pri">Lưu</span></div>"""))

# 09 Dịch vụ
P["09"] = ("Danh sách dịch vụ thanh toán", "Thanh toán / Danh mục thanh toán / Dịch vụ", f"""
<div class="head"><h1>Dịch vụ thanh toán</h1><div class="sp"></div><span class="btn pri">+ Thêm dịch vụ</span></div>
{facets(["Tất cả 32","Nháp 2","Đang hoạt động 28","Tạm dừng 1","Đã ngừng hẳn 1"])}
<div class="card"><div class="toolbar"><span class="input" style="min-width:240px">Tìm theo mã, tên</span><span class="input">Nhóm ▾</span><span class="input">Nhà cung cấp ▾</span><div style="flex:1"></div><span class="muted">⚙ Cột</span></div>
{table(["Mã","Tên dịch vụ","Nhóm","Nhà cung cấp","Khoảng số tiền","Mã phí (PH-07)","Trạng thái","GD 30 ngày",""],[
["<span class='mono'>HT-KHAI-SINH</span>","Lệ phí đăng ký hộ tịch","Tư pháp, hộ tịch","PAYGOV","5.000–200.000 ₫","<span class='mono'>PL.HT.01</span>",tag(OK,"✓ Đang hoạt động"),"<span class='num'>21.304</span>","⋯"],
["<span class='mono'>XD-GPXD</span>","Phí cấp phép xây dựng","Xây dựng","PAYGOV","100.000–20.000.000 ₫","<span class='mono'>PL.XD.02</span>",tag(OK,"✓ Đang hoạt động"),"<span class='num'>14.820</span>","⋯"],
["<span class='mono'>DD-THAM-DINH</span>","Phí thẩm định hồ sơ đất đai","Đất đai","PAYGOV","50.000–5.000.000 ₫","<span class='mono'>PL.DD.04</span>",tag(OK,"✓ Đang hoạt động"),"<span class='num'>9.105</span>","⋯"],
["<span class='mono'>KD-DKKD</span>","Lệ phí đăng ký kinh doanh","Đăng ký kinh doanh","PAYGOV","50.000–500.000 ₫","<span class='mono'>PL.KD.01</span>",tag(WA,"⏸ Tạm dừng"),"<span class='num'>7.260</span>","⋯"],
["<span class='mono'>TB-OTO</span>","Lệ phí trước bạ ô tô","Thuế, lệ phí trước bạ","PAYGOV","1.000.000–2.000.000.000 ₫","<span class='mono'>PL.TC.07</span>",tag(OK,"✓ Đang hoạt động"),"<span class='num'>3.981</span>","⋯"],
["<span class='mono'>YT-GIAM-DINH</span>","Phí giám định y khoa","Y tế","MOCK-01","100.000–1.000.000 ₫","<span class='mono'>PL.YT.03</span>",tag(MU,"✎ Nháp"),"<span class='num'>0</span>","⋯"]],"Danh sách dịch vụ")}{foot("1–20 / 32")}</div>""")

# 10 Chi tiết dịch vụ
P["10"] = ("Chi tiết, biểu mẫu dịch vụ thanh toán", "Thanh toán / Dịch vụ / Lệ phí đăng ký hộ tịch", f"""
<div class="chrome"><h1><span class="mono">HT-KHAI-SINH</span> · Lệ phí đăng ký hộ tịch {tag(OK,"✓ Đang hoạt động")}</h1><div style="display:flex;gap:8px;align-items:center"><span class="muted">Nhóm Tư pháp, hộ tịch · Nhà cung cấp PAYGOV · 4 đối tác được gán</span><span style="flex:1"></span><span class="btn">Sửa</span><span class="btn">Tạm dừng</span><span class="btn">⋯</span></div></div>
{tabs(["Thông tin","Đối tác được gán 4","Giao dịch","Lịch sử"],0)}
<div class="card"><dl class="dl"><dt>Mã dịch vụ</dt><dd class="mono">HT-KHAI-SINH</dd><dt>Tên</dt><dd>Lệ phí đăng ký hộ tịch</dd>
<dt>Nhóm</dt><dd>Tư pháp, hộ tịch</dd><dt>Nhà cung cấp</dt><dd>PAYGOV · Cổng thanh toán quốc gia</dd>
<dt>Mã phí, lệ phí (PH-07)</dt><dd><span class="mono">PL.HT.01</span> · Lệ phí hộ tịch</dd><dt>Mã thủ tục (PH-07)</dt><dd><span class="mono">1.001193</span> · Đăng ký khai sinh</dd>
<dt>Số tiền tối thiểu</dt><dd>5.000 ₫</dd><dt>Số tiền tối đa</dt><dd>200.000 ₫</dd>
<dt>Thời hạn thanh toán</dt><dd>15 phút</dd><dt>Cho phép hoàn tiền</dt><dd>Có, trong 180 ngày</dd>
<dt>Tài khoản thụ hưởng</dt><dd>KBNN T68 · ****4521</dd><dt>Hiệu lực từ</dt><dd>01/03/2027</dd>
<dt>Người tạo</dt><dd>Phạm D · 20/02/2027</dd><dt>Người sửa cuối</dt><dd>Lê C · 18/11/2026</dd></dl></div>""")

# 11 Đối tác
P["11"] = ("Danh sách đối tác", "Thanh toán / Danh mục thanh toán / Đối tác", f"""
<div class="head"><h1>Đối tác</h1><div class="sp"></div><span class="btn pri">+ Đăng ký đối tác</span></div>
{facets(["Tất cả 5","Nháp 1","Chờ duyệt 1","Đang hoạt động 3","Tạm dừng 0","Đã chấm dứt 0"])}
<div class="card"><div class="toolbar"><span class="input" style="min-width:240px">Tìm theo mã, tên</span><span class="input">Chế độ định tuyến ▾</span><div style="flex:1"></div><span class="muted">⚙ Cột</span></div>
{table(["Mã","Tên đối tác","Cơ quan chủ quản","HTTT","Trạng thái","Chế độ","Dịch vụ","Client","GD hôm nay","Webhook 24 giờ"],[
["<span class='mono'>DVC-T68</span>","Cổng dịch vụ công tỉnh","Văn phòng UBND tỉnh","<u>HT-0012</u>",tag(OK,"✓ Đang hoạt động"),tag(IN,"⧉ Chạy bóng"),"6","2","<span class='num'>2.904</span>","99,6 %"],
["<span class='mono'>MC-T68</span>","Một cửa điện tử tỉnh","Sở Thông tin và Truyền thông","<u>HT-0015</u>",tag(OK,"✓ Đang hoạt động"),tag(OK,"Datahub"),"9","1","<span class='num'>486</span>","<span style='color:#a11a1a'>92,1 % thấp</span>"],
["<span class='mono'>DD-T68</span>","Hệ thống thông tin đất đai","Sở Tài nguyên và Môi trường","<u>HT-0021</u>",tag(OK,"✓ Đang hoạt động"),tag(MU,"Hệ cũ"),"4","1","<span class='num'>22</span>","100 %"],
["<span class='mono'>YT-T68</span>","Hệ thống y tế tỉnh","Sở Y tế","<u>HT-0030</u>",tag(IN,"⏳ Chờ duyệt"),tag(MU,"Hệ cũ"),"1","0","0","—"],
["<span class='mono'>GD-T68</span>","Cơ sở dữ liệu giáo dục","Sở Giáo dục và Đào tạo","—",tag(MU,"✎ Nháp"),tag(MU,"Hệ cũ"),"0","0","0","—"]],"Danh sách đối tác")}{foot("1–5 / 5")}</div>""")

# 12 Chi tiết đối tác
P["12"] = ("Chi tiết đối tác", "Thanh toán / Đối tác / Cổng dịch vụ công tỉnh", f"""
<div class="chrome"><h1><span class="mono">DVC-T68</span> · Cổng dịch vụ công tỉnh {tag(OK,"✓ Đang hoạt động")} {tag(IN,"⧉ Chạy bóng")}</h1><div style="display:flex;gap:8px;align-items:center"><span class="muted">Chủ quản Văn phòng UBND tỉnh · HTTT HT-0012 · 6 dịch vụ · 2 client</span><span style="flex:1"></span><span class="btn">Tạm dừng</span><span class="btn">⋯ Đề nghị chấm dứt</span></div></div>
{tabs(["Hồ sơ","Client","Dịch vụ và hạn mức","Webhook ●1","Chế độ định tuyến","Lịch sử"],2)}
<div class="card"><div class="toolbar"><span class="input" style="min-width:220px">Tìm dịch vụ</span><div style="flex:1"></div><span class="btn pri">+ Gán dịch vụ</span></div>
{table(["Dịch vụ","Trạng thái dịch vụ","Hạn mức mỗi giao dịch","Tối đa số GD/ngày","Tối đa tiền/ngày","Đã dùng hôm nay","Hiệu lực",""],[
["Lệ phí đăng ký hộ tịch",tag(OK,"✓ Đang hoạt động"),"200.000 ₫","5.000","500.000.000 ₫","<div class='prog'><i style='width:16%'></i></div><span class='muted'>16 %</span>","01/03/2027 →","Sửa"],
["Phí cấp phép xây dựng",tag(OK,"✓ Đang hoạt động"),"20.000.000 ₫","2.000","5.000.000.000 ₫","<div class='prog'><i style='width:41%'></i></div><span class='muted'>41 %</span>","01/03/2027 →","Sửa"],
["Phí thẩm định hồ sơ đất đai",tag(OK,"✓ Đang hoạt động"),"5.000.000 ₫","1.000","1.000.000.000 ₫","<div class='prog'><i style='width:88%;background:#c78a00'></i></div><span style='color:#7a5200'>88 % gần hạn mức</span>","01/03/2027 →","Sửa"],
["Lệ phí đăng ký kinh doanh",tag(WA,"⏸ Tạm dừng"),"500.000 ₫","1.000","200.000.000 ₫","<div class='prog'><i style='width:0'></i></div><span class='muted'>0 %</span>","01/03/2027 →","Sửa"]],"Dịch vụ và hạn mức")}</div>""")

# 13 Hộp phê duyệt
P["13"] = ("Hộp phê duyệt", "Thanh toán / Hộp phê duyệt", f"""
<div class="head"><h1>Hộp phê duyệt</h1></div>
{facets(["Chờ tôi quyết định 3","Tôi đã lập 2","Đã xử lý","Tất cả"])}
<div class="card" style="margin-right:40%"><div class="toolbar"><span class="input">Loại ▾</span><span class="input">Trạng thái ▾</span></div>
{table(["Mã","Loại","Đối tượng","Số tiền","Người lập","Hạn"],[
["<b>AR-00412</b>","Hoàn tiền (cấp 2)","RF-0091","7.500.000 ₫","Nguyễn K","còn 6 ngày"],
["AR-00409","Kích hoạt NCC","PAYGOV-2","—","Phạm D","còn 6 ngày"],
["AR-00405","Xử lý chênh lệch","DC-20261125-0007","50.000 ₫","Nguyễn K","còn 5 ngày"]],"Đề nghị chờ quyết định")}</div>""",
drawer("AR-00412 · Hoàn tiền cấp 2", f"""<div style="margin-bottom:8px">{tag(IN,"⏳ Chờ quyết định")} <span class="muted">Gửi 25/11 14:02 · Nguyễn K</span></div>
<div class="card"><b>Hoàn 7.500.000 ₫ / 7.500.000 ₫</b><div class="muted">cho giao dịch <span class="mono">{TX4}</span> · Phí cấp phép xây dựng · DVC-T68</div></div>
<div class="card"><div class="muted">Lý do người lập</div>Hồ sơ bị trả lại do không thuộc thẩm quyền; người nộp đề nghị hoàn toàn bộ.</div>
<div class="card"><div class="muted">Bằng chứng</div>📎 Đơn đề nghị hoàn.pdf · 📎 Quyết định trả hồ sơ.pdf · <u>Giao dịch gốc ›</u><br>Duyệt cấp 1: Lê C · 25/11 16:20 · "Đồng ý"</div>
<div class="card"><div class="muted">Kiểm tra lúc duyệt</div>✓ Còn được hoàn 7.500.000 ₫ &nbsp; ✓ Trong hạn 180 ngày &nbsp; ✓ Người duyệt khác người lập và người duyệt cấp 1</div>
<div class="field"><label>Ý kiến (bắt buộc khi từ chối)</label><div class="input" style="height:56px"></div></div>
<div class="foot"><span class="btn danger">Từ chối</span><span class="btn pri">Duyệt</span></div>""", 720))

# 14 Tra cứu giao dịch
P["14"] = ("Tra cứu giao dịch", "Thanh toán / Tra cứu giao dịch", f"""
<div class="head"><h1>Tra cứu giao dịch</h1><div class="sp"></div><span class="btn">⤓ Xuất ▾</span></div>
<div class="card"><div class="toolbar"><span class="input" style="min-width:360px">Mã giao dịch, mã đơn hàng, mã tham chiếu NCC</span><span class="btn">Hôm nay</span><span class="btn pri">7 ngày</span><span class="btn">30 ngày</span><span class="btn">Tháng này</span>
<span class="input">Trạng thái: Thành công, Chờ thanh toán ×</span><span class="input">Nhóm dịch vụ (lĩnh vực) ▾</span><span class="btn">Bộ lọc nâng cao (3) ▾</span><span class="btn">Xóa bộ lọc</span></div>
<div style="display:flex;justify-content:space-between;margin-bottom:6px"><b>Tìm thấy 3.412 giao dịch · Tổng tiền 1.732.450.000 ₫</b><span class="muted">⚙ Cột · ≡ Mật độ</span></div>
{table(["Mã giao dịch","Mã yêu cầu","Tên giao dịch","Kênh","Lĩnh vực","Số tiền","Ngày phát sinh","Trạng thái","Người thanh toán"],[
[f"<span class='mono'>{TX1}</span>","HS-2026-001234","Lệ phí đăng ký hộ tịch","PayGov","Tư pháp","<span class='num'>50.000 ₫</span>","26/11 09:40:12",tag(OK,"✓ Thành công")+" "+tag(WA,"⏱ Muộn"),"Nguyễn V***"],
[f"<span class='mono'>{TX2}</span>","HS-2026-001233","Phí cấp phép xây dựng","PayGov","Xây dựng","<span class='num'>1.500.000 ₫</span>","26/11 09:39:05",tag(IN,"⏳ Chờ thanh toán"),"Trần T***"],
[f"<span class='mono'>{TX5}</span>","HS-2026-001230","Phí thẩm định hồ sơ đất đai","PayGov","Đất đai","<span class='num'>450.000 ₫</span>","26/11 09:31:44",tag(OK,"✓ Thành công"),"Lê M***"],
[f"<span class='mono'>{TX3}</span>","MC-88213","Lệ phí trước bạ ô tô","PayGov","Thuế","<span class='num'>3.200.000 ₫</span>","26/11 09:30:02",tag(ER,"✗ Thất bại"),"Phạm H***"],
[f"<span class='mono'>{TX4}</span>","HS-2026-000981","Phí cấp phép xây dựng","PayGov","Xây dựng","<span class='num'>7.500.000 ₫</span>","25/11 10:12:40",tag(OK,"✓ Thành công"),"Võ Q***"],
["<span class='mono'>T68261125M1P4S7U2WC</span>","HS-2026-000977","Lệ phí lý lịch tư pháp","PayGov","Tư pháp","<span class='num'>200.000 ₫</span>","25/11 09:58:01",tag(WA,"↶ Hoàn một phần"),"Đỗ A***"],
["<span class='mono'>T68261125H9R3D6K8YB</span>","HS-2026-000975","Lệ phí đăng ký hộ tịch","PayGov","Tư pháp","<span class='num'>8.000 ₫</span>","25/11 09:44:19",tag(MU,"⌛ Hết hạn"),"Bùi T***"]],"Kết quả tra cứu giao dịch")}
<div class="foot" style="justify-content:space-between"><span class="muted">1–20 / 3.412</span><span class="muted">‹ Trang trước · Trang sau › · 20 / trang</span></div></div>""")

# 15 Chi tiết giao dịch
P["15"] = ("Chi tiết giao dịch", f"Thanh toán / Tra cứu giao dịch / {TX1}", f"""
<div class="chrome"><h1><span class="mono">{TX1}</span> ⧉ {tag(OK,"✓ Thành công")} {tag(WA,"⏱ Thanh toán muộn")} <span class="muted" style="font-size:13px;font-weight:400">Đối soát</span> {tag(OK,"✓ Khớp")}</h1>
<div class="muted"><b style="color:#1a1d23">50.000 ₫</b> · Lệ phí đăng ký hộ tịch · Cổng dịch vụ công tỉnh · PayGov</div>
<div style="display:flex;gap:8px;align-items:center;margin-top:6px"><span class="muted">Mã đơn hàng HS-2026-001234 ⧉ · Mã tham chiếu NCC PG-99812233 ⧉ · Mã truy vết 4bf92f…a3 ⧉</span><span style="flex:1"></span><span class="btn">⟳ Đồng bộ với NCC</span><span class="btn">Lập yêu cầu hoàn</span><span class="btn">⋯ Hủy giao dịch</span><span class="btn">Mở vết đầu-cuối</span></div></div>
{tabs(["Thông tin","Dòng thời gian 5","IPN 2","Truy vấn NCC 1","Webhook 1","Hoàn tiền 0","Chênh lệch 0","Nhật ký"],0)}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 300px"><div class="card"><dl class="dl">
<dt>Số tiền</dt><dd>50.000 ₫</dd><dt>Đã hoàn</dt><dd>0 ₫ · còn được hoàn 50.000 ₫</dd>
<dt>Tạo lúc</dt><dd>26/11/2026 09:30:02</dd><dt>Hết hạn lúc</dt><dd>26/11/2026 09:45:02</dd>
<dt>Thanh toán lúc</dt><dd>26/11/2026 09:52:40</dd><dt>Kênh, ngân hàng</dt><dd>QR · VCB</dd>
<dt>Kết quả NCC</dt><dd><span class="mono">00</span> → Thành công (bảng ánh xạ v3)</dd><dt>Dịch vụ</dt><dd>HT-KHAI-SINH</dd>
<dt>Người nộp</dt><dd>Nguyễn V*** A** · ******6789 · ********1234</dd><dt></dt><dd><span class="btn">👁 Hiện thông tin người nộp</span></dd>
<dt>Nội dung</dt><dd>HS-2026-001234 Le phi dang ky ho tich</dd><dt>Thuộc tính thêm</dt><dd class="mono">hoSo=HS-2026-001234, linhVuc=TU_PHAP</dd></dl>
<div class="alert i" style="margin-top:12px">Giao dịch được thanh toán sau thời điểm hết hạn 7 phút 38 giây nên mang cờ "Thanh toán muộn"; tiền đã được ghi nhận theo IPN hợp lệ.</div></div>
<div class="card raised"><h4 style="margin:0 0 10px">Dòng thời gian</h4><div class="vtl"><div>09:30:02 Đã ghi nhận · Đối tác</div><div>09:30:03 Chờ thanh toán · NCC khởi tạo</div><div>09:45:02 Hết hạn · Tác vụ hết hạn</div><div>09:52:41 Thành công (muộn) · IPN</div><div>27/11 06:10 Khớp · Đối soát</div></div></div></div>""")

# 16 IPN
P["16"] = ("Danh sách và chi tiết IPN", "Thanh toán / IPN", f"""
<div class="head"><h1>Thông báo kết quả (IPN)</h1></div>
{facets(["Tất cả 3.421","Đã xử lý 3.409","Trùng, bỏ qua 6","Đã cách ly 4","Từ chối 2"],3)}
<div class="card" style="margin-right:40%"><div class="toolbar"><span class="input">Xác minh ▾</span><span class="input">Lý do ▾</span><span class="input">Hôm nay ▾</span></div>
{table(["Nhận lúc","Xác minh","Xử lý","Lý do cách ly"],[
["09:58:12",tag(OK,"Hợp lệ"),tag(WA,"Đã cách ly"),"Sai số tiền"],
["09:41:03",tag(OK,"Hợp lệ"),tag(WA,"Đã cách ly"),"Không tìm thấy giao dịch"],
["08:22:47",tag(ER,"Sai chữ ký"),tag(ER,"Từ chối"),"—"],
["07:15:30",tag(OK,"Hợp lệ"),tag(WA,"Đã cách ly"),"Trái trạng thái"]],"Danh sách IPN")}</div>""",
drawer("IPN · nhận 09:58:12", f"""<div class="card"><dl class="dl" style="grid-template-columns:130px 1fr"><dt>Nhà cung cấp</dt><dd>PAYGOV</dd><dt>Mã giao dịch</dt><dd class="mono">{TX5}</dd><dt>Xác minh</dt><dd>{tag(OK,"Hợp lệ")} chứng thư A4:12:…:9D</dd><dt>Xử lý</dt><dd>{tag(WA,"Đã cách ly")}</dd><dt>Lý do</dt><dd>Số tiền IPN 405.000 ₫ khác số tiền giao dịch 450.000 ₫</dd></dl></div>
<div class="alert w">Thông báo kết quả (IPN) đã được tiếp nhận nhưng bị cách ly để xem xét, lý do "Sai số tiền".</div>
<div class="code">{{
  "orderId": "{TX5}",
  "amount": 405000,
  "resultCode": "00",
  "paidAt": "2026-11-26T09:58:10+07:00",
  "signature": "MEUCIQ…(đã rút gọn)"
}}</div>
<div class="foot"><span class="btn">Bỏ qua có lý do</span><span class="btn pri">Xử lý lại (Đ2b)</span></div>""", 720))

# 17 Hoàn tiền
P["17"] = ("Danh sách yêu cầu hoàn tiền", "Thanh toán / Hoàn tiền", f"""
<div class="head"><h1>Yêu cầu hoàn tiền</h1><div class="sp"></div><span class="btn pri">+ Lập yêu cầu hoàn</span></div>
<div class="alert w">Việc của tôi · 2 yêu cầu chờ hoàn thủ công, 0 yêu cầu hoàn lỗi.<span class="sp"></span><span class="btn">Xem</span></div>
{facets(["Tất cả 41","Chờ duyệt 3","Đang thực hiện 1","Chờ hoàn thủ công 2","Hoàn lỗi 0","Đã hoàn 33","Đã kết thúc khác 2"])}
<div class="card"><div class="toolbar"><span class="input">Chế độ ▾</span><span class="input">Đối tác ▾</span><span class="input">30 ngày ▾</span></div>
{table(["Mã yêu cầu","Mã giao dịch","Số tiền hoàn","Số tiền GD","Trạng thái","Chế độ","Nguồn lập","Lý do","Người lập","Lập lúc"],[
["RF-0091",f"<span class='mono'>{TX4}</span>","<span class='num'>7.500.000 ₫</span>","<span class='num'>7.500.000 ₫</span>",tag(IN,"⏳ Chờ duyệt cấp 2"),"Thủ công","Cán bộ","Trả hồ sơ","Nguyễn K","25/11 14:02"],
["RF-0090","<span class='mono'>T68261125M1P4S7U2WC</span>","<span class='num'>100.000 ₫</span>","<span class='num'>200.000 ₫</span>",tag(WA,"Chờ hoàn thủ công"),"Thủ công","Cán bộ","Nộp thừa","Nguyễn K","25/11 10:30"],
["RF-0089","<span class='mono'>T68261124C5E2G8N4QA</span>","<span class='num'>50.000 ₫</span>","<span class='num'>50.000 ₫</span>",tag(WA,"Chờ hoàn thủ công"),"Thủ công","Đối tác","Hủy hồ sơ","DVC-T68","24/11 16:45"],
["RF-0088","<span class='mono'>T68261124J7L3T9V1XF</span>","<span class='num'>1.000.000 ₫</span>","<span class='num'>1.000.000 ₫</span>",tag(OK,"✓ Đã hoàn"),"Thủ công","Cán bộ","Nộp nhầm dịch vụ","Nguyễn K","24/11 09:12"]],"Danh sách yêu cầu hoàn tiền")}{foot("1–20 / 41")}</div>""")

# 18 Lập yêu cầu hoàn
P["18"] = ("Lập, xem chi tiết yêu cầu hoàn tiền", "Thanh toán / Hoàn tiền / Lập yêu cầu", f"""
<div class="head"><h1>Lập yêu cầu hoàn tiền</h1></div>
<div class="card raised" style="max-width:900px;margin-bottom:12px"><b>Giao dịch gốc</b> · <span class="mono">{TX1}</span> {tag(OK,"✓ Thành công")} · 50.000 ₫ · thanh toán 26/11/2026 · còn hạn hoàn 179 ngày<div class="muted">Đã hoàn 0 ₫ · Còn được hoàn 50.000 ₫</div></div>
<div class="card" style="max-width:900px">
<div class="field"><label>Loại hoàn *</label>{tag(IN,"● Toàn phần")} {tag(MU,"○ Một phần")}</div>
<div class="field"><label>Số tiền hoàn *</label><div class="input" style="width:280px">50.000 ₫</div><div class="muted">Năm mươi nghìn đồng</div></div>
<div class="field"><label>Lý do *</label><div style="display:flex;gap:8px"><div class="input" style="width:220px">Nộp thừa ▾</div><div class="input" style="flex:1">Người nộp thanh toán hai lần cho cùng hồ sơ</div></div></div>
<div class="field"><label>Cách hoàn</label>Thủ công (chuyển khoản ngoài hệ thống) <span class="muted">· theo tham số 19.refund.default-mode và năng lực NCC</span></div>
<div class="field"><label>Ngân hàng nhận, số tài khoản nhận *</label><div style="display:flex;gap:8px"><div class="input" style="width:220px">VCB ▾</div><div class="input" style="flex:1">••••••••••••••  (mã hóa ngay khi gửi)</div></div></div>
<div class="field"><label>Tài liệu</label><span class="btn">⤒ Tải lên</span> Đơn đề nghị hoàn.pdf {tag(OK,"✓ đã quét")} ×</div>
<div class="alert i">ⓘ Số tiền từ 5.000.000 ₫ trở lên cần hai cấp duyệt.</div>
<div class="foot"><span class="btn">Hủy</span><span class="btn pri">Gửi yêu cầu hoàn</span></div></div>""")

# 19 Phiên đối soát
P["19"] = ("Danh sách phiên đối soát", "Thanh toán / Đối soát", f"""
<div class="head"><h1>Phiên đối soát</h1><div class="sp"></div><span class="btn">Lịch</span><span class="btn pri">Bảng</span><span class="btn">+ Tạo phiên thủ công</span></div>
<div class="card"><div class="toolbar"><span class="input">NCC: PAYGOV ▾</span><span class="input">Trạng thái ▾</span><span class="input">Ngày nghiệp vụ 01/11/2026 – 26/11/2026</span></div>
{table(["Ngày nghiệp vụ","NCC","Trạng thái","Lần chạy","GD Datahub","GD NCC","Tiền Datahub","Tiền NCC","Chênh mở","Chốt lúc"],[
["25/11/2026","PAYGOV",tag(WA,"⚖ Đang xử lý chênh lệch"),"2","<span class='num'>3.380</span>","<span class='num'>3.379</span>","<span class='num'>1.712.450.000</span>","<span class='num'>1.712.400.000</span>","<b>1</b>","—"],
["24/11/2026","PAYGOV",tag(MU,"🔒 Đã chốt"),"1","<span class='num'>3.102</span>","<span class='num'>3.102</span>","<span class='num'>1.598.220.000</span>","<span class='num'>1.598.220.000</span>","0","25/11 08:40"],
["23/11/2026","PAYGOV",tag(MU,"🔒 Đã chốt"),"1","<span class='num'>1.215</span>","<span class='num'>1.215</span>","<span class='num'>602.730.000</span>","<span class='num'>602.730.000</span>","0","24/11 08:15"],
["22/11/2026","PAYGOV",tag(MU,"🔒 Đã chốt"),"3","<span class='num'>1.188</span>","<span class='num'>1.188</span>","<span class='num'>587.100.000</span>","<span class='num'>587.100.000</span>","0","24/11 15:02"],
["26/11/2026","PAYGOV",tag(MU,"Đã lên lịch"),"0","—","—","—","—","—","—"]],"Danh sách phiên đối soát")}{foot("1–5 / 26")}</div>""")

# 20 Chi tiết phiên đối soát
P["20"] = ("Chi tiết phiên đối soát", "Thanh toán / Đối soát / PAYGOV 25/11/2026", f"""
<div class="chrome"><h1>PAYGOV · Ngày nghiệp vụ 25/11/2026 {tag(WA,"⚖ Đang xử lý chênh lệch")} <span class="muted" style="font-size:13px;font-weight:400">Lần chạy 2</span></h1>
<div style="display:flex;gap:8px;align-items:center"><span class="muted">Nguồn tệp tải từ NCC lúc 06:05 · sha256 9f2c…e1 · 1 chênh lệch chưa xử lý</span><span style="flex:1"></span><span class="btn">⤒ Tải file đối soát</span><span class="btn">⟳ Thu thập lại</span><span class="btn">▶ Chạy lại so khớp</span><span class="btn pri" style="opacity:.45">🔒 Chốt phiên</span></div></div>
{tabs(["Tổng hợp","Dòng đối soát 3.381","Chênh lệch 1","Tệp","Biên bản","Lịch sử"],0)}
<div class="card" style="max-width:980px">{table(["Chỉ tiêu","Datahub","Nhà cung cấp","Chênh"],[
["Số giao dịch thành công","<span class='num'>3.380</span>","<span class='num'>3.379</span>","<b style='color:#a11a1a'>1</b>"],
["Tổng tiền thu","<span class='num'>1.712.450.000 ₫</span>","<span class='num'>1.712.400.000 ₫</span>","<b style='color:#a11a1a'>50.000 ₫</b>"],
["Số khoản hoàn","<span class='num'>2</span>","<span class='num'>2</span>","0"],
["Tổng tiền hoàn","<span class='num'>120.000 ₫</span>","<span class='num'>120.000 ₫</span>","0"],
["Khớp tự động","<span class='num'>3.379 (99,97 %)</span>","",""]],"Tổng hợp hai phía")}
<div class="alert w" style="margin-top:10px">Còn 1 chênh lệch chưa xử lý.<span class="sp"></span><span class="btn">Xem chênh lệch còn mở</span></div></div>""")

# 21 Chênh lệch
P["21"] = ("Danh sách chênh lệch", "Thanh toán / Chênh lệch", f"""
<div class="head"><h1>Chênh lệch đối soát</h1></div>
{facets(["Giao cho tôi 1","Chưa ai nhận 0","Quá hạn 1","Tất cả 7"])}
<div class="card"><div class="toolbar"><span class="input">Loại ▾</span><span class="input">Trạng thái ▾</span><span class="input">NCC ▾</span><div style="flex:1"></div><span class="btn">Giao cho…</span></div>
{table(["☐","Mã chênh lệch","Loại","Trạng thái","Giao dịch","Ngày nghiệp vụ","Tiền Datahub","Tiền NCC","Chênh","Tuổi","Phụ trách"],[
["☐","DC-20261125-0007","Lệch số tiền",tag(WA,"🔍 Đang xác minh"),f"<span class='mono'>{TX1}</span>","<u>25/11/2026</u>","<span class='num'>50.000</span>","<span class='num'>0</span>","<span class='num'>50.000</span>","1 ngày","Nguyễn K"],
["☐","DC-20261120-0004","Thiếu ở NCC",tag(WA,"Đã chuyển NCC"),"<span class='mono'>T68261120R6T1W4Y9ZK</span>","<u>20/11/2026</u>","<span class='num'>200.000</span>","<span class='num'>0</span>","<span class='num'>200.000</span>","<span style='color:#a11a1a'>quá hạn 2 ngày</span>","Nguyễn K"],
["☐","DC-20261118-0003","Thiếu ở Datahub",tag(OK,"✓ Đã xử lý"),"—","<u>18/11/2026</u>","<span class='num'>0</span>","<span class='num'>30.000</span>","<span class='num'>30.000</span>","—","Lê C"]],"Danh sách chênh lệch")}{foot("1–7 / 7")}</div>""")

# 22 Chi tiết chênh lệch
P["22"] = ("Chi tiết chênh lệch và đề xuất xử lý", "Thanh toán / Chênh lệch / DC-20261125-0007", f"""
<div class="chrome"><h1>DC-20261125-0007 · Lệch số tiền {tag(WA,"🔍 Đang xác minh")}</h1><div style="display:flex;gap:8px;align-items:center"><span class="muted">Phụ trách Nguyễn K · tuổi 1 ngày · phiên PAYGOV 25/11/2026</span><span style="flex:1"></span><span class="btn">Giao cho…</span><span class="btn">Chuyển NCC</span><span class="btn">Ghi chú</span><span class="btn pri">Đề xuất xử lý</span></div></div>
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 340px"><div class="card"><h4 style="margin:0 0 8px">So sánh hai phía</h4>{table(["Trường","Datahub","Nhà cung cấp",""],[
["Mã giao dịch",f"<span class='mono'>{TX1}</span>","PG-99812233",""],["Số tiền","50.000 ₫","0 ₫","<b style='color:#a11a1a'>≠</b>"],
["Trạng thái","Thành công","Không có","<b style='color:#a11a1a'>≠</b>"],["Thời điểm","25/11 09:52","—",""]],"So sánh hai phía")}
<div style="margin-top:10px;display:flex;gap:8px"><span class="btn">Mở giao dịch</span><span class="btn">Mở IPN</span><span class="btn">Mở dòng đối soát</span></div>
<h4 style="margin:16px 0 8px">Đề xuất xử lý</h4><div class="field"><label>Cách xử lý *</label><div class="input">Chờ NCC bổ sung ở phiên ngày kế tiếp ▾</div></div><div class="field"><label>Lý do *</label><div class="input">PayGov xác nhận qua email giao dịch ghi nhận muộn sang ngày 26/11</div></div></div>
<div class="card raised"><h4 style="margin:0 0 10px">Dòng thời gian</h4><div class="vtl"><div>26/11 08:10 Nguyễn K nhận việc</div><div>26/11 08:30 Ghi chú, đã gọi PayGov 📎 email-paygov.pdf</div><div>25/11 06:12 Phát hiện ở lần chạy 1</div></div><div class="input" style="width:100%">Thêm ghi chú…</div></div></div>""")

# 23 Nhật ký tích hợp
P["23"] = ("Nhật ký tích hợp", "Thanh toán / Nhật ký tích hợp", f"""
<div class="head"><h1>Nhật ký tích hợp</h1></div>
<div class="card" style="margin-right:40%"><div class="toolbar"><span class="input">Hướng ▾</span><span class="input">Thao tác ▾</span><span class="input">Kết quả ▾</span><span class="input">Hôm nay</span></div>
{table(["Lúc","Hướng","Thao tác","Đối tượng","HTTP","Mã kết quả","Độ trễ"],[
["09:58:12","NCC → Datahub","IPN","PAYGOV","200","ERR-19-028","38 ms"],
["09:52:40","Datahub → NCC","QUERY","PAYGOV","200","00","1,2 s"],
["09:41:22","Đối tác → Datahub","INIT","DVC-T68","409","ERR-19-015","22 ms"],
["09:37:05","Datahub → NCC","INIT","PAYGOV","502","ERR-19-018","<span style='color:#a11a1a'>5,4 s chậm</span>"],
["09:30:03","Datahub → Đối tác","WEBHOOK","DVC-T68","200","—","140 ms"]],"Nhật ký tích hợp")}</div>""",
drawer("INIT · Đối tác → Datahub · 09:41:22", f"""<div class="alert e">Mã đơn hàng "HS-2026-001234" đã có giao dịch {TX1}.</div>
<div class="muted">Yêu cầu (đã che)</div><div class="code">POST /api/payment-partner/v1/payments
Idempotency-Key: 6c1f…9a2e
{{ "partnerOrderId": "HS-2026-001234",
  "serviceCode": "HT-KHAI-SINH", "amount": 50000 }}</div>
<div class="muted" style="margin-top:8px">Phản hồi</div><div class="code">409 application/problem+json
{{ "code": "ERR-19-015", "traceId": "4bf92f…a3" }}</div>
<div class="foot"><span class="btn">Sao chép</span><span class="btn pri">Mở vết trong PH-13</span></div>""", 620))

# 24 Webhook
P["24"] = ("Theo dõi webhook", "Thanh toán / Webhook", f"""
<div class="head"><h1>Theo dõi webhook</h1></div>
{facets(["Hết lượt thử 3","Chờ thử lại 5","Đã nhận","Tất cả"])}
<div class="card" style="margin-right:40%"><div class="toolbar"><span class="input">Đối tác ▾</span><span class="input">Loại sự kiện ▾</span><span class="input">24 giờ qua</span></div>
{table(["Tạo lúc","Đối tác","Sự kiện","Trạng thái","Lần thử","HTTP cuối"],[
["09:30:03","MC-T68","payment.succeeded",tag(ER,"Hết lượt thử"),"8","503"],
["08:55:41","MC-T68","payment.failed",tag(ER,"Hết lượt thử"),"8","timeout"],
["09:40:12","MC-T68","payment.succeeded",tag(WA,"Chờ thử lại · 02:14"),"3","503"],
["09:52:41","DVC-T68","payment.succeeded",tag(OK,"Đã nhận"),"1","200"]],"Lượt gửi webhook")}</div>""",
drawer("payment.succeeded · MC-T68", """<div class="code">{ "specversion": "1.0",
  "type": "vn.datahub.payment.succeeded",
  "source": "/t68/payment", "sequence": 48211,
  "data": { "transactionCode": "T68261126B3H8D1ZR6N",
            "amount": 1500000, "status": "SUCCEEDED" } }</div>
<h4 style="margin:12px 0 6px">Các lần thử</h4>""" + table(["Lúc","HTTP","Độ trễ"],[["09:30:04","503","120 ms"],["09:31:05","503","98 ms"],["09:35:06","timeout","10 s"],["…","…","…"]],"Các lần thử") + """
<div class="field" style="margin-top:10px"><label>Lý do gửi lại *</label><div class="input">Đối tác báo đã khắc phục đầu nhận</div></div><div class="foot"><span class="btn pri">Gửi lại</span></div>""", 500))

# 25 Báo cáo
months = [(1.2, "T6"), (1.4, "T7"), (1.35, "T8"), (1.6, "T9"), (1.75, "T10"), (1.9, "T11")]
mb = "".join(f'<div title="{m}"><i style="height:{v*70:.0f}px;background:#0b5cd5;border-radius:4px 4px 0 0"></i></div>' for v, m in months)
P["25"] = ("Báo cáo định kỳ", "Thanh toán / Báo cáo", f"""
<div class="head"><h1>Báo cáo định kỳ</h1><div class="sp"></div><span class="btn">⤓ Xuất ▾ (XLSX, CSV, PDF)</span></div>
<div class="grid2" style="grid-template-columns:240px minmax(0,1fr)"><div class="card tree"><div class="on">RPT-19-01 Tổng hợp thu theo dịch vụ, lĩnh vực</div><div>RPT-19-02 Tổng hợp thu theo đối tác, kênh, ngân hàng</div><div>RPT-19-03 Hoàn tiền</div><div>RPT-19-04 Đối soát</div><div>RPT-19-05 Chất lượng dịch vụ</div></div>
<div class="card"><div class="toolbar"><span class="input">Kỳ: Tháng ▾</span><span class="input">11/2026 ▾</span><span class="input">Đối tác: Tất cả ▾</span><span class="input">NCC: Tất cả ▾</span><span class="btn pri">Xem</span></div>
<div style="display:grid;grid-template-columns:280px 1fr;gap:16px"><div><div class="muted">Tổng thu 6 tháng (tỷ đồng)</div><div class="vbars" style="height:160px">{mb}</div><div class="legend"><span>T6</span><span>T7</span><span>T8</span><span>T9</span><span>T10</span><span>T11</span></div></div>
{table(["Nhóm","Dịch vụ","Số GD","Tổng thu","Hoàn","Thực thu"],[
["Tư pháp","Lệ phí đăng ký hộ tịch","<span class='num'>21.304</span>","<span class='num'>612.400.000</span>","<span class='num'>1.200.000</span>","<span class='num'>611.200.000</span>"],
["Xây dựng","Phí cấp phép xây dựng","<span class='num'>14.820</span>","<span class='num'>598.150.000</span>","<span class='num'>7.500.000</span>","<span class='num'>590.650.000</span>"],
["Đất đai","Phí thẩm định hồ sơ đất đai","<span class='num'>9.105</span>","<span class='num'>402.880.000</span>","<span class='num'>0</span>","<span class='num'>402.880.000</span>"],
["Thuế","Lệ phí trước bạ ô tô","<span class='num'>3.981</span>","<span class='num'>286.420.000</span>","<span class='num'>0</span>","<span class='num'>286.420.000</span>"],
["<b>Cộng</b>","","<b class='num'>49.210</b>","<b class='num'>1.899.850.000</b>","<b class='num'>8.700.000</b>","<b class='num'>1.891.150.000</b>"]],"Tổng hợp thu theo dịch vụ")}</div></div></div>""")

# 26 Cấu hình
P["26"] = ("Cấu hình thanh toán của tenant", "Thanh toán / Quản trị / Cấu hình", f"""
<div class="head"><h1>Cấu hình thanh toán · T68</h1>{tag(OK,"Phiên bản 4 đang hiệu lực")}{tag(IN,"Phiên bản 5 chờ hiệu lực 01/12/2026")}<div class="sp"></div><span class="btn">So sánh phiên bản</span><span class="btn pri">Tạo phiên bản mới</span></div>
<div class="grid2" style="grid-template-columns:240px minmax(0,1fr)"><div class="card tree"><div class="on">Giao dịch</div><div>Hoàn tiền</div><div>Đối soát</div><div>Webhook</div><div>Dữ liệu cá nhân</div><div>Di trú</div></div>
<div class="card">{table(["Tham số","Giá trị v4","Giá trị v5 (01/12)","Mặc định nền tảng","Mô tả"],[
["<span class='mono'>19.txn.expire-minutes</span>","15","15","15","Thời hạn thanh toán mặc định (phút)"],
["<span class='mono'>19.txn.max-amount</span>","2.000.000.000 ₫","2.000.000.000 ₫","2.000.000.000 ₫","Trần số tiền mỗi giao dịch"],
["<span class='mono'>19.refund.default-mode</span>","Thủ công","Thủ công","Thủ công","Cách hoàn mặc định"],
["<span class='mono'>19.refund.window-days</span>","180","<b style='color:#7a5200'>365</b>","180","Hạn hoàn tiền kể từ ngày thanh toán"],
["<span class='mono'>19.refund.second-approval-amount</span>","5.000.000 ₫","5.000.000 ₫","10.000.000 ₫","Ngưỡng cần duyệt cấp 2"],
["<span class='mono'>19.recon.discrepancy-due-workdays</span>","3","3","3","Hạn xử lý chênh lệch (ngày làm việc)"],
["<span class='mono'>19.recon.escalate-workdays</span>","5","5","5","Hạn chuyển cấp (ngày làm việc)"]],"Tham số cấu hình")}
<div class="muted" style="margin-top:8px">Phiên bản 5 do Phạm D tạo 25/11/2026, lý do "Theo Quyết định số …/QĐ-UBND về thời hạn hoàn lệ phí".</div></div></div>""")

# 27 Di trú
P["27"] = ("Di trú và chạy song song", "Thanh toán / Quản trị / Di trú, chạy song song", f"""
<div class="head"><h1>Di trú và chạy song song</h1></div>
{tabs(["Lô nhập","Đối chiếu","Chế độ định tuyến"],2)}
<div class="card">{table(["Đối tác","Chế độ hiện tại","Đối chiếu 7 ngày","Lệch","Đủ điều kiện chuyển","Đề nghị",""],[
["DVC-T68 · Cổng dịch vụ công tỉnh",tag(IN,"⧉ Chạy bóng"),"20.318 / 20.318 khớp","0",tag(OK,"✓ Đạt 7/7 ngày"),"—","<span class='btn pri'>Đề nghị chuyển sang Datahub</span>"],
["MC-T68 · Một cửa điện tử tỉnh",tag(OK,"Datahub"),"—","—","—","Đã chuyển 15/11/2026","<span class='btn'>Đề nghị quay lại</span>"],
["DD-T68 · Hệ thống thông tin đất đai",tag(MU,"Hệ cũ"),"—","—",tag(MU,"Chưa chạy bóng"),"—","<span class='btn'>Đề nghị chạy bóng</span>"],
["YT-T68 · Hệ thống y tế tỉnh",tag(MU,"Hệ cũ"),"—","—",tag(MU,"Đối tác chờ duyệt"),"—","<span class='btn' style='opacity:.45'>Đề nghị chạy bóng</span>"]],"Chế độ định tuyến từng đối tác")}
<div class="alert i" style="margin-top:10px">Mỗi lần đổi chế độ cần một đề nghị bốn mắt (người duyệt có PERM-19-migration-switch, khác người lập). Chuyển sang Datahub chỉ khi đối chiếu đủ số ngày liên tục không lệch.</div></div>""")

def phone():
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=360">
<title>UI-19-28 · Trang kết quả thanh toán cho người nộp</title><link rel="stylesheet" href="hifi.css"></head><body style="background:#eef2f8">
<div class="phone"><div class="ph-head"><div class="logo-t">T68</div><div><b>Cổng thanh toán</b><div class="muted" style="font-size:13px">UBND tỉnh thí điểm T68</div></div></div>
<div class="ico">✓</div><h2>Thanh toán thành công</h2>
<dl><dt>Số tiền</dt><dd>50.000 ₫</dd><dt>Nội dung</dt><dd>Lệ phí đăng ký hộ tịch</dd><dt>Mã giao dịch</dt><dd class="mono" style="font-size:13px;word-break:break-all">{TX1} ⧉</dd><dt>Thời gian</dt><dd>26/11/2026 09:52</dd></dl>
<div class="cta">Quay về Cổng DVC tỉnh (5)</div><p style="text-align:center;font-size:14px;color:#545b66;margin:0 20px">Lưu mã giao dịch để tra cứu khi cần hỗ trợ: 1900 xxxx</p></div></body></html>"""


for code, (title, crumb, body, *extra) in P.items():
    (OUT / f"ui-19-{code}.html").write_text(shell(code, title, crumb, body, extra[0] if extra else ""), encoding="utf-8")
(OUT / "ui-19-28.html").write_text(phone(), encoding="utf-8")
print("Đã sinh", len(P) + 1, "trang")
