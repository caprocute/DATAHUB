#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh UI-11-01, 04, 11, 12, 15, 18, 19, 21 (D03-06-PH11).

Chạy: python3 gen_hifi.py && node shot.js
Dữ liệu là giả định của tỉnh thí điểm T68; người, số định danh đều là dữ liệu giả và luôn che.
Phong cách Liquid Glass của D03-05: kính chỉ ở thanh trên, sidebar, thanh quyết định và lớp nổi trên canvas;
nội dung (bảng, biểu mẫu, canvas, bảng thuộc tính) dùng nền đặc.
"""
import pathlib

OUT = pathlib.Path(__file__).parent

# ----------------------------------------------------------------- khung chung
NAV = [("|Quy trình", None), ("Mô hình quy trình", "mh"), ("Phiên quy trình", "ph"), ("Giám sát quy trình", "gs"),
       ("|Cá nhân", None), ("Việc của tôi", "vc")]
BADGE = {"vc": "<span class='tag t-info'>7</span>", "gs": "<span class='tag t-err'>5</span>"}
TABS = {
    "mh": ["Mô hình", "Biểu mẫu", "Ý định và bù trừ", "Mẫu dùng chung"],
    "ph": ["Phiên", "Phân công lại"],
    "gs": ["Giám sát", "Sự cố", "Bù trừ", "Báo cáo hạn", "Lịch làm việc", "Cài đặt"],
}


def shell(code, title, crumb, body, grp, tab=None, extra="", fixed=False):
    nav = ""
    for n, c in NAV:
        if n.startswith("|"):
            nav += f'<div class="grp">{n[1:]}</div>'
            continue
        nav += f'<a class="{"on" if c == grp else ""}" href="#">{n} {BADGE.get(c, "")}</a>'
    if fixed:
        ic = {"mh": "▤", "ph": "⇄", "gs": "◔", "vc": "✓"}
        nav = "".join(f'<a class="{"on" if c == grp else ""}" href="#" title="{n}" style="font-size:18px">{ic[c]}</a>' for n, c in NAV if not n.startswith("|"))
    tb = ""
    if tab is not None and grp in TABS:
        tb = '<div class="subtabs" role="tablist">' + "".join(
            f'<span class="{"on" if i == tab else ""}">{t}</span>' for i, t in enumerate(TABS[grp])) + "</div>"
    cr = f'<div class="crumb">{crumb}</div>' if crumb else ""
    main = body if fixed else f"<main>{cr}{tb}{body}</main>"
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-11-{code} · {title}</title><link rel="stylesheet" href="hifi.css"></head><body>
<div class="shell{' fix' if fixed else ''}"><header class="top"><div class="logo"><b>Datahub</b> · Điều hành</div><div class="search">Tìm mô hình, hồ sơ, việc…  ⌘K</div><div class="sp"></div>
<span class="tray">⟳ 1 tác vụ nền</span><span class="tray">T68 · Tỉnh thí điểm</span><div class="avatar">LT</div></header>
<nav class="side" aria-label="Điều hướng chính">{nav}</nav>
{main}</div>{extra}<div class="hint">Bản hi-fi minh họa · D03-06-PH11 · UI-11-{code} · dữ liệu giả định T68</div></body></html>"""


def tag(kind, text):
    return f"<span class='tag t-{kind}'>{text}</span>"


def btn(t, k=""):
    return f'<span class="btn {k}">{t}</span>'


def inp(t, w=""):
    return f'<span class="input" style="{w}">{t}</span>'


def mono(t):
    return f"<span class='mono'>{t}</span>"


def head(title, *right):
    return f'<div class="head"><h1>{title}</h1><div class="sp"></div>{"".join(right)}</div>'


def table(h, rows, label="", cls=None):
    th = "".join(f"<th>{x}</th>" for x in h)
    tr = ""
    for i, r in enumerate(rows):
        c = f' class="{cls[i]}"' if cls and cls[i] else ""
        tr += f"<tr{c}>" + "".join(f"<td>{x}</td>" for x in r) + "</tr>"
    return f'<table aria-label="{label}"><thead><tr>{th}</tr></thead><tbody>{tr}</tbody></table>'


def facets(items, on=0):
    return '<div class="facets">' + "".join(f'<span class="{"on" if i == on else ""}">{t}</span>' for i, t in enumerate(items)) + "</div>"


def kpi(a, b, d="", cls=""):
    return f'<div class="kpi {cls}"><span>{a}</span><b>{b}</b><small>{d}</small></div>'


def kpis(items):
    return f'<div class="kpis" style="--n:{len(items)}">' + "".join(items) + "</div>"


def foot(t):
    return f'<div class="foot" style="justify-content:space-between"><span class="muted">{t}</span><span class="muted">‹ 1 2 3 › · 20 / trang</span></div>'


def banner(kind, text, action=""):
    ico = "✕" if kind == "e" else "⚠"
    a = f'<span class="sp"></span>{btn(action)}' if action else ""
    return f'<div class="banner {kind}" role="alert"><span>{ico}</span><span>{text}</span>{a}</div>'


def card(title, inner, style=""):
    return f'<div class="card" style="{style}"><h3 style="margin:0 0 8px;font-size:15px">{title}</h3>{inner}</div>'


def toolbar(*items):
    return '<div class="toolbar">' + "".join(items) + "</div>"


VS = {"DRAFT": ("mute", "Nháp"), "IN_REVIEW": ("warn", "Chờ duyệt"), "PUBLISHED": ("ok", "Đang phát hành"),
      "DEPRECATED": ("mute", "Ngừng dùng"), "RETIRED": ("mute", "Đã thu hồi")}


def vs(s, v=""):
    k, t = VS[s]
    return tag(k, f"{v} {t}".strip())


IS = {"RUNNING": ("info", "Đang chạy"), "SUSPENDED": ("warn", "Tạm dừng"), "COMPENSATING": ("warn", "Đang bù trừ"),
      "COMPLETED": ("ok", "Hoàn tất"), "CANCELLED": ("mute", "Đã hủy"), "COMPENSATED": ("mute", "Đã bù trừ"), "FAILED": ("err", "Lỗi")}


def ins(s):
    k, t = IS[s]
    return tag(k, t)


DS = {"ON_TIME": ("ok", "Đúng hạn"), "DUE_SOON": ("warn", "Sắp đến hạn"), "OVERDUE": ("err", "Quá hạn"), "PAUSED": ("mute", "Tạm dừng hạn")}


def dsv(s, txt=""):
    k, t = DS[s]
    return tag(k, (txt or t))


# ----------------------------------------------------------------- sơ đồ BPMN (SVG)
def _task(x, y, w, h, label, icon, state="idle", sub="", dashed=False, sel=False, eid=""):
    col = {"idle": ("#fff", "#6b7380", "#1a1d23"), "done": ("#e5f6ec", "#0b7a52", "#0b6b3a"), "run": ("#e6efff", "#0b5cd5", "#0a3f94"),
           "pend": ("#f7f8fa", "#b9c0ca", "#8a919c")}[state]
    dash = ' stroke-dasharray="5 3"' if dashed else ""
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="9" fill="{col[0]}" stroke="{col[1]}" stroke-width="{2.2 if state=="run" else 1.6}"{dash}/>'
    if sel:
        s += f'<rect x="{x-5}" y="{y-5}" width="{w+10}" height="{h+10}" rx="12" fill="none" stroke="#0b5cd5" stroke-width="2" stroke-dasharray="6 3"/>'
        for hx, hy in ((x - 5, y - 5), (x + w + 5, y - 5), (x - 5, y + h + 5), (x + w + 5, y + h + 5)):
            s += f'<rect x="{hx-3}" y="{hy-3}" width="6" height="6" fill="#fff" stroke="#0b5cd5"/>'
    s += f'<text x="{x+8}" y="{y+16}" font-size="13" fill="{col[2]}">{icon}</text>'
    lines = label.split("|")
    for i, l in enumerate(lines):
        s += f'<text x="{x+w/2}" y="{y+h/2-1+ (i-(len(lines)-1)/2)*13}" font-size="11.5" text-anchor="middle" fill="{col[2]}" font-weight="600">{l}</text>'
    if sub:
        s += f'<text x="{x+w/2}" y="{y+h-6}" font-size="9" text-anchor="middle" fill="#6b7380" font-family="Consolas,monospace">{sub}</text>'
    return s


def _ev(cx, cy, r, kind, state="idle", label="", thick=False):
    col = {"idle": "#1a1d23", "done": "#0b7a52", "pend": "#b9c0ca", "run": "#0b5cd5"}[state]
    fill = {"idle": "#fff", "done": "#e5f6ec", "pend": "#f7f8fa", "run": "#e6efff"}[state]
    s = f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" stroke="{col}" stroke-width="{3.2 if thick else 1.6}"/>'
    if kind == "msg":
        s += f'<rect x="{cx-6}" y="{cy-4}" width="12" height="8" fill="none" stroke="{col}"/><path d="M{cx-6} {cy-4}l6 5 6-5" fill="none" stroke="{col}"/>'
    if label:
        s += f'<text x="{cx}" y="{cy+r+14}" font-size="11" text-anchor="middle" fill="#394150">{label}</text>'
    return s


def _gw(cx, cy, k, state="idle"):
    col = {"idle": "#1a1d23", "done": "#0b7a52", "pend": "#b9c0ca", "run": "#0b5cd5"}[state]
    fill = {"idle": "#fff", "done": "#e5f6ec", "pend": "#f7f8fa", "run": "#e6efff"}[state]
    s = f'<path d="M{cx} {cy-26}L{cx+26} {cy}L{cx} {cy+26}L{cx-26} {cy}Z" fill="{fill}" stroke="{col}" stroke-width="1.6"/>'
    s += f'<path d="M{cx-11} {cy}h22M{cx} {cy-11}v22" stroke="{col}" stroke-width="3"/>' if k == "+" else ""
    return s


def _flow(d, state="idle"):
    col = {"idle": "#394150", "done": "#0b7a52", "pend": "#b9c0ca"}[state]
    return f'<path d="{d}" fill="none" stroke="{col}" stroke-width="1.8" marker-end="url(#ar{ {"idle":"i","done":"d","pend":"p"}[state] })"/>'


def bpmn(mode="design", st=None):
    """mode: design (kèm bù trừ, chọn capTheBHYT, huy hiệu kiểm tra) | run (tiến độ phiên)."""
    st = st or {}
    g = lambda k: st.get(k, "idle")
    vb = "0 0 816 520" if mode == "design" else "8 90 808 330"
    s = f'<svg class="bp" viewBox="{vb}" preserveAspectRatio="xMidYMid meet" role="img" aria-label="Sơ đồ quy trình LT_KHAI_SINH">'
    s += '<defs>' + "".join(
        f'<marker id="ar{i}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto"><path d="M0 0L10 5L0 10z" fill="{c}"/></marker>'
        for i, c in (("i", "#394150"), ("d", "#0b7a52"), ("p", "#b9c0ca"))) + '</defs>'
    # luồng
    s += _flow("M56 230H80", g("f1")) + _flow("M184 230H214", g("f2")) + _flow("M318 230H338", g("f3"))
    s += _flow("M364 204V150H420", g("f4")) + _flow("M364 256V310H420", g("f5"))
    s += _flow("M524 150H584V204", g("f6")) + _flow("M524 310H584V256", g("f7")) + _flow("M610 230H630", g("f8")) + _flow("M734 230H756", g("f9"))
    # bước
    s += _ev(40, 230, 16, "msg", g("start"), "Tiếp nhận")
    s += _task(80, 203, 104, 54, "Đăng ký|khai sinh", "⚙", g("guiTuPhap"), "guiTuPhap")
    s += _task(214, 203, 104, 54, "Thẩm định|hồ sơ", "👤", g("thamDinh"), "thamDinh")
    s += _gw(364, 230, "+", g("split"))
    s += _task(420, 123, 104, 54, "Đăng ký|thường trú", "⚙", g("guiCuTru"), "guiCuTru")
    s += _task(420, 283, 104, 54, "Cấp thẻ|BHYT", "⚙", g("capTheBHYT"), "capTheBHYT", sel=(mode == "design"))
    s += _gw(584, 230, "+", g("join"))
    s += _task(630, 203, 104, 54, "Thông báo|kết quả", "✉", g("thongBao"), "thongBao")
    s += _ev(772, 230, 16, "", g("end"), "Hoàn tất", thick=True)
    # hẹn giờ biên không ngắt
    tc = {"idle": "#7a5200", "done": "#0b7a52", "pend": "#b9c0ca", "run": "#c98a00"}[g("timer")]
    s += f'<circle cx="448" cy="337" r="12" fill="#fff" stroke="{tc}" stroke-width="1.6" stroke-dasharray="3 2"/><circle cx="448" cy="337" r="8.5" fill="none" stroke="{tc}" stroke-dasharray="3 2"/><path d="M448 331v6l4 3" stroke="{tc}" fill="none" stroke-width="1.5"/>'
    s += f'<text x="448" y="362" font-size="10.5" text-anchor="middle" fill="#7a5200">2 ngày LV</text>'
    if mode == "design":
        # bù trừ
        for cx, cy, tx, ty, lbl, sub in ((132, 257, 80, 380, "Đánh dấu chờ|xử lý hộ tịch", "huyKhaiSinh"), (496, 337, 452, 380, "Hủy|thẻ BHYT", "huyTheBHYT"), (472, 123, 420, 30, "Hủy đăng ký|thường trú", "huyCuTru")):
            s += f'<circle cx="{cx}" cy="{cy}" r="11" fill="#fff" stroke="#394150" stroke-width="1.6"/><path d="M{cx+5} {cy-5}l-6 5 6 5zM{cx-1} {cy-5}l-6 5 6 5z" fill="#394150"/>'
            ty2 = ty + 46 if ty < 100 else ty
            s += f'<path d="M{cx} {cy+(11 if ty>100 else -11)}V{ty2 if ty>100 else ty2}" stroke="#394150" stroke-dasharray="2 3" fill="none"/>'
            s += _task(tx, ty, 104, 46, lbl, "↶", "idle", sub, dashed=True)
        # huy hiệu kiểm tra
        s += '<circle cx="314" cy="203" r="9" fill="#c98a00"/><text x="314" y="207" font-size="11" text-anchor="middle" fill="#fff" font-weight="700">!</text>'
        s += '<circle cx="520" cy="123" r="9" fill="#c98a00"/><text x="520" y="127" font-size="11" text-anchor="middle" fill="#fff" font-weight="700">!</text>'
    else:
        s += '<circle cx="508" cy="283" r="10" fill="#0b5cd5"/><text x="508" y="287" font-size="11" text-anchor="middle" fill="#fff">⏳</text>'
        s += '<text x="472" y="388" font-size="11.5" text-anchor="middle" fill="#0a3f94" font-weight="600">Chờ PH-04 trả kết quả từ 08:42 (đã 2 giờ 18 phút)</text>'
    return s + "</svg>"


# ================================================================= UI-11-01
def ui01():
    rows = [
        (mono("LT_KHAI_SINH"), "<b>Liên thông khai sinh, thường trú, BHYT trẻ dưới 6 tuổi</b>", "TTHC_LIEN_THONG", vs("PUBLISHED", "v2"), vs("DRAFT", "v3"), "<span class='num'>1.284</span>", "Lê Quốc Thái", "26/11/2026 10:42"),
        (mono("DUYET_KET_NAP_HTTT"), "Duyệt kết nạp HTTT hai cấp", "QUAN_TRI_NEN_TANG", vs("PUBLISHED", "v1"), vs("PUBLISHED", "v1"), "<span class='num'>12</span>", "Trần Thị Mai", "18/11/2026 15:08"),
        (mono("LT_KET_HON"), "Liên thông đăng ký kết hôn và cập nhật cư trú", "TTHC_LIEN_THONG", vs("IN_REVIEW", "v1"), vs("IN_REVIEW", "v1"), "<span class='num'>0</span>", "Lê Quốc Thái", "25/11/2026 16:30"),
        (mono("LT_DAT_DAI_THUE"), "Liên thông cấp giấy chứng nhận đất và nghĩa vụ tài chính", "TTHC_LIEN_THONG", vs("PUBLISHED", "v4"), vs("PUBLISHED", "v4"), "<span class='num'>358</span>", "Phạm Văn Hưng", "02/11/2026 09:12"),
        (mono("XAC_NHAN_CU_TRU"), "Xác nhận thông tin cư trú", "TTHC_DON_LE", vs("DEPRECATED", "v2"), vs("PUBLISHED", "v3"), "<span class='num'>4</span>", "Phạm Văn Hưng", "20/10/2026 11:00"),
        (mono("CAP_PHEP_XD"), "Cấp phép xây dựng", "TTHC_LIEN_THONG", "<span class='muted'>Chưa có bản phát hành</span>", vs("DRAFT", "v1"), "<span class='num'>0</span>", "Nguyễn Hoàng Anh", "24/11/2026 14:20"),
        (mono("CHAM_DUT_HOP_DONG"), "Chấm dứt hợp đồng lao động và bảo hiểm", "TTHC_LIEN_THONG", vs("RETIRED", "v1"), vs("RETIRED", "v1"), "<span class='num'>0</span>", "Trần Thị Mai", "01/09/2026 08:45"),
    ]
    acts = '<span class="muted">⋯</span>'
    rows = [r + (acts,) for r in rows]
    body = f"""{head("Mô hình quy trình", btn("Nhập tệp BPMN"), btn("+ Tạo mô hình", "pri"))}
{facets(["Tất cả 14", "Có bản phát hành 9", "Đang nháp 3", "Chờ duyệt 1", "Đã ngừng 1"], 0)}
<div class="card">{toolbar(inp("🔍 Tìm theo mã hoặc tên", "min-width:260px"), inp("Nhóm: Tất cả ▾"), inp("Trạng thái bản mới nhất: Tất cả ▾"), inp("Người sửa cuối ▾"), '<span class="sp" style="flex:1"></span><label class="muted"><span class="kbd">☐</span> Gồm mẫu dùng chung</label>')}
{table(["Mã", "Tên", "Nhóm nghiệp vụ", "Bản đang phát hành", "Bản mới nhất", "Phiên đang chạy", "Người sửa cuối", "Cập nhật", ""], rows, "Danh sách mô hình quy trình")}
{foot("Hiển thị 1–7 trên 14 mô hình")}</div>"""
    return shell("01", "Danh sách mô hình quy trình", "Quy trình › Mô hình quy trình", body, "mh", 0)


# ================================================================= UI-11-04
def pal_item(ic, t, off=False):
    return f'<div class="it{" off" if off else ""}"><i>{ic}</i>{t}</div>'


def ui04():
    pal = '<div class="pal" aria-label="Bảng phần tử"><div class="input" style="width:100%;height:28px">🔍 Tìm phần tử</div>'
    for g, its in (("Sự kiện", [("○", "Bắt đầu"), ("◉", "Kết thúc")]),
                   ("Việc", [("👤", "Việc người dùng"), ("⚙", "Bước tự động (PH-04)"), ("✉", "Gửi thông báo"), ("▦", "Bảng quyết định (C)")]),
                   ("Cổng", [("◇", "Loại trừ"), ("✚", "Song song"), ("◈", "Bao hàm"), ("◇", "Theo sự kiện")]),
                   ("Sự kiện trung gian và biên", [("⏱", "Hẹn giờ"), ("✉", "Chờ thông điệp"), ("↶", "Bù trừ"), ("⚡", "Bắt lỗi biên")]),
                   ("Cấu trúc", [("▭", "Quy trình con"), ("⇲", "Gọi quy trình con")]),
                   ("Không hỗ trợ", [("▤", "Script task", True), ("▥", "Transaction", True)])):
        pal += f'<div class="g">{g}</div>' + "".join(pal_item(*i) for i in its)
    pal += "</div>"
    glass_min = '<div class="glassbox" style="left:12px;bottom:12px;width:150px;height:70px"><div class="muted">Bản đồ nhỏ</div></div>'
    glass_zoom = '<div class="glassbox" style="left:12px;bottom:92px;display:flex;flex-direction:column;gap:2px"><span class="kbd">+</span><span class="kbd">−</span><span class="kbd">⛶</span></div>'
    glass_pad = '<div class="glassbox" style="left:538px;top:268px;display:flex;gap:6px;z-index:2"><span>✂</span><span>⌫</span><span>⇢</span><span>⚙</span></div>'
    cv = f'<div class="cv">{bpmn("design")}{glass_zoom}{glass_min}{glass_pad}<div class="logo-bpmn" title="bpmn.io"><i></i>bpmn.io</div></div>'
    insp = """<div class="insp" aria-label="Bảng thuộc tính"><h3>Cấp thẻ BHYT <span class="muted mono">capTheBHYT</span></h3>
<div class="muted" style="margin-bottom:6px">Bước tự động · SERVICE_TASK</div>
<div class="tabs"><span>Chung</span><span class="on">Bước tự động</span><span>Bù trừ</span><span>Tài liệu</span></div>
<div class="field"><label>Ý định nghiệp vụ *</label><span class="input">capTheBHYT ▾ &nbsp;<span class="tag t-ok">ACTIVE</span></span><div class="muted" style="margin-top:2px">→ luồng <span class="mono">bhxh-cap-the</span> · PROD đã phát hành v3</div></div>
<div class="field"><label>Ánh xạ biến vào</label><span class="input" style="height:auto;padding:4px 8px;display:block"><span class="mono">soDinhDanhTre ← ${soDinhDanhTre}</span><br><span class="mono">maXa ← ${maXaCuTru}</span></span></div>
<div class="field"><label>Thời gian chờ (phút)</label><span class="input">2.880 &nbsp;<span class="muted">= 2 ngày</span></span></div>
<div class="field"><label>Lỗi nghiệp vụ</label><span class="input">BHXH_TU_CHOI → sự kiện biên lỗi</span></div>
<div class="grp-t" style="margin-top:6px">Bù trừ (BR-11-008)</div>
<div class="field"><label>Chính sách</label><span class="seg"><span class="on">Tự động</span><span>Thủ công</span><span>Miễn (có duyệt)</span></span></div>
<div class="field"><label>Ý định bù trừ *</label><span class="input">huyTheBHYT ▾</span></div>
<div class="field"><label>Ghi chú nghiệp vụ * (≥ 20 ký tự)</label><span class="input" style="height:46px;align-items:flex-start;padding-top:4px;white-space:normal">Gửi yêu cầu hủy thẻ chưa kích hoạt; thẻ đã cấp thì khóa và báo BHXH.</span></div></div>"""
    bot = """<div class="botp"><div class="tabs"><span class="on">Kết quả kiểm tra · 0 lỗi · 2 cảnh báo · 1 thông tin</span><span>Biến (6)</span><span>Nhật ký lưu</span></div>
<table aria-label="Kết quả kiểm tra"><thead><tr><th>Mức</th><th>Quy tắc</th><th>Phần tử</th><th>Mô tả</th></tr></thead><tbody>
<tr><td><span class="tag t-warn">⚠ Cảnh báo</span></td><td class="mono">TASK_NO_DUE</td><td class="mono">thamDinh</td><td>Việc chưa có hạn xử lý. Đặt hạn ở thẻ Chung.</td></tr>
<tr><td><span class="tag t-warn">⚠ Cảnh báo</span></td><td class="mono">SERVICE_NO_TIMEOUT_BOUNDARY</td><td class="mono">guiCuTru</td><td>Bước tự động chưa có hẹn giờ biên, đang dùng thời gian chờ mặc định.</td></tr>
<tr><td><span class="tag t-info">ⓘ Thông tin</span></td><td class="mono">NO_PUBLIC_NAME</td><td class="mono">LT_KHAI_SINH</td><td>Đã có 3 bước có tên công khai; Cổng DVC hiển thị tiến độ ba bước.</td></tr></tbody></table></div>"""
    tb = """<div class="tb"><span class="ibtn">‹</span><b>LT_KHAI_SINH</b><span class="tag t-mute">v3 Nháp</span>
<span class="tag t-ok">🔒 Bạn đang giữ khóa · còn 29 phút</span><span class="muted">✓ Lưu lúc 10:42</span><span class="sp"></span>
<span class="ibtn">↶</span><span class="ibtn">↷</span><span class="seg"><span>Vừa khung</span><span class="on">100%</span></span><span class="ibtn">?</span>
<span class="btn">Biến (6)</span><span class="btn">Kiểm tra</span><span class="btn">Chạy thử</span><span class="btn pri">Gửi duyệt</span></div>"""
    body = f'<div class="dz">{tb}<div class="mid">{pal}{cv}{insp}</div>{bot}</div>'
    return shell("04", "Trình thiết kế BPMN", "", body, "mh", fixed=True)


# ================================================================= UI-11-11
def ui11():
    def r(k, pk, v, s, wait, step, due, inc, t, ch):
        return (mono(k), f"{mono(pk)} v{v}", ins(s), wait, step, due, inc, t, ch)
    rows = [
        r("HS-T68-2026-000142", "LT_KHAI_SINH", 2, "RUNNING", "Chờ hệ thống", "Cấp thẻ BHYT", dsv("ON_TIME", "Còn 1,5 ngày LV"), "", "26/11 08:40", "API · Cổng DVC"),
        r("HS-T68-2026-000139", "LT_KHAI_SINH", 2, "RUNNING", "Chờ cán bộ", "Thẩm định hồ sơ", dsv("DUE_SOON", "Còn 3 giờ LV"), "", "25/11 15:12", "API · Cổng DVC"),
        r("HS-T68-2026-000121", "LT_KHAI_SINH", 2, "RUNNING", "Chờ hệ thống", "Đăng ký thường trú", dsv("OVERDUE", "Quá 1 ngày"), tag("err", "⚠ Sự cố"), "20/11 09:02", "API · Cổng DVC"),
        r("HS-T68-2026-000098", "LT_KHAI_SINH", 1, "SUSPENDED", "—", "Thẩm định hồ sơ", dsv("PAUSED", "Chờ bổ sung"), "", "12/11 10:20", "Thủ công"),
        r("KN-T68-2026-000031", "DUYET_KET_NAP_HTTT", 1, "RUNNING", "Chờ cán bộ", "Duyệt cấp tỉnh", dsv("ON_TIME", "Còn 4 ngày LV"), "", "24/11 14:00", "API · PH-01"),
        r("HS-T68-2026-000077", "LT_KHAI_SINH", 1, "COMPENSATING", "Chờ hệ thống", "Bù trừ: Hủy thẻ BHYT", dsv("OVERDUE", "Quá 3 ngày"), tag("warn", "Bù trừ"), "03/11 16:45", "API · Cổng DVC"),
        r("HS-T68-2026-000064", "LT_KHAI_SINH", 1, "COMPLETED", "—", "Hoàn tất", tag("ok", "Đúng hạn"), "", "28/10 08:10", "API · Cổng DVC"),
        r("HS-T68-2026-000052", "LT_KHAI_SINH", 1, "COMPENSATED", "—", "Đã bù trừ", tag("mute", "Đã đóng"), "", "21/10 11:32", "API · Cổng DVC"),
    ]
    body = f"""{banner("w", "5 phiên có sự cố đang mở, 2 phiên đang bù trừ. Mở màn Sự cố hoặc Bù trừ để xử lý.", "Mở Sự cố")}
{head("Phiên quy trình", btn("Xuất CSV"), btn("Di trú phiên"), btn("+ Khởi tạo thủ công", "pri"))}
{facets(["Đang chạy 1.296", "Tạm dừng 3", "Đang bù trừ 2", "Lỗi 1", "Hoàn tất 28.412", "Đã hủy, đã bù trừ 187"], 0)}
<div class="card">{toolbar(inp("🔍 Mã hồ sơ (chính xác hoặc tiền tố)", "min-width:270px"), inp("Quy trình: Tất cả ▾"), inp("Bước hiện tại ▾"), inp("Hạn: Tất cả ▾"), inp("Có sự cố ▾"), inp("Bắt đầu: 01/11 – 26/11 ▾"))}
{table(["Mã hồ sơ", "Quy trình", "Trạng thái", "Đang chờ", "Bước hiện tại", "Hạn", "Sự cố", "Bắt đầu", "Kênh"], rows, "Danh sách phiên quy trình")}
{foot("Hiển thị 1–8 trên 1.296 phiên đang chạy")}</div>"""
    return shell("11", "Danh sách phiên quy trình", "Quy trình › Phiên quy trình", body, "ph", 0)


# ================================================================= UI-11-12
def ui12():
    st = dict(start="done", f1="done", guiTuPhap="done", f2="done", thamDinh="done", f3="done", split="done", f4="done", f5="done",
              guiCuTru="done", capTheBHYT="run", timer="run", f6="done", f7="pend", join="pend", f8="pend", thongBao="pend", f9="pend", end="pend")
    cv = f'<div class="cv" style="height:430px;border-radius:12px;border:1px solid var(--color-border)">{bpmn("run", st)}</div>'
    head_c = f"""<div class="chrome" style="margin-bottom:10px"><div class="crumb" style="margin:0">Quy trình › Phiên quy trình › HS-T68-2026-000142</div>
<h1><span class="mono">HS-T68-2026-000142</span> {ins("RUNNING")} {tag("info", "Chờ hệ thống")} {dsv("ON_TIME", "Còn 1,5 ngày LV")}<span class="sp" style="flex:1"></span>{btn("Tạm dừng")}{btn("Hủy phiên", "danger")}{btn("Thao tác quản trị ▾")}</h1>
<div class="muted"><span class="mono">LT_KHAI_SINH</span> v2 · bắt đầu 26/11/2026 08:40 · kênh API (Cổng DVC tỉnh) · hạn 02/12/2026 17:00 · mã truy vết <span class="mono">4f2a…91c</span></div></div>"""
    tabs = '<div class="tabs" role="tablist"><span class="on">Sơ đồ</span><span>Dòng thời gian</span><span>Biến</span><span>Việc (1)</span><span>Bước tự động (2)</span><span>Bù trừ</span><span>Sự cố (0)</span></div>'
    tl = f"""<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Dòng thời gian bước</h3><div class="vtl">
<div><b>08:40</b> Tiếp nhận hồ sơ từ Cổng DVC <span class="muted">· EVT-11-03</span></div>
<div><b>08:41</b> Đăng ký khai sinh (Tư pháp) hoàn tất sau 1 phút <span class="muted">· commandId <span class="mono">c-7d1…</span></span></div>
<div><b>09:15</b> Thẩm định hồ sơ do <b>Nguyễn Thị Lan</b> hoàn tất, quyết định Đồng ý</div>
<div><b>09:16</b> Đăng ký thường trú (Công an) hoàn tất sau 2 phút</div>
<div style="color:#0a3f94"><b>09:16</b> Cấp thẻ BHYT (BHXH) đang chờ kết quả, hẹn giờ biên 2 ngày LV đang chạy</div></div></div>"""
    side = f"""<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Tóm tắt phiên</h3><dl class="dl" style="grid-template-columns:110px 1fr"><dt>Bước hiện tại</dt><dd>Cấp thẻ BHYT</dd><dt>Chờ</dt><dd>PH-04 · <span class="mono">bhxh-cap-the</span></dd><dt>Lần gửi</dt><dd>1 · hết hạn chờ sau 2 ngày</dd><dt>Hạn phiên</dt><dd>02/12/2026 17:00</dd><dt>Người giữ việc</dt><dd>—</dd><dt>Saga</dt><dd>Chưa kích hoạt</dd></dl></div>
<div class="card" style="margin-top:10px"><h3 style="margin:0 0 8px;font-size:15px">Biến (đã che)</h3><dl class="dl" style="grid-template-columns:120px 1fr"><dt>soDinhDanhTre</dt><dd><span class="mono">•••••••••142</span> <span class="tag t-mute">SENSITIVE</span></dd><dt>hoTenMe</dt><dd>Nguyễn T** L**</dd><dt>maXaCuTru</dt><dd class="mono">20245</dd><dt>donViTiepNhan</dt><dd class="mono">UBND_XA_A</dd></dl></div>"""
    body = f'<main>{head_c}{tabs}<div class="grid3" style="grid-template-columns:minmax(0,1fr) 340px">{"<div>" + cv + "<div style=margin-top:10px>" + tl + "</div></div>"}<div>{side}</div></div></main>'
    return shell("12", "Chi tiết phiên quy trình", "", body, "ph", fixed=False).replace("<main><main>", "<main>")


# ================================================================= UI-11-15
def ui15():
    chrome = f"""<div class="chrome"><div class="crumb" style="margin:0">Việc của tôi › Hộp việc › Thẩm định hồ sơ</div>
<h1>Thẩm định hồ sơ khai sinh · <span class="mono">HS-T68-2026-000142</span> {tag("warn", "Còn 3 giờ làm việc")} {tag("info", "Đang giữ: bạn")}<span class="sp" style="flex:1"></span>{btn("Trả lại việc")}</h1>
<div class="muted">Quy trình <span class="mono">LT_KHAI_SINH</span> v2 · bước <span class="mono">thamDinh</span> · hạn 26/11/2026 17:00 · giao cho nhóm Thẩm định hộ tịch (đã nhận 09:20)</div></div>"""
    left = f"""<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Thông tin hồ sơ</h3>
<dl class="dl" style="grid-template-columns:104px 1fr;font-size:12.5px"><dt>Loại hồ sơ</dt><dd>Khai sinh, thường trú, BHYT</dd><dt>Họ tên trẻ</dt><dd>N** V** A</dd><dt>Số định danh</dt><dd><span class="mono">•••••••••142</span> <span class="tag t-mute">Che</span></dd><dt>Ngày sinh</dt><dd>**/10/2026</dd><dt>Cha, mẹ</dt><dd>Nguyễn T** L** · Trần V** H**</dd><dt>Xã tiếp nhận</dt><dd>UBND xã A</dd><dt>Tiếp nhận</dt><dd>26/11/2026 08:40</dd></dl>
<div style="margin-top:8px">{btn("Xem hồ sơ gốc ↗")}</div></div>
<div class="card" style="margin-top:10px"><h3 style="margin:0 0 8px;font-size:15px">Các bước trước</h3><div class="vtl"><div><b>08:40</b> Tiếp nhận hồ sơ</div><div><b>08:41</b> Đăng ký khai sinh (Tư pháp): hoàn tất</div><div style="color:#0a3f94"><b>09:20</b> Thẩm định hồ sơ: bạn đang xử lý</div></div></div>"""
    mid = f"""<div class="card"><h3 style="margin:0 0 4px;font-size:15px">Phiếu thẩm định <span class="muted" style="font-weight:400">· <span class="mono">tham-dinh-khai-sinh</span> v2 · <span style="color:#0b6b3a">✓ Đã lưu nháp 10:42</span></span></h3>
<div class="muted" style="margin-bottom:10px">Trường có dấu * là bắt buộc.</div>
<div class="field"><label>Kết quả thẩm định *</label><div class="radio on"><i></i>Hồ sơ đủ điều kiện</div><div class="radio"><i></i>Hồ sơ thiếu giấy tờ, cần bổ sung</div></div>
<div class="row"><div class="field"><label>Đối chiếu giấy chứng sinh *</label><span class="input">☑ Đã đối chiếu bản gốc</span></div><div class="field"><label>Nơi đăng ký thường trú *</label><span class="input">Xã A, huyện B ▾</span></div></div>
<div class="row"><div class="field"><label>Ngày hẹn trả kết quả *</label><span class="input">02/12/2026 📅</span></div><div class="field"><label>Mức ưu tiên</label><span class="input">Bình thường ▾</span></div></div>
<div class="field"><label>Ghi chú thẩm định</label><span class="input" style="height:64px;align-items:flex-start;padding-top:6px;white-space:normal">Giấy chứng sinh hợp lệ, thông tin cha mẹ khớp cơ sở dữ liệu cư trú.</span></div></div>"""
    right = f"""<div class="card"><div class="tabs"><span class="on">Ý kiến (3)</span><span>Tệp (2)</span><span>Gợi ý AI</span></div>
<div class="cm"><b>Lê Văn Cường</b> <small>· 26/11 09:05 · tiếp nhận</small><br>Đã kiểm hồ sơ đủ thành phần, chuyển thẩm định.</div>
<div class="cm"><b>Nguyễn Thị Lan</b> <small>· 26/11 09:22</small><br>Cần đối chiếu họ tên mẹ với cơ sở dữ liệu dân cư.</div>
<div class="cm"><b>Bạn</b> <small>· 26/11 10:40</small><br>Đã đối chiếu, khớp.</div>
<div class="field" style="margin-top:8px"><span class="input" style="height:54px;align-items:flex-start;padding-top:6px;width:100%">Nhập ý kiến, dùng @ để nhắc người khác…</span></div>
<div style="display:flex;justify-content:space-between" class="muted"><span>📎 Kéo tệp vào đây (≤ 20 MB)</span><span>{btn("Gửi ý kiến")}</span></div></div>"""
    dec = f"""<div class="dec" role="group" aria-label="Quyết định"><span class="muted">Bước này cho phép:</span>{btn("Đồng ý", "pri wide")}{btn("Từ chối", "danger wide")}{btn("Trả về…", "wide")}{btn("Yêu cầu bổ sung…", "wide")}<span class="sp"></span>{btn("Chuyển việc…")}{btn("Lưu nháp")}</div>"""
    body = f'<main style="padding-bottom:80px;overflow:hidden">{chrome}<div class="cols3"><div>{left}</div><div>{mid}</div><div>{right}</div></div></main>'
    return shell("15", "Xử lý việc", "", body, "vc", extra=dec).replace("<body>", '<body style="position:relative;height:100vh;overflow:hidden">').replace('<div class="shell">', '<div class="shell" style="height:100vh;min-height:0">')


# ================================================================= UI-11-18
def ui18():
    def month(name, start, days, hol=(), mk=()):
        cells = "".join(f'<span class="t">{x}</span>' for x in ("T2", "T3", "T4", "T5", "T6", "T7", "CN"))
        cells += "<span></span>" * start
        for d in range(1, days + 1):
            wd = (start + d - 1) % 7
            c = "h" if d in hol else ("m" if d in mk else ("w" if wd >= 5 else ""))
            cells += f'<span class="{c}">{d}</span>'
        return f'<div class="mon"><h4>{name}</h4><div class="d">{cells}</div></div>'
    # 2026: 01/01 là thứ Năm (start=3)
    ms = [month("Tháng 1", 3, 31, hol=(1,)), month("Tháng 2", 6, 28, hol=(16, 17, 18, 19, 20)), month("Tháng 3", 6, 31), month("Tháng 4", 2, 30, hol=(27, 30)),
          month("Tháng 5", 4, 31, hol=(1,), mk=(9,)), month("Tháng 6", 0, 30), month("Tháng 7", 2, 31), month("Tháng 8", 5, 31),
          month("Tháng 9", 1, 30, hol=(1, 2)), month("Tháng 10", 3, 31), month("Tháng 11", 6, 30), month("Tháng 12", 1, 31)]
    cal = '<div class="cal">' + "".join(ms) + "</div>"
    left = f"""<div class="card"><div style="display:flex;align-items:center;gap:10px;margin-bottom:8px"><b style="font-size:15px">Lịch năm</b>{inp("2026 ▾", "min-width:80px")}<span class="muted">Đã nhập từ lịch quốc gia COMMON · 11 ngày nghỉ · 1 ngày làm bù (minh họa)</span><span style="flex:1"></span>{btn("Nhập từ lịch quốc gia")}{btn("+ Thêm ngày")}</div>{cal}
<div class="legend"><span><i style="background:#fde8e8"></i>Ngày nghỉ (HOLIDAY)</span><span><i style="background:#e5f6ec"></i>Làm bù (MAKEUP_WORKDAY)</span><span><i style="background:#f1f3f5"></i>Cuối tuần</span></div></div>"""
    right = f"""<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Tuần và giờ làm việc</h3>
<div class="field"><label>Ngày làm việc trong tuần</label><span class="seg"><span class="on">T2</span><span class="on">T3</span><span class="on">T4</span><span class="on">T5</span><span class="on">T6</span><span>T7</span><span>CN</span></span></div>
<div class="field"><label>Giờ làm việc *</label><span class="input">07:30 – 11:30</span><div style="height:4px"></div><span class="input">13:30 – 17:00</span></div>
<div class="muted">Múi giờ <span class="mono">Asia/Ho_Chi_Minh</span> · 7,5 giờ mỗi ngày làm việc</div></div>
<div class="card" style="margin-top:10px"><h3 style="margin:0 0 8px;font-size:15px">Tính thử hạn</h3>
<div class="row"><div class="field"><label>Bắt đầu</label><span class="input">25/12/2026 16:00</span></div><div class="field"><label>Hạn</label><span class="input">2 ngày làm việc ▾</span></div></div>
<div class="verify"><div>Kết quả: <b>29/12/2026 16:00</b> (thứ Ba)</div><div class="muted">Bỏ qua thứ Bảy 26/12, Chủ nhật 27/12; tính 28/12 và 29/12.</div></div>{btn("Tính thử", "pri")}</div>
<div class="card" style="margin-top:10px"><h3 style="margin:0 0 8px;font-size:15px">Ngày đặc biệt của tỉnh</h3>{table(["Ngày", "Loại", "Tên"], [("27/04/2026", tag("err", "Nghỉ"), "Nghỉ bù Giỗ Tổ"), ("09/05/2026", tag("ok", "Làm bù"), "Làm bù 02/05"), ("01/09/2026", tag("err", "Nghỉ"), "Nghỉ Quốc khánh")], "Ngày đặc biệt")}</div>"""
    body = f"""{banner("w", "Năm 2027 chưa có lịch làm việc; hạn đang tính theo lịch mặc định (thứ Hai đến thứ Sáu).", "Tạo lịch 2027")}
{head("Lịch làm việc", btn("Hoàn tác thay đổi"), btn("Lưu lịch", "pri"))}<div class="grid3" style="grid-template-columns:minmax(0,1fr) 380px">{left}<div>{right}</div></div>"""
    return shell("18", "Lịch làm việc", "Quy trình › Giám sát quy trình › Lịch làm việc", body, "gs", 4)


# ================================================================= UI-11-19
def ui19():
    def line(pts, col, w=560, h=140):
        return f'<polyline fill="none" stroke="{col}" stroke-width="2.2" points="{pts}"/>'
    import math
    xs = [i * 560 / 11 for i in range(12)]
    a = [94, 93, 95, 96, 94, 92, 93, 95, 94, 91, 93, 94.2]
    b = [31, 40, 29, 33, 45, 52, 38, 36, 41, 58, 44, 37]
    pa = " ".join(f"{int(x)},{int(130-(v-85)/(100-85)*120)}" for x, v in zip(xs, a))
    pb = " ".join(f"{int(x)},{int(130-v/80*120)}" for x, v in zip(xs, b))
    chart = f'<svg viewBox="0 0 560 140" class="line" role="img" aria-label="Tỷ lệ đúng hạn và số việc quá hạn 12 ngày">{line(pa, "#0b7a52")}{line(pb, "#c0392b")}<line x1="0" y1="45" x2="560" y2="45" stroke="#a11a1a" stroke-dasharray="4 4"/><text x="556" y="40" font-size="11" text-anchor="end" fill="#a11a1a">ngưỡng cảnh báo 50 việc quá hạn</text></svg>'
    bott = table(["Quy trình", "Bước", "Hồ sơ đang chờ", "Chờ lâu nhất", "p95 lịch sử", "Hệ số"], [
        (mono("LT_KHAI_SINH"), "Đăng ký thường trú", "<span class='num'>12</span>", "3 ngày 4 giờ", "7 giờ", tag("err", "× 10,9")),
        (mono("LT_DAT_DAI_THUE"), "Thẩm định hồ sơ", "<span class='num'>41</span>", "6 ngày", "2 ngày", tag("warn", "× 3,0")),
        (mono("DUYET_KET_NAP_HTTT"), "Duyệt cấp tỉnh", "<span class='num'>3</span>", "2 ngày", "1,5 ngày", tag("ok", "× 1,3"))], "Bước tắc nghẽn")
    over = table(["Hồ sơ", "Việc", "Người giữ", "Quá hạn"], [
        (mono("HS-T68-2026-000121"), "Đăng ký thường trú", "—", tag("err", "1 ngày LV")), (mono("HS-T68-2026-000077"), "Hủy thẻ BHYT (thủ công)", "Vận hành", tag("err", "3 ngày LV")),
        (mono("HS-T68-2026-000045"), "Thẩm định hồ sơ", "Phạm Thu Hà", tag("err", "4 giờ LV"))], "Việc quá hạn")
    body = f"""{banner("e", "Outbox sự kiện tồn đọng: độ trễ 75 giây (ngưỡng 60 giây). Đã mở sự cố ERR-11-117.", "Mở sự cố")}
{head("Giám sát quy trình", inp("Quy trình: Tất cả ▾"), '<span class="seg"><span>24 giờ</span><span class="on">7 ngày</span><span>30 ngày</span></span>', '<span class="muted">Số liệu cập nhật 14:02</span>', btn("⟳"))}
{kpis([kpi("Phiên đang chạy", "1.296", "▲ 4,1% so với 7 ngày trước"), kpi("Việc quá hạn", "37", "⚠ gần ngưỡng cảnh báo 50"), kpi("Sự cố mở", "5", "1 bù trừ thất bại (P1)"), kpi("Đúng hạn 7 ngày", "94,2%", "● Đạt mục tiêu 90%"), kpi("Bù trừ thất bại", "0,4%", "ngưỡng 2%")])}
<div class="grid-2e"><div class="card"><h3 style="margin:0 0 8px;font-size:15px">Đúng hạn và việc quá hạn (12 ngày)</h3>{chart}<div class="legend"><span><i style="background:#0b7a52"></i>Tỷ lệ đúng hạn</span><span><i style="background:#c0392b"></i>Số việc quá hạn</span></div></div>
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Phiên theo trạng thái</h3><div class="hbar"><span>Đang chạy</span><i style="width:100%"></i><b>1.296</b></div><div class="hbar"><span>Tạm dừng</span><i style="width:6%;background:#c98a00"></i><b>3</b></div><div class="hbar"><span>Đang bù trừ</span><i style="width:4%;background:#c98a00"></i><b>2</b></div><div class="hbar"><span>Lỗi</span><i style="width:3%;background:#c0392b"></i><b>1</b></div><div class="hbar"><span>Hoàn tất (7 ngày)</span><i style="width:70%;background:#0b7a52"></i><b>913</b></div></div></div>
<div class="grid-2e" style="margin-top:12px"><div class="card"><h3 style="margin:0 0 8px;font-size:15px">Bước tắc nghẽn</h3>{bott}</div><div class="card"><h3 style="margin:0 0 8px;font-size:15px">Việc quá hạn lâu nhất</h3>{over}</div></div>"""
    return shell("19", "Giám sát quy trình", "Quy trình › Giám sát quy trình", body, "gs", 0)


# ================================================================= UI-11-21
def ui21():
    list_ = table(["Hồ sơ", "Kích hoạt", "Trạng thái Saga", "Bước", "Bắt đầu"], [
        (mono("HS-T68-2026-000077"), "Lỗi bước (BHYT)", tag("warn", "PARTIAL"), "2/3 · 1 thủ công", "03/11 16:45"),
        (mono("HS-T68-2026-000051"), "Hủy phiên", tag("ok", "SUCCEEDED"), "3/3", "29/10 10:02"),
        (mono("HS-T68-2026-000049"), "Lỗi bước (cư trú)", tag("info", "RUNNING"), "1/2", "26/11 09:55"),
        (mono("KN-T68-2026-000012"), "Thủ công", tag("err", "FAILED"), "0/1", "17/11 08:30")], "Nhật ký Saga", cls=["d-chg", "", "", ""])
    steps = f"""<div class="step"><span class="n done">✓</span><div><b>Hủy đăng ký thường trú</b> <span class="mono">huyCuTru</span><br><span class="muted">DONE · lần 1 · 16:46 · phản hồi 200</span></div></div>
<div class="step"><span class="n done">✓</span><div><b>Đánh dấu chờ xử lý hộ tịch</b> <span class="mono">huyKhaiSinh</span><br><span class="muted">DONE · lần 1 · 16:47 · phản hồi 200</span></div></div>
<div class="step"><span class="n man">!</span><div style="flex:1"><b>Hủy thẻ BHYT</b> <span class="mono">huyTheBHYT</span> {tag("warn", "MANUAL")}<br><span class="muted">Thất bại sau 3 lần thử (cách nhau 5 phút): BHXH_THE_DA_KICH_HOAT</span><div style="margin-top:6px">{btn("Thử lại")}{btn("Ghi nhận đã xử lý tay", "pri")}{btn("Bỏ qua (cần người khác duyệt)", "danger")}</div></div></div>"""
    detail = f"""{banner("e", "Bù trừ huyTheBHYT của hồ sơ HS-T68-2026-000077 vẫn lỗi: thẻ đã kích hoạt, BHXH không cho hủy. Đã tạo việc xử lý thủ công cho nhóm Vận hành.")}
<div class="card"><h3 style="margin:0 0 4px;font-size:15px">Saga của <span class="mono">HS-T68-2026-000077</span> {tag("warn", "PARTIAL")}</h3><div class="muted" style="margin-bottom:8px">Kích hoạt: lỗi bước Cấp thẻ BHYT (ERR-11-105) · thứ tự bù trừ ngược thời điểm hoàn thành (BR-11-011)</div>{steps}</div>"""
    recon = f"""<div class="card" style="margin-top:12px"><h3 style="margin:0 0 6px;font-size:15px">Đối soát bù trừ</h3><div class="muted">Lần chạy gần nhất 26/11 02:00 · đối chiếu 14 bù trừ trong 7 ngày</div>
<div class="verify" style="margin-top:6px"><div>{tag("ok", "13 khớp")} {tag("err", "1 lệch")}</div><div>Đối soát phát hiện 1 bù trừ chưa có hiệu lực ở BHXH.</div></div><div style="margin-top:8px">{btn("Chạy đối soát ngay")}</div></div>"""
    body = f"""{head("Nhật ký Saga và đối soát bù trừ", inp("Trạng thái: Tất cả ▾"), inp("Quy trình ▾"), inp("01/11 – 26/11 ▾"))}
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 560px"><div class="card">{list_}{foot("Hiển thị 1–4 trên 4 Saga")}</div><div>{detail}{recon}</div></div>"""
    return shell("21", "Nhật ký Saga và đối soát bù trừ", "Quy trình › Giám sát quy trình › Bù trừ", body, "gs", 2)


PAGES = {"01": ui01, "04": ui04, "11": ui11, "12": ui12, "15": ui15, "18": ui18, "19": ui19, "21": ui21}
if __name__ == "__main__":
    for k, f in PAGES.items():
        (OUT / f"ui-11-{k}.html").write_text(f(), encoding="utf-8")
    print("đã sinh", ", ".join(PAGES))
