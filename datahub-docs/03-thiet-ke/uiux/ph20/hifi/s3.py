from kit import *
from dat import *

P = {}
PC = "Nền tảng › Tenant"

# ------------------------------------------------------------------ 17 Phiên bản và lệch cấu hình (T01)
vers = [["<b>v14</b>", "27/11 08:40", "Nguyễn Văn An", "quota.yaml", "<span class='tag t-ok'>● Đã áp</span>", "Tăng API_RPS ghi đè đến 15/12 · SR-2026-1190"],
        ["<b>v13</b>", "12/11 10:02", "Trần Thị Bình", "release.yaml", "<span class='tag t-ok'>● Đã áp</span>", "Đổi kênh sang STABLE · SR-2026-1102"],
        ["<b>v12</b>", "02/11 22:41", "Hệ thống", "release.yaml", "<span class='tag t-ok'>● Đã áp</span>", "Nâng cấp 2.4.1 theo kế hoạch UP-2026-07"],
        ["<b>v11</b>", "20/10 09:30", "Nguyễn Văn An", "modules.yaml", "<span class='tag t-ok'>● Đã áp</span>", "Bật PH-19 · SR-2026-0988"],
        ["<b>v10</b>", "05/10 14:11", "Nguyễn Văn An", "tenant.yaml", "<span class='tag t-warn'>◔ Đã commit, chờ áp</span>", "Đổi vùng DR · SR-2026-0951"]]
drifts = [["<span class='mono'>realm.passwordPolicy</span>", "PH-12", "minLength: 14", "minLength: 10", "<span class='tag t-err'>✕ Lệch an ninh</span>", btn("Áp lại Git") + btn("Nhận vào Git")],
          ["<span class='mono'>kafka.quota.consume</span>", "PH-10", "20 MB/giây", "25 MB/giây", "<span class='tag t-warn'>▲ Lệch</span>", btn("Áp lại Git") + btn("Nhận vào Git")]]
body = f"""
<div class="head"><h1>Phiên bản cấu hình <span class="mono">T01</span></h1>{ts("ACTIVE")}<span class="muted">Đối chiếu gần nhất 09:00 · mỗi giờ</span><div class="sp"></div>{btn("Đối chiếu ngay")}{btn("Khôi phục v13…", "danger")}</div>
{tabs(["Phiên bản", "Lệch cấu hình 2"], 0)}
{alert("e", "<b>ERR-20-025</b> · Cấu hình tenant T01 đang lệch chưa xử lý. Đối chiếu trước khi sửa. Có 2 khác biệt, 1 ở khóa an ninh đã báo vận hành.")}
<div class="cols2">
 <div class="card" style="padding:0">{table(["Phiên bản", "Thời điểm", "Người", "Tệp đổi", "Trạng thái", "Lý do"], vers, "Lịch sử phiên bản cấu hình")}{foot("Hiển thị 5 trên 14 phiên bản")}</div>
 <div class="card"><h3 style="margin:0 0 8px;font-size:15px">So sánh <span class="mono">v13</span> và <span class="mono">v14</span> · quota.yaml</h3>
  <div class="diffgrid"><div class="h">v13 · 12/11</div><div class="h">v14 · 27/11</div><div>apiVersion: dh/v1</div><div>apiVersion: dh/v1</div><div>tenant: T01</div><div>tenant: T01</div><div class="r">  API_RPS: 500</div><div class="a">  API_RPS: 800</div><div class="c">  overrideUntil: null</div><div class="c">  overrideUntil: 2026-12-15</div><div>  ACTIVE_FLOWS: 1000</div><div>  ACTIVE_FLOWS: 1000</div></div>
  <div class="muted" style="margin-top:8px">Khôi phục áp phiên bản cũ như một thay đổi mới, không xóa lịch sử, cần lý do và mã phiếu. Phiên bản tương thích lược đồ hiện hành (ERR-20-026 nếu không).</div></div>
</div>
<div class="card" style="margin-top:12px"><h3 style="margin:0 0 8px;font-size:15px">Lệch cấu hình đang mở</h3>{table(["Khóa", "Phân hệ", "Giá trị trong Git", "Giá trị thực", "Mức", "Xử lý"], drifts, "Lệch cấu hình")}</div>
"""
P["17"] = ("Phiên bản và lệch cấu hình", PC + " › T01 › Lịch sử cấu hình", body, "", dict(active="tn"))

# ------------------------------------------------------------------ 18 Phiên bản sản phẩm và kênh
rel = [["<b class='mono'>2.5.0</b>", "<span class='tag t-info'>◔ PREVIEW</span>", "13/11/2026", "Soak 9 / 14 ngày", "2", "Lược đồ EXPAND 3", btn("Nâng lên STABLE", "pri") + btn("Rút")],
       ["<b class='mono'>2.4.1</b>", "<span class='tag t-ok'>● STABLE</span>", "30/10/2026", "Đạt 14 ngày", "9", "Không", btn("Ngừng hỗ trợ")],
       ["<b class='mono'>2.4.0</b>", "<span class='tag t-ok'>● STABLE</span>", "02/10/2026", "Đạt 14 ngày", "21", "Có CONTRACT 1", btn("Ngừng hỗ trợ")],
       ["<b class='mono'>2.3.2</b>", "<span class='tag t-warn'>▲ Ngoài hỗ trợ</span>", "04/09/2026", "—", "2", "Không", "—"],
       ["<b class='mono'>2.4.2-rc1</b>", "<span class='tag t-err'>✕ Đã rút</span>", "21/10/2026", "—", "0", "Không", "—"]]
body = f"""
{head("Phiên bản sản phẩm và kênh phát hành", inp("Kênh: tất cả ▾"), btn("＋ Đăng ký phiên bản", "pri"))}
{alert("e", "<b>ERR-20-054</b> · Phiên bản 2.5.0 mới thí điểm 9 ngày, cần tối thiểu 14 ngày và không có sự cố mức 1.")}
<div class="cols2">
 <div class="card" style="padding:0">{table(["Phiên bản", "Trạng thái", "Ngày đăng ký", "Thời gian theo dõi", "Tenant đang chạy", "Thay đổi lược đồ", "Hành động"], rel, "Danh mục phiên bản sản phẩm", num=(4,))}{foot("Hiển thị 5 phiên bản · hỗ trợ 2 bản minor gần nhất")}</div>
 <div>
  <div class="card"><h3 style="margin:0 0 8px;font-size:15px">2.5.0 · thành phần</h3>{table(["Đơn vị", "Image", "Chữ ký"], [["dh-platform", "dh-platform:2.5.0", "● Hợp lệ"], ["dh-console", "dh-console:2.5.0", "● Hợp lệ"], ["dh-gateway", "dh-gateway:2.5.0", "● Hợp lệ"]], "Thành phần phiên bản")}<div class="muted" style="margin-top:6px">Sau khi sang PREVIEW, thành phần bất biến, chỉ sửa ghi chú.</div></div>
  <div class="card" style="margin-top:10px"><h3 style="margin:0 0 8px;font-size:15px">Đăng ký kênh của tenant</h3>{table(["Tenant", "Kênh", "Môi trường"], [["<span class='mono'>T68</span>", "PREVIEW", "STAGING"], ["<span class='mono'>T04</span>", "PREVIEW", "PROD"], ["<span class='mono'>T01</span>", "STABLE", "PROD"]], "Đăng ký kênh của tenant")}
   <div class="muted" style="margin-top:6px">Đổi kênh khi tenant đang có kế hoạch nâng cấp bị chặn (ERR-20-061).</div></div>
 </div>
</div>
"""
P["18"] = ("Phiên bản sản phẩm và kênh", "Nền tảng › Phát hành", body, "", dict(active="ph"))

# ------------------------------------------------------------------ 19 Kế hoạch nâng cấp theo sóng (2.4.1, sóng 2 dừng)
def tu(code, s, note=""):
    m = {"DONE": ("ok", "✓ Xong"), "FAILED": ("err", "✕ Lỗi"), "IN_WINDOW": ("info", "◔ Trong cửa sổ"), "PENDING": ("mute", "○ Chờ"), "SKIPPED": ("mute", "– Bỏ qua (tạm ngừng)"), "UPGRADING": ("info", "▶ Đang nâng cấp")}[s]
    return f"<span class='tag t-{m[0]}'>{m[1]}</span>"


tr = [["<span class='mono'>T01</span>", "Thứ Bảy 22:00", tu("", "DONE"), "02/11 22:41", "2.4.0 → 2.4.1", "—"], ["<span class='mono'>T02</span>", "Thứ Bảy 22:00", tu("", "DONE"), "02/11 23:05", "2.4.0 → 2.4.1", "—"],
      ["<span class='mono'>T03</span>", "Chủ nhật 01:00", tu("", "FAILED"), "03/11 01:50", "2.4.0 (giữ)", "ERR-20-112 · 3 ca lỗi"], ["<span class='mono'>T15</span>", "Thứ Bảy 22:00", tu("", "IN_WINDOW"), "—", "2.4.0 → 2.4.1", "—"],
      ["<span class='mono'>T09</span>", "—", tu("", "SKIPPED"), "—", "2.4.0", "Tenant đang tạm ngừng"]]
ln = echart_line([("Tỷ lệ 5xx sóng 2", [0.2, 0.3, 0.4, 0.9, 1.6, 2.6, 2.6], "#c0392b", "")], ["22:00", "22:30", "23:00", "23:30", "00:00", "00:30", "01:00"], w=480, h=170, ymin=0, ymax=5, marks=[(2, "Ngưỡng 2 %", "#c98a00")], yfmt="{:.0f}")
body = f"""
<div class="head"><h1>Kế hoạch nâng cấp <span class="mono">UP-2026-07</span></h1><span class="tag t-warn">⏸ Tạm dừng</span><span class="muted">Phiên bản <span class="mono">2.4.1</span> · 34 tenant · 3 sóng</span><div class="sp"></div>{btn("Tiếp tục sóng 2", "pri")}{btn("Quay lui tenant…", "danger")}{btn("Hủy kế hoạch", "dis")}</div>
{banner("e", "ERR-20-057 · Sóng 2 đã dừng do vượt ngưỡng lỗi. Xác nhận đã xử lý trước khi tiếp tục.", "Xác nhận đã xử lý")}
<div class="cols2">
 <div>
  <div class="wave"><b>Sóng 1 · Thí điểm</b> {tag("ok", "✓ Hoàn tất")} <span class="muted">T04 · theo dõi 48 giờ đạt</span></div>
  <div class="wave pause"><b>Sóng 2 · Tenant nhỏ</b> {tag("warn", "⏸ Dừng do ngưỡng lỗi")} <span class="muted">5 tenant · 2 xong · 1 lỗi · 1 chờ · 1 bỏ qua</span>
   {table(["Tenant", "Cửa sổ bảo trì", "Trạng thái", "Hoàn tất", "Phiên bản", "Chi tiết"], tr, "Nâng cấp theo tenant của sóng 2")}</div>
  <div class="wave"><b>Sóng 3 · Phần còn lại</b> {tag("mute", "○ Lên lịch")} <span class="muted">27 tenant · bắt đầu sau khi sóng 2 hết theo dõi</span></div>
 </div>
 <div>
  <div class="card"><h3 style="margin:0 0 4px;font-size:15px">Tỷ lệ lỗi 5xx của sóng 2</h3>{ln}{legend([("Tỷ lệ 5xx", "#c0392b"), ("Ngưỡng 2 %", "#c98a00")])}</div>
  <div class="card" style="margin-top:10px"><h3 style="margin:0 0 6px;font-size:15px">T03 · không quay lui được?</h3><div class="muted">Phiên bản 2.4.1 không có thay đổi lược đồ CONTRACT nên quay lui được. Nếu có, hiện: "Không quay lui được phiên bản 2.4.1 vì có thay đổi lược đồ không tương thích ở PH-07." (ERR-20-058).</div></div>
  <div class="card" style="margin-top:10px"><h3 style="margin:0 0 6px;font-size:15px">Vai trò</h3><div class="muted">PO chỉ xem và bấm "Dừng sóng". Tiếp tục, quay lui, hủy cần quyền phát hành của PA.</div></div>
 </div>
</div>
"""
P["19"] = ("Kế hoạch nâng cấp theo sóng", "Nền tảng › Phát hành › 2.4.1 › Kế hoạch", body, "", dict(active="ph"))

# ------------------------------------------------------------------ 20 Bảng điều khiển đa tenant
bars = hbars([("● Hoạt động", 27, "#0b7a52"), ("◔ Đang khởi tạo", 1, "#0b5cd5"), ("⏸ Tạm ngừng", 1, "#c0392b"), ("⇄ Đang sáp nhập", 2, "#c98a00"), ("✕ Khởi tạo lỗi", 1, "#a11a1a"), ("✕ Đã chấm dứt", 2, "#8a919c")], maxv=30, w="140px 1fr 36px")
pt = echart_line([("p95 thời gian khởi tạo", [52, 48, 55, 44, 41, 47, 43, 45, 42, 41], "#0b5cd5", "")], ["T2", "T3", "T4", "T5", "T6", "T7", "T8", "T9", "T10", "T11"], w=460, h=170, ymin=30, ymax=70, marks=[(60, "Ngưỡng 60 phút", "#c0392b")], yfmt="{:.0f}")
todo = [["<span class='tag t-err'>✕ Lỗi khởi tạo</span>", "<span class='mono'>T07</span> · bước S08", "ERR-20-107", "Mở sổ bước"], ["<span class='tag t-warn'>⏳ Đang khởi tạo</span>", "<span class='mono'>T68</span> · bước S06 quá hạn", "ERR-20-106", "Mở sổ bước"],
        ["<span class='tag t-warn'>▲ Hạn mức 100 %</span>", "<span class='mono'>T01</span> · kho đối tượng", "—", "Mở hạn mức"], ["<span class='tag t-err'>✕ Lệch an ninh</span>", "<span class='mono'>T01</span> · realm.passwordPolicy", "ERR-20-025", "Mở lệch"],
        ["<span class='tag t-warn'>⏸ Sóng dừng</span>", "<span class='mono'>UP-2026-07</span> · sóng 2", "ERR-20-057", "Mở kế hoạch"]]
body = f"""
{head("Bảng điều khiển nền tảng", '<span class="seg"><span class="on">PROD</span><span>STAGING</span></span>', btn("Chạy kiểm thử rò rỉ…"))}
{kpis([kpi("Tenant tỉnh", "34", "Sức chứa 40 · 85 %"), kpi("Thời gian khởi tạo p95", "41 phút", "Ngưỡng 60 phút"), kpi("KPI-12 trung vị", "3,5 ngày", "Mục tiêu ≤ 5 ngày"), kpi("Cảnh báo hạn mức", "8", "1 chạm 100 %"), kpi("Lệch cấu hình", "2", "1 an ninh"), kpi("Nâng cấp đang chạy", "1", "UP-2026-07 · dừng")], 6)}
<div class="cols2">
 <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Việc cần xử lý</h3>{table(["Loại", "Đối tượng", "Mã", "Hành động"], todo, "Danh sách cần xử lý")}<div class="muted" style="margin-top:6px">Mỗi dòng dẫn tới màn chi tiết. Trạng thái luôn có chữ và biểu tượng.</div></div>
 <div>
  <div class="card"><h3 style="margin:0 0 6px;font-size:15px">Tenant theo trạng thái</h3><div class="hbars">{bars}</div></div>
  <div class="card" style="margin-top:10px"><h3 style="margin:0 0 6px;font-size:15px">Kiểm thử rò rỉ chéo tenant gần nhất</h3>
   <div class="row"><span class="tag t-ok">● Đạt</span><span class="muted">01:00 hôm nay · <span class="mono">T90</span> gọi dữ liệu <span class="mono">T91</span></span></div>
   <div class="muted" style="margin-top:4px">214 API, 0 phản hồi lộ dữ liệu đánh dấu. Chỉ chạy trên tenant kiểm thử T90…T99 (ERR-20-065).</div></div>
 </div>
</div>
<div class="card" style="margin-top:12px"><h3 style="margin:0 0 4px;font-size:15px">Thời gian khởi tạo p95 theo tháng (phút)</h3>{pt}{legend([("p95", "#0b5cd5"), ("Ngưỡng 60 phút", "#c0392b")])}</div>
"""
P["20"] = ("Bảng điều khiển đa tenant", "Nền tảng › Tổng quan", body, "", dict(active="tq"))

# ------------------------------------------------------------------ 21 Mẫu khởi tạo
tpl = [["<b class='mono'>tinh-chuan</b>", "Tỉnh chuẩn Đợt 1", "v3", "<span class='tag t-ok'>● Đã phát hành</span>"], ["<b class='mono'>tinh-chuan</b>", "", "v4", "<span class='tag t-info'>✎ Bản nháp</span>"],
       ["<b class='mono'>tinh-lon</b>", "Tỉnh quy mô lớn", "v1", "<span class='tag t-ok'>● Đã phát hành</span>"], ["<b class='mono'>test-minimal</b>", "Tenant kiểm thử", "v2", "<span class='tag t-ok'>● Đã phát hành</span>"],
       ["<b class='mono'>tinh-chuan</b>", "", "v1", "<span class='tag t-mute'>– Đã ngừng</span>"]]
quotas = [["API_RPS", "500", "300", "1.000"], ["ACTIVE_FLOWS", "1.000", "600", "2.000"], ["KAFKA_PRODUCE_MBPS", "10", "5", "20"], ["OBJECT_STORAGE_GB", "500", "300", "1.000"], ["DATABASE_GB", "200", "100", "400"]]
mods_chip = "".join(f'<span class="chip">{m}{" 🔒" if i < 12 else ""}</span>' for i, m in enumerate(["PH-01", "PH-02", "PH-03", "PH-04", "PH-05", "PH-07", "PH-10", "PH-12", "PH-13", "PH-14", "PH-18", "PH-20", "PH-06", "PH-16", "PH-19"]))
body = f"""
{head("Mẫu khởi tạo", btn("＋ Tạo mẫu", "pri"))}
<div class="grid2" style="grid-template-columns:420px minmax(0,1fr)">
 <div class="card" style="padding:0">{table(["Mã mẫu", "Tên", "Phiên bản", "Trạng thái"], tpl, "Mẫu khởi tạo và phiên bản", cls=[None, "list-sel", None, None, None])}<div class="muted" style="padding:8px 12px">12 tenant đã dùng tinh-chuan v3.</div></div>
 <div>
  <div class="head" style="margin-bottom:8px"><h1 style="font-size:18px"><span class="mono">tinh-chuan</span> · v4</h1><span class="tag t-info">✎ Bản nháp</span><div class="sp"></div>{btn("So sánh với v3")}{btn("Lưu nháp")}{btn("Phát hành v4", "pri")}</div>
  <div class="alert w"><span>Mở từ v3 đã phát hành. Phiên bản đã phát hành không sửa được: nếu thử sẽ hiện "Phiên bản 3 của mẫu tinh-chuan đã phát hành, không sửa được. Tạo phiên bản mới." (ERR-20-063)</span></div>
  <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Phân hệ bật sẵn</h3><div class="ctr">{mods_chip}</div><div class="muted" style="margin-top:6px">🔒 là phân hệ lõi, không bỏ được. PH-17 mặc định tắt (Q20-17).</div></div>
  <div class="card" style="margin-top:10px"><h3 style="margin:0 0 8px;font-size:15px">Hạn mức mặc định theo hồ sơ quy mô</h3>{table(["Tài nguyên", "QM-VUA", "QM-NHO", "Trần nền tảng"], quotas, "Hạn mức mặc định theo hồ sơ quy mô", num=(1, 2, 3))}</div>
  <div class="row" style="margin-top:10px"><div class="card" style="flex:1"><div class="muted">Gói danh mục nền</div><b class="mono">2026.11</b></div><div class="card" style="flex:1"><div class="muted">Bộ chỉ tiêu</div><b class="mono">2026.1</b></div><div class="card" style="flex:1"><div class="muted">Kích hoạt</div><b>Tự động</b></div><div class="card" style="flex:1"><div class="muted">Kênh phát hành</div><b>STABLE</b></div></div>
 </div>
</div>
"""
P["21"] = ("Mẫu khởi tạo", "Nền tảng › Mẫu khởi tạo", body, "", dict(active="mk"))

# ------------------------------------------------------------------ 22 Truy cập liên tenant (chính sách và nhật ký)
log = [["<b>Nguyễn Văn An</b><div class='muted'>PLATFORM · PA</div>", "Hỗ trợ sự cố", "<span class='mono'>SR-2026-1190</span>", "Tỉnh: Lê Văn Cường", "27/11 08:35", "27/11 09:05", "14", "<span class='tag t-ok'>Chỉ đọc</span>"],
       ["<b>Trần Thị Bình</b><div class='muted'>PLATFORM · PA</div>", "Kiểm tra cấu hình", "<span class='mono'>SR-2026-1102</span>", "Tỉnh: Lê Văn Cường", "12/11 09:50", "12/11 10:20", "31", "<span class='tag t-ok'>Chỉ đọc</span>"],
       ["<b>Nguyễn Văn An</b><div class='muted'>PLATFORM · PA</div>", "Theo yêu cầu của tỉnh", "<span class='mono'>SR-2026-0988</span>", "Tỉnh: Lê Văn Cường", "20/10 09:00", "20/10 10:40", "58", "<span class='tag t-warn'>▲ Có 3 thao tác ghi</span>"]]
body = f"""
{head("Truy cập liên tenant vào tỉnh", '<span class="tag t-mute">Chỉ đọc với SO, AU</span>', btn("Hủy thay đổi"), btn("Lưu chính sách", "pri"))}
<div class="cols2">
 <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Chính sách tiếp nhận</h3>
  <div class="row" style="justify-content:space-between;margin-bottom:8px"><span><b>Cho phép đọc dữ liệu của tỉnh</b><div class="muted">Quản trị nền tảng xem ở chế độ chỉ đọc</div></span>{sw(True)}</div>
  <div class="row" style="justify-content:space-between;margin-bottom:8px"><span><b>Cho phép ghi</b><div class="muted">Mỗi thao tác ghi hỏi lại lý do và mã phiếu</div></span>{sw(False)}</div>
  <div class="row" style="justify-content:space-between;margin-bottom:8px"><span><b>Cần tỉnh chấp thuận trước</b><div class="muted">Quản trị tỉnh duyệt ngoài người duyệt nền tảng</div></span>{sw(True)}</div>
  <div class="field"><label>Thời hạn tối đa mỗi phiên (giờ) *</label><span class="input" style="width:140px;justify-content:space-between;color:#1a1d23"><span>−</span><b>4</b><span>＋</span></span><div class="muted"><b>4 giờ</b> · tối đa 4 (trần nền tảng, ERR-20-027: "Thời hạn truy cập liên tenant tối đa là 4 giờ.")</div></div>
  <div class="field"><label>Người nhận thông báo</label><span class="chip">Lê Văn Cường · TENANT_ADMIN</span><span class="chip">Phạm Thị Dung · SECURITY</span><span class="chip">＋ Thêm</span></div>
  <div class="field"><label>Loại lý do tỉnh không chấp nhận</label><span class="chip">Khác ✕</span></div></div>
 <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Phiên bản chính sách</h3><dl class="kv"><dt>Hiện hành</dt><dd><b>v3</b> · 18/10/2026</dd><dt>Người sửa</dt><dd>Lê Văn Cường</dd><dt>Áp dụng</dt><dd>Từ lần cấp quyền kế tiếp ở PH-12</dd></dl>
  <div class="alert w" style="margin-top:10px"><span>Phiên đang mở không bị đổi giữa chừng. Chính sách mới có hiệu lực cho yêu cầu truy cập sau khi lưu.</span></div></div>
</div>
<div class="card" style="margin-top:12px;padding:0"><div class="toolbar" style="margin:0"><b>Nhật ký truy cập liên tenant</b><span class="input">01/10 – 27/11/2026 ▾</span><span class="input">Người ▾</span><span class="input">Loại lý do ▾</span><span class="input">Mã phiếu</span><span class="sp"></span>{btn("Xuất CSV")}</div>
{table(["Người", "Lý do", "Phiếu", "Người duyệt", "Bắt đầu", "Kết thúc", "Số thao tác", "Mức"], log, "Nhật ký truy cập liên tenant vào tỉnh", num=(6,))}{foot("Hiển thị 1–3 trên 3 phiên · khoảng tối đa 366 ngày")}</div>
"""
P["22"] = ("Truy cập liên tenant vào tỉnh", "Quản trị › Cài đặt tỉnh › Liên tenant", body, "", dict(mode="T", active="cd"))
