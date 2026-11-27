# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-08
Tính năng: TS-09-08 · Cơ sở pháp lý, văn bản căn cứ và mục đích khai thác

  @TC-09-025 @P2 @Dương
  Kịch bản: TC-09-025 Thêm văn bản căn cứ, cơ sở và mục đích, mục đích bắt buộc theo luật
    # Truy vết: FR-09-012, 014 · API-09-046, 049, 055, 054 · UI-09-07 · BR-09-047
    # Mục đích: Chứng minh danh mục mục đích gắn cơ sở pháp lý và cờ bắt buộc theo luật dùng cho BR-09-047.
    Biết T90; U-T90-DO1, U-T90-TA.
    Khi TA `POST /legal-documents` văn bản `ND-xx/2026` hiệu lực từ 2026-01-01.
    Và TA `POST /legal-bases` cơ sở `STATE_TASK` gắn văn bản.
    Và DO1 `POST /purposes` mã `MD-TRACUU-HGD`, cờ `statutory = false`; thêm `MD-LUATDINH` cờ `true`.
    Và `GET /purposes`.
    Thì bước 1 đến 3 `201`; bước 4 có cả hai mục đích; KT: có cho mỗi thao tác ghi.

  @TC-09-026 @P2 @Âm
  Kịch bản: TC-09-026 Mã mục đích trùng, ngừng mục đích còn chấp thuận, văn bản hết hiệu lực
    # Truy vết: FR-09-012, 014 · API-09-055, 057, 050 · ERR-09-002, 011, 021
    # Mục đích: Chứng minh mục đích đang dùng không ngừng được và mã duy nhất.
    Biết T90; `MD-TRACUU-HGD` có 1 chấp thuận `ACTIVE`; U-T90-DO1, U-T90-TA.
    Khi DO1 `POST /purposes` mã `MD-TRACUU-HGD`.
    Và DO1 `POST /purposes/MD-TRACUU-HGD:retire`.
    Và TA `PATCH /legal-documents/{id}` đặt hết hiệu lực văn bản đang làm căn cứ cho HD-01.
    Thì bước 1 `409` ERR-09-002. Bước 2 `409` ERR-09-011 nêu 1 chấp thuận. Bước 3 `200`, hoạt động HD-01 được gắn cờ cảnh báo cần rà soát căn cứ (ERR-09-021 khi gửi duyệt phiên bản mới).

  @TC-09-027 @P3 @Biên
  Kịch bản: TC-09-027 Mục đích bị giới hạn bởi trần thời hạn chấp thuận
    # Truy vết: FR-09-014 · API-09-056 · BR-09-015 · ERR-09-078
    # Mục đích: Chứng minh tham số tenant không vượt trần PA.
    Biết T92; U-T90-TA; PA đặt trần `09.grant.max-days = 730`.
    Khi TA đặt `09.grant.max-days = 731` qua `PUT /settings`.
    Và TA đặt `730`.
    Thì bước 1 `422` ERR-09-078 nêu miền `30…730`. Bước 2 `200`, KT: có (settings-update).
