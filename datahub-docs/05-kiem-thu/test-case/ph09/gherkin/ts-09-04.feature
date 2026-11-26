# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-04
Tính năng: TS-09-04 · Quét phát hiện trường nghi dữ liệu cá nhân

  @TC-09-011 @P1 @Dương
  Kịch bản: TC-09-011 Quét cột có CCCD, MST, thẻ, điện thoại, thư điện tử
    # Truy vết: FR-09-005 · API-09-020, 022, 023, 024 · UI-09-04 · BR-09-006 · EVT-09-02
    # Mục đích: Chứng minh phát hiện bằng mẫu và kiểm tổng, kết quả vào hộp việc, không tự đổi phân loại (BR-09-006).
    Biết T98 F-SCAN: bảng 40 cột giả (8 cột có số định danh đúng, 4 cột nhiễu), 10.000 dòng.
    Khi U-T90-SO `POST /scans` cho bảng F-SCAN, `09.scan.confidence = 0,8`.
    Và hỏi `GET /scans/{id}` đến `COMPLETED`, rồi `GET /scans/{id}/findings`.
    Và SO `POST /findings/{fid}:resolve` hành động `CLASSIFY` một kết quả.
    Thì bước 2 8 kết quả `OPEN` đúng `detectorType` (`NATIONAL_ID_12`, `TAX_ID_10_13`, `BANK_CARD_LUHN`, `PHONE_VN`, `EMAIL`), mỗi kết quả có độ tin cậy và 3 dòng mẫu đã che, không giá trị rõ. EVT: `classification.scan-finished`. Bước 3 tạo đề xuất `PROPOSED`, phân loại hiện hành chưa đổi.

  @TC-09-012 @P2 @Âm
  Kịch bản: TC-09-012 Quét chồng, mẫu phát hiện nguy hiểm, kết quả đã xử lý
    # Truy vết: FR-09-005 · API-09-020, 026 · ERR-09-016, 017, 006
    # Mục đích: Chứng minh không chạy hai lượt trên cùng phạm vi và mẫu có thể làm chậm bị chặn.
    Biết T98; một lượt quét `RUNNING`; U-T90-SO; biểu thức `(a+)+$`.
    Khi SO `POST /scans` cùng phạm vi đang quét.
    Và SO `PUT /detectors/EMAIL` với biểu thức `(a+)+$`.
    Và SO `:resolve` kết quả đã `CLASSIFIED`.
    Thì bước 1 `409` ERR-09-017. Bước 2 `422` ERR-09-016, mẫu cũ giữ. Bước 3 `409` ERR-09-006.

  @TC-09-013 @P2 @Độ @chính @xác
  Kịch bản: TC-09-013 Tỷ lệ bỏ sót số định danh chuẩn ≤ 1 %
    # Truy vết: FR-09-005 · NFR-09-009 · API-09-020
    # Mục đích: Đo độ phủ của bộ mẫu và kiểm tổng.
    Biết T98 bộ mẫu chuẩn 5.000 giá trị CCCD, MST, thẻ, điện thoại hợp lệ chèn vào 500 cột; giả định theo Q09-41.
    Khi chạy `POST /scans` cho 500 cột, `09.scan.sample-rows = 10.000`.
    Và so kết quả với danh sách chèn.
    Thì bỏ sót ≤ 1 % số cột chứa số định danh chuẩn; quét xong ≤ 10 phút (4 vCPU).
