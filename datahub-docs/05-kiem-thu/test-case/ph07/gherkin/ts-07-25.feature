# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-25
Tính năng: TS-07-25 · Bộ đệm, ảnh chụp và chịu lỗi

  @TC-07-275 @P1 @Dương
  Kịch bản: TC-07-275 Phát hành làm mới bộ đệm mọi pod
    # Truy vết: FR-07-016, 026 · NFR-07-009
    Biết ba pod đã đệm CAT-MUC v1.
    Khi phát hành v2 đổi tên một bản ghi.
    Và sau 5 giây, gọi tra bản ghi đó trên từng pod.
    Thì cả ba pod trả tên mới; khóa của v1 trong Valkey vẫn còn (phiên bản bất biến) nhưng con trỏ "phiên bản hiện hành" đã đổi.

  @TC-07-276 @P1 @Hiệu @năng
  Kịch bản: TC-07-276 Tỷ lệ trúng đệm ổn định và phục hồi sau khởi động lại
    # Truy vết: NFR-07-009
    Biết PERF; tải đọc 2.000 lượt/giây phân bố Zipf trên 1.000 danh mục.
    Khi chạy 30 phút, đọc `rdm_cache_hit_ratio`.
    Và khởi động lại toàn bộ pod, tiếp tục tải 15 phút.
    Thì bước 1 ≥ 95%. Bước 2 trở lại ≥ 95% trong ≤ 10 phút; không có lỗi `5xx`.

  @TC-07-277 @P1 @Khả @dụng
  Kịch bản: TC-07-277 PostgreSQL ngừng: tra cứu phục vụ từ L2 và ảnh chụp
    # Truy vết: NFR-07-010 · ADR-053
    Biết SIT; bộ đệm ấm.
    Khi chaos Mesh dừng PostgreSQL chính và bản sao trong 60 phút; giữ tải tra cứu 500 lượt/giây.
    Và trong thời gian đó, gọi một API ghi.
    Thì tra cứu mã đã có trong L2 hoặc ảnh chụp trả `200` với tiêu đề `X-Rdm-Degraded: true`; tỷ lệ lỗi tra cứu < 0,1%. API ghi trả `503` `ERR-07-047`. Cảnh báo `RdmDatabaseDown` bật.

  @TC-07-278 @P2 @Khả @dụng
  Kịch bản: TC-07-278 Valkey ngừng
    # Truy vết: NFR-07-010
    Biết SIT.
    Khi dừng cả ba nút Valkey 10 phút dưới tải 1.000 lượt/giây.
    Thì không có lỗi `5xx`; p95 tra một mã ≤ 50 ms (đọc L1 hoặc CSDL); circuit breaker Valkey mở và đóng lại khi Valkey trở lại.

  @TC-07-279 @P2 @Khả @dụng
  Kịch bản: TC-07-279 Garage ngừng khi phát hành
    # Truy vết: FR-07-016 · ERR-07-047
    Biết bản nháp CAT-MUC đã duyệt.
    Khi cắt mạng tới Garage, phát hành.
    Và khôi phục mạng sau 5 phút.
    Thì phát hành thành công (ảnh chụp sinh nền); `GET .../snapshots/{v}` trả `503` `ERR-07-047` có `Retry-After` trong lúc chờ; sau khôi phục, ảnh chụp sinh xong trong ≤ 2 phút và EVT-07-05 có `snapshotUri`.

  @TC-07-280 @P2 @Bảo @mật
  Kịch bản: TC-07-280 Ảnh chụp bị sửa bị phát hiện
    # Truy vết: FR-07-028 · ADR-053
    Biết ảnh chụp v1 CAT-LH.
    Khi sửa một byte của đối tượng ảnh chụp trong MinIO.
    Và `dh-runtime` nạp ảnh chụp.
    Thì thư viện tra cứu từ chối nạp vì SHA-256 lệch metadata, ghi cảnh báo, tiếp tục dùng ảnh chụp cũ trong bộ nhớ.

  @TC-07-281 @P1 @Hiệu @năng
  Kịch bản: TC-07-281 Bộ nhớ pod khi nhập, xuất, phát hành danh mục lớn nhất
    # Truy vết: NFR-07-012
    Biết PERF; danh mục 200.000 bản ghi, 100 thuộc tính.
    Khi đồng thời: nhập F-100K, xuất 200.000 dòng xlsx, phát hành danh mục 200.000 bản ghi.
    Thì không pod nào bị OOM (giới hạn 2 GB); L1 ≤ 256 MB; tra cứu đồng thời vẫn đạt NFR-07-001.

  @TC-07-282 @P1 @Biên
  Kịch bản: TC-07-282 Hai pod cùng lấy một tác vụ nền
    # Truy vết: FR-07-021 · D03-02-PH07 §4.4
    Biết 20 tác vụ nhập `UPLOADED`, ba pod.
    Khi bật worker trên cả ba pod cùng lúc; dừng đột ngột một pod giữa chừng.
    Thì mỗi tác vụ được đúng một pod xử lý (`lease_owner`); tác vụ của pod bị dừng được pod khác nhận lại sau khi `lease_until` hết hạn; không có tác vụ nào ghi hai lần vào bản nháp.
