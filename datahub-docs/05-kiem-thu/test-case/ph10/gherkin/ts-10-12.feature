# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-12
Tính năng: TS-10-12 · Phát trực tiếp qua Kafka và giám sát tuân thủ

  @TC-10-053 @P1 @Dương
  Kịch bản: TC-10-053 Bên phát Kafka ngoài ghi đúng chuẩn qua SASL OAUTHBEARER
    # Truy vết: FR-10-034 · BR-10-008 · LGC-TOOL-010
    # Mục đích: Chứng minh luồng thành công, theo FR-10-034 (Phát sự kiện trực tiếp qua Kafka).
    Biết PB-DKKD-K có publication trên TP-GT; client Java `acks=all`, `enable.idempotence=true`, serde Apicurio `auto.register=false`, token Keycloak `client_credentials`.
    Khi kết nối listener `external` cổng 9093 với `sasl.mechanism=OAUTHBEARER`; gửi 1.000 bản tin có tiêu đề `ce_*`.
    Và đọc lại bằng consumer của SUB-KAFKA.
    Thì ghi thành công; principal theo `azp`; bản tin có tiền tố lược đồ hợp lệ; giám sát tuân thủ không ghi vi phạm.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-054 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-054 Ghi ngoài ACL, ghi topic khác, bản tin không có định danh lược đồ
    # Truy vết: FR-10-034, 023 · ERR-10-119, 120 · EVT-10-14 · BR-10-008
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-034 (Phát sự kiện trực tiếp qua Kafka).
    Biết PB-DKKD-K; `10.compliance.sample-ratio = 1` ở SIT, ngưỡng 10.
    Khi ghi lên TP-CP (không có publication cho PB-DKKD-K).
    Và ghi lên `t01.dkkd.doanh-nghiep.da-cap-phep.v1`.
    Và ghi 20 bản tin JSON thô không tiền tố lược đồ lên TP-GT trong 15 phút.
    Thì bước 1, 2 `TopicAuthorizationException`; chỉ số ERR-10-120 theo principal. Bước 3 ghi được (Kafka không kiểm lược đồ) nhưng giám sát ghi 20 vi phạm ERR-10-119, `GET /topics/{TP-GT}/compliance` liệt kê publication vi phạm; EVT: `compliance.violated` một lần khi vượt ngưỡng; PH-18 nhận việc.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi. Giữ dữ liệu cho TC-10-055.

  @TC-10-055 @P2 @Dương
  Kịch bản: TC-10-055 SO tạm ngừng publication vi phạm lược đồ
    # Truy vết: FR-10-023, 032 · API-10-031, 045 · UI-10-06 · UC-10-11
    # Mục đích: Chứng minh luồng thành công, theo FR-10-023 (Giám sát tuân thủ lược đồ của bên phát Kafka trực tiếp).
    Biết U-T68-SO; vi phạm từ TC-10-054.
    Khi mở tab "Tuân thủ" ở UI-10-06; bấm "Tạm ngừng publication" với lý do.
    Thì publication `SUSPENDED` với `suspendSource = SECURITY`; ACL `WRITE` gỡ trong ≤ 2 phút; producer nhận lỗi quyền.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.
