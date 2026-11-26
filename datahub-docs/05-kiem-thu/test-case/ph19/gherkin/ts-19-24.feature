# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-24
Tính năng: TS-19-24 · Nhật ký kiểm toán và tích hợp

  @TC-19-576 @P1 @Dương
  Kịch bản: TC-19-576 Mọi thao tác ghi có kiểm toán
    # Truy vết: FR-19-053 · BR-19-029 · NFR-19-015
    Biết bộ ca chạy lại toàn bộ thao tác ghi của TS-19-01…29 trên SIT.
    Khi với mỗi API ghi của nhóm quản trị (danh sách lấy từ OpenAPI, `x-audit: true`), so số bản ghi `payment.audit.recorded.v1` với số lời gọi thành công.
    Thì bằng nhau 100%; mỗi bản ghi có người, thời điểm, tenant, đối tượng, hành động, lý do (khi bắt buộc), `trace_id`, không chứa bí mật hay dữ liệu cá nhân bản rõ.

  @TC-19-577 @P1 @Âm
  Kịch bản: TC-19-577 Không ghi được kiểm toán thì hủy thao tác
    # Truy vết: FR-19-053 · BR-19-029 · ERR-19-050
    Biết tiêm lỗi: bảng `outbox_event` từ chối ghi bản ghi loại `AUDIT` (trigger thử nghiệm).
    Khi U-APR1 duyệt một đề nghị kích hoạt NCC.
    Thì `503` ERR-19-050; đề nghị vẫn `PENDING`; NCC không đổi trạng thái (một giao dịch CSDL bị hoàn tác).

  @TC-19-578 @P2 @Dương
  Kịch bản: TC-19-578 Xem nhật ký tích hợp đã che, lọc theo giao dịch
    # Truy vết: FR-19-054, 055 · API-19-075, 076 · UI-19-23 · LGC-PAY-011, 021
    Biết U-OPR1; TX-OK đã có khởi tạo, IPN, truy vấn, webhook.
    Khi mở UI-19-23, lọc mã TX-OK.
    Và mở chi tiết lượt khởi tạo.
    Thì bước 1: bốn lượt đủ hướng, thao tác, mã kết quả, độ trễ. Bước 2: nội dung đã che (chữ ký, bí mật, dữ liệu cá nhân); có liên kết vết PH-13.

  @TC-19-579 @P2 @Âm
  Kịch bản: TC-19-579 Nhật ký tích hợp không có quyền, tỉnh khác
    # Truy vết: FR-19-054 · API-19-075, 076 · ERR-19-046, 020
    Biết U-ACC1 (không có `log-read` theo giả định khung §13); U-ADM1-T99.
    Khi U-ACC1 gọi API-19-075.
    Và U-ADM1-T99 gọi API-19-076 với mã nhật ký của T68.
    Thì bước 1: 403-PQ. Bước 2: 404-ẩn.
