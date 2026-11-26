# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-23
Tính năng: TS-01-23 · Đề nghị thay đổi hồ sơ và mở rộng trần phạm vi

  @TC-01-089 @P2 @Dương
  Kịch bản: TC-01-089 Ba mức duyệt của thay đổi hồ sơ
    # Truy vết: FR-01-034 · UC-01-23 · API-01-057, 058, 059 · UI-01-04, 07 · BR-01-025, 029 · EVT-01-04.
    Biết `HT-TUPHAP` ACTIVE; U-T68-OR1; TA1; SO.
    Khi OR1 `POST …/change-requests` đổi mô tả.
    Và OR1 đổi địa chỉ cơ sở và dải IP.
    Và OR1 đổi cấp độ ATTT; TA1 và SO duyệt qua `POST /change-requests/{id}:decide`.
    Và đổi chủ quản sang Văn phòng UBND.
    Thì bước 1: `200`, áp dụng ngay. Bước 2: `202`, chờ duyệt kỹ thuật, `GET …/change-requests` thấy yêu cầu. Bước 3: áp dụng khi cả hai duyệt; `EVT-01-04`. Bước 4: cần tổ chức mới xác nhận rồi TA duyệt.

  @TC-01-090 @P1 @Âm
  Kịch bản: TC-01-090 Thay đổi sai: chồng yêu cầu, qua đường thường để mở rộng, địa chỉ http
    # Truy vết: FR-01-034 · API-01-057 · BR-01-012 · ERR-01-037, 038, 049.
    Biết `HT-TUPHAP` có yêu cầu thay đổi đang chờ; OR1.
    Khi gửi thêm yêu cầu thay đổi khi đang chờ.
    Và gửi thay đổi nhu cầu có thêm một mục `CONSUME` qua đường thay đổi thường.
    Và gửi địa chỉ `http://…`.
    Thì `409` ERR-01-038; `422` ERR-01-037; `422` ERR-01-049.

  @TC-01-091 @P1 @Dương
  Kịch bản: TC-01-091 Mở rộng trần phạm vi: thẩm định lại, trần đổi khi duyệt
    # Truy vết: FR-01-035 · UC-01-24 · API-01-060, 059 · UI-01-04, 06, 07 · BR-01-003, 012 · EVT-01-11.
    Biết `HT-TUPHAP`; mục mở rộng có căn cứ F-PDF-VB; người thẩm định LEGAL được giao; TA duyệt khác người đề nghị.
    Khi OR1 `POST …/scope-expansions`; kiểm trần.
    Và người thẩm định ghi kết luận pháp lý cho mục mới.
    Và TA duyệt.
    Thì bước 1: `202`, trần không đổi. Bước 3: trần tăng đúng mục được chấp thuận, không hơn; `EVT-01-11`. KT: có.

  @TC-01-092 @P1 @Âm @Bảomật
  Kịch bản: TC-01-092 Mở rộng phạm vi sai: thiếu căn cứ, bí mật nhà nước, cấp độ thấp
    # Truy vết: FR-01-035 · API-01-060 · BR-01-001, 004, 026 · ERR-01-015, 016, 038, 047.
    Biết `HT-TUPHAP` cấp độ `L2`; OR1.
    Khi `POST …/scope-expansions` thiếu căn cứ.
    Và mục `BMNN-TEST`.
    Và mục mức Hạn chế khi HTTT `L2`.
    Và gửi khi đã có mở rộng đang chờ.
    Thì `422` ERR-01-015; `422` ERR-01-016; `422` ERR-01-047; `409` ERR-01-038.
