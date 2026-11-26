# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-19
Tính năng: TS-15-19 · Thử BACKEND, chặn dữ liệu cá nhân, hạn mức

  @TC-15-112 @P1 @Dương
  Kịch bản: TC-15-112 Thử qua backend của chủ dịch vụ
    # Truy vết: FR-15-037 · UC-15-19 · API-15-072 · UI-15-06 · BR-15-018, 026 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `dm-hanh-chinh` BACKEND tới `sim-backend.sim.test` (WireMock); U-T68-DEV-AN.
    Khi `POST /try/requests` `getTinh`.
    Và xem yêu cầu WireMock nhận được.
    Thì `200`, `X-DH-Sandbox: backend`; backend nhận `X-DH-Try-Id`, `traceparent`, không nhận `Authorization`, `Cookie` của người dùng; chỉ gửi tới host đã khai báo.

  @TC-15-113 @P1 @Âm
  Kịch bản: TC-15-113 Backend lỗi, chậm, ngắt mạch
    # Truy vết: FR-15-037 · UC-15-19 · API-15-072 · ERR-15-108, 109 · BR-15-018 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `15.try.timeout-seconds = 5`; WireMock trả `500`, rồi chậm 8 giây.
    Khi thử khi backend `500`.
    Và thử khi backend chậm.
    Và gây 5 lỗi trong 30 giây rồi thử tiếp.
    Thì `502` ERR-15-109 (kết quả `UPSTREAM_ERROR`); `504` ERR-15-108 "Hệ thống thử không phản hồi trong 5 giây." (`TIMEOUT`); sau 5 lỗi mạch mở: lượt kế `502` ERR-15-109 ngay, WireMock không nhận lời gọi; mạch đóng lại sau thời gian chờ.

  @TC-15-114 @P2 @Âm @Bảo @mật
  Kịch bản: TC-15-114 Kiểm lại allowlist egress lúc gọi
    # Truy vết: FR-15-037 · API-15-072 · ERR-15-119 · BR-15-018 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết hồ sơ BACKEND đã lưu; gỡ `sim-backend.sim.test` khỏi danh sách egress tenant.
    Khi thử API.
    Thì `422` ERR-15-119, không có kết nối ra backend.

  @TC-15-115 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-115 BACKEND chặn đủ sáu mẫu DLCN
    # Truy vết: FR-15-038 · UC-15-19 · API-15-071, 072 · UI-15-06 · ERR-15-106 · BR-15-016 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết sáu giá trị F-PII: CCCD `079123456789`, CMND `123456789`, mã số thuế `0312345678`, điện thoại `0912345678`, thư `a@gmail.com`, hộ chiếu `B1234567`; chế độ BACKEND; WireMock đếm lời gọi.
    Khi gửi mỗi giá trị ở thân, tham số đường dẫn, truy vấn, tiêu đề tùy chọn.
    Thì mọi lần `422` ERR-15-106 "Nội dung có vẻ chứa dữ liệu cá nhân thật. Chỉ dùng dữ liệu giả."; backend nhận 0 lời gọi; giá trị khớp không có ở `try_run`, log, vết, kiểm toán, EVT-15-11 (tìm 0 lần).

  @TC-15-116 @P1 @Dương
  Kịch bản: TC-15-116 Dải giả được phép
    # Truy vết: FR-15-038 · UC-15-19 · API-15-072 · BR-15-016 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `000123456789`, `000123456`, `0000123456`, `0900000123`, `x@example.gov.vn`, `X00123456`; BACKEND.
    Khi gửi mỗi giá trị.
    Thì tất cả `200`, không bị chặn nhầm.

  @TC-15-117 @P2 @Âm @Bảo @mật
  Kịch bản: TC-15-117 Dữ liệu mẫu tổng hợp nằm trong dải giả
    # Truy vết: FR-15-036, 038 · BR-15-016 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `SchemaDataGenerator` với lược đồ có các trường `cccd`, `soDienThoai`, `email`, `maSoThue`, `hoChieu`; 1.000 lượt sinh.
    Khi sinh 1.000 phản hồi MOCK.
    Và quét bằng bộ luật PII-15-01…06.
    Thì mọi giá trị khớp mẫu đều thuộc dải giả (bắt đầu `000`, `0900000`, `@example.gov.vn`, `X00`); 0 giá trị khớp mẫu ngoài dải.

  @TC-15-118 @P1 @Âm
  Kịch bản: TC-15-118 Hạn mức theo người và Retry-After
    # Truy vết: FR-15-039 · UC-15-19 · API-15-072, 074 · ERR-15-103 · BR-15-025 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `15.try.rate-per-user-min = 5`; U-T68-DEV-AN.
    Khi 6 lượt thử trong 1 phút; `GET /try/quota`.
    Và chờ qua phút kế.
    Thì lượt 6 `429` ERR-15-103 kèm `Retry-After`; `quota` còn 0; sau phút kế `200`; lượt `THROTTLED` có EVT-15-11 và tăng `dh_portal_try_throttled_total`.

  @TC-15-119 @P2 @Âm
  Kịch bản: TC-15-119 Hạn mức ngày theo ứng dụng, cỡ thân, phản hồi quá cỡ
    # Truy vết: FR-15-039 · API-15-072 · ERR-15-104, 105, 123 · BR-15-025 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết `15.try.rate-per-app-day = 100`; thân 257 KB (> 256 KB); backend trả 2 MB.
    Khi 101 lượt thử trong ngày (nhiều người dùng).
    Và gửi thân 257 KB.
    Và thử khi backend trả 2 MB.
    Thì lượt 101 `429` ERR-15-104 "Hạn mức làm mới lúc 00:00"; `413` ERR-15-105; phản hồi bị cắt ở 1 MB kèm cờ ERR-15-123, không lưu thân.
