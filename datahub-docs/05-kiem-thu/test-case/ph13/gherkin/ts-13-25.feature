# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-25
Tính năng: TS-13-25 · Từ điều kiện bất thường đến thông báo người trực

  @TC-13-072 @P1 @Dương
  Kịch bản: TC-13-072 Luật thỏa đủ thời gian duy trì sinh `FIRING`, gửi thông báo ≤ 60 giây
    # Truy vết: FR-13-044, 045, 046 · UC-13-28 · API-13-030, 090 · UI-13-10 · EVT-13-01 · NFR-13-015
    Biết luật `luat-api-5xx` duy trì 2 phút; lịch trực T68; F-SIM-CHAN.
    Khi phát lỗi 5xx vượt ngưỡng 1 phút, rồi ngừng; phát tiếp 3 phút.
    Và đo từ lúc `FIRING` tới khi kênh giả nhận.
    Thì nhấp nháy 1 phút không sinh cảnh báo; 3 phút sinh một cảnh báo; thông báo p95 ≤ 60 giây tới người trực đúng ca; EVT: `alert.fired`; API-13-090 chỉ nhận từ mTLS của Alertmanager.

  @TC-13-073 @P2 @Dương @Biên
  Kịch bản: TC-13-073 Gom nhóm, chống lặp và chỉ gửi ngoài ứng dụng trong giờ hành chính
    # Truy vết: FR-13-045, 046 · BR-13-028 · API-13-030 · UI-13-10
    Biết 20 cảnh báo cùng luật; mức Cảnh báo lúc 20:00 và 09:00.
    Khi sinh 20 cảnh báo cùng nhãn trong 5 phút.
    Và sinh cảnh báo mức Cảnh báo ngoài giờ rồi trong giờ.
    Thì gom thành một nhóm, một thông báo; ngoài giờ mức Cảnh báo chỉ hiển thị trong ứng dụng, chờ tới 07:30 mới gửi.

  @TC-13-124 @P2 @Âm
  Kịch bản: TC-13-124 Cảnh báo đang tạm ẩn không gửi thông báo mới, luật khác nhau không gom nhầm
    # Truy vết: FR-13-045, 046, 047 · BR-13-021 · API-13-030, 034 · UI-13-10
    Biết cảnh báo `SILENCED` 12 giờ; hai luật khác nhau cùng nhãn dịch vụ.
    Khi tạo thêm 5 lần phát của luật đang tạm ẩn; phát hai luật khác nhau cùng lúc.
    Thì không thông báo mới cho luật tạm ẩn; hai luật khác nhau thành hai nhóm riêng; hết hạn tạm ẩn mà điều kiện còn thì gửi lại.

  @TC-13-074 @P1 @Dương @Biên
  Kịch bản: TC-13-074 Nghiêm trọng chưa xác nhận leo thang 15 phút, 30 phút
    # Truy vết: FR-13-046 · BR-13-022 · EVT-13-03 · ERR-13-121 · UI-13-12
    Biết nhóm nhận ba cấp, ít nhất hai kênh khác loại; `13.alert.escalate-minutes = 15,30`.
    Khi giữ `FIRING` Nghiêm trọng, không xác nhận 31 phút; một lần khác xác nhận ở phút 10.
    Thì cấp 2 ở 15 phút, cấp 3 ở 30 phút, EVT: `alert.escalated`; hết cấp mà chưa ai nhận: ERR-13-121; xác nhận ở phút 10 dừng leo thang.

  @TC-13-075 @P2 @Âm
  Kịch bản: TC-13-075 Kênh thông báo lỗi, luật đánh giá lỗi báo về chính hệ thống
    # Truy vết: FR-13-044, 046, 049 · ERR-13-119, 120 · BR-13-022
    Biết ngắt một kênh F-SIM-CHAN; luật có biểu thức làm Ruler lỗi.
    Khi gửi cảnh báo khi một kênh ngắt.
    Thì chuyển sang kênh khác loại; ERR-13-120 hiển thị ở UI-13-01; luật lỗi đánh giá: ERR-13-119.
