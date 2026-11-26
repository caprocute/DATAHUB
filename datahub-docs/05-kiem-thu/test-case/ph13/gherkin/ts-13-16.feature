# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-16
Tính năng: TS-13-16 · Truy vết và liên kết bằng `trace_id`

  @TC-13-052 @P1 @Dương
  Kịch bản: TC-13-052 Biểu đồ thác nước và liên kết bốn nguồn
    # Truy vết: FR-13-028, 029 · UC-13-18 · API-13-022, 023, 024 · UI-13-08 · LGC-BUS-038 · NFR-13-005
    Biết F-TRACE-MIX có một trace lỗi, có bản ghi kiểm toán cùng `trace_id`; U-T68-TO.
    Khi tìm trace theo mã luồng và trạng thái lỗi.
    Và mở trace; mở liên kết.
    Thì thác nước đủ span; `GET /correlations/{traceId}` trả log, chỉ số, bản ghi kiểm toán cùng `trace_id`; p95 ≤ 2 giây.

  @TC-13-053 @P1 @Âm
  Kịch bản: TC-13-053 Trace không có ở cả ba nguồn
    # Truy vết: FR-13-028, 029 · ERR-13-030, 001 · API-13-023, 024
    Biết `trace_id` ngẫu nhiên; trace của T01.
    Khi gọi `GET /traces/{id}` với `trace_id` không có; với trace của T01.
    Thì `404` ERR-13-030; trace của T01 có phản hồi giống hệt trừ `traceId` của yêu cầu.
