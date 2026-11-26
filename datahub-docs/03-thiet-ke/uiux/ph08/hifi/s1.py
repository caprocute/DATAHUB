from kit import *

CR = "Dữ liệu dùng chung › Chất lượng dữ liệu"
P = {}

# ------------------------------------------------------------------ 01 Tổng quan
DOMS = [  # (tên, điểm, kết luận, Δ, radar, ngày đo, cờ, chủ quản)
    ("Đất đai", 64.1, "FAIL", -2.3, [72, 58, 61, 49, 70, 66], "01/11", "INC", "Sở Tài nguyên và Môi trường"),
    ("Y tế", 68.3, "FAIL", +0.6, [74, 63, 70, 55, 78, 66], "01/11", "", "Sở Y tế"),
    ("Hộ tịch", 77.9, "WARN", +3.4, [82, 74, 79, 70, 85, 76], "01/11", "", "Sở Tư pháp"),
    ("Doanh nghiệp", 84.5, "PASS", +1.9, [90, 82, 84, 78, 88, 85], "01/11", "", "Sở Kế hoạch và Đầu tư"),
    ("Giáo dục", 83.0, "PASS", +0.4, [88, 81, 82, 76, 86, 84], "01/11", "", "Sở Giáo dục và Đào tạo"),
    ("Dân cư", 91.2, "PASS", +2.1, [95, 90, 90, 86, 94, 92], "01/11", "", "Công an tỉnh"),
    ("Danh mục dùng chung", 96.4, "PASS", +0.2, [98, 95, 96, 92, 99, 97], "01/11", "", "Sở Thông tin và Truyền thông"),
]
DCOL = ["#c0392b", "#c98a00", "#7146c7", "#0b5cd5", "#0e8a9b", "#0b7a52", "#8a919c"]


def dcard(d):
    k = {"PASS": "pass", "WARN": "warn", "FAIL": "fail"}[d[2]]
    inc = '<div style="margin-top:4px"><span class="tag t-warn">⚠ Thiếu chiều Hợp lệ</span></div>' if d[6] else ""
    return (f'<div class="dcard {k}"><div style="display:flex;justify-content:space-between;align-items:flex-start"><div><h4>{d[0]}</h4><div class="muted">{d[7]}</div></div>{radar(d[4], 70, labels=False)}</div>'
            f'<div style="display:flex;gap:8px;align-items:baseline"><span class="sc">{vn(d[1])}</span>{verdict(d[2])}</div>'
            f'<div class="muted" style="margin-top:2px">{trend(d[3])} so T10 · đo {d[5]}</div>{inc}</div>')


m_tr = [vn_ for vn_ in range(13)]
SER = [
    ("Đất đai", [60, 61, 62, 61, 63, 62, 64, 65, 66, 66.4, 66.1, 66.4, 64.1], DCOL[0], ""),
    ("Y tế", [62, 63, 64, 64, 65, 66, 66.5, 67, 67.4, 67.6, 67.7, 67.7, 68.3], DCOL[1], ""),
    ("Hộ tịch", [66, 67, 68, 70, 71, 72, 73, 74, 75, 75.6, 76.2, 74.5, 77.9], DCOL[2], ""),
    ("Doanh nghiệp", [78, 79, 80, 81, 81, 82, 82.5, 83, 83.4, 83.8, 84.1, 82.6, 84.5], DCOL[3], ""),
    ("Dân cư", [84, 85, 86, 87, 88, 88.5, 89, 89.6, 90, 90.4, 90.7, 89.1, 91.2], DCOL[5], ""),
    ("Toàn tỉnh", [70, 71, 72, 73, 74, 74.6, 75.4, 76.2, 77, 77.4, 77.8, 76.8, 78.6], "#1a1d23", "5 3"),
]
chart01 = echart_line(SER, MONTHS, w=760, h=250, ymin=55, ymax=100, marks=[(80, "Đạt 80", "#0b7a52"), (70, "Cảnh báo 70", "#c98a00")])
att = table(["Đối tượng", "Điểm", "Kết luận", "Lý do chú ý"],
            [["<b>ast-thua-dat</b><div class='muted'>Thửa đất (nguồn)</div>", sc(61.7), verdict("FAIL"), "Lần đo 25/11 thất bại ERR-08-105; thiếu chiều Hợp lệ"],
             ["<b>ast-kham-chua-benh</b><div class='muted'>Khám chữa bệnh (nguồn)</div>", sc(66.0), verdict("FAIL"), "Chiều Kịp thời 52,4; 612 lỗi Nghiêm trọng"],
             ["<b>ast-ho-tich-khai-sinh</b><div class='muted'>Khai sinh (nguồn)</div>", sc(77.9), verdict("WARN"), "Chiều Duy nhất giảm 4,8 điểm (EVT-08-04)"],
             ["<b>mdm-citizen</b><div class='muted'>Bản ghi vàng công dân</div>", sc(91.2), verdict("PASS"), "Quy tắc CD-VAL-004 có 1.284 lỗi Nghiêm trọng"]],
            "Đối tượng cần chú ý", num=(1,))
body = f"""
{banner("e", "Lần đo SCN-20261125-0412 của ast-thua-dat thất bại: Không đọc được nguồn của đối tượng ast-thua-dat: hết thời gian kết nối. Thử lại sau.", "Xem lần đo")}
{alert("w", "<b>Cảnh báo mức Cao đang bật:</b> điểm miền Y tế dưới ngưỡng cảnh báo 70 (68,3). Quy tắc cảnh báo CB-DIEM-THAP.", "Xem 2 cảnh báo")}
{head("Tổng quan chất lượng dữ liệu", inp("Kỳ: Tháng 11/2026 ▾"), inp("Miền: Tất cả ▾"), inp("Tổ chức: Tất cả ▾"), '<span class="seg"><span class="on">Của tỉnh</span><span>So sánh ẩn danh</span></span>', '<span class="muted">Số liệu cập nhật 14:02</span>')}
<div class="kpis" style="grid-template-columns:1.5fr 1fr 1fr 1fr">
  <div class="kpi" style="display:flex;gap:14px;align-items:center;flex:none;min-width:330px"><div><span>Điểm chất lượng toàn tỉnh</span><div class="scorebig" style="color:#7a5200">78,6<small> / 100</small></div></div><div style="font-size:13px">{verdict("WARN")}<div class="up" style="margin-top:6px">▲ +1,8 so tháng trước</div><div class="muted">Đạt từ 80 · cảnh báo từ 70</div></div></div>
  {kpi("Đối tượng đã đo trong tháng", "41 / 46", "89,1% · mục tiêu 100% (BR-08-001) · 5 chưa đo", "")}
  {kpi("Lỗi Nghiêm trọng đang mở", "3.917", "▲ 212 so tháng trước · 1.284 ở mdm-citizen")}
  {kpi("Phiếu khắc phục quá hạn", "7", "▲ 2 · 3 đã leo thang cấp 1")}
</div>
<div class="cols2" style="margin-bottom:14px">
  <div><div style="display:flex;align-items:center;margin-bottom:6px"><h3 style="margin:0;font-size:15px">Điểm theo miền chất lượng</h3><span class="sp" style="flex:1"></span><span class="muted">Miền không đạt xếp trước · bấm thẻ để mở danh sách đối tượng</span></div>
  <div class="dgrid" style="grid-template-columns:repeat(3,minmax(0,1fr))">{"".join(dcard(d) for d in DOMS)}<div class="dcard" style="border-style:dashed;border-left-style:dashed;background:#fafbfc"><h4>Tài chính</h4><div class="muted">Chưa có đối tượng đo</div><div style="margin-top:14px" class="muted">Chưa có số liệu. Đăng ký đối tượng đo và chạy lần đo đầu tiên.</div></div></div></div>
  {card("Sáu chiều toàn tỉnh", f'<div style="display:flex;justify-content:center">{radar([85.2, 72.4, 80.1, 68.0, 90.3, 79.4], 300, prev=[84.0, 71.0, 79.0, 66.2, 89.5, 78.1])}</div><div class="legend" style="justify-content:center"><span><i style="background:#0b5cd5"></i>Tháng 11/2026</span><span><i style="background:#8a919c"></i>Tháng 10/2026 (nét đứt)</span></div><div class="muted" style="text-align:center;margin-top:4px">Thấp nhất: Kịp thời 68,0 · Chính xác 72,4</div><div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:6px;margin-top:10px;font-size:12px">' + "".join(f'<div>{dim(c)}<b class="num" style="margin-left:6px">{v}</b></div>' for c, v in zip(["COMPLETENESS","ACCURACY","CONSISTENCY","TIMELINESS","UNIQUENESS","VALIDITY"], ["85,2","72,4","80,1","68,0","90,3","79,4"])) + '</div>')}
</div>
<div class="cols2">
  {card("Xu hướng 13 tháng theo miền", chart01 + legend([(s[0], s[2]) for s in SER]) + '<div class="muted" style="margin-top:4px">Đường nét đứt: toàn tỉnh. Có nút "Xem dạng bảng" cho trình đọc màn hình.</div>')}
  {card("Đối tượng cần chú ý", att)}
</div>"""
P["01"] = ("Tổng quan chất lượng dữ liệu", CR + " › Tổng quan", body)

# ------------------------------------------------------------------ 01b so sánh ẩn danh
cmp_series = [("T68 (tỉnh của anh/chị)", [70, 71, 72, 73, 74, 74.6, 75.4, 76.2, 77, 77.4, 77.8, 76.8, 78.6], "#0b5cd5", ""),
              ("Trung vị nhóm (8 tỉnh)", [72, 72.6, 73.4, 74.2, 75, 75.7, 76.3, 77, 77.6, 78.1, 78.4, 78.9, 79.6], "#1a1d23", "5 3"),
              ("Tứ phân vị trên", [78, 78.5, 79.2, 80, 80.6, 81.1, 81.6, 82.2, 82.8, 83.1, 83.5, 83.9, 84.6], "#8a919c", "2 3")]
dimcmp = table(["Chiều", "T68", "Trung vị nhóm", "Chênh lệch", "Vị trí"],
               [[dim("COMPLETENESS"), sc(85.2), "86,4", '<span class="dn">▼ −1,2</span>', "Thứ 5 / 8"], [dim("ACCURACY"), sc(72.4), "74,0", '<span class="dn">▼ −1,6</span>', "Thứ 6 / 8"],
                [dim("CONSISTENCY"), sc(80.1), "79,2", '<span class="up">▲ +0,9</span>', "Thứ 3 / 8"], [dim("TIMELINESS"), sc(68.0), "72,5", '<span class="dn">▼ −4,5</span>', "Thứ 7 / 8"],
                [dim("UNIQUENESS"), sc(90.3), "88,1", '<span class="up">▲ +2,2</span>', "Thứ 2 / 8"], [dim("VALIDITY"), sc(79.4), "81,0", '<span class="dn">▼ −1,6</span>', "Thứ 6 / 8"]],
               "So sánh sáu chiều với nhóm", num=(1, 2, 3))
body = f"""
{alert("i", "<b>Chế độ so sánh ẩn danh.</b> Chỉ hiện số tổng hợp của nhóm từ 5 tỉnh tham gia trở lên; không nêu tên tỉnh khác (BR-08-030). Tỉnh anh/chị đã bật tham gia (<span class='mono'>08.benchmark.opt-in</span>).")}
{head("Tổng quan chất lượng dữ liệu", inp("Kỳ: Tháng 11/2026 ▾"), inp("Miền: Tất cả ▾"), '<span class="seg"><span>Của tỉnh</span><span class="on">So sánh ẩn danh</span></span>', '<span class="muted">Nhóm: 8 tỉnh quy mô vừa</span>')}
<div class="kpis" style="--n:4">
  {kpi("Điểm T68", "78,6", "Trung vị nhóm 79,6 · chênh −1,0")}
  {kpi("Vị trí trong nhóm", "Thứ 5 / 8", "Tứ phân vị thứ hai từ dưới lên")}
  {kpi("Chiều tụt xa nhất", "Kịp thời −4,5", "So với trung vị nhóm")}
  {kpi("Số tỉnh tham gia", "8", "Tối thiểu 5 để hiển thị (ERR-08-044)")}
</div>
<div class="cols2">
  {card("Điểm toàn tỉnh so với nhóm, 13 tháng", echart_line(cmp_series, MONTHS, w=760, h=260, ymin=65, ymax=90) + legend([(s[0], s[2]) for s in cmp_series]))}
  {card("Sáu chiều so với trung vị nhóm", dimcmp)}
</div>
<div class="card" style="margin-top:14px"><b>Khi nhóm nhỏ hơn 5 tỉnh:</b> <span class="muted">vùng này thay bằng thông báo "Chưa đủ 5 tỉnh tham gia để so sánh ẩn danh." (ERR-08-044) và không vẽ biểu đồ.</span></div>"""
P["01b"] = ("Tổng quan, chế độ so sánh ẩn danh", CR + " › Tổng quan › So sánh ẩn danh", body)

# ------------------------------------------------------------------ 02 Danh sách đối tượng đo
ASSETS = [
    ("mdm-citizen", "Bản ghi vàng công dân", "MDM", "Dân cư", "Công an tỉnh", 91.2, "PASS", +2.1, "01/11 02:00", "9/9", "ACTIVE"),
    ("mdm-organization", "Bản ghi vàng tổ chức", "MDM", "Doanh nghiệp", "Sở Kế hoạch và Đầu tư", 84.5, "PASS", +1.9, "01/11 02:41", "7/8", "ACTIVE"),
    ("rdm-dvhc", "Danh mục đơn vị hành chính", "RDM", "Danh mục dùng chung", "Sở Nội vụ", 98.0, "PASS", +0.1, "01/11 03:05", "4/4", "ACTIVE"),
    ("ast-ho-tich-khai-sinh", "Đăng ký khai sinh", "SRC", "Hộ tịch", "Sở Tư pháp", 77.9, "WARN", +3.4, "01/11 03:12", "6/7", "ACTIVE"),
    ("ast-ho-tich-ket-hon", "Đăng ký kết hôn", "SRC", "Hộ tịch", "Sở Tư pháp", 80.6, "PASS", +0.8, "01/11 03:40", "5/5", "ACTIVE"),
    ("ast-kham-chua-benh", "Lượt khám chữa bệnh", "SRC", "Y tế", "Sở Y tế", 66.0, "FAIL", +0.3, "01/11 04:02", "5/6", "ACTIVE"),
    ("ast-thua-dat", "Thửa đất", "SRC", "Đất đai", "Sở Tài nguyên và Môi trường", 61.7, "FAIL", -2.3, "25/11 (lỗi)", "3/7", "ACTIVE"),
    ("ast-hoc-sinh", "Học sinh phổ thông", "SRC", "Giáo dục", "Sở Giáo dục và Đào tạo", 83.0, "PASS", +0.4, "01/11 04:30", "4/4", "ACTIVE"),
    ("flow-ho-tich-lien-thong", "Bản tin luồng hộ tịch liên thông", "FLOW", "Hộ tịch", "Sở Tư pháp", 94.1, "PASS", None, "Trực tuyến", "3/3", "ACTIVE"),
    ("ast-dang-ky-kinh-doanh", "Đăng ký kinh doanh", "SRC", "Doanh nghiệp", "Sở Kế hoạch và Đầu tư", None, "NONE", None, "Chưa đo", "5/6", "DRAFT"),
    ("ast-vac-xin", "Tiêm chủng", "SRC", "Y tế", "Sở Y tế", 72.5, "WARN", None, "01/09", "2/3", "SUSPENDED"),
]
TYP = {"MDM": ("info", "Bản ghi vàng"), "RDM": ("com", "Danh mục"), "SRC": ("mute", "Dataset nguồn"), "FLOW": ("warn", "Bản tin luồng")}
ST = {"ACTIVE": ("ok", "● Đang đo"), "DRAFT": ("mute", "○ Nháp"), "SUSPENDED": ("warn", "◐ Tạm ngừng"), "RETIRED": ("mute", "○ Đã ngừng")}
rows = []
for a in ASSETS:
    t = TYP[a[2]]
    rows.append([f"<b>{a[0]}</b><div class='muted'>{a[1]}</div>", tag(t[0], t[1]), a[3], a[4], scorebar(a[5]) if a[5] is not None else "—", verdict(a[6]), trend(a[7]) if a[7] is not None else "—", a[8], a[9], tag(*ST[a[10]])])
body = f"""
{head("Danh sách đối tượng đo", inp("Tìm mã, tên… ⌕", "min-width:240px"), btn("+ Đăng ký đối tượng đo", "pri"))}
{facets(["Tất cả 46", "Bản ghi vàng 3", "Danh mục 9", "Dataset nguồn 31", "Bản tin luồng 3"], 0)}
<div class="card">
  <div class="toolbar"><span class="input">Miền: Tất cả ▾</span><span class="input">Chủ quản: Tất cả ▾</span><span class="input">Trạng thái: Đang đo ▾</span><span class="input">Kết luận: Tất cả ▾</span><span class="input">Có cờ thiếu chiều</span><span class="sp" style="flex:1"></span><span class="muted">Sắp xếp: Điểm tăng dần</span></div>
  {table(["Đối tượng đo", "Loại", "Miền", "Tổ chức chủ quản", "Điểm", "Kết luận", "So kỳ trước", "Lần đo gần nhất", "CDE có quy tắc", "Trạng thái"], rows, "Đối tượng đo", num=())}
  {foot("Hiển thị 1–11 trong 46 đối tượng")}
</div>"""
P["02"] = ("Danh sách đối tượng đo", CR + " › Đối tượng đo", body)

# ------------------------------------------------------------------ 03 Wizard
fields = [
    ("so_dinh_danh", "VARCHAR(12)", "SENSITIVE", "HASH", True, "Đã xác nhận ở PH-09", ""),
    ("ho_ten", "VARCHAR(200)", "RESTRICTED", "PARTIAL", True, "Đã xác nhận ở PH-09", ""),
    ("ngay_sinh", "DATE", "RESTRICTED", "PARTIAL", True, "Đã xác nhận ở PH-09", ""),
    ("gioi_tinh", "VARCHAR(2)", "INTERNAL", "NONE", True, "Đã xác nhận ở PH-09", ""),
    ("ma_dvhc_xa", "VARCHAR(5)", "INTERNAL", "NONE", True, "Đã xác nhận ở PH-09", ""),
    ("so_dien_thoai_me", "VARCHAR(15)", "SENSITIVE", "HASH", True, "Chưa có phân loại", "warn"),
    ("noi_sinh", "VARCHAR(500)", "INTERNAL", "NONE", False, "Đã xác nhận ở PH-09", ""),
    ("ngay_cap_nhat", "TIMESTAMP", "INTERNAL", "NONE", False, "Đã xác nhận ở PH-09", ""),
]
frows = []
for f in fields:
    cl = {"SENSITIVE": "err", "RESTRICTED": "warn", "INTERNAL": "info", "PUBLIC": "ok"}[f[2]]
    lb = {"SENSITIVE": "Nhạy cảm", "RESTRICTED": "Hạn chế", "INTERNAL": "Nội bộ", "PUBLIC": "Công khai"}[f[2]]
    frows.append([chk(f[4]), f"<span class='mono'>{f[0]}</span>", f"<span class='mono muted'>{f[1]}</span>", tag(cl, lb) if f[5] != "Chưa có phân loại" else tag("warn", "Chưa phân loại → coi như Nhạy cảm"), f"<span class='mono'>{f[3]}</span>" + (" <span class='muted'>(không được nới)</span>" if f[3] == "HASH" else ""), f[5] if not f[6] else f"<span style='color:#7a5200'>{f[5]}</span>"])
body = f"""
{head("Đăng ký đối tượng đo", btn("Hủy"), btn("‹ Quay lại"), btn("Lưu nháp"), btn("Hoàn tất và kích hoạt", "pri"))}
<div class="steps"><div class="done">✓ 1 Loại đối tượng</div><div class="done">✓ 2 Nguồn dữ liệu</div><div class="done">✓ 3 Trường và khóa</div><div class="on">4 Phần tử dữ liệu trọng yếu (CDE)</div></div>
<div class="cols2">
  <div class="card">
    <div class="toolbar"><b>Chọn CDE, kiểm tra phân loại và cách che</b><span class="sp" style="flex:1"></span><span class="muted">6 CDE đã chọn · cần tối thiểu 1 (BR-08-031)</span><span class="btn">Đồng bộ phân loại từ PH-09</span></div>
    {alert("w", "Trường <span class='mono'>so_dien_thoai_me</span> chưa có phân loại xác nhận ở PH-09. Giá trị sẽ được che như dữ liệu Nhạy cảm.")}
    {table(["CDE", "Trường", "Kiểu", "Phân loại PH-09", "Cách che giá trị lỗi", "Ghi chú"], frows, "Trường và CDE của đối tượng đo")}
    <div class="muted" style="margin-top:8px">Cách che không được lỏng hơn phân loại (ERR-08-003). Giá trị gốc trường Nhạy cảm không bao giờ được lưu (BR-08-012).</div>
  </div>
  <div>
    {card("Tóm tắt đối tượng", '<dl class="dl" style="grid-template-columns:110px 1fr"><dt>Mã</dt><dd class="mono">ast-ho-tich-khai-sinh</dd><dt>Loại</dt><dd>Dataset nguồn</dd><dt>Kết nối</dt><dd class="mono">conn-httt-tuphap (chỉ đọc)</dd><dt>Bảng</dt><dd class="mono">hotich.khai_sinh</dd><dt>Khóa bản ghi</dt><dd class="mono">so_dang_ky</dd><dt>Miền</dt><dd>Hộ tịch</dd><dt>Chủ quản</dt><dd>Sở Tư pháp</dd><dt>Lịch đo</dt><dd>Ngày 1 hằng tháng 02:00</dd></dl>')}
    <div style="height:10px"></div>
    {card("Sau khi kích hoạt", '<div class="muted">• Tự tạo lịch đo mặc định<br>• Tự chạy hồ sơ dữ liệu lần đầu<br>• Gợi ý quy tắc cho CDE chưa có quy tắc<br>• Chưa có bộ quy tắc hiệu lực: đo sẽ báo ERR-08-027</div>')}
  </div>
</div>"""
P["03"] = ("Đăng ký đối tượng đo, bước 4", CR + " › Đối tượng đo › Đăng ký mới", body)

# ------------------------------------------------------------------ 04 Chi tiết đối tượng đo, thẻ điểm
dimrows = []
dd = [("COMPLETENESS", 0.20, 82.3, 18420, 3961), ("ACCURACY", 0.20, 71.0, 9800, 4002), ("CONSISTENCY", 0.15, 79.6, 6300, 1286), ("TIMELINESS", 0.10, 70.2, 4400, 1310), ("UNIQUENESS", 0.15, 74.4, 5200, 1331), ("VALIDITY", 0.20, 84.1, 22800, 3615)]
for c, w, s, p, f in dd:
    dimrows.append([dim(c), vn(w, 2), scorebar(s, 90), vn(p, 0), vn(f, 0), "0", "0"])
body = f"""
{head('<span class="mono" style="font-size:19px">ast-ho-tich-khai-sinh</span> ' + tag("mute", "Dataset nguồn") + " " + tag("ok", "● Đang đo"), btn("Chạy hồ sơ"), btn("Tạm ngừng"), btn("Đo ngay", "pri"))}
<div class="muted" style="margin:-8px 0 10px">Đăng ký khai sinh · Miền Hộ tịch · Chủ quản Sở Tư pháp · Bộ quy tắc <b>BQ-HO-TICH v6</b> · Trọng số mặc định tenant v2</div>
{tabs(["Thẻ điểm", "Trường và CDE", "Xu hướng", "Trực tuyến", "Lịch sử đo"], 0)}
<div class="cols2" style="grid-template-columns:minmax(0,1fr) minmax(0,1.5fr)">
  {card("Điểm lần đo 01/11/2026", f'<div style="display:flex;gap:16px;align-items:center">{ring(77.9, 124)}<div>{verdict("WARN")}<div style="margin-top:6px" class="up">▲ +3,4 so T10</div><div class="muted">Xu hướng: Cải thiện</div><div class="muted">Lần đo SCN-20261101-0107 · FULL · 2.481.300 bản ghi</div></div></div><div style="display:flex;justify-content:center;margin-top:8px">{radar([82.3, 71.0, 79.6, 70.2, 74.4, 84.1], 290, prev=[80.1, 68.0, 77.0, 66.5, 69.0, 82.0])}</div>')}
  {card("Điểm sáu chiều và quy tắc vi phạm nhiều nhất", table(["Chiều", "Trọng số", "Điểm", "Đạt", "Vi phạm", "Bỏ qua", "Ngoại lệ"], dimrows, "Điểm sáu chiều của đối tượng", num=(1, 3, 4, 5, 6)) + '<div class="muted" style="margin:6px 0 10px">Điểm chiều tính gộp (POOLED): tổng đạt chia tổng áp dụng, không tính bỏ qua, lỗi, ngoại lệ.</div>' + table(["Quy tắc", "Chiều", "Vi phạm"], [["<span class='mono'>HT-ACC-004</span> Ngày sinh ≤ ngày đăng ký", dim("ACCURACY"), "2.911"], ["<span class='mono'>HT-COM-002</span> Số CCCD người mẹ bắt buộc", dim("COMPLETENESS"), "2.104"], ["<span class='mono'>HT-VAL-001</span> Mã xã ∈ DM_DVHC", dim("VALIDITY"), "1.968"], ["<span class='mono'>HT-UNI-001</span> Số đăng ký duy nhất", dim("UNIQUENESS"), "1.331"], ["<span class='mono'>HT-TIM-001</span> Cập nhật trong 30 ngày", dim("TIMELINESS"), "1.310"]], "Năm quy tắc vi phạm nhiều nhất", num=(2,)))}
</div>
<div class="cols2" style="margin-top:14px;grid-template-columns:1fr 1fr">
  {card("Lỗi đang mở", '<div class="hbar" style="grid-template-columns:100px 1fr 60px"><span>Nghiêm trọng</span><span><i style="width:48%;background:#c0392b"></i></span><b class="num">1.212</b></div><div class="hbar" style="grid-template-columns:100px 1fr 60px"><span>Đáng kể</span><span><i style="width:70%;background:#c98a00"></i></span><b class="num">3.540</b></div><div class="hbar" style="grid-template-columns:100px 1fr 60px"><span>Nhẹ</span><span><i style="width:36%;background:#8a919c"></i></span><b class="num">2.870</b></div><div class="muted" style="margin-top:6px">Mới 412 · còn 6.730 · hết 1.044 so kỳ trước</div><div style="margin-top:6px"><span class="btn">Xem bản ghi lỗi →</span></div>')}
  {card("Phủ và xử lý", '<dl class="dl" style="grid-template-columns:140px 1fr 140px 1fr"><dt>CDE có quy tắc</dt><dd><b>6/7</b> · thiếu 1</dd><dt>Phiếu đang mở</dt><dd>2 (1 quá hạn)</dd><dt>Ngoại lệ ACTIVE</dt><dd>1 · hết hạn 15/02</dd><dt>Lịch đo kế tiếp</dt><dd>01/12 02:00</dd><dt>Trực tuyến</dt><dd>Chưa bật</dd><dt>Cờ điểm</dt><dd>Không có</dd></dl>')}
</div>"""
P["04"] = ("Chi tiết đối tượng đo, thẻ điểm", CR + " › Đối tượng đo › ast-ho-tich-khai-sinh", body)

# ------------------------------------------------------------------ 05 Hồ sơ dữ liệu
cols = [
    ("so_dang_ky", "VARCHAR(20)", "0,0%", "2.481.300", "100,0%", "KS-2026-0000012", "KS-2026-2481311", [4, 4, 4, 4, 4, 4, 4, 4], "—", "Duy nhất 100%", 1),
    ("ngay_sinh", "DATE", "0,1%", "7.310", "99,9%", "01/01/2019", "26/11/2026", [3, 3, 4, 4, 5, 6, 7, 9], "▲ nhiều ngày sau ngày đăng ký", "Khoảng ngày", 2),
    ("ma_dvhc_xa", "VARCHAR(5)", "0,0%", "611", "100,0%", "01001", "99999", [9, 8, 7, 6, 6, 5, 4, 3], "▲ 118 mã không có trong DM_DVHC", "Danh mục tham chiếu", 2),
    ("gioi_tinh", "VARCHAR(2)", "0,2%", "4", "99,8%", "F", "M", [8, 1, 1, 1, 1, 1, 1, 8], "—", "Mã 1-2 (3 giá trị lạ)", 1),
    ("so_cccd_me", "VARCHAR(12)", "8,4%", "2.019.884", "91,6%", "●●●●●●●●●●●●", "●●●●●●●●●●●●", [4, 4, 4, 4, 4, 4, 4, 4], "▲ Rỗng tăng 1,1 điểm", "12 chữ số", 3),
    ("ngay_cap_nhat", "TIMESTAMP", "0,0%", "2.390.411", "100,0%", "12/03/2019", "26/11/2026", [1, 1, 2, 2, 3, 5, 8, 9], "—", "Cập nhật gần đây", 1),
]
crow = []
for c in cols:
    crow.append([f"<span class='mono'><b>{c[0]}</b></span><div class='muted mono'>{c[1]}</div>", c[2], c[3], c[4], f"<span class='mono'>{c[5]}</span> → <span class='mono'>{c[6]}</span>", histo(c[7]), c[8] if c[8] != "—" else "<span class='muted'>Không đổi</span>", tag("info", f"{c[10]} gợi ý") if c[10] > 1 else "<span class='muted'>—</span>"])
body = f"""
{head("Hồ sơ dữ liệu · ast-ho-tich-khai-sinh", btn("Chạy hồ sơ mới", "pri"))}
{tabs(["Thẻ điểm", "Trường và CDE", "Hồ sơ dữ liệu", "Xu hướng", "Trực tuyến", "Lịch sử đo"], 2)}
<div class="cols2">
  <div>
    <div class="card" style="margin-bottom:12px"><div style="display:flex;gap:18px;align-items:center;flex-wrap:wrap"><span><span class="muted">Lần hồ sơ</span><br><b class="mono">HS-20261126-0031</b></span><span>{tag("ok", "● Thành công")}</span><span><span class="muted">Chế độ</span><br><b>SAMPLE 1.000.000 bản ghi</b></span><span><span class="muted">Bắt đầu</span><br><b>26/11/2026 02:14 (7 phút 40 giây)</b></span><span><span class="muted">So sánh với</span><br><b>HS-20261029-0027 ▾</b></span><span class="sp" style="flex:1"></span><span class="muted">Số khác biệt: xấp xỉ bằng HyperLogLog (sai số ±1%)</span></div></div>
    <div class="card">
      <div class="toolbar"><b>Thống kê theo cột (6 / 31 cột)</b><span class="sp" style="flex:1"></span><span class="input">Tìm cột ⌕</span><span class="input">Chỉ cột CDE</span></div>
      {table(["Cột", "Rỗng", "Giá trị khác nhau", "Đầy đủ", "Khoảng giá trị (min → max)", "Phân bố", "So lần trước", "Gợi ý quy tắc"], crow, "Thống kê cột của lần hồ sơ", num=(1, 2, 3))}
      <div class="muted" style="margin-top:8px">Cột so_cccd_me thuộc phân loại Nhạy cảm: giá trị nhỏ nhất, lớn nhất và giá trị phổ biến chỉ hiện dạng đã che; không lưu giá trị gốc.</div>
    </div>
  </div>
  <div class="card"><div class="toolbar"><b>Gợi ý quy tắc từ hồ sơ</b><span class="sp" style="flex:1"></span><span class="muted">5 gợi ý</span></div>
    <div class="node2"><div style="display:flex;gap:6px;align-items:center">{dim("VALIDITY")}<b class="mono">ma_dvhc_xa</b></div><div class="muted" style="margin:4px 0">Toán tử <span class="mono">IN_RDM</span> danh mục <span class="mono">DM_DVHC</span>; hồ sơ thấy 118 mã lạ (0,02%).</div><span class="btn pri" style="height:26px">Thêm vào bản nháp</span> <span class="btn" style="height:26px">Bỏ qua</span></div>
    <div class="node2"><div style="display:flex;gap:6px;align-items:center">{dim("COMPLETENESS")}<b class="mono">so_cccd_me</b></div><div class="muted" style="margin:4px 0">Toán tử <span class="mono">NOT_NULL</span>; tỷ lệ rỗng 8,4%, đang tăng.</div><span class="btn pri" style="height:26px">Thêm vào bản nháp</span> <span class="btn" style="height:26px">Bỏ qua</span></div>
    <div class="node2"><div style="display:flex;gap:6px;align-items:center">{dim("ACCURACY")}<b class="mono">ngay_sinh</b></div><div class="muted" style="margin:4px 0">Toán tử <span class="mono">RANGE</span> từ 01/01/2000 đến ngày đo; 7.310 ngày khác nhau.</div><span class="btn pri" style="height:26px">Thêm vào bản nháp</span> <span class="btn" style="height:26px">Bỏ qua</span></div>
    <div class="node2"><div style="display:flex;gap:6px;align-items:center">{dim("UNIQUENESS")}<b class="mono">so_dang_ky</b></div><div class="muted" style="margin:4px 0">Toán tử <span class="mono">UNIQUE_IN_ASSET</span>; 100% khác nhau.</div><span class="btn pri" style="height:26px">Thêm vào bản nháp</span> <span class="btn" style="height:26px">Bỏ qua</span></div>
    <div class="muted" style="margin-top:8px">Gợi ý chỉ là đề xuất, chưa thành quy tắc cho đến khi DS thêm vào bản nháp và gửi duyệt.</div>
  </div>
</div>"""
P["05"] = ("Hồ sơ dữ liệu", CR + " › Đối tượng đo › ast-ho-tich-khai-sinh › Hồ sơ dữ liệu", body)
