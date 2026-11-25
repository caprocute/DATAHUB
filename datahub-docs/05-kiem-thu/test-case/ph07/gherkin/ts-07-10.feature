# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-10
Tính năng: TS-07-10 · Nhập bản ghi qua API theo lô, idempotency

  @TC-07-125 @P1 @Dương
  Kịch bản: TC-07-125 Lô thao tác hợp lệ
    # Truy vết: FR-07-023 · API-07-031 · UC-07-05 · LGC-DMDC-008
    Biết lô 100 thao tác: 60 `upsert` mới, 30 `upsert` sửa, 10 `deprecate`.
    Khi gọi `POST /catalogs/LOAI_HINH_TC/versions/draft/items:batch` với `Idempotency-Key: b-125`, thân `{"operations":[{"op":"upsert","item":{...}},{"op":"deprecate","code":"...","replacedBy":[...]}]}`.
    Thì `200`, kết quả từng thao tác theo chỉ số (`index`, `code`, `result` ∈ `INSERTED`/`UPDATED`/`DEPRECATED`/`UNCHANGED`). Bản nháp phản ánh đủ 100 thao tác. KT: có một bản ghi kiểm toán cho lô (chủ thể là HTTT `HT-NOIVU`, số thao tác). EVT: không (chỉ phát khi phát hành).

  @TC-07-126 @P1 @Âm @Biên
  Kịch bản: TC-07-126 Lô vượt kích thước tối đa
    # Truy vết: FR-07-023 · ERR-07-026
    Biết lô 5.000 và 5.001 thao tác.
    Khi gửi lô 5.000.
    Và gửi lô 5.001.
    Thì bước 1 trả `200`. Bước 2 trả `400` `ERR-07-026` trước khi xử lý bất kỳ thao tác nào.

  @TC-07-127 @P1 @Dương @Âm
  Kịch bản: TC-07-127 Phát lại cùng khóa idempotent và dùng lại khóa với nội dung khác
    # Truy vết: FR-07-023 · ERR-07-022
    Biết đã chạy TC-07-125 với `b-125`.
    Khi gửi lại nguyên văn lô với `b-125`.
    Và gửi lô khác nội dung với `b-125`.
    Và gửi hai yêu cầu cùng khóa mới `b-127` đồng thời.
    Thì bước 1 trả phản hồi giống lần đầu, không ghi lại, không thêm kiểm toán. Bước 2 trả `409` `ERR-07-022`. Bước 3: một yêu cầu được xử lý, yêu cầu kia nhận cùng kết quả hoặc `409` "đang xử lý" theo D03-04; bản nháp chỉ chịu tác động một lần.

  @TC-07-128 @P1 @Âm
  Kịch bản: TC-07-128 Lô có thao tác lỗi bị từ chối toàn bộ
    # Truy vết: FR-07-023 · BR-07-015 · ERR-07-009
    Biết lô 50 thao tác, thao tác chỉ số 17 sai kiểu `ngay_thanh_lap`, chỉ số 42 có mã cha không tồn tại.
    Khi gửi lô.
    Thì `422` `ERR-07-009`, `errors` có `index` 17 và 42 kèm mã lỗi con (ERR-07-009, ERR-07-010). Không thao tác nào được ghi.

  @TC-07-129 @P2 @Âm
  Kịch bản: TC-07-129 Lô ghi vào phiên bản không phải bản nháp hoặc danh mục chỉ đọc
    # Truy vết: FR-07-023 · ERR-07-004, ERR-07-003
    Biết CAT-LH v1 PUBLISHED; `GIOI_TINH` COMMON.
    Khi gửi lô vào `/catalogs/LOAI_HINH_TC/versions/1/items:batch`.
    Và gửi lô vào `/catalogs/GIOI_TINH/versions/draft/items:batch`.
    Thì bước 1 trả `409` `ERR-07-004`. Bước 2 trả `403` `ERR-07-003`.

  @TC-07-130 @P1 @Âm @Bảo @mật
  Kịch bản: TC-07-130 Ứng dụng thiếu scope ghi
    # Truy vết: FR-07-023 · khung §14.2 (scope)
    Biết APP-T68-READ (chỉ `rdm.read`), APP-T68-NOSCOPE.
    Khi mỗi ứng dụng gửi lô hợp lệ.
    Và APP-T68-WRITE gọi `POST /catalogs` (API quản trị tạo danh mục).
    Thì bước 1 trả 403-PQ (thiếu scope). Bước 2 trả 403-PQ (scope `rdm.write` chỉ cho nhập lô vào bản nháp, không cho thao tác quản trị khác).
