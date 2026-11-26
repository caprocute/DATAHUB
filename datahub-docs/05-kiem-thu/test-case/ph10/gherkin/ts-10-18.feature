# language: vi
# Sinh tự động từ D05-02-PH10 bằng ph10/tools/gen_gherkin.py; không sửa tay.
@PH-10 @TS-10-18
Tính năng: TS-10-18 · Giao nhận KÉO qua Kafka ngoài: SASL OAUTHBEARER

  @TC-10-082 @P1 @Dương
  Kịch bản: TC-10-082 Consumer ngoài đọc bằng token Keycloak và nhóm được cấp
    # Truy vết: FR-10-044, 037 · BR-10-035 · LGC-TOOL-010
    # Mục đích: Chứng minh luồng thành công, theo FR-10-044 (Giao nhận KÉO qua Kafka listener ngoài).
    Biết SUB-KAFKA `ACTIVE`; client C-KBNN; consumer Java `sasl.mechanism=OAUTHBEARER`, serde Apicurio đọc lược đồ qua API-10-084.
    Khi kết nối cổng 9093, `group.id = dh-ext-t68-ht-kho-bac-dn-cap-phep`; đọc 500 sự kiện; tự commit.
    Và đọc `GET /subscriptions/ht-kho-bac-dn-cap-phep/lag`.
    Thì đọc được, giải tuần tự được; lag về 0 sau commit; principal là `User:{clientId}` theo `azp`.
    # Hậu điều kiện: Đối tượng ở trạng thái nêu ở kết quả mong đợi.

  @TC-10-083 @P1 @Âm @Bảo @mật
  Kịch bản: TC-10-083 Nhóm khác tên, topic không subscription, tenant chưa bật, token giả
    # Truy vết: FR-10-044, 064 · ERR-10-028, 120 · BR-10-035
    # Mục đích: Chứng minh mỗi tình huống nêu ở tên ca bị từ chối đúng mã lỗi, theo FR-10-044 (Giao nhận KÉO qua Kafka listener ngoài).
    Biết C-KBNN; C-KBNN-T01 ở T01 (Kafka ngoài tắt).
    Khi C-KBNN dùng `group.id = nhom-tu-dat`.
    Và C-KBNN đọc TP-GT; đọc `t01.dkkd.doanh-nghiep.da-cap-phep.v1`.
    Và C-KBNN-T01 kết nối listener `external`.
    Và dùng token ký bằng khóa tự sinh.
    Thì bước 1 `GroupAuthorizationException`. Bước 2 `TopicAuthorizationException`; chỉ số ERR-10-120 theo principal. Bước 3 bị từ chối (không có `KafkaUser` ngoài cho T01; đề nghị subscription `PULL_KAFKA` ở T01 trả ERR-10-028). Bước 4 xác thực thất bại.
    # Hậu điều kiện: Dữ liệu không đổi ngoài điều nêu ở kết quả mong đợi.

  @TC-10-084 @P3 @Dương @Âm
  Kịch bản: TC-10-084 Bên nhận Kafka ngoài báo bản tin lỗi vào DLQ
    # Truy vết: FR-10-044, 049 · API-10-083 · ERR-10-106, 110
    # Mục đích: Chứng minh luồng thành công và các nhánh bị chặn nêu ở tên ca, theo FR-10-044 (Giao nhận KÉO qua Kafka listener ngoài).
    Biết C-KBNN; SUB-KAFKA.
    Khi `POST /event/v1/subscriptions/ht-kho-bac-dn-cap-phep/dead-letters` với phân vùng, offset, mã lỗi của 2 bản tin.
    Và gửi báo cáo 2 MiB; gửi khi SUB-KAFKA `PAUSED`.
    Thì bước 1 `202`, 2 mục DLQ `origin = EXTERNAL_REPORT`. Bước 2 `413` ERR-10-106; `409` ERR-10-110.
    # Hậu điều kiện: Chỉ bước thành công để lại thay đổi; bước bị từ chối không đổi dữ liệu.
