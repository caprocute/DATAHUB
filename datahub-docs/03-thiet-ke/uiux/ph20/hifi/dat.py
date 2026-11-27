"""Dữ liệu giả định dùng chung cho bản hi-fi PH-20: tenant T68 (Tỉnh Lâm Viên, giả định), T01 (Tỉnh Mẫu A), T90 (kiểm thử).
Kịch bản: nền tảng có 34 tenant tỉnh theo NFR-00-060, T68 vừa khởi tạo, T09 tạm ngừng, T12 đang sáp nhập vào T13."""
from kit import *

TS = {
    "PROVISIONING": ("info", "◔ Đang khởi tạo"), "ACTIVE": ("ok", "● Đang hoạt động"), "SUSPENDED": ("err", "⏸ Tạm ngừng"),
    "MERGING": ("warn", "⇄ Đang sáp nhập"), "MERGED": ("mute", "⇥ Đã sáp nhập"), "DECOMMISSIONED": ("mute", "✕ Đã chấm dứt"), "FAILED": ("err", "✕ Khởi tạo lỗi"),
}
ISO = {"SHARED": "Dùng chung", "DEDICATED_DB": "CSDL riêng", "DEDICATED_CLUSTER": "Cụm riêng"}


def ts(s):
    k, t = TS[s]
    return f"<span class='tag t-{k}'>{t}</span>"


def run(s):
    m = {"SUCCEEDED": ("ok", "✓ Thành công"), "RUNNING": ("info", "▶ Đang chạy"), "WAITING": ("warn", "◔ Chờ báo cáo"), "FAILED": ("err", "✕ Lỗi"),
         "COMPENSATING": ("warn", "↶ Đang bù trừ"), "PENDING": ("mute", "○ Chờ chạy"), "CANCELLED": ("mute", "– Đã hủy")}
    k, t = m[s]
    return f"<span class='tag t-{k}'>{t}</span>"


def ic(k, t=None):
    sym = {"ok": "✓", "run": "▶", "wait": "◔", "fail": "✕", "skip": "–", "pend": "", "cmp": "↶"}[k]
    return f'<span class="ic {k}" aria-label="{t or k}">{sym}</span>'


# (mã, tên, trạng thái, cách ly, quy mô, hồ sơ, phiên bản, kênh, lần chạy cuối, cảnh báo, kích hoạt)
TEN = [
    ("T68", "Tỉnh Lâm Viên (giả định)", "PROVISIONING", "SHARED", "QM-VUA", "HT-B", "—", "PREVIEW", "Đang chạy bước S06", "—", "—"),
    ("T01", "Tỉnh Mẫu A", "ACTIVE", "SHARED", "QM-VUA", "HT-B", "2.4.1", "STABLE", "Thành công 12/03/2026", "1", "12/03/2026"),
    ("T02", "Tỉnh Mẫu B", "ACTIVE", "SHARED", "QM-NHO", "HT-A", "2.4.1", "STABLE", "Thành công 02/04/2026", "—", "02/04/2026"),
    ("T03", "Tỉnh Mẫu C", "ACTIVE", "DEDICATED_DB", "QM-LON", "HT-B", "2.4.0", "STABLE", "Thành công 20/04/2026", "2", "20/04/2026"),
    ("T04", "Tỉnh Mẫu D", "ACTIVE", "SHARED", "QM-VUA", "HT-B", "2.5.0", "PREVIEW", "Thành công 11/05/2026", "—", "11/05/2026"),
    ("T07", "Tỉnh Mẫu E", "FAILED", "SHARED", "QM-NHO", "HT-A", "—", "STABLE", "Lỗi bước S08", "—", "—"),
    ("T09", "Tỉnh Mẫu G", "SUSPENDED", "SHARED", "QM-NHO", "HT-A", "2.4.1", "STABLE", "Thành công 08/06/2026", "—", "08/06/2026"),
    ("T12", "Tỉnh Mẫu H", "MERGING", "SHARED", "QM-VUA", "HT-B", "2.4.1", "STABLE", "Thành công 30/06/2026", "—", "30/06/2026"),
    ("T13", "Tỉnh Mẫu K", "ACTIVE", "DEDICATED_DB", "QM-LON", "HT-B", "2.4.1", "STABLE", "Thành công 15/07/2026", "1", "15/07/2026"),
    ("T15", "Tỉnh Mẫu L", "ACTIVE", "SHARED", "QM-VUA", "HT-B", "2.4.0", "STABLE", "Thành công 03/08/2026", "—", "03/08/2026"),
    ("T16", "Tỉnh Mẫu M", "ACTIVE", "SHARED", "QM-NHO", "HT-A", "2.4.1", "STABLE", "Thành công 25/08/2026", "—", "25/08/2026"),
    ("T20", "Tỉnh Mẫu N", "DECOMMISSIONED", "SHARED", "QM-NHO", "HT-A", "—", "STABLE", "Đã hủy khởi tạo", "—", "—"),
]
FAC = {"ACTIVE": 27, "PROVISIONING": 1, "SUSPENDED": 1, "MERGING": 2, "FAILED": 1, "MERGED": 0, "DECOMMISSIONED": 2}
STEPS = [
    ("S01_RECORD", "Ghi bản ghi tenant, cấu hình mặc định", "PH-20", "ok", "0:04", 1, ""),
    ("S02_CONFIG_REPO", "Thư mục tenants/T68/ trong kho cấu hình", "PH-20", "ok", "0:11", 1, ""),
    ("S03_REALM", "Realm dh-t68, client, vai trò chuẩn", "PH-12", "ok", "0:48", 1, ""),
    ("S04_SECRETS", "Đường dẫn kv/dh/t68, khóa KEK", "PH-20", "ok", "0:22", 1, ""),
    ("S05_BUCKETS", "Bucket dh-t68-*", "PH-20", "ok", "0:17", 1, ""),
    ("S06_EVENTING", "Hạn mức, ACL, topic hệ thống", "PH-10", "wait", "6:10", 1, ""),
    ("S09_GATEWAY", "Host, tiền tố, hạn mức ở APISIX", "PH-03", "run", "4:32", 1, ""),
    ("S10_INTEGRATION", "Không gian DEFAULT, kho luồng", "PH-04", "ok", "3:05", 1, ""),
    ("S12_SEED_MDM", "Gói dữ liệu chủ nền", "PH-06", "skip", "—", 0, ""),
    ("S07_DATABASE", "Cụm CNPG riêng (chỉ DEDICATED_DB)", "PH-20", "skip", "—", 0, ""),
    ("S08_OBSERVABILITY", "Chuỗi kiểm toán, Grafana, luật cảnh báo", "PH-13", "ok", "1:40", 1, ""),
    ("S11_SEED_RDM", "Gói danh mục nền", "PH-07", "pend", "—", 0, ""),
    ("S13_ORG_SEED", "Tổ chức cấp tỉnh từ ĐVHC COMMON", "PH-20", "pend", "—", 0, ""),
    ("S14_KPI", "Bộ chỉ tiêu mẫu", "PH-16", "pend", "—", 0, ""),
    ("S15_MODULES", "Bật phân hệ theo mẫu", "các PH", "pend", "—", 0, ""),
    ("S16_SMOKE", "Kiểm tra khói", "PH-20", "pend", "—", 0, ""),
    ("S17_ACTIVATE", "Kích hoạt, bàn giao", "PH-20", "pend", "—", 0, ""),
]
RES = [("API_RPS", "Lượt gọi API mỗi giây", "lượt/giây", 500, 410), ("ACTIVE_FLOWS", "Luồng đang chạy", "luồng", 1000, 612), ("KAFKA_PRODUCE_MBPS", "Ghi sự kiện", "MB/giây", 10, 8.6),
       ("KAFKA_CONSUME_MBPS", "Đọc sự kiện", "MB/giây", 20, 9.1), ("OBJECT_STORAGE_GB", "Kho đối tượng", "GB", 500, 505), ("DATABASE_GB", "Cơ sở dữ liệu", "GB", 200, 96),
       ("USERS", "Người dùng", "người", 2000, 1180), ("MEMBER_SYSTEMS", "Hệ thống thành viên", "HTTT", 300, 142), ("PUBLISHED_APIS", "API công bố", "API", 2000, 640),
       ("TOPICS", "Topic", "topic", 2000, 590), ("RUNTIME_CPU", "CPU runtime", "vCPU", 16, 11.2), ("RUNTIME_MEMORY_GB", "Bộ nhớ runtime", "GB", 64, 41)]


def qbar(name, code, used, lim, unit, over=None):
    pct = 100 * used / lim
    col = "#c0392b" if pct >= 100 else ("#c98a00" if pct >= 80 else "#0b7a52")
    mark = "✕ Chạm 100 %" if pct >= 100 else ("▲ Quá 80 %" if pct >= 80 else "● Trong mức")
    w = min(pct, 100)
    return (f'<div class="qbar"><span><b>{name}</b><div class="muted mono">{code}</div></span><span class="t"><i style="width:{w:.0f}%;background:{col}"></i><u style="left:80%"></u></span>'
            f'<span><b class="num">{vn(used, 1 if used < 100 and used != int(used) else 0)}</b> / {vn(lim, 0)} {unit} · {vn(pct, 0)} % <span style="color:{col};font-weight:600">{mark}</span></span></div>')
