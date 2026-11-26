# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-29
Tính năng: TS-06-29 · Cô lập tenant: API, RLS, Kafka, kho tệp

  @TC-06-121 @P1 @Âm @Bảo @mật
  Kịch bản: TC-06-121 Rò rỉ chéo tenant: cấu hình
    # Truy vết: API-06-002, 004, 018, 030, 037, 051, 093, 095 · ERR-06-001 · FR-06-001, 009, 018, 025, 033, 059, 060
    # Mục đích: Chứng minh domain, nguồn, quy tắc, tập nhãn, sống sót, lưu giữ, tham số của T90 là `404-ẩn` với T91.
    Biết T90 và T91 cùng mã domain `CITIZEN`, nguồn `HT-YTE`; U-T91-DS1.
    Khi U-T91-DS1 gọi GET chi tiết, danh sách các API nhóm cấu hình bằng định danh của T90.
    Và gửi `tenant_id` T90 trong thân `PUT /settings`.
    Thì bước 1 danh sách chỉ có dữ liệu T91, chi tiết 404-ẩn thân giống "không tồn tại" trừ `traceId`. Bước 2 `400` hoặc `403` ERR-00-003, không ghi vào T90.
    # Hậu điều kiện: T90 không đổi.

  @TC-06-122 @P1 @Âm @Bảo @mật
  Kịch bản: TC-06-122 Rò rỉ chéo tenant: ứng viên, hàng đợi, bản ghi vàng
    # Truy vết: API-06-026, 027, 045, 046, 056, 063, 065, 066, 060, 061 · ERR-06-001 · FR-06-017, 028, 035, 041, 043, 044
    # Mục đích: Chứng minh ứng viên, mục hàng đợi, bản ghi vàng, lịch sử, lineage, xref, thao tác của T90 là 404-ẩn với T91, kể cả `:claim`, `:undo`, `:approve`.
    Biết đối tượng của T90 đã tạo ở TS-06-10…20; U-T91-DS1, DA1.
    Khi gọi GET và POST hành động của các API trên bằng token T91.
    Thì mọi lệnh `404` ERR-06-001, không đổi trạng thái T90, không dòng `access_log` ở T90.
    # Hậu điều kiện: T90 không đổi.

  @TC-06-123 @P1 @Âm @Bảo @mật
  Kịch bản: TC-06-123 Rò rỉ chéo tenant: tra cứu, resolve, tìm, xuất, nhật ký
    # Truy vết: API-06-068, 069, 070, 071, 072, 074, 076, 088, 089, 091 · ERR-06-001, 050 · FR-06-045…049, 057, 058
    # Mục đích: Chứng minh các API trả dữ liệu không trả bản ghi của tenant khác dù trùng CCCD giả.
    Biết CC-03 có ở cả T90 và T91 với `goldenId` khác; S-T91-READ; tệp xuất T90.
    Khi `lookup`, `resolve`, `search` bằng S-T91-READ.
    Và tải tệp xuất, xem yêu cầu chủ thể, nhật ký của T90.
    Thì bước 1 chỉ trả `goldenId` của T91. Bước 2 `404` ERR-06-001. Tệp xuất ở Garage không truy cập được bằng URL của T91.
    # Hậu điều kiện: Không đổi.

  @TC-06-124 @P1 @Bảo @mật
  Kịch bản: TC-06-124 RLS trên mọi bảng ph06_mdm
    # Truy vết: API-06-001 · NFR-06-016 · BR-06-018
    # Mục đích: Chứng minh RLS theo `tenant_id` ở mọi bảng, kể cả bảng staging và kết quả job.
    Biết `03-thiet-ke/csdl/ph06/test/`; vai CSDL của T90, T91.
    Khi liệt kê bảng `ph06_mdm.*` thiếu `ROW LEVEL SECURITY` hoặc `FORCE`.
    Và với vai T90 đọc, chèn, sửa, xóa dòng T91; chèn dòng `tenant_id` T91.
    Và kiểm vai Job Splink: chỉ đọc `stg_match_*`, chỉ ghi `stg_match_result_*`.
    Thì không bảng thiếu RLS. Đọc thấy 0 dòng T91; chèn và sửa bị chặn `WITH CHECK`; vai nào cũng không có `BYPASSRLS`. Job không đọc được `golden_record`.
    # Hậu điều kiện: Không đổi.

  @TC-06-125 @P1 @Bảo @mật
  Kịch bản: TC-06-125 Cô lập topic và tệp theo tenant
    # Truy vết: EVT-06-01…15 · BR-06-012 · FR-06-050, 049
    # Mục đích: Chứng minh ACL tiền tố `t90.mdm.` và tiền tố kho tệp.
    Biết principal T90, T91; tệp tạm và tệp xuất T90.
    Khi principal T91 đọc, ghi `t90.mdm.golden.updated.v1`.
    Và T91 liệt kê topic.
    Và T91 đọc đối tượng Garage của T90.
    Thì bước 1 bị từ chối (`TOPIC_AUTHORIZATION_FAILED`). Bước 2 không thấy topic T90. Bước 3 `AccessDenied`.
    # Hậu điều kiện: Không đổi.
