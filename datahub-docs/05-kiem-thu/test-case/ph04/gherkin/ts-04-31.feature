# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-31
Tính năng: TS-04-31 · Khả dụng và hỗn loạn

  @TC-04-179 @P1 @Khả @dụng
  Kịch bản: TC-04-179 Mất control plane không ảnh hưởng data plane
    # Truy vết: NFR-04-014 · FR-04-061
    Biết F-HT PROD; k6 100 yêu cầu/giây.
    Khi xóa toàn bộ pod `dh-integration` và chặn `pg-core` trong 10 phút.
    Thì gọi luồng vẫn đạt tỷ lệ thành công ≥ 99,9%; runtime không phụ thuộc control plane lúc chạy. Giao diện hiện trang lỗi có mã truy vết; sau khi khôi phục, nhịp tim cập nhật lại tình trạng.

  @TC-04-180 @P1 @Khả @dụng
  Kịch bản: TC-04-180 Mất một bản sao runtime
    # Truy vết: NFR-04-014 · FR-04-051
    Biết 2 bản sao, PodDisruptionBudget `minAvailable = 1`.
    Khi giết một pod mỗi 2 phút trong 20 phút.
    Thì tỷ lệ lỗi < 0,1%; bản tin bất đồng bộ không mất (so số vào, số ra, số DLQ).

  @TC-04-181 @P2 @Khả @dụng
  Kịch bản: TC-04-181 Mất Kafka tạm thời
    # Truy vết: FR-04-062, 069, 070
    Biết F-DD đang xử lý 50 bản tin/giây.
    Khi cắt mạng tới Kafka 2 phút, khôi phục.
    Thì không mất bản tin, không trùng ở đầu ra (chống trùng theo `ce_id`); luồng đồng bộ không dùng Kafka không bị ảnh hưởng, chặng `audit` đệm cục bộ và gửi bù EVT-04-14.

  @TC-04-182 @P2 @Khả @dụng
  Kịch bản: TC-04-182 Git không sẵn sàng khi đang có lệnh khẩn
    # Truy vết: FR-04-050 · BR-04-018
    Biết gitea dừng 15 phút.
    Khi SO dừng khẩn F-HT.
    Và khôi phục Gitea sau 15 phút.
    Thì luồng dừng ngay; cảnh báo "Chưa đối soát được vào Git" sau 5 phút; ghi đè cục bộ giữ nguyên; khi Gitea trở lại, đối soát hoàn tất và lệnh `RECONCILED`.
