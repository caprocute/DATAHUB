# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-26
Tính năng: TS-15-26 · Hỏi đáp, báo lỗi tài liệu, yêu cầu hỗ trợ

  @TC-15-151 @P1 @Dương
  Kịch bản: TC-15-151 Gửi và theo dõi phiếu hỗ trợ
    # Truy vết: FR-15-054 · UC-15-28 · API-15-110, 111, 112, 113 · UI-15-20 · EVT-15-12 · BR-15-030 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết U-T68-DEV-AN; đầu mối hỗ trợ của HT-TUPHAP là U-T68-SV.
    Khi `POST /support/tickets` {kind `SUPPORT_REQUEST`, apiCode `tra-cuu-ho-tich`, tiêu đề, nội dung}.
    Và `GET /support/tickets`, chi tiết; `POST .../messages`.
    Thì `201`, `ticketCode` dạng `HT-2026-nnnn`, `OPEN`, tới đầu mối của chủ dịch vụ (Chi); EVT-15-12 tới PH-13, PH-10 (thông báo); An chỉ thấy phiếu của mình.

  @TC-15-152 @P2 @Dương
  Kịch bản: TC-15-152 Đầu mối xử lý, nhắc quá hạn
    # Truy vết: FR-15-055 · UC-15-28 · API-15-114, 115 · UI-15-28 · BR-15-030 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết phiếu OPEN; Chi có `PERM-15-support`; `15.support.sla-hours = 4`; đồng hồ +5 giờ.
    Khi chi `GET /admin/support/tickets`; `:transition` sang `ANSWERED`, `RESOLVED`, `CLOSED`.
    Và với phiếu khác để quá 5 giờ chưa phản hồi.
    Thì chuyển trạng thái đúng, EVT-15-12 mỗi lần, An nhận thông báo; phiếu quá hạn nhắc đầu mối và báo TA.

  @TC-15-153 @P2 @Âm
  Kịch bản: TC-15-153 Phiếu đóng, của người khác, quá dài, gửi tràn, thiếu quyền
    # Truy vết: FR-15-054, 055 · API-15-110, 112, 113, 114 · ERR-15-001, 003, 005, 029, 037 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết phiếu CLOSED; phiếu của An; Cự; Bình không có `PERM-15-support`; phiếu 4.001 ký tự; 6 phiếu/giờ.
    Khi thêm tin vào phiếu CLOSED.
    Và cự `GET` phiếu của An.
    Và gửi phiếu 4.001 ký tự; gửi 6 phiếu trong 1 giờ.
    Và bình `GET /admin/support/tickets`; Chi truy cập phiếu của dịch vụ khác.
    Thì `409` ERR-15-029; `404` ERR-15-001; `400` ERR-15-003; `429` ERR-15-037; Bình `403` ERR-15-005; phiếu ngoài phạm vi `404`.

  @TC-15-154 @P3 @Dương
  Kịch bản: TC-15-154 Hỏi đáp công khai, báo lỗi tài liệu, đánh giá
    # Truy vết: FR-15-053 · UC-15-28 · API-15-107, 108, 109 · UI-15-04, 07 · ERR-15-003, 037 · BR-15-030 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết an; nội dung `<b>x</b> DH-CANARY`; gửi liên tục quá ngưỡng.
    Khi `POST /catalog/apis/tra-cuu-ho-tich/questions`; `GET`.
    Và `POST /feedback` (báo lỗi tài liệu, đánh giá 4 sao).
    Và gửi nội dung rỗng; gửi vượt ngưỡng.
    Thì câu hỏi là văn bản thuần (thẻ HTML hiện nguyên chữ, không dựng); phản hồi tới đầu mối; `400` ERR-15-003; `429` ERR-15-037.
