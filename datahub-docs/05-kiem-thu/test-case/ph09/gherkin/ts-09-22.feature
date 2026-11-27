# language: vi
# Sinh tự động từ D05-02-PH09 bằng ph09/tools/gen_gherkin.py; không sửa tay.
@PH-09 @TS-09-22
Tính năng: TS-09-22 · Miền giả danh hóa và vòng đời khóa

  @TC-09-075 @P1 @Dương
  Kịch bản: TC-09-075 Tạo miền HMAC và miền token kèm khóa đầu
    # Truy vết: FR-09-031 · API-09-110, 111, 109 · UI-09-12 · BR-09-028
    # Mục đích: Chứng minh khóa riêng theo tenant và theo mục đích để hai tập không nối được (BR-09-028).
    Biết T90; U-T90-SO, U-T90-TA; OpenBao transit.
    Khi TA `POST /pseudonym-domains` `PD-HGD` (`HMAC_SHA256`, `NATIONAL_ID`, mục đích `MD-TRACUU-HGD`).
    Và tạo `PD-TK` (`MD-THONGKE`) và `PD-TOKEN` (`TOKEN_TRANSIT`).
    Và `GET /pseudonym-domains/PD-HGD/keys`.
    Thì bước 1 và 2 `201`, mỗi miền có khóa `ACTIVE` phiên bản 1 trong OpenBao, KT: có. Bước 3 không có giá trị khóa; tên khóa mang mã tenant. Tạo `PD-HGD` lần hai `409` ERR-09-045.

  @TC-09-076 @P1 @Dương @Âm
  Kịch bản: TC-09-076 Xoay khóa cảnh báo mất nhất quán, giãn cách tối thiểu
    # Truy vết: FR-09-034 · API-09-116, 115 · ERR-09-047 · BR-09-029, 033 · EVT-09-16 · PERM-09-policy-approve
    # Mục đích: Chứng minh xoay giữ khóa cũ ở `DECRYPT_ONLY` và chặn xoay quá gần.
    Biết T90; `PD-HGD` khóa v1 vừa tạo; `09.pseudo.min-rotate-days = 30`; U-T90-DA1.
    Khi DA1 `POST /pseudonym-domains/PD-HGD/keys:rotate` với `confirmInconsistency = false`.
    Và DA1 xoay lại kèm `confirmInconsistency = true`.
    Và DA1 xoay lần hai ngay.
    Thì bước 1 từ chối `422` ERR-09-003 kèm cảnh báo bí danh đổi. Bước 2 `200`, v2 `ACTIVE`, v1 `DECRYPT_ONLY`, EVT: `pseudonym-key.state-changed`. Bước 3 `409` ERR-09-047 nêu số ngày chờ.

  @TC-09-077 @P1 @Âm @Dương
  Kịch bản: TC-09-077 Hủy khóa: chặn khi còn dùng, hai người duyệt, chờ trước khi hủy
    # Truy vết: FR-09-034 · API-09-117, 118 · ERR-09-046, 005 · BR-09-033
    # Mục đích: Chứng minh BR-09-033.
    Biết T90; khóa v1 còn dữ liệu giải được; `09.pseudo.destroy-delay-days = 30`; U-T90-TA, U-T90-DA1.
    Khi TA `POST /pseudonym-keys/{v1}:disable`; rồi `:destroy` khi còn dữ liệu dùng khóa v1.
    Và sau khi không còn dữ liệu, TA `:destroy`; TA tự duyệt.
    Và DA1 duyệt; tiến đồng hồ 30 ngày.
    Thì bước 1 `:disable` `200` (`DISABLED`), `:destroy` `409` ERR-09-046. Bước 2 tự duyệt `403` ERR-09-005. Bước 3 sau 30 ngày `DESTROYED`, EVT: `pseudonym-key.state-changed`, KT: có (key-destroy).
