# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-14
Tính năng: TS-07-14 · Sự kiện và outbox

  @TC-07-171 @P1 @Dương
  Kịch bản: TC-07-171 Phát hành sinh đúng một sự kiện đúng lược đồ
    # Truy vết: FR-07-034 · EVT-07-05 · NFR-07-007
    Biết CAT-MUC có bản nháp hợp lệ, `require_approval = false`.
    Khi U-T68-DA1 phát hành bản nháp.
    Và đọc topic `t68.rdm.catalog.published.v1` trong 10 giây.
    Thì có đúng một dòng mới trong `ph07_rdm.outbox` và đúng một bản tin trên topic, nhận được trong ≤ 5 giây sau cam kết. Tiêu đề `ce_specversion = 1.0`, `ce_type = vn.datahub.rdm.catalog.published.v1`, `ce_source`, `ce_id` là UUID v7, `ce_tenant = T68`; khóa bản tin `T68:MUC_DO_DVC`. Thân hợp lệ theo lược đồ AsyncAPI, có `versionNo`, `effectiveFrom`, `stats`, `breaking`, `snapshotUri`, `schemaHash` và không có mảng bản ghi.

  @TC-07-172 @P1 @Âm
  Kịch bản: TC-07-172 Giao dịch hoàn tác không sinh sự kiện
    # Truy vết: FR-07-034 · DD-11
    Biết IT tiêm lỗi sau khi ghi outbox nhưng trước cam kết (ngoại lệ trong `PublishService`).
    Khi gọi phát hành CAT-MUC.
    Thì API trả `500` dạng problem+json; bảng `outbox` không có dòng mới; topic không có bản tin sau 10 giây (EVT: không); phiên bản vẫn ở `DRAFT`.

  @TC-07-173 @P2 @Dương
  Kịch bản: TC-07-173 Thứ tự sự kiện theo danh mục
    # Truy vết: FR-07-034 · EVT-07-04, 05, 06
    Biết danh mục `TC173_DM` mới tạo.
    Khi lần lượt: trình duyệt, từ chối, trình lại, duyệt, phát hành.
    Và đọc các topic liên quan, sắp theo `ce_time`.
    Thì mọi bản tin có cùng khóa `T68:TC173_DM` nên nằm cùng phân vùng; thứ tự nhận khớp thứ tự thao tác (submitted, rejected, submitted, published).

  @TC-07-174 @P1 @Khả @dụng
  Kịch bản: TC-07-174 Kafka gián đoạn không làm mất sự kiện
    # Truy vết: FR-07-034 · NFR-07-007
    Biết SIT; Chaos Mesh dừng ba broker Kafka trong 5 phút.
    Khi trong lúc Kafka dừng, phát hành 3 danh mục khác nhau.
    Và khôi phục Kafka.
    Thì ba thao tác phát hành trả `200` (không phụ thuộc Kafka). Sau khi Kafka trở lại, ba sự kiện xuất hiện trong ≤ 60 giây, không trùng `ce_id`. Cảnh báo `RdmOutboxLag` bật trong lúc gián đoạn và tắt sau khi đuổi kịp.

  @TC-07-175 @P2 @Dương
  Kịch bản: TC-07-175 Sự kiện của COMMON và sự kiện sắp xếp ĐVHC
    # Truy vết: FR-07-034 · EVT-07-05, EVT-07-10 · FR-07-045
    Biết CAT-DVHC có bản nháp v4 với một sự kiện `MERGE` giả lập.
    Khi U-PA phát hành v4.
    Và đọc `common.rdm.catalog.published.v1` và `common.rdm.adminunit.reorganized.v1`.
    Thì có một bản tin trên mỗi topic, `ce_tenant = COMMON`; EVT-07-10 có `events[]` với loại, mã nguồn, mã đích, căn cứ. Bộ tiêu thụ của tenant T68 và T01 đều nhận được.

  @TC-07-176 @P1 @Bảo @mật @Âm
  Kịch bản: TC-07-176 Sự kiện không lộ sang tenant khác
    # Truy vết: FR-07-034 · FR-00-011
    Biết bộ tiêu thụ thử dùng chứng thư của T01 với ACL Kafka chỉ cho `t01.*` và `common.*`.
    Khi phát hành CAT-MUC của T68.
    Và bộ tiêu thụ T01 cố đăng ký `t68.rdm.catalog.published.v1`.
    Thì bước 2 bị Kafka từ chối (`TopicAuthorizationException`); bộ tiêu thụ T01 không nhận bản tin nào của T68.
