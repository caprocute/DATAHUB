# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-20
Tính năng: TS-10-20 · DLQ tầng sự kiện: tra cứu, loại bỏ, phát lại mục DLQ

  @TC-10-089 @P1 @Dương @Âm
  Kịch bản: TC-10-089 Tra cứu mục DLQ và xem nội dung có lý do
    # Truy vết: FR-10-050 · API-10-060, 061, 103 · UI-10-15 · ERR-10-009, 054 · UC-10-18
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-050 (Tra cứu, xem và loại bỏ mục DLQ).
    Biết U-T68-TO, U-T68-VW; DLQ-30; 2 mục DLQ của SUB-KS (`SENSITIVE`); S-PH18.
    Khi mở UI-10-15 của TP-CP, lọc `errorCode = ERR-10-112`, `status = NEW`.
    Và VW `GET /dlq-entries/{id}/payload`.
    Và TO xem nội dung một mục SUB-KS không lý do, rồi có lý do.
    Và S-PH18 `GET /dlq-entries?status=NEW`.
    Thì bước 1 20 mục, đủ `sourcePartition`, `sourceOffset`, `eventId`, `attempts`. Bước 2 403-PQ. Bước 3 `400` ERR-10-009; rồi `200`, nội dung giải mã qua OpenBao transit, đã che theo chính sách khi có; KT: có (xem dữ liệu Nhạy cảm). Bước 4 `200` chỉ siêu dữ liệu, không có nội dung.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-090 @P1 @Dương @Âm
  Kịch bản: TC-10-090 Loại bỏ mục DLQ; mục đã xử lý; quá giới hạn
    # Truy vết: FR-10-050 · API-10-062 · ERR-10-009, 036 · BR-10-024
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-050 (Tra cứu, xem và loại bỏ mục DLQ).
    Biết U-T68-TO, U-T68-SO; DLQ-30.
    Khi TO `POST /dlq-entries:discard` với 10 mục ERR-10-113 và lý do.
    Và loại bỏ lại một trong 10 mục.
    Và gửi 1.001 mã mục; SO loại bỏ một mục.
    Và đặt đồng hồ +31 ngày; chạy bộ dọn đêm.
    Thì bước 1 `200`, 10 mục `DISCARDED`. Bước 2 `409` ERR-10-036. Bước 3 `400` ERR-10-003 (MVP tối đa 1.000 mục, loại bỏ theo bộ lọc thuộc Đợt sau theo FRS 0.3); SO 403-PQ. Bước 4 10 mục sang `PURGED`, `dlq_payload` bị xóa, siêu dữ liệu còn; 20 mục `NEW` giữ nguyên nội dung.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.

  @TC-10-091 @P1 @Dương
  Kịch bản: TC-10-091 Phát lại mục DLQ có duyệt từ nội dung đã lưu
    # Truy vết: FR-10-053, 052 · API-10-064, 059, 087, 088, 089 · EVT-10-12 · BR-10-028 · UC-10-18
    # Mục đích: Chứng minh luồng thành công, theo FR-10-053 (Phát lại mục DLQ).
    Biết U-T68-TO, U-T68-IA1; 20 mục `NEW` ERR-10-112; SIM-WH đã sửa về `200`; topic gốc đã hết lưu giữ cho 5 mục.
    Khi TO đề nghị `replayMode = DLQ_ENTRIES` với 20 mục, lý do, `acknowledgeDuplicates = true`.
    Và IA1 duyệt.
    Thì bước 1 `201`, `PENDING_APPROVAL`. Bước 2 mục sang `REPLAY_PENDING` rồi `REPLAYED`; cả 5 mục hết lưu giữ vẫn giao được (từ `dlq_payload`); SIM-WH nhận `X-Datahub-Replay`, cùng `Webhook-Id` lần đầu. Lượt `COMPLETED`, `deliveredRecords = 20`. EVT: `replay.completed`.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-092 @P2 @Dương @Âm
  Kịch bản: TC-10-092 Tự duyệt phát lại DLQ dưới ngưỡng; giao lại vẫn lỗi
    # Truy vết: FR-10-053 · API-10-064 · BR-10-028
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-053 (Phát lại mục DLQ).
    Biết T95 (`10.replay.dlq-auto-approve-max = 10`); 15 mục `NEW`; SIM-WH vẫn `500`.
    Khi đề nghị phát lại 8 mục; đề nghị phát lại 15 mục.
    Thì 8 mục được tự duyệt (yêu cầu `APPROVED`, `autoApproved = true`, `decidedBy = system:auto`); giao lại lỗi nên mục về `NEW`, `attempts` tăng. 15 mục cần người duyệt. Ở T68 (ngưỡng 0) mọi đề nghị đều cần duyệt.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
