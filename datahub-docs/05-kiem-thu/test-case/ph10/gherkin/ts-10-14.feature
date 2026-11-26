# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-14
Tính năng: TS-10-14 · Giao nhận ĐẨY: webhook ký HMAC và khóa ký

  @TC-10-061 @P1 @Dương @Bảo @mật
  Kịch bản: TC-10-061 Chữ ký HMAC và tiêu đề webhook đúng đặc tả
    # Truy vết: FR-10-038 · BR-10-009 · UC-10-14 · ADR-071 · LGC-HUB-013
    # Mục đích: Chứng minh luồng thành công, theo FR-10-038 (Giao nhận ĐẨY: webhook ký HMAC).
    Biết SUB-PUSH `CLOUDEVENTS_STRUCTURED`; SIM-WH nạp khóa ký hiện hành.
    Khi phát một sự kiện lên TP-CP.
    Và Ở SIM-WH tính lại `HMAC-SHA256(secret, "{Webhook-Id}.{Webhook-Timestamp}.{body}")`.
    Và lặp với subscription thử `CLOUDEVENTS_BINARY`.
    Thì yêu cầu `POST` có `Webhook-Id` bằng `ce_id`, `Webhook-Timestamp` trong 5 giây so với giờ chuẩn, `X-Datahub-Signature: t={ts},v1={hex}`, `X-Datahub-Subscription`, `X-Datahub-Attempt: 1`, `X-Datahub-Key-Id`, `traceparent`; thân `application/cloudevents+json`. Chữ ký tính lại khớp. Bước 3 tiêu đề `ce-*`, thân là `data` JSON, chữ ký tính trên thân đó.
    # Hậu điều kiện: Không lộ hay đổi dữ liệu, bí mật, quyền ngoài điều nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-062.

  @TC-10-062 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-062 Đầu nhận từ chối chữ ký sửa, dấu thời gian lệch, phát lại cùng Webhook-Id
    # Truy vết: FR-10-038 · BR-10-009 · NFR-10-007
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-038 (Giao nhận ĐẨY: webhook ký HMAC).
    Biết thư viện xác minh mẫu (Java, .NET, Python, Node.js, PHP) ở tài liệu hướng dẫn tích hợp; bản ghi yêu cầu thật từ TC-10-061.
    Khi sửa một byte thân rồi xác minh.
    Và lùi `Webhook-Timestamp` 400 giây (dung sai 300 giây).
    Và gửi lại nguyên yêu cầu lần hai.
    Thì bước 1, 2 cả năm thư viện mẫu từ chối. Bước 3 thư viện mẫu nhận diện trùng theo `Webhook-Id` và không xử lý lại. Ca chứng minh mã mẫu đúng hướng dẫn.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-063 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-063 Không đọc được khóa ký thì không gửi
    # Truy vết: FR-10-038 · ERR-10-117 · BR-10-024, 027
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-038 (Giao nhận ĐẨY: webhook ký HMAC).
    Biết SUB-PUSH; đệm khóa 10 phút.
    Khi dừng OpenBao; phát 10 sự kiện ngay; chờ 11 phút; phát 10 sự kiện nữa.
    Và bật lại OpenBao.
    Thì 10 sự kiện đầu giao bình thường bằng khóa trong đệm. Sau khi đệm hết hạn, phân vùng tạm dừng với ERR-10-117, cảnh báo; SIM-WH không nhận yêu cầu nào thiếu chữ ký; offset không commit. Bước 2 giao tiếp 10 sự kiện còn lại, không mất.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-064 @P1 @Dương
  Kịch bản: TC-10-064 Xoay khóa có thời gian chồng lấn hai chữ ký
    # Truy vết: FR-10-042 · API-10-054 · EVT-10-13 · UC-10-17 · BR-10-027
    # Mục đích: Chứng minh luồng thành công, theo FR-10-042 (Xoay khóa ký webhook).
    Biết U-T68-TO; SUB-PUSH; `10.push.key-rotation-overlap-days = 7`.
    Khi `POST /subscriptions/ht-thue-dn-cap-phep/signing-keys:rotate` có `Idempotency-Key`.
    Và phát sự kiện; đặt đồng hồ +8 ngày, phát tiếp.
    Thì bước 1 `200`, khóa mới `whsec_…` hiển thị một lần, khóa cũ `PREVIOUS` với `previousUntil`. Bước 2 trong 7 ngày tiêu đề có hai giá trị `v1=`, đầu nhận dùng khóa cũ hay mới đều xác minh được; sau 7 ngày chỉ còn chữ ký khóa mới. EVT: `signing-key.rotated`. Mồi sạch với cả hai khóa.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-065 @P1 @Dương @Âm
  Kịch bản: TC-10-065 Thu hồi khẩn khóa ký; quyền xoay; SO không thu hồi ngoài sự cố
    # Truy vết: FR-10-042 · API-10-054, 100 · ERR-10-009 · EVT-10-13
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-042 (Xoay khóa ký webhook).
    Biết U-T68-SO, U-T68-IE1, U-T68-VW; SUB-PUSH.
    Khi SO `:revoke` có lý do "Khóa bị lộ trong nhật ký đầu nhận".
    Và phát sự kiện.
    Và IE1 `:rotate`; U-T68-VW `:rotate`; SO `:revoke` không có lý do.
    Thì bước 1 `200`, khóa cũ `REVOKED` ngay, không có thời gian chồng lấn, khóa mới sinh và hiển thị một lần. Bước 2 chỉ có chữ ký khóa mới. Bước 3 IE1 `200` (có `PERM-10-subscribe`); VW 403-PQ; SO không lý do `400` ERR-10-009.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-066 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-066 Chặn DNS rebinding và đổi IP giữa các lượt
    # Truy vết: FR-10-038 · ERR-10-114, 115 · BR-10-026
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-038 (Giao nhận ĐẨY: webhook ký HMAC).
    Biết subscription thử tới `https://rebind.sim.test/h` đã xác minh khi DNS trả IP công cộng.
    Khi đổi DNS sang `10.96.0.10`; phát sự kiện.
    Và đổi đầu nhận của subscription thử khác sang chứng thư hết hạn; phát sự kiện.
    Thì bộ giao nhận kiểm lại IP trước lượt, không gửi; lượt lỗi ERR-10-115 `failureClass = SECURITY`; sau hết lượt thử vào DLQ; không có kết nối tới `10.96.0.10`. Bước 2 lượt lỗi ERR-10-114, không gửi thân qua kết nối TLS không tin cậy.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.
