# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-24
Tính năng: TS-09-24 · Khôi phục giá trị gốc từ token

  @TC-09-082 @P1 @Dương @Bảo @mật
  Kịch bản: TC-09-082 Đề nghị, duyệt cấp một và hai, thực hiện có MFA
    # Truy vết: FR-09-033 · API-09-119, 122, 124, 121 · UI-09-13 · EVT-09-17 · BR-09-032 · PERM-09-reidentify
    # Mục đích: Chứng minh ba người khác nhau, MFA, kiểm toán trước khi giải, kết quả không lưu.
    Biết T90; 20 token của `PD-TOKEN`; U-T90-SO (đề nghị, thực hiện), DO1 (cấp một), TA (cấp hai).
    Khi SO `POST /reidentification-requests` 20 token, mục đích, căn cứ.
    Và DO1 `:approve` cấp một; TA `:approve` cấp hai.
    Và SO `:execute` không MFA; rồi với MFA.
    Thì bước 1 `PENDING_L1`. Bước 2 `PENDING_L2` rồi `APPROVED`. Bước 3 không MFA bị yêu cầu xác thực lại (ERR-00-401); có MFA `200`, `EXECUTED`, kết quả hiển thị 60 giây rồi hủy, không lưu đĩa, EVT: `reidentification.executed`, KT: có (reid-execute) vĩnh viễn WORM, SO và TA nhận thông báo.

  @TC-09-083 @P1 @Âm
  Kịch bản: TC-09-083 Giá trị quá 100, miền HMAC, tự duyệt, đề nghị hết hạn
    # Truy vết: FR-09-033 · API-09-119, 122, 124 · ERR-09-049, 048, 005, 050
    # Mục đích: Chứng minh các ràng buộc BR-09-032.
    Biết T92 `09.reid.approval-ttl-hours = 1`; U-T90-SO, DO1, TA.
    Khi SO đề nghị 101 token.
    Và SO đề nghị khôi phục giá trị của `PD-HGD`.
    Và SO tự `:approve` cấp một.
    Và đề nghị hợp lệ, chờ 61 phút rồi `:execute`.
    Thì bước 1 `422` ERR-09-049. Bước 2 `422` ERR-09-048. Bước 3 `403` ERR-09-005. Bước 4 `409` ERR-09-050 "Đề nghị khôi phục đã hết hiệu lực. Lập đề nghị mới."

  @TC-09-084 @P1 @Chịu @lỗi @Bảo
  Kịch bản: TC-09-084 Không ghi được kiểm toán thì không khôi phục
    # Truy vết: FR-09-033 · BR-09-057 · ERR-09-010 · API-09-124
    # Mục đích: Chứng minh thao tác đặc quyền bị từ chối khi mất kiểm toán.
    Biết T94; đề nghị `APPROVED`; PH-13 `503`.
    Khi SO `:execute` có MFA khi PH-13 ngừng.
    Thì `503` ERR-09-010, không giải mã token nào, đề nghị vẫn `APPROVED`.
