# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-16
Tính năng: TS-20-16 · Xem sử dụng tài nguyên và lập báo cáo sử dụng

  @TC-20-070 @P1 @Dương
  Kịch bản: TC-20-070 Xem sử dụng toàn nền tảng, một tenant, và của tỉnh
    # Truy vết: FR-20-030 · UC-20-16 · API-20-056, 057, 140, 141 · NFR-20-006 · UI-20-06, 13 · `PERM-20-read`, `PERM-20-usage-read`
    Biết `U-PA1`, `U-PO`, `U-T96-TA`, `U-T90-TO`, `U-T90-AU`; F-USAGE (30 ngày `T96`).
    Khi `GET P/usage?from=2026-11-01&to=2026-11-27&granularity=DAY&resource=API_RPS&sort=-percent`
    Và `GET P/tenants/T96/usage?from=2026-11-20&to=2026-11-27&granularity=HOUR`
    Và `U-T96-TA` gọi `GET T/usage` và `GET T/quotas`
    Và `U-T90-TO`, `U-T90-AU` gọi `GET T/usage`
    Và mở `/nen-tang/su-dung` và `/quan-tri/cai-dat-tinh/su-dung`
    Thì bước 1 xếp tenant theo phần trăm giảm dần, `T96` ở đầu với 80 %. Bước 2 chuỗi theo giờ đủ. Bước 3 chỉ số liệu và hạn mức hiệu lực của `T96`, kèm cảnh báo mở. Bước 4 `200`. Bước 5 UI-20-06 và UI-20-13 hiện thẻ chỉ số, biểu đồ có bảng số thay thế, p95 danh sách ≤ 1,5 giây (NFR-20-006).

  @TC-20-071 @P2 @Âm
  Kịch bản: TC-20-071 Khoảng thời gian quá dài, tham số sai, mã tenant không có, vai trò không đủ
    # Truy vết: FR-20-030 · API-20-056, 057, 140, 141 · ERR-20-002, ERR-20-004, ERR-20-032, ERR-00-403
    Biết `U-PA1`, `U-T90-TA`, `U-T90-VW`.
    Khi `GET P/usage?from=2020-01-01&to=2026-11-27`
    Và `GET P/usage?granularity=NAM&resource=KHONG_CO`
    Và `GET P/tenants/T89/usage`
    Và `U-T90-VW` gọi `GET T/usage`
    Và `U-T90-TA` gọi `GET T/usage?tenantCode=T91`
    Thì bước 1 `400` `ERR-20-032`. Bước 2 `400` `ERR-20-004`. Bước 3 `404` `ERR-20-002`. Bước 4 `403` `ERR-00-403`. Bước 5 `200` nhưng chỉ số liệu `T90`, bỏ qua tham số `tenantCode` (không rò rỉ `T91`).

  @TC-20-072 @P2 @Dương
  Kịch bản: TC-20-072 Lập báo cáo sử dụng theo kỳ, tải tệp
    # Truy vết: FR-20-031 · API-20-060, 061, 062 · UI-20-06 · `PERM-20-read`
    Biết `U-PA1`; F-USAGE; kỳ tháng 10/2026.
    Khi `POST P/usage-reports` với `scope = ALL_TENANTS`, `period = 2026-10`, `format = XLSX`, kèm `Idempotency-Key`
    Và `GET P/usage-reports?scope=ALL_TENANTS&status=READY`
    Và `GET P/usage-reports/{reportId}/file`
    Và lập tiếp `CSV` và `PDF` cho `scope = T96`
    Thì bước 1 `202`. Bước 2 báo cáo `READY`. Bước 3 tải được tệp XLSX có một dòng mỗi tenant và tài nguyên, tổng khớp tổng ảnh chụp giờ của F-USAGE. Bước 4 hai tệp CSV, PDF đúng nội dung. Tệp không có dữ liệu cá nhân.

  @TC-20-073 @P2 @Âm
  Kịch bản: TC-20-073 Báo cáo không lập được, định dạng sai, báo cáo không có
    # Truy vết: FR-20-031 · API-20-060, 062 · ERR-20-002, ERR-20-004, ERR-20-009, ERR-20-032, ERR-20-066
    Biết `U-PA1`; kỳ `2026-12` chưa có số liệu; `T89` không tồn tại.
    Khi `POST P/usage-reports` với `period = 2026-12`
    Và `POST P/usage-reports` với `format = DOCX`
    Và `POST P/usage-reports` với `scope = T89`
    Và `GET P/usage-reports/khong-co/file`
    Và `POST` lặp cùng khóa chống lặp khác thân
    Và `POST` với `period` dài hơn 24 tháng
    Thì bước 1 `422` `ERR-20-066` ("Không lập được báo cáo sử dụng: không có số liệu."). Bước 2 `400` `ERR-20-004`. Bước 3 `404` `ERR-20-002`. Bước 4 `404` `ERR-20-002`. Bước 5 `409` `ERR-20-009`. Bước 6 `400` `ERR-20-032`.
