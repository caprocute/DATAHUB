# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-35
Tính năng: TS-13-35 · Không lộ dữ liệu Nhạy cảm

  @TC-13-097 @P1 @Bảo @mật
  Kịch bản: TC-13-097 Dò mồi trên toàn bộ đầu ra của PH-13
    # Truy vết: NFR-13-021, 024 · BR-13-011, 035 · FR-13-005, 010 · ERR-13-105, 112
    Biết F-LOG-CAN, F-AUD-PII; mồi `DH-CANARY-sweep` ở thân, nhãn, tên trường, thông điệp lỗi.
    Khi chạy toàn bộ kịch bản TS-13-01…34 với mồi.
    Và dò mồi ở Loki, Mimir, Tempo, ClickHouse, bảng `ph13.*`, chuỗi kiểm toán, Kafka, tệp xuất, SIEM giả, log ứng dụng.
    Thì 0 lần thấy mồi (trừ bảng cách ly đã che); quét hằng ngày 1 % log và 100 % dòng `ERROR` sạch.

  @TC-13-098 @P2 @Bảo @mật
  Kịch bản: TC-13-098 Thông điệp lỗi không nêu tenant, scope, khóa
    # Truy vết: ERR-13-036, 044, 001 · BR-13-017
    Biết U-T68-TO, U-PO, S-PH16.
    Khi gây ERR-13-036, ERR-13-044, ERR-13-001 theo ba cách khác nhau.
    Thì thân lỗi không nêu tên tenant đích, scope thiếu, khóa; phản hồi 404-ẩn giống hệt trừ `traceId`.
