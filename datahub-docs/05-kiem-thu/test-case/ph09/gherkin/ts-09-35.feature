# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-35
Tính năng: TS-09-35 · Cô lập tenant: API, RLS, data plane, Kafka, khóa

  @TC-09-119 @P1 @Âm @Bảo @mật
  Kịch bản: TC-09-119 Rò rỉ chéo tenant: phân loại, sổ xử lý, mục đích, chính sách che, miền, lịch, tham số
    # Truy vết: NFR-09-019 · FR-09-003, 004, 009, 014, 024, 031, 040, 064 · API-09-011, 034, 054, 094, 111, 147, 224 · ERR-09-001 · BR-09-060
    # Mục đích: Chứng minh nhóm API cấu hình của T90 là `404-ẩn` với T91 và danh sách chỉ có dữ liệu T91.
    Biết T90 và T91 cùng mã phần tử `cccd`, mục đích `MD-TRACUU-HGD`, miền `PD-HGD`; U-T91-TA, U-T91-SO.
    Khi U-T91-SO gọi GET chi tiết và danh sách các API trên bằng định danh của T90.
    Và U-T91-TA `PUT /settings` với `tenant_id` T90 trong thân.
    Thì bước 1 danh sách chỉ T91; chi tiết `404-ẩn` ERR-09-001. Bước 2 `400` hoặc `403`, không ghi vào T90. T90 không đổi.

  @TC-09-120 @P1 @Âm @Bảo @mật
  Kịch bản: TC-09-120 Rò rỉ chéo tenant: yêu cầu, chấp thuận, khôi phục, chủ thể, vi phạm, đồng ý, DPIA, nhật ký
    # Truy vết: NFR-09-019 · FR-09-015, 017, 033, 045, 053, 055, 058, 061 · API-09-060, 068, 121, 166, 191, 194, 204, 216 · ERR-09-001 · BR-09-060
    # Mục đích: Chứng minh đối tượng nghiệp vụ và nhật ký của T90 là `404-ẩn` kể cả với thao tác `:revoke`, `:execute`, `:close`.
    Biết đối tượng T90 tạo ở TS-09-09…33; U-T91-DO1, U-T91-SO, U-T91-AU.
    Khi gọi GET và POST hành động các API trên bằng token T91 với định danh của T90.
    Và U-T91-AU `GET /audit-events` đúng khoảng thời gian có sự kiện T90.
    Thì mọi lệnh `404` ERR-09-001, không đổi trạng thái T90, thân giống "không tồn tại" trừ `traceId`. Bước 2 không có bản ghi T90.

  @TC-09-121 @P1 @Âm @Bảo @mật
  Kịch bản: TC-09-121 RLS CSDL: mọi bảng `ph09_privacy` bật RLS, không ngữ cảnh tenant thì không thấy hàng
    # Truy vết: NFR-09-019 · BR-09-060 · FR-09-061
    # Mục đích: Chứng minh RLS theo `tenant_id` đủ mọi bảng.
    Biết schema `ph09_privacy` trên `ph09_test`; vai ứng dụng `dh_data_app`; 20 hàng T90, 20 hàng T91 mỗi bảng; `psql` với `03-thiet-ke/csdl/ph09/test/`.
    Khi truy `pg_class`, `pg_policies` để liệt kê bảng thiếu RLS hoặc thiếu chính sách.
    Và đặt `app.tenant_id = T90`; `SELECT` mọi bảng; thử `INSERT` hàng mang `tenant_id` T91; thử `UPDATE`, `DELETE` hàng T91.
    Và không đặt `app.tenant_id`; `SELECT` mọi bảng.
    Thì bước 1 0 bảng thiếu. Bước 2 chỉ thấy 20 hàng T90; INSERT, UPDATE, DELETE hàng T91 bị từ chối hoặc 0 hàng. Bước 3 0 hàng.

  @TC-09-122 @P1 @Âm @Bảo @mật
  Kịch bản: TC-09-122 Data plane: token T91 không lấy được kế hoạch, bundle, chỉ mục của T90
    # Truy vết: NFR-09-019 · API-09-227, 228, 232, 233, 234, 235, 236 · BR-09-060 · ERR-09-111
    # Mục đích: Chứng minh điểm thực thi chỉ nhận dữ liệu của tenant mình và băm chủ thể khác nhau giữa tenant.
    Biết T90, T91; S-T91-PEP (scope `privacy:decide` của T91); S-T91-CONSENT.
    Khi S-T91-PEP gọi `mask-plans:resolve`, `classification-index`, `bundles/current`, `purpose:decide` với `contract` chỉ có ở T90.
    Và S-T91-CONSENT gọi `consents:check` với băm chủ thể của T90.
    Và cùng CCCD `001090000101` gọi `subject-hashes:compute` ở T90 và T91.
    Thì bước 1 dữ liệu chỉ của T91; hợp đồng T90 không tồn tại với T91 (`403` ERR-09-102 hoặc `404-ẩn`). Bước 2 `GIVEN = false`. Bước 3 hai băm khác nhau (khóa theo tenant).

  @TC-09-123 @P1 @Âm @Bảo @mật
  Kịch bản: TC-09-123 Topic `{tenant}.privacy.*`, ACL tiền tố và khóa mật mã theo tenant
    # Truy vết: NFR-09-019 · EVT-09-01…32 · BR-09-060, 028
    # Mục đích: Chứng minh ACL Kafka theo tiền tố và khóa giả danh riêng từng tenant.
    Biết T90, T91; client OAUTHBEARER của mỗi tenant; `PD-HGD` ở cả hai tenant.
    Khi consumer T91 đọc `t90.privacy.purpose-grant.approved.v1`; producer T91 ghi vào `t90.privacy.*`.
    Và cùng giá trị CCCD giả qua `pseudonyms:issue` ở T90 và T91.
    Thì bước 1 `TOPIC_AUTHORIZATION_FAILED` cả hai chiều. Bước 2 hai bí danh khác nhau; khóa trong OpenBao mang mã tenant khác nhau.
