from kit import *
from dat import *

P = {}

# ------------------------------------------------------------------ 07 Nhập số liệu tay
imp = table(["Dòng", "Chỉ tiêu", "Kỳ", "Giá trị", "Bằng chứng", "Kiểm tra"],
            [["2", mono("ket-noi-diem-diem-con-lai"), "M-2026-10", "118", "bien-ban-khao-sat-q3.pdf", state("ok", "VALID")],
             ["3", mono("so-giao-dien-quan-tri"), "M-2026-10", "1", "qd-1024.pdf", state("ok", "VALID")],
             ["4", mono("ho-so-cap-do-phe-duyet"), "M-2026-10", "Có", "—", state("err", "INVALID") + '<div class="err-t">Số liệu tay cần ít nhất một bằng chứng (tệp hoặc số văn bản).</div>'],
             ["5", mono("httt-tong-so"), "M-2026-10", "2000", "qd-2026-httt.pdf", state("err", "INVALID") + '<div class="err-t">Giá trị 2000 nằm ngoài miền cho phép của chỉ tiêu (0 đến 500).</div>'],
             ["6", mono("diem-hai-long-sus"), "M-2026-10", "—", "—", state("mute", "Bỏ trống")]], "Xem trước tệp nhập", cls=[None, None, "d-del", "d-del", None], num=(0, 3))
wait = table(["Chỉ tiêu", "Kỳ", "Giá trị", "Người nhập", "Trạng thái"],
             [[mono("ket-noi-diem-diem-con-lai"), "M-2026-09", "130", "Cán bộ tổng hợp A", state("warn", "Chờ xác nhận")], [mono("bi-mat-ngoai-kho"), "M-2026-10", "0", "Cán bộ tổng hợp A", state("warn", "Chờ xác nhận")],
              [mono("so-giao-dien-quan-tri"), "M-2026-09", "1", "Cán bộ tổng hợp B", state("ok", "Đã xác nhận")]], "Số liệu tay gần đây", num=(2,))
body = f"""
{head("Nhập số liệu tay", inp("Kỳ: M-2026-10 ▾"), btn("Tải tệp mẫu"), btn("Nhập trực tiếp"))}
{tabs(["Nhập tệp XLSX (bước 2/3: xem trước)", "Chờ xác nhận (2)", "Đã xử lý"], 0)}
{'<div class="steps"><div class="done">1 · Tải tệp ✓</div><div class="on">2 · Xem trước và sửa</div><div>3 · Xác nhận nhập</div></div>'}
<div class="cols2">
  <div>{card("Xem trước: so-lieu-tay-2026-10.xlsx (5 dòng · 3 hợp lệ · 2 lỗi)", imp + '<div class="muted" style="margin-top:6px">Chỉ nhập dòng hợp lệ. Dòng lỗi giữ lại để sửa rồi tải lại. Tệp vượt 2.000 dòng bị từ chối (ERR-16-020).</div>')}</div>
  <div>{card("Bằng chứng đính kèm", '<div style="border:2px dashed #b9c0ca;border-radius:10px;padding:14px;text-align:center;background:#fafbfc">Kéo tệp vào đây hoặc bấm để chọn<div class="muted">PDF, ảnh, XLSX, DOCX · tối đa 20 MB</div></div><div style="margin-top:8px"><span class="chip">bien-ban-khao-sat-q3.pdf · 1,2 MB</span><span class="chip">qd-1024.pdf · 0,6 MB</span></div>')}
  <div style="height:12px"></div>{card("Xác nhận số liệu tay (bốn mắt)", wait + '<div class="muted" style="margin-top:6px">Người nhập không tự xác nhận. Chỉ DS, SO, TO khác người nhập mới thấy nút "Xác nhận".</div>')}</div>
</div>
<div class="decide"><span class="muted">3 dòng hợp lệ sẽ được nhập ở trạng thái Nháp, gửi xác nhận sau.</span><span class="sp" style="flex:1"></span>{btn("Quay lại")}{btn("Nhập 3 dòng hợp lệ", "pri")}</div>"""
P["07"] = ("Nhập số liệu tay", CR + " › Nhập số liệu", body)

# ------------------------------------------------------------------ 08 Kỳ báo cáo
PER = [("M-2026-10", "MONTH", "COMPUTED", "95,8 %", "03/11 01:30", "—", 'cur'), ("M-2026-09", "MONTH", "CLOSED", "100 %", "05/10 01:30", "05/10 09:10", ""), ("Q-2026-Q3", "QUARTER", "CLOSED", "100 %", "05/10 01:35", "06/10 14:00", ""),
       ("M-2026-08", "MONTH", "REOPENED", "100 %", "12/10 10:02", "Mở lại 12/10", ""), ("M-2026-07", "MONTH", "CLOSED", "100 %", "05/08 01:30", "05/08 08:55", ""), ("Y-2025", "YEAR", "CLOSED", "100 %", "10/01 01:30", "12/01 10:00", "")]
PS = {"COMPUTED": state("info", "Đã tính"), "CLOSED": state("ok", "Đã chốt"), "REOPENED": state("warn", "Đã mở lại"), "COLLECTING": state("info", "Đang thu thập"), "OPEN": state("mute", "Đang mở")}
tb = table(["Kỳ", "Loại", "Trạng thái", "Độ đầy đủ", "Tổng hợp gần nhất", "Chốt lúc"], [[f"<b class='mono'>{p[0]}</b>", p[1], PS[p[2]], p[3], p[4], p[5]] for p in PER], "Kỳ báo cáo", cls=["list-sel", None, None, None, None, None], num=(3,))
tasks = '<div class="tasks" style="--n:6">' + "".join(f'<div class="task {c}">{t}</div>' for t, c in [("Thu thập", "ok"), ("Tính 24 chỉ tiêu", "ok"), ("Điểm nhóm", "ok"), ("Điểm tổng", "ok"), ("Cảnh báo chệch", "ok"), ("Ghi kết quả", "ok")]) + "</div>"
body = f"""
{head("Kỳ báo cáo và lần tổng hợp", btn("+ Tạo kỳ"), btn("Tổng hợp ngay", "pri"), btn("Chốt kỳ"))}
{tabs(["Kỳ báo cáo", "Lần tổng hợp", "Vận hành"], 0)}
<div class="cols2">
  <div class="card">{tb}{foot("Hiển thị 1–6 trong 14 kỳ")}</div>
  <div>{card("Kỳ M-2026-10 · Đã tính, chưa chốt", '<dl class="dl" style="grid-template-columns:130px 1fr"><dt>Hạn chốt</dt><dd>05/11/2026 (16.period.close-day)</dd><dt>Lần tổng hợp</dt><dd>#41 · LỊCH · thành công · 4 phút 12 giây</dd><dt>Độ đầy đủ</dt><dd><b>23 / 24</b> chỉ tiêu · cờ <span class="mono">MANUAL_PENDING</span></dd><dt>Báo cáo</dt><dd>bc-thang-2026-10 (nháp)</dd></dl>' + tasks
        + '<div class="alert w" style="margin:10px 0 0"><span>Chưa chốt được kỳ M-2026-10: còn 1 số liệu tay chờ xác nhận.</span></div>')}
  <div style="height:12px"></div>{card("Lịch tổng hợp", '<div class="muted">Tự động 01:30 hằng ngày cho kỳ chưa chốt (<span class="mono">16.aggregate.cron</span>) · tự tính lại khi có số trễ, gom 5 phút.</div>')}</div>
</div>"""
P["08"] = ("Kỳ báo cáo và lần tổng hợp", CR + " › Kỳ báo cáo", body)

# ------------------------------------------------------------------ 09 Chi tiết lần tổng hợp
vals = []
for c in ["bi-mat-ngoai-kho", "diem-hai-long-sus", "thoi-gian-khoi-tao-tenant", "mttr-muc-1", "httt-ket-noi-ty-le", "ket-noi-diem-diem-con-lai", "diem-chat-luong-du-lieu"]:
    i = [x for x in IND if x[0] == c][0]
    flag = {"bi-mat-ngoai-kho": state("warn", "MANUAL_PENDING"), "diem-hai-long-sus": state("mute", "MISSING_SOURCE"), "thoi-gian-khoi-tao-tenant": state("err", "STALE_SOURCE")}.get(c, "—")
    note = {"bi-mat-ngoai-kho": "Chỉ tiêu bi-mat-ngoai-kho chờ xác nhận số liệu tay.", "diem-hai-long-sus": "Thiếu số liệu từ Nhập tay cho kỳ M-2026-10.", "thoi-gian-khoi-tao-tenant": "Thiếu số liệu từ ph20-tenant cho kỳ M-2026-10."}.get(c, "")
    vals.append([f"<b>{i[1]}</b><div class='muted mono'>{c}</div>", f"<b class='num'>{i[6]}</b> {i[5]}", st(i[8]), i[10], flag, f"<span class='muted'>{note}</span>"])
tb = table(["Chỉ tiêu", "Giá trị", "Trạng thái", "Đầy đủ", "Cờ", "Ghi chú"], vals, "Giá trị chỉ tiêu", num=(1,))
body = f"""
{head("Lần tổng hợp #41 · kỳ M-2026-10", state("ok", "Thành công"), '<span class="muted">LỊCH · 03/11 01:26 → 01:30 · 4 phút 12 giây · công thức theo phiên bản có hiệu lực</span>', btn("Tính lại kỳ", "pri"))}
{kpis([kpi("Độ đầy đủ", "95,8 %", "23 / 24 chỉ tiêu có số"), kpi("Cờ thiếu nguồn", "2", "MISSING_SOURCE 1 · STALE_SOURCE 1"), kpi("Chờ xác nhận tay", "1", "MANUAL_PENDING"), kpi("Lỗi công thức", "0", "FORMULA_ERROR")], 4)}
{card("Giá trị chỉ tiêu của lần tổng hợp", '<div class="toolbar">' + inp("Trạng thái: Tất cả ▾") + inp("Cờ: Có cờ ▾") + inp("Nhóm: Tất cả ▾") + '</div>' + tb + '<div class="muted" style="margin-top:6px">Bấm giá trị để mở dòng truy nguồn: quan sát và phiên bản công thức đã dùng (API-16-054).</div>')}"""
P["09"] = ("Chi tiết lần tổng hợp", CR + " › Kỳ báo cáo › M-2026-10 › Lần tổng hợp #41", body)

# ------------------------------------------------------------------ 10 Danh sách báo cáo
RB = {"DRAFT": state("mute", "Nháp"), "IN_REVIEW": state("info", "Đang duyệt"), "CHANGES_REQUESTED": state("warn", "Cần sửa"), "APPROVED": state("ok", "Đã duyệt"), "PUBLISHED": state("ok", "Đã công bố"), "SUPERSEDED": state("mute", "Đã thay thế"), "WITHDRAWN": state("err", "Đã rút")}
rep = [("bc-thang-2026-10", "Báo cáo tháng 10/2026", "PERIODIC", "M-2026-10", "DRAFT", "v1", "—"), ("bc-thang-2026-09", "Báo cáo tháng 9/2026", "PERIODIC", "M-2026-09", "PUBLISHED", "v2", "08/10/2026"),
       ("bc-quy-2026-q3", "Báo cáo quý III/2026", "PERIODIC", "Q-2026-Q3", "PUBLISHED", "v1", "09/10/2026"), ("bc-thang-2026-08", "Báo cáo tháng 8/2026", "PERIODIC", "M-2026-08", "SUPERSEDED", "v1", "09/09/2026"),
       ("bc-dot-xuat-2026-05", "Báo cáo đột xuất 05/2026", "AD_HOC", "01/05–31/05", "IN_REVIEW", "v1", "—"), ("bc-thang-2026-07", "Báo cáo tháng 7/2026", "PERIODIC", "M-2026-07", "WITHDRAWN", "v1", "08/08/2026")]
tb = table(["Mã báo cáo", "Tên", "Loại", "Kỳ", "Trạng thái", "Phiên bản", "Công bố"], [[f"<b class='mono'>{r[0]}</b>", r[1], mono(r[2]), r[3], RB[r[4]], r[5], r[6]] for r in rep], "Danh sách báo cáo")
body = f"""
{head("Báo cáo", btn("Xuất danh sách"), btn("+ Báo cáo đột xuất"), btn("Lập báo cáo kỳ…", "pri"))}
{facets(["Tất cả", "Nháp 1", "Đang duyệt 1", "Đã công bố 2", "Đã thay thế 1", "Đã rút 1"])}
<div class="card"><div class="toolbar">{inp("Tìm mã, tên… ", "width:240px")}{inp("Loại: Tất cả ▾")}{inp("Kỳ: 2026 ▾")}{inp("Trạng thái: Tất cả ▾")}</div>{tb}{foot("Hiển thị 1–6 trong 11 báo cáo")}</div>
<div class="card" style="margin-top:12px"><b>bc-thang-2026-09 · bản công bố v2</b> {RB["PUBLISHED"]}<div class="muted" style="margin:6px 0">Mã băm <span class="mono">sha256:9c41…e7b2</span> · ký số 08/10/2026 09:12 · lưu WORM 10 năm · thay bản v1 (đính chính số liệu KPI-07)</div>{btn("Tải PDF ký số")} {btn("Tải bằng chứng")} {btn("Xuất XLSX")} {btn("Đính chính")} {btn("Rút", "danger")}</div>"""
P["10"] = ("Danh sách báo cáo", CR + " › Báo cáo", body)

# ------------------------------------------------------------------ 11 Soạn báo cáo
toc = [("1. Tóm tắt điều hành", ""), ("2. Nhóm Kết nối", "2"), ("3. Nhóm Chia sẻ", "2"), ("4. Nhóm Dữ liệu", "1"), ("5. Nhóm Vận hành", "1"), ("6. Nhóm Kiến trúc", ""), ("7. Biểu đồ xu hướng", ""), ("8. Thuyết minh chung", ""), ("Phụ lục: bảng 24 chỉ tiêu", "")]
tocs = "".join(f'<div class="{"on" if i == 1 else ""}" style="display:flex;justify-content:space-between;padding:6px 8px">{t}{"<span class=tag t-err>" + b + "</span>" if b else ""}</div>'.replace('<span class=tag t-err>', '<span class="tag t-err">') for i, (t, b) in enumerate(toc))
page = f"""<div style="background:#fff;border:1px solid #cfd5de;box-shadow:0 2px 8px rgba(20,40,80,.1);padding:26px 32px;font-family:Georgia,'Times New Roman',serif;font-size:13px;line-height:1.5;color:#111">
<div style="display:flex;justify-content:space-between;font-size:12px"><div style="text-align:center"><b>ỦY BAN NHÂN DÂN TỈNH T68</b><br>SỞ KHOA HỌC VÀ CÔNG NGHỆ T68<br>Số: …/BC-SKHCN</div><div style="text-align:center"><b>CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM</b><br>Độc lập – Tự do – Hạnh phúc</div></div>
<h3 style="text-align:center;margin:14px 0 4px">BÁO CÁO CHỈ TIÊU CHIA SẺ DỮ LIỆU THÁNG 10/2026</h3><div style="text-align:center" class="muted">Kỳ M-2026-10 · Điểm tổng 77,7 · 24 chỉ tiêu</div>
<h4 style="margin:12px 0 4px;font-family:sans-serif">2. Nhóm Kết nối</h4>
<table style="font-family:sans-serif;font-size:12px"><thead><tr><th>Chỉ tiêu</th><th class="num">Giá trị</th><th>Mục tiêu</th><th>Trạng thái</th></tr></thead><tbody>
<tr><td>Tỷ lệ HTTT kết nối chia sẻ</td><td class="num">31,0 %</td><td>≥ 40</td><td>{st("AT_RISK")}</td></tr>
<tr class="d-chg"><td>Kết nối điểm–điểm còn lại</td><td class="num">118</td><td>≤ 90</td><td>{st("OFF_TRACK")}</td></tr>
<tr><td>Thời gian kết nạp HTTT</td><td class="num">9,5 ngày</td><td>≤ 10</td><td>{st("ON_TRACK")}</td></tr></tbody></table>
<div style="margin-top:8px;border:2px solid #0b5cd5;border-radius:8px;padding:8px 10px;background:#f4f8ff;font-family:sans-serif;font-size:12.5px"><b>Giải trình: Kết nối điểm–điểm còn lại (chệch mục tiêu)</b>
<div style="margin-top:4px"><span class="muted">Nguyên nhân</span> Sáu HTTT của ngành y tế chưa hoàn tất nâng cấp dịch vụ web.</div><div><span class="muted">Biện pháp</span> Ký biên bản phối hợp với Sở Y tế, ưu tiên 12 kết nối trong tháng 11.</div><div><span class="muted">Hạn</span> 30/11/2026</div></div>
<h4 style="margin:12px 0 4px;font-family:sans-serif">3. Nhóm Chia sẻ</h4><div style="height:56px;background:linear-gradient(#f1f3f5,#f1f3f5);border-radius:6px" class="muted">… bảng 7 chỉ tiêu, còn 2 giải trình thiếu …</div></div>"""
body = f"""
{head("Soạn báo cáo bc-thang-2026-10", state("mute", "Nháp v1"), '<span class="muted ok-t">Đã lưu 14:36</span>', btn("Xem PDF thử"), btn("Lưu nháp"), btn("Gửi duyệt", "dis"))}
<div style="display:grid;grid-template-columns:230px minmax(0,1fr) 300px;gap:14px">
  <div class="card tree" style="padding:10px"><b>Các phần theo mẫu</b><div class="muted" style="margin:2px 0 6px">Mẫu mau-bc-thang v2</div>{tocs}<div class="muted" style="margin-top:8px">Huy hiệu đỏ: số chỉ tiêu chệch thiếu giải trình.</div></div>
  <div>{page}</div>
  <div>{card("Thông tin báo cáo", '<dl class="dl" style="grid-template-columns:96px 1fr;font-size:12.5px"><dt>Kỳ</dt><dd>M-2026-10 (chưa chốt)</dd><dt>Lần tổng hợp</dt><dd>#41 · 03/11 01:30</dd><dt>Độ đầy đủ</dt><dd>23 / 24</dd><dt>Số ký hiệu</dt><dd><span class="input" style="min-width:0;width:100%">…/BC-SKHCN</span></dd></dl>')}
  <div style="height:10px"></div><div class="alert w"><span><b>Số liệu kỳ đã được tính lại.</b> Lần tổng hợp #42 lúc 14:02 khác bản đang soạn 2 chỉ tiêu.</span></div>{btn("Làm mới số", "pri")}
  <div style="height:10px"></div>{card("Điều kiện gửi duyệt", '<div style="font-size:12.5px;line-height:1.7"><div class="ok-t">✓ Đủ số chỉ tiêu bắt buộc</div><div class="err-t" style="font-size:12.5px">✕ Còn 6 chỉ tiêu chệch hoặc thiếu số chưa có giải trình.</div><div class="muted">Kỳ chưa chốt: chỉ gửi báo cáo kỳ chính thức sau khi chốt.</div></div>')}</div>
</div>"""
P["11"] = ("Soạn báo cáo", CR + " › Báo cáo › bc-thang-2026-10 › Soạn", body)

# ------------------------------------------------------------------ 12 Duyệt và công bố
inbox = '<div class="card" style="padding:8px">' + "".join(f'<div class="{"list-sel" if i == 2 else ""}" style="padding:8px 10px;border-bottom:1px solid #eef0f3"><div style="display:flex;justify-content:space-between"><b>{a}</b>{t}</div><div class="muted">{b}</div></div>' for i, (a, t, b) in enumerate([
    ("Định nghĩa httt-ket-noi-ty-le v4", state("info", "Chỉ tiêu"), "Gửi bởi Cán bộ tổng hợp A · 03/11"), ("Số liệu ket-noi-diem-diem-con-lai (M-2026-09)", state("warn", "Số liệu tay"), "Gửi bởi Cán bộ tổng hợp A · 03/11"),
    ("Báo cáo bc-thang-2026-10 v1", state("ok", "Báo cáo"), "Gửi bởi Cán bộ tổng hợp B · 04/11"), ("Định nghĩa mttr-muc-1 v2 (nhận từ mẫu)", state("info", "Chỉ tiêu"), "Gửi bởi Quản trị tỉnh 2 · 02/11")])) + "</div>"
body = f"""
{head("Duyệt và công bố", '<span class="muted">4 việc chờ · của tôi 3</span>')}
{facets(["Tất cả 4", "Định nghĩa 2", "Số liệu tay 1", "Báo cáo 1"], 0)}
<div style="display:grid;grid-template-columns:360px minmax(0,1fr);gap:14px">
  <div>{inbox}</div>
  <div>{card("Báo cáo bc-thang-2026-10 v1 · Đang duyệt", '<div class="step"><div class="d">Nháp ✓</div><div class="c">Đang duyệt</div><div>Đã duyệt</div><div>Đã công bố</div></div>'
    + '<dl class="dl" style="grid-template-columns:120px 1fr 120px 1fr"><dt>Người lập</dt><dd>Cán bộ tổng hợp B</dd><dt>Kỳ</dt><dd>M-2026-10 (đã chốt 05/11)</dd><dt>Độ đầy đủ</dt><dd>23 / 24</dd><dt>Giải trình</dt><dd>6 / 6 đã nhập</dd></dl>'
    + '<div style="height:150px;margin:10px 0;background:#f4f6f9;border:1px solid #dde1e7;border-radius:8px;display:grid;place-items:center" class="muted">Bản xem trước PDF (trang 1 / 6)</div>'
    + '<div class="muted">Công bố sẽ chụp bất biến, ký số bằng chứng thư cơ quan và lưu WORM 10 năm (<span class="mono">16.report.retention-years</span>).</div>')}
  <div class="decide" style="margin-top:12px"><span class="alert e" style="margin:0;padding:4px 10px">Anh/chị là người lập hoặc gửi nên không được tự duyệt.</span><span class="sp" style="flex:1"></span>{btn("Yêu cầu sửa")}{btn("Duyệt", "dis")}{btn("Công bố", "dis")}</div>
  <div class="muted" style="margin-top:6px">Ví dụ nhìn từ tài khoản của người lập (Cán bộ tổng hợp B). Người duyệt khác (Quản trị tỉnh) thấy nút "Duyệt" sáng.</div></div>
</div>"""
P["12"] = ("Duyệt và công bố", CR + " › Duyệt", body)

# ------------------------------------------------------------------ 13 Mẫu báo cáo và phân phối
tpl = table(["Mã mẫu", "Tên", "Định dạng", "Số phần", "Trạng thái", "Phiên bản"], [[f"<b class='mono'>mau-bc-thang</b>", "Báo cáo tháng", "PDF, XLSX", "8", state("ok", "Đang dùng"), "v2"], [f"<b class='mono'>mau-bc-quy</b>", "Báo cáo quý", "PDF, XLSX", "9", state("ok", "Đang dùng"), "v1"], [f"<b class='mono'>mau-bc-dot-xuat</b>", "Báo cáo đột xuất", "PDF", "5", state("ok", "Đang dùng"), "v1"]], "Mẫu báo cáo")
dist = table(["Danh sách nhận", "Lịch", "Kèm", "Người nhận", "Lần gửi gần nhất"], [["<b>Lãnh đạo UBND</b>", "Sau công bố kỳ tháng", "Liên kết", "6", state("ok", "Đã gửi 08/10")], ["<b>Giám đốc các sở</b>", "Sau công bố kỳ quý", "PDF", "23", state("err", "Lỗi 2") + '<div class="err-t">Gửi tới so.yte@t68.gov.vn không thành công.</div>']], "Danh sách phân phối", num=(3,))
body = f"""
{head("Mẫu báo cáo và phân phối", btn("+ Tạo mẫu"), btn("+ Danh sách nhận", "pri"))}
{tabs(["Mẫu báo cáo", "Phân phối", "Lịch sử gửi"], 0)}
<div class="cols2">
  <div>{card("Mẫu báo cáo", tpl)}<div style="height:12px"></div>{card("Danh sách phân phối", dist)}</div>
  {card("Phần của mau-bc-thang v2", '<div class="node2"><b>1 · SUMMARY</b> Tóm tắt điều hành</div><div class="node2"><b>2–6 · GROUP</b> Năm nhóm, bảng chỉ tiêu</div><div class="node2 on"><b>7 · CHART</b> Xu hướng 13 kỳ (đường)</div><div class="node2"><b>8 · NARRATIVE</b> Thuyết minh chung</div><div class="node2"><b>9 · ANNEX</b> Bảng 24 chỉ tiêu</div><div class="muted">Kéo thả đổi thứ tự. Thiếu phần SUMMARY thì lưu bị từ chối (ERR-16-027).</div>')}
</div>"""
P["13"] = ("Mẫu báo cáo và phân phối", CR + " › Mẫu và phân phối", body)
