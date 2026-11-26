# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-04
Tính năng: TS-04-04 · Sửa thông tin, nhân bản, hủy nháp, gỡ luồng

  @TC-04-021 @P1 @Dương
  Kịch bản: TC-04-021 Sửa thông tin luồng
    # Truy vết: FR-04-004 · API-04-013 · EVT-04-02 · LGC-BUS-006, 011.
    Biết U-T68-IE1; F-HT, `ETag` hiện tại.
    Khi gọi `PATCH /flows/tra-cuu-ho-tich` với `If-Match`, đổi `name`, thêm nhãn `muc-do:cao`.
    Và gọi `PATCH` có `code` trong thân.
    Thì bước 1 trả `200`, `ETag` mới; EVT-04-02 có `changedFields = ["name","labels"]`; phiên bản và runtime không đổi (Git: không). Bước 2 trả `400` ERR-04-049 (mã không đổi được, BR-04-001). KT: có (`INT_FLOW_UPDATE` với trước, sau).

  @TC-04-022 @P1 @Âm
  Kịch bản: TC-04-022 Sửa thông tin luồng: khóa lạc quan và quyền
    # Truy vết: FR-04-004 · API-04-013 · ERR-04-003, 006, 007.
    Biết IE1, IE3; F-HT.
    Khi IE1 gọi `PATCH` không có `If-Match`.
    Và IE1 gọi `PATCH` với ETag cũ.
    Và IE1 chuyển luồng sang `workspaceCode = "dat-dai"` (IE1 không có `EDIT` ở WS-DATDAI).
    Và IE3 gọi `PATCH` với ETag đúng.
    Thì bước 1 trả `428` ERR-04-007. Bước 2 trả `412` ERR-04-006 kèm `currentEtag`, `savedBy`, `savedAt`. Bước 3, 4 trả `403` ERR-04-003. Dữ liệu không đổi.

  @TC-04-023 @P2 @Dương
  Kịch bản: TC-04-023 Nhân bản luồng
    # Truy vết: FR-04-005 · BR-04-011 · API-04-014 · UC-04-16 · EVT-04-01.
    Biết F-HT v3; IE1.
    Khi gọi `POST /flows/tra-cuu-ho-tich:clone` với `{"code":"tc-ban-sao","name":"Bản sao","sourceVersionNo":3,"includeTestCases":true}`.
    Và gọi `GET /flows/tc-ban-sao/versions/1`.
    Thì bước 1 trả `201`, `origin = CLONE`, `clonedFrom = "tra-cuu-ho-tich@3"`. Bước 2: mã route đổi tiền tố thành `tc-ban-sao-…`, đường dẫn HTTP đổi thành `/tc-ban-sao/…` để không vi phạm VR-08, VR-18; ca kiểm thử được sao; bản tin mẫu được sao; người tạo là IE1 (không kế thừa người đóng góp cũ).

  @TC-04-024 @P2 @Dương
  Kịch bản: TC-04-024 Hủy bản nháp
    # Truy vết: FR-04-006 · BR-04-016 · API-04-023, 021.
    Biết F-HT v4 `DRAFT`.
    Khi IE1 gọi `POST /flows/tra-cuu-ho-tich/versions/4:discard` có `If-Match`.
    Và gọi `POST /flows/tra-cuu-ho-tich/versions`.
    Thì bước 1 trả `200`, `status = DISCARDED`; luồng không còn phiên bản mở. Bước 2 trả `201` phiên bản 5 sao từ v3 (đang chạy PROD). Số 4 không được dùng lại.

  @TC-04-025 @P2 @Âm
  Kịch bản: TC-04-025 Hủy bản nháp không đúng trạng thái
    # Truy vết: FR-04-006 · API-04-023 · ERR-04-005.
    Biết F-HT v3 `APPROVED`; phiên bản đang `PENDING_REVIEW` ở luồng khác.
    Khi gọi `:discard` trên v3.
    Và gọi `:discard` trên phiên bản `PENDING_REVIEW`.
    Thì cả hai trả `409` ERR-04-005, `detail` nêu trạng thái hiện tại.

  @TC-04-026 @P1 @Dương
  Kịch bản: TC-04-026 Gỡ luồng đã phát hành, rút theo thứ tự môi trường
    # Truy vết: FR-04-006 · BR-04-017 · API-04-015 · EVT-04-06, 09 · UC-04-16 · LGC-BUS-010, 012.
    Biết luồng `tc-go` đã chạy ở TEST và PROD, không có phụ thuộc cứng; U-T68-TA.
    Khi gọi `POST /flows/tc-go:retire` với `{"reason":"Thay bằng luồng mới theo Quyết định thử"}` và `If-Match`.
    Và theo dõi `GET /flows/tc-go/deployments`.
    Thì bước 1 trả `202`. Hệ thống tạo triển khai `RETIRE` cho PROD trước, rồi tới TEST; mỗi môi trường xóa `flows/tc-go/` khỏi `env/*` (với PROD là merge request). Khi mọi bản sao báo không còn luồng, trạng thái luồng `RETIRED`, EVT-04-09 phát. Gọi tới `POST /tc-go/...` qua APISIX trả `404` ERR-04-111. KT: có (`INT_FLOW_RETIRE` có lý do).

  @TC-04-027 @P1 @Âm
  Kịch bản: TC-04-027 Gỡ luồng còn phụ thuộc, thiếu lý do
    # Truy vết: FR-04-006 · BR-04-017 · API-04-015 · ERR-04-017, 025, 005.
    Biết F-HT có phụ thuộc cứng (ca TC phụ thuộc ở TS-04-02); `tc-go2` đang có lần chạy thử `RUNNING`.
    Khi TA gỡ F-HT có lý do hợp lệ.
    Và TA gỡ `tc-go2` với `reason = "gỡ"` (4 ký tự).
    Và TA gỡ `tc-go2` với lý do hợp lệ.
    Và IE1 gỡ F-HT (luồng đã phát hành, IE không có `PERM-04-publish`).
    Thì bước 1 trả `409` ERR-04-017 kèm `dependencies`. Bước 2 trả `400` ERR-04-025. Bước 3 trả `409` ERR-04-005 ("đang có lần chạy thử"). Bước 4 trả 403-PQ. Git: không. EVT: không.

  @TC-04-028 @P2 @Âm
  Kịch bản: TC-04-028 Luồng đã gỡ chỉ đọc
    # Truy vết: FR-04-006, 004 · API-04-013, 021 · ERR-04-034.
    Biết `tc-go` đã `RETIRED` (sau ca gỡ).
    Khi gọi `PATCH /flows/tc-go`.
    Và gọi `POST /flows/tc-go/versions`.
    Và gọi `GET /flows/tc-go`.
    Thì bước 1, 2 trả `409` ERR-04-034. Bước 3 trả `200` với `retiredAt`, `retireReason`, `allowedActions` chỉ có `VIEW`, `CLONE`.
