# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-01
Tính năng: TS-12-01 · Danh sách, chi tiết và danh bạ người dùng

  @TC-12-001 @P1 @Dương
  Kịch bản: TC-12-001 Danh sách người dùng có lọc, tìm kiếm, phân trang
    # Truy vết: FR-12-001 · UC-12-01 · UI-12-01 · API-12-001 · NFR-12-008
    Biết U-T68-TA1; 120 người dùng T68 (nạp seed), `ha.nguyen` có ở T01.
    Khi `GET /users?q=ha&trang-thai=ACTIVE&size=20&page=0`.
    Và mở UI-12-01, lọc `mfa=false`, sắp `sap-xep=ngay-tao:giam`, sang trang 2.
    Thì `200`, chỉ người dùng T68, tổng khớp bộ lọc, không có `ha.nguyen` của T01; UI giữ bộ lọc ở URL; p95 ≤ 300 ms.

  @TC-12-002 @P2 @Âm
  Kịch bản: TC-12-002 Người dùng chỉ đọc không thấy nút thao tác
    # Truy vết: FR-12-001 · UI-12-01 · API-12-001 · ERR-12-007 · BR-12-014
    Biết U-T68-VW (chỉ `PERM-12-read`).
    Khi mở UI-12-01.
    Và `POST /users` bằng token của VW.
    Thì danh sách xem được, không có nút "Tạo", "Khóa"; bước 2 trả 403-PQ.

  @TC-12-003 @P1 @Dương
  Kịch bản: TC-12-003 Chi tiết người dùng đủ tab và quyền hiệu lực
    # Truy vết: FR-12-002 · UC-12-01 · UI-12-02 · API-12-002 · LGC-IAM-002
    Biết U-T68-TA1, U-T68-IE.
    Khi `GET /users/{userId}` của IE.
    Và mở UI-12-02, xem các tab Vai trò, Phiên, Yếu tố xác thực, Lịch sử.
    Thì `200`, có `ETag`; trường `mfa` cho biết loại yếu tố, không có giá trị bí mật; mỗi tab tải được.

  @TC-12-004 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-004 Chi tiết người dùng của tenant khác hoặc không có
    # Truy vết: FR-12-002 · API-12-002 · ERR-12-001 · BR-12-041, BR-12-004
    Biết U-T68-TA1; người dùng `tc-chi-t01` chỉ có ở T01.
    Khi `GET /users/khong-co`.
    Và `GET /users/{id-cua-tc-chi-t01}` bằng token T68.
    Và gửi tiêu đề `X-Tenant: T01`.
    Thì cả ba trả `404` ERR-12-001, thân giống nhau trừ `traceId`; tiêu đề tenant bị bỏ qua.

  @TC-12-005 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-005 Vai trò phạm vi tổ chức chỉ thấy người cùng đơn vị
    # Truy vết: FR-12-001 · BR-12-037 · API-12-001, API-12-002 · ERR-12-001
    Biết U-T68-PH07 (vai trò quyền ○, đơn vị `DV-A`); một người dùng ở `DV-B`.
    Khi `GET /users` bằng token PH07.
    Và `GET /users/{id-DV-B}`.
    Thì danh sách chỉ người `DV-A` và đơn vị cấp dưới; bước 2 trả 404-ẩn.

  @TC-12-006 @P1 @Dương @Âm @Bảo
  Kịch bản: TC-12-006 Danh bạ người dùng trả thông tin tối thiểu
    # Truy vết: FR-12-062 · UC-12-42 · API-12-014 · BR-12-042, BR-12-004 · CMP-LAW-05
    Biết S-PH04 (scope `iam:directory-read`); người dùng có thư, điện thoại.
    Khi `GET /directory/users?q=nguyen` bằng token S-PH04.
    Và lặp với token người dùng T01 và với token thiếu scope.
    Thì chỉ có `code`, tên hiển thị, đơn vị, chức danh, trạng thái; không có thư, điện thoại, số định danh; chỉ người dùng tenant của token; token thiếu scope bị `403`.
