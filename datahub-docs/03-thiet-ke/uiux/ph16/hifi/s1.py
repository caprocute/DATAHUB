from kit import *
from dat import *

P = {}
COL = {g[0]: g[2] for g in GROUPS}


def gcard(g):
    code, name, col = g
    v, cov, d = GSC[code]
    n_bad = len([i for i in IND if i[3] == code and i[8] in ("AT_RISK", "OFF_TRACK")])
    part = '<span class="tag t-warn" style="margin-left:4px">Thiếu một phần</span>' if cov != f"{cov.split('/')[1]}/{cov.split('/')[1]}" else ""
    return (f'<div class="card" style="padding:10px 12px;border-top:4px solid {col}"><div style="display:flex;gap:10px;align-items:center">{ring(v, 84)}<div><b>{name}</b>'
            f'<div class="muted">Trọng số {WEIGHT[code]} %</div><div class="up" style="margin-top:2px">▲ +{d[1:]} so M-2026-09</div></div></div>'
            f'<div class="muted" style="margin-top:6px">Có số {cov} chỉ tiêu · {n_bad} cần chú ý {part}</div></div>')


def attn_rows(codes):
    rows = []
    for c in codes:
        i = [x for x in IND if x[0] == c][0]
        part = " " + partial() if i[10] == "PARTIAL" else ""
        rows.append([f"<b>{i[1]}</b><div class='muted mono'>{i[0]}</div>", grp(i[3]), f"<b class='num'>{i[6]}</b> {i[5]}", i[7], st(i[8]) + part, i[9]])
    return rows


# ------------------------------------------------------------------ 01 Tổng quan
att = table(["Chỉ tiêu", "Nhóm", "Giá trị", "Mục tiêu", "Trạng thái", "Δ so kỳ trước"],
            attn_rows(["mttr-muc-1", "ket-noi-diem-diem-con-lai", "httt-ket-noi-ty-le", "diem-chat-luong-du-lieu", "danh-muc-quan-ly-tap-trung", "api-dat-sla-ty-le", "diem-hai-long-sus"]),
            "Chỉ tiêu cần chú ý", num=(2,))
sers = [("Điểm tổng", TOTAL, "#1a1d23", "5 3")] + [(g[1], GSER[g[0]], g[2], "") for g in GROUPS]
chart = echart_line(sers, MONTHS, w=1000, h=250, ymin=40, ymax=90, marks=[(80, "Mục tiêu điểm 80", "#0b7a52")])
cnt = lambda s: len([i for i in IND if i[8] == s])
body = f"""
{alert("w", "<b>Kỳ M-2026-10 chưa chốt.</b> Số liệu còn có thể đổi đến ngày chốt 05/11. Nguồn <span class='mono'>ph13-kpi-sla</span> không có số mới từ 02/11 07:10 (ERR-16-107).", "Xem nguồn")}
{head("Tổng quan chỉ tiêu", inp("Kỳ: M-2026-10 · Tháng 10/2026 ▾"), '<span class="seg"><span>Chính thức</span><span class="on">Mới nhất</span></span>', btn("So sánh kỳ…"), btn("Xuất…"), '<span class="muted">Tổng hợp 03/11 01:30</span>')}
<div style="display:grid;grid-template-columns:1.25fr repeat(5,minmax(0,1fr));gap:10px;margin-bottom:12px">
  <div class="kpi" style="display:flex;gap:12px;align-items:center;padding:12px 14px"><div><span>Điểm tổng kỳ</span><div class="scorebig" style="color:#7a5200">77,7<small> / 100</small></div></div>
  <div style="font-size:13px">{st("AT_RISK")}<div class="up" style="margin-top:6px">▲ +1,3 so M-2026-09</div><div class="muted">Cùng kỳ năm trước 68,0</div></div></div>
  {"".join(gcard(g) for g in GROUPS)}
</div>
<div class="cols2" style="margin-bottom:12px">
  {card("Chỉ tiêu cần chú ý", att + '<div class="muted" style="margin-top:6px">Đỏ trước, vàng sau. Bấm dòng mở chi tiết chỉ tiêu. Còn 3 chỉ tiêu khác ở trạng thái Có nguy cơ: bấm "Xem tất cả".</div>')}
  {card("Trạng thái 24 chỉ tiêu", f'<div class="hbars">' + hbars([("● Đạt mục tiêu", cnt("ON_TRACK"), "#0b7a52"), ("▲ Có nguy cơ", cnt("AT_RISK"), "#c98a00"), ("✕ Chệch mục tiêu", cnt("OFF_TRACK"), "#c0392b"), ("– Chưa có số", cnt("NO_DATA"), "#8a919c")], maxv=24, w="130px 1fr 36px") + '</div>'
        + '<div class="muted" style="margin-top:10px">Độ đầy đủ của kỳ: <b>23 / 24</b> chỉ tiêu có số (95,8 %). Thiếu một phần: 1 (<span class="mono">bi-mat-ngoai-kho</span>, chờ cán bộ an toàn xác nhận). Chưa có số: 1 (<span class="mono">diem-hai-long-sus</span>).</div>'
        + '<div class="muted" style="margin-top:8px">Lọc nhanh:</div><div class="facets" style="margin-top:4px"><span class="on">Tất cả nhóm</span><span>Chỉ chệch mục tiêu</span><span>Thiếu số</span></div>')}
</div>
{card("Xu hướng 13 kỳ: điểm tổng và năm nhóm", chart + legend([("Điểm tổng (nét đứt)", "#1a1d23")] + [(g[1], g[2]) for g in GROUPS]) + '<div class="muted" style="margin-top:4px">Từ M-2025-10 đến M-2026-10. Có nút "Xem dạng bảng" cho trình đọc màn hình.</div>')}
"""
P["01"] = ("Tổng quan chỉ tiêu", CR + " › Tổng quan", body)

# ------------------------------------------------------------------ 02 Chi tiết chỉ tiêu
ser = [("Giá trị", [24.2, 24.9, 25.4, 26.1, 26.8, 27.4, 28.0, 28.6, 29.2, 29.9, 30.2, 27.5, 31.0], "#0b5cd5", "")]
ch = echart_line(ser, MONTHS, w=720, h=240, ymin=20, ymax=45, marks=[(40, "Mục tiêu 40 %", "#0b7a52"), (32, "Mốc vàng 32 %", "#c98a00")], area=True)
lin = table(["Quan sát", "Giá trị", "Thời điểm", "Nguồn", "Mã sự kiện"],
            [[mono("ph01.httt.connected"), "62", "03/11 01:30", "ph01-httt-event", mono("evt-0f3a91")],
             [mono("ph01.httt.total"), "200", "01/10 (nhập tay lần đầu)", "manual-httt-tong", mono("man-000214")]], "Dòng truy nguồn", num=(1,))
body = f"""
{head("Tỷ lệ HTTT kết nối chia sẻ", grp("KET_NOI"), st("AT_RISK"), partial() if False else "", '<span class="muted mono">httt-ket-noi-ty-le · KPI-01 · phiên bản 3</span>', btn("Xuất"), btn("Mở định nghĩa"))}
{tabs(["Chuỗi thời gian", "Định nghĩa", "Nguồn số liệu", "Quan sát"], 0)}
<div class="kpis" style="--n:5">
  {kpi("Giá trị kỳ M-2026-10", "31,0 %", "▲ +3,5 điểm so M-2026-09")}
  {kpi("Mục tiêu", "≥ 40 %", "Hạn: 31/12/2026 · mốc xanh 40 · vàng 32")}
  {kpi("Còn thiếu", "9,0 điểm", "Còn 2 kỳ đến hạn")}
  {kpi("Cùng kỳ năm trước", "24,2 %", "▲ +6,8 điểm")}
  {kpi("Độ đầy đủ", "Đủ", "Mẫu số 200 theo GĐ-04")}
</div>
<div class="cols2">
  {card("Chuỗi 13 kỳ và đường mục tiêu", ch + legend([("Giá trị", "#0b5cd5"), ("Mục tiêu 40", "#0b7a52"), ("Mốc vàng 32", "#c98a00")]) + '<div class="muted" style="margin-top:4px">Công thức: <span class="mono">obs("ph01.httt.connected") / obs("ph01.httt.total") * 100</span>, gộp qua kỳ <span class="mono">LAST</span>, làm tròn 1 chữ số.</div>')}
  <div>{card("Truy tới quan sát (dòng truy nguồn)", lin + '<div class="muted" style="margin-top:6px">Phiên bản công thức 3, hiệu lực từ 01/09/2026. Bấm quan sát để mở nhật ký tiếp nhận ở UI-16-06.</div>')}
  <div style="height:12px"></div>
  {card("Định nghĩa tóm tắt", '<dl class="dl" style="grid-template-columns:110px 1fr"><dt>Loại, chiều</dt><dd><span class="mono">RATIO</span>, tốt khi cao</dd><dt>Cách đo</dt><dd><span class="mono">AUTO</span> (mẫu số nhập tay)</dd><dt>Bắt buộc</dt><dd>Có, trong báo cáo chính thức</dd><dt>Nguồn</dt><dd>PH-01 (EVT-01-03)</dd></dl>')}</div>
</div>"""
P["02"] = ("Chi tiết chỉ tiêu", CR + " › Tổng quan › httt-ket-noi-ty-le", body)

# ------------------------------------------------------------------ 03 Bộ chỉ tiêu
rows = []
for i in IND[:14]:
    scope = state("com", "Mẫu COMMON") if i[0] in ("diem-chat-luong-du-lieu", "mttr-muc-1", "mttd") else state("local", "Tùy biến T68") if i[0] == "httt-ket-noi-ty-le" else state("com", "Mẫu COMMON")
    vs = "ACTIVE v3" if i[0] == "httt-ket-noi-ty-le" else "ACTIVE v1"
    rows.append([chk(), f"<b>{i[1]}</b><div class='muted mono'>{i[0]}</div>", i[2], grp(i[3]), state("mute", {"AUTO": "Tự động", "MANUAL": "Nhập tay", "MIXED": "Kết hợp"}[i[4]]), i[5], i[7], scope, state("ok", vs)])
rows.insert(2, [chk(), "<b>Điểm tín nhiệm số của HTTT</b><div class='muted mono'>diem-tin-nhiem-so</div>", "—", grp("KIEN_TRUC"), state("mute", "Tự động"), "điểm", "≥ 70", state("local", "Tùy biến T68"), state("warn", "Chờ duyệt v1")])
tb = table(["", "Chỉ tiêu", "KPI", "Nhóm", "Cách đo", "Đơn vị", "Mục tiêu", "Phạm vi", "Phiên bản"], rows, "Bộ chỉ tiêu")
body = f"""
{alert("i", "<b>Có 3 cập nhật mới từ bộ chỉ tiêu mẫu COMMON</b> (bản 2026-11). Bạn quyết định nhận hoặc bỏ qua từng cập nhật.", "Xem cập nhật mẫu")}
{head("Bộ chỉ tiêu", btn("Nhóm và trọng số"), btn("Nhận từ mẫu COMMON"), btn("+ Tạo chỉ tiêu", "pri"))}
{facets(["Tất cả 25", "Kết nối 4", "Chia sẻ 7", "Dữ liệu 3", "Vận hành 6", "Kiến trúc 5"])}
<div class="card"><div class="toolbar">{inp("Tìm mã, tên, KPI… ", "width:260px")}{inp("Trạng thái: Tất cả ▾")}{inp("Cách đo: Tất cả ▾")}{inp("Phạm vi: Tất cả ▾")}<span class="sp" style="flex:1"></span>{btn("Ngừng chỉ tiêu")}</div>
{tb}{foot("Hiển thị 1–15 trong 25 chỉ tiêu")}</div>"""
P["03"] = ("Bộ chỉ tiêu", CR + " › Bộ chỉ tiêu", body)

# ------------------------------------------------------------------ 04 Soạn định nghĩa
cel = '<div class="cel"><span class="k">obs</span>("ph01.httt.connected") /\n<span class="k">obs</span>("ph01.httt.total") * 100</div>'
dry = table(["Kỳ", "Giá trị tính", "Giá trị chính thức", "Chênh"], [["M-2026-08", "29,2", "29,2", "0"], ["M-2026-09", "27,5", "27,5", "0"], ["M-2026-10", "31,0", "31,0", "0"]], "Thử tính", num=(1, 2, 3))
body = f"""
{head("Soạn chỉ tiêu httt-ket-noi-ty-le", state("warn", "Bản nháp v4"), '<span class="muted">Đang sửa phiên bản 4 · <span class="ok-t">Đã lưu 14:21</span></span>', btn("Hủy bản nháp"), btn("Lưu nháp"), btn("Gửi duyệt", "dis"))}
{tabs(["Thông tin", "Công thức và thử tính", "Mục tiêu và ngưỡng", "Lịch sử phiên bản"], 1)}
<div class="cols2">
  <div>{card("Công thức CEL", cel + '<div class="muted" style="margin-top:6px">Biến quan sát dùng: <span class="mono">ph01.httt.connected</span> (nguồn ph01-httt-event), <span class="mono">ph01.httt.total</span> (nguồn manual-httt-tong). Cú pháp hợp lệ.</div>'
      + '<div class="alert e" style="margin:8px 0 0"><span>Thử tính phiên bản sau lần sửa cuối trước khi gửi duyệt.</span></div>')}
  <div style="height:12px"></div>{card("Thử tính trên dữ liệu kỳ trước", dry + '<div style="margin-top:8px">' + btn("Chạy thử tính", "pri") + '</div>')}</div>
  <div>{card("Biến quan sát khả dụng", table(["Biến", "Nguồn", "Độ tươi"], [[mono("ph01.httt.connected"), "ph01-httt-event", state("ok", "Đang hoạt động")], [mono("ph01.httt.total"), "manual-httt-tong", state("ok", "Đang hoạt động")], [mono("ph13.gateway.p95-ms"), "ph13-kpi-sla", state("warn", "Quá hạn")]], "Biến"))}
  <div style="height:12px"></div>{card("Ngưỡng và mục tiêu", '<dl class="dl" style="grid-template-columns:110px 1fr"><dt>Chiều tốt</dt><dd>Cao càng tốt</dd><dt>Mục tiêu</dt><dd>≥ 40 % trước 31/12/2026</dd><dt>Mốc xanh / vàng</dt><dd>40 / 32</dd><dt>Làm tròn</dt><dd>1 chữ số</dd></dl>')}</div>
</div>"""
P["04"] = ("Soạn định nghĩa chỉ tiêu", CR + " › Bộ chỉ tiêu › httt-ket-noi-ty-le › Soạn phiên bản 4", body)

# ------------------------------------------------------------------ 05 Nguồn số liệu
SRC = [("ph01-httt-event", "EVENT", "PH-01", "ACTIVE", "04/11 01:12", "0", "2"), ("ph02-api-stats", "PULL_API", "PH-02", "ACTIVE", "04/11 01:05", "0", "3"),
       ("ph13-kpi-sla", "PULL_API", "PH-13", "STALE", "02/11 07:10", "2", "6"), ("ph08-dq-kpi", "EVENT", "PH-08", "ACTIVE", "03/11 22:40", "0", "1"),
       ("ph19-doi-soat", "EVENT", "PH-19", "ACTIVE", "04/11 00:55", "0", "3"), ("ph07-danh-muc", "EVENT", "PH-07", "ACTIVE", "03/11 23:20", "0", "2"),
       ("ph20-tenant", "PUSH_API", "PH-20", "FAILED", "28/10 03:00", "3", "1"), ("manual-httt-tong", "MANUAL", "Cán bộ tổng hợp", "ACTIVE", "01/10 09:40", "0", "1"),
       ("ph12-secret-scan", "PULL_API", "PH-12", "PAUSED", "20/10 02:00", "0", "1")]
SS = {"ACTIVE": state("ok", "Đang hoạt động"), "STALE": state("warn", "Quá hạn"), "FAILED": state("err", "Lỗi"), "PAUSED": state("mute", "Tạm dừng")}
tb = table(["Mã nguồn", "Loại", "Phân hệ", "Trạng thái", "Số mới nhất", "Lần lỗi", "Chỉ tiêu dùng"],
           [[f"<b class='mono'>{s[0]}</b>", mono(s[1]), s[2], SS[s[3]], s[4], s[5], s[6]] for s in SRC], "Nguồn số liệu", num=(5, 6))
body = f"""
{banner("e", "Nguồn ph20-tenant lỗi 3 lần liên tiếp, đã chuyển trạng thái Lỗi. Chỉ tiêu thoi-gian-khoi-tao-tenant thiếu số kỳ này.", "Mở nguồn")}
{head("Nguồn số liệu", btn("Tải lại"), btn("+ Đăng ký nguồn", "pri"))}
{kpis([kpi("Đang hoạt động", "6", "trong 9 nguồn"), kpi("Quá hạn", "1", "ph13-kpi-sla · ngưỡng 26 giờ"), kpi("Lỗi", "1", "ph20-tenant"), kpi("Tạm dừng", "1", "ph12-secret-scan")], 4)}
{facets(["Tất cả 9", "Tự động 8", "Nhập tay 1", "Quá hạn hoặc lỗi 2"], 0)}
<div class="card"><div class="toolbar">{inp("Tìm mã nguồn… ", "width:240px")}{inp("Loại: Tất cả ▾")}{inp("Phân hệ: Tất cả ▾")}{inp("Trạng thái: Tất cả ▾")}</div>{tb}{foot("Hiển thị 1–9 trong 9 nguồn")}</div>"""
P["05"] = ("Nguồn số liệu", CR + " › Nguồn số liệu", body)

# ------------------------------------------------------------------ 06 Chi tiết nguồn
logrows = [["04/11 01:12", state("ok", "ACCEPTED"), mono("ph01.httt.connected"), "62", mono("evt-0f3a91"), "—"],
           ["04/11 01:12", state("ok", "ACCEPTED"), mono("ph01.httt.api-bound"), "41", mono("evt-0f3a92"), "—"],
           ["04/11 00:40", state("mute", "DUPLICATE"), mono("ph01.httt.connected"), "62", mono("evt-0f3a91"), "Đã có cùng mã sự kiện"],
           ["03/11 23:58", state("err", "REJECTED"), mono("ph01.httt.total"), "abc", mono("evt-0f3a77"), "ERR-16-105 sai lược đồ"],
           ["03/11 23:10", state("err", "REJECTED"), mono("ph01.hethong.khac"), "5", mono("evt-0f3a70"), "ERR-16-102 ngoài hợp đồng"]]
tb = table(["Thời điểm", "Kết quả", "Chỉ số", "Giá trị", "Mã sự kiện", "Ghi chú"], logrows, "Nhật ký tiếp nhận", num=(3,))
body = f"""
{head("Nguồn ph01-httt-event", state("ok", "Đang hoạt động"), '<span class="muted">EVENT · PH-01 · hợp đồng 3 chỉ số</span>', btn("Tạm dừng"), btn("Kéo ngay", "dis"), btn("Thử nguồn"))}
{tabs(["Nhật ký tiếp nhận", "Bị loại", "Hợp đồng chỉ số", "Cấu hình"], 0)}
{kpis([kpi("Quan sát nhận 24 giờ", "1.204", "▲ so hôm trước"), kpi("Bị loại 24 giờ", "2", "ERR-16-105, 102"), kpi("Độ tươi", "2 giờ 20", "Ngưỡng 26 giờ"), kpi("Lần kéo lỗi liên tiếp", "0", "Ngưỡng 3")], 4)}
<div class="card"><div class="toolbar">{inp("Kết quả: Tất cả ▾")}{inp("Chỉ số: Tất cả ▾")}{inp("Từ 03/11 ▾")}<span class="sp" style="flex:1"></span>{btn("Xử lý lại các dòng bị loại")}</div>{tb}{foot("Hiển thị 1–5 · làm mới 30 giây")}</div>"""
P["06"] = ("Chi tiết nguồn, nhật ký tiếp nhận", CR + " › Nguồn số liệu › ph01-httt-event", body)
