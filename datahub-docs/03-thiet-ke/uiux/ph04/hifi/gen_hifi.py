#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh minh họa của PH-04 cho cả 21 màn (UI-04-01…21).
Dùng token Liquid Glass đề xuất của ../../ph07/hifi/hifi.css, cộng phần CSS riêng của trình thiết kế ở biến DZ_CSS.
Chạy: python3 gen_hifi.py && node shot.js
Dữ liệu trên ảnh là dữ liệu minh họa của tenant mẫu T68, không phải dữ liệu thật của tỉnh nào."""
import pathlib

OUT = pathlib.Path(__file__).parent

NAV = [("Luồng tích hợp", "01"), ("Duyệt luồng", "14"), ("Danh mục thành phần", "17"),
       ("Khuôn mẫu luồng", "19"), ("Không gian làm việc", "21"), ("Kết nối nguồn", None), ("Tham số PH-04", "20")]
ACTIVE = {"01": "01", "02": "01", "03": "01", "12": "01", "15": "01", "16": "01", "18": "01",
          "14": "14", "17": "17", "19": "19", "20": "20", "21": "21"}

# Màu nhóm thành phần (mục 5.2), chỉ dùng cho bản hi-fi
G = {"vao": "#2563eb", "dinh-tuyen": "#7146c7", "chuyen-doi": "#0b7a52", "csdl": "#a8320f", "mang": "#0e7490",
     "hang-doi": "#b45309", "lich": "#be185d", "bao-mat": "#4d7c0f", "chuan": "#0b5cd5", "khac": "#6b7280"}

DZ_CSS = """
.dz{position:fixed;inset:0;display:grid;grid-template-rows:48px 36px minmax(0,1fr) 210px;grid-template-columns:280px minmax(0,1fr) 360px;background:#fff;font-size:13px}
.tb{grid-column:1/4;display:flex;align-items:center;gap:5px;padding:0 10px;border-bottom:1px solid var(--TKN-color-border);background:#fff;white-space:nowrap}
.tb .sep{width:1px;height:22px;background:var(--TKN-color-border)}.tb .ic{padding:3px 5px;border-radius:6px;color:#2b3240}
.tb .seg{display:inline-flex;border:1px solid var(--TKN-color-border);border-radius:8px;overflow:hidden}.tb .seg span{padding:4px 8px;font-size:12.5px}.tb .seg .on{background:var(--TKN-color-primary-weak);color:var(--TKN-color-primary);font-weight:600}
.tb .sbtn{height:28px;font-size:13px;padding:0 10px}
.er{grid-column:1/4;display:flex;align-items:center;gap:6px;padding:0 10px;border-bottom:1px solid var(--TKN-color-border);background:#fafbfc;white-space:nowrap}
.er .et{padding:4px 10px;border-radius:7px;border:1px solid var(--TKN-color-border);background:#fff;font-size:12.5px}.er .et.on{border-color:var(--TKN-color-primary);color:var(--TKN-color-primary);font-weight:600;background:var(--TKN-color-primary-weak)}
.pal{position:relative;border-right:1px solid var(--TKN-color-border);padding:10px;overflow:hidden;background:#fff}
.pal .input{width:100%;margin-bottom:8px}.pal .g{display:flex;justify-content:space-between;padding:3px 6px;font-weight:600;color:#2b3240}.pal .g span{color:var(--TKN-color-text-2);font-weight:400}
.pal .it{display:flex;align-items:center;gap:8px;height:26px;padding:0 6px 0 4px;border-radius:6px;position:relative}.pal .it i{width:4px;height:20px;border-radius:2px}.pal .it .s{color:var(--TKN-color-text-2);font-size:11.5px;margin-left:auto}
.pal .it.hv{background:#eef1f5;outline:2px solid #5b8def;outline-offset:-2px}.pal .ft{position:absolute;bottom:8px;left:10px;background:#fff;width:258px;border-top:1px solid var(--TKN-color-border);padding-top:6px;font-size:11.5px;color:var(--TKN-color-text-2)}
.cv{position:relative;overflow:hidden;background:#f3f5f8;background-image:radial-gradient(#cfd5de 1px,transparent 1px);background-size:16px 16px}
.cv svg.ed{position:absolute;inset:0;width:100%;height:100%;pointer-events:none}
.nd{position:absolute;width:220px;height:56px;background:#fff;border:1px solid #d3d8e0;border-radius:10px;box-shadow:0 1px 3px rgba(20,30,50,.08);padding:7px 10px 6px 16px;overflow:hidden}
.nd::before{content:"";position:absolute;left:0;top:0;bottom:0;width:4px;background:var(--g)}
.nd .t{font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;padding-right:44px}.nd .s{font-size:11.5px;color:var(--TKN-color-text-2);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin-top:3px}
.nd .ico{display:inline-grid;place-items:center;width:18px;height:18px;border-radius:4px;background:var(--g);color:#fff;font-size:11px;margin-right:6px;vertical-align:-3px}
.nd .bd{position:absolute;top:6px;right:8px;font-size:11px;padding:0 6px;border-radius:8px;font-weight:600}
.bd.e{background:#fde8e8;color:#a11a1a}.bd.w{background:#fff4d6;color:#7a5200}.bd.ok{background:#e5f6ec;color:#0b6b3a}.bd.k{background:#eef1f5;color:#545b66}
.nd.sel{border:2px solid #0b5cd5;background:#eef4ff}.nd.err{box-shadow:inset 0 0 0 2px #c62828}.nd.wrn{border:2px solid #d08a00}.nd.dim{opacity:.45}.nd.std{border-color:#7da4ea}
.nd.run-ok::before{background:#0b6b3a}.nd.run-err{border:2px solid #c62828;background:#fdf1f1}
.grpn{position:absolute;border:1px solid #b9c2cf;border-radius:12px;background:rgba(255,255,255,.55)}.grpn .h{padding:6px 10px;font-weight:600;font-size:12.5px;border-bottom:1px solid #dde1e7;background:#f7f8fa;border-radius:12px 12px 0 0}
.grpn .ln{position:absolute;font-size:11.5px;color:#4b5563;background:#fff;border:1px solid #dde1e7;border-radius:8px;padding:1px 7px}
.plus{position:absolute;width:20px;height:20px;border-radius:50%;background:#fff;border:1px solid #9aa3b0;display:grid;place-items:center;font-size:13px;color:#4b5563}
.ov{position:absolute;background:rgba(255,255,255,.78);backdrop-filter:blur(16px) saturate(1.5);border:1px solid rgba(255,255,255,.9);box-shadow:0 6px 24px rgba(20,40,80,.14);border-radius:10px;padding:6px 10px;font-size:12.5px}
.sticky{position:absolute;background:#fff4d6;border:1px solid #f0dc9c;border-radius:8px;padding:8px 10px;font-size:12px;width:200px;box-shadow:0 1px 3px rgba(0,0,0,.06)}
.ins{border-left:1px solid var(--TKN-color-border);padding:10px 14px;overflow:hidden;background:#fff}
.ins h4{margin:0;font-size:15px}.ins .sub{color:var(--TKN-color-text-2);font-size:12px;margin:2px 0 8px}
.ins .lb{font-size:12.5px;color:#2b3240;margin:9px 0 3px}.ins .lb code{color:var(--TKN-color-text-2);font-size:11px;margin-left:4px}.ins .input{width:100%;height:28px}
.ins .er1{color:#a11a1a;font-size:12px;margin-top:3px}.ins .tabsm{display:flex;gap:2px;border-bottom:1px solid var(--TKN-color-border);margin:6px 0}.ins .tabsm span{padding:5px 5px;color:var(--TKN-color-text-2);font-size:12px;white-space:nowrap}.ins .tabsm .on{color:var(--TKN-color-primary);border-bottom:2px solid var(--TKN-color-primary);font-weight:600}
.bp{grid-column:1/4;border-top:1px solid var(--TKN-color-border);background:#fff;padding:0 12px;overflow:hidden}
.bp .tabs{margin-bottom:4px}.bp table td{height:30px}
.scrim{position:fixed;inset:0;background:rgba(15,23,42,.38)}
.modal{position:fixed;background:var(--TKN-color-surface-glass-thick);backdrop-filter:blur(30px) saturate(1.4);border:1px solid rgba(255,255,255,.85);border-radius:16px;box-shadow:0 24px 64px rgba(15,30,60,.28);padding:14px 16px;font-size:13px}
.modal .body{background:#fff;border:1px solid var(--TKN-color-border);border-radius:10px}
.col3{display:grid;gap:0}.col3>div{padding:10px 12px;border-right:1px solid var(--TKN-color-border);overflow:hidden}.col3>div:last-child{border-right:0}
.colh{font-size:11.5px;font-weight:700;letter-spacing:.6px;color:var(--TKN-color-text-2);margin-bottom:6px}
.tr div{padding:3px 0;white-space:nowrap}.k{color:#7146c7}.v{color:#0b6b3a}
.chk div{padding:4px 0}.ok{color:#0b6b3a}.bad{color:#a11a1a}.inf{color:#0b5cd5}
.envc{display:flex;gap:10px;margin:10px 0}.envc>div{flex:1;background:#fff;border:1px solid var(--TKN-color-border);border-radius:10px;padding:10px 12px}.envc b{font-size:12px;letter-spacing:.6px;color:var(--TKN-color-text-2)}
.cards{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}.cards .card{padding:12px}
.mini{height:62px;border-radius:8px;background:#f3f5f8;background-image:radial-gradient(#cfd5de 1px,transparent 1px);background-size:10px 10px;margin:8px 0;position:relative;overflow:hidden}
.mini i{position:absolute;top:24px;height:14px;width:26px;border-radius:4px;background:#fff;border:1px solid #b9c2cf}
.rc{border:1px solid var(--TKN-color-border);border-radius:10px;padding:12px;background:#fff}.rc.on{outline:2px solid var(--TKN-color-primary);background:#f4f8ff}
.wf{display:flex;align-items:center;gap:6px}.wf .bar{height:8px;border-radius:4px;background:#5b8def}
.head h1{white-space:nowrap}
.fx{font-family:"JetBrains Mono",Consolas,monospace;font-size:12.5px}
"""


def page(code, title, body):
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-04-{code} · {title}</title><link rel="stylesheet" href="../../ph07/hifi/hifi.css"><style>{DZ_CSS}</style></head><body>
{body}<div class="hint">Bản hi-fi minh họa · D03-06-PH04 · UI-04-{code} · tenant T68</div></body></html>"""


def shell(code, title, crumb, body, extra=""):
    act = ACTIVE.get(code)
    nav = "".join(f'<a class="{"on" if act == c else ""}" href="#">{n}</a>' for n, c in NAV)
    return page(code, title, f"""<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Tích hợp</div><div class="search">Tìm luồng, route, endpoint…  Ctrl+K</div><div class="sp"></div>
<span class="tray">⧗ 1 tác vụ nền</span><span class="tray">🔔 3</span><span class="tray">Tenant T68</span><div class="avatar">VA</div></header>
<nav class="side" aria-label="Điều hướng chính"><div class="grp">Tích hợp</div>{nav}<div class="grp">Cá nhân</div><a href="#">Việc của tôi <span class="tag t-info">4</span></a></nav>
<main><div class="crumb">{crumb}</div>{body}</main></div>{extra}""")


def rows(data):
    return "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in data)


def tag(t, c="t-mute"):
    return f"<span class='tag {c}'>{t}</span>"


DOT = {"ok": "<span style='color:#0b6b3a'>●</span>", "w": "<span style='color:#d08a00'>●</span>",
       "e": "<span style='color:#a11a1a'>●</span>", "n": "<span style='color:#9aa1ab'>—</span>", "p": "<span style='color:#0b5cd5'>◐</span>"}


def node(x, y, title, sub, g, cls="", badge="", ico="◆", w=220):
    return (f'<div class="nd {cls}" style="left:{x}px;top:{y}px;width:{w}px;--g:{G[g]}" role="treeitem" aria-label="{title}">'
            f'<div class="t"><span class="ico">{ico}</span>{title}</div><div class="s">{sub}</div>{badge}</div>')


def edges(paths, hi=()):
    out = ['<svg class="ed" aria-hidden="true"><defs><marker id="a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#7b8494"/></marker>'
           '<marker id="b" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#0b6b3a"/></marker></defs>']
    for i, (x1, y1, x2, y2) in enumerate(paths):
        if abs(x1 - x2) < 2:
            d = f"M{x1},{y1} L{x2},{y2}"
        else:
            my = (y1 + y2) / 2
            d = f"M{x1},{y1} C{x1},{my} {x2},{my} {x2},{y2}"
        st = "#0b6b3a" if i in hi else "#7b8494"
        wd = 2.5 if i in hi else 1.5
        mk = "b" if i in hi else "a"
        dash = ' stroke-dasharray="5 4"' if hi and i not in hi else ""
        out.append(f'<path d="{d}" fill="none" stroke="{st}" stroke-width="{wd}"{dash} marker-end="url(#{mk})"/>')
    return "".join(out) + "</svg>"


# ---------------------------------------------------------------- Trình thiết kế (UI-04-04 và nền của các lớp nổi)
def toolbar(title="Đồng bộ khai sinh sang NDXP", ver="v8", st=tag("Bản nháp"), save="<span class='ok'>✓ Đã lưu 14:02</span>",
            issues="<span class='bad'>✕ 1</span> <span style='color:#7a5200'>⚠ 2</span>", mode=0, extra=""):
    seg = "".join(f'<span class="{"on" if i == mode else ""}">{t}</span>' for i, t in enumerate(["Sơ đồ", "YAML", "Chia đôi"]))
    return f"""<div class="tb" role="toolbar" aria-label="Thanh công cụ trình thiết kế"><span class="ic">‹</span><b style="font-size:14px">{title}</b><span class="mono">{ver}</span>{st}<span class="ic">▾</span>
<span class="sep"></span>{save}<span class="sep"></span><span class="ic">Tệp ▾</span><span class="ic">Sửa ▾</span><span class="ic">Xem ▾</span><span class="sep"></span><span class="ic">↶</span><span class="ic" style="color:#b0b6c0">↷</span>
<span class="seg">{seg}</span><div style="flex:1"></div>{extra}<span class="btn sbtn">{issues}</span><span class="btn sbtn">▶ Chạy thử ▾</span><span class="btn sbtn pri">⇪ Gửi duyệt</span>
<span style="display:inline-flex"><span class="avatar" style="width:26px;height:26px;font-size:11px">VA</span><span class="avatar" style="width:26px;height:26px;font-size:11px;background:#7146c7;margin-left:-6px">TB</span></span><span class="muted" style="font-size:12px">+1 đang mở</span><span class="ic">⛶</span></div>"""


def rail(items=None):
    items = items or [("⇢ route: nhan-khai-sinh <span class='tag t-err' style='padding:0 5px'>✕1</span>", 1), ("⇢ route: goi-ndxp", 0),
                      ("⚙ routeConfiguration", 0), ("⬡ beans 2", 0), ("≡ Thuộc tính tệp", 0)]
    return '<div class="er" role="tablist">' + "".join(f'<span class="et {"on" if o else ""}">{t}</span>' for t, o in items) + '<span class="muted" style="margin-left:6px">＋ Thêm ▾</span></div>'


def palette(hover="Gọi REST"):
    def it(n, s, g, extra=""):
        return f'<div class="it {"hv" if n == hover else ""}"><i style="background:{G[g]}"></i>{n}<span class="s">{s}</span>{extra}</div>'
    return f"""<aside class="pal" aria-label="Bảng thành phần"><span class="input">🔍 Tìm thành phần…  <span class="muted" style="margin-left:auto">Ctrl+P</span></span>
<div style="display:flex;gap:6px;margin-bottom:6px"><span class="input" style="min-width:0;width:196px">Xem theo: Nghiệp vụ ▾</span><span class="input" style="min-width:0;width:56px">☰ ▦</span></div>
<div class="g">★ Dùng nhiều <span>24</span></div>{it("Gọi REST", "http", "mang", " ⓘ ☆")}{it("Ánh xạ dữ liệu", "jq", "chuyen-doi")}{it("Ghi Kafka", "kafka", "hang-doi")}
<div class="g">▸ Điểm vào <span>7</span></div><div class="g">▾ Định tuyến <span>9</span></div>{it("Rẽ nhánh", "choice", "dinh-tuyen")}{it("Lọc", "filter", "dinh-tuyen")}{it("Tách", "split", "dinh-tuyen")}{it("Gộp", "aggregate", "dinh-tuyen")}
<div class="g">▸ Chuyển đổi dữ liệu <span>14</span></div><div class="g">▸ Kết nối CSDL <span>4</span></div><div class="g">▸ Mạng <span>11</span></div><div class="g">▸ Hàng đợi bản tin <span>6</span></div>
<div class="g">▸ Lập lịch <span>3</span></div><div class="g">▸ Bảo mật <span>5</span></div><div class="g">▸ Chặng chuẩn Datahub <span>9</span></div>
<div class="ft">751 thành phần · 612 được phép · catalog 3.33.1 · Camel 4.18.2<br><a href="#">Danh mục thành phần</a> · <a href="#">Đề xuất thành phần mới</a></div></aside>"""


def canvas_main(sel="ht", run=False):
    """Sơ đồ route nhan-khai-sinh: trái là chuỗi chặng chuẩn, phải là nhóm Rẽ nhánh, dưới là Kiểm toán, Trả lời."""
    S = lambda k: " sel" if sel == k else ""
    rb = (lambda t, c="ok": f'<span class="bd {c}">{t}</span>') if run else (lambda t, c="ok": "")
    n = []
    n.append(node(36, 24, "Nhận yêu cầu", "from · platform-http · POST /ho-tich/khai-sinh", "vao", "std" + (" run-ok" if run else "") + S("a"), rb("✓ 2 ms"), "⤓"))
    n.append(node(36, 112, "Kiểm lược đồ", "dh-stage-schema · ho-tich-ks v4", "chuan", "std" + (" run-ok" if run else ""), rb("✓ 5 ms"), "⬡"))
    n.append(node(36, 200, "Phân quyền", "dh-stage-authz · OPA tu-phap", "chuan", "std" + (" run-ok" if run else ""), rb("✓ 8 ms"), "⬡"))
    n.append(node(36, 288, "Ánh xạ sang NDXP", "dh-stage-transform · ks-to-ndxp.dhmap", "chuyen-doi", ("run-ok" if run else "") + S("map"), rb("✓ 11 ms") if run else '<span class="bd k">🔒</span>', "⇄"))
    grp = ('<div class="grpn" style="left:300px;top:24px;width:480px;height:330px"><div class="h">◆ Rẽ nhánh (choice) · 2 nhánh · 3 chặng '
           + ('<span class="bd w" style="position:static;margin-left:6px">⚠1</span>' if not run else '<span class="bd ok" style="position:static;margin-left:6px">→ when 1</span>') + '<span style="float:right;color:#6b7280">⌃</span></div>'
           '<span class="ln" style="left:16px;top:44px">when ${header.loai} == \'KS\'</span><span class="ln" style="left:16px;top:226px">otherwise</span>'
           '<span class="muted" style="position:absolute;left:16px;bottom:8px">＋ Thêm điều kiện</span></div>')
    htcls = ("run-ok" if run else "err") + S("ht")
    n.append(node(320, 92, "Gọi hộ tịch", "to · http · ndxp-ho-tich /api/v1/khai-sinh", "mang", htcls, rb("✓ 40 ms") if run else '<span class="bd e">✕2</span>', "⇢"))
    n.append(node(552, 92, "Đọc CSDL hộ tịch", "to · sql · pg-ho-tich-ro", "csdl", "run-ok" if run else "", rb("✓ 9 ms") if run else "", "⛁", 214))
    n.append(node(320, 254, "Ghi nhật ký", "log · WARN · loại không hỗ trợ", "khac", "dim" if run else "", '<span class="bd k">⊘ Bỏ qua</span>' if run else "", "✎"))
    n.append(node(320, 400, "Kiểm toán", "dh-stage-audit · che soDinhDanh", "chuan", "std" + (" run-ok" if run else ""), rb("✓ 3 ms"), "⬡"))
    n.append(node(560, 400, "Trả lời", "dh-stage-respond · 200 application/json", "chuan", "std" + (" run-ok" if run else ""), rb("✓ 115 ms"), "⬡"))
    e = edges([(146, 80, 146, 112), (146, 168, 146, 200), (146, 256, 146, 288), (256, 316, 300, 190),
               (540, 120, 552, 120), (430, 148, 430, 254), (660, 148, 660, 400), (540, 428, 560, 428)],
              hi=(0, 1, 2, 3, 4, 6, 7) if run else ())
    plus = '' if run else '<div class="plus" style="left:136px;top:86px">＋</div><div class="plus" style="left:420px;top:316px;opacity:.6">＋</div>'
    sticky = '' if run else '<div class="sticky" style="left:36px;top:380px"><b>Ghi chú.</b> NDXP trả 429 khi quá 20 yêu cầu/giây; nhánh cấp lại (KS-CL) làm ở v9.</div>'
    return e + grp + "".join(n) + plus + sticky


def canvas_overlays(minimap=True):
    o = '<div class="ov" style="left:14px;bottom:14px">−  85%  +  ⤢  ⊡  🔒</div>'
    if minimap:
        o += ('<div class="ov" style="right:14px;bottom:14px;width:170px;height:110px;padding:6px"><div style="position:relative;height:96px;background:#eef1f5;border-radius:6px">'
              '<i style="position:absolute;left:10px;top:8px;width:22px;height:60px;background:#c8cfda;border-radius:3px"></i><i style="position:absolute;left:46px;top:8px;width:90px;height:54px;border:1px solid #9aa3b0;border-radius:4px"></i>'
              '<i style="position:absolute;left:60px;top:22px;width:8px;height:8px;background:#c62828;border-radius:50%"></i><i style="position:absolute;left:4px;top:4px;width:150px;height:88px;border:2px solid #0b5cd5;border-radius:4px"></i></div></div>')
    return o


def inspector_ht():
    return """<aside class="ins" aria-label="Inspector"><div style="display:flex;justify-content:space-between"><h4>⇢ Gọi hộ tịch</h4><span class="muted">⤢ Mở rộng · ⋯</span></div>
<div class="sub">to · http · <span class="mono">id: goi-ho-tich</span> ⧉ · <a href="#">Tài liệu ↗</a></div>
<div class="tabsm"><span class="on">Cơ bản</span><span>Nâng cao</span><span>Xử lý lỗi</span><span>Mô tả</span><span>Dữ liệu mẫu</span></div>
<div class="lb">Kết nối * <code>connection</code></div><span class="input cell-err" style="width:100%">ndxp-ho-tich ▾ <span class="muted" style="margin-left:auto">PH-05</span></span>
<div class="er1">✕ ERR-04-013 · Kết nối chưa được cấp cho không gian Tư pháp</div>
<div class="lb">Đường dẫn * <code>path</code></div><span class="input fx">/api/v1/khai-sinh/${header.soDinhDanh} <span style="margin-left:auto">ƒx</span></span>
<div class="lb">Phương thức <code>httpMethod</code></div><span class="input">POST ▾</span>
<div class="lb">Thời gian chờ (ms) <code>connectTimeout</code></div><span class="input" style="border-color:#d08a00">10000 <span class="muted" style="margin-left:auto">mặc định 30000</span></span>
<div class="er1" style="color:#7a5200">⚠ LINT-04-03 · Lớn hơn SLA dịch vụ 5.000 ms</div>
<div class="lb">Tiêu đề gửi kèm <code>headers</code></div><span class="input">dh-tenant = T68 · Accept = application/json</span>
<div class="muted" style="margin-top:8px">Hiện tất cả (38) · ⟲ Khôi phục mặc định</div>
<div style="border-top:1px solid var(--TKN-color-border);margin-top:10px;padding-top:6px" class="muted"><span class="bad">✕ 1 lỗi</span> · <span style="color:#7a5200">⚠ 1 cảnh báo</span> trong chặng này</div></aside>"""


def bottom_issues():
    return """<div class="bp"><div class="tabs" style="margin-bottom:2px"><span class="on">Vấn đề 3</span><span>Kết quả chạy</span><span>Nhật ký</span><span>Lịch sử sửa</span><span style="margin-left:auto">Lọc: Tất cả mức ▾ · ⌄ Thu gọn</span></div>
<table aria-label="Bảng vấn đề"><thead><tr><th style="width:96px">Mức</th><th style="width:120px">Mã</th><th style="width:300px">Vị trí</th><th>Thông điệp</th><th style="width:160px"></th><th style="width:110px">Nguồn</th></tr></thead><tbody>""" + rows([
        ["<span class='bad'>✕ Lỗi</span>", "<span class='mono'>ERR-04-013</span>", "nhan-khai-sinh › Gọi hộ tịch › Kết nối", "Kết nối \"ndxp-ho-tich\" chưa được cấp cho không gian Tư pháp.", "<span class='btn sbtn' style='height:24px'>Chọn kết nối</span>", "Máy chủ · 14:02"],
        ["<span style='color:#7a5200'>⚠ Cảnh báo</span>", "<span class='mono'>LINT-04-03</span>", "nhan-khai-sinh › Gọi hộ tịch › Thời gian chờ", "Thời gian chờ 10.000 ms lớn hơn SLA dịch vụ 5.000 ms.", "<span class='muted'>Đi tới</span>", "Tức thì"],
        ["<span style='color:#7a5200'>⚠ Cảnh báo</span>", "<span class='mono'>LINT-04-01</span>", "nhan-khai-sinh › Rẽ nhánh › otherwise", "Nhánh \"otherwise\" chỉ ghi nhật ký, bản tin sẽ không được trả lời.", "<span class='btn sbtn' style='height:24px'>Thêm trả lời</span>", "Tức thì"],
    ]) + "</tbody></table></div>"


def designer(cv, ins, bp, tb=None, pal=None, rl=None):
    return f"""<div class="dz">{tb or toolbar()}{rl or rail()}{pal if pal is not None else palette()}<section class="cv" aria-label="Canvas route nhan-khai-sinh">{cv}</section>{ins}{bp}</div>"""


DESIGNER_BG = designer(canvas_main() + canvas_overlays(), inspector_ht(), bottom_issues())

P = {}

# ---------------------------------------------------------------- UI-04-01
P["01"] = shell("01", "Danh sách luồng", "Tích hợp › Luồng tích hợp", """
<div class="head"><div><h1>Luồng tích hợp</h1><div class="muted">Thiết kế, chạy thử, phát hành các luồng Camel kết nối hệ thống trong tỉnh.</div></div><div class="sp"></div><span class="btn">⇪ Nhập luồng hệ cũ</span><span class="btn pri">＋ Tạo luồng ▾</span></div>
<div class="stats"><div class="stat on"><b>142</b><span>Tất cả</span></div><div class="stat"><b>18</b><span>Nháp</span></div><div class="stat"><b>4</b><span>Chờ duyệt</span></div><div class="stat"><b>103</b><span>Đang chạy</span></div><div class="stat"><b style="color:#7a5200">6</b><span>Tạm dừng</span></div><div class="stat"><b style="color:#a11a1a">3</b><span>Suy giảm</span></div><div class="stat"><b>8</b><span>Đã gỡ</span></div></div>
<div class="card"><div class="toolbar"><span class="input" style="min-width:300px">🔍 Tìm theo mã, tên, endpoint, mô tả…</span><span class="input">Không gian: Tư pháp ▾</span><span class="input">Loại ▾</span><span class="input">Môi trường ▾</span><span class="input">⚙ Bộ lọc khác 2</span><div style="flex:1"></div><span class="muted">Mật độ · Cột · Xuất</span></div>
<div class="muted" style="margin:-2px 0 8px">Đang lọc: <span class="tag t-info">Nguồn = HTTT Hộ tịch ✕</span> <span class="tag t-info">Vận chuyển = REST ✕</span> · <a href="#">Xóa bộ lọc</a></div>
<table aria-label="Danh sách luồng"><thead><tr><th>☐</th><th>Mã luồng ▲</th><th>Tên luồng</th><th>Loại</th><th>Nguồn → Đích</th><th>Test</th><th>Stg</th><th>Prod</th><th>Phiên bản</th><th>Cập nhật</th><th>⋯</th></tr></thead><tbody>""" + rows([
    ["☐", "<span class='mono'><a href='#'>ho-tich-khai-sinh</a></span>", "Đồng bộ khai sinh sang NDXP", tag("Đối ngoại", "t-info"), "HTTT Hộ tịch → NDXP", DOT["ok"], DOT["ok"], DOT["ok"], "v7 · Đang chạy ✎", "2 giờ trước", "⋯"],
    ["☐", "<span class='mono'><a href='#'>dkkd-tra-cuu</a></span>", "Tra cứu đăng ký kinh doanh", tag("Đối ngoại", "t-info"), "Cổng DVC → ĐKKD", DOT["ok"], DOT["p"], DOT["n"], "v2 · Nháp", "hôm qua", "⋯"],
    ["☐", "<span class='mono'><a href='#'>ho-tich-ket-hon</a></span>", "Đồng bộ đăng ký kết hôn", tag("Đối ngoại", "t-info"), "HTTT Hộ tịch → NDXP", DOT["ok"], DOT["ok"], DOT["w"], "v4 · Suy giảm", "hôm qua", "⋯"],
    ["☐", "<span class='mono'><a href='#'>bhxh-ho-so-sftp</a></span>", "Nhận hồ sơ BHXH qua SFTP", tag("Pipe"), "SFTP BHXH → t68.bhxh.hs.v1", DOT["ok"], DOT["n"], DOT["ok"], "v3 · Đang chạy", "3 ngày trước", "⋯"],
    ["☐", "<span class='mono'><a href='#'>motcua-ho-so-moi</a></span>", "Phát sự kiện hồ sơ một cửa", tag("Nội bộ"), "Một cửa → Kafka", DOT["ok"], DOT["ok"], DOT["ok"], "v11 · Đang chạy", "4 ngày trước", "⋯"],
    ["☐", "<span class='mono'><a href='#'>thue-dat-dong-bo</a></span>", "Đồng bộ nghĩa vụ thuế đất", tag("Đối ngoại", "t-info"), "Đất đai → Thuế", DOT["ok"], DOT["ok"], DOT["e"], "v5 · Tạm dừng", "5 ngày trước", "⋯"],
    ["☐", "<span class='mono'><a href='#'>dh-sftp-csv-source</a></span>", "Đọc CSV từ SFTP (Kamelet)", tag("Kamelet"), "—", DOT["ok"], DOT["n"], DOT["n"], "v1 · Đã duyệt", "1 tuần trước", "⋯"],
    ["☐", "<span class='mono'><a href='#'>vbqppl-cap-nhat</a></span>", "Cập nhật văn bản QPPL quốc gia", tag("Đối ngoại", "t-info"), "NDXP → Cổng TTĐT", DOT["ok"], DOT["ok"], DOT["ok"], "v2 · Đang chạy", "2 tuần trước", "⋯"],
]) + """</tbody></table><div class="foot" style="justify-content:space-between"><span class="muted">Hiển thị 1–20 trong 103 · ● đồng bộ, khỏe · ◐ đang đồng bộ · ● vàng suy giảm · ● đỏ lỗi · — chưa triển khai</span><span class="muted">‹ 1 2 3 4 5 6 › · 20 / trang ▾</span></div></div>""")

# ---------------------------------------------------------------- UI-04-02
ENV = """<div class="envc"><div><b>TEST</b><div style="margin-top:4px"><b style="color:#1a1d23;font-size:14px">v8</b> · <span class="ok">Đồng bộ, khỏe</span></div><div class="muted">10 phút trước · 1/1 bản sao</div></div>
<div><b>STAGING</b><div style="margin-top:4px"><b style="color:#1a1d23;font-size:14px">v7</b> · <span class="ok">Đồng bộ, khỏe</span></div><div class="muted">2 ngày trước · 2/2 bản sao</div></div>
<div style="border-color:#bfe6cf"><b>PROD</b><div style="margin-top:4px"><b style="color:#1a1d23;font-size:14px">v7</b> · <span class="ok">Đồng bộ, khỏe</span> · 3/3 bản sao</div><div class="muted">2 ngày trước · 1.204 bản tin/giờ · lỗi 0,2 %</div></div></div>"""
P["02"] = shell("02", "Chi tiết luồng", "Tích hợp › Luồng tích hợp › Đồng bộ khai sinh sang NDXP", f"""
<div class="card"><div class="head" style="margin-bottom:4px"><h1>🔀 Đồng bộ khai sinh sang NDXP</h1><span class="mono">ho-tich-khai-sinh ⧉</span>{tag("Đang chạy", "t-ok")}{tag("Đối ngoại", "t-info")}<div class="sp"></div>
<span class="btn pri">✎ Mở trình thiết kế</span><span class="btn">▶ Chạy thử</span><span class="btn">⇡ Phát hành ▾</span><span class="btn">⏸ Tạm dừng ▾</span><span class="btn">⋯</span></div>
<div class="muted">Không gian: Tư pháp · Chủ sở hữu: Nguyễn V. A · HTTT Hộ tịch → Nền tảng NDXP · tenant T68</div>{ENV}</div>
<div class="tabs" style="margin-top:12px"><span class="on">Tổng quan</span><span>Sơ đồ</span><span>Route 2</span><span>Điểm kết nối 5</span><span>Thuộc tính</span><span>Mã nguồn</span><span>Phiên bản 8</span><span>Triển khai</span><span>Chạy thử</span><span>Giám sát</span><span>Lịch sử</span></div>
<div class="grid3"><div class="card"><table><tbody>""" + rows([
    ["<b>Mô tả</b>", "Đẩy giấy khai sinh mới đăng ký từ HTTT Hộ tịch của tỉnh sang NDXP; trả mã giấy tờ cho hệ nguồn."],
    ["<b>Vận chuyển</b>", "SYNC (suy từ chặng đầu <span class='mono'>platform-http</span>)"],
    ["<b>HTTT nguồn</b>", "HTTT Hộ tịch tỉnh (HT-TUPHAP)"], ["<b>HTTT đích</b>", "Nền tảng NDXP"],
    ["<b>Nhãn</b>", tag("linh-vuc = tu-phap", "t-info") + " " + tag("muc-do = cao", "t-warn")],
    ["<b>Căn cứ pháp lý</b>", "Nghị định 47/2024/NĐ-CP"], ["<b>Hồ sơ runtime</b>", "core-native"],
    ["<b>Thông tin thêm</b>", "<a href='#'>Tài liệu đặc tả NDXP v3 ↗</a>"],
]) + """</tbody></table></div><div class="card"><div class="colh">PHỤ THUỘC</div><div class="tr">""" + "".join(f"<div>{x}</div>" for x in [
    "⇢ Luồng con <span class='mono'>ho-tich-tra-cuu-cha-me</span>", "⬡ Kamelet <span class='mono'>dh-stage-*</span> (9)", "🔌 Kết nối <span class='mono'>ndxp-ho-tich</span>",
    "🔌 Kết nối <span class='mono'>pg-ho-tich-ro</span> (chỉ đọc)", "📨 Topic <span class='mono'>t68.ho-tich.ks.v1</span>", "📐 Lược đồ <span class='mono'>ho-tich-ks v4</span>",
    "🗂 Bảng mã PH-07 <span class='mono'>gioi-tinh</span>", "🌐 API PH-02 <span class='mono'>tra-cuu-khai-sinh v2</span>"]) + """</div>
<div class="colh" style="margin-top:12px">CHẠY THỬ GẦN NHẤT</div><div>#41 · <span class="ok">Đạt</span> · 184 ms · 14:10</div><div class="muted">Băm a3f9… · v8</div></div></div>""")

# ---------------------------------------------------------------- UI-04-03
def rcard(t, d, on=False, extra=""):
    return f'<div class="rc {"on" if on else ""}"><b>{t}</b><div class="muted" style="margin-top:4px">{d}</div>{extra}</div>'


def tplcard(code, name, use):
    return f'<div class="card"><span class="mono">{code}</span><div style="font-weight:600;margin-top:2px">{name}</div><div class="mini">' + "".join(f'<i style="left:{8 + i * 34}px"></i>' for i in range(9)) + f'</div><div class="muted">{use}</div></div>'


P["03"] = shell("03", "Tạo luồng", "Tích hợp › Luồng tích hợp › Tạo luồng", """
<div class="head"><h1>Tạo luồng tích hợp</h1><div class="sp"></div><span class="btn">✕ Hủy</span></div>
<div class="steps"><div class="on">① Điểm xuất phát</div><div>② Thông tin luồng</div><div>③ Xem lại và tạo</div></div>
<div style="display:grid;grid-template-columns:repeat(5,1fr);gap:10px;margin-bottom:14px" role="radiogroup" aria-label="Điểm xuất phát">""" +
    rcard("▦ Từ khuôn mẫu", "Có sẵn 9 chặng chuẩn", True, "<div class='ok' style='margin-top:6px'>✓ Khuyên dùng</div>") + rcard("⇄ Từ API", "Chọn API trong danh mục dịch vụ PH-02") +
    rcard("◻ Luồng trống", "Chỉ có điểm vào") + rcard("⇪ Nhập YAML", "Từ tệp .camel.yaml tối đa 512 KB") + rcard("⧉ Nhân bản", "Sao chép luồng đã có") + """</div>
<div class="card"><div class="toolbar"><b style="margin-right:8px">Khuôn mẫu</b><span class="input" style="min-width:220px">🔍 Tìm khuôn mẫu…</span>""" +
    "".join(f'<span class="tag {"t-info" if i == 0 else "t-mute"}">{t}</span>' for i, t in enumerate(["Tất cả", "Tra cứu đồng bộ", "Đồng bộ định kỳ", "Nhận sự kiện", "Tệp", "Quốc gia"])) + """</div>
<div class="cards">""" + tplcard("tpl-sync-lookup", "Tra cứu đồng bộ REST", "Dùng 34 lần · Đối ngoại · Nền tảng") + tplcard("tpl-db-poll-to-kafka", "Đọc định kỳ CSDL → Kafka", "Dùng 12 lần · Nội bộ · Nền tảng") +
    tplcard("tpl-sftp-to-kafka", "SFTP định kỳ → Kafka", "Dùng 7 lần · Đối ngoại · Nền tảng") + tplcard("tpl-ndxp-proxy", "Ủy quyền gọi NDXP", "Dùng 21 lần · Đối ngoại · Nền tảng") +
    tplcard("tpl-soap-to-rest", "Chuyển SOAP sang REST", "Dùng 9 lần · Đối ngoại · Nền tảng") + tplcard("t68-tpl-mot-cua", "Hồ sơ một cửa → Kafka", "Dùng 5 lần · Nội bộ · Của tỉnh T68") + """</div>
<div class="foot"><span class="muted" style="margin-right:auto">Đã chọn: tpl-sync-lookup · tham số khuôn nhập ở bước 2</span><span class="btn pri">Tiếp tục →</span></div></div>""")

# ---------------------------------------------------------------- UI-04-04
P["04"] = page("04", "Trình thiết kế luồng", designer(
    canvas_main() + canvas_overlays() + '<div class="ov" style="right:14px;top:12px">🔍 Tìm trong luồng  Ctrl+F</div>', inspector_ht(), bottom_issues()))

# ---------------------------------------------------------------- UI-04-05
P["05"] = page("05", "Cấu hình chặng mở rộng", DESIGNER_BG + """<div class="scrim"></div>
<div class="modal" style="left:180px;top:68px;width:1080px;height:765px" role="dialog" aria-label="Cấu hình chặng Gọi hộ tịch">
<div style="display:flex;align-items:center;gap:10px;margin-bottom:10px"><b style="font-size:16px">⇢ Gọi hộ tịch</b><span class="muted">to · http</span><span class="muted" style="margin-left:24px">‹ Ánh xạ sang NDXP · Đọc CSDL hộ tịch ›</span><div style="flex:1"></div><a href="#">Tài liệu ↗</a><span class="muted">✕ Esc</span></div>
<div class="body col3" style="grid-template-columns:260px 1fr 260px;height:640px">
<div><div class="colh">VÀO</div><span class="input" style="width:100%;margin-bottom:8px">Nguồn: lần chạy #41 ▾</span><div class="tr fx">
<div>▾ headers (12)</div><div>&nbsp;&nbsp;<span class="k">dh-tenant</span> <span class="v">"T68"</span></div><div>&nbsp;&nbsp;<span class="k">loai</span> <span class="v">"KS"</span></div><div>&nbsp;&nbsp;<span class="k">soDinhDanh</span> <span class="v">"0010•••••12"</span></div>
<div>▾ body (JSON)</div><div>&nbsp;&nbsp;<span class="k">citizenId</span> <span class="v">"0010•••••12"</span></div><div>&nbsp;&nbsp;<span class="k">fullName</span> <span class="v">"NGUYỄN VĂN A"</span></div><div>&nbsp;&nbsp;<span class="k">sex</span> <span class="v">"M"</span></div><div>&nbsp;&nbsp;<span class="k">birthDate</span> <span class="v">"2026-11-20"</span></div>
<div>▸ exchange properties (3)</div><div>▸ variables (1)</div></div><div class="muted" style="margin-top:12px">Kéo trường vào ô tham số để chèn <span class="fx">${…}</span></div></div>
<div><div class="colh">THAM SỐ</div><div style="display:flex;gap:8px;margin-bottom:8px"><span class="input" style="flex:1">🔍 Tìm tham số…</span><span class="input">☐ Chỉ trường đã đặt</span></div>
<div class="card" style="padding:10px 12px"><b>Cơ bản</b>
<div class="field" style="margin-top:8px"><label>Kết nối * <span class="mono muted">connection</span></label><span class="input cell-err">ndxp-ho-tich ▾ <span class="muted" style="margin-left:auto">✓ kiểm tra 2 giờ trước</span></span><div class="er1" style="color:#a11a1a;font-size:12px">✕ ERR-04-013 · Kết nối chưa được cấp cho không gian Tư pháp</div></div>
<div class="field"><label>Đường dẫn * <span class="mono muted">path</span></label><span class="input fx">/api/v1/khai-sinh/${header.soDinhDanh} <span style="margin-left:auto">ƒx</span></span></div>
<div class="field"><label>Phương thức <span class="mono muted">httpMethod</span></label><span class="input">POST ▾</span></div></div>
<div class="tr" style="margin-top:8px"><div>▾ Kết nối và thời gian chờ (6 · 2 đã đặt) <span class="bd w" style="position:static">⚠1</span></div>
<div style="padding-left:16px">Thời gian chờ kết nối <span class="mono muted">connectTimeout</span> <span class="input" style="min-width:110px;border-color:#d08a00">10000</span> <span class="muted">mặc định 30000</span></div>
<div style="padding-left:16px">Thời gian chờ đọc <span class="mono muted">soTimeout</span> <span class="input" style="min-width:110px">15000</span></div>
<div>▸ Bảo mật (4)</div><div>▸ Proxy (5)</div><div>▸ Nâng cao (38)</div><div>▸ Xử lý lỗi · kế thừa dh-default-config</div><div>▸ Mô tả</div></div></div>
<div><div class="colh">RA</div><span class="input" style="width:100%;margin-bottom:8px">Nguồn: lần chạy #41 ▾</span><div class="tr fx"><div>▾ headers (14)</div><div>&nbsp;&nbsp;<span class="k">CamelHttpResponseCode</span> <span class="v">200</span></div>
<div>▾ body (JSON)</div><div>&nbsp;&nbsp;<span class="k">maGiayTo</span> <span class="v">"KS-T68-2026-00412"</span></div><div>&nbsp;&nbsp;<span class="k">trangThai</span> <span class="v">"OK"</span></div></div>
<div class="card" style="margin-top:12px;padding:10px"><div class="muted">Lược đồ ra dự kiến</div><span class="mono">ndxp-khai-sinh-resp v3</span><div class="ok" style="margin-top:4px">✓ khớp lần chạy #41</div></div></div></div>
<div class="foot" style="margin-top:10px"><span style="margin-right:auto"><span class="bad">✕ 1 lỗi</span> · <span style="color:#7a5200">⚠ 1 cảnh báo</span> · 2 tham số đã đổi trong phiên này</span><span class="btn">⟲ Hoàn tác phiên</span><span class="btn pri">Xong  Enter</span></div></div>""")

# ---------------------------------------------------------------- UI-04-06
P["06"] = page("06", "Trình soạn biểu thức", DESIGNER_BG.replace(inspector_ht(), """<aside class="ins"><h4>◆ Rẽ nhánh</h4><div class="sub">choice · <span class="mono">id: re-nhanh-loai</span></div>
<div class="tabsm"><span class="on">Cơ bản</span><span>Nâng cao</span><span>Mô tả</span></div><div class="lb">Nhánh 1 · điều kiện *</div><span class="input fx" style="outline:2px solid #0b5cd5">simple ▾ ${header.loai} == 'KS' && … <span style="margin-left:auto">ƒx</span></span>
<div class="lb">Nhánh otherwise</div><span class="input">Có (1 chặng)</span></aside>""") + """
<div class="modal" style="left:452px;top:150px;width:640px;height:440px" role="dialog" aria-label="Trình soạn biểu thức">
<div style="display:flex;gap:8px;align-items:center;margin-bottom:8px"><b>Biểu thức · Điều kiện nhánh 1 của Rẽ nhánh</b><div style="flex:1"></div><span class="muted">⤢  ✕</span></div>
<div style="display:flex;gap:10px;align-items:center;margin-bottom:8px">Ngôn ngữ <span class="input" style="min-width:110px">simple ▾</span><span class="muted">Kiểu kết quả cần: boolean</span></div>
<div class="body fx" style="padding:10px 12px;height:62px;line-height:1.6"><span class="k">${header.loai}</span> == <span class="v">'KS'</span> &amp;&amp; <span class="k">${body[namSinh]}</span> &gt;= 1900<span style="border-left:2px solid #0b5cd5;margin-left:1px"></span></div>
<div class="ok" style="margin:6px 0 10px">✓ Biên dịch được (Camel 4.18 · máy chủ)</div>
<div style="display:grid;grid-template-columns:220px 1fr;gap:10px"><div class="body" style="padding:8px 10px;height:200px"><div class="colh">BIẾN KHẢ DỤNG</div><div class="tr fx"><div>${body}</div><div>${header.*} (12)</div><div>${exchangeProperty.*} (3)</div><div>Tiêu đề chuẩn dh-*</div><div>{{dh.env.*}} (5)</div><div>date:now, random(…)</div></div></div>
<div class="body" style="padding:8px 10px;height:200px"><div class="colh">XEM TRƯỚC</div><div>Bản tin <span class="input" style="min-width:180px">Bản tin mẫu của chặng ▾</span></div><div style="margin-top:8px">Kết quả: <b class="ok">true</b> (boolean) · 0,4 ms</div>
<div style="border-top:1px solid var(--TKN-color-border);margin:10px 0;padding-top:8px">Thử với dữ liệu khác: <span class="input fx" style="min-width:150px">{ "namSinh": 1850 }</span></div><div>Kết quả: <b class="bad">false</b></div></div></div>
<div class="foot" style="margin-top:8px"><span class="btn">Hủy</span><span class="btn pri">Áp dụng  Ctrl+Enter</span></div></div>""")

# ---------------------------------------------------------------- UI-04-07
SRC = ["▾ hoSo {object}", "&nbsp;&nbsp;Aa soDinhDanh <span class='muted'>string</span>", "&nbsp;&nbsp;Aa hoTen <span class='muted'>string</span>", "&nbsp;&nbsp;≡ gioiTinh <span class='muted'>string</span>",
       "&nbsp;&nbsp;📅 ngaySinh <span class='muted'>string</span>", "&nbsp;&nbsp;▾ cha {object}", "&nbsp;&nbsp;&nbsp;&nbsp;Aa ho · Aa ten", "&nbsp;&nbsp;▾ giayTo [array]", "&nbsp;&nbsp;&nbsp;&nbsp;Aa loai · Aa so", "&nbsp;&nbsp;Aa noiDangKy"]
DST = ["▾ request {object}", "&nbsp;&nbsp;Aa citizenId * <span class='ok'>✓</span>", "&nbsp;&nbsp;Aa fullName * <span class='ok'>✓</span>", "&nbsp;&nbsp;≡ sex enum[M,F,O] * <span class='ok'>✓</span>",
       "&nbsp;&nbsp;📅 birthDate * <span class='ok'>✓</span>", "&nbsp;&nbsp;▾ father {object}", "&nbsp;&nbsp;&nbsp;&nbsp;Aa name <span style='color:#7a5200'>⚠</span>", "&nbsp;&nbsp;▾ documents [array]", "&nbsp;&nbsp;&nbsp;&nbsp;≡ type * · Aa number",
       "&nbsp;&nbsp;📅 requestedAt = now() <span class='ok'>✓</span>", "&nbsp;&nbsp;Aa province = $tenant <span class='ok'>✓</span>", "&nbsp;&nbsp;Aa registrationOffice * <span class='ok'>✓</span>"]


def tree(items, top=78):
    return "".join(f'<div style="position:absolute;left:12px;top:{top + i * 30}px;white-space:nowrap">{t}</div>' for i, t in enumerate(items))


def mline(y1, y2, fn=None, c="#0b5cd5"):
    s = f'<path d="M0,{y1} C200,{y1} 380,{y2} 600,{y2}" stroke="{c}" stroke-width="1.8" fill="none" marker-end="url(#m)"/>'
    if fn:
        s += f'<foreignObject x="230" y="{(y1 + y2) / 2 - 12}" width="150" height="24"><div xmlns="http://www.w3.org/1999/xhtml" style="background:#fff;border:1px solid {c};color:{c};border-radius:12px;font-size:11.5px;padding:2px 8px;text-align:center;white-space:nowrap">{fn}</div></foreignObject>'
    return s


Y = lambda i: 58 + 30 * i  # tâm dòng i của cây nguồn, đích trong tọa độ vùng ánh xạ
MAPSVG = ('<svg style="position:absolute;left:0;top:0;width:600px;height:460px" aria-hidden="true"><defs><marker id="m" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#0b5cd5"/></marker></defs>'
          + mline(Y(1), Y(1)) + mline(Y(2), Y(2), "ƒ upper") + mline(Y(3), Y(3), "⇄ PH-07 gioi-tinh", "#0b7a52") + mline(Y(4), Y(4), "ƒ date dd/MM→ISO")
          + mline(Y(5) + 4, Y(6), "ƒ concat") + mline(Y(6), Y(6)) + mline(Y(7), Y(7), "⟳ lặp giayTo", "#7146c7") + mline(Y(8), Y(8), "⇄ PH-07 loai-giay-to", "#0b7a52")
          + mline(Y(9), Y(11), "ƒ trim", "#9aa3b0") + "</svg>")
P["07"] = page("07", "Trình ánh xạ dữ liệu", DESIGNER_BG + """<div class="scrim"></div>
<div class="modal" style="left:28px;top:26px;width:1384px;height:846px" role="dialog" aria-label="Trình ánh xạ dữ liệu">
<div style="display:flex;align-items:center;gap:10px;margin-bottom:8px"><b style="font-size:16px">Ánh xạ dữ liệu · Chuyển hồ sơ khai sinh sang NDXP</b><span class="mono muted">ks-to-ndxp.dhmap.json</span><div style="flex:1"></div>
<span class="seg" style="display:inline-flex;border:1px solid var(--TKN-color-border);border-radius:8px;overflow:hidden;background:#fff"><span style="padding:4px 10px;background:var(--TKN-color-primary-weak);color:var(--TKN-color-primary);font-weight:600">Trực quan</span><span style="padding:4px 10px">JQ</span><span style="padding:4px 10px">Chia đôi</span></span><span class="muted">✕</span></div>
<div style="display:flex;gap:10px;margin-bottom:8px">Nguồn <span class="input" style="min-width:260px">JSON Schema ho-tich-ks v4 ▾</span><div style="flex:1"></div>Đích <span class="input" style="min-width:260px">CDM ndxp-khai-sinh-req v3 ▾</span><span class="btn sbtn">✨ Gợi ý ánh xạ</span></div>
<div class="body col3" style="grid-template-columns:330px 1fr 360px;height:640px">
<div style="position:relative"><div class="colh">NGUỒN · 18 trường</div><span class="input" style="width:100%">🔍 Tìm trường</span>""" + tree(SRC, 70) + """</div>
<div style="position:relative;padding:0"><div class="colh" style="padding:10px 12px 0">ÁNH XẠ · 9 đường · 2 hàm chuyển mã</div><div style="position:absolute;left:0;top:22px;right:0;bottom:0">""" + MAPSVG + """</div>
<div class="muted" style="position:absolute;left:14px;bottom:12px">Kéo trường nguồn thả vào trường đích · bấm đường để thêm hàm · Space đánh dấu, Enter ánh xạ</div></div>
<div style="position:relative"><div class="colh">ĐÍCH · 10 bắt buộc</div><span class="input" style="width:100%">🔍 Tìm trường · ☐ Chỉ chưa ánh xạ</span>""" + tree(DST, 70) + """</div></div>
<div class="foot" style="margin-top:8px;align-items:center"><span>Thử: <span class="input" style="min-width:150px">Lần chạy #41 ▾</span></span><span class="ok" style="white-space:nowrap">✓ Hợp lệ theo ndxp-khai-sinh-req v3</span><span class="bad">✕ 0</span><span style="color:#7a5200;white-space:nowrap">⚠ 1 father.name rỗng</span>
<span class="muted" style="margin-left:auto;white-space:nowrap">10/10 trường bắt buộc đã ánh xạ</span><span class="btn">Xuất ánh xạ</span><span class="btn">Hủy thay đổi</span><span class="btn pri">Lưu ánh xạ</span></div></div>""")

# ---------------------------------------------------------------- UI-04-08
KPAL = palette("dh-sftp-source").replace("Xem theo: Nghiệp vụ", "Xem theo: Kamelet")
P["08"] = page("08", "Trình soạn Kamelet", f"""<div class="dz">{toolbar("Đọc CSV từ SFTP", "v1", tag("Bản nháp"), issues="<span class='ok'>✓ Hợp lệ</span>")}
{rail([("⬡ Đặc tả", 1), ("⇢ Mẫu (template)", 0), ("⧉ Phụ thuộc", 0)])}{KPAL}
<section class="cv" style="background:#fff;padding:16px 20px;overflow:hidden"><div class="colh">ĐẶC TẢ KAMELET</div>
<div style="display:grid;grid-template-columns:1fr 1fr;gap:10px 18px">
<div class="field"><label>Tên (metadata.name) *</label><span class="input mono">t68-sftp-csv-source</span><div class="muted">Hậu tố -source xác định loại</div></div>
<div class="field"><label>Loại</label><span class="input">(•) source  ( ) sink  ( ) action</span></div>
<div class="field"><label>Tiêu đề *</label><span class="input">Đọc tệp CSV từ SFTP</span></div><div class="field"><label>Nhóm hiển thị</label><span class="input">Mạng ▾</span></div>
<div class="field" style="grid-column:1/3"><label>Mô tả *</label><span class="input" style="height:44px">Đọc định kỳ tệp CSV trong thư mục SFTP, mỗi dòng thành một bản tin JSON.</span></div>
<div class="field"><label>Kiểu dữ liệu ra</label><span class="input">application/json · lược đồ bhxh-ho-so v2</span></div><div class="field"><label>Biểu tượng</label><span class="input">Lucide: FileSpreadsheet ▾</span></div></div>
<div class="colh" style="margin-top:6px">THAM SỐ (spec.definition.properties)</div>
<table><thead><tr><th>Tên</th><th>Tiêu đề tiếng Việt</th><th>Kiểu</th><th>Bắt buộc</th><th>Mặc định</th><th>Nhạy cảm</th></tr></thead><tbody>""" + rows([
    ["<span class='mono'>connection</span>", "Kết nối SFTP", "string", "✓", "—", "🔒 Có"], ["<span class='mono'>directory</span>", "Thư mục", "string", "✓", "/out", ""],
    ["<span class='mono'>delimiter</span>", "Ký tự phân cách", "string", "", ";", ""], ["<span class='mono'>pollMinutes</span>", "Chu kỳ (phút)", "integer", "", "5", ""],
    ["<span class='mono'>skipHeader</span>", "Bỏ dòng tiêu đề", "boolean", "", "true", ""]]) + """</tbody></table><div class="muted" style="margin-top:6px">＋ Thêm tham số · tham số Nhạy cảm chỉ nhận tham chiếu kết nối (VR-15)</div></section>
<aside class="ins"><div class="colh">XEM TRƯỚC KHI THẢ VÀO LUỒNG</div><h4>⬡ Đọc tệp CSV từ SFTP</h4><div class="sub">kamelet · t68-sftp-csv-source · <span class="tag t-info">Của tỉnh</span></div>
<div class="lb">Kết nối SFTP *</div><span class="input">Chọn kết nối PH-05 ▾</span><div class="lb">Thư mục *</div><span class="input">/out</span><div class="lb">Ký tự phân cách</div><span class="input">; <span class="muted" style="margin-left:auto">mặc định</span></span>
<div class="lb">Chu kỳ (phút)</div><span class="input">5</span><div class="lb">Bỏ dòng tiêu đề</div><span class="input">Mặc định (true)</span>
<div class="warn" style="margin-top:12px">Dùng chung toàn quốc cần đăng ký Kamelet ở PH-05 (PA, SO duyệt). <a href="#">Đề nghị dùng chung</a></div></aside>
<div class="bp"><div class="tabs"><span class="on">Vấn đề 0</span><span>Kết quả chạy</span><span>Nhật ký</span></div><div class="ok" style="padding:8px 0">✓ Không có vấn đề. Mẫu dùng đủ 5 tham số đã khai báo.</div></div></div>""")

# ---------------------------------------------------------------- UI-04-09
SLOT = lambda x, h, t, s, cls="", b="": f'<div class="nd {cls}" style="left:{x}px;top:140px;width:184px;height:96px;--g:{G["chuan"]}"><div class="colh">{h}</div><div class="t" style="padding-right:18px"><span class="ico">⬡</span>{t}</div><div class="s">{s}</div>{b}</div>'
PIPECV = (edges([(204, 188, 230, 188), (414, 188, 440, 188), (624, 188, 650, 188)])
          + SLOT(20, "NGUỒN", "dh-sftp-source", "bhxh-sftp · /out/ho-so · 5 phút", "sel") + SLOT(230, "BƯỚC 1", "dh-csv-to-json", "phân cách \";\" · bỏ tiêu đề")
          + SLOT(440, "BƯỚC 2", "dh-mask-pii", "che soDinhDanh, soDienThoai") + SLOT(650, "ĐÍCH", "dh-kafka-sink", "t68.bhxh.hs.v1", "", '<span class="bd ok">✓</span>')
          + '<div class="plus" style="left:417px;top:250px">＋</div><div class="muted" style="position:absolute;left:24px;top:110px">Dải Pipe tuyến tính · kéo ô bước để đổi thứ tự · rẽ nhánh bị khóa</div>'
          + '<div class="card" style="position:absolute;left:20px;top:290px;width:814px"><b>Xử lý lỗi (errorHandler)</b>  <span style="margin-left:16px">(•) DLQ tới PH-18</span>  <span style="margin-left:16px">( ) Ghi nhật ký</span>  <span style="margin-left:16px">( ) Không</span>'
          '<div class="muted" style="margin-top:4px">Bản tin lỗi chuyển sang topic DLQ <span class="mono">t68.dlq.bhxh-ho-so-sftp</span>, xử lý lại ở PH-18.</div></div>' + canvas_overlays(False))
PIPE_PAL = ('<aside class="pal" aria-label="Kamelet"><span class="input">🔍 Tìm Kamelet…</span><div class="muted" style="margin:2px 0 8px">Đang hiện Kamelet loại source cho ô Nguồn</div>'
            + '<div class="g">Của tỉnh <span>1</span></div>' + "".join(f'<div class="it {"hv" if n == "dh-sftp-source" else ""}"><i style="background:{G["chuan"]}"></i>{n}<span class="s">{d}</span></div>' for n, d in [
                ("t68-sftp-csv-source", "CSV SFTP"), ]) + '<div class="g">Nền tảng <span>6</span></div>'
            + "".join(f'<div class="it {"hv" if n == "dh-sftp-source" else ""}"><i style="background:{G["chuan"]}"></i>{n}<span class="s">{d}</span></div>' for n, d in [
                ("dh-sftp-source", "SFTP"), ("dh-sql-ro-source", "CSDL chỉ đọc"), ("dh-rest-poll-source", "REST định kỳ"), ("dh-kafka-source", "Kafka"),
                ("dh-timer-source", "Hẹn giờ"), ("dh-cron-source", "Lịch cron")])
            + '<div class="g" style="opacity:.5">⊘ Thành phần Camel thô</div><div class="muted">Pipe chỉ dùng Kamelet. Muốn dùng thành phần khác, tạo luồng loại route.</div>'
            + '<div class="ft">7 Kamelet source được phép · catalog 3.33.1</div></aside>')
P["09"] = page("09", "Trình soạn Pipe", f"""<div class="dz" style="grid-template-columns:280px minmax(0,1fr) 300px">{toolbar("Nhận hồ sơ BHXH qua SFTP", "v3", tag("Bản nháp"), issues="<span class='ok'>✓ Hợp lệ</span>", mode=0)}
{rail([("⇄ pipe: bhxh-ho-so-sftp", 1)])}{PIPE_PAL}<section class="cv">{PIPECV}</section>
<aside class="ins"><h4>⬡ Đọc SFTP định kỳ</h4><div class="sub">kamelet source · dh-sftp-source</div><div class="lb">Kết nối *</div><span class="input">bhxh-sftp ▾ <span class="muted" style="margin-left:auto">PH-05</span></span>
<div class="lb">Thư mục *</div><span class="input">/out/ho-so</span><div class="lb">Mẫu tên tệp</div><span class="input fx">HS_*.csv</span><div class="lb">Chu kỳ</div><span class="input">5 phút ▾</span><div class="lb">Sau khi đọc</div><span class="input">Chuyển sang /out/da-doc ▾</span></aside>
<div class="bp"><div class="tabs"><span>Vấn đề 0</span><span class="on">Kết quả chạy</span><span>Nhật ký</span></div><div>#12 · <span class="ok">Đạt</span> · MOCK · 3 bản tin · 412 ms · Bắt lại 3 bản tin gửi <span class="mono">t68.bhxh.hs.v1</span>, không gửi thật</div></div></div>""")

# ---------------------------------------------------------------- UI-04-10
P["10"] = page("10", "Cấu hình cấp tệp và bean", DESIGNER_BG + """<div class="scrim" style="background:rgba(15,23,42,.18)"></div>
<div class="drawer" style="top:0;width:640px;padding:16px" role="dialog" aria-label="Cấu hình cấp tệp và bean"><div style="display:flex;align-items:center"><b style="font-size:16px">Cấu hình cấp tệp</b><div style="flex:1"></div><span class="muted">✕ Esc</span></div>
<div class="tabs" style="margin-top:8px"><span class="on">beans 2</span><span>routeConfiguration</span><span>Thuộc tính tệp</span><span>Biến môi trường</span></div>
<div class="card"><table><thead><tr><th>Tên bean</th><th>Kiểu (lớp được phép)</th><th>Thuộc tính</th><th>Nơi dùng</th></tr></thead><tbody>""" + rows([
    ["<span class='mono'>ndxpSigner</span>", "<span class='mono'>vn.datahub.runtime.sign.JwsSigner</span>", "alg=ES256, keyRef={{conn:ndxp-ho-tich.signKey}}", "Gọi hộ tịch"],
    ["<span class='mono'>ksAgg</span>", "<span class='mono'>…aggregate.GroupedBodyAggregationStrategy</span>", "—", "—"]]) + """</tbody></table>
<div class="muted" style="margin-top:6px">＋ Thêm bean · Kiểu chỉ chọn từ danh sách lớp được phép của hồ sơ runtime; không nhập tên lớp tự do</div></div>
<div class="colh" style="margin-top:14px">BIẾN MÔI TRƯỜNG DÙNG TRONG LUỒNG</div><div class="card"><table><thead><tr><th>Biến</th><th>TEST</th><th>STAGING</th><th>PROD</th><th></th></tr></thead><tbody>""" + rows([
    ["<span class='mono'>{{dh.env.ndxp-base-path}}</span>", "/test/api", "/stg/api", "/api", "Tìm chỗ dùng"],
    ["<span class='mono'>{{dh.env.ks-max-batch}}</span>", "10", "50", "200", "Tìm chỗ dùng"],
    ["<span class='mono'>{{dh.env.sla-ms}}</span>", "5000", "5000", "<span class='bad'>chưa khai báo ✕</span>", "Tìm chỗ dùng"]]) + """</tbody></table>
<div class="warn" style="margin-top:8px">Biến <span class="mono">sla-ms</span> chưa khai báo cho PROD: lỗi ở mức PUBLISH. Giá trị do quản trị tenant khai ở màn tham số PH-04.</div></div>
<div class="muted" style="margin-top:12px">Không có ô nhập bí mật ở đây; bí mật chỉ qua {{conn:…}} hoặc {{vault:…}} (BR-04-003).</div></div>""")

# ---------------------------------------------------------------- UI-04-11
FLOWRUN = [("✓", "1 Nhận yêu cầu", "2 ms", 2), ("✓", "2 Kiểm lược đồ", "5 ms", 5), ("✓", "3 Phân quyền", "8 ms", 8), ("✓", "4 Ánh xạ sang NDXP", "11 ms", 11),
           ("✓", "5 Rẽ nhánh → when 1", "0 ms", 1), ("✓", "6   Gọi hộ tịch", "40 ms", 40), ("✓", "7   Đọc CSDL hộ tịch", "9 ms", 9), ("⊘", "    Ghi nhật ký (Bỏ qua)", "", 0),
           ("✓", "8 Kiểm toán", "3 ms", 3), ("✓", "9 Trả lời", "115 ms", 115)]
fr = "".join(f'<tr style="{"background:#eef4ff" if "Gọi" in n else ""}"><td class="{"ok" if s == "✓" else "muted"}">{s}</td><td>{n}</td><td style="text-align:right">{t}</td><td style="width:120px"><div class="wf"><div class="bar" style="width:{max(2, w)}px;opacity:{1 if w else 0}"></div></div></td></tr>' for s, n, t, w in FLOWRUN)
RUNTB = toolbar(issues="<span class='ok'>✓ Hợp lệ</span>", save="<span class='ok'>✓ Đã lưu 14:10</span>")
INS_OK = inspector_ht().replace('class="input cell-err"', 'class="input"').replace('<div class="er1">✕ ERR-04-013 · Kết nối chưa được cấp cho không gian Tư pháp</div>', '<div class="er1" style="color:#0b6b3a">✓ Đã cấp cho Tư pháp · có giá trị TEST</div>')
RAIL_OK = rail().replace("<span class='tag t-err' style='padding:0 5px'>✕1</span>", "")
P["11"] = page("11", "Chạy thử", f"""<div class="dz" style="grid-template-rows:48px 36px minmax(0,1fr) 430px">{RUNTB}{RAIL_OK}{palette()}<section class="cv"><div style="position:absolute;left:0;top:44px;width:820px;height:520px;transform:scale(.7);transform-origin:0 0">{canvas_main(sel="ht", run=True)}</div><style>.dz .bp table td{{height:24px;padding:1px 8px}}</style>
<div class="ov" style="left:50%;transform:translateX(-50%);top:10px;white-space:nowrap">Đang xem kết quả lần chạy #42 · <b class="ok">Đạt</b> · 184 ms · <a href="#">Ẩn</a> · <a href="#">Mở chi tiết</a></div>{canvas_overlays(False).replace("85%", "70%")}</section>{INS_OK}
<div class="bp" style="background:var(--TKN-color-surface-glass-thick);padding:10px 14px"><div style="display:flex;align-items:center;gap:10px"><b style="font-size:15px">Kết quả #42</b>{tag("Đạt", "t-ok")}{tag("MOCK")}<span class="muted">184 ms · 14:10:22 · Lê V. C · băm a3f9… <span class="ok">khớp nội dung hiện tại ✓</span></span><div style="flex:1"></div>
<span class="tabs" style="margin:0;border:0"><span>Thiết lập</span><span class="on">Kết quả #42</span><span>Lịch sử</span></span><span class="muted">⤢ trang riêng · ✕</span></div>
<div style="display:grid;grid-template-columns:420px 1fr;gap:12px;margin-top:8px"><div class="card" style="padding:8px 10px"><div class="colh">DÒNG CHẢY · 10 chặng · 1 bỏ qua</div><table><tbody>{fr}</tbody></table></div>
<div class="card" style="padding:8px 12px"><div class="colh">CHI TIẾT CHẶNG · GỌI HỘ TỊCH</div><div class="tabs" style="margin-bottom:6px"><span class="on">Vào</span><span>Ra</span><span>Khác biệt</span><span>Log 3</span></div>
<div class="code" style="height:184px;overflow:hidden;white-space:pre">headers (12)  dh-tenant: "T68" · loai: "KS" · Content-Type: application/json
body (JSON)
{{
  "citizenId": "0010•••••12",   <span style="color:#8fa3b8">// đã che theo BR-04-013</span>
  "fullName": "NGUYỄN VĂN A",
  "sex": "M",
  "birthDate": "2026-11-20",
  "province": "T68",
  "documents": [{{ "type": "GKS", "number": "KS-00412" }}]
}}</div><div class="muted" style="margin-top:6px">Điểm cuối: ndxp-ho-tich · Mô phỏng "ks-ok" · 200 · 40 ms</div></div></div>
<div class="foot" style="margin-top:8px"><span class="muted" style="margin-right:auto">Trả về: HTTP 200 · application/json · 312 B · <a href="#">Xem</a> · traceId 4bf9… <a href="#">↗ PH-13</a></span><span class="btn">Chạy lại F5</span><span class="btn">Lưu thành ca kiểm thử</span><span class="btn">So sánh với lần khác…</span></div></div></div>""")

# ---------------------------------------------------------------- UI-04-12
P["12"] = shell("12", "Nhật ký chạy thử", "Tích hợp › Luồng tích hợp › Đồng bộ khai sinh sang NDXP › Nhật ký chạy thử", """
<div class="head"><h1>Nhật ký chạy thử</h1><span class="mono muted">ho-tich-khai-sinh</span><div class="sp"></div><span class="btn">So sánh 2 lần đã chọn</span><span class="btn pri">▶ Chạy thử</span></div>
<div class="card"><div class="toolbar"><span class="input">Phiên bản: Tất cả ▾</span><span class="input">Kết quả: Tất cả ▾</span><span class="input">Người chạy ▾</span><span class="input">Chế độ ▾</span><span class="input">20/11/2026 – 26/11/2026</span></div>
<table><thead><tr><th>☐</th><th>#</th><th>Thời điểm</th><th>Người chạy</th><th>Phiên bản</th><th>Băm</th><th>Chế độ</th><th>Nguồn bản tin</th><th>Kết quả</th><th>Thời lượng</th><th>Chặng lỗi</th><th></th></tr></thead><tbody>""" + rows([
    ["☑", "42", "26/11/2026 14:10:22", "Lê V. C", "v8", "<span class='mono'>a3f9…</span>", tag("MOCK"), "Bản tin mẫu", tag("Đạt", "t-ok"), "184 ms", "—", tag("Bằng chứng duyệt v8", "t-info")],
    ["☑", "41", "26/11/2026 13:58:04", "Nguyễn V. A", "v8", "<span class='mono'>a3f9…</span>", tag("SANDBOX_LIVE", "t-warn"), "Ca: ks-hop-le", tag("Đạt", "t-ok"), "312 ms", "—", "🔒 Dữ liệu thật"],
    ["☐", "40", "26/11/2026 11:20:47", "Nguyễn V. A", "v8", "<span class='mono'>91c2…</span>", tag("MOCK"), "Nhập tay", tag("Không đạt", "t-err"), "96 ms", "Gọi hộ tịch", ""],
    ["☐", "39", "25/11/2026 16:02:10", "Trần T. B", "v8", "<span class='mono'>77d0…</span>", tag("MOCK"), "Ca: ks-thieu-truong", tag("Quá thời gian", "t-err"), "30 s", "Đọc CSDL hộ tịch", ""],
    ["☐", "38", "25/11/2026 09:44:31", "Trần T. B", "v7", "<span class='mono'>5be1…</span>", tag("MOCK"), "Bản tin mẫu", tag("Đạt", "t-ok"), "171 ms", "—", ""],
    ["☐", "37", "24/11/2026 15:12:55", "Nguyễn V. A", "v7", "<span class='mono'>5be1…</span>", tag("SIMULATED", "t-warn"), "Bản tin mẫu", tag("Mô phỏng", "t-warn"), "—", "—", "Không tính là chạy thử đạt"],
]) + """</tbody></table><div class="foot" style="justify-content:space-between"><span class="muted">Metadata giữ 90 ngày · thân bản tin giữ 7 ngày · lần chạy làm bằng chứng duyệt được giữ lâu hơn</span><span class="muted">‹ 1 2 › · 20 / trang</span></div></div>
<div class="card" style="margin-top:12px"><div class="colh">SO SÁNH #42 VÀ #41</div><table><thead><tr><th>Chặng</th><th>#42 (MOCK)</th><th>#41 (SANDBOX_LIVE)</th><th>Chênh</th></tr></thead><tbody>""" + rows([
    ["Gọi hộ tịch", "40 ms", "168 ms", "<span class='bad'>+128 ms</span>"], ["Trả lời", "115 ms", "121 ms", "+6 ms"]]) + "</tbody></table></div>")

# ---------------------------------------------------------------- UI-04-13
P["13"] = page("13", "Ca kiểm thử", DESIGNER_BG + """<div class="scrim" style="background:rgba(15,23,42,.18)"></div>
<div class="drawer" style="top:0;width:720px;padding:16px" role="dialog" aria-label="Ca kiểm thử"><div style="display:flex;align-items:center"><b style="font-size:16px">Ca kiểm thử · v8</b><span class="muted" style="margin-left:8px">băm a3f9…</span><div style="flex:1"></div><span class="btn sbtn">▶ Chạy tất cả</span><span class="muted" style="margin-left:8px">✕</span></div>
<div class="card" style="margin-top:10px"><table><thead><tr><th>Tên ca</th><th>Route vào</th><th>Khẳng định</th><th>Kết quả trên băm hiện tại</th><th></th></tr></thead><tbody>""" + rows([
    ["<b>ks-hop-le</b>", "nhan-khai-sinh", "4", tag("Đạt", "t-ok"), "▶"], ["ks-thieu-truong", "nhan-khai-sinh", "2", tag("Đạt", "t-ok"), "▶"],
    ["ks-ndxp-503", "nhan-khai-sinh", "3", tag("Chưa chạy"), "▶"]]) + """</tbody></table></div>
<div class="card" style="margin-top:10px"><div class="colh">SOẠN CA · KS-HOP-LE</div><div style="display:grid;grid-template-columns:1fr 1fr;gap:8px 14px">
<div class="field"><label>Tên *</label><span class="input">ks-hop-le</span></div><div class="field"><label>Route vào</label><span class="input">nhan-khai-sinh ▾</span></div>
<div class="field" style="grid-column:1/3"><label>Bản tin vào</label><span class="input fx">{ "soDinhDanh": "001099000012", "hoTen": "Nguyễn Văn A", "loai": "KS" }</span></div></div>
<div class="colh" style="margin-top:4px">KHẲNG ĐỊNH</div><table><thead><tr><th>Loại</th><th>Chặng, điểm cuối</th><th>Giá trị mong đợi</th><th></th></tr></thead><tbody>""" + rows([
    ["<span class='mono'>STATUS</span>", "—", "200", "✕"], ["<span class='mono'>BODY_JQ</span>", "—", "<span class='fx'>.maGiayTo | startswith(\"KS-T68\")</span>", "✕"],
    ["<span class='mono'>STEP_VISITED</span>", "Gọi hộ tịch", "—", "✕"], ["<span class='mono'>DURATION_LT</span>", "—", "500 ms", "✕"]]) + """</tbody></table>
<div class="muted" style="margin-top:6px">＋ Thêm khẳng định · Mỗi ca phải có ít nhất một khẳng định (VR-20)</div></div>
<div class="foot"><span class="muted" style="margin-right:auto">Gửi duyệt cần mọi ca đạt trên đúng băm (BR-04-004)</span><span class="btn">Hủy</span><span class="btn pri">Lưu ca</span></div></div>""")

# ---------------------------------------------------------------- UI-04-14
def mini_canvas(diff=False):
    def n(x, y, t, cls="", lab=""):
        st = {"add": "border:2px solid #0b6b3a;background:#f1fbf5", "chg": "border:2px solid #d08a00;background:#fffaf0", "": ""}[cls]
        return f'<div class="nd" style="left:{x}px;top:{y}px;width:170px;height:44px;--g:{G["mang"]};{st}"><div class="t" style="padding-right:0">{t}</div><div class="s">{lab}</div></div>'
    h = edges([(99, 58, 99, 74), (99, 118, 99, 134), (184, 156, 220, 156), (99, 178, 99, 254)] + ([(184, 166, 220, 216)] if diff else []))
    h += n(14, 14, "Nhận yêu cầu") + n(14, 74, "Kiểm lược đồ") + n(14, 134, "Rẽ nhánh")
    if diff:
        h += n(220, 134, "Gọi hộ tịch", "chg", "~ Sửa · connectTimeout") + n(220, 194, "Ghi nhật ký", "add", "＋ Thêm · nhánh otherwise") + n(14, 254, "Kiểm toán") + '<span class="bd w" style="position:absolute;left:362px;top:128px">💬 2</span>'
    else:
        h += n(220, 134, "Gọi hộ tịch") + n(14, 254, "Kiểm toán")
    return h


P["14"] = shell("14", "Màn duyệt", "Tích hợp › Duyệt luồng › Đồng bộ khai sinh sang NDXP v8", """
<div class="card"><div class="head" style="margin-bottom:4px"><h1>Đồng bộ khai sinh sang NDXP · v8</h1>""" + tag("Chờ duyệt", "t-info") + """<div class="sp"></div><span class="btn">Yêu cầu sửa</span><span class="btn">Duyệt, phát hành sau</span><span class="btn pri" style="opacity:.55" title="Đủ checklist trước khi duyệt">Duyệt và phát hành lên STAGING</span></div>
<div class="muted">Gửi bởi Nguyễn V. A lúc 14:12 · Người đóng góp: Trần T. B · Môi trường đích: STAGING · chờ 1 giờ 18 phút (SLA 24 giờ)</div>
<div style="margin-top:6px">Ghi chú: "Thêm nhánh xử lý giấy khai sinh cấp lại; tăng thời gian chờ NDXP lên 10 giây."</div></div>
<div class="tabs" style="margin-top:12px"><span>Tóm tắt</span><span class="on">So sánh sơ đồ ✓ đã xem</span><span>So sánh YAML</span><span>Bằng chứng</span><span>Bình luận 3</span><span>Checklist 2/4</span></div>
<div style="display:grid;grid-template-columns:1fr 1fr 300px;gap:12px">
<div class="card" style="padding:8px"><div class="colh">v7 · ĐANG CHẠY Ở STAGING</div><div class="cv" style="height:330px;border-radius:8px">""" + mini_canvas() + """</div></div>
<div class="card" style="padding:8px"><div class="colh">v8 · CHỜ DUYỆT · <span class="ok">+1</span> <span style="color:#7a5200">~1</span> −0</div><div class="cv" style="height:330px;border-radius:8px">""" + mini_canvas(True) + """</div></div>
<div class="card"><div class="colh">BẰNG CHỨNG</div><div class="chk"><div class="ok">✓ Kiểm tra mức PUBLISH (STAGING): 0 lỗi</div><div class="ok">✓ Chạy thử #42 đạt, đúng băm a3f9…</div><div class="ok">✓ 3/3 ca kiểm thử đạt</div>
<div class="inf">ⓘ 1 truy cập CSDL trực tiếp (Q359): pg-ho-tich-ro · chỉ đọc · có app.tenant_id</div><div class="inf">ⓘ Kết nối mới: không · Topic mới: không</div></div>
<div class="colh" style="margin-top:10px">CHECKLIST</div><div class="chk"><div>☑ Đã xem toàn bộ khác biệt</div><div>☑ Không có dữ liệu cá nhân đi ra ngoài mục đích</div><div>☐ Xử lý lỗi và DLQ phù hợp</div><div>☐ Đã kiểm tra kết nối và quyền CSDL mới</div></div>
<div class="field" style="margin-top:8px"><label>Ý kiến duyệt *</label><span class="input" style="width:100%;height:40px">Đồng ý thăng cấp lên STAGING…</span></div></div></div>
<div class="card" style="margin-top:12px"><div class="colh">THAM SỐ ĐỔI · GỌI HỘ TỊCH</div><table><thead><tr><th>Tham số</th><th>v7</th><th>v8</th><th>Bình luận</th></tr></thead><tbody>
<tr class="d-chg"><td class="mono">connectTimeout</td><td><del>5000</del></td><td><ins>10000</ins></td><td>Lê V. C: "Vượt SLA 5 giây, cần giải trình." · 1 trả lời</td></tr>
<tr class="d-add"><td class="mono">otherwise › log</td><td>—</td><td><ins>WARN · loại không hỗ trợ</ins></td><td>—</td></tr></tbody></table></div>""")

# ---------------------------------------------------------------- UI-04-15
STEPS = [("ok", "1. Ghi kho cấu hình", "Commit có ký <span class='mono'>a1b2c3d</span> vào <span class='mono'>dh-flows-t68</span> nhánh <span class='mono'>env/staging</span> · flow(ho-tich-khai-sinh): v8 → STAGING"),
         ("ok", "2. Đồng bộ Argo CD", "ApplicationSet <span class='mono'>t68-flows-staging</span> · Synced · 42 giây"),
         ("run", "3. Runtime nạp", "1/2 bản sao đã nạp v8 (băm khớp) · nhịp tim 30 giây"),
         ("wait", "4. SYNCED và sức khỏe", "Chờ bước 3; so tỷ lệ lỗi 5 phút đầu với v7")]
st = "".join(f'<div style="display:flex;gap:10px;margin-bottom:14px"><div style="width:22px;height:22px;border-radius:50%;display:grid;place-items:center;font-size:12px;{ {"ok": "background:#e5f6ec;color:#0b6b3a", "run": "background:#e6efff;color:#0b5cd5", "wait": "background:#f1f3f5;color:#9aa1ab"}[k] }">{ {"ok": "✓", "run": "⟳", "wait": "○"}[k] }</div><div><b>{t}</b><div class="muted">{d}</div></div></div>' for k, t, d in STEPS)
P["15"] = shell("15", "Phát hành, triển khai", "Tích hợp › Luồng tích hợp › Đồng bộ khai sinh sang NDXP", f"""
<div class="card" style="margin-right:470px"><div class="head" style="margin-bottom:4px"><h1>🔀 Đồng bộ khai sinh sang NDXP</h1>{tag("Đang chạy", "t-ok")}</div>{ENV.replace("v7</b> · <span class=\"ok\">Đồng bộ, khỏe</span></div><div class=\"muted\">2 ngày trước · 2/2", "v8</b> · <span class=\"inf\">⟳ Đang đồng bộ</span></div><div class=\"muted\">vừa xong · 1/2")}</div>
<div class="tabs" style="margin:12px 470px 12px 0"><span>Tổng quan</span><span>Phiên bản 8</span><span class="on">Triển khai</span><span>Chạy thử</span><span>Giám sát</span></div>
<div class="card" style="margin-right:470px"><table><thead><tr><th>Môi trường</th><th>Phiên bản</th><th>Trạng thái</th><th>Lệnh</th><th>Thời điểm</th></tr></thead><tbody>""" + rows([
    ["STAGING", "v8", tag("Đang đồng bộ", "t-info"), "Thăng cấp · YC-2026-1142", "26/11 15:02"],
    ["TEST", "v8", tag("Đồng bộ, khỏe", "t-ok"), "Phát hành", "26/11 14:20"],
    ["PROD", "v7", tag("Đồng bộ, khỏe", "t-ok"), "Tạm dừng route goi-ndxp · Đã xác nhận 3/3", "24/11 09:10"],
    ["PROD", "v7", tag("Xác nhận một phần (2/3)", "t-warn"), "Tiếp tục · <a href='#'>Gửi lại lệnh</a>", "24/11 09:40"]]) + f"""</tbody></table></div>
<div class="drawer" style="width:460px" role="dialog" aria-label="Theo dõi triển khai"><div style="display:flex"><b style="font-size:16px">Thăng cấp v8 lên STAGING</b><div style="flex:1"></div><span class="muted">✕</span></div>
<div class="muted" style="margin:4px 0 14px">Bắt đầu 15:02:11 bởi Lê V. C · lý do YC-2026-1142 Bổ sung cấp lại khai sinh</div>
<div class="card">{st}</div><div class="card"><div class="colh">KIỂM TRA TRƯỚC (ĐÃ ĐẠT)</div><div class="chk"><div class="ok">✓ v8 đã duyệt bởi Lê V. C</div><div class="ok">✓ Đang SYNCED, khỏe ở TEST đủ 30 phút</div><div class="ok">✓ Biến môi trường STAGING đủ 14/14 · kết nối 2/2</div><div class="ok">✓ Không trong khoảng đóng băng</div></div></div>
<div class="foot"><span class="btn danger">Quay lui về v7</span><span class="btn">Mở trên PH-13</span><span class="btn pri">Đóng, theo dõi nền</span></div></div>""")

# ---------------------------------------------------------------- UI-04-16
P["16"] = shell("16", "So sánh phiên bản", "Tích hợp › Luồng tích hợp › Đồng bộ khai sinh sang NDXP › So sánh", """
<div class="head"><h1>So sánh phiên bản</h1><div class="sp"></div><span class="btn">⧉ Sao chép liên kết</span><span class="btn">Mở trình thiết kế</span></div>
<div class="card" style="margin-bottom:12px"><div style="display:flex;gap:10px;align-items:center">Từ <span class="input" style="min-width:220px">v7 · đang chạy ở PROD ▾</span>⇄ Đến <span class="input" style="min-width:200px">v8 · Chờ duyệt ▾</span><div style="flex:1"></div>
<span style="display:inline-flex;border:1px solid var(--TKN-color-border);border-radius:8px;overflow:hidden"><span style="padding:5px 12px">Sơ đồ</span><span style="padding:5px 12px;background:var(--TKN-color-primary-weak);color:var(--TKN-color-primary);font-weight:600">YAML</span><span style="padding:5px 12px">Tóm tắt</span></span></div>
<div style="margin-top:8px">""" + tag("+2 chặng", "t-ok") + " " + tag("~3 chặng", "t-warn") + " " + tag("−0") + " " + tag("↕ 1 di chuyển", "t-info") + " " + tag("1 kết nối mới", "t-info") + " " + tag("0 topic mới") + """<span class="muted" style="float:right">‹ Thay đổi trước · 2/6 · Thay đổi sau ›</span></div></div>
<div class="grid3" style="grid-template-columns:1fr 1fr"><div class="card" style="padding:0"><div class="colh" style="padding:8px 12px">v7 · nhan-khai-sinh.camel.yaml</div><div class="code" style="border-radius:0 0 12px 12px;height:470px;white-space:pre">  - choice:
      when:
        - simple: "${header.loai} == 'KS'"
          steps:
            - to:
                id: goi-ho-tich
                uri: http:{{conn:ndxp-ho-tich.host}}/api/v1/khai-sinh
                parameters:
<span style="background:#5c1d1d">-                 connectTimeout: 5000</span>
      otherwise:
        steps:
<span style="background:#5c1d1d">-         - stop: {}</span>
  - kamelet:
      name: dh-stage-audit</div></div>
<div class="card" style="padding:0"><div class="colh" style="padding:8px 12px">v8 · nhan-khai-sinh.camel.yaml · <a href="#">Mở trên sơ đồ</a></div><div class="code" style="border-radius:0 0 12px 12px;height:470px;white-space:pre">  - choice:
      when:
        - simple: "${header.loai} == 'KS'"
          steps:
            - to:
                id: goi-ho-tich
                uri: http:{{conn:ndxp-ho-tich.host}}/api/v1/khai-sinh
                parameters:
<span style="background:#1d4a2c">+                 connectTimeout: 10000</span>
<span style="background:#1d4a2c">+            - to:</span>
<span style="background:#1d4a2c">+                id: doc-csdl-ho-tich</span>
<span style="background:#1d4a2c">+                uri: sql:select … ?dataSource=#pg-ho-tich-ro</span>
      otherwise:
        steps:
<span style="background:#1d4a2c">+         - log: "WARN loại không hỗ trợ ${header.loai}"</span>
  - kamelet:
      name: dh-stage-audit</div></div></div>""")

# ---------------------------------------------------------------- UI-04-17
P["17"] = shell("17", "Danh mục thành phần", "Tích hợp › Danh mục thành phần", """
<div class="head"><h1>Danh mục thành phần</h1><div class="sp"></div><span class="btn">Đề xuất thành phần mới</span><span class="btn">Hồ sơ runtime</span></div>
<div class="grid2" style="grid-template-columns:230px minmax(0,1fr)"><div class="card tree" role="tree" aria-label="Nhóm nghiệp vụ"><div class="muted">Xem theo: Nghiệp vụ ▾</div><div>Tất cả (751)</div><div>▸ Điểm vào (42)</div><div>▸ Định tuyến (38)</div><div>▸ Chuyển đổi dữ liệu (96)</div><div>▸ Kết nối CSDL (27)</div>
<div class="on">▾ Mạng (88)</div><div>&nbsp;&nbsp;HTTP, REST (14)</div><div>&nbsp;&nbsp;Tệp, FTP, SFTP (9)</div><div>&nbsp;&nbsp;SOAP (4)</div><div>▸ Hàng đợi bản tin (31)</div><div>▸ Lập lịch (6)</div><div>▸ Bảo mật (12)</div><div>▸ Chặng chuẩn Datahub (9)</div><div>▸ Kamelet của tỉnh (3)</div><div>▸ Khác (395)</div></div>
<div class="card"><div class="toolbar"><span class="input" style="min-width:240px">🔍 Tìm tên, tiêu đề, mô tả…</span><span class="input">Loại ▾</span><span class="input">Mức hỗ trợ ▾</span><span class="input">Native ▾</span><span class="input">Được phép ở tỉnh ▾</span></div>
<table><thead><tr><th>Tên</th><th>Tiêu đề</th><th>Loại</th><th>Mức hỗ trợ</th><th>Native</th><th>Giấy phép</th><th>Được phép ở tỉnh</th><th>Số luồng dùng</th></tr></thead><tbody>""" + rows([
    ["<span class='mono'>http</span>", "Gọi HTTP", tag("component"), tag("Ổn định", "t-ok"), "✓", "Apache-2.0", tag("Có", "t-ok"), "61"],
    ["<span class='mono'>rest</span>", "REST DSL", tag("component"), tag("Ổn định", "t-ok"), "✓", "Apache-2.0", tag("Có", "t-ok"), "38"],
    ["<span class='mono'>sftp</span>", "SFTP", tag("component"), tag("Ổn định", "t-ok"), "✓", "Apache-2.0", tag("Có", "t-ok"), "9"],
    ["<span class='mono'>cxf</span>", "SOAP (CXF)", tag("component"), tag("Ổn định", "t-ok"), "JVM", "Apache-2.0", tag("Có", "t-ok"), "4"],
    ["<span class='mono'>ftp</span>", "FTP không mã hóa", tag("component"), tag("Ổn định", "t-ok"), "✓", "Apache-2.0", tag("Không", "t-err"), "0"],
    ["<span class='mono'>netty-http</span>", "HTTP qua Netty", tag("component"), tag("Thử nghiệm", "t-warn"), "✓", "Apache-2.0", tag("Không", "t-err"), "0"],
    ["<span class='mono'>soap</span>", "Định dạng SOAP", tag("dataformat"), tag("Ổn định", "t-ok"), "✓", "Apache-2.0", tag("Có", "t-ok"), "6"],
    ["<span class='mono'>dh-rest-poll-source</span>", "Đọc REST định kỳ", tag("Kamelet", "t-info"), tag("Ổn định", "t-ok"), "✓", "Nền tảng", tag("Có", "t-ok"), "12"],
]) + """</tbody></table><div class="foot" style="justify-content:space-between"><span class="ok">Catalog Camel 4.18.2 · @kaoto/camel-catalog 3.33.1 · khớp runtime ✓</span><span class="muted">88 thành phần · 76 được phép</span></div></div></div>""")

# ---------------------------------------------------------------- UI-04-18
P["18"] = shell("18", "Nhập luồng hệ cũ", "Tích hợp › Luồng tích hợp › Nhập luồng hệ cũ", """
<div class="head"><h1>Nhập luồng hệ cũ</h1><div class="sp"></div><span class="btn">✕ Hủy</span></div>
<div class="steps"><div class="done">✓ ① Tải tệp</div><div class="on">② Phân tích</div><div>③ Ánh xạ</div><div>④ Xem trước và tạo</div></div>
<div class="card"><div class="muted" style="margin-bottom:8px">Tệp <span class="mono">bus-export-2026-11.zip</span> · 14 route · phân tích xong 09:12 · không gian đích Tư pháp</div>
<div class="stats"><div class="stat on"><b>14</b><span>Tất cả</span></div><div class="stat"><b class="ok">9</b><span>Tự động hoàn toàn</span></div><div class="stat"><b style="color:#7a5200">4</b><span>Cần chỉnh</span></div><div class="stat"><b class="bad">1</b><span>Không chuyển được</span></div><div class="stat"><b style="color:#a11a1a">3</b><span>Bí mật tìm thấy (không lưu)</span></div></div>
<table><thead><tr><th>☑</th><th>Route</th><th>Tệp</th><th>Trạng thái</th><th>Điểm cần chỉnh</th><th>Mã luồng đề xuất</th></tr></thead><tbody>""" + rows([
    ["☑", "<span class='mono'>hotich-ks-sync</span>", "hotich.xml", tag("Tự động hoàn toàn", "t-ok"), "—", "<span class='mono'>ho-tich-ks-sync</span>"],
    ["☑", "<span class='mono'>hotich-kh-sync</span>", "hotich.xml", tag("Tự động hoàn toàn", "t-ok"), "—", "<span class='mono'>ho-tich-kh-sync</span>"],
    ["☑", "<span class='mono'>dkkd-tra-cuu</span>", "dkkd.xml", tag("Cần chỉnh 2 điểm", "t-warn"), "Bí mật trong URI (dòng 41) · bean tùy biến <span class='mono'>com.vnpt.DkkdMapper</span>", "<span class='mono'>dkkd-tra-cuu-cu</span>"],
    ["☑", "<span class='mono'>motcua-hs-push</span>", "motcua.xml", tag("Cần chỉnh 1 điểm", "t-warn"), "Phụ thuộc pom <span class='mono'>camel-jms 2.25</span>", "<span class='mono'>motcua-hs-push</span>"],
    ["☐", "<span class='mono'>thue-ftp-legacy</span>", "thue.xml", tag("Không chuyển được", "t-err"), "Thành phần <span class='mono'>ftp</span> không được phép ở tỉnh", "—"],
    ["☑", "<span class='mono'>bhxh-sftp-in</span>", "bhxh.xml", tag("Cần chỉnh 1 điểm", "t-warn"), "Mật khẩu SFTP nhúng trong URI · cần chọn kết nối", "<span class='mono'>bhxh-sftp-in</span>"],
]) + """</tbody></table><div class="warn" style="margin-top:10px">Bí mật tìm thấy trong tệp hệ cũ không được lưu. Báo cáo nhập sẽ liệt kê 3 vị trí để đổi mật khẩu ở hệ nguồn.</div>
<div class="foot"><span class="btn">Tải báo cáo</span><span class="btn">‹ Quay lại</span><span class="btn pri">Tiếp tục → Ánh xạ (13 route)</span></div></div>""")

# ---------------------------------------------------------------- UI-04-19
def tcard(code, name, desc, scope, use, kind="ROUTE"):
    return (f'<div class="card"><div style="display:flex;justify-content:space-between"><span class="mono">{code}</span>{tag(scope, "t-info" if scope == "Nền tảng" else "t-local")}</div><div style="font-weight:600;margin-top:4px">{name}</div>'
            f'<div class="mini">' + "".join(f'<i style="left:{8 + i * 38}px"></i>' for i in range(8)) + f'</div><div class="muted">{desc}</div><div class="muted" style="margin-top:6px">{kind} · Dùng {use} lần</div></div>')


P["19"] = shell("19", "Thư viện khuôn mẫu", "Tích hợp › Khuôn mẫu luồng", """
<div class="head"><h1>Khuôn mẫu luồng</h1><div class="sp"></div><span class="btn pri">＋ Khuôn của tỉnh</span></div>
<div class="toolbar" style="margin:0 0 12px;border-radius:10px;border:1px solid var(--TKN-color-border)"><span class="input" style="min-width:240px">🔍 Tìm khuôn…</span>""" +
    "".join(f'<span class="tag {"t-info" if i == 0 else "t-mute"}">{t}</span>' for i, t in enumerate(["Tất cả 11", "Tra cứu đồng bộ", "Đồng bộ định kỳ", "Nhận sự kiện", "Tệp", "Quốc gia"])) + """<span class="input">Loại: ROUTE ▾</span><span class="input">Phạm vi: Tất cả ▾</span></div>
<div class="cards" style="grid-template-columns:repeat(4,1fr)">""" + "".join([
    tcard("tpl-standard-9", "Khung chín chặng chuẩn", "Nhận, kiểm lược đồ, phân quyền, biến đổi, gọi đích, kiểm toán, trả lời…", "Nền tảng", 58),
    tcard("tpl-sync-lookup", "Tra cứu đồng bộ REST", "Gọi một HTTT đích, trả kết quả đồng bộ trong SLA", "Nền tảng", 34),
    tcard("tpl-ndxp-proxy", "Ủy quyền gọi NDXP", "Ký JWS, gọi NDXP, chuẩn hóa lỗi", "Nền tảng", 21),
    tcard("tpl-db-poll-to-kafka", "Đọc định kỳ CSDL → Kafka", "SQL chỉ đọc theo lịch, phát sự kiện", "Nền tảng", 12),
    tcard("tpl-soap-to-rest", "Chuyển SOAP sang REST", "Bọc dịch vụ SOAP cũ thành REST JSON", "Nền tảng", 9),
    tcard("tpl-kafka-to-rest", "Kafka → REST", "Nhận sự kiện, gọi HTTT đích, DLQ khi lỗi", "Nền tảng", 8),
    tcard("tpl-sftp-to-kafka", "SFTP định kỳ → Kafka", "Đọc tệp, tách dòng, phát sự kiện", "Nền tảng", 7, "PIPE"),
    tcard("t68-tpl-mot-cua", "Hồ sơ một cửa → Kafka", "Khuôn của T68 cho hồ sơ một cửa mới", "Của tỉnh", 5)]) + "</div>")

# ---------------------------------------------------------------- UI-04-20
P["20"] = shell("20", "Tham số PH-04", "Quản trị › Tham số › 04 · Tích hợp", """
<div class="head"><h1>Tham số · 04 Tích hợp</h1><div class="sp"></div><span class="btn">Lịch sử thay đổi</span><span class="btn pri">Lưu thay đổi</span></div>
<div class="tabs"><span class="on">Tham số 04.*</span><span>Biến môi trường {{dh.env.*}}</span><span>Khoảng đóng băng</span></div>
<div class="card"><table><thead><tr><th>Tham số</th><th>Kiểu</th><th>Miền</th><th>Mặc định</th><th>Giá trị tỉnh T68</th><th>Người sửa cuối</th></tr></thead><tbody>""" + rows([
    ["<span class='mono'>04.env.stages</span>", "danh sách", "TEST, STAGING, PROD", "TEST,PROD", "<span class='input'>TEST,STAGING,PROD</span>", "Phạm T. D · 12/11/2026"],
    ["<span class='mono'>04.env.soak-minutes</span>", "số", "0…1440", "30", "<span class='input'>30</span>", "—"],
    ["<span class='mono'>04.test.max-concurrent</span>", "số", "1…50", "5", "<span class='input'>8</span>", "Phạm T. D · 03/11/2026"],
    ["<span class='mono'>04.test.retention-days</span>", "số", "7…365", "90", "<span class='input'>90</span>", "—"],
    ["<span class='mono'>04.review.require-test</span>", "boolean", "—", "true", "<span class='input'>Bật</span>", "—"],
    ["<span class='mono'>04.review.sla-hours</span>", "số", "1…168", "24", "<span class='input cell-edit'>12</span>", "đang sửa"],
    ["<span class='mono'>04.review.require-reauth</span>", "boolean", "Luôn true khi đích là PROD", "false", "<span class='input'>Tắt</span>", "—"],
    ["<span class='mono'>04.workspace.enforce</span>", "boolean", "—", "false", "<span class='input'>Bật</span>", "Phạm T. D · 01/10/2026"],
    ["<span class='mono'>04.deploy.rollback-suggest-error-ratio</span>", "số", "1,1…10", "2,0", "<span class='input'>2,0</span>", "—"],
    ["<span class='mono'>04.mapping.require-all-required</span>", "boolean", "—", "false", "<span class='input'>Tắt</span>", "—"],
]) + """</tbody></table><div class="muted" style="margin-top:8px">Thay đổi có hiệu lực ngay; mỗi lần lưu ghi kiểm toán kèm giá trị cũ và mới.</div></div>""")

# ---------------------------------------------------------------- UI-04-21
P["21"] = shell("21", "Không gian làm việc", "Tích hợp › Không gian làm việc › Tư pháp", """
<div class="head"><h1>Không gian làm việc</h1><div class="sp"></div><span class="btn pri">＋ Tạo không gian</span></div>
<div class="warn" style="margin-bottom:12px;background:#e6efff;border-color:#bcd2fb;color:#0b3d8f">ⓘ Giới hạn theo không gian làm việc đang <b>bật</b> (04.workspace.enforce). Khi bật, chỉ thành viên mức EDIT sửa được luồng, mức MAINTAIN duyệt được luồng của không gian; TA, PA không bị giới hạn.</div>
<div class="grid3" style="grid-template-columns:520px minmax(0,1fr)"><div class="card"><table><thead><tr><th>Tên</th><th>Mã</th><th>Đơn vị chủ quản</th><th>Thành viên</th><th>Luồng</th></tr></thead><tbody>""" + rows([
    ["<b>Tư pháp</b>", "<span class='mono'>tu-phap</span>", "Sở Tư pháp T68", "12", "31"], ["Kế hoạch ĐT", "<span class='mono'>ke-hoach-dt</span>", "Sở KH-ĐT T68", "7", "18"],
    ["Tài nguyên MT", "<span class='mono'>tai-nguyen-mt</span>", "Sở TN-MT T68", "9", "22"], ["Một cửa", "<span class='mono'>mot-cua</span>", "Văn phòng UBND T68", "5", "14"],
    ["Y tế", "<span class='mono'>y-te</span>", "Sở Y tế T68", "4", "6"]]) + """</tbody></table></div>
<div class="card"><div class="head" style="margin-bottom:6px"><h1 style="font-size:18px">Tư pháp</h1><span class="mono muted">tu-phap</span><div class="sp"></div><span class="btn">Lưu trữ</span><span class="btn pri">Lưu thành viên</span></div>
<div class="tabs"><span>Thông tin</span><span class="on">Thành viên 12</span><span>Kết nối được cấp 6</span><span>Luồng 31</span></div>
<table><thead><tr><th>Người dùng, nhóm</th><th>Mức</th><th>Hạn hiệu lực</th><th></th></tr></thead><tbody>""" + rows([
    ["Nguyễn V. A", tag("EDIT", "t-info"), "—", "✕"], ["Trần T. B", tag("EDIT", "t-info"), "31/12/2026", "✕"], ["Lê V. C", tag("MAINTAIN", "t-ok"), "—", "✕"],
    ["Nhóm PH-12: <span class='mono'>tu-phap-it</span>", tag("VIEW"), "—", "✕"], ["Phạm T. D (TA)", tag("MAINTAIN", "t-ok"), "—", "✕"]]) + """</tbody></table><div class="muted" style="margin-top:8px">＋ Thêm thành viên · cần ít nhất một MAINTAIN · Ctrl+Enter lưu</div></div></div>""")

for code, html in P.items():
    (OUT / f"ui-04-{code}.html").write_text(html, encoding="utf-8")
print("Đã sinh", len(P), "tệp ui-04-*.html")
