# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-05
Tính năng: TS-01-05 · Quản lý đầu mối liên hệ

  @TC-01-023 @P1 @Dương
  Kịch bản: TC-01-023 Thêm, sửa, thay thế đầu mối
    # Truy vết: FR-01-008 · UC-01-05 · API-01-014, 015, 016 · UI-01-04 · EVT-01-13 · BR-01-025.
    Biết U-T68-OR1; `HT-HOTICH`; thư `phuc@sotuphap.gov.vn`.
    Khi `POST …/contacts` loại `TECHNICAL`; `POST` loại `SECURITY`; `GET …/contacts`.
    Và `PATCH …/contacts/{contactId}` đổi chức vụ.
    Và `POST …/contacts` loại `TECHNICAL` với `replaceContactId` trỏ đầu mối cũ.
    Thì `201`, `200`, `200`. Có đúng một đầu mối kỹ thuật hoạt động sau bước 3, đầu mối cũ ở trạng thái không hoạt động. EVT: `EVT-01-13` mỗi thay đổi, chỉ có mã HTTT và loại, không có họ tên, thư, số điện thoại. KT: có.

  @TC-01-024 @P1 @Âm
  Kịch bản: TC-01-024 Thư ngoài miền công vụ, dữ liệu sai
    # Truy vết: FR-01-008 · API-01-015, 016 · BR-01-028 · ERR-01-011, 003.
    Biết U-T68-OR1; `contact.allowedEmailDomains = ["gov.vn"]`.
    Khi `POST …/contacts` với thư `phuc@gmail.com`.
    Và `POST …/contacts` thiếu số điện thoại.
    Và đặt `T90` cho phép `["gov.vn", "tuphap.vn"]`; thêm thư `a@tuphap.vn`.
    Thì `422` ERR-01-011; `400` ERR-01-003; bước 3 ở T90 `201`.

  @TC-01-025 @P1 @Âm
  Kịch bản: TC-01-025 Không bỏ đầu mối kỹ thuật cuối cùng
    # Truy vết: FR-01-008 · API-01-017 · BR-01-013 · ERR-01-050.
    Biết U-T68-OR1; `HT-TUPHAP` có đúng một đầu mối kỹ thuật.
    Khi `DELETE …/contacts/{contactId}` của đầu mối kỹ thuật duy nhất.
    Và thêm đầu mối kỹ thuật thứ hai rồi `DELETE` đầu mối đầu.
    Thì bước 1: `409` ERR-01-050. Bước 2: `204`.

  @TC-01-026 @P2 @Dương @Bảomật
  Kịch bản: TC-01-026 Đầu mối của HTTT đã kết nạp sửa được không cần duyệt; đầu mối an ninh ẩn
    # Truy vết: FR-01-008 · API-01-014, 016 · BR-01-025, 027 · UI-01-04.
    Biết U-T68-OR1; U-T68-VW; `HT-TUPHAP` ACTIVE có đầu mối `SECURITY`.
    Khi OR1 sửa số điện thoại đầu mối của `HT-TUPHAP`.
    Và VW và SO gọi `GET …/contacts`.
    Thì bước 1: `200`, không tạo yêu cầu duyệt. Bước 2: VW không thấy đầu mối `SECURITY`; SO thấy.
