# language: vi
# Sinh tự động từ D05-02-PH18 bằng ph18/tools/gen_gherkin.py; không sửa tay.
@PH-18 @TS-18-20
Tính năng: TS-18-20 · Soạn, kiểm trường cấm và duyệt mẫu thông báo

  @TC-18-068 @P1 @Dương
  Kịch bản: TC-18-068 Tạo mẫu thư, soạn phiên bản, dựng thử, gửi duyệt và người thứ hai duyệt
    # Truy vết: FR-18-035 · API-18-082, 083, 084, 085, 086, 087, 088 · BR-18-027 · UI-18-11, 12, 15
    # Mục đích: Chứng minh vòng đời `DRAFT → IN_REVIEW → ACTIVE`, phiên bản cũ thành `RETIRED` khi phiên bản mới có hiệu lực, thư chỉ mang liên kết về hệ thống.
    Biết T90; U-T90-TA1 (`PERM-18-template`), U-T90-TA2 (`PERM-18-approve`); biến khai báo `{{tenHttt}}` (Công khai), `{{lienKet}}`.
    Khi TA1 `POST /notification-templates` `TPL-ONB-MAIL` kênh `EMAIL`, chủ PH-01.
    Và TA1 tạo phiên bản 1 có tiêu đề, thân dùng hai biến.
    Và TA1 `:preview` với dữ liệu mẫu.
    Và TA1 `:submit`; TA2 `:approve`.
    Và TA1 tạo, gửi phiên bản 2; TA2 duyệt.
    Thì bước 3 `200` bản dựng, kiểm trường cấm đạt. Bước 4 phiên bản 1 `ACTIVE`. Bước 5 phiên bản 2 `ACTIVE`, phiên bản 1 `RETIRED`. Mỗi lần chuyển có kiểm toán; thân thư dựng thử chỉ có tên HTTT và liên kết.

  @TC-18-069 @P1 @Âm @Bảo_mật
  Kịch bản: TC-18-069 Mẫu dùng biến mức Hạn chế, biến chưa rõ mức, cú pháp sai, người soạn tự duyệt
    # Truy vết: FR-18-035 · API-18-085, 086, 087, 088 · BR-18-027 · ERR-18-005, 039, 040
    # Mục đích: Chứng minh BR-18-027 và FR-00-062: kiểm trường cấm chạy khi dựng thử và khi gửi duyệt; bốn mắt mẫu không có đường vòng.
    Biết T90; WireMock PH-09 xếp `{{soCccd}}` mức Nhạy cảm, `{{diaChi}}` mức Hạn chế, `{{ghiChuNoiBo}}` chưa xác định mức.
    Khi TA1 tạo phiên bản có `{{soCccd}}`, `:preview`.
    Và TA1 tạo phiên bản có `{{ghiChuNoiBo}}`, `:submit`.
    Và TA1 tạo phiên bản có `{{#ds}}` không đóng.
    Và TA1 tạo phiên bản hợp lệ, gửi duyệt, tự `:approve`.
    Thì bước 1 `422` ERR-18-039 nêu biến và mức. Bước 2 `422` ERR-18-039 (chưa xác định mức coi như cấm). Bước 3 `422` ERR-18-040 nêu dòng. Bước 4 `403` ERR-18-005.

  @TC-18-070 @P2 @Âm @Dương
  Kịch bản: TC-18-070 Ngừng mẫu, trả phiên bản về nháp và gửi bằng mẫu đã ngừng
    # Truy vết: FR-18-035, 036 · API-18-089, 090, 091 · ERR-18-041
    # Mục đích: Chứng minh `:reject` trả về `DRAFT` kèm lý do và mẫu `RETIRED` không gửi được.
    Biết T90; `TPL-OLD` `ACTIVE`; `TPL-ONB-MAIL` phiên bản 3 `IN_REVIEW`; S-PH01 (`ops:notify`).
    Khi TA2 `:reject` phiên bản 3 kèm lý do.
    Và TA1 `POST /notification-templates/TPL-OLD:retire`.
    Và S-PH01 gửi bằng `TPL-OLD`.
    Thì bước 1 phiên bản 3 `DRAFT`, lý do hiện ở UI-18-12. Bước 2 `RETIRED`. Bước 3 `409` ERR-18-041.
