# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-01
Tính năng: TS-09-01 · Danh mục mức phân loại, loại dữ liệu cá nhân, tra cứu và xuất

  @TC-09-001 @P2 @Dương @Âm
  Kịch bản: TC-09-001 Xem bốn mức, loại DLCN nạp sẵn và sửa chính sách log của mức
    # Truy vết: FR-09-001, 002 · API-09-001, 002, 007 · ERR-09-003 · UI-09-02 · PERM-09-read, PERM-09-policy
    # Mục đích: Chứng minh `DataClass` có đúng bốn mức thứ hạng 1 đến 4 và 18 loại DLCN nạp sẵn (9 cơ bản, 9 nhạy cảm) theo FRS Phụ lục A.
    Biết T90 mới nạp; U-T90-VW, U-T90-TA.
    Khi VW `GET /data-classes` và `GET /personal-data-categories`.
    Và TA `PATCH /data-classes/INTERNAL` đặt `logPolicy = PARTIAL_MASK`, kèm `If-Match`.
    Và VW gọi lại `PATCH /data-classes/INTERNAL`.
    Và TA `PATCH` thiếu `If-Match`.
    Và TA `PATCH /data-classes/SENSITIVE` đặt `logPolicy = FULL`.
    Thì bước 1 `200`, bốn mức `PUBLIC`, `INTERNAL`, `RESTRICTED`, `SENSITIVE`, 18 loại. Bước 2 `200`, `ETag` mới, KT: có (data-class-update). Bước 3 ERR-00-403 (VW thiếu `PERM-09-policy`). Bước 4 `428` ERR-00-428. Bước 5 `422` ERR-09-003 vì mức `SENSITIVE` luôn `NO_VALUE`.

  @TC-09-002 @P2 @Âm
  Kịch bản: TC-09-002 Thêm loại DLCN trùng mã, ngừng loại đang dùng
    # Truy vết: FR-09-002 · API-09-008, 009 · ERR-09-001, 002, 011 · BR-09-002
    # Mục đích: Chứng minh mã loại duy nhất và loại đang được trường dùng không ngừng được.
    Biết T90; loại `HEALTH` đang gắn 3 phần tử; U-T90-SO.
    Khi SO `POST /personal-data-categories` với `code = HEALTH`.
    Và SO `PATCH /personal-data-categories/HEALTH` đặt `status = RETIRED`.
    Và SO thêm loại `TC_LOAI_MOI` rồi ngừng ngay.
    Và SO `GET /personal-data-categories/TC_LOAI_MOI` sau khi đã `RETIRED`.
    Thì bước 1 `409` ERR-09-002. Bước 2 `409` ERR-09-011, không đổi. Bước 3 thêm `201`, ngừng `200`; KT: có cho cả hai. Bước 4 `410` ERR-09-001 vì đối tượng danh mục đã ngừng.

  @TC-09-003 @P2 @Dương @Âm @Bảo
  Kịch bản: TC-09-003 Xuất danh mục phân loại chạy nền, tải tệp, rò rỉ chéo tenant
    # Truy vết: FR-09-008 · API-09-030, 031 · UI-09-02 · BR-09-060 · ERR-09-001
    # Mục đích: Chứng minh xuất theo bộ lọc có trạng thái nền và không lẫn phần tử tenant khác.
    Biết T90 F-ELM 60 phần tử; T91 có 5 phần tử; U-T90-AU, U-T91-SO.
    Khi AU `POST /classification-exports` lọc `dataClass = SENSITIVE`, rồi hỏi `GET /classification-exports/{id}` đến `READY`.
    Và tải tệp; đếm dòng.
    Và U-T91-SO `GET /classification-exports/{id}` của T90.
    Thì bước 1 `202` rồi `READY`. Bước 2 tệp chỉ có phần tử `SENSITIVE` của T90, không có giá trị dữ liệu, KT: có (classification-export). Bước 3 `404` ERR-09-001, thân giống "không tồn tại".
