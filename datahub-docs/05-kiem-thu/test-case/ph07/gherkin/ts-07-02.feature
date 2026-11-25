# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-02
Tính năng: TS-07-02 · Nhóm danh mục

  @TC-07-019 @P2 @Dương
  Kịch bản: TC-07-019 Tạo nhóm con và xem cây nhóm
    # Truy vết: FR-07-010 · API-07-007, 008 · UI-07-01
    Biết như chung.
    Khi gọi `POST /catalog-groups` thân `{"code":"TC019_NHOM","name":"Nhóm thử","parentId":"<id HANH_CHINH>","sortOrder":5}`.
    Và gọi `GET /catalog-groups`.
    Và trên UI-07-01, mở rộng nút "Hành chính" ở khung trái.
    Thì bước 1 trả `201`. Bước 2 trả cây có `TC019_NHOM` dưới `HANH_CHINH`, sắp theo `sortOrder`, mỗi nút có số danh mục. Giao diện hiển thị nhóm mới, bấm vào lọc bảng danh mục theo nhóm (FR-07-001). KT: có (CREATE catalog_group).

  @TC-07-020 @P3 @Âm
  Kịch bản: TC-07-020 Di chuyển nhóm tạo vòng trong cây nhóm
    # Truy vết: FR-07-010 · API-07-009 · ERR-07-039
    Biết `HANH_CHINH` là cha của `HANH_CHINH.TO_CHUC`.
    Khi gọi `PATCH /catalog-groups/<id HANH_CHINH>` với `parentId` = id của `HANH_CHINH.TO_CHUC`, `If-Match` đúng.
    Thì `409` `ERR-07-039` (chi tiết "tạo vòng trong cây nhóm"). Cây không đổi.

  @TC-07-021 @P3 @Dương
  Kịch bản: TC-07-021 Xóa nhóm rỗng
    # Truy vết: FR-07-010 · API-07-010
    Biết `TC019_NHOM` rỗng.
    Khi gọi `DELETE /catalog-groups/<id TC019_NHOM>`.
    Thì `204`; nhóm không còn trong cây. KT: có (DELETE catalog_group).

  @TC-07-022 @P2 @Âm
  Kịch bản: TC-07-022 Không xóa được nhóm còn danh mục
    # Truy vết: FR-07-010 · API-07-010 · ERR-07-037
    Biết `HANH_CHINH` chứa 2 danh mục.
    Khi gọi `DELETE /catalog-groups/<id HANH_CHINH>`.
    Thì `409`, `ERR-07-037`, chi tiết nêu số danh mục còn lại. Nhóm giữ nguyên.

  @TC-07-023 @P3 @Âm
  Kịch bản: TC-07-023 Tạo nhóm trùng mã
    # Truy vết: FR-07-010 · API-07-008 · ERR-07-039
    Biết nhóm `HANH_CHINH` tồn tại.
    Khi gọi `POST /catalog-groups` với `code` = `hanh_chinh`.
    Thì `409` `ERR-07-039` (chi tiết chỉ rõ trường `code`). Không tạo nhóm mới.
