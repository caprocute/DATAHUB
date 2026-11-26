# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-29
Tính năng: TS-14-29 · Nhật ký khai thác, cảnh báo bất thường, báo cáo

  @TC-14-074 @P1 @Dương @Âm
  Kịch bản: TC-14-074 Nhật ký khai thác theo HTTT, xuất báo cáo
    # Truy vết: FR-14-052 · API-14-065, 066 · UI-14-13 · UC-14-35 · NFR-14-020 · ERR-14-003.
    Biết U-T68-AU; 1.000 lượt gọi mẫu của 3 HTTT.
    Khi `GET /usage` lọc theo HTTT, mục đích.
    Và `POST /usage:export`; xuất khoảng thời gian không hợp lệ.
    Thì số dòng nhật ký bằng số giao dịch (100 %); tệp xuất không có DLCN; khoảng sai `400` ERR-14-003.

  @TC-14-075 @P2 @Dương @Bảo @mật
  Kịch bản: TC-14-075 Cảnh báo bất thường khai thác và xử lý
    # Truy vết: FR-14-053 · API-14-067, 068 · UC-14-35 · UI-14-13 · ERR-14-004, 001.
    Biết U-T68-SO; `14.anomaly.lookups-per-hour = 500`; S-HT-MC tra 600 đối tượng khác nhau trong 1 giờ; Đợt 2.
    Khi chạy tra hàng loạt rồi `GET /anomaly-alerts`.
    Và `POST …/{alertId}:resolve` kèm kết luận; giải quyết lại; cảnh báo của T01.
    Thì cảnh báo tra cứu hàng loạt (THR-51) nêu HTTT, mục đích; `:resolve` ghi kiểm toán; lần hai `409` ERR-14-004; T01 `404` ERR-14-001.

  @TC-14-076 @P3 @Dương
  Kịch bản: TC-14-076 Báo cáo hạn mức và hiệu quả đệm
    # Truy vết: FR-14-057 · API-14-069 · UC-14-36 · UI-14-13 · NFR-14-005.
    Biết U-T68-TA; 7 ngày dữ liệu đệm mẫu; Đợt 3.
    Khi `POST /reports/quota-efficiency` cho 7 ngày.
    Thì báo cáo có tỷ lệ trúng đệm theo dịch vụ, số lượt tiết kiệm, dự báo cạn hạn mức; số khớp `GET /cache/stats`.
