"""Bản hi-fi tĩnh các màn còn lại của PH-13 (UI-13-02…07, 09…12, 14…18), dùng chung hàm của gen_hifi.py.
Dữ liệu là giả định của tỉnh thí điểm T68. Trạng thái luôn có nhãn chữ cộng màu."""


def build(shell, tag, kpi, line):
    def tbl(label, heads, rows):
        th = "".join(f"<th>{h}</th>" for h in heads)
        tr = "".join("<tr>" + "".join(f"<td>{c}</td>" for c in r) + "</tr>" for r in rows)
        return f'<table aria-label="{label}"><thead><tr>{th}</tr></thead><tbody>{tr}</tbody></table>'

    def card(title, inner, style=""):
        return f'<div class="card" style="{style}"><h3 style="margin:0 0 8px;font-size:15px">{title}</h3>{inner}</div>'

    def head(title, right=""):
        return f'<div class="head"><h1>{title}</h1><div class="sp"></div>{right}</div>'

    def tabs(items, on):
        return '<div class="tabs">' + "".join(f'<span class="{"on" if i == on else ""}">{x}</span>' for i, x in enumerate(items)) + "</div>"

    def kp(items, n=None):
        return f'<div class="kpis" style="--n:{n or len(items)}">' + "".join(kpi(*i) for i in items) + "</div>"

    def hb(rows):
        return "".join(f'<div class="hbar"><span>{a}</span><div><i style="width:{w}%"></i></div><span class="num">{v}</span></div>' for a, w, v in rows)

    def chart(pts, color="#0b5cd5", label="Biểu đồ"):
        return f'<svg viewBox="0 0 680 110" style="width:100%;height:120px" role="img" aria-label="{label}">{line(pts, color)}</svg>'

    P = [(0, 80), (80, 70), (160, 74), (240, 55), (320, 60), (400, 40), (480, 48), (560, 30), (680, 34)]
    rng = '<span class="seg"><span>1 giờ</span><span class="on">24 giờ</span><span>7 ngày</span></span>'
    XEM = '<span class="btn">Xem dạng bảng</span>'

    def ui02():
        rows = [("luong-dong-bo-dc", "Chạy thật", "1.204.331", "1.902", "0,16%", "88 ms", tag("ok", "Tốt")),
                ("luong-nop-ho-so", "Chạy thật", "412.880", "8.120", "1,93%", "240 ms", tag("warn", "Cảnh báo")),
                ("luong-tra-cuu-cccd", "Chạy thật", "98.440", "12", "0,01%", "61 ms", tag("ok", "Tốt")),
                ("luong-thanh-toan", "Chạy thật", "35.102", "2.840", "8,09%", "1,4 s", tag("err", "Lỗi"))]
        body = head("Bảng giám sát · Data plane", rng) + tabs(["Đơn vị triển khai", "Luồng", "Endpoint"], 1) + \
            kp([("Luồng đang chạy", "38", "● 35 tốt · 2 cảnh báo · 1 lỗi"), ("Đã xử lý 24 giờ", "1.750.753", "● +4% so với hôm qua"),
                ("Tỷ lệ thất bại", "0,76%", "● dưới ngưỡng 1%"), ("Độ phân giải biểu đồ", "15 giây", "● theo chu kỳ thu")]) + \
            '<div class="grid3" style="grid-template-columns:minmax(0,1fr) 420px">' + \
            card("Luồng tích hợp", tbl("Bảng luồng", ["Luồng", "Môi trường", "Đã xử lý", "Thất bại", "Lỗi %", "p95", "Trạng thái"], rows)) + \
            card("luong-thanh-toan · xử lý theo 15 giây", chart(P, "#a11a1a", "Lỗi theo thời gian") + '<div class="legend"><span><i style="background:#0b5cd5"></i>Thành công</span><span><i style="background:#a11a1a"></i>Thất bại</span></div>' + XEM +
                 '<div class="grp-t">Route</div>' + tbl("Route", ["Route", "Thất bại", "p95"], [("goi-nha-cung-cap", "2.810", "1,4 s"), ("ghi-nhan-gd", "30", "52 ms")])) + "</div>"
        return shell("02", "Data plane", "Giám sát và kiểm toán › Bảng giám sát › Data plane", body)

    def ui03():
        rows = [("qlvb-tra-cuu", "Sở Nội vụ", "1.120.044", "0,04%", "38 ms", '<div class="prog" style="width:120px"><i style="width:82%"></i></div> 82% hạn mức'),
                ("dc-lay-thua-dat", "Sở TN&MT", "640.210", "0,31%", "92 ms", '<div class="prog" style="width:120px"><i style="width:45%"></i></div> 45% hạn mức'),
                ("cccd-xac-thuc", "Công an tỉnh", "401.887", "0,02%", "61 ms", '<div class="prog" style="width:120px"><i style="width:97%"></i></div> 97% hạn mức'),
                ("tt-tao-giao-dich", "Sở Tài chính", "35.102", "8,09%", "1,4 s", '<div class="prog" style="width:120px"><i style="width:12%"></i></div> 12% hạn mức')]
        body = head("Bảng giám sát · Theo API và theo HTTT", rng) + tabs(["Theo API", "Theo HTTT"], 0) + \
            kp([("API có lượt gọi", "64", "● trên 71 API công bố"), ("Tổng lượt gọi", "4.812.300", "● 24 giờ qua"), ("API lỗi > 1%", "3", "● xem bảng"), ("HTTT gọi", "41", "● 200 HTTT kết nạp")]) + \
            '<div class="grid3" style="grid-template-columns:minmax(0,1fr) 360px">' + card("Xếp hạng API", tbl("Xếp hạng API", ["API", "Chủ dịch vụ", "Lượt gọi", "Lỗi %", "p95", "Mức dùng hạn mức"], rows)) + \
            card("HTTT: DVC tỉnh", '<div class="dl" style="grid-template-columns:120px 1fr"><dt>Lượt gọi</dt><dd>1.842.300</dd><dt>Số API dùng</dt><dd>12</dd><dt>Lỗi chính</dt><dd>429 Vượt hạn mức (62%)</dd><dt>Lần gọi cuối</dt><dd>14:05:31</dd></div>' + chart(P, "#0b5cd5", "Lượt gọi HTTT") + '<span class="btn">Tra log truy cập →</span>') + "</div>"
        return shell("03", "Theo API và theo HTTT", "Giám sát và kiểm toán › Bảng giám sát › Theo API", body)

    def ui04():
        rows = [("apisix-int-01", "Z1", "v2026.11.26-3", tag("ok", "Đồng bộ"), "34%", "52%", "1.204"),
                ("apisix-int-02", "Z1", "v2026.11.26-3", tag("ok", "Đồng bộ"), "31%", "49%", "1.188"),
                ("apisix-ext-01", "Z2", "v2026.11.26-2", tag("warn", "Lệch 7 phút"), "58%", "63%", "2.310"),
                ("apisix-ext-02", "Z2", "v2026.11.26-3", tag("ok", "Đồng bộ"), "55%", "61%", "2.287")]
        body = head("Bảng giám sát · Hạ tầng", rng) + tabs(["Gateway", "Kafka"], 0) + \
            kp([("Nút gateway", "4", "● 3 đồng bộ · 1 lệch"), ("Broker Kafka", "3/3", "● sống"), ("Phân vùng thiếu bản sao", "2", "● cần xử lý", ""), ("Lag consumer lớn nhất", "1.240", "● nhóm dh-audit")]) + \
            '<div class="alert w">⚠ Có 2 phân vùng thiếu bản sao ở cụm Kafka. <b>Xem cảnh báo →</b></div>' + \
            '<div class="grid3" style="grid-template-columns:minmax(0,1fr) 400px">' + card("Nút gateway", tbl("Nút gateway", ["Nút", "Vùng", "Cấu hình", "Đồng bộ", "CPU", "Bộ nhớ", "Kết nối"], rows)) + \
            card("apisix-ext-01 · CPU và bộ nhớ", chart(P, "#0b5cd5", "CPU") + chart([(x, y + 10) for x, y in P], "#7a5200", "Bộ nhớ") + '<div class="legend"><span><i style="background:#0b5cd5"></i>CPU 58%</span><span><i style="background:#7a5200"></i>Bộ nhớ 63%</span></div>' + XEM) + "</div>"
        return shell("04", "Hạ tầng", "Giám sát và kiểm toán › Bảng giám sát › Hạ tầng", body)

    def ui05():
        body = head("Bảng giám sát · Hoạt động nghiệp vụ", '<span class="seg"><span>7 ngày</span><span class="on">30 ngày</span><span>90 ngày</span></span>') + tabs(["Tổng quan", "Theo đơn vị", "Theo dịch vụ"], 0) + \
            kp([("Lượt trao đổi", "128.440.210", "▲ 6% so với kỳ trước"), ("Dịch vụ đang dùng", "64", "● trên 71 công bố"), ("HTTT đang kết nối", "158", "● trên 200 kết nạp"), ("Tỷ lệ thành công", "99,41%", "● đạt mục tiêu")]) + \
            '<div class="grid-2e">' + card("Xu hướng 30 ngày", chart(P, "#0b5cd5", "Xu hướng lượt trao đổi") + XEM) + \
            card("Đơn vị dùng nhiều nhất", hb([("Sở Nội vụ", 92, "24,1 tr"), ("Sở TN&MT", 74, "19,2 tr"), ("Công an tỉnh", 61, "15,8 tr"), ("Sở Tài chính", 38, "9,9 tr"), ("Sở Y tế", 26, "6,7 tr")])) + "</div>" + \
            card("HTTT đã kết nạp nhưng chưa có lượt gọi", tbl("HTTT chưa kết nối", ["HTTT", "Đơn vị", "Ngày kết nạp", "Số ngày chưa có lượt gọi"], [("qlvb-huyen-a", "UBND huyện A", "12/10/2026", "45"), ("htqt-xa-b", "UBND xã B", "03/11/2026", "23")]), "margin-top:12px")
        return shell("05", "Hoạt động nghiệp vụ", "Giám sát và kiểm toán › Bảng giám sát › Nghiệp vụ", body)

    def ui06():
        body = head("Bảng giám sát · An ninh", rng) + tabs(["Tổng quan an ninh"], 0) + \
            kp([("Đăng nhập thất bại", "184", "▲ 12% · đỉnh 09:00"), ("Quyết định từ chối", "1.206", "● bình thường"), ("WAF chặn", "9.402", "● chủ yếu quét cổng"), ("Xem dữ liệu Nhạy cảm", "312", "● đều trong ngưỡng"), ("Cảnh báo an ninh mở", "2", "⚠ 1 mức Nghiêm trọng")]) + \
            '<div class="grid-2e">' + card("Đăng nhập thất bại theo giờ", chart(P, "#a11a1a", "Đăng nhập thất bại") + XEM) + \
            card("Chỉ báo toàn vẹn chuỗi kiểm toán", f'<div style="font-size:15px">{tag("ok", "✔ Chuỗi toàn vẹn")} kiểm tra 03:00 hôm nay · neo 14:00</div><p class="muted">Chuỗi kiểm toán tenant T68 chưa phát hiện đứt chuỗi.</p><span class="btn">Mở toàn vẹn và bằng chứng →</span>') + "</div>" + \
            '<div class="grid-2e" style="margin-top:12px">' + card("Nguồn bị từ chối nhiều nhất", tbl("Nguồn từ chối", ["Chủ thể", "Số lần", "Lý do chính"], [("htt-dat-dai (CLIENT)", "412", "Thiếu quyền PII.REVEAL"), ("a3f5b8…", "188", "Sai chứng thư"), ("203.0.113.x", "96", "Vượt hạn mức")])) + \
            card("Quét dữ liệu cá nhân trong log", tbl("Kết quả quét", ["DU", "Mẫu", "Số dòng", "Trạng thái"], [("dh-integration", "CCCD 12 số", "3", tag("warn", "Cần xử lý")), ("dh-runtime", "—", "0", tag("ok", "Sạch"))])) + "</div>"
        return shell("06", "Bảng điều khiển an ninh", "Giám sát và kiểm toán › Bảng giám sát › An ninh", body)

    def logrow(t, lv, du, msg):
        k = {"LỖI": "err", "CẢNH BÁO": "warn", "TT": "info"}[lv]
        return f'<div class="mono" style="font-size:12px;padding:3px 0;border-bottom:1px solid #eef1f5;white-space:nowrap;overflow:hidden">{t} {tag(k, lv)} {du} {msg}</div>'

    def ui07():
        logs = [("26/11 14:05:32.120", "LỖI", "dh-runtime", "Gọi ndxp-gateway thất bại: timeout 1200ms trace_id=4bf92f35…"),
                ("26/11 14:05:32.118", "CẢNH BÁO", "dh-runtime", "Thử lại 1/3 sau 400ms"), ("26/11 14:05:32.101", "TT", "apisix", "POST /api/ndxp/v1/ho-so 504 1203ms"),
                ("26/11 14:05:31.980", "TT", "dh-runtime", "Bắt đầu luồng luong-nop-ho-so"), ("26/11 14:05:31.640", "LỖI", "dh-runtime", "Gọi ndxp-gateway thất bại: timeout 1200ms"),
                ("26/11 14:05:31.201", "TT", "apisix", "GET /api/dc/v1/thua-dat 200 41ms")] * 2
        body = head("Tra log", '<span class="btn">Lưu truy vấn</span><span class="btn">Truy vấn đã lưu ▾</span><span class="btn">Xuất CSV</span>') + \
            '<div class="card" style="margin-bottom:12px"><div class="row"><span class="input">Khoảng: 1 giờ qua ▾</span><span class="input" style="flex:1;color:var(--color-text)">du:dh-runtime OR du:apisix</span><span class="btn pri">▶ Chạy</span></div>' + \
            '<div class="row" style="margin-top:8px"><span class="input">Dịch vụ: dh-runtime, apisix ▾</span><span class="input">Mức: tất cả ▾</span><span class="input">Luồng: ops ▾</span><span class="tag t-info">● Trực tiếp: Tắt</span></div></div>' + \
            card("Số dòng theo thời gian · 3.482 kết quả", '<div class="vbars">' + "".join(f'<div><i style="height:{h}px;background:#0b5cd5"></i><i style="height:{e}px;background:#a11a1a"></i></div>' for h, e in [(30, 4), (40, 6), (36, 3), (52, 8), (44, 5), (60, 12), (48, 30), (70, 40), (56, 18), (40, 6), (34, 4), (30, 3)]) + '</div><div class="legend"><span><i style="background:#0b5cd5"></i>Khác</span><span><i style="background:#a11a1a"></i>LỖI</span></div>', "margin-bottom:12px") + \
            '<div class="grid3" style="grid-template-columns:minmax(0,1fr) 380px">' + card("Danh sách log", "".join(logrow(*l) for l in logs)) + \
            card("Chi tiết dòng", '<div class="code" style="font-size:11.5px">{\n  "ts": "2026-11-26T14:05:32.120+07:00",\n  "level": "ERROR",\n  "du": "dh-runtime",\n  "tenant": "T68",\n  "trace_id": "4bf92f35c1a84d0e…",\n  "msg": "Gọi ndxp-gateway thất bại",\n  "client": "a3f5b8…(che)"\n}</div><div class="foot" style="justify-content:flex-start"><span class="btn pri">Mở trace</span><span class="btn">Ngữ cảnh ±50 dòng</span></div>') + "</div>"
        return shell("07", "Tra log", "Giám sát và kiểm toán › Tra log", body)

    def ui09():
        rows = [("14:05:32", "dvc-tinh", "dc-lay-thua-dat", "GET", tag("ok", "200 Thành công"), "92 ms", "1,2 KB", "4bf92f35…"),
                ("14:05:31", "dvc-tinh", "tt-tao-giao-dich", "POST", tag("err", "503 Lỗi máy chủ"), "1.203 ms", "2,4 KB", "9a1c77e0…"),
                ("14:05:30", "htt-dat-dai", "cccd-xac-thuc", "POST", tag("warn", "429 Vượt hạn mức"), "4 ms", "0,6 KB", "c03d58aa…"),
                ("14:05:29", "qlvb-huyen-a", "qlvb-tra-cuu", "GET", tag("ok", "200 Thành công"), "38 ms", "0,9 KB", "7be014cd…")]
        body = head("Nhật ký truy cập API", '<span class="btn">Xuất CSV</span>') + \
            '<div class="card" style="margin-bottom:12px"><div class="row"><span class="input">Từ 26/11 13:00</span><span class="input">Đến 26/11 14:05</span><span class="input">HTTT: tất cả ▾</span><span class="input">API: tất cả ▾</span><span class="input">Trạng thái: 4xx, 5xx ▾</span><span class="input">Độ trễ ≥ 500 ms</span><span class="btn pri">Lọc</span></div></div>' + \
            '<div class="grid3" style="grid-template-columns:minmax(0,1fr) 360px">' + card("1.284 lượt gọi", tbl("Lượt gọi API", ["Thời điểm", "HTTT gọi", "API", "PT", "Trạng thái", "Độ trễ", "Kích thước", "trace_id"], rows) + '<div class="foot" style="justify-content:space-between"><span class="muted">Trang 1 / 26 · 50 dòng mỗi trang</span><span class="muted">Chỉ lưu siêu dữ liệu, không lưu nội dung gói tin</span></div>') + \
            card("Chi tiết lượt gọi", '<div class="dl" style="grid-template-columns:110px 1fr"><dt>Mã yêu cầu</dt><dd class="mono">req-7f3a2c</dd><dt>Nút gateway</dt><dd>apisix-int-01</dd><dt>Nguồn</dt><dd class="mono">10.20.4.x (che)</dd><dt>Chính sách</dt><dd>Giới hạn tốc độ 100/phút</dd><dt>Phản hồi</dt><dd>503 sau 1.203 ms</dd></div><div class="foot" style="justify-content:flex-start"><span class="btn pri">Mở trace</span></div>') + "</div>"
        return shell("09", "Nhật ký truy cập API", "Giám sát và kiểm toán › Tra log › Truy cập API", body)

    def ui10():
        rows = [(tag("err", "Nghiêm trọng"), "Lỗi kết nối nhà cung cấp thanh toán vượt 5%", "dh-payment", "13:57", "18 phút", "Cấp 1", tag("err", "Đang phát")),
                (tag("warn", "Cảnh báo"), "Phân vùng Kafka thiếu bản sao", "Kafka", "13:41", "34 phút", "—", tag("info", "Đã tiếp nhận")),
                (tag("warn", "Cảnh báo"), "Chứng thư sắp hết hạn (19 ngày)", "pki-clients", "06:00", "8 giờ", "—", tag("err", "Đang phát")),
                (tag("info", "Thông tin"), "Dung lượng volume Loki 78%", "Loki", "Hôm qua", "—", "—", tag("neutral", "Tạm ẩn") if False else tag("local", "Tạm ẩn"))]
        body = head("Cảnh báo", '<span class="btn">Luật và runbook</span><span class="btn">Lịch trực</span>') + tabs(["Đang mở (3)", "Lịch sử", "Thống kê"], 0) + \
            '<div class="card"><div class="toolbar"><span class="input">Mức: tất cả ▾</span><span class="input">Trạng thái: Đang phát, Đã tiếp nhận ▾</span><span class="input">Thành phần ▾</span><span class="input">Nguồn luật ▾</span></div>' + \
            tbl("Cảnh báo đang mở", ["Mức", "Cảnh báo", "Thành phần", "Bắt đầu", "Thời lượng", "Leo thang", "Trạng thái"], rows) + "</div>" + \
            '<aside class="drawer" aria-label="Chi tiết cảnh báo"><h3 style="margin:0 0 6px">Lỗi kết nối nhà cung cấp thanh toán</h3><div>' + tag("err", "Nghiêm trọng") + " " + tag("err", "Đang phát") + '</div>' + \
            '<div class="dl" style="grid-template-columns:100px 1fr;margin:10px 0"><dt>Giá trị đo</dt><dd>8,1% (ngưỡng 5%)</dd><dt>Bắt đầu</dt><dd>13:57 · 18 phút</dd><dt>Thông báo</dt><dd>SMS 13:58 ✔ · Thư 13:58 ✔</dd></div>' + \
            '<div class="card"><b>Runbook</b><ol style="margin:6px 0 0 16px;padding:0;font-size:12.5px;line-height:1.5"><li><b>Ý nghĩa:</b> kết nối tới nhà cung cấp thanh toán đang lỗi.</li><li><b>Kiểm tra đầu tiên:</b> trạng thái kênh ở PH-19.</li><li><b>Nguyên nhân thường gặp:</b> chứng thư, mạng, nhà cung cấp bảo trì.</li><li><b>Cách xử lý:</b> chuyển kênh dự phòng.</li><li><b>Báo cấp trên:</b> sau 30 phút chưa khắc phục.</li></ol></div>' + \
            '<div class="foot" style="justify-content:flex-start"><span class="btn pri">Tiếp nhận</span><span class="btn">Tạm ẩn…</span><span class="btn">Đánh dấu đã xử lý…</span></div></aside>'
        return shell("10", "Cảnh báo", "Giám sát và kiểm toán › Cảnh báo", body)

    def ui11():
        rows = [("payment-provider-connection-error", tag("info", "Chuẩn nền tảng"), tag("err", "Nghiêm trọng"), tag("ok", "Đang bật") + " 🔒", "3"),
                ("kafka-under-replicated", tag("info", "Chuẩn nền tảng"), tag("warn", "Cảnh báo"), tag("ok", "Đang bật") + " 🔒", "1"),
                ("tinh-t68-luong-nop-ho-so-cham", tag("local", "Riêng của tỉnh"), tag("warn", "Cảnh báo"), tag("ok", "Đang bật"), "0"),
                ("tinh-t68-ngoai-gio", tag("local", "Riêng của tỉnh"), tag("info", "Thông tin"), tag("local", "Đã tắt"), "0")]
        body = head("Luật cảnh báo và runbook", '<span class="btn pri">Luật mới</span>') + \
            '<div class="grid3" style="grid-template-columns:minmax(0,1fr) 440px">' + card("Danh sách luật", tbl("Luật cảnh báo", ["Mã luật", "Nguồn", "Mức", "Trạng thái", "Phát 30 ngày"], rows) + '<p class="muted">🔒 Luật chuẩn của nền tảng không sửa hoặc tắt được; có thể nhân bản thành luật riêng.</p>') + \
            card("Sửa luật tinh-t68-luong-nop-ho-so-cham", '<div class="field"><label>Biểu thức</label><div class="code" style="white-space:pre-wrap;font-size:11.5px">histogram_quantile(0.95, sum(rate(dh_flow_duration_bucket{flow="luong-nop-ho-so"}[5m])) by (le)) &gt; 1</div></div>' + \
                 '<div class="row"><div class="field"><label>Thời gian duy trì</label><span class="input">10 phút</span></div><div class="field"><label>Mức độ</label><span class="input">Cảnh báo ▾</span></div></div>' + \
                 '<div class="field"><label>Nhóm nhận</label><span class="input">Trực vận hành T68 ▾</span></div><div class="grp-t">Runbook (5 mục, bắt buộc)</div>' + "".join(f'<div class="field"><label>{x}</label><span class="input" style="height:auto;min-height:30px;white-space:normal">…</span></div>' for x in ["Ý nghĩa", "Kiểm tra đầu tiên"]) + \
                 '<div class="alert w" style="background:#e6efff;border-color:#bcd2f7;color:#0b3a8c">ⓘ Chạy thử 24 giờ gần nhất: luật sẽ phát 2 lần.</div><div class="foot"><span class="btn">Chạy thử</span><span class="btn pri">Lưu luật</span></div>') + "</div>"
        return shell("11", "Luật cảnh báo và runbook", "Giám sát và kiểm toán › Cảnh báo › Luật", body)

    def ui12():
        def cell(txt, gap=False):
            st = "background:#fde8e8;color:#a11a1a;" if gap else ""
            return f'<div style="background:#fff;border:1px solid var(--color-border);padding:6px;font-size:12px;{st}">{txt}</div>'
        day = ["Nguyễn Văn An"] * 3 + ["Trần Thị Bình"] * 4
        night = ["Lê Văn Sơn"] * 3 + ["Phạm Thu Hà"] * 3 + ["Hở lịch"]
        grid = "".join(cell(n) for n in day) + "".join(cell(n, n == "Hở lịch") for n in night)
        body = head("Lịch trực, nhóm nhận, kênh thông báo", '<span class="btn pri">Lưu</span>') + tabs(["Lịch trực", "Nhóm nhận", "Kênh thông báo"], 0) + \
            '<div class="alert w">⚠ Lịch trực chưa có người nhận Chủ nhật 22:00 đến 07:30 (ca đêm). Bổ sung trước khi lưu.</div>' + \
            card("Lịch tuần 23–29/11 · hàng trên ca ngày 07:30–17:00, hàng dưới ca đêm 17:00–07:30", '<div style="display:grid;grid-template-columns:repeat(7,1fr);gap:4px;font-size:12px"><b>T2</b><b>T3</b><b>T4</b><b>T5</b><b>T6</b><b>T7</b><b>CN</b>' + grid + "</div>") + \
            '<div class="grid-2e" style="margin-top:12px">' + card("Leo thang", tbl("Leo thang", ["Cấp", "Người nhận", "Kênh", "Chờ"], [("1", "Trực ca", "SMS + Thư", "0 phút"), ("2", "Trưởng nhóm vận hành", "SMS + Gọi tự động", "15 phút"), ("3", "Quản trị tỉnh", "Thư", "30 phút")])) + \
            card("Kênh thông báo", tbl("Kênh", ["Mã", "Loại", "Đích", "Kiểm tra gần nhất"], [("sms-vh", "SMS", "090****123", tag("ok", "Đã gửi thử 13:20")), ("mail-vh", "Thư", "vh@t68.gov.vn", tag("ok", "Đã gửi thử 13:20")), ("webhook-chat", "Webhook", "…/hook/***", tag("err", "Không thành công"))]) + '<span class="btn">Gửi thử</span>') + "</div>"
        return shell("12", "Lịch trực, nhóm nhận, kênh thông báo", "Giám sát và kiểm toán › Cảnh báo › Lịch trực", body)

    def ui14():
        rows = [("EX-0142", "01/10–31/10/2026", "QĐ 88/QĐ-TTr", tag("info", "Đang xuất") + ' <div class="prog" style="width:90px;display:inline-block"><i style="width:62%"></i></div> 62%', "—", "tran.thi.binh"),
                ("EX-0141", "01/09–30/09/2026", "QĐ 71/QĐ-TTr", tag("ok", "Sẵn sàng tải"), "còn 5 ngày", "tran.thi.binh"),
                ("EX-0139", "01/08–31/08/2026", "Khiếu nại 42/2026", tag("local", "Hết hạn tải"), "—", "le.minh.cuong"),
                ("EX-0138", "01/07–31/07/2026", "QĐ 55/QĐ-TTr", tag("err", "Không xuất được"), "—", "tran.thi.binh")]
        body = head("Toàn vẹn và bằng chứng", '<span class="btn">Kiểm tra toàn vẹn…</span><span class="btn pri">Xuất bằng chứng…</span>') + tabs(["Neo băm", "Kiểm tra toàn vẹn", "Xuất bằng chứng"], 2) + \
            card("Yêu cầu xuất bằng chứng ký số", tbl("Yêu cầu xuất", ["Mã", "Phạm vi", "Căn cứ", "Trạng thái", "Hạn tải", "Người yêu cầu"], rows) + '<div class="foot" style="justify-content:space-between"><span class="muted">Gói gồm bản ghi, chuỗi băm, neo, chữ ký số; mỗi lượt tải được ghi kiểm toán</span><span class="btn pri">Tải gói EX-0141</span></div>') + \
            '<div class="grid-2e" style="margin-top:12px">' + card("Neo băm gần nhất", tbl("Neo", ["Thời điểm", "Khoảng seq", "Khóa ký", "WORM", "SIEM"], [("14:00", "4.819.001–4.820.117", "v2", tag("ok", "Có"), tag("ok", "Có")), ("13:00", "4.817.640–4.819.000", "v2", tag("ok", "Có"), tag("ok", "Có"))])) + \
            card("Kiểm tra toàn vẹn gần nhất", f'<div>{tag("ok", "✔ Chuỗi toàn vẹn")} 03:00 hôm nay · 36,4 triệu bản ghi · 41 phút</div><p class="muted">Kiểm tra theo yêu cầu chỉ dành cho cán bộ ATTT và kiểm toán viên.</p>') + "</div>"
        return shell("14", "Toàn vẹn và bằng chứng", "Giám sát và kiểm toán › Nhật ký kiểm toán › Toàn vẹn và bằng chứng", body)

    def ui15():
        rows = [(tag("err", "Nghiêm trọng"), "UC-SEC-04 Xem dữ liệu Nhạy cảm hàng loạt", "htt-dat-dai", "13:58", "—", tag("err", "Mới")),
                (tag("warn", "Cảnh báo"), "UC-SEC-01 Đăng nhập thất bại liên tiếp", "pham.thu.ha", "09:47", "le.van.son", tag("info", "Đang điều tra")),
                (tag("info", "Thông tin"), "UC-SEC-09 Truy cập ngoài giờ", "nguyen.van.an", "Hôm qua", "le.van.son", tag("local", "Đã đóng"))]
        body = head("Cảnh báo an ninh và luật phát hiện", '<span class="btn">Báo cáo sự cố</span>') + tabs(["Cảnh báo an ninh (2)", "Luật phát hiện"], 0) + \
            '<div class="grid3" style="grid-template-columns:minmax(0,1fr) 430px">' + card("Cảnh báo an ninh", tbl("Cảnh báo an ninh", ["Mức", "Luật", "Chủ thể", "Bắt đầu", "Người điều tra", "Trạng thái"], rows)) + \
            card("UC-SEC-04 · htt-dat-dai", f'<div>{tag("err", "Nghiêm trọng")} {tag("err", "Mới")}</div><div class="grp-t">Bằng chứng (3 bản ghi kiểm toán)</div>' + tbl("Bằng chứng", ["Lúc", "Hành động", "Kết quả"], [("13:58:09", "PII.REVEAL", tag("err", "Từ chối")), ("13:58:07", "PII.REVEAL", tag("err", "Từ chối")), ("13:58:02", "PII.REVEAL", tag("ok", "Thành công"))]) + \
                 '<div class="grp-t">Đóng cảnh báo: kết luận bắt buộc</div><div class="facets"><span>Sự cố thật</span><span>Báo nhầm</span><span>Chấp nhận rủi ro</span></div><div class="foot"><span class="btn pri">Tiếp nhận</span><span class="btn">Đề xuất tạm ngừng HTTT</span><span class="btn danger">Đóng cảnh báo…</span></div>') + "</div>"
        return shell("15", "Cảnh báo an ninh", "Giám sát và kiểm toán › Bảng giám sát › An ninh › Cảnh báo", body)

    def ui16():
        rows = [("26/11 11:02–11:40", "vo.thanh.tam", "Vận hành nền tảng", "PLATFORM", "Khắc phục sự cố Kafka theo ticket INC-2210", "14", tag("warn", "Có ghi")),
                ("20/11 15:10–15:25", "le.minh.hai", "Kiểm toán nền tảng", "PLATFORM", "Thanh tra định kỳ quý 4", "37", tag("ok", "Chỉ đọc")),
                ("12/11 08:30–08:52", "vo.thanh.tam", "Vận hành nền tảng", "PLATFORM", "Nâng cấp phiên bản APISIX", "9", tag("warn", "Có ghi"))]
        body = head("Truy cập liên tenant", '<span class="input">Từ 01/11/2026 · Đến 26/11/2026</span>') + \
            '<div class="alert w" style="background:#e6efff;border-color:#bcd2f7;color:#0b3a8c">ⓘ Phiên có thao tác ghi được gắn nhãn "Có ghi". Bấm "Xem thao tác" để mở nhật ký kiểm toán (cần nhập lý do).</div>' + \
            card("Phiên truy cập tenant T68 từ tenant khác", tbl("Phiên liên tenant", ["Thời gian", "Người", "Vai trò", "Tenant xuất phát", "Lý do", "Số thao tác", "Loại", ""], [r + ('<span class="btn">Xem thao tác</span>',) for r in rows]))
        return shell("16", "Truy cập liên tenant", "Giám sát và kiểm toán › Nhật ký kiểm toán › Liên tenant", body)

    def ui17():
        def row(k, v, d, rg):
            return f'<div class="qrow"><span><b>{k}</b><br><small class="muted mono">{d}</small></span><span class="input" style="min-width:0">{v}</span><span class="muted">{rg}</span></div>'
        body = head("Cài đặt giám sát", '<span class="btn pri">Lưu</span>') + tabs(["Tham số và hạn mức", "Mục tiêu SIEM", "Bộ dashboard", "Kiểm tra tổng hợp", "Chuỗi kiểm toán"], 0) + \
            '<div class="grid-2e">' + card("Lưu giữ", row("Lưu kiểm toán trực tuyến", "12 tháng", "13.audit.online-months", "6–36") + row("Lưu kiểm toán WORM", "5 năm", "13.audit.retention-years", "≥ 3 năm") + row("Lưu log vận hành", "90 ngày", "13.logs.retention-days", "30–180") + row("Lưu trace", "14 ngày", "13.trace.retention-days", "7–30")) + \
            card("Hạn mức quan sát và SLO", row("Chuỗi chỉ số hoạt động", "250.000", "13.quota.active-series", "≤ 500.000") + row("Giữ trace thành công", "10 %", "13.trace.success-sample-percent", "1–100") + row("SLO tỷ lệ thành công", "99,9 %", "13.slo.availability", "99–99,99") + row("SLO độ trễ gateway p95", "50 ms", "13.slo.gateway-p95-ms", "20–200")) + "</div>" + \
            '<div class="alert w" style="margin-top:12px;background:#e6efff;border-color:#bcd2f7;color:#0b3a8c">ⓘ Thay đổi tham số được ghi kiểm toán kèm giá trị trước và sau. Thời hạn lưu kiểm toán không được thấp hơn 3 năm.</div>'
        return shell("17", "Cài đặt giám sát", "Giám sát và kiểm toán › Cài đặt", body)

    def ui18():
        body = head("Sức khỏe chuỗi kiểm toán", rng) + \
            kp([("seq đầu chuỗi", "4.820.117", "● cập nhật 14:05:31"), ("Backlog hộp thư đi", "0", "● không tồn"), ("Độ trễ ghi p95", "1,1 s", "● dưới 2 giây"), ("Độ trễ sao WORM", "4 phút", "● dưới 10 phút"), ("Neo gần nhất", "14:00", "● chữ ký hợp lệ")]) + \
            f'<div class="alert w" style="background:#e5f6ec;border-color:#bfe6cf;color:#0b6b3a">{tag("ok", "✔ Chuỗi toàn vẹn")} kiểm tra hằng ngày lúc 03:00 hôm nay, không phát hiện đứt chuỗi.</div>' + \
            '<div class="grid-2e">' + card("Đối chiếu số lượng theo DU", tbl("Đối chiếu", ["DU", "Phát", "Nhận", "Lệch", "Trạng thái"], [("dh-integration", "41.220", "41.220", "0", tag("ok", "Khớp")), ("dh-data", "18.044", "18.044", "0", tag("ok", "Khớp")), ("dh-payment", "9.410", "9.408", "2", tag("warn", "Lệch")), ("dh-runtime", "22.871", "22.871", "0", tag("ok", "Khớp"))])) + \
            card("Phân vùng theo tháng", tbl("Phân vùng", ["Tháng", "Số bản ghi", "Xác minh WORM", "Trạng thái"], [("11/2026", "2.610.442", tag("info", "Đang ghi"), tag("ok", "Trực tuyến")), ("10/2026", "3.012.870", tag("ok", "Đủ"), tag("ok", "Trực tuyến")), ("11/2025", "2.488.115", tag("ok", "Đủ"), tag("local", "Đã lưu trữ"))])) + "</div>" + \
            card("Kho cách ly", '<div class="muted">3 bản ghi cách ly 24 giờ qua · lý do: thiếu trường bắt buộc (2), chứa giá trị Nhạy cảm chưa che (1). Chỉ xem số lượng và lý do, không xem nội dung.</div>', "margin-top:12px")
        return shell("18", "Sức khỏe chuỗi kiểm toán", "Giám sát và kiểm toán › Nhật ký kiểm toán › Sức khỏe chuỗi", body)

    return {"02": ui02, "03": ui03, "04": ui04, "05": ui05, "06": ui06, "07": ui07, "09": ui09, "10": ui10, "11": ui11,
            "12": ui12, "14": ui14, "15": ui15, "16": ui16, "17": ui17, "18": ui18}
