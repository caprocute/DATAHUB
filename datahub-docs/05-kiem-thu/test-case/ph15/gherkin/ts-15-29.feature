# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-29
Tính năng: TS-15-29 · Nhật ký kiểm toán và báo cáo sử dụng

  @TC-15-163 @P1 @Dương
  Kịch bản: TC-15-163 Tra cứu nhật ký theo hành động
    # Truy vết: FR-15-060 · UC-15-31 · API-15-128 · UI-15-26 · BR-15-024 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-SO, U-T68-AU; 20 lượt thử, 2 lần xem tài liệu nhạy cảm đã thực hiện.
    Khi `GET /admin/audit?hanh-dong=TRY_API&tu=…&den=…`.
    Và lọc `VIEW_SENSITIVE_DOCS`.
    Thì kết quả đúng số, có người, ứng dụng, API, `traceId`, kết quả; không có thân, bí mật; việc xem nhật ký tự ghi KT `VIEW_AUDIT`.

  @TC-15-164 @P1 @Dương
  Kịch bản: TC-15-164 Mỗi hành động của cổng đều có bản ghi kiểm toán
    # Truy vết: FR-15-060 · UC-15-31 · API-15-128 · BR-15-023 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết S-PH13 ghi nhận; kịch bản gọi từng hành động: `VIEW_SENSITIVE_DOCS`, `DOWNLOAD_SPEC`, `TRY_API`, `TRY_PRODUCTION`, `SECRET_ISSUED`, `SUBMIT_SUBSCRIPTION`, `SUBMIT_ONBOARDING`, `SUBMIT_PUBLICATION`, `LOCK_ACCOUNT`, `UNLOCK_ACCOUNT`, `CHANGE_SETTING`, `VIEW_AUDIT`, `EXPORT_AUDIT`.
    Khi thực hiện từng hành động một lần.
    Thì mỗi hành động đúng một bản ghi `PORTAL_*` ở PH-13 đủ trường FR-00-041 (người, tenant, thời điểm, đối tượng, kết quả, `traceId`), không chứa bí mật hay thân yêu cầu.

  @TC-15-165 @P2 @Dương
  Kịch bản: TC-15-165 Xuất nhật ký và báo cáo sử dụng
    # Truy vết: FR-15-060 · UC-15-31 · API-15-129, 130 · UI-15-26 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết khánh; dữ liệu 30 ngày.
    Khi `GET /admin/usage-report?khoang=30d`.
    Và `POST /admin/audit:export`.
    Thì báo cáo khớp số lượt thử, ứng dụng, tài khoản mới; tệp xuất có băm; KT: có (`EXPORT_AUDIT`).

  @TC-15-166 @P1 @Âm
  Kịch bản: TC-15-166 Khoảng quá dài, PH-13 lỗi, thiếu quyền, tenant khác
    # Truy vết: FR-15-060 · API-15-128, 129 · ERR-15-003, 005, 039 · NFR-15-017 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết khoảng 13 tháng; ngắt PH-13; An, Bình; U-T01-AU.
    Khi `GET /admin/audit?tu=` quá 12 tháng.
    Và gọi khi PH-13 ngắt.
    Và an, Bình gọi.
    Và U-T01-AU gọi qua tên miền T68.
    Thì `400` ERR-15-003 "Khoảng thời gian vượt 12 tháng"; `502` ERR-15-039; `403` ERR-15-005; bước 4 không có bản ghi nào của T68.
