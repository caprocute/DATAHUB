# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-32
Tính năng: TS-05-32 · Cách ly tenant và RLS

  @TC-05-123 @P1 @Bảo @mật
  Kịch bản: TC-05-123 Mọi API đọc trả 404-ẩn hoặc rỗng với đối tượng tenant khác
    # Truy vết: BR-05-002 · ERR-05-001 · API-05-005, 010, 019, 025, 035, 045, 049, 053, 067, 077
    Biết U-T01-IE; mọi đối tượng mẫu của T68 (mục 2.3) với mã trùng ở T01 khi có.
    Thì API chi tiết 404-ẩn; API danh sách không có mục nào của T68; với mã trùng `ndxp-ho-tich`, trả đúng bản T01 (`baseUrl` T01). Danh sách API sinh từ OpenAPI để không sót.

  @TC-05-124 @P1 @Bảo @mật
  Kịch bản: TC-05-124 Bài kiểm cô lập CSDL 23 khối
    # Truy vết: BR-05-002 · NFR-05-011
    Biết `ph05_adapter.sql` đã áp; dữ liệu mẫu T68, T01, COMMON.
    Thì 23 khối `PASS`: đặt `app.tenant_id = T68` không đọc, sửa được dòng T01 ở 20 bảng chế độ P; đọc được Kamelet `COMMON` nhưng không ghi được (chế độ S); thiếu `app.tenant_id` thì 0 dòng; `outbox` không nhận tiêu đề có chuỗi giống bí mật.

  @TC-05-125 @P1 @Bảo @mật
  Kịch bản: TC-05-125 Bảng chỉ thêm không sửa, xóa được
    # Truy vết: FR-05-027 · NFR-05-015
    Biết role `dh_integration_app`; dòng mẫu ở `db_access_record`, `connection_test`.
    Thì trigger `tg_append_only` chặn `db_access_record`; `tg_adapter_version_frozen` chặn phiên bản đã duyệt; cả hai báo lỗi có mã nghiệp vụ.

  @TC-05-126 @P1 @Bảo @mật
  Kịch bản: TC-05-126 Tiêu đề tenant giả từ bên gọi bị bỏ qua
    # Truy vết: BR-05-002 · API-05-003, 032
    Biết U-T68-IE1; S-RT-T68.
    Thì kết quả của T68 (tenant lấy từ token); runtime ghi đè `dh-tenant` bằng tenant của mình, lượt gọi dùng kết nối của T68.
