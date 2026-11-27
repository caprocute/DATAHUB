# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-18
Tính năng: TS-04-18 · Lệnh runtime có ký: tạm dừng, tiếp tục, dừng khẩn, đối soát

  @TC-04-108 @P1 @Dương
  Kịch bản: TC-04-108 Tạm dừng một route ở PROD
    # Truy vết: FR-04-050 · API-04-061 · UC-04-14 · EVT-04-08, 11, 13 · ERR-04-110 · NFR-04-010 · LGC-BUS-009.
    Biết F-HT v4 chạy PROD, 2 bản sao; U-T68-TO.
    Khi gọi `POST /flows/tra-cuu-ho-tich/runtime/commands` với `{"environment":"PROD","action":"PAUSE","scope":"ROUTES","routeIds":["tra-cuu-ho-tich-main"],"reason":"Bảo trì HTTT hộ tịch 22:00–23:00","drain":true}`.
    Và theo dõi `GET .../commands/{id}`.
    Và gọi luồng qua APISIX.
    Thì bước 1 trả `202`, `status = ISSUED`, `expiresAt = issuedAt + 60 giây`. EVT-04-11 có `signature`, `keyId`. Bước 2: hai `acks` `APPLIED`, `status = ACKNOWLEDGED` trong p95 < 10 giây. Bước 3 trả `503` ERR-04-110. EVT-04-08 phát. Trong vòng 5 phút `desiredState` của route được ghi vào Git (`flow.dh.yaml`), lệnh `RECONCILED`. KT: có (`INT_FLOW_PAUSE` có lý do).

  @TC-04-109 @P1 @Dương
  Kịch bản: TC-04-109 Tiếp tục route
    # Truy vết: FR-04-050 · API-04-061 · LGC-BUS-012.
    Biết route đã tạm dừng ở ca trên.
    Khi TO gửi `RESUME` cùng phạm vi.
    Và gọi luồng.
    Thì `ACKNOWLEDGED`; gọi luồng trả `200`. Bảng route bỏ nhãn "Tạm dừng bởi…".

  @TC-04-110 @P1 @Dương
  Kịch bản: TC-04-110 Dừng khẩn đi trước Git
    # Truy vết: FR-04-050 · BR-04-018 · API-04-061 · UC-04-15 · NFR-04-010.
    Biết F-HT PROD; U-T68-SO; Gitea bị làm chậm 30 giây mỗi lệnh đẩy.
    Khi SO gửi `EMERGENCY_STOP`, `scope = FLOW`, `drain = false`, `incidentRef = "SC-2026-001"`.
    Và đo thời gian tới khi cả hai bản sao xác nhận.
    Và chờ đối soát.
    Thì bước 2: < 5 giây, không phụ thuộc độ chậm của Git. Bản sao đặt `localOverride = true` trong nhịp tim. Bước 3: tiến trình `system:int-reconciler` ghi trạng thái `PAUSED` vào Git trong ≤ 5 phút; khi Git khớp, bản sao bỏ `localOverride`. Argo CD đồng bộ trong lúc đó không bật lại luồng. KT: có (`INT_FLOW_EMERGENCY_STOP`, người thực hiện SO và `system:int-reconciler` cho lần ghi Git).

  @TC-04-111 @P1 @Dương
  Kịch bản: TC-04-111 Đối soát hoàn tất
    # Truy vết: FR-04-050 · BR-04-018.
    Biết lệnh `ACKNOWLEDGED` từ ca tạm dừng.
    Khi đọc `GET .../commands/{id}` sau 5 phút.
    Và đọc `flow.dh.yaml` trên `env/prod`.
    Thì `status = RECONCILED`, `reconciledAt` ≤ `issuedAt + 5 phút`. Tệp có trạng thái mong muốn của route khớp runtime.

  @TC-04-112 @P1 @Âm @Khả @dụng
  Kịch bản: TC-04-112 Một bản sao không xác nhận, gửi lại
    # Truy vết: FR-04-050 · API-04-061, 107, 108 · ERR-04-024.
    Biết chaos Mesh cắt mạng Kafka của bản sao thứ hai.
    Khi TO gửi `PAUSE`.
    Và sau 30 giây đọc lệnh.
    Và khôi phục mạng, gọi `:resend`.
    Thì bước 2: `status = PARTIAL`, `ackedReplicas = 1/2`, giao diện liệt kê bản sao chưa xác nhận và nút "Gửi lại lệnh". Bước 3: lệnh mới có `resendOf` = lệnh cũ, chữ ký mới, hạn mới; sau khi đủ xác nhận, lệnh gốc `ACKNOWLEDGED`.

  @TC-04-113 @P1 @Bảo @mật
  Kịch bản: TC-04-113 Lệnh có chữ ký sai
    # Truy vết: FR-04-050 · EVT-04-11, 13 · ERR-04-024.
    Biết client Kafka thử có quyền ghi `dh.integration.runtime.command.v1` (giả định kẻ tấn công vượt được ACL).
    Khi gửi lệnh `EMERGENCY_STOP` với chữ ký Ed25519 sai.
    Và gửi lệnh đúng chữ ký nhưng sửa `flowCode` sau khi ký.
    Thì runtime không thực thi; gửi ack `REJECTED`, `reason = BAD_SIGNATURE`; luồng vẫn chạy; cảnh báo an ninh mức cao ở PH-13.

  @TC-04-114 @P1 @Bảo @mật
  Kịch bản: TC-04-114 Lệnh hết hạn và lệnh phát lại
    # Truy vết: FR-04-050 · EVT-04-11, 13.
    Biết một lệnh hợp lệ đã thực thi lúc T; bản ghi Kafka của nó.
    Khi phát lại bản tin lệnh đó lúc T + 90 giây.
    Và phát lại lúc T + 20 giây.
    Thì bước 1: `REJECTED`, `reason = EXPIRED`. Bước 2: `REJECTED`, `reason = DUPLICATE` (đã xử lý `commandId`). Không có thay đổi trạng thái route.

  @TC-04-115 @P1 @Bảo @mật
  Kịch bản: TC-04-115 Lệnh mang tenant khác hoặc luồng không tồn tại
    # Truy vết: FR-04-050, 073 · EVT-04-13.
    Biết lệnh ký đúng khóa nhưng `tenantId = T01` gửi tới runtime namespace `dh-rt-t68`; lệnh cho `flowCode = khong-co`.
    Khi gửi hai lệnh.
    Thì lần lượt `REJECTED` với `TENANT_MISMATCH`, `UNKNOWN_FLOW`. Runtime T68 không thay đổi.

  @TC-04-116 @P1 @Âm
  Kịch bản: TC-04-116 Lệnh thiếu lý do, sai quyền, môi trường chưa triển khai
    # Truy vết: FR-04-050 · BR-04-017 · API-04-061 · ERR-04-025, 023, 045.
    Biết F-SQL chỉ chạy TEST; TO (không có `PERM-04-emergency-stop`); IE1.
    Khi TO `PAUSE` F-HT với `reason = "bảo trì"`.
    Và TO `PAUSE` F-SQL ở PROD.
    Và TO `EMERGENCY_STOP` F-HT.
    Và IE1 `PAUSE` F-HT.
    Thì lần lượt `400` ERR-04-025, `409` ERR-04-023, 403-PQ, 403-PQ. EVT: không.

  @TC-04-117 @P2 @Âm
  Kịch bản: TC-04-117 Tiếp tục sau dừng khẩn chỉ SO hoặc TA
    # Truy vết: FR-04-050 · UC-04-15.
    Biết F-HT đang dừng khẩn.
    Khi TO gửi `RESUME`.
    Và TA gửi `RESUME`.
    Thì bước 1 trả 403-PQ với `detail` "Luồng đang dừng khẩn; chỉ cán bộ ATTT hoặc quản trị tenant tiếp tục được" (Q04-47). Bước 2 trả `202`.

  @TC-04-197 @P1 @Dương
  Kịch bản: TC-04-197 Đầu cuối dừng khẩn ở PROD theo trình tự SDD
    # Truy vết: FR-04-050 · BR-04-018 · UC-04-15 · API-04-061 · EVT-04-08, 11, 13 · NFR-04-010.
    Biết U-T68-SO; F-HT PROD hai bản sao, đang có 20 bản tin xử lý dở (WireMock CONN-HT trả chậm 5 giây); theo dõi OpenBao transit, Kafka, `runtime_command`, DLQ PH-18 (D03-02-PH04 §10.2, hình dừng khẩn).
    Khi SO gửi `POST /flows/tra-cuu-ho-tich/runtime/commands` với `{"type":"EMERGENCY_STOP","scope":"FLOW","reason":"Nghi lộ dữ liệu","incidentRef":"SC-2026-002"}`.
    Và đối chiếu thứ tự: lời gọi `transit/sign`, bản tin EVT-04-11, dòng `runtime_command`.
    Và đọc EVT-04-13 của từng bản sao và trạng thái lệnh.
    Và đọc DLQ.
    Và chờ đối soát, đọc `flow.dh.yaml` ở `env/prod`.
    Thì bước 1 trả `202` có `commandId`. Bước 2: chữ ký tính trên dạng JCS của lệnh; EVT-04-11 gửi với `acks=all` trước khi ghi `runtime_command` `ISSUED` và trước mọi lần ghi Git. Bước 3: mỗi bản sao kiểm chữ ký, hạn, tenant rồi xác nhận `APPLIED`; lệnh `ACKNOWLEDGED` trong < 5 giây. Bước 4: bản tin dở vào DLQ với lý do "dừng khẩn". Bước 5: tác vụ nền ghi `desiredState: PAUSED`, Argo CD áp, nhịp tim khớp; lệnh `RECONCILED`, phát EVT-04-08. KT: có (`INT_FLOW_EMERGENCY_STOP`).
