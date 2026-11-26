# language: vi
# Sinh tự động từ D05-02-PH15 bằng ph15/tools/gen_gherkin.py; không sửa tay.
@PH-15 @TS-15-30
Tính năng: TS-15-30 · Đồng bộ lại và đối soát danh mục

  @TC-15-167 @P2 @Dương
  Kịch bản: TC-15-167 Đồng bộ lại theo yêu cầu
    # Truy vết: FR-15-061 · UC-15-04 · API-15-131, 132 · UI-15-27 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết hà; bản sao đã nạp.
    Khi `POST /admin/sync:run`; `GET /admin/sync/runs`.
    Thì lần chạy có `runId`, `RUNNING` rồi `IDLE`, số mục, thời lượng; KT: có; lịch sử liệt kê đúng.

  @TC-15-168 @P2 @Âm
  Kịch bản: TC-15-168 Đang chạy, PH-02 lỗi, thiếu quyền
    # Truy vết: FR-15-061 · API-15-131 · ERR-15-005, 030, 035 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết lần chạy dài (WireMock chậm); ngắt PH-02; An.
    Khi gọi `sync:run` hai lần liên tiếp.
    Và gọi khi PH-02 ngắt.
    Và an gọi.
    Thì `409` ERR-15-035 "Đang có lần chạy khác..."; `502` ERR-15-030; `403` ERR-15-005.

  @TC-15-169 @P2 @Dương
  Kịch bản: TC-15-169 Đối soát phát hiện và sửa sai lệch
    # Truy vết: FR-15-061 · UC-15-04 · API-15-133, 134 · BR-15-001 · LGC mới (không có chức năng hệ cũ tương ứng).
    Biết xóa tay một mục ở bản sao, sửa tên mục khác (chỉ ở bản sao).
    Khi `POST /admin/reconciliations`; `GET /admin/reconciliations/latest`.
    Và `sync:run`; đối soát lại.
    Thì báo 2 sai lệch (thiếu, khác `sourceVersion`); sau đồng bộ lại 0 sai lệch, bản sao ghi đè theo PH-02.
