# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-32
Tính năng: TS-13-32 · Dịch vụ cho phân hệ khác

  @TC-13-090 @P1 @Dương
  Kịch bản: TC-13-090 PH-16 lấy số liệu tổng hợp, PH-18 lấy ngữ cảnh chẩn đoán
    # Truy vết: FR-13-056, 057 · UC-13-38, 39 · API-13-067, 068, 069
    Biết S-PH16; S-PH18; F-TRACE-MIX.
    Khi S-PH16 `POST /metrics:query`, `GET /metrics/summary`.
    Và S-PH18 `GET /diagnostics/{traceId}`.
    Thì `200`; số liệu khớp bộ phát; chẩn đoán gồm trace, log lỗi, cảnh báo liên quan; không dữ liệu Nhạy cảm.

  @TC-13-091 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-091 Scope thiếu, truy vấn sai, ngoài phạm vi tenant
    # Truy vết: FR-13-056, 057 · API-13-067, 068, 069 · ERR-13-044, 004, 005, 006, 030, 011, 015
    Biết S-PH16 gọi `diagnostics`; S-PH18 gọi `metrics:query`.
    Khi gọi chéo scope.
    Và truy vấn thiếu khoảng, quá khoảng, sai cú pháp; trace không có.
    Thì ERR-13-044; ERR-13-004; ERR-13-005; ERR-13-006; ERR-13-030.
