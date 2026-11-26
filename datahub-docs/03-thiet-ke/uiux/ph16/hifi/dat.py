"""Dữ liệu giả định dùng chung cho bản hi-fi PH-16: tỉnh T68, kỳ M-2026-10, nền GĐ-04 (200 HTTT, 150 kết nối điểm–điểm)."""
from kit import *

CR = "Giám sát và kiểm toán › Báo cáo chỉ tiêu"
# (mã, tên hiển thị, KPI, nhóm, đo, đơn vị, giá trị, mục tiêu, trạng thái, Δ, đầy đủ, nguồn)
IND = [
    ("httt-ket-noi-ty-le", "Tỷ lệ HTTT kết nối chia sẻ", "KPI-01", "KET_NOI", "AUTO", "%", "31,0", "≥ 40", "AT_RISK", "▲ +3,5", "COMPLETE", "PH-01"),
    ("ket-noi-diem-diem-con-lai", "Kết nối điểm–điểm còn lại", "KPI-02", "KET_NOI", "MANUAL", "kết nối", "118", "≤ 90", "OFF_TRACK", "▼ −12", "COMPLETE", "Nhập tay"),
    ("thoi-gian-ket-nap-httt", "Thời gian kết nạp HTTT", "KPI-05", "KET_NOI", "AUTO", "ngày", "9,5", "≤ 10", "ON_TRACK", "▼ −0,8", "COMPLETE", "PH-01"),
    ("thoi-gian-xay-luong", "Thời gian xây luồng tích hợp", "KPI-06", "KET_NOI", "AUTO", "ngày", "4,2", "≤ 5", "ON_TRACK", "▼ −0,3", "COMPLETE", "PH-04"),
    ("nhat-ky-khai-thac-du", "Nhật ký khai thác đủ trường", "KPI-07", "CHIA_SE", "AUTO", "%", "97,4", "100", "AT_RISK", "▲ +0,6", "COMPLETE", "PH-13"),
    ("doi-soat-tu-dong-khop", "Đối soát tự động khớp", "KPI-13", "CHIA_SE", "AUTO", "%", "98,6", "≥ 99", "AT_RISK", "▲ +0,2", "COMPLETE", "PH-19"),
    ("thoi-gian-phat-hien-lech", "Thời gian phát hiện lệch", "KPI-14", "CHIA_SE", "AUTO", "giờ", "6,2", "≤ 24", "ON_TRACK", "▼ −1,1", "COMPLETE", "PH-19"),
    ("api-cong-bo", "API đã công bố", "—", "CHIA_SE", "AUTO", "API", "86", "≥ 80", "ON_TRACK", "▲ +4", "COMPLETE", "PH-02"),
    ("luot-khai-thac-thang", "Lượt khai thác trong tháng", "—", "CHIA_SE", "AUTO", "lượt", "1.284.300", "≥ 1.000.000", "ON_TRACK", "▲ +8,2 %", "COMPLETE", "PH-02"),
    ("api-dat-sla-ty-le", "API đạt SLA", "—", "CHIA_SE", "AUTO", "%", "93,0", "≥ 95", "AT_RISK", "▼ −1,2", "COMPLETE", "PH-02"),
    ("giao-dich-thanh-toan-truc-tuyen", "Giao dịch thanh toán trực tuyến", "—", "CHIA_SE", "AUTO", "giao dịch", "5.912", "≥ 5.000", "ON_TRACK", "▲ +9,0 %", "COMPLETE", "PH-19"),
    ("danh-muc-quan-ly-tap-trung", "Danh mục quản lý tập trung", "KPI-10", "DU_LIEU", "AUTO", "%", "71,0", "≥ 80", "AT_RISK", "▲ +2,0", "COMPLETE", "PH-07"),
    ("tre-dong-bo-danh-muc-qg", "Trễ đồng bộ danh mục quốc gia", "KPI-11", "DU_LIEU", "AUTO", "giờ", "5,5", "≤ 24", "ON_TRACK", "▼ −0,5", "COMPLETE", "PH-07, PH-14"),
    ("diem-chat-luong-du-lieu", "Điểm chất lượng dữ liệu", "—", "DU_LIEU", "AUTO", "điểm", "78,6", "≥ 80", "AT_RISK", "▲ +1,8", "COMPLETE", "PH-08"),
    ("san-sang-data-plane", "Sẵn sàng mặt phẳng dữ liệu", "KPI-03", "VAN_HANH", "AUTO", "%", "99,92", "≥ 99,9", "ON_TRACK", "▲ +0,01", "COMPLETE", "PH-13"),
    ("tre-gateway-p95", "Độ trễ gateway P95", "KPI-04", "VAN_HANH", "AUTO", "ms", "182", "≤ 200", "ON_TRACK", "▼ −9", "COMPLETE", "PH-13"),
    ("ho-so-cap-do-phe-duyet", "Hồ sơ cấp độ ATTT đã phê duyệt", "KPI-08", "VAN_HANH", "MANUAL", "có/không", "Có", "Có", "ON_TRACK", "—", "COMPLETE", "Nhập tay"),
    ("bi-mat-ngoai-kho", "Bí mật nằm ngoài kho", "KPI-09", "VAN_HANH", "MIXED", "bí mật", "0", "0", "ON_TRACK", "— 0", "PARTIAL", "PH-12, SO xác nhận"),
    ("mttd", "Thời gian phát hiện sự cố MTTD", "KPI-15", "VAN_HANH", "AUTO", "phút", "7", "≤ 10", "ON_TRACK", "▼ −2", "COMPLETE", "PH-13"),
    ("mttr-muc-1", "Thời gian khắc phục sự cố mức 1 MTTR", "KPI-16", "VAN_HANH", "AUTO", "phút", "42", "≤ 30", "OFF_TRACK", "▲ +11", "COMPLETE", "PH-13"),
    ("thoi-gian-khoi-tao-tenant", "Thời gian khởi tạo tenant", "KPI-12", "KIEN_TRUC", "AUTO", "ngày", "3,5", "≤ 5", "ON_TRACK", "—", "COMPLETE", "PH-20"),
    ("so-giao-dien-quan-tri", "Số giao diện quản trị", "KPI-17", "KIEN_TRUC", "MANUAL", "giao diện", "1", "1", "ON_TRACK", "—", "COMPLETE", "Nhập tay"),
    ("diem-hai-long-sus", "Điểm hài lòng SUS", "KPI-18", "KIEN_TRUC", "MANUAL", "điểm", "—", "≥ 68", "NO_DATA", "—", "NO_DATA", "Nhập tay"),
    ("thanh-phan-da-danh-gia-tuan-thu", "Thành phần đã đánh giá tuân thủ", "—", "KIEN_TRUC", "AUTO", "%", "68,3", "≥ 80", "AT_RISK", "▲ +6,7", "COMPLETE", "Sổ kiến trúc"),
]
GSC = {"KET_NOI": (72.4, "4/4", "+2,1"), "CHIA_SE": (81.0, "7/7", "+1,4"), "DU_LIEU": (76.5, "3/3", "+0,9"), "VAN_HANH": (88.2, "6/6", "+0,3"), "KIEN_TRUC": (64.0, "3/4", "+3,2")}
WEIGHT = {"KET_NOI": 25, "CHIA_SE": 25, "DU_LIEU": 20, "VAN_HANH": 20, "KIEN_TRUC": 10}
TOTAL = [68, 69.2, 70.1, 70.8, 71.5, 72.4, 73.6, 74.2, 75.1, 75.9, 76.4, 76.8, 77.7]
GSER = {
    "KET_NOI": [58, 59, 61, 62, 63, 64, 66, 67, 68.4, 69.6, 70.2, 70.3, 72.4],
    "CHIA_SE": [72, 73, 74, 74.5, 75, 76, 77, 78, 78.6, 79.5, 80.2, 79.6, 81.0],
    "DU_LIEU": [66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 75.6, 75.6, 76.5],
    "VAN_HANH": [82, 83, 84, 84, 85, 85.5, 86, 86.5, 87, 87.6, 88, 87.9, 88.2],
    "KIEN_TRUC": [40, 42, 44, 46, 49, 52, 55, 57, 58, 60, 60.8, 60.8, 64.0],
}
TENDENCY = {"ON_TRACK": "pass", "AT_RISK": "warn", "OFF_TRACK": "fail", "NO_DATA": "none"}
