#!/usr/bin/env python3
"""Sinh bản hi-fi tĩnh 18 màn UI-13-01…18 (D03-06-PH13; UI-13-01, 08, 13 cũng dùng ở D02-03-PH13 mục 10.2).

Chạy: python3 gen_hifi.py; chụp ảnh: node shot.js
Dữ liệu là giả định của tỉnh thí điểm T68. Menu theo D03-06-00 §2.3: nhóm "Giám sát và kiểm toán"
có năm mục Bảng giám sát, Cảnh báo, Tra log, Truy vết, Nhật ký kiểm toán. Phong cách Liquid Glass của D03-05:
kính chỉ ở lớp điều hướng và lớp nổi, nội dung dày dùng nền đặc. Trạng thái luôn có nhãn chữ cộng màu.
"""
import pathlib

OUT = pathlib.Path(__file__).parent
NAV = [("|Giám sát và kiểm toán", None), ("Bảng giám sát", "bd"), ("Cảnh báo", "cb"), ("Tra log", "lg"),
       ("Truy vết", "tv"), ("Nhật ký kiểm toán", "kt"), ("|Cá nhân", None), ("Việc của tôi", "vc")]
BADGE = {"cb": "<span class='tag t-err'>3</span>", "vc": "<span class='tag t-info'>2</span>"}
ACTIVE = {"01": "bd", "02": "bd", "03": "bd", "04": "bd", "05": "bd", "06": "bd", "07": "lg", "08": "tv", "09": "lg",
          "10": "cb", "11": "cb", "12": "cb", "13": "kt", "14": "kt", "15": "bd", "16": "kt", "17": "bd", "18": "kt"}


def shell(code, title, crumb, body):
    nav = ""
    for n, c in NAV:
        if n.startswith("|"):
            nav += f'<div class="grp">{n[1:]}</div>'
            continue
        nav += f'<a class="{"on" if ACTIVE[code] == c else ""}" href="#">{n} {BADGE.get(c, "")}</a>'
    return f"""<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=1440">
<title>UI-13-{code} · {title}</title><link rel="stylesheet" href="hifi.css"></head><body>
<div class="shell"><header class="top"><div class="logo"><b>Datahub</b> · Điều hành</div><div class="search">Tìm cảnh báo, trace_id, luật, bản ghi kiểm toán…  ⌘K</div><div class="sp"></div>
<span class="tray">T68 · Tỉnh thí điểm</span><div class="avatar">NA</div></header>
<nav class="side" aria-label="Điều hướng chính">{nav}</nav>
<main><div class="crumb">{crumb}</div>{body}</main></div><div class="hint">Bản hi-fi minh họa · D02-03-PH13 · UI-13-{code} · dữ liệu giả định T68</div></body></html>"""


def tag(kind, text):
    return f"<span class='tag t-{kind}'>{text}</span>"


def kpi(label, val, sub="", cls=""):
    return f'<div class="kpi {cls}"><span>{label}</span><b>{val}</b><small>{sub}</small></div>'


def line(points, color, w=680, h=110, fill=False):
    d = " ".join(("M" if i == 0 else "L") + f"{x},{y}" for i, (x, y) in enumerate(points))
    return f'<path d="{d}" fill="none" stroke="{color}" stroke-width="2"/>'


# ---------------- UI-13-01 ----------------
def ui01():
    cells = [("APISIX", "Tốt", "ok"), ("dh-runtime", "Tốt", "ok"), ("Kafka", "Cảnh báo", "warn"), ("PostgreSQL", "Tốt", "ok"),
             ("Keycloak", "Tốt", "ok"), ("OPA", "Tốt", "ok"), ("OpenBao", "Tốt", "ok"), ("ClickHouse", "Tốt", "ok"),
             ("Mimir", "Tốt", "ok"), ("Loki", "Tốt", "ok"), ("Tempo", "Chưa có dữ liệu", "info"), ("Kho WORM", "Tốt", "ok"),
             ("dh-integration", "Tốt", "ok"), ("dh-data", "Tốt", "ok"), ("dh-platform", "Tốt", "ok"), ("dh-payment", "Lỗi", "err")]
    grid = "".join(
        f'<div style="background:#fff;border:1px solid var(--color-border);border-radius:8px;padding:8px 10px;font-size:12.5px"><b>{n}</b><div style="margin-top:4px">{tag(k, s)}</div></div>'
        for n, s, k in cells)
    traffic = line([(0, 90), (60, 82), (120, 70), (180, 58), (240, 50), (300, 52), (360, 44), (420, 36), (480, 40), (540, 34), (600, 30), (680, 28)], "#0b5cd5")
    err = line([(0, 104), (60, 103), (120, 102), (180, 100), (240, 101), (300, 97), (360, 98), (420, 92), (480, 80), (540, 99), (600, 100), (680, 101)], "#a11a1a")
    lat = (line([(0, 80), (80, 78), (160, 76), (240, 74), (320, 72), (400, 70), (480, 66), (560, 68), (680, 64)], "#0b6b3a")
           + line([(0, 62), (80, 60), (160, 58), (240, 56), (320, 52), (400, 48), (480, 40), (560, 46), (680, 38)], "#7a5200")
           + line([(0, 40), (80, 38), (160, 36), (240, 34), (320, 28), (400, 20), (480, 12), (560, 24), (680, 18)], "#a11a1a")
           + '<line x1="0" y1="74" x2="680" y2="74" stroke="#545b66" stroke-dasharray="4 4"/><text x="560" y="70" font-size="10" fill="#545b66">SLO 50 ms</text>')
    body = f"""
<div class="head"><h1>Bảng giám sát</h1><div class="sp"></div><span class="seg"><span>1 giờ</span><span class="on">24 giờ</span><span>7 ngày</span></span><span class="input">Tự làm mới: 30 giây ▾</span><span class="muted">Cập nhật 14:02:31</span><span class="btn">⟳</span></div>
<div class="kpis" style="--n:5">{kpi("Lượt gọi mỗi giây", "142", "● cao điểm hôm nay 287")}{kpi("Thành công 5 phút", "99,82%", "● đạt SLO 99,9% theo tháng")}{kpi("Độ trễ gateway p95", "41 ms", "● dưới SLO 50 ms")}{kpi("Cảnh báo đang mở", "3", "✕ 1 Nghiêm trọng · ⚠ 2 Cảnh báo", "")}{kpi("Kiểm tra tổng hợp", "12/12", "● mọi API quan trọng đạt")}</div>
<div class="alert e">✕ <b>Nghiêm trọng:</b> dh-payment — tỷ lệ lỗi kết nối nhà cung cấp thanh toán 8,1% trong 5 phút. <span class="mono">payment-provider-connection-error</span> &nbsp; Mở cảnh báo →</div>
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 420px">
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Bản đồ thành phần</h3><div style="display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:8px">{grid}</div>
<div class="legend"><span><i style="background:#0b6b3a"></i>Tốt</span><span><i style="background:#7a5200"></i>Cảnh báo</span><span><i style="background:#a11a1a"></i>Lỗi</span><span><i style="background:#0b5cd5"></i>Chưa có dữ liệu</span></div></div>
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Hệ thống giám sát</h3>
<div class="dl" style="grid-template-columns:1fr auto"><dt>Nhịp tim ngoài site</dt><dd>{tag("ok", "Tốt")}</dd><dt>Mẫu bị bỏ 10 phút qua</dt><dd>0,02% {tag("ok", "Tốt")}</dd><dt>Ruler, Alertmanager</dt><dd>{tag("ok", "Tốt")}</dd><dt>Kho lượt gọi (ClickHouse)</dt><dd>trễ 3 giây {tag("ok", "Tốt")}</dd><dt>Độ trễ sao WORM</dt><dd>4 phút {tag("ok", "Tốt")}</dd><dt>Chuỗi kiểm toán</dt><dd>Neo 14:00 {tag("ok", "Toàn vẹn")}</dd></div></div></div>
<div class="grid3" style="grid-template-columns:1fr 1fr;margin-top:12px">
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Lưu lượng theo lớp trạng thái</h3><svg viewBox="0 0 680 110" style="width:100%;height:130px" role="img" aria-label="Lưu lượng 24 giờ: thành công tăng dần, lỗi 5xx thấp có một đỉnh lúc 10 giờ">{traffic}{err}</svg>
<div class="legend"><span><i style="background:#0b5cd5"></i>2xx</span><span><i style="background:#a11a1a"></i>5xx (đỉnh lúc 10:20)</span></div></div>
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Độ trễ p50, p95, p99</h3><svg viewBox="0 0 680 110" style="width:100%;height:130px" role="img" aria-label="Độ trễ p50 p95 p99 với vạch SLO 50 mili giây">{lat}</svg>
<div class="legend"><span><i style="background:#0b6b3a"></i>p50 22 ms</span><span><i style="background:#7a5200"></i>p95 41 ms</span><span><i style="background:#a11a1a"></i>p99 88 ms</span></div></div></div>
<div class="card" style="margin-top:12px"><h3 style="margin:0 0 8px;font-size:15px">Cảnh báo mới nhất</h3>
<table aria-label="Cảnh báo mới nhất"><thead><tr><th>Mức</th><th>Cảnh báo</th><th>Thành phần</th><th>Bắt đầu</th><th>Trạng thái</th></tr></thead><tbody>
<tr><td>{tag("err", "Nghiêm trọng")}</td><td>Lỗi kết nối nhà cung cấp thanh toán vượt 5%</td><td>dh-payment</td><td>13:57</td><td>{tag("err", "Đang phát")}</td></tr>
<tr><td>{tag("warn", "Cảnh báo")}</td><td>Phân vùng Kafka thiếu bản sao</td><td>Kafka</td><td>13:41</td><td>{tag("info", "Đã tiếp nhận")}</td></tr>
<tr><td>{tag("warn", "Cảnh báo")}</td><td>Chứng thư sắp hết hạn (19 ngày)</td><td>pki-clients</td><td>06:00</td><td>{tag("err", "Đang phát")}</td></tr>
<tr><td>{tag("info", "Thông tin")}</td><td>Dung lượng volume Loki 78%</td><td>Loki</td><td>Hôm qua</td><td>{tag("ok", "Đã xử lý")}</td></tr>
<tr><td>{tag("warn", "Cảnh báo")}</td><td>Độ trễ gateway p95 vượt 50 ms trong 15 phút</td><td>APISIX</td><td>Hôm qua</td><td>{tag("ok", "Đã xử lý")}</td></tr></tbody></table></div>"""
    return shell("01", "Bảng giám sát", "Giám sát và kiểm toán › Bảng giám sát", body)


# ---------------- UI-13-08 ----------------
def ui08():
    spans = [("gateway.receive", "PH-03", 0, 4, "ok", "4 ms"), ("core.validate", "PH-04", 4, 12, "ok", "12 ms"),
             ("iam.authorize", "PH-12", 16, 8, "ok", "8 ms"), ("national.invoke", "PH-14", 27, 1280, "warn", "1.280 ms · 94%"),
             ("privacy.apply", "PH-09", 1330, 9, "ok", "9 ms"), ("audit.record", "PH-13", 1340, 6, "ok", "6 ms")]
    total = 1360.0
    rows = ""
    for name, ph, st, du, k, lab in spans:
        left = st / total * 100
        w = max(du / total * 100, 0.8)
        col = {"ok": "#0b5cd5", "warn": "#7a5200", "err": "#a11a1a"}[k]
        extra = " ⚠" if k == "warn" else ""
        rows += (f'<div style="display:grid;grid-template-columns:190px 70px 1fr 120px;gap:8px;align-items:center;font-size:12.5px;margin:6px 0">'
                 f'<span class="mono">{name}</span><span class="muted">{ph}</span>'
                 f'<div style="position:relative;height:16px;background:#f1f3f6;border-radius:4px"><i style="position:absolute;left:{left:.2f}%;width:{w:.2f}%;top:0;height:16px;border-radius:4px;background:{col}"></i></div>'
                 f'<span class="num">{lab}{extra}</span></div>')
    body = f"""
<div class="head"><h1>Truy vết</h1><div class="sp"></div><span class="muted">Trace giữ 14 ngày, đầy đủ với mọi trace lỗi hoặc chậm</span></div>
<div class="card" style="margin-bottom:12px"><div class="toolbar" style="display:flex;gap:8px;align-items:center"><span class="input" style="flex:1;color:var(--color-text);font-family:'JetBrains Mono',Consolas,monospace">4bf92f3577b34da6a3ce929d0e0e4736</span><span class="btn pri">Tìm trace</span><span class="btn">⧉ Sao chép trace_id</span></div></div>
<div class="kpis" style="--n:5">{kpi("Thời gian tổng", "1.360 ms", "")}{kpi("Trạng thái", "Thành công", "● OK")}{kpi("Số chặng", "9", "")}{kpi("Bên gọi", "cong-dvc", "HTTT thành viên")}{kpi("Thời gian chờ nền tảng quốc gia", "94%", "⚠ chiếm hơn 50% tổng thời gian", "")}</div>
<div class="alert w">⚠ <b>Nhận xét tự động:</b> 94% thời gian là chờ nền tảng quốc gia (PH-14). Độ trễ nội tại của Datahub là 80 ms.</div>
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 360px">
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Biểu đồ thác nước các chặng</h3>{rows}
<div class="legend"><span><i style="background:#0b5cd5"></i>Chặng bình thường</span><span><i style="background:#7a5200"></i>Chặng chiếm quá 50% thời gian</span><span><i style="background:#a11a1a"></i>Chặng lỗi (tự mở rộng)</span></div>
<h3 style="margin:14px 0 6px;font-size:15px">Phân bổ thời gian theo thành phần</h3>
<div class="hbar"><span>PH-14 Kết nối quốc gia</span><div><i style="width:94%;background:#7a5200"></i></div><span class="num">94,1%</span></div>
<div class="hbar"><span>PH-04 Lõi tích hợp</span><div><i style="width:4%"></i></div><span class="num">3,8%</span></div>
<div class="hbar"><span>PH-03 Cổng API</span><div><i style="width:1%"></i></div><span class="num">0,9%</span></div>
<div class="hbar"><span>Khác</span><div><i style="width:1.2%"></i></div><span class="num">1,2%</span></div></div>
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Log của chặng <span class="mono">national.invoke</span></h3>
<div class="code" style="font-size:11.5px;white-space:pre-wrap">14:32:10.147 TT  dh-runtime  Gọi NDXP dich-vu-cong-dan v2
14:32:10.150 TT  dh-runtime  Chờ phản hồi, hết hạn 3.000 ms
14:32:11.427 TT  dh-runtime  NDXP trả 200 sau 1.280 ms
14:32:11.428 TT  dh-runtime  Ánh xạ phản hồi, 4 trường</div>
<div class="grp-t">Liên kết</div>
<div style="display:flex;flex-direction:column;gap:6px"><span class="btn">Log của trace (14 dòng) →</span><span class="btn">Chỉ số liên quan →</span><span class="btn">Bản ghi kiểm toán (1) →</span></div>
<div class="muted" style="margin-top:8px">Nút kiểm toán chỉ hiện với người có quyền xem nhật ký kiểm toán.</div></div></div>"""
    return shell("08", "Truy vết", "Giám sát và kiểm toán › Truy vết › 4bf92f35…4736", body)


# ---------------- UI-13-13 ----------------
def ui13():
    rows = [("14:32:11.462", "cong-dvc (CLIENT)", "PII.REVEAL", "cong-dan · a3f5b8c1d2e4…", "GIAI_QUYET_TTHC", tag("ok", "Thành công")),
            ("14:30:02.118", "nguyen.van.an (USER)", "CATALOG.PUBLISH", "DM_GIOI_TINH", "—", tag("ok", "Thành công")),
            ("14:12:40.905", "tran.thi.binh (USER)", "PAYMENT.REFUND.APPROVE", "GD-2026-118842", "Hoàn tiền theo QĐ", tag("ok", "Thành công")),
            ("13:58:09.331", "htt-dat-dai (CLIENT)", "PII.REVEAL", "ho-so · 71c0e9aa5b13…", "QUAN_LY_DAT_DAI", tag("err", "Từ chối")),
            ("13:41:55.020", "system:dh-platform", "AUDIT.VERIFY", "tenant T68", "—", tag("ok", "Thành công")),
            ("11:06:20.774", "le.minh.cuong (USER)", "FLOW.RELEASE", "luong-dong-bo-dc", "Phát hành bản 1.4", tag("ok", "Thành công")),
            ("09:47:33.610", "pham.thu.ha (USER)", "SESSION.LOGIN", "—", "—", tag("warn", "Thất bại"))]
    trs = "".join(f"<tr><td class='mono'>{a}</td><td>{b}</td><td class='mono'>{c}</td><td>{d}</td><td>{e}</td><td>{f}</td></tr>" for a, b, c, d, e, f in rows)
    body = f"""
<div class="head"><h1>Nhật ký kiểm toán</h1><div class="sp"></div><span class="tag t-info">🔒 Việc tra cứu này sẽ được ghi vết</span></div>
<div class="alert w" style="background:#e6efff;border-color:#bcd2f7;color:#0b3a8c">ⓘ Mọi lượt tra cứu, xem chi tiết và xuất bằng chứng đều được ghi lại cùng lý do của bạn. Định danh công dân hiển thị dạng băm; muốn tra một người cụ thể, dùng "Tra theo đối tượng bị tra cứu".</div>
<div class="card" style="margin-bottom:12px">
<div class="field"><label>Lý do truy vấn (bắt buộc, 10 đến 500 ký tự)</label><span class="input" style="width:100%;color:var(--color-text)">Điều tra khiếu nại số 42/2026 về truy cập dữ liệu công dân</span></div>
<div class="toolbar" style="display:flex;gap:8px;flex-wrap:wrap;align-items:center"><span class="input">Từ: 25/11/2026 00:00</span><span class="input">Đến: 26/11/2026 23:59</span><span class="input">Chủ thể: tất cả ▾</span><span class="input">Hành động: PII.REVEAL, PAYMENT.* ▾</span><span class="input">Kết quả: tất cả ▾</span><span class="btn pri">Tra cứu</span><span class="btn">Tra theo đối tượng bị tra cứu</span></div></div>
<div class="grid3" style="grid-template-columns:minmax(0,1fr) 380px">
<div class="card"><div style="display:flex;align-items:center;gap:10px;margin-bottom:8px"><b>184 bản ghi</b><span class="muted">sắp xếp mới nhất trước</span><div class="sp" style="flex:1"></div>
<span class="tag t-ok" style="font-size:13px">✔ Chuỗi toàn vẹn · kiểm tra 03:00 hôm nay · neo 14:00</span></div>
<table aria-label="Kết quả tra cứu nhật ký kiểm toán"><thead><tr><th>Thời điểm</th><th>Chủ thể</th><th>Hành động</th><th>Đối tượng</th><th>Mục đích, lý do</th><th>Kết quả</th></tr></thead><tbody>{trs}</tbody></table>
<div class="foot" style="justify-content:space-between"><span class="muted">Trang 1 / 4 · 50 dòng mỗi trang</span><span class="btn pri">Xuất bằng chứng…</span></div></div>
<div class="card"><h3 style="margin:0 0 8px;font-size:15px">Chi tiết bản ghi <span class="mono">01J5X8K2…</span></h3>
<div class="dl" style="grid-template-columns:110px 1fr"><dt>seq</dt><dd class="mono">4.820.117</dd><dt>Chủ thể</dt><dd>cong-dvc (CLIENT)</dd><dt>Hành động</dt><dd class="mono">PII.REVEAL</dd><dt>Đối tượng</dt><dd>cong-dan</dd><dt>Khóa tra cứu</dt><dd class="mono">a3f5b8c1d2e4… (băm)</dd><dt>Mục đích</dt><dd>GIAI_QUYET_TTHC</dd><dt>Trace</dt><dd class="mono">4bf92f35…4736 · Mở trace →</dd></div>
<div class="grp-t">Giá trị trước, sau (đã che)</div>
<div class="code" style="font-size:11.5px;white-space:pre-wrap"><del>- soDinhDanh: ************</del>
<ins>+ soDinhDanh: 001******234</ins>
  hoTen: Nguyễn *** An (che một phần)</div>
<div class="grp-t">Chứng minh toàn vẹn</div>
<div class="verify"><div>● Băm bản ghi khớp với nội dung</div><div>● prev_hash khớp bản ghi 4.820.116</div><div>● Neo 14:00 ngày 26/11/2026 chữ ký hợp lệ (khóa phiên bản 2)</div><div>● Có bản trên kho WORM, ngày lô 26/11/2026</div></div>
<div class="foot"><span class="btn">Xác minh lại</span><span class="btn pri">Xuất bằng chứng…</span></div></div></div>"""
    return shell("13", "Nhật ký kiểm toán", "Giám sát và kiểm toán › Nhật ký kiểm toán", body)


from hifi_more import build  # noqa: E402  (UI-13-02…07, 09…12, 14…18)

MORE = build(shell, tag, kpi, line)

SCREENS = {"01": ui01, "08": ui08, "13": ui13, **MORE}
for code, fn in sorted(SCREENS.items()):
    (OUT / f"ui-13-{code}.html").write_text(fn(), encoding="utf-8")
print("ok", len(SCREENS))
