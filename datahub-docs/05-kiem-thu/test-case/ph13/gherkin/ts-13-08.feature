# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-08
Tính năng: TS-13-08 · Xử lý đứt chuỗi và neo không khớp

  @TC-13-027 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-027 Sửa trực tiếp một bản ghi đã neo bị phát hiện
    # Truy vết: FR-13-014, 015 · UC-13-08 · BR-13-012, 033 · ERR-13-109 · EVT-13-05 · API-13-079 · UI-13-14 · NFR-13-016
    Biết F-AUD-CUT; U-T68-SO, U-T68-TA nhận thông báo.
    Khi chạy kiểm tra gia tăng khi neo.
    Và `GET /verifications/{id}`; mở UI-13-14.
    Thì kết quả `BROKEN` nêu `seq` đầu tiên sai; ≤ 1 giờ phát hiện; ERR-13-109; cảnh báo Nghiêm trọng gửi SO và TA ngay; EVT: `audit.chain-broken`; không có nút sửa; chuỗi giữ nguyên.

  @TC-13-028 @P1 @Âm @Bảo @mật
  Kịch bản: TC-13-028 Neo không khớp bản WORM hoặc SIEM
    # Truy vết: FR-13-015 · UC-13-08 · ERR-13-110 · BR-13-012, 013 · EVT-13-05
    Biết F-AUD-1K; sửa bản neo ở bảng neo (tài khoản DBA thử).
    Khi chạy kiểm tra toàn vẹn.
    Thì so ba nơi thấy lệch; ERR-13-110 Nghiêm trọng; nêu nơi nào lệch; EVT: `chain-broken`; không tự ghi đè.

  @TC-13-029 @P2 @Dương
  Kịch bản: TC-13-029 Chuỗi nguyên vẹn không sinh cảnh báo giả
    # Truy vết: FR-13-015 · UC-13-08 · BR-13-012 · ERR-13-109
    Biết F-AUD-1K, qua 7 ngày kiểm tra hằng ngày.
    Khi chạy kiểm tra liên tiếp 7 lần với ghi liên tục.
    Thì 7 lần `PASSED`; 0 cảnh báo đứt chuỗi; 0 EVT `chain-broken`.
