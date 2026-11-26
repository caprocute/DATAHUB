# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-03
Tính năng: TS-19-03 · Kích hoạt NCC có phê duyệt

  @TC-19-051 @P1 @Dương
  Kịch bản: TC-19-051 Gửi đề nghị kích hoạt khi checklist đạt
    # Truy vết: FR-19-005 · BR-19-010 · API-19-012 · UI-19-06 · LGC-PAY-007
    Biết U-ADM1.
    Khi mở UI-19-06, đi bước ① → ④, nhập ghi chú, bấm "Gửi đề nghị kích hoạt".
    Và `GET /providers/{id}`.
    Thì bước 1 gọi `POST /providers/{id}/lifecycle-requests` `{"action":"ACTIVATE"}` trả `201` với `approval` `PENDING`, loại `PROVIDER_ACTIVATE`. Bước 2: `status = PENDING_ACTIVATION`, `hasPendingChange = true`. U-APR1 thấy đề nghị trong hộp "Chờ tôi quyết định" của UI-19-13 và huy hiệu menu tăng 1. KT: có (`APPROVAL_REQUEST_CREATE`). EVT: `approval.requested`.

  @TC-19-052 @P1 @Âm
  Kịch bản: TC-19-052 Gửi đề nghị khi thiếu từng điều kiện checklist
    # Truy vết: FR-19-005 · BR-19-010 · API-19-012 · ERR-19-035
    Biết U-ADM1; bốn bản sao của PV-NEW, mỗi bản thiếu đúng một điều kiện: kiểm tra kết nối thật cách 25 giờ; giao dịch thử chỉ `PASSED_WITHOUT_IPN`; khóa thật còn 29 ngày; thiếu đầu mối nghiệp vụ.
    Khi gửi đề nghị `ACTIVATE` cho từng bản.
    Thì mỗi lần trả `422` ERR-19-035 với `detail` liệt kê đúng một mục thiếu; trạng thái giữ `DRAFT`; không tạo `approval_request`. Nút "Gửi đề nghị" ở UI-19-06 vô hiệu với tooltip nêu đúng mục thiếu.

  @TC-19-053 @P1 @Dương
  Kịch bản: TC-19-053 Người khác người lập duyệt kích hoạt
    # Truy vết: FR-19-005 · BR-19-011 · API-19-049, 050 · UI-19-13
    Biết đề nghị từ TC-19-051; U-APR1.
    Khi U-APR1 mở UI-19-13, mở đề nghị, xem khối "Kiểm tra lại lúc duyệt", bấm "Duyệt".
    Và `GET /providers/{id}`.
    Thì bước 1 gọi `POST /approval-requests/{id}/decisions` `{"decision":"APPROVE"}` có `If-Match`, trả `200`, `status = APPROVED`. Bước 2: `status = ACTIVE`, `activatedAt` có giá trị, `effectiveFrom` theo đề nghị. KT: có (`APPROVAL_DECIDE`, `PROVIDER_ACTIVATE`). EVT: `provider.activated`, `approval.decided`.

  @TC-19-054 @P1 @Âm @Bảo @mật
  Kịch bản: TC-19-054 Người lập tự duyệt, người duyệt khi checklist đổi
    # Truy vết: FR-19-005 · BR-19-010, 011 · API-19-050 · ERR-19-033, 035, 046
    Biết U-AA1 (vừa quản trị vừa phê duyệt) lập đề nghị kích hoạt cho bản sao PV-NEW; U-APR1; U-ADM2.
    Khi U-AA1 gọi `POST /approval-requests/{id}/decisions` `APPROVE`.
    Và U-AA1 mở UI-19-13.
    Và U-ADM2 gọi duyệt.
    Và cho khóa thật hết hạn (đồng hồ giả +2 năm), U-APR1 gọi duyệt.
    Thì bước 1 trả `403` ERR-19-033 (so theo `sub`, không theo tên). Bước 2: nút "Duyệt" vô hiệu kèm "Bạn là người lập đề nghị này". Bước 3 trả 403-PQ. Bước 4 trả `422` ERR-19-035; đề nghị vẫn `PENDING`. Mọi bước: NCC giữ `PENDING_ACTIVATION`.

  @TC-19-055 @P2 @Dương
  Kịch bản: TC-19-055 Từ chối, rút và hết hạn đề nghị kích hoạt
    # Truy vết: FR-19-005 · BR-19-011 · API-19-050 · ERR-19-034 · UI-19-13
    Biết ba đề nghị kích hoạt A, B, C trên ba bản sao PV-NEW.
    Khi U-APR1 từ chối A không có ý kiến.
    Và U-APR1 từ chối A với ý kiến 20 ký tự.
    Và U-ADM1 (người lập) rút B.
    Và tiến đồng hồ 7 ngày 1 phút, chạy ApprovalExpiryJob cho C.
    Và U-APR1 duyệt C.
    Thì bước 1 trả `400` ERR-19-001. Bước 2: A `REJECTED`, NCC về `DRAFT`. Bước 3: B `WITHDRAWN`, NCC về `DRAFT`. Bước 4: C `EXPIRED`, NCC về `DRAFT`, người lập nhận thông báo. Bước 5 trả `409` ERR-19-034. KT: có cho bước 2, 3, 4.
