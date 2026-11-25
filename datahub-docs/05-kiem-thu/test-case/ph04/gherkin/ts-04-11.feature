# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-11
Tính năng: TS-04-11 · Kiểm tra hợp lệ VR-01…20

  @TC-04-062 @P1 @Dương
  Kịch bản: TC-04-062 Ma trận mức nghiêm trọng theo mức kiểm tra
    # Truy vết: FR-04-023 · API-04-030
    Biết bộ 20 tệp YAML, mỗi tệp vi phạm đúng một quy tắc VR-01…20 (`src/test/resources/vr/vr-nn.yaml`), cộng YAML-OK.
    Khi chạy `ValidationEngine` trên từng tệp ở ba mức `DESIGN`, `SUBMIT`, `PUBLISH`.
    Thì 60 kết quả khớp đúng bảng FR-04-023 (ví dụ VR-05: `WARN`, `ERROR`, `ERROR`; VR-12: `INFO`, `WARN`, `ERROR`). YAML-OK không có finding nào ở mọi mức. Mỗi finding có `rule`, `severity`, `path`, `nodeId`, `message` tiếng Việt.

  @TC-04-063 @P1 @Âm
  Kịch bản: TC-04-063 Chín chặng chuẩn với luồng đối ngoại và nội bộ
    # Truy vết: FR-04-023, 060 · BR-04-002 · ERR-04-012
    Biết `tc-ngoai` (EXTERNAL) và `tc-noi` (INTERNAL), cùng thiếu chặng `authz` và đảo thứ tự `audit` với `deliver`.
    Khi `:validate` mức `SUBMIT` trên `tc-ngoai`.
    Và như bước 1 trên `tc-noi`.
    Thì bước 1: VR-05 `ERROR`, `args.stages = ["authz"]`, và một finding thứ tự; map sang ERR-04-012. Bước 2: VR-06 `WARN`, không chặn.

  @TC-04-064 @P1 @Âm
  Kịch bản: TC-04-064 Trùng mã route, trùng đường dẫn HTTP
    # Truy vết: FR-04-023 · BR-04-011
    Biết `tc-trung` có route `tra-cuu-ho-tich-main` (trùng F-HT đang chạy) và `path: /ho-tich/tra-cuu`.
    Khi `:validate` mức `DESIGN`.
    Và đổi mã route và đường dẫn, kiểm lại.
    Thì bước 1: VR-08 và VR-18 `ERROR` ngay ở `DESIGN`. Bước 2: không còn finding. Đường dẫn trùng F-T01 ở T01 không bị báo (khác tenant).

  @TC-04-065 @P1 @Âm
  Kịch bản: TC-04-065 Topic chưa đăng ký hoặc không có quyền
    # Truy vết: FR-04-023, 069 · BR-04-009
    Biết `tc-topic` gửi tới `t68.chua-dang-ky.v1`, TOPIC-NOACL, TOPIC-T01.
    Khi `:validate` mức `SUBMIT`.
    Thì ba finding VR-10 `ERROR`. Với TOPIC-T01 thông điệp là "Không được dùng topic của tỉnh khác".

  @TC-04-066 @P1 @Âm
  Kịch bản: TC-04-066 Thiếu xử lý lỗi và DLQ
    # Truy vết: FR-04-023, 070 · BR-04-008
    Biết `tc-loi` bỏ `routeConfigurationId`, không có `errorHandler`.
    Khi `:validate` mức `SUBMIT`.
    Và thêm `errorHandler: deadLetterChannel` tới `kafka:t68.ops.dlq.v1`, kiểm lại.
    Thì bước 1: VR-11 `ERROR`. Bước 2: không còn finding.

  @TC-04-067 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-067 Đặt tiêu đề tenant sai chỗ
    # Truy vết: FR-04-023, 073 · BR-04-010
    Biết `tc-ten` có `setHeader: name: dh-tenant, simple: ${header.X-Tenant}` ở chặng `transform`.
    Khi `:validate` mức `DESIGN`, `SUBMIT`.
    Thì VR-14 `WARN`, `ERROR`. Thông điệp "Không được đặt tiêu đề dh-tenant; tenant do chặng Tiếp nhận đặt".

  @TC-04-068 @P1 @Âm @Bảo @mật
  Kịch bản: TC-04-068 Thành phần nguy hiểm và chỉ chạy JVM
    # Truy vết: FR-04-023, 075 · BR-04-014 · ERR-04-011, 029
    Biết `tc-nguy` dùng `exec:`, `file:/etc`, `cxf` (chỉ JVM) khi T68 không được phép hồ sơ `legacy-jvm` nhưng được `soap-jvm`.
    Khi `:validate` mức `PUBLISH` với `targetEnvironment = TEST`.
    Thì VR-19 `ERROR` cho `exec`, `file`; VR-12 không báo lỗi cho `cxf` vì có hồ sơ `soap-jvm` hợp lệ; nếu bỏ quyền `soap-jvm` thì VR-12 `ERROR` và ERR-04-029.

  @TC-04-069 @P2 @Âm
  Kịch bản: TC-04-069 HTTT đích chưa kết nạp và catalog cũ
    # Truy vết: FR-04-023, 068, 081 · BR-04-020 · ERR-04-043, 042
    Biết `tc-dich` có `targetSystems = ["HT-CHUA-KET-NAP"]` (không có ở bản sao PH-01); `definition.catalogVersion` thấp hơn catalog hiện hành.
    Khi `:validate` mức `SUBMIT`.
    Và `:submit`.
    Thì bước 1: finding với ERR-04-043 và VR-17 `ERROR`. Bước 2 trả `409` ERR-04-042 (kiểm catalog trước khi chạy đủ quy tắc, theo thứ tự ở D03-04-PH04 §3 ghi chú 3).

  @TC-04-070 @P2 @Dương
  Kịch bản: TC-04-070 Kiểm tra trình duyệt và máy chủ cho cùng kết quả
    # Truy vết: FR-04-023 · NFR-04-007
    Biết bộ tệp `vr-nn.yaml` của các quy tắc VR-01…09, 15, 18, 20 (phần chạy được ở trình duyệt).
    Khi chạy bộ quy tắc trình duyệt (Vitest) và máy chủ (JUnit) trên cùng tệp, so sánh `rule`, `severity`, `path`.
    Thì kết quả trùng khớp 100%. Thời gian máy chủ mức `SUBMIT` cho YAML-200 p95 < 2 giây (NFR-04-007).
