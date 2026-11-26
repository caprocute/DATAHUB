# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-02
Tính năng: TS-09-02 · Đăng ký phần tử dữ liệu từ lược đồ và khai báo MVP

  @TC-09-004 @P1 @Dương
  Kịch bản: TC-09-004 Đăng ký phần tử hàng loạt qua scope `privacy:register`
    # Truy vết: FR-09-003 · API-09-012, 010, 011 · UI-09-02 · BR-09-001
    # Mục đích: Chứng minh phần tử mới chưa phân loại được xử lý như `SENSITIVE` (BR-09-001) cho đến khi `CONFIRMED`.
    Biết T90; S-T90-REG; PH-06 giả lập gửi 20 phần tử `INTERNAL_ENTITY`.
    Khi S-T90-REG `POST /data-elements:register` 20 phần tử, `Idempotency-Key` K1.
    Và gửi lại đúng yêu cầu với K1.
    Và `GET /data-elements?status=ACTIVE&unclassified=true` rồi `GET /data-elements/{id}`.
    Thì bước 1 `201`, 20 phần tử `ACTIVE`. Bước 2 `200` cùng kết quả, không tạo thêm. Bước 3 20 phần tử, `effectiveClass = SENSITIVE`, `provisional = true`; KT: có (element-register).

  @TC-09-005 @P1 @Dương @Âm
  Kịch bản: TC-09-005 Nhập lược đồ, khai báo MVP và lược đồ hỏng
    # Truy vết: FR-09-003 · API-09-013, 014 · BR-09-007 · ERR-09-015, 003, 014
    # Mục đích: Chứng minh khai báo MVP nhập ở `PROPOSED`, giữ nguyên mức đã khai; lược đồ hỏng và phần tử trùng bị từ chối.
    Biết T90; tệp `hs-suc-khoe.openapi.yaml` (14 trường), `ca.avsc` (6 trường), `hong.json`; khai báo `x-dh-classification` ở 5 trường; U-T90-DS1.
    Khi DS1 `POST /data-elements:import-schema` với từng tệp.
    Và DS1 `POST /data-elements:import-declarations` với 5 khai báo.
    Và DS1 nhập lại `hs-suc-khoe.openapi.yaml`.
    Và DS1 đăng ký phần tử trỏ tới hợp đồng không có.
    Thì bước 1 OpenAPI và Avro `201` (20 phần tử), `hong.json` `422` ERR-09-015, không tạo phần tử. Bước 2 5 phần tử `ClassificationStatus = PROPOSED`, `source = MVP_IMPORT`, mức đúng như khai. Bước 3 `409` ERR-09-014. Bước 4 `400` ERR-09-003.

  @TC-09-006 @P2 @Âm
  Kịch bản: TC-09-006 Ngừng phần tử đang thuộc hoạt động xử lý rồi ngừng sau khi gỡ liên kết
    # Truy vết: FR-09-003 · API-09-010, 243 · ERR-09-006 · UI-09-03
    # Mục đích: Chứng minh phần tử đang được hoạt động hoặc hợp đồng dùng không ngừng được.
    Biết T90; phần tử `cccd` thuộc hoạt động `ACTIVE` HD-01.
    Khi DS1 mở UI-09-03, tab "Hoạt động liên kết" của phần tử `cccd`, bấm "Ngừng phần tử" kèm lý do.
    Và SO của tổ chức sở hữu gỡ liên kết với HD-01 rồi `POST /data-elements/{id}:retire` (API-09-243).
    Thì bước 1 giao diện hiện số liên kết, gọi API trả `409` ERR-09-006, phần tử vẫn `ACTIVE`. Bước 2 `200`, `RETIRED`, lịch sử phân loại còn nguyên.
