#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh minh họa của PH-05 (UI-05-01, UI-05-02 kèm drawer UI-05-04).
Dùng token Liquid Glass đề xuất của ph07/hifi/hifi.css. Chạy: python3 gen_hifi.py && node shot.js
Dữ liệu trên ảnh là dữ liệu minh họa, không phải dữ liệu thật của tỉnh nào."""
import pathlib

OUT = pathlib.Path(__file__).parent
NAV = [("Luồng tích hợp", None), ("Kết nối nguồn", "01"), ("Bộ điều hợp", "08"), ("Giám sát CDC", "12"),
       ("Danh mục Kamelet", "14"), ("Sức khỏe kết nối", "07")]


def shell(code, active, title, crumb, body, extra=""):
    nav = "".join(f'<a class="{"on" if active == c else ""}" href="#">{n}</a>' for n, c in NAV)
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-05-{code} · {title}</title><link rel="stylesheet" href="../../ph07/hifi/hifi.css"></head><body>
<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Tích hợp</div><div class="search">Tìm kết nối, bộ điều hợp, luồng…  ⌘K</div><div class="sp"></div>
<span class="tray">Tỉnh mẫu T68</span><span class="tray">Môi trường: PROD</span><div class="avatar">AN</div></header>
<nav class="side" aria-label="Điều hướng chính"><div class="grp">Tích hợp</div>{nav}<div class="grp">Cá nhân</div><a href="#">Việc của tôi <span class="tag t-info">2</span></a></nav>
<main><div class="crumb">{crumb}</div>{body}</main></div>{extra}<div class="hint">Bản hi-fi minh họa · D02-03-PH05 · UI-05-{code}</div></body></html>"""


def rows(data):
    return "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in data)


def env(t, s, p):
    m = {"ok": "<span style='color:#0b6b3a'>●</span>", "warn": "<span style='color:#d08a00'>●</span>",
         "err": "<span style='color:#a11a1a'>●</span>", "no": "<span style='color:#9aa1ab'>—</span>"}
    return f"{m[t]} {m[s]} {m[p]}"


UI01 = """
<div class="head"><h1>Kết nối nguồn</h1><div class="sp"></div><span class="btn">Nhập từ hệ cũ</span><span class="btn">Xuất CSV</span><span class="btn pri">+ Tạo kết nối</span></div>
<div class="stats"><div class="stat on"><b>86</b><span>Tất cả kết nối</span></div><div class="stat"><b>71</b><span>Đang dùng</span></div><div class="stat"><b style="color:#a11a1a">3</b><span>Mất kết nối</span></div><div class="stat"><b style="color:#7a5200">2</b><span>Bí mật quá hạn xoay</span></div><div class="stat"><b>1</b><span>Chờ duyệt bật PROD</span></div></div>
<div class="card"><div class="toolbar"><span class="input" style="min-width:240px">Tìm mã, tên, HTTT, máy chủ</span><span class="input">Loại: Tất cả ▾</span><span class="input">HTTT: Tất cả ▾</span><span class="input">Trạng thái: Đang dùng ▾</span><span class="input">Sức khỏe: Tất cả ▾</span><div style="flex:1"></div><span class="muted">Sắp xếp: kết nối lỗi trước</span></div>
<table aria-label="Danh sách kết nối nguồn"><thead><tr><th></th><th>Mã · Tên</th><th>Loại</th><th>HTTT</th><th>Trạng thái</th><th>TEST · STG · PROD</th><th>Nơi dùng</th><th>Bí mật</th><th>Cập nhật</th></tr></thead><tbody>""" + rows([
    ["<span style='color:#a11a1a'>●</span>", "<span class='mono'>qlvb-soap</span><br><span class='muted'>Quản lý văn bản, dịch vụ SOAP</span>", "SOAP · WS-Security", "HT-QLVB", "<span class='tag t-ok'>Đang dùng</span>", env("ok", "ok", "err"), "6", "41 ngày", "26/11/2026 09:12"],
    ["<span style='color:#a11a1a'>●</span>", "<span class='mono'>datdai-cdc</span><br><span class='muted'>CSDL đất đai, đọc nhật ký giao dịch</span>", "CDC Debezium", "HT-DATDAI", "<span class='tag t-ok'>Đang dùng</span>", env("ok", "no", "err"), "2", "12 ngày", "25/11/2026 22:40"],
    ["<span style='color:#d08a00'>●</span>", "<span class='mono'>dkkd-db</span><br><span class='muted'>Đăng ký kinh doanh, CSDL cho luồng</span>", "CSDL cho luồng", "HT-DKKD", "<span class='tag t-ok'>Đang dùng</span>", env("ok", "ok", "warn"), "3", "<span style='color:#7a5200'>95 ngày ⚠</span>", "24/11/2026 15:03"],
    ["<span style='color:#0b6b3a'>●</span>", "<span class='mono'>ndxp-ho-tich</span><br><span class='muted'>NDXP tra cứu hộ tịch</span>", "OAuth2 client", "HT-TUPHAP", "<span class='tag t-ok'>Đang dùng</span>", env("ok", "ok", "ok"), "4", "32 ngày", "24/11/2026 10:21"],
    ["<span style='color:#0b6b3a'>●</span>", "<span class='mono'>mot-cua-rest</span><br><span class='muted'>Hệ thống một cửa điện tử</span>", "HTTP API key", "HT-MOTCUA", "<span class='tag t-ok'>Đang dùng</span>", env("ok", "ok", "ok"), "9", "18 ngày", "20/11/2026 08:55"],
    ["<span style='color:#9aa1ab'>○</span>", "<span class='mono'>bhxh-sftp</span><br><span class='muted'>Trao đổi tệp với BHXH tỉnh</span>", "SFTP", "HT-BHXH", "<span class='tag t-warn'>Chờ duyệt PROD</span>", env("ok", "ok", "no"), "0", "3 ngày", "26/11/2026 08:02"],
    ["<span style='color:#9aa1ab'>○</span>", "<span class='mono'>yte-hl7</span><br><span class='muted'>Sở Y tế, hàng đợi HL7</span>", "AMQP 1.0", "HT-YTE", "<span class='tag t-mute'>Bản nháp</span>", env("warn", "no", "no"), "0", "Chưa đặt", "23/11/2026 16:47"],
]) + """</tbody></table><div class="foot" style="justify-content:space-between"><span class="muted">Hiển thị 1–7 / 86 · <span style='color:#0b6b3a'>●</span> đạt · <span style='color:#d08a00'>●</span> suy giảm · <span style='color:#a11a1a'>●</span> mất kết nối · — chưa khai báo</span><span class="muted">‹ Trước · Sau › · 25 / trang</span></div></div>"""

UI02 = """
<div class="head"><h1>qlvb-soap</h1><span class="tag t-ok">Đang dùng</span><span class="tag t-err">PROD mất kết nối</span><div class="sp"></div><span class="btn">Xoay bí mật</span><span class="btn">Tạm ngừng</span><span class="btn pri">Kiểm tra kết nối</span><span class="btn">⋯</span></div>
<div class="tabs"><span>Tổng quan</span><span class="on">Môi trường</span><span>Cấp sử dụng</span><span>Kiểm tra</span><span>Sức khỏe</span><span>Nơi dùng (6)</span><span>Lịch sử</span></div>
<div class="card" style="margin-right:440px"><table><thead><tr><th>Môi trường</th><th>Điểm cuối</th><th>Bí mật</th><th>Trạng thái</th><th>Kiểm tra gần nhất</th></tr></thead><tbody>""" + rows([
    ["TEST", "<span class='mono'>https://qlvb-test.tinh.gov.vn/ws</span>", "Đã đặt · v3", "<span class='tag t-ok'>Đang bật</span>", "Đạt · 25/11 14:02"],
    ["STAGING", "<span class='mono'>https://qlvb-stg.tinh.gov.vn/ws</span>", "Đã đặt · v2", "<span class='tag t-ok'>Đang bật</span>", "Đạt · 25/11 14:05"],
    ["PROD", "<span class='mono'>https://qlvb.tinh.gov.vn/ws</span>", "Đã đặt · v5", "<span class='tag t-ok'>Đang bật</span>", "<span style='color:#a11a1a'>Không đạt · 26/11 10:14</span>"],
]) + """</tbody></table><div class="muted" style="margin-top:10px">Giá trị bí mật không bao giờ hiển thị; chỉ có trạng thái "Đã đặt", phiên bản và thời điểm cập nhật.</div></div>"""

DRAWER = """<div class="drawer" role="dialog" aria-label="Kiểm tra kết nối"><h3 style="margin:0 0 4px">Kiểm tra kết nối · PROD</h3><div class="muted" style="margin-bottom:12px">Bí mật v5 · tham số #a41f · chạy bởi An lúc 10:14:02</div>
<div class="card"><table><tbody>""" + rows([
    ["<span style='color:#0b6b3a'>✓</span>", "Phân giải tên miền", "3 ms", "<span class='muted'>→ 10.20.1.15</span>"],
    ["<span style='color:#0b6b3a'>✓</span>", "Kết nối TCP", "18 ms", "<span class='muted'>cổng 443</span>"],
    ["<span style='color:#a11a1a'>✕</span>", "<b>Bắt tay TLS</b>", "391 ms", "<span style='color:#a11a1a'>Chứng thư không tin cậy</span>"],
    ["<span class='muted'>–</span>", "<span class='muted'>Xác thực</span>", "", "<span class='muted'>bỏ qua</span>"],
    ["<span class='muted'>–</span>", "<span class='muted'>Thao tác thử</span>", "", "<span class='muted'>bỏ qua</span>"],
]) + """</tbody></table></div>
<div class="warn"><b>Cách khắc phục.</b> Chứng thư của <span class="mono">qlvb.tinh.gov.vn</span> do "CA Nội bộ Sở TT" cấp, chưa có trong kho chứng thư tin cậy của tỉnh. Tải chuỗi chứng thư CA lên mục Chứng thư tin cậy, hoặc đề nghị đơn vị chủ quản dùng chứng thư công khai.</div>
<div class="foot"><span class="btn">Sao chép để gửi</span><span class="btn">Chạy lại</span><span class="btn pri">Đóng</span></div></div>"""

(OUT / "ui-05-01.html").write_text(shell("01", "01", "Danh sách kết nối nguồn", "Tích hợp / Kết nối nguồn", UI01), encoding="utf-8")
(OUT / "ui-05-04.html").write_text(shell("04", "01", "Kiểm tra, chẩn đoán kết nối",
                                         "Tích hợp / Kết nối nguồn / qlvb-soap", UI02, DRAWER), encoding="utf-8")
print("Đã sinh ui-05-01.html, ui-05-04.html")
