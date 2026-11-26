# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-16
Tính năng: TS-02-16 · Đăng ký sử dụng: gửi và duyệt

  @TC-02-053 @P1 @Dương
  Kịch bản: TC-02-053 Gửi đăng ký vào gói `autoApprove` dữ liệu `INTERNAL` được tự duyệt
    # Truy vết: FR-02-046, 047 · API-02-058 · UI-02-09 · UC-02-23 · BR-02-012, 026 · EVT-02-09, 10 · LGC-APIM-016; 021.
    Biết gói `goi-co-ban` bật `autoApprove`; H-KHAITHAC-1; U-T68-OR1.
    Khi `POST /subscriptions` kèm mục đích, khối lượng, `Idempotency-Key`; gửi lại cùng khóa.
    Thì `201` đăng ký `ACTIVE`, EVT: `subscription.activated`; lần hai trả cùng kết quả, không tạo thêm.

  @TC-02-054 @P1 @Âm
  Kịch bản: TC-02-054 Đăng ký bị từ chối: HTTT không `ACTIVE`, gói không nhận, trùng, thiếu căn cứ
    # Truy vết: FR-02-046 · API-02-058 · BR-02-011, 012, 027 · ERR-02-026, 025, 027, 028, 029, 042.
    Biết H-KHAITHAC-2 chưa `ACTIVE`; gói `DEPRECATED`; SUB-ACTIVE; API dữ liệu cá nhân.
    Khi đăng ký bằng H-KHAITHAC-2; vào gói `DEPRECATED`; lần hai vào cùng phiên bản.
    Và đăng ký dữ liệu cá nhân thiếu căn cứ pháp lý; thiếu mục đích.
    Và dùng lại `Idempotency-Key` với thân khác.
    Thì `422` ERR-02-026; `409` ERR-02-025; `409` ERR-02-027; `422` ERR-02-029; `422` ERR-02-042.

  @TC-02-055 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-02-055 Duyệt đăng ký `RESTRICTED`: SV một mình không đủ, CA hoặc TA quyết định
    # Truy vết: FR-02-047 · API-02-044, 045, 046 · UI-02-10 · UC-02-24 · BR-02-026, 008 · ERR-02-013, 014 · KT: có (subscription.approve).
    Biết đăng ký `PENDING` vào gói `RESTRICTED`; U-T68-SV1, U-T68-CA.
    Khi U-T68-SV1 `:approve`.
    Và U-T68-CA `:reject` thiếu ý kiến, rồi kèm ý kiến; đăng ký thứ hai CA `:approve`.
    Thì 403-PQ hoặc `403` ERR-02-013; từ chối thiếu ý kiến `400` ERR-02-041; `REJECTED` có lý do; duyệt thành công `ACTIVE`.

  @TC-02-122 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-122 Đăng ký: HTTT thuộc tổ chức khác hoặc không hoạt động
    # Truy vết: FR-02-046 · API-02-058 · UI-02-09 · UC-02-23 · BR-02-011, 033 · ERR-02-026.
    Biết U-T68-OR1 (thuộc H-KHAITHAC-1); H-KHAITHAC-2 (`PENDING` ở PH-01); HTTT của Sở khác ở T68; HTTT chỉ có ở T01.
    Khi OR1 `POST /subscriptions` cho HTTT của Sở khác.
    Và OR1 gửi cho H-KHAITHAC-2 (không `ACTIVE`).
    Và OR1 gửi với mã HTTT của T01.
    Và OR1 gửi cho H-KHAITHAC-1 đúng tổ chức.
    Thì bước 1: `422` ERR-02-026. Bước 2: `422` ERR-02-026 (HTTT không `ACTIVE`). Bước 3: `422` ERR-02-026, thân không phân biệt "không tồn tại" với "ở tenant khác". Bước 4: `201`.

  @TC-02-123 @P1 @Âm
  Kịch bản: TC-02-123 Đăng ký: đối tượng được dùng gói, trùng hiệu lực, thiếu mục đích hoặc căn cứ pháp lý
    # Truy vết: FR-02-046 · API-02-058 · UI-02-09 · UC-02-23 · BR-02-012, 027 · ERR-02-028, 027, 029.
    Biết gói `goi-gioi-han` chỉ cho nhóm HTTT thuộc đơn vị `Sở Tư pháp`; gói `goi-mtls` dữ liệu `RESTRICTED`; SUB-ACTIVE; U-T68-OR1.
    Khi OR1 đăng ký HTTT ngoài đối tượng vào `goi-gioi-han`.
    Và OR1 đăng ký lần hai cùng phiên bản (đã có SUB-ACTIVE).
    Và đăng ký thiếu `purpose`, thiếu `expectedVolume`.
    Và đăng ký vào `goi-mtls` thiếu căn cứ pháp lý.
    Thì bước 1: `422` ERR-02-028. Bước 2: `409` ERR-02-027. Bước 3, 4: `422` ERR-02-029 nêu trường thiếu (căn cứ pháp lý bắt buộc từ mức `RESTRICTED` hoặc có dữ liệu cá nhân, CMP-LAW-05). UI-02-09 chặn gửi và nêu trường thiếu.

  @TC-02-124 @P1 @Âm
  Kịch bản: TC-02-124 Đăng ký vào gói hoặc phiên bản không nhận đăng ký mới
    # Truy vết: FR-02-046 · API-02-058 · UI-02-09 · UC-02-23 · BR-02-011, 018 · ERR-02-025.
    Biết gói `STAGING`, `DEPRECATED`, `CLOSED`; phiên bản `SUSPENDED`, `DEPRECATED`, `RETIRED`; gói và phiên bản `PUBLISHED`; U-T68-OR1.
    Khi gửi đăng ký vào từng gói không `PUBLISHED`.
    Và gửi đăng ký vào từng phiên bản không `PUBLISHED`.
    Và gửi vào gói và phiên bản `PUBLISHED`.
    Thì bước 1, 2: `409` ERR-02-025 với mọi trạng thái trên, không tạo bản ghi. Bước 3: `201`. Đăng ký sẵn có vào gói `DEPRECATED` vẫn giữ hiệu lực.

  @TC-02-125 @P2 @Dương
  Kịch bản: TC-02-125 Đổi gói: đăng ký mới rồi hủy đăng ký cũ
    # Truy vết: FR-02-046, 051 · API-02-058, 064 · UI-02-08, 09 · UC-02-23, 27 · BR-02-027, 025.
    Biết SUB-ACTIVE vào `goi-co-ban`; `goi-mtls` nhận đăng ký; U-T68-OR1.
    Khi đăng ký `goi-mtls` cho cùng HTTT khi đăng ký cũ còn `ACTIVE`.
    Và hủy đăng ký cũ (`:cancel`), duyệt đăng ký mới.
    Và kiểm tra phạm vi truy cập của HTTT.
    Thì bước 1: `409` ERR-02-027 (BR-02-027: đổi gói là đăng ký mới sau khi hủy cũ hoặc theo luồng đổi gói được hỗ trợ). Bước 2: sau khi hủy, đăng ký mới `201`, duyệt `ACTIVE`. Bước 3: chỉ còn phạm vi `api:tc-dat-dai:goi-mtls`, phạm vi `goi-co-ban` đã thu hồi.

  @TC-02-126 @P1 @Âm @Dương
  Kịch bản: TC-02-126 Từ chối đăng ký: lý do, trạng thái `REJECTED`, gửi lại
    # Truy vết: FR-02-047 · API-02-045, 046 · UI-02-10 · UC-02-24 · BR-02-026, 028, 029 · ERR-02-041, 011.
    Biết đăng ký `PENDING` vào gói `RESTRICTED`; U-T68-CA, U-T68-OR1.
    Khi CA `:reject` không lý do; có lý do.
    Và kiểm tra phạm vi truy cập, thông báo.
    Và CA `:approve` đăng ký đã `REJECTED`.
    Và OR1 gửi đăng ký mới với căn cứ bổ sung.
    Thì bước 1: `400` ERR-02-041, rồi `200`, đăng ký `REJECTED`. Bước 2: không có phạm vi; HTTT nhận thông báo quyết định kèm lý do (bắt buộc, không tắt được). Bước 3: `409` ERR-02-011. Bước 4: `201` đăng ký mới.
