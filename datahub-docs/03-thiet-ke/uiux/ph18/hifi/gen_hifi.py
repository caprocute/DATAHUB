#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-18-01 đến UI-18-24 (D03-06-PH18, mục "Bản hi-fi" của từng màn).

Chạy: python3 gen_hifi.py && node shot.js && python3 nen.py
Dữ liệu là giả định của tỉnh thí điểm T68: người, mã, luồng, đơn vị đều là dữ liệu giả; không có dữ liệu cá nhân thật,
địa chỉ thư luôn che, nội dung bản tin chỉ hiện khung cấu trúc hoặc giá trị đã che, bí mật chỉ hiện tham chiếu kho.
Phong cách Liquid Glass của D03-05: kính chỉ ở lớp điều hướng và lớp nổi (thanh trên, sidebar, thanh lọc, thanh thao tác
hàng loạt, Drawer, hộp thoại), bảng, biểu mẫu, payload, biểu đồ đều trên nền đặc.
"""
import pathlib

OUT = pathlib.Path(__file__).parent


def tag(k, t):
    return f"<span class='tag t-{k}'>{t}</span>"


def btn(t, k=""):
    return f'<span class="btn {k}">{t}</span>'


ST = {  # nhãn trạng thái mục DLQ: chữ kèm biểu tượng, không chỉ màu
    "NEW": ("warn", "● Mới"), "TRIAGED": ("info", "◆ Đã phân loại"), "REPLAY_PENDING": ("info", "◷ Chờ phát lại"),
    "REPLAYING": ("info", "↻ Đang phát lại"), "RESOLVED": ("ok", "✓ Đã xử lý"), "REPLAY_FAILED": ("err", "✕ Phát lại lỗi"),
    "DISCARDED": ("mute", "⊘ Đã bỏ qua"), "POISON": ("err", "☠ Thiếu ngữ cảnh"), "EXPIRED": ("mute", "⌛ Hết hạn"),
}


def st(code):
    k, t = ST[code]
    return tag(k, t)


def top():
    return ('<header class="top"><div class="logo"><b>Datahub</b> · Điều hành</div>'
            '<div class="search">Tìm mục DLQ, tham số, sự cố…  ⌘K</div><div class="sp"></div>'
            '<span class="tray">🔔 4</span><span class="tray">T68 · Tỉnh thí điểm</span><div class="avatar">LH</div></header>')


SIDE = [("g", "", ""), ("", "Tổng quan", ""), ("", "Việc của tôi", "7"), ("", "Danh mục", ""), ("", "Tích hợp", ""), ("", "Sự kiện", ""),
        ("g", "Vận hành", ""), ("s", "Tổng quan vận hành", ""), ("s", "Hàng đợi lỗi (DLQ)", "37"), ("s", "Tham số hệ thống", ""),
        ("s", "Thông báo", ""), ("s", "Lịch và bảo trì", ""), ("s", "Sự cố", "2"), ("s", "Sao lưu và khôi phục", ""), ("s", "Di trú hệ cũ", ""),
        ("g", "Quản trị", ""), ("", "Người dùng và vai trò", "")]


def side(on):
    h = ""
    for kind, name, cnt in SIDE:
        if kind == "g":
            h += f'<div class="grp">{name}</div>' if name else ""
            continue
        c = f'<span class="cnt">{cnt}</span>' if cnt else ""
        h += f'<a class="{"on " if name == on else ""}{"sub" if kind == "s" else ""}" href="#">{name}{c}</a>'
    return f'<nav class="side" aria-label="Điều hướng chính">{h}</nav>'


def page(code, title, body, extra="", scrim=False):
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-18-{code} · {title}</title><link rel="stylesheet" href="hifi.css"></head><body>
{body}{'<div class="scrim"></div>' if scrim else ''}{extra}<div class="hint">Bản hi-fi minh họa · D03-06-PH18 · UI-18-{code} · dữ liệu giả định T68</div></body></html>"""


def shell(on, crumb, title, actions, content):
    return (f'<div class="shell">{top()}{side(on)}<main><div class="crumb">{crumb}</div>'
            f'<div class="head"><h1>{title}</h1><div class="sp"></div>{actions}</div>{content}</main></div>')


def table(heads, rows, aria, cls=""):
    th = "".join(f"<th{' class=num' if h.startswith('#') else ''}>{h.lstrip('#')}</th>" for h in heads)
    body = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in rows)
    return f'<table class="{cls}" aria-label="{aria}"><thead><tr>{th}</tr></thead><tbody>{body}</tbody></table>'


def kpis(items, n=None):
    h = "".join(f'<div class="kpi{" " + c if c else ""}"><span>{a}</span><b>{b}</b><small>{s}</small></div>' for a, b, s, c in items)
    return f'<div class="kpis" style="--n:{n or len(items)}">{h}</div>'


def tabs(items, on):
    return '<div class="tabs" role="tablist">' + "".join(f'<span class="{"on" if i == on else ""}" role="tab">{i}</span>' for i in items) + "</div>"


DLQ_TABS = ["Danh sách", "Theo nhóm lỗi", "Lượt phát lại", "Thống kê và nguồn", "Sổ tay xử lý lỗi"]
CR_DLQ = "Vận hành › Hàng đợi lỗi (DLQ)"
P = {}

# ---------------------------------------------------------------- 01 Danh sách DLQ
def drow(sel, mid, src, flow, err, cls, s, n, age, pr, who):
    chk = "☑" if sel else "☐"
    return [chk, f'<span class="mono">{mid}</span>', f'<span class="mono">{src}</span>', flow, f'<span class="mono">{err}</span>',
            cls, st(s), f'<span class="num">{n}</span>', age, pr, who]


rows01 = [
    drow(1, "DLQ-7Q4K", "ph04-runtime", "Đồng bộ hộ tịch", "ERR-04-103", "TRANSIENT", "NEW", 4, "26 giờ", tag("err", "P1"), "Chưa gán"),
    drow(1, "DLQ-7Q4M", "ph04-runtime", "Đồng bộ hộ tịch", "ERR-04-103", "TRANSIENT", "NEW", 3, "25 giờ", tag("err", "P1"), "Chưa gán"),
    drow(1, "DLQ-7Q51", "ph04-runtime", "Đồng bộ hộ tịch", "ERR-04-103", "TRANSIENT", "TRIAGED", 1, "6 giờ", tag("warn", "P2"), "Lê Hà (TO)"),
    drow(0, "DLQ-7P9X", "ph10-event", "dat-dai.ho-so.v1", "ERR-10-041", "CONTRACT", "REPLAY_FAILED", 2, "19 giờ", tag("warn", "P2"), "Phạm An (IE)"),
    drow(0, "DLQ-7P2C", "ph19-inbox", "Thanh toán DVC", "ERR-19-021", "BUSINESS", "TRIAGED", 1, "14 giờ", tag("info", "P3"), "Lê Hà (TO)"),
    drow(0, "DLQ-7N8D", "ph04-runtime", "Tra cứu BHXH", "ERR-04-101", "CONTRACT", "POISON", 1, "11 giờ", tag("warn", "P2"), "Chưa gán"),
    drow(0, "DLQ-7N6A", "ph08-dq", "Kiểm chất lượng đất đai", "DQ_FAIL", "BUSINESS", "NEW", 12, "9 giờ", tag("info", "P3"), "Chưa gán"),
    drow(0, "DLQ-7M3T", "ph06-mdm", "Hợp nhất công dân", "ERR-06-077", "UNKNOWN", "NEW", 1, "5 giờ", tag("mute", "P4"), "Chưa gán"),
    drow(0, "DLQ-7M1B", "ph01-onboarding", "Kết nạp HTTT", "ERR-01-031", "BUSINESS", "TRIAGED", 1, "3 giờ", tag("info", "P3"), "Trần Vy (TA)"),
    drow(0, "DLQ-7L0Q", "ph04-runtime", "Đồng bộ hộ tịch", "ERR-04-108", "BUSINESS", "REPLAYING", 1, "42 phút", tag("warn", "P2"), "Lê Hà (TO)"),
]
filt = ('<div class="chrome" style="padding:10px 12px"><div class="row">'
        '<span class="input" style="min-width:300px">🔍 Mã mục, messageId, traceId, mã lỗi, mã luồng</span>'
        '<span class="chip">Nguồn: ph04-runtime ✕</span><span class="chip">Trạng thái: Chưa xử lý ✕</span>'
        '<span class="input">Mã lỗi ▾</span><span class="input">Lớp lỗi ▾</span><span class="input">Tuổi ▾</span><span class="input">Người xử lý ▾</span><span class="input">Ưu tiên ▾</span>'
        '<span class="muted">Xóa bộ lọc</span></div></div>')
bulk = (f'<div class="bulk" role="region" aria-label="Thao tác với mục đã chọn"><b>Đã chọn 3 mục</b><span class="muted">trong 1.284 mục đang lọc</span><span class="sp"></span>'
        f'{btn("Phân loại…")}{btn("Gán…")}{btn("↻ Phát lại 3 mục", "pri")}{btn("⊘ Bỏ qua…", "danger")}{btn("✕ Bỏ chọn")}</div>')
P["01"] = ("Danh sách DLQ", page("01", "Danh sách DLQ", shell(
    "Hàng đợi lỗi (DLQ)", CR_DLQ, "Hàng đợi lỗi (DLQ)", btn("⇩ Xuất CSV") + btn("Tạo lượt phát lại…", "pri"),
    tabs(DLQ_TABS, "Danh sách")
    + kpis([("Chưa xử lý", "1.284", "NEW, TRIAGED, REPLAY_FAILED, POISON", "on"), ("Thiếu ngữ cảnh (POISON)", "37", "+6 trong 1 giờ qua", ""),
            ("Đang phát lại", "212", "2 lượt đang chạy", ""), ("Quá 24 giờ chưa xử lý", "96", "ngưỡng 18.dlq.threshold.age-hours = 24", "")])
    + filt + bulk
    + '<div class="card">' + table(["Chọn", "Mã mục", "Nguồn", "Luồng", "Mã lỗi", "Lớp lỗi", "Trạng thái", "#Số lần", "Tuổi", "Ưu tiên", "Người xử lý"], rows01, "Danh sách mục DLQ")
    + '<div class="row" style="margin-top:8px"><span class="muted">Hiển thị 1 đến 10 trong 1.284 mục · sắp theo ưu tiên rồi tuổi giảm dần</span><span style="flex:1"></span>'
    + btn("‹ Trang trước", "dis") + btn("Trang sau ›") + "</div></div>")))

# ---------------------------------------------------------------- 01b Trạng thái của danh sách DLQ
es = lambda ic, h, p, b="": f'<div class="es"><div class="ic">{ic}</div><h4>{h}</h4><div class="muted">{p}</div><div style="margin-top:10px">{b}</div></div>'
P["01b"] = ("Bốn trạng thái của danh sách DLQ", page("01b", "Trạng thái danh sách DLQ", shell(
    "Hàng đợi lỗi (DLQ)", CR_DLQ, "Trạng thái của màn Danh sách DLQ", "",
    '<div class="banner w">⚠ Phân hệ vận hành đang ở chế độ chỉ đọc. Thay đổi tham số tạm thời không thực hiện được. (ERR-18-071)<span class="sp"></span>Từ 14:05 · PO đang xử lý</div>'
    + '<div class="statebox">'
    + f'<div class="card"><div class="muted"><b>Rỗng lần đầu (ST-03)</b></div>{es("✓", "Chưa có bản tin lỗi nào", "Bản tin lỗi từ luồng tích hợp, sự kiện và phân hệ khác sẽ hiện ở đây để bạn phát lại hoặc bỏ qua.", btn("Xem nguồn DLQ đã đăng ký"))}</div>'
    + f'<div class="card"><div class="muted"><b>Không có kết quả (ST-04)</b></div>{es("🔍", "Không tìm thấy mục DLQ phù hợp", "Đang lọc: Nguồn ph19-inbox · Trạng thái Phát lại lỗi · Tuổi trên 7 ngày", btn("Xóa bộ lọc"))}</div>'
    + f'<div class="card"><div class="muted"><b>Lỗi tải (ST-05)</b></div><div class="alert e" role="alert" style="margin-top:12px">✕ Chưa tải được danh sách mục DLQ. Thử lại sau ít phút.<span class="sp"></span>{btn("Thử lại")}</div><div class="muted">Mã truy vết 7c1e…09ab · Sao chép</div><div class="muted" style="margin-top:8px">Bốn thẻ số và thanh lọc vẫn dùng được.</div></div>'
    + f'<div class="card"><div class="muted"><b>Không có quyền (ST-07)</b></div>{es("⛔", "Bạn không có quyền xem danh sách mục DLQ", "Cần quyền PERM-18-dlq. Liên hệ quản trị tỉnh để được cấp. Người xem (VW) chỉ xem được thống kê DLQ.", btn("Mở thống kê DLQ"))}</div>'
    + "</div>")))

# ---------------------------------------------------------------- 02 DLQ theo nhóm lỗi
g = lambda sig, n, a, b, src, s, who: [f'<span class="mono" style="font-size:12px">{sig}</span>', f'<span class="num">{n}</span>', a, b, src, st(s), who, btn("Gán nhóm…") + " " + btn("↻ Phát lại nhóm")]
rows02 = [g("ph04-runtime:ho-tich-dong-bo:ERR-04-103:deliver", "842", "26/11 08:12", "27/11 09:41", "PH-04", "NEW", "Chưa gán"),
          g("ph08-dq:dat-dai-kiem-tra:DQ_FAIL:validate", "196", "26/11 22:03", "27/11 09:30", "PH-08", "NEW", "Nhóm dữ liệu"),
          g("ph10-event:dat-dai.ho-so.v1:ERR-10-041:deliver", "74", "27/11 01:15", "27/11 08:55", "PH-10", "REPLAY_FAILED", "Phạm An (IE)"),
          g("ph04-runtime:tra-cuu-bhxh:ERR-04-101:schema", "37", "27/11 02:40", "27/11 09:12", "PH-04", "POISON", "Chưa gán"),
          g("ph19-inbox:thanh-toan-dvc:ERR-19-021:receive", "21", "27/11 06:00", "27/11 09:02", "PH-19", "TRIAGED", "Lê Hà (TO)")]
detail02 = ('<div class="card"><h3>Nhóm đang chọn</h3><div class="mono" style="font-size:12px;margin-bottom:8px">ph04-runtime:ho-tich-dong-bo:ERR-04-103:deliver</div>'
            '<dl class="ctx"><dt>Số mục</dt><dd>842 (cửa sổ 24 giờ)</dd><dt>Lớp lỗi gợi ý</dt><dd>TRANSIENT, theo sổ tay ERR-04-103</dd><dt>Phát lại được</dt><dd>Có, sau khi hệ đích phục hồi</dd>'
            '<dt>Hệ đích</dt><dd>Hộ tịch điện tử · đã phục hồi lúc 09:20</dd><dt>Sự cố liên kết</dt><dd>SC-2026-0041</dd></dl>'
            '<div class="muted" style="margin:10px 0 4px">Số mục mới theo giờ</div><div class="hist">' + "".join(f'<i style="height:{h}%"></i>' for h in [8, 10, 6, 12, 30, 72, 95, 88, 60, 34, 18, 9]) + '</div>'
            f'<div class="alert w" style="margin-top:10px">⚠ 842 mục vượt ngưỡng 500 (18.dlq.replay.approval-threshold). Phát lại nhóm sẽ gửi duyệt bốn mắt.</div>'
            f'<div class="row">{btn("Xem 842 mục")}{btn("Gửi duyệt phát lại nhóm…", "pri")}</div></div>')
P["02"] = ("DLQ theo nhóm lỗi", page("02", "DLQ theo nhóm lỗi", shell(
    "Hàng đợi lỗi (DLQ)", CR_DLQ + " › Theo nhóm lỗi", "Hàng đợi lỗi (DLQ)", btn("⇩ Xuất CSV"),
    tabs(DLQ_TABS, "Theo nhóm lỗi")
    + '<div class="chrome" style="padding:10px 12px"><div class="row"><span class="input" style="min-width:280px">🔍 Dấu hiệu, mã lỗi, luồng</span><span class="chip">Cửa sổ: 24 giờ ✕</span><span class="input">Nguồn ▾</span><span class="input">Lớp lỗi ▾</span><span class="input">Trạng thái ▾</span></div></div>'
    + '<div class="grid3" style="grid-template-columns:minmax(0,1fr) 360px"><div class="card">'
    + table(["Dấu hiệu lỗi (nguồn:luồng:mã lỗi:bước)", "#Số mục", "Mục đầu", "Mục cuối", "Nguồn", "Trạng thái chính", "Người xử lý", "Hành động"], rows02, "Nhóm lỗi")
    + f'</div>{detail02}</div>')))

# ---------------------------------------------------------------- 03 Chi tiết mục DLQ
ctx03 = ('<div class="card"><h3>Ngữ cảnh lỗi</h3><dl class="ctx">'
         '<dt>Nguồn</dt><dd><span class="mono">ph04-runtime</span> · PH-04</dd><dt>Luồng</dt><dd>Đồng bộ hộ tịch <span class="mono">ho-tich-dong-bo</span> v7</dd>'
         '<dt>Bước</dt><dd><span class="mono">deliver</span></dd><dt>Mã lỗi</dt><dd><span class="mono">ERR-04-103</span> Hệ đích quá thời gian chờ · <a href="#">Sổ tay</a></dd>'
         '<dt>Lớp lỗi</dt><dd>TRANSIENT (gợi ý từ sổ tay)</dd><dt>Số lần thử ở nguồn</dt><dd>3</dd><dt>Số lần gặp</dt><dd>4 (khử trùng theo khóa DLQ)</dd>'
         '<dt>Lần đầu, lần cuối</dt><dd>26/11/2026 07:41 · 27/11/2026 09:12</dd><dt>Mã vết</dt><dd><span class="mono">00-4bf9…4736-01</span> · <a href="#">Mở vết ở PH-13</a></dd>'
         '<dt>Người xử lý</dt><dd>Lê Hà (TO) · từ 08:30</dd><dt>Ưu tiên</dt><dd>' + tag("err", "P1") + '</dd><dt>Hạn lưu giữ</dt><dd>Giữ đến khi đóng, sau đó 90 ngày</dd></dl></div>'
         '<div class="card" style="margin-top:12px"><h3>Sổ tay ERR-04-103</h3><div style="font-size:12.5px"><b>Nguyên nhân thường gặp.</b> Hệ đích chậm hoặc quá tải; mạng tới hệ đích gián đoạn.'
         '<br><b>Cách xử lý.</b> 1. Kiểm hệ đích đã phục hồi ở PH-13. 2. Phát lại mục hoặc cả nhóm. 3. Lặp lại trên 3 lần thì mở sự cố.</div>'
         '<div style="margin-top:6px">' + tag("ok", "✓ Phát lại được") + '</div></div>')
mid03 = ('<div class="card"><h3 style="display:flex;gap:8px;align-items:center">Nội dung bản tin <span class="sp"></span>' + tag("mute", "Đã che") + '</h3>'
         '<div class="muted" style="margin-bottom:8px">application/json · 18,4 KB · lưu nội tuyến · tổng kiểm tra SHA-256 khớp · bản gốc (số 0)</div>'
         '<div class="skel"><span class="m">// Khung cấu trúc, không có giá trị</span>\n{\n  <span class="k">"maHoSo"</span>: <span class="m">chuỗi · ••••</span>,\n  <span class="k">"loaiHoSo"</span>: <span class="m">chuỗi · ••••</span>,\n'
         '  <span class="k">"nguoiYeuCau"</span>: {\n    <span class="k">"hoTen"</span>: <span class="m">chuỗi · ••••</span>,\n    <span class="k">"soDinhDanh"</span>: <span class="enc">•••• đã mã hóa ở nguồn</span>,\n'
         '    <span class="k">"ngaySinh"</span>: <span class="m">ngày · ••••</span>\n  },\n  <span class="k">"coQuanXuLy"</span>: <span class="m">chuỗi · ••••</span>,\n  <span class="k">"thoiDiemNop"</span>: <span class="m">thời điểm · ••••</span>\n}</div>'
         f'<div class="row" style="margin-top:10px">{btn("👁 Xem nội dung…", "pri")}{btn("Sửa nội dung…")}<span class="muted">Cần quyền PERM-18-dlq-payload và lý do; phiếu xem 15 phút.</span></div></div>'
         '<div class="card" style="margin-top:12px"><h3>Chẩn đoán từ giám sát</h3><div style="font-size:12.5px">Vết 00-4bf9…4736-01: 3 bước, bước 3 gọi Hộ tịch điện tử hết 30.000 ms.'
         '<br>12 dòng log quanh thời điểm lỗi (đã che) · chỉ số hàng đợi hệ đích tăng từ 07:35 đến 08:10.</div>'
         '<div class="muted" style="margin-top:6px">Lấy lúc 09:41 · nguồn PH-13</div></div>')
tl03 = ('<div class="card"><h3>Dòng thời gian</h3><div class="vtl">'
        '<div><b>09:12</b> Gặp lại lần 4 · số lần gặp tăng</div><div><b>08:31</b> Lê Hà (TO) phân loại TRANSIENT, ưu tiên P1</div>'
        '<div><b>08:30</b> Lê Hà (TO) nhận việc</div><div><b>08:02</b> Lượt PL-2026-0149 phát lại · ' + tag("err", "✕ Lỗi") + ' ERR-18-107 Nguồn từ chối phát lại: hệ đích chưa sẵn sàng</div>'
        '<div><b>07:58</b> Trần Vy (TA) xem khung cấu trúc</div><div><b>26/11 07:41</b> Nhận từ topic t68.ops.dlq.v1 · trạng thái Mới</div></div>'
        '<div class="muted">Bản sửa: chưa có · Lượt phát lại: 1 · Sự cố: SC-2026-0041</div></div>')
act03 = btn("✦ Giải thích lỗi này") + btn("Phân loại…") + btn("Gán…") + btn("⊘ Bỏ qua…", "danger") + btn("↻ Phát lại", "pri")
P["03"] = ("Chi tiết mục DLQ", page("03", "Chi tiết mục DLQ", shell(
    "Hàng đợi lỗi (DLQ)", CR_DLQ + " › DLQ-7Q4K", "Mục DLQ-7Q4K " + st("TRIAGED") + " " + tag("err", "P1"), act03,
    f'<div class="col3"><div>{ctx03}</div><div>{mid03}</div><div>{tl03}</div></div>')))

# ---------------------------------------------------------------- 03b Hộp thoại xem nội dung có lý do
modal03 = ('<div class="modal" role="dialog" aria-modal="true" aria-labelledby="t03b"><h3 id="t03b">Xem nội dung bản tin DLQ-7Q4K</h3>'
           '<div class="muted" style="margin-bottom:10px">Việc xem được ghi kiểm toán. Trường đã mã hóa ở nguồn vẫn che.</div>'
           '<div class="field"><label>Mục đích *</label><div class="seg"><span class="on">Chẩn đoán</span><span>Sửa nội dung</span><span>Hỗ trợ</span></div></div>'
           '<div class="field"><label for="ly-do">Lý do *</label><div class="input cell-err" id="ly-do" style="height:64px;align-items:flex-start;padding-top:6px;color:#1a1d23">Kiểm tra</div>'
           '<div style="color:#a11a1a;font-size:12.5px;margin-top:4px">✕ Nhập lý do xem nội dung (ít nhất 10 ký tự). · 8/10</div></div>'
           '<div class="warn">Phiếu xem có hạn 15 phút (18.dlq.reveal.ttl-minutes). Hết hạn, nội dung tự che và cần lý do mới.</div>'
           f'<div class="foot">{btn("Hủy")}{btn("Xem nội dung", "dis")}</div></div>')
P["03b"] = ("Hộp thoại xem nội dung có lý do", page("03b", "Xem nội dung có lý do", shell(
    "Hàng đợi lỗi (DLQ)", CR_DLQ + " › DLQ-7Q4K", "Mục DLQ-7Q4K " + st("TRIAGED"), act03,
    f'<div class="col3"><div>{ctx03}</div><div>{mid03}</div><div>{tl03}</div></div>'), extra=modal03, scrim=True))

# ---------------------------------------------------------------- 04 Sửa payload
ed_l = '{\n  "maHoSo": "••••",\n  "loaiHoSo": "KS",\n  "nguoiYeuCau": {\n    "hoTen": "••••",\n    "soDinhDanh": "•••• đã mã hóa",\n    "ngaySinh": "27/02/1990"\n  },\n  "coQuanXuLy": "UBND-XA-0412"\n}'
P["04"] = ("Sửa payload", page("04", "Sửa payload", shell(
    "Hàng đợi lỗi (DLQ)", CR_DLQ + " › DLQ-7N8D › Sửa nội dung", "Sửa nội dung bản tin DLQ-7N8D " + st("POISON"), "",
    '<div class="alert i">ⓘ Bản gốc không bao giờ bị sửa. Lưu sẽ tạo bản sửa số 1; phát lại dùng bản sửa đã duyệt với khóa lũy đẳng DLQ-7N8D:1.</div>'
    '<div class="grid-2e"><div class="card"><h3>Bản gốc (số 0) · chỉ đọc</h3><div class="ed"><div class="ln">1\n2\n3\n4\n5\n6\n7\n8\n9\n10</div><div class="tx">' + ed_l + '</div></div></div>'
    '<div class="card"><h3>Bản sửa số 1</h3><div class="ed"><div class="ln">1\n2\n3\n4\n5\n6\n7\n8\n9\n10</div><div class="tx">{\n  "maHoSo": "••••",\n  "loaiHoSo": "KS",\n  "nguoiYeuCau": {\n    "hoTen": "••••",\n    "soDinhDanh": "•••• đã mã hóa",\n<span class="add">    "ngaySinh": "1990-02-27"</span>\n  },\n  "coQuanXuLy": "UBND-XA-0412"\n}</div></div>'
    '<div class="muted" style="margin-top:6px">Kiểm lược đồ <span class="mono">bhxh.tra-cuu.v3</span>: ✓ hợp lệ · 1 trường đổi</div></div></div>'
    '<div class="card" style="margin-top:12px"><h3>Khác biệt và kiểm soát</h3>'
    + table(["Đường dẫn trường", "Trước", "Sau", "Mức phân loại (PH-09)"], [["<span class='mono'>$.nguoiYeuCau.ngaySinh</span>", "<del>27/02/1990</del>", "<ins>1990-02-27</ins>", tag("warn", "Hạn chế")]], "Khác biệt bản sửa")
    + '<div class="alert w" style="margin-top:10px">⚠ Bản sửa có trường mức Hạn chế nên cần người thứ hai duyệt trước khi phát lại.</div>'
    '<div class="field"><label>Lý do sửa *</label><div class="input" style="color:#1a1d23">Chuẩn hóa ngày sinh về ISO 8601 theo lược đồ v3, nguồn gửi sai định dạng</div></div>'
    f'<div class="foot">{btn("Hủy")}{btn("Kiểm tra lược đồ")}{btn("Gửi duyệt bản sửa", "pri")}</div></div>')))

# ---------------------------------------------------------------- 05 Lượt phát lại
jobs = [["<span class='mono'>PL-2026-0153</span>", "Nhóm ERR-04-103 đồng bộ hộ tịch", "842", tag("info", "↻ Đang chạy"), "Lê Hà (TO)", "Trần Vy (TA)"],
        ["<span class='mono'>PL-2026-0152</span>", "Danh sách 3 mục", "3", tag("ok", "✓ Hoàn tất"), "Lê Hà (TO)", "Dưới ngưỡng"],
        ["<span class='mono'>PL-2026-0151</span>", "Bộ lọc ph10-event, 19 giờ", "74", tag("warn", "◐ Một phần"), "Phạm An (IE)", "Dưới ngưỡng"],
        ["<span class='mono'>PL-2026-0150</span>", "Nhóm DQ_FAIL đất đai", "196", tag("warn", "◷ Chờ duyệt"), "Ngô Minh (TO)", "Chờ người thứ hai"]]
items05 = [["09:41:12", "<span class='mono'>DLQ-7Q4K</span>", "0", tag("ok", "✓ Thành công"), "1,2 giây"],
           ["09:41:12", "<span class='mono'>DLQ-7Q4M</span>", "0", tag("ok", "✓ Thành công"), "0,9 giây"],
           ["09:41:11", "<span class='mono'>DLQ-7Q2A</span>", "0", tag("err", "✕ Lỗi"), "ERR-18-107 Nguồn từ chối phát lại: hệ đích trả 503"],
           ["09:41:11", "<span class='mono'>DLQ-7Q29</span>", "1", tag("ok", "✓ Thành công"), "1,4 giây"],
           ["09:41:10", "<span class='mono'>DLQ-7Q27</span>", "0", tag("info", "◷ Chờ kết quả"), "còn 29 phút chờ"]]
P["05"] = ("Lượt phát lại", page("05", "Lượt phát lại", shell(
    "Hàng đợi lỗi (DLQ)", CR_DLQ + " › Lượt phát lại › PL-2026-0153", "Lượt phát lại PL-2026-0153 " + tag("info", "↻ Đang chạy"),
    btn("⏸ Tạm dừng") + btn("Đổi tốc độ…") + btn("✕ Hủy lượt…", "danger"),
    tabs(DLQ_TABS, "Lượt phát lại")
    + '<div class="card"><div class="row"><b>Tiến độ 61%</b><span class="muted">514 trên 842 mục đã gửi · tốc độ 10 mục mỗi giây · dự kiến xong 09:47</span><span style="flex:1"></span><span class="muted">Duyệt bởi Trần Vy (TA) lúc 09:20</span></div>'
    + '<div class="prog" style="margin:8px 0 12px" role="progressbar" aria-valuenow="61" aria-valuemin="0" aria-valuemax="100"><i style="width:61%"></i></div>'
    + kpis([("Đã gửi", "514", "trên 842", ""), ("Thành công", "498", "96,9%", ""), ("Thất bại", "6", "tỷ lệ lỗi 1,2%, ngưỡng tự dừng 20%", ""), ("Chờ kết quả", "10", "hạn chờ 30 phút", ""), ("Bị loại khi tạo", "12", "9 POISON, 3 đang trong lượt khác", "")], 5)
    + '</div><div class="grid-2e" style="margin-top:12px"><div class="card"><h3>Kết quả từng mục (cập nhật mỗi 5 giây)</h3>'
    + table(["Lúc", "Mục", "Bản", "Kết quả", "Chi tiết"], items05, "Kết quả từng mục") + '</div>'
    + '<div class="card"><h3>Các lượt gần đây</h3>' + table(["Mã lượt", "Phạm vi", "#Số mục", "Trạng thái", "Người tạo", "Duyệt"], jobs, "Danh sách lượt phát lại") + "</div></div>")))

# ---------------------------------------------------------------- 06 Thống kê và nguồn
bars = "".join(f'<div><i style="height:{a}px;background:#0b5cd5"></i><i style="height:{b}px;background:#f0c26a"></i><i style="height:{c}px;background:#e3a0a0"></i></div>'
               for a, b, c in [(40, 12, 3), (52, 10, 4), (38, 9, 2), (61, 14, 5), (70, 20, 6), (44, 11, 3), (35, 8, 2), (58, 13, 4), (66, 18, 7), (90, 25, 9), (110, 22, 12), (80, 16, 6), (64, 12, 4), (120, 20, 8)])
srcs = [["<span class='mono'>ph04-runtime</span>", "PH-04", "KAFKA_TOPIC", "20", tag("ok", "● Hoạt động"), "1.012"],
        ["<span class='mono'>ph10-event</span>", "PH-10", "EVENT_LAYER", "10", tag("ok", "● Hoạt động"), "74"],
        ["<span class='mono'>ph08-dq</span>", "PH-08", "HTTP_PORT", "5", tag("ok", "● Hoạt động"), "196"],
        ["<span class='mono'>ph19-inbox</span>", "PH-19", "HTTP_PORT", "5", tag("warn", "⏸ Tạm ngừng"), "21"],
        ["<span class='mono'>ph06-mdm</span>", "PH-06", "NONE", "-", tag("ok", "● Hoạt động"), "8"]]
P["06"] = ("Thống kê và nguồn DLQ", page("06", "Thống kê và nguồn DLQ", shell(
    "Hàng đợi lỗi (DLQ)", CR_DLQ + " › Thống kê và nguồn", "Hàng đợi lỗi (DLQ)", '<span class="seg"><span>24 giờ</span><span class="on">14 ngày</span><span>90 ngày</span></span>',
    tabs(DLQ_TABS, "Thống kê và nguồn")
    + kpis([("Mục chưa xử lý", "1.284", "ngưỡng 18.dlq.threshold.depth = 1.000, đã vượt", ""), ("Mục cũ nhất chưa xử lý", "26 giờ", "ngưỡng 24 giờ", ""), ("POISON mỗi giờ", "6", "ngưỡng 10", ""), ("Tỷ lệ phát lại thành công", "94,8%", "14 ngày", ""), ("Đối soát chỉ mục với Kafka", "0 thiếu", "lần chạy 02:30 hôm nay", "")], 5)
    + '<div class="grid-2e"><div class="card"><h3>Mục mới theo ngày và lớp lỗi</h3><div class="vbars">' + bars + '</div>'
    + '<div class="legend"><span><i style="background:#0b5cd5"></i>TRANSIENT</span><span><i style="background:#f0c26a"></i>BUSINESS, CONTRACT</span><span><i style="background:#e3a0a0"></i>POISON, UNKNOWN</span><span style="margin-left:auto">Xem dạng bảng</span></div></div>'
    + '<div class="card"><h3>Chưa xử lý theo nguồn</h3>' + "".join(f'<div class="hbar"><span class="mono">{n}</span><i style="width:{w}%"></i><span class="num">{v}</span></div>' for n, w, v in [("ph04-runtime", 92, "1.012"), ("ph08-dq", 18, "196"), ("ph10-event", 8, "74"), ("ph19-inbox", 3, "21"), ("ph06-mdm", 1, "8")])
    + '<div class="muted" style="margin-top:10px">Lưu giữ: 312 mục sẽ hết hạn trong 7 ngày · dung lượng Garage của DLQ 1,8 GB · lần dọn gần nhất 03:00</div></div></div>'
    + f'<div class="card" style="margin-top:12px"><h3 style="display:flex">Nguồn DLQ đã đăng ký<span style="flex:1"></span>{btn("+ Nguồn")}{btn("Chạy đối soát ngay")}</h3>'
    + table(["Mã nguồn", "Phân hệ", "Cổng phát lại", "#Tốc độ tối đa mỗi giây", "Trạng thái", "#Mục chưa xử lý"], srcs, "Nguồn DLQ") + "</div>")))

# ---------------------------------------------------------------- 07 Sổ tay xử lý lỗi
guides = [["<span class='mono'>ERR-04-103</span>", "Hệ đích quá thời gian chờ", "PH-04", "TRANSIENT", tag("ok", "Có"), "v4 · 20/11"],
          ["<span class='mono'>ERR-04-101</span>", "Bản tin sai lược đồ", "PH-04", "CONTRACT", tag("warn", "Sau khi sửa"), "v3 · 18/11"],
          ["<span class='mono'>ERR-04-108</span>", "Lỗi chuyển đổi, mã không có trong bảng", "PH-04", "BUSINESS", tag("warn", "Sau khi sửa"), "v2 · 12/11"],
          ["<span class='mono'>ERR-10-041</span>", "Bản tin không khớp lược đồ topic", "PH-10", "CONTRACT", tag("warn", "Sau khi sửa"), "v1 · 09/11"],
          ["<span class='mono'>ERR-19-021</span>", "Thông báo thanh toán không khớp giao dịch", "PH-19", "BUSINESS", tag("err", "Không"), "v2 · 21/11"]]
drawer07 = ('<div class="drawer" role="dialog" aria-label="Soạn hướng dẫn ERR-04-103"><h3 style="margin:0 0 4px">Hướng dẫn ERR-04-103</h3><div class="muted" style="margin-bottom:10px">Dùng chung · phiên bản 4 · chủ PH-04</div>'
            '<div class="field"><label>Tiêu đề *</label><div class="input" style="color:#1a1d23">Hệ đích quá thời gian chờ</div></div>'
            '<div class="field"><label>Nguyên nhân</label><div class="input" style="height:54px;color:#1a1d23">Hệ đích chậm hoặc quá tải; mạng tới hệ đích gián đoạn</div></div>'
            '<div class="field"><label>Các bước xử lý (Markdown giới hạn)</label><div class="ed"><div class="ln">1\n2\n3</div><div class="tx">1. Kiểm hệ đích đã phục hồi ở PH-13.\n2. Phát lại mục hoặc cả nhóm.\n3. Lặp lại trên 3 lần thì mở sự cố.</div></div></div>'
            '<div class="row"><div class="field"><label>Phát lại được</label><div class="seg"><span class="on">Có</span><span>Sau khi sửa</span><span>Không</span></div></div><div class="field"><label>Lớp lỗi mặc định</label><div class="input">TRANSIENT ▾</div></div></div>'
            '<div class="field"><label>Ghi chú riêng của tỉnh T68</label><div class="input" style="height:44px;color:#1a1d23">Hộ tịch điện tử bảo trì 22:00 thứ Bảy, tránh phát lại giờ này</div></div>'
            f'<div class="foot">{btn("Hủy")}{btn("Lưu hướng dẫn", "pri")}</div></div>')
P["07"] = ("Sổ tay xử lý lỗi", page("07", "Sổ tay xử lý lỗi", shell(
    "Hàng đợi lỗi (DLQ)", CR_DLQ + " › Sổ tay xử lý lỗi", "Hàng đợi lỗi (DLQ)", "",
    tabs(DLQ_TABS, "Sổ tay xử lý lỗi")
    + '<div class="chrome" style="padding:10px 12px;margin-right:430px"><div class="row"><span class="input" style="min-width:260px">🔍 Mã lỗi hoặc tiêu đề</span><span class="input">Phân hệ ▾</span><span class="input">Lớp lỗi ▾</span><span class="input">Phát lại được ▾</span></div></div>'
    + '<div class="card" style="margin-right:430px">' + table(["Mã lỗi", "Tiêu đề", "Phân hệ", "Lớp mặc định", "Phát lại được", "Phiên bản"], guides, "Sổ tay xử lý lỗi") + "</div>"), extra=drawer07))

# ---------------------------------------------------------------- 08 Tham số
toc08 = '<div class="toc"><div class="muted" style="padding:4px 10px">Không gian tên</div>' + "".join(f'<div class="{"on" if n.startswith("18.") else ""}">{n}</div>' for n in ["onboarding. · PH-01", "02. · PH-02", "04. · PH-04", "07.rdm. · PH-07", "10. · PH-10", "14. · PH-14", "17. · PH-17", "18. · PH-18", "20. · PH-20"]) + "</div>"
STAR = ' <b title="Tham số bảo mật">★</b>'
prow = lambda k, lab, v, d, dom, lv, star, ver, cls="": [f'<span class="mono">{k}</span>' + (STAR if star else ""), lab, f'<span class="{cls}" style="display:inline-block;min-width:70px;padding:2px 6px">{v}</span>', d, dom, lv, ver]
rows08 = [prow("18.dlq.threshold.depth", "Ngưỡng số mục chưa xử lý", "1000", "1000", "10…1000000", "TENANT", 0, "v1"),
          prow("18.dlq.threshold.age-hours", "Ngưỡng tuổi mục cũ nhất (giờ)", "12", "24", "1…720", "TENANT", 0, "v3", "cell-edit"),
          prow("18.dlq.replay.batch-max", "Số mục tối đa một lượt", "60000", "10000", "100…50000", "TENANT", 0, "v1", "cell-err"),
          prow("18.dlq.replay.approval-threshold", "Ngưỡng duyệt bốn mắt phát lại", "300", "500", "10…10000", "TENANT", 1, "v2", "cell-edit"),
          prow("18.dlq.replay.rate-per-second", "Tốc độ phát lại mặc định", "10", "10", "1…100", "TENANT", 0, "v1"),
          prow("18.dlq.payload.inline-max-kb", "Ngưỡng payload nội tuyến (KB)", "256", "256", "64…256", "PLATFORM 🔒", 0, "v1"),
          prow("18.dlq.retention.closed-days", "Giữ payload mục đã đóng (ngày)", "90", "90", "30…365", "TENANT", 0, "v1")]
P["08"] = ("Tham số", page("08", "Tham số", shell(
    "Tham số hệ thống", "Vận hành › Tham số hệ thống › 18. · Hàng đợi lỗi", "Tham số hệ thống", btn("Lịch sử đổi của tỉnh") + btn("Gói tham số…"),
    tabs(["Tham số", "Cờ tính năng", "Egress", "Gói tham số"], "Tham số")
    + '<div style="display:flex;gap:14px">' + toc08 + '<div style="flex:1;min-width:0"><div class="chrome" style="padding:10px 12px"><div class="row"><span class="input" style="min-width:260px">🔍 Tìm theo khóa hoặc nhãn</span><span class="input">Nhóm: Hàng đợi lỗi ▾</span><span class="sw off"><i></i>Chỉ khóa đã khác mặc định</span></div></div>'
    + '<div class="card">' + table(["Khóa", "Nhãn", "Giá trị", "Mặc định", "Miền", "Mức", "Phiên bản"], rows08, "Tham số nhóm hàng đợi lỗi")
    + '<div style="color:#a11a1a;font-size:12.5px;margin-top:6px">✕ 18.dlq.replay.batch-max: Giá trị 60000 nằm ngoài miền cho phép của 18.dlq.replay.batch-max: 100…50000. (ERR-18-013)</div>'
    + '<div class="muted">★ là tham số bảo mật: lưu sẽ tạo đề nghị chờ người thứ hai duyệt. 🔒 PLATFORM do quản trị nền tảng đặt, tỉnh chỉ xem.</div></div>'
    + '<div class="decide"><b>3 thay đổi chưa lưu</b><span class="muted">1 lỗi · 1 khóa ★ sẽ thành đề nghị</span><span class="input" style="flex:1;color:#1a1d23">Lý do: Giảm ngưỡng cảnh báo theo yêu cầu trực ca tháng 12</span>' + btn("Bỏ thay đổi") + btn("Lưu và gửi đề nghị", "dis") + "</div></div></div>")))

# ---------------------------------------------------------------- 09 Lịch sử và đề nghị đổi
vers = [["v3", tag("warn", "◷ Chờ duyệt"), "300", "Nguyễn Thu (TA)", "27/11 09:05", "Giảm ngưỡng theo yêu cầu trực ca tháng 12"],
        ["v2", tag("ok", "● Đang dùng"), "500", "Trần Vy (TA)", "12/11 14:20", "Đưa về mặc định sau thử nghiệm"],
        ["v1", tag("mute", "Đã thay"), "200", "Trần Vy (TA)", "02/11 10:02", "Thử nghiệm tỉnh thí điểm"],
        ["v0", tag("mute", "Mặc định"), "500", "Hệ thống", "01/11 00:00", "Ghi mặc định khi khởi tạo tenant"]]
P["09"] = ("Lịch sử và đề nghị đổi tham số", page("09", "Lịch sử tham số", shell(
    "Tham số hệ thống", "Vận hành › Tham số hệ thống › 18.dlq.replay.approval-threshold › Lịch sử", '<span class="mono" style="font-size:20px">18.dlq.replay.approval-threshold</span> <b>★</b>', btn("So với mặc định"),
    '<div class="muted" style="margin:-8px 0 12px">Ngưỡng duyệt bốn mắt phát lại · INT · miền 10…10000 · mặc định 500 · mức TENANT · duyệt tại PH-18</div>'
    + '<div class="grid3" style="grid-template-columns:minmax(0,1fr) 400px"><div><div class="card"><h3>Phiên bản</h3>'
    + table(["Phiên bản", "Trạng thái", "Giá trị", "Người đổi", "Lúc", "Lý do"], vers, "Lịch sử phiên bản")
    + f'<div class="row" style="margin-top:8px">{btn("So sánh v1 và v2")}{btn("Khôi phục phiên bản v1…")}</div></div>'
    + '<div class="card" style="margin-top:12px"><h3>So sánh v2 và v3</h3>' + table(["Thuộc tính", "v2 (đang dùng)", "v3 (đề nghị)"], [["Giá trị", "<del>500</del>", "<ins>300</ins>"], ["Ảnh hưởng", "Lượt trên 500 mục cần duyệt", "Lượt trên 300 mục cần duyệt"]], "So sánh phiên bản") + "</div></div>"
    + '<div class="card" style="align-self:start"><h3>Đề nghị chờ duyệt</h3><dl class="ctx"><dt>Người đề nghị</dt><dd>Nguyễn Thu (TA)</dd><dt>Lúc</dt><dd>27/11/2026 09:05</dd><dt>Hết hạn</dt><dd>30/11/2026 09:05 (72 giờ)</dd><dt>Giá trị</dt><dd>500 → 300</dd><dt>Lý do</dt><dd>Giảm ngưỡng theo yêu cầu trực ca tháng 12</dd></dl>'
    + f'<div class="field" style="margin-top:10px"><label>Ý kiến (bắt buộc khi từ chối)</label><div class="input" style="height:44px"></div></div><div class="row">{btn("Duyệt", "dis")}{btn("Từ chối…")}</div>'
    + '<div class="muted" style="margin-top:6px" id="ly-do-duyet">Bạn là người đề nghị nên không được duyệt đề nghị này. (ERR-18-005) Bạn có thể rút đề nghị.</div><div style="margin-top:6px">' + btn("Rút đề nghị") + "</div></div></div>")))

# ---------------------------------------------------------------- 10 Cờ tính năng và egress
ff = [["<span class='mono'>ff.rdm.hybrid</span>", "Chế độ danh mục lai", "PH-07 · Võ Lan", "30/06/2027", "TENANT", '<span class="sw"><i></i>Bật</span>'],
      ["<span class='mono'>ff.dlq.group-auto-assign</span>", "Tự gán người xử lý theo nhóm lỗi", "PH-18 · Lê Hà", "06/12/2026 " + tag("warn", "còn 9 ngày"), "TENANT", '<span class="sw off"><i></i>Tắt</span>'],
      ["<span class='mono'>ff.flow.visual-diff</span>", "So sánh trực quan phiên bản luồng", "PH-04 · Phạm An", "15/03/2027", "TENANT", '<span class="sw"><i></i>Bật</span>'],
      ["<span class='mono'>ff.portal.sandbox-v2</span>", "Hộp cát thế hệ 2 của cổng nhà phát triển", "PH-15 · Đỗ Khoa", "20/11/2026 " + tag("err", "quá hạn gỡ"), "PLATFORM 🔒", '<span class="sw"><i></i>Bật</span>']]
eg = [["<span class='mono'>git.vi-du.gov.vn</span>", "443", "GIT_REPO", "PH-15", "27/11/2027", btn("Gỡ…")],
      ["<span class='mono'>*.hook.vi-du.gov.vn</span>", "443", "WEBHOOK", "PH-10", "01/06/2027", btn("Gỡ…")]]
P["10"] = ("Cờ tính năng và egress", page("10", "Cờ tính năng và egress", shell(
    "Tham số hệ thống", "Vận hành › Tham số hệ thống › Cờ tính năng", "Tham số hệ thống", btn("+ Cờ tính năng", "pri"),
    tabs(["Tham số", "Cờ tính năng", "Egress", "Gói tham số"], "Cờ tính năng")
    + '<div class="alert w">⚠ 2 cờ sắp đến hoặc đã quá ngày gỡ. Hệ thống đã tạo việc cho chủ sở hữu; cờ không tự tắt.</div>'
    + '<div class="card">' + table(["Khóa cờ", "Mô tả", "Chủ sở hữu", "Ngày gỡ dự kiến", "Mức", "Giá trị cho T68"], ff, "Cờ tính năng") + "</div>"
    + f'<div class="card" style="margin-top:12px"><h3 style="display:flex">Xem trước tab Egress: đích cho phép của T68 (2 trên tối đa 200)<span style="flex:1"></span>{btn("+ Đích egress")}</h3>'
    + table(["Tên miền", "Cổng", "Mục đích", "Phân hệ dùng", "Hạn dùng", ""], eg, "Đích egress")
    + '<div class="muted" style="margin-top:6px">Chỉ chấp nhận tên miền công khai qua HTTPS; không nhận địa chỉ IP, dải nội bộ, ký tự đại diện quá một cấp.</div></div>')))

# ---------------------------------------------------------------- 11 Mẫu và quy tắc thông báo
tpl = [["<span class='mono'>ph01.review-decided</span>", "Thư", "PH-01", "v3", tag("ok", "● Đang dùng"), "Dùng chung"],
       ["<span class='mono'>ph18.dlq-threshold</span>", "Trong ứng dụng", "PH-18", "v2", tag("ok", "● Đang dùng"), "T68"],
       ["<span class='mono'>ph18.incident-sev1</span>", "SMS", "PH-18", "v1", tag("warn", "◷ Chờ duyệt"), "T68"],
       ["<span class='mono'>ops.maintenance</span>", "Thư", "PH-18", "v4", tag("mute", "Nháp v5"), "T68"],
       ["<span class='mono'>ph02.api-deprecated</span>", "Thư", "PH-02", "v1", tag("mute", "Đã ngừng"), "Dùng chung"]]
rules = [["<span class='mono'>t68.ops.dlq.threshold-crossed.v1</span>", "type == 'DEPTH'", "ph18.dlq-threshold", "Vai trò TO", "Cao", '<span class="sw"><i></i>Bật</span>'],
         ["<span class='mono'>t68.obs.security-alert.raised.v1</span>", "(mọi sự kiện)", "ph18.incident-sev1", "Lịch trực", "Khẩn", '<span class="sw"><i></i>Bật</span>'],
         ["<span class='mono'>t68.onboarding.review.decided.v1</span>", "decision == 'REJECTED'", "ph01.review-decided", "Đầu mối HTTT", "Thường", '<span class="sw off"><i></i>Tắt (lớp phủ T68)</span>']]
P["11"] = ("Mẫu và quy tắc thông báo", page("11", "Mẫu và quy tắc thông báo", shell(
    "Thông báo", "Vận hành › Thông báo › Mẫu", "Thông báo", btn("Nhật ký gửi") + btn("+ Mẫu thông báo", "pri"),
    tabs(["Mẫu", "Quy tắc", "Danh sách chặn"], "Mẫu")
    + '<div class="chrome" style="padding:10px 12px"><div class="row"><span class="input" style="min-width:260px">🔍 Mã mẫu</span><span class="input">Kênh ▾</span><span class="input">Phân hệ ▾</span><span class="input">Trạng thái ▾</span><span class="chip">Gồm mẫu dùng chung ✕</span></div></div>'
    + '<div class="card">' + table(["Mã mẫu", "Kênh", "Phân hệ chủ", "Phiên bản dùng", "Trạng thái", "Phạm vi"], tpl, "Mẫu thông báo") + "</div>"
    + f'<div class="card" style="margin-top:12px"><h3 style="display:flex">Xem nhanh tab Quy tắc: sự kiện sang mẫu và người nhận<span style="flex:1"></span>{btn("+ Quy tắc")}</h3>'
    + table(["Sự kiện", "Điều kiện", "Mẫu", "Người nhận", "Mức", "Hiệu lực"], rules, "Quy tắc thông báo") + "</div>")))

# ---------------------------------------------------------------- 12 Soạn mẫu
vars12 = [["<span class='mono'>systemCode</span>", tag("ok", "PUBLIC"), "HTTT-0412"], ["<span class='mono'>link</span>", tag("ok", "PUBLIC"), "đường dẫn tới hồ sơ"],
          ["<span class='mono'>decision</span>", tag("info", "INTERNAL"), "Chấp thuận"], ["<span class='mono'>contactPhone</span>", tag("err", "RESTRICTED ✕"), "không cho dùng"]]
P["12"] = ("Soạn mẫu thông báo", page("12", "Soạn mẫu thông báo", shell(
    "Thông báo", "Vận hành › Thông báo › Mẫu › ph01.review-decided › Phiên bản 4 (nháp)", '<span class="mono" style="font-size:20px">ph01.review-decided</span> ' + tag("mute", "Nháp v4"), "",
    '<div class="grid-2e"><div class="card"><h3>Nội dung phiên bản 4 · Thư · tiếng Việt</h3>'
    '<div class="field"><label>Tiêu đề thư *</label><div class="input" style="color:#1a1d23">Hồ sơ {{systemCode}} đã có kết quả</div></div>'
    '<div class="field"><label>Thân thư (Mustache không logic) *</label><div class="ed"><div class="ln">1\n2\n3\n4\n5\n6</div><div class="tx">Kính gửi đầu mối HTTT,\n\nHồ sơ kết nạp {{systemCode}} đã có kết quả: {{decision}}.\n<span class="err">Liên hệ lại số {{contactPhone}} nếu cần.</span>\nXem chi tiết tại {{link}}.\nTrân trọng, Datahub T68</div></div>'
    '<div style="color:#a11a1a;font-size:12.5px;margin-top:4px">✕ Mẫu dùng trường contactPhone mức RESTRICTED. Thư chỉ được chứa liên kết, không chứa dữ liệu mức Hạn chế hoặc Nhạy cảm. (ERR-18-039) · dòng 4</div></div>'
    '<h3 style="margin-top:6px">Biến đã khai báo</h3>' + table(["Biến", "Mức phân loại", "Ví dụ"], vars12, "Biến của mẫu") + '</div>'
    '<div class="card"><h3>Xem thử với dữ liệu mẫu</h3><div class="mail"><div class="mh"><b>Từ:</b> Datahub T68 · <b>Tới:</b> n***@t68.gov.vn<br><b>Tiêu đề:</b> Hồ sơ HTTT-0412 đã có kết quả</div>'
    '<div class="mb">Kính gửi đầu mối HTTT,<br><br>Hồ sơ kết nạp HTTT-0412 đã có kết quả: Chấp thuận.<br><span style="background:#fde8e8">[đã chặn: contactPhone]</span><br>Xem chi tiết tại <a href="#">đường dẫn tới hồ sơ</a>.<br>Trân trọng, Datahub T68</div></div>'
    '<div class="gate" style="margin-top:12px"><div><b style="color:#0b6b3a">✓ Đạt</b>Cú pháp Mustache không logic</div><div><b style="color:#0b6b3a">✓ Đạt</b>Mọi biến đã khai báo</div><div><b style="color:#a11a1a">✕ Chưa</b>Không dùng trường mức Hạn chế, Nhạy cảm</div><div><b style="color:#0b6b3a">✓ Đạt</b>Tiêu đề ≤ 200 ký tự</div></div>'
    f'<div class="foot">{btn("Lưu nháp")}{btn("Xem thử lại")}{btn("Gửi duyệt", "dis")}</div></div></div>')))

# ---------------------------------------------------------------- 13 Nhật ký gửi thông báo
dl13 = [["27/11 09:40", "ph18.dlq-threshold", "Trong ứng dụng", "Lê Hà (TO)", tag("ok", "✓ Đã nhận"), "1", "PH-18"],
        ["27/11 09:21", "ph01.review-decided", "Thư", "n***@t68.gov.vn", tag("err", "↩ Bị trả lại"), "1", "PH-01"],
        ["27/11 09:05", "ph18.approve-param", "Trong ứng dụng", "Trần Vy (TA)", tag("ok", "✓ Đã nhận"), "1", "PH-18"],
        ["27/11 08:47", "ph18.incident-sev1", "SMS", "09*****321", tag("warn", "↻ Đang thử lại"), "3", "PH-18"],
        ["27/11 02:10", "ops.maintenance", "Thư", "h***@t68.gov.vn", tag("mute", "⊘ Hoãn giờ yên lặng"), "0", "PH-18"],
        ["26/11 22:30", "ph02.api-deprecated", "Thư", "k***@vi-du.gov.vn", tag("mute", "⊘ Chặn"), "0", "PH-02"]]
drawer13 = ('<div class="drawer" role="dialog" aria-label="Chi tiết lần gửi"><h3 style="margin:0 0 4px">Lần gửi thư bị trả lại</h3><div class="muted" style="margin-bottom:10px">ph01.review-decided v3 · tới n***@t68.gov.vn</div>'
            '<dl class="ctx"><dt>Trạng thái</dt><dd>' + tag("err", "↩ Bị trả lại") + ' cứng</dd><dt>Mã máy chủ thư</dt><dd>550 5.1.1 hộp thư không tồn tại</dd><dt>Nguồn</dt><dd>PH-01 · quy tắc dùng chung</dd>'
            '<dt>Người nhận</dt><dd>Đầu mối HTTT-0412 (tham chiếu, đã che)</dd><dt>Danh sách chặn</dt><dd>Đã thêm 09:21 · thông báo PH-01 cập nhật đầu mối</dd></dl>'
            '<h3 style="margin-top:12px;font-size:14px">Lịch sử thử</h3><div class="vtl"><div><b>09:21:04</b> Máy chủ thư báo trả lại (ERR-18-112)</div><div><b>09:21:01</b> Đã gửi tới máy chủ thư</div><div><b>09:21:00</b> Xếp hàng</div></div>'
            '<div class="muted">Nội dung đã dựng không lưu; xem lại bằng Xem thử mẫu với dữ liệu mẫu.</div>'
            f'<div class="foot">{btn("Gỡ khỏi danh sách chặn…")}{btn("Gửi lại", "pri")}</div></div>')
P["13"] = ("Nhật ký gửi thông báo", page("13", "Nhật ký gửi thông báo", shell(
    "Thông báo", "Vận hành › Thông báo › Nhật ký gửi", "Nhật ký gửi thông báo", "",
    '<div class="chrome" style="padding:10px 12px;margin-right:430px"><div class="row"><span class="input">Loại mẫu ▾</span><span class="input">Kênh ▾</span><span class="chip">Trạng thái: Lỗi, Bị trả lại ✕</span><span class="input">Người nhận (mã) ▾</span><span class="input">27/11 00:00 đến nay</span></div></div>'
    + kpis([("Đã gửi 24 giờ", "3.412", "", ""), ("Bị trả lại", "4", "", ""), ("Lỗi sau 5 lần", "1", "", ""), ("Hoãn hoặc chặn", "37", "", "")], 4).replace('class="kpis"', 'class="kpis" style="margin-right:430px"')
    + '<div class="card" style="margin-right:430px">' + table(["Lúc", "Mẫu", "Kênh", "Người nhận (đã che)", "Trạng thái", "#Lần thử", "Nguồn"], dl13, "Nhật ký gửi") + "</div>"), extra=drawer13))

# ---------------------------------------------------------------- 14 Tùy chọn nhận thông báo
sw = lambda on, lock=False: (f'<span class="sw{"" if on else " off"}"><i></i></span>' + (' <span class="lock">🔒 bắt buộc</span>' if lock else ""))
pref = [["Việc chờ tôi duyệt (bốn mắt)", sw(1, 1), sw(1), sw(0), "Bắt buộc"], ["Cảnh báo an ninh, sự cố khẩn", sw(1, 1), sw(1, 1), sw(1), "Bắt buộc, vượt giờ yên lặng"],
        ["Thay đổi API bắt buộc (BR-02-029)", sw(1, 1), sw(1), sw(0), "Bắt buộc"], ["Mục DLQ được gán cho tôi", sw(1), sw(1), sw(0), ""],
        ["Kết quả lượt phát lại tôi tạo", sw(1), sw(0), sw(0), ""], ["Bảo trì và phát hành", sw(1), sw(1), sw(0), ""], ["Tin tức nền tảng", sw(0), sw(1), sw(0), ""]]
P["14"] = ("Tùy chọn nhận thông báo", page("14", "Tùy chọn nhận thông báo", shell(
    "", "Cá nhân › Thông báo › Tùy chọn nhận", "Thông báo của tôi", "",
    tabs(["Thông báo", "Tùy chọn nhận"], "Tùy chọn nhận")
    + '<div style="display:flex;gap:14px"><div class="toc"><div class="on">Nhóm thông báo và kênh</div><div>Giờ yên lặng</div></div><div style="flex:1;min-width:0">'
    + '<div class="card"><h3>Nhóm thông báo và kênh</h3>' + table(["Nhóm thông báo", "Trong ứng dụng", "Thư", "SMS", "Ghi chú"], pref, "Tùy chọn kênh nhận", "matrix")
    + '<div class="muted" style="margin-top:6px">SMS chỉ dùng được khi tỉnh bật kênh SMS (18.notify.sms.enabled). Nhóm bắt buộc không tắt được.</div></div>'
    + '<div class="card" style="margin-top:12px"><h3>Giờ yên lặng</h3><div class="row"><div class="field"><label>Từ</label><div class="input" style="color:#1a1d23">22:00</div></div><div class="field"><label>Đến</label><div class="input" style="color:#1a1d23">06:00</div></div>'
    + '<div class="muted" style="flex:2">Trong giờ yên lặng, thông báo thường được giữ đến hết giờ (tối đa 12 giờ); thông báo khẩn vẫn gửi ngay. Mặc định của tỉnh: 22:00 đến 06:00.</div></div>'
    + f'<div class="foot">{btn("Đưa về mặc định")}{btn("Lưu tùy chọn", "pri")}</div></div></div></div>')))

# ---------------------------------------------------------------- 15 Việc của tôi
task = lambda on, t, ph, due, dk, who: (f'<div class="node2{" on" if on else ""}"><div class="row"><b style="flex:1">{t}</b>{tag(dk, due)}</div><div class="muted">{ph} · {who}</div></div>')
list15 = (task(1, "Duyệt lượt phát lại PL-2026-0150 (196 mục)", "PH-18 · Hàng đợi lỗi", "Quá hạn 3 giờ", "err", "Ngô Minh đề nghị")
          + task(0, "Duyệt tham số ★ 18.dlq.replay.approval-threshold", "PH-18 · Tham số", "Hôm nay 17:00", "warn", "Nguyễn Thu đề nghị")
          + task(0, "Duyệt bản sửa nội dung DLQ-7N8D số 1", "PH-18 · Hàng đợi lỗi", "Hôm nay 18:00", "warn", "Phạm An đề nghị")
          + task(0, "Duyệt kết nạp HTTT-0412", "PH-01 · Kết nạp", "28/11", "info", "Sở Tư pháp gửi")
          + task(0, "Duyệt phiên bản mẫu ph18.incident-sev1 v1", "PH-18 · Thông báo", "29/11", "info", "Lê Hà đề nghị")
          + task(0, "Xử lý mục DLQ-7Q51 được gán", "PH-18 · Hàng đợi lỗi", "02/12", "mute", "Gán bởi Lê Hà"))
det15 = ('<div class="card"><h3>Duyệt lượt phát lại PL-2026-0150</h3><dl class="ctx"><dt>Phạm vi</dt><dd>Nhóm DQ_FAIL kiểm chất lượng đất đai, 196 mục (ngưỡng duyệt 100 của tỉnh khác mặc định)</dd>'
         '<dt>Người đề nghị</dt><dd>Ngô Minh (TO) · 27/11 06:10</dd><dt>Bị loại khi tạo</dt><dd>4 mục POISON</dd><dt>Tốc độ</dt><dd>5 mục mỗi giây (trần nguồn 5)</dd><dt>Hạn</dt><dd>27/11 06:10 + 3 giờ · ' + tag("err", "Quá hạn") + '</dd></dl>'
         '<div class="field" style="margin-top:10px"><label>Ý kiến</label><div class="input" style="height:44px;color:#1a1d23">Đã kiểm bản sửa quy tắc DQ ở PH-08, đồng ý phát lại</div></div>'
         f'<div class="row">{btn("Duyệt", "ok")}{btn("Từ chối…")}{btn("Mở màn lượt phát lại ↗")}</div><div class="muted" style="margin-top:6px">Việc tự đóng khi lượt được duyệt hoặc từ chối ở bất kỳ màn nào.</div></div>')
P["15"] = ("Việc của tôi", page("15", "Việc của tôi", shell(
    "Việc của tôi", "Cá nhân › Việc của tôi", "Việc của tôi", "",
    '<div class="facets"><span class="on">Tất cả 7</span><span>Quá hạn 1</span><span>Hôm nay 2</span><span>Tuần này 6</span><span>Phân hệ ▾</span><span>Loại việc ▾</span></div>'
    + f'<div class="grid3" style="grid-template-columns:440px minmax(0,1fr)"><div>{list15}</div>{det15}</div>')))

# ---------------------------------------------------------------- 16 Lịch, bảo trì và đóng băng
days = ""
for i in range(35):
    d = i  # 1/12/2026 là thứ Ba (cột thứ hai)
    cls, note = [], ""
    if d < 1 or d > 31:
        cls.append("out"); num = ""
    else:
        num = str(d)
        wd = i % 7
        if wd in (5, 6):
            cls.append("we")
        if d == 13:
            cls.append("mt"); note = "Bảo trì 22:00–02:00 PROD"
        if d >= 21:
            cls.append("fz"); note = note or ("Đóng băng PROD" if d == 21 else "")
        if d == 26:
            note = "Làm bù (giả định)"; cls = [c for c in cls if c != "we"]
    days += f'<div class="{" ".join(cls)}"><span>{num}</span><em>{note}</em></div>'
cal = '<div class="cal">' + "".join(f"<b>{x}</b>" for x in ["Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy", "Chủ nhật"]) + days + "</div>"
wins = [["<span class='mono'>CS-2026-031</span>", "Bảo trì", "PROD", "13/12 22:00", "14/12 02:00", tag("info", "Sắp tới"), "Có, trước 72 giờ"],
        ["<span class='mono'>CS-2026-032</span>", "Đóng băng", "PROD, STAGING", "21/12 00:00", "04/01 23:59", tag("info", "Sắp tới"), "Có"],
        ["<span class='mono'>CS-2026-027</span>", "Bảo trì", "TEST", "22/11 20:00", "22/11 23:00", tag("mute", "Đã xong"), "Không"]]
P["16"] = ("Lịch, bảo trì và đóng băng", page("16", "Lịch, bảo trì và đóng băng", shell(
    "Lịch và bảo trì", "Vận hành › Lịch và bảo trì", "Lịch, bảo trì và đóng băng", btn("+ Ngày lễ hoặc ngày làm bù") + btn("+ Cửa sổ bảo trì hoặc đóng băng", "pri"),
    tabs(["Lịch tháng", "Lịch năm 2027", "Cửa sổ"], "Lịch tháng")
    + '<div class="grid3" style="grid-template-columns:minmax(0,1fr) 330px"><div class="card"><h3 style="display:flex">‹ Tháng 12 năm 2026 ›<span style="flex:1"></span><span class="legend"><span><i style="background:#f7f8fa;border:1px solid #ccc"></i>Cuối tuần</span><span><i style="background:#fde8e8"></i>Ngày lễ</span><span><i style="background:#fff4d6"></i>Đóng băng</span><span><i style="background:#fff;outline:2px solid #7146c7"></i>Bảo trì</span></span></h3>' + cal + "</div>"
    + '<div class="card" style="align-self:start"><h3>Ngày lễ năm 2027 (T68)</h3><div class="vtl"><div><b>01/01</b> Tết Dương lịch</div><div><b>05/02 đến 09/02</b> Tết Nguyên đán (giả định theo lịch nhà nước)</div><div><b>16/04</b> Giỗ Tổ Hùng Vương</div><div><b>30/04, 01/05</b> Ngày Chiến thắng, Quốc tế lao động</div><div><b>02/09</b> Quốc khánh</div></div><div class="muted">Nguồn: sao từ lịch dùng chung · cuối tuần SAT, SUN · múi giờ Asia/Ho_Chi_Minh</div></div></div>'
    + '<div class="card" style="margin-top:12px"><h3>Cửa sổ bảo trì và đóng băng</h3>' + table(["Mã", "Loại", "Môi trường", "Bắt đầu", "Kết thúc", "Trạng thái", "Báo trước"], wins, "Cửa sổ") + "</div>")))

# ---------------------------------------------------------------- 17 Danh sách sự cố
sev = {"SEV1": "err", "SEV2": "warn", "SEV3": "info", "SEV4": "mute"}
inc = lambda c, t, s, stt, sk, src, who, opn, ack: [f"<span class='mono'>{c}</span>", t, tag(sev[s], s), tag(sk, stt), src, who, opn, ack]
rows17 = [inc("SC-2026-0042", "Cảnh báo an ninh: đăng nhập bất thường cổng API", "SEV1", "Đang điều tra", "warn", "EVT-13-04", "Đinh Quang (SO)", "27/11 09:30", "6 phút"),
          inc("SC-2026-0041", "DLQ đồng bộ hộ tịch vượt ngưỡng 1.000 mục", "SEV2", "Đã giảm thiểu", "info", "DLQ vượt ngưỡng", "Lê Hà (TO)", "27/11 08:15", "14 phút"),
          inc("SC-2026-0040", "Bản sao cơ sở pg-core trễ quá 26 giờ", "SEV2", "Đã khắc phục", "ok", "Sao lưu lỗi", "Hoàng Nam (PO)", "26/11 03:05", "22 phút"),
          inc("SC-2026-0039", "Chậm phản hồi tra cứu BHXH giờ cao điểm", "SEV3", "Mở", "warn", "Tạo tay", "Chưa gán", "26/11 15:40", "-"),
          inc("SC-2026-0036", "Mất kết nối SMS gateway 20 phút", "SEV3", "Đã đóng", "mute", "Tạo tay", "Lê Hà (TO)", "22/11 10:12", "9 phút")]
P["17"] = ("Danh sách sự cố", page("17", "Danh sách sự cố", shell(
    "Sự cố", "Vận hành › Sự cố", "Sự cố vận hành", btn("+ Tạo sự cố", "pri"),
    kpis([("Đang mở", "4", "1 SEV1 · 2 SEV2 · 1 SEV3", "on"), ("Chưa ai nhận", "1", "SEV3, mở 18 giờ", ""), ("Thời gian nhận trung vị", "12 phút", "30 ngày, chỉ tiêu SEV1 15 phút", ""), ("Có dữ liệu cá nhân", "0", "chuyển PH-09 khi có", "")])
    + '<div class="chrome" style="padding:10px 12px"><div class="row"><span class="input" style="min-width:260px">🔍 Mã hoặc tiêu đề</span><span class="chip">Trạng thái: chưa đóng ✕</span><span class="input">Mức ▾</span><span class="input">Loại ▾</span><span class="input">Người xử lý ▾</span><span class="input">Nguồn ▾</span></div></div>'
    + '<div class="card">' + table(["Mã", "Tiêu đề", "Mức", "Trạng thái", "Nguồn", "Người xử lý", "Mở lúc", "Thời gian nhận"], rows17, "Danh sách sự cố") + "</div>")))

# ---------------------------------------------------------------- 18 Chi tiết sự cố
P["18"] = ("Chi tiết sự cố", page("18", "Chi tiết sự cố", shell(
    "Sự cố", "Vận hành › Sự cố › SC-2026-0041", "SC-2026-0041 " + tag("warn", "SEV2") + " " + tag("info", "Đã giảm thiểu"),
    btn("Đổi mức…") + btn("Gán…") + btn("Chuyển PH-09…") + btn("Chuyển: Đã khắc phục", "pri"),
    '<div class="muted" style="margin:-8px 0 12px">DLQ đồng bộ hộ tịch vượt ngưỡng 1.000 mục · Loại AVAILABILITY · mở 27/11 08:15 từ sự kiện vượt ngưỡng DLQ · nhận sau 14 phút (chỉ tiêu SEV2 60 phút)</div>'
    + '<div class="steps"><div class="done">✓ Mở</div><div class="done">✓ Đang điều tra</div><div class="on">● Đã giảm thiểu</div><div>Đã khắc phục</div><div>Đã đóng</div></div>'
    + '<div class="grid3" style="grid-template-columns:minmax(0,1fr) 380px"><div class="card"><h3 style="display:flex">Mốc thời gian<span style="flex:1"></span>' + btn("+ Thêm mốc") + '</h3><div class="vtl">'
    + '<div><b>09:41 · Hành động</b> Lượt PL-2026-0153 chạy 61%, tỷ lệ lỗi 1,2%</div><div><b>09:20 · Quyết định</b> Trần Vy (TA) duyệt phát lại nhóm 842 mục</div>'
    + '<div><b>09:18 · Ghi chú</b> Hộ tịch điện tử đã phục hồi, độ trễ về 300 ms</div><div><b>08:40 · Liên lạc</b> Đã báo đơn vị chủ quản Hộ tịch qua thư</div>'
    + '<div><b>08:29 · Hệ thống</b> Lê Hà (TO) nhận sự cố</div><div><b>08:15 · Hệ thống</b> Mở từ sự kiện vượt ngưỡng DEPTH của ph04-runtime</div></div>'
    + '<div class="muted">Mốc không sửa được sau 15 phút; sửa nhầm bằng mốc đính chính.</div></div>'
    + '<div><div class="card"><h3>Liên kết</h3>' + table(["Loại", "Đối tượng"], [["Nhóm DLQ", "ph04-runtime:ho-tich-dong-bo:ERR-04-103"], ["Lượt phát lại", "PL-2026-0153"], ["Cảnh báo PH-13", "Độ trễ hệ đích hộ tịch"]], "Liên kết sự cố") + "</div>"
    + '<div class="card" style="margin-top:12px"><h3>Dữ liệu cá nhân</h3><div style="font-size:13px">Chưa xác định. Bấm "Chuyển PH-09…" nếu sự cố làm lộ dữ liệu cá nhân; PH-09 giữ đồng hồ 72 giờ.</div></div>'
    + '<div class="card" style="margin-top:12px"><h3>Đóng sự cố</h3><div style="font-size:13px">Cần nguyên nhân gốc và bài học, mỗi phần ít nhất 30 ký tự, và các việc khắc phục có người, hạn. Mở được sau khi sự cố ở trạng thái Đã khắc phục.</div></div></div></div>')))

# ---------------------------------------------------------------- 19 Bảng điều khiển sao lưu
bk = lambda o, tool, last, fresh, fk, keep, ver, vk: [o, tool, last, tag(fk, fresh), keep, tag(vk, ver)]
rows19 = [bk("PostgreSQL pg-core, bản sao cơ sở", "CNPG, Barman", "27/11 01:00", "✕ Trễ 32 giờ", "err", "30 ngày", "✓ Đạt 26/11", "ok"),
          bk("PostgreSQL pg-core, WAL", "CNPG, Barman", "27/11 09:40", "✓ Đúng hạn", "ok", "30 ngày", "✓ PITR ngẫu nhiên đạt", "ok"),
          bk("Xuất logic theo tenant T68", "dh-tenant-export", "27/11 02:15", "✓ Đúng hạn", "ok", "30 ngày", "✓ Đạt 27/11", "ok"),
          bk("Garage, bucket dh-t68-*", "rclone", "27/11 03:00", "✓ Đúng hạn", "ok", "90 ngày", "◐ Đạt chậm", "warn"),
          bk("OpenBao, ảnh chụp", "OpenBao", "27/11 00:30", "✓ Đúng hạn", "ok", "90 ngày", "✓ Đạt 25/11", "ok"),
          bk("Kubernetes, tài nguyên cụm", "Velero", "26/11 23:00", "? Không rõ", "mute", "14 ngày", "- Chưa kiểm", "mute"),
          bk("ClickHouse, nhật ký giám sát", "clickhouse-backup", "27/11 04:00", "✓ Đúng hạn", "ok", "30 ngày", "✓ Đạt 24/11", "ok"),
          bk("Kho kiểm toán WORM", "rclone", "27/11 04:30", "✓ Đúng hạn", "ok", "5 năm", "✓ Chuỗi băm hợp lệ", "ok")]
P["19"] = ("Bảng điều khiển sao lưu", page("19", "Bảng điều khiển sao lưu", shell(
    "Sao lưu và khôi phục", "Vận hành › Sao lưu và khôi phục", "Sao lưu và khôi phục", btn("Khôi phục, xuất, sáp nhập ›") + btn("+ Ghi nhận diễn tập DR…"),
    tabs(["Bảng điều khiển", "Kiểm tra khôi phục", "Diễn tập DR"], "Bảng điều khiển")
    + '<div class="alert e" role="alert">✕ Bản sao cơ sở pg-core trễ 32 giờ (ngưỡng 18.backup.stale-hours = 26 giờ). Đã mở sự cố SC-2026-0040.<span class="sp"></span>' + btn("Mở sự cố") + "</div>"
    + kpis([("Đối tượng đúng hạn", "6 / 8", "1 trễ · 1 không rõ", ""), ("Kiểm tra khôi phục đạt trong kỳ", "86%", "6 trên 7 đối tượng", ""), ("Diễn tập DR gần nhất", "15/11/2026", "RTO 3 giờ 10 phút · đạt", ""), ("Độ tươi trạng thái thu", "4 phút", "ngưỡng 15 phút", "")])
    + '<div class="card">' + table(["Đối tượng", "Công cụ", "Thành công gần nhất", "Độ tươi", "Thời gian giữ", "Kiểm tra khôi phục"], rows19, "Đối tượng sao lưu")
    + '<div class="muted" style="margin-top:6px">"Không rõ": chưa thu được trạng thái từ Velero lúc 09:35 (ERR-18-122); cảnh báo sau 3 lần thu liên tiếp lỗi.</div></div>')))

# ---------------------------------------------------------------- 20 Khôi phục, xuất và sáp nhập
steps20 = "".join(f'<div class="{c}"><i>{n}</i><span><b>{t}</b><br><span class="muted">{d}</span></span><span class="muted">{tm}</span></div>' for c, n, t, d, tm in [
    ("ok", "1", "Ghi phê duyệt", "Hoàng Nam (PA) duyệt 10:02", "10:02"), ("ok", "2", "PITR vào cụm tạm cô lập", "về 25/11/2026 08:30", "10:31"),
    ("ok", "3", "Trích dòng của tenant và bản trích để quay lui", "ph07_rdm: 184.220 dòng", "10:44"), ("ok", "4", "Tạm ngừng tenant T68", "PH-20 chuyển SUSPENDED, dừng luồng", "10:45"),
    ("run", "5", "Thay dữ liệu từng phân hệ", "ph07_rdm 62%", "đang chạy"), ("", "6", "Khôi phục kho khác theo phạm vi", "Garage: không chọn", ""),
    ("", "7", "Ghi bản kiểm toán khôi phục", "", ""), ("", "8", "Kiểm tra khói, đối chiếu số dòng", "", "")])
P["20"] = ("Khôi phục, xuất và sáp nhập", page("20", "Khôi phục, xuất và sáp nhập", shell(
    "Sao lưu và khôi phục", "Vận hành › Sao lưu và khôi phục › Khôi phục › KP-2026-007", "Yêu cầu khôi phục KP-2026-007 " + tag("info", "↻ Đang chạy bước 5/8"), btn("+ Yêu cầu khôi phục") + btn("+ Xuất dữ liệu tenant"),
    tabs(["Khôi phục tenant", "Xuất dữ liệu", "Chuyển sáp nhập"], "Khôi phục tenant")
    + '<div class="banner w">⚠ Tỉnh T68 đang tạm ngừng trong bước 4 đến 8. Dữ liệu ph07_rdm sau 25/11/2026 08:30 sẽ mất. Nhật ký kiểm toán không bị khôi phục.<span class="sp"></span>Ước tính xong 11:40 · chỉ tiêu 4 giờ</div>'
    + '<div class="grid3" style="grid-template-columns:minmax(0,1fr) 400px"><div class="card"><h3>Tám bước khôi phục</h3><div class="vsteps">' + steps20 + "</div></div>"
    + '<div><div class="card"><h3>Yêu cầu</h3><dl class="ctx"><dt>Thời điểm đích</dt><dd>25/11/2026 08:30 (trong cửa sổ 30 ngày)</dd><dt>Phạm vi</dt><dd>MODULES: ph07_rdm</dd><dt>Kho khác</dt><dd>Tệp: không · Danh tính: không · Bí mật: không</dd>'
    + '<dt>Lý do</dt><dd>Nhập nhầm danh mục DM_DON_VI ngày 25/11, văn bản 112/STTTT</dd><dt>Người tạo</dt><dd>Trần Vy (TA) · 09:12</dd><dt>Người duyệt</dt><dd>Hoàng Nam (PA) · 10:02</dd></dl></div>'
    + '<div class="card" style="margin-top:12px"><h3>Quay lui</h3><div style="font-size:13px">Lỗi ở bước 5 đến 8 thì hệ thống tự quay lui từ bản trích. Nút "Quay lui" chỉ hiện cho PA khi quay lui tự động thất bại.</div>'
    + f'<div style="margin-top:8px">{btn("Quay lui…", "dis")}</div></div></div></div>')))

# ---------------------------------------------------------------- 21 Nguồn và kế hoạch di trú
items21 = [["1", "Danh mục Aita", "<span class='mono'>aita-catalog v2</span>", "PH-07", "-", tag("ok", "✓ Có bộ chuyển")],
           ["2", "HTTT, application", "<span class='mono'>bus-application v3</span>", "PH-01", "1", tag("ok", "✓ Có bộ chuyển")],
           ["3", "API, plan, subscription", "<span class='mono'>apim-api v2</span>", "PH-02, PH-03", "2", tag("ok", "✓ Có bộ chuyển")],
           ["4", "Topic, publisher, subscriber", "<span class='mono'>hub-topic v1</span>", "PH-10", "2", tag("ok", "✓ Có bộ chuyển")],
           ["5", "Luồng Camel XML (nháp)", "<span class='mono'>bus-camel-xml v1</span>", "PH-04", "2, 3", tag("warn", "⚠ PH-04 chưa có chế độ kiểm")],
           ["6", "Giao dịch lịch sử", "<span class='mono'>pay-transaction v1</span>", "PH-19", "2", tag("ok", "✓ Có bộ chuyển")]]
P["21"] = ("Nguồn và kế hoạch di trú", page("21", "Nguồn và kế hoạch di trú", shell(
    "Di trú hệ cũ", "Vận hành › Di trú hệ cũ › KH-HOTICH-01", "Kế hoạch di trú KH-HOTICH-01 " + tag("mute", "Nháp"), btn("Lưu nháp") + btn("Đánh dấu sẵn sàng", "pri"),
    '<div class="steps"><div class="done">✓ 1. Nguồn hệ cũ</div><div class="on">● 2. Kế hoạch</div><div>3. Chạy thử</div><div>4. Chạy thật (bốn mắt)</div><div>5. Đối chiếu, cắt chuyển</div></div>'
    + '<div class="grid3" style="grid-template-columns:330px minmax(0,1fr)"><div class="card" style="align-self:start"><h3>Nguồn BUS-T68-CU ' + tag("ok", "Sẵn sàng") + '</h3><dl class="ctx"><dt>Hệ cũ</dt><dd>BUS (Viettel 2021)</dd>'
    + '<dt>JDBC</dt><dd><span class="mono">jdbc:postgresql://bus-cu.t68.noi-bo:5432/bus</span></dd><dt>Thông tin kết nối</dt><dd><span class="mono">kv/dh/t68/legacy/bus-cu</span> (tham chiếu kho bí mật)</dd>'
    + '<dt>Kiểm chỉ đọc</dt><dd>✓ Tạo bảng tạm bị từ chối</dd><dt>Bảng, dòng</dt><dd>146 bảng · khoảng 3,1 triệu dòng</dd><dt>Thử gần nhất</dt><dd>27/11 08:50</dd></dl>'
    + f'<div style="margin-top:8px">{btn("Thử kết nối")}</div></div>'
    + '<div class="card"><h3 style="display:flex">Loại đối tượng theo thứ tự phụ thuộc<span style="flex:1"></span>' + btn("+ Loại đối tượng") + "</h3>"
    + table(["#Thứ tự", "Loại đối tượng", "Bộ chuyển", "Phân hệ đích", "Phụ thuộc", "Kiểm tra"], items21, "Mục kế hoạch di trú")
    + '<div class="alert i" style="margin-top:10px">ⓘ Đồ thị phụ thuộc không có vòng. Thông tin xác thực (khóa API, mật khẩu ứng dụng) không di trú; hệ thống đánh dấu cần cấp lại ở PH-01, PH-03.</div></div></div>')))

# ---------------------------------------------------------------- 22 Lần chạy di trú
rec = [["Danh mục Aita", "12.400", "12.400", "12.400", "0", tag("ok", "✓ Khớp")], ["HTTT, application", "212", "212", "208", "4", tag("warn", "◐ 4 lỗi đã giải trình 2")],
       ["API, plan, subscription", "1.840", "1.836", "1.836", "4", tag("ok", "✓ Khớp")], ["Topic, publisher, subscriber", "96", "96", "96", "0", tag("ok", "✓ Khớp")],
       ["Giao dịch lịch sử", "2.310.000", "1.402.000", "1.401.880", "120", tag("info", "↻ Đang chạy 61%")]]
errs = [["<span class='mono'>app:BUS-0091</span>", "HTTT, application", "ERR-01-031", "Thiếu đơn vị chủ quản", tag("warn", "Mở")],
        ["<span class='mono'>app:BUS-0102</span>", "HTTT, application", "ERR-01-031", "Thiếu đơn vị chủ quản", tag("info", "Sửa ở nguồn")],
        ["<span class='mono'>sub:APIM-7781</span>", "API, plan, subscription", "Bộ chuyển", "Gói cước không còn", tag("mute", "Không di trú")]]
P["22"] = ("Lần chạy di trú", page("22", "Lần chạy di trú", shell(
    "Di trú hệ cũ", "Vận hành › Di trú hệ cũ › KH-HOTICH-01 › Lần chạy LC-2026-014", "Lần chạy LC-2026-014 · Chạy thật " + tag("info", "↻ Đang chạy"), btn("⇩ Báo cáo đối chiếu PDF") + btn("Hủy sau lô hiện hành…", "danger"),
    kpis([("Đã đọc", "1.416.548", "lô 500", ""), ("Đã chuyển đổi", "1.416.544", "", ""), ("Đã ghi vào phân hệ đích", "1.416.420", "", ""), ("Bản ghi lỗi", "128", "2 đã sửa ở nguồn", ""), ("Thông tin xác thực cần cấp lại", "208", "HTTT · 0 đã cấp lại", "")], 5)
    + '<div class="card"><h3>Đối chiếu số lượng và tổng kiểm tra</h3>' + table(["Loại đối tượng", "#Nguồn", "#Chuyển đổi", "#Ghi thành công", "#Lỗi", "Tổng kiểm tra SHA-256"], rec, "Đối chiếu") + "</div>"
    + f'<div class="card" style="margin-top:12px"><h3 style="display:flex">Bản ghi lỗi<span style="flex:1"></span>{btn("⇩ CSV")}{btn("Chạy lại bản ghi đã chọn (cần duyệt)…")}</h3>'
    + table(["Khóa nguồn", "Loại", "Mã lỗi", "Lý do", "Cách xử lý"], errs, "Bản ghi lỗi") + "</div>")))

# ---------------------------------------------------------------- 23 Chạy song song và cắt chuyển
grp = [["<span class='mono'>NHOM-HOTICH</span>", tag("ok", "Bóng đạt"), "Đang chạy · hết hạn 10/12", "99,82%", "12 / 12", "Chưa"],
       ["<span class='mono'>NHOM-DATDAI</span>", tag("warn", "Song song"), "Đang chạy · hết hạn 03/12 ⚠", "97,10%", "8 / 15", "Chưa"],
       ["<span class='mono'>NHOM-BHXH</span>", tag("info", "Cắt chuyển một phần"), "Không dùng", "99,95%", "6 / 6", "30%"],
       ["<span class='mono'>NHOM-DVC</span>", tag("ok", "Đã cắt chuyển"), "Đã đóng", "99,97%", "20 / 20", "100% · còn 7 phút quay lui"]]
P["23"] = ("Chạy song song và cắt chuyển", page("23", "Chạy song song và cắt chuyển", shell(
    "Di trú hệ cũ", "Vận hành › Di trú hệ cũ › Chạy song song", "Chạy song song và cắt chuyển", "",
    '<div class="card">' + table(["Nhóm dịch vụ", "Trạng thái", "Cầu nối PH-10", "Tỷ lệ khớp 7 ngày", "HTTT đã cấp lại xác thực", "Lưu lượng sang Datahub"], grp, "Nhóm chạy song song") + "</div>"
    + '<div class="grid-2e" style="margin-top:12px"><div class="card"><h3>NHOM-HOTICH · danh sách kiểm tra cắt chuyển</h3><div class="chk">'
    + '<div><b class="y">✓ Đạt</b>DLQ của nhóm không còn mục chưa xử lý<span class="v">0</span></div>'
    + '<div><b class="y">✓ Đạt</b>Tỷ lệ khớp ≥ 99,5% trong 7 ngày, ≥ 1.000 mẫu<span class="v">99,82% · 41.200</span></div>'
    + '<div><b class="y">✓ Đạt</b>100% HTTT của nhóm đã cấp lại xác thực<span class="v">12 / 12</span></div>'
    + '<div><b class="y">✓ Đạt</b>Báo cáo đối chiếu không còn chênh lệch chưa giải trình<span class="v">LC-2026-012</span></div>'
    + '<div><b class="n">✕ Chưa</b>Không trong thời gian đóng băng<span class="v">CS-2026-032 từ 21/12</span></div>'
    + '<div><b class="h">☐ Tay</b>Đã thông báo đầu mối HTTT và người trực<span class="v">chờ xác nhận</span></div></div>'
    + f'<div class="row" style="margin-top:10px">{btn("Gửi đề nghị cắt chuyển", "dis")}<span class="muted">Chưa cắt chuyển được nhóm NHOM-HOTICH: còn 2 mục kiểm tra chưa đạt. (ERR-18-067)</span></div></div>'
    + '<div class="card"><h3>NHOM-DVC · sổ cắt chuyển</h3><div class="cd"><div class="ring"><span>7:12</span></div><div><b>Còn 7 phút 12 giây để quay lui tự động</b><div class="muted">Cửa sổ 18.migration.rollback-window-minutes = 15 phút từ 09:34</div></div></div>'
    + '<div class="vtl" style="margin-top:12px"><div><b>09:34</b> Cắt chuyển toàn phần · duyệt Hoàng Nam (PA) · PH-03 đổi tuyến 100%</div><div><b>20/11</b> Cắt chuyển một phần 30%</div><div><b>12/11</b> Bóng đạt</div></div>'
    + f'<div style="margin-top:8px">{btn("↶ Quay lui về hệ cũ…", "danger")}</div></div></div>')))

# ---------------------------------------------------------------- 24 Tổng quan vận hành và sức khỏe
health = [["param · kho tham số", tag("ok", "● Bình thường"), "bộ đệm 60 giây", "0"], ["dlq · tiếp nhận DLQ", tag("ok", "● Bình thường"), "độ trễ tiêu thụ 2 giây", "0"],
          ["notify · thông báo", tag("warn", "◐ Suy giảm"), "SMS gateway thử lại", "3"], ["task · việc", tag("ok", "● Bình thường"), "", "0"],
          ["incident · sự cố", tag("ok", "● Bình thường"), "", "0"], ["backup · sao lưu", tag("warn", "◐ Suy giảm"), "Velero chưa thu được", "1"], ["migration · di trú", tag("ok", "● Bình thường"), "1 Job đang chạy", "0"]]
audit = [["09:41", "Lê Hà (TO)", "Phát lại mục DLQ-7Q51", "Hàng đợi lỗi"], ["09:20", "Trần Vy (TA)", "Duyệt lượt PL-2026-0153", "Hàng đợi lỗi"],
         ["09:05", "Nguyễn Thu (TA)", "Đề nghị đổi 18.dlq.replay.approval-threshold", "Tham số"], ["08:50", "Ngô Minh (TO)", "Thử kết nối BUS-T68-CU", "Di trú"]]
P["24"] = ("Tổng quan vận hành và sức khỏe", page("24", "Tổng quan vận hành", shell(
    "Tổng quan vận hành", "Vận hành › Tổng quan", "Tổng quan vận hành", btn("Báo cáo vận hành tháng 11 (nháp)") + btn("⇩ Báo cáo tháng 10"),
    kpis([("DLQ chưa xử lý", "1.284", "vượt ngưỡng 1.000 → Hàng đợi lỗi", ""), ("Sự cố đang mở", "4", "1 SEV1 → Sự cố", ""), ("Việc chờ tôi", "7", "1 quá hạn → Việc của tôi", ""),
          ("Sao lưu đúng hạn", "6 / 8", "→ Sao lưu", ""), ("Di trú", "1 lần chạy", "61% · → Di trú", ""), ("Đóng băng sắp tới", "21/12", "PROD, STAGING", "")], 6)
    + '<div class="grid-2e"><div class="card"><h3>Sức khỏe các mô-đun PH-18</h3>' + table(["Mô-đun", "Trạng thái", "Ghi chú", "#Sự kiện inbox lỗi"], health, "Sức khỏe mô-đun")
    + '<div class="muted" style="margin-top:6px">Chế độ chỉ đọc (18.degraded.read-only): tắt · phân hệ vận hành vắng không chặn giao dịch của HTTT.</div></div>'
    + '<div class="card"><h3>Nhật ký thao tác vận hành gần đây</h3>' + table(["Lúc", "Người", "Thao tác", "Khu"], audit, "Nhật ký thao tác") + '<div class="muted" style="margin-top:6px">Bản chính thức ở kiểm toán PH-13 · Xem tất cả</div></div></div>')))

for k, (t, h) in P.items():
    (OUT / f"ui-18-{k}.html").write_text(h, encoding="utf-8")
print(len(P), "trang")
