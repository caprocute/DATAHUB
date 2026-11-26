# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-07
Tính năng: TS-13-07 · Kiểm tra toàn vẹn chuỗi

  @TC-13-024 @P1 @Dương
  Kịch bản: TC-13-024 Kiểm tra toàn vẹn theo yêu cầu trên chuỗi nguyên vẹn
    # Truy vết: FR-13-014 · UC-13-07 · API-13-077, 078, 079 · UI-13-14 · EVT-13-07 · BR-13-006
    Biết F-AUD-1K; U-T68-AU đã xác thực lại phiên.
    Khi `POST /verifications` kèm `reason` (12 ký tự) và `Idempotency-Key`.
    Và hỏi `GET /verifications/{id}` đến khi xong.
    Thì `202`; kết quả `PASSED`, số bản ghi 1.000, neo cuối khớp; EVT: `verification-completed`; KT: có (`AUDIT.VERIFY`) với `reason`.

  @TC-13-025 @P1 @Âm
  Kịch bản: TC-13-025 Yêu cầu kiểm tra thiếu lý do, thiếu xác thực lại, đang chạy
    # Truy vết: FR-13-014 · API-13-077 · ERR-13-008, 028, 032, 009
    Biết U-T68-AU; U-T68-TO.
    Khi `POST /verifications` không có `reason`.
    Và gọi khi phiên chưa xác thực lại.
    Và gọi hai lần liên tiếp khi lần một còn chạy.
    Và U-T68-TO gọi.
    Thì bước 1 `400` ERR-13-008; bước 2 `403` ERR-13-028; bước 3 `409` ERR-13-032; bước 4 403-PQ. Không phát sinh lượt kiểm tra nào ngoài lượt đầu.

  @TC-13-026 @P2 @Dương @Biên
  Kịch bản: TC-13-026 Kiểm tra gia tăng khi neo và kiểm tra hằng ngày
    # Truy vết: FR-13-014 · NFR-13-010, 016 · BR-13-033
    Biết F-AUD-1K; `13.audit.verify-cron = 0 3 * * *`.
    Khi kích kiểm tra hằng ngày ở SIT; đo thời gian.
    Và kiểm tra API không có đường sửa, nối lại chuỗi.
    Thì từ neo gần nhất tới đầu chuỗi ≤ 2 phút; không có endpoint sửa hay dựng lại chuỗi (BR-13-033); lượt kiểm tra gia tăng nối với mỗi neo mới.
