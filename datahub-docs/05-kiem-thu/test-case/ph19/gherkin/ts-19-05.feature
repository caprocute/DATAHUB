# language: vi
# Sinh tự động từ D05-02-PH19 bằng ph19/tools/gen_gherkin.py; không sửa tay.
@PH-19 @TS-19-05
Tính năng: TS-19-05 · Tra cứu và cập nhật NCC

  @TC-19-101 @P2 @Dương
  Kịch bản: TC-19-101 Danh sách NCC có lọc, tìm, đếm theo trạng thái
    # Truy vết: FR-19-007 · API-19-001 · UI-19-03 · LGC-PAY-002, 006
    Biết U-OPR1.
    Khi mở UI-19-03.
    Và gõ "pay" vào ô tìm.
    Và lọc "Sức khỏe: Suy giảm" sau khi cho `PGSIM` lỗi 30% để PV-PG suy giảm.
    Thì bước 1: đủ cột của hệ cũ (tên, ngày hiệu lực, đầu mối, tình trạng) cộng sức khỏe, số dịch vụ; facet đếm theo trạng thái đúng. Bước 2 chỉ còn PV-PG, PV-SUS. Bước 3 chỉ PV-PG. URL giữ `q`, `suc-khoe`. U-OPR1 không thấy nút "Thêm".

  @TC-19-102 @P2 @Dương
  Kịch bản: TC-19-102 Chi tiết NCC có đủ thông tin hệ cũ và biểu đồ 30 ngày
    # Truy vết: FR-19-008 · API-19-003 · UI-19-04 · LGC-PAY-003
    Biết U-AUD1; PV-PG có giao dịch 30 ngày.
    Khi mở UI-19-04 của PV-PG, tab "Thông tin".
    Và U-AUD1 xem `callbackUrls`.
    Thì bước 1: ngày bắt đầu, đầu mối, điện thoại (che giữa), tình trạng, số dịch vụ, biểu đồ giao dịch theo ngày 30 điểm khớp số đếm từ `payment_stats_daily`. Bước 2: đường callback hiện dạng che `…/paygov/••••••••/ipn`, không có nút "Sao chép đường dẫn đầy đủ" (cần `provider-write`).

  @TC-19-107 @P2 @Âm
  Kịch bản: TC-19-107 Danh sách, chi tiết NCC: tham số sai, không có quyền, tỉnh khác
    # Truy vết: FR-19-007, 008 · API-19-001, 003 · ERR-19-001, 046, 020
    Biết U-OPR1; U-SEC1 (không có `provider-read`); U-ADM1-T99.
    Khi `GET /providers?q=p` (1 ký tự); `?status=FOO`; `?limit=500`.
    Và U-SEC1 gọi API-19-001.
    Và U-ADM1-T99 gọi API-19-003 với mã PV-PG.
    Thì bước 1: mỗi trường hợp `400` ERR-19-001 chỉ đúng tham số. Bước 2: 403-PQ. Bước 3: 404-ẩn.

  @TC-19-103 @P1 @Dương
  Kịch bản: TC-19-103 Sửa NCC Nháp áp dụng ngay, sửa trường mô tả NCC đang hoạt động
    # Truy vết: FR-19-009 · API-19-004 · UI-19-05 · LGC-PAY-004
    Biết U-ADM1; PV-NEW `DRAFT`; PV-PG `ACTIVE`.
    Khi `PATCH /providers/{PV-NEW}` đổi `sandboxBaseUrl` với `If-Match`.
    Và `PATCH /providers/{PV-PG}` đổi `name`, `techContact`.
    Thì cả hai trả `200` với `ETag` mới; thay đổi có hiệu lực ngay; `pendingChange = null`. KT: có (`PROVIDER_UPDATE` với giá trị trước, sau).

  @TC-19-104 @P1 @Dương @Âm
  Kịch bản: TC-19-104 Đổi địa chỉ kết nối NCC đang thu tiền chỉ áp dụng sau kiểm tra
    # Truy vết: FR-19-009 · BR-19-026 · API-19-004, 009 · UI-19-04, 05
    Biết U-ADM1; PV-PG `ACTIVE`; `PGSIM` có địa chỉ thứ hai `https://pgsim2.test`.
    Khi `PATCH /providers/{PV-PG}` đổi `productionBaseUrl` sang `https://pgsim2.test`.
    Và C-DVC tạo giao dịch S-HT.
    Và cho `pgsim2` lỗi TLS; chạy kiểm tra kết nối `PRODUCTION`.
    Và sửa `pgsim2`; chạy lại kiểm tra.
    Và C-DVC tạo giao dịch S-HT.
    Thì bước 1 trả `200` có `pendingChange` chứa giá trị cũ, mới; UI-19-04 hiện dải "Có thay đổi kết nối chờ áp dụng". Bước 2 gọi địa chỉ cũ (kiểm `integration_log`). Bước 3 `FAILED`, `pendingChange` giữ nguyên. Bước 4 `PASSED`, `pendingChange = null`, địa chỉ mới có hiệu lực. Bước 5 gọi `pgsim2`. KT: có (`PROVIDER_CHANGE_PENDING`, `PROVIDER_CHANGE_APPLIED`).

  @TC-19-105 @P1 @Âm
  Kịch bản: TC-19-105 Sửa NCC sai trạng thái, sai phiên bản
    # Truy vết: FR-19-009 · API-19-004 · ERR-19-021, 045 · UI-19-05
    Biết U-ADM1, U-ADM2; NCC `PENDING_ACTIVATION`; PV-PG.
    Khi `PATCH` NCC `PENDING_ACTIVATION`.
    Và U-ADM1 và U-ADM2 cùng mở UI-19-05 của PV-PG; U-ADM2 lưu trước; U-ADM1 lưu sau.
    Và `PATCH` PV-PG không có `If-Match`.
    Thì bước 1 trả `409` ERR-19-021. Bước 2: U-ADM1 nhận `412` ERR-19-045, màn mở hộp "Dữ liệu đã thay đổi" hai cột. Bước 3 trả `428` hoặc `412` ERR-19-045 theo D03-04-PH19 §1.

  @TC-19-106 @P1 @Dương @Âm
  Kịch bản: TC-19-106 Đề nghị đổi bảng ánh xạ mã kết quả
    # Truy vết: FR-19-069 · BR-19-011, 015 · API-19-091, 092, 050 · UI-19-04 · ERR-19-033
    Biết U-ADM1, U-APR1; PV-PG bảng ánh xạ v1; IPN cách ly `UNMAPPED_CODE` mã `77` trong 30 ngày.
    Khi `GET /providers/{PV-PG}/result-mappings`.
    Và trên tab "Ánh xạ mã kết quả", bấm "Thêm vào đề nghị" cho mã `77`, chọn kết quả `SUCCEEDED`, gửi.
    Và U-ADM1 tự duyệt.
    Và U-APR1 duyệt.
    Và `POST C: …/ipn` có mã `77` cho giao dịch `PENDING`.
    Thì bước 1: v1 `ACTIVE`, khối mã lạ có `77`. Bước 2: màn hiện cảnh báo kết quả `SUCCEEDED`; API trả `201` đề nghị `RESULT_MAPPING_CHANGE`. Bước 3 trả `403` ERR-19-033. Bước 4: v2 `ACTIVE`, v1 `RETIRED` (không xóa). Bước 5: ST: `PENDING` → `SUCCEEDED` với `mappingVersion = 2`.
