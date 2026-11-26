# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-14
Tính năng: TS-06-14 · Duyệt bốn mắt hợp nhất rủi ro cao

  @TC-06-065 @P1 @Dương @Biên
  Kịch bản: TC-06-065 Năm điều kiện rủi ro cao
    # Truy vết: FR-06-031, 027 · BR-06-019
    # Mục đích: Chứng minh `RiskLevel` theo từng điều kiện của BR-06-019.
    Biết năm cặp: (a) hai bản ghi vàng cùng 3 liên kết; (b) thuộc tính quan trọng khác nhau; (c) vàng-vàng điểm 0,94; (d) hợp nhất thủ công 3 bản ghi; (e) tách bản ghi có 3 liên kết; cặp đối chứng 2 liên kết điểm 0,96.
    Khi tạo thao tác cho từng cặp, đọc `riskLevel`.
    Thì năm cặp `HIGH` (chờ duyệt, bản ghi vàng `LOCKED`); cặp đối chứng `LOW`; biên 0,95 vàng-vàng là `LOW`, 0,949 là `HIGH`.
    # Hậu điều kiện: Năm thao tác PENDING_APPROVAL.

  @TC-06-066 @P1 @Dương
  Kịch bản: TC-06-066 DA khác duyệt và từ chối
    # Truy vết: FR-06-031 · API-06-049, 061, 109, 112 · BR-06-019 · EVT-06-03 · PERM-06-approve
    # Mục đích: Chứng minh duyệt thực hiện thao tác trong một giao dịch và từ chối trả về người đề nghị, theo FR-06-031.
    Biết thao tác (a), (b) của risk-classify; DS1 đề nghị, DA1.
    Khi DA1 `:approve` (a).
    Và DA1 `:reject` (b) kèm ý kiến.
    Và DA1 đổi `survivorId` rồi duyệt một thao tác (c).
    Thì bước 1 hợp nhất áp, mở khóa, mục `RESOLVED`, EVT-06-03. Bước 2 mục về `ASSIGNED` cho DS1 kèm ý kiến, bản ghi vàng mở khóa. Bước 3 coi như từ chối kèm đề nghị. KT: có (steward-approve, reject).
    # Hậu điều kiện: (a) đã áp; (b), (c) về DS1.

  @TC-06-067 @P1 @Âm
  Kịch bản: TC-06-067 Tự duyệt, DA duy nhất, nhắc và giao lại
    # Truy vết: FR-06-031 · API-06-049 · ERR-06-005, 031 · UI-06-05
    # Mục đích: Chứng minh người đề nghị không tự duyệt, bản ghi vàng `LOCKED` chặn thao tác khác và việc nhắc, giao lại, theo FR-06-031.
    Biết thao tác (d); TA vừa đề nghị vừa có `approve` (cấu hình sai chủ ý, SIT); đồng hồ giả lập.
    Khi TA `:approve` thao tác do TA đề nghị.
    Và DS2 sửa tay bản ghi vàng đang `LOCKED`.
    Và tiến 3 ngày làm việc, rồi 6 ngày.
    Thì bước 1 `403` ERR-06-005 dù có quyền. Bước 2 `409` ERR-06-031. Bước 3 nhắc DA sau 2 ngày làm việc; quá 5 ngày giao DA khác của tenant (Q06-45 nếu chỉ có một DA).
    # Hậu điều kiện: (d) vẫn PENDING_APPROVAL.
