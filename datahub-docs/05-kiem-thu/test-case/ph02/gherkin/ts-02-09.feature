# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-09
Tính năng: TS-02-09 · Gói sử dụng: thông tin, kiểu xác thực, hạn mức

  @TC-02-032 @P1 @Dương
  Kịch bản: TC-02-032 Tạo gói `API_KEY`, đặt hạn mức và đường dẫn cho phép
    # Truy vết: FR-02-027, 028, 029 · API-02-034, 036 · UI-02-07 · UC-02-12 · BR-02-040 · LGC-APIM-009; 010, 011 · EVT-02-08.
    Biết A-DRAFT mức `INTERNAL`; U-T68-SV1.
    Khi `POST …/plans` mã `goi-co-ban`, đối tượng được xin là HTTT cấp tỉnh.
    Và `PUT …/access-policy`: `API_KEY`, 100 lượt/phút, cho phép `GET /thua-dat/*`.
    Thì `201` gói `STAGING`, `200` chính sách; EVT: `plan.state-changed`; đơn giá chỉ hiển thị (BR-02-040).

  @TC-02-033 @P1 @Âm @Biên
  Kịch bản: TC-02-033 Kiểu xác thực không hợp mức phân loại, hạn mức vô lý, mã gói trùng
    # Truy vết: FR-02-027, 028, 029 · API-02-034, 036 · BR-02-016, 021 · ERR-02-022, 023, 002, 040.
    Biết API `RESTRICTED`, API `SENSITIVE`, API `INTERNAL`.
    Khi `KEYLESS` cho API `INTERNAL`; `API_KEY` cho `RESTRICTED`; `OAUTH2_PKJWT` cho `SENSITIVE`.
    Và hạn mức 0, hạn mức âm; đường dẫn cho phép `/` trên API chỉ có `GET`.
    Và tạo gói mã `goi-co-ban` lần hai; tạo gói thứ 11.
    Thì bước 1: `422` ERR-02-022. Bước 2: `422` ERR-02-023. Bước 3: `409` ERR-02-002, `422` ERR-02-040.

  @TC-02-034 @P1 @Dương @Âm
  Kịch bản: TC-02-034 Gói `PUBLISHED` chỉ sửa theo hướng tương thích
    # Truy vết: FR-02-028, 029 · API-02-035, 036 · BR-02-017 · ERR-02-011.
    Biết gói `goi-co-ban` của A-DATDAI (`PUBLISHED`, 100 lượt/phút).
    Khi tăng hạn mức lên 200; thêm thao tác cho phép.
    Và hạ hạn mức xuống 50; đổi sang `OAUTH2_MTLS`.
    Thì bước 1: `200`. Bước 2: `409` ERR-02-011, thông báo hướng dẫn tạo gói mới.

  @TC-02-103 @P1 @Dương @Âm @Biên
  Kịch bản: TC-02-103 Ma trận kiểu xác thực theo mức phân loại dữ liệu (bảng tham số hóa)
    # Truy vết: FR-02-028 · API-02-036, 040 · UI-02-07 · UC-02-12 · BR-02-016 · ERR-02-022 · SEC-24.
    Biết bốn API mẫu ở các mức `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE` (mức hiển thị `PUBLIC` cho API đầu); U-T68-SV1.
    Khi với mỗi API, `PUT …/access-policy` lần lượt `KEYLESS`, `API_KEY`, `OAUTH2_PKJWT`, `OAUTH2_MTLS` (16 cặp).
    Và cặp `PUBLIC` + `KEYLESS` nhưng mức hiển thị `ORG` (không phải `PUBLIC`).
    Và `POST …/plans:copy-from` từ phiên bản có mức `INTERNAL` sang phiên bản đã nâng lên `RESTRICTED`, gói gốc dùng `API_KEY`.
    Thì chỉ các cặp hợp lệ `200`: `PUBLIC` nhận cả bốn kiểu, `INTERNAL` từ `API_KEY`, `RESTRICTED` chỉ `OAUTH2_PKJWT` hoặc `OAUTH2_MTLS`, `SENSITIVE` chỉ `OAUTH2_MTLS`; 10 cặp còn lại `422` ERR-02-022. Bước 2: `422` ERR-02-022 vì `KEYLESS` đòi hiển thị `PUBLIC`. Bước 3: `422` ERR-02-022, gói chưa được tạo ở phiên bản đích. UI-02-07 chỉ liệt kê kiểu hợp lệ ở danh sách chọn.

  @TC-02-104 @P1 @Âm @Biên
  Kịch bản: TC-02-104 Thao tác cho phép ngoài đặc tả và hạn mức vô lý
    # Truy vết: FR-02-029 · API-02-036 · UI-02-07 · UC-02-12 · BR-02-017 · ERR-02-037, 023, 003.
    Biết A-DRAFT với đặc tả F-SPEC-OK (có `getDatDai`, `taoDatDai`); gói `goi-nhap`; U-T68-SV1.
    Khi `PUT …/access-policy` với `operationScopes` chỉ gồm `operationId` của `GET /dat-dai/{id}`.
    Và thêm `operationId` không có trong đặc tả (ví dụ `xoaDatDai`).
    Và `quota.perSecond` = `0`, `-5`; rồi `dailyCalls` nhỏ hơn `perSecond` (ví dụ `perSecond` 20, `dailyCalls` 10).
    Và hạn mức hợp lệ sát giới hạn dưới (`perSecond` = 1, `dailyCalls` = 100).
    Thì bước 1, 4: `200`. Bước 2: `422` ERR-02-037 nêu thao tác thừa. Bước 3: `422` ERR-02-023 nêu trường không hợp lý (`quota.perSecond`, `quota.dailyCalls`); chính sách cũ không đổi.

  @TC-02-105 @P2 @Biên @Âm
  Kịch bản: TC-02-105 Giới hạn số gói mỗi phiên bản và đọc danh sách gói
    # Truy vết: FR-02-027 · API-02-033, 034 · UI-02-06 · UC-02-12 · BR-02-033, 039 · ERR-02-040, 001.
    Biết A-DRAFT; `02.plan.max-per-version` = 10 (giả định mặc định, cơ sở: bảng tham số FRS PH-02 §tham số); U-T68-SV1, U-T68-SV2, U-T68-VW; A-T01.
    Khi U-T68-SV1 tạo gói thứ 1…10, rồi gói thứ 11.
    Và U-T68-VW và U-T68-SV2 gọi `GET …/tc-nhap/versions/1.0.0/plans`.
    Và U-T68-SV1 gọi `GET /apis/tc-chi-t01/versions/1.0.0/plans`.
    Thì gói thứ 11 `422` ERR-02-040 kèm `limit`. Bước 2: người ngoài tổ chức không thấy danh sách gói của bản `DRAFT` (rỗng). Bước 3: `404` ERR-02-001. UI-02-06 vô hiệu hóa nút "Tạo gói" khi đủ 10 gói và nêu lý do.

  @TC-02-106 @P3 @Dương
  Kịch bản: TC-02-106 Đơn giá của gói chỉ là thông tin hiển thị
    # Truy vết: FR-02-027 · API-02-034 · UI-02-06, 07 · UC-02-12 · BR-02-040.
    Biết A-DRAFT; U-T68-SV1.
    Khi tạo gói `goi-gia` có `priceNote` "Miễn phí giữa cơ quan nhà nước".
    Và xem gói ở UI-02-06, 07 và ở danh mục cho máy.
    Và tìm trong hệ thống bất kỳ chức năng tính phí, hóa đơn từ PH-02.
    Thì đơn giá hiện đúng nhãn "thông tin tham khảo", không ảnh hưởng đăng ký hay hạn mức; PH-02 không có operation tính phí (thu phí thuộc PH-19).
