# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-09
Tính năng: TS-05-09 · Nhập kết nối từ hệ cũ

  @TC-05-035 @P1 @Dương
  Kịch bản: TC-05-035 Phân tích gói Bus cũ ra đề xuất kết nối
    # Truy vết: FR-05-018 · API-05-028, 029 · UI-05-06 · BR-05-025 · UC-05-11 · LGC-BUS-040
    Biết U-T68-IE1; F-CTX.
    Khi tải F-CTX ở UI-05-06.
    Và chờ `CMP-JobProgress` xong; `GET /connections/legacy-imports/{jobId}`.
    Thì `proposals` có 6 kết nối (HTTP, SOAP, JDBC, SFTP, JMS) với tham số tìm được và vị trí trong tệp; `findings` có 2 mục `INLINE_PASSWORD_URI` (chỉ vị trí, không giá trị) và 1 `UNKNOWN_SCHEME` (`jt400`). Chuỗi mật khẩu trong F-CTX không có ở phản hồi, log, bảng `legacy_import_job`. Tệp gốc không còn ở kho sau khi phân tích.

  @TC-05-036 @P2 @Dương
  Kịch bản: TC-05-036 Tạo kết nối nháp từ đề xuất và tải bảng ánh xạ
    # Truy vết: FR-05-018 · API-05-030 · UI-05-06
    Biết kết quả TC-05-035.
    Thì `200`, 5 kết nối `DRAFT`, chưa có bí mật; `connectionMap` (URI cũ → mã mới) tải được cho FR-04-082.

  @TC-05-037 @P2 @Âm
  Kịch bản: TC-05-037 Tệp sai định dạng, quá lớn, có mã độc
    # Truy vết: FR-05-018 · API-05-028 · ERR-05-024, 034
    Biết U-T68-IE1; tệp `.xml` hỏng; ZIP 21 MiB (trần 20 MiB); F-EICAR trong ZIP.
    Thì hỏng `400` ERR-05-024; quá lớn `413` ERR-05-024; mã độc `422` ERR-05-034. Không job nào ở trạng thái thành công.
