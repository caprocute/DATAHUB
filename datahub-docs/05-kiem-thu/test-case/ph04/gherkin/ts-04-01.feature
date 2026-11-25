# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-01
Tính năng: TS-04-01 · Không gian làm việc và thành viên

  @TC-04-001 @P2 @Dương
  Kịch bản: TC-04-001 Liệt kê, tạo và sửa không gian làm việc
    # Truy vết: FR-04-007 · API-04-001, 002 · UI-04-21 · UC-04-01 · LGC-BUS-032
    Biết người gọi U-T68-TA.
    Khi gọi `GET /workspaces`.
    Và gọi `POST /workspaces` với `{"code":"tc-thue","name":"Thuế (thử)"}` và `Idempotency-Key`.
    Và gửi lại bước 2 cùng khóa, cùng thân.
    Và gọi `PATCH /workspaces/tc-thue` với `If-Match` từ bước 2, đổi `name`.
    Thì bước 1 trả `200` với WS-HOTICH, WS-DATDAI, WS-ARCH (trạng thái `ARCHIVED`) và DEFAULT; mỗi phần tử có `flowCount`, `allowedActions`. Bước 2 trả `201`. Bước 3 trả lại đúng phản hồi bước 2, không tạo bản ghi thứ hai. Bước 4 trả `200`, `ETag` mới. KT: có (`INT_WORKSPACE_CREATE`, `INT_WORKSPACE_UPDATE`).

  @TC-04-002 @P2 @Âm
  Kịch bản: TC-04-002 Tạo không gian trùng mã, sửa không gian không tồn tại
    # Truy vết: FR-04-007 · API-04-002 · ERR-04-027, 028
    Biết U-T68-TA.
    Khi gọi `POST /workspaces` với `code = "ho-tich"`.
    Và gọi `PATCH /workspaces/khong-co` có `If-Match`.
    Và U-T68-IE1 gọi `POST /workspaces` với mã mới.
    Thì bước 1 trả `409` ERR-04-028. Bước 2 trả `404` ERR-04-027. Bước 3 trả 403-PQ (IE không có `PERM-04-admin`). KT: không với bước 1, 2.

  @TC-04-003 @P1 @Dương
  Kịch bản: TC-04-003 Thay danh sách thành viên và hiệu lực ngay
    # Truy vết: FR-04-007 · BR-04-021 · API-04-004, 022 · UC-04-01
    Biết U-T68-IA1 (mức `MAINTAIN` trên WS-HOTICH); F-HT v4 `DRAFT`.
    Khi U-T68-IE3 gọi `PUT /flows/tra-cuu-ho-tich/versions/4/draft` với nội dung hợp lệ.
    Và U-T68-IA1 gọi `PUT /workspaces/ho-tich/members`, thêm IE3 mức `EDIT`.
    Và IE3 lặp bước 1 với `If-Match` mới.
    Thì bước 1 trả `403` ERR-04-003. Bước 2 trả `200`. Bước 3 trả `200` không cần đăng nhập lại (quyền không gian tra theo yêu cầu, không nằm trong token). KT: có (`INT_WORKSPACE_MEMBERS` ghi danh sách thêm, bớt).

  @TC-04-004 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-004 Thành viên mức VIEW và người ngoài không gian
    # Truy vết: FR-04-007, 010 · BR-04-021 · API-04-010, 012, 022 · ERR-04-003
    Biết U-T68-VW (VIEW trên WS-HOTICH), U-T68-IE3 (chỉ WS-DATDAI).
    Khi VW gọi `GET /flows/tra-cuu-ho-tich`.
    Và VW gọi `PUT /flows/tra-cuu-ho-tich/versions/4/draft`.
    Và IE3 gọi `GET /flows?workspace=ho-tich`.
    Và IE3 gọi `GET /flows/tra-cuu-ho-tich`.
    Thì bước 1 trả `200`, `allowedActions` không có `EDIT`, `disabledReasons.EDIT` nêu "chỉ có quyền xem trong không gian Hộ tịch". Bước 2 trả `403` ERR-04-003. Bước 3 trả `200` với `items` rỗng, lọc ở SQL chứ không ở ứng dụng (kiểm bằng log câu lệnh ở IT). Bước 4 trả 404-ẩn.

  @TC-04-005 @P2 @Dương
  Kịch bản: TC-04-005 Tắt giới hạn không gian làm việc
    # Truy vết: FR-04-007, 084 · BR-04-021
    Biết U-T68-TA đặt `04.workspace.enforce = false` qua PH-18.
    Khi IE3 gọi lại bước 2 của TC ở trên với F-HT v4.
    Và TA bật lại tham số; IE3 gọi lại.
    Thì bước 1 trả `200` (chỉ quyền chức năng có hiệu lực). Bước 2 trả `403` ERR-04-003 trong vòng 60 giây sau khi bật (bộ đệm tham số).

  @TC-04-006 @P3 @Dương @Âm
  Kịch bản: TC-04-006 Lưu trữ không gian còn luồng
    # Truy vết: FR-04-007 · API-04-003, 011 · ERR-04-017, 027 · UI-04-03
    Biết U-T68-TA; không gian `tc-thue` (từ ca đầu) có một luồng nháp.
    Khi gọi `POST /workspaces/tc-thue:archive`.
    Và IE1 mở UI-04-03 bước 1, mở ô "Không gian làm việc".
    Và IE1 gọi `POST /flows` với `workspaceCode = "tc-thue"`.
    Thì bước 1 trả `200`, `status = ARCHIVED`, luồng cũ vẫn xem được. Bước 2 không có `tc-thue` trong danh sách. Bước 3 trả `409` ERR-04-005 với `detail` "Không gian làm việc đã lưu trữ". KT: có (`INT_WORKSPACE_ARCHIVE`).
