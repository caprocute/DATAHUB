# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-28
Tính năng: TS-08-28 · Cô lập tenant: API, RLS, Kafka, bộ đệm trực tuyến

  @TC-08-130 @P1 @Bảo @mật @Âm
  Kịch bản: TC-08-130 Rò rỉ chéo tenant ở mọi API đọc và ghi
    # Truy vết: FR-08-006 · FR-08-037 · FR-08-051 · API-08-007, 021, 027, 061, 074, 079, 086, 109 · ERR-08-001 · NFR-08-017
    Biết T90 có đối tượng, bộ quy tắc, lần đo, lỗi, phiếu, báo cáo, ngoại lệ, tệp xuất; U-T91-DS1, U-T91-DA1.
    Khi T91 `GET`/`POST` lên id của T90 ở các API: `/assets`, `/profile-runs`, `/rule-sets`, `/scans`, `/findings`, `/waivers`, `/issues`, `/reports`, `/exports`
    Và T91 gọi các thao tác ghi `:approve`, `:cancel`, `:activate` lên id T90
    Và giả mạo tiêu đề `X-Tenant-Id: T90`
    Và so thân phản hồi với id không tồn tại
    Thì mọi lệnh `404` ERR-08-001, thân giống hệt trường hợp "không tồn tại" trừ `traceId` (404-ẩn); dữ liệu T90 không đổi; tenant lấy từ token, tiêu đề giả mạo bị bỏ qua; danh sách của T91 không có dòng nào của T90.

  @TC-08-131 @P1 @Bảo @mật
  Kịch bản: TC-08-131 RLS theo tenant_id ở schema ph08_dq
    # Truy vết: FR-08-060 · BR-08-026 · NFR-08-016
    Biết tệp `03-thiet-ke/csdl/ph08/test/ph08_isolation_test.sql` trên CSDL rỗng đã chạy `ph08_dq.sql`; vai trò `dh_data_app` (không `BYPASSRLS`).
    Khi `psql -v ON_ERROR_STOP=1 -f ph08_isolation_test.sql`
    Và thêm: `SET app.tenant_id = 'T90'` rồi `SELECT` các bảng
    Và không đặt `app.tenant_id`
    Và `INSERT` dòng `tenant_id = 'T91'` khi đang là T90
    Và T90 đọc và sửa `dq_rule_template` của `COMMON`
    Thì tệp chạy hết, mọi dòng `PASS`. Với T90 chỉ thấy dòng T90; không đặt `app.tenant_id` thì 0 dòng; chèn sai tenant bị `42501`; `COMMON` đọc được nhưng sửa bị `42501`.

  @TC-08-132 @P1 @Bảo @mật
  Kịch bản: TC-08-132 ACL Kafka theo tiền tố tenant và nội dung sự kiện
    # Truy vết: FR-08-057 · EVT-08-02 · EVT-08-06 · EVT-08-14 · NFR-08-017
    Biết client T91 OAUTHBEARER; sự kiện EVT-08-02, 06, 14 của T90.
    Khi T91 `subscribe` `t90.dq.scan.completed.v1`
    Và T91 `produce` vào `t90.dq.check.failed.v1`
    Và đọc nội dung bản tin T90 bằng client hợp lệ
    Thì hai bước đầu bị từ chối ACL. Bản tin T90 chỉ có mã đối tượng, số đếm, điểm; không có khóa bản ghi cá nhân và giá trị dữ liệu.

  @TC-08-133 @P1 @Bảo @mật
  Kịch bản: TC-08-133 Bộ đệm quy tắc trực tuyến cô lập theo tenant
    # Truy vết: FR-08-032 · API-08-068 · NFR-08-005 · BR-08-026
    Biết T90 và T91 cùng có `mdm-citizen` với bộ quy tắc khác nhau (T90 yêu cầu `nationalId`, T91 không).
    Khi T90 gọi `POST /checks:evaluate` bản ghi thiếu `nationalId` để nạp bộ đệm
    Và T91 gọi cùng bản ghi
    Và T91 kích hoạt bộ quy tắc mới
    Và T90 gọi lại
    Thì T90 `FAIL`, T91 `PASS`. Kích hoạt của T91 không làm làm mới bộ đệm T90; kết luận T90 không đổi.
