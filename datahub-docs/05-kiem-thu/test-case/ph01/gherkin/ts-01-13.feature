# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-13
Tính năng: TS-01-13 · Cấp định danh SANDBOX (saga)

  @TC-01-052 @P1 @Dương
  Kịch bản: TC-01-052 Saga thành công đến trạng thái bàn giao
    # Truy vết: FR-01-020 · UC-01-13 · API-01-036 · UI-01-08 · BR-01-003, 007, 031 · EVT-01-05 · NFR-01-004.
    Biết sau phê duyệt `HT-HOTICH` (khóa công khai chưa đăng ký); PH-12, PH-03, OpenBao khỏe.
    Khi chờ saga; `GET /systems/HT-HOTICH/provisioning`; mở UI-01-08.
    Và đọc định danh qua `GET /systems/HT-HOTICH/credentials`.
    Thì các bước saga lần lượt tạo client, consumer, `secret_ref`; `provisionStage = AWAITING_KEY` (mức Hạn chế). Định danh SANDBOX không có scope dữ liệu nào. Bảng PH-01 chỉ có `secret_ref`, vân tay, băm. Mồi sạch. EVT: `EVT-01-05`. Thời gian từ duyệt ≤ 5 phút (p95).

  @TC-01-053 @P1 @Âm @Chịulỗi
  Kịch bản: TC-01-053 Saga lỗi: PH-12, OpenBao ngừng, client trùng, thử lại
    # Truy vết: FR-01-020 · API-01-035, 036 · ERR-01-021, 022, 023 · NFR-01-016.
    Biết hồ sơ vừa phê duyệt; U-T68-TA1.
    Khi PH-12 giả lập `fail`; phê duyệt; xem tiến độ; sau đó khôi phục và TA1 `POST …/credentials:provision`.
    Và PH-12 giả lập `duplicate-client`.
    Và dừng OpenBao.
    Thì bước 1: saga `FAILED` ở bước PH-12, cảnh báo PH-13; `provision` trả `202` rồi hoàn tất, không tạo client hai lần. Bước 2: `409` ERR-01-022 xử lý được bằng liên kết lại client có sẵn. Bước 3: `503` ERR-01-023, không có bí mật nào ghi vào PH-01.

  @TC-01-054 @P2 @Âm @Bảomật
  Kịch bản: TC-01-054 Kết quả bất đồng bộ của bước saga
    # Truy vết: FR-01-020 · API-01-087 · ERR-01-052, 053 · UC-01-13.
    Biết S-CB; một bước saga `ACCEPTED`; bước khác không ở `ACCEPTED`; cờ `onboarding.saga.async-callback`.
    Khi S-CB `POST /internal/provisioning-callbacks` đúng bước `ACCEPTED`.
    Và gọi cho bước không `ACCEPTED`; rồi tắt cờ và gọi lại.
    Và dùng token không có scope `onboarding:provision-callback`.
    Thì bước 1: nhận, saga tiếp tục. Bước 2: `409` ERR-01-053, ghi nhật ký vận hành, không đổi trạng thái. Bước 3: `403-PQ`.
