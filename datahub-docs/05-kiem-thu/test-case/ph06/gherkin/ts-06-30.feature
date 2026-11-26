# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-30
Tính năng: TS-06-30 · Phân quyền theo ma trận PERM-06 và bốn mắt

  @TC-06-126 @P1 @Âm @Bảo @mật
  Kịch bản: TC-06-126 Ma trận 12 quyền × 10 vai trò
    # Truy vết: PERM-06-read, update, merge, config, approve, steward, ingest, export, sync, operate, dsr, audit-read · ERR-06-028 · FR-06-001…060
    # Mục đích: Chứng minh từng ô ●, ○, — của ma trận quyền bằng một API đại diện cho mỗi quyền.
    Biết 10 vai trò PA, TA, TO, SO, DS, DA, DO, VW, AU cùng token máy.
    Khi chạy bảng tham số 12 × 10 gọi API đại diện (ví dụ `PERM-06-merge`: `POST …:merge`).
    Và với ô `○`, gọi trên đối tượng trong và ngoài tổ chức.
    Thì Ô ● trả 2xx, ô — trả ERR-00-403; ô ○ chỉ đối tượng thuộc tổ chức, ngoài tổ chức `403` ERR-06-028. DS không có `approve`; DA không có `update`.
    # Hậu điều kiện: Không đổi.

  @TC-06-127 @P1 @Âm @Bảo @mật
  Kịch bản: TC-06-127 Mọi điểm bốn mắt
    # Truy vết: BR-06-004, 019, 024, 027 · ERR-06-005 · FR-06-006, 009, 018, 031, 033, 039, 042, 049 · API-06-103
    # Mục đích: Chứng minh người đề nghị không tự duyệt ở tám điểm bốn mắt của FRS §3.3, kể cả TA có cả hai quyền.
    Biết U-T90-TA (soạn và duyệt, chỉ SIT), DS1, DA1.
    Khi tại từng điểm: kích hoạt mô hình, bộ quy tắc, ưu tiên nguồn, quy tắc sống sót, hợp nhất rủi ro cao, hoàn tác quá hạn, xuất, áp lại, người đề nghị gọi `:approve`.
    Và cùng thao tác do DA khác duyệt.
    Thì bước 1 tám lần `403` ERR-06-005, không đổi trạng thái. Bước 2 tám lần thành công. KT: có ghi cả lượt bị chặn.
    # Hậu điều kiện: Không đổi.

  @TC-06-128 @P1 @Âm @Bảo @mật
  Kịch bản: TC-06-128 Scope tài khoản máy
    # Truy vết: FR-06-010, 046, 047, 048 · ERR-06-014, 037
    # Mục đích: Chứng minh scope `mdm:ingest`, `read`, `resolve`, `search` tách biệt và gắn nguồn, mục đích.
    Biết bốn token, mỗi token một scope.
    Khi mỗi token gọi API của scope khác.
    Và token `mdm:search` khi PH-09 chưa chấp thuận mục đích.
    Thì gọi sai scope ERR-00-403; `mdm:ingest` chỉ cho nguồn đã đăng ký (ERR-06-014); bước 2 `403` ERR-06-037 và không cấp được `mdm:search`.
    # Hậu điều kiện: Không đổi.
