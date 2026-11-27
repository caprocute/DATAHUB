# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-08
Tính năng: TS-18-08 · Đăng ký nguồn DLQ và cổng phát lại

  @TC-18-024 @P1 @Dương
  Kịch bản: TC-18-024 Nguồn tự đăng ký khi khởi động và PA khai báo nguồn thủ công
    # Truy vết: FR-18-012 · API-18-031, 032, 034 · BR-18-019, 022 · UI-18-06
    # Mục đích: Chứng minh `dh-runtime` (PH-04) tự đăng ký cổng `KAFKA_TOPIC`, PH-19 đăng ký cổng `HTTP_PORT`, PA khai báo nguồn không tự đăng ký; danh sách nguồn hiện trần tốc độ.
    Biết T90; S-PH04, S-PH19 (`ops:dlq-write`); U-PA1 (`PERM-18-admin`).
    Khi S-PH04 `POST /ops/internal/v1/dlq-sources:register` `SRC-PH04`, cổng `KAFKA_TOPIC`, trần 50 mục mỗi giây.
    Và S-PH19 đăng ký `SRC-PH19`, cổng `HTTP_PORT` `/payment/internal/v1/inbox:replay`.
    Và S-PH04 gọi lại bước 1 với cùng nội dung.
    Và U-PA1 `POST /dlq-sources` `SRC-PH08-DQ` cổng `NONE`; mở UI-18-06.
    Thì bước 1, 2 `200`, nguồn `ACTIVE`. Bước 3 `200` không tạo bản ghi mới. Bước 4 `201`; UI-18-06 hiện ba nguồn, kiểu cổng và trần tốc độ.

  @TC-18-025 @P1 @Âm
  Kịch bản: TC-18-025 Sửa cổng sai, tạm ngừng nguồn và ghi DLQ từ nguồn tạm ngừng
    # Truy vết: FR-18-012, 014, 027 · API-18-033, 035, 064 · BR-18-019 · ERR-18-003, 026, 033
    # Mục đích: Chứng minh nguồn tạm ngừng bị từ chối ghi, nguồn cổng `NONE` không phát lại được, cổng khai sai bị chặn.
    Biết T90; `SRC-PH19` `ACTIVE`; `SRC-PH08-DQ` cổng `NONE` có mục `DLQ-PH08-1` `TRIAGED`.
    Khi U-PA1 `PATCH /dlq-sources/SRC-PH19` đặt cổng `HTTP_PORT` với đường dẫn tuyệt đối ra ngoài cụm.
    Và U-PA1 tạm ngừng `SRC-PH19` kèm lý do và `If-Match`.
    Và S-PH19 `POST /ops/internal/v1/dlq/messages` một mục hợp lệ.
    Và U-T90-TO `POST /dlq/messages/DLQ-PH08-1:replay`.
    Thì bước 1 `400` ERR-18-003. Bước 2 `200`, `SUSPENDED`. Bước 3 `403` ERR-18-026; PH-19 giữ mục ở inbox `FAILED` của mình (LP-18-04). Bước 4 `409` ERR-18-033.
