# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-01
Tính năng: TS-01-01 · Danh sách, chi tiết, lịch sử và xuất HTTT thành viên

  @TC-01-001 @P1 @Dương
  Kịch bản: TC-01-001 Danh sách có lọc, tìm kiếm, thẻ tổng
    # Truy vết: FR-01-001 · UC-01-01 · API-01-001 · UI-01-03 · LGC-APIM-019.
    Biết U-T68-TA1; bộ HTTT mục 2.3 (ít nhất 200 HTTT nền).
    Khi mở UI-01-03; đọc năm thẻ tổng; bấm thẻ "Đang hoạt động".
    Và `GET /systems?q=hộ tịch&status=ACTIVE&page=1&size=50`.
    Thì bước 1: bảng lọc theo `ACTIVE`, số thẻ bằng `facets` của API. Bước 2: `200`, có `items`, `facets`, `page`; mỗi dòng có mã, tên, tổ chức, trạng thái, nhóm, cấp độ ATTT; sắp xếp mặc định ổn định. KT: không. EVT: không.

  @TC-01-002 @P1 @Âm @Bảomật
  Kịch bản: TC-01-002 Giới hạn theo vai trò: OR chỉ thấy tổ chức mình, DO chỉ thấy dữ liệu của mình
    # Truy vết: FR-01-001, 002 · API-01-001, 002 · BR-01-030.
    Biết U-T68-OR1 (Sở Tư pháp); U-T68-DO; `HT-DVC` của Văn phòng UBND.
    Khi U-T68-OR1 gọi `GET /systems`; sau đó `GET /systems/HT-DVC`.
    Và U-T68-DO gọi `GET /systems`.
    Thì bước 1: danh sách chỉ có HTTT của Sở Tư pháp; chi tiết `HT-DVC` `404-ẩn`. Bước 2: chỉ các HTTT có dữ liệu thuộc chủ quản của DO. Tổng số (`total`) không tiết lộ HTTT ngoài phạm vi.

  @TC-01-003 @P2 @Dương
  Kịch bản: TC-01-003 Chi tiết và lịch sử trạng thái, hành động khả dụng theo trạng thái
    # Truy vết: FR-01-002 · UC-01-01 · API-01-002, 003 · UI-01-04.
    Biết U-T68-TA1; `HT-QLVB` ACTIVE; `HT-HOTICH` DRAFT.
    Khi `GET /systems/HT-QLVB`; `GET /systems/HT-QLVB/history`.
    Và `GET /systems/HT-HOTICH`.
    Thì bước 1: `200`, `ETag`; `allowedActions` có `suspend`, `rotate`; lịch sử có các chuyển trạng thái theo thứ tự thời gian kèm người thực hiện; không có trường bí mật nào. Bước 2: `allowedActions` có `submit`, `delete`; không có `suspend`.

  @TC-01-004 @P1 @Âm @Bảomật
  Kịch bản: TC-01-004 Chi tiết không tồn tại hoặc ở tenant khác
    # Truy vết: FR-01-002 · API-01-002, 003 · ERR-01-001 · BR-01-030.
    Biết U-T68-TA1; `HT-QLVB` có ở cả T68 và T01 với nội dung khác; `HT-TC-KHAC` chỉ có ở T01.
    Khi U-T68-TA1 gọi `GET /systems/khong-co`.
    Và U-T68-TA1 gọi `GET /systems/HT-TC-KHAC` và `GET /systems/HT-TC-KHAC/history`.
    Và U-T68-TA1 gọi `GET /systems/HT-QLVB` rồi so với U-T01-TA.
    Thì bước 1 và 2: `404-ẩn`, thân giống hệt trừ `traceId`. Bước 3: mỗi người chỉ thấy bản của tenant mình, không lẫn trường.

  @TC-01-005 @P2 @Dương @Âm
  Kịch bản: TC-01-005 Xuất danh sách: phạm vi theo quyền, tác vụ nền
    # Truy vết: FR-01-050 · UC-01-01 · API-01-085, 088 · UI-01-03 · ERR-01-052.
    Biết U-T68-AU; U-T68-OR1; U-T68-VW.
    Khi U-T68-AU gọi `POST /systems:export` kèm `format=XLSX`, `Idempotency-Key`; hỏi `GET /jobs/{jobId}` đến khi xong.
    Và U-T68-OR1 gọi cùng API xuất toàn bộ tenant.
    Và U-T68-VW gọi cùng API.
    Thì bước 1: `200` hoặc `202`, tệp có đủ HTTT của tenant, không có `secret_ref`; KT: có (xuất danh sách). Bước 2: chỉ xuất HTTT của tổ chức mình. Bước 3: `403-PQ` khi xuất toàn bộ.

  @TC-01-006 @P3 @Biên
  Kịch bản: TC-01-006 Biên phân trang và bộ lọc sai
    # Truy vết: FR-01-001 · API-01-001 · ERR-01-003.
    Biết U-T68-TA1.
    Khi `GET /systems?size=100` rồi `size=101` và `status=KHONG-CO`.
    Thì `size=100` trả `200`; `size=101` và `status` sai trả `400` ERR-01-003 kèm danh sách lỗi theo trường.
