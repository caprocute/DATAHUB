#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh minh họa của PH-12 cho FRS (UI-12-01 Danh sách người dùng, UI-12-13 Chạy khô và duyệt chính sách).
Dùng token Liquid Glass đề xuất của 03-thiet-ke/uiux/ph07/hifi/hifi.css. Chạy: python3 gen_hifi.py && node shot.js
Dữ liệu trên ảnh là dữ liệu minh họa, không phải dữ liệu thật của tỉnh nào."""
import pathlib

OUT = pathlib.Path(__file__).parent
CSS = "../../../../03-thiet-ke/uiux/ph07/hifi/hifi.css"
NAV = [("Người dùng", "01"), ("Vai trò và quyền", "05"), ("Nhóm và đơn vị", "07"), ("Quyền có thời hạn", "08"),
       ("Danh tính HTTT", "10"), ("Liên kết định danh", "11"), ("Chính sách truy cập", "12"),
       ("Nhật ký quyết định", "14"), ("Cảnh báo và báo cáo", "15")]


def shell(code, active, title, crumb, body, extra="", user="LT"):
    nav = "".join(f'<a class="{"on" if active == c else ""}" href="#">{n}</a>' for n, c in NAV)
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-12-{code} · {title}</title><link rel="stylesheet" href="{CSS}"></head><body>
<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Định danh và phân quyền</div><div class="search">Tìm người dùng, vai trò, chính sách…  ⌘K</div><div class="sp"></div>
<span class="tray">Tỉnh mẫu T68</span><span class="tray">Phiên còn 14 phút</span><div class="avatar">{user}</div></header>
<nav class="side" aria-label="Điều hướng chính"><div class="grp">Định danh</div>{nav}<div class="grp">Cá nhân</div><a href="#">Việc của tôi <span class="tag t-info">3</span></a></nav>
<main><div class="crumb">{crumb}</div>{body}</main></div>{extra}<div class="hint">Bản hi-fi minh họa · D02-03-PH12 · UI-12-{code}</div></body></html>"""


def rows(data):
    return "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in data)


def mfa(v):
    return {"ok": "<span class='tag t-ok'>WebAuthn</span>", "totp": "<span class='tag t-ok'>TOTP</span>",
            "miss": "<span class='tag t-err'>Chưa đăng ký</span>", "no": "<span class='muted'>Không bắt buộc</span>"}[v]


def st(v):
    return {"act": "<span class='tag t-ok'>Hoạt động</span>", "blk": "<span class='tag t-err'>Khóa hẳn</span>",
            "lck": "<span class='tag t-warn'>Khóa tạm</span>", "pen": "<span class='tag t-info'>Chờ kích hoạt</span>",
            "dis": "<span class='tag t-mute'>Vô hiệu</span>"}[v]


UI01 = """
<div class="head"><h1>Người dùng</h1><div class="sp"></div><span class="btn">Nhập từ tệp</span><span class="btn">Xuất CSV</span><span class="btn pri">+ Tạo người dùng</span></div>
<div class="stats"><div class="stat on"><b>1.284</b><span>Tất cả tài khoản</span></div><div class="stat"><b>1.173</b><span>Đang hoạt động</span></div><div class="stat"><b style="color:#a11a1a">4</b><span>Bị khóa</span></div><div class="stat"><b style="color:#7a5200">3</b><span>Nhóm bắt buộc chưa có MFA</span></div><div class="stat"><b style="color:#7a5200">17</b><span>Sắp bị vô hiệu (quá 30 ngày)</span></div><div class="stat"><b>52</b><span>Chờ kích hoạt</span></div></div>
<div class="card"><div class="toolbar"><span class="input" style="min-width:240px">Tìm tên, tên đăng nhập, thư, đơn vị</span><span class="input">Trạng thái: Tất cả ▾</span><span class="input">Đơn vị: Tất cả ▾</span><span class="input">Vai trò: Tất cả ▾</span><span class="input">MFA: Tất cả ▾</span><div style="flex:1"></div><span class="muted">Sắp xếp: tài khoản bị khóa trước</span></div>
<table aria-label="Danh sách người dùng"><thead><tr><th>Họ tên · Tên đăng nhập</th><th>Đơn vị</th><th>Vai trò</th><th>Yếu tố thứ hai</th><th>Đăng nhập cuối</th><th>Trạng thái</th></tr></thead><tbody>""" + rows([
    ["<b>Phạm Văn D</b><br><span class='mono muted'>phamvand</span>", "Sở KH&amp;CN", "INTEGRATION_ENGINEER", mfa("no"), "<span style='color:#a11a1a'>11/11/2026 08:41</span>", st("blk")],
    ["<b>Hoàng Thị E</b><br><span class='mono muted'>hoangthie</span>", "Sở Tư pháp", "SERVICE_OWNER (STP)", mfa("no"), "26/11/2026 07:55", st("lck")],
    ["<b>Nguyễn Văn A</b><br><span class='mono muted'>nguyenvana</span>", "Sở Tư pháp", "TENANT_ADMIN", mfa("ok"), "26/11/2026 09:02", st("act")],
    ["<b>Lê Thị T</b><br><span class='mono muted'>lethit</span>", "Văn phòng UBND", "SECURITY_OFFICER", mfa("ok"), "26/11/2026 08:47", st("act")],
    ["<b>Trần Thị B</b><br><span class='mono muted'>tranthib</span>", "Sở KH&amp;CN", "INTEGRATION_APPROVER", "<span class='tag t-err'>Chưa đăng ký</span> <span class='muted'>bị buộc ở lần sau</span>", "25/11/2026 16:20", st("act")],
    ["<b>Vũ Minh G</b><br><span class='mono muted'>vuminhg</span>", "Sở Y tế", "DATA_STEWARD (SYT)", mfa("no"), "<span style='color:#7a5200'>12/10/2026 10:15 · 45 ngày ⚠</span>", st("act")],
    ["<b>Đỗ Thu H</b><br><span class='mono muted'>dothuh</span>", "Sở Tài chính", "PAYMENT_ACCOUNTANT", mfa("totp"), "—", st("pen")],
]) + """</tbody></table><div class="foot" style="justify-content:space-between"><span class="muted">Hiển thị 1–7 / 1.284 · MFA bắt buộc cho các vai trò quản trị, duyệt, ATTT, thanh toán</span><span class="muted">‹ Trước · Sau › · 20 / trang</span></div></div>"""

UI13 = """
<div class="head"><h1>Chạy khô · deny-after-hours</h1><span class="tag t-info">Phiên bản 3 · PENDING_REVIEW</span><div class="sp"></div><span class="btn">Tải báo cáo CSV</span><span class="btn">So sánh với bản đang chạy</span></div>
<div class="stats" style="margin-right:440px"><div class="stat"><b>96.412</b><span>Yêu cầu mẫu, 24 giờ gần nhất</span></div><div class="stat on"><b style="color:#a11a1a">23.627 · 24,5%</b><span>Đổi kết quả (ngưỡng 20%)</span></div><div class="stat"><b>23.594</b><span>Cho phép → từ chối</span></div><div class="stat"><b style="color:#7a5200">33</b><span>Từ chối → cho phép (nới quyền)</span></div></div>
<div class="card" style="margin-right:440px"><div class="warn" style="margin-bottom:10px"><b>Vượt ngưỡng 20%.</b> Thay đổi này sẽ chặn thêm 23.594 yêu cầu vốn đang được phép, chủ yếu từ HT-QLVB và HT-DATDAI ngoài giờ hành chính. Người duyệt phải xác nhận bổ sung.</div>
<table aria-label="Tác động theo bên gọi"><thead><tr><th>Bên gọi</th><th>Tài nguyên</th><th>Trước</th><th>Sau</th><th>Số yêu cầu</th></tr></thead><tbody>""" + rows([
    ["<span class='mono'>ht-qlvb</span>", "van-ban/gui", "Cho phép", "<span class='tag t-err'>Từ chối</span> <span class='muted'>AFTER_HOURS</span>", "11.840"],
    ["<span class='mono'>ht-datdai</span>", "dat-dai/tra-cuu", "Cho phép", "<span class='tag t-err'>Từ chối</span> <span class='muted'>AFTER_HOURS</span>", "6.115"],
    ["<span class='mono'>ht-motcua</span>", "ho-so/cap-nhat", "Cho phép", "<span class='tag t-err'>Từ chối</span> <span class='muted'>AFTER_HOURS</span>", "3.402"],
    ["<span class='mono'>ht-bhxh</span>", "bao-hiem/tra-cuu", "Cho phép", "<span class='tag t-err'>Từ chối</span> <span class='muted'>AFTER_HOURS</span>", "2.237"],
    ["<span class='mono'>ht-yte</span>", "ho-so-suc-khoe/doc", "Từ chối", "<span class='tag t-warn'>Cho phép</span> <span class='muted'>nới quyền</span>", "33"],
]) + """</tbody></table><div class="muted" style="margin-top:10px">Kết quả gắn với băm nội dung <span class="mono">a41f9c…</span> và gói <span class="mono">t68-20261126-0153</span>; sửa nội dung thì phải chạy khô lại. 20 ví dụ tiêu biểu xem ở tab Ví dụ.</div></div>"""

DRAWER = """<div class="drawer" role="dialog" aria-label="Duyệt phiên bản chính sách"><h3 style="margin:0 0 4px">Duyệt phiên bản 3</h3><div class="muted" style="margin-bottom:12px">Soạn bởi Lê Thị T lúc 08:55 · Gửi duyệt lúc 09:10</div>
<div class="card"><table><tbody>""" + rows([
    ["<span style='color:#0b6b3a'>✓</span>", "Cú pháp, <span class='mono'>opa check</span>", "", "<span class='muted'>đạt</span>"],
    ["<span style='color:#0b6b3a'>✓</span>", "Ca kiểm thử", "12/12", "<span class='muted'>có ca dương và ca âm</span>"],
    ["<span style='color:#0b6b3a'>✓</span>", "Độ phủ", "94%", "<span class='muted'>≥ 90%</span>"],
    ["<span style='color:#0b6b3a'>✓</span>", "Người duyệt khác người soạn", "", "<span class='muted'>Bốn mắt</span>"],
    ["<span style='color:#0b6b3a'>✓</span>", "Xác thực mức 3 (WebAuthn)", "2 phút trước", "<span class='muted'>≤ 5 phút</span>"],
]) + """</tbody></table></div>
<div class="field"><label>Ý kiến của người duyệt (bắt buộc)</label><span class="input" style="height:64px;align-items:flex-start;padding-top:8px;white-space:normal;line-height:1.4">Đã trao đổi với đầu mối HT-QLVB, chấp nhận chặn ngoài giờ hành chính.</span></div>
<div class="warn" style="margin-bottom:8px">☑ Tôi đã xem 33 trường hợp nới quyền và xác nhận thay đổi đổi 24,5% quyết định.</div>
<div class="foot"><span class="btn danger">Từ chối</span><span class="btn pri">Phê duyệt và phát hành</span></div></div>"""

(OUT / "ui-12-01.html").write_text(shell("01", "01", "Danh sách người dùng", "Định danh / Người dùng", UI01), encoding="utf-8")
(OUT / "ui-12-13.html").write_text(shell("13", "12", "Chạy khô và duyệt chính sách",
                                         "Định danh / Chính sách truy cập / deny-after-hours / Phiên bản 3", UI13, DRAWER, user="NQ"), encoding="utf-8")
print("Đã sinh ui-12-01.html, ui-12-13.html")
