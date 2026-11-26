# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-11
Tính năng: TS-05-11 · Tài khoản CSDL chỉ đọc theo luồng

  @TC-05-042 @P1 @Âm @Bảo @mật
  Kịch bản: TC-05-042 Khai báo kết nối db-flow trỏ CSDL control plane bị chặn
    # Truy vết: FR-05-023 · API-05-011 · ERR-05-016 · BR-05-017
    Biết U-T68-IE1; kết nối thử `tc-db-cp` loại `db-flow`.
    Khi `PUT …/tc-db-cp/environments/TEST` với `jdbcUrl` trỏ `pg-core.dh-data.svc`.
    Và với `pg-payment.dh-data.svc`.
    Và với SIM-PG nhưng `allowedSchemas = ["ph04","public"]`.
    Thì cả ba `422` ERR-05-016; không có dòng mới ở `connection_environment`.

  @TC-05-043 @P1 @Dương
  Kịch bản: TC-05-043 Cấp tài khoản chỉ đọc cho luồng, sống 1 giờ
    # Truy vết: FR-05-024 · API-05-035, 036 · EVT-05-15 · UI-05-05 · UC-05-08 · LGC-TOOL-008
    Biết U-T68-IE1; C-DKKD TEST; luồng `dkkd-dong-bo` ở PH-04.
    Khi `POST …/dkkd-db/flow-accounts` với `flowCode = dkkd-dong-bo`, `envs = [TEST]`, `access = READ`, `tables = ["dkkd.doanh_nghiep","dkkd.nganh_nghe"]`.
    Và bằng token `dh-runtime` T68, đọc `database/creds/dh-t68-dkkd-dong-bo-test` ở OpenBao.
    Và dùng thông tin đó `SELECT` từ hai bảng, rồi `SELECT` từ `dkkd.ho_so_mat`.
    Và chờ hết TTL.
    Thì bước 1 `201`, `ISSUED` ngay (không cần duyệt). EVT: `flow-account.changed`. Bước 2 trả tài khoản `lease_duration = 3600`. Bước 3 lần đầu đạt, lần hai `permission denied`. Bước 4 role bị xóa ở SIM-PG.

  @TC-05-044 @P1 @Bảo @mật
  Kịch bản: TC-05-044 Tài khoản chỉ đọc không ghi, không DDL, không vượt RLS
    # Truy vết: FR-05-024 · BR-05-019
    Biết tài khoản từ TC-05-043.
    Thì mọi lệnh bị SIM-PG từ chối. `pg_roles` của tài khoản: `rolsuper`, `rolcreaterole`, `rolcreatedb`, `rolbypassrls` đều `false`; `default_transaction_read_only = on`.

  @TC-05-045 @P2 @Âm
  Kịch bản: TC-05-045 Yêu cầu bảng ngoài phạm vi; luồng không tồn tại
    # Truy vết: FR-05-024 · API-05-036 · ERR-05-027, 033
    Biết U-T68-IE1; C-DKKD `allowedSchemas = dkkd, dm`.
    Khi `POST …/flow-accounts` với `tables = ["ns.luong"]`.
    Và với `flowCode = khong-co`.
    Thì bước 1 `422` ERR-05-027. Bước 2 `422` ERR-05-033.

  @TC-05-046 @P1 @Dương @Âm
  Kịch bản: TC-05-046 Kiểm tra quyền thực tế phát hiện quyền vượt khai báo
    # Truy vết: FR-05-025 · API-05-040 · ERR-05-015 · UI-05-05
    Biết U-T68-IE1; kết nối `tc-db-ro` khai chỉ đọc, tài khoản gốc ở SIM-PG có `INSERT` trên `dkkd.ket_qua`.
    Khi `POST …/tc-db-ro/environments/TEST:inspect-privileges`.
    Và `POST …/tc-db-ro/environments/TEST:enable`.
    Và thu hồi `INSERT` ở SIM-PG, chạy lại bước 1.
    Thì bước 1 `conclusion = EXCESSIVE`, liệt kê `dkkd.ket_qua INSERT`. Bước 2 `422` ERR-05-015. Bước 3 `conclusion = OK`.

  @TC-05-047 @P1 @Dương
  Kịch bản: TC-05-047 Thu hồi tài khoản có hiệu lực trong 60 giây
    # Truy vết: FR-05-028 · API-05-039 · NFR-05-007 · EVT-05-15
    Biết U-T68-SO; tài khoản `ISSUED` đang có phiên mở.
    Thì `200`, `REVOKED`; role bị xóa, phiên bị cắt ≤ 60 giây; lần lấy thông tin mới ở OpenBao bị từ chối. EVT: `flow-account.changed`. KT: có (`FLOW_ACCOUNT_REVOKE`).

  @TC-05-149 @P1 @Dương
  Kịch bản: TC-05-149 Khai báo kết nối db-flow hợp lệ
    # Truy vết: FR-05-023 · API-05-004, 011, 012, 017 · UI-05-03 · LGC-TOOL-008
    Biết U-T68-IE1; SIM-PG có role quản trị `dh_vault_admin` để OpenBao tạo tài khoản động.
    Khi tạo kết nối `tc-db-ok` loại `db-flow`, PostgreSQL, mục đích Chỉ đọc, `allowedSchemas = ["dkkd"]`.
    Và khai `TEST` (`jdbcUrl` SIM-PG, `maxRows = 10000`), ghi bí mật tài khoản quản trị; kiểm tra.
    Thì bước 1 `201`. Bước 2 kiểm tra đạt gồm bước "OpenBao tạo được tài khoản thử và xóa ngay"; role OpenBao mẫu `dh-t68-{flowCode}-test` (SDD §5, FlowAccountService) được tạo và hủy; tài khoản quản trị chỉ nằm ở OpenBao.

  @TC-05-150 @P2 @Âm
  Kịch bản: TC-05-150 Thu hồi lặp, thiếu lý do, thiếu quyền
    # Truy vết: FR-05-028 · API-05-039 · ERR-05-008, 038, 012
    Biết U-T68-SO, U-T68-VW; tài khoản đã `REVOKED` từ TC-05-047; tài khoản khác `ISSUED`.
    Khi SO thu hồi tài khoản đã `REVOKED`.
    Và SO thu hồi tài khoản `ISSUED` không lý do.
    Và VW thu hồi.
    Thì bước 1 `409` ERR-05-008. Bước 2 `400` ERR-05-038. Bước 3 403-PQ.
