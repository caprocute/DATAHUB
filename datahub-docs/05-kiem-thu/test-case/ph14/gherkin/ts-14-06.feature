# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-06
Tính năng: TS-14-06 · Đối chiếu danh mục dịch vụ với NDXP

  @TC-14-017 @P1 @Dương
  Kịch bản: TC-14-017 Chạy đối chiếu, xem đề xuất và áp dụng
    # Truy vết: FR-14-007 · API-14-014, 015, 016, 017 · UI-14-06 · UC-14-06 · BR-14-024.
    Biết U-T68-IE; `sim-ndxp` trả danh mục thiếu một dịch vụ, đổi đặc tả một dịch vụ, thêm một dịch vụ mới.
    Khi `POST /service-reconciliations`; chờ xong; `GET …/{runId}`.
    Và `POST …/{runId}:apply` chỉ cho dịch vụ "Đổi đặc tả".
    Và `POST /services/{serviceCode}:set-label` đặt `UNKNOWN`.
    Thì đề xuất `STILL`, `SPEC_CHANGED`, `DISCONTINUED`, thêm mới; "Đổi đặc tả" chỉ sửa bộ điều hợp, giữ hợp đồng cung cấp lại; dịch vụ ngừng chuyển `DEPRECATED` hoặc `RETIRED` theo nhãn; nhãn tay ghi kiểm toán.

  @TC-14-018 @P2 @Âm
  Kịch bản: TC-14-018 Đối chiếu đang chạy hoặc đã áp dụng
    # Truy vết: FR-14-007 · API-14-014, 016 · ERR-14-026, 004, 001.
    Biết một phiên đối chiếu đang chạy; một phiên đã `APPLIED`.
    Khi `POST /service-reconciliations` khi đang có phiên cùng loại.
    Và `POST …:apply` lần hai lên phiên đã áp dụng.
    Và `GET` runId không có.
    Thì `409` ERR-14-026; `409` ERR-14-004; `404` ERR-14-001.
