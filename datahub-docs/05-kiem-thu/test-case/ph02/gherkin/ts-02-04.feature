# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-04
Tính năng: TS-02-04 · Đăng ký API bằng trình hướng dẫn và nạp đặc tả

  @TC-02-012 @P1 @Dương
  Kịch bản: TC-02-012 Đăng ký API qua năm bước từ tệp OpenAPI hợp lệ
    # Truy vết: FR-02-010, 011, 024 · API-02-014, 015, 030 · UI-02-03 · UC-02-05 · EVT-02-01 · KT: có (api.register) · LGC-APIM-002; 003.
    Biết U-T68-SV1; H-CUNGCAP-1; F-SPEC-OK.
    Khi `POST /spec-uploads` nguồn `FILE` với F-SPEC-OK.
    Và `GET /context-paths:check?path=/dat-dai/tc-moi/v1`.
    Và `POST /apis` mã `tc-moi`, kèm phiên bản 1.0.0.
    Thì `201`; phiên bản `DRAFT`; context-path đúng `/{nhóm}/tc-moi/v1`; EVT: `api.registered`; chủ quản là tổ chức của H-CUNGCAP-1.

  @TC-02-013 @P1 @Dương @Âm
  Kịch bản: TC-02-013 Nạp Swagger 2.0, nội dung dán, URL và các nguồn lỗi
    # Truy vết: FR-02-011 · API-02-015 · ERR-02-005, 009, 010, 036 · LGC-APIM-003.
    Biết F-SPEC-SW2, F-SPEC-BIG; M-URL (trả chậm 30 giây, chuyển hướng tới `http://169.254.169.254/`).
    Khi nạp F-SPEC-SW2; nạp nội dung dán; nạp URL hợp lệ.
    Và nạp F-SPEC-BIG; nạp tệp rác `{`; nạp URL trả chậm; nạp URL chuyển hướng tới địa chỉ cấm.
    Và nạp URL 21 lần trong một giờ.
    Thì bước 1: chuyển Swagger 2.0 sang OpenAPI 3.1 có cảnh báo. Bước 2: lần lượt `413` ERR-02-009, `422` ERR-02-005, `422` ERR-02-010, `422` ERR-02-010. Bước 3: lần 21 là `429` ERR-02-036.

  @TC-02-014 @P1 @Âm @Biên
  Kịch bản: TC-02-014 Context-path trùng, xung đột tiền tố, sai quy ước, bất biến sau công bố
    # Truy vết: FR-02-024, 014 · API-02-030, 018, 014 · BR-02-022 · ERR-02-019, 002 · UI-02-03.
    Biết A-DATDAI (`/dat-dai/tc-dat-dai/v1` đã `PUBLISHED`); API `RETIRED` mới 2 tháng giữ chỗ.
    Khi đăng ký API với path trùng A-DATDAI; path `/dat-dai/tc-dat-dai/v1/con`; path `/Dat Dai/x`; path của API `RETIRED`.
    Và `PATCH /apis/tc-dat-dai` đổi context-path.
    Thì bước 1: cả bốn `422` ERR-02-019. Bước 2: `409` ERR-02-011 hoặc `422` ERR-02-019 (path bất biến).

  @TC-02-015 @P1 @Dương @Âm
  Kịch bản: TC-02-015 Sửa bản nháp, khóa khi chờ duyệt, xung đột `If-Match`, mẫu đặc tả
    # Truy vết: FR-02-014, 015 · API-02-018, 019 · BR-02-030, 032 · ERR-02-038, 015, 014 · UI-02-03.
    Biết A-DRAFT; A-DRAFT thứ hai ở `PENDING`; U-T68-SV1, U-T68-SV2.
    Khi U-T68-SV1 `PATCH /apis/tc-nhap` đúng `If-Match`, rồi `If-Match` cũ.
    Và sửa A-DRAFT đang `PENDING`.
    Và U-T68-SV2 sửa A-DRAFT của Sở TN&MT.
    Và `GET /spec-templates/openapi`.
    Thì bước 1: `200`, rồi `412` ERR-02-015. Bước 2: `409` ERR-02-038. Bước 3: 403-PQ. Bước 4: tệp mẫu đạt lớp 1, lớp 2.

  @TC-02-016 @P1 @Âm
  Kịch bản: TC-02-016 Đăng ký cho HTTT không `ACTIVE` hoặc thiếu mô tả tổng thể
    # Truy vết: FR-02-010 · API-02-014 · BR-02-002, 032 · ERR-02-004, 003, 002, 041.
    Biết H-KHAITHAC-2 chưa `ACTIVE`; mã `tc-dat-dai` đã dùng.
    Khi `POST /apis` với HTTT không `ACTIVE`.
    Và `POST /apis` thiếu `name`.
    Và `POST /apis` với mã `tc-dat-dai`.
    Thì lần lượt `422` ERR-02-004, `400` ERR-02-003 kèm danh sách lỗi theo trường, `409` ERR-02-002.

  @TC-02-091 @P2 @Biên @Âm
  Kịch bản: TC-02-091 Đăng ký API: biên độ dài mã API, mã phiên bản, context-path
    # Truy vết: FR-02-010, 024 · API-02-014 · UI-02-03 · UC-02-05 · BR-02-021, 022 · ERR-02-003.
    Biết U-T68-SV1; F-SPEC-OK; H-CUNGCAP-1.
    Khi `POST /apis` với `apiCode` 2 ký tự, rồi 3 ký tự, 63 ký tự, 64 ký tự, bắt đầu bằng số, chứa chữ hoa.
    Và `versionNo` `1.0`, `1.0.0`, `01.0.0`, `1.0.0-beta`.
    Và `contextPath` dài 120 ký tự rồi 121 ký tự; có chữ hoa; không bắt đầu bằng `/`.
    Thì chỉ các giá trị đúng `^[a-z][a-z0-9-]{2,62}$` (3…63 ký tự), `MAJOR.MINOR.PATCH` và `^/[a-z0-9/-]{3,120}$` được `201`; còn lại `400` ERR-02-003 nêu đúng trường. UI-02-03 chặn ngay ở bước nhập và hiện cùng thông báo.

  @TC-02-092 @P1 @Biên @Âm
  Kịch bản: TC-02-092 Giới hạn kích thước đặc tả: đúng 10 MiB và vượt giới hạn
    # Truy vết: FR-02-011 · API-02-015 · UI-02-03 · UC-02-05 · BR-02-001 · ERR-02-009 · NFR-02-011.
    Biết F-SPEC-10M (đúng 10 MiB), F-SPEC-BIG (11 MiB); `02.spec.max-size-mib` = 10.
    Khi `POST /spec-uploads` với F-SPEC-10M.
    Và `POST /spec-uploads` với F-SPEC-BIG bằng tệp, rồi bằng nội dung dán.
    Và đặt `02.spec.max-size-mib` = 5 (miền cho phép) rồi nạp lại F-SPEC-10M.
    Thì bước 1: `200` trong ≤ 20 giây. Bước 2: `413` ERR-02-009 ở cả hai nguồn, không giữ tệp nào ở kho đối tượng. Bước 3: `413`. UI-02-03 báo vượt giới hạn trước khi gửi nếu biết kích thước tệp.

  @TC-02-093 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-093 Nạp đặc tả từ URL: địa chỉ nội bộ, chuyển hướng, quá thời gian, quá số lần
    # Truy vết: FR-02-011 · API-02-015 · UI-02-03 · UC-02-05 · BR-02-023 · ERR-02-010, 036 · SEC-16.
    Biết M-URL với các kịch bản: trả thường, chuyển hướng `302` tới `http://169.254.169.254/`, trả chậm hơn `02.spec.url-fetch-timeout-seconds`; U-T68-SV1.
    Khi nạp URL `http://169.254.169.254/latest/meta-data`, `http://127.0.0.1:8080/spec`, `http://localhost/spec`.
    Và nạp URL M-URL chuyển hướng tới địa chỉ nội bộ.
    Và nạp URL M-URL trả chậm.
    Và nạp hợp lệ 20 lần trong một giờ, rồi lần 21.
    Thì bước 1, 2, 3: `422` ERR-02-010, thông báo chung, không nêu địa chỉ IP đã phân giải; nhật ký ghi lý do ở mức nội bộ. Bước 4: 20 lần đầu `200`, lần 21 `429` ERR-02-036 kèm `retryAfterSeconds` và tiêu đề `Retry-After`.

  @TC-02-162 @P2 @Dương @Âm
  Kịch bản: TC-02-162 Kiểm tra context-path trước khi đăng ký: hợp lệ, trùng, tiền tố, tham số sai
    # Truy vết: FR-02-024 · API-02-030 · UI-02-03 · UC-02-05 · BR-02-022 · ERR-02-019, 003.
    Biết A-DATDAI (`/dat-dai/tc-dat-dai/v1`); API `RETIRED` còn trong thời gian giữ chỗ 12 tháng; U-T68-VW.
    Khi `GET /context-paths:check?path=/dat-dai/tc-moi/v1`.
    Và kiểm tra đúng đường dẫn của A-DATDAI; tiền tố cha `/dat-dai/tc-dat-dai`; đường dẫn con `/dat-dai/tc-dat-dai/v1/con`; đường dẫn của API đang giữ chỗ.
    Và kiểm tra `path=` rỗng; `path=/Dat-Dai`; thiếu tham số.
    Và gõ thử ở UI-02-03 bước "Đường dẫn".
    Thì bước 1: `200`, khả dụng. Bước 2: `200` kèm `available=false` và lý do (trùng, xung đột tiền tố, đang giữ chỗ); đây là phép kiểm tra, không tạo gì. Bước 3: `400` ERR-02-003; đường dẫn sai quy ước `/{nhóm}/{mã API}/v{số chính}` báo sai quy ước (ERR-02-019 khi đăng ký thật). Bước 4: UI báo cùng lý do ngay khi gõ, có giới hạn tần suất gọi ở trình duyệt.
