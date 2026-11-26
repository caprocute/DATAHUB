from kit import *
from dat import *

P = {}
LC = {"PLANNED": state("mute", "Dự kiến"), "ACTIVE": state("ok", "Đang hoạt động"), "DEPRECATED": state("warn", "Sắp ngừng"), "RETIRED": state("mute", "Đã ngừng")}
OP = {"UP": state("ok", "● Chạy tốt"), "DEGRADED": state("warn", "▲ Suy giảm"), "DOWN": state("err", "✕ Ngừng"), "UNKNOWN": state("mute", "? Chưa rõ")}
CL = {"COMPLIANT": state("ok", "Tuân thủ"), "PARTIAL": state("warn", "Một phần"), "NON_COMPLIANT": state("err", "Không tuân thủ"), "EXEMPTED": state("info", "Được miễn trừ"), "NOT_ASSESSED": state("mute", "Chưa đánh giá")}
COMP = [("httt-qlvb", "Hệ thống quản lý văn bản", "HTTT", "ACTIVE", "UP", "COMPLIANT", "AUTO"), ("httt-dvc", "Cổng dịch vụ công", "HTTT", "ACTIVE", "DEGRADED", "PARTIAL", "AUTO"),
        ("api-tra-cuu-thua-dat", "API tra cứu thửa đất", "API", "ACTIVE", "UP", "COMPLIANT", "AUTO"), ("flow-dong-bo-ho-tich", "Luồng đồng bộ hộ tịch", "FLOW", "ACTIVE", "UP", "NOT_ASSESSED", "AUTO"),
        ("topic-t68-kpi-report", "Topic t68.kpi.report.published.v1", "TOPIC", "ACTIVE", "UP", "COMPLIANT", "AUTO"), ("adapter-soap-so-yte", "Bộ điều hợp SOAP Sở Y tế", "ADAPTER", "DEPRECATED", "DOWN", "NON_COMPLIANT", "AUTO"),
        ("svc-gateway-apisix", "Gateway APISIX", "PLATFORM_SERVICE", "ACTIVE", "UP", "EXEMPTED", "MANUAL"), ("link-lgsp-quoc-gia", "Kết nối trục quốc gia", "NATIONAL_LINK", "ACTIVE", "UNKNOWN", "NOT_ASSESSED", "MANUAL")]
tb = table(["", "Thành phần", "Loại", "Vòng đời", "Vận hành", "Tuân thủ", "Nguồn gốc"], [[chk(), f"<b>{c[1]}</b><div class='muted mono'>{c[0]}</div>", mono(c[2]), LC[c[3]], OP[c[4]], CL[c[5]], mono(c[6])] for c in COMP], "Sổ kiến trúc")
body = f"""
{alert("w", "<b>3 thành phần lệch với phân hệ nguồn</b> (1 thiếu, 1 mồ côi, 1 khác phiên bản). Mở tab Lệch để xử lý.", "Xem tab Lệch")}
{head("Sổ kiến trúc", btn("Đối chiếu ngay"), btn("Xuất sổ"), btn("+ Khai báo thành phần", "pri"))}
{kpis([kpi("Thành phần", "60", "▲ 4 trong tháng"), kpi("Đã đánh giá tuân thủ", "41 / 60", "68,3 % · mục tiêu ≥ 80 %"), kpi("Không tuân thủ", "5", "2 đã có kế hoạch"), kpi("Chưa rõ vận hành", "3", "ERR-16-121")], 4)}
{tabs(["Thành phần", "Lệch (3)", "Phụ thuộc"], 0)}
{facets(["Tất cả 60", "HTTT 18", "API 21", "FLOW 9", "TOPIC 6", "Khác 6"])}
<div class="card"><div class="toolbar">{inp("Tìm mã, tên… ", "width:240px")}{inp("Vòng đời: Tất cả ▾")}{inp("Tuân thủ: Tất cả ▾")}{inp("Nguồn gốc: Tất cả ▾")}</div>{tb}{foot("Hiển thị 1–8 trong 60 thành phần")}</div>"""
P["14"] = ("Sổ kiến trúc", CR + " › Sổ kiến trúc", body)

# ------------------------------------------------------------------ 15 Chi tiết thành phần
dep = ('<svg viewBox="0 0 560 190" width="100%" role="img" aria-label="Sơ đồ phụ thuộc" style="display:block">'
       '<defs><marker id="a" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 z" fill="#6a717c"/></marker></defs>'
       '<g stroke="#6a717c" stroke-width="1.5" marker-end="url(#a)" fill="none"><path d="M150,95 L215,95"/><path d="M345,95 L410,60"/><path d="M345,95 L410,130"/><path d="M30,40 L30,60 L60,75" stroke-dasharray="4 3"/></g>'
       '<g font-size="12" font-family="sans-serif"><rect x="10" y="70" width="140" height="50" rx="8" fill="#fff" stroke="#b9c0ca"/><text x="80" y="92" text-anchor="middle">Cổng dịch vụ công</text><text x="80" y="108" text-anchor="middle" fill="#6a717c" font-size="11">httt-dvc</text>'
       '<rect x="215" y="70" width="130" height="50" rx="8" fill="#e6efff" stroke="#0b5cd5" stroke-width="2"/><text x="280" y="92" text-anchor="middle" font-weight="700">Gateway APISIX</text><text x="280" y="108" text-anchor="middle" fill="#6a717c" font-size="11">svc-gateway-apisix</text>'
       '<rect x="410" y="30" width="140" height="50" rx="8" fill="#fff" stroke="#b9c0ca"/><text x="480" y="52" text-anchor="middle">API tra cứu thửa đất</text><text x="480" y="68" text-anchor="middle" fill="#6a717c" font-size="11">api-tra-cuu-thua-dat</text>'
       '<rect x="410" y="110" width="140" height="50" rx="8" fill="#fff" stroke="#b9c0ca"/><text x="480" y="132" text-anchor="middle">Kết nối trục quốc gia</text><text x="480" y="148" text-anchor="middle" fill="#6a717c" font-size="11">link-lgsp-quoc-gia</text></g></svg>')
ver = table(["Phiên bản", "Hiệu lực từ", "Ghi chú", "Nguồn"], [["3.4.1", "20/10/2026", "Nâng cấp plugin giới hạn tốc độ", mono("AUTO")], ["3.3.0", "01/07/2026", "Phát hành ban đầu ở T68", mono("AUTO")]], "Phiên bản thành phần")
body = f"""
{head("Gateway APISIX", mono("svc-gateway-apisix"), mono("PLATFORM_SERVICE"), LC["ACTIVE"], OP["UP"], CL["EXEMPTED"], btn("Đánh giá tuân thủ", "pri"))}
{tabs(["Thông tin", "Phiên bản", "Phụ thuộc", "Vận hành", "Tuân thủ"], 2)}
<div class="cols2">
  {card("Sơ đồ phụ thuộc (1 mức lên, 1 mức xuống)", dep + '<div class="muted">Nét đứt: phụ thuộc khai báo tay. Nét liền: tự đăng ký từ sự kiện phân hệ nguồn.</div>')}
  <div>{card("Thông tin", '<dl class="dl" style="grid-template-columns:110px 1fr"><dt>Chủ quản</dt><dd>Sở Khoa học và Công nghệ T68</dd><dt>Nguồn gốc</dt><dd><span class="mono">MANUAL</span> (nhập tay)</dd><dt>Trạng thái vận hành</dt><dd>Chạy tốt · cập nhật 04/11 01:20</dd><dt>Miễn trừ</dt><dd>Đến 30/04/2027 (còn 177 ngày)</dd></dl>')}
  <div style="height:12px"></div>{card("Phiên bản", ver)}</div>
</div>"""
P["15"] = ("Chi tiết thành phần kiến trúc", CR + " › Sổ kiến trúc › svc-gateway-apisix", body)

# ------------------------------------------------------------------ 16 Đánh giá tuân thủ (ngăn kéo)
crit = [("KT-01", "Dữ liệu lưu trong nước", "PASS", ""), ("KT-02", "Truyền dữ liệu qua trục tích hợp được phê duyệt", "PASS", ""), ("KT-03", "Có hồ sơ cấp độ an toàn thông tin được phê duyệt", "FAIL", "Hồ sơ cấp độ 3 đang chờ thẩm định"), ("KT-04", "Nhật ký khai thác đủ trường", "PASS", ""), ("KT-05", "Dự phòng và khôi phục thảm họa (dự thảo CMP-LAW-11)", "NA", "")]
def rad(v, cur):
    return "".join(f'<span class="seg"><span class="{"on" if cur == x else ""}">{t}</span></span> ' for x, t in [("PASS", "Đạt"), ("FAIL", "Không"), ("NA", "N/A")] if x == v or True)
rows = ""
for c in crit:
    seg = '<span class="seg">' + "".join(f'<span class="{"on" if c[2] == x else ""}">{t}</span>' for x, t in [("PASS", "Đạt"), ("FAIL", "Không đạt"), ("NA", "Không áp dụng")]) + "</span>"
    note = f'<div class="field" style="margin:6px 0 0"><span class="input" style="width:100%">{c[3] or "Ghi chú, bằng chứng…"}</span></div>' if c[2] == "FAIL" else ""
    rows += f'<div class="node2"><div style="display:flex;justify-content:space-between;gap:8px"><span><b class="mono">{c[0]}</b> {c[1]}</span>{seg}</div>{note}</div>'
bg = f"""{head("Sổ kiến trúc", btn("Đối chiếu ngay"), btn("+ Khai báo thành phần", "pri"))}<div class="card dim-bg">{table(["Thành phần", "Loại", "Tuân thủ"], [[f"<b>{c[1]}</b>", mono(c[2]), CL[c[5]]] for c in COMP], "Nền")}</div>"""
inner = (f'<div class="muted" style="margin-bottom:8px"><b>Bộ tiêu chí ktcpd3-2026 v2</b> · Khung kiến trúc Chính phủ điện tử 3.0 · 5 tiêu chí · bản nháp đánh giá</div>{rows}'
         f'<div class="node2"><b>Mức đề xuất:</b> {CL["PARTIAL"]} <span class="muted">(4 / 5 đạt, KT-03 không đạt)</span></div>'
         '<div class="alert w" style="margin:8px 0"><span>Còn 1 tiêu chí không đạt chưa có ghi chú.</span></div>'
         f'<div class="foot"><span class="muted" style="margin-right:auto">Người đánh giá: Cán bộ an toàn thông tin</span>{btn("Miễn trừ…")}{btn("Lưu nháp")}{btn("Gửi xác nhận", "pri")}</div>')
body = bg
extra = drawer("Đánh giá tuân thủ · adapter-soap-so-yte", inner, 560)
P["16"] = ("Đánh giá tuân thủ", CR + " › Sổ kiến trúc › adapter-soap-so-yte › Đánh giá", body, extra)

# ------------------------------------------------------------------ 17 Gửi quốc gia
NS = {"ACKNOWLEDGED": state("ok", "Đã có biên nhận"), "SENT": state("info", "Đã gửi"), "REJECTED": state("err", "Bị từ chối"), "FAILED": state("err", "Lỗi gửi"), "PENDING": state("mute", "Chờ gửi"), "SENDING": state("info", "Đang gửi")}
sub = [("SUB-000031", "KPI_REPORT", "bc-thang-2026-09 v2", "ACKNOWLEDGED", "BN-2026-118207", "08/10 10:02"), ("SUB-000030", "ARCH_REGISTRY", "Sổ kiến trúc tháng 10", "REJECTED", "—", "01/11 03:00"),
       ("SUB-000029", "KPI_REPORT", "bc-quy-2026-q3 v1", "ACKNOWLEDGED", "BN-2026-117954", "09/10 08:31"), ("SUB-000028", "ARCH_REGISTRY", "Sổ kiến trúc tháng 9", "FAILED", "—", "01/10 03:00"), ("SUB-000027", "ARCH_REGISTRY", "Sổ kiến trúc tháng 8", "ACKNOWLEDGED", "BN-2026-116420", "01/09 03:00")]
tb = table(["Mã gói", "Loại", "Nội dung", "Trạng thái", "Biên nhận", "Gửi lúc"], [[f"<b class='mono'>{s[0]}</b>", mono(s[1]), s[2], NS[s[3]], mono(s[4]), s[5]] for s in sub], "Gói gửi quốc gia", cls=[None, "list-sel", None, None, None])
logs = '<div class="vtl"><div><b>01/11 03:00:04</b> Lập gói theo mẫu <span class="mono">arch-registry v2</span>, mã băm <span class="mono">sha256:be10…7c3a</span></div><div><b>01/11 03:00:09</b> Gửi qua PH-14, thử lần 1</div><div><b>01/11 03:00:15</b> Hệ quốc gia từ chối gói: E-102 thiếu trường mã định danh thành phần.</div></div>'
body = f"""
{alert("i", "Gửi quốc gia đang <b>bật thử nghiệm</b> cho T68 (<span class='mono'>16.national.enabled</span>). Mẫu gói là cấu hình, chưa có đặc tả chính thức (Q16-02, Q16-03).")}
{head("Gửi quốc gia và nhật ký nộp", btn("Mẫu gói"), btn("Đối soát"), btn("+ Lập gói", "pri"))}
{tabs(["Gói đã lập", "Mẫu gói", "Đối soát"], 0)}
<div class="cols2">
  <div class="card">{tb}{foot("Hiển thị 1–5 trong 31 gói")}</div>
  <div>{card("SUB-000030 · Sổ kiến trúc tháng 10", '<div style="display:flex;gap:6px;margin-bottom:6px">' + NS["REJECTED"] + state("mute", "FULL") + '</div><div class="alert e" style="margin:0 0 8px"><span>Hệ quốc gia từ chối gói: E-102 thiếu trường mã định danh thành phần.</span></div>' + logs + '<div class="foot">' + btn("Xem gói") + btn("Gửi lại (lần 2 / 5)", "pri") + '</div>')}</div>
</div>"""
P["17"] = ("Gửi quốc gia và nhật ký nộp", CR + " › Gửi quốc gia", body)

# ------------------------------------------------------------------ 18 So sánh liên tenant
bars = ""
vals = [("Tỉnh A", 83.4), ("Tỉnh B", 80.1), ("Tỉnh C", 78.9), ("T68 (tỉnh của bạn)", 77.7), ("Tỉnh D", 74.0), ("Tỉnh E", 69.5), ("Tỉnh F", 66.2)]
for n, v in vals:
    col = "#0b5cd5" if "T68" in n else "#9db9e8"
    bars += f'<div class="hbar" style="grid-template-columns:150px 1fr 56px"><span>{n}</span><span><i style="width:{v}%;background:{col}"></i></span><b class="num">{vn(v)}</b></div>'
body = f"""
{alert("i", "<b>So sánh ẩn danh.</b> Chỉ hiện từ 3 tỉnh có số chính thức (<span class='mono'>16.compare.min-tenants</span>). Tên tỉnh khác được thay bằng ký hiệu.")}
{head("So sánh liên tenant", inp("Kỳ: Q-2026-Q3 ▾"), inp("Nhóm: Điểm tổng ▾"), btn("Xuất"))}
{kpis([kpi("Số tỉnh có số chính thức", "7", "Đủ tối thiểu 3"), kpi("Trung vị", "77,7", "Tứ phân vị 69,5 – 80,1"), kpi("Cao nhất", "83,4", "Tỉnh A"), kpi("Thấp nhất", "66,2", "Tỉnh F")], 4)}
<div class="cols2">{card("Phân bố điểm tổng theo tỉnh (ẩn danh)", bars + '<div class="muted" style="margin-top:8px">Vị trí T68 chỉ hiện với quản trị nền tảng khi tỉnh đó cho phép; kiểm toán nền tảng chỉ thấy ký hiệu.</div>')}
{card("Điểm theo nhóm: trung vị và khoảng", table(["Nhóm", "Thấp", "Trung vị", "Cao"], [[g[1], "55,0", "72,4", "85,0"] for g in GROUPS], "Theo nhóm", num=(1, 2, 3)))}</div>"""
P["18"] = ("So sánh liên tenant", CR + " › So sánh", body)

# ------------------------------------------------------------------ 19 Cài đặt
prm = [("16.period.close-day", "Ngày chốt kỳ tháng trước", "5", "1…28"), ("16.aggregate.cron", "Lịch tổng hợp", "0 30 1 * * *", "không dày hơn 1 giờ"), ("16.source.stale-hours", "Ngưỡng nguồn quá hạn (giờ)", "26", "1…744"),
       ("16.source.fail-after", "Số lần kéo lỗi để đặt Lỗi", "3", "1…10"), ("16.manual.evidence-required", "Bắt buộc bằng chứng số liệu tay", "true", "PA có thể khóa"), ("16.report.signing", "Ký số bản công bố", "true", "Boolean"),
       ("16.report.retention-years", "Hạn lưu báo cáo công bố (năm)", "10", "10…30"), ("16.export.link-hours", "Hạn liên kết tải (giờ)", "24", "1…168"), ("16.national.enabled", "Bật gửi quốc gia", "true", "Boolean"), ("16.compliance.waiver-max-days", "Hạn miễn trừ tối đa (ngày)", "180", "30…365")]
tb = table(["Khóa", "Ý nghĩa", "Giá trị", "Miền, trần", "Mặc định"], [[f"<b class='mono'>{p[0]}</b>", p[1], f'<span class="input" style="min-width:0;width:130px{";outline:2px solid #d33" if p[0]=="16.source.stale-hours" else ""}">{p[2] if p[0]!="16.source.stale-hours" else "9999"}</span>' + ('<div class="err-t">Giá trị 9999 của 16.source.stale-hours nằm ngoài miền cho phép (1…744).</div>' if p[0] == "16.source.stale-hours" else ""), p[3], mono(p[2])] for p in prm], "Tham số 16")
body = f"""
{head("Cài đặt báo cáo chỉ tiêu", btn("Khôi phục mặc định"), btn("Lưu thay đổi", "pri"))}
{tabs(["Tham số", "Lưu giữ", "Nhật ký thay đổi"], 0)}
<div class="card">{tb}<div class="muted" style="margin-top:8px">Một lần lưu là một giao dịch: một tham số lỗi thì cả lần lưu không được áp dụng.</div></div>
<div class="card" style="margin-top:12px"><b>Lưu giữ</b><div class="muted" style="margin:4px 0">Báo cáo công bố 10 năm · quan sát chi tiết 36 tháng · lần dọn gần nhất 01/11 02:00 thành công.</div></div>"""
P["19"] = ("Cài đặt", CR + " › Cài đặt", body)

# ------------------------------------------------------------------ 20 Nhật ký kiểm toán
au = [("04/11 14:36", "Cán bộ tổng hợp B", "TO", mono("report.update"), "bc-thang-2026-10", "Viết giải trình ket-noi-diem-diem-con-lai", "trace-7f21"), ("04/11 14:02", "Hệ thống", "—", mono("run.recompute"), "M-2026-10", "Tính lại do số trễ (LATE_DATA)", "trace-7f19"),
      ("04/11 09:10", "Quản trị tỉnh 1", "TA", mono("indicator.approve"), "mttr-muc-1 v2", "Duyệt định nghĩa", "trace-7e77"), ("03/11 16:20", "Cán bộ tổng hợp A", "TO", mono("manual.submit"), "bi-mat-ngoai-kho", "Gửi xác nhận số liệu tay", "trace-7d40"),
      ("03/11 16:25", "Cán bộ an toàn", "SO", mono("manual.accept"), "bi-mat-ngoai-kho", "Xác nhận số liệu", "trace-7d44"), ("02/11 08:00", "Quản trị tỉnh 1", "TA", mono("period.reopen"), "M-2026-08", "Mở lại kỳ: đính chính số", "trace-7c01")]
tb = table(["Thời điểm", "Người", "Vai trò", "Thao tác", "Đối tượng", "Chi tiết", "Mã truy vết"], [[a[0], a[1], a[2], a[3], f"<b class='mono'>{a[4]}</b>", a[5], mono(a[6])] for a in au], "Nhật ký kiểm toán")
body = f"""
{head("Nhật ký kiểm toán PH-16", btn("Xuất bằng chứng"))}
<div class="card"><div class="toolbar">{inp("Người: Tất cả ▾")}{inp("Thao tác: Tất cả ▾")}{inp("Đối tượng… ", "width:200px")}{inp("Từ 01/11 đến 04/11 ▾")}</div>{tb}{foot("Hiển thị 1–6 trong 1.842 bản ghi · chỉ đọc")}</div>
<div class="muted" style="margin-top:8px">Bản ghi do PH-13 lưu, bất biến. Tồn đọng chưa chuyển hiện ở thông báo vận hành (ERR-16-123).</div>"""
P["20"] = ("Nhật ký kiểm toán", CR + " › Kiểm toán", body)
