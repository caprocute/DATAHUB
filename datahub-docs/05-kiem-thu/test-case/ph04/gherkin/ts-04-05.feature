# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-05
Tính năng: TS-04-05 · Phiên bản, lưu nháp, ETag, phiên soạn, gộp ba bên

  @TC-04-029 @P1 @Dương
  Kịch bản: TC-04-029 Lưu nháp và tính lại băm
    # Truy vết: FR-04-024, 010 · API-04-020, 022 · BR-04-007
    Biết F-HT v4 `DRAFT`; IE1 lấy ETag ở `GET /flows/tra-cuu-ho-tich/versions/4`.
    Khi gọi `PUT .../versions/4/draft` chỉ đổi `canvasLayout` (kéo một chặng).
    Và gọi `PUT .../draft` đổi `samples`.
    Và gọi `PUT .../draft` đổi một thuộc tính trong `definitionYaml`.
    Thì bước 1, 2 trả `200`, `contentHash` không đổi (bố cục và bản tin mẫu không thuộc YAML). Bước 3 trả `200`, `contentHash` đổi, `validation.level = DESIGN` kèm `findings`. Mỗi bước `ETag` tăng `version`. IE1 có trong `contributors`. KT: không cho từng lần lưu (chỉ mốc gửi duyệt mới kiểm toán), có metric `dh_int_draft_saves_total`.

  @TC-04-030 @P1 @Âm
  Kịch bản: TC-04-030 Lưu nháp sai điều kiện
    # Truy vết: FR-04-024 · API-04-022 · ERR-04-004, 006, 007, 033, 008, 010
    Biết F-HT v4 `DRAFT`.
    Khi lưu `versions/9` (không tồn tại).
    Và lưu không có `If-Match`.
    Và lưu với YAML-BIG.
    Và lưu với YAML cú pháp hỏng.
    Và lưu với YAML-SECRET.
    Thì lần lượt `404` ERR-04-004, `428` ERR-04-007, `413` ERR-04-033, `422` ERR-04-008, `422` ERR-04-010. Ở bước 4, 5 nội dung cũ giữ nguyên trên máy chủ; CSDL không có chuỗi `Abc@12345678` ở bất kỳ cột nào (kiểm bằng truy vấn `ILIKE` trên `ph04` ở IT).

  @TC-04-031 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-031 Phiên bản đã gửi duyệt là bất biến
    # Truy vết: FR-04-011, 040 · BR-04-016 · API-04-022 · ERR-04-005
    Biết phiên bản `PENDING_REVIEW` và v3 `APPROVED` của F-HT.
    Khi gọi `PUT .../draft` trên phiên bản `PENDING_REVIEW` với ETag đúng.
    Và gọi `PUT .../draft` trên v3.
    Và Ở IT, dùng vai trò `ph04_app` chạy `UPDATE ph04.flow_version SET definition_yaml = 'x' WHERE status = 'APPROVED'`.
    Thì bước 1, 2 trả `409` ERR-04-005. Bước 3 bị trigger `tg_flow_version_immutable` từ chối với lỗi SQLSTATE `P0001`; dữ liệu không đổi.

  @TC-04-032 @P1 @Dương @Âm
  Kịch bản: TC-04-032 Tạo phiên bản mới khi đã có phiên bản mở
    # Truy vết: FR-04-011 · BR-04-016 · API-04-021, 024 · ERR-04-016, 004
    Biết F-DD v1 `APPROVED`, không có phiên bản mở.
    Khi IE2 gọi `POST /flows/dong-bo-dat-dai/versions` với `{}`.
    Và IE3 gọi lại.
    Và gọi `POST /flows/tra-cuu-ho-tich/versions` với `baseVersionNo = 99`.
    Và gọi `GET /flows/dong-bo-dat-dai/versions`.
    Thì bước 1 trả `201` v2 `DRAFT` sao từ v1. Bước 2 trả `409` ERR-04-016 kèm `versionNo = 2` và người tạo. Bước 3 trả `404` ERR-04-004. Bước 4 liệt kê v1, v2 có `environments`.

  @TC-04-033 @P1 @Dương
  Kịch bản: TC-04-033 Hai người cùng sửa: phát hiện, xung đột, gộp ba bên
    # Truy vết: FR-04-024, 010 · API-04-022, 034 · UI-04-04 · UC-04-04 · ERR-04-006
    Biết IE1 và IE2 cùng mở F-HT v4 trên hai trình duyệt.
    Khi cả hai mở trình thiết kế.
    Và IE2 đổi `timeout` của chặng `deliver`, chờ tự lưu.
    Và IE1 (chưa tải lại) đổi mô tả chặng `transform`, chờ tự lưu.
    Và IE1 chọn "Gộp" trong hộp xung đột.
    Và lặp lại, lần này IE1 và IE2 cùng đổi `timeout` của chặng `deliver` với giá trị khác nhau.
    Thì bước 1: mỗi người thấy huy hiệu "Trần Thị Bình đang mở" (nhịp API-04-034). Bước 3: lưu nhận `412`, giao diện mở hộp xung đột ba bên (ST-08). Bước 4: thay đổi không chồng nhau được gộp tự động, lưu thành công với ETag mới, cả hai thay đổi có trong YAML. Bước 5: hộp liệt kê trường xung đột `timeout` với ba giá trị (gốc, của tôi, của Bình); chưa chọn thì nút "Lưu" bị khóa. Không bước nào mất thay đổi của IE1 (giữ ở IndexedDB tới khi lưu được).

  @TC-04-034 @P2 @Khả @dụng
  Kịch bản: TC-04-034 Mất kết nối khi đang soạn, khôi phục phiên nháp
    # Truy vết: FR-04-024 · UI-04-04 · NFR-04-015
    Biết IE1 mở F-HT v4.
    Khi playwright đặt `context.setOffline(true)`, IE1 thêm hai chặng.
    Và đóng tab, mở lại trang khi vẫn ngoại tuyến.
    Và bật mạng.
    Thì bước 1: banner ST-09, chỉ báo "Chưa lưu lên máy chủ". Bước 2: hộp "Khôi phục thay đổi chưa lưu lúc {giờ}?". Bước 3: tự lưu, chỉ báo về "Đã lưu". Nếu ETag đã đổi trong lúc ngoại tuyến thì vào hộp gộp ba bên như ca xung đột.

  @TC-04-035 @P3 @Biên
  Kịch bản: TC-04-035 Phiên soạn hết hạn và catalog đổi khi đang mở
    # Truy vết: FR-04-010, 081 · API-04-034 · UI-04-04
    Biết IE1 mở F-HT v4.
    Khi IE2 gọi `PUT .../session` một lần rồi ngừng.
    Và sau 125 giây IE1 gọi `PUT .../session`.
    Và PA phát hành catalog mới cho T68 trong lúc IE1 đang mở.
    Thì bước 2: `others` không còn IE2. Bước 3: ở nhịp kế tiếp `catalogVersion` khác bản đang dùng, giao diện hiện banner "Danh mục thành phần đã cập nhật" và nút "Nạp lại danh mục", không tự đổi giữa chừng.

  @TC-04-036 @P3 @Âm
  Kịch bản: TC-04-036 Lưu nháp trong khoảng đóng băng cả việc soạn
    # Truy vết: FR-04-024, 084 · BR-04-022 · API-04-022 · ERR-04-041
    Biết TA đặt khoảng đóng băng có cờ "khóa cả soạn thảo" từ bây giờ tới 2 giờ sau.
    Khi IE1 lưu nháp F-HT v4.
    Và TA đặt lại khoảng đóng băng không có cờ, IE1 lưu lại.
    Thì bước 1 trả `423` ERR-04-041 với `until`. Bước 2 trả `200` (đóng băng thường chỉ chặn phát hành).
