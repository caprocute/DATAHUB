# language: vi
# Sinh tự động từ D05-02-PH06 bằng ph06/tools/gen_gherkin.py; không sửa tay.
@PH-06 @TS-06-23
Tính năng: TS-06-23 · Xuất dữ liệu chủ có kiểm soát

  @TC-06-100 @P1 @Dương
  Kịch bản: TC-06-100 Xuất 500 bản ghi có chấp thuận
    # Truy vết: FR-06-049 · BR-06-027 · API-06-073, 074, 075, 076 · UI-06-15 · PERM-06-export
    # Mục đích: Chứng minh đề nghị, chấp thuận bởi DO và DA khác người đề nghị, tệp mã hóa có thủy vân, theo BR-06-027.
    Biết TA đề nghị; DO1, DA1; 500 bản ghi vàng, trường `PUBLIC`, `INTERNAL`.
    Khi `POST .../exports` `CSV`, `fields[]`, 500 bản ghi.
    Và DO1 và DA1 `:approve`.
    Và chờ job `EXPORT`; `GET .../file`.
    Thì `PENDING_APPROVAL` → `APPROVED` → `GENERATING` → `READY`; tệp mã hóa, mật khẩu qua thông báo trong ứng dụng, thủy vân người xuất ở dòng đầu, trường `SENSITIVE` che; hạn tải 24 giờ; mỗi lần tải có `access_log` ghi số bản ghi. KT: có (export-request, approve, download).
    # Hậu điều kiện: Tệp READY hết hạn sau 24 giờ.

  @TC-06-101 @P1 @Âm
  Kịch bản: TC-06-101 Vượt giới hạn, chưa chấp thuận, tự duyệt, tệp hết hạn
    # Truy vết: FR-06-049 · BR-06-027 · API-06-073, 075, 076 · ERR-06-005, 041, 042
    # Mục đích: Chứng minh các chặn của xuất, theo FR-06-049.
    Biết T92 (`06.export.max-rows = 1000`).
    Khi đề nghị xuất 1.001 bản ghi.
    Và tải tệp khi chưa `APPROVED`.
    Và người đề nghị tự `:approve`.
    Và tiến 25 giờ, tải tệp `READY`.
    Thì bước 1 `422` ERR-06-041. Bước 2 `422` ERR-06-041. Bước 3 `403` ERR-06-005. Bước 4 `410` ERR-06-042, tệp đã xóa khỏi Garage.
    # Hậu điều kiện: Tệp EXPIRED.

  @TC-06-102 @P2 @Dương
  Kịch bản: TC-06-102 Xuất nhỏ chỉ trường không nhạy cảm
    # Truy vết: FR-06-049 · BR-06-013, 026 · API-06-073
    # Mục đích: Chứng minh ≤ 100 bản ghi chỉ trường `PUBLIC`, `INTERNAL` cần DA duyệt, theo FR-06-049.
    Biết DA1; 80 bản ghi.
    Khi đề nghị xuất 80 bản ghi trường `PUBLIC`, `INTERNAL`.
    Và đề nghị xuất 80 bản ghi có `idNumber`.
    Thì bước 1 chỉ cần DA1 duyệt. Bước 2 cần cả DO và DA, `idNumber` che trừ khi duyệt rõ.
    # Hậu điều kiện: Một tệp READY.
