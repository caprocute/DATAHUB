# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-08
Tính năng: TS-10-08 · Bên phát và bên nhận

  @TC-10-037 @P1 @Dương
  Kịch bản: TC-10-037 Đăng ký bên phát HTTT và bên nhận là luồng
    # Truy vết: FR-10-026, 027 · API-10-033, 038 · UI-10-09, 10 · UC-10-07 · BR-10-017 · LGC-HUB-010, 011
    Biết U-T68-IE1; SIM-PH01 có `HT-QLDD` `ACTIVE`; SIM-PH04 có luồng `dkkd-tong-hop`.
    Khi `POST /publishers` với `publisherCode = tc-ht-qldd`, `partyType = SYSTEM`, `systemCode = HT-QLDD`, `commType = HTTP_PUBLISH`, `referenceKey = PUB_QLDD_01`.
    Và `POST /subscribers` với `subscriberCode = tc-luong-tong-hop`, `partyType = FLOW`, `flowCode = dkkd-tong-hop`, `commType = INTERNAL_KAFKA`.
    Và mở UI-10-10.
    Thì bước 1 `201`, `status = ACTIVE`, `clientId` lấy từ PH-01, chưa có publication. Bước 2 `201`, `isFlow = true`, `kafkaPrincipal` là principal nội bộ của tenant. Bước 3 cột "Loại" của dòng mới hiện "Luồng tích hợp". KT: có.

  @TC-10-038 @P1 @Âm
  Kịch bản: TC-10-038 Tổ hợp không hợp lệ, HTTT không hoạt động, luồng ngừng, DU lạ, trùng cặp
    # Truy vết: FR-10-026, 027 · API-10-033, 038 · ERR-10-002, 003, 021, 022, 023, 024, 028, 044 · BR-10-017
    Biết U-T68-IE1, U-T68-SV; U-T01-IE (T01 tắt Kafka ngoài).
    Khi bên phát `SYSTEM` với `commType = WEBHOOK_PUSH`; bên nhận `FLOW` với `commType = HTTP_PULL`; bên phát `LEGACY_BRIDGE`.
    Và `systemCode = HT-DUNG` (`SUSPENDED`).
    Và `flowCode = luong-cu` (`RETIRED`); `serviceCode = dh-khong-co`.
    Và bên phát thứ hai cho cặp (`HT-DKKD`, `HTTP_PUBLISH`).
    Và U-T01-IE đăng ký bên phát `KAFKA_NATIVE`.
    Và U-T68-SV đăng ký bên phát cho HTTT của `SO-TC`.
    Thì bước 1 `400` ERR-10-003. Bước 2 `422` ERR-10-021. Bước 3 `422` ERR-10-022, ERR-10-023. Bước 4 `409` ERR-10-024. Bước 5 `422` ERR-10-028. Bước 6 403-TC. KT: không.

  @TC-10-039 @P2 @Dương
  Kịch bản: TC-10-039 Danh sách và chi tiết bên tham gia
    # Truy vết: FR-10-025 · API-10-032, 034, 037, 039 · UI-10-09, 10 · LGC-HUB-010, 011
    Biết U-T68-VW; dữ liệu mục 2.3.
    Khi `GET /publishers?q=PUB_DKKD&partyType=SYSTEM`.
    Và `GET /subscribers?projectCode=dang-ky-kinh-doanh&status=ACTIVE`.
    Và `GET /subscribers/ht-thue`.
    Thì bước 1 tìm theo `referenceKey` ra `ht-dkkd`. Bước 2 có `ht-thue`, `ht-bhxh`, `ht-kho-bac`, `luong-dong-bo-thue` với số subscription theo trạng thái. Bước 3 có trạng thái HTTT ở PH-01, `commType`, `lastActiveAt`.

  @TC-10-040 @P1 @Dương
  Kịch bản: TC-10-040 Sửa, tạm ngừng, tiếp tục, ngừng dùng bên phát
    # Truy vết: FR-10-028 · API-10-035, 036, 092, 093 · EVT-10-07 · UC-10-08 · NFR-10-009 · LGC-HUB-010
    Biết U-T68-IE1, U-T68-SO; PB-DKKD có publication `ACTIVE`.
    Khi IE1 `PATCH /publishers/ht-dkkd` đổi `name`, `referenceKey`.
    Và SO `:suspend` với lý do "Nghi lộ khóa client"; HTTT phát ngay sau đó.
    Và SO `:resume`.
    Và bên phát thử không còn quan hệ: IE1 `:retire`.
    Thì bước 1 `200`. Bước 2 bên phát `SUSPENDED` với `suspendSource = SECURITY`, publication `SUSPENDED`; lượt phát bị từ chối 403-PQ trong ≤ 60 giây; EVT: `publication.state-changed`. Bước 3 về `ACTIVE`, publication `ACTIVE` không cần duyệt lại. Bước 4 `RETIRED`, mã không dùng lại được (ERR-10-002 khi tạo lại). KT: có cho cả bốn bước.

  @TC-10-041 @P2 @Âm
  Kịch bản: TC-10-041 Đổi trường bất biến; SO tiếp tục bên do người khác tạm ngừng; trạng thái sai
    # Truy vết: FR-10-028 · API-10-035, 036, 094, 095 · ERR-10-003, 006, 009
    Biết U-T68-IE1, U-T68-SO, U-T68-TO; SB-THUE.
    Khi `PATCH /subscribers/ht-thue` đổi `partyType`, `systemCode`, `commType`.
    Và TO `:suspend` SB-THUE; SO gọi `:resume`.
    Và `:resume` bên nhận đang `ACTIVE`; `:suspend` không lý do.
    Thì bước 1 `400` ERR-10-003 cho cả ba trường. Bước 2 SO nhận 403-PQ (SO chỉ tiếp tục đối tượng `suspendSource = SECURITY`). Bước 3 `409` ERR-10-006; `400` ERR-10-009.
