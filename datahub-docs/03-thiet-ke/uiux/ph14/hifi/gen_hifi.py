#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-14-01…17 của D03-06-PH14 (mỗi màn một tệp HTML, chụp bằng shot.js).
Dùng lại hifi.css (token Liquid Glass theo D03-05-02, sao từ ph19/hifi). Chạy: python3 gen_hifi.py && node shot.js
Dữ liệu trên ảnh là dữ liệu minh họa của tỉnh giả lập T68, không phải dữ liệu thật."""
import pathlib

OUT = pathlib.Path(__file__).parent
NAV = [("Tổng quan", "01"), ("Nền tảng quốc gia", "02"), ("Dịch vụ quốc gia", "04"), ("Đối chiếu danh mục", "06"),
       ("Bảng định tuyến", "07"), ("Chứng thư số", "08"), ("Sự cố chữ ký", "14"), ("Hạn mức và đệm", "09"),
       ("Điểm cuối chiều vào", "10"), ("Đồng bộ", "11"), ("Giao dịch, đối soát", "12"), ("Nhật ký khai thác", "13"),
       ("Cắt chuyển từ hệ cũ", "15"), ("Cài đặt phân hệ", "16")]
ACTIVE = {"03": "02", "05": "04", "17": "17"}
BADGE = {"07": "<span class='tag t-info'>2</span>", "14": "<span class='tag t-err'>1</span>", "08": "<span class='tag t-warn'>1</span>"}

EXTRA_CSS = """<style>
.bar{position:relative;height:10px;border-radius:5px;background:#e8ecf2;min-width:140px;overflow:hidden}
.bar i{display:block;height:100%;border-radius:5px;background:#2f6fe4}
.bar.w i{background:#e0a100}.bar.e i{background:#c62828}
.bar:before,.bar:after{content:"";position:absolute;top:0;bottom:0;width:1px;background:rgba(0,0,0,.35);z-index:2}
.bar:before{left:70%}.bar:after{left:95%}
.cards3{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:10px;margin-bottom:12px}
.cards3 .card h3{margin:0 0 6px;font-size:15px}.cards3 .card p{margin:3px 0;font-size:13px}
.dot{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:6px}
.dot.g{background:#0b6b3a}.dot.y{background:#d08a00}.dot.r{background:#a11a1a}
.warn{margin-bottom:8px}
.legend{font-size:12px;color:#5b6573;margin-top:6px}
</style>"""


def shell(code, active, title, crumb, body, extra=""):
    active = ACTIVE.get(code, active)
    nav = "".join(f'<a class="{"on" if active == c else ""}" href="#">{n} {BADGE.get(c, "")}</a>' for n, c in NAV)
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-14-{code} · {title}</title><link rel="stylesheet" href="hifi.css">{EXTRA_CSS}</head><body>
<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Kết nối quốc gia</div><div class="search">Tìm dịch vụ, giao dịch, chứng thư…  ⌘K</div><div class="sp"></div>
<span class="tray">Tỉnh mẫu T68</span><span class="tray">Môi trường: PROD</span><div class="avatar">AN</div></header>
<nav class="side" aria-label="Điều hướng chính"><div class="grp">Kết nối quốc gia</div>{nav}<div class="grp">Cá nhân</div><a href="#">Việc của tôi <span class="tag t-info">3</span></a></nav>
<main><div class="crumb">{crumb}</div>{body}</main></div>{extra}<div class="hint">Bản hi-fi minh họa · D02-03-PH14 · UI-14-{code}</div></body></html>"""


def rows(data):
    return "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in data)


def bar(pct, cls=""):
    return f'<div class="bar {cls}" role="img" aria-label="Mức dùng {pct}%"><i style="width:{pct}%"></i></div>'


UI01 = """
<div class="head"><h1>Kết nối quốc gia</h1><div class="sp"></div><span class="muted">Làm mới sau 30 giây · 26/11/2026 14:05</span><span class="btn">Báo cáo hạn mức</span><span class="btn pri">Kiểm tra kết nối</span></div>
<div class="warn"><b>Chứng thư ký số còn 24 ngày.</b> Chứng thư <span class="mono">t68-sign-2026</span> hết hạn ngày 20/12/2026 và chưa có bản thay thế. Khởi động gia hạn ngay để không ngưng kết nối quốc gia.</div>
<div class="warn"><b>Hạn mức tra cứu bảo hiểm xã hội dự báo cạn lúc 21:40 hôm nay.</b> Đã dùng 77% hạn mức ngày; tác vụ nền đang bị hoãn. Cân nhắc tăng thời hạn đệm hoặc đề nghị nâng hạn mức.</div>
<div class="cards3">
<div class="card"><h3><span class="dot g"></span>NDXP · Nền tảng trao đổi dữ liệu</h3><p><span class="tag t-ok">Khỏe</span> <span class="tag t-mute">Ngắt mạch đóng</span></p><p>Token còn 41 phút · p95 438 ms</p><p class="muted">Lần kiểm tra 14:04 · 4 bước đạt</p></div>
<div class="card"><h3><span class="dot y"></span>NDOP · Dữ liệu mở</h3><p><span class="tag t-warn">Đặc tả tạm thời</span> <span class="tag t-mute">Chờ bật</span></p><p>Kiểm tra TLS đạt, chưa có dịch vụ</p><p class="muted">Rà soát khi có đặc tả chính thức</p></div>
<div class="card"><h3><span class="dot g"></span>Hệ thống đăng ký danh mục dịch vụ</h3><p><span class="tag t-ok">Khỏe</span> <span class="tag t-ok">Đồng bộ 02:00</span></p><p>18 dịch vụ gửi · 18 chấp nhận</p><p class="muted">Lần đồng bộ kế tiếp 02:00 ngày mai</p></div>
</div>
<div class="stats"><div class="stat"><b>150.000</b><span>Lượt gọi 24 giờ</span></div><div class="stat"><b>99,3%</b><span>Tỷ lệ thành công</span></div><div class="stat"><b>71%</b><span>Trúng đệm (mục tiêu ≥ 60%)</span></div><div class="stat"><b>438 ms</b><span>p95 lượt gọi thật tới NDXP</span></div><div class="stat"><b style="color:#a11a1a">0</b><span>Sự cố chữ ký chưa xác nhận</span></div></div>
<div class="card"><div class="muted" style="margin-bottom:6px"><b>Hạn mức theo dịch vụ</b> · chu kỳ ngày, đặt lại 00:00</div>
<table aria-label="Hạn mức theo dịch vụ"><thead><tr><th>Dịch vụ</th><th>Nhóm</th><th>Đã dùng</th><th>Giới hạn</th><th style="min-width:180px">Mức dùng</th><th>Dự báo cạn</th></tr></thead><tbody>""" + rows([
    ["Tra cứu hộ gia đình theo mã số BHXH", "BHXH", "23.100", "30.000", bar(77, "w") + "<span style='color:#7a5200'>77%</span>", "<span class='tag t-warn'>21:40 hôm nay</span>"],
    ["Tra trạng thái hồ sơ lý lịch tư pháp", "LLTP", "4.600", "20.000", bar(23) + "23%", "<span class='muted'>Không cạn</span>"],
    ["Dữ liệu mới nhất của doanh nghiệp", "ĐKDN", "11.200", "40.000", bar(28) + "28%", "<span class='muted'>Không cạn</span>"],
    ["Tìm kiếm văn bản quy phạm pháp luật", "VBQPPL", "4.600", "100.000", bar(5) + "5%", "<span class='muted'>Không cạn</span>"],
]) + """</tbody></table><div class="legend">Vạch đứng đánh dấu mốc 70% (hoãn tác vụ nền) và 95% (chỉ dịch vụ thiết yếu). Tổng 43.500 lượt ra NDXP, 106.500 lượt được phục vụ từ đệm.</div></div>"""

UI09 = """
<div class="head"><h1>Hạn mức và đệm</h1><div class="sp"></div><span class="btn">Xuất báo cáo</span><span class="btn pri">+ Hạn mức</span></div>
<div class="tabs"><span>Tổng quan</span><span class="on">Mức dùng và phân bổ</span><span>Đệm</span><span>Lịch sử hạn mức</span></div>
<div class="stats"><div class="stat"><b>71%</b><span>Tỷ lệ trúng đệm hôm nay</span></div><div class="stat"><b>106.500</b><span>Lượt tiết kiệm nhờ đệm</span></div><div class="stat"><b>12</b><span>Lượt phục vụ dữ liệu cũ (stale)</span></div><div class="stat"><b>0</b><span>Yêu cầu trong hàng chờ</span></div></div>
<div class="card"><div class="muted" style="margin-bottom:6px"><b>Mức dùng theo dịch vụ</b> · nền tảng NDXP</div>
<table aria-label="Mức dùng theo dịch vụ"><thead><tr><th>Dịch vụ</th><th>Chu kỳ</th><th>Đã dùng / giới hạn</th><th style="min-width:170px">Mức dùng</th><th>Căn cứ văn bản</th><th>Đặt lại</th></tr></thead><tbody>""" + rows([
    ["Tra hộ gia đình theo mã số BHXH", "Ngày", "23.100 / 30.000", bar(77, "w") + "77% <span class='tag t-warn'>Tác vụ nền bị hoãn</span>", "<span class='mono'>Văn bản …/… ngày …</span>", "00:00 27/11"],
    ["Tra trạng thái hồ sơ lý lịch tư pháp", "Ngày", "4.600 / 20.000", bar(23) + "23%", "<span class='mono'>Văn bản …/… ngày …</span>", "00:00 27/11"],
    ["Dữ liệu mới nhất của doanh nghiệp", "Ngày", "11.200 / 40.000", bar(28) + "28%", "<span class='mono'>Văn bản …/… ngày …</span>", "00:00 27/11"],
    ["Tìm kiếm văn bản quy phạm pháp luật", "Ngày", "4.600 / 100.000", bar(5) + "5%", "<span class='mono'>Văn bản …/… ngày …</span>", "00:00 27/11"],
]) + """</tbody></table></div>
<div class="card" style="margin-top:10px"><div class="muted" style="margin-bottom:6px"><b>Phân bổ theo HTTT</b> · Tra hộ gia đình theo mã số BHXH · hạn mức 30.000 lượt/ngày, đã phân bổ 28.000, chưa phân bổ 2.000</div>
<table aria-label="Phân bổ theo HTTT"><thead><tr><th>HTTT</th><th>Phân bổ</th><th>Đã dùng</th><th style="min-width:170px">Mức dùng phần được giao</th><th>Ghi chú</th></tr></thead><tbody>""" + rows([
    ["<span class='mono'>HT-MOTCUA</span> Một cửa điện tử", "12.000", "10.800", bar(90, "w") + "<span style='color:#7a5200'>90%</span>", "Giờ cao điểm 8–11 giờ"],
    ["<span class='mono'>HT-TUPHAP</span> Sở Tư pháp", "8.000", "6.300", bar(79, "w") + "79%", ""],
    ["<span class='mono'>HT-LDTBXH</span> Sở Lao động", "5.000", "3.900", bar(78, "w") + "78%", ""],
    ["<span class='mono'>HT-YTE</span> Sở Y tế", "3.000", "2.100", bar(70, "w") + "70%", ""],
]) + """</tbody></table>
<div class="foot" style="justify-content:space-between"><span class="muted">Đệm: BHXH 300 giây · ĐKDN 3.600 giây · VBQPPL 86.400 giây · lý lịch tư pháp và hộ tịch không đệm</span><span><span class="btn">Tăng thời hạn đệm…</span> <span class="btn">Vô hiệu đệm…</span> <span class="btn pri">Phân bổ</span></span></div></div>"""

SCREENS = {}


def table(head, data, label="", style=""):
    th = "".join(f"<th>{h}</th>" for h in head)
    return f'<table aria-label="{label}" style="{style}"><thead><tr>{th}</tr></thead><tbody>{rows(data)}</tbody></table>'


def tag(kind, text):
    return f"<span class='tag t-{kind}'>{text}</span>"


def tabs(items, on):
    return '<div class="tabs" role="tablist">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def facets(items, on=0):
    return '<div class="facets">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def head(title, *btns, sub=""):
    b = "".join(f'<span class="btn{" pri" if i == len(btns) - 1 and len(btns) > 0 else ""}">{x}</span>' for i, x in enumerate(btns))
    return f'<div class="head"><h1>{title}</h1>{sub}<div class="sp"></div>{b}</div>'


def filt(*items):
    return '<div class="toolbar">' + "".join(f'<span class="input">{x}</span>' for x in items) + "</div>"


def alert(kind, text):
    return f'<div class="alert {kind}" role="alert"><span>{text}</span></div>'


def fld(label, val, note=""):
    return f'<div class="field"><label>{label}</label><div class="input">{val}</div>{("<div class=muted>" + note + "</div>") if note else ""}</div>'


# 02 Danh sách nền tảng
SCREENS["02"] = ("Danh sách nền tảng quốc gia", "Tích hợp / Kết nối quốc gia / Nền tảng quốc gia",
    head("Nền tảng quốc gia", "Kiểm tra tất cả", "+ Khai báo nền tảng") +
    facets(["Tất cả 4", "Đang dùng 3", "Chờ duyệt bật 1", "Mất kết nối 0"]) +
    '<div class="card">' + filt("Tìm mã, tên…", "Loại: Tất cả ▾", "Sức khỏe ▾", "Trạng thái ▾", "Môi trường: PROD ▾") + table(
        ["", "Mã · Tên", "Loại", "Phạm vi", "Trạng thái", "Đặc tả", "Ngắt mạch", "Token", "Kiểm tra cuối", "⋯"], [
            ["<span class='dot g'></span>", "<span class='mono'>ndxp-t68</span><br>Nền tảng chia sẻ dữ liệu quốc gia", "NDXP", "Tenant", tag("ok", "Đang dùng"), tag("ok", "Chính thức"), tag("ok", "Đóng"), "41 phút", "14:04 · 438 ms", "⋯"],
            ["<span class='dot g'></span>", "<span class='mono'>dmdc-common</span><br>Danh mục dùng chung quốc gia", "NDXP", tag("info", "COMMON"), tag("ok", "Đang dùng"), tag("ok", "Chính thức"), tag("ok", "Đóng"), "52 phút", "14:04 · 402 ms", "⋯"],
            ["<span class='dot y'></span>", "<span class='mono'>ndop-t68</span><br>Dữ liệu mở quốc gia", "NDOP", "Tenant", tag("warn", "Chờ duyệt bật"), tag("warn", "Tạm thời"), tag("mute", "—"), "—", "13:50 · 612 ms", "⋯"],
            ["<span class='dot g'></span>", "<span class='mono'>registry-t68</span><br>Hệ thống đăng ký danh mục dịch vụ", "REGISTRY", "Tenant", tag("ok", "Đang dùng"), tag("ok", "Chính thức"), tag("ok", "Đóng"), "—", "02:00 · 910 ms", "⋯"]],
        "Danh sách nền tảng") + '<div class="muted" style="margin-top:8px">4 nền tảng · 25 / trang · ‹ 1 ›</div></div>')

# 03 Khai báo nền tảng (wizard)
SCREENS["03"] = ("Khai báo nền tảng quốc gia", "Tích hợp / Kết nối quốc gia / Nền tảng quốc gia / Khai báo",
    head("Khai báo nền tảng quốc gia", "Lưu nháp", "Tiếp tục") +
    '<div class="steps"><div class="done">1 Loại ✓</div><div class="done">2 Kết nối PH-05 ✓</div><div class="on">3 Xác thực</div><div>4 Kiểm tra</div><div>5 Gửi duyệt</div></div>' +
    '<div class="grid-2e"><div class="card"><h3 style="margin-top:0">Cách xác thực với nền tảng</h3>' +
    fld("Kiểu xác thực *", "OAuth 2.1 · private_key_jwt (khuyến nghị) ▾") + fld("Kết nối PH-05 (môi trường PROD) *", "ndxp-oauth-t68 · loại oauth2-client ▾", "Địa chỉ, client và khóa khai ở phân hệ Bộ điều hợp; PH-14 không giữ bí mật.") +
    fld("Phạm vi (scope) *", "dichvu.tracuu dichvu.hoso") + fld("Làm mới token trước hạn", "60 giây", "Tham số 14.token.refresh-before-seconds") +
    alert("i", "Thông tin xác thực đã khai: <b>phiên bản 2</b>, ghi bởi An (IE), 26/11/2026 10:12. Giá trị không bao giờ hiện lại.") + '</div>' +
    '<div class="card raised"><h3 style="margin-top:0">Tóm tắt khai báo</h3><dl class="dl" style="grid-template-columns:130px 1fr"><dt>Mã</dt><dd class="mono">ndxp-t68</dd><dt>Loại</dt><dd>NDXP · phạm vi Tenant</dd><dt>Đặc tả</dt><dd>' + tag("ok", "Chính thức") + '</dd><dt>Kết nối TEST</dt><dd>ndxp-oauth-t68-test</dd><dt>Kết nối PROD</dd><dd>ndxp-oauth-t68</dd><dt>Dịch vụ ký số</dt><dd>3 dịch vụ cần chứng thư SIGNING</dd></dl>' +
    alert("w", "Bước 5 cần kiểm tra kết nối đạt trong 24 giờ và người duyệt thứ hai (bốn mắt).") + '</div></div>')

# 04 Danh mục dịch vụ
SCREENS["04"] = ("Danh mục dịch vụ quốc gia", "Tích hợp / Dịch vụ quốc gia",
    head("Dịch vụ quốc gia", "Đối chiếu danh mục", "+ Khai báo dịch vụ") +
    facets(["Tất cả 22", "LLTP 3", "Hộ tịch 4", "BHXH 3", "ĐVQHNS 3", "ĐKDN 4", "VBQPPL 4", "DMDC 1"]) +
    '<div class="card">' + filt("Tìm mã, tên, Service-code…", "Nền tảng ▾", "Nhãn đối chiếu ▾", "Ưu tiên ▾", "Trạng thái ▾") + table(
        ["Mã · Tên", "Nhóm", "Nhạy cảm", "Ưu tiên", "Đệm", "Ký số", "Nhãn đối chiếu", "Cung cấp lại", "Trạng thái"], [
            ["<span class='mono'>bhxh-tra-ho</span><br>Tra hộ gia đình theo mã số BHXH", "BHXH", tag("err", "Nhạy cảm"), "Thiết yếu", "300 s", "Ký + xác minh", tag("ok", "Còn"), tag("ok", "Đã cung cấp"), tag("ok", "Hoạt động")],
            ["<span class='mono'>lltp-tra-trang-thai</span><br>Tra trạng thái hồ sơ lý lịch tư pháp", "LLTP", tag("err", "Nhạy cảm"), "Thiết yếu", "Không đệm", "Ký + xác minh", tag("ok", "Còn"), tag("ok", "Đã cung cấp"), tag("ok", "Hoạt động")],
            ["<span class='mono'>dkdn-moi-nhat</span><br>Dữ liệu mới nhất của doanh nghiệp", "ĐKDN", tag("warn", "Hạn chế"), "Thường", "3.600 s", "Xác minh", tag("warn", "Đổi đặc tả"), tag("ok", "Đã cung cấp"), tag("ok", "Hoạt động")],
            ["<span class='mono'>vbqppl-tim-kiem</span><br>Tìm kiếm văn bản quy phạm pháp luật", "VBQPPL", tag("mute", "Công khai"), "Nền", "86.400 s", "Không", tag("ok", "Còn"), tag("ok", "Đã cung cấp"), tag("ok", "Hoạt động")],
            ["<span class='mono'>dvqhns-ds-hoso</span><br>Danh sách hồ sơ cấp mã ĐVQHNS", "ĐVQHNS", tag("warn", "Hạn chế"), "Nền", "Không đệm", "Ký", tag("mute", "Chưa đối chiếu"), tag("mute", "Chưa"), tag("mute", "Nháp")]],
        "Danh mục dịch vụ quốc gia") + '<div class="muted" style="margin-top:8px">22 dịch vụ · 25 / trang · ‹ 1 ›</div></div>')

# 05 Chi tiết dịch vụ
SCREENS["05"] = ("Chi tiết dịch vụ quốc gia", "Tích hợp / Dịch vụ quốc gia / bhxh-tra-ho",
    head("Tra hộ gia đình theo mã số BHXH", "Thử chuyển đổi", "Tạm ngừng", "Cung cấp lại…", sub=" " + tag("ok", "Hoạt động") + " " + tag("ok", "Còn") + " " + tag("err", "Nhạy cảm")) +
    tabs(["Tổng quan", "Hợp đồng", "Đặc tả", "Đệm và hạn mức", "Cung cấp lại", "Lịch sử"], 2) +
    '<div class="grid3"><div class="card"><div class="muted" style="margin-bottom:6px"><b>Phiên bản đặc tả</b> · WSDL + XSD</div>' + table(
        ["Phiên bản", "Loại", "Mã băm", "Phá vỡ", "Trạng thái", "Nạp lúc"], [
            ["<b>2.1.0</b>", "WSDL", "<span class='mono'>9f3a…c41e</span>", tag("ok", "Không"), tag("ok", "Đang dùng"), "02/11/2026"],
            ["2.0.3", "WSDL", "<span class='mono'>51bd…07aa</span>", tag("ok", "Không"), tag("mute", "Đã thay"), "14/08/2026"],
            ["3.0.0 (nháp)", "OpenAPI", "<span class='mono'>c7e0…2b19</span>", tag("err", "Có"), tag("info", "Nháp"), "hôm nay"]], "Phiên bản đặc tả") +
    '<div class="muted" style="margin:10px 0 6px"><b>Khác biệt 2.1.0 → 3.0.0 (nháp)</b></div><table aria-label="Khác biệt đặc tả"><tbody>' +
    '<tr class="d-del"><td>− Trường <span class="mono">soHoGiaDinh</span> (bắt buộc)</td><td>' + tag("err", "Phá vỡ") + '</td></tr><tr class="d-chg"><td>~ <span class="mono">maSoBHXH</span>: chuỗi 10 → 13 ký tự</td><td>' + tag("warn", "Đổi") + '</td></tr><tr class="d-add"><td>+ Trường <span class="mono">ngayCapNhat</span> (tùy chọn)</td><td>' + tag("ok", "Thêm") + '</td></tr></tbody></table>' +
    alert("e", "<b>Đặc tả 3.0.0 có thay đổi phá vỡ.</b> Cần người duyệt xác nhận và tăng số chính của hợp đồng (ERR-14-012).") + '</div>' +
    '<div class="card raised"><h3 style="margin-top:0">Thông tin chung</h3><dl class="dl" style="grid-template-columns:120px 1fr"><dt>Service-code</dt><dd class="mono">BHXH_TRA_HGD</dd><dt>Nền tảng</dt><dd class="mono">ndxp-t68</dd><dt>Giao thức</dt><dd>SOAP 1.1</dd><dt>Thao tác</dt><dd>Đọc</dd><dt>Ký số</dt><dd>Ký gửi · xác minh phản hồi</dd><dt>Đệm</dt><dd>300 giây · cho phép dữ liệu cũ</dd><dt>Mục đích</dt><dd>Bắt buộc + mã hồ sơ</dd><dt>Cung cấp lại</dt><dd>/api/national/v1/bhxh/ho-gia-dinh</dd></dl></div></div>')

# 06 Đối chiếu danh mục
SCREENS["06"] = ("Đối chiếu danh mục dịch vụ", "Tích hợp / Dịch vụ quốc gia / Đối chiếu",
    head("Đối chiếu danh mục dịch vụ với NDXP", "Tải lại", "Áp dụng 17 thay đổi") +
    '<div class="steps"><div class="done">1 Tải danh mục ✓</div><div class="on">2 Xem đề xuất</div><div>3 Áp dụng</div></div>' +
    '<div class="stats"><div class="stat"><b>17</b><span>Còn (giữ nguyên)</span></div><div class="stat"><b style="color:#7a5200">3</b><span>Đổi đặc tả</span></div><div class="stat"><b style="color:#a11a1a">1</b><span>Ngừng</span></div><div class="stat"><b style="color:#0b5cd5">1</b><span>Thêm mới</span></div></div>' +
    '<div class="card"><div class="muted" style="margin-bottom:6px">Tệp <span class="mono">danh-muc-ndxp-2026-11-26.json</span> · 22 dịch vụ hiện hành · chạy lúc 14:02 bởi An (IE)</div>' + table(
        ["Dịch vụ", "Service-code", "Nhãn hiện tại", "Đề xuất", "Chi tiết", "Chọn"], [
            ["Dữ liệu mới nhất của doanh nghiệp", "<span class='mono'>DKDN_MOI_NHAT</span>", tag("ok", "Còn"), tag("warn", "Đổi đặc tả"), "Đặc tả mới 3.1: thêm 2 trường", "☑"],
            ["Tra hộ tịch theo số định danh", "<span class='mono'>HT_TRA_SDD</span>", tag("ok", "Còn"), tag("warn", "Đổi đặc tả"), "Địa chỉ dịch vụ đổi", "☑"],
            ["Danh sách hồ sơ cấp mã ĐVQHNS", "<span class='mono'>DVQHNS_DS</span>", tag("mute", "Chưa đối chiếu"), tag("err", "Ngừng"), "Không còn trong danh mục hiện hành", "☑"],
            ["Tra cứu chứng chỉ hành nghề", "<span class='mono'>CCHN_TRA</span>", "—", tag("info", "Thêm mới"), "Chưa có dịch vụ tương ứng", "☐"]], "Đề xuất đối chiếu") +
    alert("w", "Dịch vụ <b>DVQHNS_DS</b> đề xuất Ngừng sẽ chặn mọi lượt gọi mới (ERR-14-117). Kiểm tra HTTT đang dùng trước khi áp dụng.") + '</div>')

# 07 Bảng định tuyến
SCREENS["07"] = ("Bảng định tuyến", "Tích hợp / Kết nối quốc gia / Bảng định tuyến",
    head("Bảng định tuyến", "Mô phỏng", "+ Thêm luật") +
    '<div class="grid3"><div class="card">' + filt("Tìm theo dịch vụ, nhóm…", "Nhóm ▾", "Trạng thái ▾") + table(
        ["Ưu tiên", "Điều kiện", "Đích chính", "Dự phòng", "Căn cứ", "Trạng thái"], [
            ["10", "Nhóm <b>BHXH</b> · đọc", "<span class='mono'>ndxp-t68</span>", "—", "CV 1234/…", tag("ok", "Hiệu lực")],
            ["20", "Nhóm <b>VBQPPL</b> · đọc", "<span class='mono'>ndxp-t68</span>", "<span class='mono'>ndxp-t68-b</span>", "CV 88/…", tag("ok", "Hiệu lực")],
            ["30", "Dịch vụ <span class='mono'>dkdn-moi-nhat</span>", "<span class='mono'>ndxp-t68</span>", "—", "QĐ 55/…", tag("warn", "Chờ duyệt")],
            ["40", "Nhóm <b>DMDC</b> · đọc", "<span class='mono'>dmdc-common</span>", "—", "ADR-057", tag("ok", "Hiệu lực")]], "Luật định tuyến") + '</div>' +
    '<div class="card raised"><h3 style="margin-top:0">Mô phỏng</h3>' + fld("Dịch vụ", "bhxh-tra-ho") + fld("Loại thao tác", "Đọc") +
    '<div class="muted"><b>Kết quả:</b> khớp luật ưu tiên 10 → đích <span class="mono">ndxp-t68</span>, không dự phòng.</div>' + alert("i", "Luật ưu tiên 30 đang chờ duyệt, chưa được dùng khi mô phỏng PROD.") + '</div></div>')

# 08 Chứng thư số
SCREENS["08"] = ("Chứng thư số và chuỗi tin cậy", "Tích hợp / Kết nối quốc gia / Chứng thư số",
    head("Chứng thư số và chuỗi tin cậy", "Làm mới chuỗi tin cậy", "+ Nạp chứng thư") +
    alert("w", "<b>Chứng thư ký số <span class='mono'>t68-sign-2026</span> còn 24 ngày</b> (hết hạn 20/12/2026) và chưa có bản thay thế.") +
    tabs(["Chứng thư", "Chuỗi tin cậy và CRL", "Thống kê ký"], 0) +
    '<div class="card">' + table(["Mã", "Mục đích", "Chủ thể", "Hiệu lực đến", "Đếm ngược", "Khóa", "Trạng thái", "⋯"], [
        ["<span class='mono'>t68-sign-2026</span>", "Ký", "CN=Sở KH&amp;CN T68", "20/12/2026", tag("warn", "24 ngày"), "OpenBao transit", tag("warn", "Sắp hết hạn"), "⋯"],
        ["<span class='mono'>t68-tls-2026</span>", "TLS khách", "CN=dh-national-t68", "14/05/2027", tag("ok", "169 ngày"), "OpenBao PKI", tag("ok", "Đang dùng"), "⋯"],
        ["<span class='mono'>t68-sign-2027</span>", "Ký", "CN=Sở KH&amp;CN T68", "30/11/2028", tag("info", "—"), "OpenBao transit", tag("info", "Chờ duyệt kích hoạt"), "⋯"],
        ["<span class='mono'>t68-sign-2024</span>", "Ký", "CN=Sở KH&amp;CN T68", "02/03/2026", tag("mute", "Đã hết hạn"), "—", tag("mute", "Hết hạn"), "⋯"]], "Chứng thư số") +
    '<div class="foot" style="justify-content:space-between"><span class="muted">Chuỗi tin cậy làm mới 02:10 · CRL tuổi 1 ngày (tối đa 7)</span><span><span class="btn">Yêu cầu kích hoạt…</span> <span class="btn danger">Thu hồi…</span></span></div></div>')

# 10 Điểm cuối chiều vào
SCREENS["10"] = ("Điểm cuối chiều vào", "Tích hợp / Kết nối quốc gia / Điểm cuối chiều vào",
    head("Điểm cuối chiều vào", "+ Đăng ký điểm cuối") +
    '<div class="stats"><div class="stat"><b>2</b><span>Điểm cuối đang bật</span></div><div class="stat"><b>1.284</b><span>Bản tin vào 24 giờ</span></div><div class="stat"><b>6</b><span>Bị từ chối (mTLS, lặp)</span></div><div class="stat"><b>1</b><span>Chờ xác nhận vân tay</span></div></div>' +
    '<div class="grid3"><div class="card">' + table(["Mã", "Đường dẫn", "Nền tảng", "Nguồn được phép", "Trạng thái", "Vân tay"], [
        ["<span class='mono'>in-ndxp-t68</span>", "<span class='mono'>/inbound/v1/in-ndxp-t68</span>", "ndxp-t68", "2", tag("ok", "Đang bật"), "SHA-256 a1:9c…"],
        ["<span class='mono'>in-registry-t68</span>", "<span class='mono'>/inbound/v1/in-registry-t68</span>", "registry-t68", "1", tag("warn", "Chờ xác nhận"), "SHA-256 7e:02…"],
        ["<span class='mono'>in-ndop-t68</span>", "<span class='mono'>/inbound/v1/in-ndop-t68</span>", "ndop-t68", "0", tag("mute", "Nháp"), "—"]], "Điểm cuối chiều vào") + '</div>' +
    '<div class="card raised"><h3 style="margin-top:0">Nguồn được phép · in-registry-t68</h3>' + table(["Nguồn", "Dịch vụ"], [["REGISTRY-BO", "thông báo thay đổi"]], "Nguồn được phép") +
    alert("w", "Đối chiếu vân tay chứng thư nguồn với biên bản của trung ương rồi bấm Xác nhận. Cần xác thực nhiều yếu tố.") + '<div class="foot"><span class="btn pri">Xác nhận vân tay và bật</span></div></div></div>')

# 11 Đồng bộ
SCREENS["11"] = ("Đồng bộ", "Tích hợp / Kết nối quốc gia / Đồng bộ",
    head("Đồng bộ với quốc gia", "Làm mới", "Chạy đồng bộ danh mục dịch vụ") +
    tabs(["Danh mục dịch vụ", "Dữ liệu chủ", "Dữ liệu mở", "Danh mục dùng chung"], 0) +
    '<div class="stats"><div class="stat"><b>02:00</b><span>Phiên gần nhất (26/11)</span></div><div class="stat"><b>18 / 18</b><span>Gửi / chấp nhận</span></div><div class="stat"><b>0</b><span>Bản ghi lỗi</span></div><div class="stat"><b>02:00 27/11</b><span>Phiên kế tiếp</span></div></div>' +
    '<div class="card">' + table(["Phiên", "Kích hoạt", "Bắt đầu", "Thời lượng", "Gửi", "Chấp nhận", "Từ chối", "Trạng thái"], [
        ["<span class='mono'>run-0412</span>", "Lịch", "26/11 02:00", "41 s", "18", "18", "0", tag("ok", "Hoàn tất")],
        ["<span class='mono'>run-0411</span>", "Lịch", "25/11 02:00", "39 s", "18", "17", "1", tag("warn", "Hoàn tất có lỗi")],
        ["<span class='mono'>run-0410</span>", "Tay (An)", "24/11 15:20", "44 s", "18", "18", "0", tag("ok", "Hoàn tất")],
        ["<span class='mono'>run-0409</span>", "Lịch", "24/11 02:00", "—", "18", "0", "18", tag("err", "Lỗi")]], "Phiên đồng bộ") +
    alert("e", "Phiên <b>run-0409</b> lỗi: bên nhận từ chối toàn lô (ERR-14-028). Có 18 bản ghi chờ thử lại. <b>Thử lại bản ghi lỗi</b>") + '</div>')

# 12 Giao dịch và đối soát
SCREENS["12"] = ("Giao dịch và đối soát", "Tích hợp / Kết nối quốc gia / Giao dịch, đối soát",
    head("Giao dịch và đối soát", "Xuất bằng chứng", "Hàng chờ bất đồng bộ (0)") +
    '<div class="card">' + filt("Mã giao dịch hoặc mã hồ sơ…", "HTTT ▾", "Dịch vụ ▾", "Trạng thái ▾", "26/11 00:00 → 14:05") +
    '<div class="grid3" style="grid-template-columns:minmax(0,1fr) 380px">' + '<div>' + table(["Giờ", "Mã giao dịch", "HTTT", "Dịch vụ", "Trạng thái", "Nguồn", "Thời gian"], [
        ["14:03:12", "<span class='mono'>T68-261126-8KQ2</span>", "HT-MOTCUA", "bhxh-tra-ho", tag("ok", "Thành công"), "Gọi thật", "431 ms"],
        ["14:03:02", "<span class='mono'>T68-261126-7ZP1</span>", "HT-TUPHAP", "lltp-tra-trang-thai", tag("ok", "Thành công"), "Gọi thật", "502 ms"],
        ["14:02:47", "<span class='mono'>T68-261126-7XA9</span>", "HT-MOTCUA", "bhxh-tra-ho", tag("info", "Từ đệm"), "Đệm", "9 ms"],
        ["14:01:30", "<span class='mono'>T68-261126-6MC4</span>", "HT-YTE", "dkdn-moi-nhat", tag("err", "Chữ ký lỗi"), "Gọi thật", "611 ms"],
        ["14:00:18", "<span class='mono'>T68-261126-5HD7</span>", "HT-LDTBXH", "bhxh-tra-ho", tag("warn", "Kết quả chưa rõ"), "Gọi thật", "15.000 ms"]], "Danh sách giao dịch") + '</div>' +
    '<div class="card raised"><h3 style="margin-top:0">T68-261126-5HD7</h3><div class="vtl"><div>14:00:03 · Nhận yêu cầu (HT-LDTBXH)</div><div>14:00:03 · Kiểm tra mục đích: đạt</div><div>14:00:03 · Hạn mức: còn 6.900</div><div>14:00:03 · Đã ký, đã gửi tới ndxp-t68</div><div style="color:#7a5200">14:00:18 · Quá hạn chờ 15.000 ms → kết quả chưa rõ</div></div>' +
    '<div class="muted">Không tự gửi lại. Hệ thống đối soát trạng thái trước (BR-14-030).</div><div class="foot"><span class="btn">Xem nội dung đầy đủ…</span></div></div></div></div>')

# 13 Nhật ký khai thác
SCREENS["13"] = ("Nhật ký khai thác và báo cáo", "Tích hợp / Kết nối quốc gia / Nhật ký khai thác",
    head("Nhật ký khai thác", "Xuất báo cáo sử dụng", "Báo cáo hạn mức và đệm") +
    alert("w", "<b>Cảnh báo bất thường:</b> HT-MOTCUA tra <b>612 đối tượng khác nhau</b> trong 1 giờ (ngưỡng 500). <b>Xem và xử lý</b>") +
    '<div class="card">' + filt("HTTT ▾", "Dịch vụ ▾", "Mục đích ▾", "Từ 26/11 → 26/11", "Chỉ lượt bị từ chối ☐") + table(
        ["HTTT", "Dịch vụ", "Mục đích", "Lượt", "Từ đệm", "Bị từ chối", "Đối tượng khác nhau", "Giờ cao điểm"], [
            ["<span class='mono'>HT-MOTCUA</span>", "bhxh-tra-ho", "Giải quyết thủ tục hành chính", "11.840", "8.402", "4", "612 " + tag("warn", "Vượt ngưỡng"), "09:00"],
            ["<span class='mono'>HT-TUPHAP</span>", "lltp-tra-trang-thai", "Cấp phiếu lý lịch tư pháp", "4.600", "0", "0", "389", "10:00"],
            ["<span class='mono'>HT-YTE</span>", "dkdn-moi-nhat", "Cấp phép hoạt động", "2.120", "1.870", "1", "94", "08:00"],
            ["<span class='mono'>HT-LDTBXH</span>", "bhxh-tra-ho", "Chi trả trợ cấp", "3.900", "2.790", "0", "301", "14:00"]], "Nhật ký khai thác") + '</div>')

# 14 Sự cố chữ ký
SCREENS["14"] = ("Sự cố chữ ký", "Tích hợp / Kết nối quốc gia / Sự cố chữ ký",
    head("Sự cố chữ ký", "Giải trừ giữ an ninh…") +
    '<div class="alert e" role="alert"><b>Nền tảng <span class="mono">ndxp-t68</span> đang ở trạng thái giữ an ninh (SECURITY_HOLD):</b> 5 sự cố chữ ký trong 10 phút. Lượt gọi mới bị từ chối cho tới khi Cán bộ ATTT giải trừ.</div>' +
    '<div class="grid3"><div class="card">' + table(["Mã", "Loại", "Giao dịch", "Phát hiện", "Người xử lý", "Trạng thái"], [
        ["<span class='mono'>SI-0031</span>", "Chữ ký phản hồi sai", "<span class='mono'>T68-261126-6MC4</span>", "14:01", "—", tag("err", "Mở")],
        ["<span class='mono'>SI-0030</span>", "Chứng thư ngoài chuỗi tin cậy", "<span class='mono'>T68-261126-6MA1</span>", "14:00", "Bình (SO)", tag("warn", "Đã xác nhận")],
        ["<span class='mono'>SI-0029</span>", "Thời điểm ký lệch", "<span class='mono'>T68-261125-2QD8</span>", "25/11", "Bình (SO)", tag("ok", "Đã giải quyết")]], "Sự cố chữ ký") + '</div>' +
    '<div class="card raised"><h3 style="margin-top:0">SI-0031</h3><dl class="dl" style="grid-template-columns:110px 1fr"><dt>Loại</dt><dd>Chữ ký phản hồi sai (ERR-14-109)</dd><dt>Dịch vụ</dt><dd>dkdn-moi-nhat</dd><dt>Chứng thư</dt><dd class="mono">ndxp-sign-root</dd><dt>Mã băm</dt><dd class="mono">e3b0…b855</dd></dl><div class="foot"><span class="btn">Xác nhận</span><span class="btn pri">Kết thúc…</span></div></div></div>')

# 15 Cắt chuyển
SCREENS["15"] = ("Cắt chuyển từ hệ cũ", "Tích hợp / Kết nối quốc gia / Cắt chuyển từ hệ cũ",
    head("Cắt chuyển từ kết nối NGSP cũ", "Nhập phụ lục NGSP", "+ Phiên chạy song song") +
    tabs(["Nhập cấu hình", "Chạy song song", "Xác nhận thu hồi khóa cũ"], 1) +
    '<div class="card">' + table(["Dịch vụ", "Phiên", "Mẫu", "Tỷ lệ khớp", "Số ngày đạt", "Sẵn sàng cắt chuyển"], [
        ["bhxh-tra-ho", "<span class='mono'>pr-014</span>", "12.480 / 1.000", "99,6% (≥ 99%)", "9 / 7", tag("ok", "Sẵn sàng")],
        ["lltp-tra-trang-thai", "<span class='mono'>pr-015</span>", "3.102 / 1.000", "98,1% (< 99%)", "2 / 7", tag("warn", "Chưa đạt")],
        ["dkdn-moi-nhat", "<span class='mono'>pr-016</span>", "880 / 1.000", "99,8%", "4 / 7", tag("warn", "Chưa đủ mẫu")]], "Chạy song song") +
    alert("w", "Dịch vụ ghi (đăng ký hộ tịch, nhận hồ sơ) <b>không chạy song song</b> (ERR-14-033); cắt chuyển một lần theo kế hoạch.") + '</div>')

# 16 Cài đặt
SCREENS["16"] = ("Cài đặt phân hệ", "Tích hợp / Kết nối quốc gia / Cài đặt phân hệ",
    head("Cài đặt phân hệ", "Khôi phục mặc định", "Lưu thay đổi") + tabs(["Gọi ra quốc gia", "Hạn mức, đệm", "Chứng thư, chữ ký", "Chiều vào, đồng bộ", "Giám sát, bất thường"], 1) +
    '<div class="card">' + table(["Khóa", "Giá trị", "Mặc định", "Miền", "Bảo mật", "Sửa gần nhất"], [
        ["<span class='mono'>14.quota.warn-levels</span>", "<div class='input' style='min-width:120px'>[70%, 85%, 95%]</div>", "[70%, 85%, 95%]", "tăng dần, 1…3 mức", "", "An · 20/11"],
        ["<span class='mono'>14.quota.background-defer-ratio</span>", "<div class='input'>0,7</div>", "0,7", "0,5…0,95", "", "—"],
        ["<span class='mono'>14.cache.max-ttl-seconds</span> ★", "<div class='input cell-edit'>43.200</div>", "86.400", "60…86.400", tag("warn", "Cần duyệt"), "hôm nay"],
        ["<span class='mono'>14.cache.stale-max-seconds</span>", "<div class='input'>86.400</div>", "86.400", "0…259.200", "", "—"],
        ["<span class='mono'>14.quota.window-mode</span>", "<div class='input'>CALENDAR ▾</div>", "CALENDAR", "CALENDAR, SLIDING", "", "—"]], "Tham số phân hệ") +
    alert("i", "★ Tham số bảo mật: thay đổi gửi người thứ hai duyệt (BR-14-022); giá trị mới có hiệu lực trong 30 giây sau khi duyệt.") + '</div>')

# 17 Duyệt
SCREENS["17"] = ("Duyệt yêu cầu của phân hệ", "Việc của tôi / Duyệt PH-14",
    head("Việc của tôi", "Lọc: Kết nối quốc gia ▾") + facets(["Chờ tôi duyệt 3", "Bật nền tảng 1", "Luật định tuyến 1", "Kích hoạt chứng thư 1", "Hạn mức 0"]) +
    '<div class="grid3" style="grid-template-columns:340px minmax(0,1fr)"><div class="card">' + table(["Yêu cầu", "Người đề nghị", "Gửi lúc"], [
        ["<b>Bật nền tảng ndop-t68</b><br><span class='muted'>ph14.platform-activate</span>", "An (TA)", "13:20"],
        ["Luật định tuyến ưu tiên 30", "Minh (IE)", "11:05"],
        ["Kích hoạt chứng thư t68-sign-2027", "Bình (SO)", "09:40"]], "Hàng đợi duyệt") + '</div>' +
    '<div class="card"><h3 style="margin-top:0">Bật nền tảng <span class="mono">ndop-t68</span> ở PROD</h3><dl class="dl" style="grid-template-columns:150px 1fr"><dt>Đề nghị bởi</dt><dd>An (TA), 13:20</dd><dt>Kiểm tra kết nối</dt><dd>' + tag("ok", "Đạt") + ' 13:50 · 612 ms</dd><dt>Đặc tả</dt><dd>' + tag("warn", "Tạm thời") + ' (PROVISIONAL)</dd><dt>Dịch vụ phụ thuộc</dt><dd>0 dịch vụ</dd></dl>' +
    alert("w", "Nền tảng dùng đặc tả tạm thời. Chỉ duyệt khi đã rà soát với đơn vị quản lý NDOP.") + '<div class="foot"><span class="btn danger">Từ chối…</span><span class="btn pri">Duyệt và bật</span></div></div></div>')

SCREENS["01"] = ("Tổng quan kết nối quốc gia", "Tích hợp / Kết nối quốc gia / Tổng quan", UI01)
SCREENS["09"] = ("Hạn mức và đệm", "Tích hợp / Kết nối quốc gia / Hạn mức và đệm", UI09)

for code, (title, crumb, body) in sorted(SCREENS.items()):
    (OUT / f"ui-14-{code}.html").write_text(shell(code, code, title, crumb, body), encoding="utf-8")
print(f"Đã sinh {len(SCREENS)} tệp HTML")
