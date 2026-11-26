# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-26
Tính năng: TS-06-26 · Vận hành: dashboard, lịch job và nhật ký

  @TC-06-112 @P2 @Dương
  Kịch bản: TC-06-112 Dashboard khớp số liệu CSDL
    # Truy vết: FR-06-055 · API-06-085 · UI-06-01 · NFR-06-018 · ERR-06-112
    # Mục đích: Chứng minh chỉ số dashboard khớp đếm trực tiếp, theo FR-06-055.
    Biết T90 sau các kịch bản trước; VW.
    Khi `GET /dashboard/metrics`.
    Và so từng chỉ số với truy vấn `psql`.
    Thì số bản ghi vàng theo trạng thái, hàng đợi mở và quá hạn, tỷ lệ tự động, job gần nhất, lệch quốc gia khớp đúng; chèn cố ý hai bản ghi vàng cùng số định danh thì hiện thẻ cảnh báo ERR-06-112 "Phát hiện {n} bản ghi vàng cùng số định danh"; VW xem được, không có nút hành động.
    # Hậu điều kiện: Không đổi.

  @TC-06-113 @P2 @Dương @Âm
  Kịch bản: TC-06-113 Lịch job, chạy lại, hủy
    # Truy vết: FR-06-056 · API-06-041, 044, 086, 087 · ERR-06-006 · PERM-06-operate
    # Mục đích: Chứng minh đặt lịch, `:rerun`, `:cancel` và chặn hủy job đã xong, theo FR-06-056.
    Biết TO; job `RUNNING` và `SUCCEEDED`.
    Khi `PUT /job-schedules/BATCH_MATCH` cron `0 2 * * 0`.
    Và `:cancel` job `RUNNING`; `:rerun` job `FAILED`.
    Và `:cancel` job `SUCCEEDED`; DS1 `:cancel`.
    Thì bước 1 lịch lưu. Bước 2 `CANCELLED`, rồi job mới `QUEUED`. Bước 3 `409` ERR-06-006; DS1 ERR-00-403. KT: có (job-cancel, job-rerun).
    # Hậu điều kiện: Lịch tuần 02:00.

  @TC-06-114 @P1 @Dương @Bảo @mật
  Kịch bản: TC-06-114 Nhật ký xử lý và nhật ký truy cập
    # Truy vết: FR-06-057 · BR-06-013, 031 · API-06-088, 089 · UI-06-18 · PERM-06-audit-read
    # Mục đích: Chứng minh nhật ký có đủ trường, phạm vi quyền, giữ 12 tháng trực tuyến và 5 năm WORM, theo BR-06-031.
    Biết AU, SO, DS1; T90 có 100.000 dòng access_log.
    Khi AU `GET /access-logs` lọc theo người, mục đích, khoảng ngày.
    Và DS1 `GET /access-logs`.
    Và `GET /processing-logs` với DS1.
    Thì bước 1 mỗi dòng có người hoặc HTTT, mục đích, `goldenId`, số bản ghi, thời điểm, không có giá trị thuộc tính; lượt vượt ngưỡng hàng loạt gắn "vết đặc biệt". Bước 2 ERR-00-403. Bước 3 `200`. Cấu hình lưu giữ `access_log` 12 tháng và bản sao WORM 5 năm (kiểm cấu hình, không chờ thời gian).
    # Hậu điều kiện: Không đổi.
