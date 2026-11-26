# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-25
Tính năng: TS-15-25 · Theo dõi thay đổi API và hộp thông báo

  @TC-15-147 @P1 @Dương
  Kịch bản: TC-15-147 Theo dõi và nhận thông báo ngừng khuyến nghị
    # Truy vết: FR-15-051, 052 · UC-15-27 · API-15-101, 102, 103, 104, 140 · UI-15-19 · BR-15-027 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết an theo dõi `tra-cuu-ho-tich` kênh `IN_APP`, `EMAIL`; S-PH02 phát EVT-02-12 ngừng khuyến nghị.
    Khi `PUT /notification-subscriptions/tra-cuu-ho-tich`.
    Và phát sự kiện; `GET /inbox`; `GET /inbox/unread-count`.
    Và `DELETE /notification-subscriptions/tra-cuu-ho-tich`; phát lại sự kiện thông tin.
    Thì trong ≤ 60 giây có thông báo trong hộp thư và thư điện tử; `unread-count` tăng 1; sau bước 3 không còn thông báo loại thông tin (loại bắt buộc vẫn tới); An không thấy thông báo về API đã ẩn khỏi tầm của An (xem TC-15-008).

  @TC-15-148 @P1 @Âm
  Kịch bản: TC-15-148 Không tắt loại bắt buộc; API ngoài tầm
    # Truy vết: FR-15-051 · API-15-102 · ERR-15-001, 003 · BR-15-027 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết an; `tra-cuu-dat-dai` ngoài tầm.
    Khi `PUT` tắt loại "ngừng khuyến nghị".
    Và `PUT /notification-subscriptions/tra-cuu-dat-dai`.
    Thì `400` ERR-15-003 "Loại thông báo này là bắt buộc nên không tắt được"; `404` ERR-15-001; thay đổi phá vỡ vẫn gửi dù người dùng tắt loại thông tin.

  @TC-15-149 @P3 @Dương
  Kịch bản: TC-15-149 Đánh dấu đã đọc, giữ 90 ngày
    # Truy vết: FR-15-052 · API-15-105, 106 · NFR-15-016 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết 5 thông báo chưa đọc; đồng hồ +91 ngày.
    Khi `:read` một thông báo; `:read-all`.
    Và đẩy đồng hồ 91 ngày.
    Thì số chưa đọc 4 rồi 0; thông báo cũ hơn 90 ngày bị xóa; phân trang đúng.

  @TC-15-150 @P1 @Âm @Bảo @mật
  Kịch bản: TC-15-150 Không đọc hộp thư người khác
    # Truy vết: FR-15-052 · API-15-104, 105 · ERR-15-001 · NFR-15-017 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết thông báo của An; Cự; U-T01-DEV.
    Khi cự `POST /inbox/{id của An}:read`; `GET /inbox`.
    Thì `404` ERR-15-001; hộp thư của Cự không có thông báo của An; thông báo không đổi trạng thái.
