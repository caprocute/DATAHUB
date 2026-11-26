# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-21
Tính năng: TS-09-21 · Che log, trace và quét rò rỉ DLCN trong log

  @TC-09-072 @P1 @Dương @Bảo @mật
  Kịch bản: TC-09-072 Đặt cấu hình che log rồi quét thấy canary rò rỉ
    # Truy vết: FR-09-030 · API-09-105, 106, 107, 108 · UI-09-10 · BR-09-025 · NFR-09-014
    # Mục đích: Chứng minh quét phát hiện rò rỉ và kết quả không chứa giá trị rõ.
    Biết T90; F-LOG log 5 phút có `DH-CANARY-log-scan` và CCCD giả ở dạng rõ; U-T90-SO.
    Khi SO `PUT /log-masking-config` mức `SENSITIVE` ghi `[REDACTED]`.
    Và `POST /leak-scans`; `GET /leak-findings`.
    Và SO `POST /leak-findings/{id}:resolve`.
    Thì bước 2 có kết quả chỉ tên trường, dịch vụ, thời điểm; không giá trị rõ; thẻ UI-09-01 tăng. Bước 3 `RESOLVED`, KT: có.

  @TC-09-073 @P2 @Âm
  Kịch bản: TC-09-073 Cấu hình che log không hợp lệ
    # Truy vết: FR-09-030 · API-09-105 · ERR-09-044
    # Mục đích: Chứng minh không cho phép tắt che mức `SENSITIVE` ở log.
    Biết T90; U-T90-SO.
    Khi SO đặt mức `SENSITIVE` ghi giá trị rõ ở kênh `LOG`.
    Thì `422` ERR-09-044 nêu lý do; cấu hình cũ giữ.

  @TC-09-074 @P1 @Bảo @mật
  Kịch bản: TC-09-074 Quét canary toàn hệ không thấy DLCN ở log, trace, topic
    # Truy vết: NFR-09-014 · BR-09-025, 058 · FR-09-030
    # Mục đích: Chứng minh 0 giá trị `SENSITIVE` dạng rõ ngoài phiếu xem (NFR-09-014).
    Biết T90; canary đặt vào trường `SENSITIVE` của mọi ca ghi ở TS-09-01…34.
    Khi chạy bộ quét canary sau khi chạy toàn bộ mục 4.
    Thì 0 lần xuất hiện ở log 24 giờ, vết OTel, mọi topic `t90.privacy.*`, outbox, bảng `ph09_privacy.*`, tệp xuất.
