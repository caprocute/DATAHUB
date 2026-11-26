# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-08
Tính năng: TS-02-08 · Backend, cân bằng tải và sức khỏe

  @TC-02-028 @P1 @Dương
  Kịch bản: TC-02-028 Khai báo hai backend, đặt trọng số và kiểm tra sức khỏe
    # Truy vết: FR-02-022, 023, 025 · API-02-026, 027, 028, 031 · UI-02-02 · UC-02-11 · BR-02-024 · LGC-APIM-018.
    Biết A-DRAFT; hai kết nối PH-05 cùng tenant.
    Khi `POST …/backends` hai lần, trọng số 70 và 30.
    Và `PATCH` thời gian chờ 5.000 ms, thử lại 2, kiểm tra sức khỏe `/health`.
    Và `GET …/backends/health`.
    Thì `201/202`, `200`; sức khỏe từng backend hiển thị; tổng trọng số lớn hơn 0.

  @TC-02-029 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-029 Backend trỏ tới địa chỉ cấm, TLS thấp, ngoài danh sách cho phép
    # Truy vết: FR-02-022 · API-02-027 · BR-02-023 · ERR-02-020 · NFR-02-011.
    Biết đích: `http://127.0.0.1`, `https://169.254.169.254`, `https://dh-control.svc`, host TLS 1.0, kết nối của T01.
    Khi khai báo lần lượt từng đích.
    Thì mọi lần `422` ERR-02-020; không có bản ghi backend nào được tạo; log không chứa nội dung phản hồi từ đích.

  @TC-02-030 @P2 @Biên @Âm
  Kịch bản: TC-02-030 Giới hạn số backend, trần thời gian chờ, xóa backend cuối
    # Truy vết: FR-02-023, 022 · API-02-027, 028, 029 · BR-02-024 · ERR-02-040, 021, 003.
    Biết `02.backend.max-per-version` = 10, `02.backend.max-timeout-ms` = 60.000.
    Khi thêm backend thứ 11; đặt timeout 120.000 ms.
    Và đặt tổng trọng số 0; xóa backend `ACTIVE` cuối cùng rồi gửi duyệt.
    Thì bước 1: `422` ERR-02-040. Bước 2: không gửi duyệt được, `422` ERR-02-021.

  @TC-02-031 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-031 Backend của tenant khác và phiên bản không thuộc tổ chức
    # Truy vết: FR-02-022, 025 · API-02-026, 027, 031 · BR-02-032, 033 · ERR-02-001, 014.
    Biết A-T01; U-T68-SV2.
    Khi U-T68-SV2 gọi `POST …/tc-dat-dai/…/backends`.
    Và người dùng T68 gọi `GET /apis/tc-chi-t01/versions/1.0.0/backends/health`.
    Thì bước 1: 403-PQ. Bước 2: 404-ẩn.

  @TC-02-100 @P1 @Âm @Bảo @mật
  Kịch bản: TC-02-100 Backend trỏ tới kết nối hoặc luồng của tenant khác, hoặc không đúng loại
    # Truy vết: FR-02-022 · API-02-027, 028, 032 · UI-02-02 · UC-02-11 · BR-02-023, 033 · ERR-02-020, 001 · SEC-16.
    Biết kết nối `tc-kn-t68` (PH-05, T68), `tc-kn-t01` (T01); luồng `tc-luong-t68`, `tc-luong-t01`; A-DRAFT.
    Khi `POST …/backends` đích kết nối `tc-kn-t68`, rồi luồng `tc-luong-t68`.
    Và lặp với `tc-kn-t01` và `tc-luong-t01`.
    Và `PATCH` backend hợp lệ sang đích `tc-kn-t01`.
    Và đích là kết nối đã ngừng dùng ở PH-05.
    Thì bước 1: `201`. Bước 2, 3, 4: `422` ERR-02-020, thông báo chung không nói đối tượng có tồn tại ở tenant khác hay không; backend cũ không đổi.

  @TC-02-101 @P2 @Dương @Âm
  Kịch bản: TC-02-101 Sức khỏe backend: tenant khác, trạng thái từng backend, dịch vụ phụ thuộc sự cố
    # Truy vết: FR-02-025 · API-02-031 · UI-02-02 · UC-02-11 · BR-02-033 · ERR-02-001, 034.
    Biết A-DATDAI có hai backend, một chạy, một tắt; A-T01; U-T68-VW.
    Khi U-T68-VW `GET …/backends/health`.
    Và `GET /apis/tc-chi-t01/versions/1.0.0/backends/health`.
    Và làm PH-03 (nguồn số liệu sức khỏe) không phản hồi rồi gọi lại.
    Thì bước 1: `200`, backend chạy `UP`, backend tắt `DOWN` kèm thời điểm kiểm tra gần nhất. Bước 2: `404` ERR-02-001. Bước 3: `503` ERR-02-034 kèm `retryAfterSeconds`; UI-02-02 hiện thẻ "chưa lấy được dữ liệu", không hiện `UP` giả.

  @TC-02-102 @P2 @Biên @Âm
  Kịch bản: TC-02-102 Trọng số backend: tổng bằng 0, âm, và xóa backend khiến hết trọng số
    # Truy vết: FR-02-022, 023 · API-02-028, 029, 042 · UI-02-02 · UC-02-11 · BR-02-024 · ERR-02-003, 012.
    Biết A-DRAFT có hai backend trọng số 50 và 50; U-T68-SV1.
    Khi `PATCH` trọng số `-1`; rồi `101` (giả định miền hợp lệ 0…100, cơ sở: mẫu `weight: 100` ở D03-04-PH02).
    Và đặt cả hai trọng số `0`; sau đó `POST …:submit`.
    Và đặt `100` và `0`; `POST …:submit`.
    Thì bước 1: `400` ERR-02-003. Bước 2: cho phép lưu nháp nhưng `:submit` trả `409` ERR-02-012 với `missing[]` có `NO_ACTIVE_BACKEND`. Bước 3: đủ điều kiện (tổng trọng số > 0), `:submit` qua điều kiện này.
