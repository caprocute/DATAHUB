# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-28
Tính năng: TS-04-28 · Sự kiện, outbox và hợp đồng API

  @TC-04-156 @P1 @Dương @Âm
  Kịch bản: TC-04-156 Outbox ghi cùng giao dịch, không phát khi lỗi
    # Truy vết: EVT-04-01, 03, 04, 06
    Biết testcontainers PostgreSQL, Kafka, Debezium.
    Khi tạo luồng; kiểm `ph04.outbox` và topic.
    Và gây lỗi sau khi ghi `flow` nhưng trước khi commit (tiêm lỗi ở `FlowService`).
    Thì bước 1: một dòng outbox, một bản tin CloudEvents trên `t68.integration.flow.created.v1` với tiêu đề `ce_id`, `ce_type`, `ce_source = /tenants/T68/integration`, khóa `T68:{flowId}`. Bước 2: không có dòng luồng, không có dòng outbox, không có bản tin.

  @TC-04-157 @P2 @Dương
  Kịch bản: TC-04-157 Lược đồ mọi sự kiện khớp AsyncAPI
    # Truy vết: EVT-04-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14
    Biết chạy đầy đủ một vòng tạo, sửa, gửi, yêu cầu sửa, duyệt, phát hành, tạm dừng, chạy thử, gỡ.
    Khi thu mọi bản tin trên 14 topic, kiểm bằng lược đồ trong `asyncapi-integration.yaml`.
    Thì 100% bản tin hợp lệ; không bản tin nào chứa `definitionYaml`, `samples` hay thân bản tin nghiệp vụ.

  @TC-04-158 @P1 @Dương
  Kịch bản: TC-04-158 Hợp đồng OpenAPI khớp máy chủ
    # Truy vết: API-04-001, 091
    Biết `openapi-integration.yaml`; `dh-integration` trên Testcontainers.
    Khi chạy Schemathesis (`--checks all`) trên toàn bộ operation với token IE1, IA1, TA.
    Và chạy `oasdiff breaking` so với `main`.
    Thì không phản hồi nào sai lược đồ, không mã HTTP ngoài khai báo, không lỗi 500. `oasdiff` không báo thay đổi phá vỡ trong `v1`.
