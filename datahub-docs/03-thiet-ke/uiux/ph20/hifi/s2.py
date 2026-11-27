from kit import *
from dat import *

P = {}
SC = "Nền tảng › Sáp nhập"


def mp(t):
    return {"MAP": "<span class='tag t-ok'>⇄ Ánh xạ</span>", "CREATE": "<span class='tag t-info'>＋ Tạo mới</span>", "SKIP": "<span class='tag t-mute'>– Bỏ qua</span>", "?": "<span class='tag t-err'>? Chưa quyết</span>"}[t]


# ------------------------------------------------------------------ 09 Lập kế hoạch sáp nhập (bước 3 Ánh xạ)
maps = [
    ["Tổ chức", "<span class='mono'>UBND-TINH</span> UBND tỉnh Mẫu H", mp("MAP"), "<span class='mono'>UBND-TINH</span> UBND tỉnh Mẫu K", "Bắt buộc"],
    ["Tổ chức", "<span class='mono'>SO-KHCN</span> Sở Khoa học và Công nghệ", mp("MAP"), "<span class='mono'>SO-KHCN</span>", "Bắt buộc"],
    ["Tổ chức", "<span class='mono'>SO-DULICH</span> Sở Du lịch", mp("?"), "Chọn tổ chức đích…", "<b>Bắt buộc</b>"],
    ["HTTT", "<span class='mono'>qlvb-t12</span> Quản lý văn bản", mp("CREATE"), "<span class='mono'>qlvb-t12</span>", "Bắt buộc"],
    ["HTTT", "<span class='mono'>hotich-t12</span> Hộ tịch điện tử", mp("?"), "Chọn HTTT đích…", "<b>Bắt buộc</b>"],
    ["Tiền tố API", "<span class='mono'>/t12/hotich</span>", mp("?"), "Nhập tiền tố đích…", "<b>Bắt buộc</b>"],
    ["Mã danh mục", "<span class='mono'>DM-LOAIVB</span> Loại văn bản (địa phương)", mp("MAP"), "<span class='mono'>DM-LOAIVB</span>", "Tùy chọn"],
    ["Người dùng", "412 người dùng ở realm dh-t12", mp("CREATE"), "Tạo ở realm dh-t13", "Tùy chọn"],
    ["Topic", "<span class='mono'>t12.hotich.created.v1</span>", mp("CREATE"), "<span class='mono'>t13.hotich-t12.created.v1</span>", "Tùy chọn"],
]
cls_ = [None, None, "d-del", None, "d-del", "d-del", None, None, None]
body = f"""
{head("Lập kế hoạch sáp nhập", '<span class="tag t-info">Bản nháp SN-2026-004</span>')}
<div class="steps"><div class="done">✓ 1 Nguồn và đích</div><div class="done">✓ 2 Căn cứ</div><div class="on"><b>3 Bảng ánh xạ</b></div><div>4 Chạy thử</div><div>5 Gửi duyệt</div></div>
{alert("e", "<b>ERR-20-042</b> · Bảng ánh xạ còn 3 dòng bắt buộc chưa quyết định. Chưa chạy thử được.")}
<div class="cols2">
 <div class="card" style="padding:0"><div class="toolbar" style="margin:0"><b>Bảng ánh xạ</b><span class="muted">96 dòng · bắt buộc 41, còn 3 chưa quyết</span><span class="sp"></span><span class="seg"><span class="on">Chưa quyết 3</span><span>Bắt buộc</span><span>Tất cả</span></span>{btn("Gợi ý tự động")}</div>
 {table(["Loại", "Đối tượng nguồn (T12)", "Hành động", "Đích (T13)", "Mức"], maps, "Bảng ánh xạ sáp nhập", cls=cls_)}{foot("Hiển thị 9 trên 96 dòng")}</div>
 <div>
  <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Kế hoạch</h3>
   <dl class="kv"><dt>Tenant nguồn</dt><dd><span class="mono">T12</span> Tỉnh Mẫu H · {ts("ACTIVE")}</dd><dt>Tenant đích</dt><dd><span class="mono">T13</span> Tỉnh Mẫu K · {ts("ACTIVE")}</dd>
   <dt>Căn cứ</dt><dd>Nghị quyết 07/NQ-2026, 20/11/2026</dd><dt>Hiệu lực</dt><dd>01/01/2027</dd><dt>Chuyển tiếp</dt><dd>6 tháng (tối đa 12)</dd><dt>Phân hệ tham gia</dt><dd>PH-01, 02, 03, 04, 05, 07, 10, 12</dd></dl></div>
  <div class="card" style="margin-top:10px"><h3 style="margin:0 0 8px;font-size:15px">Chạy thử</h3><div class="muted">Chưa chạy. Cần bảng ánh xạ đủ, kết quả đạt và còn mới (so với <span class="mono">mappingHash</span>) mới gửi duyệt được (ERR-20-043).</div>
   <div class="foot">{btn("‹ Quay lại")}{btn("Chạy thử", "dis")}{btn("Gửi duyệt", "dis")}</div>
   <div class="muted">Nút khóa vì còn dòng bắt buộc chưa quyết. Cần hai quản trị nền tảng khác nhau (người lập, người duyệt).</div></div>
 </div>
</div>
"""
P["09"] = ("Lập kế hoạch sáp nhập", SC + " › Lập mới", body, "", dict(active="sn"))

# ------------------------------------------------------------------ 10 Theo dõi sáp nhập (SN-2026-001, CONFLICT_REVIEW)
mods = [["1", "PH-20 Tổ chức", "● Xong", "212", "212", "0", "● Khớp"], ["2", "PH-07 Danh mục", "● Xong", "1.844", "1.844", "1", "● Khớp"], ["3", "PH-01 HTTT", "● Xong", "86", "86", "0", "● Khớp"],
        ["4", "PH-02 Dịch vụ", "● Xong", "94", "94", "0", "● Khớp"], ["5", "PH-10 Topic", "◔ Đang chuyển", "301", "188", "1", "—"], ["6", "PH-04 Luồng", "◔ Đang chuyển", "57", "40", "1", "—"],
        ["6", "PH-05 Bộ điều hợp", "✕ Lỗi", "33", "31", "0", "<span class='err-t'>✕ Lệch (ERR-20-113)</span>"], ["7", "PH-03 Cổng API", "○ Chờ", "—", "—", "0", "—"]]
mrows = []
for r in mods:
    st_ = {"● Xong": "ok", "◔ Đang chuyển": "info", "✕ Lỗi": "err", "○ Chờ": "mute"}[r[2]]
    mrows.append([r[0], f"<b>{r[1]}</b>", f"<span class='tag t-{st_}'>{r[2]}</span>", r[3], r[4], r[5], r[6]])
mrows[6][2] = mrows[6][2]
body = f"""
<div class="head"><h1>Sáp nhập <span class="mono">SN-2026-001</span></h1><span class="tag t-warn">⚑ Xử lý xung đột</span><span class="muted"><span class="mono">T12</span> → <span class="mono">T13</span> · hiệu lực 01/01/2027</span><div class="sp"></div>{btn("Chạy lại phân hệ")}{btn("Thực hiện cutover…", "dis")}</div>
{banner("w", "ERR-20-044 · Còn 3 xung đột sáp nhập chưa xử lý. Chưa thực hiện được cutover.", "Mở tab Xung đột")}
<div class="step" style="margin-top:0"><div class="d">Lập, duyệt</div><div class="d">Chạy thử</div><div class="c"><b>Chuyển dữ liệu</b></div><div class="c">Xung đột</div><div>Định danh</div><div>Cutover</div><div>Chuyển tiếp 6 tháng</div><div>Hoàn tất</div></div>
{tabs(["Phân hệ", "Xung đột 3", "Chuyển tiếp", "Kiểm toán"], 0)}
<div class="cols2">
 <div class="card" style="padding:0">{table(["Thứ tự", "Phân hệ", "Trạng thái", "Bản ghi nguồn", "Đã nhập đích", "Xung đột", "Kiểm đếm"], mrows, "Tiến độ chuyển theo phân hệ", num=(3, 4, 5))}
  <div style="padding:8px 14px" class="muted">Kiểm đếm so số bản ghi nguồn và đích, trừ dòng bỏ qua. Lệch thì phân hệ chuyển lỗi: "Kiểm đếm PH-05 lệch: nguồn 33, đích 31."</div></div>
 <div>
  <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Xung đột mở: <span class="mono">DM-LOAIVB</span> (mã danh mục)</h3>
   <div class="diffgrid"><div class="h">Nguồn T12</div><div class="h">Đích T13</div><div class="c">code: DM-LOAIVB</div><div class="c">code: DM-LOAIVB</div><div class="r">name: Loại văn bản đến</div><div class="a">name: Loại văn bản</div><div>items: 14</div><div>items: 17</div></div>
   <div class="row" style="margin-top:8px"><span class="chip">Giữ đích</span><span class="chip">Giữ nguồn</span><span class="chip">Đổi mã nguồn</span><span class="chip" style="outline:2px solid #0b5cd5">Gộp mục</span><span class="chip">Bỏ qua</span></div>
   <div class="muted">"Gộp mục" chỉ cho mã danh mục. Quyết định hàng loạt cần ý kiến chung.</div></div>
  <div class="card" style="margin-top:10px"><h3 style="margin:0 0 6px;font-size:15px">Vai trò xem</h3><div class="muted">Quản trị tỉnh T12 và T13 (chỉ đọc) chỉ thấy tab Chuyển tiếp của tỉnh mình.</div></div>
 </div>
</div>
"""
P["10"] = ("Theo dõi sáp nhập", SC + " › SN-2026-001", body, "", dict(active="sn"))

# ------------------------------------------------------------------ 11 Danh sách sáp nhập
pl = [["<b class='mono'>SN-2026-001</b>", "<span class='mono'>T12</span> → <span class='mono'>T13</span>", "01/01/2027", "<span class='tag t-warn'>⚑ Xử lý xung đột</span>", "7 / 8 phân hệ", "3", "Nguyễn Văn An"],
      ["<b class='mono'>SN-2026-002</b>", "<span class='mono'>T05</span> + <span class='mono'>T06</span> → <span class='mono'>T08</span>", "01/07/2027", "<span class='tag t-info'>✎ Bản nháp</span>", "—", "—", "Trần Thị Bình"],
      ["<b class='mono'>SN-2026-003</b>", "<span class='mono'>T10</span> → <span class='mono'>T11</span>", "01/03/2027", "<span class='tag t-warn'>⏳ Chờ duyệt</span>", "—", "—", "Nguyễn Văn An"],
      ["<b class='mono'>MG-2025-001</b>", "<span class='mono'>T31</span> → <span class='mono'>T30</span>", "01/07/2026", "<span class='tag t-ok'>● Chuyển tiếp đến 01/01/2027</span>", "8 / 8 phân hệ", "0", "Trần Thị Bình"],
      ["<b class='mono'>MG-2025-002</b>", "<span class='mono'>T21</span> → <span class='mono'>T22</span>", "01/01/2026", "<span class='tag t-mute'>✓ Hoàn tất</span>", "8 / 8 phân hệ", "0", "Nguyễn Văn An"]]
body = f"""
{head("Danh sách sáp nhập", inp("Tìm mã kế hoạch hoặc tenant…", "min-width:240px"), btn("＋ Lập kế hoạch sáp nhập", "pri"))}
{facets(["Tất cả 5", "Bản nháp 1", "Chờ duyệt 1", "Đang chuyển 1", "Chuyển tiếp 1", "Hoàn tất 1"], 0)}
<div class="card" style="padding:0">{table(["Mã kế hoạch", "Nguồn → đích", "Hiệu lực", "Trạng thái", "Tiến độ", "Xung đột mở", "Người lập"], pl, "Danh sách kế hoạch sáp nhập", num=(5,))}{foot("Hiển thị 1–5 trên 5")}</div>
<div class="muted" style="margin-top:8px">Nguồn T12 đang ở trạng thái Đang sáp nhập nên mọi người dùng của T12 thấy dải vàng. Kế hoạch chờ duyệt không được người lập duyệt (ERR-20-007).</div>
"""
P["11"] = ("Danh sách sáp nhập", SC, body, "", dict(active="sn"))

# ------------------------------------------------------------------ 12 Cài đặt tỉnh (T68, TA)
top = '<div class="tbanner x" role="status"><span>⚠</span><span>Bảo trì nâng cấp lên 2.5.0 vào Thứ Bảy 06/12/2026, 22:00 đến 02:00. Thao tác ghi có thể tạm dừng trong thời gian này.</span><span class="sp"></span><span class="btn">Xem ghi chú phát hành</span></div>'
body = f"""
{head("Cài đặt tỉnh", '<span class="tag t-ok">Phiên bản cấu hình v6</span>', btn("Hủy thay đổi"), btn("Lưu thay đổi", "pri"))}
<div class="grid2" style="grid-template-columns:230px minmax(0,1fr)">
 <div class="card tree" style="padding:10px"><div class="on">Thông tin hiển thị</div><div>Chủ quản CNTT</div><div>An toàn đăng nhập</div><div>Phiên bản và bảo trì</div></div>
 <div>
  <div class="card"><h3 style="margin:0 0 10px;font-size:15px">Thông tin hiển thị và chủ quản CNTT</h3>
   <div class="row"><div class="field"><label>Tên hiển thị *</label><span class="input" style="color:#1a1d23">Datahub tỉnh T68</span></div><div class="field"><label>Logo (PNG, SVG, tối đa 512 KB)</label><span class="input">logo-t68.svg · 18 KB ✓</span></div></div>
   <div class="row"><div class="field"><label>Tổ chức chủ quản CNTT *</label><span class="input" style="color:#1a1d23">SO-KHCN · Sở Khoa học và Công nghệ ▾</span></div><div class="field"><label>Thư hỗ trợ</label><span class="input" style="color:#1a1d23">ho-tro@t68.example.vn</span></div></div></div>
  <div class="card" style="margin-top:12px"><h3 style="margin:0 0 4px;font-size:15px">An toàn đăng nhập</h3><div class="muted" style="margin-bottom:8px">Chỉ chặt hơn mức nền tảng, không nới.</div>
   <div class="row"><div class="field"><label>Hết phiên khi không thao tác (phút) *</label><span class="input" style="color:#1a1d23">10</span><div class="muted">Miền 5…15, nền tảng 15</div></div>
   <div class="field"><label>Độ dài mật khẩu tối thiểu *</label><span class="input" style="color:#1a1d23;outline:2px solid #c0392b">12</span><div class="err-t">ERR-20-023 · Độ dài mật khẩu tối thiểu vượt giới hạn của nền tảng (14 đến 64).</div></div></div>
   <div class="field"><label>Vai trò bắt buộc MFA *</label><span class="chip">ROLE-TENANT_ADMIN 🔒</span><span class="chip">ROLE-SECURITY_OFFICER ✕</span><div class="muted">Quản trị tỉnh luôn bắt buộc, không bỏ được.</div></div></div>
  <div class="card" style="margin-top:12px"><h3 style="margin:0 0 8px;font-size:15px">Phiên bản và bảo trì</h3>
   <div class="row"><dl class="kv" style="flex:1"><dt>Phiên bản đang chạy</dt><dd><b class="mono">2.4.1</b> · STABLE</dd><dt>Nâng cấp tới</dt><dd><span class="mono">2.5.0</span> · 06/12 22:00</dd><dt>Ghi chú 2.4.1</dt><dd>Sửa lỗi đồng bộ danh mục, tăng tốc tra cứu</dd></dl>
   <div class="field" style="flex:1"><label>Cửa sổ bảo trì ưa thích *</label><span class="input" style="color:#1a1d23">Thứ Bảy · 22:00 · 4 giờ ▾</span><div class="muted">Dài 2…6 giờ, không trùng 7:00–17:00 ngày làm việc (ERR-20-059).</div></div></div></div>
 </div>
</div>
"""
P["12"] = ("Cài đặt tỉnh", "Quản trị › Cài đặt tỉnh", body, "", dict(mode="T", active="cd", top=top))

# ------------------------------------------------------------------ 13 Sử dụng tài nguyên của tỉnh (T68, TA, TO, AU)
bars = "".join(qbar(nm, c, u, l, un) for c, nm, un, l, u in RES)
ln = echart_line([("Lượt gọi API p95", [210, 240, 260, 255, 300, 340, 330, 360, 380, 395, 410, 410], "#0b5cd5", "")], ["1/11", "4/11", "7/11", "10/11", "13/11", "16/11", "19/11", "22/11", "24/11", "25/11", "26/11", "27/11"],
                 w=520, h=190, ymin=0, ymax=600, marks=[(500, "Hạn mức 500", "#c0392b"), (400, "Ngưỡng 80 % = 400", "#c98a00")], area=True, yfmt="{:.0f}")
body = f"""
{head("Sử dụng tài nguyên của tỉnh", inp("Kỳ: 30 ngày qua ▾"), btn("Xuất CSV"))}
<div class="alert w"><span>▲ <b>Lượt gọi API mỗi giây</b> đang ở 82 % hạn mức (410 / 500). Liên hệ quản trị nền tảng nếu cần tăng. Hạn mức do hợp đồng quy định, quản trị tỉnh chỉ xem.</span></div>
<div class="cols2">
 <div class="card"><h3 style="margin:0 0 6px;font-size:15px">Mức dùng so hạn mức hiệu lực</h3>{bars}<div class="muted" style="margin-top:6px">Vạch đen là ngưỡng 80 %. Ảnh chụp mỗi giờ, cập nhật 09:00. Mỗi dòng có chữ trạng thái ngoài màu.</div></div>
 <div>
  <div class="card"><h3 style="margin:0 0 4px;font-size:15px">Lượt gọi API mỗi giây (p95)</h3>{ln}</div>
  <div class="card" style="margin-top:10px"><h3 style="margin:0 0 6px;font-size:15px">Cảnh báo của tỉnh</h3>{table(["Tài nguyên", "Mức", "Từ"], [["API_RPS", "<span class='tag t-warn'>▲ 82 %</span>", "26/11 14:00"], ["OBJECT_STORAGE_GB", "<span class='tag t-err'>✕ 101 %</span>", "27/11 09:05"]], "Cảnh báo hạn mức của tỉnh")}</div>
 </div>
</div>
"""
P["13"] = ("Sử dụng tài nguyên của tỉnh", "Quản trị › Cài đặt tỉnh › Sử dụng tài nguyên", body, "", dict(mode="T", active="cd"))

# ------------------------------------------------------------------ 14 Danh mục tổ chức (cây + bảng)
tree = """<div class="otree"><div>▾ <b>UBND tỉnh Lâm Viên</b></div><div style="padding-left:16px">▾ Các sở, ngành (14)</div><div style="padding-left:32px" class="on">Sở Khoa học và Công nghệ</div><div style="padding-left:32px">Sở Thông tin và Truyền thông</div>
<div style="padding-left:32px">Sở Tài chính</div><div style="padding-left:32px" class="gone">Sở Du lịch <span class="tag t-mute">Đã sáp nhập</span></div><div style="padding-left:32px">Sở Văn hóa, Thể thao và Du lịch</div><div style="padding-left:16px">▸ UBND cấp xã (138)</div><div style="padding-left:16px">▸ Đơn vị sự nghiệp (23)</div></div>"""
orgs = [["<b class='mono'>SO-KHCN</b>", "Sở Khoa học và Công nghệ", "Sở, ngành", "UBND-TINH", "01/07/2025", "<span class='tag t-ok'>● Hoạt động</span>", "<span class='tag t-info'>Chủ quản dữ liệu</span>"],
        ["<b class='mono'>SO-TTTT</b>", "Sở Thông tin và Truyền thông", "Sở, ngành", "UBND-TINH", "01/07/2025", "<span class='tag t-ok'>● Hoạt động</span>", "—"],
        ["<b class='mono'>SO-TC</b>", "Sở Tài chính", "Sở, ngành", "UBND-TINH", "01/07/2025", "<span class='tag t-ok'>● Hoạt động</span>", "<span class='tag t-info'>Chủ quản dữ liệu</span>"],
        ["<b class='mono'>SO-DULICH</b>", "Sở Du lịch", "Sở, ngành", "UBND-TINH", "01/07/2025", "<span class='tag t-mute'>⇥ Đã sáp nhập → SO-VHTTDL</span>", "—"],
        ["<b class='mono'>SO-VHTTDL</b>", "Sở Văn hóa, Thể thao và Du lịch", "Sở, ngành", "UBND-TINH", "01/10/2026", "<span class='tag t-ok'>● Hoạt động</span>", "—"]]
body = f"""
{head("Danh mục tổ chức", inp("Tìm theo mã hoặc tên…", "min-width:220px"), btn("Nhập từ tệp"), btn("Xuất"), btn("＋ Tạo tổ chức", "pri"))}
{alert("w", "<b>3 đề xuất đồng bộ</b> do sắp xếp đơn vị hành chính (UBND xã Mẫu 1 và Mẫu 2 sáp nhập thành UBND xã Mẫu 12). Xem và áp hoặc bỏ có lý do.", "Xem đề xuất")}
<div class="grid2" style="grid-template-columns:300px minmax(0,1fr)">
 <div class="card">{tree}</div>
 <div class="card" style="padding:0"><div class="toolbar" style="margin:0"><span class="input">Loại: tất cả ▾</span><span class="input">Trạng thái: hoạt động ▾</span><span class="chip">☐ Chỉ chủ quản dữ liệu</span><span class="sp"></span><span class="muted">14 tổ chức dưới "Các sở, ngành"</span></div>
 {table(["Mã", "Tên", "Loại", "Cấp trên", "Hiệu lực từ", "Trạng thái", "Chủ quản dữ liệu"], orgs, "Tổ chức dưới nút đang chọn")}{foot("Hiển thị 1–5 trên 14")}</div>
</div>
"""
P["14"] = ("Danh mục tổ chức", "Quản trị › Tổ chức", body, "", dict(mode="T", active="to"))

# ------------------------------------------------------------------ 15 Chi tiết, biểu mẫu tổ chức (sửa + giải thể)
body = f"""
<div class="head"><h1>Sửa tổ chức <span class="mono">SO-TTTT</span></h1><span class="tag t-ok">● Hoạt động</span><div class="sp"></div>{btn("Giải thể…", "danger")}{btn("Hủy")}{btn("Lưu", "pri")}</div>
<div class="cols2">
 <div>
  <div class="card"><h3 style="margin:0 0 10px;font-size:15px">Thông tin tổ chức</h3>
   <div class="row"><div class="field"><label>Mã tổ chức (không đổi)</label><span class="input" style="background:#f1f3f5"><span class="mono">SO-TTTT</span> 🔒</span></div><div class="field"><label>Loại *</label><span class="input" style="color:#1a1d23">Sở, ngành (DEPARTMENT) ▾</span></div></div>
   <div class="row"><div class="field"><label>Tên đầy đủ *</label><span class="input" style="color:#1a1d23">Sở Thông tin và Truyền thông</span></div><div class="field"><label>Tên viết tắt</label><span class="input" style="color:#1a1d23">Sở TT&amp;TT</span></div></div>
   <div class="row"><div class="field"><label>Tổ chức cấp trên</label><span class="input" style="color:#1a1d23">UBND-TINH · UBND tỉnh Lâm Viên ▾</span></div><div class="field"><label>Đơn vị hành chính *</label><span class="input" style="color:#1a1d23">Tỉnh Lâm Viên ▾</span></div></div>
   <div class="row"><div class="field"><label>Mã định danh điện tử</label><span class="input" style="color:#1a1d23">H68.07</span></div><div class="field"><label>Hiệu lực từ *</label><span class="input" style="color:#1a1d23">01/07/2025</span></div><div class="field"><label>Hiệu lực đến</label><span class="input">—</span></div></div>
   <div class="row"><span>{sw(True)} Là chủ quản dữ liệu</span><span class="muted">Lĩnh vực: thông tin truyền thông, chuyển đổi số</span></div></div>
  <div class="card" style="margin-top:12px;outline:2px solid #f2b8b8"><h3 style="margin:0 0 6px;font-size:15px">Giải thể có tổ chức kế thừa</h3>
   <div class="err-t" style="margin-bottom:8px">ERR-20-049 · Tổ chức SO-TTTT còn 61 đối tượng tham chiếu. Chọn tổ chức kế thừa.</div>
   <div class="row"><div class="field"><label>Tổ chức kế thừa *</label><span class="input" style="outline:2px solid #c0392b">Chọn tổ chức đang hoạt động… ▾</span></div><div class="field"><label>Ngày hết hiệu lực *</label><span class="input">—</span></div><div class="field"><label>Văn bản quyết định</label><span class="input">—</span></div></div></div>
 </div>
 <div>
  <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Đối tượng đang tham chiếu</h3>{table(["Phân hệ", "Đối tượng", "Số lượng"], [["PH-01", "Hệ thống thành viên do tổ chức chủ quản", "12"], ["PH-12", "Người dùng thuộc tổ chức", "46"], ["PH-06, PH-08", "Đối tượng giao làm chủ quản dữ liệu", "3"]], "Tham chiếu tổ chức", num=(2,))}</div>
  <div class="card" style="margin-top:10px"><h3 style="margin:0 0 8px;font-size:15px">Lịch sử hiệu lực</h3><div class="vtl"><div><b>01/07/2025</b> Hiệu lực, cấp trên UBND-TINH</div><div><b>15/03/2026</b> Đánh dấu chủ quản dữ liệu · Nguyễn Văn Cường</div></div></div>
 </div>
</div>
"""
P["15"] = ("Chi tiết, biểu mẫu tổ chức", "Quản trị › Tổ chức › SO-TTTT › Sửa", body, "", dict(mode="T", active="to"))

# ------------------------------------------------------------------ 16 Nhập tổ chức (xem trước)
imp = [["2", "<span class='mono'>UBND-X001</span>", "UBND xã Mẫu 1", "UBND-TINH", "<span class='tag t-info'>＋ Tạo</span>", ""], ["3", "<span class='mono'>UBND-X002</span>", "UBND xã Mẫu 2", "UBND-TINH", "<span class='tag t-info'>＋ Tạo</span>", ""],
       ["4", "<span class='mono'>SO-KHCN</span>", "Sở Khoa học và Công nghệ", "UBND-TINH", "<span class='tag t-warn'>✎ Cập nhật tên viết tắt</span>", ""], ["5", "<span class='mono'>SO-TC</span>", "Sở Tài chính", "UBND-TINH", "<span class='tag t-mute'>= Không đổi</span>", ""],
       ["6", "<span class='mono'>UBND-X003</span>", "UBND xã Mẫu 3", "<span class='mono'>UBND-X999</span>", "<span class='tag t-err'>✕ Lỗi</span>", "Tổ chức cấp trên UBND-X999 không tồn tại (ERR-20-047)"],
       ["7", "<span class='mono'>ubnd-x004</span>", "UBND xã Mẫu 4", "UBND-TINH", "<span class='tag t-err'>✕ Lỗi</span>", "Mã sai mẫu, phải viết hoa (ERR-20-004)"]]
body = f"""
{head("Nhập tổ chức", btn("Tải tệp mẫu"))}
<div class="steps"><div class="done">✓ 1 Tải tệp</div><div class="on"><b>2 Xem trước</b></div><div>3 Xác nhận</div></div>
{alert("e", "<b>ERR-20-051</b> · Còn 2 dòng lỗi. Sửa tệp rồi tải lại. Nút \"Xác nhận nhập\" chỉ bật khi không còn dòng lỗi.")}
{kpis([kpi("Tệp", "to-chuc-xa.xlsx", "312 dòng · 148 KB"), kpi("Tạo mới", "296", ""), kpi("Cập nhật", "9", ""), kpi("Không đổi", "5", ""), kpi("Lỗi", "2", "Giới hạn 5.000 dòng")], 5)}
<div class="card" style="padding:0"><div class="toolbar" style="margin:0"><span class="seg"><span>Tất cả 312</span><span class="on">Chỉ lỗi 2</span></span><span class="input">Chế độ: chỉ tạo mới ▾</span><span class="sp"></span><span class="muted">Quét mã độc xong · kiểm cha trước con</span></div>
{table(["Dòng", "Mã", "Tên", "Cấp trên", "Hành động", "Chi tiết lỗi"], imp, "Xem trước kết quả kiểm từng dòng", cls=[None, None, None, None, "d-del", "d-del"])}
<div class="foot" style="padding:10px 14px">{btn("Tải lại tệp")}{btn("Xác nhận nhập 310 dòng", "dis")}</div></div>
"""
P["16"] = ("Nhập tổ chức", "Quản trị › Tổ chức › Nhập", body, "", dict(mode="T", active="to"))
