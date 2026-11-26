# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-31
Tính năng: TS-05-31 · Không lộ bí mật

  @TC-05-120 @P1 @Bảo @mật
  Kịch bản: TC-05-120 Mồi bí mật qua toàn bộ vòng đời kết nối
    # Truy vết: FR-05-011, 005, 010, 012, 018 · NFR-05-011 · BR-05-001 · API-05-012, 017, 020
    Biết U-T68-IE1; mồi `DH-CANARY-L1-{uuid}` cho mọi khóa bí mật của 7 loại kết nối.
    Khi tạo, ghi bí mật, kiểm tra, bật, xoay, xuất, xem lịch sử cho 7 kết nối.
    Và cho kiểm tra không đạt ở bước xác thực (mồi bị hệ đích từ chối).
    Và tìm mồi ở: phản hồi API (HAR của Playwright), `localStorage`, `sessionStorage`, IndexedDB, log mọi pod 1 giờ (Loki), vết (Tempo), mọi bảng `ph05_adapter.*`, outbox, Kafka topic `t68.*`, DLQ, tệp CSV xuất, kiểm toán PH-13.
    Thì mồi sạch ở mọi nơi; chỉ có ở OpenBao.

  @TC-05-121 @P1 @Bảo @mật
  Kịch bản: TC-05-121 Mồi bí mật trong runtime khi lỗi
    # Truy vết: FR-05-033, 034 · NFR-05-011 · ERR-05-102
    Biết luồng mẫu dùng kết nối có mồi; SIM-HTTP trả 401 và lặp lại tiêu đề `Authorization` trong thân lỗi.
    Thì mồi sạch trong log, vết, thân lỗi trả cho bên gọi, DLQ; tiêu đề `Authorization` bị che thành `*`.

  @TC-05-122 @P2 @Khả @dụng @Bảo
  Kịch bản: TC-05-122 OpenBao không khả dụng khi ghi bí mật
    # Truy vết: FR-05-011 · API-05-012 · ERR-05-028 · UI-05-03
    Biết U-T68-IE1; OpenBao dừng.
    Thì `503` ERR-05-028; UI hiện "Kho bí mật tạm thời không khả dụng; bí mật chưa được ghi", ô bí mật bị xóa, các tham số khác giữ; không có bản sao bí mật ở hàng đợi thử lại, CSDL, log.
