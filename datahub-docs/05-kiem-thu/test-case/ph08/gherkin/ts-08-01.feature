# language: vi
# Sinh tự động từ D05-02-PH08 bằng ph08/tools/gen_gherkin.py; không sửa tay.
@PH-08 @TS-08-01
Tính năng: TS-08-01 · Miền chất lượng, chủ quản và cán bộ phụ trách

  @TC-08-001 @P1 @Dương
  Kịch bản: TC-08-001 Tạo, xem và liệt kê miền
    # Truy vết: FR-08-001 · API-08-001, 002, 003 · UI-08-19 · PERM-08-asset
    Biết T90 đã seed; U-T90-TA; ORG-CA (Công an tỉnh) tồn tại ở PH-20 giả lập (`org-sim`); DS1 có vai trò DS.
    Khi `POST /domains` thân `{domainCode: DAN_CU, name: "Dân cư", ownerOrgCode: ORG-CA, stewardUser: DS1}`
    Và `GET /domains/DAN_CU`
    Và `GET /domains?status=ACTIVE&page=0&size=10`
    Thì bước 1 `201`, tiêu đề `Location` và `ETag`, `status = ACTIVE`. Bước 2 trả đủ `ownerOrgCode`, `stewardUser`. Bước 3 có đúng một miền. KT: có (domain.create), ghi chủ quản và cán bộ phụ trách. EVT: không.

  @TC-08-002 @P1 @Âm
  Kịch bản: TC-08-002 Mã miền trùng hoặc sai mẫu
    # Truy vết: FR-08-001 · API-08-002 · UI-08-19 · ERR-08-002, 003
    Biết miền `DAN_CU` đã có (dom-create).
    Khi `POST /domains` lại với `code = DAN_CU`
    Và `POST /domains` với `code = "dan-cu"`
    Thì bước 1 `409` ERR-08-002. Bước 2 `400` ERR-08-003, `errors[]` trỏ trường `code`, theo mẫu `^[A-Z][A-Z0-9_]{2,31}$`. Không tạo thêm miền.

  @TC-08-003 @P1 @Âm
  Kịch bản: TC-08-003 Miền thiếu chủ quản hoặc cán bộ phụ trách không hợp lệ
    # Truy vết: FR-08-001 · API-08-002 · BR-08-026 · ERR-08-008
    Biết T90; U-T90-TA; U-T90-VW (vai trò VW, không phải DS); tổ chức `ORG-KHONG-CO` không có ở `org-sim`.
    Khi `POST /domains` với `ownerOrgId = ORG-KHONG-CO`
    Và `POST /domains` với `stewardUser` là người dùng VW
    Thì cả hai `422` ERR-08-008, không tạo miền, không bản ghi kiểm toán thành công.

  @TC-08-004 @P2 @Âm
  Kịch bản: TC-08-004 Ngừng miền còn đối tượng đo hoạt động
    # Truy vết: FR-08-001 · API-08-004 · UI-08-19
    Biết miền `DAN_CU` có đối tượng `mdm-citizen` `ACTIVE`.
    Khi `PATCH /domains/DAN_CU` thân `{status: INACTIVE}` với `If-Match` đúng
    Và `POST /assets/mdm-citizen:suspend` (lý do 25 ký tự) rồi lặp bước 1
    Thì bước 1 `409` ERR-08-006, thân liệt kê đối tượng cần ngừng trước. Bước 2 sau khi ngừng đối tượng: `200`, `status = INACTIVE`, phiếu đang mở không tự chuyển.

  @TC-08-005 @P2 @Âm
  Kịch bản: TC-08-005 Sửa miền đồng thời và thiếu If-Match
    # Truy vết: FR-08-001 · API-08-004 · ERR-00-428 · ERR-08-004
    Biết miền `DAN_CU`, `ETag` v1 của U-T90-DS1 và U-T90-TA.
    Khi TA `PATCH /domains/DAN_CU` đổi tên với `If-Match` v1 (thành công, `ETag` v2)
    Và DS1 `PATCH` với `If-Match` v1 cũ
    Và `PATCH` không có `If-Match`
    Thì bước 2 `409` ERR-08-004 và không ghi đè. Bước 3 `428` ERR-00-428.
