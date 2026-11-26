# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-12
Tính năng: TS-05-12 · Quyền ghi CSDL có đồng ý và duyệt

  @TC-05-048 @P1 @Dương
  Kịch bản: TC-05-048 Đề nghị ghi, SO đồng ý, IA duyệt, cấp đúng quyền
    # Truy vết: FR-05-026 · API-05-036, 037, 038 · UI-05-05, 17 · BR-05-020 · UC-05-09
    Biết U-T68-IE1, U-T68-SO, U-T68-IA1; C-DKKD (đọc ghi); luồng `ghi-ket-qua`.
    Khi IE1 `POST …/flow-accounts` với `access = WRITE`, `tables = ["dkkd.ket_qua"]`, `operations = ["INSERT"]`, `expiresAt` +60 ngày, lý do, số văn bản đồng ý.
    Và SO mở UI-05-17 loại `ph05.db-write`, xem câu lệnh cấp quyền, bấm "Đồng ý".
    Và IA1 duyệt.
    Và dùng tài khoản cấp ra `INSERT` vào `dkkd.ket_qua`, rồi `UPDATE` cùng bảng, rồi `INSERT` vào `dkkd.doanh_nghiep`.
    Thì bước 1 `202`, `REQUESTED`. Bước 2 `CONSENTED`. Bước 3 `ISSUED`. Bước 4: `INSERT` đạt; `UPDATE` và `INSERT` bảng khác bị từ chối. KT: có ở cả ba bước, có số văn bản.

  @TC-05-049 @P1 @Âm
  Kịch bản: TC-05-049 Ghi trên kết nối chỉ đọc, vượt hạn, duyệt khi chưa đồng ý
    # Truy vết: FR-05-026 · API-05-036, 038 · ERR-05-017, 037, 008
    Biết U-T68-IE1, U-T68-IA1; `tc-db-ro` (chỉ đọc); C-DKKD.
    Khi `POST …/tc-db-ro/flow-accounts` với `access = WRITE`.
    Và `POST …/dkkd-db/flow-accounts` với `access = WRITE`, `expiresAt` +120 ngày.
    Và IA1 `POST …:approve` cho yêu cầu còn `REQUESTED`.
    Thì bước 1 `409` ERR-05-017. Bước 2 `422` ERR-05-037. Bước 3 `409` ERR-05-008.

  @TC-05-050 @P1 @Âm @Bảo @mật
  Kịch bản: TC-05-050 Bốn mắt với tài khoản ghi
    # Truy vết: FR-05-026 · API-05-037, 038 · ERR-05-011 · BR-05-009
    Biết U-T68-IA2 (IA + IE) đề nghị ghi; U-T68-SO đã đồng ý.
    Thì `403` ERR-05-011; trạng thái giữ `CONSENTED`.

  @TC-05-051 @P2 @Biên
  Kịch bản: TC-05-051 Tài khoản ghi hết hạn tự thu hồi
    # Truy vết: FR-05-026, 028 · EVT-05-15
    Biết tài khoản từ TC-05-048.
    Thì `EXPIRED`; role ở OpenBao database engine bị xóa; chủ sở hữu luồng và SO nhận thông báo 7 ngày trước hạn và lúc hết hạn.
