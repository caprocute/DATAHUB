# language: vi
# Sinh tự động từ D05-02-PH17 bằng ph17/tools/gen_gherkin.py; không sửa tay.
@PH-17 @TS-17-05
Tính năng: TS-17-05 · Tắt khẩn cấp trợ lý toàn tenant hoặc toàn nền tảng

  @TC-17-015 @P1 @Hiệu_năng @Bảo_mật
  Kịch bản: TC-17-015 Tắt khẩn tenant: mọi bản sao trả 403 trong 60 giây
    # Truy vết: FR-17-006 · NFR-17-004 · API-17-020, 021 · BR-17-008 · ERR-17-012, 104 · EVT-17-03 · UI-17-06
    # Mục đích: Đo thời gian từ EVT-17-03 phát đến lượt gọi đầu tiên bị `403` ở mọi bản sao, mọi DU gọi và giao diện (NFR-17-004).
    Biết T90 bật, `dh-assist` 2 bản sao, 50 phiên hội thoại đang mở, một luồng PH-04 đang gọi `/assist/v1/inference/classify`; U-T90-TA1, U-T90-SO; đồng hồ thật.
    Khi k6 giữ 50 phiên gửi câu hỏi mỗi 2 giây và PH-04 gọi suy luận mỗi giây.
    Và SO `POST /kill-switch:activate` với `reason` 30 ký tự; ghi thời điểm `t0` khi EVT-17-03 phát.
    Và ghi thời điểm lượt gọi đầu tiên bị `403` ở từng bản sao, ở data plane và thời điểm nút "Trợ lý" ẩn trên giao diện.
    Và lặp 30 lần (gỡ rồi bật lại ở T94) lấy p99.
    Thì bước 2 `200`, `TenantAssistState = KILLED`, KT: có, EVT: `assist.kill-switch.changed`. Bước 3 người dùng `403` ERR-17-012, DU gọi `403` ERR-17-104, nút ẩn; chênh lệch từ `t0` p99 ≤ 60 giây ở mọi bản sao; lượt đang chạy bị ngắt. Bước 4 p99 ≤ 60 giây qua 30 lần. Nhật ký và chỉ mục giữ nguyên.

  @TC-17-016 @P1 @Chịu_lỗi @Bảo_mật
  Kịch bản: TC-17-016 Tắt khẩn khi Kafka chậm hoặc PH-13 không ghi được vẫn có hiệu lực ≤ 60 giây
    # Truy vết: FR-17-006 · API-17-020 · BR-17-008, 009 · NFR-17-004 · ERR-17-012 · EVT-17-03
    # Mục đích: Chứng minh bản sao đọc cờ ở CSDL theo bộ đệm 30 giây khi Kafka chậm, và tắt khẩn không bị chặn bởi kiểm toán.
    Biết T94 bật; chặn Kafka tới một bản sao (Chaos Mesh trễ 120 giây); PH-13 WireMock trả `503`; U-T94-SO.
    Khi SO `POST /kill-switch:activate` kèm lý do.
    Và gửi câu hỏi tới bản sao bị trễ Kafka mỗi 5 giây.
    Và sau khi PH-13 phục hồi, kiểm tra hàng đợi kiểm toán cục bộ.
    Thì bước 1 `200` (kill switch không bị chặn bởi lỗi kiểm toán, khác thao tác thường vốn từ chối ERR-17-010; chờ Q17-23). Bước 2 bản sao trễ vẫn `403` ERR-17-012 trong ≤ 60 giây nhờ cờ CSDL làm mới 30 giây. Bước 3 bản ghi kiểm toán được ghi bù, đủ trường, không mất.

  @TC-17-017 @P1 @Dương @Âm @Bảo_mật
  Kịch bản: TC-17-017 Tắt khẩn toàn nền tảng, gỡ cần hai người, nhóm tenant
    # Truy vết: FR-17-006 · API-17-022, 023, 024, 025 · BR-17-008 · ERR-17-005, 012 · EVT-17-03
    # Mục đích: Chứng minh PA tắt khẩn nền tảng hoặc nhóm tenant và việc gỡ đi qua đề nghị và duyệt bởi hai PA khác nhau.
    Biết T90, T91, T92 bật; U-PA1, U-PA2; U-T90-TA1.
    Khi PA1 `POST /platform/kill-switch:activate` với `scope = PLATFORM`.
    Và U-T90-IE và U-T91-IE gửi câu hỏi.
    Và U-T90-TA1 gọi `POST /platform/kill-switch:activate`.
    Và PA1 `POST /platform/kill-switch:release`, rồi PA1 `POST /platform/kill-switch:approve-release` cho đề nghị của chính mình.
    Và PA2 `POST /platform/kill-switch:approve-release`.
    Và PA1 tắt khẩn nhóm `[T90]` rồi U-T91-IE gửi câu hỏi.
    Thì bước 1 `200`, KT: có. Bước 2 cả hai `403` ERR-17-012 trong ≤ 60 giây. Bước 3 `403` ERR-00-403 (thiếu `PERM-17-model`). Bước 4 đề nghị `PENDING`, tự duyệt `403` ERR-17-005. Bước 5 `200`, các tenant về trạng thái trước tắt khẩn, bật lại tenant phải theo FR-17-001 nếu tenant từng `KILLED` riêng. Bước 6 chỉ T90 bị chặn, T91 `200`.
