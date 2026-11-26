# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-23
Tính năng: TS-05-23 · Sinh bộ điều hợp từ OpenAPI, WSDL

  @TC-05-090 @P2 @Dương
  Kịch bản: TC-05-090 Sinh từ OpenAPI 3.1
    # Truy vết: FR-05-046 · API-05-065 · UI-05-11 · UC-05-13
    Biết U-T68-IE1; F-OAS.
    Thì 10 thao tác: GET → `sideEffect = NONE`, POST → `WRITE`; phân trang phát hiện ở 2 thao tác; cảnh báo `oneOf` cho 2 lược đồ; chuyển UI-05-10, mục R2 chưa có ✓.

  @TC-05-091 @P2 @Dương @Âm
  Kịch bản: TC-05-091 Sinh từ WSDL ZIP; đặc tả hỏng hoặc quá lớn
    # Truy vết: FR-05-046 · API-05-065 · ERR-05-023, 035
    Biết F-WSDL; YAML OpenAPI hỏng ở dòng 40; OpenAPI 6 MiB.
    Thì F-WSDL `200` với thao tác SOAP và XSD nhập kèm. YAML hỏng `422` ERR-05-023 có dòng 40. Tệp 6 MiB `413` ERR-05-035.
