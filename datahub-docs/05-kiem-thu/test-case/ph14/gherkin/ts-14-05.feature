# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-05
Tính năng: TS-14-05 · Đặc tả có phiên bản và phát hiện lệch

  @TC-14-015 @P1 @Dương
  Kịch bản: TC-14-015 Nạp đặc tả mới, phát hiện lệch, kích hoạt
    # Truy vết: FR-14-008 · API-14-018, 019, 020 · UI-14-05 · UC-14-05.
    Biết U-T68-IE; V-HT có đặc tả v1 `ACTIVE`; tệp v2 chỉ thêm trường tùy chọn.
    Khi `POST /services/hotich-tra-cuu/specs` tệp v2.
    Và `GET …/specs` xem báo cáo lệch.
    Và `POST …/specs/2:activate`.
    Thì v2 `UPLOADED`, báo cáo "không phá vỡ"; kích hoạt `ACTIVE`, v1 giữ lịch sử; hiệu lực ≤ 30 giây (NFR-14-026).

  @TC-14-016 @P1 @Âm
  Kịch bản: TC-14-016 Đặc tả trùng phiên bản, hỏng, phá vỡ chưa duyệt, tải xa lỗi
    # Truy vết: FR-14-008 · API-14-019, 020 · ERR-14-010, 011, 012, 131 · BR-14-024.
    Biết U-T68-IE; v2 đã có; tệp v2 nội dung khác; tệp XML có thực thể ngoài (XXE); v3 xóa trường bắt buộc; WSDL từ xa `sim-ndxp` chế độ `DOWN`.
    Khi nạp lại số phiên bản 2 nhưng khác nội dung.
    Và nạp tệp không đọc được, vượt giới hạn, và tệp có thực thể ngoài.
    Và nạp v3 phá vỡ rồi kích hoạt khi chưa duyệt.
    Và nạp đặc tả từ URL xa khi giả lập không phản hồi.
    Thì bước 1 `409` ERR-14-010; bước 2 `422` ERR-14-011, không giải thực thể ngoài; bước 3 `422` ERR-14-012; bước 4 `502` ERR-14-131 và hệ thống dùng bản đã lưu.
