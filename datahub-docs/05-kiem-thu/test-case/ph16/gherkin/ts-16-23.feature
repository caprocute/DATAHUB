# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-23
Tính năng: TS-16-23 · Tìm, xem và xuất sổ kiến trúc

  @TC-16-081 @P1 @Dương @Âm
  Kịch bản: TC-16-081 Liệt kê, tìm, lọc, xem chi tiết thành phần; bộ lọc sai, tenant khác
    # Truy vết: FR-16-043 · API-16-094, 096 · UI-16-14, UI-16-15 · ERR-16-057, ERR-16-001
    Biết T90, F-KT (40 thành phần); U-T90-VW.
    Khi `GET /arch/components?page=0&size=20`
    Và `GET /arch/components?componentType=API&lifecycle=ACTIVE&complianceLevel=NOT_ASSESSED`
    Và `GET /arch/components?opsStatus=DOWN&origin=AUTO&q=hotich`
    Và `GET /arch/components/httt-hotich`
    Và `GET /arch/components?componentType=LOAI-LA`
    Và U-T90-VW `GET /arch/components/httt-chi-t91` (chỉ có ở T91)
    Thì bước 1 `totalElements = 40`, `facets` theo loại, vòng đời, tuân thủ. Bước 2, 3 chỉ phần tử khớp. Bước 4 có `componentType`, `lifecycle`, `opsStatus`, `origin`, `complianceLevel`, `versions[]`, `dependencies[]`, `ownerOrgName`, `sourceRef`. Bước 5 `400` ERR-16-057. Bước 6 `404` ERR-16-001 (404-ẩn).

  @TC-16-082 @P3 @Dương
  Kịch bản: TC-16-082 Xuất sổ kiến trúc và sơ đồ phụ thuộc
    # Truy vết: FR-16-049 · API-16-079, 080, 081 · UI-16-15 · BR-16-026
    Biết T90, F-KT; U-T90-TO1.
    Khi `POST /exports` `{subject: ARCH_REGISTRY, subjectRef: {filter: {componentType: API}}, format: CSV}`
    Và `POST /exports` `{subject: ARCH_GRAPH, subjectRef: {rootComponent: httt-hotich, depth: 2}, format: JSON}`
    Và `POST /exports` `{subject: ARCH_GRAPH, subjectRef: {rootComponent: httt-hotich, depth: 6}, format: JSON}`
    Thì bước 1, 2 `202`, kết thúc `SUCCEEDED`; CSV đủ cột, JSON có nút và cạnh đến độ sâu 2. Bước 3 `400` ERR-16-003 (`depth` tối đa 5) hoặc `422` ERR-16-034 khi vượt giới hạn dữ liệu.
