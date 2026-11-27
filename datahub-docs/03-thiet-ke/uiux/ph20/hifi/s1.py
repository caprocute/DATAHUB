from kit import *
from dat import *

P = {}
PC = "Nền tảng › Tenant"


def ctab(items, on):
    return tabs(items, on)


# ------------------------------------------------------------------ 01 Danh sách tenant
rows = []
for t in TEN:
    code, name, st, iso, qm, ht, ver, ch, last, al, act = t
    warn = f"<span class='tag t-warn'>▲ {al} cảnh báo</span>" if al != "—" else "—"
    chn = "<span class='tag t-info'>PREVIEW</span>" if ch == "PREVIEW" else "<span class='tag t-mute'>STABLE</span>"
    rows.append([f"<b class='mono'>{code}</b>", name, ts(st), ISO[iso], f"{qm} · {ht}", f"<span class='mono'>{ver}</span> {chn}", last, warn, act])
cls = ["", "", "", "", "", "", "", "", ""]
tb = table(["Mã", "Tên tỉnh", "Trạng thái", "Cách ly", "Quy mô · Triển khai", "Phiên bản · Kênh", "Lần chạy gần nhất", "Hạn mức", "Kích hoạt"], rows, "Danh sách tenant")
body = f"""
{head("Tenant", inp("Tìm theo mã hoặc tên…", "min-width:220px"), btn("＋ Khai báo tenant", "pri"), btn("Xuất CSV"))}
{facets(["Tất cả 34", "Hoạt động 27", "Đang khởi tạo 1", "Khởi tạo lỗi 1", "Tạm ngừng 1", "Đang sáp nhập 2", "Đã chấm dứt 2"], 0)}
<div class="card" style="padding:0">
 <div class="toolbar" style="margin:0"><span class="input">Cách ly: tất cả ▾</span><span class="input">Quy mô ▾</span><span class="input">Hồ sơ triển khai ▾</span><span class="input">Kênh ▾</span><span class="input">Phiên bản ▾</span><span class="input">Cảnh báo hạn mức ▾</span><span class="chip">☐ Hiện tenant kiểm thử T90…T99</span><span class="sp"></span><span class="muted">Mặc định chỉ tenant tỉnh (<span class="mono">kind = PROVINCE</span>)</span></div>
 {tb}
 {foot("Hiển thị 1–12 trên 34 tenant")}
</div>
<div class="muted" style="margin-top:8px">Bấm một dòng để mở chi tiết tenant. Tenant <span class="mono">PLATFORM</span> và <span class="mono">COMMON</span> chỉ hiện khi lọc loại "Đặc biệt" và mang nhãn "Bảo vệ".</div>
"""
P["01"] = ("Danh sách tenant", PC, body, "", dict(active="tn"))

# ------------------------------------------------------------------ 02 Khai báo tenant (bước 5 Rà soát)
def chk_row(code, nd, lv, msg, err=""):
    m = {"PASS": ("ok", "● Đạt"), "WARN": ("warn", "▲ Cảnh báo"), "BLOCKER": ("err", "✕ Chặn")}[lv]
    return [f"<span class='mono'>{code}</span>", nd, f"<span class='tag t-{m[0]}'>{m[1]}</span>", msg]


chks = [
    chk_row("CODE_UNIQUE", "Mã chưa từng dùng", "PASS", "T68 chưa có trong sổ tenant, kể cả đã chấm dứt hoặc sáp nhập"),
    chk_row("ADMIN_UNIT", "Đơn vị hành chính cấp tỉnh", "PASS", "Tỉnh Lâm Viên (giả định) còn hiệu lực ở COMMON, chưa có tenant"),
    chk_row("CAPACITY", "Sức chứa nền tảng", "WARN", "34 / 40 tenant (85 %). Khi đạt 90 % sẽ hiện cảnh báo, đạt 40 thì chặn (ERR-20-013)"),
    chk_row("CLUSTER_RESOURCES", "Tài nguyên cụm cho hồ sơ QM-VUA", "PASS", "Còn trống 31 % CPU, 38 % Ceph, 29 % pg-core sau khởi tạo"),
    chk_row("TEMPLATE", "Mẫu tinh-chuan phiên bản 3", "PASS", "Đã phát hành, 12 phân hệ lõi, gói danh mục nền 2026.11 tồn tại ở PH-07"),
    chk_row("CONTACTS", "Đầu mối bắt buộc", "PASS", "Có TENANT_ADMIN và TECHNICAL, thư công vụ chưa là tài khoản ở realm khác"),
    chk_row("HOST_PREFIX", "Host và tiền tố API", "PASS", "t68.datahub.example.vn, /t68 chưa dùng"),
    chk_row("DEPENDENCIES", "Phụ thuộc hạ tầng", "PASS", "PH-12, PH-13, PH-07, PH-10, OpenBao, Ceph RGW, Git, Argo CD trả kiểm sức khỏe đạt"),
    chk_row("CONTRACT", "Hợp đồng dịch vụ hiệu lực", "WARN", "Chưa có hợp đồng. Cho phép khởi tạo trước khi ký (Q20-03), bổ sung ở tab Hợp đồng"),
]
body = f"""
{head("Khai báo tenant mới", '<span class="tag t-info">Bản nháp chưa lưu</span>')}
<div class="steps"><div class="done">✓ 1 Hồ sơ</div><div class="done">✓ 2 Cách ly và quy mô</div><div class="done">✓ 3 Mẫu và phân hệ</div><div class="done">✓ 4 Đầu mối</div><div class="on"><b>5 Rà soát</b></div></div>
<div class="cols2">
 <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Kiểm tra sẵn sàng (FR-20-007)</h3>
  <div class="alert w" style="margin-bottom:10px"><span>9 mục kiểm: 7 đạt, 2 cảnh báo, <b>0 chặn</b>. Có thể lưu khai báo. Kiểm lúc 09:41:12, mỗi mục tối đa 10 giây.</span><span class="sp"></span>{btn("Kiểm tra lại")}</div>
  {table(["Mã kiểm", "Nội dung", "Kết quả", "Thông điệp"], chks, "Kết quả kiểm tra sẵn sàng")}
 </div>
 <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Tóm tắt khai báo</h3>
  <dl class="kv"><dt>Mã tenant</dt><dd><b class="mono">T68</b></dd><dt>Tên</dt><dd>Tỉnh Lâm Viên (giả định)</dd><dt>Đơn vị hành chính</dt><dd>Tỉnh Lâm Viên · cấp tỉnh</dd>
  <dt>Chế độ cách ly</dt><dd>Dùng chung (<span class="mono">SHARED</span>)</dd><dt>Quy mô, triển khai</dt><dd><span class="mono">QM-VUA</span> · <span class="mono">HT-B</span></dd>
  <dt>Mẫu khởi tạo</dt><dd><span class="mono">tinh-chuan</span> v3 · kênh STABLE</dd><dt>Phân hệ bật sẵn</dt><dd>12 lõi + PH-16, PH-19 <span class="muted">(bỏ PH-17)</span></dd>
  <dt>Đầu mối</dt><dd>2 (Quản trị tỉnh, Kỹ thuật)</dd><dt>Hợp đồng</dt><dd>Chưa có</dd><dt>Dự kiến</dt><dd>Khoảng 45 phút (trung vị 20 lần gần nhất)</dd></dl>
  <div class="foot" style="flex-wrap:wrap">{btn("‹ Quay lại")}<span class="sp" style="flex:1"></span>{btn("Lưu khai báo")}{btn("Lưu và khởi tạo", "pri")}</div>
  <div class="muted" style="margin-top:6px">Lưu khai báo chỉ tạo bản ghi <span class="mono">PROVISIONING</span>, chưa tạo tài nguyên ở hệ khác. "Lưu và khởi tạo" chuyển sang UI-20-04.</div>
 </div>
</div>
"""
P["02"] = ("Khai báo tenant", PC + " › Khai báo mới", body, "", dict(active="tn"))

# ------------------------------------------------------------------ 03 Chi tiết tenant (T01, tab Tổng quan)
tabs7 = ["Tổng quan", "Cấu hình nền tảng", "Hợp đồng và đầu mối", "Phân hệ", "Hạn mức", "Lịch sử vòng đời", "Kiểm toán"]
body = f"""
<div class="head"><h1><span class="mono">T01</span> · Tỉnh Mẫu A</h1>{ts("ACTIVE")}<span class="tag t-mute">Dùng chung</span><span class="tag t-mute">QM-VUA · HT-B</span><div class="sp"></div>
 {btn("Tạm ngừng…", "danger")}{btn("Đổi cách ly…")}{btn("Sửa hồ sơ")}</div>
{ctab(tabs7, 0)}
{kpis([kpi("Phiên bản đang chạy", "2.4.1", "Kênh STABLE · nâng cấp 02/11"), kpi("Hệ thống thành viên", "142", "Hạn mức 300"), kpi("Người dùng", "1.180", "Hạn mức 2.000"), kpi("API công bố", "640", "Hạn mức 2.000"), kpi("Cảnh báo hạn mức", "1", "Kho đối tượng chạm 100 %", "")], 5)}
<div class="cols2">
 <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Hồ sơ tenant</h3>
  <dl class="dl"><dt>Mã, realm</dt><dd><span class="mono">T01</span> · <span class="mono">dh-t01</span></dd><dt>Đơn vị hành chính</dt><dd>Tỉnh Mẫu A (cấp tỉnh)</dd>
  <dt>Mẫu khởi tạo</dt><dd><span class="mono">tinh-chuan</span> v2</dd><dt>Khai báo</dt><dd>10/03/2026 · Nguyễn Văn An</dd>
  <dt>Kích hoạt</dt><dd>12/03/2026 · thời gian khởi tạo 41 phút</dd><dt>Kênh phát hành</dt><dd>STABLE · môi trường PROD</dd>
  <dt>Cửa sổ bảo trì</dt><dd>Thứ Bảy 22:00, 4 giờ</dd><dt>Cấu hình Git</dt><dd><span class="mono">tenants/T01/</span> · v14 · <span class="tag t-ok">● Đã áp</span></dd></dl>
  <div class="muted" style="margin-top:8px">Hành động hiện theo <span class="mono">allowedActions[]</span> của máy chủ; PO và PAU chỉ thấy dạng đọc.</div></div>
 <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Lần chạy saga gần nhất</h3>
  <div>{run("SUCCEEDED")} <span class="mono">run-01JH2R7Q4T</span></div><div class="muted" style="margin:6px 0">17 bước, 41 phút 08 giây (ngưỡng 60 phút), kiểm tra khói 4 / 4 ca đạt.</div>{btn("Mở sổ bước")}
  <h3 style="margin:14px 0 6px;font-size:15px">Việc đang chờ</h3>
  <div class="verify"><div>⏳ Đề nghị đổi hạn mức <span class="mono">QCR-0042</span> chờ PA khác duyệt</div><div>▲ Cảnh báo <span class="mono">OBJECT_STORAGE_GB</span> 100 % từ 09:05</div></div></div>
</div>
"""
P["03"] = ("Chi tiết tenant", PC + " › T01", body, "", dict(active="tn"))

# ------------------------------------------------------------------ 04 Tiến độ khởi tạo (T68, lỗi S06)
def stepc(i):
    code, nd, who, s, dur, att, _ = i
    kind = {"ok": "ok", "run": "run", "wait": "wait", "skip": "skip", "pend": "pend", "fail": "fail"}[s]
    lab = {"ok": "Thành công", "run": "Đang chạy", "wait": "Chờ báo", "skip": "Bỏ qua (không áp dụng)", "pend": "Chưa tới", "fail": "Lỗi"}[s]
    par = " par" if code in ("S06_EVENTING", "S09_GATEWAY", "S10_INTEGRATION", "S12_SEED_MDM") else ""
    clsx = " fail" if s == "fail" else (" run" if s == "run" else "")
    act = ""
    if s == "fail":
        act = btn("Thử lại bước") + btn("Bỏ qua", "dis")
    return (f'<div class="sg{clsx}{par}">{ic(kind, lab)}<span class="mono">{code}</span><span>{nd}<div class="muted">{lab}</div></span><span>{who}</span><span class="num">{dur}</span><span class="num">{att if att else "—"}</span></div>'
            + (f'<div style="padding:4px 10px 8px 52px;font-size:12.5px;color:#a11a1a;background:#fde8e8">ERR-20-106 · Bước S06_EVENTING chưa nhận báo cáo từ PH-10 sau 15 phút. <span class="ctr" style="display:inline-flex;margin-left:8px">{act}</span><div class="muted">Bước bắt buộc nên nút "Bỏ qua" bị khóa. Thử lại là lũy đẳng với khóa <span class="mono">run-01JH8K2V9M:S06_EVENTING</span>.</div></div>' if s == "fail" else ""))


st_rows = []
for i in STEPS:
    i = list(i)
    if i[0] == "S06_EVENTING":
        i[3] = "fail"; i[4] = "15:00"; i[5] = 1
    st_rows.append(stepc(tuple(i)))
steps_html = '<div class="sg h"><span></span><span>Mã bước</span><span>Việc và trạng thái</span><span>Bên thực hiện</span><span>Thời gian</span><span>Lần thử</span></div>' + "".join(st_rows)
body = f"""
<div class="head"><h1>Tiến độ khởi tạo <span class="mono">T68</span></h1>{run("FAILED")}<span class="tag t-mute">INITIAL</span><div class="sp"></div>{btn("Thử lại từ bước lỗi", "pri")}{btn("Bù trừ và hủy…", "danger")}</div>
{banner("e", "ERR-20-106 · Bước S06_EVENTING chưa nhận báo cáo từ PH-10 sau 15 phút. Lần chạy dừng ở trạng thái lỗi, các bước sau chưa chạy.", "Xem chi tiết bước")}
<div class="kpis" style="--n:4">{kpi("Thời gian đã chạy", "31:20", "Ngưỡng 60 phút (NFR-00-057)")}{kpi("Tiến độ", "8 / 17", "1 lỗi · 2 bỏ qua · 7 chưa tới")}{kpi("Ước còn lại", "—", "Dừng vì lỗi")}{kpi("Mẫu, phiên bản", "tinh-chuan v3", "Kênh STABLE · QM-VUA")}</div>
<div class="cols2">
 <div class="card" style="padding:0"><div style="padding:10px 14px"><b>Sổ bước saga</b> <span class="muted">· cập nhật trực tiếp, nhóm song song S06, S09, S10, S12 thụt vào</span></div>{steps_html}</div>
 <div>
  <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Luồng tiến độ</h3>
   <div class="row"><span class="tag t-ok">● Đang nhận</span><span class="muted">Máy chủ gửi sự kiện từ 09:12:04 · mã <span class="mono">evt-1186</span></span></div>
   <div class="prog" style="margin:10px 0 4px"><i style="width:47%"></i></div><div class="muted">8 trên 17 bước (47 %)</div>
   <div class="verify" style="margin-top:10px"><div><b>Kiểm tra sẵn sàng</b> lúc bắt đầu: 7 đạt, 2 cảnh báo, 0 chặn</div><div><b>Kiểm tra khói</b>: chưa chạy (sau S15)</div></div></div>
  <div class="card" style="margin-top:10px"><h3 style="margin:0 0 8px;font-size:15px">Báo cáo nhận được</h3>
   <div class="vtl"><div><b>09:41:50</b> PH-04 báo <span class="mono">S10_INTEGRATION</span> thành công</div><div><b>09:30:05</b> PH-13 báo <span class="mono">S08_OBSERVABILITY</span> thành công</div><div><b>09:28:40</b> Phát EVT-20-01 sau S05</div><div><b>09:27:55</b> <span class="mono">S05_BUCKETS</span> xong, 3 bucket</div></div></div>
 </div>
</div>
"""
P["04"] = ("Tiến độ khởi tạo", PC + " › T68 › Khởi tạo", body, "", dict(active="tn"))

# ------------------------------------------------------------------ 05 Hạn mức tenant (T01)
qrows = []
for code, nm, unit, lim, used in RES:
    pct = 100 * used / lim
    mk = "✕ 100 %" if pct >= 100 else ("▲ ≥ 80 %" if pct >= 80 else "● ")
    qrows.append([f"<b>{nm}</b><div class='muted mono'>{code}</div>", f"<span class='input' style='min-width:70px;justify-content:flex-end'>{vn(lim, 0)}</span>",
                  vn(lim * 2 if lim >= 100 else lim * 3, 0), f"{vn(used, 1 if used != int(used) else 0)} · {vn(pct, 0)} % {mk}", f"{vn(lim, 0)} {unit}"])
qrows[0][4] = "<b>800</b> lượt/giây <span class='tag t-info'>↑ ghi đè đến 15/12</span>"
qrows[5][1] = "<span class='input' style='min-width:70px;justify-content:flex-end;outline:2px solid #c98a00'>80</span><div class='err-t'>ERR-20-030 · thấp hơn mức đang dùng 96</div>"
body = f"""
<div class="head"><h1>Hạn mức <span class="mono">T01</span> · Tỉnh Mẫu A</h1><span class="tag t-info">Hợp đồng HĐ-15/2026/DH</span><div class="sp"></div>{btn("Ghi đè tạm thời…")}{btn("Lập đề nghị đổi", "pri")}</div>
{alert("w", "<b>Đã sửa DATABASE_GB từ 200 xuống 80, thấp hơn mức đang dùng (p95 7 ngày: 96 GB).</b> Thay đổi này cần người thứ hai duyệt. Bấm \"Lập đề nghị đổi\" để gửi duyệt, không lưu trực tiếp được.")}
<div class="cols2">
 <div class="card" style="padding:0">{table(["Tài nguyên", "Giá trị hợp đồng", "Trần nền tảng", "Mức dùng p95", "Hiệu lực"], qrows, "Hạn mức hợp đồng 12 tài nguyên", num=(1, 2))}</div>
 <div>
  <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Đề nghị chờ duyệt</h3>
   <div class="node2"><b class="mono">QCR-0042</b> {tag("warn", "Chờ duyệt")}<div class="muted">Hạ <span class="mono">DATABASE_GB</span> 200 → 80 · lập bởi Nguyễn Văn An · 09:02</div><div class="muted">Phiếu <span class="mono">SR-2026-1187</span></div></div>
   <div class="alert w"><span>Anh/chị là người lập nên không được duyệt. Cần một quản trị nền tảng khác duyệt. (ERR-20-007)</span></div></div>
  <div class="card" style="margin-top:10px"><h3 style="margin:0 0 8px;font-size:15px">Ghi đè tạm thời</h3>
   <div class="node2"><b class="mono">API_RPS</b> 500 → 800 · 01/12 đến 15/12 {tag("ok", "● Đang hiệu lực")}<div class="muted">Tối đa 30 ngày (<span class="mono">20.quota.override-max-days</span>) · báo đầu mối trước 24 giờ</div></div></div>
  <div class="card" style="margin-top:10px"><h3 style="margin:0 0 6px;font-size:15px">Nơi thực thi xác nhận</h3>
   <div class="muted">PH-03 ● 09:05 · PH-04 ● 09:05 · PH-10 <span class="tag t-warn">▲ Chưa xác nhận sau 15 phút</span></div></div>
 </div>
</div>
"""
P["05"] = ("Hạn mức tenant", PC + " › T01 › Hạn mức", body, "", dict(active="tn"))

# ------------------------------------------------------------------ 06 Sử dụng tài nguyên toàn nền tảng
def cell(p):
    if p is None:
        return '<span style="background:#f1f3f5;color:#8a919c">—</span>'
    if p >= 100:
        return f'<span style="background:#fde8e8;color:#a11a1a;border-color:#f2b8b8;font-weight:700">✕ {p}%</span>'
    if p >= 80:
        return f'<span style="background:#fff4d6;color:#7a5200;border-color:#f0dc9c;font-weight:600">▲ {p}%</span>'
    return f'<span style="background:#e5f6ec;color:#0b6b3a">{p}%</span>'


HEAT = [("T01", "Tỉnh Mẫu A", [82, 61, 86, 48, 100, 48]), ("T03", "Tỉnh Mẫu C", [91, 84, 55, 62, 74, 81]), ("T04", "Tỉnh Mẫu D", [44, 51, 39, 33, 41, 46]),
        ("T09", "Tỉnh Mẫu G", [None, None, None, None, 62, 38]), ("T12", "Tỉnh Mẫu H", [58, 66, 70, 52, 88, 59]), ("T13", "Tỉnh Mẫu K", [77, 72, 64, 69, 83, 71]),
        ("T15", "Tỉnh Mẫu L", [35, 29, 40, 31, 52, 44]), ("T16", "Tỉnh Mẫu M", [28, 33, 25, 22, 37, 41])]
hdr = "".join(f'<span style="font-weight:600;color:#545b66;height:auto;white-space:normal;text-align:center;font-size:11.5px">{h}</span>' for h in ["Lượt gọi API", "Luồng chạy", "Ghi sự kiện", "Đọc sự kiện", "Kho đối tượng", "Cơ sở dữ liệu"])
heat = f'<div class="heat" style="grid-template-columns:160px repeat(6,1fr)"><span></span>{hdr}'
for c, n, v in HEAT:
    heat += f'<span style="justify-content:start;padding-left:4px;display:flex;align-items:center"><b class="mono">{c}</b>&nbsp;{n}</span>' + "".join(cell(x) for x in v)
heat += "</div>"
trend_line = echart_line([("Tenant chạm 80 %", [3, 3, 4, 4, 5, 4, 5, 6, 5, 6, 7, 7], "#c98a00", ""), ("Tenant chạm 100 %", [0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 2, 1], "#c0392b", "5 3")],
                         ["T1", "T2", "T3", "T4", "T5", "T6", "T7", "T8", "T9", "T10", "T11", "T12"], w=520, h=200, ymin=0, ymax=10, yfmt="{:.0f}")
alerts = [["<span class='mono'>T01</span>", "OBJECT_STORAGE_GB", "<span class='tag t-err'>✕ 100 %</span>", "09:05", "Chưa xử lý"],
          ["<span class='mono'>T03</span>", "API_RPS", "<span class='tag t-warn'>▲ 91 %</span>", "Hôm qua 16:20", "Chưa xử lý"],
          ["<span class='mono'>T12</span>", "OBJECT_STORAGE_GB", "<span class='tag t-warn'>▲ 88 %</span>", "Hôm qua 11:02", "Đã xác nhận"],
          ["<span class='mono'>T13</span>", "OBJECT_STORAGE_GB", "<span class='tag t-warn'>▲ 83 %</span>", "25/11", "Chưa xử lý"]]
body = f"""
{head("Sử dụng tài nguyên toàn nền tảng", inp("Kỳ: 30 ngày qua ▾"), inp("Tenant: tất cả ▾"), btn("Lập báo cáo kỳ…"), btn("Xuất…"))}
{alert("w", "Thiếu số liệu <span class='mono'>DATABASE_GB</span> của <span class='mono'>T09</span> từ 07:00 (ERR-20-110). Ô tương ứng hiện dấu gạch, không hiện 0.", "Xem tenant")}
{kpis([kpi("Tenant tỉnh hoạt động", "27 / 34", "Sức chứa 40 (85 %)"), kpi("Chạm 80 % trở lên", "7", "▲ +1 so tuần trước"), kpi("Chạm 100 %", "1", "T01 · kho đối tượng"), kpi("Ghi đè đang hiệu lực", "3", "Tối đa 30 ngày"), kpi("Dữ liệu mới nhất", "09:00", "Ảnh chụp mỗi giờ")], 5)}
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Mức dùng so hạn mức hiệu lực theo tenant và tài nguyên</h3>{heat}
<div class="muted" style="margin-top:8px">Quy ước: ● dưới 80 %, ▲ từ 80 %, ✕ từ 100 %, — chưa có số. Mỗi ô có chữ và biểu tượng, màu chỉ củng cố. Bấm ô để mở sử dụng của tenant đó.</div></div>
<div class="cols2" style="margin-top:12px">
 <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Cảnh báo hạn mức đang mở</h3>{table(["Tenant", "Tài nguyên", "Mức", "Từ", "Trạng thái"], alerts, "Cảnh báo hạn mức")}<div class="muted" style="margin-top:6px">Xác nhận đã xử lý cần <span class="mono">PERM-20-quota</span>; PO chỉ xem.</div></div>
 <div class="card"><h3 style="margin:0 0 4px;font-size:15px">Số tenant chạm ngưỡng theo tháng</h3>{trend_line}{legend([("Chạm 80 %", "#c98a00"), ("Chạm 100 % (nét đứt)", "#c0392b")])}</div>
</div>
"""
P["06"] = ("Sử dụng tài nguyên toàn nền tảng", "Nền tảng › Sử dụng tài nguyên", body, "", dict(active="sd"))

# ------------------------------------------------------------------ 07 Phân hệ và tính năng (T01)
MODS = [("PH-01", "Kết nạp hệ thống thành viên", 1, 1, "ENABLED", "—"), ("PH-02", "Danh mục dịch vụ", 1, 1, "ENABLED", "PH-01"), ("PH-03", "Cổng API", 1, 1, "ENABLED", "PH-12"),
        ("PH-04", "Tích hợp", 1, 1, "ENABLED", "PH-05"), ("PH-06", "Dữ liệu chủ", 0, 3, "ENABLED", "PH-07"), ("PH-08", "Chất lượng dữ liệu", 0, 3, "ENABLED", "PH-06"),
        ("PH-11", "Quy trình", 0, 2, "DISABLED", "PH-04"), ("PH-16", "Báo cáo chỉ tiêu", 0, 3, "ENABLED", "PH-13"), ("PH-17", "Trợ lý AI", 0, 3, "DISABLED", "PH-08, PH-12"),
        ("PH-19", "Thanh toán", 0, 2, "SUSPENDED", "PH-03, PH-12")]
SM = {"ENABLED": ("ok", "● Đang bật"), "DISABLED": ("mute", "– Đã tắt"), "SUSPENDED": ("warn", "⏸ Tạm ngừng"), "ENABLING": ("info", "◔ Đang bật"), "FAILED": ("err", "✕ Lỗi")}
mr = []
for c, n, core, wave, s, dep in MODS:
    k, t = SM[s]
    sw_ = "<span class='tag t-mute'>Lõi, không tắt</span>" if core else (btn("Tắt") + btn("Tạm ngừng") if s == "ENABLED" else (btn("Tiếp tục", "pri") if s == "SUSPENDED" else btn("Bật", "pri")))
    mr.append([f"<b class='mono'>{c}</b>", n, f"Đợt {wave}" + (" · lõi" if core else ""), dep, f"<span class='tag t-{k}'>{t}</span>", sw_])
flags = [["<span class='mono'>ph04.sql-direct</span>", "PH-04", sw(False) + " Tắt", "Đọc SQL trực tiếp (ADR-067)", "—"], ["<span class='mono'>ph17.chat</span>", "PH-17", "<span class='muted'>PH-17 đang tắt</span>", "Trò chuyện trợ lý", "Không áp dụng"],
         ["<span class='mono'>ph19.refund-auto</span>", "PH-19", sw(True) + " Bật", "Hoàn tiền tự động", "đến 31/12/2026"]]
body = f"""
<div class="head"><h1>Phân hệ và tính năng <span class="mono">T01</span></h1>{ts("ACTIVE")}<div class="sp"></div><span class="muted">Phiên bản đang chạy 2.4.1</span></div>
{tabs(["Phân hệ của tỉnh", "Danh mục và phụ thuộc", "Cờ tính năng"], 0)}
{alert("e", "<b>ERR-20-034</b> · Phân hệ PH-08 đang được PH-17 dùng. Tắt các phân hệ đó trước. <span class='muted'>(ví dụ giả định cho phụ thuộc REQUIRED)</span>")}
<div class="cols2">
 <div class="card" style="padding:0">{table(["Mã", "Phân hệ", "Đợt", "Phụ thuộc", "Trạng thái", "Hành động"], mr, "Phân hệ theo tenant")}{foot("10 trên 20 phân hệ · lọc: tất cả")}</div>
 <div>
  <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Đồ thị phụ thuộc PH-19</h3>
   <div style="display:flex;gap:14px;align-items:center;flex-wrap:wrap"><div class="node2" style="margin:0"><b class="mono">PH-12</b><div class="muted">lõi · bật</div></div><span>→</span><div class="node2 on" style="margin:0"><b class="mono">PH-03</b><div class="muted">lõi · bật</div></div><span>→</span><div class="node2" style="margin:0;outline:2px solid #c98a00"><b class="mono">PH-19</b><div class="muted">tạm ngừng</div></div></div>
   <div class="muted" style="margin-top:8px">Bật PH-19 cần PH-03 và PH-12 đã bật (ERR-20-033 nếu thiếu). Đợt 2, chưa có ở bản chạy khi lọc theo đợt khác.</div></div>
  <div class="card" style="margin-top:10px"><h3 style="margin:0 0 8px;font-size:15px">Cờ tính năng</h3>{table(["Cờ", "Phân hệ", "Giá trị", "Mô tả", "Hết hạn"], flags, "Cờ tính năng")}</div>
 </div>
</div>
"""
P["07"] = ("Phân hệ và tính năng", PC + " › T01 › Phân hệ", body, "", dict(active="tn"))

# ------------------------------------------------------------------ 08 Đổi trạng thái tenant (T09 SUSPENDED, hộp thoại đề nghị chấm dứt)
extra = f"""<div class="scrim"></div><div class="modal" role="dialog" aria-label="Đề nghị chấm dứt tenant T09">
<h3 style="margin:0 0 6px">Đề nghị chấm dứt tenant <span class="mono">T09</span></h3>
<div class="alert w" style="margin-bottom:10px"><span>Dữ liệu sẽ bị xóa sau khi bàn giao và hai người duyệt. Thao tác không hoàn tác. Đang có 38 HTTT, 41 API, 214 người dùng, 9,8 GB.</span></div>
<div class="field"><label>Lý do (bắt buộc, tối thiểu 20 ký tự) *</label><span class="input" style="height:64px;align-items:flex-start;padding-top:6px;color:#1a1d23">Hợp đồng dịch vụ hết hạn ngày 31/05/2026, tỉnh không gia hạn theo công văn số 214/UBND.</span><div class="muted">96 / 1.000 ký tự</div></div>
<div class="row"><div class="field"><label>Mã phiếu *</label><span class="input" style="color:#1a1d23">SR-2026-1203</span></div><div class="field"><label>Văn bản quyết định *</label><span class="input" style="color:#1a1d23">214/UBND · 02/06/2026</span></div></div>
<div class="row"><div class="field"><label>Dự kiến thực hiện *</label><span class="input" style="color:#1a1d23">08/07/2026</span><div class="muted">Sớm nhất 08/07/2026 (tạm ngừng 08/06 + 30 ngày)</div></div><div class="field"><label>Xuất gói bàn giao trước</label><span class="muted">{sw(True)} Bắt buộc</span></div></div>
<div class="muted">Lý do và mã phiếu được ghi vào nhật ký kiểm toán của tenant T09 và không sửa được.</div>
<div class="foot">{btn("Hủy")}{btn("Lưu nháp")}{btn("Gửi duyệt", "danger")}</div></div>"""
flow = '<div class="steps"><div class="done">✓ Tạm ngừng 08/06</div><div class="on"><b>Đề nghị chấm dứt</b></div><div>Duyệt (PA khác)</div><div>Gói bàn giao</div><div>Thực hiện, xóa mật mã</div></div>'
body = f"""
<div class="head"><h1>Vòng đời <span class="mono">T09</span> · Tỉnh Mẫu G</h1>{ts("SUSPENDED")}<div class="sp"></div>{btn("Khôi phục tenant", "pri")}{btn("Đề nghị chấm dứt…", "danger")}{btn("Xuất gói bàn giao")}</div>
{banner("e", "Tenant T09 đang tạm ngừng từ 08/06/2026 (hết hợp đồng). Mọi API của tỉnh trả ERR-20-001. Chờ hết thời gian nguội 30 ngày mới chấm dứt được.")}
{flow}
<div class="cols2">
 <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Hành động hợp lệ</h3>
  <div class="node2"><b>Khôi phục tenant</b><div class="muted">Chạy kiểm tra khói rút gọn rồi về Đang hoạt động. Cần lý do, mã phiếu.</div></div>
  <div class="node2"><b>Đề nghị chấm dứt</b><div class="muted">Cần văn bản quyết định, tạm ngừng ≥ 30 ngày. Hai quản trị nền tảng khác nhau.</div></div>
  <div class="node2"><b>Xuất gói bàn giao dữ liệu</b><div class="muted">Mọi phân hệ tham gia, JSONL hoặc CSV kèm lược đồ, lưu 90 ngày.</div></div></div>
 <div class="card"><h3 style="margin:0 0 8px;font-size:15px">Gói bàn giao <span class="mono">EXP-0007</span> {tag("warn", "◔ Đang thu thập 4/9")}</h3>
  {table(["Phân hệ", "Trạng thái", "Bản ghi", "Kích thước"], [["PH-01", "● Xong", "38", "0,2 GB"], ["PH-02", "● Xong", "41", "0,1 GB"], ["PH-07", "● Xong", "1.204", "0,6 GB"], ["PH-10", "● Xong", "212", "3,1 GB"], ["PH-13", "◔ Đang xuất", "—", "—"]], "Tiến độ theo phân hệ", num=(2, 3))}
  <div class="muted" style="margin-top:6px">Người duyệt chấm dứt không được xác nhận bàn giao (ERR-20-007).</div></div>
</div>
<div class="card" style="margin-top:12px"><h3 style="margin:0 0 6px;font-size:15px">Lịch sử vòng đời</h3><div class="vtl"><div><b>08/06/2026 08:15</b> ACTIVE → SUSPENDED · Hết hợp đồng · PA Nguyễn Văn An · SR-2026-1120</div><div><b>08/06/2026 08:16</b> Thông báo gửi 3 đầu mối, 214 người dùng</div></div></div>
"""
P["08"] = ("Đổi trạng thái tenant", PC + " › T09 › Vòng đời", body, extra, dict(active="tn"))
