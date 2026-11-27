# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-19
Tính năng: TS-07-19 · Rò rỉ chéo tenant trên mọi nhóm API

  @TC-07-220 @P1 @Bảo @mật @Âm
  Kịch bản: TC-07-220 Đọc danh mục và bản ghi của tenant khác
    # Truy vết: FR-00-011 · FR-07-002, 026 · API-07-003, 026
    Biết U-T01-DS; danh mục `TRAM_QUAN_TRAC` chỉ có ở T68.
    Khi U-T01-DS gọi `GET /catalogs/TRAM_QUAN_TRAC`.
    Và U-T01-DS gọi `GET /catalogs/LOAI_HINH_TC/items`.
    Thì bước 1 `404-ẩn` `ERR-07-001`. Bước 2 trả dữ liệu của T01 (tên có hậu tố "(T01)"), không có bản ghi nào của T68.

  @TC-07-221 @P1 @Bảo @mật @Âm
  Kịch bản: TC-07-221 Truy cập phiên bản, bản ghi bằng định danh nội bộ của tenant khác
    # Truy vết: FR-00-011 · API-07-011, 027
    Biết mã UUID của phiên bản v1 CAT-LH (T68) lấy từ CSDL.
    Khi U-T01-DS gọi các API nhận `versionRef` bằng UUID của T68.
    Và U-T01-DS gọi `GET /import-jobs/{jobId của T68}`, `GET /export-jobs/{jobId của T68}`, `GET /sync-runs/{runId của PLATFORM}`.
    Thì mọi lời gọi `404-ẩn`, thời gian phản hồi không khác biệt có ý nghĩa thống kê so với định danh ngẫu nhiên (kiểm 50 lần, chênh trung vị < 20 ms) để không suy ra được sự tồn tại.

  @TC-07-222 @P1 @Bảo @mật @Âm
  Kịch bản: TC-07-222 Ghi vào danh mục của tenant khác
    # Truy vết: FR-00-011 · API-07-004, 012, 028, 031
    Biết U-T01-TA.
    Khi sửa thông tin `TRAM_QUAN_TRAC`; tạo bản nháp; thêm bản ghi; nhập lô với UUID phiên bản của T68.
    Thì mọi lời gọi `404-ẩn`; số dòng trong các bảng của T68 không đổi; KT: không ghi gì cho T68.

  @TC-07-223 @P1 @Bảo @mật
  Kịch bản: TC-07-223 RLS chặn ngay cả khi tầng ứng dụng sai
    # Truy vết: FR-00-011 · D03-03-PH07 §1 · D03-10 §6
    Biết IT kết nối bằng `dh_data_app`, đặt `app.tenant_id = 'T01'`.
    Khi chạy `SELECT count(*)` trên mọi bảng có `tenant_id` của `ph07_rdm`.
    Và chạy `UPDATE ph07_rdm.catalog SET name = 'x' WHERE tenant_id = 'T68'`.
    Và không đặt `app.tenant_id` rồi chạy `SELECT` bất kỳ.
    Thì bước 1 chỉ đếm dòng của T01 và COMMON (bảng mẫu S, P). Bước 2 cập nhật 0 dòng. Bước 3 không trả dữ liệu: coi cả hai dạng là thiếu tenant, hoặc báo lỗi `unrecognized configuration parameter` (kết nối chưa từng đặt biến), hoặc chuỗi rỗng từ `current_setting` (kết nối pool từng `SET LOCAL`, PostgreSQL 18) bị hàm lấy tenant của thư viện dùng chung từ chối (so khớp `tenant_id` không bao giờ đúng với chuỗi rỗng); kiểm thử không được dựa riêng vào dạng lỗi thứ nhất (D03-10, D04-01).

  @TC-07-224 @P1 @Bảo @mật
  Kịch bản: TC-07-224 Vai trò worker chỉ thấy cột hàng đợi
    # Truy vết: FR-00-011 · D03-03-PH07 §3.8 · D03-02-PH07 §4.4
    Biết có tác vụ nhập `UPLOADED` ở T68 và T01.
    Khi `SET LOCAL ROLE ph07_worker; SET LOCAL app.tenant_id = 'PLATFORM'`; chọn các cột hàng đợi.
    Và cùng phiên, chọn cột `file_id` hoặc `summary`.
    Và cùng phiên, cập nhật `status`.
    Thì bước 1 thấy tác vụ của cả hai tenant, chỉ các cột `id`, `tenant_id`, `job_type`, `status`, `lease_owner`, `lease_until`, `created_at`. Bước 2, 3 báo `permission denied`.

  @TC-07-225 @P1 @Bảo @mật
  Kịch bản: TC-07-225 Bộ đệm không trả nhầm tenant
    # Truy vết: FR-00-011 · FR-07-028 · NFR-07-009
    Biết valkey và Caffeine trống.
    Khi APP-T68-READ gọi `GET /catalogs/LOAI_HINH_TC/items/KH01` (nạp đệm).
    Và ngay sau đó APP-T01-READ gọi cùng đường dẫn trên cùng bản sao `dh-data`.
    Và liệt kê khóa Valkey.
    Thì bước 2 trả bản ghi của T01. Bước 3 mọi khóa có tiền tố tenant (`rdm:T68:...`, `rdm:T01:...`); không có khóa thiếu tenant trừ khóa `rdm:COMMON:...`.

  @TC-07-226 @P1 @Bảo @mật @Âm
  Kịch bản: TC-07-226 Ảnh chụp và URL ký sẵn của tenant khác
    # Truy vết: FR-00-011 · FR-07-028 · API-07-049
    Biết URL ký sẵn ảnh chụp v1 CAT-LH của T68.
    Khi APP-T01-READ gọi `GET /catalogs/TRAM_QUAN_TRAC/snapshots/1`.
    Và dùng khóa truy cập của bucket `dh-t01-rdm` đọc đối tượng trong `dh-t68-rdm`.
    Và dùng URL ký sẵn sau 16 phút.
    Thì bước 1 `404-ẩn`. Bước 2 `AccessDenied`. Bước 3 `403` (URL hết hạn sau 15 phút).

  @TC-07-227 @P1 @Bảo @mật @Âm
  Kịch bản: TC-07-227 Tệp xuất, tệp nhập của tenant khác
    # Truy vết: FR-00-011 · FR-07-021, 024 · API-07-034, 039
    Biết tác vụ xuất `COMPLETED` của T68.
    Khi U-T01-TA gọi `GET /export-jobs/{id}` và đường dẫn tải tệp.
    Và U-T01-TA gọi `GET /import-jobs/{id}/rows` với tác vụ nhập của T68.
    Thì mọi lời gọi `404-ẩn`.

  @TC-07-228 @P1 @Bảo @mật
  Kịch bản: TC-07-228 Truy vấn DSL, tìm kiếm, cây không vượt tenant
    # Truy vết: FR-00-011 · FR-07-030, 032 · API-07-044, 045, 047
    Biết APP-T01-READ được cấp `rdm.query` trong ca.
    Khi gọi `items:query` không lọc trên `LOAI_HINH_TC`.
    Và gọi `items:search?q=khoi`.
    Và gọi `tree`.
    Thì mọi kết quả chỉ có bản ghi "(T01)".

  @TC-07-229 @P1 @Bảo @mật @Âm
  Kịch bản: TC-07-229 Ánh xạ và hệ thống mã của tenant khác
    # Truy vết: FR-00-011 · FR-07-040…042
    Biết `CS-BHXH-DT` chỉ có ở T68.
    Khi APP-T01-READ gọi `mappings:translate` với `codeSystem = CS-BHXH-DT`.
    Và U-T01-TA gọi `GET /code-systems/CS-BHXH-DT`.
    Thì `404` `ERR-07-045` cho cả hai.

  @TC-07-230 @P1 @Bảo @mật
  Kịch bản: TC-07-230 Lịch sử kiểm toán không lộ tenant khác
    # Truy vết: FR-00-011 · FR-07-050 · API-07-072
    Biết U-T01-DS (vai trò AU thử thêm U-T01-AU).
    Khi `GET /catalogs/LOAI_HINH_TC/history`.
    Thì chỉ có mục của T01; không có `actor` thuộc realm `t68`.

  @TC-07-231 @P1 @Bảo @mật @Âm
  Kịch bản: TC-07-231 Tiêu đề tenant giả mạo
    # Truy vết: FR-00-011 · D03-10 §6
    Biết token của U-T01-DS.
    Khi gửi thêm tiêu đề `X-Tenant-Id: T68` và tham số `?tenant=T68`.
    Và gửi token có claim `tenant = T68` nhưng ký bằng khóa không hợp lệ.
    Thì bước 1: tiêu đề và tham số bị bỏ qua, dữ liệu trả về là của T01. Bước 2 `401` `ERR-07-041`.

  @TC-07-232 @P1 @Bảo @mật
  Kịch bản: TC-07-232 Đồng thời hai tenant trên cùng luồng xử lý
    # Truy vết: FR-00-011 · D03-02-PH07 §6
    Biết một bản sao `dh-data`, pool 4 kết nối, luồng ảo bật.
    Khi gửi xen kẽ 2.000 yêu cầu của T68 và T01 trong 30 giây với 64 luồng song song.
    Thì mọi phản hồi khớp tenant của token (kiểm theo hậu tố "(T01)"); `app.tenant_id` được đặt lại mỗi giao dịch (kiểm bằng nhật ký `TenantAwareTransactionManager` ở mức DEBUG trong IT).

  @TC-07-233 @P1 @Bảo @mật
  Kịch bản: TC-07-233 Tác vụ nền giữ đúng tenant
    # Truy vết: FR-00-011 · FR-07-021, 036
    Biết một tác vụ nhập T68, một tác vụ nhập T01 cùng lúc; worker lấy cả hai.
    Khi chạy hai tác vụ tới `COMMITTED`.
    Thì mỗi tác vụ ghi vào đúng bản nháp của tenant mình; sự kiện EVT-07-07 nằm trên đúng topic `t68.*`, `t01.*`; tệp tạm nằm đúng bucket.
