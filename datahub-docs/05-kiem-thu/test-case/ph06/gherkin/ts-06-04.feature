# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-04
Tính năng: TS-06-04 · Nguồn và ưu tiên nguồn

  @TC-06-015 @P1 @Dương
  Kịch bản: TC-06-015 Đăng ký nguồn gắn HTTT và kênh nạp
    # Truy vết: FR-06-008 · API-06-014, 015, 016 · UI-06-08 · PERM-06-config
    # Mục đích: Chứng minh đăng ký `QG-DANCU` kiểu `NATIONAL_DB` qua kênh `NATIONAL_SYNC` và `HT-YTE` qua `API`, `FLOW`, theo FR-06-008.
    Biết T90; HTTT `HT-YTE`, `HT-GIAODUC` `ACTIVE` ở PH-01; TA.
    Khi `POST /sources` mã `HT-YTE`, `SourceKind = SECTOR_RELATED`, kênh `API`, `FLOW`.
    Và `PATCH /sources/HT-YTE` thêm kênh `EVENT`.
    Và `POST /sources/HT-YTE:suspend` rồi `:resume`.
    Thì nguồn `DRAFT` rồi `ACTIVE`; kênh cập nhật; tạm ngừng rồi tiếp tục đúng `SourceStatus`. Nguồn quốc gia chỉ nhận kênh `NATIONAL_SYNC`. KT: có (source-create, source-update).
    # Hậu điều kiện: Nguồn HT-YTE ACTIVE dùng cho các ca nạp.

  @TC-06-016 @P1 @Âm
  Kịch bản: TC-06-016 HTTT chưa ACTIVE, trùng mã, trỏ thẳng CSDL quốc gia
    # Truy vết: FR-06-008 · BR-06-032 · API-06-015 · ERR-06-002, 003, 012
    # Mục đích: Chứng minh nguồn phải gắn HTTT `ACTIVE` và PH-06 không gọi thẳng CSDL quốc gia, theo BR-06-032.
    Biết HTTT `HT-MOI` `DRAFT` ở PH-01; nguồn `HT-YTE` đã có.
    Khi `POST /sources` mã `HT-MOI`.
    Và `POST /sources` mã `HT-YTE`.
    Và `POST /sources` kiểu `NATIONAL_DB` có `endpoint = https://csdl-quocgia.example`.
    Thì bước 1 `422` ERR-06-012. Bước 2 `409` ERR-06-002. Bước 3 `400` ERR-06-003: không có trường `endpoint`, nguồn quốc gia chỉ đi qua PH-14; egress từ `dh-data` tới host ngoài bị NetworkPolicy chặn (kiểm bằng `curl` trong pod, kết nối bị từ chối).
    # Hậu điều kiện: Không nguồn mới.

  @TC-06-017 @P1 @Dương
  Kịch bản: TC-06-017 Đề xuất và duyệt thứ tự ưu tiên có văn bản
    # Truy vết: FR-06-009 · BR-06-003, 004 · API-06-018, 019, 020 · UI-06-08 · PERM-06-approve
    # Mục đích: Chứng minh thứ tự ưu tiên chỉ có hiệu lực khi có căn cứ và DA khác duyệt, và `QG-DANCU` mức 1 cho thuộc tính thẩm quyền, theo FR-06-009.
    Biết nguồn `QG-DANCU`, `HT-YTE`, `HT-GIAODUC` ACTIVE; DS1 đề nghị, DA1 duyệt.
    Khi `POST /domains/CITIZEN/source-priorities:propose` đặt `QG-DANCU` 1, `HT-YTE` 2, `HT-GIAODUC` 3, kèm số, ngày văn bản `12/QĐ-SKHCN`.
    Và DA1 `POST /source-priority-proposals/{id}:approve`.
    Và `GET /domains/CITIZEN/source-priorities`.
    Thì bước 1 `201` `PENDING_APPROVAL`. Bước 2 `200`. Bước 3 thứ tự áp dụng, thuộc tính `dateOfBirth`, `idNumber` đánh dấu `nationalAuthority` có `QG-DANCU` mức 1. KT: có (priority-propose, priority-approve).
    # Hậu điều kiện: Bảng ưu tiên ACTIVE dùng ở các ca sống sót, golden-create.

  @TC-06-018 @P1 @Âm
  Kịch bản: TC-06-018 Thiếu căn cứ, tự duyệt, nguồn quốc gia không mức 1
    # Truy vết: FR-06-009 · BR-06-003, 004 · ERR-06-005, 013, 022
    # Mục đích: Chứng minh ba điều kiện chặn của FR-06-009.
    Biết như prio-approve; thêm đề xuất của DS1.
    Khi `propose` không có số, ngày văn bản.
    Và DS1 `approve` đề xuất do chính DS1 gửi.
    Và `propose` đặt `HT-YTE` mức 1 cho `dateOfBirth` (thuộc tính thẩm quyền).
    Thì bước 1 `422` ERR-06-013. Bước 2 `403` ERR-06-005 (và ERR-00-403 vì DS không có `approve`). Bước 3 `422` ERR-06-022 (vi phạm BR-06-003).
    # Hậu điều kiện: Bảng ưu tiên không đổi.

  @TC-06-019 @P2 @Dương @Âm
  Kịch bản: TC-06-019 Nguồn tạm ngừng không nạp được
    # Truy vết: FR-06-008 · API-06-017, 021 · ERR-06-014
    # Mục đích: Chứng minh nguồn `SUSPENDED` hoặc `RETIRED` bị từ chối nạp ứng viên, theo FR-06-008.
    Biết nguồn `HT-GIAODUC` ACTIVE; S-T90-INGEST-HT-GIAODUC.
    Khi `:suspend` nguồn; gửi một ứng viên.
    Và `:resume`; gửi lại.
    Và `:retire`; gửi lại.
    Thì bước 1 `403` ERR-06-014. Bước 2 `202` `RECEIVED`. Bước 3 `403` ERR-06-014; liên kết đã có không đổi.
    # Hậu điều kiện: Nguồn HT-GIAODUC RETIRED; dùng nguồn FILE-NHAP cho ca sau.
