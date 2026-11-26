# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-02
Tính năng: TS-06-02 · Soạn mô hình domain, khóa định danh và phân loại

  @TC-06-004 @P1 @Dương
  Kịch bản: TC-06-004 Tạo domain tùy chỉnh với mười một kiểu thuộc tính
    # Truy vết: FR-06-002 · API-06-003, 005, 006 · UI-06-07 · PERM-06-config
    # Mục đích: Chứng minh soạn domain `DEMO-CANBO` đủ các `AttributeType`, thuộc tính `matchable`, trọng số, theo FR-06-002.
    Biết T90, U-T90-DS1 có `PERM-06-config` (○).
    Khi `POST /domains` mã `DEMO-CANBO`.
    Và `PUT .../model-versions/1` với 11 thuộc tính, mỗi `AttributeType` một cái, hai thuộc tính `matchable`.
    Và `GET .../model-versions/1`.
    Thì bước 1 `201` `DRAFT`. Bước 2 `200`, `ETag` mới. Bước 3 trả đủ 11 thuộc tính theo thứ tự, kiểu đúng. KT: có (domain-create, model-update).
    # Hậu điều kiện: Domain DEMO-CANBO DRAFT; dùng lại ở model-neg, version-diff.

  @TC-06-005 @P2 @Âm
  Kịch bản: TC-06-005 Mã trùng, kiểu sai, tham chiếu không tồn tại, ETag cũ
    # Truy vết: FR-06-002 · API-06-003, 006 · ERR-06-002, 003, 004
    # Mục đích: Chứng minh các nhánh bị chặn khi soạn mô hình, theo FR-06-002.
    Biết DEMO-CANBO DRAFT của ca model-create; DS2 sửa đồng thời.
    Khi `POST /domains` mã `DEMO-CANBO` lần hai.
    Và `PUT` thuộc tính `ngaySinh` kiểu `TEXT` (không có trong enum).
    Và `PUT` thuộc tính `CODE_REF` trỏ danh mục `KHONG-CO`.
    Và DS2 `PUT` bằng `If-Match` cũ.
    Thì bước 1 `409` ERR-06-002. Bước 2, 3 `400` ERR-06-003 có `errors[]` đúng trường. Bước 4 `409` ERR-06-004 kèm `currentEtag`.
    # Hậu điều kiện: Mô hình không đổi.

  @TC-06-006 @P1 @Dương
  Kịch bản: TC-06-006 Thử kiểm tra khóa định danh CCCD, MST
    # Truy vết: FR-06-003 · BR-06-001 · API-06-013 · UI-06-07 · NFR-06-010
    # Mục đích: Chứng minh bộ kiểm tra trả đúng `IdentifierStatus` và che giá trị, theo FR-06-003.
    Biết CC-01, CC-03, CC-X, MST-01, MST-X (mục 2.3).
    Khi `POST /identifier-rules:test` validator `CCCD_12` với `[CC-01, CC-X chín số, 000000000000]`.
    Và lặp với `MST_10_13` và `[MST-01, MST-X, 0109000015-001, 0000000000]`.
    Thì bước 1 `VALID`, `INVALID_FORMAT`, `PLACEHOLDER`. Bước 2 `VALID`, `INVALID_CHECKSUM`, `VALID`, `PLACEHOLDER`. Mỗi `value` chỉ giữ 3 số cuối, lượt thử không lưu giá trị (Mồi sạch).
    # Hậu điều kiện: Không đổi mô hình.

  @TC-06-007 @P1 @Âm @Bảo @mật
  Kịch bản: TC-06-007 Khóa sai kiểu, biểu thức ReDoS, trùng loại, CMND xác định
    # Truy vết: FR-06-003 · BR-06-001 · API-06-006, 013 · ERR-06-002, 003, 009, 052
    # Mục đích: Chứng minh khóa chỉ khai được trên thuộc tính `IDENTIFIER` và biểu thức không gây quá tải, theo FR-06-003.
    Biết DEMO-CANBO DRAFT.
    Khi gắn khóa `CCCD_12` vào thuộc tính `STRING`.
    Và khai `REGEX` `^(a+)+$`; đo thời gian trả lời.
    Và khai hai khóa `CCCD_12` trong một domain.
    Và khai `CMND_9` với `deterministic = true`.
    Thì bước 1 `422` ERR-06-009. Bước 2 `400` ERR-06-003 trong ≤ 1 s, không treo CPU. Bước 3 `409` ERR-06-002. Bước 4 `422` ERR-06-052 (CMND_9 chỉ để so sánh, không làm khóa xác định); API-06-013 kiểm thử khóa trả cùng mã.
    # Hậu điều kiện: Không khóa nào được lưu.

  @TC-06-008 @P1 @Dương
  Kịch bản: TC-06-008 Gán và xác nhận phân loại dữ liệu theo PH-09
    # Truy vết: FR-06-004 · BR-06-016 · API-06-006 · UI-06-07
    # Mục đích: Chứng minh phân loại `PROPOSED` thành `CONFIRMED` qua PH-09 và `SENSITIVE` kéo theo mã hóa, theo FR-06-004.
    Biết CITIZEN DRAFT của T93; PH-09 giả lập xác nhận.
    Khi xem thuộc tính `idNumber` `PROPOSED`.
    Và PH-09 giả lập trả `CONFIRMED` cho `idNumber`, `fullName`, `dateOfBirth`.
    Và `GET` lại thuộc tính.
    Thì `ClassificationStatus = CONFIRMED`, `dataClass` giữ `SENSITIVE`, đặt cờ mã hóa envelope và chỉ dùng HMAC trong gom nhóm (BR-06-016). KT: có (classify).
    # Hậu điều kiện: CITIZEN của T93 đủ phân loại, sẵn sàng gửi duyệt ở ca lifecycle-pos.

  @TC-06-009 @P1 @Âm
  Kịch bản: TC-06-009 Kích hoạt khi DLCN chưa xác nhận; PH-09 ngừng
    # Truy vết: FR-06-004, 006 · BR-06-016 · API-06-008, 098 · ERR-06-010, 021
    # Mục đích: Chứng minh không gửi duyệt được mô hình còn thuộc tính DLCN chưa xác nhận, theo FR-06-004.
    Biết DEMO-CANBO có thuộc tính `ngaySinh` `PROPOSED`.
    Khi `POST .../model-versions/1:submit`.
    Và dừng PH-09 giả lập (`503`), `GET` phân loại.
    Thì bước 1 `422` ERR-06-010 nêu tên thuộc tính. Bước 2 `503` ERR-06-021, dữ liệu phân loại đang có không mất.
    # Hậu điều kiện: Mô hình vẫn DRAFT.

  @TC-06-010 @P2 @Dương
  Kịch bản: TC-06-010 Tạo phiên bản mới và so sánh tương thích
    # Truy vết: FR-06-005 · API-06-004, 005, 007 · BR-06-017 · UI-06-07
    # Mục đích: Chứng minh phiên bản mới từ bản `ACTIVE` và phân loại `NON_BREAKING`, `BREAKING`, theo FR-06-005.
    Biết CITIZEN `ACTIVE` phiên bản 1 ở T90.
    Khi `POST .../model-versions` tạo phiên bản 2; thêm thuộc tính `email`.
    Và `GET .../model-versions/2/diff?against=1`.
    Và đổi kiểu `phone` từ `STRING` sang `PHONE` rồi `diff`.
    Thì bước 2 `CompatLevel = NON_BREAKING`. Bước 3 `BREAKING` kèm danh sách thay đổi và kế hoạch áp lại cần có. Phiên bản 1 vẫn `ACTIVE`.
    # Hậu điều kiện: Phiên bản 2 DRAFT ở T90, dùng ở ca lifecycle-pos.

  @TC-06-011 @P1 @Âm
  Kịch bản: TC-06-011 Sửa trực tiếp phiên bản ACTIVE và thay đổi phá vỡ
    # Truy vết: FR-06-005 · BR-06-017 · API-06-006 · ERR-06-004, 008
    # Mục đích: Chứng minh phiên bản `ACTIVE` bất biến, theo BR-06-017.
    Biết CITIZEN `ACTIVE` phiên bản 1.
    Khi `PUT .../model-versions/1` đổi tên thuộc tính.
    Và `PUT .../model-versions/2` với `If-Match` cũ.
    Thì bước 1 `422` ERR-06-008 "cần phiên bản mới". Bước 2 `409` ERR-06-004. Phiên bản 1 không đổi byte nào (so `ETag`).
    # Hậu điều kiện: Không đổi.
