# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-25
Tính năng: TS-19-25 · Dashboard và cảnh báo

  @TC-19-601 @P1 @Dương
  Kịch bản: TC-19-601 Dashboard tổng quan đủ chỉ tiêu hệ cũ, số liệu đúng
    # Truy vết: FR-19-056 · API-19-080 · UI-19-01 · LGC-PAY-013, 026
    Biết U-OPR1; bộ dữ liệu §2.4 cộng 3 giao dịch thử.
    Khi mở UI-19-01.
    Và so các thẻ với truy vấn đối chứng SQL.
    Thì bước 1: đủ số dịch vụ, số hệ thống áp dụng, tổng giao dịch, giao dịch trong ngày, biểu đồ theo dịch vụ giảm dần, huy hiệu việc cần làm. Bước 2: bằng nhau; giao dịch thử không được đếm.

  @TC-19-602 @P1 @Dương
  Kịch bản: TC-19-602 Số liệu cập nhật trong 60 giây
    # Truy vết: FR-19-056 · NFR-19-006 · API-19-080
    Biết dashboard đang mở.
    Khi tạo và hoàn tất 10 giao dịch.
    Và đo thời điểm `txnToday` tăng 10.
    Thì ≤ 60 giây (thay đệm 10 phút của hệ cũ, LGC-PAY-026); `asOf` hiện trên giao diện.

  @TC-19-603 @P2 @Dương
  Kịch bản: TC-19-603 Dashboard kênh thanh toán 30 ngày
    # Truy vết: FR-19-057 · API-19-081 · UI-19-02 · LGC-PAY-003, 020, 023
    Biết PV-PG có giao dịch 30 ngày; PV-SUS.
    Khi mở UI-19-02.
    Thì mỗi NCC một thẻ: tên, ngày hiệu lực, đầu mối, tình trạng (PV-SUS hiện "Tạm ngừng"), số dịch vụ, biểu đồ số giao dịch theo ngày 30 ngày, tỷ lệ thành công, độ trễ p95.

  @TC-19-604 @P2 @Âm
  Kịch bản: TC-19-604 Dashboard không có quyền, tỉnh khác
    # Truy vết: FR-19-056, 057 · API-19-080, 081 · ERR-19-046 · NFR-19-025
    Biết U-SEC1; U-ADM1-T99.
    Khi U-SEC1 gọi API-19-080.
    Và U-ADM1-T99 gọi API-19-080 với `X-Tenant-Id: T68`.
    Thì bước 1: 403-PQ. Bước 2: số liệu của T99, tiêu đề tenant giả bị bỏ qua hoặc từ chối theo D03-10.

  @TC-19-605 @P2 @Dương
  Kịch bản: TC-19-605 Chỉ số vận hành và cảnh báo
    # Truy vết: FR-19-059 · NFR-19-026 · LGC-PAY-009
    Biết prometheus của SIT; quy tắc cảnh báo của D04.
    Khi cho `PGSIM` lỗi 60% trong 2 phút.
    Và giữ 5 giao dịch `PENDING` quá 30 phút.
    Và ngừng đầu nhận webhook 15 phút.
    Thì có các chỉ số `payment_provider_errors_total`, `payment_pending_age_seconds`, `payment_webhook_backlog`; ba cảnh báo tương ứng tới PH-13 trong 2 phút sau khi vượt ngưỡng; nhãn chỉ có tenant, NCC, không có mã giao dịch.
