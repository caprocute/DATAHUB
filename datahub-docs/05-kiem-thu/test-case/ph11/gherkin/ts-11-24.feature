# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-24
Tính năng: TS-11-24 · Kiểm toán lịch sử bước, nhật ký phân hệ và bằng chứng tuân thủ BPMN 2.0

  @TC-11-128 @P1 @Dương
  Kịch bản: TC-11-128 Lịch sử bước và xuất bằng chứng
    # Truy vết: FR-11-057 · API-11-105, 106 · BR-11-025, 038 · NFR-11-023 · PERM-11-audit-read
    Biết phiên `HS-26` 50 bước đã hoàn thành; AU.
    Khi AU `GET /instances/{id}/history`
    Và AU `POST /instances/{id}/history:export`
    Và tính lại SHA-256 của tệp
    Thì bước 1 đủ bước, người, thời điểm, biến đã che, ≤ 5 giây. Bước 2 `202`, tệp kèm băm. Bước 3 trùng băm và có tham chiếu chuỗi băm kiểm toán (ADR-031). KT: có.

  @TC-11-129 @P1 @Âm @Bảo @mật
  Kịch bản: TC-11-129 Lịch sử: thiếu quyền, hết lưu giữ
    # Truy vết: FR-11-057 · API-11-105, 106 · ERR-11-001 · ERR-00-403
    Biết VW, TO, TA; phiên đã dọn lịch sử.
    Khi VW `GET /instances/{id}/history`
    Và TO `POST /instances/{id}/history:export`
    Và TA `GET /instances/{id đã hết lưu giữ}/history`
    Thì bước 1 và 2 `403` ERR-00-403. Bước 3 `410` ERR-11-001.

  @TC-11-130 @P1 @Dương @Âm
  Kịch bản: TC-11-130 Bằng chứng tuân thủ BPMN 2.0 và thuyết minh WS-BPEL
    # Truy vết: FR-11-064 · API-11-121, 122, 137 · ERR-11-006, 039 · BR-11-026, 038 · NFR-11-023 · PERM-11-audit-read
    Biết AU; mẫu `MAU_CV631` có bước tự động giả lập, việc tự hoàn thành, một nhánh bù trừ.
    Khi AU `POST /compliance/sample-runs`
    Và AU `GET /compliance/evidence-packs/{id}`
    Và AU gọi với khoảng thống kê 13 tháng
    Và AU `GET /compliance/sample-runs`; tải gói chưa dựng xong
    Và VW gọi `POST /compliance/sample-runs`
    Thì bước 1 `202`, gói ≤ 2 phút; gói PDF và JSON có băm, XML mẫu, `instanceId`, lịch sử bước, danh sách phần tử BPMN 2.0 đã chạy, phiên bản Flowable, thuyết minh WS-BPEL. Bước 3 `422` ERR-11-039. Bước 4 danh sách lần chạy mẫu, gói chưa xong `409` ERR-11-006. Bước 5 `403` ERR-00-403.

  @TC-11-131 @P1 @Dương @Âm
  Kịch bản: TC-11-131 Nhật ký kiểm toán phân hệ
    # Truy vết: FR-11-065 · API-11-123 · ERR-11-003, 039 · EVT-11-21 · BR-11-038 · PERM-11-audit-read
    Biết các thao tác của các ca trước (phát hành, hủy, sửa biến, bỏ qua bù trừ); AU, VW.
    Khi AU `GET /audit-logs?from&to&actor=TA&action=instance.cancel`
    Và AU `GET /audit-logs?size=1000`
    Và AU `GET /audit-logs` khoảng 400 ngày
    Và VW `GET /audit-logs`
    Thì bước 1 trả đúng bản ghi, có `traceId`, tham chiếu chuỗi băm, không có giá trị biến. Bước 2 `400` ERR-11-003. Bước 3 `403` ERR-00-403. Bước 4 `422` ERR-11-039. Mỗi bản ghi có EVT: `audit.recorded` (`action`, `objectType`, `objectId`, `actor`, `traceId`, `hashRef`, không giá trị biến).

  @TC-11-171 @P2 @Dương @Âm
  Kịch bản: TC-11-171 Xuất CSV phiên, Saga và nhật ký kiểm toán
    # Truy vết: FR-11-021, 052, 065 · API-11-128, 129, 130 · ERR-11-039 · EVT-11-21 · PERM-11-read, PERM-11-audit-read
    Biết 20 phiên, các Saga của TS-11-19; TO, AU, VW.
    Khi TO `POST /instances:export` lọc `status=RUNNING`
    Và TO `POST /sagas:export`
    Và AU `POST /audit-logs:export` khoảng 30 ngày, rồi khoảng 400 ngày
    Và VW `POST /audit-logs:export`
    Thì bước 1, 2 `202`, tệp CSV có băm, đúng số dòng lọc, không giá trị `SENSITIVE`. Bước 3 `202`, KT: có; khoảng 400 ngày `422` ERR-11-039 "Khoảng thời gian tối đa 366 ngày." Bước 4 `403` ERR-00-403.
