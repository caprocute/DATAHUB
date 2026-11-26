from kit import *

CR = "Dữ liệu dùng chung › Chất lượng dữ liệu"
P = {}

# ------------------------------------------------------------------ 06 Danh sách bộ quy tắc
RS = [
    ("BQ-HO-TICH", "Bộ quy tắc hộ tịch", "ast-ho-tich-khai-sinh", "v6", "v7 · Nguyễn Thị Lan", 12, "6/6", "PENDING"),
    ("BQ-DAN-CU", "Bộ quy tắc dân cư", "mdm-citizen", "v4", "—", 18, "6/6", "ACTIVE"),
    ("BQ-DOANH-NGHIEP", "Bộ quy tắc doanh nghiệp", "mdm-organization", "v3", "v4 · Phạm Văn Hùng", 14, "6/6", "DRAFT"),
    ("BQ-DVHC", "Bộ quy tắc danh mục đơn vị hành chính", "rdm-dvhc", "v2", "—", 7, "5/6", "ACTIVE"),
    ("BQ-KHAM-BENH", "Bộ quy tắc khám chữa bệnh", "ast-kham-chua-benh", "v5", "—", 16, "6/6", "ACTIVE"),
    ("BQ-THUA-DAT", "Bộ quy tắc thửa đất", "ast-thua-dat", "v2", "—", 9, "4/6", "ACTIVE"),
    ("BQ-HOC-SINH", "Bộ quy tắc học sinh", "ast-hoc-sinh", "v3", "—", 11, "6/6", "ACTIVE"),
    ("BQ-DKKD", "Bộ quy tắc đăng ký kinh doanh", "ast-dang-ky-kinh-doanh", "—", "v1 · Phạm Văn Hùng", 8, "5/6", "DRAFT"),
]
VS = {"ACTIVE": ("ok", "● Hiệu lực"), "PENDING": ("warn", "◐ Chờ duyệt"), "DRAFT": ("mute", "○ Có bản nháp")}
rows = []
for r in RS:
    rows.append([f"<b class='mono'>{r[0]}</b><div class='muted'>{r[1]}</div>", f"<span class='mono'>{r[2]}</span>", r[3], r[4], str(r[5]), r[6], tag(*VS[r[7]])])
tpl = table(["Mẫu", "Chiều", "Toán tử"],
            [["CCCD 12 số", dim("VALIDITY"), "<span class='mono'>CEL</span>"], ["Mã số thuế 10, 13 số", dim("VALIDITY"), "<span class='mono'>CHECKSUM</span>"],
             ["Số điện thoại Việt Nam", dim("VALIDITY"), "<span class='mono'>REGEX</span>"], ["Email", dim("VALIDITY"), "<span class='mono'>REGEX</span>"],
             ["Mã ĐVHC thuộc danh mục", dim("VALIDITY"), "<span class='mono'>IN_RDM</span>"], ["Ngày sinh không ở tương lai", dim("ACCURACY"), "<span class='mono'>RANGE</span>"]], "Thư viện mẫu COMMON")
body = f"""
{head("Danh sách bộ quy tắc", inp("Tìm mã, tên… ⌕", "min-width:220px"), btn("Nhập YAML, JSON"), btn("+ Tạo bộ quy tắc", "pri"))}
{tabs(["Bộ quy tắc 8", "Quy tắc 95", "Thư viện mẫu 24"], 0)}
<div class="cols2" style="grid-template-columns:minmax(0,1.9fr) minmax(0,1fr)">
  <div class="card">
    <div class="toolbar"><span class="input">Đối tượng: Tất cả ▾</span><span class="input">Trạng thái: Tất cả ▾</span><span class="input">Chỉ bản nháp của tôi</span><span class="sp" style="flex:1"></span><span class="muted">Hàng có menu ⋯: Sao chép, Xuất, Lịch sử, Ngừng</span></div>
    {table(["Bộ quy tắc", "Đối tượng đo", "Hiệu lực", "Bản nháp", "Quy tắc bật", "Chiều phủ", "Trạng thái"], rows, "Danh sách bộ quy tắc", num=(4,))}
    {foot("Hiển thị 1–8 trong 8 bộ")}
  </div>
  {card("Thư viện mẫu dùng chung (tenant COMMON)", '<div class="muted" style="margin-bottom:8px">Mẫu do Quản trị nền tảng duy trì. Chọn mẫu để thêm vào bản nháp; sửa mẫu tạo phiên bản mẫu mới, quy tắc đã dùng giữ phiên bản cũ.</div>' + tpl + '<div style="margin-top:8px"><span class="btn">Xem cả 24 mẫu →</span></div>')}
</div>"""
P["06"] = ("Danh sách bộ quy tắc", CR + " › Bộ quy tắc", body)

# ------------------------------------------------------------------ 07 Trình soạn bộ quy tắc
RULES = [
    ("HT-COM-001", "Số đăng ký bắt buộc", "COMPLETENESS", "NOT_NULL", "so_dang_ky", "CRITICAL", "BOTH", "0,0%", True, True),
    ("HT-COM-002", "Số CCCD người mẹ bắt buộc khi còn sống", "COMPLETENESS", "REQUIRED_IF", "so_cccd_me", "MAJOR", "BATCH", "8,4%", True, True),
    ("HT-VAL-001", "Mã xã thuộc danh mục DM_DVHC", "VALIDITY", "IN_RDM", "ma_dvhc_xa", "MAJOR", "BOTH", "0,02%", True, True),
    ("HT-VAL-002", "Giới tính thuộc DM_GIOI_TINH", "VALIDITY", "IN_RDM", "gioi_tinh", "MINOR", "BOTH", "0,2%", True, False),
    ("HT-VAL-003", "CCCD đủ 12 chữ số, mã tỉnh hợp lệ", "VALIDITY", "CEL_EXPRESSION", "so_cccd_me", "MAJOR", "BOTH", "1,1%", True, True),
    ("HT-ACC-004", "Ngày sinh không sau ngày đăng ký", "ACCURACY", "CEL_EXPRESSION", "ngay_sinh", "CRITICAL", "BOTH", "0,12%", True, True),
    ("HT-ACC-005", "Họ tên khớp CSDL dân cư", "ACCURACY", "EQ_SOURCE", "ho_ten", "MAJOR", "BATCH", "2,9%", True, True),
    ("HT-CON-001", "Mã xã thuộc đúng mã huyện", "CONSISTENCY", "EQ_FIELDS", "ma_dvhc_xa", "MAJOR", "BATCH", "0,4%", True, False),
    ("HT-CON-002", "Số CCCD có trong bản ghi vàng công dân", "CONSISTENCY", "CROSS_ENTITY", "so_cccd_me", "MINOR", "BATCH", "3,1%", True, False),
    ("HT-TIM-001", "Cập nhật trong 30 ngày", "TIMELINESS", "MAX_AGE_DAYS", "ngay_cap_nhat", "MINOR", "BATCH", "5,2%", False, False),
    ("HT-UNI-001", "Số đăng ký duy nhất", "UNIQUENESS", "UNIQUE_IN_ASSET", "so_dang_ky", "CRITICAL", "BATCH", "0,05%", True, True),
    ("HT-UNI-002", "Cặp (CCCD mẹ, ngày sinh) duy nhất", "UNIQUENESS", "UNIQUE_COMPOSITE", "so_cccd_me, ngay_sinh", "MAJOR", "BATCH", "0,3%", True, False),
]
MODE = {"BATCH": tag("mute", "Lô"), "INLINE": tag("info", "Trực tuyến"), "BOTH": tag("com", "Lô + trực tuyến")}


def rule_rows(state="a"):
    rows, cls = [], []
    for i, r in enumerate(RULES):
        dry = f"<span class='up'>✓</span> {r[7]}" if r[8] else "<span class='muted'>— tắt</span>"
        c = None
        if state == "b":
            if r[0] == "HT-ACC-004":
                dry = "<span style='color:#7a5200'>◔ sửa 14:52, chưa chạy thử</span>"
            if r[0] == "HT-CON-001":
                dry = "<span class='dn'>✕ ERR-08-116</span>"
                c = "d-del"
            if r[0] == "HT-ACC-005":
                dry = "<span style='color:#7a5200'>◔ chưa chạy thử</span>"
        rows.append([chk(False), sw(r[8]), f"<b class='mono'>{r[0]}</b> {tag('warn', 'CDE') if r[9] else ''}<div class='muted'>{r[1]} · <span class='mono'>{r[4]}</span></div>", dim(r[2]), f"<span class='mono'>{r[3]}</span>", sev(r[5]), MODE[r[6]], dry])
        cls.append(c)
    return rows, cls


def editor(state="a"):
    rows, cls = rule_rows(state)
    chips = '<div class="facets"><span class="on">Tất cả 12</span>' + "".join(f'<span><i style="display:inline-block;width:8px;height:8px;border-radius:2px;background:{c[2]};margin-right:5px"></i>{c[1]} {n}</span>' for c, n in zip(DIMS, [2, 2, 2, 1, 2, 3])) + '<span>Nghiêm trọng 3</span><span>Chỉ CDE 7</span></div>'
    if state == "b":
        chips = chips.replace('<span class="on">Tất cả 12</span>', '<span>Tất cả 12</span>').replace("Chính xác 2</span>", "Chính xác 2</span>", 1)
        chips = chips.replace("<span><i", '<span class="on"><i', 1) if False else chips
    return f"""
<div class="chrome" style="display:flex;align-items:center;gap:12px">
  <div><div class="crumb" style="margin:0">Bộ quy tắc › BQ-HO-TICH › ast-ho-tich-khai-sinh</div><h1 style="margin:2px 0 0">Bộ quy tắc hộ tịch · phiên bản 7 {tag("mute", "○ Nháp")}</h1></div>
  <span class="sp" style="flex:1"></span><span class="muted">{"Sửa 14:52 · đã tự lưu" if state == "b" else "Đã tự lưu 14:35"}</span>
  {btn("So sánh với v6")}{btn("Chạy thử ▷")}{btn("Gửi duyệt", "dis") if state == "b" else btn("Gửi duyệt", "pri")}
</div>"""


def editor_body(state="a"):
    rows, cls = rule_rows(state)
    msg = (alert("e", "<b>Chạy thử phiên bản sau lần sửa cuối trước khi gửi duyệt.</b> Quy tắc HT-ACC-004 và HT-ACC-005 đã đổi sau lần chạy thử 14:35 (ERR-08-053).", "Chạy thử ngay")
           + alert("w", "Trường <span class='mono'>ma_huyen</span> không còn ở nguồn. Quy tắc HT-CON-001 không chạy được. (ERR-08-116)", "Sửa quy tắc")
           ) if state == "b" else alert("i", "Đã chạy thử nội dung hiện tại lúc 14:35 trên mẫu 10.000 bản ghi (seed 8812734690113): 11 quy tắc bật chạy được, 9 quy tắc có vi phạm.", "Xem kết quả chạy thử")
    chips = '<div class="facets"><span class="on">Tất cả 12</span>' 
    for c, n in zip(DIMS, [2, 2, 2, 1, 2, 3]):
        on = False
        chips += f'<span class="{"on" if on else ""}"><i style="display:inline-block;width:8px;height:8px;border-radius:2px;background:{c[2]};margin-right:5px"></i>{c[1]} {n}</span>'
    chips += '<span>Nghiêm trọng 3</span><span>Chỉ CDE 7</span><span>Lô 8 · Trực tuyến 0 · Cả hai 4</span></div>'
    if state == "b":  # trong bản b hiển thị đủ 12 dòng nhưng chip Chính xác chỉ để minh họa lọc, nên giữ nguyên danh sách
        pass
    side = card("Tóm tắt phiên bản", '<div class="muted" style="margin-bottom:6px">Độ phủ chiều (số quy tắc bật)</div>' + hbars([(DK[c][1], n, DK[c][2]) for c, n in [("COMPLETENESS", 2), ("ACCURACY", 2), ("CONSISTENCY", 2), ("TIMELINESS", 0), ("UNIQUENESS", 2), ("VALIDITY", 3)]], 4, w="80px 1fr 24px")
                + '<div class="warn" style="margin-top:8px">Chiều Kịp thời không có quy tắc bật: điểm chiều rỗng, đối tượng bị gắn cờ <span class="mono">INCOMPLETE_DIMENSIONS</span>.</div>'
                + '<dl class="dl" style="grid-template-columns:110px 1fr;margin-top:10px"><dt>CDE có quy tắc</dt><dd><b>6/7</b></dd><dt>Quy tắc bật</dt><dd>11 / 12</dd><dt>Chạy thử</dt><dd>' + ("<span class='dn'>Đã cũ (sửa sau 14:35)</span>" if state == "b" else "<span class='up'>✓ Hợp lệ 14:35</span>") + '</dd><dt>Người soạn</dt><dd>Nguyễn Thị Lan</dd><dt>Duyệt bởi</dt><dd class="muted">Chưa gửi</dd></dl>')
    side2 = card("Kiểm tra trước khi gửi", ("<div class='err-t'>✕ Chạy thử đã cũ</div><div class='err-t'>✕ HT-CON-001 không chạy được</div><div class='ok-t'>✓ Có ít nhất một quy tắc bật</div><div class='ok-t'>✓ Mọi quy tắc Hợp lệ có danh mục PH-07</div>" if state == "b" else "<div class='ok-t'>✓ Chạy thử hợp lệ</div><div class='ok-t'>✓ Có ít nhất một quy tắc bật</div><div class='ok-t'>✓ Mọi quy tắc Hợp lệ có danh mục PH-07</div><div style='color:#7a5200;font-size:12px;margin-top:3px'>⚠ CDE so_dien_thoai_me chưa có quy tắc (không chặn)</div>"))
    return f"""{editor(state)}{msg}
<div class="cols2" style="grid-template-columns:minmax(0,3.2fr) minmax(0,1fr);margin-top:12px">
  <div class="card">{chips}
    <div class="toolbar"><span class="input">Tìm quy tắc ⌕</span><span class="btn">+ Thêm quy tắc ▾</span><span class="btn">Từ thư viện mẫu</span><span class="btn">Từ gợi ý hồ sơ (5)</span><span class="sp" style="flex:1"></span><span class="muted">Bấm dòng để mở ngăn kéo quy tắc (UI-08-08)</span></div>
    {table(["", "Bật", "Quy tắc, trường", "Chiều", "Toán tử", "Mức", "Chế độ", "Chạy thử (tỷ lệ lỗi)"], rows, "Quy tắc của bản nháp", cls)}
  </div>
  <div>{side}<div style="height:10px"></div>{side2}</div>
</div>"""


P["07"] = ("Trình soạn bộ quy tắc", CR + " › Bộ quy tắc › BQ-HO-TICH › Soạn phiên bản 7", editor_body("a"))
P["07b"] = ("Trình soạn bộ quy tắc, chưa chạy thử lại", CR + " › Bộ quy tắc › BQ-HO-TICH › Soạn phiên bản 7", editor_body("b"))

# ------------------------------------------------------------------ 08 Ngăn kéo quy tắc và chạy thử
inner = f"""
{tabs(["Biểu mẫu", "Biểu thức CEL", "Chạy thử"], 1)}
<div class="row"><div class="field"><label>Mã quy tắc *</label><span class="input mono">HT-VAL-003</span></div><div class="field"><label>Mức nghiêm trọng *</label><span class="input">Đáng kể ▾</span></div></div>
<div class="field"><label>Tên quy tắc *</label><span class="input">CCCD đủ 12 chữ số, mã tỉnh hợp lệ</span></div>
<div class="row"><div class="field"><label>Chiều *</label><span class="input">Hợp lệ ▾</span></div><div class="field"><label>Toán tử *</label><span class="input mono">CEL_EXPRESSION ▾</span></div><div class="field"><label>Chế độ chạy</label><span class="input">Lô + trực tuyến ▾</span></div></div>
<div class="field"><label>Trường áp dụng *</label><span class="input mono">so_cccd_me</span></div>
<div class="field"><label>Biểu thức CEL (trả về true khi bản ghi đạt) *</label>
<div class="cel"><span class="k">has</span>(record.so_cccd_me) &amp;&amp;
record.so_cccd_me.<span class="e">matchs</span>(<span class="s">'^[0-9]{{12}}$'</span>) &amp;&amp;
record.so_cccd_me.substring(0, 3) <span class="k">in</span> provinceCodes</div>
<div class="err-t">✕ Biểu thức không hợp lệ ở vị trí 2:21: hàm matchs không tồn tại (có phải matches). (ERR-08-019)</div>
<div class="muted" style="margin-top:4px">CEL chạy trực tuyến phải dưới giới hạn chi phí; danh sách <span class="mono">provinceCodes</span> lấy từ danh mục PH-07 DM_DVHC.</div></div>
<div class="card raised" style="margin-bottom:10px"><b style="font-size:13px">Kết quả chạy thử gần nhất (14:35, nội dung cũ)</b>
<div class="muted" style="margin:4px 0">Mẫu 10.000 bản ghi · vi phạm 110 (1,1%) · thời gian 0,8 giây</div>
<table><thead><tr><th>Khóa bản ghi</th><th>Giá trị (đã che)</th><th>Lý do</th></tr></thead><tbody><tr><td class="mono">KS-2026-0412207</td><td class="mono">●●●●●●●●●●●●</td><td>Mã tỉnh ngoài danh mục</td></tr><tr><td class="mono">KS-2026-0771290</td><td class="mono">●●●●●●●●●●●</td><td>Thiếu 1 chữ số</td></tr><tr><td class="mono">KS-2026-1190382</td><td class="mono">●●●●●●●●●●●●●</td><td>Thừa 1 chữ số</td></tr></tbody></table>
<div class="muted" style="margin-top:4px">Sửa biểu thức làm kết quả chạy thử mất hiệu lực (BR-08-006).</div></div>
<div class="foot"><span class="muted" style="flex:1;text-align:left">Chạy thử tối đa 10.000 bản ghi (ERR-08-031)</span>{btn("Hủy")}{btn("Chạy thử ▷")}{btn("Lưu quy tắc", "dis")}</div>
"""
base = editor_body("a")
P["08"] = ("Ngăn kéo quy tắc, trình soạn CEL và chạy thử", CR + " › Bộ quy tắc › BQ-HO-TICH › Soạn phiên bản 7 › HT-VAL-003",
           f'<div class="dim-bg">{base}</div>', drawer("Quy tắc HT-VAL-003", inner, 560))

# ------------------------------------------------------------------ 09 Lịch sử, so sánh, duyệt
vers = [("v7", "Chờ duyệt", "warn", "Nguyễn Thị Lan · gửi 26/11 14:40", True), ("v6", "Hiệu lực", "ok", "Duyệt 02/10 · Trần Minh Quân", False), ("v5", "Đã thay", "mute", "Duyệt 04/08", False), ("v4", "Đã thay", "mute", "Duyệt 11/06", False), ("v3", "Đã thay", "mute", "Duyệt 02/04", False)]
vl = "".join(f'<div class="node2 {"on" if v[4] else ""}"><div style="display:flex;justify-content:space-between"><b>{v[0]}</b>{tag(v[2], v[1])}</div><div class="muted">{v[3]}</div></div>' for v in vers)
dif = table(["Thay đổi", "Quy tắc", "Chiều", "Nội dung thay đổi"],
            [[tag("ok", "+ Thêm"), "<span class='mono'>HT-VAL-003</span>", dim("VALIDITY"), "CCCD đủ 12 chữ số, mã tỉnh hợp lệ (CEL)"],
             [tag("ok", "+ Thêm"), "<span class='mono'>HT-UNI-002</span>", dim("UNIQUENESS"), "Cặp (CCCD mẹ, ngày sinh) duy nhất"],
             [tag("warn", "~ Sửa"), "<span class='mono'>HT-ACC-004</span>", dim("ACCURACY"), "Mức <del>Đáng kể</del> → <ins>Nghiêm trọng</ins>; biểu thức đổi sang so với ngày đăng ký"],
             [tag("warn", "~ Sửa"), "<span class='mono'>HT-COM-002</span>", dim("COMPLETENESS"), "Điều kiện <del>mẹ trên 18 tuổi</del> → <ins>mẹ còn sống</ins>"],
             [tag("err", "− Bỏ"), "<span class='mono'>HT-TIM-002</span>", dim("TIMELINESS"), "<del>Đăng ký trong 60 ngày kể từ sinh</del> (gộp vào HT-TIM-001)"]],
            "So sánh phiên bản 6 và 7", ["d-add", "d-add", "d-chg", "d-chg", "d-del"])
body = f"""
{head("Lịch sử và duyệt · BQ-HO-TICH", btn("Xuất YAML"), btn("Sao chép bộ"))}
<div class="cols3" style="grid-template-columns:230px minmax(0,1fr) 340px">
  <div>{card("Phiên bản", vl)}</div>
  <div>
    {card("So sánh phiên bản 6 (hiệu lực) với phiên bản 7 (chờ duyệt)", '<div class="muted" style="margin-bottom:8px">2 thêm · 2 sửa · 1 bỏ. Màu chỉ phụ trợ, mỗi dòng có nhãn chữ Thêm, Sửa, Bỏ.</div>' + dif)}
    <div style="height:12px"></div>
    {card("Tác động ước tính (chạy thử trên mẫu 100.000 bản ghi)", table(["Chỉ số", "v6", "v7", "Chênh"], [["Điểm đối tượng", "77,9", "75,8", '<span class="dn">▼ −2,1</span>'], ["Chiều Hợp lệ", "84,1", "80,4", '<span class="dn">▼ −3,7</span>'], ["Lỗi Nghiêm trọng", "1.212", "1.640", '<span class="dn">▲ +428</span>'], ["Kết luận", verdict("WARN"), verdict("WARN"), "Không đổi"]], "Tác động ước tính của phiên bản 7", num=(1, 2, 3)))}
  </div>
  <div>
    <div class="chrome" style="margin:0">
      <b style="font-size:15px">Duyệt phiên bản 7</b>
      <dl class="dl" style="grid-template-columns:100px 1fr;margin:10px 0"><dt>Người soạn</dt><dd>Nguyễn Thị Lan (DS)</dd><dt>Gửi duyệt</dt><dd>26/11 14:40</dd><dt>Người duyệt</dt><dd>Trần Minh Quân (DA)</dd><dt>Chạy thử</dt><dd><span class="up">✓ 14:35, khớp nội dung</span></dd></dl>
      <div class="field"><label>Lý do duyệt hoặc từ chối *</label><span class="input" style="height:64px;align-items:flex-start;padding-top:8px;white-space:normal">Tăng mức HT-ACC-004 vì sai ngày sinh ảnh hưởng cấp giấy tờ…</span><div class="muted" style="margin-top:3px">Bắt buộc khi từ chối. Tối thiểu 20 ký tự.</div></div>
      <div style="display:flex;gap:8px"><span class="btn ok wide">Duyệt</span><span class="btn danger wide">Từ chối</span></div>
      <div class="muted" style="margin-top:10px">Người soạn hoặc người gửi duyệt thấy nút Duyệt bị vô hiệu kèm câu: "Anh/chị là người soạn hoặc gửi duyệt nên không được tự duyệt." (ERR-08-005)</div>
      <div class="muted" style="margin-top:6px">Sau khi duyệt, chọn <b>Kích hoạt ngay</b> hoặc đặt ngày hiệu lực; v6 chuyển Đã thay.</div>
    </div>
  </div>
</div>"""
P["09"] = ("Lịch sử, so sánh và duyệt phiên bản", CR + " › Bộ quy tắc › BQ-HO-TICH › Lịch sử", body)

# ------------------------------------------------------------------ 10 Trọng số và ngưỡng
W = [("COMPLETENESS", 0.20, 0.20), ("ACCURACY", 0.20, 0.25), ("CONSISTENCY", 0.15, 0.15), ("TIMELINESS", 0.10, 0.10), ("UNIQUENESS", 0.15, 0.10), ("VALIDITY", 0.20, 0.20)]
sl = ""
for c, old, new in W:
    ch = " <span class='tag t-warn'>đổi</span>" if old != new else ""
    sl += f'<div style="display:grid;grid-template-columns:120px 1fr 80px 70px;gap:12px;align-items:center;margin:12px 0"><span>{dim(c)}</span><div class="slider" style="margin:0"><div style="position:absolute;left:0;top:0;bottom:0;width:{new * 100 / 0.4:.0f}%;background:{DK[c][2]};border-radius:3px;opacity:.5"></div><b style="left:calc({new * 100 / 0.4:.0f}% - 10px)"></b></div><span class="input num" style="min-width:0;justify-content:flex-end">{vn(new, 2)}</span><span class="muted">cũ {vn(old, 2)}{ch}</span></div>'
prev = table(["Phạm vi", "Điểm hiện tại", "Điểm với cấu hình mới", "Chênh", "Kết luận"],
             [["Toàn tỉnh", "78,6", "78,1", '<span class="dn">▼ −0,5</span>', verdict("WARN") + " → " + verdict("WARN")], ["Hộ tịch", "77,9", "77,1", '<span class="dn">▼ −0,8</span>', verdict("WARN") + " → " + verdict("WARN")],
              ["Doanh nghiệp", "84,5", "83,9", '<span class="dn">▼ −0,6</span>', verdict("PASS") + " → " + verdict("PASS")], ["Y tế", "68,3", "67,4", '<span class="dn">▼ −0,9</span>', verdict("FAIL") + " → " + verdict("FAIL")],
              ["Dân cư", "91,2", "91,0", '<span class="fl">▬ −0,2</span>', verdict("PASS") + " → " + verdict("PASS")]], "Xem trước tác động của trọng số", num=(1, 2, 3))
body = f"""
{head("Trọng số và ngưỡng", '<span class="seg"><span class="on">Toàn tỉnh</span><span>Theo miền</span><span>Theo đối tượng</span></span>', btn("Lưu nháp"), btn("Gửi duyệt", "pri"))}
<div class="cols2" style="grid-template-columns:minmax(0,1.5fr) minmax(0,1fr)">
  <div>
    {card("Trọng số sáu chiều · bản nháp v3 phạm vi toàn tỉnh", sl + '<div style="display:flex;gap:10px;align-items:center;border-top:1px solid #dde1e7;padding-top:10px"><b>Tổng trọng số</b><span class="vd pass">✓ 1,00</span><span class="muted">Phải bằng 1 (dung sai 0,001); mỗi trọng số trong 0…1.</span></div><div class="warn" style="margin-top:10px">Trọng số chiều Kịp thời là 0,10: đối tượng nào không có quy tắc chiều này vẫn bị gắn cờ thiếu chiều.</div>')}
    <div style="height:12px"></div>
    {card("Ngưỡng kết luận", '<div style="display:grid;grid-template-columns:1fr 1fr;gap:14px"><div class="field"><label>Ngưỡng Đạt (điểm ≥)</label><span class="input num">80</span><div class="muted">Hiện hành 80 · không đổi</div></div><div class="field"><label>Ngưỡng Cảnh báo (điểm ≥)</label><span class="input num">70</span><div class="muted">Hiện hành 70 · không đổi</div></div></div><div class="scorebar" style="border:0;padding:6px 0"><div class="meter" style="background:linear-gradient(90deg,#fde8e8 0 70%,#fff4d6 70% 80%,#e5f6ec 80% 100%)"><u style="left:70%">70</u><u style="left:80%">80</u></div></div><div class="muted" style="margin-top:14px">Không đạt: dưới 70 · Cảnh báo: từ 70 đến dưới 80 · Đạt: từ 80. Hạ ngưỡng Đạt buộc nhập lý do từ 20 ký tự.</div>')}
  </div>
  <div>
    {card("Xem trước tác động (không hồi tố)", prev + '<div class="muted" style="margin-top:6px">Tính trên ảnh chụp điểm tháng 11/2026. Điểm quá khứ không đổi; so kỳ khác cấu hình được gắn cờ <span class="mono">WEIGHTS_CHANGED</span>.</div>')}
    <div style="height:12px"></div>
    {card("Phiên bản và duyệt", '<div class="node2"><div style="display:flex;justify-content:space-between"><b>v3 · bản nháp</b>' + tag("mute", "Nháp") + '</div><div class="muted">Nguyễn Thị Lan · sửa 14:20</div></div><div class="node2"><div style="display:flex;justify-content:space-between"><b>v2 · hiệu lực</b>' + tag("ok", "Hiệu lực") + '</div><div class="muted">Từ 01/07/2026 · duyệt Trần Minh Quân</div></div><div class="node2"><div style="display:flex;justify-content:space-between"><b>v1 · đã thay</b>' + tag("mute", "Đã thay") + '</div><div class="muted">Mặc định hệ thống 0,20/0,20/0,15/0,10/0,15/0,20</div></div><div class="field" style="margin-top:8px"><label>Hiệu lực từ</label><span class="input">01/12/2026 ▾</span></div>')}
  </div>
</div>"""
P["10"] = ("Trọng số và ngưỡng", CR + " › Cài đặt › Trọng số và ngưỡng", body)
