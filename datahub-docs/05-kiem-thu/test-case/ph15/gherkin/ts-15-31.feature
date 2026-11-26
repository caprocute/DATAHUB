# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-31
Tính năng: TS-15-31 · Cô lập tenant

  @TC-15-170 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-170 Mọi API đọc, ghi theo mã trả 404-ẩn giữa T68 và T01
    # Truy vết: NFR-15-017 · BR-15-003, 034 · ERR-15-001 · API-15-004, 024, 057, 073, 077, 089, 093, 096, 112 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết T68 và T01 có cùng mã `tra-cuu-ho-tich`, `app-tra-cuu-ho-tich`, `bat-dau-nhanh`, `HT-2026-0001`; token U-T01-TA, U-T01-DEV qua tên miền T68; danh sách thao tác sinh từ `openapi-portal.yaml`.
    Khi với mọi operation có tham số định danh gọi bằng mã của T68.
    Và với mọi operation ghi lặp lại.
    Và đọc lại dữ liệu T68 bằng token T68; thêm tiêu đề `X-DH-Tenant: T68`.
    Thì mọi lần `404` ERR-15-001, thân giống "không tồn tại" trừ `traceId`, `instance`; dữ liệu T68 không đổi; tiêu đề `X-DH-Tenant` do client gửi bị bỏ qua.

  @TC-15-171 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-171 Danh sách không lẫn tenant
    # Truy vết: NFR-15-017 · BR-15-003 · API-15-005, 055, 075, 104, 111, 121, 128 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết dữ liệu seed cả hai tenant (mỗi loại 3 bản ghi T68, 2 bản ghi T01).
    Khi mỗi danh sách gọi bằng token T01 và bằng token T68.
    Thì token T01 chỉ thấy 2 bản ghi của T01; `total` đếm đúng; không có mã T68.

  @TC-15-172 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-172 Tên miền và token khác tenant
    # Truy vết: BR-15-003 · NFR-15-017 · ERR-15-005 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết tên miền cổng T01 với token realm T68, và ngược lại.
    Khi gọi `GET /me`, `GET /apps`.
    Thì bị từ chối `403` ERR-15-005, không lộ dữ liệu của cả hai tenant (FR-15-008).

  @TC-15-173 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-173 Chỉ mục tìm kiếm, bộ đệm, hạn mức theo tenant
    # Truy vết: NFR-15-017 · FR-15-005 · BR-15-003 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết hai tenant có mục trùng tên; OpenSearch, Valkey thật.
    Khi T01 tìm `q=hộ tịch`, mở trang chủ sau khi T68 đã nạp bộ đệm.
    Và kiểm khóa Valkey và chỉ mục.
    Thì T01 không thấy mục T68; khóa bộ đệm, hạn mức, chỉ mục đều chứa mã tenant; hạn mức của T68 không tiêu của T01.

  @TC-15-174 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-174 RLS, sandbox, sự kiện
    # Truy vết: NFR-15-017 · BR-15-003 · EVT-15-01 · API-15-082 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `ph15_isolation_test.sql`; client `sbx-t01-…`; topic `t68.portal.*`.
    Khi chạy `psql -v ON_ERROR_STOP=1 -f ph15_isolation_test.sql`.
    Và dùng credential `sbx-t01-…` gọi sandbox ở host T68; dùng credential T68 ở host T01.
    Và principal Kafka của T01 đọc `t68.portal.app.created.v1`.
    Thì bài kiểm CSDL toàn `PASS` (không đặt `app.tenant_id` thì 0 dòng; ghi sai tenant bị chặn; bảng nhật ký không sửa được); bước 2 `forward-auth` từ chối; bước 3 bị ACL từ chối.
