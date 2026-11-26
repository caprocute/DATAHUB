# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-31
Tính năng: TS-19-31 · Cách ly tenant và RLS

  @TC-19-751 @P1 @Bảo @mật
  Kịch bản: TC-19-751 Quét 100% API đọc, ghi chéo tenant
    # Truy vết: NFR-19-025 · API-19-001…110
    Biết bộ sinh ca từ OpenAPI: với mỗi thao tác có tham số đường dẫn, dùng mã đối tượng của T68 và danh tính của T99 (U-ADM1-T99, C-DVC-T99).
    Khi chạy toàn bộ thao tác đọc.
    Và chạy toàn bộ thao tác ghi (có `Idempotency-Key`, `If-Match` hợp lệ của T68).
    Thì 100% thao tác trả 404-ẩn (đọc) hoặc 404-ẩn, 403 (ghi); không đối tượng nào của T68 thay đổi; báo cáo liệt kê số thao tác đã quét bằng số thao tác trong OpenAPI.

  @TC-19-752 @P1 @Bảo @mật
  Kịch bản: TC-19-752 Tiêu đề tenant giả
    # Truy vết: NFR-19-025 · D03-10
    Biết U-ADM1-T99.
    Khi gửi `X-Tenant-Id: T68` kèm token T99 tới API-19-001, 051.
    Thì tenant lấy từ claim của token; tiêu đề giả bị APISIX gỡ; trả dữ liệu T99 hoặc `403`; sự kiện an ninh.

  @TC-19-753 @P1 @Bảo @mật
  Kịch bản: TC-19-753 RLS FORCE trên mọi bảng
    # Truy vết: NFR-19-025 · D03-03-PH19
    Biết kết nối `ph19_app` đặt `app.tenant_id = 'T99'`.
    Khi truy vấn `pg_class` liệt kê bảng của `ph19_payment` không có `relrowsecurity` và `relforcerowsecurity`.
    Và `SELECT count(*)` từng bảng; `UPDATE` một bản ghi của T68 theo khóa chính.
    Và kết nối không đặt `app.tenant_id`.
    Thì bước 1: rỗng. Bước 2: chỉ thấy dữ liệu T99; `UPDATE` 0 dòng. Bước 3: 0 dòng ở mọi bảng (mặc định từ chối).

  @TC-19-754 @P1 @Bảo @mật
  Kịch bản: TC-19-754 Valkey, Kafka, kho đối tượng, khóa ký theo tenant
    # Truy vết: NFR-19-025, 022
    Biết thông tin xác thực dịch vụ của T99.
    Khi liệt kê khóa Valkey `t68:payment:*` bằng ACL của T99.
    Và tiêu thụ topic `t68.payment.transaction.succeeded.v1` bằng principal của T99.
    Và đọc `dh-t68-payment` bằng khóa truy cập của T99.
    Và đọc `kv/dh/t68/payment/` bằng vai trò OpenBao của T99.
    Thì cả bốn bị từ chối, có bản ghi từ chối ở hệ tương ứng.

  @TC-19-755 @P1 @Bảo @mật
  Kịch bản: TC-19-755 Xác định tenant cho callback chỉ theo connectionKey
    # Truy vết: NFR-19-025 · ADR-045 · API-19-201
    Biết hai tenant T68, T99 cùng dùng PayGov với `connectionKey` khác nhau; giao dịch `PENDING` ở T68.
    Khi gửi IPN của giao dịch T68 tới `connectionKey` của T99, ký bằng khóa của T99.
    Thì IPN `QUARANTINED` lý do `NOT_FOUND` ở T99; giao dịch của T68 không đổi.

  @TC-19-756 @P2 @Bảo @mật
  Kịch bản: TC-19-756 Hạn mức tốc độ riêng mỗi tenant
    # Truy vết: NFR-19-025 · ERR-19-048
    Biết hạn mức thử 50 yêu cầu/giây mỗi tenant.
    Khi bắn 200 yêu cầu/giây vào T99; đồng thời 20 yêu cầu/giây vào T68.
    Thì T99 nhận `429` ERR-19-048 có `Retry-After`; T68 không có `429`, p95 không đổi quá 10%.
