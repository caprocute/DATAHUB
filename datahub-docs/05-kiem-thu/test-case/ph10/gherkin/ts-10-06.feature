# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-06
Tính năng: TS-10-06 · Lược đồ sự kiện: soạn, kiểm tra, duyệt

  @TC-10-027 @P1 @Dương
  Kịch bản: TC-10-027 Soạn phiên bản lược đồ mới và kiểm tra
    # Truy vết: FR-10-017, 018 · API-10-023, 026 · UI-10-08 · UC-10-06 · LGC-HUB-009
    # Mục đích: Chứng minh luồng thành công, theo FR-10-017 (Soạn và kiểm tra lược đồ).
    Biết U-T68-IE1; TP-CP; F-AV-ADD.
    Khi Ở UI-10-08 dán F-AV-ADD, ghi chú thay đổi "Thêm ngành nghề kinh doanh"; bấm "Kiểm tra".
    Và `GET /topics/{TP-CP}/schema/versions/4`.
    Thì bước 1 gọi `POST …/schema/versions` (`201`) rồi `:check` (`200`): cú pháp đạt, `compatibilityReport.compatible = true` theo `BACKWARD`, cảnh báo quy ước (nếu có) không chặn, `piiFindings` rỗng. Bước 2 `status = DRAFT`, `contentHash` là SHA-256 của nội dung. Apicurio chưa có phiên bản 4 (chạy thử `dryRun`). KT: có (băm, kết quả kiểm tra).
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-028.

  @TC-10-028 @P1 @Âm
  Kịch bản: TC-10-028 Phiên bản sai định dạng, quá lớn, thiếu ghi chú, đang có bản chờ duyệt
    # Truy vết: FR-10-017 · API-10-023, 025 · ERR-10-003, 006, 015, 020
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-017 (Soạn và kiểm tra lược đồ).
    Biết U-T68-IE1; TP-CP định dạng Avro; phiên bản 4 từ TC-10-027 đã gửi duyệt.
    Khi tạo phiên bản JSON Schema F-JS1 cho TP-CP.
    Và tạo phiên bản Avro 300 KiB.
    Và tạo phiên bản không có `changeNote`.
    Và tạo phiên bản thứ hai khi v4 đang `PENDING_APPROVAL`.
    Thì bước 1 `422` ERR-10-020 (khác định dạng đã có). Bước 2 `400` ERR-10-003 với `errors[].field = content` (vượt 256 KiB, FR-10-017). Bước 3 `400` ERR-10-003. Bước 4 `409` ERR-10-006.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-029 @P1 @Dương
  Kịch bản: TC-10-029 Gửi duyệt và duyệt phiên bản lược đồ
    # Truy vết: FR-10-019 · API-10-027, 059 · UI-10-13 · EVT-10-05 · UC-10-06
    # Mục đích: Chứng minh luồng thành công, theo FR-10-019 (Gửi duyệt và duyệt phiên bản lược đồ).
    Biết U-T68-IE1 gửi, U-T68-IA1 duyệt; v4 `DRAFT` đã kiểm tra trong 24 giờ.
    Khi `POST …/schema/versions/4:submit`.
    Và IA1 mở yêu cầu `SCHEMA_VERSION` ở UI-10-13: xem khác biệt, danh sách bên nhận hiện có; duyệt.
    Và PB-DKKD phát sự kiện có trường `nganhNghe` với `dataschema` trỏ v4.
    Thì bước 1 `200`, v4 `PENDING_APPROVAL`. Bước 2 v4 `ENABLED`, có `apicurioGlobalId`, `latestVersionNo = 4`; EVT: `schema.version-enabled`. Bước 3 cổng nhận sau ≤ 60 giây (đệm làm mới bằng EVT-10-05); SUB-PUSH vẫn giải tuần tự được sự kiện v1…v3 cũ. KT: có.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-030 @P1 @Âm
  Kịch bản: TC-10-030 Bốn mắt, quá hạn kiểm tra, không tương thích khi duyệt
    # Truy vết: FR-10-019 · API-10-027, 059 · ERR-10-008, 016 · BR-10-010
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-019 (Gửi duyệt và duyệt phiên bản lược đồ).
    Biết U-T68-TA soạn v5; U-T68-IA1; F-AV-BRK.
    Khi U-T68-TA gửi duyệt rồi tự duyệt v5.
    Và soạn v6 bằng F-AV-BRK, `:submit`.
    Và soạn v7 hợp lệ, kiểm tra, đặt đồng hồ SIT +25 giờ rồi `:submit`.
    Thì bước 1 duyệt trả `403` ERR-10-008. Bước 2 `409` ERR-10-016 kèm báo cáo (trường `ngayCap` không mặc định, `phienBan` đổi kiểu). Bước 3 hệ thống chạy lại kiểm tra trước khi gửi (kết quả 24 giờ hết hạn), gửi thành công nếu vẫn tương thích. Apicurio không có v6.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-031 @P2 @Dương @Âm
  Kịch bản: TC-10-031 Lịch sử phiên bản, so sánh, tải lược đồ
    # Truy vết: FR-10-020 · API-10-021, 022, 024, 030 · UI-10-08 · ERR-10-049 · LGC-HUB-009
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-020 (Xem lịch sử phiên bản, so sánh và tải lược đồ).
    Biết U-T68-VW; TP-CP v1…v4.
    Khi `GET …/schema/versions`.
    Và `GET …/schema/diff?from=1&to=4`.
    Và `GET …/schema/diff?from=1&to=99`.
    Và Ở UI-10-08 tải `.avsc` của v2, xem ví dụ sự kiện sinh từ lược đồ.
    Thì bước 1 bốn phiên bản kèm người duyệt, ngày, ghi chú. Bước 2 khác biệt cấu trúc liệt kê trường thêm `nganhNghe`. Bước 3 404-ẩn. Bước 4 tệp đúng nội dung v2 (so băm); ví dụ dùng giá trị giả lập, không có dữ liệu thật.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-032 @P2 @Dương @Âm
  Kịch bản: TC-10-032 Ngừng khuyến nghị và vô hiệu phiên bản lược đồ
    # Truy vết: FR-10-022 · API-10-028, 029 · ERR-10-006, 009 · BR-10-015 · EVT-10-02
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-022 (Ngừng khuyến nghị và vô hiệu phiên bản lược đồ).
    Biết U-T68-IE1, U-T68-IA1; TP-CP v1…v4; bản tin cuối theo v1 ghi nhận 10 ngày trước, lưu giữ 7 ngày; bản tin theo v2 còn trong lưu giữ.
    Khi `:deprecate` v1; phát một sự kiện theo v1.
    Và `:deprecate` v4 (mới nhất).
    Và đề nghị `:disable` v2.
    Và đề nghị `:disable` v1, IA1 duyệt.
    Thì bước 1 v1 `DEPRECATED` ở cả PH-10 và Apicurio; phát được nhưng phản hồi có tiêu đề `Deprecation`. Bước 2 `409` ERR-10-006. Bước 3 `409` ERR-10-006 kèm thời điểm bản tin cuối dùng v2. Bước 4 v1 `DISABLED`; EVT: `topic.changed`.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
