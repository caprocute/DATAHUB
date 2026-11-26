#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-12-01…19 (D03-06-PH12, mục "Ảnh hi-fi" của từng màn).

Chạy: python3 gen_hifi.py; chụp ảnh: node shot.js
Dữ liệu là giả định của tỉnh thí điểm T68 (tên người dùng, thư điện tử, mã phiếu đều là dữ liệu minh họa).
Phong cách: Liquid Glass của D03-05; kính chỉ ở lớp điều hướng và lớp nổi, nội dung dày dùng nền đặc.
Dùng lại hifi.css (sao từ ph19/hifi) kèm vài lớp bổ sung cho PH-12.
"""
import pathlib
import re

OUT = pathlib.Path(__file__).parent

NAV = [("|Người dùng và quyền", None), ("Người dùng", "01"), ("Vai trò và quyền", "05"), ("Nhóm và đơn vị", "07"),
       ("Quyền có thời hạn", "08"), ("Rà soát quyền", "09"), ("|Danh tính máy", None), ("Danh tính HTTT", "10"),
       ("Liên kết định danh", "11"), ("|Chính sách", None), ("Chính sách truy cập", "12"), ("Nhật ký quyết định", "14"),
       ("Cảnh báo, báo cáo", "15"), ("|Quản trị", None), ("Duyệt yêu cầu", "17"), ("Cài đặt Định danh", "16"),
       ("Realm của tenant", "19")]
BADGE = {"01": "<span class='tag t-err'>3</span>", "08": "<span class='tag t-info'>2</span>",
         "15": "<span class='tag t-warn'>4</span>", "17": "<span class='tag t-info'>5</span>"}
ACTIVE = {"01": "01", "02": "01", "03": "01", "04": "01", "05": "05", "06": "01", "07": "07", "08": "08", "09": "09",
          "10": "10", "11": "11", "12": "12", "13": "12", "14": "14", "15": "15", "16": "16", "17": "17", "19": "19"}


def shell(code, title, crumb, body, extra=""):
    nav = ""
    for n, c in NAV:
        if n.startswith("|"):
            nav += f'<div class="grp">{n[1:]}</div>'
            continue
        nav += f'<a class="{"on" if ACTIVE[code] == c else ""}" href="#">{n} {BADGE.get(c, "")}</a>'
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-12-{code} · {title}</title><link rel="stylesheet" href="hifi.css"></head><body>
<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Quản trị</div><div class="search">Tìm người dùng, vai trò, chính sách…  ⌘K</div><div class="sp"></div>
<span class="tray">⟳ 1 tác vụ nền</span><span class="tray">T68 · Tỉnh thí điểm</span><div class="avatar">LH</div></header>
<nav class="side" aria-label="Điều hướng chính">{nav}</nav>
<main><div class="crumb">{crumb}</div>{body}</main></div>{extra}<div class="hint">Bản hi-fi minh họa · D03-06-PH12 · UI-12-{code} · dữ liệu giả định</div></body></html>"""


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


def kpis(items):
    cells = "".join(f'<div class="kpi {c}"><span>{a}</span><b>{b}</b><small>{d}</small></div>' for a, b, d, c in items)
    return f'<div class="kpis" style="--n:{len(items)}">{cells}</div>'


def foot(text="Hiển thị 1–20"):
    return f'<div class="foot" style="justify-content:space-between"><span class="muted">{text}</span><span class="muted">‹ 1 2 3 › · 20 / trang</span></div>'


def drawer(title, inner, width=480):
    return f'<div class="drawer" role="dialog" aria-label="{title}" style="width:{width}px"><h3 style="margin:0 0 10px">{title}</h3>{inner}</div>'


def mono(s):
    return f"<span class='mono'>{s}</span>"


def head(title, right="", sub=""):
    return f'<div class="head"><h1>{title}</h1>{sub}<div class="sp"></div>{right}</div>'


def chrome(title, tags, line, btns):
    return f'<div class="chrome"><h1>{title} {tags}</h1><div style="display:flex;align-items:center;gap:8px"><span class="muted">{line}</span><span style="flex:1"></span>{btns}</div></div>'


def field(label, value, hint="", m=False):
    h = f'<div class="muted">{hint}</div>' if hint else ""
    return f'<div class="field"><label>{label}</label><div class="input{" mono" if m else ""}">{value}</div>{h}</div>'


OK, WA, ER, IN, MU = "ok", "warn", "err", "info", "mute"
BTN = lambda t, c="": f'<span class="btn {c}">{t}</span>'
P = {}

# 01 Danh sách người dùng
users = [
    ("Phạm Văn Khoa", "khoa.pv", "Sở Tài chính", "Cán bộ đối soát", tag(MU, "Chưa đăng ký"), tag(ER, "🔒 Khóa tạm"), "hôm nay 08:12"),
    ("Đỗ Thị Hạnh", "hanh.dt", "Sở KH&CN", "Quản trị tỉnh", tag(OK, "WebAuthn"), tag(OK, "Đang hoạt động"), "hôm nay 09:02"),
    ("Lê Quang Huy", "huy.lq", "Sở TT&TT", "Kỹ sư tích hợp", tag(OK, "TOTP"), tag(OK, "Đang hoạt động"), "hôm nay 08:47"),
    ("Nguyễn Thị Mai", "mai.nt", "Sở Tư pháp", "Cán bộ ATTT", tag(OK, "WebAuthn"), tag(OK, "Đang hoạt động"), "hôm qua 16:30"),
    ("Trần Minh Tuấn", "tuan.tm", "UBND huyện A", "Người xem", tag(MU, "Không bắt buộc"), tag(WA, "⏳ Chờ kích hoạt"), "—"),
    ("Vũ Hoài Nam", "nam.vh", "Sở Y tế", "Chủ sở hữu dữ liệu", tag(OK, "TOTP"), tag(WA, "⚠ Sắp vô hiệu · 41 ngày"), "12 ngày trước"),
    ("Bùi Thanh Sơn", "son.bt", "Sở GD&ĐT", "Vận hành tỉnh", tag(OK, "TOTP"), tag(MU, "Đã vô hiệu"), "52 ngày trước"),
]
rows = [[f"<b>{n}</b><br><span class='muted'>{mono(u)}</span>", d, r, m, s, w, "⋯"] for n, u, d, r, m, s, w in users]
P["01"] = ("Danh sách người dùng", "Quản trị / Người dùng", f"""
{head("Người dùng", BTN("Nhập từ tệp") + BTN("Xuất CSV") + BTN("+ Tạo người dùng", "pri"), '<span class="muted">1.846 người dùng · tenant T68</span>')}
{kpis([("Tất cả", "1.846", "", ""), ("Đang hoạt động", "1.790", "", ""), ("Bị khóa", "3", "xếp đầu bảng", "on"), ("Chờ kích hoạt", "21", "", ""), ("Nhóm bắt buộc chưa có MFA", "7", "→ lọc", ""), ("Sắp bị vô hiệu (45 ngày)", "14", "→ lọc", "")])}
<div class="card"><div class="toolbar"><span class="input" style="min-width:240px">Tìm tên, tên đăng nhập, thư…</span><span class="input">Trạng thái ▾</span><span class="input">Đơn vị ▾</span><span class="input">Vai trò ▾</span><span class="input">Yếu tố thứ hai ▾</span><span class="btn">Xóa bộ lọc</span></div>
{table(["Họ tên · Tên đăng nhập", "Đơn vị", "Vai trò", "Yếu tố thứ hai", "Trạng thái", "Đăng nhập gần nhất", ""], rows, "Danh sách người dùng")}
{foot("1–7 / 1.846")}</div>""")

# 02 Chi tiết người dùng
P["02"] = ("Chi tiết người dùng", "Quản trị / Người dùng / Phạm Văn Khoa", f"""
{chrome("Phạm Văn Khoa", tag(ER, "🔒 Khóa tạm") + tag(MU, "Chưa đăng ký MFA"), mono("khoa.pv") + " · khoa.pv@t68.gov.vn · Sở Tài chính", BTN("Mở khóa") + BTN("Buộc đăng xuất") + BTN("Thu hồi truy cập", "danger") + BTN("⋯"))}
<div class="alert e" role="alert">🔒 Tài khoản bị khóa tạm do đăng nhập sai 5 lần lúc 08:12. Tự mở sau 12 phút hoặc mở khóa ngay. <span class="sp"></span><span class="muted">ERR-12-112</span></div>
{tabs(["Tổng quan", "Vai trò ●2", "Quyền hiệu lực", "Yếu tố xác thực", "Phiên ●1", "Lịch sử"], 1)}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 300px"><div class="card"><div class="toolbar"><b>Vai trò đang gán</b><div style="flex:1"></div>{BTN("+ Gán vai trò", "pri")}</div>
{table(["Vai trò", "Phạm vi", "Hiệu lực", "Gán bởi", "Lý do", ""], [
["PAYMENT_ACCOUNTANT · Kế toán đối soát", "Sở Tài chính", "từ 01/09/2026", "Đỗ T. Hạnh (TA)", "Giao nhiệm vụ đối soát", "Gỡ"],
["VIEWER · Người xem", "Toàn tỉnh", "từ 01/09/2026", "Hệ thống", "Vai trò mặc định", "Gỡ"]], "Vai trò đang gán")}
<div class="muted" style="margin-top:10px">Không tự gán, gỡ vai trò của chính mình (BR-12-033). Cặp xung đột bị chặn khi gán (BR-12-030).</div></div>
<div class="card raised"><h4 style="margin:0 0 10px">Thông tin chính</h4><div class="vtl"><div>Tạo 01/09/2026 bởi Đỗ T. Hạnh</div><div>Kích hoạt 02/09/2026</div><div>Đăng nhập gần nhất 08:12 hôm nay (thất bại)</div><div>Nguồn đăng nhập: Keycloak nội bộ</div></div></div></div>""")

# 03 Tạo, sửa người dùng (ngăn kéo trên nền danh sách)
P["03"] = ("Tạo, sửa người dùng", "Quản trị / Người dùng / Tạo mới", P["01"][2], drawer("Tạo người dùng", f"""
{field("Họ và tên *", "Trần Thị Lan")}{field("Tên đăng nhập *", "lan.tt", "Chữ thường, số, dấu chấm; 3–40 ký tự; không đổi sau khi tạo.", True)}
{field("Thư điện tử công vụ *", "lan.tt@t68.gov.vn", "Phải thuộc miền t68.gov.vn của tỉnh (ERR-12-005).")}
{field("Đơn vị *", "Sở Nội vụ ▾", "Lấy từ danh mục đơn vị PH-07.")}{field("Vai trò ban đầu", "VIEWER · Người xem ▾")}
<div class="warn">Hệ thống gửi liên kết kích hoạt, hiệu lực 72 giờ. Người dùng tự đặt mật khẩu (≥ 14 ký tự) và đăng ký yếu tố thứ hai.</div>
<div class="foot"><span class="btn">Hủy</span><span class="btn pri">Tạo và gửi liên kết</span></div>""", 520))

# 04 Nhập người dùng hàng loạt
P["04"] = ("Nhập người dùng từ tệp", "Quản trị / Người dùng / Nhập từ tệp", f"""
{head("Nhập người dùng từ tệp")}
<div class="steps"><div class="done">✓ 1. Tải tệp</div><div class="on">2. Ánh xạ vai trò hệ cũ</div><div>3. Xem trước</div><div>4. Xác nhận</div></div>
<div class="alert w" role="alert">⚠ 2 vai trò hệ cũ chưa có ánh xạ: <b>OPERATOR_OLD</b>, <b>BUS_VIEWER</b>. Chọn vai trò chuẩn để tiếp tục (ERR-12-036).</div>
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 340px"><div class="card"><div class="toolbar"><b>Xem trước theo dòng</b><span class="muted">nhapnd_2026-11.xlsx · 412 dòng · 398 hợp lệ · 14 lỗi</span></div>
{table(["#", "Họ tên", "Thư điện tử", "Đơn vị", "Vai trò hệ cũ → chuẩn", "Kết quả"], [
["2", "Hoàng Văn An", "an.hv@t68.gov.vn", "Sở Công thương", "BUS_ADMIN → INTEGRATION_ENGINEER", tag(OK, "Hợp lệ")],
["3", "Mai Thị Bích", "bich.mt@t68.gov.vn", "Sở Xây dựng", "TOOL_USER → VIEWER", tag(OK, "Hợp lệ")],
["4", "Lý Quốc Đạt", "<span style='outline:2px solid #d33'>dat.lq@gmail.com</span>", "Sở Công thương", "OPERATOR_OLD → ?", tag(ER, "Ngoài miền công vụ")],
["5", "Phan Thu Hà", "ha.pt@t68.gov.vn", "<span style='outline:2px solid #d33'>Sở ABC</span>", "BUS_VIEWER → ?", tag(ER, "Đơn vị không tồn tại")]], "Xem trước nhập")}{foot("1–4 / 412")}</div>
<div class="card raised"><h4 style="margin:0 0 8px">Ánh xạ vai trò hệ cũ</h4>{table(["Hệ cũ", "Vai trò chuẩn"], [["BUS_ADMIN", "INTEGRATION_ENGINEER"], ["TOOL_USER", "VIEWER"], ["OPERATOR_OLD", "<span class='input'>Chọn… ▾</span>"], ["BUS_VIEWER", "<span class='input'>Chọn… ▾</span>"]], "Ánh xạ")}
<div class="foot"><span class="btn">Tải tệp lỗi (14)</span><span class="btn pri" style="opacity:.5">Xác nhận nhập 398 dòng</span></div></div></div>""")

# 05 Danh mục vai trò và quyền
P["05"] = ("Danh mục vai trò và quyền", "Quản trị / Vai trò và quyền", f"""
{head("Vai trò và quyền", BTN("Xuất ma trận") + BTN("+ Vai trò tùy biến (Đợt 2)"), '<span class="muted">22 vai trò chuẩn · 120 quyền · nguồn D02-08</span>')}
<div class="grid2" style="grid-template-columns:260px minmax(0,1fr)"><div class="card tree"><div class="toolbar"><span class="input" style="min-width:0;width:100%">Tìm vai trò…</span></div>
<div class="muted" style="margin:4px 6px">Nền tảng</div><div>PLATFORM_ADMIN</div><div>PLATFORM_OPERATOR</div><div class="muted" style="margin:8px 6px 4px">Tỉnh</div><div class="on">TENANT_ADMIN · Quản trị tỉnh</div><div>SECURITY_OFFICER</div><div>AUDITOR</div><div>INTEGRATION_ENGINEER</div><div>INTEGRATION_APPROVER</div><div>DATA_STEWARD</div><div>PAYMENT_ACCOUNTANT</div><div class="muted" style="margin:8px 6px 4px">Tùy biến (0)</div></div>
<div class="card"><div class="toolbar"><b>TENANT_ADMIN</b> {tag(IN, "Vai trò chuẩn, chỉ đọc")}<div style="flex:1"></div><span class="muted">Xung đột với: AUDITOR</span></div>
{table(["Phân hệ", "Quyền", "Phạm vi", "Ý nghĩa"], [
["PH-12", mono("PERM-12-user-admin"), "Tổ chức mình", "Tạo, sửa, nhập người dùng; gán, gỡ vai trò"],
["PH-12", mono("PERM-12-user-lock"), "Tổ chức mình", "Khóa, mở khóa, vô hiệu, buộc đăng xuất"],
["PH-12", mono("PERM-12-client"), "Tổ chức mình", "Sửa, xoay bí mật, chứng thư client"],
["PH-12", mono("PERM-12-admin"), "Tenant", "Tham số phân hệ, liên kết định danh"],
["PH-01", mono("PERM-01-approve"), "Tenant", "Duyệt hồ sơ kết nạp HTTT"],
["PH-20", mono("PERM-20-tenant-admin"), "Tenant", "Quản trị tenant của tỉnh"]], "Quyền của vai trò")}
<div class="muted" style="margin-top:8px">Tra ngược: nhập mã quyền để xem những vai trò mang quyền đó.</div></div></div>""")

# 06 Gán vai trò và ngoại lệ (ngăn kéo trên chi tiết người dùng)
BG06 = P["02"][2].replace("Phạm Văn Khoa", "Lê Quang Huy").replace("khoa.pv", "huy.lq").replace("Sở Tài chính", "Sở TT&TT").replace(tag(ER, "🔒 Khóa tạm") + tag(MU, "Chưa đăng ký MFA"), tag(OK, "Đang hoạt động") + tag(OK, "TOTP"))
BG06 = re.sub(r'<div class="alert e".*?</div>\n', '', BG06, count=1, flags=re.S).replace("PAYMENT_ACCOUNTANT · Kế toán đối soát", "INTEGRATION_ENGINEER · Kỹ sư tích hợp")
BG06 = BG06.replace(BTN("Mở khóa"), "")
P["06"] = ("Gán vai trò và ngoại lệ tách nhiệm vụ", "Quản trị / Người dùng / Lê Quang Huy / Gán vai trò", BG06, drawer("Gán vai trò cho Lê Quang Huy", f"""
{field("Vai trò *", "INTEGRATION_APPROVER · Người duyệt tích hợp ▾")}{field("Phạm vi *", "Sở TT&TT ▾")}{field("Hiệu lực", "01/12/2026 → không thời hạn")}{field("Lý do *", "Bổ sung người duyệt luồng tích hợp cho Sở TT&TT")}
<div class="alert e" role="alert" style="align-items:flex-start">⛔<div><b>Xung đột tách nhiệm vụ.</b> Anh/chị không được giữ cùng lúc INTEGRATION_ENGINEER và INTEGRATION_APPROVER: người xây luồng không tự duyệt luồng của mình. Có thể đề nghị ngoại lệ có thời hạn. <span class="muted">ERR-12-009</span></div></div>
<div class="card raised"><b>Đề nghị ngoại lệ</b><div class="field" style="margin-top:8px"><label>Thời hạn (tối đa 90 ngày)</label><div class="input">30 ngày</div></div><div class="field"><label>Lý do ngoại lệ * (≥ 10 ký tự)</label><div class="input">Sở chỉ có một cán bộ tích hợp, chờ tuyển thêm</div></div><div class="muted">Gửi cán bộ ATTT duyệt; có hiệu lực sau khi duyệt.</div></div>
<div class="foot"><span class="btn">Hủy</span><span class="btn pri">Gửi đề nghị ngoại lệ</span></div>""", 540))

# 07 Nhóm và đơn vị
P["07"] = ("Nhóm và đơn vị", "Quản trị / Vai trò và quyền / Nhóm và đơn vị", f"""
{head("Nhóm và đơn vị", BTN("Báo cáo đồng bộ đơn vị") + BTN("+ Tạo nhóm", "pri"))}
<div class="alert w" role="alert">⚠ Lần đồng bộ đơn vị lúc 02:00 có <b>6 người dùng</b> cần rà soát (đơn vị đã đổi tên hoặc hết hiệu lực). <span class="sp"></span><span class="btn">Xem danh sách</span></div>
<div class="grid2" style="grid-template-columns:280px minmax(0,1fr)"><div class="card tree"><div>▾ UBND tỉnh T68</div><div style="padding-left:18px">▾ Sở KH&CN</div><div class="on" style="padding-left:36px">Phòng Chuyển đổi số</div><div style="padding-left:36px">Phòng Quản lý công nghệ</div><div style="padding-left:18px">▸ Sở TT&TT</div><div style="padding-left:18px">▸ Sở Tài chính</div><div style="padding-left:18px">▸ UBND huyện A</div></div>
<div class="card"><div class="toolbar"><b>Phòng Chuyển đổi số</b> {tag(IN, "Đơn vị tổ chức · đồng bộ từ PH-07")}<div style="flex:1"></div>{BTN("Chuyển thành viên")}{BTN("+ Thêm thành viên", "pri")}</div>
{table(["", "Thành viên", "Tên đăng nhập", "Vai trò", "Trạng thái"], [
["☐", "Đỗ Thị Hạnh", mono("hanh.dt"), "TENANT_ADMIN", tag(OK, "Đang hoạt động")], ["☐", "Lê Quang Huy", mono("huy.lq"), "INTEGRATION_ENGINEER", tag(OK, "Đang hoạt động")],
["☐", "Ngô Văn Bình", mono("binh.nv"), "DATA_STEWARD", tag(OK, "Đang hoạt động")], ["☐", "Đặng Thu Trang", mono("trang.dt"), "VIEWER", tag(WA, "⏳ Chờ kích hoạt")]], "Thành viên nhóm")}{foot("1–4 / 11")}</div></div>""")

# 08 Quyền có thời hạn
P["08"] = ("Quyền có thời hạn", "Quản trị / Quyền có thời hạn", f"""
{head("Quyền có thời hạn", BTN("+ Đề nghị quyền", "pri"), '<span class="muted">Tối đa 4 giờ · cần người duyệt thứ hai · tỉnh bị truy cập được báo</span>')}
{facets(["Tất cả 9", "Chờ duyệt 2", "Đang hiệu lực 2", "Hết hạn 4", "Bị từ chối 1"], 2)}
<div class="card"><div class="toolbar"><span class="input" style="min-width:240px">Tìm người đề nghị, tenant, mã phiếu…</span><span class="input">Loại ▾</span><span class="input">Tenant đích ▾</span></div>
{table(["Người đề nghị", "Quyền, tenant đích", "Mã phiếu", "Lý do", "Trạng thái", "Còn lại", ""], [
["Hà Văn Phong (PO)", "Vào tenant T68 · đọc nhật ký", mono("SUP-20261126-014"), "Điều tra tăng lỗi 5xx của cổng", tag(OK, "Đang hiệu lực"), "<span class='cd'>02:41:18</span>", "Thu hồi sớm"],
["Cao Minh Đức (PA)", "ROLE-PLATFORM_ADMIN · tenant PLATFORM", mono("SUP-20261126-009"), "Xoay khóa ký realm", tag(OK, "Đang hiệu lực"), "<span class='cd' style='color:#a8320f'>00:12:05</span>", "Thu hồi sớm"],
["Hà Văn Phong (PO)", "Vào tenant T71 · đọc nhật ký", mono("SUP-20261126-018"), "Kiểm tra DLQ theo đề nghị của tỉnh", tag(IN, "⏳ Chờ duyệt"), "—", "Hủy đề nghị"],
["Trịnh Quốc Việt (PA)", "Vào tenant T68 · đọc cấu hình", mono("SUP-20261125-003"), "Kiểm tra cấu hình theo phiếu", tag(MU, "Đã hết hạn"), "—", ""]], "Quyền có thời hạn")}{foot("1–4 / 9")}</div>""")

# 09 Rà soát quyền
P["09"] = ("Rà soát quyền", "Quản trị / Rà soát quyền / Quý IV năm 2026", f"""
{head("Rà soát quyền · Quý IV năm 2026", BTN("Đóng chiến dịch") + BTN("Giữ các mục đã chọn", "pri") + BTN("Gỡ các mục đã chọn", "danger"), tag(IN, "Đang mở · hạn 15/12/2026"))}
{kpis([("Tổng mục", "642", "", ""), ("Đã quyết định", "418", "65%", ""), ("Gỡ", "37", "", ""), ("Quá hạn chưa xử lý", "9", "gửi nhắc", "")])}
<div class="card"><div style="margin-bottom:10px"><div class="prog"><i style="width:65%"></i></div></div><div class="toolbar"><span class="input" style="min-width:220px">Tìm người dùng, vai trò…</span><span class="input">Người rà soát ▾</span><span class="input">Quyết định: Chưa ▾</span></div>
{table(["", "Người dùng", "Vai trò, quyền", "Lần dùng gần nhất", "Người rà soát", "Quyết định"], [
["☑", "Vũ Hoài Nam<br><span class='muted'>Sở Y tế</span>", "DATA_STEWARD · PERM-07-publish", "12 ngày trước", "Lê Văn Chính", tag(MU, "Chưa quyết định")],
["☑", "Bùi Thanh Sơn<br><span class='muted'>Sở GD&ĐT</span>", "TENANT_OPERATOR · PERM-18-dlq", "<span style='color:#a8320f'>Chưa dùng 90 ngày</span>", "Trần Văn Dũng", tag(MU, "Chưa quyết định")],
["☐", "Trần Minh Tuấn<br><span class='muted'>UBND huyện A</span>", "VIEWER · PERM-13-read", "hôm qua", "Phạm Thị Em", tag(OK, "Giữ")],
["☐", "Lý Quốc Đạt<br><span class='muted'>Sở Công thương</span>", "INTEGRATION_ENGINEER", "30 ngày trước", "Lê Văn Chính", tag(ER, "Gỡ")]], "Mục rà soát")}{foot("1–4 / 642")}</div>""")

# 10 Danh tính HTTT
P["10"] = ("Danh tính HTTT và tài khoản dịch vụ", "Quản trị / Danh tính HTTT / dvc-t68", f"""
{chrome(mono("dvc-t68") + " · Cổng dịch vụ công tỉnh", tag(OK, "Đang hoạt động") + tag(IN, "Hợp đồng mức Nhạy cảm"), "HTTT thuộc Sở TT&TT · xác thực mTLS · token 5 phút", BTN("Tạm ngừng") + BTN("Thu hồi", "danger"))}
{tabs(["Tổng quan", "Scope", "Chứng thư", "Xoay bí mật", "Tài khoản dịch vụ", "Lịch sử"], 2)}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 340px"><div class="card"><div class="toolbar"><b>Chứng thư mTLS và khóa công khai</b><div style="flex:1"></div>{BTN("Tải chứng thư mới", "pri")}{BTN("Đăng ký JWKS")}</div>
{table(["Loại", "Vân tay SHA-256", "Cấp bởi", "Hiệu lực đến", "Trạng thái"], [
["Chứng thư mTLS", mono("3F:9A:7C:…:C2"), "CA nội bộ T68", "15/01/2027", tag(WA, "Hết hạn sau 50 ngày")],
["Chứng thư mTLS (kế tiếp)", mono("71:0B:E4:…:5E"), "CA nội bộ T68", "15/01/2028", tag(IN, "Chờ chuyển tiếp")]], "Chứng thư")}
<div class="alert w" style="margin-top:12px;margin-bottom:0">⚠ Hợp đồng mức Nhạy cảm yêu cầu chứng thư mTLS hoặc khóa công khai, không dùng bí mật chia sẻ (ERR-12-022).</div></div>
<div class="card raised"><h4 style="margin:0 0 8px">Scope hiện có (chỉ đọc)</h4><div class="muted" style="margin-bottom:6px">Sinh từ dữ liệu đã duyệt ở PH-02, PH-09, PH-10, PH-19</div>
<div><span class="pill">api:dvc.read</span><span class="pill">event:hotich.publish</span><span class="pill">pay:order.create</span></div><div class="muted" style="margin-top:10px">Cập nhật lần cuối 20/11/2026 theo đăng ký sử dụng ĐK-0412.</div></div></div>""")

# 11 Liên kết định danh
P["11"] = ("Liên kết định danh", "Quản trị / Liên kết định danh", f"""
{head("Liên kết định danh", "", '<span class="muted">LDAP/AD · SAML 2 · VNeID</span>')}
<div class="grid-2e"><div class="card"><div class="toolbar"><b>LDAP / Active Directory</b>{tag(OK, "Đang hoạt động")}<div style="flex:1"></div>{BTN("Kiểm tra")}{BTN("Đồng bộ ngay")}</div>
{field("Địa chỉ máy chủ", "ldaps://ad.t68.gov.vn:636", "", True)}{field("Tài khoản đọc", "svc-datahub (bí mật đã khai · phiên bản 2)", "", False)}{field("Gốc tìm kiếm", "OU=CanBo,DC=t68,DC=gov,DC=vn", "", True)}
<div class="muted">Đồng bộ gần nhất 02:00 · 1.790 tài khoản · 0 lỗi · chính sách mật khẩu AD yếu hơn SEC-22, bật MFA bắt buộc cho nguồn này.</div></div>
<div class="card"><div class="toolbar"><b>Ứng dụng SAML 2</b><div style="flex:1"></div>{BTN("+ Đăng ký ứng dụng", "pri")}</div>
{table(["Ứng dụng", "Entity ID", "Trạng thái"], [["QLVB cũ", mono("urn:t68:qlvb"), tag(OK, "Hoạt động")], ["Cổng thông tin cũ", mono("urn:t68:portal"), tag(IN, "⏳ Chờ SO duyệt")]], "Ứng dụng SAML")}
<div class="toolbar" style="margin:14px -16px 8px"><b>VNeID</b>{tag(MU, "Chưa bật · Đợt 2")}</div><div class="muted">Cần ý kiến về mức xác thực (Q12-02) trước khi bật.</div></div></div>""")

# 12 Chính sách truy cập (trình soạn)
rego = [
    ("<span class='cm'># Chính sách tỉnh T68 · ngăn tải dữ liệu mức Nhạy cảm ngoài giờ</span>", ""),
    ("<span class='kw'>package</span> datahub.authz.tenant.t68", ""),
    ("<span class='kw'>import</span> rego.v1", ""),
    ("", ""),
    ("<span class='kw'>deny</span> contains res <span class='kw'>if</span> {", ""),
    ("    input.resource.classification == <span class='st'>\"SENSITIVE\"</span>", ""),
    ("    input.action == <span class='st'>\"export\"</span>", ""),
    ("    <span class='kw'>not</span> in_business_hours(input.context.time)", ""),
    ("    res := {<span class='st'>\"reason\"</span>: <span class='st'>\"OUT_OF_HOURS\"</span>}", ""),
    ("}", ""),
    ("<span class='kw'>allow</span> <span class='kw'>if</span> { input.user.role == <span class='st'>\"ADMIN\"</span> }", "bad"),
]
code = "".join(f'<span class="{c}"><span class="ln">{i+1:>2}</span>{t}</span>\n' for i, (t, c) in enumerate(rego))
P["12"] = ("Chính sách truy cập", "Quản trị / Chính sách truy cập / tinh-t68-ngoai-gio / Thiết kế", f"""
{chrome("tinh-t68-ngoai-gio · phiên bản 4", tag(MU, "Nháp") + tag(WA, "Chưa chạy khô"), "Phạm vi: tenant T68 · soạn bởi Nguyễn T. Mai · lưu 09:38", BTN("Kiểm thử") + BTN("Chạy khô") + BTN("Gửi duyệt") )}
<div class="ed"><div class="card tree"><div class="muted" style="margin:0 6px 4px">Tệp</div><div class="on">tinh-t68-ngoai-gio.rego</div><div>helpers.rego</div><div class="muted" style="margin:10px 6px 4px">Ca kiểm thử (14)</div><div>✓ cho phép giờ hành chính</div><div>✓ từ chối xuất ngoài giờ</div><div style="color:#a11a1a">✗ allow nới quyền ADMIN</div></div>
<div class="card" style="padding:0"><div class="code" style="border-radius:10px;min-height:330px">{code}</div></div>
<div class="card"><h4 style="margin:0 0 8px">Kết quả kiểm tra</h4><div class="alert e" style="margin-bottom:8px">Dòng 11 · luật <b>allow</b> không được có trong chính sách của tỉnh <span class="muted">ERR-12-028</span></div>
<div class="chk"><div class="y">Cú pháp Rego</div><div class="n">Chỉ thêm luật chặt hơn</div><div class="y">13/14 ca kiểm thử đạt</div><div class="n">Chưa có ca âm cho luật mới</div></div>
<div class="muted" style="margin-top:10px">Gói dữ liệu vai trò–quyền: bản sinh 26/11 06:00 · ký bởi khóa OpenBao.</div></div></div>""")

# 13 Chạy khô và duyệt
P["13"] = ("Chạy khô và duyệt chính sách", "Quản trị / Chính sách truy cập / tinh-t68-ngoai-gio / Duyệt", f"""
{chrome("Duyệt phiên bản 4 · tinh-t68-ngoai-gio", tag(IN, "Chờ duyệt"), "Gửi bởi Nguyễn T. Mai · chạy khô 24 giờ lưu lượng thật · 1.204.380 quyết định", "")}
{kpis([("Quyết định đã so sánh", "1.204.380", "24 giờ gần nhất", ""), ("Giữ nguyên", "1.157.020", "96,1%", ""), ("Đổi kết quả", "47.360", "<span style='color:#a11a1a'>3,9%</span>", ""), ("Nới quyền", "0", "cho phép mới", "")])}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 360px"><div class="card"><div class="toolbar"><b>Tác động theo bên gọi</b><span class="muted">So với phiên bản 3 đang chạy</span></div>
{table(["Bên gọi", "Allow → Deny", "Deny → Allow", "Tỷ lệ đổi"], [["dvc-t68", "31.204", "0", "<b>6,2%</b>"], ["bao-cao-so", "9.870", "0", "2,8%"], ["dh-console (người dùng)", "4.120", "0", "0,4%"], ["Khác (11 bên)", "2.166", "0", "0,1%"]], "Tác động")}
<div class="muted" style="margin-top:10px">Mẫu 20 quyết định đổi kết quả được mở ở tab “Chi tiết mẫu”. Tài nguyên, người dùng được che theo mức phân loại.</div></div>
<div class="card raised"><h4 style="margin:0 0 6px">Điều kiện phát hành</h4><div class="chk"><div class="y">Cú pháp và biên dịch</div><div class="y">Ca kiểm thử: 14/14, có ca âm</div><div class="y">Độ phủ luật ≥ 80%</div><div class="y">Người duyệt khác người soạn</div><div class="y">Xác thực mức 3 (WebAuthn) trong 15 phút</div></div>
<label style="display:block;margin:10px 0;font-size:13px">☑ Tôi đã xem tác động và xác nhận bổ sung (thay đổi 3,9% quyết định)</label>
<div class="field"><label>Ý kiến *</label><div class="input" style="height:54px;align-items:flex-start;padding-top:6px">Chặn xuất mức Nhạy cảm ngoài giờ</div></div>
<div class="foot"><span class="btn danger">Từ chối</span><span class="btn pri">Phê duyệt và phát hành</span></div></div></div>""")

# 14 Nhật ký quyết định
hv = [(30, 2), (42, 3), (55, 3), (120, 8), (180, 12), (210, 18), (190, 31), (160, 14), (170, 11), (150, 9), (90, 5), (40, 3)]
vb = "".join(f'<div title="{i*2}h"><i style="height:{a/2.4:.0f}px;background:#2f9e5b"></i><i style="height:{d*2}px;background:#d64545"></i></div>' for i, (a, d) in enumerate(hv))
P["14"] = ("Nhật ký quyết định", "Quản trị / Nhật ký quyết định", f"""
{head("Nhật ký quyết định ủy quyền", BTN("Xuất CSV"), '<span class="muted">Lấy mẫu 10% mức Công khai, Nội bộ · 100% mức Hạn chế, Nhạy cảm</span>')}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 360px"><div class="card"><div class="toolbar"><span class="input" style="min-width:200px">traceId, người dùng, bên gọi…</span><span class="input">24 giờ qua ▾</span><span class="input">Quyết định: Từ chối ▾</span><span class="input">Lý do ▾</span><span class="input">Mức phân loại ▾</span></div>
{table(["Thời điểm", "Bên gọi", "Hành động · Tài nguyên", "Quyết định", "Lý do", "traceId"], [
["09:41:07", "dvc-t68", "export · hồ sơ hộ tịch", tag(ER, "Từ chối"), "OUT_OF_HOURS", mono("9f3a…c21")], ["09:40:52", "huy.lq", "read · luồng bảo hiểm", tag(OK, "Cho phép"), "—", mono("b71d…0e8")],
["09:40:31", "bao-cao-so", "read · chỉ tiêu", tag(ER, "Từ chối"), "SCOPE_MISSING", mono("44ac…9d1")], ["09:39:12", "khoa.pv", "approve · hoàn tiền", tag(ER, "Từ chối"), "STEPUP_REQUIRED", mono("e0f2…a37")],
["09:38:47", "dvc-t68", "read · danh mục", tag(OK, "Cho phép"), "—", mono("12bb…f60")]], "Nhật ký quyết định")}{foot("1–5 / 18.402")}</div>
<div class="card"><h4 style="margin:0 0 8px;font-size:15px">Tỷ lệ từ chối theo giờ</h4><div class="vbars">{vb}</div><div class="legend"><span><i style="background:#2f9e5b"></i>Cho phép</span><span><i style="background:#d64545"></i>Từ chối</span></div>
<div class="muted" style="margin-top:10px">Tỷ lệ từ chối 24 giờ: 7,3% · cao nhất 14:00–16:00 (OUT_OF_HOURS, SCOPE_MISSING).</div></div></div>""")

# 15 Cảnh báo và báo cáo tài khoản
P["15"] = ("Cảnh báo và báo cáo tài khoản", "Quản trị / Cảnh báo, báo cáo", f"""
{head("Cảnh báo và báo cáo tài khoản", BTN("Ngưỡng phát hiện"))}
{kpis([("Cảnh báo mở", "4", "1 mức Cao", ""), ("Độ phủ MFA nhóm bắt buộc", "99,6%", "7 tài khoản chưa có", ""), ("Tài khoản không dùng 45 ngày", "14", "sẽ tự vô hiệu", ""), ("Tự vô hiệu 30 ngày", "9", "", "")])}
<div class="grid-2e"><div class="card"><div class="toolbar"><b>Cảnh báo an ninh đang mở</b></div>
{table(["Mức", "Quy tắc", "Đối tượng", "Lúc", ""], [[tag(ER, "Cao"), "Dò mật khẩu (≥ 20 lần sai/phút)", mono("khoa.pv") + " · 10.20.4.17", "08:12", "Xác nhận"], [tag(WA, "Trung bình"), "Đăng nhập từ vị trí lạ", mono("huy.lq"), "07:55", "Xác nhận"], [tag(WA, "Trung bình"), "Từ chối tăng đột biến", "bao-cao-so", "07:20", "Xác nhận"], [tag(IN, "Thấp"), "Client dùng scope ít", "dvc-t68", "hôm qua", "Xác nhận"]], "Cảnh báo")}</div>
<div class="card"><div class="toolbar"><b>Phủ xác thực hai yếu tố theo vai trò</b></div>
<div class="hbar"><span>Quản trị tỉnh</span><i style="width:100%"></i><span class="num">100%</span></div><div class="hbar"><span>Cán bộ ATTT</span><i style="width:100%"></i><span class="num">100%</span></div><div class="hbar"><span>Kỹ sư tích hợp</span><i style="width:98%"></i><span class="num">98%</span></div><div class="hbar"><span>Kế toán đối soát</span><i style="width:94%"></i><span class="num">94%</span></div>
<div class="muted" style="margin-top:8px">Xem dạng bảng · Xuất CSV</div></div></div>""")

# 16 Cài đặt Định danh
P["16"] = ("Cài đặt Định danh", "Quản trị / Cài đặt Định danh", f"""
{head("Cài đặt Định danh", BTN("Khôi phục mặc định") + BTN("Lưu thay đổi", "pri"), '<span class="muted">Tham số 12.* của tenant T68, trong trần của nền tảng</span>')}
<div class="card"><div class="toolbar"><b>Mật khẩu, khóa tài khoản và vòng đời</b><span class="muted">3 thay đổi chưa lưu</span></div>{table(["Tham số", "Giá trị", "Mặc định", "Miền cho phép", "Ghi chú"], [
[mono("12.password.min-length"), "<span class='input' style='min-width:70px'>14</span> ký tự", "14", "14…128", "Không hạ thấp hơn 14 (TCVN 14423)"],
[mono("12.lockout.max-failures"), "<span class='input' style='min-width:70px'>5</span> lần", "5", "3…10", "Số lần sai liên tiếp thì khóa tạm"],
[mono("12.account.inactive-days"), "<span class='input' style='min-width:70px'>45</span> ngày", "45", "30…45", "Tự vô hiệu tài khoản không đăng nhập"],
[mono("12.client.secret-rotation-overlap-hours"), "<span class='input' style='min-width:70px'>24</span> giờ", "24", "1…72", "Giữ bí mật cũ sau khi xoay"],
[mono("12.jit.max-hours"), "<span class='input cell-err' style='min-width:70px'>8</span> giờ", "4", "1…4", "<span style='color:#a11a1a'>✗ Giá trị vượt giới hạn cho phép (1 đến 4) · ERR-12-043</span>"],
[mono("12.recert.interval-days.admin"), "<span class='input' style='min-width:70px'>90</span> ngày", "90", "30…90", "Chu kỳ rà soát quyền quản trị"]], "Tham số")}
<div class="field" style="margin-top:12px"><label>Lý do thay đổi * (ít nhất 10 ký tự)</label><div class="input">Điều chỉnh theo kết luận cuộc họp ATTT tháng 11</div></div></div>""")

# 17 Duyệt yêu cầu
P["17"] = ("Duyệt yêu cầu của PH-12", "Việc của tôi / Duyệt yêu cầu PH-12", f"""
{head("Duyệt yêu cầu", "", '<span class="muted">5 yêu cầu chờ bạn</span>')}
{facets(["Tất cả 5", "Ngoại lệ tách nhiệm vụ 1", "Quyền có thời hạn 2", "Chính sách 1", "Liên kết định danh 1"])}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 400px"><div class="card"><div class="toolbar"><span class="input" style="min-width:220px">Tìm người đề nghị, mã…</span><span class="input">Hạn xử lý ▾</span></div>
{table(["Loại", "Đề nghị", "Người đề nghị", "Chờ", "Hạn"], [
[tag(IN, "Ngoại lệ SoD"), "Lê Quang Huy · ENGINEER + APPROVER · 30 ngày", "Đỗ T. Hạnh (TA)", "2 giờ", "—"],
[tag(WA, "Quyền có thời hạn"), "Vào tenant T71 · đọc nhật ký · 2 giờ", "Hà Văn Phong (PO)", "14 phút", "<b style='color:#a8320f'>còn 16 phút</b>"],
[tag(IN, "Chính sách"), "tinh-t68-ngoai-gio v4", "Nguyễn T. Mai (SO)", "1 giờ", "—"],
[tag(MU, "Liên kết định danh"), "SAML · Cổng thông tin cũ", "Đỗ T. Hạnh (TA)", "1 ngày", "—"]], "Hộp việc")}</div>
<div class="card raised"><h4 style="margin:0 0 8px">Ngoại lệ tách nhiệm vụ · Lê Quang Huy</h4><div class="dl" style="grid-template-columns:110px 1fr"><dt>Vai trò</dt><dd>INTEGRATION_ENGINEER + INTEGRATION_APPROVER</dd><dt>Thời hạn</dt><dd>30 ngày</dd><dt>Lý do</dt><dd>Sở chỉ có một cán bộ tích hợp</dd><dt>Đề nghị</dt><dd>Đỗ T. Hạnh, 09:12</dd></div>
<div class="field" style="margin-top:12px"><label>Ý kiến duyệt *</label><div class="input" style="height:50px"></div></div><div class="foot"><span class="btn danger">Từ chối</span><span class="btn pri">Duyệt ngoại lệ</span></div></div></div>""")

# 19 Realm của tenant
P["19"] = ("Realm của tenant", "Nền tảng / Realm / T68", f"""
{chrome(mono("dh-t68") + " · Realm của tenant T68", tag(OK, "Đang hoạt động") + tag(WA, "Lệch cấu hình 2 mục"), "Mẫu realm v3.2 · GitOps · đối chiếu hằng giờ, lần gần nhất 09:00", BTN("Đối chiếu ngay") + BTN("Áp lại mẫu") + BTN("Tạm ngừng", "danger"))}
{tabs(["Tổng quan", "Lệch cấu hình ●2", "Khóa ký", "Vòng đời"], 1)}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 340px"><div class="card"><div class="toolbar"><b>Khác biệt so với mẫu Git</b></div>
{table(["Mục", "Mẫu (Git)", "Thực tế", "Mức"], [["accessTokenLifespan", mono("300"), "<span style='color:#a11a1a'>" + mono("900") + "</span>", tag(ER, "Cao")], ["passwordPolicy.length", mono("14"), "<span style='color:#a11a1a'>" + mono("12") + "</span>", tag(ER, "Cao")]], "Lệch cấu hình")}
<div class="muted" style="margin-top:10px">Quản trị tỉnh không sửa được cấu hình bảo mật realm (BR-12-038). “Áp lại mẫu” đưa realm về đúng cấu hình Git.</div></div>
<div class="card raised"><h4 style="margin:0 0 8px">Khóa ký realm</h4><div class="vtl"><div>Đang dùng · tạo 02/10/2026</div><div>Xoay kế tiếp: <b>31/12/2026</b> (90 ngày)</div><div>Khóa cũ giữ để xác minh 24 giờ</div></div><div class="muted">JWKS công bố công khai, APISIX tải mỗi 5 phút.</div></div></div>""")

# 18 Trang xác thực Keycloak (không có khung ứng dụng)
P["18"] = ("Trang xác thực của Keycloak", "", "")
PAGE18 = """<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440"><title>UI-12-18 · Trang xác thực của Keycloak</title><link rel="stylesheet" href="hifi.css"></head><body>
<div class="kc"><div class="box"><div class="brand"><div class="crest">T68</div><div>Tỉnh thí điểm T68<br><span class="muted" style="font-weight:400">Nền tảng tích hợp dữ liệu Datahub</span></div></div>
<h1>Đăng nhập</h1><div class="alert e" role="alert" style="margin-top:10px">⛔ Tên đăng nhập hoặc mật khẩu không đúng.</div>
<div class="field"><label>Tên đăng nhập hoặc thư điện tử</label><div class="input">khoa.pv</div></div><div class="field"><label>Mật khẩu</label><div class="input">••••••••••••••</div></div>
<div class="btn pri">Đăng nhập</div><div style="text-align:center;margin-top:10px;font-size:13px;color:#0b5cd5">Quên mật khẩu?</div>
<div class="sep">hoặc đăng nhập bằng</div><div class="btn">Tài khoản Active Directory của tỉnh</div><div class="btn" style="opacity:.6">VNeID (chưa bật)</div>
<div class="muted" style="margin-top:16px;text-align:center">Phiên khóa sau 15 phút không thao tác · Mật khẩu ≥ 14 ký tự<br>Hỗ trợ: quản trị tỉnh T68</div></div></div></body></html>"""

for code in sorted(P):
    if code == "18":
        html = PAGE18
    else:
        title, crumb, body = P[code][:3]
        extra = P[code][3] if len(P[code]) > 3 else ""
        html = shell(code, title, crumb, body, extra)
    (OUT / f"ui-12-{code}.html").write_text(html, encoding="utf-8")
print("Đã sinh", len(P), "tệp HTML")
