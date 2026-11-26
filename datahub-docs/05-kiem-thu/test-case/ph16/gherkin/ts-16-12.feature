# language: vi
# Sinh tự động từ D05-02-PH16 bằng ph16/tools/gen_gherkin.py; không sửa tay.
@PH-16 @TS-16-12
Tính năng: TS-16-12 · Quản lý mẫu báo cáo

  @TC-16-052 @P1 @Dương
  Kịch bản: TC-16-052 Tạo mẫu báo cáo, sửa có phiên bản và xem thử
    # Truy vết: FR-16-025 · API-16-060, 062, 063, 059, 061 · UI-16-13 · BR-16-027
    Biết T90; U-T90-TA1; kỳ `M-2026-10` đã tính.
    Khi `POST /report-templates` `{templateCode: tc-thang-ngan, name: "Báo cáo tháng ngắn", reportType: PERIODIC, periodTypes: [MONTH], sections: [{type: SUMMARY}, {type: GROUP, groupCode: KET_NOI}, {type: INDICATOR_TABLE, indicatorCodes: [httt-ket-noi-ty-le, mttd]}, {type: CHART, chartType: "line"}, {type: NARRATIVE}], formats: [PDF, XLSX], letterhead: {issuer: "UBND tỉnh T90", formNo: "BC-CT/01", recipients: "Bộ Khoa học và Công nghệ"}}`
    Và `POST /report-templates/tc-thang-ngan:preview` `{periodCode: M-2026-10}`
    Và `PATCH /report-templates/tc-thang-ngan` thêm phần `ANNEX` kèm `If-Match`
    Và `GET /report-templates/tc-thang-ngan`
    Thì bước 1 `201`, `state = ACTIVE`, `version = 1`. Bước 2 `200`, `previewUrl`, `expiresAt`; bản xem thử có tên cơ quan, số ký hiệu, nơi nhận theo thể thức NĐ 30/2020. Bước 3 `version = 2`; báo cáo đã lập từ bản 1 giữ bố cục cũ.

  @TC-16-053 @P1 @Âm
  Kịch bản: TC-16-053 Mẫu không hợp lệ hoặc mã trùng
    # Truy vết: FR-16-025 · API-16-060, 062, 063 · ERR-16-027, ERR-16-002
    Biết mẫu `tc-thang-ngan` đã có.
    Khi `POST /report-templates` với phần `INDICATOR_TABLE` chứa `khong-co-ma`
    Và `POST /report-templates` với `formats = []`
    Và `POST /report-templates` lại `templateCode = tc-thang-ngan`
    Và `POST …:preview` cho kỳ chưa tính
    Và U-T90-TO1 `POST /report-templates`
    Thì bước 1, 2 `422` ERR-16-027. Bước 3 `409` ERR-16-002. Bước 4 `422` ERR-16-027 hoặc xem thử với số trống. Bước 5 `403` ERR-00-403 (TO không có `PERM-16-admin`).
