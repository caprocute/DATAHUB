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

  @TC-14-148 @P1 @Chịu @lỗi @Âm
  Kịch bản: TC-14-148 Dừng OpenBao giữa tải: không ký thì không gửi, không mất bản tin, tự gửi lại
    # Truy vết: NFR-14-010, 013 · FR-14-026, 016 · BR-14-001 · ERR-14-112, 035 · NFR-14-018.
    Biết tải 300 lượt/giây có cả lượt đồng bộ và bất đồng bộ (V-HT-DK); OpenBao 3 nút; Chaos Mesh.
    Khi dừng cả OpenBao trong 5 phút giữa lượt tải; ghi thời điểm cảnh báo.
    Và gọi đồng bộ và bất đồng bộ khi OpenBao dừng.
    Và khởi động lại OpenBao; chờ hàng chờ xả.
    Và đối chiếu số bản tin gửi, nhận tại `sim-ndxp` với giao dịch.
    Thì phát hiện ≤ 30 giây, cảnh báo cho SO. Lượt đồng bộ `503` ERR-14-112 "Chưa ký được bản tin nên chưa gửi. Hệ thống sẽ gửi lại khi sẵn sàng." kèm `retryAfterSeconds`; không bản tin nào tới `sim-ndxp` khi chưa ký. Lượt bất đồng bộ ở lại hàng chờ rồi tự gửi sau khi OpenBao hoạt động, không mất, không trùng. 0 bản tin mất; 100 % bản tin yêu cầu ký đều đã ký.

  @TC-14-149 @P1 @Chịu @lỗi @Biên
  Kịch bản: TC-14-149 Mất Valkey: đệm bị bỏ qua, hạn mức đếm cục bộ, phục hồi hợp nhất bộ đếm
    # Truy vết: FR-14-033, 035 · NFR-14-008, 012, 024 · BR-14-012 · ERR-14-104, 133.
    Biết 3 bản sao; hạn mức V-HT 3.000 lượt mỗi giờ; tải 100 lượt/giây; V-HT có mục đệm; Chaos Mesh dừng Valkey trong 10 phút.
    Khi dừng Valkey khi đang tải; gọi V-HT thao tác đọc.
    Và quan sát tổng số lượt chuyển ra quốc gia so với hạn mức.
    Và gọi thao tác ghi khi Valkey dừng.
    Và khởi động lại Valkey; đọc bộ đếm và `quota_usage`.
    Thì bước 1 `200` từ lượt gọi thật, không trả lỗi vì lý do đệm, có cảnh báo. Bước 2 mỗi bản sao đếm với giới hạn bằng một phần ba hạn mức, tổng không vượt 3.000 lượt mỗi giờ, cảnh báo "đếm suy giảm". Bước 3 `503` ERR-14-133, không gửi ra quốc gia. Bước 4 bộ đếm phục hồi từ `quota_usage`, sai lệch tối đa một phút; ngưỡng 70, 85, 95 % không bị phát trùng.

  @TC-14-150 @P1 @Chịu @lỗi @Âm
  Kịch bản: TC-14-150 Mất kết nối giữa chừng khi ghi: đối soát trước khi gửi lại, không ghi trùng
    # Truy vết: FR-14-010, 016, 018 · BR-14-030 · API-14-075, 076, 077 · ERR-14-115, 116 · NFR-14-011.
    Biết S-HT-MC; V-HT-DK; `sim-ndxp` nhận bản tin rồi cắt kết nối trước khi phản hồi cho 20 yêu cầu đăng ký; mỗi yêu cầu một `Idempotency-Key`.
    Khi gửi 20 yêu cầu đăng ký khi `sim-ndxp` cắt kết nối sau khi nhận.
    Và khôi phục `sim-ndxp`; để bộ đối soát chạy.
    Và gửi lại từng yêu cầu bằng cùng `Idempotency-Key`.
    Và đếm số bản đăng ký thực sự có ở `sim-ndxp`.
    Thì bước 1 mọi giao dịch `UNKNOWN_RESULT`, không thử lại tự động. Bước 2 giao dịch được đối soát bằng `getDossierStatus` theo `caseCode` rồi chuyển `SUCCEEDED`. Bước 3 trả kết quả lần đầu, không gửi lại. Bước 4 đúng 20 bản đăng ký, không có bản nào trùng.
