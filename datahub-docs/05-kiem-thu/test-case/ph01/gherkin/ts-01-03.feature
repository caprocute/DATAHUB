# language: vi
# Sinh tự động từ D05-02-PH01 bằng ph01/tools/gen_gherkin.py; không sửa tay.
@PH-01 @TS-01-03
Tính năng: TS-01-03 · Hồ sơ năng lực kỹ thuật và đề xuất nhóm HTTT

  @TC-01-014 @P1 @Dương
  Kịch bản: TC-01-014 Bảng quy tắc đề xuất nhóm (tham số hóa)
    # Truy vết: FR-01-006 · UC-01-03 · API-01-010, 011 · UI-01-01.
    Biết U-T68-OR1; `HT-HOTICH` DRAFT.
    Khi `PUT /systems/HT-HOTICH/technical-profile` lần lượt với năm tổ hợp: (a) `replacementPlanned=true`; (b) `hasApi=true`, `apiSpecKind=OPENAPI`, `underMaintenance=true`; (c) `hasApi=true`, `apiSpecKind=WSDL`; (d) `hasApi=false`, `dbType=ORACLE`, `cdcLogEnabled=UNKNOWN`; (e) `hasApi=false`, `dbType=NONE`.
    Thì `proposedGroup` lần lượt là 4, 1, 2, 3 và `null`; (a) thắng khi trùng với (b) (thứ tự 1); mỗi lần có `explanation[]` nêu điều kiện đã dùng; `confirmedGroup` rỗng. (e) có lựa chọn "Đề nghị khảo sát trực tiếp", không chặn nộp. KT: có (tóm tắt).

  @TC-01-015 @P1 @Âm
  Kịch bản: TC-01-015 Nhóm 3 thiếu loại CSDL, số kết nối đồng thời sai
    # Truy vết: FR-01-006 · API-01-010 · ERR-01-003.
    Biết U-T68-OR1.
    Khi `PUT …/technical-profile` với `hasApi=false` và không có `dbType`.
    Và gửi `maxConcurrentConnections = 0`, rồi `1.5`.
    Thì cả ba `400` ERR-01-003, thông báo nêu cách khắc phục theo FRS; hồ sơ kỹ thuật cũ không đổi.

  @TC-01-016 @P2 @Dương @Âm
  Kịch bản: TC-01-016 Xem hồ sơ kỹ thuật, quyền và trạng thái
    # Truy vết: FR-01-006 · API-01-010, 011 · ERR-01-005, 052.
    Biết U-T68-OR1; U-T68-VW; `HT-HOTICH-SS` SUBMITTED.
    Khi U-T68-VW `GET …/technical-profile` của `HT-HOTICH`; rồi `PUT`.
    Và U-T68-OR1 `PUT` vào `HT-HOTICH-SS`.
    Thì `GET` `200` có `proposedGroup`; `PUT` của VW `403-PQ`; `PUT` vào hồ sơ đã nộp `409` ERR-01-005.
