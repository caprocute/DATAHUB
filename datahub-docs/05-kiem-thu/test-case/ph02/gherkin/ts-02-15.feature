# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-15
Tính năng: TS-02-15 · Mức hiển thị và chuyển chủ quản

  @TC-02-051 @P1 @Dương @Âm
  Kịch bản: TC-02-051 Đặt mức hiển thị `NATIONAL` cần CA duyệt; `PUBLIC` với dữ liệu không công khai bị chặn
    # Truy vết: FR-02-041 · API-02-053 · UI-02-02 · UC-02-21 · BR-02-037, 008, 009 · ERR-02-043, 014 · EVT-02-02 · LGC-APIM-006.
    Biết A-DATDAI `INTERNAL`; U-T68-SV1, U-T68-CA.
    Khi đặt `PUBLIC`; đặt `NATIONAL` bằng SV1; CA duyệt.
    Và gỡ khỏi cổng nhà phát triển.
    Thì `PUBLIC` `422` ERR-02-043; `NATIONAL` chờ CA, sau duyệt thành công và vào hàng đồng bộ quốc gia; gỡ cổng có thông báo bắt buộc.

  @TC-02-052 @P2 @Dương @Âm
  Kịch bản: TC-02-052 Chuyển chủ quản API chỉ TA, kiểm tra đơn vị đích
    # Truy vết: FR-02-045 · API-02-057 · BR-02-032 · ERR-02-004, 014 · KT: có (api.transfer-owner).
    Biết U-T68-TA, U-T68-SV1; đơn vị đích `ACTIVE`; đơn vị không tồn tại.
    Khi U-T68-SV1 `PUT /apis/tc-dat-dai/owner`.
    Và U-T68-TA chuyển sang đơn vị không tồn tại, rồi sang đơn vị hợp lệ.
    Thì 403-PQ; `422` ERR-02-004; thành công, SV2 của chủ mới sửa được.

  @TC-02-121 @P1 @Dương
  Kịch bản: TC-02-121 Hạ mức hiển thị: gỡ khỏi cổng, thông báo bắt buộc, đồng bộ quốc gia
    # Truy vết: FR-02-041, 054 · API-02-053, 069 · UI-02-02, 12 · UC-02-21 · BR-02-009, 029, 037 · ERR-02-041.
    Biết A-DATDAI `NATIONAL`, có SUB-ACTIVE, đã đồng bộ lên Nền tảng quốc gia (M-NSP); U-T68-SV1, U-T68-CA.
    Khi SV `PUT /apis/tc-dat-dai/visibility` hạ về `ORG`, không lý do; rồi có lý do.
    Và quan sát danh mục cho máy, cổng nhà phát triển, hàng đợi thông báo, bản ghi đồng bộ.
    Thì bước 1: `400` ERR-02-041, rồi `200` (hạ mức không cần CA duyệt). Bước 2: API biến mất khỏi danh mục `NATIONAL` và `removed[]` ghi nhận; bên đăng ký nhận thông báo bắt buộc không tắt được; bản ghi đồng bộ có hành động gỡ; chỉ báo quá hạn đồng bộ tắt.
