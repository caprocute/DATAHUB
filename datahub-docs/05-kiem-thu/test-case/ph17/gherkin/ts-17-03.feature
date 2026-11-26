# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-03
Tính năng: TS-17-03 · Bật chính sách dùng mô hình ngoài và danh sách trắng nhà cung cấp

  @TC-17-009 @P1 @Dương
  Kịch bản: TC-17-009 Bật mô hình ngoài bằng đề nghị riêng rồi thêm nhà cung cấp vào danh sách trắng
    # Truy vết: FR-17-003 · API-17-003, 006, 010, 011, 032 · BR-17-004, 013 · EVT-17-01, 04, 06 · UI-17-06, 07
    # Mục đích: Chứng minh trình tự ba bước: đề nghị `EXTERNAL_ON` được duyệt, nhà cung cấp có cam kết, danh sách trắng có hiệu lực.
    Biết T90 bật; nhà cung cấp `P-EXT-VN` (ngoài, `ACTIVE`, FQDN trong nước, cam kết còn hạn 12 tháng) do U-PA1 khai báo; U-T90-TA1, TA2.
    Khi TA1 `GET /policy` kiểm `17.model.external-allowed`.
    Và TA1 `POST /policy/provider-grants` cho `P-EXT-VN` khi chưa có đề nghị.
    Và TA1 `POST /policy/changes` `EXTERNAL_ON`; TA2 `:approve`.
    Và TA1 `POST /policy/provider-grants` cho `P-EXT-VN`.
    Và TA1 `GET /policy/provider-grants`.
    Thì bước 1 `false`. Bước 2 `409` ERR-17-017 hoặc từ chối vì chưa có đề nghị đã duyệt. Bước 3 `APPROVED`, `17.model.external-allowed = true`, KT: có, EVT: `assist.policy-change.decided`. Bước 4 `201`, KT: có. Bước 5 thấy `P-EXT-VN`; phiên bản mô hình của nhà cung cấp này vẫn chưa gọi được cho tới khi `APPROVED` và bật (FR-17-009, 010).

  @TC-17-010 @P1 @Âm
  Kịch bản: TC-17-010 Nhà cung cấp thiếu cam kết hoặc cam kết hết hạn không vào danh sách trắng
    # Truy vết: FR-17-003, 007 · API-17-011, 032 · BR-17-004, 013 · ERR-17-016, 017, 026 · EVT-17-06
    # Mục đích: Chứng minh cam kết lưu dữ liệu trong nước và không huấn luyện là điều kiện bắt buộc và hết hạn thì tự đình chỉ.
    Biết T90 có `EXTERNAL_ON` đã duyệt; `P-EXT-NN` (ngoài, không có cam kết); `P-EXT-VN` có cam kết hết hạn sau 2 ngày; đồng hồ giả T95.
    Khi TA1 `POST /policy/provider-grants` cho `P-EXT-NN`.
    Và TA1 `POST /policy/provider-grants` cho nhà cung cấp chưa nằm trong danh sách của nền tảng.
    Và đẩy đồng hồ quá ngày hết hạn cam kết của `P-EXT-VN`; U-T90-IE gửi câu hỏi được định tuyến tới mô hình của nhà cung cấp này.
    Thì bước 1 `422` ERR-17-016. Bước 2 `409` ERR-17-017. Bước 3 nhà cung cấp tự `SUSPENDED`, EVT: `assist.provider.state-changed`, SO nhận cảnh báo, lời gọi bị từ chối (dùng mô hình nội bộ hoặc `503` ERR-17-036 nếu không còn mô hình hợp lệ), không có gói tin ra egress.

  @TC-17-011 @P2 @Dương @Âm
  Kịch bản: TC-17-011 Gỡ nhà cung cấp khỏi danh sách trắng có hiệu lực ngay
    # Truy vết: FR-17-003 · API-17-012 · BR-17-004 · EVT-17-01 · ERR-17-017
    # Mục đích: Chứng minh gỡ khỏi danh sách trắng chặn lời gọi đang chạy và mô hình ngoài không còn được định tuyến.
    Biết T90 có `P-EXT-VN` trong danh sách trắng, mô hình ngoài `MV-EXT-1` `APPROVED` và được bật; U-T90-TA1, U-T90-IE.
    Khi IE gửi câu hỏi buộc dùng `MV-EXT-1` (chính sách năng lực `SEARCH` ưu tiên ngoài), ghi nhận `200`.
    Và TA1 `DELETE /policy/provider-grants/{grantId}`.
    Và IE gửi lại câu hỏi như bước 1 sau 60 giây.
    Và TA1 `DELETE` lần hai cùng `grantId`.
    Thì bước 1 `200`, vết lời gọi ghi `MV-EXT-1`. Bước 2 `200`, KT: có, EVT: `assist.config.changed`. Bước 3 không lời gọi nào tới `MV-EXT-1` (vết lời gọi mới là mô hình nội bộ hoặc `409` ERR-17-017 theo cấu hình ưu tiên). Bước 4 `404` ERR-17-001.
