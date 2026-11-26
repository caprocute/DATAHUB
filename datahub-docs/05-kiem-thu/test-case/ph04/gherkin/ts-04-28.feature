# language: vi
# Sinh tự động từ D05-02-PH04 bằng ph04/tools/gen_gherkin.py; không sửa tay.
@PH-04 @TS-04-28
Tính năng: TS-04-28 · Sự kiện, outbox và hợp đồng API

  @TC-04-156 @P1 @Dương @Âm
  Kịch bản: TC-04-156 Outbox ghi cùng giao dịch, không phát khi lỗi
    # Truy vết: EVT-04-01, 03, 04, 06.
    Biết testcontainers PostgreSQL, Kafka, Debezium.
    Khi tạo luồng; kiểm `ph04.outbox` và topic.
    Và gây lỗi sau khi ghi `flow` nhưng trước khi commit (tiêm lỗi ở `FlowService`).
    Thì bước 1: một dòng outbox, một bản tin CloudEvents trên `t68.integration.flow.created.v1` với tiêu đề `ce_id`, `ce_type`, `ce_source = /tenants/T68/integration`, khóa `T68:{flowId}`. Bước 2: không có dòng luồng, không có dòng outbox, không có bản tin.

  @TC-04-157 @P2 @Dương
  Kịch bản: TC-04-157 Lược đồ mọi sự kiện khớp AsyncAPI
    # Truy vết: EVT-04-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14.
    Biết chạy đầy đủ một vòng tạo, sửa, gửi, yêu cầu sửa, duyệt, phát hành, tạm dừng, chạy thử, gỡ.
    Khi thu mọi bản tin trên 14 topic, kiểm bằng lược đồ trong `asyncapi-integration.yaml`.
    Thì 100% bản tin hợp lệ; không bản tin nào chứa `definitionYaml`, `samples` hay thân bản tin nghiệp vụ.

  @TC-04-158 @P1 @Dương
  Kịch bản: TC-04-158 Hợp đồng OpenAPI khớp máy chủ
    # Truy vết: API-04-001, 091.
    Biết `openapi-integration.yaml`; `dh-integration` trên Testcontainers.
    Khi chạy Schemathesis (`--checks all`) trên toàn bộ operation với token IE1, IA1, TA.
    Và chạy `oasdiff breaking` so với `main`.
    Thì không phản hồi nào sai lược đồ, không mã HTTP ngoài khai báo, không lỗi 500. `oasdiff` không báo thay đổi phá vỡ trong `v1`.

  @TC-04-202 @P1 @Dương @Biên
  Kịch bản: TC-04-202 Di trú dữ liệu W2 khi schema do tài khoản khác sở hữu
    # Truy vết: FR-04-011, 030 · BR-04-004 · ERR-04-014 · D03-03-PH04 §4.2.
    Biết testcontainers PostgreSQL (bản của CI và bản 16.15 như lần chạy thử ở D03-03-PH04 §4.2); schema `ph04` tạo sẵn do `postgres` sở hữu, có bốn bảng W2: một `route` `PUBLISHED`, hai `route_version` `PUBLISHED` và `TESTING`, một `route_test_run`; tài khoản `ph04_owner` không phải chủ schema.
    Khi chạy changelog Liquibase của `ph04` dưới `ph04_owner`.
    Và đọc `flow`, `flow_version`, `test_run`, danh sách bảng của schema.
    Và chạy lại changelog lần hai.
    Và dưới `ph04_app`, thử cập nhật lần chạy di trú sang `PASSED` và gửi duyệt phiên bản 2.
    Và chạy changelog trên CSDL trống để đối chứng.
    Thì bước 1: changeset `ph04-0004-legacy-owner` chuyển quyền sở hữu schema và bốn bảng cũ cho `ph04_owner`; không có lỗi "permission denied for schema ph04". Bước 2: luồng `APPROVED`; phiên bản 1 `APPROVED` (người duyệt `system:migrate`), phiên bản 2 `DRAFT`; cả hai `needs_revalidation = true`; lần chạy `mode = SIMULATED`; bốn bảng cũ đổi tên `*_legacy_w2`. Bước 3: không áp thêm changeset, dữ liệu không đổi. Bước 4: ràng buộc chặn `SIMULATED` thành `PASSED`; gửi duyệt trả `409` ERR-04-014 vì chưa có lần chạy thật (BR-04-004). Bước 5: 26 bảng, 25 bảng bật RLS, 100 chính sách.
