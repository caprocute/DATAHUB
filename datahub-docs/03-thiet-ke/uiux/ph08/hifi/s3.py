from kit import *

CR = "Dữ liệu dùng chung › Chất lượng dữ liệu"
P = {}

SS = {"SUCCEEDED": ("ok", "● Thành công"), "PARTIAL": ("warn", "◐ Một phần"), "FAILED": ("err", "✕ Lỗi"), "RUNNING": ("info", "◔ Đang chạy"), "QUEUED": ("mute", "○ Chờ chạy"), "CANCELLED": ("mute", "⊘ Đã hủy")}
TR = {"SCHEDULE": ("mute", "Theo lịch"), "MANUAL": ("info", "Theo yêu cầu"), "EVENT": ("com", "Theo sự kiện"), "ANNUAL": ("warn", "Báo cáo năm"), "VERIFY": ("ok", "Kiểm chứng")}

# ------------------------------------------------------------------ 11 Lịch đo và lần đo
SC = [
    ("SCN-20261125-0412", "ast-thua-dat", "MANUAL", "FULL", "FAILED", "25/11 21:40", "12 phút", None, "NONE", "ERR-08-105"),
    ("SCN-20261126-0431", "ast-kham-chua-benh", "VERIFY", "FULL", "RUNNING", "26/11 13:55", "đang chạy 7/12 tác vụ", None, "NONE", ""),
    ("SCN-20261126-0430", "mdm-citizen", "EVENT", "INCREMENTAL", "SUCCEEDED", "26/11 13:15", "3 phút", 91.4, "PASS", "Tăng dần"),
    ("SCN-20261101-0107", "ast-ho-tich-khai-sinh", "SCHEDULE", "FULL", "SUCCEEDED", "01/11 03:12", "38 phút", 77.9, "WARN", ""),
    ("SCN-20261101-0112", "ast-kham-chua-benh", "SCHEDULE", "FULL", "PARTIAL", "01/11 04:02", "1 giờ 20", 66.0, "FAIL", "Thiếu chiều Hợp lệ"),
    ("SCN-20261101-0098", "mdm-citizen", "SCHEDULE", "FULL", "SUCCEEDED", "01/11 02:00", "52 phút", 91.2, "PASS", ""),
    ("SCN-20261031-0390", "ast-hoc-sinh", "MANUAL", "SAMPLE", "SUCCEEDED", "31/10 16:20", "4 phút", 82.6, "PASS", "Mẫu 100.000"),
    ("SCN-20261030-0377", "ast-vac-xin", "SCHEDULE", "FULL", "CANCELLED", "30/10 02:00", "—", None, "NONE", "ERR-08-119"),
]
rows = []
for r in SC:
    s = SS[r[4]]
    prog = ""
    if r[4] == "RUNNING":
        prog = '<div class="prog" style="width:110px;margin-top:3px"><i style="width:58%"></i></div>'
    rows.append([f"<b class='mono'>{r[0]}</b>", f"<span class='mono'>{r[1]}</span>", tag(*TR[r[2]]), f"<span class='mono'>{r[3]}</span>", tag(*s) + prog, r[5], r[6], sc(r[7]) if r[7] else "—", verdict(r[8]), r[9] and (tag("warn", r[9]) if r[9].startswith("ERR") else r[9])])
body = f"""
{head("Lịch đo và lần đo", btn("Lịch đo"), btn("▷ Đo theo yêu cầu", "pri"))}
{tabs(["Lần đo 128", "Lịch đo 46"], 0)}
{facets(["Tất cả", "Theo lịch 82", "Theo yêu cầu 19", "Theo sự kiện 14", "Báo cáo năm 3", "Kiểm chứng 10"], 0)}
<div class="cols2" style="grid-template-columns:minmax(0,2.4fr) minmax(0,1fr)">
  <div class="card">
    <div class="toolbar"><span class="input">Đối tượng: Tất cả ▾</span><span class="input">Trạng thái: Tất cả ▾</span><span class="input">Từ 01/10/2026 – nay</span><span class="sp" style="flex:1"></span><span class="muted">Tự làm mới 5 giây khi có lần đo đang chạy</span></div>
    {table(["Lần đo", "Đối tượng", "Kích hoạt", "Chế độ", "Trạng thái", "Bắt đầu", "Thời lượng", "Điểm", "Kết luận", "Ghi chú"], rows, "Danh sách lần đo", num=(7,))}
    {foot("Hiển thị 1–8 trong 128 lần đo")}
  </div>
  <div>
    {card("Lịch đo sắp tới", table(["Đối tượng", "Giờ chạy"], [["<span class='mono'>mdm-citizen</span>", "01/12 02:00"], ["<span class='mono'>ast-ho-tich-khai-sinh</span>", "01/12 02:00"], ["<span class='mono'>ast-kham-chua-benh</span>", "01/12 22:00 *"], ["<span class='mono'>ast-thua-dat</span>", "01/12 22:00 *"]], "Lịch đo sắp tới") + '<div class="muted" style="margin-top:6px">Mặc định ngày 1 hằng tháng lúc 02:00. * Cửa sổ giờ của nguồn HTTT 22:00–05:00.</div>')}
    <div style="height:12px"></div>
    {card("Hạn mức", '<dl class="dl" style="grid-template-columns:150px 1fr"><dt>Đo theo yêu cầu</dt><dd><b>3 / 10</b> lần trong giờ</dd><dt>Đang chạy</dt><dd>1</dd><dt>Đang chờ</dt><dd>0</dd><dt>Đo tăng dần</dt><dd>Gom mỗi 15 phút</dd></dl>')}
  </div>
</div>"""
P["11"] = ("Lịch đo và danh sách lần đo", CR + " › Lần đo", body)

# ------------------------------------------------------------------ 12 Chi tiết lần đo
RR = [
    ("HT-ACC-004", "Ngày sinh không sau ngày đăng ký", "ACCURACY", "CRITICAL", "FAILED", "2.481.300", "2.478.389", "2.911", "0"),
    ("HT-COM-002", "Số CCCD người mẹ bắt buộc", "COMPLETENESS", "MAJOR", "FAILED", "2.019.100", "1.916.996", "2.104", "0"),
    ("HT-UNI-001", "Số đăng ký duy nhất", "UNIQUENESS", "CRITICAL", "FAILED", "2.481.300", "2.479.969", "1.331", "0"),
    ("HT-TIM-001", "Cập nhật trong 30 ngày", "TIMELINESS", "MINOR", "FAILED", "2.481.300", "2.349.841", "1.310", "0"),
    ("HT-VAL-001", "Mã xã thuộc danh mục DM_DVHC", "VALIDITY", "MAJOR", "SKIPPED", "—", "—", "—", "—"),
    ("HT-VAL-002", "Giới tính thuộc DM_GIOI_TINH", "VALIDITY", "MINOR", "SKIPPED", "—", "—", "—", "—"),
    ("HT-CON-002", "Số CCCD có trong bản ghi vàng công dân", "CONSISTENCY", "MINOR", "FAILED", "1.904.000", "1.845.000", "588", "0"),
    ("HT-COM-001", "Số đăng ký bắt buộc", "COMPLETENESS", "CRITICAL", "PASSED", "2.481.300", "2.481.300", "0", "0"),
    ("HT-ACC-005", "Họ tên khớp CSDL dân cư", "ACCURACY", "MAJOR", "ERROR", "—", "—", "—", "ERR-08-107"),
]
RS_ = {"PASSED": ("ok", "✓ Đạt"), "FAILED": ("err", "✕ Có vi phạm"), "SKIPPED": ("mute", "⊘ Bỏ qua"), "ERROR": ("warn", "⚠ Lỗi chạy")}
rr = []
cl = []
for r in RR:
    rr.append([f"<b class='mono'>{r[0]}</b><div class='muted'>{r[1]}</div>", dim(r[2]), sev(r[3]), tag(*RS_[r[4]]), r[5], r[6], f"<b>{r[7]}</b>" if r[7] != "—" else "—", ("<span class='btn' style='height:24px'>Xem lỗi</span>" if r[7] not in ("—", "0") else "<span class='muted'>—</span>") if r[8] != "ERR-08-107" else "<span class='tag t-warn'>ERR-08-107</span>"])
    cl.append("d-chg" if r[4] == "ERROR" else None)
dimcards = ""
dv = [("COMPLETENESS", 0.20, 82.3, "18.420", "3.961"), ("ACCURACY", 0.20, 71.0, "9.800", "4.002"), ("CONSISTENCY", 0.15, 79.6, "6.300", "1.286"), ("TIMELINESS", 0.10, 70.2, "4.400", "1.310"), ("UNIQUENESS", 0.15, 74.4, "5.200", "1.331")]
for c, w, s_, p, f in dv:
    dimcards += f'<div class="dimcard"><div>{dim(c)}</div><b>{vn(s_)}</b><span class="muted">trọng số {vn(w, 2)}<br>đạt {p}<br>vi phạm {f} · bỏ qua 0</span></div>'
dimcards += '<div class="dimcard skip"><div>' + dim("VALIDITY") + '</div><b>—</b><span>trọng số 0,20<br>Bỏ qua: PH-07 gián đoạn 02:10–02:40</span></div>'
tasks = "".join(f'<div class="task ok">T{i}<br><b>200.000</b> ✓</div>' for i in range(1, 12)) + '<div class="task ok">T12<br><b>81.300</b> ✓</div>'
body = f"""
{banner("w", "Không đối chiếu được danh mục DM_DVHC. Chiều Hợp lệ bị bỏ qua ở lần đo này. Điểm có cờ thiếu chiều và không dùng cho báo cáo năm.", "Đo lại chiều Hợp lệ")}
{head('<span class="mono" style="font-size:19px">SCN-20261101-0107</span> ' + tag(*SS["PARTIAL"]) + " " + tag("warn", "INCOMPLETE_DIMENSIONS"), btn("Chạy lại"), btn("Hủy", "dis"))}
<div class="card" style="margin-bottom:12px"><dl class="dl" style="grid-template-columns:100px 1fr 100px 1fr 100px 1fr 100px 1fr">
<dt>Đối tượng</dt><dd class="mono">ast-ho-tich-khai-sinh</dd><dt>Kích hoạt</dt><dd>Theo lịch · FULL</dd><dt>Bộ quy tắc</dt><dd>BQ-HO-TICH v6</dd><dt>Trọng số</dt><dd>Mặc định v2</dd>
<dt>Bắt đầu</dt><dd>01/11 02:34</dd><dt>Kết thúc</dt><dd>01/11 03:12 (38 phút)</dd><dt>Seed lấy mẫu</dt><dd class="mono">8812734690113</dd><dt>Bản ghi</dt><dd>2.481.300</dd></dl></div>
<div class="card" style="margin-bottom:12px"><div style="display:flex;align-items:center;margin-bottom:6px"><b>Tiến độ theo tác vụ</b><span class="sp" style="flex:1"></span><span class="muted">12/12 tác vụ xong · 200.000 bản ghi mỗi tác vụ</span></div><div class="tasks" style="--n:12">{tasks}</div></div>
<div class="cols2" style="grid-template-columns:minmax(0,2.3fr) minmax(0,1fr)">
  <div>
    <div class="card" style="margin-bottom:12px"><div style="display:flex;align-items:center;gap:20px"><div><span class="muted">Điểm lần đo</span><div class="scorebig" style="color:#7a5200">77,9 <small>/ 100</small></div></div>{verdict("WARN")}<span class="up">▲ +3,4 so lần trước</span><span class="sp" style="flex:1"></span><span class="muted">Điểm tính trên 5 chiều có kết quả; chiều Hợp lệ không vào tổng</span></div>
    <div class="dimcards">{dimcards}</div></div>
    <div class="card"><div class="toolbar"><b>Kết quả từng quy tắc (9 / 12)</b><span class="sp" style="flex:1"></span><span class="input">Trạng thái: Tất cả ▾</span><span class="input">Chiều: Tất cả ▾</span><span class="muted">Sắp theo số vi phạm</span></div>
    {table(["Quy tắc", "Chiều", "Mức", "Kết quả", "Áp dụng", "Đạt", "Vi phạm", ""], rr, "Kết quả quy tắc của lần đo", cl, num=(4, 5, 6))}
    <div class="muted" style="margin-top:6px">HT-ACC-005: Quy tắc HT-ACC-005 lỗi khi chạy: kết nối CSDL dân cư hết thời gian. (ERR-08-107)</div></div>
  </div>
  <div>
    {card("So với kỳ trước (SCN-20261001-0093)", '<dl class="dl" style="grid-template-columns:120px 1fr"><dt>Δ điểm</dt><dd class="up"><b>▲ +3,4</b></dd><dt>Xu hướng</dt><dd>Cải thiện</dd><dt>Lỗi mới</dt><dd><b>412</b></dd><dt>Lỗi còn</dt><dd><b>6.730</b></dd><dt>Lỗi hết</dt><dd><b>1.044</b></dd><dt>Ngoại lệ</dt><dd>1 đang hiệu lực</dd></dl><div class="warn" style="margin-top:8px">Cấu hình trọng số khác lần trước (v1 → v2): so sánh có cờ <span class="mono">WEIGHTS_CHANGED</span>.</div>')}
    <div style="height:12px"></div>
    {card("Phụ thuộc và cảnh báo", '<div class="muted" style="line-height:1.7">• 02:10–02:40 PH-07 không khả dụng, chiều Hợp lệ bỏ qua<br>• 1.340 bản ghi thiếu khóa, ghi là lỗi cấu trúc (ERR-08-109)<br>• HT-ACC-005 lỗi chạy (ERR-08-107)<br>• Quy tắc HT-COM-002 chỉ lưu 50.000 bản ghi lỗi đầu, số đếm vẫn đủ (ERR-08-110)</div>')}
    <div style="height:12px"></div>
    {card("Sự kiện đã phát", '<div class="mono muted" style="line-height:1.7">t68.dq.scan.completed.v1<br>t68.dq.finding.opened.v1</div>')}
  </div>
</div>"""
P["12"] = ("Chi tiết lần đo", CR + " › Lần đo › SCN-20261101-0107", body)

# ------------------------------------------------------------------ 12b đang chạy, có tác vụ lỗi
tk = ""
for i in range(1, 13):
    if i <= 5:
        tk += f'<div class="task ok">T{i}<br><b>200.000</b> ✓</div>'
    elif i == 6:
        tk += '<div class="task err">T6<br><b>lỗi</b> ✕ thử lại 2/3</div>'
    elif i in (7, 8):
        tk += f'<div class="task run">T{i}<br><b>{"64%" if i == 7 else "21%"}</b> ◔</div>'
    else:
        tk += f'<div class="task q">T{i}<br>chờ</div>'
body = f"""
{alert("e", "<b>Tác vụ T6 lỗi:</b> Không đọc được nguồn của đối tượng ast-kham-chua-benh: kết nối bị ngắt. Thử lại sau. Hệ thống tự thử lại tối đa 3 lần. (ERR-08-105)")}
{head('<span class="mono" style="font-size:19px">SCN-20261126-0431</span> ' + tag(*SS["RUNNING"]) + " " + tag(*TR["VERIFY"]), btn("Chạy lại", "dis"), btn("Hủy lần đo", "danger"))}
<div class="card" style="margin-bottom:12px"><dl class="dl" style="grid-template-columns:100px 1fr 100px 1fr 100px 1fr 100px 1fr">
<dt>Đối tượng</dt><dd class="mono">ast-kham-chua-benh</dd><dt>Kích hoạt</dt><dd>Kiểm chứng phiếu DQ-2026-000138</dd><dt>Bộ quy tắc</dt><dd>BQ-KHAM-BENH v5</dd><dt>Trọng số</dt><dd>Mặc định v2</dd>
<dt>Bắt đầu</dt><dd>26/11 13:55</dd><dt>Đã chạy</dt><dd>11 phút</dd><dt>Giới hạn</dt><dd>6 giờ</dd><dt>Cửa sổ giờ</dt><dd>Ngoài cửa sổ: đo kiểm chứng được phép</dd></dl></div>
<div class="card" style="margin-bottom:12px"><div style="display:flex;align-items:center;margin-bottom:6px"><b>Tiến độ theo tác vụ</b><span class="sp" style="flex:1"></span><span class="muted">5 xong · 2 đang chạy · 1 lỗi · 4 chờ · ước tính còn 14 phút</span></div><div class="prog" style="margin-bottom:8px"><i style="width:49%"></i></div><div class="tasks" style="--n:12">{tk}</div></div>
<div class="cols2" style="grid-template-columns:minmax(0,2.3fr) minmax(0,1fr)">
  <div class="card"><div class="toolbar"><b>Kết quả quy tắc đến thời điểm này</b><span class="sp" style="flex:1"></span><span class="muted">Điểm chỉ có khi mọi tác vụ xong hoặc đạt độ phủ tối thiểu 95%</span></div>
  {table(["Quy tắc", "Chiều", "Kết quả", "Đã xử lý", "Vi phạm tạm tính"], [["<b class='mono'>KB-COM-001</b><div class='muted'>Mã bệnh nhân bắt buộc</div>", dim("COMPLETENESS"), tag("info", "◔ Đang tổng hợp"), "1.000.000 / 1.600.000", "0"], ["<b class='mono'>KB-VAL-002</b><div class='muted'>Mã ICD-10 thuộc danh mục</div>", dim("VALIDITY"), tag("info", "◔ Đang tổng hợp"), "1.000.000 / 1.600.000", "812"], ["<b class='mono'>KB-TIM-001</b><div class='muted'>Nhập trong 3 ngày sau khám</div>", dim("TIMELINESS"), tag("mute", "○ Chờ"), "0 / 1.600.000", "—"]], "Kết quả tạm của lần đo đang chạy", num=(3, 4))}</div>
  {card("Đo kiểm chứng", '<div class="muted" style="line-height:1.7">Phiếu DQ-2026-000138 đã được chủ quản báo đã sửa. Lần đo này kiểm tra 612 lỗi Nghiêm trọng của quy tắc KB-TIM-001. Nếu sạch, phiếu chuyển Đã kiểm chứng.</div><div style="margin-top:8px"><span class="btn">Mở phiếu →</span></div>')}
</div>"""
P["12b"] = ("Chi tiết lần đo, đang chạy", CR + " › Lần đo › SCN-20261126-0431", body)

# ------------------------------------------------------------------ 13 Bản ghi lỗi
FD = [
    ("SD-0412207", "HT-ACC-004", "ACCURACY", "CRITICAL", "ngay_sinh", "12/**/2026", "OPEN", "01/11", "01/11", "—", True),
    ("SD-0412219", "HT-ACC-004", "ACCURACY", "CRITICAL", "ngay_sinh", "03/**/2027", "OPEN", "01/10", "01/11", "—", True),
    ("SD-0771290", "HT-COM-002", "COMPLETENESS", "MAJOR", "so_cccd_me", "(rỗng)", "IN_REMEDIATION", "01/09", "01/11", "DQ-2026-000142", True),
    ("SD-0990014", "HT-VAL-001", "VALIDITY", "MAJOR", "ma_dvhc_xa", "7●●●●", "OPEN", "01/11", "01/11", "—", False),
    ("SD-1190382", "HT-UNI-001", "UNIQUENESS", "CRITICAL", "so_dang_ky", "KS-2026-●●●●●●", "OPEN", "01/08", "01/11", "—", False),
    ("SD-1204771", "HT-TIM-001", "TIMELINESS", "MINOR", "ngay_cap_nhat", "12/03/2019", "WAIVED", "01/06", "01/11", "—", False),
    ("SD-0330102", "HT-VAL-003", "VALIDITY", "MAJOR", "so_cccd_me", "●●●●●●●●●●●", "RESOLVED", "01/09", "01/10", "—", False),
    ("SD-0554420", "HT-ACC-005", "ACCURACY", "MAJOR", "ho_ten", "Nguyễn V●● A", "OPEN", "01/11", "01/11", "—", False),
]
FS = {"OPEN": ("err", "● Mở"), "IN_REMEDIATION": ("info", "◐ Đang khắc phục"), "RESOLVED": ("ok", "✓ Đã hết"), "WAIVED": ("mute", "◌ Ngoại lệ")}
fr = []
for f in FD:
    fr.append([chk(f[10]), f"<span class='mono'>{f[0]}</span>", f"<b class='mono'>{f[1]}</b>", dim(f[2]), sev(f[3]), f"<span class='mono'>{f[4]}</span>", f"<span class='mono'>{f[5]}</span>", tag(*FS[f[6]]), f[7], f[8], f"<span class='mono'>{f[9]}</span>" if f[9] != "—" else "—"])
body = f"""
{head("Bản ghi lỗi · ast-ho-tich-khai-sinh", '<span class="seg"><span class="on">Danh sách</span><span>Nhóm theo quy tắc</span></span>', btn("Xuất…"))}
{facets(["Mở 6.730", "Đang khắc phục 412", "Đã hết 1.044", "Ngoại lệ 36", "Tất cả 8.222"], 0)}
<div class="card">
  <div class="toolbar"><span class="input">Đối tượng: ast-ho-tich-khai-sinh ▾</span><span class="input">Chiều: Tất cả ▾</span><span class="input">Mức: Tất cả ▾</span><span class="input">Quy tắc ▾</span><span class="input">Lần đầu thấy: tất cả ▾</span><span class="input">Khóa bản ghi (gửi bằng POST) ⌕</span></div>
  {alert("w", "Có 1 bản ghi lỗi đã thuộc phiếu DQ-2026-000142. Bỏ chọn hoặc gắn vào phiếu đó. (ERR-08-034)")}
  {table(["", "Khóa bản ghi", "Quy tắc", "Chiều", "Mức", "Trường", "Giá trị (đã che)", "Trạng thái", "Lần đầu thấy", "Lần cuối thấy", "Phiếu"], fr, "Bản ghi lỗi", num=())}
  {foot("Hiển thị 1–8 trong 6.730 · giá trị trường Nhạy cảm chỉ hiện dạng đã che hoặc băm")}
</div>
<div class="selbar"><b>Đã chọn 3</b><span class="muted">2 Nghiêm trọng · 1 Đáng kể</span><span class="sp" style="flex:1"></span>{btn("Mở phiếu khắc phục", "pri")}{btn("Đề nghị ngoại lệ")}{btn("Xuất…")}{btn("Bỏ chọn")}</div>"""
P["13"] = ("Bản ghi lỗi", CR + " › Bản ghi lỗi", body)

# ------------------------------------------------------------------ 14 Chi tiết lỗi, ngoại lệ (ngăn kéo)
dr = f"""
<div style="display:flex;gap:8px;align-items:center;margin-bottom:8px"><span class="mono"><b>SD-0412207</b></span>{sev("CRITICAL")}{tag("err", "● Mở")}</div>
{tabs(["Chi tiết", "Lịch sử", "Nguồn gốc", "Ngoại lệ"], 3)}
<div class="card raised" style="margin-bottom:10px"><div style="display:flex;gap:6px;align-items:center">{dim("ACCURACY")}<b class="mono">HT-ACC-004</b></div><div class="muted" style="margin-top:3px">Ngày sinh không sau ngày đăng ký · trường <span class="mono">ngay_sinh</span> · giá trị <span class="mono">12/**/2026</span> (đã che một phần)</div></div>
<b style="font-size:14px">Đề nghị ngoại lệ chấp nhận</b>
<div class="field" style="margin-top:8px"><label>Phạm vi *</label><div class="seg"><span class="on">Các lỗi đã chọn (3)</span><span>Theo bộ lọc quy tắc</span></div></div>
<div class="row"><div class="field"><label>Hiệu lực đến *</label><span class="input cell-err">15/09/2027 ▾</span><div class="err-t">Ngoại lệ tối đa 180 ngày và phải có phạm vi lỗi cụ thể. (ERR-08-033)</div></div><div class="field"><label>Người đề nghị</label><span class="input">Nguyễn Thị Lan (DS)</span></div></div>
<div class="field"><label>Lý do *</label><span class="input" style="height:70px;align-items:flex-start;padding-top:8px;white-space:normal">Ngày sinh theo hồ sơ giấy trước 2010, chờ Sở Tư pháp đối chiếu sổ gốc, không sửa được tại nguồn trong kỳ.</span><div class="muted">Tối thiểu 20 ký tự · 98 ký tự</div></div>
<div class="alert i">Lỗi được ngoại lệ không tính vào mẫu số điểm, được đếm riêng và nêu ở báo cáo. Cần người duyệt (DA) khác người đề nghị.</div>
<div class="foot">{btn("Hủy")}{btn("Gửi đề nghị ngoại lệ", "pri")}</div>
<div class="muted" style="margin-top:8px">Ngoại lệ đang chờ duyệt hoặc hiệu lực của cùng quy tắc: 1 (WV-2026-014, hết hạn 15/02/2027).</div>
"""
P["14"] = ("Chi tiết bản ghi lỗi, ngoại lệ", CR + " › Bản ghi lỗi › SD-0412207",
           '<div class="dim-bg">' + body.replace('<div class="selbar">', '<div class="selbar" style="display:none">') + "</div>", drawer("Bản ghi lỗi", dr, 520))

# ------------------------------------------------------------------ 15 Hộp việc phiếu khắc phục
IS = [
    ("DQ-2026-000142", "ast-ho-tich-khai-sinh · HT-COM-002", "MAJOR", "Sở Tư pháp", "2.104", "ASSIGNED", "Còn 3 ngày", 70),
    ("DQ-2026-000138", "ast-kham-chua-benh · KB-TIM-001", "CRITICAL", "Sở Y tế", "612", "FIXED", "Chờ kiểm chứng", 100),
    ("DQ-2026-000131", "ast-thua-dat · TD-VAL-002", "CRITICAL", "Sở TN&MT", "1.882", "IN_PROGRESS", "Quá 4 ngày", 100),
    ("DQ-2026-000127", "ast-hoc-sinh · HS-UNI-001", "MAJOR", "Sở GD&ĐT", "340", "OPEN", "Còn 9 ngày", 40),
    ("DQ-2026-000119", "mdm-citizen · CD-VAL-004", "CRITICAL", "Công an tỉnh", "1.284", "REOPENED", "Quá 1 ngày", 100),
    ("DQ-2026-000112", "ast-ho-tich-ket-hon · KH-ACC-002", "MINOR", "Sở Tư pháp", "96", "IN_PROGRESS", "Còn 21 ngày", 25),
]
IST = {"OPEN": ("info", "Mở"), "ASSIGNED": ("info", "Đã giao"), "IN_PROGRESS": ("info", "Đang xử lý"), "FIXED": ("ok", "Đã báo sửa"), "VERIFIED": ("ok", "Đã kiểm chứng"), "REOPENED": ("warn", "Mở lại"), "REJECTED": ("mute", "Bị từ chối"), "CANCELLED": ("mute", "Đã hủy")}
ir = []
for i in IS:
    col = "#c0392b" if "Quá" in i[6] else ("#c98a00" if "3 ngày" in i[6] else "#0b7a52")
    ir.append([f"<b class='mono'>{i[0]}</b><div class='muted'>{i[1]}</div>", sev(i[2]), i[3], i[4], tag(*IST[i[5]]), f'<div style="min-width:120px"><div class="sla"><i style="width:{min(i[7], 100)}%;background:{col}"></i></div><span style="font-size:12px;color:{col}">{i[6]}</span></div>'])
part = [("Của tôi", 12, True), ("Chưa nhận", 5, False), ("Quá hạn", 7, False), ("Sắp hạn (3 ngày)", 9, False), ("Chờ kiểm chứng", 4, False), ("Đã đóng", 118, False)]
pl = "".join(f'<div class="{"on" if p[2] else ""}" style="display:flex;justify-content:space-between"><span>{p[0]}</span><b>{p[1]}</b></div>' for p in part)
body = f"""
{head("Hộp việc phiếu khắc phục", inp("Tìm mã phiếu… ⌕"), btn("Giao việc"), btn("Chuyển tổ chức"))}
<div class="grid2" style="grid-template-columns:170px minmax(0,1fr) 300px">
  <div class="card tree">{pl}<div class="muted" style="margin-top:10px">SLA theo ngày làm việc: Nghiêm trọng 5 · Đáng kể 15 · Nhẹ 30 (giả định).</div></div>
  <div class="card">
    <div class="toolbar"><span class="input">Tổ chức: Tất cả ▾</span><span class="input">Mức: Tất cả ▾</span><span class="input">Trạng thái: Tất cả ▾</span><span class="sp" style="flex:1"></span><span class="muted">Sắp theo hạn gần nhất</span></div>
    {table(["Phiếu", "Mức", "Tổ chức chủ quản", "Số lỗi", "Trạng thái", "Hạn xử lý (SLA)"], ir, "Hộp việc phiếu khắc phục", num=(3,))}
    {foot("Hiển thị 1–6 trong 12 phiếu của tôi")}
  </div>
  <div class="card list-sel" style="outline:0;background:#fff"><h3 style="margin:0 0 8px;font-size:15px">DQ-2026-000142</h3>
    <div style="margin-bottom:8px">{sev("MAJOR")} {tag(*IST["ASSIGNED"])}</div>
    <dl class="dl" style="grid-template-columns:100px 1fr"><dt>Đối tượng</dt><dd class="mono">ast-ho-tich-khai-sinh</dd><dt>Quy tắc</dt><dd class="mono">HT-COM-002</dd><dt>Chủ quản</dt><dd>Sở Tư pháp</dd><dt>Người nhận</dt><dd>Lê Thị Mai (DO)</dd><dt>Số lỗi</dt><dd>2.104 (còn mở 2.104)</dd><dt>Hạn</dt><dd>01/12/2026 · còn 3 ngày làm việc</dd><dt>Leo thang</dt><dd class="muted">Sau 5 ngày quá hạn</dd></dl>
    <div style="margin:10px 0 4px"><b style="font-size:13px">Hoạt động gần nhất</b></div><div class="vtl"><div>24/11 · Lê Thị Mai bắt đầu xử lý</div><div>19/11 · Giao cho Sở Tư pháp</div><div>19/11 · Hệ thống mở phiếu từ 2.104 lỗi</div></div>
    <div class="foot" style="justify-content:flex-start">{btn("Mở chi tiết", "pri")}{btn("Chuyển")}{btn("Từ chối")}</div>
  </div>
</div>"""
P["15"] = ("Hộp việc phiếu khắc phục", CR + " › Khắc phục", body)

# ------------------------------------------------------------------ 16 Chi tiết phiếu khắc phục
body = f"""
{alert("w", "<b>Chủ quản không tự xác nhận phiếu.</b> Sau khi anh/chị báo đã sửa, hệ thống sẽ đo lại để kiểm chứng. (ERR-08-035)")}
{head('<span class="mono" style="font-size:19px">DQ-2026-000138</span> ' + sev("CRITICAL") + " " + tag(*IST["IN_PROGRESS"]), btn("Chuyển tổ chức"), btn("Từ chối"), btn("Báo đã sửa", "pri"))}
<div class="step"><div class="d">✓ Mở</div><div class="d">✓ Đã giao</div><div class="c">Đang xử lý</div><div>Đã báo sửa</div><div>Đã kiểm chứng</div></div>
<div class="cols3" style="grid-template-columns:minmax(0,1.3fr) minmax(0,1fr) 340px">
  {card("Dòng thời gian", '<div class="vtl"><div><b>24/11 16:20</b> · Lê Thị Mai (DO, Sở Y tế)<br>Đã chỉnh 380 bản ghi tại HTTT khám chữa bệnh, còn 232.</div><div><b>22/11 09:05</b> · Lê Thị Mai<br>Bắt đầu xử lý; đính kèm kế hoạch chỉnh (PDF, 120 KB).</div><div><b>20/11 08:30</b> · Nguyễn Thị Lan (DS)<br>Giao cho Sở Y tế; hạn 27/11 (5 ngày làm việc).</div><div><b>19/11 07:55</b> · Hệ thống<br>Mở phiếu từ 612 lỗi Nghiêm trọng của KB-TIM-001.</div></div><div class="field" style="margin-top:12px"><label>Thêm trao đổi</label><span class="input" style="height:54px;align-items:flex-start;padding-top:8px">Nhập nội dung, đính kèm tệp…</span></div><div class="foot" style="margin-top:0">' + btn("Gửi") + '</div>')}
  <div>
    {card("Lỗi thuộc phiếu", '<div class="hbar" style="grid-template-columns:90px 1fr 60px"><span>Còn mở</span><span><i style="width:38%;background:#c0392b"></i></span><b class="num">232</b></div><div class="hbar" style="grid-template-columns:90px 1fr 60px"><span>Đã hết</span><span><i style="width:62%;background:#0b7a52"></i></span><b class="num">380</b></div><dl class="dl" style="grid-template-columns:110px 1fr;margin-top:8px"><dt>Quy tắc</dt><dd class="mono">KB-TIM-001</dd><dt>Đối tượng</dt><dd class="mono">ast-kham-chua-benh</dd><dt>Tổng lỗi</dt><dd>612</dd></dl><div style="margin-top:8px"><span class="btn">Xem lỗi trong UI-08-13 →</span></div>')}
    <div style="height:10px"></div>
    {card("SLA", '<div class="sla" style="height:10px"><i style="width:80%;background:#c98a00"></i></div><div class="muted" style="margin-top:4px">Hạn 27/11 · còn 1 ngày làm việc</div>')}
  </div>
  <div>
    <div class="chrome" style="margin:0"><b>Báo đã sửa</b>
    <div class="field" style="margin-top:8px"><label>Mô tả việc đã sửa *</label><span class="input cell-err" style="height:70px;align-items:flex-start;padding-top:8px;white-space:normal">Đã sửa phần lớn.</span><div class="err-t">Mô tả việc đã sửa (tối thiểu 20 ký tự) trước khi báo đã sửa. (ERR-08-036)</div></div>
    <div class="foot">{btn("Báo đã sửa", "dis")}</div></div>
    <div style="height:10px"></div>
    {card("Đo kiểm chứng và chuyển PH-06", '<div class="muted" style="line-height:1.6">Sau khi báo đã sửa, lần đo VERIFY tự chạy (chờ tối đa 60 phút nếu nguồn là bản ghi vàng). Sạch: phiếu Đã kiểm chứng. Còn lỗi: Mở lại.</div><div style="margin-top:10px">' + btn("Chuyển hàng đợi dữ liệu chủ", "dis") + '</div><div class="muted" style="margin-top:4px">Chỉ lỗi của bản ghi vàng mới chuyển được sang hàng đợi dữ liệu chủ. (ERR-08-051)</div>')}
  </div>
</div>"""
P["16"] = ("Chi tiết phiếu khắc phục", CR + " › Khắc phục › DQ-2026-000138", body)

# ------------------------------------------------------------------ 17 Cảnh báo
AL = [
    ("AL-2026-0312", "CB-DIEM-THAP", "Điểm miền Y tế 68,3 dưới ngưỡng cảnh báo 70", "HIGH", "FIRING", "26/11 02:10", "Lần 3 (nhắc mỗi 4 giờ)"),
    ("AL-2026-0311", "CB-LAN-DO-LOI", "Lần đo SCN-20261125-0412 thất bại", "HIGH", "FIRING", "25/11 21:52", "ERR-08-114: chưa gửi được kênh Email"),
    ("AL-2026-0307", "CB-CRITICAL-MOI", "412 lỗi Nghiêm trọng mới ở ast-ho-tich-khai-sinh", "MEDIUM", "ACKNOWLEDGED", "01/11 03:15", "Đã xác nhận bởi Nguyễn Thị Lan"),
    ("AL-2026-0301", "CB-PHIEU-QUA-HAN", "7 phiếu quá hạn", "MEDIUM", "SILENCED", "20/11 07:00", "Tắt tiếng đến 27/11"),
    ("AL-2026-0299", "CB-TY-LE-LOI-TT", "Tỷ lệ FAIL trực tuyến 4,2% trong 15 phút", "LOW", "RESOLVED", "18/11 10:20", "Tự hết 10:50"),
]
AS = {"FIRING": ("err", "● Đang bật"), "ACKNOWLEDGED": ("info", "✓ Đã xác nhận"), "SILENCED": ("mute", "◌ Tắt tiếng"), "RESOLVED": ("ok", "✓ Đã hết")}
AV = {"HIGH": ("c", "Cao"), "MEDIUM": ("m", "Trung bình"), "LOW": ("n", "Thấp")}
ar = [[f"<b class='mono'>{a[0]}</b><div class='muted'>{a[1]}</div>", a[2], f'<span class="sev {AV[a[3]][0]}">{AV[a[3]][1]}</span>', tag(*AS[a[4]]), a[5], a[6], ("<span class='btn' style='height:24px'>Xác nhận</span> <span class='btn' style='height:24px'>Tắt tiếng</span>" if a[4] == "FIRING" else "")] for a in AL]
rl = table(["Quy tắc cảnh báo", "Điều kiện", "Phạm vi", "Mức", "Kênh", "Bật"],
           [["<b class='mono'>CB-DIEM-THAP</b>", "<span class='mono'>SCORE_BELOW</span> &lt; 70", "Mọi miền", '<span class="sev c">Cao</span>', "Trong ứng dụng, Email", sw(True)],
            ["<b class='mono'>CB-LAN-DO-LOI</b>", "<span class='mono'>SCAN_FAILED</span>", "Mọi đối tượng", '<span class="sev c">Cao</span>', "Trong ứng dụng, Email", sw(True)],
            ["<b class='mono'>CB-CRITICAL-MOI</b>", "<span class='mono'>NEW_CRITICAL_FINDINGS</span> &gt; 100", "Mọi đối tượng", '<span class="sev m">Trung bình</span>', "Trong ứng dụng", sw(True)],
            ["<b class='mono'>CB-PHIEU-QUA-HAN</b>", "<span class='mono'>ISSUE_OVERDUE</span> ≥ 5 ngày", "Mọi tổ chức", '<span class="sev m">Trung bình</span>', "Trong ứng dụng, Email", sw(True)],
            ["<b class='mono'>CB-TY-LE-LOI-TT</b>", "<span class='mono'>INLINE_FAIL_RATE</span> &gt; 4%", "flow-ho-tich-lien-thong", '<span class="sev n">Thấp</span>', "Trong ứng dụng", sw(False)]], "Quy tắc cảnh báo")
body = f"""
{alert("e", "Cảnh báo AL-2026-0311 chưa gửi được tới kênh thông báo Email. Hệ thống sẽ thử lại; cảnh báo vẫn hiện trong ứng dụng. (ERR-08-114)", "Xem")}
{head("Cảnh báo chất lượng", btn("+ Quy tắc cảnh báo", "pri"))}
{tabs(["Cảnh báo 5", "Quy tắc cảnh báo 5"], 0)}
<div class="card" style="margin-bottom:14px">
  <div class="toolbar"><span class="input">Trạng thái: Đang bật, Đã xác nhận ▾</span><span class="input">Mức: Tất cả ▾</span><span class="sp" style="flex:1"></span><span class="muted">Một quy tắc và một đối tượng chỉ có một cảnh báo chưa hết (BR-08-029)</span></div>
  {table(["Cảnh báo", "Nội dung", "Mức", "Trạng thái", "Bắt đầu", "Ghi chú", "Thao tác"], ar, "Cảnh báo chất lượng")}
</div>
<div class="cols2" style="grid-template-columns:minmax(0,1.8fr) minmax(0,1fr)">
  {card("Quy tắc cảnh báo", rl)}
  <div class="chrome" style="margin:0"><b>Tắt tiếng cảnh báo AL-2026-0312</b>
    <div class="field" style="margin-top:8px"><label>Tắt tiếng đến *</label><span class="input">03/12/2026 ▾</span><div class="muted">Tối đa 7 ngày.</div></div>
    <div class="field"><label>Lý do *</label><span class="input" style="height:54px;align-items:flex-start;padding-top:8px;white-space:normal">Đã giao Sở Y tế xử lý, theo dõi qua phiếu DQ-2026-000138.</span></div>
    <div class="foot">{btn("Hủy")}{btn("Tắt tiếng", "pri")}</div>
  </div>
</div>"""
P["17"] = ("Cảnh báo chất lượng", CR + " › Cảnh báo", body)

# ------------------------------------------------------------------ 18 Báo cáo
BC = [("BC-DQ-2026-NAM-T68", "Báo cáo chính thức năm 2026", "ANNUAL", "DRAFT", True), ("BC-DQ-2026-10-T68", "Báo cáo kỳ tháng 10/2026", "PERIODIC", "PUBLISHED", False), ("BC-DQ-2026-09-T68", "Báo cáo kỳ tháng 9/2026", "PERIODIC", "PUBLISHED", False), ("BC-DQ-2025-NAM-T68", "Báo cáo chính thức năm 2025", "ANNUAL", "PUBLISHED", False)]
RT = {"DRAFT": ("mute", "Nháp"), "IN_REVIEW": ("warn", "Chờ duyệt"), "PUBLISHED": ("ok", "Đã công bố"), "WITHDRAWN": ("mute", "Đã thu hồi")}
bl = "".join(f'<div class="node2 {"on" if b[4] else ""}"><div style="display:flex;justify-content:space-between"><b class="mono" style="font-size:12px">{b[0]}</b></div><div>{b[1]}</div><div style="margin-top:3px">{tag(*RT[b[3]])} <span class="muted">{"Năm" if b[2] == "ANNUAL" else "Kỳ"}</span></div></div>' for b in BC)
ready = table(["Điều kiện (BR-08-010)", "Kết quả", "Chi tiết"],
              [["Mọi đối tượng có lần đo FULL trong năm", tag("err", "✕ 43 / 46"), "ast-thua-dat, ast-vac-xin, +1"], ["Ảnh chụp đại diện đủ sáu chiều", tag("err", "✕ 2 đối tượng"), "ast-kham-chua-benh, ast-thua-dat"], ["Không dùng ảnh chụp mẫu hoặc tăng dần", tag("ok", "✓ Đạt"), "FULL_DECEMBER"], ["Có ít nhất một khuyến nghị", tag("ok", "✓ 3 khuyến nghị"), "Đã nhập"]], "Sẵn sàng báo cáo năm")
body = f"""
{head("Báo cáo chất lượng dữ liệu", btn("+ Báo cáo kỳ"), btn("+ Báo cáo năm", "pri"))}
<div class="cols3" style="grid-template-columns:250px minmax(0,1fr) 270px">
  <div>{card("Danh sách báo cáo", '<div class="toolbar" style="margin-bottom:8px"><span class="input" style="min-width:0">Tìm ⌕</span><span class="input" style="min-width:0">Loại ▾</span></div>' + bl)}</div>
  <div>
    {alert("e", "Chưa đủ điều kiện báo cáo chính thức năm 2026: 3 đối tượng thiếu lần đo toàn bộ hoặc có điểm thiếu chiều. (ERR-08-038)", "Tạo lần đo FULL còn thiếu")}
    <div class="chrome" style="margin:0 0 12px"><h1>Báo cáo chính thức năm 2026 {tag("mute", "Nháp")}</h1><div class="muted">BC-DQ-2026-NAM-T68 · phạm vi toàn tỉnh · 46 đối tượng · soạn bởi Nguyễn Thị Lan</div>
    <div class="step"><div class="c">Soạn</div><div>Chờ duyệt (bốn mắt)</div><div>Đã công bố</div><div>Xuất, ký số, phân phối</div></div></div>
    {card("Sẵn sàng báo cáo năm", ready)}
    <div style="height:12px"></div>
    {card("Nội dung báo cáo", '<div style="display:grid;grid-template-columns:1fr 1fr;gap:12px"><div><b style="font-size:13px">Tóm tắt điều hành</b><div class="muted">Điểm toàn tỉnh tháng 12/2026 (tạm): 79,3, xu hướng Cải thiện. 5 miền đạt, 1 cảnh báo, 2 không đạt.</div></div><div><b style="font-size:13px">Điểm theo miền và theo chiều</b><div class="muted">Bảng 7 miền, radar sáu chiều, biểu đồ 13 tháng.</div></div><div><b style="font-size:13px">Lỗi và khắc phục</b><div class="muted">3.917 lỗi Nghiêm trọng mở; 118 phiếu đóng; 7 quá hạn; 36 lỗi ngoại lệ.</div></div><div><b style="font-size:13px">Tiến độ chuẩn hóa trước 31/12/2026</b><div class="muted">Khối bổ sung khi có yêu cầu (Q08-17).</div></div></div><div style="margin-top:10px"><b style="font-size:13px">Khuyến nghị (3)</b><div class="muted">1. Sở TN&amp;MT hoàn tất đo FULL thửa đất trước 15/12. 2. Sở Y tế xử lý chiều Kịp thời. 3. Bật kiểm tra trực tuyến cho luồng hộ tịch liên thông.</div></div>')}
  </div>
  <div>
    <div class="chrome" style="margin:0 0 12px"><b>Thao tác</b>
    <div style="display:flex;flex-direction:column;gap:8px;margin-top:8px">{btn("Cập nhật số liệu từ ảnh chụp")}{btn("Gửi duyệt", "dis")}<div class="muted">Gửi duyệt bị khóa vì chưa đủ điều kiện năm.</div>{btn("Xuất PDF")}{btn("Xuất XLSX")}{btn("Ký số")}</div></div>
    {card("Đăng ký nhận báo cáo", '<div class="muted" style="margin-bottom:6px">Nhận khi công bố</div>' + table(["Người nhận", "Kênh"], [["Trần Minh Quân (DA)", "Email, Trong ứng dụng"], ["Lãnh đạo UBND tỉnh (VW)", "Trong ứng dụng"], ["Sở TN&MT (DO)", "Email"]], "Người nhận báo cáo") + '<div style="margin-top:8px"><span class="btn">+ Thêm người nhận</span></div>')}
  </div>
</div>"""
P["18"] = ("Báo cáo chất lượng", CR + " › Báo cáo › BC-DQ-2026-NAM-T68", body)

# ------------------------------------------------------------------ 19 Cài đặt
def prm(k, v, rng, note="", err=""):
    return f'<tr><td class="mono">{k}</td><td><span class="input {"cell-err" if err else ""}" style="min-width:90px">{v}</span>{"<div class=err-t>" + err + "</div>" if err else ""}</td><td class="muted">{rng}</td><td class="muted">{note}</td></tr>'
pt = ('<table aria-label="Tham số chất lượng"><thead><tr><th>Khóa</th><th>Giá trị</th><th>Miền, trần</th><th>Ý nghĩa</th></tr></thead><tbody>'
      + prm("08.scan.default-cron", "0 0 2 1 * ?", "Quartz", "Lịch tự tạo khi kích hoạt")
      + prm("08.scan.manual-per-hour", "80", "1…60", "Hạn mức đo theo yêu cầu mỗi giờ", "Giá trị 80 của 08.scan.manual-per-hour ngoài khoảng cho phép 1…60. (ERR-08-042)")
      + prm("08.scan.max-duration-hours", "6", "1…24", "Dừng lần đo quá thời gian")
      + prm("08.finding.retention-months", "9", "13…60", "Lưu bản ghi lỗi", "Thời gian lưu bản ghi lỗi không được dưới 13 tháng. (ERR-08-043)")
      + prm("08.issue.sla-days", "CRITICAL 5 · MAJOR 15 · MINOR 30", "1…90 mỗi mức", "SLA ngày làm việc (giả định)")
      + prm("08.waiver.max-days", "180", "≤ 365", "Hạn tối đa của ngoại lệ")
      + prm("08.inline.timeout-ms", "40", "10…50", "Ngân sách đánh giá trực tuyến")
      + prm("08.rule.sql-predicate-enabled", sw(False) + " Tắt", "Bật/tắt", "Cho phép toán tử SQL_PREDICATE")
      + prm("08.benchmark.opt-in", sw(True) + " Bật", "Bật/tắt", "Tham gia so sánh liên tenant")
      + "</tbody></table>")
nav19 = "".join(f'<div class="{"on" if i == 1 else ""}">{t}</div>' for i, t in enumerate(["Miền chất lượng", "Tham số", "Lưu giữ và dọn dữ liệu", "Đẩy KPI sang PH-16", "Nhật ký kiểm toán"]))
body = f"""
{alert("w", "Chưa đẩy được 3 bản tin KPI chất lượng dữ liệu sang PH-16. (ERR-08-113)", "Xem tab Đẩy KPI")}
{head("Cài đặt chất lượng dữ liệu", btn("Hoàn tác thay đổi"), btn("Lưu tham số", "dis"))}
<div class="grid2" style="grid-template-columns:220px minmax(0,1fr)">
  <div class="card tree">{nav19}<div class="muted" style="margin-top:10px">Tab Nhật ký chỉ hiện với SO, AU (<span class="mono">PERM-08-audit-read</span>).</div></div>
  <div class="card"><div class="toolbar"><b>Tham số theo tenant T68</b><span class="sp" style="flex:1"></span><span class="input">Tìm khóa ⌕</span><span class="muted">40 khóa · 2 giá trị không hợp lệ</span></div>
  {pt}
  <div class="muted" style="margin-top:8px">Trần do Quản trị nền tảng đặt ở cấp nền tảng. Ngưỡng Đạt, Cảnh báo và trọng số không nằm ở đây mà ở UI-08-10.</div></div>
</div>"""
P["19"] = ("Cài đặt chất lượng theo tenant", CR + " › Cài đặt › Tham số", body)

# ------------------------------------------------------------------ 20 Giám sát kiểm tra trực tuyến
mins = [f"{h}:{m:02d}" for h in (13, 14) for m in (0, 10, 20, 30, 40, 50)][2:]
req = [118, 124, 131, 140, 152, 149, 143, 160, 171, 166]
fail = [3.1, 3.4, 3.2, 3.9, 4.2, 4.6, 4.1, 3.8, 3.5, 3.3]
lat = [31, 33, 32, 36, 41, 44, 39, 37, 35, 34]
ch = echart_line([("Tỷ lệ FAIL (%)", fail, "#c0392b", "")], mins[:10], w=640, h=210, ymin=0, ymax=6, yfmt="{:.0f}", marks=[(5, "Ngưỡng cảnh báo 5%", "#a11a1a")])
body = f"""
{alert("w", "Dịch vụ đối chiếu danh mục tạm thời không khả dụng. 14 yêu cầu trong 5 phút qua trả kết quả Đạt có cờ degraded (FAIL_OPEN). (ERR-08-104)")}
{head("Giám sát kiểm tra trực tuyến", inp("Đối tượng: flow-ho-tich-lien-thong ▾"), '<span class="seg"><span>15 phút</span><span class="on">1 giờ</span><span>24 giờ</span></span>', btn("Cấu hình", "pri"))}
<div class="kpis" style="--n:5">
  {kpi("Yêu cầu mỗi phút", "152", "▲ 9% so 1 giờ trước")}
  {kpi("Độ trễ p95", "41 ms", "Ngân sách 50 ms · đạt")}
  {kpi("Tỷ lệ FAIL", "4,2%", "Chế độ STRICT · ngưỡng cảnh báo 5%")}
  {kpi("Kết quả degraded", "14", "Phụ thuộc lỗi, FAIL_OPEN")}
  {kpi("Quá ngân sách", "0", "Không có ERR-08-103")}
</div>
<div class="cols2" style="grid-template-columns:minmax(0,1.6fr) minmax(0,1fr)">
  {card("Tỷ lệ FAIL theo phút, 1 giờ gần nhất (đỉnh 4,6%)", ch + legend([("Tỷ lệ FAIL (%)", "#c0392b")]) + '<div class="muted">Thống kê tổng hợp theo phút, giữ 90 ngày. Không hiển thị nội dung bản ghi.</div>')}
  {card("Cấu hình trực tuyến của đối tượng", '<dl class="dl" style="grid-template-columns:150px 1fr"><dt>Chế độ</dt><dd><div class="seg"><span class="on">STRICT</span><span>ADVISORY</span></div></dd><dt>Khi phụ thuộc lỗi</dt><dd><div class="seg"><span class="on">FAIL_OPEN</span><span>FAIL_CLOSED</span></div></dd><dt>Ngân sách</dt><dd>40 ms (10…50)</dd><dt>Quy tắc chạy</dt><dd>4 quy tắc (Lô + trực tuyến)</dd><dt>Kamelet</dt><dd class="mono">dh-dq-check · STOP_TO_DLQ</dd><dt>Sửa lần cuối</dt><dd>Nguyễn Thị Lan · 12/11</dd></dl><div class="muted" style="margin-top:6px">STRICT: lỗi Nghiêm trọng, Đáng kể cho FAIL; ADVISORY không bao giờ FAIL.</div>')}
</div>
<div class="cols2" style="margin-top:14px;grid-template-columns:1fr 1fr">
  {card("Quy tắc vi phạm nhiều nhất (1 giờ)", table(["Quy tắc", "Chiều", "Vi phạm", "p95"], [["<span class='mono'>HTLT-VAL-001</span> Mã xã thuộc DM_DVHC", dim("VALIDITY"), "231", "12 ms"], ["<span class='mono'>HTLT-COM-001</span> Họ tên bắt buộc", dim("COMPLETENESS"), "168", "3 ms"], ["<span class='mono'>HTLT-ACC-002</span> Ngày sinh hợp lệ", dim("ACCURACY"), "92", "5 ms"], ["<span class='mono'>HTLT-VAL-003</span> CCCD 12 số", dim("VALIDITY"), "60", "9 ms"]], "Quy tắc vi phạm nhiều nhất trực tuyến", num=(2, 3)))}
  {card("Bên gọi", table(["Bên gọi", "Yêu cầu", "FAIL", "Lỗi 5xx"], [["PH-04 luồng <span class='mono'>ho-tich-lien-thong</span> (scope dq.check)", "7.912", "4,3%", "14"], ["PH-06 cổng chất lượng đầu vào", "1.204", "2,1%", "0"], ["PH-04 luồng <span class='mono'>kham-chua-benh</span>", "0", "—", "0"]], "Bên gọi kiểm tra trực tuyến", num=(1, 2, 3)))}
</div>"""
P["20"] = ("Giám sát kiểm tra trực tuyến", CR + " › Trực tuyến", body)
