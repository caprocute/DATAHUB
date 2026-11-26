#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh minh họa của PH-02 (UI-02-01 danh mục API, UI-02-05 so sánh phiên bản).
Dùng hifi.css (sao từ ph19/hifi). Chạy: python3 gen_hifi.py && node shot.js
Dữ liệu trên ảnh là dữ liệu minh họa, không phải dữ liệu thật của tỉnh nào."""
import pathlib

OUT = pathlib.Path(__file__).parent
NAV = [("Kết nối & API", [("Danh mục API", "api"), ("Gói sử dụng", "goi"), ("Đăng ký sử dụng", "dk"), ("Đồng bộ quốc gia", "sync"), ("Tuân thủ SLA", "sla")]),
       ("Quản trị dịch vụ", [("Phân loại và thẻ", "pl"), ("Bộ luật kiểm tra", "luat"), ("Nhập từ APIM cũ", "nhap"), ("Cài đặt và đối soát", "cd")])]


def shell(code, active, title, crumb, body, extra=""):
    nav = "".join(f'<div class="grp">{g}</div>' + "".join(f'<a class="{"on" if active == k else ""}" href="#">{n}</a>' for n, k in items) for g, items in NAV)
    viec = f'<a class="{"on" if active == "viec" else ""}" href="#">Việc của tôi <span class="tag t-info">4</span></a>'
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-02-{code} · {title}</title><link rel="stylesheet" href="hifi.css"><style>.vbars>div{{align-self:stretch}}.code{{overflow:hidden}}</style></head><body>
<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Kết nối &amp; API</div><div class="search">Tìm API, gói, HTTT…  ⌘K</div><div class="sp"></div>
<span class="tray">Tỉnh mẫu T68</span><span class="avatar">LH</span></header>
<nav class="side" aria-label="Điều hướng chính">{nav}<div class="grp">Cá nhân</div>{viec}</nav>
<main><div class="crumb">{crumb}</div>{body}</main></div>{extra}<div class="hint">Bản hi-fi minh họa · D03-06-PH02 · UI-02-{code}</div></body></html>"""


def rows(data):
    return "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in data)


UI01 = """
<div class="head"><h1>Danh mục API</h1><div class="sp"></div><span class="btn">Nhập từ APIM cũ</span><span class="btn">Xuất CSV</span><span class="btn pri">+ Đăng ký API</span></div>
<div class="stats"><div class="stat on"><b>186</b><span>Tất cả API</span></div><div class="stat"><b>141</b><span>Đang chạy</span></div><div class="stat"><b style="color:#7a5200">4</b><span>Chờ duyệt</span></div><div class="stat"><b style="color:#7a5200">9</b><span>Sắp ngừng</span></div><div class="stat"><b style="color:#a11a1a">3</b><span>Cần chú ý</span></div></div>
<div class="card"><div class="toolbar"><span class="input" style="min-width:260px">Tìm mã, tên, mô tả, HTTT</span><span class="input">Nhóm: Tất cả ▾</span><span class="input">Phân loại: Tất cả ▾</span><span class="input">Trạng thái: Đang chạy ▾</span><span class="input">Hiển thị: Tất cả ▾</span><div style="flex:1"></div><span class="muted">Sắp xếp: cần chú ý trước</span></div>
<table aria-label="Danh sách API"><thead><tr><th>Mã · Tên</th><th>HTTT cung cấp</th><th>Phân loại</th><th>Hiển thị</th><th>Phiên bản · Trạng thái</th><th>Đăng ký</th><th>SLA kỳ 10/2026</th><th>Cập nhật</th></tr></thead><tbody>""" + rows([
    ["<span class='mono'>ho-so-dat-dai</span><br><span class='muted'>Tra cứu hồ sơ đất đai</span>", "HT-DATDAI<br><span class='muted'>Sở TN&amp;MT</span>", "<span class='tag t-err'>Hạn chế</span>", "Quốc gia", "2.0.0 <span class='tag t-ok'>Đang chạy</span><br><span class='muted'>1.4.0 Sắp ngừng 03/2027</span>", "14", "<span style='color:#a11a1a'>Không đạt · 3 kỳ ⚠</span>", "26/11/2026 08:40"],
    ["<span class='mono'>tra-cuu-ho-tich</span><br><span class='muted'>Tra cứu thông tin hộ tịch</span>", "HT-TUPHAP<br><span class='muted'>Sở Tư pháp</span>", "<span class='tag t-err'>Hạn chế</span>", "Quốc gia", "1.2.0 <span class='tag t-ok'>Đang chạy</span>", "12", "<span style='color:#0b6b3a'>Đạt · 99,82%</span>", "25/11/2026 16:12"],
    ["<span class='mono'>dang-ky-kinh-doanh</span><br><span class='muted'>Thông tin đăng ký doanh nghiệp</span>", "HT-DKKD<br><span class='muted'>Sở KH&amp;ĐT</span>", "<span class='tag t-info'>Nội bộ</span>", "Trong tỉnh", "3.1.0 <span class='tag t-ok'>Đang chạy</span>", "21", "<span style='color:#0b6b3a'>Đạt · 99,95%</span>", "24/11/2026 10:05"],
    ["<span class='mono'>danh-muc-don-vi</span><br><span class='muted'>Danh mục đơn vị hành chính</span>", "HT-NEN<br><span class='muted'>Trung tâm CNTT</span>", "<span class='tag t-ok'>Công khai</span>", "Công khai", "1.0.0 <span class='tag t-ok'>Đang chạy</span>", "37", "<span style='color:#0b6b3a'>Đạt · 99,99%</span>", "20/11/2026 09:30"],
    ["<span class='mono'>thong-ke-dan-cu</span><br><span class='muted'>Thống kê dân cư theo xã</span>", "HT-DANCU<br><span class='muted'>Công an tỉnh</span>", "<span class='tag t-err'>Hạn chế</span>", "Trong tỉnh", "0.9.0 <span class='tag t-warn'>Chờ duyệt</span>", "0", "<span class='muted'>Chưa công bố</span>", "26/11/2026 07:55"],
    ["<span class='mono'>bao-hiem-xa-hoi</span><br><span class='muted'>Tra cứu quá trình đóng BHXH</span>", "HT-BHXH<br><span class='muted'>BHXH tỉnh</span>", "<span class='tag t-err'>Hạn chế</span>", "Trong tỉnh", "1.0.0 <span class='tag t-mute'>Bản nháp</span>", "0", "<span class='muted'>Chưa công bố</span>", "23/11/2026 14:21"],
]) + """</tbody></table><div class="foot" style="justify-content:space-between"><span class="muted">Hiển thị 1–6 / 186 · cờ ⚠ là API có SLA không đạt, đồng bộ quốc gia lỗi hoặc gateway lệch</span><span class="muted">‹ Trước · Sau › · 20 / trang</span></div></div>"""

UI05 = """
<div class="head"><h1>So sánh phiên bản · ho-so-dat-dai</h1><span class="tag t-err">Có thay đổi phá vỡ</span><div class="sp"></div><span class="btn">Xem đặc tả song song</span><span class="btn pri">Tạo lộ trình ngừng dùng</span></div>
<div class="toolbar" style="margin-bottom:12px"><span class="input">Từ: 1.4.0 (Sắp ngừng) ▾</span><span class="muted">→</span><span class="input">Đến: 2.0.0 (Nháp) ▾</span><div style="flex:1"></div><span class="muted">Đề xuất số phiên bản: <b>2.0.0</b> (tăng số chính)</span></div>
<div class="warn"><b>Phá vỡ tương thích.</b> Phiên bản 2.0.0 có 3 thay đổi phá vỡ. Số chính phải tăng (đã đúng) và nên chạy song song với 1.4.0 ít nhất 180 ngày. <b>5 HTTT</b> đang gọi các thao tác bị ảnh hưởng.</div>
<div class="grid2" style="display:grid;grid-template-columns:1.9fr 1fr;gap:14px;align-items:start"><div class="card"><div style="padding:12px 14px"><b>Thay đổi (7)</b></div><table aria-label="Thay đổi giữa hai phiên bản"><thead><tr><th style='width:110px'>Loại</th><th style='width:250px'>Vị trí</th><th>Mô tả và tác động</th></tr></thead><tbody>""" + rows([
    ["<span class='tag t-err'>Phá vỡ</span>", "<span class='mono'>GET /thua-dat/{id}</span> phản hồi", "Xóa trường <span class='mono'>soGiayChungNhan</span>. Bên đang đọc trường này sẽ lỗi."],
    ["<span class='tag t-err'>Phá vỡ</span>", "<span class='mono'>POST /thua-dat:tra-cuu</span> yêu cầu", "Thêm trường bắt buộc <span class='mono'>mucDichSuDung</span>. Lời gọi cũ bị từ chối 400."],
    ["<span class='tag t-err'>Phá vỡ</span>", "<span class='mono'>GET /thua-dat</span> mã lỗi", "Đổi mã lỗi <span class='mono'>404</span> thành <span class='mono'>422</span> khi không đủ điều kiện tra cứu."],
    ["<span class='tag t-warn'>Cần xác nhận</span>", "<span class='mono'>loaiDat</span> phản hồi", "Mở rộng danh sách giá trị (thêm 4 mã). Bên xử lý chặt có thể lỗi."],
    ["<span class='tag t-ok'>Tương thích</span>", "<span class='mono'>GET /thua-dat/{id}</span> phản hồi", "Thêm trường tùy chọn <span class='mono'>ngayCapNhat</span>."],
    ["<span class='tag t-ok'>Tương thích</span>", "Đường dẫn mới", "Thêm <span class='mono'>GET /thua-dat/{id}/lich-su</span>."],
    ["<span class='tag t-ok'>Tương thích</span>", "Mô tả, ví dụ", "Sửa 12 mô tả tiếng Việt, thêm 6 ví dụ."],
]) + """</tbody></table></div>
<div class="card"><div style="padding:12px 14px"><b>Bên bị ảnh hưởng</b> <span class="muted">· 30 ngày gần nhất</span></div><table aria-label="Bên khai thác bị ảnh hưởng"><thead><tr><th>HTTT</th><th>Lượt gọi</th><th>Thao tác</th></tr></thead><tbody>""" + rows([
    ["HT-MOTCUA<br><span class='muted'>VP UBND tỉnh</span>", "184.320", "2 / 3"],
    ["HT-DKKD<br><span class='muted'>Sở KH&amp;ĐT</span>", "41.775", "1 / 3"],
    ["HT-THUE<br><span class='muted'>Cục Thuế tỉnh</span>", "27.630", "2 / 3"],
    ["HT-XAYDUNG<br><span class='muted'>Sở Xây dựng</span>", "9.412", "1 / 3"],
    ["HT-NOTARY<br><span class='muted'>Sở Tư pháp</span>", "1.208", "1 / 3"],
]) + """</tbody></table><div class="foot" style="justify-content:space-between"><span class="muted">9 HTTT khác đăng ký nhưng không gọi thao tác bị ảnh hưởng</span><span class="btn">Xuất danh sách</span></div></div></div>"""



# ---- Hàm dựng nhanh dùng cho các màn còn lại ----
def tg(k, t):
    return f"<span class='tag t-{k}'>{t}</span>"


def m(t):
    return f"<span class='mono'>{t}</span>"


def mu(t):
    return f"<span class='muted'>{t}</span>"


def tb(label, heads, data, cls=""):
    th = "".join(f"<th>{h}</th>" for h in heads)
    return f'<table aria-label="{label}"{cls}><thead><tr>{th}</tr></thead><tbody>{rows(data)}</tbody></table>'


def hd(title, tags="", btns=""):
    return f'<div class="head"><h1>{title}</h1>{tags}<div class="sp"></div>{btns}</div>'


def btn(t, k=""):
    return f'<span class="btn {k}">{t}</span>'


def inp(t):
    return f'<span class="input">{t}</span>'


def tabs(items, on):
    return '<div class="tabs">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def steps(items, on):
    return '<div class="steps">' + "".join(f'<div class="{"done" if i < on else ("on" if i == on else "")}">{"✓ " if i < on else f"{i + 1}. "}{t}</div>' for i, t in enumerate(items)) + "</div>"


def pager(txt):
    return f'<div class="foot" style="justify-content:space-between"><span class="muted">{txt}</span><span class="muted">‹ Trước · Sau › · 20 / trang</span></div>'


OK, WN, ER, IN, MT = "ok", "warn", "err", "info", "mute"

UI02 = hd("ho-so-dat-dai · Tra cứu hồ sơ đất đai", tg(OK, "2.0.0 Đang chạy") + tg(WN, "1.4.0 Sắp ngừng"), btn("Tạm ngừng") + btn("Chuyển chủ quản") + btn("Gửi duyệt bản mới", "pri")) + """
<div class="alert w"><span>⚠ Phiên bản 2.0.0 có SLA không đạt 3 kỳ liên tiếp (99,41% so với cam kết 99,90%). Đã báo người duyệt dịch vụ.</span><span class="sp"></span><span class="btn">Xem tuân thủ SLA</span></div>
""" + tabs(["Tổng quan", "Phiên bản (2)", "Backend (2)", "Gói sử dụng (3)", "Đăng ký (14)", "Thống kê", "SLA", "Lịch sử"], 0) + """
<div class="grid3"><div class="card"><dl class="dl"><dt>Mã API</dt><dd>""" + m("ho-so-dat-dai") + """</dd><dt>Chủ quản</dt><dd>Sở TN&amp;MT · HT-DATDAI</dd><dt>Context-path</dt><dd>""" + m("/dat-dai/v2") + """</dd><dt>Phân loại</dt><dd>Đất đai · """ + tg(ER, "Hạn chế") + """</dd><dt>Hiển thị</dt><dd>Quốc gia (đã đồng bộ 26/11 06:00)</dd><dt>Xác thực</dt><dd>OAuth2 client credentials</dd><dt>Thẻ</dt><dd>tra-cuu · dia-chinh · NDXP</dd><dt>Kiểm tra đặc tả</dt><dd>""" + tg(OK, "Đạt") + """ 0 lỗi · 2 cảnh báo</dd></dl>
<div style="margin-top:14px"><b>Backend</b></div>""" + tb("Backend của phiên bản", ["Mã", "Đích", "Tỷ trọng", "Sức khỏe", "p95"], [
    [m("be-dat-dai-01"), m("https://datdai-a.tnmt.local:8443"), "50%", tg(OK, "Tốt"), "182 ms"], [m("be-dat-dai-02"), m("https://datdai-b.tnmt.local:8443"), "50%", tg(WN, "Suy giảm"), "611 ms"]]) + """</div>
<div><div class="card"><b>Cách gọi</b><div class="code" style="margin-top8px;margin-top:8px">curl -X POST \\
  api.t68.example/dat-dai/v2/thua-dat:tra-cuu \\
  -H "Authorization: Bearer $TOKEN" \\
  -H "Content-Type: application/json" \\
  -d '{"soTo":12,"soThua":345}'</div><div class="foot"><span class="btn">Sao chép</span><span class="btn">Tải OpenAPI 3.1</span></div></div>
<div class="card" style="margin-top:12px"><b>Đã sử dụng 30 ngày</b><div class="vbars" style="height:70px"><div><i style="height:40%;background:var(--color-primary)"></i></div><div><i style="height:55%;background:var(--color-primary)"></i></div><div><i style="height:48%;background:var(--color-primary)"></i></div><div><i style="height:80%;background:var(--color-primary)"></i></div><div><i style="height:70%;background:var(--color-primary)"></i></div><div><i style="height:62%;background:var(--color-primary)"></i></div></div><span class="muted">412.300 lượt gọi · 14 HTTT</span></div></div></div>"""

UI03 = hd("Đăng ký API mới", "", btn("Lưu nháp") + btn("‹ Quay lại") + btn("Tiếp tục ›", "pri")) + steps(["Thông tin", "Đặc tả", "Kiểm tra, xem trước", "Backend, gói", "Rà soát"], 2) + """
<div class="alert e"><span>Đặc tả còn <b>2 lỗi</b> theo quy ước nền tảng và <b>1 chuỗi giống bí mật</b>. Sửa rồi kiểm tra lại, bước tiếp theo đang bị khóa.</span></div>
<div class="grid3" style="grid-template-columns:minmax(0,1.5fr) minmax(0,1fr)"><div class="card" style="padding:0"><div style="padding:10px 14px;border-bottom:1px solid var(--color-border)"><b>Đặc tả OpenAPI</b> <span class="muted">· dán · 128 dòng · kiểm tra không lưu 0,8 giây trước</span></div><div class="code" style="border-radius:0 0 12px 12px;min-height:430px">  <span style="color:#7aa2d6">11</span>  /thua-dat/{id}:
  <span style="color:#7aa2d6">12</span>    get:
  <span style="color:#7aa2d6">13</span>      operationId: layThuaDat
<span style="background:#5a1e1e;display:block">  <span style="color:#7aa2d6">14</span>      summary:                    ← thiếu mô tả</span>  <span style="color:#7aa2d6">15</span>      responses:
  <span style="color:#7aa2d6">16</span>        '200': {description: Thành công}
<span style="background:#5a1e1e;display:block">  <span style="color:#7aa2d6">17</span>        '400': {description: Lỗi}   ← thiếu mẫu lỗi RFC 9457</span>  <span style="color:#7aa2d6">18</span>  /thua-dat:tra-cuu:
  <span style="color:#7aa2d6">19</span>    post:
<span style="background:#5a4a1e;display:block">  <span style="color:#7aa2d6">24</span>        example: "Bearer eyJhbGciOi●●●●●●●●"   ← giống bí mật</span>  <span style="color:#7aa2d6">25</span>      security: [{oauth2: [dat-dai.read]}]</div></div>
<div class="card"><b>Phát hiện (3)</b>""" + tb("Phát hiện kiểm tra", ["Mức", "Luật", "Vị trí"], [
    [tg(ER, "Lỗi"), "Q-ERR-01 Lỗi phải theo RFC 9457", m("dòng 17")], [tg(ER, "Lỗi"), "Q-DOC-02 Thiếu mô tả thao tác", m("dòng 14")], [tg(WN, "Bí mật"), "S-TOKEN Chuỗi giống token", m("dòng 24")]]) + """
<div style="margin-top:12px"><b>Xem trước</b> <span class="muted">· 3 đường dẫn, 2 thao tác</span></div><div class="vtl"><div>GET <span class="mono">/dat-dai/v2/thua-dat/{id}</span> · layThuaDat</div><div>POST <span class="mono">/dat-dai/v2/thua-dat:tra-cuu</span> · traCuuThuaDat</div></div>
<div class="warn" style="margin-top:8px"><b>API gần giống:</b> <span class="mono">tra-cuu-thua-dat</span> (HT-DATDAI, độ giống 86%)</div></div></div>"""

UI04 = hd("Kết quả kiểm tra · ho-so-dat-dai 2.0.0", tg(ER, "Chưa đạt"), btn("Chấp nhận cảnh báo") + btn("Kiểm tra lại", "pri")) + """
<div class="kpis" style="--n:4"><div class="kpi"><b style="color:#a11a1a">2</b><span>Lỗi (chặn gửi duyệt)</span></div><div class="kpi"><b style="color:#7a5200">5</b><span>Cảnh báo</span></div><div class="kpi"><b style="color:#a11a1a">1</b><span>Bí mật nghi ngờ</span></div><div class="kpi"><b>86%</b><span>Độ giống API gần nhất</span></div></div>
<div class="grid3" style="grid-template-columns:minmax(0,1.3fr) minmax(0,1fr)"><div class="card" style="padding:0"><div class="facets" style="padding:10px 14px 0"><span class="on">Tất cả 8</span><span>Lớp 1 · OpenAPI 0</span><span>Lớp 2 · Quy ước 7</span><span>Bí mật 1</span></div>""" + tb("Danh sách phát hiện", ["Mức", "Lớp", "Luật và thông điệp", "Vị trí", ""], [
    [tg(ER, "Lỗi"), "2", "<b>Q-ERR-01</b> Phản hồi lỗi phải theo RFC 9457", m("dòng 17"), "Đi tới"], [tg(ER, "Lỗi"), "2", "<b>Q-DOC-02</b> Thao tác thiếu mô tả", m("dòng 14"), "Đi tới"], [tg(ER, "Bí mật"), "3", "<b>S-TOKEN</b> Giá trị giống token (đuôi đã che)", m("dòng 24"), "Đề nghị không phải bí mật"],
    [tg(WN, "Cảnh báo"), "2", "<b>Q-NAME-04</b> Tên tham số nên theo camelCase", m("dòng 31"), "Chấp nhận"], [tg(WN, "Cảnh báo"), "2", "<b>Q-EX-01</b> Thiếu ví dụ phản hồi 200", m("dòng 16"), "Chấp nhận"]]) + """</div>
<div class="card"><b>Đặc tả</b> <span class="muted">· dòng 14–17</span><div class="code" style="margin-top:8px">  13      operationId: layThuaDat
<span style="background:#5a1e1e;display:block">  14      summary:</span>  15      responses:
  16        '200': {description: Thành công}
<span style="background:#5a1e1e;display:block">  17        '400': {description: Lỗi}</span>  18  /thua-dat:tra-cuu:</div><div class="warn" style="margin-top:10px"><b>Cách sửa.</b> Khai báo <span class="mono">content: application/problem+json</span> theo lược đồ <span class="mono">Problem</span> trong mẫu nền tảng.</div></div></div>"""

UI06 = hd("Gói sử dụng", "", btn("Xuất CSV") + btn("Tạo gói", "pri")) + """<div class="card"><div class="toolbar">""" + inp("Tìm mã gói, tên, API") + inp("API: Tất cả ▾") + inp("Trạng thái: Tất cả ▾") + inp("Xác thực: Tất cả ▾") + """</div>""" + tb("Danh sách gói sử dụng", ["Mã gói · Tên", "API · Phiên bản", "Xác thực", "Hạn mức", "Trạng thái", "Đăng ký", "Cập nhật", ""], [
    [m("dd-tra-cuu-co-ban") + "<br>" + mu("Tra cứu cơ bản"), "ho-so-dat-dai · 2.0.0", "OAuth2", "60 yêu cầu/phút", tg(OK, "Đang công bố"), "11", "26/11/2026", "⋯"],
    [m("dd-tra-cuu-nang-cao") + "<br>" + mu("Tra cứu nâng cao"), "ho-so-dat-dai · 2.0.0", "OAuth2 + mTLS", "300 yêu cầu/phút", tg(WN, "Đang soạn"), "0", "26/11/2026", "⋯"],
    [m("dd-tra-cuu-co-ban") + "<br>" + mu("Tra cứu cơ bản"), "ho-so-dat-dai · 1.4.0", "OAuth2", "60 yêu cầu/phút", tg(MT, "Ngừng khuyến nghị"), "3", "02/09/2026", "⋯"],
    [m("ho-tich-chung") + "<br>" + mu("Dùng chung nội bộ"), "tra-cuu-ho-tich · 1.2.0", "API key", "120 yêu cầu/phút", tg(OK, "Đang công bố"), "12", "14/11/2026", "⋯"],
    [m("dkkd-mo-rong") + "<br>" + mu("Mở rộng"), "dang-ky-kinh-doanh · 3.1.0", "OAuth2", "200 yêu cầu/phút", tg(OK, "Đang công bố"), "21", "24/11/2026", "⋯"],
    [m("dancu-thu-nghiem") + "<br>" + mu("Thử nghiệm"), "thong-ke-dan-cu · 0.9.0", "mTLS", "30 yêu cầu/phút", tg(MT, "Đã đóng"), "0", "10/10/2026", "⋯"]]) + pager("Hiển thị 1–6 / 34 gói") + "</div>"

UI07 = hd("Tạo gói sử dụng", tg(MT, "Đang soạn"), btn("Hủy") + btn("Lưu nháp") + btn("Lưu và gửi duyệt", "pri")) + """<div class="grid3" style="grid-template-columns:minmax(0,1.3fr) minmax(0,1fr)"><div>
<div class="card"><b>Thông tin</b><div class="field" style="margin-top:8px"><label>Mã gói *</label><span class="input">dd-tra-cuu-nang-cao</span></div><div class="field"><label>Tên hiển thị *</label><span class="input">Tra cứu nâng cao</span></div><div class="field"><label>Đối tượng được xin</label><span class="input">HTTT cùng tỉnh, cơ quan trung ương ▾</span></div><div class="field"><label>Điều kiện truy cập</label><span class="input" style="height:54px;align-items:flex-start;padding-top:6px">Chỉ HTTT đã hoàn tất kết nạp và có văn bản đề nghị của thủ trưởng đơn vị.</span></div></div>
<div class="card" style="margin-top:12px"><b>Kiểu xác thực</b><div class="facets" style="margin-top:8px"><span>API key</span><span>OAuth2</span><span class="on">OAuth2 + mTLS</span><span>mTLS</span></div><div class="warn">Dữ liệu mức <b>Hạn chế</b> chỉ cho OAuth2 trở lên (ERR-02-022 nếu chọn API key).</div></div></div>
<div><div class="card"><b>Hạn mức</b><div class="field" style="margin-top:8px"><label>Số yêu cầu mỗi phút</label><span class="input">300</span></div><div class="field"><label>Số yêu cầu mỗi ngày</label><span class="input">200.000</span></div><div class="field"><label>Kích thước phản hồi tối đa</label><span class="input">5 MB</span></div></div>
<div class="card" style="margin-top:12px"><b>Đường dẫn cho phép</b>""" + tb("Đường dẫn cho phép", ["Thao tác", "Đường dẫn", ""], [["GET", m("/thua-dat/{id}"), "✕"], ["POST", m("/thua-dat:tra-cuu"), "✕"], ["GET", m("/thua-dat/{id}/lich-su"), "✕"]]) + """<div style="margin-top:8px"><span class="btn">+ Thêm từ đặc tả</span></div></div></div></div>"""

UI08 = hd("Đăng ký sử dụng", "", btn("Xuất CSV") + btn("Đăng ký API cho HTTT", "pri")) + """<div class="facets"><span class="on">Theo API</span><span>Theo HTTT</span><span style="margin-left:14px">Tất cả 62</span><span>Chờ duyệt 4</span><span>Đang hiệu lực 51</span><span>Tạm ngừng 2</span><span>Sắp hết hạn 5</span></div><div class="card"><div class="toolbar">""" + inp("Tìm HTTT, API, gói") + inp("API: ho-so-dat-dai ▾") + inp("Gói: Tất cả ▾") + inp("Cấp quyền: Tất cả ▾") + """</div>""" + tb("Danh sách đăng ký sử dụng", ["HTTT khai thác", "API · Gói", "Trạng thái", "Cấp phạm vi", "Hiệu lực đến", "Lượt gọi 30 ngày", ""], [
    ["HT-MOTCUA<br>" + mu("VP UBND tỉnh"), "ho-so-dat-dai · cơ bản", tg(OK, "Hiệu lực"), tg(OK, "Đã cấp"), "31/12/2027", "184.320", "⋯"],
    ["HT-DKKD<br>" + mu("Sở KH&amp;ĐT"), "ho-so-dat-dai · cơ bản", tg(OK, "Hiệu lực"), tg(OK, "Đã cấp"), "30/06/2027", "41.775", "⋯"],
    ["HT-XAYDUNG<br>" + mu("Sở Xây dựng"), "ho-so-dat-dai · nâng cao", tg(WN, "Chờ duyệt"), tg(MT, "Chưa cấp"), "—", "0", "Duyệt"],
    ["HT-THUE<br>" + mu("Cục Thuế tỉnh"), "ho-so-dat-dai · cơ bản", tg(OK, "Hiệu lực"), tg(WN, "Đang cấp lại"), "15/03/2027", "27.630", "⋯"],
    ["HT-NOTARY<br>" + mu("Sở Tư pháp"), "ho-so-dat-dai · cơ bản", tg(MT, "Tạm ngừng"), tg(OK, "Đã cấp"), "30/09/2027", "0", "Tiếp tục"],
    ["HT-HOTICH<br>" + mu("Sở Tư pháp"), "ho-so-dat-dai · cơ bản", tg(ER, "Hết hạn"), tg(MT, "Đã thu"), "01/11/2026", "1.208", "Gia hạn"]]) + pager("Hiển thị 1–6 / 62") + "</div>"

UI09_BG = """<div class="head"><h1>Đăng ký sử dụng</h1></div><div class="card" style="opacity:.55">""" + tb("Nền", ["HTTT khai thác", "API · Gói", "Trạng thái"], [["HT-MOTCUA", "ho-so-dat-dai · cơ bản", tg(OK, "Hiệu lực")], ["HT-DKKD", "ho-so-dat-dai · cơ bản", tg(OK, "Hiệu lực")], ["HT-THUE", "ho-so-dat-dai · cơ bản", tg(OK, "Hiệu lực")]]) + "</div>"
UI09 = UI09_BG
UI09X = """<div class="drawer" style="width:520px;top:56px"><div class="head" style="margin-bottom:10px"><h1 style="font-size:18px">Đăng ký sử dụng API</h1><div class="sp"></div><span class="muted">✕</span></div>
<div class="field"><label>API và gói *</label><span class="input">ho-so-dat-dai 2.0.0 · Tra cứu nâng cao ▾</span></div>
<div class="field"><label>HTTT khai thác *</label><span class="input">HT-XAYDUNG · Sở Xây dựng ▾</span></div>
<div class="field"><label>Mục đích sử dụng *</label><span class="input" style="height:54px;align-items:flex-start;padding-top:6px">Đối chiếu thửa đất khi thẩm định hồ sơ cấp phép xây dựng.</span></div>
<div style="display:flex;gap:10px"><div class="field" style="flex:1"><label>Khối lượng dự kiến *</label><span class="input">8.000 lượt/ngày</span></div><div class="field" style="flex:1"><label>Căn cứ pháp lý *</label><span class="input">NĐ 15/2021 Điều 9</span></div></div>
<div class="warn">Gói yêu cầu <b>duyệt</b>. Hệ thống gửi yêu cầu tới người duyệt dịch vụ của Sở TN&amp;MT, dự kiến xử lý trong 3 ngày làm việc.</div>
<div class="alert e" style="margin-top:10px"><span>HTTT đã có đăng ký hiệu lực cho phiên bản này (ERR-02-027).</span></div>
<div class="field" style="margin-top:8px"><label><b>☑</b> Tôi xác nhận điều khoản sử dụng dữ liệu hạn chế *</label></div>
<div class="foot"><span class="btn">Hủy</span><span class="btn pri">Gửi đăng ký</span></div></div>"""

UI10 = hd("Việc của tôi", tg(IN, "4 chờ duyệt")) + """<div class="grid2" style="grid-template-columns:380px minmax(0,1fr)"><div class="card" style="padding:0"><div class="facets" style="padding:10px"><span class="on">Chờ tôi 4</span><span>Đã xử lý</span></div>
<div style="padding:0 12px 12px">""" + "".join(f'<div style="padding:10px;border-radius:8px;{b}margin-bottom:6px"><b>{t}</b><br><span class="muted">{s}</span></div>' for t, s, b in [
    ("Công bố API · thong-ke-dan-cu 0.9.0", "Công an tỉnh · gửi 07:55 · " + "chờ 1 ngày", "background:var(--color-primary-weak);"), ("Đăng ký · HT-XAYDUNG → ho-so-dat-dai", "Sở Xây dựng · gửi 25/11", "border:1px solid var(--color-border);"), ("Công bố gói · dd-tra-cuu-nang-cao", "Sở TN&amp;MT · gửi 25/11", "border:1px solid var(--color-border);"), ("Ngừng khuyến nghị · ho-so-dat-dai 1.4.0", "Sở TN&amp;MT · gửi 24/11", "border:1px solid var(--color-border);")]) + """</div></div>
<div class="card"><div class="head" style="margin-bottom:8px"><h1 style="font-size:18px">Công bố API · thong-ke-dan-cu 0.9.0</h1>""" + tg(WN, "Chờ duyệt") + """</div><dl class="dl"><dt>Người gửi</dt><dd>Trần Văn B (SV) · Công an tỉnh</dd><dt>Phân loại</dt><dd>""" + tg(ER, "Hạn chế") + """ · Trong tỉnh</dd></dl>
<div style="margin:12px 0 4px"><b>Điều kiện công bố</b></div><div class="vtl"><div>✓ Đặc tả đạt lớp 1, lớp 2 (0 lỗi, 1 cảnh báo đã chấp nhận) · <u>xem kết quả</u></div><div>✓ Backend hoạt động (2/2) · đã thử trên TEST 25/11</div><div>✓ Có ít nhất một gói (1 gói đang soạn, công bố cùng đợt)</div><div><span style="color:#7a5200">⚠ API gần giống: tra-cuu-dan-cu (82%)</span> · <u>so sánh</u></div></div>
<div class="field" style="margin-top:10px"><label>Ý kiến (bắt buộc khi trả lại) </label><span class="input" style="height:54px"></span></div>
<div class="foot"><span class="btn danger">Trả lại</span><span class="btn pri">Duyệt và công bố</span></div></div></div>"""

UI11 = hd("Tuân thủ SLA và thống kê", "", btn("Xuất báo cáo") + inp("Kỳ: 6 tháng gần nhất ▾")) + """<div class="kpis" style="--n:4"><div class="kpi"><b>186</b><span>API có cam kết SLA</span></div><div class="kpi"><b style="color:#0b6b3a">94,6%</b><span>Tuân thủ kỳ 10/2026</span></div><div class="kpi"><b style="color:#a11a1a">3</b><span>API không đạt ≥ 3 kỳ</span></div><div class="kpi"><b>4,18 triệu</b><span>Lượt gọi tháng 10</span></div></div>
<div class="grid3" style="grid-template-columns:minmax(0,1fr) minmax(0,1.2fr)"><div class="card"><b>Tỷ lệ API đạt SLA theo kỳ</b><div class="vbars"><div><i style="height:88%;background:var(--color-primary)"></i></div><div><i style="height:90%;background:var(--color-primary)"></i></div><div><i style="height:86%;background:var(--color-primary)"></i></div><div><i style="height:92%;background:var(--color-primary)"></i></div><div><i style="height:93%;background:var(--color-primary)"></i></div><div><i style="height:95%;background:var(--color-primary)"></i></div></div><div class="legend"><span>05</span><span>06</span><span>07</span><span>08</span><span>09</span><span>10/2026</span></div><div class="legend"><span><i style="background:var(--color-primary)"></i>Tỷ lệ đạt</span><span>Bảng số liệu thay thế ở dưới biểu đồ</span></div></div>
<div class="card" style="padding:0">""" + tb("Cam kết và thực tế", ["API · Phiên bản", "Sẵn sàng (cam kết / thực tế)", "p95 (cam kết / thực tế)", "Kỳ 10", "Liên tiếp"], [
    [m("ho-so-dat-dai") + " 2.0.0", "99,90% / 99,41%", "400 / 611 ms", tg(ER, "Không đạt"), "3 kỳ ⚠"], [m("tra-cuu-ho-tich") + " 1.2.0", "99,50% / 99,82%", "500 / 233 ms", tg(OK, "Đạt"), "—"], [m("dang-ky-kinh-doanh") + " 3.1.0", "99,50% / 99,95%", "400 / 188 ms", tg(OK, "Đạt"), "—"], [m("danh-muc-don-vi") + " 1.0.0", "99,00% / 99,99%", "300 / 96 ms", tg(OK, "Đạt"), "—"], [m("bao-hiem-xa-hoi") + " 1.0.0", "99,50% / 99,47%", "500 / 540 ms", tg(WN, "Gần ngưỡng"), "1 kỳ"]]) + "</div></div>"

UI12 = hd("Đồng bộ danh mục quốc gia", "", btn("Xuất CSV") + btn("Đồng bộ ngay", "pri")) + """<div class="alert w"><span>⚠ <b>2 bản ghi</b> quá hạn 24 giờ chưa đồng bộ được. Lần chạy gần nhất 26/11/2026 06:00 (tự động).</span></div><div class="kpis" style="--n:5"><div class="kpi"><b>141</b><span>Đã đồng bộ</span></div><div class="kpi"><b style="color:#7a5200">6</b><span>Đang chờ</span></div><div class="kpi"><b style="color:#a11a1a">4</b><span>Bị từ chối</span></div><div class="kpi"><b style="color:#a11a1a">2</b><span>Quá hạn</span></div><div class="kpi"><b>31</b><span>Không thuộc diện đồng bộ</span></div></div><div class="card"><div class="toolbar">""" + inp("Tìm API") + inp("Trạng thái: Cần xử lý ▾") + inp("Khoảng: 30 ngày ▾") + """</div>""" + tb("Bản ghi đồng bộ", ["API · Phiên bản", "Loại", "Trạng thái", "Lần thử", "Lý do hoặc mã từ chối", "Cập nhật", ""], [
    [m("ho-so-dat-dai") + " 2.0.0", "Cập nhật", tg(ER, "Quá hạn"), "7", "Nền tảng quốc gia không phản hồi (timeout)", "25/11 06:02", "Gửi lại"],
    [m("tra-cuu-ho-tich") + " 1.2.0", "Cập nhật", tg(ER, "Quá hạn"), "7", "Nền tảng quốc gia không phản hồi (timeout)", "25/11 06:02", "Gửi lại"],
    [m("dang-ky-kinh-doanh") + " 3.1.0", "Tạo mới", tg(ER, "Bị từ chối"), "1", "NGSP-422: thiếu mã dịch vụ công liên quan", "26/11 06:01", "Xem lý do"],
    [m("danh-muc-don-vi") + " 1.0.0", "Tạo mới", tg(WN, "Đang chờ"), "2", "Hàng đợi PH-14 đang xử lý", "26/11 06:01", "—"],
    [m("thong-ke-cong-nghiep") + " 1.1.0", "Gỡ", tg(OK, "Đã đồng bộ"), "1", "—", "26/11 06:00", "—"]]) + pager("Hiển thị 1–5 / 12 bản ghi cần xử lý") + "</div>"

UI13 = ('<div class="head"><h1>Chi tiết API · ho-so-dat-dai</h1></div><div class="card" style="opacity:.55">' + tb("Nền", ["Phiên bản", "Trạng thái", "Đăng ký"], [["2.0.0", tg(OK, "Đang chạy"), "9"], ["1.4.0", tg(WN, "Sắp ngừng"), "5"]]) + "</div>") + """<div class="drawer" style="width:560px"><div class="head" style="margin-bottom:10px"><h1 style="font-size:18px">Lộ trình ngừng dùng · phiên bản 1.4.0</h1><div class="sp"></div><span class="muted">✕</span></div>
<div class="field"><label>Phiên bản kế nhiệm *</label><span class="input">2.0.0 (Đang chạy) ▾</span></div><div style="display:flex;gap:10px"><div class="field" style="flex:1"><label>Ngừng khuyến nghị từ</label><span class="input">26/11/2026</span></div><div class="field" style="flex:1"><label>Ngừng hẳn vào (≥ 180 ngày)</label><span class="input">03/06/2027</span></div></div>
<div class="timeline"><div class="seg" style="flex:3;background:#bcd2fb"></div><div class="seg" style="flex:7;background:#f0dc9c"></div></div><div class="muted" style="display:flex;justify-content:space-between"><span>Chạy song song</span><span>Chỉ đọc, cảnh báo mỗi lần gọi</span></div>
<div class="field" style="margin-top:10px"><label>Hướng dẫn chuyển đổi</label><span class="input" style="height:54px;align-items:flex-start;padding-top:6px">Đổi đường dẫn sang /dat-dai/v2; bổ sung trường mucDichSuDung khi tra cứu.</span></div>
<b>Bên bị ảnh hưởng (5) · thông báo</b>""" + tb("Bên nhận thông báo", ["HTTT", "Thông báo", "Xác nhận"], [["HT-MOTCUA", tg(OK, "Đã gửi 26/11"), tg(OK, "Đã đọc")], ["HT-DKKD", tg(OK, "Đã gửi 26/11"), tg(MT, "Chưa")], ["HT-THUE", tg(WN, "Gửi lỗi (thư)"), tg(MT, "—")], ["HT-XAYDUNG", tg(OK, "Đã gửi 26/11"), tg(MT, "Chưa")]]) + """<div class="foot"><span class="btn">Gửi thông báo tay</span><span class="btn pri">Gửi duyệt lộ trình</span></div></div>"""

UI14 = hd("Phân loại và thẻ", "", btn("+ Thêm nhóm", "pri")) + """<div class="grid2" style="grid-template-columns:300px minmax(0,1fr)"><div class="card tree"><b>Cây phân loại</b><div style="margin-top:8px"><div>▾ Tất cả (186)</div><div style="margin-left:14px" class="on">▾ Đất đai, tài nguyên (23)</div><div style="margin-left:34px">Địa chính (11)</div><div style="margin-left:34px">Môi trường (12)</div><div style="margin-left:14px">▸ Hộ tịch, tư pháp (31)</div><div style="margin-left:14px">▸ Doanh nghiệp, đầu tư (28)</div><div style="margin-left:14px">▸ An sinh, bảo hiểm (19)</div><div style="margin-left:14px">▸ Hạ tầng, đô thị (24)</div><div style="margin-left:14px">▸ Chưa phân loại (3)</div></div></div>
<div class="card" style="padding:0"><div style="padding:12px 14px;display:flex;gap:10px;align-items:center"><b>Đất đai, tài nguyên</b><span class="muted">· 23 API · mã <span class="mono">dat-dai</span></span><div style="flex:1"></div>""" + btn("Đổi tên") + btn("Gộp vào…") + btn("Xóa nhóm", "danger") + "</div>" + tb("API trong nhóm", ["API", "Chủ quản", "Phân loại dữ liệu", "Thẻ", "Trạng thái"], [
    [m("ho-so-dat-dai"), "Sở TN&amp;MT", tg(ER, "Hạn chế"), "tra-cuu · NDXP", tg(OK, "Đang chạy")], [m("quy-hoach-su-dung-dat"), "Sở TN&amp;MT", tg(OK, "Công khai"), "quy-hoach", tg(OK, "Đang chạy")], [m("quan-trac-moi-truong"), "Chi cục BVMT", tg(IN, "Nội bộ"), "quan-trac", tg(OK, "Đang chạy")], [m("gia-dat"), "Sở TN&amp;MT", tg(OK, "Công khai"), "gia", tg(WN, "Chờ duyệt")]]) + "</div></div>"

UI15 = hd("Bộ luật kiểm tra quy ước", "", btn("Khôi phục mặc định") + btn("Lưu thay đổi", "pri")) + """<div class="alert i"><span>Luật có mức <b>Lỗi</b> chặn gửi duyệt; mức <b>Cảnh báo</b> cho chấp nhận kèm lý do. Mẫu quét bí mật do nền tảng quản lý, chỉ đọc.</span></div><div class="card" style="padding:0">""" + tb("Bộ luật", ["Mã luật", "Nội dung", "Mức hiệu lực", "Mặc định", "API vi phạm"], [
    [m("Q-ERR-01"), "Phản hồi lỗi theo RFC 9457", inp("Lỗi ▾"), "Lỗi", "17"], [m("Q-DOC-02"), "Mọi thao tác có mô tả tiếng Việt", inp("Lỗi ▾"), "Lỗi", "9"], [m("Q-NAME-04"), "Tên tham số camelCase", inp("Cảnh báo ▾"), "Cảnh báo", "41"], [m("Q-EX-01"), "Có ví dụ cho phản hồi 2xx", inp("Cảnh báo ▾"), "Cảnh báo", "63"], [m("Q-VER-03"), "Số phiên bản theo SemVer", inp("Lỗi ▾"), "Lỗi", "2"], [m("S-TOKEN"), "Chuỗi giống token, khóa riêng (chỉ đọc)", tg(MT, "Lỗi · cố định"), "Lỗi", "1"], [m("S-PII"), "Số định danh, số điện thoại thật (chỉ đọc)", tg(MT, "Lỗi · cố định"), "Lỗi", "0"]]) + "</div>"

UI16 = hd("Nhập từ APIM cũ", "", btn("‹ Quay lại") + btn("Xác nhận nhập 24 API", "pri")) + steps(["Tải gói xuất", "Xem trước ánh xạ", "Xác nhận", "Báo cáo đối chiếu"], 1) + """<div class="kpis" style="--n:4"><div class="kpi"><b>26</b><span>API trong gói</span></div><div class="kpi"><b style="color:#0b6b3a">24</b><span>Nhập được</span></div><div class="kpi"><b style="color:#7a5200">1</b><span>Cần sửa</span></div><div class="kpi"><b style="color:#a11a1a">1</b><span>Bỏ qua (trùng mã)</span></div></div><div class="card" style="padding:0">""" + tb("Xem trước ánh xạ", ["Mã API cũ", "Mã API mới", "Gói (cũ → mới)", "Đăng ký", "Ghi chú"], [
    ["ho-so-dat-dai", "ho-so-dat-dai", "Production → PUBLISHED", "14", "Giữ nguyên"], ["tra-cuu-ho-tich", "tra-cuu-ho-tich", "Production → PUBLISHED", "12", "Giữ nguyên"], ["dang-ky-kinh-doanh", "dang-ky-kinh-doanh", "Staging → STAGING", "21", "Giữ nguyên"], ["thong_ke_dan_cu", "<b>thong-ke-dan-cu</b>", "Production → PUBLISHED", "0", "Đổi mã theo quy ước (gạch dưới → gạch nối)"], ["bao-hiem", "—", "—", "—", "Trùng mã bao-hiem-xa-hoi, bỏ qua (ERR-02-002)"], ["gia-dat", "gia-dat", "Staging → STAGING", "2", "Thiếu context-path, cần nhập tay"]]).replace("<tr><td>thong_ke_dan_cu", "<tr class='d-chg'><td>thong_ke_dan_cu").replace("<tr><td>bao-hiem</td>", "<tr class='d-del'><td>bao-hiem</td>").replace("<tr><td>gia-dat", "<tr class='d-chg'><td>gia-dat") + "</div>"

UI17 = hd("Cài đặt phân hệ và đối soát", "", btn("Hoàn tác") + btn("Lưu (cần lý do)", "pri")) + """<div class="grid3" style="grid-template-columns:minmax(0,1.2fr) minmax(0,1fr)"><div class="card" style="padding:0"><div style="padding:12px 14px"><b>Tham số phân hệ</b> <span class="muted">· nhóm <span class="mono">02.*</span></span></div>""" + tb("Tham số", ["Tham số", "Giá trị", "Mặc định", "Trần nền tảng"], [
    [m("02.spec.url-refresh-hours"), inp("24"), "24", "168"], [m("02.lint.max-per-hour"), inp("60"), "60", "300"], [m("02.duplicate.threshold"), inp("0,8"), "0,8", "—"], [m("02.backend.max-per-version"), inp("10"), "10", "20"], [m("02.deprecation.min-days"), inp("180"), "180", "≥ 90"], [m("02.notice.announcement-max-per-day"), inp("3"), "3", "10"]]) + """</div>
<div class="card"><b>Đối soát cấu hình với gateway</b> <span class="muted">· lần cuối 26/11 03:00</span><div class="kpis" style="--n:3;margin-top:10px"><div class="kpi"><b>186</b><span>Đã so</span></div><div class="kpi"><b style="color:#0b6b3a">183</b><span>Khớp</span></div><div class="kpi"><b style="color:#a11a1a">3</b><span>Lệch</span></div></div>""" + tb("API lệch cấu hình", ["API", "Khác biệt", ""], [[m("ho-so-dat-dai"), "Thiếu route POST /thua-dat:tra-cuu", "Đẩy lại"], [m("gia-dat"), "Hạn mức 120 ≠ 60", "Đẩy lại"], [m("bao-hiem-xa-hoi"), "Route thừa", "Đẩy lại"]]) + """<div class="foot"><span class="btn pri">Đối soát và đẩy lại tất cả</span></div></div></div>"""

SCREENS = [
    ("01", "api", "Danh mục API", "Kết nối &amp; API / Danh mục API", UI01, ""),
    ("02", "api", "Chi tiết API", "Kết nối &amp; API / Danh mục API / ho-so-dat-dai", UI02, ""),
    ("03", "api", "Đăng ký API từ OpenAPI", "Kết nối &amp; API / Danh mục API / Đăng ký mới", UI03, ""),
    ("04", "api", "Kết quả kiểm tra đặc tả", "Kết nối &amp; API / Danh mục API / ho-so-dat-dai / Kiểm tra đặc tả", UI04, ""),
    ("05", "api", "So sánh phiên bản và tác động", "Kết nối &amp; API / Danh mục API / ho-so-dat-dai / So sánh", UI05, ""),
    ("06", "goi", "Danh sách gói sử dụng", "Kết nối &amp; API / Gói sử dụng", UI06, ""),
    ("07", "goi", "Tạo gói sử dụng", "Kết nối &amp; API / Gói sử dụng / Tạo gói", UI07, ""),
    ("08", "dk", "Danh sách đăng ký sử dụng", "Kết nối &amp; API / Đăng ký sử dụng", UI08, ""),
    ("09", "dk", "Gửi đăng ký sử dụng", "Kết nối &amp; API / Đăng ký sử dụng", UI09, UI09X),
    ("10", "viec", "Duyệt công bố, gói, đăng ký", "Cá nhân / Việc của tôi", UI10, ""),
    ("11", "sla", "Tuân thủ SLA và thống kê", "Kết nối &amp; API / Tuân thủ SLA", UI11, ""),
    ("12", "sync", "Đồng bộ danh mục quốc gia", "Kết nối &amp; API / Đồng bộ quốc gia", UI12, ""),
    ("13", "api", "Lộ trình ngừng dùng và thông báo", "Kết nối &amp; API / Danh mục API / ho-so-dat-dai / Ngừng dùng", UI13, ""),
    ("14", "pl", "Phân loại và thẻ", "Quản trị dịch vụ / Phân loại và thẻ", UI14, ""),
    ("15", "luat", "Bộ luật kiểm tra quy ước", "Quản trị dịch vụ / Bộ luật kiểm tra", UI15, ""),
    ("16", "nhap", "Nhập từ APIM cũ", "Quản trị dịch vụ / Nhập từ APIM cũ", UI16, ""),
    ("17", "cd", "Cài đặt phân hệ và đối soát", "Quản trị dịch vụ / Cài đặt và đối soát", UI17, ""),
]
for code, act, title, crumb, body, extra in SCREENS:
    (OUT / f"ui-02-{code}.html").write_text(shell(code, act, title, crumb, body, extra), encoding="utf-8")
print(f"Đã sinh {len(SCREENS)} tệp ui-02-nn.html")
