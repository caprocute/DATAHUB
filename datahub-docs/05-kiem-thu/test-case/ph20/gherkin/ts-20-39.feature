# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-39
Tính năng: TS-20-39 · Lũy đẳng, đồng thời, định dạng lỗi và kiểm toán

  @TC-20-198 @P1 @Dương @Âm
  Kịch bản: TC-20-198 Gọi lại cùng Idempotency-Key trả kết quả cũ, khác nội dung trả 409
    # Truy vết: ERR-20-009 · API-20-002, 086, 110, 144 · BR-20-009
    Biết `U-PA1`, `U-T90-TA`; bốn thao tác `POST` tạo mới đại diện (khai báo tenant, kế hoạch sáp nhập, phiên bản, tổ chức).
    Khi gửi `POST` với `Idempotency-Key = K1`, rồi gửi lại đúng nội dung
    Và gửi lại với `K1` nhưng nội dung khác
    Và gửi hai yêu cầu đồng thời cùng `K2`
    Và gửi `POST` không có `Idempotency-Key`
    Thì bước 1 lần hai trả đúng kết quả lần một, không tạo bản ghi mới, không phát sự kiện thứ hai. Bước 2 `409` `ERR-20-009` ("Khóa chống lặp đã được dùng cho một yêu cầu khác. Tạo yêu cầu mới."). Bước 3 một bản ghi duy nhất. Bước 4 `400` `ERR-20-004` (giả định ĐN-TC-03: hợp đồng chưa nêu mã lỗi).

  @TC-20-199 @P1 @Âm
  Kịch bản: TC-20-199 Hai người sửa cùng đối tượng: người sau nhận 412
    # Truy vết: ERR-20-005 · ERR-00-428 · API-20-004, 146, 120, 112 · UI-20-15
    Biết `U-PA1`, `U-PA2`; một tenant, một tổ chức, một kế hoạch nâng cấp; `ETag` hiện tại `v1`.
    Khi hai người cùng đọc `ETag = v1`
    Và người A `PATCH` kèm `If-Match: v1`, thành công, `ETag = v2`
    Và người B `PATCH` kèm `If-Match: v1`
    Và người B `PATCH` không có `If-Match`
    Thì bước 2 `200`. Bước 3 `412` `ERR-20-005` ("Tổ chức đã được người khác sửa. Tải lại để xem thay đổi."), dữ liệu giữ bản của A. Bước 4 `428` `ERR-00-428`. UI hiện hộp thoại "Tải lại".

  @TC-20-200 @P2 @Dương
  Kịch bản: TC-20-200 Mọi lỗi theo RFC 9457 có code, traceId, errors[]
    # Truy vết: ERR-20-004 · ERR-20-002 · ERR-20-006 · API-20-001, 003, 144 · NFR-20-021
    Biết ba lỗi đại diện: `400` (sai trường), `404`, `409`.
    Khi gọi để sinh `400`, `404`, `409`
    Và kiểm `Content-Type` và trường
    Thì `application/problem+json`; có `type`, `title`, `status`, `code` (`ERR-20-xxx`), `traceId`; `400` có `errors[]` (`field`, `message`); thông báo tiếng Việt có dấu; không lộ ngăn xếp, tên bảng, địa chỉ nội bộ.

  @TC-20-201 @P1 @Dương
  Kịch bản: TC-20-201 Mọi thao tác thay đổi có kiểm toán đủ trường, không có bí mật
    # Truy vết: BR-20-009 · NFR-20-018 · NFR-20-024 · FR-20-068 · EVT-20-04
    Biết danh sách thao tác ghi của 134 + 27 API (lấy từ OpenAPI); `obs-sim` nhận bản ghi; `U-PA1`.
    Khi thực hiện một lần mỗi thao tác ghi (thành công)
    Và thực hiện thao tác ghi bị từ chối (403, 409)
    Và duyệt bản ghi kiểm toán trong `obs-sim`
    Và tìm chuỗi bí mật mẫu `<bi-mat-mau>` trong kiểm toán, nhật ký, CSDL `ph20_tenant`, kho Git giả
    Thì 100 % thao tác ghi thành công có bản ghi (ai, khi nào, tenant, đối tượng, giá trị trước và sau trừ bí mật, `ticketRef`, `traceId`). Thao tác bị từ chối có bản ghi từ chối. Không tìm thấy bí mật ở bất kỳ nơi nào (NFR-20-024).

  @TC-20-202 @P1 @Dương
  Kịch bản: TC-20-202 Outbox phát đủ 16 sự kiện đúng khóa, tenantCode, lược đồ
    # Truy vết: EVT-20-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16 · NFR-20-020 · NFR-20-021
    Biết kafka và Apicurio thật; kịch bản gây ra từng sự kiện (khai báo, lỗi saga, kích hoạt, đổi trạng thái, đổi hạn mức, chạm ngưỡng, bật và tắt phân hệ, đổi cấu hình, ba sự kiện sáp nhập, tổ chức, phát hành, nâng cấp, gói bàn giao).
    Khi thực hiện từng kịch bản
    Và đọc sự kiện từ topic, kiểm lược đồ với Apicurio, khóa, `tenantCode`, `eventId`
    Và đo trễ từ commit đến sự kiện; làm Kafka ngừng 2 phút rồi bật lại
    Thì cả 16 sự kiện được phát đúng tên, đúng lược đồ, `eventId` duy nhất; p95 ≤ 5 giây; sau khi Kafka phục hồi không mất, không trùng ngoài ý muốn (người nhận lũy đẳng theo `eventId`); số đo `dh_tenant_*` có nhãn `tenant` (NFR-20-021).
