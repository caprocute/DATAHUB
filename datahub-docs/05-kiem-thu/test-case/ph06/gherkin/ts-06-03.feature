# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-03
Tính năng: TS-06-03 · Gửi duyệt, kích hoạt, tạm ngừng và ngừng domain

  @TC-06-012 @P1 @Dương
  Kịch bản: TC-06-012 Gửi duyệt rồi DA khác kích hoạt phiên bản
    # Truy vết: FR-06-006 · API-06-008, 009 · EVT-06-10 · BR-06-017 · PERM-06-approve
    # Mục đích: Chứng minh DRAFT, PENDING_APPROVAL, ACTIVE, phiên bản cũ thành SUPERSEDED, theo FR-06-006.
    Biết CITIZEN phiên bản 2 của ca version-diff (T90, NON_BREAKING); DS1 đề nghị, DA1 duyệt.
    Khi DS1 `POST .../model-versions/2:submit`.
    Và DA1 `POST .../model-versions/2:approve`.
    Và đọc topic `t90.mdm.model.activated.v1`.
    Thì bước 1 `200` `PENDING_APPROVAL`. Bước 2 `200` `ACTIVE`, phiên bản 1 `SUPERSEDED`. Bước 3 đúng một bản tin EVT-06-10 chỉ có mã domain, phiên bản. KT: có (submit, approve).
    # Hậu điều kiện: CITIZEN phiên bản 2 ACTIVE.

  @TC-06-013 @P1 @Âm
  Kịch bản: TC-06-013 Tự duyệt bị chặn; từ chối
    # Truy vết: FR-06-006 · API-06-008, 009, 010 · ERR-06-005, 007 · BR-06-004
    # Mục đích: Chứng minh người đề nghị không tự duyệt kể cả TA có cả hai quyền, theo FR-06-006 và ADR-046.
    Biết DEMO-CANBO đủ phân loại; U-T90-TA (soạn và duyệt), DA1.
    Khi TA `submit` rồi TA `approve` chính bản đó.
    Và DA1 `reject` không lý do.
    Và DA1 `reject` với lý do 30 ký tự.
    Thì bước 1 `403` ERR-06-005. Bước 2 `422` ERR-06-007. Bước 3 `200` `REJECTED`, ý kiến lưu. KT: có (reject).
    # Hậu điều kiện: Phiên bản REJECTED; không phát EVT-06-10.

  @TC-06-014 @P2 @Dương @Âm
  Kịch bản: TC-06-014 Tạm ngừng, tiếp tục, ngừng; ngừng khi còn bản ghi vàng
    # Truy vết: FR-06-006 · API-06-011, 097 · ERR-06-006, 011 · BR-06-007
    # Mục đích: Chứng minh chuyển trạng thái domain hợp lệ và chặn chuyển cấm, theo FR-06-006.
    Biết DEMO-CANBO `ACTIVE` không có bản ghi vàng; CITIZEN `ACTIVE` có bản ghi vàng.
    Khi `POST /domains/DEMO-CANBO:suspend`, nạp ứng viên, `:resume`.
    Và `:retire` DEMO-CANBO; sau đó `:resume` lần nữa.
    Và `:retire` CITIZEN.
    Thì bước 1 SUSPENDED nhận ứng viên bị từ chối rồi ACTIVE nhận lại. Bước 2 `RETIRED`; `:resume` `409` ERR-06-006. Bước 3 `422` ERR-06-011. KT: có (suspend, resume, retire).
    # Hậu điều kiện: DEMO-CANBO RETIRED, CITIZEN không đổi.
