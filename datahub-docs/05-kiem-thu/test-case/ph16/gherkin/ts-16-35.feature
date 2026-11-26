# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-35
Tính năng: TS-16-35 · Tái lập, chịu lỗi và giao sự kiện

  @TC-16-118 @P1 @Dương
  Kịch bản: TC-16-118 Tính lại cho cùng giá trị
    # Truy vết: NFR-16-011 · FR-16-019, FR-16-023 · BR-16-034
    Biết T90; dữ liệu F-KY-1 đóng băng; hai lần tổng hợp liên tiếp cùng phiên bản công thức.
    Khi chạy tổng hợp `M-2026-10` lần 1
    Và chạy tổng hợp lần 2 (`trigger = RECOMPUTE`)
    Và so từng `value`, `status`, `completeness`, `lineage` giữa hai lần
    Thì mọi `value` giống nhau tới 6 chữ số thập phân (sai số 0), `status`, `completeness` và `inputs[]` trùng; chỉ `runId`, `computedAt` khác.

  @TC-16-119 @P1 @Chịu @lỗi
  Kịch bản: TC-16-119 Dừng dh-platform 1 giờ, xóa một bản sao khi đang tổng hợp
    # Truy vết: NFR-16-012, NFR-16-008 · FR-16-010, FR-16-018 · BR-16-012, BR-16-030 · ERR-16-110
    Biết T95; Kafka giữ 7 ngày; hai bản sao `dh-platform`; luồng 50 sự kiện/giây; một lần tổng hợp đang `RUNNING`.
    Khi dừng cả hai bản sao 1 giờ trong khi phát sự kiện
    Và bật lại, đợi tiêu thụ bù
    Và khi đang tổng hợp, xóa một pod
    Và đo tỷ lệ API control thành công trong tháng thử
    Thì bước 2 0 quan sát mất, 0 quan sát trùng (so số sự kiện đã phát). Bước 3 lần tổng hợp dở dang hoàn tất ở bản còn lại hoặc `FAILED` không ghi đè kết quả lần trước; API control vẫn đáp. Sẵn sàng ≥ 99,5 % mỗi tháng với tối thiểu 2 bản sao.

  @TC-16-120 @P1 @Chịu @lỗi @Bảo
  Kịch bản: TC-16-120 Kiểm băm hằng ngày bản công bố 100 % khớp
    # Truy vết: NFR-16-013 · FR-16-029, FR-16-036 · ERR-16-124 · BR-16-009, BR-16-010
    Biết T90 có 50 báo cáo `PUBLISHED` ở các phiên bản; tác vụ kiểm băm.
    Khi chạy tác vụ kiểm băm hằng ngày
    Và thử 100 lệnh sửa (`PATCH`, `PUT`, `:refresh`, SQL, ghi đè WORM) lên báo cáo `PUBLISHED`
    Và chạy lại tác vụ
    Thì lần 1 khớp 100 %. Bước 2 0 lệnh sửa thành công. Lần 3 vẫn khớp 100 %; nếu có sai lệch cài sẵn thì đúng mục sai bị báo ERR-16-124.

  @TC-16-121 @P2 @Chịu @lỗi
  Kịch bản: TC-16-121 Giao sự kiện ít nhất một lần khi Kafka ngừng
    # Truy vết: NFR-16-017 · EVT-16-05, EVT-16-08, EVT-16-12 · FR-16-029, FR-16-051
    Biết T95; hộp gửi (outbox) bật; Kafka ngừng 10 phút.
    Khi ngừng Kafka, công bố một báo cáo và đổi trạng thái một gói quốc gia
    Và bật Kafka
    Và đo `kpi_outbox_lag_seconds` và đếm bản tin trên topic
    Thì sau khi bật lại, mỗi sự kiện được giao ít nhất một lần, bên tiêu thụ xử lý trùng không lỗi (khóa theo `eventId`); trễ outbox p95 ≤ 5 giây khi Kafka bình thường; trạng thái dữ liệu không lệch với sự kiện.
