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

  @TC-14-134 @P2 @Âm @Bảo @mật
  Kịch bản: TC-14-134 Nhật ký khai thác và báo cáo sử dụng sai: khoảng quá rộng, nhóm sai, thiếu quyền
    # Truy vết: FR-14-052 · API-14-065, 066 · UI-14-13 · ERR-14-003 · BR-14-008, 029 · PERM-14-audit-read.
    Biết U-T68-AU, U-T68-VW; nhật ký của T68 và T01.
    Khi `GET /usage` khoảng 93 ngày.
    Và `GET /usage?groupBy=KHAC`.
    Và `POST /usage:export` thiếu `Idempotency-Key`.
    Và U-T68-VW gọi `GET /usage`.
    Và U-T68-AU lọc `system=HT-CUA-T01`.
    Thì bước 1 `400` ERR-14-003 "Khoảng thời gian báo cáo tối đa 92 ngày." Bước 2 `400` ERR-14-003. Bước 3 `400` ERR-14-003. Bước 4 `403`. Bước 5 trả danh sách rỗng, không có bản ghi của T01. Lượt gọi bị từ chối ở các ca khác (ERR-14-106, 107, 132) vẫn có dòng nhật ký khai thác.

  @TC-14-135 @P2 @Âm
  Kịch bản: TC-14-135 Cảnh báo bất thường: kết thúc không lý do, PH-02 lỗi, cảnh báo tenant khác
    # Truy vết: FR-14-053 · API-14-067, 068 · UC-14-35 · ERR-14-001, 003, 004, 027 · EVT-14-16.
    Biết U-T68-SO, U-T68-AU; cảnh báo `tc-al-01` `OPEN` do một HTTT tra 600 đối tượng khác nhau trong một giờ (ngưỡng 500); cảnh báo `tc-al-t01` của T01; PH-02 dừng ở bước 3.
    Khi `POST /anomaly-alerts/tc-al-01:resolve` xác nhận hợp lệ, không có lý do.
    Và gọi `:resolve` với `decision = REVOKE` khi PH-02 không khả dụng.
    Và xử lý `tc-al-t01`.
    Và xử lý lại cảnh báo đã `RESOLVED`.
    Thì bước 1 `400` ERR-14-003 "Nhập lý do khi xác nhận hợp lệ hoặc đề nghị thu hồi." Bước 2 `502` ERR-14-027 "Chưa gửi được đề nghị thu hồi. Thử lại sau.", cảnh báo vẫn `OPEN`. Bước 3 `404` ERR-14-001. Bước 4 `409` ERR-14-004. Cảnh báo `OPEN` đã phát EVT-14-16 và thông báo cho SO trong 15 phút; không quyết định nào được ghi khi thất bại.

  @TC-14-136 @P3 @Âm @Biên
  Kịch bản: TC-14-136 Báo cáo hạn mức và hiệu quả đệm: kỳ không có dữ liệu, khoảng quá rộng, tháng chưa kết thúc
    # Truy vết: FR-14-057 · API-14-069 · UC-14-36 · ERR-14-001, 003 · NFR-14-005 · PERM-14-audit-read.
    Biết U-T68-AU, U-T68-VW; tenant có dữ liệu tháng trước, không có dữ liệu cho một kỳ `2026-01`; tháng hiện tại chưa kết thúc.
    Khi `POST /reports/quota-efficiency` cho kỳ `2026-01`.
    Và gọi với khoảng tùy chọn 93 ngày.
    Và gọi cho tháng hiện tại.
    Và U-T68-VW gọi tạo báo cáo.
    Thì bước 1 `404` ERR-14-001 "Chưa có dữ liệu sử dụng trong kỳ này." Bước 2 `400` ERR-14-003. Bước 3 `202` rồi `200` nhưng đánh dấu xem tạm. Bước 4 `403`. Báo cáo hợp lệ ở các ca khác có liên kết tải hết hạn sau 30 ngày; thông báo chỉ có liên kết, không đính kèm dữ liệu.
