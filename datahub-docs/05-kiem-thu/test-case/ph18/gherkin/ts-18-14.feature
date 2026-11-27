# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-14
Tính năng: TS-18-14 · Sửa payload có kiểm soát và duyệt bốn mắt

  @TC-18-044 @P1 @Dương
  Kịch bản: TC-18-044 Sửa trường thường không cần duyệt, khác biệt rõ, bản gốc giữ nguyên
    # Truy vết: FR-18-024 · API-18-052, 053, 054 · BR-18-012 · UI-18-04
    # Mục đích: Chứng minh BR-18-012: bản sửa mới `APPROVED` ngay khi không chạm trường Hạn chế, bản gốc trong CSDL và Garage không đổi.
    Biết T90; `DLQ-A-05` `TRIAGED` có trường `ngayHieuLuc` sai định dạng; U-T90-IE (`PERM-18-dlq-payload`); băm SHA-256 của bản gốc đã ghi lại.
    Khi IE mở `/van-hanh/dlq/DLQ-A-05/sua`, sửa `ngayHieuLuc` theo ISO 8601, lý do "Sửa định dạng ngày theo hợp đồng".
    Và `GET /dlq/messages/DLQ-A-05/revisions/1/diff`.
    Và tính lại băm bản gốc.
    Thì bước 1 `201` bản sửa số 1 `APPROVED`, kiểm lược đồ đạt. Bước 2 khác biệt chỉ một trường. Bước 3 băm bản gốc không đổi; bảng `dlq_message` không có cột nào bị cập nhật nội dung (bộ kiểm `ph18_isolation_test.sql` khối bất biến chạy đạt).

  @TC-18-045 @P1 @Âm @Dương @Bảo_mật
  Kịch bản: TC-18-045 Bản sửa chạm trường Hạn chế cần TA duyệt, IE tự duyệt bị chặn, bản sửa thứ hai chờ
    # Truy vết: FR-18-024 · API-18-053, 055, 056 · BR-18-018, 046 · ERR-18-005, 030 · EVT-18-07 · UI-18-04, 15
    # Mục đích: Chứng minh BR-18-018 và LP-18-01: bản sửa chạm trường mức Hạn chế theo PH-09 vào `PENDING_APPROVAL`, việc duyệt hiện cho TA không hiện cho người sửa, người sửa không tự duyệt được.
    Biết T90; `DLQ-A-06` có trường `diaChiThuongTru` mức Hạn chế (WireMock PH-09); U-T90-IE có cả `PERM-18-approve` để kiểm tách nhiệm vụ; U-T90-TA2.
    Khi IE tạo bản sửa số 1 đổi `diaChiThuongTru`.
    Và IE `POST .../revisions/1:approve`.
    Và IE tạo bản sửa số 2 khi số 1 còn chờ.
    Và TA2 mở việc `ph18.approve-revision` ở `/viec-cua-toi`, duyệt.
    Thì bước 1 `201` `PENDING_APPROVAL`. Bước 2 `403` ERR-18-005. Bước 3 `409` ERR-18-030. Bước 4 `200` `APPROVED`, mục sang `TRIAGED` nếu đang `POISON`, EVT-18-07; việc không hiện với IE.

  @TC-18-046 @P1 @Âm
  Kịch bản: TC-18-046 Bản sửa sai lược đồ, thiếu lý do và từ chối bản sửa
    # Truy vết: FR-18-024 · API-18-053, 056, 064 · BR-18-012 · ERR-18-007, 029
    # Mục đích: Chứng minh bản sửa phải đúng lược đồ của luồng và có lý do; bản bị từ chối không phát lại được.
    Biết T90; `DLQ-A-05`; lược đồ `thue-dong-bo` v3 yêu cầu `maSoThue` 10 hoặc 13 chữ số.
    Khi tạo bản sửa có `maSoThue = "12AB"`.
    Và tạo bản sửa hợp lệ nhưng lý do rỗng.
    Và tạo bản sửa chạm trường Hạn chế, TA2 `:reject` kèm lý do, rồi `POST /dlq/messages/DLQ-A-05:replay` chọn bản sửa đó.
    Thì bước 1 `422` ERR-18-029 nêu đường dẫn trường. Bước 2 `422` ERR-18-007. Bước 3 bản sửa `REJECTED`; phát lại chọn bản bị từ chối trả `409` ERR-18-006 và mục vẫn `TRIAGED`.

  @TC-18-047 @P2 @Dương
  Kịch bản: TC-18-047 Sửa mục POISON bổ sung ngữ cảnh thành TRIAGED rồi phát lại được
    # Truy vết: FR-18-024, 015, 027 · API-18-053, 064 · BR-18-013, 023 · EVT-18-07
    # Mục đích: Chứng minh mục `POISON` chỉ có hai lối ra: sửa (thành `TRIAGED`) hoặc bỏ qua.
    Biết T90; `DLQ-P-01` `POISON` thiếu `stage`.
    Khi IE tạo bản sửa bổ sung `stage = transform`, lý do.
    Và TO phát lại mục dùng bản sửa 1.
    Thì bước 1 `201`, mục `TRIAGED`, EVT-18-07 `from = POISON`. Bước 2 `202`, khóa lũy đẳng `DLQ-P-01:1`.
