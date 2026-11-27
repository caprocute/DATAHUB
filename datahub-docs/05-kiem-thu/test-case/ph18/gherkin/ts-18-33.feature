# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-33
Tính năng: TS-18-33 · Chuyển dữ liệu phân hệ khi sáp nhập tenant theo yêu cầu PH-20

  @TC-18-110 @P2 @Dương
  Kịch bản: TC-18-110 PH-20 yêu cầu chạy thử rồi chạy thật chuyển dữ liệu PH-04 từ T92 sang T90
    # Truy vết: FR-18-057 · API-18-150, 151, 152 · BR-18-045, 047 · EVT-18-24 · UI-18-20
    # Mục đích: Chứng minh BR-18-045: bản ghi giữ `id` gốc, có `origin_tenant_id = T92`, chạy thử không ghi, tiến độ báo về PH-20.
    Biết STAGING; S-PH20 (`ops:merge-transfer`); `mergePlanId = MP-01`, `module = PH-04`, `mappingRef` hợp lệ; WireMock PH-20 nhận báo tiến độ.
    Khi S-PH20 `POST /merge-transfers` `dryRun = true`.
    Và S-PH20 gửi lại với `dryRun = false`.
    Và theo dõi `GET /merge-transfers/{transferId}`.
    Và kiểm dòng ở T90.
    Thì bước 1 `202`, kết quả số bản ghi dự kiến, không ghi dòng nào. Bước 2 `202`. Bước 3 `SUCCEEDED`; EVT-18-24 theo trạng thái; PH-20 nhận báo cáo `:report`. Bước 4 mọi dòng chuyển có `origin_tenant_id = T92` và `id` như ở T92; 0 dòng mất `origin_tenant_id`.

  @TC-18-111 @P2 @Âm @Lũy_đẳng @Chịu_lỗi
  Kịch bản: TC-18-111 Yêu cầu sáp nhập sai, trùng khóa khác nội dung, báo tiến độ lỗi, hủy chuyển
    # Truy vết: FR-18-057 · API-18-150, 153 · BR-18-045 · ERR-18-060, 061, 123
    # Mục đích: Chứng minh điều kiện của API chuyển sáp nhập và thử lại khi báo PH-20 lỗi.
    Biết STAGING; S-PH20; `MP-01:PH-04` đã chạy; WireMock PH-20 trả `503` cho `:report` ở bước 3.
    Khi gửi yêu cầu `sourceTenant = targetTenant`.
    Và gửi `MP-01:PH-04` với `mappingRef` khác.
    Và chạy `MP-01:PH-07`, PH-20 không nhận báo cáo trong 10 phút.
    Và S-PH20 `POST /merge-transfers/{transferId}:cancel` cho một chuyển đang chạy; gửi lại `MP-01:PH-04` cùng nội dung.
    Thì bước 1 `422` ERR-18-060. Bước 2 `409` ERR-18-061. Bước 3 ghi ERR-18-123 mỗi lần thử, báo cáo gửi được khi PH-20 trở lại, không mất trạng thái. Bước 4 chuyển dừng sau lô hiện hành `CANCELLED`; gửi lại cùng nội dung trả `200` bản ghi cũ.
