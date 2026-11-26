# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-37
Tính năng: TS-15-37 · Chịu lỗi, hợp đồng, quan sát, lưu giữ, bắt đầu nhanh

  @TC-15-203 @P2 @Âm
  Kịch bản: TC-15-203 Outbox giữ sự kiện khi Kafka ngắt
    # Truy vết: NFR-15-008 · EVT-15-01, 02, 03, 05, 08, 11, 14 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết ngắt Kafka 10 phút; thực hiện tạo ứng dụng, cấp, thu hồi, đăng trang, thử.
    Khi làm các thao tác; khôi phục Kafka.
    Thì API vẫn thành công; `outbox` giữ bản tin; sau khôi phục phát đủ, đúng thứ tự theo khóa, không trùng; bản tin không có bí mật; có `dhtenant`.

  @TC-15-204 @P2 @Âm
  Kịch bản: TC-15-204 Giết pod giữa thao tác
    # Truy vết: NFR-15-008 · FR-15-015, 027, 030 · LGC-IAM-006.
    Biết chaos Mesh giết pod `api` giữa `:approve` trang, giữa `:rotate`.
    Khi thực hiện thao tác, giết pod, thử lại với cùng `Idempotency-Key`.
    Thì trạng thái nhất quán (không nửa chừng), không trùng sự kiện, không credential mồ côi.

  @TC-15-205 @P2 @Dương
  Kịch bản: TC-15-205 Tương thích hợp đồng API và sự kiện
    # Truy vết: NFR-15-019 · FR-15-001 · LGC-APIM-006.
    Biết `openapi-portal.yaml`, `asyncapi-portal.yaml`; bản phát hành trước.
    Khi chạy Spectral, oasdiff với bản trước; kiểm Apicurio chế độ BACKWARD.
    Thì không thay đổi phá vỡ ở `v1` (chỉ thêm trường tùy chọn); mọi phản hồi lỗi khớp RFC 9457; mọi lược đồ Avro tương thích BACKWARD.

  @TC-15-206 @P2 @Dương
  Kịch bản: TC-15-206 Chỉ số và cảnh báo
    # Truy vết: NFR-15-020 · FR-15-001, 030, 035 · LGC-APIM-006.
    Biết sau các kịch bản đồng bộ, thử, xoay, từ chối hiển thị.
    Khi đọc `/metrics`; đẩy `sync_lag` lên 1.000 giây.
    Thì có và tăng đúng `dh_portal_sync_lag_seconds`, `dh_portal_try_total`, `dh_portal_try_throttled_total`, `dh_portal_cred_old_use_total`, `dh_portal_visibility_denied_total`; cảnh báo lag > 900 giây phát trong 2 phút.

  @TC-15-207 @P2 @Dương
  Kịch bản: TC-15-207 Lưu giữ
    # Truy vết: NFR-15-016 · FR-15-040, 052, 060 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết đồng hồ giả lập; cấu hình lưu giữ.
    Khi kiểm lịch sử thử, thông báo, phiên bản trang, nhật ký, ẩn danh tài khoản.
    Thì lịch sử thử 30 ngày; thông báo 90 ngày; phiên bản trang vĩnh viễn; nhật ký 12 tháng trực tuyến và WORM 5 năm (khóa đối tượng); tài khoản ẩn danh sau 24 tháng.

  @TC-15-208 @P2 @Dương
  Kịch bản: TC-15-208 Lời gọi sandbox đầu tiên trong 15 phút
    # Truy vết: NFR-15-022 · FR-15-012, 025, 027, 035 · UC-15-14, 15, 19 · LGC-APIM-017; LGC-APIM-020; LGC-IAM-006.
    Biết 5 người chưa từng dùng cổng, có tài khoản dh-dev ACTIVE; trang `bat-dau-nhanh` đã đăng.
    Khi theo hướng dẫn: tạo ứng dụng, cấp credential, chép mẫu curl, gọi sandbox.
    Thì ≥ 4/5 người có lời gọi thành công đầu tiên ≤ 15 phút (đo bằng EVT-15-03 và EVT-15-11); khói sáu ngôn ngữ ≥ 95 % thao tác mẫu chạy được.
