"""Bộ dựng chung cho bản hi-fi PH-20 (D03-06-PH20): khung dh-console cho vai trò nền tảng và quản trị tỉnh, thành phần và biểu đồ SVG.
Dữ liệu là giả định: tenant T68 (Tỉnh Lâm Viên, giả định), T01 (Tỉnh Mẫu A), T90 (tenant kiểm thử); mọi tên người, mã, số đều là dữ liệu giả."""
import math

PLAT_NAV = [("|Nền tảng", None), ("Tổng quan nền tảng", "tq"), ("Tenant", "tn"), ("Sáp nhập", "sn"), ("Phát hành", "ph"), ("Sử dụng tài nguyên", "sd"), ("Mẫu khởi tạo", "mk"),
            ("|Giám sát", None), ("Bảng giám sát", "x1"), ("Nhật ký kiểm toán", "x2"), ("|Vận hành", None), ("Tham số hệ thống", "x3"), ("Việc của tôi", "vc")]
PROV_NAV = [("|Tổng quan", None), ("Bảng điều khiển", "x0"), ("|Kết nối & API", None), ("Hệ thống thành viên", "x1"), ("Danh mục API", "x2"),
            ("|Giám sát & kiểm toán", None), ("Bảng giám sát", "x3"), ("Nhật ký kiểm toán", "x4"),
            ("|Quản trị", None), ("Người dùng", "x5"), ("Nhóm & vai trò", "x6"), ("Tổ chức", "to"), ("Cài đặt tỉnh", "cd"), ("Việc của tôi", "vc")]
BADGE = {"vc": "<span class='tag t-info'>3</span>", "sn": "", "ph": ""}


def vn(x, nd=1):
    return f"{x:,.{nd}f}".replace(",", "§").replace(".", ",").replace("§", ".")


def shell(code, title, crumb, body, extra="", mode="P", active="tn", tenant=None, top=""):
    """mode P = nền tảng (tenant PLATFORM), T = quản trị tỉnh. top = dải cảnh báo đặt trên thanh trên."""
    nav_src = PLAT_NAV if mode == "P" else PROV_NAV
    nav = ""
    for n, c in nav_src:
        if n.startswith("|"):
            nav += f'<div class="grp">{n[1:]}</div>'
            continue
        nav += f'<a class="{"on" if c == active else ""}" href="#">{n} {BADGE.get(c, "")}</a>'
    who = "PLATFORM · Nền tảng Datahub" if mode == "P" else (tenant or "T68 · Tỉnh Lâm Viên (giả định)")
    av = "NA" if mode == "P" else "LT"
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-20-{code} · {title}</title><link rel="stylesheet" href="hifi.css"></head><body>
{top}<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Quản trị</div><div class="search">Tìm tenant, tổ chức, phiên bản…  ⌘K</div><div class="sp"></div>
<span class="tray">⟳ 2 tác vụ nền</span><span class="tray">{who} ▾</span><div class="avatar">{av}</div></header>
<nav class="side" aria-label="Điều hướng chính">{nav}</nav>
<main><div class="crumb">{crumb}</div>{body}</main></div>{extra}<div class="hint">Bản hi-fi minh họa · D03-06-PH20 · UI-20-{code} · dữ liệu giả định</div></body></html>"""


def table(head, data, label="", cls=None, num=()):
    th = "".join(f'<th{" class=num" if i in num else ""}>{h}</th>' for i, h in enumerate(head))
    tr = ""
    for i, r in enumerate(data):
        c = f' class="{cls[i]}"' if cls and cls[i] else ""
        tr += f"<tr{c}>" + "".join(f'<td{" class=num" if j in num else ""}>{x}</td>' for j, x in enumerate(r)) + "</tr>"
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


def banner(kind, text, action=""):
    ico = "✕" if kind == "e" else "⚠"
    a = f'<span class="sp"></span>{btn(action)}' if action else ""
    return f'<div class="banner {kind}" role="alert"><span>{ico}</span><span>{text}</span>{a}</div>'


def alert(kind, text, action=""):
    a = f'<span class="sp"></span>{btn(action)}' if action else ""
    return f'<div class="alert {kind}"><span>{text}</span>{a}</div>'


def state(kind, text):
    return f'<span class="tag t-{kind}">{text}</span>'


def sw(on=True):
    return f'<span class="sw {"" if on else "off"}"></span>'


def chk(on=False):
    return f'<span class="chk {"on" if on else ""}"></span>'


# ------------------------------------------------------------------ biểu đồ SVG kiểu ECharts
def smooth(points):
    """Đường cong Catmull-Rom sang Bézier, giống đường smooth của ECharts."""
    if len(points) < 3:
        return "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in points)
    d = f"M{points[0][0]:.1f},{points[0][1]:.1f}"
    for i in range(len(points) - 1):
        p0 = points[i - 1] if i > 0 else points[i]
        p1, p2 = points[i], points[i + 1]
        p3 = points[i + 2] if i + 2 < len(points) else p2
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += f" C{c1[0]:.1f},{c1[1]:.1f} {c2[0]:.1f},{c2[1]:.1f} {p2[0]:.1f},{p2[1]:.1f}"
    return d


def echart_line(series, xlabels, w=700, h=230, ymin=50, ymax=100, marks=(), area=False, yfmt="{:.0f}", ylabel="", tip=None):
    """series: [(tên, [giá trị], màu, nét đứt?)]; marks: [(giá trị, nhãn, màu)]."""
    L, R, T, B = 40, 14, 14, 30
    pw, ph = w - L - R, h - T - B
    def X(i, n):
        return L + pw * i / (n - 1)
    def Y(v):
        return T + ph * (1 - (v - ymin) / (ymax - ymin))
    out = f'<svg viewBox="0 0 {w} {h}" width="100%" role="img" aria-label="Biểu đồ xu hướng" style="display:block">'
    step = (ymax - ymin) / 5
    for k in range(6):
        v = ymin + step * k
        y = Y(v)
        out += f'<line x1="{L}" y1="{y:.1f}" x2="{w - R}" y2="{y:.1f}" stroke="#e4e7ec" {"" if k == 0 else "stroke-dasharray=%r" % "3 3"}/><text x="{L - 6}" y="{y + 4:.1f}" font-size="11" text-anchor="end" fill="#6a717c">{yfmt.format(v)}</text>'
    n = len(xlabels)
    for i, lb in enumerate(xlabels):
        out += f'<text x="{X(i, n):.1f}" y="{h - 10}" font-size="11" text-anchor="middle" fill="#6a717c">{lb}</text>'
    for val, lb, col in marks:
        y = Y(val)
        out += f'<line x1="{L}" y1="{y:.1f}" x2="{w - R}" y2="{y:.1f}" stroke="{col}" stroke-dasharray="6 4" stroke-width="1.3"/><text x="{w - R - 2}" y="{y - 4:.1f}" font-size="11" text-anchor="end" fill="{col}">{lb}</text>'
    for si, (nm, vals, col, dash) in enumerate(series):
        pts = [(X(i, n), Y(v)) for i, v in enumerate(vals) if v is not None]
        d = smooth(pts)
        if area and si == 0:
            out += f'<defs><linearGradient id="g{si}{abs(hash(nm)) % 997}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{col}" stop-opacity=".22"/><stop offset="1" stop-color="{col}" stop-opacity="0"/></linearGradient></defs>'
            out += f'<path d="{d} L{pts[-1][0]:.1f},{Y(ymin):.1f} L{pts[0][0]:.1f},{Y(ymin):.1f} Z" fill="url(#g{si}{abs(hash(nm)) % 997})"/>'
        out += f'<path d="{d}" fill="none" stroke="{col}" stroke-width="2.2" {"stroke-dasharray=%r" % dash if dash else ""} stroke-linecap="round"/>'
        for (x, y) in pts[-1:]:
            out += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="4" fill="#fff" stroke="{col}" stroke-width="2.2"/>'
    if tip:
        tx, ty, html = tip
        out += f'<line x1="{tx}" y1="{T}" x2="{tx}" y2="{T + ph}" stroke="#9aa3b0" stroke-dasharray="3 3"/>'
    return out + "</svg>"


def legend(items):
    return '<div class="legend">' + "".join(f'<span><i style="background:{c}"></i>{n}</span>' for n, c in items) + "</div>"


def hbars(rows, maxv=None, color="#0b5cd5", w="150px 1fr 56px"):
    maxv = maxv or max(v for _, v, *_ in rows)
    out = ""
    for r in rows:
        nm, v = r[0], r[1]
        col = r[2] if len(r) > 2 else color
        out += f'<div class="hbar" style="grid-template-columns:{w}"><span>{nm}</span><span><i style="width:{100 * v / maxv:.0f}%;background:{col}"></i></span><b class="num">{vn(v, 0)}</b></div>'
    return out


def spark(vals, w=80, h=22, col="#0b5cd5"):
    lo, hi = min(vals), max(vals)
    hi = hi if hi > lo else lo + 1
    pts = " ".join(f"{i * w / (len(vals) - 1):.1f},{h - 3 - (v - lo) / (hi - lo) * (h - 6):.1f}" for i, v in enumerate(vals))
    return f'<svg viewBox="0 0 {w} {h}" width="{w}" height="{h}" class="mini" aria-hidden="true"><polyline points="{pts}" fill="none" stroke="{col}" stroke-width="1.8"/></svg>'


def histo(vals, w=90, h=26, col="#9db9e8"):
    mx = max(vals)
    bw = w / len(vals)
    return f'<svg viewBox="0 0 {w} {h}" width="{w}" height="{h}" class="mini" aria-hidden="true">' + "".join(
        f'<rect x="{i * bw + 1:.1f}" y="{h - v / mx * (h - 2):.1f}" width="{bw - 2:.1f}" height="{v / mx * (h - 2):.1f}" fill="{col}"/>' for i, v in enumerate(vals)) + "</svg>"


def ring(v, size=110, col=None):
    col = col or ("#0b7a52" if v >= 80 else ("#c98a00" if v >= 70 else "#c0392b"))
    r = size / 2 - 9
    c = 2 * math.pi * r
    return (f'<svg viewBox="0 0 {size} {size}" width="{size}" height="{size}" class="mini" role="img" aria-label="Điểm {vn(v)} trên 100">'
            f'<circle cx="{size / 2}" cy="{size / 2}" r="{r}" fill="none" stroke="#eef0f3" stroke-width="10"/>'
            f'<circle cx="{size / 2}" cy="{size / 2}" r="{r}" fill="none" stroke="{col}" stroke-width="10" stroke-linecap="round" stroke-dasharray="{c * v / 100:.1f} {c:.1f}" transform="rotate(-90 {size / 2} {size / 2})"/>'
            f'<text x="50%" y="52%" text-anchor="middle" font-size="{size * 0.27:.0f}" font-weight="700" fill="#1a1d23">{vn(v)}</text>'
            f'<text x="50%" y="{size * 0.72:.0f}" text-anchor="middle" font-size="11" fill="#6a717c">/ 100</text></svg>')


MONTHS_OLD = ["10/25", "11/25", "12/25", "01/26", "02/26", "03/26", "04/26", "05/26", "06/26", "07/26", "08/26", "09/26", "10/26"]
