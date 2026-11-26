# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-23
Tính năng: TS-19-23 · Chi tiết giao dịch

  @TC-19-551 @P1 @Dương
  Kịch bản: TC-19-551 Chi tiết đủ khối, dòng thời gian, liên kết vết
    # Truy vết: FR-19-051, 055 · API-19-052, 054 · UI-19-15 · LGC-PAY-019
    Biết U-OPR1; TX-PR (có một lần hoàn một phần).
    Khi mở UI-19-15 của TX-PR.
    Và bấm "Mở vết" ở dòng IPN của dòng thời gian.
    Thì bước 1: đủ khối thông tin chung, người nộp (đã che theo BR-19-031), NCC, đối tác, dòng thời gian (mỗi chuyển trạng thái có nguồn, thời điểm, `sequence`), hoàn tiền, đối soát, webhook; `allowedActions` khớp vai trò. Bước 2 mở PH-13 đúng `trace_id`.

  @TC-19-552 @P1 @Dương
  Kịch bản: TC-19-552 Xem bản rõ dữ liệu cá nhân có lý do
    # Truy vết: FR-19-051 · BR-19-031 · NFR-19-024 · API-19-052 · UI-19-15
    Biết U-ACC1 có `transaction-read-pii`.
    Khi bấm "Hiện thông tin người nộp", nhập lý do "Đối chiếu khiếu nại số 12".
    Và chờ 5 phút.
    Thì bước 1: gọi API-19-052 có `X-Datahub-Reveal-Reason`; hiện bản rõ; KT: `TRANSACTION_PII_REVEALED` có lý do, không chứa bản rõ. Bước 2: giao diện tự che lại.

  @TC-19-553 @P1 @Âm @Bảo @mật
  Kịch bản: TC-19-553 Xem bản rõ không có quyền, thiếu lý do; giao dịch tỉnh khác
    # Truy vết: FR-19-051 · API-19-052 · ERR-19-046, 001, 020
    Biết U-OPR1 (không có `transaction-read-pii`); U-ACC1; TX-T99.
    Khi U-OPR1 gọi API-19-052 có `X-Datahub-Reveal-Reason`.
    Và U-ACC1 gọi với lý do 5 ký tự.
    Và U-ACC1 mở TX-T99.
    Thì bước 1: 403-PQ. Bước 2 trả `400` ERR-19-001. Bước 3: 404-ẩn. Không bước nào trả bản rõ.
