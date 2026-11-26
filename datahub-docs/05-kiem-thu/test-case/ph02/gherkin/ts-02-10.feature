# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-10
Tính năng: TS-02-10 · Vòng đời gói: công bố, ngừng khuyến nghị, đóng, sao chép

  @TC-02-035 @P1 @Dương @Âm
  Kịch bản: TC-02-035 Công bố gói qua bốn mắt
    # Truy vết: FR-02-030 · API-02-037, 045 · UI-02-06, 10 · UC-02-13 · BR-02-008 · ERR-02-013, 012, 014 · KT: có (plan.publish).
    Biết gói `STAGING`, phiên bản `PUBLISHED`; U-T68-SV1, U-T68-CA, U-T68-SV-CA, U-T68-VW.
    Khi U-T68-SV1 `:submit`; U-T68-VW `:submit`.
    Và U-T68-SV1 phê duyệt chính yêu cầu của mình; U-T68-SV-CA vừa gửi vừa duyệt.
    Và U-T68-CA `:approve`.
    Thì bước 1: `202`; VW 403-PQ. Bước 2: `403` ERR-02-013. Bước 3: gói `PUBLISHED`, GW: nạp plan.

  @TC-02-036 @P1 @Dương @Âm
  Kịch bản: TC-02-036 Ngừng khuyến nghị, đóng gói và điều kiện còn đăng ký
    # Truy vết: FR-02-031, 032 · API-02-038, 039, 041 · BR-02-018, 019 · ERR-02-024, 025, 011.
    Biết `goi-co-ban` có SUB-ACTIVE; gói `goi-trong` không có đăng ký; H-KHAITHAC-1.
    Khi ngừng khuyến nghị `goi-co-ban` (duyệt xong), rồi gửi đăng ký mới vào gói.
    Và `:submit-close` `goi-co-ban`; rồi `:submit-close` `goi-trong`.
    Và hủy gói nháp bằng `DELETE`.
    Thì bước 1: đăng ký mới `409` ERR-02-025. Bước 2: `409` ERR-02-024, gói không đăng ký đóng được. Bước 3: `204`.

  @TC-02-037 @P2 @Dương @Âm
  Kịch bản: TC-02-037 Sao chép gói sang phiên bản mới
    # Truy vết: FR-02-033 · API-02-040 · UI-02-06 · BR-02-021, 035 · ERR-02-002.
    Biết A-DATDAI 1.0.0 có 2 gói; phiên bản 1.1.0 `DRAFT`.
    Khi `POST …/1.1.0/plans:copy-from` từ 1.0.0; gọi lần hai.
    Thì lần một tạo 2 gói `STAGING` cùng mã; lần hai `409` ERR-02-002.

  @TC-02-107 @P1 @Âm @Dương @Biên
  Kịch bản: TC-02-107 Ngừng khuyến nghị gói: hạn ngắn, thiếu gói kế nhiệm, ngoại lệ khẩn có TA đồng ý
    # Truy vết: FR-02-031 · API-02-038, 045 · UI-02-06, 10 · UC-02-14 · BR-02-004, 005, 008, 018 · ERR-02-031, 032, 013, 041.
    Biết A-DATDAI có `goi-co-ban` (`PUBLISHED`, có SUB-ACTIVE) và `goi-co-ban-v2` (`PUBLISHED`); U-T68-SV1, U-T68-CA, U-T68-TA; `02.deprecation.min-days` = 180.
    Khi `POST …/plans/goi-co-ban:submit-deprecate` hạn 30 ngày.
    Và hạn 180 ngày nhưng không chỉ gói kế nhiệm.
    Và hạn 179 ngày, rồi đúng 180 ngày, gói kế nhiệm `goi-co-ban-v2`.
    Và hạn 30 ngày kèm cờ khẩn, lý do; CA duyệt (không phải TA).
    Và như bước 4, TA đồng ý trong yêu cầu duyệt.
    Thì bước 1: `422` ERR-02-031 kèm hạn tối thiểu 180. Bước 2: `422` ERR-02-032. Bước 3: 179 ngày `422` ERR-02-031, 180 ngày `202`. Bước 4: CA không đủ quyền chấp nhận ngoại lệ (`403` ERR-02-013 hoặc yêu cầu giữ `PENDING` chờ TA). Bước 5: duyệt được. Sau duyệt, gói `DEPRECATED` không nhận đăng ký mới, đăng ký sẵn có tiếp tục (BR-02-018).

  @TC-02-108 @P1 @Âm @Dương
  Kịch bản: TC-02-108 Đóng gói còn đăng ký: danh sách nơi đang dùng và đóng được khi hết
    # Truy vết: FR-02-032 · API-02-039, 045 · UI-02-06 · UC-02-14 · BR-02-019 · ERR-02-024.
    Biết gói `goi-dong` (`DEPRECATED`) có 3 đăng ký: `PENDING`, `ACTIVE`, `SUSPENDED`; U-T68-SV1, U-T68-CA.
    Khi `POST …/plans/goi-dong:submit-close`.
    Và hủy từng đăng ký (`PENDING` → `CANCELLED`, `ACTIVE` → `REVOKED`); gọi lại sau mỗi lần.
    Và còn đăng ký `SUSPENDED` duy nhất; gọi lại.
    Và hủy nốt; gọi lại; CA duyệt.
    Thì bước 1, 2, 3: `409` ERR-02-024 với `usages[]` giảm dần 3, 2, 1 phần tử (`kind`, `ref`), không có dữ liệu cá nhân; đăng ký `SUSPENDED` vẫn tính là còn hiệu lực. Bước 4: `202`; sau duyệt gói `CLOSED`, mã gói không dùng lại.

  @TC-02-109 @P2 @Dương @Âm
  Kịch bản: TC-02-109 Hủy gói nháp và mã gói đã hủy không dùng lại
    # Truy vết: FR-02-032 · API-02-034, 041 · UI-02-06 · UC-02-14 · BR-02-021, 028 · ERR-02-011, 002, 041.
    Biết A-DRAFT có gói `goi-huy` ở `STAGING`; A-DATDAI `goi-co-ban` ở `PUBLISHED`; U-T68-SV1.
    Khi `DELETE …/plans/goi-huy` (không lý do) rồi có lý do.
    Và `POST …/plans` tạo lại mã `goi-huy`.
    Và `DELETE …/plans/goi-co-ban` (gói `PUBLISHED`).
    Thì bước 1: `400` ERR-02-041, rồi `204` xóa mềm, vẫn còn trong lịch sử. Bước 2: `409` ERR-02-002. Bước 3: `409` ERR-02-011, phải theo đường ngừng khuyến nghị và đóng.

  @TC-02-110 @P2 @Âm
  Kịch bản: TC-02-110 Từ chối công bố gói: thiếu lý do, yêu cầu đã xử lý, quay về nháp
    # Truy vết: FR-02-030, 035 · API-02-037, 045, 046 · UI-02-10 · UC-02-13 · BR-02-008, 028 · ERR-02-041, 011.
    Biết A-DRAFT có gói `goi-tu-choi` đủ điều kiện; U-T68-SV1, U-T68-CA.
    Khi SV gửi duyệt công bố gói; CA `:reject` không lý do.
    Và CA `:reject` có lý do; sau đó CA `:approve` cùng yêu cầu.
    Và SV sửa gói và gửi lại.
    Thì bước 1: `400` ERR-02-041. Bước 2: từ chối `200`, gói về `STAGING`, SV nhận thông báo kèm lý do; duyệt lại yêu cầu đã xử lý `409` ERR-02-011. Bước 3: tạo yêu cầu duyệt mới `202`.

  @TC-02-166 @P2 @Dương @Âm
  Kịch bản: TC-02-166 Danh sách gói toàn tenant: lọc, phân trang, đếm theo trạng thái, cách ly
    # Truy vết: FR-02-027, 031 · API-02-096, 033 · UI-02-06 · UC-02-12, 14 · BR-02-039 · ERR-02-003, 001.
    Biết A-DATDAI (hai gói), A-DRAFT (một gói `STAGING`), A-DEPREC (gói `DEPRECATED`), A-T01 ở tenant T01; người dùng U-T68-SV1, U-T68-SV2, U-T68-VW.
    Khi U-T68-VW gọi `GET /plans?size=2&page=1`, rồi `page=2`.
    Và U-T68-VW gọi `GET /plans?status=DEPRECATED&authType=OAUTH2_MTLS`.
    Và U-T68-SV2 gọi `GET /plans?apiCode=tc-nhap` (API `DRAFT` của tổ chức khác).
    Và gọi `GET /plans?size=500` và `GET /plans?authType=KHONG-CO`.
    Và tìm mã gói của T01 trong kết quả của U-T68-VW.
    Thì bước 1: `200`, `totalElements` bằng số gói người gọi được xem, hai trang không trùng dòng, `counts` đếm theo `STAGING`, `PUBLISHED`, `DEPRECATED`, `CLOSED`. Bước 2: chỉ gói `DEPRECATED` đúng kiểu xác thực, mỗi dòng nêu API, phiên bản và `versionStatus`. Bước 3: danh sách rỗng, không lộ sự tồn tại của `tc-nhap` (BR-02-039). Bước 4: `400` ERR-02-003 kèm `errors[]` theo trường. Bước 5: không có gói của T01. UI-02-06 hiện đúng số gói và nhãn trạng thái.
