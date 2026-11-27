# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-42
Tính năng: TS-20-42 · Chịu lỗi và phục hồi

  @TC-20-224 @P1 @Dương
  Kịch bản: TC-20-224 DU khởi động lại giữa saga, tiếp tục đúng bước
    # Truy vết: FR-20-008 · API-20-015 · BR-20-007 · NFR-20-017
    Biết hai bản DU PH-20; lần chạy tới `S06` (đang chờ báo).
    Khi dừng DU đang giữ khóa lần chạy
    Và bản còn lại nhận lần chạy; `S-PH10` báo `S06`
    Thì lần chạy tiếp tục từ `S06`, không chạy lại `S01…S05`; không bước nào thực hiện hai lần (`Idempotency-Key = {runId}:{stepCode}`).

  @TC-20-225 @P2 @Dương
  Kịch bản: TC-20-225 ShedLock: thu sử dụng, hết hạn ghi đè, nhắc chuyển tiếp chỉ chạy một bản
    # Truy vết: FR-20-028, 032, 052 · NFR-20-008
    Biết hai bản DU; đồng hồ giả lập đến giờ tròn.
    Khi cả hai bản cùng đến giờ thu sử dụng và hết hạn ghi đè
    Thì mỗi việc chạy đúng một lần; không cảnh báo trùng; không thư nhắc trùng.

  @TC-20-226 @P1 @Âm
  Kịch bản: TC-20-226 Phụ thuộc ngừng: PH-12, PH-13, PH-07, PH-18, Git, Argo CD, Kafka
    # Truy vết: ERR-20-062 · ERR-20-024 · ERR-20-109 · NFR-20-020 · FR-20-007, 020
    Biết từng bản giả `503`, riêng Kafka ngừng 5 phút.
    Khi kiểm sẵn sàng khi `iam-sim` `503`
    Và ghi cấu hình khi `git-sim` từ chối
    Và phát sự kiện khi Kafka ngừng
    Thì `ERR-20-017` kèm kiểm `DEPENDENCIES` `BLOCKER` (`ERR-20-062`); `ERR-20-024` 502, không để cấu hình nửa vời; sự kiện giữ ở outbox và phát khi Kafka về, không mất.
