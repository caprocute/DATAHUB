# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-14
Tính năng: TS-02-14 · Ngừng khuyến nghị, ngừng hẳn, xóa API

  @TC-02-047 @P1 @Dương
  Kịch bản: TC-02-047 Ngừng khuyến nghị có kế nhiệm, đúng hạn tối thiểu
    # Truy vết: FR-02-038 · API-02-050, 045 · UI-02-13 · UC-02-19 · BR-02-004, 005 · EVT-02-06 · LGC-APIM-008.
    Biết `tc-cu` 1.0.0 `PUBLISHED` có đăng ký, 2.0.0 `PUBLISHED`; U-T68-SV1, U-T68-CA.
    Khi `:propose-deprecate` hạn 200 ngày, kế nhiệm 2.0.0; CA duyệt.
    Thì phiên bản `DEPRECATED`; thông báo bắt buộc tới bên khai thác; lịch nhắc 90, 30, 7 ngày.

  @TC-02-048 @P1 @Âm @Biên
  Kịch bản: TC-02-048 Ngừng khuyến nghị thiếu kế nhiệm hoặc hạn ngắn
    # Truy vết: FR-02-038 · API-02-050 · BR-02-004, 005 · ERR-02-031, 032.
    Biết `02.deprecation.min-days` = 180.
    Khi đề nghị hạn 179 ngày (không lý do khẩn); hạn 180 ngày.
    Và đề nghị không có kế nhiệm và không xác nhận ngừng hẳn dịch vụ.
    Thì 179 ngày `422` ERR-02-031; 180 ngày được chấp nhận; thiếu kế nhiệm `422` ERR-02-032.

  @TC-02-049 @P1 @Dương @Âm
  Kịch bản: TC-02-049 Ngừng hẳn khi còn đăng ký hiệu lực, hủy bản nháp
    # Truy vết: FR-02-039 · API-02-051 · BR-02-006, 014 · ERR-02-030, 011.
    Biết A-DEPREC còn SUB-ACTIVE; A-DRAFT.
    Khi `:propose-retire` A-DEPREC tới hạn.
    Và hủy A-DRAFT bằng `:propose-retire`.
    Và hủy toàn bộ đăng ký rồi thử lại bước 1.
    Thì bước 1: `409` ERR-02-030, không tự chuyển `RETIRED`. Bước 2: phiên bản `RETIRED`, đặc tả vẫn lưu. Bước 3: được duyệt.

  @TC-02-050 @P1 @Dương @Âm
  Kịch bản: TC-02-050 Xóa mềm API: điều kiện, mã không dùng lại
    # Truy vết: FR-02-040 · API-02-052, 014 · BR-02-020, 021, 014 · ERR-02-030, 002 · EVT-02-03 · KT: có (api.delete).
    Biết `tc-nhap` (chỉ `DRAFT`); A-DATDAI.
    Khi `DELETE /apis/tc-dat-dai`.
    Và `DELETE /apis/tc-nhap`; đăng ký lại mã `tc-nhap`.
    Thì bước 1: `409` ERR-02-030. Bước 2: `204`, EVT: `api.deleted`, bản ghi vẫn còn (xóa mềm), đăng ký lại `409` ERR-02-002.

  @TC-02-118 @P2 @Biên @Dương
  Kịch bản: TC-02-118 Nhắc ngừng khuyến nghị theo mốc 90, 30, 7 ngày
    # Truy vết: FR-02-038, 044 · API-02-050 · UI-02-13 · UC-02-19 · BR-02-004, 029 · NFR-02-015.
    Biết A-DEPREC có hạn chuyển đổi còn 91 ngày, SUB-ACTIVE; đồng hồ giả; `02.deprecation.reminders` = 90, 30, 7.
    Khi chạy bộ nhắc ở ngày còn 91, 90, 89 ngày; lặp lại trong cùng ngày.
    Và chạy ở các mốc 31, 30, 8, 7, 1 ngày.
    Và đổi `02.deprecation.reminders` thành `60, 14` rồi chạy lại ở mốc 60.
    Thì mỗi mốc gửi đúng một thông báo tới SV và bên đăng ký của A-DEPREC (không gửi lặp trong cùng mốc); ngày 91, 89, 31, 8, 1 không gửi. Sau khi đổi tham số, mốc 60 gửi, mốc 90 không gửi nữa.

  @TC-02-119 @P1 @Âm @Biên
  Kịch bản: TC-02-119 Tới hạn ngừng hẳn khi còn đăng ký: không tự chuyển `RETIRED`
    # Truy vết: FR-02-039, 044 · API-02-051 · UI-02-13 · UC-02-20 · BR-02-006 · ERR-02-030.
    Biết A-DEPREC đã quá hạn chuyển đổi, còn đăng ký `ACTIVE`; `tc-cu-het` quá hạn, đăng ký `SUSPENDED`; `tc-cu-sach` quá hạn, không còn đăng ký; đồng hồ giả.
    Khi chạy bộ xử lý hạn ngừng dùng.
    Và đề nghị ngừng hẳn A-DEPREC (`propose-retire`).
    Và hủy mọi đăng ký của A-DEPREC rồi đề nghị lại; CA duyệt.
    Thì bước 1: không phiên bản nào tự `RETIRED`; A-DEPREC và `tc-cu-het` có cảnh báo gửi SV, CA, TA; `tc-cu-sach` vẫn chờ người can thiệp (không tự động). Bước 2: `409` ERR-02-030 kèm `usages[]`. Bước 3: `202`, sau duyệt `RETIRED`, đường dẫn giữ chỗ 12 tháng.

  @TC-02-120 @P1 @Âm
  Kịch bản: TC-02-120 Xóa API: còn phiên bản đang phục vụ, còn đăng ký, và sai tổ chức
    # Truy vết: FR-02-040 · API-02-052 · UI-02-02 · UC-02-20 · BR-02-020, 032 · ERR-02-030, 011, 014, 001.
    Biết A-DATDAI (`PUBLISHED`); `tc-ngung` chỉ còn phiên bản `RETIRED` và một đăng ký `SUSPENDED`; U-T68-SV1, U-T68-SV2.
    Khi U-T68-SV1 `DELETE /apis/tc-dat-dai`.
    Và `DELETE /apis/tc-ngung`.
    Và U-T68-SV2 `DELETE /apis/tc-dat-dai`.
    Và `DELETE /apis/khong-co`.
    Thì bước 1: `409` ERR-02-011 (còn phiên bản `PUBLISHED`). Bước 2: `409` ERR-02-030 kèm `usages[]` (đăng ký `SUSPENDED` vẫn tính). Bước 3: `403` ERR-02-014 hoặc `404` ERR-02-001 theo quyền; API không đổi. Bước 4: `404`.
