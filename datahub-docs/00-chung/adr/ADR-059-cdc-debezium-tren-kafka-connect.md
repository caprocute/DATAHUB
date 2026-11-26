---
ma_tai_lieu: ADR-059
ten: CDC cho HTTT di sản bằng Debezium chạy trên Kafka Connect (Strimzi), PH-05 quản lý connector qua GitOps
phien_ban: 0.1
ngay: 2026-11-26
trang_thai: Đề xuất
nguoi_doc: Kiến trúc sư, đội dh-integration, đội vận hành nền tảng, PH-05, PH-10
---

# ADR-059 · CDC bằng Debezium trên Kafka Connect

## Bối cảnh

HTTT nhóm 3 (không API, không còn nhà thầu) chỉ đưa được dữ liệu lên trục bằng cách đọc nhật ký giao dịch của CSDL (D02-03-PH05 §2.2, FR-05-048…053). Repo cũ chọn Debezium (ADR-005 của `docs/05-adr`) nhưng chưa định nơi chạy. Datahub dùng Kafka (ADR-004), Camel Quarkus cho data plane (ADR-002) và GitOps với Argo CD (ADR-009). Debezium cần lưu vị trí đọc bền vững, lịch sử lược đồ, chạy một tác vụ duy nhất cho mỗi CSDL nguồn và hỗ trợ PostgreSQL, MySQL, Oracle, SQL Server.

## Các phương án

| Phương án | Ưu điểm | Nhược điểm |
|---|---|---|
| A. Debezium nhúng trong `dh-runtime` qua `camel-debezium-*` | Một runtime, chung cách đóng gói luồng | Offset, lịch sử lược đồ phải tự lưu; cần bầu chọn một bản sao chạy; Oracle connector chưa chắc biên dịch native; tải CDC lẫn với tải luồng |
| B. **Debezium trên Kafka Connect do Strimzi quản lý** | Offset, lịch sử lược đồ ở topic Kafka; phân phối và khởi động lại tác vụ sẵn có; connector khai báo bằng CRD `KafkaConnector` nên đi được GitOps; tách tải | Thêm một thành phần vận hành (cụm Kafka Connect); ảnh Kafka Connect phải đóng gói plugin Debezium và driver đã duyệt |
| C. Debezium Server độc lập | Nhẹ | Mỗi nguồn một tiến trình, quản lý vòng đời và cấu hình rời rạc, không có CRD |

## Quyết định

Chọn **phương án B**. Mỗi tenant có một cụm Kafka Connect riêng (namespace của tenant ở Z4, D03-09) với ảnh dựng sẵn chứa Debezium 3.x cho PostgreSQL, MySQL, Oracle (LogMiner), SQL Server và driver JDBC đã qua quét chuỗi cung ứng. PH-05 sinh đặc tả `KafkaConnector` từ cấu hình CDC (FR-05-048) vào kho GitOps của tenant (ADR-068); Argo CD áp dụng. Bí mật CSDL nguồn được Strimzi đọc từ OpenBao qua External Secrets, không nằm trong kho Git. Topic dữ liệu do PH-10 đăng ký, tên `{tenant}.cdc.{adapterCode}.{schema}.{table}.v1`, lược đồ Avro ở Apicurio. `dh-integration` theo dõi trạng thái connector qua REST API của Kafka Connect và topic lịch sử lược đồ để phát hiện thay đổi phá vỡ, rồi tạm dừng connector (`PAUSED_SCHEMA`).

## Hệ quả

- D03-09 phải bổ sung cụm Kafka Connect vào sơ đồ triển khai và định cỡ (đề nghị đồng bộ ở D03-02-PH05).
- CDC không bị ảnh hưởng khi `dh-runtime` nâng phiên bản; ngược lại nâng Debezium là một bản phát hành riêng có kiểm thử ở D05-02-PH05.
- Luồng PH-04 tiêu thụ CDC như mọi topic Kafka, qua Kamelet `dh-kafka-source` của PH-10.

## Truy vết

FR-05-048…053; BR-05-022; NFR-05-009, 010; ADR-004, ADR-009, ADR-068.
