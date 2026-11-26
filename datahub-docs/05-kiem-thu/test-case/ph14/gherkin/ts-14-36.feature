# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-36
Tính năng: TS-14-36 · Chịu lỗi và phục hồi

  @TC-14-093 @P1 @Chịu @lỗi
  Kịch bản: TC-14-093 Hàng chờ giữ ≥ 100.000 bản tin khi quốc gia gián đoạn
    # Truy vết: NFR-14-011 · FR-14-016 · API-14-076 · ERR-14-118 · BR-14-030.
    Biết `T90`; `sim-ndxp` `DOWN`; giả lập nhanh 72 giờ.
    Khi gửi 100.000 yêu cầu bất đồng bộ.
    Và giữ `DOWN` 72 giờ giả lập; khôi phục.
    Thì 0 bản tin mất, 0 bản tin gửi trùng; gửi lại hết theo thứ tự sau khôi phục; sự cố quá `14.queue.max-age-hours` đánh dấu `FAILED` có cảnh báo.

  @TC-14-094 @P1 @Chịu @lỗi
  Kịch bản: TC-14-094 Mất một bản sao, OpenBao chậm; nạp nóng; khả dụng
    # Truy vết: NFR-14-008, 010, 012, 017, 026 · FR-14-033, 038.
    Biết 3 bản sao trên 2 nút; tải 300 lượt/giây.
    Khi xóa một bản sao, rồi một nút.
    Và đổi luật định tuyến, hạn mức, chứng thư khi đang tải.
    Và đo khả dụng 24 giờ ở đường gọi ra và chiều vào.
    Thì không lượt nào mất; bộ đếm hạn mức vẫn chính xác; cấu hình mới có hiệu lực ≤ 30 giây không khởi động lại; khả dụng đường gọi ra ≥ 99,9 %, chiều vào ≥ 99,95 % (số liệu đo trên SIT, ngoại suy theo tháng).

  @TC-14-095 @P2 @Chịu @lỗi @Âm
  Kịch bản: TC-14-095 Kho chống trùng (Valkey) không khả dụng thì từ chối thao tác ghi
    # Truy vết: FR-14-010, 016 · API-14-075, 076 · ERR-14-133 · BR-14-030.
    Biết S-HT-MC; V-HT-DK; dừng Valkey.
    Khi gọi thao tác ghi có `Idempotency-Key`.
    Và gọi thao tác đọc không đệm.
    Và khôi phục Valkey, gọi lại ghi.
    Thì bước 1 `503` ERR-14-133, quốc gia nhận 0 bản tin (đóng an toàn, không gửi trùng); bước 2 vẫn chạy được; bước 3 thành công.
