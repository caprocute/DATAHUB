# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-01
Tính năng: TS-06-01 · Gói domain nền và xem domain

  @TC-06-001 @P2 @Dương
  Kịch bản: TC-06-001 Liệt kê, lọc và xem chi tiết domain
    # Truy vết: FR-06-001 · API-06-001, 002 · UI-06-07 · PERM-06-read
    # Mục đích: Chứng minh danh sách domain có phân trang, lọc theo trạng thái và chi tiết đủ thuộc tính, khóa, phiên bản, theo FR-06-001.
    Biết T90 có CITIZEN, ORGANIZATION `ACTIVE`, ADDRESS `DRAFT`; U-T90-VW.
    Khi `GET /domains?page=0&size=2&status=ACTIVE`.
    Và `GET /domains/CITIZEN`.
    Và VW gọi `GET /domains/CITIZEN` rồi so với `GET /domains/CITIZEN` của DS1.
    Thì bước 1 `200`, 2 phần tử, `totalElements = 2`, ADDRESS không có. Bước 2 có `status`, `activeVersion`, danh sách thuộc tính với `AttributeType`, `dataClass`, khóa `CCCD_12`. Bước 3 hai thân giống nhau; `ETag` có mặt.
    # Hậu điều kiện: Không đổi dữ liệu.

  @TC-06-002 @P1 @Dương
  Kịch bản: TC-06-002 Cài gói domain nền vào tenant mới
    # Truy vết: FR-06-007 · API-06-012 · UI-06-07 · BR-06-016 · PERM-06-config
    # Mục đích: Chứng minh gói nền tạo CITIZEN, ORGANIZATION, ADDRESS với thuộc tính, khóa, phân loại đề xuất, theo FR-06-007.
    Biết T93 chưa có domain; U-PA, PH-09 giả lập `PROPOSED`.
    Khi PA `POST /domains:install-baseline` cho T93.
    Và `GET /domains` và chi tiết CITIZEN.
    Thì bước 1 `201`, ba domain `DRAFT` phiên bản 1. CITIZEN có khóa `CCCD_12` `deterministic = true`, ORGANIZATION có `MST_10_13`, ADDRESS có `DVHC_CODE`. Thuộc tính DLCN (họ tên, ngày sinh, CCCD) `ClassificationStatus = PROPOSED`, `dataClass = SENSITIVE` cho số định danh. KT: có (install-baseline).
    # Hậu điều kiện: T93 có ba domain DRAFT, chưa kích hoạt được tới khi PH-09 xác nhận phân loại.

  @TC-06-003 @P2 @Âm
  Kịch bản: TC-06-003 Cài gói nền lần hai, thiếu quyền, tenant đã tùy chỉnh
    # Truy vết: FR-06-007 · API-06-012 · ERR-06-002, 006 · PERM-06-config
    # Mục đích: Chứng minh gói nền không ghi đè domain đã có và chỉ PA, TA được cài, theo FR-06-007.
    Biết T93 sau ca baseline-install; T90 đã sửa thuộc tính CITIZEN.
    Khi TA gọi lại `POST /domains:install-baseline` ở T93.
    Và DS1 gọi `POST /domains:install-baseline`.
    Và TA gọi ở T90 khi CITIZEN đã có phiên bản 2 do tỉnh sửa.
    Thì bước 1 `409` ERR-06-002, không tạo thêm. Bước 2 ERR-00-403. Bước 3 không ghi đè phiên bản 2, các domain thiếu mới được bổ sung, phản hồi liệt kê "đã có, bỏ qua".
    # Hậu điều kiện: Không domain nào bị đổi ngoài domain thiếu.
