# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-22
Tính năng: TS-07-22 · Di trú dữ liệu Aita

  @TC-07-260 @P1 @Dương
  Kịch bản: TC-07-260 Chạy thử sinh báo cáo, không ghi dữ liệu
    # Truy vết: FR-07-051 · FR-00-090 · LGC-DMDC-001…019
    Biết 40 danh mục Aita.
    Khi chạy công cụ ở chế độ chạy thử.
    Thì tác vụ loại `MIGRATION` hiện ở UI-07-08; báo cáo có 40 dòng, mỗi dòng một quyết định đề xuất, mã đề xuất, kiểu thuộc tính suy ra, vấn đề; số danh mục trong `ph07_rdm.catalog` của T68 không đổi.

  @TC-07-261 @P1 @Dương
  Kịch bản: TC-07-261 Suy kiểu thuộc tính và đề xuất cột mã, cột cha
    # Truy vết: FR-07-051 bước 4…6 · FR-07-022
    Biết bảng giá trị mẫu cho từng kiểu (BOOLEAN có ít nhất hai giá trị, INTEGER có số 0 đầu, ngày `31/02/2024`, ENUM ≤ 20 giá trị trên ≥ 100 dòng).
    Khi chạy bộ suy kiểu trên từng cột mẫu.
    Thì kiểu khớp bảng ở FR-07-051 bước 6; cột toàn `1` không thành BOOLEAN; mã có số 0 đầu thành STRING; ngày không có thật làm cột thành STRING.

  @TC-07-262 @P1 @Dương
  Kịch bản: TC-07-262 Đối chiếu COMMON: dùng chung, HYBRID, đồng bộ
    # Truy vết: FR-07-051 bước 7 · FR-07-048 · LGC-DMDC-017, 019
    Biết aita có "Giới tính" trùng COMMON, "Dân tộc" có 2 mã bổ sung, một danh mục `is_update = 1`.
    Khi chạy thử.
    Thì "Giới tính" đề xuất "dùng COMMON kèm ánh xạ" với hệ thống mã `AITA_T68`; "Dân tộc" đề xuất HYBRID cho 2 mã; danh mục `is_update = 1` đề xuất đăng ký đồng bộ quốc gia.

  @TC-07-263 @P1 @Âm
  Kịch bản: TC-07-263 Phát hiện dữ liệu cá nhân
    # Truy vết: FR-07-051 bước 8 · BR-07-025 · ERR-07-036
    Biết một danh mục Aita có cột "Số CCCD" chứa chuỗi 12 chữ số.
    Khi chạy thử.
    Và chạy thật mà không bỏ thuộc tính đó.
    Thì bước 1 báo vấn đề "dữ liệu cá nhân", đề xuất loại bỏ. Bước 2 danh mục đó bị bỏ qua với `ERR-07-036`, các danh mục khác vẫn chạy.

  @TC-07-264 @P1 @Dương
  Kịch bản: TC-07-264 Chạy thật đi qua API, chờ duyệt theo lô
    # Truy vết: FR-07-051 bước 10, 11 · API-07-002, 014, 017, 031 · BR-07-011, 027
    Biết cấu hình đã chốt sau TC-07-260.
    Khi chạy thật.
    Và U-T68-DA1 duyệt và phát hành các phiên bản di trú trên UI-07-07.
    Thì bước 1 tạo danh mục với `legacy_ref`, phiên bản 1 `origin = MIGRATION` ở `IN_REVIEW`; kiểm toán của từng API có chủ thể U-T68-TA. Bước 2 phát hành được, cho phép `effectiveFrom` hồi tố theo BR-07-027; U-T68-TA không duyệt được (bốn mắt).

  @TC-07-265 @P1 @Âm
  Kịch bản: TC-07-265 Đối soát phát hiện chênh lệch
    # Truy vết: FR-07-051 bước 12 · FR-00-091
    Biết sau TC-07-264, xóa tay một bản ghi và sửa một ô trong Datahub (trên bản sao CSDL thử).
    Khi chạy đối soát.
    Thì biên bản (PDF, Excel) tô đỏ hai danh mục lệch, nêu số bản ghi lệch và ô có băm SHA-256 khác; trạng thái "chưa ký được".

  @TC-07-266 @P1 @Dương
  Kịch bản: TC-07-266 Chạy lại không nạp trùng
    # Truy vết: FR-07-051 bước 13 · FR-00-092
    Biết chạy thật bị ngắt giữa lô thứ 2 của danh mục lớn.
    Khi chạy lại công cụ.
    Thì danh mục đã có `legacy_ref` không tạo lại; lô đã nạp được bỏ qua nhờ `Idempotency-Key`; tổng số bản ghi khớp nguồn.

  @TC-07-267 @P2 @Âm @Biên
  Kịch bản: TC-07-267 Bản kết xuất thiếu bảng hoặc dữ liệu biên
    # Truy vết: FR-07-051 bước 1 · ERR-07-008, 009
    Biết (a) Bản kết xuất thiếu bảng `category_details_value`; (b) danh mục có giá trị dài 2.000 ký tự, mã " ab01" và "AB01".
    Khi chạy thử với (a).
    Và chạy thử với (b).
    Thì bước 1 dừng với báo cáo lỗi, không ghi gì. Bước 2 giá trị 2.000 ký tự giữ nguyên (thuộc tính TEXT hoặc STRING 2.000); hai mã trùng sau chuẩn hóa bị báo vấn đề `ERR-07-008`, cột đó không được chọn làm cột mã.
