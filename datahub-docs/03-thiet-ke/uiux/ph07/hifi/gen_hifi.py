#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-07-01…12 (D03-06-PH07 §24.1). Chạy: python3 gen_hifi.py; chụp ảnh: node shot.js"""
import pathlib
OUT = pathlib.Path(__file__).parent
NAV = [("Tổng quan", None), ("Danh mục dùng chung", "01"), ("Tác vụ nhập xuất", "08"), ("Đồng bộ quốc gia", "09"),
       ("Ánh xạ mã", "10"), ("Đơn vị hành chính", "11"), ("Thử API truy vấn", "12")]
ACTIVE = {"01": "01", "02": "01", "03": "01", "04": "01", "05": "01", "06": "01", "07": "01", "08": "08", "09": "09", "10": "10", "11": "11", "12": "12"}

def shell(code, title, crumb, body, extra=""):
    nav = "".join(f'<a class="{"on" if ACTIVE[code]==c else ""}" href="#">{n}</a>' for n, c in NAV)
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-07-{code} · {title}</title><link rel="stylesheet" href="hifi.css"></head><body>
<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Quản trị</div><div class="search">Tìm danh mục, bản ghi, tác vụ…  ⌘K</div><div class="sp"></div>
<span class="tray">⟳ 1 tác vụ nền</span><span class="tray">Tỉnh mẫu</span><div class="avatar">NL</div></header>
<nav class="side" aria-label="Điều hướng chính"><div class="grp">Dữ liệu</div>{nav}<div class="grp">Cá nhân</div><a href="#">Việc của tôi <span class="tag t-info">3</span></a></nav>
<main><div class="crumb">{crumb}</div>{body}</main></div>{extra}<div class="hint">Bản hi-fi minh họa · D03-06-PH07 · UI-07-{code}</div></body></html>"""

def rows(data):
    return "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in data)

P = {}
P["01"] = ("Danh sách danh mục", "Trang chủ / Danh mục dùng chung", """
<div class="head"><h1>Danh mục dùng chung</h1><div class="sp"></div><span class="btn">Nhập tệp</span><span class="btn">Xuất ▾</span><span class="btn pri">+ Tạo danh mục</span></div>
<div class="stats"><div class="stat on"><b>148</b><span>Tất cả danh mục</span></div><div class="stat"><b>21</b><span>Nguồn quốc gia</span></div><div class="stat"><b>96</b><span>Của tỉnh</span></div><div class="stat"><b>7</b><span>Bản nháp chờ duyệt</span></div><div class="stat"><b>2</b><span>Đồng bộ chờ xác nhận</span></div></div>
<div class="grid2"><div class="card tree" role="tree" aria-label="Nhóm danh mục"><div class="on">▾ Tất cả (148)</div><div>&nbsp;&nbsp;▸ Hành chính (34)</div><div>&nbsp;&nbsp;▸ Dân cư (18)</div><div>&nbsp;&nbsp;▸ Thủ tục hành chính (22)</div><div>&nbsp;&nbsp;▸ Tài chính, ngân sách (15)</div><div>&nbsp;&nbsp;▸ Giáo dục (11)</div><div>&nbsp;&nbsp;▸ Y tế (13)</div><div>&nbsp;&nbsp;▸ Khác (35)</div></div>
<div class="card"><div class="toolbar"><span class="input" style="min-width:200px">Tìm theo mã, tên</span><span class="input">Nguồn: Tất cả ▾</span><span class="input">Trạng thái: Đang hiệu lực ▾</span><span class="input">Phạm vi: Tất cả ▾</span><div style="flex:1"></div><span class="muted">⚙</span></div>
<table aria-label="Danh sách danh mục"><thead><tr><th>Mã</th><th>Tên danh mục</th><th>Nguồn</th><th>Phiên bản hiệu lực</th><th>Bản ghi</th><th>Phiên bản mở</th><th>Đơn vị chủ quản</th><th>Cập nhật ▾</th></tr></thead><tbody>""" + rows([
 ["<span class='mono'>DVHC</span>","Đơn vị hành chính 🌐","<span class='tag t-nat'>Quốc gia 🔒</span>","v12 · 01/07/2025","3.321","—","Bộ Nội vụ","24/11/2026 09:12"],
 ["<span class='mono'>DAN_TOC</span>","Dân tộc 🌐","<span class='tag t-nat'>Quốc gia 🔒</span>","v3 · 01/01/2024","55","—","Cục Thống kê","20/11/2026 15:40"],
 ["<span class='mono'>LINH_VUC_TTHC</span>","Lĩnh vực thủ tục hành chính","<span class='tag t-hyb'>Kết hợp</span>","v8 · 15/10/2026","412","<span class='tag t-warn'>Chờ duyệt</span>","Văn phòng UBND","19/11/2026 10:03"],
 ["<span class='mono'>CO_QUAN</span>","Cơ quan, đơn vị của tỉnh","<span class='tag t-local'>Tỉnh</span>","v21 · 01/11/2026","1.184","<span class='tag t-info'>Bản nháp</span>","Sở Nội vụ","18/11/2026 16:22"],
 ["<span class='mono'>LOAI_VB</span>","Loại văn bản","<span class='tag t-com'>Dùng chung</span>","v2 · 01/03/2026","28","—","Nền tảng","12/11/2026 08:30"],
 ["<span class='mono'>CHUC_DANH</span>","Chức danh công chức","<span class='tag t-local'>Tỉnh</span>","v5 · 01/06/2026","96","—","Sở Nội vụ","05/11/2026 11:47"],
 ["<span class='mono'>KCN</span>","Khu, cụm công nghiệp","<span class='tag t-local'>Tỉnh</span>","v4 · 01/09/2026","17","—","Sở Công Thương","01/11/2026 14:05"],
 ["<span class='mono'>TON_GIAO</span>","Tôn giáo 🌐","<span class='tag t-nat'>Quốc gia 🔒</span>","v2 · 01/01/2023","16","<span class='tag t-err'>Đồng bộ chờ xác nhận</span>","Ban Tôn giáo","30/10/2026 09:00"],
 ["<span class='mono'>DIA_BAN_DL</span>","Điểm du lịch","<span class='tag t-local'>Tỉnh</span>","v1 · 01/08/2026","64","—","Sở VHTTDL","22/10/2026 17:18"],
]) + """</tbody></table><div class="foot" style="justify-content:space-between"><span class="muted">Hiển thị 1–20 / 148</span><span class="muted">‹ 1 2 3 … 8 › · 20 / trang</span></div></div></div>""")

P["02"] = ("Chi tiết danh mục", "Trang chủ / Danh mục dùng chung / Cơ quan, đơn vị của tỉnh", """
<div class="head"><h1>Cơ quan, đơn vị của tỉnh</h1><span class="tag t-local">Tỉnh</span><span class="tag t-ok">Đang hiệu lực v21</span><div class="sp"></div><span class="btn">Xuất ▾</span><span class="btn">Ánh xạ</span><span class="btn pri">Mở bản nháp v22</span><span class="btn">⋯</span></div>
<div class="tabs"><span>Tổng quan</span><span>Thuộc tính</span><span class="on">Bản ghi</span><span>Phiên bản</span><span>Ánh xạ</span><span>Đồng bộ</span><span>Sử dụng</span><span>Lịch sử</span></div>
<div class="grid3"><div class="card"><div class="toolbar"><span class="input">Phiên bản: v21 (hiệu lực) ▾</span><span class="input" style="min-width:240px">Tìm mã, tên bản ghi</span><span class="input">Trạng thái: Đang dùng ▾</span><div style="flex:1"></div><span class="btn">Bảng</span><span class="btn pri">Cây</span></div>
<div class="tree" role="tree" aria-label="Cây bản ghi">
<div>▾ <span class="mono">000.00.00.H99</span> UBND tỉnh</div><div>&nbsp;&nbsp;&nbsp;&nbsp;▾ <span class="mono">000.00.01.H99</span> Văn phòng UBND tỉnh</div>
<div class="on">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;▸ <span class="mono">000.01.01.H99</span> Trung tâm Phục vụ hành chính công</div>
<div>&nbsp;&nbsp;&nbsp;&nbsp;▸ <span class="mono">000.00.02.H99</span> Sở Nội vụ (14)</div><div>&nbsp;&nbsp;&nbsp;&nbsp;▸ <span class="mono">000.00.03.H99</span> Sở Tài chính (9)</div><div>&nbsp;&nbsp;&nbsp;&nbsp;▸ <span class="mono">000.00.04.H99</span> Sở Khoa học và Công nghệ (7)</div><div>&nbsp;&nbsp;&nbsp;&nbsp;▸ <span class="mono">000.00.05.H99</span> Sở Y tế (42)</div><div>&nbsp;&nbsp;&nbsp;&nbsp;▸ <span class="mono">000.00.06.H99</span> Sở Giáo dục và Đào tạo (118)</div><div>&nbsp;&nbsp;▸ UBND cấp xã (102)</div></div></div>
<div class="card raised"><h3 style="margin:0 0 8px">Trung tâm Phục vụ hành chính công</h3><table><tbody>""" + rows([["Mã","<span class='mono'>000.01.01.H99</span>"],["Mã cha","000.00.01.H99"],["Mã ĐVQHNS","1234567"],["Địa chỉ","Số 1 đường Trung tâm, phường Mẫu"],["Hiệu lực từ","01/07/2025"],["Trạng thái","<span class='tag t-ok'>Đang dùng</span>"]]) + """</tbody></table>
<h4 style="margin:14px 0 6px">Lịch sử</h4><div class="muted">v19 · 01/07/2025 · Thành lập theo QĐ 1234/QĐ-UBND<br>v21 · 01/11/2026 · Đổi địa chỉ</div></div></div>""")

P["03"] = ("Tạo danh mục", "Trang chủ / Danh mục dùng chung / Tạo danh mục", """
<div class="head"><h1>Tạo danh mục</h1></div><div class="steps"><div class="on">1 · Thông tin chung</div><div>2 · Thuộc tính</div><div>3 · Xem lại</div></div>
<div class="card" style="max-width:820px"><div class="field"><label>Mã danh mục *</label><div class="input mono">KCN</div><div class="muted">Chữ in hoa, số và dấu gạch dưới, 2–64 ký tự. Không đổi được sau khi phát hành.</div></div>
<div class="field"><label>Tên danh mục *</label><div class="input">Khu, cụm công nghiệp</div></div>
<div class="field"><label>Nhóm *</label><div class="input">Kinh tế ▾</div></div>
<div class="field"><label>Đơn vị chủ quản *</label><div class="input">Sở Công Thương ▾</div></div>
<div class="field"><label>Nguồn</label><span class="tag t-local">Tỉnh</span> <span class="tag t-mute">Kết hợp</span> <span class="muted">— nguồn quốc gia chỉ tạo qua đồng bộ</span></div>
<div class="field"><label>Kiểu cấu trúc</label><span class="tag t-info">Danh sách phẳng</span> <span class="tag t-mute">Phân cấp cha con</span></div>
<div class="field"><label>Căn cứ pháp lý</label><div class="input">Quyết định số …/QĐ-UBND ngày …</div></div>
<div class="foot"><span class="btn">Hủy</span><span class="btn pri">Tiếp tục</span></div></div>""")

P["04"] = ("Lược đồ thuộc tính", "Danh mục dùng chung / Khu, cụm công nghiệp / Bản nháp v5 / Lược đồ", """
<div class="head"><h1>Lược đồ thuộc tính · bản nháp v5</h1><span class="tag t-info">Bản nháp</span><div class="sp"></div><span class="btn">Xem JSON Schema</span><span class="btn pri">+ Thêm thuộc tính</span></div>
<div class="grid3"><div class="card"><table><thead><tr><th>⋮⋮</th><th>Mã</th><th>Nhãn</th><th>Kiểu</th><th>Bắt buộc</th><th>Duy nhất</th><th>Truy vấn</th><th>Trạng thái</th></tr></thead><tbody>""" + rows([
 ["⋮⋮","<span class='mono'>dien_tich_ha</span>","Diện tích (ha)","DECIMAL","✓","","✓","<span class='tag t-ok'>Hiện</span>"],
 ["⋮⋮","<span class='mono'>loai_hinh</span>","Loại hình","ENUM","✓","","✓","<span class='tag t-ok'>Hiện</span>"],
 ["⋮⋮","<span class='mono'>ma_dvhc_xa</span>","Xã, phường","CATALOG_REF → DVHC","✓","","✓","<span class='tag t-ok'>Hiện</span>"],
 ["⋮⋮","<span class='mono'>ty_le_lap_day</span>","Tỷ lệ lấp đầy (%)","DECIMAL","","","","<span class='tag t-ok'>Hiện</span>"],
 ["⋮⋮","<span class='mono'>nguoi_dai_dien</span>","Người đại diện","TEXT","","","","<span class='tag t-warn'>Mới</span>"],
]) + """</tbody></table></div><div class="card raised"><h3 style="margin:0 0 10px">Người đại diện</h3>
<div class="warn" role="alert">⚠ Nhãn "người đại diện" có thể là dữ liệu cá nhân. Danh mục không được chứa dữ liệu cá nhân (BR-07-025). Đổi thành tên chức danh, hoặc xác nhận đây không phải dữ liệu cá nhân.</div>
<div class="field" style="margin-top:10px"><label>Mã *</label><div class="input mono">nguoi_dai_dien</div></div><div class="field"><label>Kiểu dữ liệu *</label><div class="input">TEXT ▾</div></div><div class="field"><label>Độ dài tối đa</label><div class="input">255</div></div><div class="field"><label>Mức phân loại</label><div class="input">Nội bộ ▾</div></div>
<div class="foot"><span class="btn">Hủy</span><span class="btn pri">Lưu thuộc tính</span></div></div></div>""")

P["05"] = ("Sửa bản ghi bản nháp", "Danh mục dùng chung / Cơ quan, đơn vị của tỉnh / Bản nháp v22 / Bản ghi", """
<div class="head"><h1>Sửa bản ghi · bản nháp v22</h1><span class="tag t-info">Bản nháp</span><span class="muted">so với v21: +3 · ✎12 · −1</span><div class="sp"></div><span class="btn">Nhập tệp</span><span class="btn">So sánh</span><span class="btn pri">Trình duyệt</span></div>
<div class="card"><div class="toolbar"><span class="btn pri">Lưu 4 thay đổi (Ctrl+S)</span><span class="btn">Hoàn tác</span><span class="btn">+ Thêm dòng</span><span class="input" style="min-width:220px">Tìm trong bản nháp</span><span class="input">Chỉ dòng: Có thay đổi ▾</span><div style="flex:1"></div><span class="muted">1.843 bản ghi · Gọn</span></div>
<table role="grid" aria-rowcount="1843"><thead><tr><th></th><th>Mã *</th><th>Tên *</th><th>Mã cha</th><th>Mã ĐVQHNS</th><th>Địa chỉ</th><th>Trạng thái</th></tr></thead><tbody>
<tr><td>✎</td><td class="mono">000.00.02.H99</td><td>Sở Nội vụ</td><td class="mono">000.00.00.H99</td><td>1023456</td><td class="cell-edit">Số 5 đường Hành chính|</td><td><span class="tag t-ok">Đang dùng</span></td></tr>
<tr><td>+</td><td class="mono">000.02.05.H99</td><td>Trung tâm Chuyển đổi số</td><td class="mono">000.00.04.H99</td><td>—</td><td>Số 9 đường Công nghệ</td><td><span class="tag t-ok">Đang dùng</span></td></tr>
<tr><td style="color:#a11a1a">!</td><td class="mono cell-err">000.02.05.H99</td><td>Trung tâm Thông tin</td><td class="mono">000.00.04.H99</td><td>—</td><td></td><td><span class="tag t-ok">Đang dùng</span></td></tr>
<tr><td style="color:#7a5200">⚠</td><td class="mono">000.00.07.H99</td><td>Sở Xây dựng</td><td class="mono">000.00.00.H99</td><td>1029988</td><td>Số 12 đường Kiến thiết</td><td><span class="tag t-ok">Đang dùng</span></td></tr>
""" + rows([["",f"<span class='mono'>000.00.{i:02d}.H99</span>",n,"<span class='mono'>000.00.00.H99</span>",f"10{i:02d}456","—","<span class='tag t-ok'>Đang dùng</span>"] for i,n in [(8,"Sở Nông nghiệp và Môi trường"),(9,"Sở Tư pháp"),(10,"Sở Công Thương"),(11,"Sở Văn hóa, Thể thao và Du lịch"),(12,"Sở Dân tộc và Tôn giáo"),(13,"Thanh tra tỉnh")]]) + """</tbody></table>
<div class="warn" style="margin-top:10px">Dòng 3: Mã "000.02.05.H99" đã có ở bản ghi "Trung tâm Chuyển đổi số" (ERR-07-008). · Dòng 4: Bản ghi đã được Lê Thị H. sửa lúc 10:42. <u>Xem khác biệt</u> · <u>Giữ của tôi</u> · <u>Lấy bản mới</u></div></div>""")

P["06"] = ("Nhập tệp", "Danh mục dùng chung / Cơ quan, đơn vị của tỉnh / Nhập tệp", """
<div class="head"><h1>Nhập tệp vào bản nháp v22</h1></div><div class="steps"><div class="done">✓ 1 · Chọn tệp</div><div class="done">✓ 2 · Ghép cột</div><div class="on">3 · Kiểm tra và xem trước</div><div>4 · Ghi vào bản nháp</div></div>
<div class="stats"><div class="stat"><b>1.207</b><span>Dòng đọc được</span></div><div class="stat"><b style="color:#0b6b3a">38</b><span>Thêm mới</span></div><div class="stat"><b style="color:#7a5200">114</b><span>Sửa</span></div><div class="stat"><b>1.049</b><span>Không đổi</span></div><div class="stat on"><b style="color:#a11a1a">6</b><span>Lỗi, sẽ bỏ qua</span></div></div>
<div class="card"><div class="toolbar"><span class="input">Chế độ: Cập nhật và thêm mới (UPSERT)</span><span class="input">Lọc: Lỗi ▾</span><div style="flex:1"></div><span class="btn">Tải báo cáo lỗi (xlsx)</span></div>
<table><thead><tr><th>Dòng tệp</th><th>Mã</th><th>Tên</th><th>Loại</th><th>Lỗi</th></tr></thead><tbody>""" + rows([
 ["14","<span class='mono'>000.00.2.H99</span>","Sở Nội vụ","<span class='tag t-err'>Lỗi</span>","Mã không đúng mẫu ###.##.##.H99 (ERR-07-009)"],
 ["87","<span class='mono'>000.03.11.H99</span>","Phòng Kế hoạch","<span class='tag t-err'>Lỗi</span>","Mã cha 000.00.31.H99 không có trong bản nháp (ERR-07-010)"],
 ["233","","Trung tâm Y tế","<span class='tag t-err'>Lỗi</span>","Thiếu giá trị cột bắt buộc Mã"],
 ["412","<span class='mono'>000.05.02.H99</span>","Bệnh viện Đa khoa","<span class='tag t-err'>Lỗi</span>","Trùng mã với dòng 398"],
 ["990","<span class='mono'>000.06.77.H99</span>","Trường THPT Mẫu","<span class='tag t-err'>Lỗi</span>","Mã ĐVQHNS phải có 7 chữ số"],
 ["1.150","<span class='mono'>000.09.01.H99</span>","Ban Quản lý dự án","<span class='tag t-err'>Lỗi</span>","Ngày hiệu lực 31/02/2026 không hợp lệ"],
]) + """</tbody></table><div class="foot"><span class="btn">Quay lại</span><span class="btn">Hủy tác vụ</span><span class="btn pri">Ghi 152 thay đổi vào bản nháp</span></div></div>""")

P["07"] = ("So sánh và duyệt", "Việc của tôi / Lĩnh vực thủ tục hành chính / v8 so với v7", """
<div class="head"><h1>Lĩnh vực thủ tục hành chính · v8 so với v7</h1><span class="tag t-warn">Chờ duyệt</span><div class="sp"></div><span class="btn">Xuất khác biệt</span></div>
<div class="grid3"><div class="card"><div class="stats" style="margin:0 0 10px"><div class="stat"><b style="color:#0b6b3a">+6</b><span>Thêm mới</span></div><div class="stat on"><b style="color:#7a5200">✎19</b><span>Đã sửa</span></div><div class="stat"><b style="color:#a11a1a">−2</b><span>Ngừng dùng</span></div><div class="stat"><b>1</b><span>Phá vỡ</span></div></div>
<table><thead><tr><th>Loại</th><th>Mã</th><th>Trường</th><th>Giá trị</th></tr></thead><tbody>
<tr class="d-add"><td>Thêm mới</td><td class="mono">LV.412</td><td>Tên</td><td><ins>Chuyển đổi số</ins></td></tr>
<tr class="d-chg"><td>Đã sửa</td><td class="mono">LV.103</td><td>Tên</td><td><del>Bưu chính viễn thông</del> → <ins>Bưu chính, viễn thông và tần số</ins></td></tr>
<tr class="d-chg"><td>Đã sửa</td><td class="mono">LV.208</td><td>Cơ quan chủ trì</td><td><del>Sở TT&amp;TT</del> → <ins>Sở KH&amp;CN</ins></td></tr>
<tr class="d-del"><td>Ngừng dùng</td><td class="mono">LV.077</td><td>Trạng thái</td><td><del>Đang dùng</del> → <ins>Ngừng dùng</ins></td></tr>
<tr class="d-del"><td>Phá vỡ ⚠</td><td class="mono">LV.150</td><td>Mã</td><td>Xóa bản ghi đang được 3 hệ thống tham chiếu</td></tr>
<tr class="d-chg"><td>Đã sửa</td><td class="mono">LV.311</td><td>Thứ tự</td><td><del>14</del> → <ins>9</ins></td></tr>
</tbody></table></div>
<aside class="card raised" aria-label="Quyết định phiên bản"><h3 style="margin:0 0 8px">Quyết định</h3><div class="muted">Người trình: Trần Văn B. · 19/11/2026 10:03<br>Ghi chú: Cập nhật theo QĐ 2201/QĐ-UBND.</div>
<div class="field" style="margin-top:12px"><label>Ngày hiệu lực *</label><div class="input">01/12/2026</div></div><div class="field"><label>Ý kiến duyệt</label><div class="input" style="height:72px;align-items:flex-start;padding-top:6px">Đồng ý, lưu ý LV.150 đã báo các đơn vị.</div></div>
<div class="warn">Có 1 thay đổi phá vỡ. Bạn cần đánh dấu "Đã xem thay đổi phá vỡ" trước khi duyệt.</div>
<div class="foot" style="flex-wrap:wrap"><span class="btn danger">Từ chối</span><span class="btn">Duyệt</span><span class="btn pri">Duyệt và phát hành</span></div><div class="muted">Bạn không phải người trình nên được duyệt (bốn mắt).</div></aside></div>""")

P["08"] = ("Tác vụ nhập xuất", "Trang chủ / Tác vụ nhập xuất", """
<div class="head"><h1>Tác vụ nhập xuất</h1><div class="sp"></div><span class="input">Loại: Tất cả ▾</span><span class="input">Trạng thái: Tất cả ▾</span><span class="input">7 ngày gần nhất ▾</span></div>
<div class="card"><table><thead><tr><th>Mã tác vụ</th><th>Loại</th><th>Danh mục</th><th>Trạng thái</th><th>Tiến độ</th><th>Người tạo</th><th>Bắt đầu</th><th></th></tr></thead><tbody>""" + rows([
 ["<span class='mono'>01JD…7Q2</span>","Nhập","Cơ quan, đơn vị","<span class='tag t-info'>Đang kiểm tra</span>","62%","Nguyễn Lan","25/11 10:20","Xem"],
 ["<span class='mono'>01JD…6K1</span>","Xuất","Đơn vị hành chính","<span class='tag t-ok'>Hoàn thành</span>","100%","Nguyễn Lan","25/11 09:55","Tải xuống"],
 ["<span class='mono'>01JD…5M8</span>","Nhập","Khu, cụm công nghiệp","<span class='tag t-ok'>Đã ghi</span>","100%","Trần B.","24/11 16:02","Xem"],
 ["<span class='mono'>01JD…4X0</span>","Nhập","Lĩnh vực TTHC","<span class='tag t-err'>Thất bại</span>","—","Trần B.","24/11 14:31","Xem lỗi"],
 ["<span class='mono'>01JC…9P3</span>","Di trú","48 danh mục Aita","<span class='tag t-warn'>Chờ xác nhận</span>","100%","Quản trị tỉnh","23/11 21:00","Báo cáo"],
 ["<span class='mono'>01JC…8R7</span>","Nhập","Điểm du lịch","<span class='tag t-mute'>Đã hủy</span>","—","Lê H.","22/11 08:47","Xem"],
 ["<span class='mono'>01JC…2T5</span>","Xuất","Chức danh công chức","<span class='tag t-mute'>Hết hạn</span>","—","Lê H.","18/11 15:10","—"],
]) + """</tbody></table></div>""", """<div class="drawer" role="dialog" aria-label="Chi tiết tác vụ"><h3 style="margin:0 0 10px">Nhập · Cơ quan, đơn vị</h3><div class="card"><div class="muted">Trạng thái</div><b>Đang kiểm tra 62%</b><div style="height:8px;background:#e6efff;border-radius:4px;margin-top:8px"><div style="width:62%;height:8px;background:#0b5cd5;border-radius:4px"></div></div></div>
<div class="card"><div class="muted">Tệp</div>co_quan_2026_11.xlsx · 1,2 MB · đã quét mã độc ✓</div><div class="card"><div class="muted">Các bước</div>✓ Tải lên 10:20 · ✓ Quét 10:20 · ✓ Đọc tệp 10:21 · ⟳ Kiểm tra…</div><div class="foot"><span class="btn">Hủy tác vụ</span></div></div>""")

P["09"] = ("Đồng bộ quốc gia", "Trang chủ / Đồng bộ quốc gia / Tôn giáo", """
<div class="head"><h1>Đồng bộ · Tôn giáo</h1><span class="tag t-nat">Quốc gia 🔒</span><span class="tag t-err">Chờ xác nhận</span><div class="sp"></div><span class="btn">Lịch: 02:00 hằng ngày</span><span class="btn pri">Đồng bộ ngay</span></div>
<div class="grid3"><div class="card"><h3 style="margin:0 0 8px">Lần chạy 30/10/2026 02:00 · nguồn DMDC quốc gia</h3><div class="muted">Kết quả: +1 · ✎2 · −0 · Có 1 thay đổi phá vỡ nên cần xác nhận (FR-07-034)</div>
<table style="margin-top:10px"><thead><tr><th>Loại</th><th>Mã</th><th>Giá trị</th><th>Loại trừ</th></tr></thead><tbody>
<tr class="d-add"><td>Thêm mới</td><td class="mono">17</td><td><ins>Tôn giáo mới được công nhận</ins></td><td>☐</td></tr>
<tr class="d-chg"><td>Đã sửa</td><td class="mono">05</td><td><del>Tin lành</del> → <ins>Đạo Tin lành</ins></td><td>☐</td></tr>
<tr class="d-del"><td>Phá vỡ ⚠</td><td class="mono">12</td><td>Đổi mã <del>12</del> → <ins>12A</ins></td><td>☐</td></tr></tbody></table></div>
<div class="card raised"><h3 style="margin:0 0 8px">Xác nhận</h3><div class="field"><label>Ý kiến *</label><div class="input" style="height:72px">Đã đối chiếu thông báo của Bộ.</div></div><div class="foot"><span class="btn danger">Từ chối</span><span class="btn pri">Xác nhận, tạo bản nháp</span></div>
<h4 style="margin:12px 0 6px">Các lần chạy gần đây</h4><div class="muted">29/10 · Không đổi<br>28/10 · Không đổi<br>27/10 · Lỗi nguồn (503), đã thử lại 3 lần</div></div></div>""")

P["10"] = ("Ánh xạ mã", "Trang chủ / Ánh xạ mã / Dân tộc ↔ Mã dân tộc BHXH", """
<div class="head"><h1>Ánh xạ · Dân tộc ↔ Mã dân tộc BHXH</h1><div class="sp"></div><span class="btn">Nhập ánh xạ</span><span class="btn pri">Lưu 2 thay đổi</span></div>
<div class="stats"><div class="stat"><b>55</b><span>Mã nguồn</span></div><div class="stat"><b style="color:#0b6b3a">52</b><span>Đã ánh xạ (94,5%)</span></div><div class="stat on"><b style="color:#a11a1a">3</b><span>Chưa ánh xạ</span></div><div class="stat"><b>1</b><span>Nhiều đích</span></div></div>
<div class="card"><table role="grid"><thead><tr><th>Mã Datahub</th><th>Tên</th><th>Quan hệ</th><th>Mã hệ ngoài</th><th>Tên hệ ngoài</th><th>Hiệu lực từ</th></tr></thead><tbody>""" + rows([
 ["<span class='mono'>01</span>","Kinh","EQUAL","<span class='mono'>DT01</span>","Kinh","01/01/2024"],
 ["<span class='mono'>02</span>","Tày","EQUAL","<span class='mono'>DT02</span>","Tày","01/01/2024"],
 ["<span class='mono'>04</span>","Hoa","BROADER","<span class='mono'>DT04, DT04B</span>","Hoa; Hoa (Hán)","01/01/2024"],
 ["<span class='mono'>53</span>","Rơ Măm","<span class='tag t-err'>Chưa ánh xạ</span>","<span class='cell-edit'>|</span>","","—"],
 ["<span class='mono'>54</span>","Brâu","<span class='tag t-err'>Chưa ánh xạ</span>","","","—"],
 ["<span class='mono'>55</span>","Ơ Đu","<span class='tag t-err'>Chưa ánh xạ</span>","","","—"],
]) + """</tbody></table></div>""")

P["11"] = ("Đơn vị hành chính", "Trang chủ / Đơn vị hành chính", """
<div class="head"><h1>Đơn vị hành chính</h1><span class="tag t-nat">Quốc gia 🔒</span><div class="sp"></div><span class="input">Tại ngày: 25/11/2026</span></div>
<div class="tabs"><span class="on">Tra cứu</span><span>Dòng thời gian sắp xếp</span><span>Chuyển mã</span></div>
<div class="grid2"><div class="card tree" role="tree" aria-label="Cây đơn vị hành chính"><div>▾ Tỉnh Mẫu</div><div class="on">&nbsp;&nbsp;&nbsp;&nbsp;Phường Trung Tâm</div><div>&nbsp;&nbsp;&nbsp;&nbsp;Phường Bắc Sơn</div><div>&nbsp;&nbsp;&nbsp;&nbsp;Xã Đông Hòa</div><div>&nbsp;&nbsp;&nbsp;&nbsp;Xã Tây Lĩnh</div><div>&nbsp;&nbsp;&nbsp;&nbsp;Xã Nam Giang</div><div class="muted">&nbsp;&nbsp;&nbsp;&nbsp;… 97 xã, phường</div></div>
<div class="card"><h3 style="margin:0">Phường Trung Tâm <span class="mono muted">· mã 10123</span></h3><div class="muted">Hiệu lực từ 01/07/2025 · cấp xã · thuộc Tỉnh Mẫu</div>
<h4 style="margin:14px 0 4px">Dòng thời gian</h4><div class="timeline" aria-hidden="true"><div class="seg" style="width:55%;background:#c9d3e0"></div><div class="seg" style="width:45%;background:#0b5cd5"></div></div><div class="muted" style="display:flex;justify-content:space-between"><span>01/01/2008</span><span>01/07/2025 · Sáp nhập</span><span>Nay</span></div>
<table style="margin-top:12px"><caption class="muted" style="text-align:left;padding-bottom:4px">Sự kiện sắp xếp</caption><thead><tr><th>Ngày</th><th>Loại</th><th>Đơn vị nguồn</th><th>Đơn vị đích</th><th>Căn cứ</th></tr></thead><tbody>""" + rows([
 ["01/07/2025","MERGE","Phường 1 (00412), Phường 2 (00415), Xã Ven Sông (00418)","Phường Trung Tâm (10123)","NQ …/NQ-UBTVQH15"],
 ["01/07/2025","ABOLISH","Thành phố Mẫu (cấp huyện)","—","Luật Tổ chức CQĐP 2025"],
]) + """</tbody></table><div class="foot"><span class="btn">Sao chép mã</span><span class="btn pri">Chuyển mã danh sách…</span></div></div></div>""")

P["12"] = ("Thử API truy vấn", "Trang chủ / Thử API truy vấn", """
<div class="head"><h1>Thử API truy vấn</h1><div class="sp"></div><span class="btn">Sao chép cURL</span><span class="btn pri">Chạy (Ctrl+Enter)</span></div>
<div class="grid3" style="grid-template-columns:1fr 1fr"><div class="card"><div class="toolbar"><span class="input">Danh mục: KCN ▾</span><span class="input">Tại ngày: 25/11/2026</span><span class="input">Ứng dụng: Cổng DVC ▾</span></div>
<div class="code">POST /api/rdm/v1/catalogs/KCN/query
{
  "filter": {
    "and": [
      { "attr": "loai_hinh", "op": "in", "value": ["KCN", "CCN"] },
      { "attr": "dien_tich_ha", "op": "gte", "value": "100" },
      { "attr": "ma_dvhc_xa", "op": "eq", "value": "10123" }
    ]
  },
  "fields": ["code", "name", "dien_tich_ha"],
  "sort": [{ "attr": "dien_tich_ha", "dir": "desc" }],
  "pageSize": 20
}</div><div class="muted" style="margin-top:6px">✓ Hợp lệ theo lược đồ v4 · thuộc tính truy vấn được: loai_hinh, dien_tich_ha, ma_dvhc_xa</div></div>
<div class="card"><div class="toolbar"><span class="tag t-ok">200 OK</span><span class="muted">38 ms · 3 kết quả · ETag "v4"</span><div style="flex:1"></div><span class="btn">Bảng</span><span class="btn pri">JSON</span></div>
<div class="code">{
  "items": [
    { "code": "KCN-01", "name": "KCN Phía Bắc", "dien_tich_ha": "312.50" },
    { "code": "KCN-03", "name": "KCN Ven Sông", "dien_tich_ha": "205.00" },
    { "code": "CCN-07", "name": "CCN Trung Tâm", "dien_tich_ha": "104.20" }
  ],
  "page": { "size": 20, "next": null },
  "version": { "no": 4, "effectiveFrom": "2026-09-01" }
}</div></div></div>""")

for code, (title, crumb, body, *extra) in P.items():
    (OUT / f"ui-07-{code}.html").write_text(shell(code, title, crumb, body, extra[0] if extra else ""), encoding="utf-8")
print("đã sinh", len(P), "tệp")
