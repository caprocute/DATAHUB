# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-05
Tính năng: TS-12-05 · Nhập người dùng hàng loạt và ánh xạ vai trò hệ cũ

  @TC-12-023 @P1 @Dương
  Kịch bản: TC-12-023 Nhập tệp hợp lệ qua hai pha
    # Truy vết: FR-12-009 · UC-12-05 · UI-12-04 · API-12-010, 011, 012 · BR-12-043 · LGC-IAM-002
    Biết U-T68-TA1; F-USR-OK.
    Khi tải tệp ở bước 1 UI-12-04; xem kết quả kiểm tra.
    Và `POST /user-imports/{id}:commit`.
    Thì sau kiểm tra chưa có tài khoản nào; sau commit 20 tài khoản `PENDING_ACTIVATION` và thư kích hoạt gửi đi; KT: có (user.import).

  @TC-12-024 @P1 @Âm
  Kịch bản: TC-12-024 Tệp có dòng lỗi: báo từng dòng, chỉ nhập dòng đạt
    # Truy vết: FR-12-009 · API-12-011, 012 · BR-12-043 · ERR-12-002, ERR-12-004, ERR-12-005
    Biết F-USR-BAD.
    Khi tải tệp; đọc kết quả; commit.
    Thì ba dòng lỗi có số dòng và mã lỗi (trùng tên, đơn vị hết hiệu lực, thư ngoài miền); commit chỉ tạo 17 tài khoản (hoặc từ chối nếu tham số "tất cả hoặc không" bật).

  @TC-12-025 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-025 Tệp có cột mật khẩu, quá lớn, sai định dạng
    # Truy vết: FR-12-009 · API-12-010 · BR-12-043 · ERR-12-035 · BR-12-045
    Biết F-USR-PWD, F-USR-BIG, tệp `.exe` đổi đuôi `.csv`.
    Khi tải lần lượt ba tệp.
    Thì F-USR-PWD bị từ chối vì có mật khẩu; F-USR-BIG `413`; tệp sai định dạng `400` ERR-12-035; giá trị mật khẩu trong tệp không xuất hiện ở log.

  @TC-12-026 @P2 @Âm
  Kịch bản: TC-12-026 Vai trò hệ cũ chưa có ánh xạ
    # Truy vết: FR-12-009 · API-12-011 · ERR-12-036 · LGC-IAM-002 · BR-12-029
    Biết F-USR-LGC (2 vai trò lạ).
    Khi tải tệp; xem kết quả; bổ sung ánh xạ ở bước 3 của UI-12-04; tải lại.
    Thì lần đầu ERR-12-036 nêu vai trò chưa ánh xạ; sau khi ánh xạ, vai trò hệ cũ được đề xuất, không tự gán vai trò đặc quyền.
