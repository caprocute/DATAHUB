# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-14
Tính năng: TS-04-14 · Gửi duyệt, rút lại

  @TC-04-082 @P1 @Dương
  Kịch bản: TC-04-082 Gửi duyệt thành công
    # Truy vết: FR-04-040 · BR-04-004, 016 · API-04-050 · UC-04-10 · EVT-04-03
    Biết F-HT v4 hợp lệ; một lần `MOCK` `PASSED` trên băm hiện tại; KS-01, KS-02 đạt trên băm hiện tại; IE1, IE2 là người đóng góp.
    Khi IE1 gọi `POST .../versions/4:submit` với `{"changeNote":"Thêm chuẩn hóa họ tên theo QĐ thử","suggestedReviewers":["U-T68-IA1"]}` và `If-Match`.
    Thì `200`, `status = PENDING_REVIEW`, `submittedBy = IE1`, danh sách người đóng góp chụp lại (IE1, IE2). EVT-04-03 phát, PH-18 tạo thông báo cho IA1. `allowedActions` của IE1 chỉ còn `WITHDRAW`. KT: có (`INT_VERSION_SUBMIT`).

  @TC-04-083 @P1 @Âm
  Kịch bản: TC-04-083 Gửi duyệt khi chưa chạy thử đạt trên đúng băm
    # Truy vết: FR-04-040 · BR-04-004 · API-04-050 · ERR-04-014
    Biết F-HT v4: lần `PASSED` gần nhất ở băm cũ; sau đó sửa một thuộc tính.
    Khi `:submit`.
    Và chạy `MOCK` đạt trên băm mới nhưng KS-02 `FAILED`, `:submit` lại.
    Thì cả hai trả `409` ERR-04-014; `detail` nêu rõ lý do (chưa có lần đạt trên băm hiện tại, hoặc ca KS-02 chưa đạt).

  @TC-04-084 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-084 Lần chạy mô phỏng không được tính
    # Truy vết: FR-04-040, 030 · BR-04-004 · ERR-04-014
    Biết F-HT v4 chỉ có lần chạy `SIMULATED` đạt trên băm hiện tại (từ ca sandbox không sẵn sàng); hoặc lần chạy cũ di trú từ W2 có `mode = SIMULATED`.
    Khi `:submit`.
    Thì `409` ERR-04-014. Câu truy vấn kiểm BR-04-004 (SDD §8.4) lọc `mode <> 'SIMULATED'` (kiểm bằng IT với dữ liệu di trú `ph04-9000`).

  @TC-04-085 @P1 @Âm
  Kịch bản: TC-04-085 Gửi duyệt sai trạng thái, thiếu ghi chú, còn lỗi
    # Truy vết: FR-04-040 · BR-04-017 · API-04-050 · ERR-04-005, 009, 025
    Biết v3 `APPROVED`; `tc-con-loi` có VR-05 `ERROR`.
    Khi `:submit` v3.
    Và `:submit` F-HT v4 với `changeNote = "sửa"`.
    Và `:submit` `tc-con-loi`.
    Thì lần lượt `409` ERR-04-005, `400` ERR-04-025, `422` ERR-04-009 kèm `findings`. Phiên bản giữ `DRAFT`. EVT: không.

  @TC-04-086 @P2 @Dương
  Kịch bản: TC-04-086 Rút lại yêu cầu duyệt
    # Truy vết: FR-04-040 · BR-04-017 · API-04-051
    Biết F-HT v4 `PENDING_REVIEW`.
    Khi IE1 gọi `:withdraw` với lý do hợp lệ.
    Và IE1 lưu nháp.
    Thì bước 1 trả `200`, `status = DRAFT`; thông báo cho người duyệt được thu hồi. Bước 2 trả `200`. KT: có (`INT_VERSION_WITHDRAW` có lý do).

  @TC-04-087 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-087 Phiên bản đã gửi duyệt không sửa được qua mọi kênh
    # Truy vết: FR-04-040 · BR-04-016 · API-04-022, 027, 044
    Biết F-HT v4 `PENDING_REVIEW`.
    Khi lưu nháp.
    Và nhập YAML.
    Và tạo ca kiểm thử mới.
    Và gọi `:discard`.
    Thì bước 1, 2, 4 trả `409` ERR-04-005. Bước 3 trả `201` (ca kiểm thử gắn luồng, không thuộc phiên bản), nhưng không thay đổi `contentHash` của v4.
