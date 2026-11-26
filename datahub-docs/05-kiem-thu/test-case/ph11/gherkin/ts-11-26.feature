# language: vi
# Sinh tự động từ D05-02-PH11 bằng ph11/tools/gen_gherkin.py; không sửa tay.
@PH-11 @TS-11-26
Tính năng: TS-11-26 · Phân quyền theo ma trận PERM-11 và bốn mắt

  @TC-11-137 @P1 @Âm @Bảo @mật
  Kịch bản: TC-11-137 Ma trận quyền: mọi API, mọi vai trò
    # Truy vết: API-11-001…127 · ERR-00-403, 401 · NFR-11-020 · PERM-11-read, PERM-11-model, PERM-11-publish, PERM-11-instance, PERM-11-instance-admin, PERM-11-task-admin, PERM-11-compensate, PERM-11-config, PERM-11-audit-read
    # Mục đích: Chứng minh mỗi API trả `200` cho vai trò được phép và `403` hoặc `401` cho vai trò khác, 100 % API có ca âm.
    Biết mười chủ thể: PA, PO, TA, TO, IE, IA, AU, VW, CB, không vai trò; bảng kỳ vọng sinh từ `x-datahub-permission` của `openapi-bpm.yaml` và ma trận FRS 3.2.
    Khi sinh ca từ OpenAPI: mỗi cặp (API, chủ thể) một lệnh gọi
    Và so mã trả về với kỳ vọng
    Và gọi mỗi API không token, token hết hạn, token sai tenant
    Thì không lệch ma trận; `403` thân RFC 9457 có `code = ERR-00-403`, `traceId`; không token `401` ERR-00-401; không có API nào thiếu ca âm.

  @TC-11-138 @P1 @Âm @Bảo @mật
  Kịch bản: TC-11-138 Bốn mắt ở mọi điểm bắt buộc
    # Truy vết: FR-11-008, 009, 014, 025, 026, 027, 053, 015 · ERR-11-005 · BR-11-004, 020, 021 · NFR-11-020
    # Mục đích: Chứng minh người gửi, người đề nghị không tự duyệt ở sáu điểm bốn mắt, kể cả TA có cả hai quyền.
    Biết TA có cả quyền soạn lẫn duyệt (SIT); TA2, IE1, IE2, IA1; sáu đối tượng chờ duyệt: bản phát hành, miễn bù trừ, sửa biến, chuyển bước, di trú, bỏ qua bước bù trừ, mẫu `COMMON`.
    Khi với từng đối tượng: người đề nghị tự duyệt
    Và người sửa cuối tự duyệt (bản phát hành)
    Và người khác có quyền duyệt
    Và đọc KT của hai người
    Thì hai lần đầu `403` ERR-11-005 ở cả bảy điểm; người khác duyệt được `200`; kiểm toán ghi cả hai người, lý do, thời điểm.

  @TC-11-139 @P1 @Âm @Bảo @mật
  Kịch bản: TC-11-139 Phạm vi của tài khoản máy
    # Truy vết: FR-11-018, 035, 055, 028 · API-11-049, 104, 072, 051 · ERR-11-020, 034 · NFR-11-020
    # Mục đích: Chứng minh scope máy chỉ làm đúng việc được cấp.
    Biết S-DVC, S-DVC2, S-MC, S-PH04, S-PH01.
    Khi S-DVC gọi `GET /models`, `POST /tasks/{id}:complete`
    Và S-MC gọi `GET /tasks`, đọc biến `SENSITIVE`
    Và S-PH04 gọi API REST bất kỳ
    Và S-DVC `GET /instances/{id}` của phiên do client khác khởi tạo
    Và S-DVC2 khởi tạo `M-KS`
    Thì bước 1 `403` ERR-00-403. Bước 2 có danh sách, không có biến `SENSITIVE`. Bước 3 `403` (chỉ dùng Kafka). Bước 4 `403` ERR-11-034. Bước 5 `403` ERR-11-020.
