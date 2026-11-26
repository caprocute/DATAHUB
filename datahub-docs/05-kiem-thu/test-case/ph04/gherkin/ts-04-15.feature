# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-15
Tính năng: TS-04-15 · Duyệt bốn mắt và so sánh phiên bản

  @TC-04-088 @P1 @Dương
  Kịch bản: TC-04-088 Duyệt phiên bản
    # Truy vết: FR-04-041 · BR-04-005 · API-04-053, 025, 052 · UI-04-14 · UC-04-11 · EVT-04-04.
    Biết F-HT v4 `PENDING_REVIEW` (người tạo IE1, đóng góp IE2); IA1.
    Khi IA1 gọi `GET /reviews`.
    Và IA1 gọi `GET .../versions/4/diff?base=3&markViewed=true`.
    Và IA1 gọi `:review` với `{"decision":"APPROVE","comment":"Đúng đặc tả","checklist":{"c1":true,"c2":true,"c3":true,"c4":true}}`.
    Thì bước 1: có F-HT v4, `canDecide = true`, `changeSummary` đúng. Bước 2 trả `200` với khác biệt theo chặng. Bước 3 trả `200`, `status = APPROVED`, `approvedBy = IA1`; EVT-04-04 phát. KT: có (`INT_VERSION_APPROVE` với checklist).

  @TC-04-089 @P1 @Dương
  Kịch bản: TC-04-089 Yêu cầu sửa có ý kiến theo chặng
    # Truy vết: FR-04-041 · API-04-052 · UI-04-14 · EVT-04-05.
    Biết như trên.
    Khi IA1 gọi `:review` với `decision = REQUEST_CHANGES`, `comment`, `nodeComments = [{"nodeId":"transform-1","text":"Thiếu chuẩn hóa dấu"}]`.
    Và IE1 mở trình thiết kế.
    Thì bước 1: `status = CHANGES_REQUESTED`; EVT-04-05 phát. Bước 2: chặng `transform-1` có huy hiệu ý kiến, bảng Vấn đề có mục "Ý kiến người duyệt"; phiên bản sửa được.

  @TC-04-090 @P2 @Dương
  Kịch bản: TC-04-090 Gửi duyệt lại sau khi sửa
    # Truy vết: FR-04-040, 041 · API-04-050.
    Biết F-HT v4 `CHANGES_REQUESTED`.
    Khi IE1 sửa, chạy thử đạt, `:submit`.
    Thì `200`, `status = PENDING_REVIEW`; lịch sử duyệt giữ ý kiến vòng trước.

  @TC-04-091 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-091 Tự duyệt bị chặn với người tạo, người đóng góp, người gửi
    # Truy vết: FR-04-041 · BR-04-005 · API-04-052 · ERR-04-015.
    Biết ba phiên bản `PENDING_REVIEW` trong WS-HOTICH: (a) do IA2 tạo; (b) do IE1 tạo, IA2 đóng góp một lần lưu; (c) do IE1 tạo, IA2 gửi duyệt. IA2 có cả vai trò IA và IE.
    Khi IA2 xem diff và `:review` APPROVE trên (a), (b), (c).
    Và xem `GET /reviews` của IA2.
    Thì bước 1: cả ba trả `403` ERR-04-015, trạng thái không đổi; KT: có (`INT_REVIEW_DENIED`, nhật ký an ninh). Bước 2: ba mục có `canDecide = false`; trên giao diện nút "Duyệt" ẩn kèm lý do.

  @TC-04-092 @P1 @Âm
  Kịch bản: TC-04-092 Duyệt khi chưa xem so sánh, thiếu checklist, sai trạng thái
    # Truy vết: FR-04-041, 043 · BR-04-017 · API-04-052 · ERR-04-005, 025.
    Biết F-HT v4 `PENDING_REVIEW`; `tc-nhap` v1 `DRAFT`.
    Khi IA1 `:review` APPROVE khi chưa gọi diff.
    Và IA1 xem diff rồi APPROVE thiếu mục `c3`.
    Và IA1 REQUEST_CHANGES không có `comment`.
    Và IA1 APPROVE `tc-nhap` v1.
    Thì bước 1 trả `409` ERR-04-005 ("chưa xem so sánh"). Bước 2, 3 trả `400` ERR-04-025. Bước 4 trả `409` ERR-04-005.

  @TC-04-093 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-093 Duyệt bởi người ngoài không gian hoặc thiếu quyền
    # Truy vết: FR-04-041, 007 · BR-04-021 · ERR-04-003, 045.
    Biết IA thứ ba `U-T68-IA3` không là thành viên WS-HOTICH; IE2 (không có `PERM-04-publish`).
    Khi IA3 `:review` F-HT v4.
    Và IE2 `:review` F-HT v4.
    Thì bước 1 trả `403` ERR-04-003. Bước 2 trả 403-PQ.

  @TC-04-094 @P2 @Bảo @mật
  Kịch bản: TC-04-094 Xác thực lại khi duyệt
    # Truy vết: FR-04-041, 084 · API-04-052 · ERR-04-044.
    Biết `04.review.require-reauth = true`; token của IA1 có `auth_time` cách 10 phút.
    Khi `:review` APPROVE.
    Và trên giao diện, đăng nhập lại trong cửa sổ bật, duyệt lại.
    Thì bước 1 trả `401` kèm `WWW-Authenticate: Bearer error="insufficient_user_authentication", max_age=300`, `code = ERR-04-044`. Bước 2 trả `200`.

  @TC-04-095 @P1 @Dương
  Kịch bản: TC-04-095 So sánh hai phiên bản bất kỳ
    # Truy vết: FR-04-043 · API-04-025 · UI-04-16.
    Biết F-HT v2, v3, v4.
    Khi gọi `diff` v4 với `base=2`.
    Và mở UI-04-16 chế độ "Sơ đồ" và "YAML".
    Và gọi `diff` v4 với `base=99`.
    Thì bước 1: `nodes[]` có `ADDED`, `REMOVED`, `MODIFIED` (kèm `fields`), `MOVED` khi chỉ đổi vị trí trong route; khác biệt bố cục không tính. Bước 2: sơ đồ tô xanh, đỏ, vàng; YAML hai cột cuộn đồng bộ. Bước 3 trả `404` ERR-04-004.

  @TC-04-193 @P1 @Dương @Âm
  Kịch bản: TC-04-193 Đầu cuối gửi duyệt và duyệt bốn mắt theo trình tự SDD
    # Truy vết: FR-04-040, 041 · BR-04-004 · UC-04-10, 11 · API-04-050, 052 · EVT-04-03, 04 · ERR-04-015.
    Biết U-T68-IE1 tạo F-HT v4 và có lần chạy `PASSED` trên `contentHash` hiện tại, mọi ca kiểm thử đạt; U-T68-IA2 là người đóng góp của v4; U-T68-IA1 (D03-02-PH04 §9.1, hình gửi duyệt và duyệt bốn mắt).
    Khi IE1 gọi `:submit` với ghi chú.
    Và đọc `flow_version` và `ph04.outbox`.
    Và IA2 mở so sánh rồi gọi `:review` `APPROVE` có đủ checklist.
    Và IA1 mở so sánh (`markViewed=true`) rồi gọi `:review` `APPROVE` có đủ checklist.
    Thì bước 1 trả `200` sau khi kiểm mức `SUBMIT`. Bước 2: `status = PENDING_REVIEW`, `submitted_hash` bằng `contentHash` của lần chạy đạt, một dòng outbox EVT-04-03. Bước 3 trả `403` ERR-04-015 ("Bạn đã tạo, đóng góp hoặc gửi duyệt phiên bản này nên không thể tự duyệt. Cần một người duyệt khác."), phiên bản giữ `PENDING_REVIEW`, không có EVT-04-04. Bước 4 trả `200`, `APPROVED`: máy chủ so băm hiện tại với `submitted_hash`, cập nhật có điều kiện `status = PENDING_REVIEW`, ghi `review`, phát EVT-04-04. Ba chốt ở máy chủ được chứng minh: lần chạy gắn đúng băm, người duyệt ngoài tập người đã chạm phiên bản, băm lúc duyệt bằng băm lúc gửi.

  @TC-04-194 @P3 @Dương @Âm
  Kịch bản: TC-04-194 Trạng thái màn So sánh phiên bản
    # Truy vết: FR-04-043 · UI-04-16 · ERR-04-001, 004.
    Biết U-T68-IA1; F-HT v3 và bản sao giống hệt v3 là v5 (tạo trong ca); YAML-200 làm v6; U-T01-IE.
    Khi IA1 mở UI-04-16 với Từ v3, Đến v5.
    Và chọn Đến v99.
    Và chọn Từ v3, Đến v6.
    Và U-T01-IE mở URL so sánh của F-HT ở T68.
    Thì bước 1: trạng thái rỗng "Hai phiên bản giống hệt nhau." Bước 2: ST-05 với câu "Không tìm thấy phiên bản v99 của luồng này." (ERR-04-004). Bước 3: khác biệt hơn 500 dòng YAML nên mặc định chế độ Tóm tắt kèm cảnh báo hiệu năng; skeleton hai canvas và dải tổng "—" trong lúc tải. Bước 4: ST-05 với ERR-04-001, giống hệt trường hợp không tồn tại.
