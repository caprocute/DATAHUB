# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-03
Tính năng: TS-13-03 · Siêu dữ liệu lượt gọi API và chỉ số thành phần nền

  @TC-13-009 @P1 @Dương
  Kịch bản: TC-13-009 Lượt gọi API qua APISIX vào kho lượt gọi, không có thân yêu cầu
    # Truy vết: FR-13-006 · UC-13-03 · BR-13-011 · LGC-APIM-022
    Biết 50 lượt gọi tới HTTT giả lập, một lượt có thân chứa `DH-CANARY-access`.
    Khi gửi 50 lượt gọi qua APISIX.
    Và truy vấn ClickHouse (qua API-13-025) trong 60 giây.
    Thì 50 bản ghi có `trace_id`, HTTT, API, mã trả về, thời gian, kích thước; không thân yêu cầu, không tiêu đề `Authorization`; mồi sạch.

  @TC-13-010 @P1 @Âm @Khả @dụng
  Kịch bản: TC-13-010 Kho lượt gọi API ngừng, gateway không bị chặn
    # Truy vết: FR-13-006 · BR-13-015 · ERR-13-118 · NFR-13-014
    Biết tắt ClickHouse 10 phút; gửi 100 lượt/giây.
    Khi tắt ClickHouse; gửi tải; bật lại.
    Thì 0 lượt gọi lỗi do PH-13; Kafka giữ siêu dữ liệu; sau khi bật lại bản ghi vào đủ, không trùng; ERR-13-118 hiện ở UI-13-01.

  @TC-13-011 @P2 @Dương @Âm
  Kịch bản: TC-13-011 Chỉ số thành phần nền đủ cho Kafka, PostgreSQL, OpenBao, APISIX
    # Truy vết: FR-13-007 · BR-13-016 · EVT-13-14 · NFR-13-027
    Biết SIT đủ thành phần; tắt exporter của OpenBao.
    Khi truy vấn `GET /components`.
    Và tắt exporter của OpenBao 2 phút, truy vấn lại.
    Thì bước 1: mọi thành phần có trạng thái. Bước 2: OpenBao hiển thị "Chưa có dữ liệu" (không phải 0), các thành phần khác không đổi.
