# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-08
Tính năng: TS-14-08 · Bảng định tuyến

  @TC-14-021 @P1 @Dương
  Kịch bản: TC-14-021 Tạo luật, mô phỏng, gửi duyệt và duyệt
    # Truy vết: FR-14-012, 013 · API-14-024, 025, 027, 028 · UI-14-07, 17 · UC-14-08 · BR-14-022.
    Biết U-T68-IE, U-T68-IA; `hotich-tra-cuu` có hai đích: `ndxp` (ưu tiên 10), dự phòng `ndxp-moi` (ưu tiên 20).
    Khi `POST /routing-rules` điều kiện dịch vụ = `hotich-tra-cuu`, đích `ndxp`, dự phòng `ndxp-moi`.
    Và `POST /routing-rules:simulate` với dịch vụ và HTTT mẫu.
    Và IE gửi duyệt; U-T68-IA `POST /routing-rules/{ruleId}:approve`; `GET /routing-rules`.
    Thì mô phỏng trả đúng đích và lý do khớp; luật chưa duyệt chưa có hiệu lực; sau duyệt có hiệu lực ≤ 30 giây.

  @TC-14-022 @P1 @Âm
  Kịch bản: TC-14-022 Luật trùng, đích chưa hoạt động, dự phòng không hợp lệ
    # Truy vết: FR-14-013 · API-14-025, 026 · ERR-14-013, 014, 015, 007 · BR-14-023.
    Biết U-T68-IE; luật hiện có; dịch vụ đích `DRAFT`; dịch vụ ghi `hotich-dang-ky`; dịch vụ khác nhóm dữ liệu.
    Khi tạo luật trùng điều kiện và ưu tiên.
    Và tạo luật đích là dịch vụ chưa hoạt động.
    Và tạo luật dự phòng cho thao tác ghi; rồi dự phòng khác nhóm dữ liệu.
    Và U-T68-IE (người đề nghị) tự duyệt luật.
    Thì bước 1 `409` ERR-14-013; bước 2 `422` ERR-14-014; bước 3 `422` ERR-14-015 hai lần; bước 4 `403` ERR-14-007.
