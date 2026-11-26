# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-07
Tính năng: TS-09-07 · Sổ hoạt động xử lý, liên kết và xuất sổ

  @TC-09-021 @P1 @Dương
  Kịch bản: TC-09-021 Lập hoạt động, gửi duyệt, duyệt bốn mắt, kích hoạt
    # Truy vết: FR-09-009, 010 · API-09-033, 036, 037, 040 · UI-09-05, 06 · BR-09-009, 010, 011 · EVT-09-04
    # Mục đích: Chứng minh hoạt động chỉ `ACTIVE` sau khi người khác người soạn duyệt và có phiên bản.
    Biết T90; U-T90-DS1 (soạn), U-T90-DA1 (duyệt); căn cứ `STATE_TASK` văn bản `ND-xx/2026` còn hiệu lực.
    Khi DS1 `POST /processing-activities` đủ mục đích, cơ sở `STATE_TASK`, vai trò `CONTROLLER`, dữ liệu, bên nhận, thời hạn lưu 60 tháng, hành động `DELETE`.
    Và DS1 `:submit`; DA1 `:approve`.
    Và `GET /processing-activities/{id}/versions`.
    Thì bước 1 `201`, `DRAFT`; hoạt động dữ liệu đi qua ghi vai trò `PROCESSOR` và bên kiểm soát là cơ quan cung cấp (BR-09-010). Bước 2 `PENDING_APPROVAL` rồi `ACTIVE`, EVT: `activity.activated`, KT: có (activity-approve). Bước 3 phiên bản 1 `ACTIVE`.

  @TC-09-022 @P1 @Âm
  Kịch bản: TC-09-022 Thiếu mục, căn cứ hết hiệu lực, đồng ý cho hoạt động bắt buộc, tự duyệt
    # Truy vết: FR-09-009, 010 · API-09-033, 036, 037 · ERR-09-020, 021, 024, 005 · BR-09-009, 012
    # Mục đích: Chứng minh kiểm đủ mục (BR-09-012), căn cứ còn hiệu lực, cơ sở `CONSENT` không dùng cho hoạt động bắt buộc, người soạn không duyệt.
    Biết T90; văn bản `ND-cu/2020` hết hiệu lực; U-T90-DS1, U-T90-DA1.
    Khi DS1 `:submit` hoạt động thiếu thời hạn lưu.
    Và DS1 tạo hoạt động dùng căn cứ `ND-cu/2020`.
    Và DS1 tạo hoạt động bắt buộc theo luật với `legalBasis = CONSENT`.
    Và DS1 gửi duyệt rồi tự `:approve`.
    Thì bước 1 `422` ERR-09-020 nêu "thời hạn lưu". Bước 2 `422` ERR-09-021. Bước 3 `422` ERR-09-024. Bước 4 `403` ERR-09-005.

  @TC-09-023 @P1 @Dương @Âm
  Kịch bản: TC-09-023 Liên kết trường DLCN, trường chưa thuộc hoạt động, ngừng khi còn liên kết
    # Truy vết: FR-09-011 · API-09-041, 042, 043, 044, 039 · ERR-09-022, 023 · BR-09-008
    # Mục đích: Chứng minh mỗi trường DLCN đã xác nhận thuộc ít nhất một hoạt động `ACTIVE` (BR-09-008).
    Biết T90; 4 trường DLCN `CONFIRMED`, 1 trường chưa thuộc hoạt động; HD-01 `ACTIVE`.
    Khi `GET /processing-activities:unlinked-elements`.
    Và DS1 thêm liên kết trường còn lại vào HD-01 (phiên bản mới, chờ duyệt).
    Và TA gọi `:retire` HD-01 khi còn liên kết.
    Và S-T90-REG kích hoạt hợp đồng chứa trường chưa liên kết (xem TC-09-051).
    Thì bước 1 liệt kê đúng 1 trường. Bước 3 `409` ERR-09-022. Bước 4 `422` ERR-09-023 nêu số trường chưa thuộc hoạt động. Sau khi duyệt, `unlinked-elements` rỗng.

  @TC-09-024 @P2 @Dương @Âm
  Kịch bản: TC-09-024 Xuất sổ theo mẫu và mẫu không tồn tại
    # Truy vết: FR-09-013 · API-09-051, 052, 053 · ERR-09-025 · UI-09-05
    # Mục đích: Chứng minh xuất sổ chạy nền theo mẫu và không chứa dữ liệu cá nhân.
    Biết T90; HD-01 `ACTIVE`; U-T90-SO.
    Khi SO `GET /ropa-templates`; `POST /ropa-exports` mẫu `A05-ROPA` rồi tải tệp.
    Và `POST /ropa-exports` mẫu `khong-co`.
    Thì bước 1 tệp đủ cột mục đích, cơ sở, dữ liệu, bên nhận, thời hạn lưu; không giá trị DLCN; KT: có (ropa-export). Bước 2 `422` ERR-09-025.
