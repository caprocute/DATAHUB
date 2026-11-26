#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-09-01…22 (D03-06-PH09, mục "Bản hi-fi" của từng màn).

Chạy: python3 gen_hifi.py && node shot.js && python3 nen.py
Dữ liệu là giả định của tỉnh thí điểm T68: người, số định danh, tổ chức đều là dữ liệu giả; số định danh luôn che.
Menu theo D03-06-00 mục 23 (Dữ liệu dùng chung › Quyền riêng tư); hàng tab phụ theo D03-06-PH09 mục 4.
Phong cách Liquid Glass của D03-05: kính chỉ ở lớp điều hướng và lớp nổi, nội dung nền đặc.
"""
import pathlib

OUT = pathlib.Path(__file__).parent

NAV = [("|Dữ liệu dùng chung", None), ("Danh mục dùng chung", "dm"), ("Đồng bộ danh mục quốc gia", "ds"),
       ("Dữ liệu chủ", "mdm"), ("Chất lượng dữ liệu", "cl"), ("Quyền riêng tư", "qr"), ("|Cá nhân", None), ("Việc của tôi", "vc")]
BADGE = {"qr": "<span class='tag t-warn'>6</span>", "vc": "<span class='tag t-info'>5</span>"}
TABS = ["Tổng quan", "Phân loại", "Hoạt động xử lý", "Mục đích", "Yêu cầu khai thác", "Chấp thuận", "Chính sách che", "Giả danh", "Ẩn danh", "Lưu giữ",
        "Yêu cầu chủ thể", "Đồng ý", "DPIA", "Vi phạm", "Nhật ký", "Cài đặt"]
TABON = {"01": 0, "02": 1, "05": 2, "06": 2, "09": 5, "10": 6, "11": 6, "13": 7, "14": 8, "16": 10, "19": 13, "22": 1, "22b": 1}


def shell(code, title, crumb, body, extra=""):
    nav = ""
    for n, c in NAV:
        if n.startswith("|"):
            nav += f'<div class="grp">{n[1:]}</div>'
            continue
        nav += f'<a class="{"on" if c == "qr" else ""}" href="#">{n} {BADGE.get(c, "")}</a>'
    tb = '<div class="subtabs" role="tablist" style="flex-wrap:wrap">' + "".join(
        f'<span class="{"on" if i == TABON[code] else ""}">{t}</span>' for i, t in enumerate(TABS)) + "</div>"
    if code.startswith("22"):
        tb = '<div class="subtabs" role="tablist" style="flex-wrap:wrap">' + "".join(
            f'<span class="{"on" if i == 1 else ""}">{t}</span>' for i, t in enumerate(["Tổng quan", "Bản ghi", "Ứng viên", "Hàng đợi", "Cấu hình", "Job", "Nhật ký"])) + "</div>"
        nav = nav.replace('class="on" href="#">Quyền riêng tư', 'class="" href="#">Quyền riêng tư').replace('<a class="" href="#">Dữ liệu chủ', '<a class="on" href="#">Dữ liệu chủ')
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-09-{code} · {title}</title><link rel="stylesheet" href="hifi.css"></head><body>
<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Điều hành</div><div class="search">Tìm phần tử dữ liệu, mục đích, yêu cầu…  ⌘K</div><div class="sp"></div>
<span class="tray">⟳ 1 tác vụ nền</span><span class="tray">T68 · Tỉnh thí điểm</span><div class="avatar">NT</div></header>
<nav class="side" aria-label="Điều hướng chính">{nav}</nav>
<main><div class="crumb">{crumb}</div>{tb}{body}</main></div>{extra}<div class="hint">Bản hi-fi minh họa · D03-06-PH09 · UI-09-{code} · dữ liệu giả định T68</div></body></html>"""


def table(head, data, label="", cls=None):
    th = "".join(f"<th>{h}</th>" for h in head)
    tr = ""
    for i, r in enumerate(data):
        c = f' class="{cls[i]}"' if cls and cls[i] else ""
        tr += f"<tr{c}>" + "".join(f"<td>{x}</td>" for x in r) + "</tr>"
    return f'<table aria-label="{label}"><thead><tr>{th}</tr></thead><tbody>{tr}</tbody></table>'


def tag(kind, text):
    return f"<span class='tag t-{kind}'>{text}</span>"


def tabs(items, on):
    return '<div class="tabs" role="tablist">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def facets(items, on=0):
    return '<div class="facets">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def kpi(a, b, d="", cls=""):
    return f'<div class="kpi {cls}"><span>{a}</span><b>{b}</b><small>{d}</small></div>'


def kpis(items, n=None):
    n = n or len(items)
    return f'<div class="kpis" style="--n:{n}">' + "".join(items) + "</div>"


def foot(text="Hiển thị 1–20"):
    return f'<div class="foot" style="justify-content:space-between"><span class="muted">{text}</span><span class="muted">‹ 1 2 3 › · 20 / trang</span></div>'


def drawer(title, inner, width=480):
    return f'<div class="drawer" role="dialog" aria-label="{title}" style="width:{width}px"><h3 style="margin:0 0 10px">{title}</h3>{inner}</div>'


def mono(t):
    return f"<span class='mono'>{t}</span>"


def card(title, inner, style=""):
    return f'<div class="card" style="{style}"><h3 style="margin:0 0 8px;font-size:15px">{title}</h3>{inner}</div>'


def head(title, *right):
    return f'<div class="head"><h1>{title}</h1><div class="sp"></div>{"".join(right)}</div>'


def btn(t, k=""):
    return f'<span class="btn {k}">{t}</span>'


def inp(t, w=""):
    return f'<span class="input" style="{w}">{t}</span>'


def conf(v):
    c = "h" if v >= 0.9 else ("m" if v >= 0.7 else "l")
    t = {"h": "cao", "m": "TB", "l": "thấp"}[c]
    return f'<span style="white-space:nowrap"><span class="dot {c}"></span>{str(v).replace(".", ",")} <span class="muted">{t}</span></span>'


def src(code, kind):
    return tag({"NAT": "nat", "SEC": "com", "REL": "hyb", "OTH": "mute", "MAN": "warn", "FILE": "mute"}[kind], code)


def banner(kind, text, action=""):
    ico = "✕" if kind == "e" else "⚠"
    a = f'<span class="sp"></span>{btn(action)}' if action else ""
    return f'<div class="banner {kind}" role="alert"><span>{ico}</span><span>{text}</span>{a}</div>'


def line_chart(series, w=640, h=150, thr=None, labels=("T9", "T10", "T11")):
    out = f'<svg viewBox="0 0 {w} {h}" class="line" role="img" aria-label="Xu hướng">'
    if thr is not None:
        out += f'<line x1="0" y1="{thr}" x2="{w}" y2="{thr}" stroke="#a11a1a" stroke-dasharray="4 4"/><text x="{w-4}" y="{thr-4}" font-size="11" text-anchor="end" fill="#a11a1a">ngưỡng 5%</text>'
    for pts, col, dash in series:
        out += f'<polyline fill="none" stroke="{col}" stroke-width="2.2" {"stroke-dasharray=%r" % dash if dash else ""} points="{pts}"/>'
    return out + "</svg>"


def pts(vals, w=640, h=150, mx=None, lo=None, hi=None):
    lo = min(vals) * 0.9 if lo is None else lo
    hi = max(vals) * 1.05 if hi is None else hi
    n = len(vals) - 1
    return " ".join(f"{int(i * w / n)},{int(h - 10 - (v - lo) / (hi - lo) * (h - 24))}" for i, v in enumerate(vals))


OK, WA, ER, IN, MU = "ok", "warn", "err", "info", "mute"
P = {}

MK = lambda t: f"<span class='mk'>{t}</span>"

# ---------------------------------------------------------------- 01 Tổng quan tuân thủ
t1 = pts([61, 58, 55, 52, 49, 47, 44, 42, 40, 39, 38, 37], mx=70)
t2 = pts([2, 3, 3, 4, 4, 5, 5, 4, 4, 4, 4, 4], mx=8)
P["01"] = ("Tổng quan tuân thủ", "Dữ liệu dùng chung › Quyền riêng tư › Tổng quan", f"""
{banner("e", "Vụ việc VP-2026-007 còn 41 giờ 33 phút đến hạn thông báo Cục A05. Mở hồ sơ vi phạm.", "Mở vụ việc")}
{banner("w", "Gói chính sách quyền riêng tư phát hành lúc 13:58 (4 phút trước). Điểm thực thi PH-06 chậm 12 giây, trong giới hạn 60 giây.")}
{head("Tổng quan tuân thủ quyền riêng tư", '<span class="seg"><span>24 giờ</span><span>7 ngày</span><span class="on">30 ngày</span><span>90 ngày</span></span>', '<span class="muted">Số liệu cập nhật 14:02</span>', btn("⟳"))}
{kpis([
    kpi("Trường chưa phân loại", "37", "⚠ xử lý như Nhạy cảm (BR-09-001) · giảm 24 so với 12 tuần trước"),
    kpi("Hợp đồng bị chặn kích hoạt", "4", "⚠ thiếu mục đích hoặc chấp thuận (ERR-09-035)"),
    kpi("Yêu cầu chủ thể quá hạn", "2", "⚠ 11 đang xử lý · hạn 10 ngày làm việc (giả định)"),
    kpi("Đồng hồ vi phạm", "41 giờ 33 phút", "VP-2026-007 · đã qua mốc 24 giờ, sắp tới mốc 48 giờ"),
    kpi("Tuổi gói chính sách", "4 phút", "● Đạt (≤ 60 phút) · hiệu lực đến 14:58"),
], 5)}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 420px">
{card("Xu hướng 12 tuần: trường chưa phân loại và cảnh báo khai thác mở", line_chart([(t1, "#0b5cd5", ""), (t2, "#a8320f", "6 3")]) + '<div class="legend"><span><i style="background:#0b5cd5"></i>Trường chưa phân loại</span><span><i style="background:#a8320f"></i>Cảnh báo khai thác mở (nét đứt)</span><span style="flex:1"></span><span>Xem dạng bảng</span></div>')}
{card("Phần tử dữ liệu theo mức phân loại", "".join(f'<div class="hbar"><span>{n}</span><i style="width:{w}%"></i><span class="num">{c}</span></div>' for n, w, c in [("PUBLIC", 62, "18.420"), ("INTERNAL", 100, "29.115"), ("RESTRICTED", 21, "6.208"), ("SENSITIVE", 9, "2.671"), ("Chưa xác nhận", 1, "37")]))}
</div>
{card("Cảnh báo khai thác theo mục đích đang mở (4)", table(["Mã", "HTTT", "Mục đích", "Loại", "Mức", "Phát hiện", "Trạng thái"], [
    [mono("an-0412"), "HT-BHXH", mono("TTHC-BHXH"), tag(WA, "QUOTA_EXCEEDED"), "Trung bình", "13:41", tag(IN, "OPEN")],
    [mono("an-0409"), "HT-YTE", mono("THONG-KE"), tag(ER, "OFF_PURPOSE"), "Cao", "11:20", tag(IN, "OPEN")],
    [mono("an-0401"), "HT-GD", mono("TTHC-HO-TICH"), tag(WA, "BULK_ACCESS"), "Trung bình", "Hôm qua", tag(MU, "ACKNOWLEDGED")]], "Cảnh báo khai thác"))}</div>""")

# ---------------------------------------------------------------- 02 Danh mục phân loại trường
P["02"] = ("Danh mục phân loại trường", "Dữ liệu dùng chung › Quyền riêng tư › Phân loại", f"""
{head("Danh mục phân loại trường", btn("Kết quả quét"), btn("Xuất danh mục"), btn("+ Đăng ký phần tử", "pri"))}
<div class="grid2" style="grid-template-columns:260px minmax(0,1fr)">
<div class="card tree"><div class="grp-t" style="margin-top:0">Hệ thống và hợp đồng</div><div>▾ HT-DANCU (48)</div><div>&nbsp;&nbsp;▸ API dan-cu-tra-cuu</div><div class="on">▾ HT-BHXH (212)</div><div class="on" style="margin-left:14px">▸ API bhxh-tra-cuu-ho-gia-dinh</div><div>&nbsp;&nbsp;▸ Topic bhxh.dong-bhxh</div><div>▾ HT-YTE (305)</div><div>▸ PH-06 ph06_mdm (96)</div><div>▸ PH-19 thanh toán (71)</div></div>
<div class="card"><div class="toolbar">{facets(["Tất cả 212", "Chưa xác nhận 14", "Đề xuất 9", "Nhạy cảm 31"], 0)}{inp("Loại DLCN ▾")}{inp("Mức ▾")}<div style="flex:1"></div>{inp("Tìm tên trường…")}</div>
{table(["", "Phần tử", "Phạm vi", "Loại DLCN", "Mức", "Nhận dạng", "Trạng thái", "Nguồn"], [
    ["☐", mono("so_dinh_danh"), "API_SCHEMA", "NATIONAL_ID", tag(ER, "SENSITIVE"), "DIRECT", tag(OK, "CONFIRMED"), "DECLARATION"],
    ["☑", mono("ho_ten"), "API_SCHEMA", "FULL_NAME", tag(WA, "RESTRICTED"), "DIRECT", tag(IN, "PROPOSED"), "SCAN"],
    ["☑", mono("so_bhxh"), "API_SCHEMA", "SOCIAL_INSURANCE_ID", tag(ER, "SENSITIVE"), "DIRECT", tag(IN, "PROPOSED"), "SCHEMA_IMPORT"],
    ["☑", mono("ngay_sinh"), "API_SCHEMA", "DATE_OF_BIRTH", tag(WA, "RESTRICTED"), "QUASI", tag(IN, "PROPOSED"), "MVP_IMPORT"],
    ["☐", mono("muc_luong"), "API_SCHEMA", "FINANCIAL_ACCOUNT", tag(MU, "Chưa phân loại"), "—", tag(ER, "Chưa xác nhận · coi như SENSITIVE"), "—"],
    ["☐", mono("ma_cskcb"), "API_SCHEMA", "NONE", tag(MU, "INTERNAL"), "NONE", tag(OK, "CONFIRMED"), "MANUAL"]], "Phần tử dữ liệu")}
<div class="decide" style="position:static;margin-top:10px"><b>Đã chọn 3 phần tử</b><span class="muted">Xác nhận hàng loạt chỉ cho phần tử PROPOSED không hạ mức</span><div style="flex:1"></div>{btn("Từ chối đề xuất")}{btn("Xác nhận 3 phần tử", "pri")}</div>
{foot("1–20 / 212")}</div></div>""")

# ---------------------------------------------------------------- 05 Sổ hoạt động xử lý
P["05"] = ("Sổ hoạt động xử lý", "Dữ liệu dùng chung › Quyền riêng tư › Hoạt động xử lý", f"""
{head("Sổ hoạt động xử lý dữ liệu cá nhân", btn("Xuất sổ ▾"), btn("+ Lập hoạt động", "pri"))}
{banner("w", "Có 23 trường dữ liệu cá nhân đã xác nhận nhưng chưa thuộc hoạt động xử lý nào (ERR-09-023).", "Xem 23 trường")}
<div class="card"><div class="toolbar">{facets(["Tất cả 38", "ACTIVE 27", "PENDING_APPROVAL 4", "DRAFT 5", "RETIRED 2"], 0)}{inp("Cơ sở pháp lý ▾")}{inp("Vai trò ▾")}<div style="flex:1"></div>{inp("Tìm tên, mã…")}</div>
{table(["Mã", "Tên hoạt động", "Mục đích", "Cơ sở pháp lý", "Vai trò", "Loại dữ liệu", "Lưu", "Phiên bản", "Trạng thái"], [
    [mono("ropa-014"), "Tra cứu hộ gia đình hưởng BHXH", mono("TTHC-BHXH"), "STATE_TASK", "CONTROLLER", "NATIONAL_ID, FULL_NAME, +4", "60 tháng", "v3", tag(OK, "ACTIVE")],
    [mono("ropa-021"), "Bản ghi vàng công dân (PH-06)", mono("TTHC-HO-TICH"), "LEGAL_OBLIGATION", "CONTROLLER", "9 loại", "Theo luật", "v2", tag(OK, "ACTIVE")],
    [mono("ropa-030"), "Đối soát thanh toán dịch vụ công", mono("THANH-TOAN"), "CONTRACT", "PROCESSOR", "FINANCIAL_ACCOUNT, +2", "120 tháng", "v1", tag(WA, "PENDING_APPROVAL")],
    [mono("ropa-033"), "Thống kê dân số theo phường", mono("THONG-KE"), "STATISTICS_RESEARCH", "CONTROLLER", "ADDRESS, DATE_OF_BIRTH", "36 tháng", "v1", tag(MU, "DRAFT")],
    [mono("ropa-008"), "Nhắn tin nhắc lịch khám (tiện ích)", mono("TIEN-ICH-NHAC"), "CONSENT", "CONTROLLER", "PHONE", "12 tháng", "v2", tag(MU, "RETIRED")]], "Hoạt động xử lý")}
{foot("1–5 / 38")}</div>""")

# ---------------------------------------------------------------- 06 Biểu mẫu hoạt động xử lý
P["06"] = ("Biểu mẫu hoạt động xử lý", "Dữ liệu dùng chung › Quyền riêng tư › Hoạt động xử lý › ropa-033 › Soạn", f"""
{head("Soạn hoạt động xử lý ropa-033 · Thống kê dân số theo phường", btn("Lưu nháp"), btn("Hủy"))}
<div class="steps"><div class="done">✓ 1 Mục đích</div><div class="done">✓ 2 Cơ sở pháp lý</div><div class="on">3 Dữ liệu và chủ thể</div><div>4 Bên nhận</div><div>5 Thời hạn lưu</div><div>6 Liên kết và gửi duyệt</div></div>
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 380px"><div class="card"><h3 style="margin:0 0 10px;font-size:15px">Bước 3. Dữ liệu và chủ thể</h3>
<div class="row"><div class="field"><label>Loại dữ liệu cá nhân *</label>{inp("ADDRESS ✕  DATE_OF_BIRTH ✕  GENDER ✕  + thêm")}</div><div class="field"><label>Nhóm chủ thể *</label>{inp("Công dân thường trú ✕  + thêm")}</div></div>
<div class="row"><div class="field"><label>Vai trò kiểm soát, xử lý *</label>{inp("CONTROLLER ▾")}</div><div class="field"><label>Mức cao nhất của trường</label>{inp("RESTRICTED (tự tính, chỉ đọc)")}</div></div>
<div class="field"><label>Biện pháp bảo vệ *</label>{inp("Che theo chính sách mask-pol-02, giả danh hóa mục đích THONG-KE, mã hóa trường ✕")}</div>
<div class="alert e" style="margin:10px 0 0">✕ Hoạt động còn thiếu: bên nhận dữ liệu, thời hạn lưu (ERR-09-020). Hoàn tất bước 4 và 5 trước khi gửi duyệt.</div>
<div class="foot">{btn("‹ Quay lại")}{btn("Tiếp tục ›", "pri")}</div></div>
<div class="card raised"><h3 style="margin:0 0 8px;font-size:15px">Tóm tắt hoạt động</h3><div class="dl" style="grid-template-columns:120px 1fr"><dt>Mục đích</dt><dd>{mono("THONG-KE")}</dd><dt>Căn cứ</dt><dd>STATISTICS_RESEARCH<br><span class="muted">Luật Dữ liệu 60/2024</span></dd><dt>Bên nhận</dt><dd class="muted">Chưa nhập</dd><dt>Thời hạn lưu</dt><dd class="muted">Chưa nhập</dd><dt>Trạng thái</dt><dd>{tag(MU, "DRAFT")} v1</dd></div>
<div class="grp-t">Mục còn thiếu</div><div class="hb">⚠ Bên nhận (bước 4)</div><div class="hb">⚠ Thời hạn lưu và hành động hết hạn (bước 5)</div></div></div>""")

# ---------------------------------------------------------------- 09 Hộp việc chấp thuận của chủ quản
P["09"] = ("Hộp việc chấp thuận của chủ quản", "Dữ liệu dùng chung › Quyền riêng tư › Chấp thuận", f"""
{head("Hộp việc chấp thuận của chủ quản dữ liệu", '<span class="muted">Chủ quản: Bảo hiểm xã hội tỉnh</span>', btn("Chấp thuận đang hiệu lực"), btn("Cảnh báo khai thác 4"))}
<div class="grid3" style="grid-template-columns:400px minmax(0,1fr)">
<div class="card"><div class="toolbar">{facets(["Chờ thẩm định 7", "Cần bổ sung 2", "Quá hạn 1"], 0)}</div>
<div class="hb" style="border-color:var(--color-primary);background:#f6f9ff"><b>ar-0208 · HT-YTE</b> <span style="float:right">{tag(WA, "còn 3 ngày")}</span><br>Hợp đồng bhxh-tra-cuu-ho-gia-dinh · {tag(ER, "SENSITIVE")}<br><span class="muted">Mục đích TTHC-BHXH · 6 trường · 12.000 lượt/ngày</span></div>
<div class="hb"><b>ar-0207 · HT-GD</b> <span style="float:right">{tag(ER, "quá hạn 1 ngày")}</span><br>Hợp đồng gd-thong-tin-hoc-sinh · {tag(WA, "RESTRICTED")}<br><span class="muted">Mục đích TTHC-HO-TICH · 4 trường</span></div>
<div class="hb"><b>ar-0205 · HT-TNMT</b> <span style="float:right">{tag(MU, "còn 8 ngày")}</span><br>Hợp đồng dat-dai-tra-cuu · {tag(WA, "RESTRICTED")}<br><span class="muted">Mục đích THONG-KE · 3 trường</span></div></div>
<div class="card"><h3 style="margin:0 0 8px;font-size:16px">ar-0208 · Yêu cầu khai thác của HT-YTE</h3>
<div class="alert w">⚠ Yêu cầu vượt mức đã duyệt cho tổ chức: 12.000 lượt/ngày so với 8.000. Có 1 cảnh báo khai thác OFF_PURPOSE trong 90 ngày (an-0409).</div>
<div class="dl" style="grid-template-columns:140px 1fr 140px 1fr"><dt>Mục đích</dt><dd>{mono("TTHC-BHXH")}</dd><dt>Căn cứ pháp lý</dt><dd>STATE_TASK · NĐ 165/2025</dd><dt>Đăng ký sử dụng</dt><dd>{mono("dk-2291")} (PH-02)</dd><dt>Thời hạn đề nghị</dt><dd>365 ngày</dd></div>
{table(["Trường", "Loại DLCN", "Mức", "Hiển thị", "Chấp thuận có sẵn"], [
    [mono("so_dinh_danh"), "NATIONAL_ID", tag(ER, "SENSITIVE"), MK("*********345"), "—"],
    [mono("ho_ten"), "FULL_NAME", tag(WA, "RESTRICTED"), "Nguyễn V** A", "Có · HT-YTE, THONG-KE"],
    [mono("so_bhxh"), "SOCIAL_INSURANCE_ID", tag(ER, "SENSITIVE"), MK("*******8821"), "—"],
    [mono("trang_thai_dong"), "NONE", tag(MU, "INTERNAL"), "Đang đóng", "—"]], "Trường yêu cầu")}
<div class="grp-t">Điều kiện khi chấp thuận có điều kiện</div><div class="chip">☑ FIELD_SUBSET: bỏ so_bhxh</div><div class="chip">☑ DAILY_QUOTA: 8.000</div><div class="chip">☑ TIME_WINDOW: 06:00–22:00</div><div class="chip">☐ NO_EXPORT</div><div class="chip">☑ MASK_REQUIRED</div>
<div class="decide" style="position:static">{btn("Yêu cầu bổ sung")}<div style="flex:1"></div>{btn("Từ chối…", "danger")}{btn("Chấp thuận có điều kiện", "pri wide")}{btn("Chấp thuận", "ok wide")}</div></div></div>""")

# ---------------------------------------------------------------- 10 Chính sách che
P["10"] = ("Chính sách che", "Dữ liệu dùng chung › Quyền riêng tư › Chính sách che", f"""
{head("Chính sách che mask-pol-01", tag(MU, "DRAFT v5"), '<span class="muted">Bản ACTIVE: v4</span>', btn("Mô phỏng"), btn("Gửi duyệt", "dis"))}
{tabs(["Quy tắc", "Kiểu che", "Log"], 0)}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 380px"><div class="card">
{table(["#", "Mức", "Loại DLCN", "Vai trò", "Mục đích", "Kênh", "Kiểu che", "Trước → sau"], [
    ["1", tag(ER, "SENSITIVE"), "NATIONAL_ID", "mặc định", "mặc định", "UI, API, EXPORT", "PARTIAL KEEP_LAST_N=3", mono("012345678901") + " → " + MK("*********901")],
    ["2", tag(ER, "SENSITIVE"), "SOCIAL_INSURANCE_ID", "mặc định", "mặc định", "mọi kênh", "KEYED_HASH", mono("8801234567") + " → " + mono("h:7f3a…")],
    ["3", tag(WA, "RESTRICTED"), "FULL_NAME", "DS, SO", "TTHC-*", "UI", "NONE", "Nguyễn Văn An → Nguyễn Văn An"],
    ["4", tag(WA, "RESTRICTED"), "FULL_NAME", "mặc định", "mặc định", "mọi kênh", "PARTIAL KEEP_FIRST_TOKEN", "Nguyễn Văn An → Nguyễn **"],
    ["5", tag(WA, "RESTRICTED"), "ADDRESS", "mặc định", "THONG-KE", "EXPORT", "GENERALIZE ADMIN_LEVEL", "12 Lê Lợi, P.3 → Phường 3"],
    ["6", tag(ER, "SENSITIVE"), "HEALTH", "mặc định", "mặc định", "LOG", "DROP", "(bỏ trường)"]], "Quy tắc che")}
<div class="alert e" style="margin:10px 0 0">✕ Quy tắc 4 và 7 trùng độ ưu tiên hoặc thiếu quy tắc mặc định cho mức SENSITIVE (ERR-09-038).</div>
<div class="foot"><span class="muted" style="flex:1;align-self:center">Gửi duyệt cần mô phỏng đạt trên bộ mẫu chuẩn (ERR-09-040)</span>{btn("+ Thêm quy tắc")}{btn("Lưu nháp")}</div></div>
<div class="card raised"><h3 style="margin:0 0 8px;font-size:15px">So với bản ACTIVE v4</h3>
{table(["Dòng", "Thay đổi", "Chi tiết"], [["2", tag(WA, "Sửa"), "PARTIAL → KEYED_HASH"], ["5", tag(OK, "Thêm"), "ADDRESS, THONG-KE, EXPORT"], ["7", tag(ER, "Xóa"), "PHONE, mọi kênh, NONE"]], "So sánh", ["d-chg", "d-add", "d-del"])}
<div class="grp-t">Phiên bản</div><div class="vtl"><div><b>v5</b> Bản nháp · Phạm Thị Hoa</div><div><b>v4</b> ACTIVE từ 12/11/2026</div><div><b>v3</b> SUPERSEDED</div></div></div></div>""")

# ---------------------------------------------------------------- 11 Mô phỏng che
P["11"] = ("Mô phỏng che", "Dữ liệu dùng chung › Quyền riêng tư › Chính sách che › Mô phỏng", f"""
{head("Mô phỏng chính sách che mask-pol-01 v5", btn("Quay lại chính sách"), btn("Chạy mô phỏng", "pri"))}
<div class="card"><div class="row"><div class="field"><label>Vai trò</label>{inp("DS ▾")}</div><div class="field"><label>Mục đích</label>{inp("TTHC-BHXH ▾")}</div><div class="field"><label>Kênh</label>{inp("API ▾")}</div><div class="field"><label>Dữ liệu mẫu (tối đa 1.000 dòng)</label>{inp("Dán hoặc tải CSV · 5 dòng giả")}</div></div></div>
<div class="card" style="margin-top:12px">{table(["Trường", "Loại DLCN", "Mẫu giả (chưa che)", "Sau che", "Quy tắc áp dụng", "Kiểu che", "Kết quả"], [
    [mono("so_dinh_danh"), "NATIONAL_ID", mono("000000000001"), MK("*********001"), "#1", "PARTIAL", tag(OK, "Đạt")],
    [mono("ho_ten"), "FULL_NAME", "Nguyễn Văn Mẫu", "Nguyễn **", "#4", "PARTIAL", tag(OK, "Đạt")],
    [mono("so_bhxh"), "SOCIAL_INSURANCE_ID", mono("0000000001"), mono("h:91c2…"), "#2", "KEYED_HASH", tag(OK, "Đạt")],
    [mono("dia_chi"), "ADDRESS", "1 Đường Mẫu, P.1", "Phường 1", "#5", "GENERALIZE", tag(OK, "Đạt")],
    [mono("dien_thoai"), "PHONE", mono("0900000001"), mono("0900000001"), "—", "NONE", tag(ER, "Rò rỉ: SĐT không được che")]], "Kết quả mô phỏng")}
<div class="alert e" style="margin:10px 0 0">✕ Mô phỏng chưa đạt: 1 dòng lộ giá trị. Sửa quy tắc rồi mô phỏng lại. Dữ liệu mẫu là giá trị giả, không dùng dữ liệu thật.</div>
<div class="foot"><span class="muted" style="flex:1;align-self:center">Thời gian chạy 1,2 giây · 5 dòng · bộ mẫu chuẩn 300 ca: 299 đạt, 1 lệch</span>{btn("Tải kết quả CSV")}</div></div>""")

# ---------------------------------------------------------------- 13 Khôi phục giá trị gốc
P["13"] = ("Khôi phục giá trị gốc", "Dữ liệu dùng chung › Quyền riêng tư › Giả danh › Khôi phục", f"""
{head("Khôi phục giá trị gốc từ token", btn("Nhật ký khôi phục"), btn("+ Đề nghị khôi phục", "pri"))}
<div class="alert w">⚠ Thao tác đặc quyền: cần ba người khác nhau, xác thực lại bằng MFA và được ghi nhật ký vĩnh viễn. Giá trị chỉ hiện 60 giây rồi bị hủy (BR-09-032).</div>
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 460px"><div class="card"><div class="toolbar">{facets(["Chờ duyệt cấp 1 1", "Chờ cấp 2 1", "Đã duyệt 1", "Đã thực hiện", "Hết hạn"], 0)}</div>
{table(["Mã", "Miền", "Số token", "Mục đích", "Căn cứ", "Người đề nghị", "Trạng thái", "Hạn"], [
    [mono("rei-0031"), mono("dom-bhxh-token"), "12", mono("DIEU-TRA"), "Công văn 118/CAT", "Nguyễn Thị Lan (SO)", tag(IN, "PENDING_L1"), "còn 22 giờ"],
    [mono("rei-0030"), mono("dom-bhxh-token"), "3", mono("KHIEU-NAI"), "Yêu cầu dsr-0087", "Nguyễn Thị Lan (SO)", tag(WA, "PENDING_L2"), "còn 9 giờ"],
    [mono("rei-0029"), mono("dom-ytế-token".replace("ế","e")), "40", mono("DIEU-TRA"), "Công văn 097/CAT", "Nguyễn Thị Lan (SO)", tag(OK, "APPROVED"), "thực hiện trong 18 phút"],
    [mono("rei-0027"), mono("dom-bhxh-token"), "8", mono("KHIEU-NAI"), "Yêu cầu dsr-0071", "Nguyễn Thị Lan (SO)", tag(MU, "EXECUTED"), "—"]], "Đề nghị khôi phục")}</div>
<div class="card"><h3 style="margin:0 0 6px;font-size:15px">rei-0029 · Chuỗi duyệt</h3>
<div class="approve"><div class="done"><b>Đề nghị</b><br>Nguyễn Thị Lan (SO)<br><span class="muted">25/11 16:02</span></div><div class="done"><b>Cấp 1 · DO</b><br>Trần Văn Hùng<br><span class="muted">✓ 25/11 17:10</span></div><div class="done"><b>Cấp 2 · TA</b><br>Lê Quốc Bảo<br><span class="muted">✓ 26/11 08:45</span></div></div>
<div class="dl" style="grid-template-columns:120px 1fr"><dt>Miền, khóa</dt><dd>{mono("dom-yte-token")} · khóa v2 {tag(IN, "DECRYPT_ONLY")}</dd><dt>Số token</dt><dd>40 (tối đa 100)</dd><dt>Căn cứ</dt><dd>Công văn 097/CAT</dd><dt>Cửa sổ thực hiện</dt><dd>còn 18 phút (30 phút)</dd></div>
<div class="alert i" style="margin:10px 0 0">ⓘ Bấm "Thực hiện" sẽ yêu cầu xác thực lại bằng MFA. Kết quả không được lưu và không đưa vào tệp.</div>
<div class="foot">{btn("Hủy đề nghị")}{btn("Thực hiện khôi phục (MFA)", "pri wide")}</div></div></div>""")

# ---------------------------------------------------------------- 14 Ẩn danh hóa và đánh giá rủi ro
P["14"] = ("Ẩn danh hóa và đánh giá rủi ro", "Dữ liệu dùng chung › Quyền riêng tư › Ẩn danh › Job anj-0017", f"""
{head("Ẩn danh hóa tập dữ liệu · job anj-0017", tag(WA, "AWAITING_RISK_REVIEW"), btn("Cấu hình"), btn("Hủy job"))}
<div class="steps"><div class="done">✓ 1 Cấu hình</div><div class="done">✓ 2 Chạy job</div><div class="on">3 Báo cáo rủi ro</div><div>4 Phát hành tập</div></div>
{kpis([kpi("k thực tế nhỏ nhất", "12", "≥ k cấu hình 10 · ARX"), kpi("Bản ghi còn lại", "96,4%", "chặn nếu thấp ngưỡng giá trị thống kê"), kpi("Rủi ro tái định danh", "0,07", "MEDIUM (từ 0,05) · mô hình PROSECUTOR"), kpi("Rủi ro tối đa theo nhóm", "0,083", "= 1/12")], 4)}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 420px"><div class="card"><h3 style="margin:0 0 8px;font-size:15px">Cấu hình biến đổi theo thuộc tính</h3>
{table(["Thuộc tính", "Nhận dạng", "Biến đổi", "Mức tổng quát hóa", "Kết quả"], [
    [mono("so_dinh_danh"), "DIRECT", "REMOVE", "—", tag(OK, "Đã loại bỏ")],
    [mono("ho_ten"), "DIRECT", "REMOVE", "—", tag(OK, "Đã loại bỏ")],
    [mono("ngay_sinh"), "QUASI", "BUCKET", "Nhóm 5 năm", tag(OK, "Đạt")],
    [mono("dia_chi"), "QUASI", "GENERALIZE", "Phường → Quận", tag(OK, "Đạt")],
    [mono("benh_man_tinh"), "SENSITIVE_ATTR", "SUPPRESS", "l-đa dạng l=3", tag(WA, "Cần duyệt")]], "Cấu hình ẩn danh")}
<div class="grp-t">Phân bố kích thước nhóm tương đương (số nhóm)</div><div class="hist"><i style="height:100%"></i><i style="height:84%"></i><i style="height:60%" class="a"></i><i style="height:42%" class="a"></i><i style="height:30%" class="a"></i><i style="height:18%" class="r"></i><i style="height:9%" class="r"></i><i style="height:5%" class="r"></i></div><div class="legend"><span>k = 12 → 40+</span><span style="flex:1"></span><span>Không có nhóm dưới k = 10</span></div></div>
<div class="card raised"><h3 style="margin:0 0 8px;font-size:15px">Khuyến nghị và phê duyệt</h3>
<div class="risk"><i style="width:70%;background:#7fc8a0"></i><i style="width:20%;background:#f0c26a"></i><i style="width:10%;background:#e3a0a0"></i></div><div class="legend"><span>LOW dưới 0,05</span><span>MEDIUM 0,05…0,10</span><span>HIGH từ 0,10</span></div>
<div class="alert w" style="margin-top:10px">⚠ Rủi ro MEDIUM: cần Cán bộ ATTT duyệt trước khi phát hành. Mục đích sử dụng: AI_TRAINING (mô hình chạy nội bộ).</div>
<div class="hb">Gợi ý: nâng nhóm tuổi lên 10 năm giảm rủi ro còn 0,04.</div>
<div class="foot">{btn("Từ chối rủi ro", "danger")}{btn("Duyệt rủi ro MEDIUM", "pri")}</div></div></div>""")

# ---------------------------------------------------------------- 16 Yêu cầu của chủ thể
P["16"] = ("Yêu cầu của chủ thể dữ liệu", "Dữ liệu dùng chung › Quyền riêng tư › Yêu cầu chủ thể", f"""
{head("Yêu cầu của chủ thể dữ liệu", btn("Báo cáo xử lý"), btn("+ Tiếp nhận yêu cầu", "pri"))}
{kpis([kpi("Đang xử lý", "11", "Hạn 10 ngày làm việc (giả định, Q09-02)"), kpi("Sắp đến hạn (≤ 3 ngày)", "3", "⚠ nhắc SO"), kpi("Quá hạn", "2", "⚠ cảnh báo SO"), kpi("Đóng trong hạn quý này", "97,6%", "Mục tiêu ≥ 98% (NFR-09-016)")], 4)}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 470px"><div class="card"><div class="toolbar">{facets(["Của tôi 5", "Sắp đến hạn 3", "Quá hạn 2", "Tất cả 11"], 0)}{inp("Loại ▾")}</div>
{table(["Mã", "Loại", "Chủ thể", "Kênh", "Nhận lúc", "Hạn", "Trạng thái"], [
    [mono("dsr-0087"), tag(IN, "ACCESS"), "Nguyễn V** A · " + MK("*********345"), "COUNTER", "18/11", tag(ER, "Quá hạn 1 ngày"), tag(IN, "IN_PROGRESS")],
    [mono("dsr-0088"), tag(WA, "RECTIFY"), "Trần T** B · " + MK("*********772"), "PUBLIC_SERVICE", "19/11", "03/12", tag(IN, "IN_PROGRESS")],
    [mono("dsr-0090"), tag(MU, "RESTRICT"), "Lê V** C · " + MK("*********012"), "DOCUMENT", "24/11", "09/12", tag(WA, "VERIFYING")],
    [mono("dsr-0091"), tag(ER, "ERASE"), "Phạm T** D · " + MK("*********508"), "EMAIL", "25/11", "10/12", tag(IN, "RECEIVED")]], "Yêu cầu chủ thể")}</div>
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">dsr-0087 · Yêu cầu truy cập</h3>
<div class="dl" style="grid-template-columns:130px 1fr"><dt>Xác minh</dt><dd>{tag(OK, "✓ VNEID")} đã xác minh 18/11</dd><dt>Băm chủ thể</dt><dd>{mono("hs:b41e…9a02")}</dd><dt>Kết quả tra cứu</dt><dd>PH-06: 1 bản ghi vàng · PH-19: 4 giao dịch · PH-13: 12 lượt truy cập</dd></div>
<div class="grp-t">Tác vụ</div><div class="hb">{tag(OK, "DONE")} Tra cứu PH-06 · bản ghi vàng {mono("0193a0c2…5e6f")}</div><div class="hb">{tag(IN, "OPEN")} PH-19 · gửi yêu cầu trích xuất giao dịch</div><div class="hb">{tag(MU, "OPEN")} Bên kiểm soát: HT-BHXH (dữ liệu đi qua)</div>
<div class="alert e" style="margin-top:10px">✕ Còn 2 tác vụ chưa hoàn tất, chưa đóng được yêu cầu (ERR-09-067).</div>
<div class="foot">{btn("Từ chối có căn cứ…", "danger")}{btn("Soạn câu trả lời")}{btn("Đóng yêu cầu", "dis")}</div></div></div>""")

# ---------------------------------------------------------------- 19 Vi phạm dữ liệu cá nhân
P["19"] = ("Vi phạm dữ liệu cá nhân", "Dữ liệu dùng chung › Quyền riêng tư › Vi phạm › VP-2026-007", f"""
{head("VP-2026-007 · Lộ tệp xuất chứa số định danh", tag(WA, "NOTIFYING"), tag(ER, "HIGH"), btn("Tải hồ sơ"), btn("+ Ghi biện pháp"))}
<div class="card"><div class="row"><div><div class="muted">Đồng hồ 72 giờ (từ phát hiện 25/11 07:40)</div><div style="font-size:30px;font-weight:700;font-variant-numeric:tabular-nums">còn 41 giờ 33 phút</div></div><div style="flex:1;min-width:360px"><div class="clock"><div style="width:33%;background:#7fc8a0"></div><div style="width:33%;background:#f0c26a"></div><div style="width:17%;background:#e8a04a"></div><div style="width:17%;background:#e3a0a0"></div></div><div class="legend"><span>0</span><span style="flex:1">24 giờ ✓ đã qua</span><span style="flex:1">48 giờ</span><span style="flex:1">60 giờ</span><span>72 giờ · hạn A05</span></div><div class="muted">Hiện tại: giờ thứ 30,5 (26/11 14:07)</div></div></div></div>
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 420px;margin-top:12px"><div class="card">{tabs(["Chi tiết", "Thông báo", "Chủ thể ảnh hưởng", "Khắc phục", "Bài học"], 1)}
{table(["Người nhận", "Hạn", "Trạng thái", "Nội dung", "Bằng chứng"], [
    ["Cục A05", "28/11 07:40", tag(WA, "DRAFT"), "Mô tả, phạm vi, biện pháp", "—"],
    ["Chủ thể ảnh hưởng (212)", "Khi rủi ro cao", tag(WA, "DRAFT"), "Thông báo gửi qua email, văn bản", "—"],
    ["Bên kiểm soát HT-YTE", "25/11 09:00", tag(OK, "SENT"), "Báo trong 24 giờ", "Biên nhận " + mono("rcpt-5521")]], "Thông báo")}
<div class="alert w" style="margin-top:10px">⚠ Hồ sơ không chứa giá trị cá nhân rõ, chỉ ghi số lượng, loại và băm (BR-09-056).</div>
<div class="foot">{btn("Không thông báo chủ thể…")}{btn("Soạn thông báo Cục A05")}{btn("Ghi đã gửi", "pri")}</div></div>
<div class="card raised"><h3 style="margin:0 0 8px;font-size:15px">Tóm tắt vụ việc</h3><div class="dl" style="grid-template-columns:120px 1fr"><dt>Nguồn</dt><dd>ANOMALY an-0409</dd><dt>Loại dữ liệu</dt><dd>NATIONAL_ID, FULL_NAME</dd><dt>Số chủ thể</dt><dd>212 (băm)</dd><dt>Ghi nhận bởi</dt><dd>Trực vận hành · SO đang xử lý</dd></div>
<div class="grp-t">Dòng thời gian</div><div class="vtl"><div><b>25/11 07:40</b> Phát hiện tệp xuất lộ (ANOMALY)</div><div><b>25/11 09:00</b> Báo bên kiểm soát</div><div><b>25/11 11:30</b> SO đánh giá HIGH</div><div><b>26/11 14:00</b> Soạn thông báo A05</div></div></div></div>""")

# ---------------------------------------------------------------- 22 Hộp thoại xem giá trị đầy đủ (nhúng vào UI-06-03)
def host06(masked=True):
    return f"""{head("Chi tiết bản ghi vàng · CITIZEN 0193a0c2", tag(OK, "ACTIVE"), btn("Lịch sử"), btn("Hợp nhất, tách"))}
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Thuộc tính (PH-06, màn của phân hệ khác)</h3>{table(["Thuộc tính", "Giá trị", "Nguồn", "Hành động"], [
    ["ho_ten", "Nguyễn V** A", src("QG-DANCU", "NAT"), ""], ["so_dinh_danh", MK("*********345"), src("QG-DANCU", "NAT"), btn("Xem đầy đủ")], ["dien_thoai", MK("*******5688"), src("HT-YTE", "REL"), btn("Xem đầy đủ")], ["dia_chi", "Phường 3, Quận Hải Châu", src("HT-TUPHAP", "SEC"), ""]], "Thuộc tính")}</div>"""

P["22b"] = ("Hộp thoại xem giá trị đầy đủ, nhập lý do", "Dữ liệu dùng chung › Dữ liệu chủ › Bản ghi vàng", host06(), f"""<div class="scrim"></div><div class="modal" role="dialog" aria-modal="true" aria-label="Xem giá trị đầy đủ">
<h3>Xem giá trị đầy đủ: so_dinh_danh</h3><div class="muted" style="margin-bottom:12px">Bản ghi vàng CITIZEN 0193a0c2 · mức SENSITIVE · mọi lần xem được ghi nhật ký</div>
<div class="field"><label>Lý do xem (tối thiểu 20 ký tự) *</label><span class="input" style="height:76px;align-items:flex-start;padding-top:8px">Đối chiếu với giấy tờ công dân mang tới quầy theo yêu cầu dsr-0087</span></div>
<div class="muted">Đã nhập 66 ký tự · còn được xem 19 lần trong giờ này · giá trị sẽ tự che sau 60 giây</div>
<div class="alert w" style="margin-top:10px">⚠ Ảnh chụp màn hình sẽ có thủy vân tên bạn và thời điểm xem.</div>
<div class="foot">{btn("Hủy")}{btn("Xem trong 60 giây", "pri")}</div></div>""")

P["22"] = ("Hộp thoại xem giá trị đầy đủ, đang đếm ngược", "Dữ liệu dùng chung › Dữ liệu chủ › Bản ghi vàng", host06(), f"""<div class="scrim"></div><div class="modal" role="dialog" aria-modal="true" aria-label="Giá trị đầy đủ">
<h3>Giá trị đầy đủ: so_dinh_danh</h3><div class="muted" style="margin-bottom:12px">Người xem Nguyễn Thị Lan · 26/11/2026 14:07 · phiếu {mono("rg-7c21")} (ISSUED)</div>
<div class="cd"><div class="ring"><span>47 s</span></div><div><b>Còn 47 giây, sau đó tự che lại</b><div class="muted">Đóng hộp thoại hoặc rời màn cũng che ngay</div></div></div>
<div class="reveal" style="margin:14px 0">000000000345</div>
<div class="alert i">ⓘ Giá trị không được ghi đĩa hay log. Người đọc màn hình nhận thông báo "Còn 47 giây" mỗi 15 giây.</div>
<div class="foot">{btn("Sao chép (bị chặn)", "dis")}{btn("Che lại ngay", "pri")}</div></div>""")

if __name__ == "__main__":
    for code, v in P.items():
        title, crumb, body = v[0], v[1], v[2]
        extra = v[3] if len(v) > 3 else ""
        if '<div class="drawer"' in body:
            extra = '<div class="drawer"' + body.split('<div class="drawer"', 1)[1]
            body = body.split('<div class="drawer"')[0]
        (OUT / f"ui-09-{code}.html").write_text(shell(code, title, crumb, body, extra), encoding="utf-8")
    print("đã sinh", len(P), "trang")
