#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-17 (D03-06-PH17, mục "Bản hi-fi" của UI-17-01, 02, 03, 06, 11).

Chạy: python3 gen_hifi.py && node shot.js && python3 nen.py
Dữ liệu là giả định của tỉnh thí điểm T68: người, mã, tổ chức đều là dữ liệu giả; không có dữ liệu cá nhân thật, số định danh luôn che.
Phong cách Liquid Glass của D03-05: kính chỉ ở lớp điều hướng và lớp nổi (thanh trên, sidebar, đầu và ô nhập của bảng bên, hộp xem trước),
nội dung hội thoại, bảng, biểu mẫu đều trên nền đặc.
"""
import pathlib

OUT = pathlib.Path(__file__).parent


def tag(k, t):
    return f"<span class='tag t-{k}'>{t}</span>"


def btn(t, k=""):
    return f'<span class="btn {k}">{t}</span>'


def top(extra=""):
    return ('<header class="top"><div class="logo"><b>Datahub</b> · Điều hành</div>'
            '<div class="search">Tìm hoặc hỏi trợ lý…  ⌘K</div><div class="sp"></div>'
            f'{extra}<span class="tray" style="background:#f1ecff">✦ Trợ lý</span><span class="tray">T68 · Tỉnh thí điểm</span><div class="avatar">NT</div></header>')


def side(collapsed=False, on="Thiết kế luồng"):
    items = [("▤", "Danh mục"), ("⇄", "Thiết kế luồng"), ("◉", "Vận hành"), ("☰", "Nhật ký"), ("⚙", "Quản trị")]
    if collapsed:
        h = "".join(f'<a class="{"on" if n == on else ""}" href="#"><i>{i}</i></a>' for i, n in items)
    else:
        h = "".join(f'<a class="{"on" if n == on else ""}" href="#">{i}  {n}</a>' for i, n in items)
    return f'<nav class="side" aria-label="Điều hướng chính">{h}</nav>'


def page(code, title, body, cls="", width=1440, scrim=False, extra=""):
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width={width}">
<title>UI-17-{code} · {title}</title><link rel="stylesheet" href="hifi.css"></head><body>
{body}{'<div class="scrim"></div>' if scrim else ''}{extra}<div class="hint">Bản hi-fi minh họa · D03-06-PH17 · UI-17-{code} · dữ liệu giả định T68</div>{'<style>.hint{position:static;text-align:right;padding:6px 14px}</style>' if code == '01c' else ''}</body></html>"""


def panel(msgs, cls="", tabs=True, composer=None, title="Trợ lý AI"):
    tb = '<div class="tb"><span class="on">Hội thoại</span><span>Lịch sử</span><span>Gợi ý</span></div>' if tabs else ""
    comp = composer or ('<div class="box">Hỏi về API, topic, ánh xạ hoặc lỗi…</div>'
                        '<div class="row2"><span>Tìm dịch vụ ▾</span><span class="sp"></span><span>Còn 38 lượt hôm nay</span>'
                        f'{btn("Gửi", "pri")}</div>')
    return (f'<aside class="ap {cls}" role="complementary" aria-label="Trợ lý AI"><div class="hd"><b>✦ {title}</b>'
            f'<span class="sp"></span><span class="ib" title="Hội thoại mới">＋</span><span class="ib" title="Đóng">✕</span></div>{tb}'
            f'<div class="bd">{msgs}</div><div class="cmp">{comp}</div></aside>')


AI = '<span class="ai">✦ Nội dung do AI tạo, cần kiểm tra lại</span>'
FB = '<div class="fb"><span>👍 Hữu ích</span><span>👎 Chưa đúng</span><span>Sao chép</span></div>'
ANS1 = f"""<div class="m-u">Tra cứu thông tin khai sinh thì dùng API nào?</div>
<div class="m-a">{AI}<p>Có hai API liên quan đến tra cứu khai sinh trong phạm vi bạn được xem: <b>tra cứu giấy khai sinh theo mã hồ sơ</b> <span class="cit">1</span> và <b>kiểm tra trạng thái đăng ký khai sinh</b> <span class="cit">2</span>. Cả hai thuộc nhóm dịch vụ hộ tịch, cần phạm vi <span class="mono">hotich.read</span>.</p>
<div class="srcs"><div><span class="cit">1</span> API-HT-0412 · Tra cứu giấy khai sinh · Nội bộ</div><div><span class="cit">2</span> API-HT-0418 · Trạng thái đăng ký khai sinh · Nội bộ</div></div>{FB}</div>
<div class="sug"><span>Xem lược đồ trả về</span><span>Ai đang gọi API này?</span></div>"""


def alert_host():
    return ('<div class="alert e" role="alert"><span>✕</span><span><b>ERR-04-117</b> · Ánh xạ trường "ngay_sinh" sang "ngaySinh" không hợp lệ: kiểu dữ liệu không khớp.</span>'
            '<span class="sp"></span><span class="btn" style="height:28px;color:#4a3a8a;border-color:#d8ccf5;background:#f1ecff">✦ Giải thích lỗi này</span></div>')


def flow_canvas(h=420):
    nodes = [("Nguồn: Hộ tịch", "API-HT-0412", 30, 40), ("Chuẩn hóa ngày", "Biến đổi", 270, 40), ("Ánh xạ khai sinh", "Ánh xạ trường", 510, 40),
             ("Kiểm tra mã", "Kiểm tra", 270, 150), ("Đích: Kho dùng chung", "Topic ho-tich.khai-sinh", 510, 150)]
    n = "".join(f'<div class="node" style="left:{x}px;top:{y}px"><b>{a}</b>{b}</div>' for a, b, x, y in nodes)
    return (f'<div class="canvas" style="height:{h}px"><svg><path d="M230 68 L270 68 M470 68 L510 68 M610 96 L610 150 M370 96 L370 150" stroke="#8a919c" stroke-width="1.6" fill="none"/></svg>{n}</div>')


P = {}

# ---------------------------------------------------------------- 01 Bảng bên gắn 400px
P["01"] = ("Bảng bên trợ lý AI", page("01", "Bảng bên trợ lý AI", f"""
<div class="shell c push">{top()}{side(True)}<main><div class="crumb">Thiết kế luồng › Luồng khai sinh sang kho dùng chung › Ánh xạ</div>
<div class="head"><h1>Ánh xạ khai sinh v3 <span class="tag t-warn">Bản nháp</span></h1><div class="sp"></div>{btn("Gợi ý ánh xạ ✦")}{btn("Lưu")}{btn("Gửi duyệt", "pri")}</div>
{alert_host()}{flow_canvas(380)}
<div class="card" style="margin-top:12px"><b>Thanh trạng thái</b><div class="muted">Vùng nội dung đã co để chừa 400px cho bảng bên (không phủ lên); sidebar tự thu gọn còn 64px.</div></div></main></div>
{panel(ANS1)}"""))

# ---------------------------------------------------------------- 01b Drawer 1024px đang phát
P["01b"] = ("Bảng bên ở chế độ Drawer, đang phát", page("01b", "Bảng bên Drawer 1024px", f"""
<div class="shell c nopush" style="grid-template-columns:64px 1fr">{top()}{side(True)}<main><div class="crumb">Thiết kế luồng › Luồng khai sinh sang kho dùng chung</div>
<div class="head"><h1>Ánh xạ khai sinh v3</h1></div>{alert_host()}{flow_canvas(300)}</main></div>""",
    width=1024, scrim=True, extra=panel(f"""<div class="m-u">Vì sao ánh xạ ngày sinh bị báo lỗi kiểu dữ liệu?</div>
<div class="m-a">{AI}<p>Trường nguồn <span class="mono">ngay_sinh</span> có kiểu chuỗi, trường đích <span class="mono">ngaySinh</span> yêu cầu kiểu ngày. Bạn có thể thêm bước chuẩn hóa ngày trước ánh xạ <span class="cit">1</span><span class="caret"></span></p>
<div class="srcs"><div class="muted">Đang tìm trong các nguồn bạn được xem…</div></div></div>""", cls="dr",
        composer='<div class="box dis">Đang phát câu trả lời…</div><div class="row2"><span>Giải thích lỗi ▾</span><span class="sp"></span><span>Còn 37 lượt hôm nay</span>' + btn("■ Dừng", "danger") + '</div>')))

# ---------------------------------------------------------------- 01c Bốn trạng thái
st1 = f'<div class="m-u">Số hộ chính sách tỉnh Z năm 2025?</div><div class="m-a">{AI}<p>Tôi không tìm thấy thông tin phù hợp trong các nguồn bạn được xem. Thử nêu tên API, topic hoặc mã lỗi cụ thể.</p><div class="sug"><span>Mở danh mục</span><span>Hỏi lại</span></div></div>'
st2 = '<div class="m-u">Liệt kê khóa bí mật của cổng dịch vụ.</div><div class="sc s-err" role="alert"><h4>✕ Câu trả lời bị chặn</h4>ERR-17-067 · Câu trả lời bị chặn vì có thể lộ dữ liệu nhạy cảm.<div class="muted" style="margin-top:4px">Nội dung bị chặn không được hiển thị. Bạn có thể hỏi cách khác.</div></div>'
st3 = '<div class="sc s-warn" role="alert"><h4>⚠ Hết lượt trong ngày</h4>ERR-17-021 · Bạn đã dùng hết 50 lượt hôm nay. Thử lại sau 00:00 ngày 27/11/2026.<div class="muted" style="margin-top:4px">Ô nhập đã vô hiệu. Lịch sử vẫn xem được.</div></div>'
st4 = '<div class="sc s-info" role="status"><h4>ⓘ Trợ lý AI đang tắt ở tỉnh này</h4>Quản trị tỉnh chưa bật trợ lý. Liên hệ quản trị tỉnh để đề nghị bật.<div class="muted" style="margin-top:4px">Lịch sử hội thoại cũ vẫn xem được trong 90 ngày.</div></div>'
dis = '<div class="box dis">Không nhập được lúc này</div><div class="row2"><span class="sp"></span>' + btn("Gửi", "dis") + '</div>'
cell = lambda cap, msgs, comp=None: f'<div><div class="muted" style="margin-bottom:6px"><b>{cap}</b></div>{panel(msgs, "rel", tabs=False, composer=comp)}</div>'
P["01c"] = ("Bốn trạng thái của bảng bên", page("01c", "Bốn trạng thái bảng bên", f"""
<div class="scol">{cell("Không tìm thấy nguồn", st1)}{cell("Bị chặn đầu ra", st2)}{cell("Hết hạn mức", st3, dis)}{cell("Tenant tắt trợ lý", st4, dis)}</div>""", width=1000))

# ---------------------------------------------------------------- 02 Khung xem trước
def mrow(cls, sel, s, d, conf, why, state):
    return f'<tr class="{cls}"><td>{sel}</td><td class="mono">{s}</td><td class="mono">{d}</td><td>{conf}</td><td>{why}</td><td>{state}</td></tr>'


rows = "".join([
    mrow("d-add", "☑", "ma_ho_so", "maHoSo", '<span class="dot h"></span>0,97 cao', "Tên gần giống, cùng kiểu chuỗi", tag("ok", "Hợp lệ")),
    mrow("d-add", "☑", "ho_ten", "hoTen", '<span class="dot h"></span>0,94 cao', "Cùng nghĩa, cùng kiểu", tag("ok", "Hợp lệ")),
    mrow("d-chg", "☐", "ngay_sinh", "ngaySinh", '<span class="dot m"></span>0,78 TB', "Khác kiểu: cần chuẩn hóa ngày", tag("warn", "Cần xem kỹ")),
    mrow("", "☐", "ma_quoc_tich", "<i class='muted'>chưa gợi ý được</i>", '<span class="dot l"></span>-', "Không đủ căn cứ trong lược đồ", tag("mute", "Chưa gợi ý")),
])
pv = f"""<div class="pv" role="dialog" aria-label="Xem trước đề xuất ánh xạ"><h3>Xem trước đề xuất ánh xạ <span class="muted">· 4 trường, 2 chọn</span></h3>
<div class="muted" style="margin-bottom:8px">{AI} Thay đổi chỉ ghi vào bản nháp khi bạn bấm Áp dụng, bằng quyền của bạn.</div>
<table aria-label="Khác biệt ánh xạ"><thead><tr><th>Chọn</th><th>Trường nguồn</th><th>Trường đích</th><th>Tin cậy</th><th>Lý do</th><th>Kiểm tra</th></tr></thead><tbody>{rows}</tbody></table>
<div class="foot"><span class="muted" style="margin-right:auto">Khác biệt so với bản nháp hiện tại: <ins>＋ 2 ánh xạ</ins></span>{btn("Hủy")}{btn("Áp dụng vào bản nháp", "pri")}</div></div>"""
P["02"] = ("Khung xem trước đề xuất ánh xạ", page("02", "Xem trước đề xuất ánh xạ", f"""
<div class="shell c push">{top()}{side(True)}<main><div class="crumb">Thiết kế luồng › Luồng khai sinh sang kho dùng chung › Ánh xạ</div>
<div class="head"><h1>Ánh xạ khai sinh v3 <span class="tag t-warn">Bản nháp</span></h1></div>{flow_canvas(420)}</main></div>
{panel('<div class="sc s-info"><h4>✦ Đề xuất ánh xạ: 4 trường</h4>2 tin cậy cao, 1 cần xem kỹ, 1 chưa gợi ý được.<div style="margin-top:6px">' + btn("Mở xem trước") + '</div></div>')}""", extra=pv))

# ---------------------------------------------------------------- 03 Giải thích lỗi
P["03"] = ("Giải thích lỗi theo mã vết", page("03", "Giải thích lỗi theo mã vết", f"""
<div class="shell c push">{top()}{side(True, "Vận hành")}<main><div class="crumb">Vận hành › Vết › 7f3a9c21</div>
<div class="head"><h1>Vết 7f3a9c21 <span class="tag t-err">Lỗi</span></h1></div>
<div class="alert e" role="alert"><span>✕</span><span><b>ERR-11-204</b> · Gọi API đích quá thời gian chờ sau 3 lần thử.</span><span class="sp"></span><span class="btn" style="height:28px;color:#4a3a8a;border-color:#d8ccf5;background:#f1ecff">✦ Giải thích lỗi này</span></div>
<div class="card"><table aria-label="Các bước"><thead><tr><th>Bước</th><th>Dịch vụ</th><th>Kết quả</th><th class="num">Thời gian</th></tr></thead><tbody>
<tr><td>1</td><td>Cổng API</td><td>{tag("ok","200")}</td><td class="num">12 ms</td></tr><tr><td>2</td><td>Chuẩn hóa</td><td>{tag("ok","OK")}</td><td class="num">48 ms</td></tr>
<tr><td>3</td><td>Gọi API Hộ tịch</td><td>{tag("err","Hết thời gian chờ")}</td><td class="num">30.000 ms</td></tr></tbody></table></div></main></div>
{panel(f'''<div class="sc"><h4>Chuẩn bị giải thích</h4><div class="muted">Mã vết 7f3a9c21 · Đã che 2 mẫu dữ liệu cá nhân</div>
<div class="code" style="margin-top:6px;font-size:12px">GET /ho-tich/khai-sinh?ma=●●●●●●●●●●●●
Authorization: ●●●●●●●●</div><div style="margin-top:8px">{btn("Gửi tới trợ lý", "pri")}{btn("Hủy")}</div></div>
<div class="m-a">{AI}<p><b>Nguyên nhân có khả năng nhất:</b> API Hộ tịch phản hồi chậm quá 30 giây ở lần gọi thứ ba <span class="cit">1</span>. Cùng thời điểm, hàng đợi của dịch vụ đích tăng cao <span class="cit">2</span>.</p>
<p><span class="tag t-warn">Chắc chắn mức trung bình</span></p><div class="srcs"><div><span class="cit">1</span> Vết 7f3a9c21, bước 3</div><div><span class="cit">2</span> ERR-11-204, hướng dẫn xử lý</div><div><span class="cit">3</span> Chỉ số hàng đợi 14:05 đến 14:20</div></div>
<div style="margin-top:8px">{btn("Tạo danh sách kiểm")}{btn("Tóm tắt sự cố")}</div>{FB}</div>''')}"""))

# ---------------------------------------------------------------- 06 Cấu hình trợ lý
P["06"] = ("Cấu hình trợ lý, nhóm Bật và tắt", page("06", "Cấu hình trợ lý", f"""
<div class="shell">{top()}{side(False, "Quản trị")}<main><div class="crumb">Quản trị › Trợ lý AI › Cấu hình</div>
<div class="chrome"><h1>Cấu hình trợ lý AI {tag("ok", "● Đang bật")}<span style="flex:1"></span><span class="btn danger">⏻ Tắt khẩn cấp…</span></h1><div class="muted">Bật từ 12/11/2026 · duyệt bởi Lê Văn C (SO) · lần sửa cuối 25/11/2026</div></div>
<div style="display:flex;gap:14px"><div class="toc"><div class="on">Bật và tắt</div><div>Năng lực</div><div>Mô hình mặc định</div><div>Hạn mức</div><div>Dữ liệu và lưu giữ</div><div>Điều khoản</div><div>Tham số 17.*</div></div>
<div style="flex:1;min-width:0"><div class="card"><h3 style="margin:0 0 8px;font-size:15px">Trạng thái trợ lý</h3>
<div class="sw"><i></i><b>Bật trợ lý cho tỉnh T68</b></div><div class="muted" style="margin:6px 0 10px">Điều kiện đã đạt khi bật</div>
<div class="gate"><div><b>✓ Đạt</b>Có mô hình mặc định đã duyệt<span class="n">vllm-chat v2</span></div><div><b>✓ Đạt</b>Có ít nhất một nguồn tri thức đã lập chỉ mục<span class="n">6 nguồn</span></div><div><b>✓ Đạt</b>Đã công bố điều khoản dùng AI<span class="n">phiên bản 3</span></div><div><b>✓ Đạt</b>Ca đỏ bị chặn 100%<span class="n">52/52</span></div></div></div>
<div class="card" style="margin-top:12px"><h3 style="margin:0 0 8px;font-size:15px">Đề nghị chờ duyệt</h3>
<table aria-label="Đề nghị chờ duyệt"><thead><tr><th>Đề nghị</th><th>Người đề nghị</th><th>Lúc</th><th>Hành động</th></tr></thead><tbody>
<tr><td>Bật năng lực "Gợi ý ánh xạ"</td><td>Nguyễn Văn A (TA)</td><td>26/11/2026 09:10</td><td>{btn("Duyệt", "dis")} {btn("Từ chối…")}</td></tr></tbody></table>
<div class="muted" style="margin-top:6px">Bạn là người đề nghị nên không được duyệt (ERR-17-005). Cần một người khác có quyền duyệt.</div></div></div></div></main></div>"""))

# ---------------------------------------------------------------- 11 Bộ đánh giá và ca đỏ
def cr(g, c, a, b, ra, rb):
    k = {"Bị chặn": "ok", "Lọt": "err", "Cảnh báo": "warn"}
    return f'<tr><td>{g}</td><td>{c}</td><td>{tag("err" if a == "Cao" else "warn" if a == "Trung bình" else "mute", a)}</td><td>{tag(k[ra], ("✓ " if ra == "Bị chặn" else "✕ " if ra == "Lọt" else "⚠ ") + ra)}</td><td>{tag(k[rb], ("✓ " if rb == "Bị chặn" else "✕ " if rb == "Lọt" else "⚠ ") + rb)}</td></tr>'


crow = "".join([
    cr("Tiêm lệnh", "Yêu cầu bỏ qua chỉ dẫn hệ thống", "Cao", "", "Bị chặn", "Bị chặn"),
    cr("Tiêm lệnh", "Chèn lệnh trong tài liệu truy hồi", "Cao", "", "Bị chặn", "Bị chặn"),
    cr("Đánh cắp dữ liệu", "Đòi liệt kê khóa bí mật", "Cao", "", "Bị chặn", "Bị chặn"),
    cr("Đánh cắp dữ liệu", "Đòi xuất số định danh hàng loạt", "Cao", "", "Bị chặn", "Bị chặn"),
    cr("Liên kết ngoài", "Chèn đường dẫn ngoài danh sách trắng", "Trung bình", "", "Bị chặn", "Bị chặn"),
    cr("Gọi công cụ ghi", "Ép trợ lý sửa luồng", "Cao", "", "Bị chặn", "Bị chặn"),
])
P["11"] = ("Bộ đánh giá và ca đỏ, tab Ca đỏ", page("11", "Bộ đánh giá và ca đỏ", f"""
<div class="shell">{top()}{side(False, "Quản trị")}<main><div class="crumb">Quản trị › Trợ lý AI › Đánh giá</div>
<div class="head"><h1>Bộ đánh giá và ca đỏ</h1><div class="sp"></div>{btn("Thêm ca")}{btn("Chạy ca đỏ", "pri")}</div>
<div class="tabs"><span>Bộ đánh giá</span><span class="on">Ca đỏ</span><span>Lượt chạy</span><span>Cổng phát hành</span></div>
<div class="kpis" style="--n:4"><div class="kpi"><span>Tổng ca</span><b>52</b><small>cập nhật 25/11/2026</small></div><div class="kpi"><span>Bị chặn</span><b>✓ 52</b><small>100%</small></div><div class="kpi"><span>Lọt</span><b>0</b><small>ngưỡng cho phép: 0</small></div><div class="kpi"><span>Cảnh báo</span><b>0</b><small>không có ca cần rà soát</small></div></div>
<div style="display:grid;grid-template-columns:minmax(0,1fr) 340px;gap:14px"><div class="card"><table aria-label="Ca đỏ"><thead><tr><th>Nhóm tấn công</th><th>Ca</th><th>Mức</th><th>Chỉ dẫn v4</th><th>Chỉ dẫn v5 (đối tượng)</th></tr></thead><tbody>{crow}</tbody></table></div>
<div class="card" style="align-self:start"><h3 style="margin:0 0 8px;font-size:15px">Cổng phát hành</h3><div class="gate"><div><b>✓ Đạt</b>Điểm bộ đánh giá ≥ 0,80<span class="n">0,86</span></div><div><b>✓ Đạt</b>Sụt điểm ≤ 0,03<span class="n">-0,01</span></div><div><b>✓ Đạt</b>Ca đỏ bị chặn 100%<span class="n">52/52</span></div><div><b>✓ Đạt</b>Không có ca Cao lọt<span class="n">0</span></div><div><b>✓ Đạt</b>Đã chạy trong 7 ngày<span class="n">2 ngày</span></div></div>
<div style="margin-top:10px">{btn("Duyệt…", "ok")}<div class="muted" style="margin-top:6px">Người duyệt khác người đề nghị.</div></div></div></div></main></div>"""))

for k, (t, h) in P.items():
    (OUT / f"ui-17-{k}.html").write_text(h, encoding="utf-8")
print(len(P), "trang")
