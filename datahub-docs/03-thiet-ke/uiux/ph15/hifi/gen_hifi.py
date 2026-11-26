#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-15-01…28 (D03-06-PH15, mục "Ảnh hi-fi" của từng màn).

Chạy: python3 gen_hifi.py; chụp ảnh: node shot.js (cần playwright, chromium.launch() không tham số).
Dữ liệu là giả định của tỉnh thí điểm T68: dịch vụ tra-cuu-ho-tich của HT-TUPHAP, HTTT khai thác HT-DATDAI,
nhà phát triển nguyen.van.an. Phong cách Liquid Glass của D03-05: kính chỉ ở thanh trên, mục lục quản trị và lớp nổi
(ngăn kéo, hộp thoại); văn bản, bảng, mã và biểu mẫu dùng nền đặc. Cùng một HTML được chụp ở 1440 px và 360 px
(quy tắc @media trong hifi.css) để chứng minh bố cục một cột ở 360 px.
"""
import pathlib

OUT = pathlib.Path(__file__).parent
OK, WA, ER, IN, MU = "ok", "warn", "err", "info", "mute"
TITLE = {}


def tag(k, t):
    return f"<span class='tag t-{k}'>{t}</span>"


def table(head, rows, label=""):
    th = "".join(f"<th scope='col'>{h}</th>" for h in head)
    out = ""
    for r in rows:
        sel = isinstance(r[0], tuple)
        cells = [r[0][0]] + list(r[1:]) if sel else list(r)
        out += "<tr" + (" class='sel'" if sel else "") + ">" + "".join(
            f"<td data-l='{head[i] if i < len(head) else ''}'>{c}</td>" for i, c in enumerate(cells)) + "</tr>"
    return f'<div class="tw"><table class="rt" aria-label="{label}"><thead><tr>{th}</tr></thead><tbody>{out}</tbody></table></div>'


def tabs(items, on):
    return '<div class="tabs" role="tablist">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def facets(items, on=0):
    return '<div class="facets">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def kpis(items):
    return f'<div class="kpis" style="--n:{len(items)}">' + "".join(f'<div class="kpi"><span>{a}</span><b>{b}</b><small>{c}</small></div>' for a, b, c in items) + "</div>"


def foot(t="Hiển thị 1–20"):
    return f'<div class="foot" style="justify-content:space-between"><span class="muted">{t}</span><span class="muted">‹ 1 2 3 › · 20 / trang</span></div>'


def inp(label, val="", req=False, hint="", mono=False):
    return (f'<div class="field"><label>{label}{" <span class=star>*</span>" if req else ""}</label>'
            f'<div class="input{" mono" if mono else ""}">{val or "&nbsp;"}</div>' + (f'<div class="muted">{hint}</div>' if hint else "") + "</div>")


def head(title, right="", sub=""):
    return f'<div class="head"><h1>{title}</h1>{sub}<div class="sp"></div>{right}</div>'


def drawer(title, inner, w=480):
    return f'<div class="drawer" role="dialog" aria-label="{title}" style="width:{w}px"><h3 style="margin:0 0 10px">{title}</h3>{inner}</div>'


def dialog(title, inner):
    return f'<div class="scrim"></div><div class="dialog" role="dialog" aria-modal="true" aria-label="{title}"><h3 style="margin:0 0 10px">{title}</h3>{inner}</div>'


def sc(name, code, desc, tags="", foot_=""):
    return f'<div class="sc"><h3>{name}</h3><div class="muted mono">{code}</div><p>{desc}</p><div class="row">{tags}</div>{foot_}</div>'


NAV = ["Dịch vụ", "Sự kiện", "Hướng dẫn", "Hỏi đáp", "Ứng dụng của tôi", "Hỗ trợ"]
ADMIN = [("Nhận diện", "25"), ("Tham số", "25"), ("Nội dung", "22"), ("Tài khoản dh-dev", "24"), ("Dịch vụ, thử production", "23"),
         ("Đồng bộ, đối soát", "27"), ("Di trú hệ cũ", "27"), ("Nhật ký, báo cáo", "26"), ("Hộp hỗ trợ", "28")]


def shell(code, title, body, nav=None, user="Nguyễn Văn An", admin=False, anon=False, extra=""):
    TITLE[code] = title
    nv = "".join(f'<a class="{"on" if n == nav else ""}" href="#">{n}</a>' for n in NAV)
    who = ('<span class="btn">Đăng nhập</span><span class="btn pri hide-m">Đăng ký</span>' if anon else
           '<span class="tray hide-m">🔔 3</span><span class="tray hide-m">T68</span><div class="avatar" aria-label="Menu tài khoản">AN</div>')
    side = ""
    if admin:
        side = '<aside aria-label="Quản trị cổng"><div class="grp">Quản trị cổng</div>' + "".join(
            f'<a class="{"on" if c == code else ""}" href="#">{n}</a>' for n, c in ADMIN) + "</aside>"
        content = f'<div class="adm">{side}<main>{body}</main></div>'
    else:
        content = f'<main class="page">{body}</main>'
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>UI-15-{code} · {title}</title><link rel="stylesheet" href="hifi.css"></head><body>
<header class="pt"><span class="burger" aria-label="Mở menu">☰</span><div class="logo"><b>Cổng API</b> Tỉnh T68</div><nav aria-label="Điều hướng chính">{nv}</nav><div class="sp"></div>
<div class="search input">Tìm dịch vụ, hướng dẫn…  Ctrl K</div>{who}</header>
{content}{extra}
<footer class="pf"><span>Điều khoản sử dụng</span><span>Chính sách bảo vệ dữ liệu cá nhân</span><span>Hỗ trợ: hotro@t68.datahub.gov.vn</span><span>Cổng v1.0</span></footer>
<div class="hint">Bản hi-fi minh họa · D03-06-PH15 · UI-15-{code} · dữ liệu giả định</div></body></html>"""


P = {}
CODE_REQ = """<b>curl</b> -X POST https://api.t68.datahub.gov.vn/tu-phap/v1/ho-tich/tra-cuu \\
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \\
  -d '{"<i>soGiayKhaiSinh</i>": "<i>000-KS-2026-0001</i>"}'"""
CODE_RES = """HTTP/1.1 200 OK
{ "<i>soGiayKhaiSinh</i>": "000-KS-2026-0001",
  "<i>hoTen</i>": "Nguyen Van Mau", "<i>trangThai</i>": "DA_CAP" }"""

# 01 Trang chủ
P["01"] = ("Trang chủ cổng", "", f"""
<div class="hero"><h1>Cổng nhà phát triển tỉnh T68</h1><p class="muted" style="font-size:15px">Tìm API, đọc tài liệu, thử trên sandbox và đăng ký sử dụng, tất cả ở một nơi.</p>
<div class="bigsearch"><div class="input">🔍 Tìm "tra cứu hộ tịch", "đất đai", "thanh toán"…</div><span class="btn pri">Tìm</span></div>
<div class="facets"><span>Tư pháp</span><span>Đất đai</span><span>Thanh toán</span><span>Y tế</span><span>Giao thông</span><span>Xem tất cả lĩnh vực</span></div></div>
{kpis([("Dịch vụ API","48","3 mới trong 30 ngày"),("Dịch vụ sự kiện","9","topic Kafka"),("Cơ quan cung cấp","14","chủ quản"),("Ứng dụng sandbox","126","đang hoạt động")])}
<h2 style="font-size:18px;margin:14px 0 8px">Dịch vụ nổi bật</h2><div class="cards">
{sc("Tra cứu hộ tịch","tra-cuu-ho-tich · v1.0.0","Tra cứu giấy khai sinh, kết hôn theo số định danh.",tag(OK,"Đã công bố")+tag(IN,"OAuth2")+tag(MU,"Sở Tư pháp"))}
{sc("Tra cứu thửa đất","tra-cuu-thua-dat · v2.1.0","Thông tin thửa đất theo mã thửa, tờ bản đồ.",tag(OK,"Đã công bố")+tag(IN,"mTLS")+tag(MU,"Sở TN&MT"))}
{sc("Sự kiện: hồ sơ hộ tịch đã cấp","t68.tuphap.hotich.cap.v1","Thông báo khi cấp giấy tờ hộ tịch.",tag(IN,"Sự kiện")+tag(MU,"Sở Tư pháp"))}</div>
<h2 style="font-size:18px;margin:16px 0 8px">Bắt đầu nhanh</h2><div class="cards">
{sc("1. Đăng nhập","","Cán bộ dùng tài khoản của cơ quan; nhà thầu đăng ký tài khoản riêng.")}
{sc("2. Tạo ứng dụng sandbox","","Nhận client sandbox, bí mật chỉ hiện một lần.")}
{sc("3. Thử API","","Gọi thử với dữ liệu giả, rồi đăng ký sử dụng production.")}</div>""", "", "", False, True)

# 02 Danh mục dịch vụ
P["02"] = ("Danh mục dịch vụ", "Dịch vụ", f"""
{head("Danh mục dịch vụ", '<span class="muted">Đồng bộ lúc 09:36 · 48 dịch vụ</span>')}
<div class="lay2"><div class="card"><b>Lọc</b><div class="field" style="margin-top:8px"><label>Loại</label><div class="input">API, Sự kiện ▾</div></div>
<div class="field"><label>Lĩnh vực</label><div class="input">Tư pháp ▾</div></div><div class="field"><label>Cơ quan chủ quản</label><div class="input">Tất cả ▾</div></div>
<div class="field"><label>Kiểu xác thực</label><div class="input">OAuth2, mTLS ▾</div></div><div class="field"><label><span class="input" style="min-width:0;height:18px">☐</span> Hiện cả dịch vụ đã ngừng</label></div><span class="btn">Xóa bộ lọc</span></div>
<div><div class="toolbar" style="margin:0 0 10px;border-radius:12px;border:1px solid var(--color-border)"><span class="input" style="min-width:240px">🔍 Tìm trong danh mục</span><span class="input">Sắp xếp: Phổ biến ▾</span><div style="flex:1"></div><span class="muted">▦ Thẻ · ☰ Bảng</span></div>
<div class="cards c2">
{sc("Tra cứu hộ tịch","tra-cuu-ho-tich · v1.0.0","Tra cứu giấy khai sinh, kết hôn theo số định danh.",tag(OK,"Đã công bố")+tag(IN,"OAuth2")+tag(MU,"Sandbox"))}
{sc("Cấp bản sao trích lục","cap-ban-sao-trich-luc · v1.2.0","Yêu cầu cấp bản sao trích lục hộ tịch.",tag(OK,"Đã công bố")+tag(IN,"mTLS"))}
{sc("Tra cứu lý lịch tư pháp (cũ)","tra-cuu-llt · v1.0.0","Sẽ ngừng ngày 30/06/2027, chuyển sang v2.",tag(WA,"⚠ Sắp ngừng")+tag(IN,"OAuth2"))}
{sc("Sự kiện: hồ sơ hộ tịch đã cấp","t68.tuphap.hotich.cap.v1","Thông báo khi cấp giấy tờ hộ tịch.",tag(IN,"Sự kiện")+tag(MU,"AsyncAPI"))}</div>{foot("1–4 / 12")}</div></div>""", "Dịch vụ")

# 03 Kết quả tìm kiếm
P["03"] = ("Kết quả tìm kiếm", "", f"""
<div class="bigsearch"><div class="input">🔍 ho tich</div><span class="btn pri">Tìm</span></div>
<div class="card" style="margin:-6px 0 10px;padding:8px 12px"><span class="muted">Gợi ý:</span> <b>hộ tịch</b> · hộ tịch điện tử · giấy khai sinh</div>
{tabs(["API 12","Hướng dẫn 4","Sự kiện 1"],0)}
<div class="muted" style="margin-bottom:8px">17 kết quả cho "ho tich" (đã bỏ dấu khi so khớp) · 0,12 giây</div>
<div class="card" style="margin-bottom:10px"><b>Tra cứu <span class="mark">hộ tịch</span></b> {tag(OK,"Đã công bố")} <span class="muted mono">tra-cuu-ho-tich · v1.0.0</span><p style="margin:4px 0">Tra cứu giấy khai sinh, kết hôn theo số định danh. Dữ liệu <span class="mark">hộ tịch</span> của Sở Tư pháp…</p></div>
<div class="card" style="margin-bottom:10px"><b>Cấp bản sao trích lục <span class="mark">hộ tịch</span></b> {tag(OK,"Đã công bố")} <span class="muted mono">cap-ban-sao-trich-luc · v1.2.0</span><p style="margin:4px 0">Yêu cầu cấp bản sao trích lục <span class="mark">hộ tịch</span> điện tử…</p></div>
<div class="card"><b>Đăng ký <span class="mark">hộ tịch</span> trực tuyến</b> {tag(MU,"Hướng dẫn")}<p style="margin:4px 0">Luồng gọi API đăng ký <span class="mark">hộ tịch</span> qua cổng dịch vụ công…</p></div>{foot("1–10 / 17")}""", "Dịch vụ")

# 04 Chi tiết dịch vụ
P["04"] = ("Chi tiết dịch vụ", "Dịch vụ", f"""
<div class="muted">Dịch vụ › Tư pháp › Tra cứu hộ tịch</div>
<div class="chrome"><h1>Tra cứu hộ tịch {tag(OK,"Đã công bố")} {tag(IN,"Sandbox có")} <span class="muted mono" style="font-size:14px">tra-cuu-ho-tich</span></h1>
<div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap"><span class="input">Phiên bản v1.0.0 ▾</span><span class="muted">HT-TUPHAP · Sở Tư pháp · OAuth2 · dữ liệu NỘI BỘ</span><span style="flex:1"></span><span class="btn">Tài liệu</span><span class="btn">Thử API</span><span class="btn pri">Đăng ký sử dụng</span></div></div>
<div class="banner w">⚠ Phiên bản v0.9.0 đã ngừng ngày 01/09/2026. <span class="sp"></span><span>Xem lộ trình ngừng ›</span></div>
<div class="lay2" style="grid-template-columns:minmax(0,1fr) 340px"><div class="doc"><h2>Giới thiệu</h2><p>Tra cứu giấy khai sinh, giấy chứng nhận kết hôn theo số định danh của người dân.</p>
<h3>Đường dẫn sử dụng</h3><div class="code">https://api.t68.datahub.gov.vn/tu-phap/v1/ho-tich/tra-cuu</div>
<h3>Cam kết dịch vụ (SLA)</h3>{table(["Chỉ tiêu","Cam kết"],[["Khả dụng","99,5 % / tháng"],["Độ trễ p95","≤ 800 ms"],["Hạn mức mặc định","60 lượt / phút"]],"SLA")}
<h3>Thay đổi gần đây</h3><div class="muted">12/10/2026 · v1.0.0: thêm trường trangThai · 20/08/2026 · v0.9.0 ngừng</div></div>
<div><div class="card" style="margin-bottom:10px"><b>Chủ dịch vụ</b><div class="muted">Sở Tư pháp · HT-TUPHAP</div><div class="muted">Đầu mối: dichvu.tuphap@t68.gov.vn</div><span class="btn" style="margin-top:8px">Hỏi đáp (3) ›</span></div>
<div class="card"><b>Theo dõi thay đổi</b><div class="muted">Nhận thông báo khi dịch vụ đổi phiên bản.</div><span class="btn" style="margin-top:8px">🔔 Theo dõi</span></div></div></div>""", "Dịch vụ")

# 05 Tài liệu API (PTN-14)
P["05"] = ("Tài liệu API", "Dịch vụ", f"""
<div class="muted">Dịch vụ › Tra cứu hộ tịch › Tài liệu</div>
<div class="lay3"><nav class="toc" aria-label="Mục lục"><div class="input" style="margin-bottom:8px">v1.0.0 ▾</div><div>Giới thiệu</div><div>Xác thực</div><div>Thao tác</div>
<div class="sub on">POST /ho-tich/tra-cuu</div><div class="sub">GET /ho-tich/{{ma}}</div><div>Mã lỗi</div><div>Giới hạn sử dụng</div><div>Nhật ký thay đổi</div><div style="margin-top:8px"><span class="btn">⬇ OpenAPI (yaml)</span></div></nav>
<div class="doc"><h2>Tra cứu hộ tịch <span class="muted" style="font-size:13px">v1.0.0</span></h2>
<h3><span class="m">POST</span> /ho-tich/tra-cuu</h3><p>Tra cứu giấy khai sinh theo số giấy khai sinh. Cần phạm vi <span class="mono">hotich:read</span>.</p>
{table(["Tham số","Vị trí","Kiểu","Bắt buộc","Mô tả"],[["soGiayKhaiSinh","body","chuỗi","Có","Số giấy khai sinh, 6–30 ký tự"],["Idempotency-Key","header","chuỗi","Không","Khóa chống trùng"]],"Tham số")}
<h3>Mã trạng thái</h3><div class="row">{tag(OK,"200")} {tag(WA,"404")} {tag(ER,"422")} {tag(ER,"429")}</div><h3>Đặc tả liên quan</h3><div class="muted">Xem phiên bản trước · So sánh v0.9.0 ↔ v1.0.0</div></div>
<div><div class="card" style="margin-bottom:10px"><div class="tabs"><span class="on">curl</span><span>Java</span><span>Python</span><span>JavaScript</span><span>C#</span><span>Go</span></div><div class="code">{CODE_REQ}</div><div class="foot"><span class="btn">⧉ Sao chép</span></div></div>
<div class="card"><b>Phản hồi mẫu 200</b><div class="code" style="margin-top:8px">{CODE_RES}</div></div></div></div>""", "Dịch vụ")

# 06 Thử API
P["06"] = ("Thử API", "Dịch vụ", f"""
<div class="muted">Dịch vụ › Tra cứu hộ tịch › Thử API</div>
<div class="banner i">ℹ Đang thử trên <b>Sandbox</b> (chế độ MOCK): phản hồi sinh từ ví dụ trong đặc tả, chỉ dùng dữ liệu giả.</div>
<div class="lay3" style="grid-template-columns:240px minmax(0,1fr) minmax(0,1fr)"><nav class="toc"><div class="input" style="margin-bottom:8px">v1.0.0 ▾</div><div class="on">POST /ho-tich/tra-cuu</div><div>GET /ho-tich/{{ma}}</div><div class="muted" style="margin-top:10px">Hạn mức phút này</div><div class="prog"><i style="width:90%"></i></div><div class="muted">27/30 lượt · ứng dụng 412/3.000 hôm nay</div></nav>
<div class="card"><h3 style="margin:0 0 8px">Yêu cầu</h3><div class="fg"><div class="field"><label>Môi trường</label><div class="input">Sandbox ▾</div></div><div class="field"><label>Ứng dụng</label><div class="input">datdai-thu-nghiem ▾</div></div></div>
<div class="field"><label>Thân yêu cầu (JSON)</label><div class="ed" style="min-height:90px">{{ "soGiayKhaiSinh": "000-KS-2026-0001" }}</div></div>
<div class="banner w">⚠ Nội dung có vẻ chứa dữ liệu cá nhân thật. Chỉ dùng dữ liệu giả (dải 000…).</div>
<div class="foot"><span class="btn">Kiểm tra</span><span class="btn">Lưu vào bộ sưu tập</span><span class="btn pri">Gửi thử  Ctrl+Enter</span></div></div>
<div class="card"><h3 style="margin:0 0 8px">Phản hồi {tag(OK,"200 OK")} <span class="muted" style="font-weight:400">184 ms · MOCK · tryId TR-8F2K</span></h3><div class="code">{CODE_RES}</div>
<div class="muted" style="margin-top:8px">Tiêu đề: X-DH-Sandbox: mock · X-DH-Try-Id: TR-8F2K</div><div class="foot"><span class="btn">Mẫu mã tương ứng</span><span class="btn">⧉ Sao chép</span></div></div></div>""", "Dịch vụ")

# 07 Hướng dẫn
P["07"] = ("Hướng dẫn, hỏi đáp, thông báo", "Hướng dẫn", f"""
{tabs(["Hướng dẫn","Hỏi đáp","Thông báo"],0)}
<div class="lay2"><nav class="toc"><div class="input" style="margin-bottom:8px">🔍 Tìm hướng dẫn</div><div>Bắt đầu nhanh</div><div class="on">Kết nối mTLS tới cổng API</div><div>Lấy token client_credentials</div><div>Xử lý lỗi RFC 9457</div><div>Danh sách kiểm tra tích hợp</div></nav>
<div class="doc"><div class="muted">Cập nhật 12/11/2026 · phiên bản 3 · Sở KH&CN</div><h2>Kết nối mTLS tới cổng API</h2><p>Hướng dẫn cấu hình chứng thư máy khách để gọi API qua kênh mTLS.</p>
<h3>1. Chuẩn bị chứng thư</h3><p>Tạo khóa riêng và yêu cầu ký chứng thư (CSR). Không gửi khóa riêng qua thư điện tử.</p><div class="code"><b>openssl</b> req -new -newkey rsa:3072 -nodes -keyout client.key -out client.csr</div>
<h3>2. Gọi thử</h3><p>Dùng <span class="mono">curl --cert client.pem --key client.key</span> tới địa chỉ sandbox.</p>
<div class="foot" style="justify-content:flex-start;align-items:center"><span class="muted">Trang này có hữu ích không?</span><span class="btn">👍 Có</span><span class="btn">👎 Chưa</span><span class="btn">Báo lỗi tài liệu</span></div></div></div>""", "Hướng dẫn")

# 08 Đăng nhập, đăng ký
P["08"] = ("Đăng nhập và đăng ký dh-dev", "", f"""
<div class="cards c2" style="max-width:1000px;margin:0 auto"><div class="card"><h2 style="margin:0 0 6px;font-size:20px">Đăng nhập</h2><p class="muted">Chọn nơi lưu tài khoản của bạn.</p>
<div class="sc sel" style="margin-bottom:10px"><b>Cán bộ cơ quan nhà nước</b><p>Đăng nhập một lần (SSO) bằng tài khoản của tỉnh T68.</p><span class="btn pri">Đăng nhập bằng tài khoản tỉnh</span></div>
<div class="sc"><b>Nhà thầu, tài khoản dh-dev</b><p>Dành cho đơn vị thầu đã được cơ quan giao việc.</p><span class="btn">Đăng nhập tài khoản nhà thầu</span></div></div>
<div class="card"><h2 style="margin:0 0 6px;font-size:20px">Đăng ký tài khoản nhà thầu</h2><div class="fg">{inp("Thư điện tử",'nguyen.van.an@congty-abc.vn',True)}{inp("Họ và tên",'Nguyễn Văn An',True)}{inp("Đơn vị thầu",'Công ty ABC',True)}{inp("Số hợp đồng, văn bản giao việc",'HĐ 25/2026/SKHCN',True)}{inp("Tổ chức giao việc",'SO-TUPHAP ▾',True)}{inp("Điện thoại",'0901234567')}</div>
{inp("Mật khẩu",'••••••••••••••',True,"Từ 14 ký tự.")}<div class="field"><label>☑ Tôi đã đọc thông báo xử lý dữ liệu cá nhân và điều khoản sử dụng</label></div>
<div class="banner i">Sau khi gửi, kiểm tra thư để xác minh trong 24 giờ; quản trị cổng sẽ duyệt tài khoản.</div><div class="foot"><span class="btn pri">Đăng ký</span></div></div></div>""", "", "", False, True)

# 09 Hồ sơ, điều khoản, nhóm
P["09"] = ("Hồ sơ, điều khoản, nhóm", "", f"""
{head("Tài khoản của tôi")}
<div class="lay2"><div class="card"><div class="tree"><div class="on">Hồ sơ</div><div>Phiên đăng nhập</div><div>Nhóm phát triển</div><div>Điều khoản sử dụng</div><div>Xóa tài khoản</div></div></div>
<div><div class="card" style="margin-bottom:12px"><h3 style="margin:0 0 8px">Hồ sơ</h3><div class="fg">{inp("Họ và tên","Nguyễn Văn An",True)}{inp("Đơn vị","Công ty ABC",True)}{inp("Điện thoại","0901234567")}{inp("Ngôn ngữ","Tiếng Việt ▾")}</div>
<div class="muted">Nguồn tài khoản: dh-dev · Trạng thái {tag(OK,"Đang hoạt động")}</div><div class="foot"><span class="btn pri">Lưu</span></div></div>
<div class="card" style="margin-bottom:12px"><h3 style="margin:0 0 8px">Nhóm phát triển</h3>{table(["Nhóm","Vai trò","Thành viên","Ứng dụng"],[["nhom-datdai","Chủ nhóm","4","3"],["nhom-thau-a","Nhà phát triển","6","5"]],"Nhóm")}<div class="foot"><span class="btn">Mời thành viên</span><span class="btn">+ Tạo nhóm</span></div></div>
<div class="banner e">Điều khoản sử dụng v2.0 có hiệu lực từ 01/12/2026. Cần chấp nhận để tiếp tục thử API. <span class="sp"></span><span class="btn pri">Đọc và chấp nhận</span></div></div></div>""", "")

# 10 Danh sách ứng dụng
P["10"] = ("Danh sách ứng dụng", "Ứng dụng của tôi", f"""
{head("Ứng dụng của tôi", '<span class="btn pri">+ Tạo ứng dụng</span>')}
{facets(["Tất cả 5","Đang hoạt động 3","Tạm ngừng 1","Đã lưu trữ 1"],0)}
<div class="card"><div class="toolbar"><span class="input" style="min-width:240px">🔍 Tìm theo mã, tên</span><span class="input">Chủ: Tất cả ▾</span><div style="flex:1"></div><span class="muted">Hạn mức: 3/10 ứng dụng đang hoạt động</span></div>
{table(["Mã ứng dụng","Tên","Chủ","Trạng thái","Thông tin xác thực","Gọi 7 ngày","Cập nhật"],[
["<a class='mono'>datdai-thu-nghiem</a>","Thử nghiệm tra cứu hộ tịch","nhom-datdai",tag(OK,"✓ Đang hoạt động"),"2 (1 sắp hết hạn)","<span class='num'>1.482</span>","25/11/2026"],
["<a class='mono'>app-tra-cuu-ho-tich</a>","Ứng dụng tra cứu hộ tịch","Cá nhân",tag(OK,"✓ Đang hoạt động"),"1","<span class='num'>320</span>","20/11/2026"],
["<a class='mono'>app-demo</a>","Ứng dụng mẫu","Cá nhân",tag(WA,"⏸ Tạm ngừng"),"1","<span class='num'>0</span>","02/11/2026"],
["<a class='mono'>app-cu</a>","Ứng dụng cũ","Cá nhân",tag(MU,"▣ Đã lưu trữ"),"0","<span class='num'>0</span>","01/10/2026"]],"Danh sách ứng dụng")}{foot("1–4 / 5")}</div>""", "Ứng dụng của tôi")

# 11 Tạo ứng dụng (ngăn kéo trên danh sách)
P["11"] = ("Tạo ứng dụng", "Ứng dụng của tôi", P["10"][2], "Ứng dụng của tôi", "Nguyễn Văn An", False, False,
          drawer("Tạo ứng dụng sandbox", f"""{inp("Tên ứng dụng","Thử nghiệm tra cứu thửa đất",True)}{inp("Mã ứng dụng","tn-tra-cuu-thua-dat",True,"Chữ thường, số, gạch nối; 3–41 ký tự; không đổi sau khi tạo.",True)}
{inp("Mô tả","Ứng dụng của HT-DATDAI")}<div class="field"><label>Chủ sở hữu <span class="star">*</span></label><div class="input">Nhóm: nhom-datdai ▾</div></div>{inp("Hệ thống thông tin (tùy chọn)","HT-DATDAI ▾",False,"Chỉ cán bộ cơ quan nhà nước; dùng để xem tham chiếu production.")}
<div class="foot"><span class="btn">Hủy</span><span class="btn">Tạo</span><span class="btn pri">Tạo và cấp thông tin xác thực</span></div>"""))

# 12 Chi tiết ứng dụng
P["12"] = ("Chi tiết ứng dụng", "Ứng dụng của tôi", f"""
<div class="muted">Ứng dụng của tôi › datdai-thu-nghiem</div>
<div class="chrome"><h1>Thử nghiệm tra cứu hộ tịch {tag(OK,"✓ Đang hoạt động")}</h1><div style="display:flex;gap:8px;align-items:center;flex-wrap:wrap"><span class="muted mono">datdai-thu-nghiem · chủ: nhom-datdai · HT-DATDAI</span><span style="flex:1"></span><span class="btn">Sửa</span><span class="btn">Lưu trữ</span></div></div>
{tabs(["Tổng quan","Xác thực","Bộ sưu tập","Thống kê","Nhật ký","Thành viên"],3)}
<div class="head" style="margin-bottom:8px"><span class="input">7 ngày ▾</span><span class="input">Dịch vụ: Tất cả ▾</span><div class="sp"></div><span class="muted">Cập nhật 09:41 · PH-13</span></div>
{kpis([("Lượt gọi","1.482","▲ 6 %"),("Tỷ lệ lỗi","2,1 %","▼ 0,4 điểm"),("Độ trễ p95","412 ms",""),("Lượt thử bị chặn","3","hạn mức")])}
<div class="split"><div class="card"><b>Lượt gọi theo ngày</b><div class="vbars" style="margin-top:8px">{"".join(f'<div><i style="height:{h}px;background:#0b5cd5"></i><i style="height:{e}px;background:#d64545"></i></div>' for h,e in [(90,4),(110,5),(95,3),(130,6),(120,4),(70,2),(140,5)])}</div><div class="legend"><span><i style="background:#0b5cd5"></i>Thành công</span><span><i style="background:#d64545"></i>Lỗi</span><span>Xem dạng bảng</span></div></div>
<div class="card"><b>Thành viên</b>{table(["Người dùng","Vai trò"],[["nguyen.van.an","Chủ sở hữu"],["tran.thi.b","Nhà phát triển"],["le.van.c","Người xem"]],"Thành viên")}<div class="foot"><span class="btn">Thêm thành viên</span></div></div></div>""", "Ứng dụng của tôi")

# 13 Thông tin xác thực
P["13"] = ("Thông tin xác thực", "Ứng dụng của tôi", f"""
<div class="muted">Ứng dụng của tôi › datdai-thu-nghiem › Xác thực</div>
{head("Thông tin xác thực", '<span class="btn pri">+ Cấp thông tin xác thực</span>')}
<div class="card" style="margin-bottom:12px"><h3 style="margin:0 0 8px">Sandbox <span class="muted" style="font-weight:400">(2/3)</span></h3>{table(["Client ID / khóa","Loại","Trạng thái","Hết hạn","Thao tác"],[
["<span class='mono'>sbx-t68-datdai-thu-nghiem-1</span>","client_credentials",tag(WA,"⏳ Sắp hết hạn (6 ngày)"),"02/12/2026","Xoay vòng · Thu hồi"],
["<span class='mono'>sbx-t68-datdai-thu-nghiem-2</span>","client_credentials",tag(OK,"✓ Đang hoạt động"),"24/02/2027","Xoay vòng · Thu hồi"],
["<span class='mono'>dhsk_t68_Xk…</span>","API key",tag(MU,"⏻ Đã thu hồi"),"—","—"]],"Thông tin xác thực sandbox")}</div>
<div class="card"><h3 style="margin:0 0 8px">Production (chỉ tham chiếu, không có bí mật) {tag(IN,"HT-DATDAI")}</h3>{table(["Client ID","Phương thức","Dấu vân tay","Hết hạn","Trạng thái"],[["<span class='mono'>datdai-prod</span>","tls_client_auth","<span class='mono'>3F:9A:…:C2</span>","15/01/2027",tag(WA,"Sắp hết hạn")]],"Tham chiếu production")}
<div class="muted" style="margin-top:8px">Bí mật production do cơ quan quản lý hệ thống cấp qua kênh riêng.</div></div>""", "Ứng dụng của tôi",
          "Nguyễn Văn An", False, False, dialog("Bí mật chỉ hiện một lần", f"""<div class="banner w">⚠ Sao chép ngay. Sau khi đóng, không xem lại được.</div>
<div class="field"><label>Client ID</label><div class="secret">sbx-t68-datdai-thu-nghiem-2</div></div><div class="field"><label>Client secret</label><div class="secret">••••••••••••••••••••••••••••••••  [Hiện] [Sao chép]</div></div>
<div class="field"><label>☐ Tôi đã lưu bí mật ở nơi an toàn</label></div><div class="foot"><span class="btn pri" style="opacity:.5">Đóng</span></div>"""))

# 14 Lịch sử và bộ sưu tập thử
P["14"] = ("Lịch sử và bộ sưu tập thử", "Ứng dụng của tôi", f"""
<div class="muted">Ứng dụng của tôi › datdai-thu-nghiem › Bộ sưu tập</div>
{tabs(["Tổng quan","Xác thực","Bộ sưu tập","Thống kê","Nhật ký","Thành viên"],2)}
<div class="lay2"><div class="card"><b>Bộ sưu tập (2/50)</b><div class="tree" style="margin-top:8px"><div class="on">Tra cứu hộ tịch (6)</div><div>Cấp bản sao (3)</div></div><div class="foot"><span class="btn">+ Mới</span></div></div>
<div><div class="card" style="margin-bottom:12px"><div class="toolbar"><span class="input">Xuất: Postman ▾</span><span class="btn">⬇ Tải</span><div style="flex:1"></div><span class="muted">6 yêu cầu</span></div>{table(["Tên yêu cầu","Thao tác","Môi trường","Cập nhật"],[["Khai sinh hợp lệ","POST /ho-tich/tra-cuu","Sandbox","25/11"],["Thiếu số giấy","POST /ho-tich/tra-cuu","Sandbox","25/11"]],"Bộ sưu tập")}</div>
<div class="card"><b>Lịch sử thử 30 ngày</b><div class="toolbar" style="margin-top:8px"><span class="input">Từ 20/11 đến 26/11</span><span class="input">Kết quả: Tất cả ▾</span><div style="flex:1"></div><span class="btn danger">Xóa lịch sử</span></div>
{table(["Giờ","Thao tác","Kết quả","Độ trễ","tryId"],[["09:41:07","POST /ho-tich/tra-cuu",tag(OK,"✓ 200"),"184 ms","<span class='mono'>TR-8F2K</span>"],["09:38:51","POST /ho-tich/tra-cuu",tag(ER,"✗ 422"),"96 ms","<span class='mono'>TR-8F1A</span>"],["09:30:02","GET /ho-tich/HT-0001",tag(WA,"⏱ Hạn mức"),"—","<span class='mono'>TR-8E9Q</span>"]],"Lịch sử thử")}{foot("1–3 / 128")}</div></div></div>""", "Ứng dụng của tôi")


def steps(items, on):
    return '<div class="steps">' + "".join(f'<div class="{"done" if i < on else "on" if i == on else ""}">{"✓ " if i < on else ""}{i+1}. {t}</div>' for i, t in enumerate(items)) + "</div>"


# 15 Đăng ký sử dụng (PTN-05)
P["15"] = ("Đăng ký sử dụng", "Ứng dụng của tôi", f"""
{head("Đăng ký sử dụng API production")}
{steps(["Chọn dịch vụ","Mục đích và quy mô","Xác nhận"],1)}
<div class="lay2" style="grid-template-columns:minmax(0,1fr) 320px"><div class="card"><div class="fg">{inp("Dịch vụ","tra-cuu-ho-tich · v1.0.0 ▾",True)}{inp("Gói sử dụng","Chuẩn 60 lượt/phút ▾",True)}{inp("Hệ thống thông tin","HT-DATDAI ▾",True)}{inp("Lượt gọi dự kiến mỗi ngày","5.000",True)}</div>
<div class="field"><label>Thao tác cần dùng <span class="star">*</span></label><div class="input">☑ POST /ho-tich/tra-cuu  ☐ GET /ho-tich/{{ma}}</div></div>{inp("Mục đích sử dụng","Đối chiếu hộ tịch khi giải quyết hồ sơ đất đai",True)}{inp("Căn cứ pháp lý","Nghị định 278/2025/NĐ-CP, Điều …",True)}
<div class="field"><label>☑ Tôi chấp nhận điều khoản sử dụng dịch vụ</label></div><div class="foot"><span class="btn">‹ Quay lại</span><span class="btn pri">Tiếp tục</span></div></div>
<div class="card raised"><b>Đăng ký của tôi</b>{table(["Mã","Dịch vụ","Trạng thái"],[["SUB-0041","tra-cuu-thua-dat",tag(OK,"Đang hoạt động")],["SUB-0052","tra-cuu-ho-tich",tag(IN,"Chờ duyệt")],["SUB-0037","tra-cuu-llt",tag(ER,"Bị từ chối")]],"Đăng ký của tôi")}<div class="muted" style="margin-top:6px">Duyệt do PH-02; cổng chỉ chuyển yêu cầu và hiển thị trạng thái.</div></div></div>""", "Ứng dụng của tôi")

# 16 Kết nạp HTTT
P["16"] = ("Kết nạp HTTT", "Ứng dụng của tôi", f"""
{head("Kết nạp hệ thống thông tin")}
{steps(["Tổ chức","Hệ thống","Đầu mối, cấp độ","Xác nhận"],2)}
<div class="banner i">Biểu mẫu do PH-01 quy định. Cổng chỉ chuyển hồ sơ; việc thẩm định ở PH-01.</div>
<div class="card"><div class="fg">{inp("Tổ chức","SO-NNPTNT · Sở NN&PTNT",True)}{inp("Tên hệ thống","HT-NONGNGHIEP · Quản lý nông nghiệp",True)}{inp("Đầu mối kỹ thuật","Trần Văn B · tran.b@t68.gov.vn",True)}{inp("Cấp độ ATTT","Cấp độ 3 ▾",True)}</div>{inp("Mục đích kết nối","Tra cứu hộ tịch phục vụ trợ cấp",True)}{inp("Căn cứ pháp lý","Quyết định số …/QĐ-UBND",True)}
<div class="foot"><span class="btn">‹ Quay lại</span><span class="btn">Lưu nháp</span><span class="btn pri">Tiếp tục</span></div></div>""", "Ứng dụng của tôi")

# 17 Công bố API
P["17"] = ("Công bố API", "Ứng dụng của tôi", f"""
{head("Công bố API mới")}
{steps(["Đặc tả","Mô tả nghiệp vụ","Xác nhận"],0)}
<div class="card"><div class="field"><label>Đặc tả OpenAPI 3.1 <span class="star">*</span></label><div class="input" style="height:90px;justify-content:center">⬆ Kéo tệp .yaml/.json vào đây hoặc nhập địa chỉ HTTPS</div></div>
<div class="banner s">✓ Đã đọc đặc tả: 6 thao tác, 4 lược đồ. Cảnh báo: thao tác GET /ho-tich/{{ma}} thiếu ví dụ phản hồi.</div>
<div class="fg">{inp("Hệ thống cung cấp","HT-TUPHAP ▾",True)}{inp("Phân loại dữ liệu","Nội bộ ▾",True)}</div>{inp("Mô tả nghiệp vụ","Tra cứu giấy khai sinh theo số định danh",True)}
<div class="foot"><span class="btn">Lưu nháp</span><span class="btn pri">Tiếp tục</span></div></div>
<div class="card" style="margin-top:12px"><b>Hồ sơ công bố của tôi</b>{table(["Mã","API","Trạng thái","Gửi lúc"],[["PUB-0017","tra-cuu-ho-tich",tag(IN,"Chờ duyệt"),"24/11/2026"],["PUB-0009","cap-ban-sao",tag(OK,"Đã công bố"),"02/11/2026"]],"Hồ sơ công bố")}</div>""", "Ứng dụng của tôi")

# 18 Tổng quan cá nhân
P["18"] = ("Tổng quan cá nhân", "", f"""
{head("Tổng quan của tôi", '<span class="muted">Cập nhật 09:41</span>')}
{kpis([("Ứng dụng hoạt động","3","/ 10"),("Lượt thử hôm nay","412","hạn mức 3.000"),("Đăng ký chờ duyệt","1",""),("Thông tin xác thực sắp hết hạn","1","trong 7 ngày")])}
<div class="banner w">⚠ Khóa sbx-t68-datdai-thu-nghiem-1 hết hạn sau 6 ngày. <span class="sp"></span><span class="btn">Xoay vòng</span></div>
<div class="split"><div class="card"><b>Lượt thử 7 ngày</b><div class="vbars" style="margin-top:8px">{"".join(f'<div><i style="height:{h}px;background:#0b5cd5"></i></div>' for h in [60,80,50,110,95,40,130])}</div><div class="muted">Xem dạng bảng</div></div>
<div class="card"><b>Thay đổi dịch vụ tôi theo dõi</b>{table(["Dịch vụ","Thay đổi","Lúc"],[["tra-cuu-ho-tich","Ra v1.0.0","12/10"],["tra-cuu-llt","Báo ngừng 30/06/2027","20/11"]],"Thay đổi")}</div></div>
<div class="card" style="margin-top:12px"><b>Việc nên làm</b><div class="muted">Hoàn tất đăng ký SUB-0052 · Chấp nhận điều khoản v2.0 · Tạo bộ sưu tập thử</div></div>""", "")

# 19 Hộp thông báo và theo dõi
P["19"] = ("Hộp thông báo và theo dõi", "", f"""
{head("Thông báo", '<span class="btn">Đánh dấu tất cả đã đọc</span>')}{tabs(["Hộp thông báo 3","Đang theo dõi 4"],0)}
<div class="card">{table(["","Thông báo","Loại","Lúc"],[
["●","<b>tra-cuu-llt</b> sẽ ngừng ngày 30/06/2027","Lộ trình ngừng","20/11 14:02"],["●","Đăng ký SUB-0041 đã được duyệt","Đăng ký","18/11 09:15"],["●","Khóa sbx-…-1 hết hạn sau 7 ngày","Thông tin xác thực","19/11 07:00"],["○","tra-cuu-ho-tich ra phiên bản v1.0.0","Thay đổi API","12/10 10:30"]],"Hộp thông báo")}{foot("1–4 / 22")}</div>
<div class="card" style="margin-top:12px"><b>Đang theo dõi</b>{table(["Dịch vụ","Kênh","Loại thay đổi",""],[["tra-cuu-ho-tich","Trong cổng, Thư","Tất cả","Sửa · Bỏ theo dõi"],["tra-cuu-llt","Trong cổng","Ngừng, đổi phiên bản","Sửa · Bỏ theo dõi"]],"Theo dõi")}</div>""", "")

# 20 Hỗ trợ
P["20"] = ("Hỗ trợ và hỏi đáp", "Hỗ trợ", f"""
{head("Hỗ trợ", '<span class="btn pri">+ Gửi yêu cầu hỗ trợ</span>')}{facets(["Tất cả 4","Đang mở 2","Đã trả lời 1","Đã đóng 1"])}
<div class="lay2" style="grid-template-columns:minmax(0,1fr) 380px"><div class="card">{table(["Mã phiếu","Chủ đề","Loại","Trạng thái","Cập nhật"],[
[("<a class='mono'>HT-2026-0042</a>"),"Lỗi 422 khi thử POST /ho-tich/tra-cuu","Câu hỏi",tag(IN,"Đang mở"),"26/11 09:12"],["<a class='mono'>HT-2026-0038</a>","Thiếu ví dụ phản hồi ở GET /ho-tich/{ma}","Lỗi tài liệu",tag(OK,"Đã trả lời"),"24/11 16:40"],["<a class='mono'>HT-2026-0031</a>","Xin cấp quyền gọi production","Đề nghị truy cập",tag(MU,"Đã đóng"),"18/11"]],"Phiếu hỗ trợ")}</div>
<div class="card"><b>HT-2026-0042</b> {tag(IN,"Đang mở")}<div class="vtl" style="margin-top:10px"><div>Bạn · 09:12: Gửi thân đúng mẫu nhưng nhận 422…</div><div>Chủ dịch vụ · 10:05: Vui lòng gửi tryId.</div></div>{inp("Trả lời","",False)}<div class="foot"><span class="btn pri">Gửi</span></div></div></div>""", "Hỗ trợ")

# 21 Soạn trang nội dung
P["21"] = ("Soạn trang nội dung", "", f"""
<div class="muted">Quản trị cổng › Nội dung › bat-dau-nhanh-mtls</div>
<div class="chrome"><h1>Kết nối mTLS tới cổng API {tag(MU,"✎ Bản nháp")} <span class="muted" style="font-size:13px">tự lưu 09:40:12</span></h1><div style="display:flex;gap:8px;flex-wrap:wrap"><span class="muted">Hướng dẫn · vi · công khai trong cổng</span><span style="flex:1"></span><span class="btn">Lưu nháp</span><span class="btn pri">Gửi duyệt</span></div></div>
<div class="fg">{inp("Mã trang","bat-dau-nhanh-mtls",True,"",True)}{inp("Tiêu đề","Kết nối mTLS tới cổng API",True)}{inp("Đối tượng xem","Đã đăng nhập ▾",True)}{inp("Thẻ","mtls, bảo mật")}</div>
<div class="split"><div class="ed"># Kết nối mTLS

Hướng dẫn cấu hình **chứng thư máy khách**.

## 1. Chuẩn bị
- Tạo khóa riêng
- Gửi CSR cho quản trị

![Sơ đồ](anh/mtls.png)</div>
<div class="doc" style="min-height:260px"><h2>Kết nối mTLS</h2><p>Hướng dẫn cấu hình <b>chứng thư máy khách</b>.</p><h3>1. Chuẩn bị</h3><p>• Tạo khóa riêng<br>• Gửi CSR cho quản trị</p><div class="muted">Xem trước dùng cùng bộ lọc an toàn như khi đăng.</div></div></div>
<div class="muted" style="margin-top:8px">Kích thước 1,4 KB / 200 KB · ảnh đính kèm 1 (PNG ≤ 5 MB)</div>""", "", "Lê Thị Hoa", True)

# 22 Duyệt nội dung
P["22"] = ("Duyệt nội dung, quản lý trang", "", f"""
{head("Nội dung cổng")}{tabs(["Chờ duyệt 2","Tất cả trang","Đã đăng","Đã gỡ"],0)}
<div class="lay2" style="grid-template-columns:420px minmax(0,1fr)"><div class="card">{table(["Trang","Người gửi","Hạn duyệt"],[
[("<b>Kết nối mTLS tới cổng API</b><br><span class='mono muted'>v3 · bat-dau-nhanh-mtls</span>",),"Lê Thị Hoa","28/11"],["Xử lý lỗi RFC 9457<br><span class='mono muted'>v1 · xu-ly-loi</span>","Phạm Văn D","29/11"]],"Chờ duyệt")}</div>
<div class="card"><b>Kết nối mTLS tới cổng API</b> {tag(IN,"Chờ duyệt")} <span class="muted">· Người soạn: Lê Thị Hoa</span>
<div class="split" style="margin-top:10px"><div class="ed" style="min-height:130px">- Gửi CSR cho quản trị
+ Gửi CSR cho quản trị viên cổng
+ Thời hạn chứng thư tối đa 1 năm</div><div class="doc" style="padding:10px"><p><del>Gửi CSR cho quản trị</del> <ins>Gửi CSR cho quản trị viên cổng</ins></p></div></div>
<div class="banner i" style="margin-top:10px">Người duyệt phải khác người soạn và người gửi duyệt.</div>{inp("Nhận xét (bắt buộc khi từ chối)","")}<div class="foot"><span class="btn danger">Từ chối</span><span class="btn pri">Duyệt và đăng</span></div></div></div>""", "", "Phạm Thị E", True)

# 23 Khai báo sandbox
P["23"] = ("Khai báo sandbox và thử production", "", f"""
<div class="muted">Quản trị cổng › Dịch vụ › tra-cuu-ho-tich</div>
{head("Sandbox: Tra cứu hộ tịch", '<span class="input">v1.0.0 ▾</span>')}
<div class="split"><div class="card"><h3 style="margin:0 0 8px">Chế độ sandbox</h3><div class="facets"><span class="on">MOCK</span><span>BACKEND</span><span>TẮT</span></div>
<div class="fg">{inp("Cách chọn ví dụ","Ví dụ đầu tiên ▾",True)}{inp("Độ trễ giả (ms)","100")}</div><div class="banner s">✓ Đủ ví dụ cho 6/6 thao tác.</div>
<div class="muted">Chế độ BACKEND: địa chỉ HTTPS thuộc danh sách cho phép, đường kiểm tra sức khỏe, tiêu đề xác thực (ghi một chiều).</div><div class="foot"><span class="btn pri">Lưu</span></div></div>
<div class="card"><h3 style="margin:0 0 8px">Thử trên production {tag(MU,"Tắt")}</h3><div class="banner w">Chỉ GET, HEAD với dữ liệu Công khai, Nội bộ; cần người duyệt khác người đề xuất.</div>
{inp("Thời hạn bật (ngày)","30",True,"Tối đa 90 ngày.")}{inp("Lý do đề xuất","Kiểm thử tích hợp với HT-DATDAI trước nghiệm thu",True)}<div class="foot"><span class="btn">Tắt</span><span class="btn pri">Đề xuất bật</span></div></div></div>""", "", "Lê Văn C", True)

# 24 Quản trị tài khoản dh-dev
P["24"] = ("Quản trị tài khoản dh-dev và ứng dụng", "", f"""
{head("Tài khoản nhà thầu (dh-dev)")}{facets(["Chờ duyệt 3","Đang hoạt động 41","Bị khóa 1","Hết hạn 6"])}
<div class="card"><div class="toolbar"><span class="input" style="min-width:240px">🔍 Tìm thư, đơn vị</span><span class="input">Hạn duyệt: Tất cả ▾</span><div style="flex:1"></div><span class="muted">Hạn duyệt 3 ngày</span></div>
{table(["Người đăng ký","Đơn vị","Hợp đồng","Tổ chức giao việc","Đăng ký lúc","Trạng thái"],[
[("nguyen.van.an<br><span class='muted'>nguyen.van.an@congty-abc.vn</span>",),"Công ty ABC","HĐ 25/2026/SKHCN","SO-TUPHAP","25/11 08:30",tag(IN,"Chờ duyệt")],
["pham.van.k<br><span class='muted'>k@congty-xyz.vn</span>","Công ty XYZ","QĐ 112/2026","SO-TNMT","24/11 15:10",tag(WA,"Quá hạn 1 ngày")]],"Tài khoản dh-dev")}{foot("1–2 / 3")}</div>""", "", "Trần Văn Ba", True,
          False, drawer("Duyệt tài khoản", f"""<div class="muted">nguyen.van.an · Công ty ABC · HĐ 25/2026/SKHCN</div><div class="banner i" style="margin-top:8px">Thư đã xác minh 25/11 08:41. Tài khoản chỉ dùng sandbox.</div>
<div class="field"><label>Tenant được cấp</label><div class="input">T68 ▾</div></div>{inp("Nhận xét (bắt buộc khi từ chối)","")}<div class="foot"><span class="btn danger">Từ chối</span><span class="btn pri">Duyệt</span></div>""", 440))

# 25 Nhận diện và tham số
P["25"] = ("Nhận diện và tham số cổng", "", f"""
{head("Nhận diện và tham số cổng")}{tabs(["Nhận diện","Tham số"],0)}
<div class="split"><div class="card">{inp("Tên cổng","Cổng API Tỉnh T68",True)}{inp("Khẩu hiệu","Một cửa kết nối dữ liệu của tỉnh")}<div class="fg">{inp("Email hỗ trợ","hotro@t68.datahub.gov.vn",True)}{inp("Điện thoại hỗ trợ","1900 xxxx")}</div>
<div class="field"><label>Logo (PNG, WebP ≤ 512 KB, từ 128 px)</label><div class="input">⬆ logo-t68.png · 256×256 · 41 KB</div></div><div class="foot"><span class="btn">Hoàn tác</span><span class="btn pri">Lưu</span></div></div>
<div class="card raised"><b>Xem trước</b><div class="pt" style="position:static;margin:10px 0;border-radius:12px"><div class="logo"><b>Cổng API</b> Tỉnh T68</div><span class="sp"></span><span class="btn">Đăng nhập</span></div><div class="muted">Khẩu hiệu hiển thị ở trang chủ.</div></div></div>
<div class="card" style="margin-top:12px"><b>Tham số (15.*)</b>{table(["Khóa","Mặc định","Hiện tại","Miền"],[["<span class='mono'>15.public.enabled</span>","false","<b>false</b>","bật, tắt"],["<span class='mono'>15.try.rate-per-user-min</span>","30","<b>30</b>","5…120"],["<span class='mono'>15.cred.ttl-days</span>","90","<b>90</b>","30…180"]],"Tham số")}</div>""", "", "Trần Văn Ba", True)

# 26 Nhật ký truy cập
P["26"] = ("Nhật ký truy cập, thử, báo cáo", "", f"""
{head("Nhật ký và báo cáo", '<span class="btn">⬇ Xuất CSV</span>')}{tabs(["Nhật ký","Báo cáo sử dụng"],0)}
<div class="card"><div class="toolbar"><span class="input">Từ 20/11 đến 26/11</span><span class="input">Hành động: TRY_API ▾</span><span class="input">Người dùng: Tất cả ▾</span><span class="input">Kết quả ▾</span><div style="flex:1"></div><span class="btn">Xóa bộ lọc</span></div>
{table(["Lúc","Người dùng","Hành động","Đối tượng","Kết quả","Mã vết"],[
["26/11 09:41:07","nguyen.van.an","TRY_API","tra-cuu-ho-tich · sandbox",tag(OK,"OK"),"<span class='mono'>4bf9…a1</span>"],["26/11 09:38:51","nguyen.van.an","TRY_API","tra-cuu-ho-tich · sandbox",tag(ER,"DENIED"),"<span class='mono'>4bf8…77</span>"],["26/11 08:02:15","tran.thi.b","DOWNLOAD_SPEC","tra-cuu-thua-dat v2.1.0",tag(OK,"OK"),"<span class='mono'>3ac1…0e</span>"],["25/11 16:20:44","pham.van.k","SECRET_ISSUED","app-demo",tag(OK,"OK"),"<span class='mono'>2de0…5b</span>"]],"Nhật ký")}{foot("1–4 / 1.236")}</div>""", "", "Đỗ Văn An (kiểm toán)", True)

# 27 Đồng bộ, đối soát, di trú
P["27"] = ("Đồng bộ, đối soát, di trú", "", f"""
{head("Đồng bộ, đối soát và di trú")}{tabs(["Đồng bộ","Đối soát","Di trú hệ cũ"],0)}
{kpis([("Trạng thái","Rảnh",tag(OK,"✓ Bình thường")),("Lần đồng bộ gần nhất","09:36","trễ 4 phút"),("Mục danh mục","48","khớp PH-02"),("Lỗi 24 giờ","0","")])}
<div class="card"><div class="toolbar"><b>Lần chạy gần đây</b><div style="flex:1"></div><span class="btn">Đối soát với PH-02</span><span class="btn pri">Đồng bộ lại toàn bộ</span></div>
{table(["Lần chạy","Loại","Bắt đầu","Số mục","Kết quả"],[["RUN-1042","Gia tăng","09:36","3",tag(OK,"✓ Xong")],["RUN-1041","Gia tăng","09:31","0",tag(OK,"✓ Xong")],["RUN-1038","Đối soát","08:00","48",tag(WA,"1 lệch")]],"Lần chạy")}</div>
<div class="card" style="margin-top:12px"><b>Di trú portal Gravitee</b><div class="muted">Tải gói ZIP (≤ 50 MB) gồm trang, tài liệu, ảnh → xem trước → xác nhận.</div>{steps(["Tải gói","Xem trước","Xác nhận"],1)}<div class="banner w">⚠ 2 tệp không hợp lệ bị bỏ qua (SVG). 31 trang sẽ tạo ở trạng thái Bản nháp.</div></div>""", "", "Trần Văn Ba", True)

# 28 Hộp xử lý hỗ trợ
P["28"] = ("Hộp xử lý hỗ trợ", "", f"""
{head("Hộp hỗ trợ")}{facets(["Mở 5","Đã trả lời 2","Đã giải quyết 10","Đóng 24"])}
<div class="lay2" style="grid-template-columns:480px minmax(0,1fr)"><div class="card">{table(["Phiếu","Dịch vụ","Hạn phản hồi"],[
[("<b>HT-2026-0042</b><br>Lỗi 422 khi thử POST",),"tra-cuu-ho-tich",tag(WA,"còn 2 giờ")],["<b>HT-2026-0043</b><br>Xin cấp quyền production","tra-cuu-thua-dat",tag(OK,"còn 20 giờ")],["<b>HT-2026-0040</b><br>Báo lỗi tài liệu","tra-cuu-ho-tich",tag(ER,"quá 3 giờ")]],"Hàng đợi")}</div>
<div class="card"><b>HT-2026-0042</b> {tag(IN,"Đang mở")}<div class="muted">Từ nguyen.van.an (Công ty ABC) · nhận: Sở Tư pháp</div><div class="vtl" style="margin-top:10px"><div>nguyen.van.an · 09:12: Gửi thân đúng mẫu nhưng nhận 422.</div><div>Ghi chú nội bộ: kiểm tra lược đồ v1.0.0.</div></div>
{inp("Trả lời","Vui lòng gửi tryId TR-8F1A.")}<div class="foot"><span class="btn">Ghi chú nội bộ</span><span class="btn">Đã giải quyết</span><span class="btn pri">Gửi trả lời</span></div></div></div>""", "", "Lê Văn C", True)

MOBILE = ["01", "04", "06", "08", "12", "13"]
for code, v in P.items():
    title, _c, body = v[0], v[1], v[2]
    nav = v[3] if len(v) > 3 else None
    user = v[4] if len(v) > 4 and v[4] else "Nguyễn Văn An"
    admin = v[5] if len(v) > 5 else False
    anon = v[6] if len(v) > 6 else False
    extra = v[7] if len(v) > 7 else ""
    (OUT / f"ui-15-{code}.html").write_text(shell(code, title, body, nav, user, admin, anon, extra), encoding="utf-8")
print("Đã sinh", len(P), "trang; ảnh 360 px cho", ", ".join(MOBILE))
