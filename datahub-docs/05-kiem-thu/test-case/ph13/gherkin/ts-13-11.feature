# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-11
Tính năng: TS-13-11 · Tra cứu nhật ký kiểm toán

  @TC-13-038 @P1 @Dương
  Kịch bản: TC-13-038 Tra cứu theo người, hành động, khoảng thời gian kèm lý do
    # Truy vết: FR-13-020, 021 · UC-13-12 · API-13-074, 075 · UI-13-13 · BR-13-006, 007 · LGC-APIM-027
    Biết F-AUD-1K; U-T68-AU đã xác thực lại phiên.
    Khi mở UI-13-13, lọc `action = CATALOG.PUBLISH`, 24 giờ, nhập lý do 20 ký tự.
    Và mở một bản ghi; bấm "Xác minh băm".
    Thì `POST /records:search` `200`, phân trang con trỏ, có `totalEstimate`; chi tiết hiện `before`, `after` đã che; băm khớp neo gần nhất; KT: có (`AUDIT.QUERY`, `AUDIT.VIEW`) kèm `reason`.

  @TC-13-039 @P1 @Âm @Biên
  Kịch bản: TC-13-039 Tra cứu thiếu lý do, quá khoảng, quá rộng, sai định dạng
    # Truy vết: FR-13-020, 021 · API-13-074, 075 · ERR-13-012, 004, 005, 013, 029, 031, 028, 015
    Biết F-AUD-1K; U-T68-AU.
    Khi không `reason`; không `from`; khoảng 32 ngày; khoảng 13 tháng trước; số định danh sai định dạng; phạm vi trả về hơn 1 triệu bản ghi; phiên chưa xác thực lại; mở chi tiết `auditId` của T01 (404-ẩn).
    Thì lần lượt ERR-13-012; 004; 005 (`maxDays = 31`); 029; 031; 013 (kèm `recordCount`); 028. Mỗi lần thất bại vẫn có KT `AUDIT.QUERY` với `outcome = DENIED` hoặc `FAILED`.

  @TC-13-040 @P1 @Dương @Bảo @mật
  Kịch bản: TC-13-040 Tra theo đối tượng bị tra cứu, số định danh chỉ lưu HMAC
    # Truy vết: FR-13-023 · UC-13-14 · BR-13-005, 007 · API-13-074 · UI-13-13
    Biết F-AUD-PII có `object_key_hmac`; U-T68-SO nhập số định danh giả và căn cứ.
    Khi tra theo số định danh `DH-CANARY-subject`, kèm căn cứ.
    Và tìm số này trong log ứng dụng, bảng `ph13.*`, bản ghi kiểm toán.
    Thì kết quả đúng đối tượng; số định danh người tra nhập không được lưu, ghi log hay trả lại; bản ghi `AUDIT.QUERY` chỉ có HMAC và căn cứ; mồi sạch.

  @TC-13-041 @P2 @Biên
  Kịch bản: TC-13-041 Giới hạn đồng thời và thời gian chờ của truy vấn
    # Truy vết: FR-13-020 · ERR-13-011, 015 · NFR-13-009 · BR-13-029
    Biết U-T68-AU; truy vấn nặng giả lập.
    Khi chạy 6 truy vấn đồng thời.
    Và chạy truy vấn nặng quá 30 giây.
    Thì truy vấn thứ 6 `429` ERR-13-011 có `retryAfterSeconds`; truy vấn quá hạn `504` ERR-13-015; truy vấn thường p95 ≤ 3 giây (10.000 kết quả, 31 ngày).
