# language: vi
# Sinh tự động từ D05-02-PH13 bằng ph13/tools/gen_gherkin.py; không sửa tay.
@PH-13 @TS-13-10
Tính năng: TS-13-10 · Lưu giữ, lưu trữ phân vùng và tự kiểm toán của PH-13

  @TC-13-035 @P1 @Dương
  Kịch bản: TC-13-035 Phân vùng tháng thứ 13 chuyển `ARCHIVED` sau khi WORM xác minh đủ
    # Truy vết: FR-13-018 · UC-13-10 · BR-13-002, 020 · API-13-088 · UI-13-18 · EVT-13-11 · LGC-NFR-005
    Biết F-AUD-12M.
    Khi chạy bộ quản lý phân vùng; `GET /partitions`.
    Thì phân vùng cũ `SEALED` → `ARCHIVED` chỉ sau khi tổng kiểm WORM khớp; EVT: `partition-archived`; phân vùng trong 12 tháng không bị động tới.

  @TC-13-036 @P1 @Âm
  Kịch bản: TC-13-036 Chưa xác minh được WORM thì giữ phân vùng và báo
    # Truy vết: FR-13-018 · UC-13-10 · ERR-13-125 · BR-13-002 · API-13-088 · UI-13-18
    Biết F-AUD-12M; xóa lô WORM của một ngày ở bản sao thử.
    Khi chạy bộ quản lý phân vùng.
    Thì phân vùng giữ `SEALED`; ERR-13-125 `WARNING`; không có bản ghi nào bị xóa khỏi bảng.

  @TC-13-037 @P1 @Dương
  Kịch bản: TC-13-037 Mọi thao tác trên PH-13 để lại bản ghi kiểm toán
    # Truy vết: FR-13-019 · UC-13-11 · BR-13-006 · NFR-13-025
    Biết U-T68-TA, U-T68-SO, U-T68-AU.
    Khi thực hiện: tra kiểm toán, xem chi tiết, kiểm tra toàn vẹn, xuất bằng chứng, tải, xem liên tenant, sửa luật, đổi ngưỡng, tạm ẩn, đổi tham số, đổi SIEM.
    Và tra chuỗi T68 theo `source_du = dh-platform` trong khoảng thời gian.
    Thì đúng một bản ghi cho mỗi thao tác (100 %), có `actor`, `action`, `reason` (nếu bắt buộc), `trace_id`; không chứa giá trị Nhạy cảm.

  @TC-13-122 @P1 @Âm
  Kịch bản: TC-13-122 Thao tác bị từ chối hoặc thất bại vẫn có bản ghi kiểm toán
    # Truy vết: FR-13-019 · UC-13-11 · BR-13-006 · NFR-13-025 · ERR-13-009 · ERR-13-012
    Biết U-T68-TO (không quyền kiểm toán); U-T68-AU.
    Khi U-T68-TO gọi `POST /records:search`.
    Và U-T68-AU tra kiểm toán thiếu lý do.
    Và tra chuỗi T68 theo `action = AUDIT.QUERY`.
    Thì hai bản ghi với `outcome = DENIED` và `FAILED`, có `actor`, `error_code` (ERR-13-009, ERR-13-012); không chứa nội dung truy vấn nhạy cảm.
