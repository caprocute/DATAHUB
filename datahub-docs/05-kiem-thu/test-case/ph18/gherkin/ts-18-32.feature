# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-32
Tính năng: TS-18-32 · Xuất dữ liệu tenant

  @TC-18-108 @P1 @Dương
  Kịch bản: TC-18-108 Xuất T93 khi DECOMMISSIONED, tải bằng liên kết 24 giờ
    # Truy vết: FR-18-056 · API-18-147, 148, 149 · BR-18-048 · EVT-18-23 · UI-18-20
    # Mục đích: Chứng minh FR-18-056: gói có manifest và tổng kiểm tra 100 % tệp, liên kết tải có hạn, EVT-18-23 cho PH-20.
    Biết T93 trạng thái `DECOMMISSIONED` (WireMock PH-20); U-PA1 (`PERM-18-backup`).
    Khi `POST /tenant-exports` mục đích `HANDOVER`.
    Và theo dõi `GET /tenant-exports/{exportId}`.
    Và `POST /tenant-exports/{exportId}:download-link`.
    Và kiểm tổng kiểm tra từng tệp.
    Thì bước 2 `SUCCEEDED`, `sizeBytes`, `manifestSha256`; EVT-18-23. Bước 3 `200` liên kết hết hạn sau `18.export.link-ttl-hours`, KT: có. Bước 4 100 % tệp khớp manifest.

  @TC-18-109 @P1 @Âm @Chịu_lỗi
  Kịch bản: TC-18-109 Xuất với trạng thái tenant không phù hợp, tác vụ nặng khác và Job lỗi
    # Truy vết: FR-18-056 · API-18-147 · BR-18-039 · ERR-18-057, 059, 116
    # Mục đích: Chứng minh điều kiện chặn của xuất tenant.
    Biết T90 `ACTIVE`; khôi phục `RST-T90-02` đang chạy ở bước 2; tiêm lỗi Garage ở bước 3.
    Khi xuất T90 mục đích `HANDOVER`.
    Và xuất T90 mục đích `CELL_MOVE` khi khôi phục đang chạy.
    Và xuất T93 khi Garage lỗi.
    Thì bước 1 `409` ERR-18-059. Bước 2 `409` ERR-18-057. Bước 3 lệnh xuất `FAILED` ghi ERR-18-116, gói dở dang bị xóa.
