# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-29
Tính năng: TS-01-29 · Không lộ bí mật

  @TC-01-113 @P1 @Bảomật
  Kịch bản: TC-01-113 Dò mồi trên toàn luồng cấp, bàn giao, xoay vòng, thu hồi
    # Truy vết: NFR-01-009 · FR-01-020, 022, 025, 026 · BR-01-007 · API-01-040, 045.
    Biết giả lập PH-12 trả bí mật có chuỗi `DH-CANARY-flow`; OpenBao thật; U-T68-TECH, TA1.
    Khi chạy: phê duyệt, saga, bàn giao, xoay vòng, thu hồi.
    Và quét phản hồi API, log 5 phút, vết OTel, bảng `ph01_onboarding.*`, outbox, Kafka, thư mail-sink.
    Thì `DH-CANARY-flow` chỉ có trong phản hồi `POST /handovers:open` và trong OpenBao; mọi nơi khác 0 lần xuất hiện.

  @TC-01-114 @P1 @Bảomật
  Kịch bản: TC-01-114 Dò mồi khi xảy ra lỗi
    # Truy vết: NFR-01-009 · ERR-01-021, 023 · API-01-035, 040.
    Biết mồi `DH-CANARY-err` trong bí mật giả lập; PH-12 và OpenBao điều khiển được.
    Khi gây lỗi giữa saga; gây lỗi khi mở bàn giao; gây lỗi khi xoay vòng.
    Và quét thân lỗi RFC 9457 (trường `detail`, `errors`), log, vết.
    Thì không có `DH-CANARY-err` ở thân lỗi, log, vết, kể cả ngăn xếp ngoại lệ.

  @TC-01-115 @P1 @Bảomật
  Kịch bản: TC-01-115 Dò mồi ở tệp xuất, thư thông báo, báo cáo
    # Truy vết: NFR-01-009 · API-01-075, 079, 085, 088 · FR-01-050.
    Biết HTTT có định danh mang `DH-CANARY-exp`; U-T68-AU.
    Khi xuất danh sách HTTT, danh bạ, báo cáo rà soát; tải qua `GET /jobs/{jobId}`.
    Và đọc mọi thư của mail-sink.
    Thì không có `DH-CANARY-exp` ở tệp xuất lẫn thư; thư bàn giao chỉ có liên kết.

  @TC-01-116 @P2 @Bảomật
  Kịch bản: TC-01-116 Lược đồ CSDL không có chỗ lưu bí mật
    # Truy vết: BR-01-007 · NFR-01-009 · FR-01-020, 021.
    Biết lược đồ `ph01_onboarding` theo D03-03-PH01.
    Khi liệt kê cột có tên hay kiểu có thể chứa bí mật, khóa riêng (`secret`, `password`, `private`, `token` ngoài `*_ref`, `*_hash`).
    Thì chỉ có `secret_ref`, vân tay, giá trị băm; không có cột bí mật.
