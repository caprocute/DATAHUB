# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-20
Tính năng: TS-04-20 · Data plane đồng bộ qua chín chặng

  @TC-04-122 @P1 @Dương
  Kịch bản: TC-04-122 Bản tin hợp lệ đi qua đủ chín chặng
    # Truy vết: FR-04-060, 061, 063, 064, 065, 066, 068, 074 · BR-04-002 · UC-04-17 · EVT-04-14 · LGC-BUS-035.
    Biết F-HT v4 PROD; HTTT `HT-MOT-CUA` (giả lập) có đăng ký sử dụng API ở PH-02; OPA cho phép; PH-07 có bảng chuyển mã.
    Khi gọi `POST https://apisix-int…/t68/ho-tich/tra-cuu` với MSG-OK, `traceparent`.
    Và đọc vết OpenTelemetry và topic `t68.audit.connection-log.v1`.
    Thì bước 1 trả `200` với thân đã chuyển CDM, trường `hoTen` được che theo chính sách PH-09 với bên gọi này. Bước 2: vết có span cho đủ chín marker `dh-stage-receive` … `dh-stage-respond` theo đúng thứ tự, cùng `traceId` với bên gọi; EVT-04-14 có `consumerClientId`, `sourceSystem`, `targetSystem`, `outcome = SUCCESS`, `legalBasisRef`, `durationMs`, không có thân bản tin.

  @TC-04-123 @P1 @Âm
  Kịch bản: TC-04-123 Sai lược đồ và vượt kích thước
    # Truy vết: FR-04-063, 061 · ERR-04-101, 107.
    Biết MSG-NOID, MSG-RT-BIG; bản tin có 30 trường sai.
    Khi gọi với MSG-NOID.
    Và gọi với bản tin 30 trường sai.
    Và gọi với MSG-RT-BIG.
    Thì bước 1 trả `400` ERR-04-101 với `errors[].path = "/soDinhDanh"`, không lặp giá trị nào. Bước 2 trả tối đa 20 lỗi. Bước 3 trả `413` ERR-04-107 trước khi đọc hết thân. Hệ đích không nhận lệnh gọi nào. EVT-04-14 có `outcome = REJECTED`.

  @TC-04-124 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-124 OPA từ chối hoặc không trả lời
    # Truy vết: FR-04-064 · ERR-04-102 · LGC-BUS-041.
    Biết chính sách OPA từ chối `HT-KHAC`; OPA bị làm chậm 300 ms ở bước 2.
    Khi `HT-KHAC` gọi F-HT.
    Và `HT-MOT-CUA` gọi khi OPA chậm.
    Thì cả hai trả `403` ERR-04-102 (đóng khi lỗi, không mở). Đầu vào OPA có `tenant`, `caller`, `subscription`, `flow`, `operation`, `purpose`, `dataClasses`. Không đưa DLQ.

  @TC-04-125 @P1 @Âm
  Kịch bản: TC-04-125 Lỗi chuyển đổi và làm giàu
    # Truy vết: FR-04-065, 066 · ERR-04-108.
    Biết bản tin có `gioiTinh = "9"` (không có trong bảng chuyển mã, cấu hình `FAIL`); nguồn làm giàu PH-07 trả `500`.
    Khi gọi với `gioiTinh = "9"`.
    Và gọi khi nguồn làm giàu lỗi.
    Thì bước 1 trả `422` ERR-04-108. Bước 2 trả `502` ERR-04-104 sau số lần thử lại của chặng `enrich`. Thông điệp lỗi không lộ URL nội bộ.

  @TC-04-126 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-04-126 Che dữ liệu cá nhân ở phản hồi và log
    # Truy vết: FR-04-067, 074 · BR-04-013.
    Biết chính sách PH-09: `soDinhDanh` che 8 số đầu với bên gọi mục đích `THONG_KE`; log mức DEBUG bật trên runtime.
    Khi gọi F-HT với mục đích `THONG_KE`.
    Và gọi với mục đích `KHAC` không có trong chính sách.
    Và quét log runtime, vết, chỉ số, EVT-04-14 tìm `001099000001` và `Nguyễn Văn Thử`.
    Thì bước 1: phản hồi có `soDinhDanh = "0001"`. Bước 2: mọi trường phân loại Hạn chế, Nhạy cảm bị che toàn bộ (mặc định khi không có quy tắc). Bước 3: không xuất hiện ở bất kỳ nguồn nào, kể cả log DEBUG (log thân bản tin bị chặn bởi `dh-default-config`).

  @TC-04-127 @P1 @Dương @Âm @Khả
  Kịch bản: TC-04-127 Đích quá thời gian, lỗi, ngắt mạch
    # Truy vết: FR-04-068, 070 · ERR-04-103, 104, 105.
    Biết wireMock `SLOW_5S` với `04.runtime.sync-timeout-seconds = 3`; `HTTP_500`; `FLAKY_50`.
    Khi gọi khi đích `SLOW_5S`.
    Và gọi khi đích `HTTP_500`.
    Và gọi 20 lần khi đích `FLAKY_50`, rồi gọi lần 21.
    Và sau 30 giây gọi lại khi đích đã `OK`.
    Thì bước 1 trả `504` ERR-04-103 sau khoảng 3 giây. Bước 2 trả `502` ERR-04-104 sau đúng số lần thử lại cấu hình, giãn cách lũy thừa. Bước 3: lần 21 trả `503` ERR-04-105 ngay (mạch mở, tỷ lệ lỗi ≥ 50% trên 20 lượt), không gọi đích. Bước 4: nửa mở cho một lượt thử, thành công thì đóng mạch.

  @TC-04-128 @P3 @Âm
  Kịch bản: TC-04-128 Đường dẫn không khớp route
    # Truy vết: FR-04-061 · ERR-04-111.
    Biết F-HT PROD.
    Khi gọi `POST …/t68/ho-tich/khong-co`.
    Thì `404` ERR-04-111, thân RFC 9457 không liệt kê các route có sẵn.

  @TC-04-129 @P2 @Âm @Bảo @mật
  Kịch bản: TC-04-129 Lỗi nội bộ không lộ chi tiết
    # Truy vết: FR-04-070 · ERR-04-109.
    Biết luồng thử có chặng ném `NullPointerException`.
    Khi gọi luồng.
    Thì `500` ERR-04-109, thân chỉ có `title`, `code`, `traceId`; không có tên lớp, ngăn xếp, đường dẫn tệp.

  @TC-04-130 @P2 @Dương
  Kịch bản: TC-04-130 SOAP qua hồ sơ JVM
    # Truy vết: FR-04-061, 075 · LGC-BUS-036.
    Biết F-SOAP trên hồ sơ `soap-jvm`; dịch vụ SOAP BHXH giả lập (WireMock SOAP).
    Khi gọi REST F-SOAP; luồng chuyển sang SOAP 1.1 với WS-Security UsernameToken lấy từ `{{conn:…}}`.
    Thì `200`; bản tin SOAP đúng XSD; mật khẩu WS-Security không có trong log. Pod `soap-jvm` tách khỏi pod `core-native`.

  @TC-04-198 @P1 @Âm
  Kịch bản: TC-04-198 Gọi đồng bộ khi luồng hoặc route đang tạm dừng
    # Truy vết: FR-04-050, 061 · UC-04-17 · ERR-04-110.
    Biết F-HT PROD; route `tra-cuu` tạm dừng bằng lệnh `PAUSE` (`scope = ROUTES`), route `kiem-tra-trang-thai` của cùng luồng vẫn chạy; WireMock CONN-HT đếm lượt gọi.
    Khi gọi `POST /ho-tich/tra-cuu` qua `apisix-int` với MSG-OK.
    Và gọi điểm vào của route `kiem-tra-trang-thai`.
    Và gửi lệnh `RESUME`, đợi `ACKNOWLEDGED`, lặp bước 1.
    Thì bước 1 trả `503` ERR-04-110 (RFC 9457, `title` "Luồng hoặc route đang tạm dừng"; câu hiển thị "Dịch vụ đang tạm dừng. Thử lại sau."); không có lượt gọi tới WireMock, bản tin không vào DLQ, nhật ký kết nối ghi lượt bị từ chối. Bước 2 trả `200`. Bước 3 trả `200` do v hiện hành sinh.
