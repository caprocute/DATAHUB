# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-27
Tính năng: TS-11-27 · Che dữ liệu cá nhân trong biến, sự kiện, lệnh, nhật ký

  @TC-11-140 @P1 @Bảo @mật
  Kịch bản: TC-11-140 Quét rò rỉ giá trị biến SENSITIVE trên toàn hệ thống
    # Truy vết: NFR-11-021 · BR-11-014 · FR-11-016, 028, 056, 022 · EVT-11-03, 04, 17, 20
    # Mục đích: Chứng minh 0 giá trị `SENSITIVE` dạng rõ ở log, vết, chỉ số, lệnh, sự kiện, outbox, bảng engine.
    Biết T96; 200 phiên `F-DLCN` chạy `LT_KHAI_SINH` đầu cuối, có sự cố, Saga, hủy; canary `DH-CANARY-leak` trong `hoTenTre`, `001099000123` trong `soDinhDanhMe`.
    Khi chạy 200 phiên
    Và quét log ứng dụng, vết OTel, chỉ số Prometheus, bản tin Kafka mọi topic `t96.bpm.*`, `outbox_event.payload`, `ACT_RU_VARIABLE_`, `ACT_HI_VARINST`, thông báo
    Và đọc cột mã hóa của `ph11_bpm`
    Thì 0 lần xuất hiện canary và số định danh dạng rõ ở mọi nơi trừ cột mã hóa của biến; `ACT_*` chỉ chứa mã hóa hoặc tham chiếu.

  @TC-11-141 @P2 @Bảo @mật
  Kịch bản: TC-11-141 Che hiển thị và mở che có điều kiện
    # Truy vết: FR-11-016, 022, 037 · API-11-055, 073 · BR-11-014 · PERM-09-unmask
    # Mục đích: Chứng minh che theo `dataClass`, mở che cần quyền và lý do, người vận hành nền tảng không xem biến.
    Biết `F-DLCN`; TA có `PERM-09-unmask`; TO không; PO có phiếu sự cố.
    Khi TA, TO, PO, CB-TP đọc biến phiên và việc
    Và TA mở che có lý do
    Và xuất lịch sử bằng AU
    Thì `SENSITIVE` luôn `` trừ TA có quyền và lý do (KT: có); `RESTRICTED` che với người thiếu quyền; PO không thấy biến; tệp xuất chỉ chứa băm và biến đã che.

  @TC-11-142 @P1 @Bảo @mật
  Kịch bản: TC-11-142 Quét phản hồi tiến độ DVC quy mô lớn
    # Truy vết: FR-11-055 · API-11-104 · BR-11-015, 014 · NFR-11-021
    # Mục đích: Chứng minh 500 phản hồi tiến độ, kể cả lỗi, chỉ chứa `publicName`, trạng thái, hạn, thông điệp.
    Biết T96; 500 hồ sơ nhiều trạng thái (đang xử lý, lỗi kỹ thuật, bù trừ, hủy); từ điển cấm như `progress-mask`.
    Khi S-DVC tra 500 hồ sơ
    Và quét thân, tiêu đề, thông điệp lỗi bằng từ điển cấm
    Thì 0 khớp từ điển cấm; trường chỉ thuộc tập cho phép (`businessKey`, `displayStatus`, `percentEstimate`, `dueAt`, `steps`, `message`).
