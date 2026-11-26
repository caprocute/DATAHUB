# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-26
Tính năng: TS-02-26 · Sẵn sàng, cách ly sự cố và phục hồi

  @TC-02-080 @P1 @Hiệu @năng
  Kịch bản: TC-02-080 Tắt `dh-connect` 24 giờ, API đang chạy vẫn phục vụ
    # Truy vết: NFR-02-008, 007 · FR-02-059, 036 · ERR-02-033, 034.
    Biết 20 API `PUBLISHED` đang nhận tải ổn định qua gateway.
    Khi tắt toàn bộ bản sao `dh-connect` (CX-01); giữ 24 giờ.
    Và thử công bố API mới; bật lại `dh-connect`.
    Thì tỷ lệ lỗi data plane không tăng; công bố mới `503` ERR-02-034; sau khi bật lại, đồng bộ cấu hình hồi phục ≤ 5 phút, không mất bản ghi.

  @TC-02-081 @P2 @Hiệu @năng
  Kịch bản: TC-02-081 Diễn tập DR: RPO ≤ 15 phút, RTO ≤ 4 giờ, đối soát sau khôi phục
    # Truy vết: NFR-02-009, 020, 018 · FR-02-060.
    Biết hai site; dữ liệu T68 đầy đủ; tải ghi liên tục.
    Khi chuyển site; đo thời điểm bản ghi cuối còn lại và thời gian dịch vụ hồi phục.
    Và chạy đối soát gateway.
    Thì mất dữ liệu ≤ 15 phút, hồi phục ≤ 4 giờ; đối soát không báo lệch ngoài vùng bị mất; hợp đồng `v1` không đổi (CI-5).

  @TC-02-149 @P1 @Âm @Khả @dụng
  Kịch bản: TC-02-149 Từng dịch vụ phụ thuộc ngừng: đọc vẫn chạy, ghi trả `503` đúng mã
    # Truy vết: NFR-02-007, 008 · FR-02-010, 011, 034, 053 · API-02-001, 014, 015, 042, 069 · ERR-02-034, 033.
    Biết bộ giả của PH-01, PH-04, PH-10, PH-12, PH-13, PH-14, PH-18, kho đối tượng, cổng API; tắt từng cái một.
    Khi với mỗi dịch vụ, tắt rồi chạy một lệnh đọc và một lệnh ghi phụ thuộc vào nó.
    Và bật lại, lặp lệnh có `Idempotency-Key`.
    Thì đọc danh mục (API-02-001) luôn `200`. Lệnh ghi cần dịch vụ phụ thuộc: `503` ERR-02-034 (ERR-02-033 với cổng API) kèm `retryAfterSeconds`; không có dữ liệu ghi dở. Sau khi bật lại, lặp lệnh thành công, không tạo trùng.

  @TC-02-150 @P1 @Khả @dụng
  Kịch bản: TC-02-150 Dừng tiến trình giữa lúc công bố: không mất, không công bố trùng
    # Truy vết: FR-02-036, 048 · API-02-047, 082 · UC-02-16 · NFR-02-008, 009 · ERR-02-033.
    Biết yêu cầu duyệt đã duyệt; M-GW; hộp thư đi (outbox) bật.
    Khi gọi `:publish`; ngay sau khi giao dịch xong, dừng bất thình lình pod `dh-connect` trước khi đẩy cấu hình.
    Và khởi động lại pod; quan sát outbox và M-GW.
    Và lặp lại dừng pod sau khi M-GW đã nạp nhưng trước khi nhận xác nhận.
    Thì bước 2: cấu hình được đẩy đúng một lần từ outbox, phiên bản chuyển `PUBLISHED` sau xác nhận, thông báo gửi một lần. Bước 3: M-GW nhận lần hai bỏ qua (cùng `configEpoch`), không route trùng.
