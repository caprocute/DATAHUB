# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-35
Tính năng: TS-08-35 · Vòng đầy đủ và truy cập giao diện

  @TC-08-151 @P1 @Dương
  Kịch bản: TC-08-151 Vòng đầy đủ lịch tháng đến báo cáo kỳ
    # Truy vết: FR-08-023 · FR-08-026 · FR-08-028 · FR-08-036 · FR-08-041 · FR-08-044 · FR-08-052 · FR-08-053 · UI-08-01, 11, 12, 13, 16, 18 · EVT-08-02 · EVT-08-09 · EVT-08-11
    Biết T90 `mdm-citizen` với F-SCORE; lịch tháng; DS1, DA1, DO1; `clock-sim`.
    Khi đẩy `clock-sim` tới 2026-12-01 02:00, lịch tự bắn lần đo `FULL`
    Và xem lần đo ở UI-08-12 và lỗi ở UI-08-13
    Và DS1 mở phiếu cho `R-CCCD-NN` (UI-08-16)
    Và DO1 sửa nguồn và báo đã sửa
    Và chờ đo kiểm chứng `VERIFIED`
    Và DS1 sinh báo cáo kỳ, DA1 duyệt, công bố
    Và xem điểm mới ở UI-08-01
    Thì mỗi bước hoàn tất đúng trạng thái: lần đo `SUCCEEDED` điểm 91,45, lỗi mới `OPEN`, phiếu `VERIFIED`, lỗi `RESOLVED`, báo cáo `PUBLISHED`, dashboard cập nhật; đủ EVT-08-02, 06, 07, 09, 11 và kiểm toán từng bước.

  @TC-08-152 @P2 @Truy @cập
  Kịch bản: TC-08-152 Truy cập và giao diện các màn trọng yếu
    # Truy vết: UI-08-01 · UI-08-12 · UI-08-13 · UI-08-18 · FR-08-050
    Biết STAGING; Playwright, axe-core.
    Khi chạy axe-core trên UI-08-01, 12, 13, 18 ở độ rộng 1280 và 360 px
    Và điều hướng chỉ bằng bàn phím
    Và đọc thẻ điểm bằng trình đọc màn hình
    Thì 0 lỗi mức nghiêm trọng; kết luận `PASS`, `WARN`, `FAIL` không chỉ phân biệt bằng màu; thứ tự tab hợp lý; không cuộn ngang ở 360 px.
