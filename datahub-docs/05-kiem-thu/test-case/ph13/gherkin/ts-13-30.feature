# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-30
Tính năng: TS-13-30 · Phát hiện bất thường và xử lý cảnh báo an ninh

  @TC-13-084 @P1 @Dương
  Kịch bản: TC-13-084 Chuỗi đăng nhập thất bại sinh cảnh báo an ninh
    # Truy vết: FR-13-052, 053 · UC-13-34 · API-13-056, 057 · UI-13-15 · EVT-13-04
    Biết F-SEC-EVT; U-T68-SO.
    Khi phát 6 lần đăng nhập thất bại từ một nguồn trong 5 phút; sau đó phát chuỗi hợp lệ.
    Thì một cảnh báo an ninh `NEW` với bằng chứng là `audit_id`; EVT: `security-alert.raised`; chuỗi hợp lệ không sinh cảnh báo.

  @TC-13-125 @P2 @Âm @Biên
  Kịch bản: TC-13-125 Dưới ngưỡng, hành vi hợp lệ, đồng hồ lệch không sinh cảnh báo an ninh giả
    # Truy vết: FR-13-052 · UC-13-34 · API-13-056 · BR-13-025
    Biết F-SEC-EVT; luật đăng nhập thất bại ngưỡng 5.
    Khi phát 5 lần thất bại (đúng ngưỡng chưa vượt), rồi 4 lần trong cửa sổ khác; phát thao tác hợp lệ giờ hành chính.
    Thì 0 cảnh báo an ninh; chỉ vượt ngưỡng (6 lần) mới sinh; bản ghi lệch đồng hồ ERR-13-126 không gây cảnh báo.

  @TC-13-085 @P1 @Dương
  Kịch bản: TC-13-085 Tiếp nhận, đóng kết luận và đề xuất tạm ngừng HTTT
    # Truy vết: FR-13-053 · UC-13-35 · API-13-058, 059, 060 · UI-13-15 · BR-13-024
    Biết cảnh báo an ninh `NEW`; U-T68-SO.
    Khi tiếp nhận; đề xuất tạm ngừng HTTT `HT-NDXP` kèm lý do; đóng kết luận "sự cố thật".
    Thì `NEW` → `ACKNOWLEDGED` → `CLOSED`; đề xuất tới hộp việc PH-01, HTTT chưa bị tạm ngừng cho tới khi người có quyền duyệt; KT: có từng bước.

  @TC-13-086 @P1 @Âm
  Kịch bản: TC-13-086 Đóng thiếu kết luận, thao tác sai trạng thái
    # Truy vết: FR-13-053 · API-13-058, 059, 060 · ERR-13-023, 020, 008, 028 · BR-13-024
    Biết cảnh báo an ninh `CLOSED`; cảnh báo `NEW`.
    Khi đóng không kết luận; tiếp nhận cảnh báo đã `CLOSED`; đề xuất tạm ngừng không lý do; phiên chưa xác thực lại.
    Thì ERR-13-023; ERR-13-020; ERR-13-008; ERR-13-028.
