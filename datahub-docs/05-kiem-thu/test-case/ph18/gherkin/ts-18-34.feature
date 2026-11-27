# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-34
Tính năng: TS-18-34 · Khai báo nguồn hệ cũ và lập kế hoạch di trú

  @TC-18-112 @P1 @Dương
  Kịch bản: TC-18-112 Khai báo nguồn Aita bằng tham chiếu OpenBao và thử kết nối chỉ đọc
    # Truy vết: FR-18-059 · API-18-156, 157, 158 · BR-18-040, 048 · UI-18-21
    # Mục đích: Chứng minh FR-18-059: thông tin kết nối chỉ là tham chiếu `kv/dh/t96/legacy/aita`, thử kết nối kiểm quyền `SELECT` và đếm bảng.
    Biết T96; PostgreSQL giả lập hệ cũ `LEG-AITA` có tài khoản chỉ đọc; OpenBao dev có khóa tại `kv/dh/t96/legacy/aita`; U-T96-TA1 (`PERM-18-migration`).
    Khi `POST /legacy-sources` `LEG-AITA`, JDBC, `credentialRef = kv/dh/t96/legacy/aita`.
    Và `POST /legacy-sources/LEG-AITA:test-connection`.
    Và `GET /legacy-sources`.
    Thì bước 1 `201`, không lưu giá trị bí mật trong `ph18_ops`. Bước 2 `200` `readOnly = true`, số bảng. Bước 3 trạng thái kết nối `OK`.

  @TC-18-113 @P1 @Âm @Bảo_mật
  Kịch bản: TC-18-113 Nhập thẳng thông tin đăng nhập, tài khoản có quyền ghi, nguồn không kết nối được
    # Truy vết: FR-18-059 · API-18-157, 158 · BR-18-040, 048 · ERR-18-062, 070
    # Mục đích: Chứng minh BR-18-040, 048: không nhận bí mật dạng rõ và không dùng tài khoản có quyền ghi.
    Biết T96; `LEG-RW` có tài khoản có quyền `INSERT`; `LEG-DOWN` địa chỉ không mở.
    Khi khai nguồn với trường thông tin đăng nhập dạng chữ rõ thay cho tham chiếu kho bí mật.
    Và khai `LEG-RW` bằng tham chiếu, `:test-connection`.
    Và `:test-connection` cho `LEG-DOWN`.
    Thì bước 1 `422` ERR-18-070, không có bản ghi, log không chứa chuỗi đã gửi. Bước 2 `422` ERR-18-062 nêu quyền thừa. Bước 3 `422` ERR-18-062 nêu lỗi kết nối.

  @TC-18-114 @P1 @Dương @Âm
  Kịch bản: TC-18-114 Lập kế hoạch theo thứ tự phụ thuộc, phụ thuộc vòng bị chặn
    # Truy vết: FR-18-060 · API-18-159, 160, 161, 162, 163 · BR-18-040 · ERR-18-003, 063 · UI-18-21
    # Mục đích: Chứng minh FR-18-060: danh mục Aita → PH-07 đứng trước HTTT → PH-01 và API → PH-02; phụ thuộc vòng hoặc thiếu tiền đề bị từ chối khi `:mark-ready`.
    Biết T96; `LEG-AITA`; U-T96-TA1.
    Khi `POST /migration-plans` `PLAN-AITA`.
    Và `PUT /migration-plans/PLAN-AITA/items` với `CATALOG → PH-07`, `APPLICATION → PH-01`, `API → PH-02` và phụ thuộc đúng.
    Và `:mark-ready`.
    Và tạo `PLAN-VONG` có `API` phụ thuộc `APPLICATION` và ngược lại, `:mark-ready`; tạo kế hoạch có loại đối tượng `XYZ`.
    Thì bước 3 `200` `READY`, thứ tự chạy hiện ở UI-18-21. Bước 4 `422` ERR-18-063 liệt kê vòng; loại lạ `400` ERR-18-003.
