# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-22
Tính năng: TS-17-22 · Giải thích lỗi theo trace_id, bản tin DLQ và che dữ liệu cá nhân trong log

  @TC-17-072 @P1 @Dương @Bảo_mật
  Kịch bản: TC-17-072 Giải thích lỗi theo trace_id bằng token người dùng, log đã che
    # Truy vết: FR-17-037, 041 · API-17-114, 119 · BR-17-051, 052, 055 · NFR-17-023 · UI-17-03
    # Mục đích: Chứng minh BR-17-051, 052: log lấy qua PH-13 bằng token người dùng, đã che DLCN, cắt tối đa số dòng.
    Biết T90 bật `EXPLAIN`; `trace_id` `0000000000000000000000000000a001` có 350 dòng log (F-LOG) chứa CCCD giả `001090000101`, `0912345678`, `an.nguyen@example.test`, canary `DH-CANARY-trace` và trường mức `RESTRICTED`; U-T90-TO có quyền xem log ở PH-13.
    Khi TO `POST /redaction:preview` với `trace_id`.
    Và TO `POST /explanations/traces`.
    Và đọc bản ghi prompt đã che của lượt.
    Thì bước 1 xem trước nội dung sẽ gửi: CCCD, điện thoại, thư đã che; trường `RESTRICTED` bị loại hoàn toàn; tối đa `17.explain.log-lines-max` (200) dòng. Bước 2 `200` giải thích có trích dẫn dòng log. Bước 3 0 canary, 0 mẫu DLCN dạng rõ; log gọi PH-13 mang token của TO (`act` = `dh-assist`).

  @TC-17-073 @P1 @Âm @Bảo_mật
  Kịch bản: TC-17-073 trace_id sai định dạng, quá phạm vi, người dùng không có quyền xem log
    # Truy vết: FR-17-037 · API-17-114 · BR-17-051 · ERR-17-060, 061, 062
    # Mục đích: Chứng minh ERR-17-060, 061, 062.
    Biết T90; U-T90-IE không có quyền xem log PH-13; U-T90-TO có.
    Khi TO gửi `trace_id = "xyz"`.
    Và TO gửi `trace_id` hợp lệ nhưng chọn 300 dòng và khoảng 120 phút.
    Và IE gửi `trace_id` hợp lệ.
    Thì bước 1 `422` ERR-17-061. Bước 2 `422` ERR-17-062 (tối đa 200 dòng, 60 phút). Bước 3 `403` ERR-17-060, không có dữ liệu log nào được lấy để giải thích.

  @TC-17-074 @P2 @Dương @Âm @Bảo_mật
  Kịch bản: TC-17-074 Giải thích bản tin DLQ của PH-18 và đề xuất hướng xử lý
    # Truy vết: FR-17-038, 041 · API-17-115, 116 · BR-17-051, 052 · UI-17-03
    # Mục đích: Chứng minh FR-17-038: bản tin DLQ lấy bằng quyền người dùng và che nội dung nghiệp vụ.
    Biết PH-18 WireMock có bản tin DLQ `DLQ-7` lỗi lược đồ, thân chứa họ tên và CCCD giả; U-T90-TO có quyền; U-T90-IE không có.
    Khi TO `POST /explanations/dlq-messages` cho `DLQ-7`.
    Và IE gọi lại cho `DLQ-7`.
    Thì bước 1 `200`: nguyên nhân (lỗi lược đồ), hướng xử lý, không có họ tên và CCCD dạng rõ ở prompt, kết quả hay nhật ký. Bước 2 `403` ERR-17-060.

  @TC-17-075 @P1 @Độ_chính_xác @Bảo_mật
  Kịch bản: TC-17-075 Bộ che DLCN: bỏ sót ≤ 0,5 % và 0 số định danh, che nhầm ≤ 2 % trên 2.000 chuỗi mẫu
    # Truy vết: FR-17-041, 046 · BR-17-055 · NFR-17-009 · API-17-119
    # Mục đích: Đo NFR-17-009 trên bộ mẫu chuẩn tổng hợp, kể cả khi PH-09 không khả dụng (chỉ dùng bộ mẫu cục bộ).
    Biết bộ F-PII 2.000 chuỗi tổng hợp: 400 CCCD 12 số, 300 điện thoại, 300 thư, 200 số tài khoản, 800 chuỗi sạch có số gần giống (mã hồ sơ 12 số, ngày giờ).
    Khi chạy bộ che trên 2.000 chuỗi khi PH-09 sẵn sàng.
    Và lặp lại khi PH-09 trả `503`.
    Thì tỷ lệ bỏ sót ≤ 0,5 % tổng, 0 bỏ sót số định danh 12 số; che nhầm chuỗi sạch ≤ 2 %. Bước 2 vẫn che bằng bộ mẫu cục bộ, kết quả không kém hơn.
