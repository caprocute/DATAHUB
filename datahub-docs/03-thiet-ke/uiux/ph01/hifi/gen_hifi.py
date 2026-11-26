#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-01-01…17 (D03-06-PH01, mục "Ảnh hi-fi" của từng màn; UI-01-03, 06, 09 cũng là hình của D02-03-PH01 §10.2).
Dùng bộ kiểu hifi.css (sao từ ph19/hifi, tên token theo D03-05-02). Chạy: python3 gen_hifi.py && node shot.js
Dữ liệu trên ảnh là dữ liệu minh họa của tenant T68, không phải dữ liệu thật."""
import pathlib

OUT = pathlib.Path(__file__).parent
NAV = [("Hệ thống thành viên", "03"), ("Hàng đợi thẩm định", "05"), ("Rà soát quyền", "12"),
       ("Danh bạ đầu mối", "14"), ("Thống kê kết nạp", "17")]


def shell(code, active, title, crumb, body, extra=""):
    nav = "".join(f'<a class="{"on" if active == c else ""}" href="#">{n}</a>' for n, c in NAV)
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-01-{code} · {title}</title><link rel="stylesheet" href="hifi.css"></head><body>
<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Kết nối &amp; API</div><div class="search">Tìm HTTT, đầu mối, hồ sơ…  ⌘K</div><div class="sp"></div>
<span class="tray">Tỉnh mẫu T68</span><div class="avatar">TA</div></header>
<nav class="side" aria-label="Điều hướng chính"><div class="grp">Kết nối &amp; API</div>{nav}<div class="grp">Cá nhân</div><a href="#">Việc của tôi <span class="tag t-info">4</span></a></nav>
<main><div class="crumb">{crumb}</div>{body}</main></div>{extra}<div class="hint">Bản hi-fi minh họa · D03-06-PH01 · UI-01-{code}</div></body></html>"""


def rows(data):
    return "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in data)


def dot(c):
    return {"ok": "<span style='color:#0b6b3a'>●</span>", "warn": "<span style='color:#d08a00'>●</span>",
            "err": "<span style='color:#a11a1a'>●</span>", "no": "<span style='color:#9aa1ab'>○</span>"}[c]


UI03 = """
<div class="head"><h1>Hệ thống thành viên</h1><div class="sp"></div><span class="btn">Nhập từ hệ cũ</span><span class="btn">Xuất CSV</span><span class="btn pri">+ Tạo hồ sơ</span></div>
<div class="stats"><div class="stat on"><b>118</b><span>Tất cả</span></div><div class="stat"><b>86</b><span>Đang hoạt động</span></div><div class="stat"><b>9</b><span>Đang thẩm định</span></div><div class="stat"><b>3</b><span>Tạm ngừng</span></div><div class="stat"><b style="color:#a11a1a">6</b><span>Quá hạn rà soát</span></div></div>
<div class="card"><div class="toolbar"><span class="input" style="min-width:260px">Tìm mã, tên HTTT, đơn vị</span><span class="input">Trạng thái: Tất cả ▾</span><span class="input">Nhóm: Tất cả ▾</span><span class="input">Đơn vị: Tất cả ▾</span><span class="input">Cảnh báo: Tất cả ▾</span></div>
<table aria-label="Danh sách HTTT thành viên"><thead><tr><th></th><th>Mã · Tên</th><th>Đơn vị chủ quản</th><th>Nhóm</th><th>Trạng thái</th><th>Vai trò</th><th>Phạm vi</th><th>Lượt gọi 30 ngày</th><th>Rà soát gần nhất</th><th>Cảnh báo</th></tr></thead><tbody>""" + rows([
    [dot("err"), "<span class='mono'>HT-DATDAI</span><br><span class='muted'>CSDL đất đai</span>", "Sở TN&amp;MT", "3 · Di sản", "<span class='tag t-ok'>Hoạt động</span>", "CONSUMER, PROVIDER", "5", "182.400", "<span style='color:#a11a1a'>08/05/2026</span>", "<span class='tag t-err'>Quá hạn rà soát</span>"],
    [dot("warn"), "<span class='mono'>HT-TUPHAP</span><br><span class='muted'>Quản lý hộ tịch</span>", "Sở Tư pháp", "1 · Hiện đại", "<span class='tag t-ok'>Hoạt động</span>", "CONSUMER, PROVIDER", "7", "411.050", "12/09/2026", "<span class='tag t-warn'>Định danh còn 12 ngày</span>"],
    [dot("ok"), "<span class='mono'>HT-QLVB</span><br><span class='muted'>Quản lý văn bản</span>", "Văn phòng UBND", "2 · API hạn chế", "<span class='tag t-ok'>Hoạt động</span>", "PUBLISHER", "2", "96.310", "30/09/2026", ""],
    [dot("warn"), "<span class='mono'>HT-BHXH</span><br><span class='muted'>Bảo hiểm xã hội tỉnh</span>", "BHXH tỉnh", "2 · API hạn chế", "<span class='tag t-warn'>SANDBOX · kiểm thử</span>", "CONSUMER", "3", "—", "—", "<span class='tag t-warn'>SANDBOX 24 ngày</span>"],
    [dot("no"), "<span class='mono'>HT-YTE</span><br><span class='muted'>Quản lý khám chữa bệnh</span>", "Sở Y tế", "1 · Hiện đại", "<span class='tag t-info'>Đang thẩm định</span>", "CONSUMER", "4", "—", "—", "<span class='tag t-mute'>Chờ pháp lý · hạn 28/11</span>"],
    [dot("err"), "<span class='mono'>HT-GTVT</span><br><span class='muted'>Giấy phép lái xe</span>", "Sở GTVT", "2 · API hạn chế", "<span class='tag t-err'>Tạm ngừng</span>", "CONSUMER", "2", "0", "03/06/2026", "<span class='tag t-err'>Nghi lộ bí mật · SO</span>"],
    [dot("no"), "<span class='mono'>HT-DKKD</span><br><span class='muted'>Đăng ký kinh doanh</span>", "Sở KH&amp;ĐT", "1 · Hiện đại", "<span class='tag t-mute'>Bản nháp</span>", "CONSUMER", "—", "—", "—", "<span class='tag t-warn'>Thiếu căn cứ 2 mục</span>"],
]) + """</tbody></table><div class="foot" style="justify-content:space-between"><span class="muted">Hiển thị 1–7 / 118 · <span style='color:#0b6b3a'>●</span> bình thường · <span style='color:#d08a00'>●</span> cần chú ý · <span style='color:#a11a1a'>●</span> cần xử lý</span><span class="muted">Trang 1 / 17 · 7 dòng ▾</span></div></div>"""

UI06 = """
<div class="head"><h1>Thẩm định · HT-DATDAI</h1><span class="tag t-info">Đang thẩm định · vòng 1</span><span class="tag t-mute">HS-KN-2026-0042</span><div class="sp"></div></div>
<div class="tabs"><span>Kỹ thuật ✓</span><span class="on">Pháp lý (2/3)</span><span>ATTT</span></div>
<div class="card" style="margin-right:440px"><div class="muted" style="margin-bottom:8px">Sở TN&amp;MT · đề nghị khai thác dữ liệu để giải quyết thủ tục cấp giấy chứng nhận · hạn thẩm định <b>28/11/2026</b></div>
<table aria-label="Nhu cầu khai thác"><thead><tr><th>Loại dữ liệu</th><th>Phạm vi đề nghị</th><th>Mức</th><th>Căn cứ pháp lý</th><th>Kết luận</th></tr></thead><tbody>""" + rows([
    ["Thông tin công dân", "Tra cứu phục vụ giải quyết TTHC, gồm sức khỏe", "Hạn chế", "Luật 91/2025/QH15 · <a href='#'>xem</a>", "<span class='tag t-warn'>Thu hẹp</span><br><span class='muted'>Không gồm thông tin sức khỏe</span>"],
    ["Thông tin thửa đất", "Tra cứu theo số thửa", "Nội bộ", "<span style='color:#a11a1a'>Thiếu số, ngày văn bản</span>", "<span class='tag t-err'>Từ chối</span><br><span class='muted'>Chưa có văn bản cho phép</span>"],
    ["Giấy phép xây dựng", "Tra cứu theo mã hồ sơ", "Công khai", "Nghị định 15/2021 · <a href='#'>xem</a>", "<span style='white-space:nowrap'><span class='btn' style='padding:1px 7px;font-size:12px'>Chấp thuận</span> <span class='btn' style='padding:1px 7px;font-size:12px'>Thu hẹp</span> <span class='btn' style='padding:1px 7px;font-size:12px'>Từ chối</span></span>"],
    ["Hồ sơ mật (danh mục BMNN)", "Tra cứu toàn bộ", "—", "—", "<span class='tag t-mute'>Chỉ được từ chối</span><br><span class='muted'>Bí mật nhà nước, không kết nối</span>"],
]) + """</tbody></table>
<div class="warn" style="margin-top:10px"><b>Ý kiến chung.</b> Đề nghị đơn vị bổ sung căn cứ cho mục dữ liệu đất đai nếu thực sự cần.</div>
<div class="foot" style="justify-content:space-between"><span class="muted">Đã đánh giá 2 / 3 mục</span><span><span class="btn">Tham vấn</span> <span class="btn">Trả bổ sung</span> <span class="btn pri" style="opacity:.55">Hoàn tất</span></span></div></div>"""

UI06_DRAWER = """<div class="drawer" role="dialog" aria-label="Văn bản căn cứ"><h3 style="margin:0 0 4px">Luật 91/2025/QH15</h3><div class="muted" style="margin-bottom:12px">Tài liệu đính kèm · PDF · 1,2 MB · đã quét sạch</div>
<div class="card"><div class="muted">Điều 17. Xử lý dữ liệu cá nhân… (xem trước trang 12 trên 64)</div><div style="height:260px;margin-top:8px;border:1px dashed #c8ced8;border-radius:10px;display:flex;align-items:center;justify-content:center" class="muted">Xem trước văn bản</div></div>
<div class="foot"><span class="btn">Mở cơ sở dữ liệu văn bản pháp luật</span><span class="btn pri">Đóng</span></div></div>"""

UI09 = """<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-01-09 · Bàn giao thông tin xác thực</title><link rel="stylesheet" href="hifi.css"></head><body>
<div class="shell" style="grid-template-columns:1fr"><header class="top"><div class="logo"><b>Datahub</b> · Bàn giao thông tin kết nối</div><div class="sp"></div><span class="tray">Tỉnh mẫu T68</span><div class="avatar">AN</div></header>
<main style="max-width:760px;margin:0 auto;padding-top:28px">
<div class="head"><h1>HT-TUPHAP · môi trường thử (SANDBOX)</h1><span class="tag t-ok">Liên kết còn hiệu lực · hết hạn 27/11 09:12</span></div>
<div class="card"><div class="muted" style="margin-bottom:8px">Đăng nhập là <b>Nguyễn Văn An</b> (đầu mối kỹ thuật) · xác thực hai yếu tố lúc 09:14</div>
<table><tbody>""" + rows([
    ["<b>Mã ứng dụng (clientId)</b>", "<span class='mono'>t68-ht-tuphap-sbx</span>"],
    ["<b>Bí mật (clientSecret)</b>", "<span class='mono' style='background:#0f1b2d;color:#e8f0ff;padding:3px 10px;border-radius:8px'>dh_sb_7Qm2•••••••••••••••••••••••••9xTa</span> <span class='btn' style='padding:2px 10px'>Sao chép</span> <span class='btn' style='padding:2px 10px'>Tải về</span>"],
    ["<b>Điểm cuối lấy token</b>", "<span class='mono'>https://t68.datahub.gov.vn/auth/realms/t68/protocol/openid-connect/token</span>"],
    ["<b>Địa chỉ API thử</b>", "<span class='mono'>https://sandbox.t68.datahub.gov.vn/api</span>"],
    ["<b>Phương thức xác thực</b>", "client_credentials · chuỗi bí mật (giai đoạn chuyển tiếp, hạn 180 ngày)"],
    ["<b>Phạm vi</b>", "<span class='mono'>sandbox.call</span> (chưa có scope dữ liệu, cấp sau khi đăng ký sử dụng API)"],
    ["<b>Hạn mức</b>", "1.000 lượt mỗi ngày"],
]) + """</tbody></table></div>
<div class="warn" style="margin-top:12px"><b>Thông tin này chỉ hiển thị MỘT LẦN.</b> Lưu vào nơi an toàn ngay. Sau khi bấm "Đã lưu, đóng" hoặc rời trang, liên kết vô hiệu và bản sao bí mật bị hủy. Nếu làm mất, liên hệ quản trị tỉnh để xoay bí mật.</div>
<div class="foot" style="justify-content:space-between"><a href="#" class="muted">Hướng dẫn kết nối</a><span class="btn pri">Đã lưu, đóng</span></div></main></div>
<div class="hint">Bản hi-fi minh họa · D03-06-PH01 · UI-01-09</div></body></html>"""


# ---------------------------------------------------------------------------------------------
# Các màn còn lại (UI-01-01, 02, 04, 05, 07, 08, 10, 11, 12, 13, 14, 15, 16, 17)
# ---------------------------------------------------------------------------------------------
def tg(kind, text):
    return f"<span class='tag t-{kind}'>{text}</span>"


def bt(text, cls="", style=""):
    return f'<span class="btn {cls}" style="{style}">{text}</span>'


def tabs(items, on):
    return '<div class="tabs" role="tablist">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def facets(items, on=0):
    return '<div class="facets">' + "".join(f'<span class="{"on" if i == on else ""}">{x}</span>' for i, x in enumerate(items)) + "</div>"


def steps(items, on):
    out = ""
    for i, t in enumerate(items):
        c = "done" if i < on else ("on" if i == on else "")
        out += f'<div class="{c}">{"✓ " if i < on else f"{i + 1}. "}{t}</div>'
    return f'<div class="steps" aria-label="Các bước kết nạp">{out}</div>'


def alert(kind, text, extra=""):
    return f'<div class="alert {kind}" role="alert"><span>{text}</span><span class="sp"></span>{extra}</div>'


def tbl(head, data, label):
    th = "".join(f"<th>{h}</th>" for h in head)
    return f'<table aria-label="{label}"><thead><tr>{th}</tr></thead><tbody>{rows(data)}</tbody></table>'


def kpis(items):
    return f'<div class="kpis" style="--n:{len(items)}">' + "".join(f'<div class="kpi"><b>{v}</b><span>{l}</span>{("<small>" + s + "</small>") if s else ""}</div>' for v, l, s in items) + "</div>"


def field(label, value, err=False, w=""):
    return f'<div class="field" style="{w}"><label>{label}</label><div class="input{" cell-err" if err else ""}">{value}</div></div>'


NAV_ALL = {"01": "03", "02": "03", "04": "03", "07": "05", "08": "03", "10": "03", "11": "03", "15": "03", "16": "03"}

UI01 = (
    '<div class="head"><h1>Kết nạp hệ thống · HT-DATDAI</h1>' + tg("mute", "Bản nháp") + '<span class="muted">✓ Đã lưu tự động 09:41:12</span><div class="sp"></div>' + bt("Tải mẫu văn bản") + bt("Lưu và thoát") + "</div>"
    + steps(["Thông tin hệ thống", "Đầu mối", "Hồ sơ kỹ thuật và pháp lý", "Rà soát", "Gửi duyệt"], 2)
    + alert("e", "<b>Còn 1 mục thiếu căn cứ pháp lý.</b> Mục “Thông tin thửa đất” chưa có số, ngày, cơ quan ban hành văn bản cho phép khai thác. <span class='muted'>ERR-01-015</span>", bt("Đến mục", "", "height:26px"))
    + '<div class="grid3"><div><div class="card"><b>Hồ sơ năng lực kỹ thuật</b> <span class="muted">· nhóm HTTT đề xuất: <b>2 · API hạn chế</b></span><div class="grid-2e" style="margin-top:10px">'
    + field("Loại hệ thống", "Web ▾") + field("Công nghệ", "Java 8, Spring 4") + field("Có giao diện lập trình (API)", "Có") + field("Chuẩn đặc tả API", "OpenAPI ▾")
    + field("Giao thức", "REST ▾") + field("Mức quan trọng", "Bình thường ▾") + field("Kết nối đồng thời tối đa", "20") + field("Lượt gọi dự kiến mỗi ngày", "5.000")
    + '</div></div><div class="card" style="margin-top:12px"><div style="display:flex;align-items:center"><b>Nhu cầu khai thác dữ liệu</b><div class="sp" style="flex:1"></div>' + bt("+ Thêm mục", "pri", "height:28px") + "</div>"
    + tbl(["Chiều", "Loại dữ liệu", "Phạm vi đề nghị", "Mức", "Căn cứ pháp lý", "Tệp", ""], [
        ["Khai thác", "Thông tin công dân", "Tra cứu phục vụ giải quyết TTHC", tg("warn", "Hạn chế"), "Luật 91/2025/QH15 · 26/06/2025", "luat-91.pdf ✓", "⋯"],
        ["<span class='cell-err' style='display:block;margin:-4px -8px;padding:4px 8px'>Khai thác</span>", "<span class='cell-err' style='display:block;margin:-4px -8px;padding:4px 8px'>Thông tin thửa đất</span>", "Tra cứu theo số thửa", tg("info", "Nội bộ"), "<span style='color:#a11a1a'>Chưa khai · bắt buộc</span>", "—", "⋯"],
        ["Khai thác", "Giấy phép xây dựng", "Tra cứu theo mã hồ sơ", tg("ok", "Công khai"), "Nghị định 15/2021/NĐ-CP · 03/03/2021", "nd-15.pdf ✓", "⋯"],
        ["Cung cấp", "Tình trạng thửa đất", "Cho phép HTTT khác tra cứu", tg("info", "Nội bộ"), "—", "—", "⋯"],
    ], "Nhu cầu khai thác")
    + '<div class="foot" style="justify-content:space-between"><span class="muted">4 mục · 1 thiếu căn cứ</span><span>' + bt("‹ Quay lại") + " " + bt("Tiếp tục ›", "pri") + "</span></div></div></div>"
    + '<div><div class="card"><b>Mẫu văn bản và hướng dẫn</b><div style="margin-top:8px;line-height:2"><a href="#">Mẫu văn bản đề nghị kết nạp.docx</a><br><a href="#">Hướng dẫn khai nhu cầu khai thác.pdf</a><br><a href="#">Danh mục dữ liệu bí mật nhà nước (tra cứu)</a></div></div>'
    + '<div class="card" style="margin-top:12px"><b>Tài liệu đính kèm</b><div class="muted" style="margin:6px 0">Tối đa 20 MB mỗi tệp · PDF, DOCX, XLSX, PNG, JPG</div><div style="border:1px dashed #b8c2d1;border-radius:10px;padding:18px;text-align:center" class="muted">Kéo thả tệp vào đây hoặc bấm để chọn</div><div style="margin-top:8px">📄 van-ban-de-nghi.pdf <span class="muted">· 1,4 MB · đã quét sạch</span></div></div></div></div>'
)

UI02 = (
    '<div class="head"><h1>Tiến độ hồ sơ · HT-YTE</h1>' + tg("info", "Đang thẩm định · vòng 2") + tg("mute", "HS-KN-2026-0051") + '<div class="sp"></div>' + bt("Rút hồ sơ") + "</div>"
    + alert("w", "<b>Hồ sơ đã được trả bổ sung ở vòng 1.</b> Đã nộp lại 24/11/2026. Đang chờ: <b>Quản trị tỉnh</b> (thẩm định pháp lý) · hạn 28/11/2026, còn 2 ngày làm việc.")
    + '<div class="grid3"><div class="card"><b>Dòng thời gian</b><div class="vtl" style="margin-top:12px">'
    + "<div><b>Nộp hồ sơ (vòng 2)</b> · 24/11/2026 08:30 <span class='muted'>· ở bước trước 4 ngày</span></div>"
    + "<div><b>Phân công thẩm định</b> · 24/11/2026 14:05 <span class='muted'>· 5 giờ 35 phút</span></div>"
    + "<div><b>Thẩm định kỹ thuật</b> · giữ kết luận vòng 1 ✓ <span class='muted'>(dữ liệu liên quan không đổi)</span></div>"
    + "<div><b>Thẩm định pháp lý</b> · <span class='tag t-info'>đang xử lý</span> <span class='muted'>· 1 ngày 02 giờ</span></div>"
    + "<div><b>Thẩm định ATTT</b> · <span class='tag t-info'>đang xử lý</span></div>"
    + "<div style='opacity:.55'><b>Phê duyệt</b> · chờ</div><div style='opacity:.55'><b>Cấp định danh · bàn giao · kiểm thử · kích hoạt</b> · chưa tới</div></div></div>"
    + '<div><div class="card"><b>Yêu cầu bổ sung ở vòng 1</b><div class="muted" style="margin:4px 0 8px">Trả ngày 18/11/2026 bởi quản trị tỉnh</div>'
    + "<div class='warn'>Bổ sung văn bản cho phép khai thác “Dữ liệu bệnh án”: số, ngày, cơ quan ban hành. Thu hẹp phạm vi nếu chưa có văn bản.</div>"
    + '<ul style="margin:10px 0 0;padding-left:18px;line-height:1.8"><li>Trường cần sửa: <span class="mono">dataDemands[2].legalBasis</span> <span style="color:#0b6b3a">✓ đã sửa</span></li><li>Trường cần sửa: <span class="mono">contacts[TECHNICAL]</span> <span style="color:#0b6b3a">✓ đã sửa</span></li></ul></div>'
    + '<div class="card" style="margin-top:12px"><b>Thông báo</b><div class="muted" style="margin-top:6px">Mỗi lần hồ sơ đổi trạng thái, hệ thống gửi thông báo trong ứng dụng và thư chỉ chứa liên kết tới trang này.</div></div></div></div>'
)

UI04 = (
    '<div class="head"><h1>HT-TUPHAP · Quản lý hộ tịch</h1>' + tg("ok", "Hoạt động") + tg("mute", "CONSUMER, PROVIDER") + '<div class="sp"></div>' + bt("Sửa hồ sơ") + bt("Đề nghị mở rộng phạm vi") + bt("Tạm ngừng ▾", "danger") + "</div>"
    + alert("w", "<b>Định danh PRODUCTION hết hạn sau 12 ngày</b> (08/12/2026). Xoay vòng trước hạn để không gián đoạn.", bt("Xoay vòng", "", "height:26px"))
    + tabs(["Hồ sơ", "Ứng dụng và thông tin xác thực", "Đầu mối", "API đang dùng", "Phụ thuộc", "Lịch sử"], 0)
    + '<div class="grid3"><div class="card"><dl class="dl">'
    + "<dt>Đơn vị chủ quản</dt><dd>Sở Tư pháp</dd><dt>Cấp độ ATTT</dt><dd>L3 · QĐ 1234/QĐ-UBND ngày 12/03/2026</dd>"
    + "<dt>Nhóm HTTT</dt><dd>1 · Hiện đại (có API OpenAPI)</dd><dt>Loại hệ thống</dt><dd>Cấp tỉnh</dd>"
    + "<dt>Địa chỉ cơ sở</dt><dd class='mono'>https://hotich.t68.gov.vn/api</dd><dt>Danh sách IP cho phép</dt><dd class='mono'>10.20.0.0/24</dd>"
    + "<dt>Kích hoạt</dt><dd>14/07/2026 10:05</dd><dt>Rà soát gần nhất</dt><dd>12/09/2026</dd>"
    + "<dt>Mô tả</dt><dd style='grid-column:2/5'>Cấp, quản lý giấy khai sinh, giấy chứng tử, đăng ký kết hôn trên địa bàn tỉnh.</dd></dl></div>"
    + '<div><div class="card"><b>Trần phạm vi đã duyệt</b><div style="margin-top:8px;line-height:2">'
    + "Thông tin công dân · <span class='muted'>Hạn chế</span><br>Giấy phép xây dựng · <span class='muted'>Công khai</span><br>Tình trạng thửa đất (cung cấp) · <span class='muted'>Nội bộ</span></div></div>"
    + '<div class="card" style="margin-top:12px"><b>Việc gần đây</b><div class="vtl" style="margin-top:8px"><div>12/09/2026 · Rà soát quyền kỳ RS-2026-H1: giữ nguyên</div><div>14/07/2026 · Kích hoạt môi trường thật</div></div></div></div></div>'
)

UI05 = (
    '<div class="head"><h1>Hàng đợi thẩm định</h1><div class="sp"></div>' + bt("Phân công hàng loạt") + "</div>"
    + facets(["Chờ nhận 4", "Của tôi 3", "Quá hạn 2", "Đang tham vấn 1", "Chờ phê duyệt 2"], 1)
    + '<div class="card"><div class="toolbar"><span class="input" style="min-width:240px">Tìm mã hồ sơ, tên HTTT, đơn vị</span><span class="input">Loại bước: Tất cả ▾</span><span class="input">Hạn: Tất cả ▾</span><span class="input">Người xử lý: Tôi ▾</span></div>'
    + tbl(["", "Hồ sơ · HTTT", "Đơn vị", "Bước", "Vòng", "Hạn", "Người xử lý", "Trạng thái", ""], [
        ["☐", "<span class='mono'>HS-KN-2026-0042</span><br><b>HT-DATDAI</b>", "Sở TN&amp;MT", "Pháp lý", "1", "<span style='color:#a11a1a'>Quá 1 ngày · 26/11</span>", "Bạn (TA)", tg("err", "Quá hạn"), bt("Mở", "pri", "height:26px")],
        ["☐", "<span class='mono'>HS-KN-2026-0051</span><br><b>HT-YTE</b>", "Sở Y tế", "Pháp lý", "2", "28/11 · còn 2 ngày", "Bạn (TA)", tg("info", "Đang xử lý"), bt("Mở", "pri", "height:26px")],
        ["☐", "<span class='mono'>HS-KN-2026-0051</span><br><b>HT-YTE</b>", "Sở Y tế", "ATTT", "2", "28/11 · còn 2 ngày", "Trần Thị Bình (SO)", tg("info", "Đang xử lý"), bt("Mở", "", "height:26px")],
        ["☐", "<span class='mono'>HS-KN-2026-0053</span><br><b>HT-LDTBXH</b>", "Sở LĐ-TB&amp;XH", "Kỹ thuật", "1", "27/11 · còn 1 ngày", "—", tg("warn", "Chờ nhận"), bt("Nhận việc", "pri", "height:26px")],
        ["☐", "<span class='mono'>HS-KN-2026-0054</span><br><b>HT-GDDT</b>", "Sở GD&amp;ĐT", "ATTT", "1", "29/11 · còn 3 ngày", "—", tg("warn", "Chờ nhận"), bt("Nhận việc", "", "height:26px")],
        ["☐", "<span class='mono'>HS-KN-2026-0049</span><br><b>HT-NOIVU</b>", "Sở Nội vụ", "Kỹ thuật", "1", "Tạm dừng đồng hồ", "Lê Văn Cường (IE)", tg("mute", "Tham vấn"), bt("Mở", "", "height:26px")],
    ], "Hàng đợi thẩm định")
    + '<div class="foot" style="justify-content:space-between"><span class="muted">Hiển thị 1–6 / 11 · hạn mỗi bước 2 ngày làm việc (tham số)</span><span class="muted">Trang 1 / 2</span></div></div>'
)

UI07 = (
    '<div class="head"><h1>Duyệt kết nạp · HT-DATDAI</h1>' + tg("info", "Chờ phê duyệt") + tg("mute", "HS-KN-2026-0042") + '<div class="sp"></div></div>'
    + '<div style="display:grid;grid-template-columns:300px minmax(0,1fr);gap:14px"><div class="card"><b>Việc của tôi</b><div class="muted" style="margin:2px 0 8px">4 việc chờ</div>'
    + "<div class='tree'><div class='on'>Duyệt kết nạp HT-DATDAI<br><span class='muted'>Sở TN&amp;MT · hạn 27/11</span></div><div>Duyệt thay đổi kỹ thuật HT-QLVB<br><span class='muted'>Văn phòng UBND · hạn 28/11</span></div><div>Xác nhận thao tác khẩn HT-GTVT<br><span class='muted'>Cán bộ ATTT · hạn 26/11 17:00</span></div><div>Duyệt chấm dứt HT-CU01<br><span class='muted'>Sở Công Thương</span></div></div></div>"
    + '<div class="card"><dl class="dl"><dt>Đơn vị</dt><dd>Sở TN&amp;MT</dd><dt>Cấp độ ATTT</dt><dd>L3</dd><dt>Nhóm xác nhận</dt><dd>3 · Di sản (CSDL)</dd><dt>Xác thực tối thiểu</dt><dd>Khóa công khai (PRIVATE_KEY_JWT)</dd><dt>Hạn mức đề xuất</dt><dd>20.000 lượt/ngày</dd><dt>Tác động hạn mức quốc gia</dt><dd>' + tg("ok", "Thấp · 8%") + "</dd></dl>"
    + '<div style="margin:12px 0 4px"><b>Trần phạm vi sẽ cấp</b></div>'
    + tbl(["Loại dữ liệu", "Phạm vi được duyệt", "Mức", "Kết luận"], [
        ["Thông tin công dân", "Tra cứu phục vụ TTHC, <b>không gồm thông tin sức khỏe</b>", "Hạn chế", tg("warn", "Thu hẹp")],
        ["Giấy phép xây dựng", "Tra cứu theo mã hồ sơ", "Công khai", tg("ok", "Chấp thuận")],
        ["Thông tin thửa đất", "—", "Nội bộ", tg("err", "Từ chối")],
    ], "Trần phạm vi")
    + '<div class="grid-2e" style="margin-top:12px"><div class="raised card"><b>Kỹ thuật</b> ' + tg("ok", "Hoàn tất") + '<div class="muted" style="margin-top:4px">Lê Văn Cường (IE): nhóm 3 xác nhận, kết nối CSDL qua CDC.</div></div><div class="raised card"><b>Pháp lý · ATTT</b> ' + tg("ok", "Hoàn tất") + '<div class="muted" style="margin-top:4px">Đề nghị bổ sung căn cứ cho dữ liệu đất đai nếu thực sự cần.</div></div></div>'
    + '<div class="warn" style="margin-top:12px">Bạn chưa tham gia hồ sơ này (bốn mắt đạt). Bấm “Duyệt” sẽ yêu cầu xác thực lại hai yếu tố trong 5 phút.</div>'
    + '<div class="foot" style="justify-content:flex-end">' + bt("Trả bổ sung") + bt("Từ chối", "danger") + bt("Duyệt kết nạp", "pri") + "</div></div></div>"
)

UI08 = (
    '<div class="head"><h1>Định danh ứng dụng · HT-TUPHAP</h1>' + tg("ok", "Hoạt động") + '<div class="sp"></div>' + bt("Đăng ký khóa công khai") + bt("Tạo lại liên kết bàn giao") + "</div>"
    + tabs(["Hồ sơ", "Ứng dụng và thông tin xác thực", "Đầu mối", "API đang dùng", "Phụ thuộc", "Lịch sử"], 1)
    + '<div class="card"><b>Tiến độ cấp định danh PRODUCTION</b><div style="margin:10px 0">' + steps(["Tạo client ở PH-12", "Tạo consumer ở cổng", "Gắn hạn mức", "Bàn giao một lần", "Hoàn tất"], 4) + "</div></div>"
    + '<div class="card" style="margin-top:12px"><b>Danh sách định danh</b> <span class="muted">· không hiển thị bí mật</span>'
    + tbl(["Môi trường", "Mã ứng dụng", "Phương thức", "Phạm vi", "Hạn", "Trạng thái", "Bàn giao", ""], [
        ["<span class='tag t-warn' style='border-width:2px'>PRODUCTION</span>", "<span class='mono'>t68-ht-tuphap</span>", "Khóa công khai · ES256", "5", "08/12/2026 " + tg("warn", "còn 12 ngày"), tg("ok", "Hoạt động"), "Đã nhận 14/07", "⋯"],
        ["<span class='tag t-mute' style='border-width:2px'>SANDBOX</span>", "<span class='mono'>t68-ht-tuphap-sbx</span>", "Chuỗi bí mật (chuyển tiếp)", "1", "30/04/2027", tg("info", "Đang xoay · tới 03/12"), "Liên kết mới còn 22 giờ", "⋯"],
        ["<span class='tag t-mute' style='border-width:2px'>SANDBOX</span>", "<span class='mono'>t68-ht-tuphap-sbx (cũ)</span>", "Chuỗi bí mật", "1", "—", tg("err", "Đã thu hồi"), "—", "⋯"],
    ], "Danh sách định danh")
    + '<div class="foot" style="justify-content:space-between"><span class="muted">Xoay vòng: thông tin cũ và mới cùng hiệu lực tối đa 7 ngày · thu hồi cần lý do và xác thực lại hai yếu tố</span><span>' + bt("Xoay vòng") + " " + bt("Thu hồi", "danger") + "</span></div></div>"
)

UI10 = (
    '<div class="head"><h1>Kiểm thử SANDBOX · HT-BHXH</h1>' + tg("warn", "SANDBOX_READY · 24 ngày") + '<div class="sp"></div>' + bt("Làm mới kết quả") + "</div>"
    + kpis([("5", "Lần xác thực thành công", "đạt tiêu chí ≥ 1"), ("2 / 3", "Lượt gọi API thành công", "<span style='color:#a11a1a'>chưa đạt, cần 3 trong 7 ngày</span>"), ("4", "Lỗi invalid_scope", ""), ("0", "Lỗi invalid_client", "")])
    + '<div class="grid3"><div class="card"><b>Lỗi nổi bật và cách khắc phục</b>' + tbl(["Mã lỗi từ cổng", "Số lần", "Hướng dẫn"], [
        ["<span class='mono'>invalid_scope</span>", "4", "Chỉ dùng scope môi trường thử. Scope dữ liệu cấp sau khi đăng ký sử dụng API."],
        ["<span class='mono'>ip_not_allowed</span>", "1", "Thêm địa chỉ máy chủ vào danh sách IP cho phép (xin quản trị tỉnh)."],
    ], "Lỗi kiểm thử") + '<div class="muted" style="margin-top:8px">Kết quả cập nhật mỗi 5 phút · lần cuối 09:40 · đơn vị và quản trị tỉnh cùng thấy.</div></div>'
    + '<div class="card"><b>Điều kiện kích hoạt</b><ul style="list-style:none;padding:0;margin:8px 0;line-height:2"><li><span style="color:#a11a1a">✗</span> Kiểm thử đạt (2/3 lượt gọi)</li><li><span style="color:#0b6b3a">✓</span> Có đầu mối kỹ thuật hoạt động</li><li><span style="color:#0b6b3a">✓</span> Cấp độ ATTT đạt yêu cầu trần phạm vi</li><li><span style="color:#0b6b3a">✓</span> Định danh SANDBOX còn hạn</li></ul>'
    + '<div class="foot" style="justify-content:flex-end;margin-top:6px"><span class="btn pri" style="opacity:.5" title="Chưa đủ lượt kiểm thử đạt ở môi trường thử">Kích hoạt môi trường thật</span></div><div class="muted" style="text-align:right;margin-top:4px">Chưa đủ lượt kiểm thử đạt ở môi trường thử. Xem kết quả và khắc phục.</div></div></div>'
)

UI11_BG = (
    '<div class="head"><h1>HT-TUPHAP · Quản lý hộ tịch</h1>' + tg("ok", "Hoạt động") + "</div>" + tabs(["Hồ sơ", "Ứng dụng và thông tin xác thực", "Đầu mối", "API đang dùng", "Phụ thuộc", "Lịch sử"], 4)
    + '<div class="card" style="margin-right:560px"><b>Phụ thuộc</b>' + tbl(["Nguồn", "Đối tượng", "Đơn vị phụ thuộc", "30 ngày"], [
        ["PH-02", "Đăng ký sử dụng: Tra cứu giấy khai sinh", "Sở Y tế", "1.204"], ["PH-02", "Đăng ký sử dụng: Xác minh hộ tịch", "Công an tỉnh", "9.318"], ["PH-04", "Luồng: ho-tich-sang-bhxh", "Sở Tư pháp", "411"], ["PH-10", "Topic t68.civil.birth.registered.v1", "BHXH tỉnh", "—"]], "Phụ thuộc") + "</div>"
)
UI11_DRAWER = (
    '<div class="drawer" role="dialog" aria-label="Tạm ngừng HTTT" style="width:540px;overflow:auto"><h3 style="margin:0 0 2px">Tạm ngừng HT-TUPHAP</h3><div class="muted" style="margin-bottom:10px">Chặn mọi lượt gọi trong ≤ 60 giây · giữ nguyên cấu hình để khôi phục</div>'
    + '<div class="card"><b>Tác động</b> ' + tg("warn", "Trung bình") + '<div class="muted" style="margin:4px 0 6px">7 đối tượng phụ thuộc · 3 HTTT khác bị ảnh hưởng</div>'
    + "<div style='font-size:12.5px;line-height:1.8'>Đăng ký sử dụng ×3 (Sở Y tế, Công an tỉnh, BHXH tỉnh)<br>Luồng tích hợp ×2 · Topic ×2<br><a href='#'>Xem danh sách và đầu mối để báo trước</a></div></div>"
    + field("Mã lý do", "Bảo trì theo kế hoạch ▾") + field("Lý do (bắt buộc)", "Nâng cấp cơ sở dữ liệu hộ tịch, dự kiến 4 giờ")
    + '<div class="field"><label>Thời hạn dự kiến</label><div class="input">27/11/2026 18:00</div></div>'
    + '<div style="margin:6px 0 10px">☑ Tôi đã xem 7 đối tượng phụ thuộc và đồng ý tiếp tục</div>'
    + '<div class="warn">Cần xác thực lại hai yếu tố trong 5 phút để thực hiện.</div><div class="foot">' + bt("Hủy") + bt("Tạm ngừng", "danger") + "</div></div>"
)

UI12 = (
    '<div class="head"><h1>Rà soát quyền · Kỳ RS-2026-H2</h1>' + tg("info", "Đang chờ phản hồi") + '<div class="sp"></div>' + bt("Báo cáo rà soát") + bt("Gửi nhắc đơn vị") + "</div>"
    + '<div class="stats"><div class="stat"><b>31 / 54</b><span>Đơn vị đã phản hồi</span><div class="prog" style="margin-top:6px"><i style="width:57%"></i></div></div><div class="stat"><b>118</b><span>Phạm vi cần rà soát</span></div><div class="stat"><b style="color:#a11a1a">14</b><span>Không dùng trong kỳ</span></div><div class="stat"><b style="color:#a11a1a">3</b><span>Căn cứ hết hiệu lực</span></div><div class="stat"><b>9</b><span>Đơn vị chưa phản hồi</span></div></div>'
    + '<div class="card"><div class="toolbar"><span class="input">Kỳ: RS-2026-H2 ▾</span><span class="input">Cờ: Tất cả ▾</span><span class="input">Đơn vị: Tất cả ▾</span><span class="input">Đề xuất: Tất cả ▾</span><div class="sp" style="flex:1"></div><span class="tag t-info">Đã chọn 3</span>' + bt("Thu hẹp", "", "height:26px") + bt("Thu hồi phạm vi", "danger", "height:26px") + "</div>"
    + tbl(["", "HTTT", "Phạm vi", "Lượt dùng kỳ", "Lần dùng cuối", "Căn cứ", "Phản hồi đơn vị", "Đề xuất", "Quyết định"], [
        ["☑", "<b>HT-GTVT</b>", "Dữ liệu dân cư", "0", "03/06/2026", "Còn hiệu lực", tg("mute", "Chưa phản hồi"), tg("err", "Thu hẹp"), "—"],
        ["☑", "<b>HT-DATDAI</b>", "Thông tin công dân", "182.400", "25/11/2026", "<span style='color:#a11a1a'>Hết hiệu lực 30/09</span>", "Còn cần", tg("err", "Thu hồi"), "—"],
        ["☑", "<b>HT-BHXH</b>", "Thông tin việc làm", "0", "—", "Còn hiệu lực", "Không cần nữa", tg("warn", "Thu hồi"), "—"],
        ["☐", "<b>HT-TUPHAP</b>", "Giấy khai sinh", "411.050", "26/11/2026", "Còn hiệu lực", "Còn cần", tg("ok", "Giữ"), tg("ok", "Giữ")],
        ["☐", "<b>HT-QLVB</b>", "Văn bản điều hành", "96.310", "26/11/2026", "Không thời hạn", "Còn cần", tg("ok", "Giữ"), "—"],
        ["☐", "<b>HT-YTE</b>", "Thông tin sức khỏe", "12", "02/04/2026", "Còn hiệu lực", tg("mute", "Chưa phản hồi"), tg("warn", "Thu hẹp"), "—"],
    ], "Mục rà soát")
    + '<div class="foot" style="justify-content:space-between"><span class="muted">Mỗi quyết định cần lý do; thu hồi cần xác thực lại hai yếu tố</span><span class="muted">Hiển thị 1–6 / 118</span></div></div>'
)

UI13 = """<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-01-13 · Xác nhận của đơn vị</title><link rel="stylesheet" href="hifi.css"></head><body>
<div class="shell" style="grid-template-columns:1fr"><header class="top"><div class="logo"><b>Datahub</b> · Xác nhận phạm vi kết nối</div><div class="sp"></div><span class="tray">Tỉnh mẫu T68</span><div class="avatar">LH</div></header>
<main style="max-width:980px;margin:0 auto;padding-top:26px">
<div class="head"><h1>Sở Tư pháp · Xác nhận phạm vi kỳ RS-2026-H2</h1>""" + tg("ok", "Liên kết còn hiệu lực · tới 26/12/2026") + """</div>
<div class="card"><div class="muted" style="margin-bottom:8px">Đăng nhập là <b>Lê Thị Hoa</b> (đầu mối nghiệp vụ, Sở Tư pháp) · xác thực hai yếu tố lúc 14:02. Chọn cho từng phạm vi dưới đây; đơn vị không trả lời trước <b>26/12/2026</b> sẽ được đề xuất thu hẹp.</div>
""" + tbl(["HTTT", "Phạm vi", "Dùng thực tế 12 tháng", "Lần dùng cuối", "Đơn vị cho biết"], [
    ["<b>HT-TUPHAP</b>", "Giấy khai sinh", "4,9 triệu lượt", "26/11/2026", "<span class='btn pri' style='padding:1px 9px;font-size:12px'>Còn cần</span> <span class='btn' style='padding:1px 9px;font-size:12px'>Thu hẹp</span> <span class='btn' style='padding:1px 9px;font-size:12px'>Không cần nữa</span>"],
    ["<b>HT-TUPHAP</b>", "Thông tin công dân", "0 lượt", "<span style='color:#a11a1a'>Chưa từng</span>", "<span class='btn' style='padding:1px 9px;font-size:12px'>Còn cần</span> <span class='btn' style='padding:1px 9px;font-size:12px'>Thu hẹp</span> <span class='btn pri' style='padding:1px 9px;font-size:12px'>Không cần nữa</span>"],
    ["<b>HT-HOTICH-DB</b>", "Hộ tịch (đọc CSDL)", "128.300 lượt", "20/11/2026", "<span class='btn' style='padding:1px 9px;font-size:12px'>Còn cần</span> <span class='btn pri' style='padding:1px 9px;font-size:12px'>Thu hẹp</span> <span class='btn' style='padding:1px 9px;font-size:12px'>Không cần nữa</span><div class='input' style='margin-top:4px;width:100%'>Chỉ cần số liệu tổng hợp, không cần họ tên</div>"],
], "Phạm vi của đơn vị") + """</div>
<div class="warn" style="margin-top:12px">Phản hồi của anh/chị được ghi nhận kèm tên và thời điểm. Có thể đổi ý cho tới khi gửi.</div>
<div class="foot" style="justify-content:space-between"><span class="muted">Đã chọn 3 / 3 phạm vi</span><span class="btn pri">Gửi phản hồi</span></div></main></div>
<div class="hint">Bản hi-fi minh họa · D03-06-PH01 · UI-01-13</div></body></html>"""

UI14 = (
    '<div class="head"><h1>Danh bạ đầu mối</h1><div class="sp"></div>' + bt("Xuất danh bạ") + "</div>"
    + '<div class="grid2"><div class="card" style="align-self:start"><b>Cần xử lý</b><div style="margin-top:8px;font-size:13px;line-height:1.7"><div class="alert e" style="margin-bottom:8px;display:block"><b>2 tổ chức thiếu đầu mối kỹ thuật</b><br>Sở Công Thương · UBND huyện Hòa Bình</div><div class="alert w" style="margin-bottom:8px;display:block"><b>3 đầu mối có thư không hoạt động</b></div><div class="alert i" style="display:block"><b>11 đầu mối chưa xác nhận trên 12 tháng</b></div></div></div>'
    + '<div class="card"><div class="toolbar"><span class="input" style="min-width:260px">Tìm tên, tổ chức, HTTT</span><span class="input">Loại đầu mối: Tất cả ▾</span><span class="input">Tổ chức: Tất cả ▾</span></div>'
    + tbl(["Họ tên · Chức vụ", "Tổ chức", "HTTT", "Loại", "Điện thoại", "Thư điện tử", "Xác nhận gần nhất"], [
        ["<b>Nguyễn Văn An</b><br><span class='muted'>Chuyên viên CNTT</span>", "Sở Tư pháp", "HT-TUPHAP", tg("info", "Kỹ thuật"), "0912 345 678", "an.nv@tuphap.t68.gov.vn", "12/09/2026"],
        ["<b>Lê Thị Hoa</b><br><span class='muted'>Phó trưởng phòng</span>", "Sở Tư pháp", "HT-TUPHAP", tg("mute", "Nghiệp vụ"), "0903 221 004", "hoa.lt@tuphap.t68.gov.vn", "30/10/2026"],
        ["<b>Phạm Quốc Dũng</b><br><span class='muted'>Cán bộ CNTT</span>", "Sở TN&amp;MT", "HT-DATDAI", tg("info", "Kỹ thuật"), "0988 120 345", "dung.pq@tnmt.t68.gov.vn", "<span style='color:#7a5200'>14/08/2025 · nhắc</span>"],
        ["<b>Vũ Minh Tuấn</b><br><span class='muted'>Chuyên viên</span>", "Văn phòng UBND", "HT-QLVB", tg("info", "Kỹ thuật"), "0977 654 321", "tuan.vm@ubnd.t68.gov.vn <span class='tag t-warn'>Thư không hoạt động</span>", "02/06/2026"],
        ["<b>Đỗ Thu Hà</b><br><span class='muted'>Quản trị hệ thống</span>", "BHXH tỉnh", "HT-BHXH", tg("info", "Kỹ thuật"), "0935 777 190", "ha.dt@bhxh.t68.gov.vn", "21/11/2026"],
    ], "Danh bạ đầu mối")
    + '<div class="foot" style="justify-content:space-between"><span class="muted">Chỉ hiện đầu mối công khai trong tỉnh · tra cứu tối đa 60 lượt mỗi phút</span><span class="muted">Trang 1 / 9</span></div></div></div>'
)

UI15 = (
    '<div class="head"><h1>Nhập HTTT từ hệ cũ</h1><div class="sp"></div>' + bt("Tải mẫu nhập") + "</div>"
    + steps(["Tải tệp", "Xem trước và ghép tổ chức", "Xác nhận ghi"], 1)
    + '<div class="stats"><div class="stat"><b>120</b><span>Bản ghi đã đọc (3 nguồn)</span></div><div class="stat"><b style="color:#0b6b3a">98</b><span>HTTT sẽ tạo (bản nháp)</span></div><div class="stat"><b style="color:#7a5200">7</b><span>Trùng HTTT đã có, bỏ qua</span></div><div class="stat"><b style="color:#a11a1a">15</b><span>Cần chọn tổ chức</span></div><div class="stat"><b>23</b><span>Cột bí mật đã bỏ, không nhập</span></div></div>'
    + alert("i", "Thông tin xác thực của hệ cũ <b>không được nhập</b>. Đơn vị phải hoàn tất hồ sơ để cấp lại định danh. Ghi tất cả hoặc không ghi gì.")
    + '<div class="card"><div class="toolbar"><span class="input">Hiển thị: Cần xử lý ▾</span><span class="input" style="min-width:240px">Tìm mã, tên</span></div><table aria-label="Xem trước nhập"><thead><tr><th>Mã hệ cũ</th><th>Tên HTTT (đã gộp)</th><th>Vai trò đã gộp</th><th>Tổ chức ghép được</th><th>Kết quả</th></tr></thead><tbody>'
    + '<tr class="d-add"><td class="mono">APIM-APP-0042</td><td>Quản lý hộ tịch</td><td>CONSUMER, PROVIDER</td><td>Sở Tư pháp ✓</td><td>' + tg("ok", "Tạo mới") + "</td></tr>"
    + '<tr class="d-add"><td class="mono">HUB-PUB-0007</td><td>Cổng dịch vụ công</td><td>PUBLISHER</td><td>Văn phòng UBND ✓</td><td>' + tg("ok", "Tạo mới") + "</td></tr>"
    + '<tr class="d-chg"><td class="mono">APIM-APP-0113</td><td>Quản lý khám chữa bệnh</td><td>CONSUMER</td><td><span class="input" style="min-width:0;height:24px">Chọn tổ chức (gợi ý: Sở Y tế) ▾</span></td><td>' + tg("warn", "Cần chọn tổ chức") + "</td></tr>"
    + '<tr class="d-del"><td class="mono">APIM-APP-0007</td><td>Đăng ký kinh doanh</td><td>CONSUMER</td><td>Sở KH&amp;ĐT ✓</td><td>' + tg("err", "Trùng HT-DKKD · bỏ qua") + "</td></tr>"
    + '<tr class="d-add"><td class="mono">HUB-SUB-0021</td><td>Bảo hiểm xã hội tỉnh</td><td>SUBSCRIBER</td><td>BHXH tỉnh ✓</td><td>' + tg("ok", "Tạo mới") + "</td></tr></tbody></table>"
    + '<div class="foot" style="justify-content:space-between"><span class="muted">Hiển thị 5 / 120 · 15 dòng cần xử lý trước khi xác nhận</span><span>' + bt("Hủy") + " " + bt("Xác nhận tạo 98 hồ sơ nháp", "pri", "opacity:.5") + "</span></div></div>"
)

UI16 = (
    '<div class="head"><h1>Tham số kết nạp</h1><span class="muted">Khóa <span class="mono">onboarding.*</span> của tỉnh T68</span><div class="sp"></div>' + bt("Lịch sử thay đổi") + "</div>"
    + '<div class="grid3"><div class="card"><div class="toolbar"><span class="input" style="min-width:240px">Tìm khóa</span><span class="input">Nhóm: Tất cả ▾</span></div>'
    + tbl(["Khóa", "Giá trị", "Mặc định", "Miền", "Cập nhật"], [
        ["<span class='mono'>review.slaWorkingDays</span><br><span class='muted'>Hạn mỗi bước thẩm định (ngày làm việc)</span>", "2", "2", "1…10", "10/10/2026 · TA"],
        ["<span class='mono'>approve.slaWorkingDays</span><br><span class='muted'>Hạn phê duyệt</span>", "1", "1", "1…10", "—"],
        ["<span class='mono'>handover.ttlHours</span><br><span class='muted'>Hạn liên kết bàn giao (giờ)</span>", "<div class='cell-edit input' style='min-width:0'>48</div>", "24", "1…72", "—"],
        ["<span class='mono'>credential.rotationOverlapDays</span><br><span class='muted'>Thời gian chuyển tiếp xoay vòng (ngày)</span>", "7", "7", "1…14", "—"],
        ["<span class='mono'>sandbox.requiredSuccessfulCalls</span><br><span class='muted'>Lượt gọi thành công để đạt kiểm thử</span>", "3", "3", "1…10", "—"],
        ["<span class='mono'>contact.allowedEmailDomains</span><br><span class='muted'>Miền thư công vụ của đầu mối</span>", "gov.vn", "gov.vn", "Danh sách", "02/09/2026 · PA"],
    ], "Tham số kết nạp") + '</div>'
    + '<div class="card"><b>Sửa tham số</b><div class="muted" style="margin:2px 0 8px"><span class="mono">handover.ttlHours</span></div>'
    + field("Giá trị mới", "48") + '<div class="muted" style="margin:-6px 0 10px">Miền cho phép: 1…72 · mặc định 24</div>' + field("Lý do thay đổi (bắt buộc)", "Đầu mối nhà thầu thường nhận thư chậm")
    + '<div class="foot">' + bt("Hủy") + bt("Lưu tham số", "pri") + '</div><div style="margin-top:12px"><b>Lịch sử gần đây</b><div class="vtl" style="margin-top:8px"><div>10/10/2026 · review.slaWorkingDays 3 → 2 · TA</div><div>02/09/2026 · contact.allowedEmailDomains thêm “vn” · PA</div></div></div></div></div>'
)

UI17 = (
    '<div class="head"><h1>Thống kê kết nạp</h1><span class="input">Quý 4/2026 ▾</span><span class="input">Đơn vị: Tất cả ▾</span><div class="sp"></div>' + bt("Xuất báo cáo") + "</div>"
    + kpis([("41", "Hồ sơ đã nộp", "+6 so với quý trước"), ("3,2 ngày", "Trung vị từ nộp đến kích hoạt", "đạt KPI-05 ≤ 5 ngày"), ("18%", "Tỷ lệ trả bổ sung", ""), ("2", "Hồ sơ quá hạn thẩm định", ""), ("7", "Định danh sắp hết hạn", "")])
    + '<div class="grid-2e"><div class="card"><b>Thời gian từng giai đoạn</b> <span class="muted">· trung vị / p90, ngày làm việc</span><div style="margin-top:10px">'
    + "".join(f'<div class="hbar"><span>{n}</span><i style="width:{w}%"></i><span class="num">{v}</span></div>' for n, w, v in [("Nộp đến phân công", 12, "0,3 / 0,8"), ("Thẩm định", 52, "1,6 / 2,9"), ("Phê duyệt", 20, "0,6 / 1,1"), ("Cấp định danh", 8, "0,2 / 0,4"), ("Kiểm thử SANDBOX", 70, "2,4 / 6,5"), ("Kích hoạt", 14, "0,4 / 0,9")])
    + '</div></div><div class="card"><b>Hồ sơ nộp theo tuần</b><div class="vbars">'
    + "".join(f'<div><i style="height:{h}px;background:#0b5cd5"></i><i style="height:{t}px;background:#f0a020"></i></div>' for h, t in [(40, 6), (55, 10), (62, 8), (35, 12), (70, 14), (58, 9), (66, 11), (48, 5), (80, 16), (60, 8)])
    + '</div><div class="legend"><span><i style="background:#0b5cd5"></i>Nộp mới</span><span><i style="background:#f0a020"></i>Nộp lại sau bổ sung</span></div></div></div>'
    + '<div class="card" style="margin-top:12px"><b>Hồ sơ quá hạn và định danh sắp hết hạn</b>' + tbl(["Đối tượng", "HTTT", "Đơn vị", "Chi tiết", "Mức"], [
        ["Hồ sơ HS-KN-2026-0042", "HT-DATDAI", "Sở TN&amp;MT", "Quá hạn thẩm định pháp lý 1 ngày", tg("err", "Quá hạn")],
        ["Định danh PRODUCTION", "HT-TUPHAP", "Sở Tư pháp", "Hết hạn 08/12/2026", tg("warn", "12 ngày")],
    ], "Cần chú ý") + "</div>"
)

SCREENS = [
    ("01", "Biểu mẫu kết nạp", "Kết nối &amp; API / Hệ thống thành viên / HT-DATDAI / Sửa", UI01, ""),
    ("02", "Tiến độ hồ sơ", "Kết nối &amp; API / Hệ thống thành viên / HT-YTE / Tiến độ", UI02, ""),
    ("04", "Chi tiết HTTT thành viên", "Kết nối &amp; API / Hệ thống thành viên / HT-TUPHAP", UI04, ""),
    ("05", "Hàng đợi thẩm định", "Kết nối &amp; API / Hệ thống thành viên / Hàng đợi thẩm định", UI05, ""),
    ("07", "Duyệt kết nạp", "Việc của tôi / Duyệt kết nạp HT-DATDAI", UI07, ""),
    ("08", "Định danh ứng dụng", "Kết nối &amp; API / Hệ thống thành viên / HT-TUPHAP / Định danh", UI08, ""),
    ("10", "Kiểm thử SANDBOX và kích hoạt", "Kết nối &amp; API / Hệ thống thành viên / HT-BHXH / Kiểm thử", UI10, ""),
    ("11", "Vòng đời và xử lý khẩn", "Kết nối &amp; API / Hệ thống thành viên / HT-TUPHAP / Phụ thuộc", UI11_BG, UI11_DRAWER),
    ("12", "Rà soát quyền định kỳ", "Kết nối &amp; API / Rà soát quyền", UI12, ""),
    ("14", "Danh bạ đầu mối", "Kết nối &amp; API / Danh bạ đầu mối", UI14, ""),
    ("15", "Nhập HTTT từ hệ cũ", "Kết nối &amp; API / Hệ thống thành viên / Nhập từ hệ cũ", UI15, ""),
    ("16", "Tham số kết nạp", "Quản trị / Tham số / Kết nạp", UI16, ""),
    ("17", "Thống kê kết nạp", "Kết nối &amp; API / Thống kê kết nạp", UI17, ""),
]
ACTIVE_NAV = {"07": "05", "12": "12", "14": "14", "17": "17", "05": "05"}
for code, title, crumb, body, extra in SCREENS:
    (OUT / f"ui-01-{code}.html").write_text(shell(code, ACTIVE_NAV.get(code, "03"), title, crumb, body, extra), encoding="utf-8")

(OUT / "ui-01-03.html").write_text(shell("03", "03", "Danh sách HTTT thành viên", "Kết nối &amp; API / Hệ thống thành viên", UI03), encoding="utf-8")
(OUT / "ui-01-06.html").write_text(shell("06", "05", "Thẩm định hồ sơ", "Kết nối &amp; API / Hệ thống thành viên / HT-DATDAI / Thẩm định", UI06, UI06_DRAWER), encoding="utf-8")
(OUT / "ui-01-09.html").write_text(UI09, encoding="utf-8")
(OUT / "ui-01-13.html").write_text(UI13, encoding="utf-8")
print("Đã sinh 17 tệp ui-01-01…17.html")
