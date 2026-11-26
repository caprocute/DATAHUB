# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-29
Tính năng: TS-12-29 · Duyệt bốn mắt, phát hành, thu hồi và quay lui chính sách

  @TC-12-093 @P1 @Dương
  Kịch bản: TC-12-093 Gửi duyệt, duyệt và phát hành gói ký
    # Truy vết: FR-12-054 · UC-12-35 · UI-12-13, 17 · API-12-096, 097, 101 · BR-12-008, BR-12-010 · ADR-069
    Biết soạn bởi U-T68-SO; người duyệt U-T68-SO2.
    Khi `:submit`; SO2 `:approve`; xem `GET /policy-bundles`.
    Thì `PUBLISHED`, gói ký mới, hiệu lực ≤ 60 giây; KT: có (policy.approve); SK: `policy.published`.

  @TC-12-094 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-094 Tự duyệt, người đóng góp duyệt, thiếu test hoặc chạy khô
    # Truy vết: FR-12-054 · BR-12-008, BR-12-009 · API-12-097, 098 · ERR-12-008 · ERR-12-025 · ERR-12-026
    Biết người soạn, một người sửa thêm, phiên bản chưa đủ ca âm, phiên bản chưa chạy khô đúng hash.
    Khi người soạn tự `:approve`; người đóng góp `:approve`.
    Và duyệt phiên bản thiếu ca âm; duyệt phiên bản sửa sau khi chạy khô.
    Thì bước 1 `403` ERR-12-008; ca thiếu `409` ERR-12-025; chưa chạy khô đúng nội dung `409` ERR-12-026.

  @TC-12-095 @P1 @Âm
  Kịch bản: TC-12-095 Chạy khô đổi quá 20 % cần xác nhận bổ sung; trạng thái sai
    # Truy vết: FR-12-054 · BR-12-011 · UI-12-13 · API-12-097, 098 · ERR-12-029 · ERR-12-027
    Biết phiên bản chạy khô đổi 25 %; một phiên bản đã `PUBLISHED`.
    Khi `:approve` không có xác nhận bổ sung; rồi có xác nhận kèm ý kiến.
    Và `:approve` phiên bản đã `PUBLISHED`; `:reject` phiên bản `DRAFT`.
    Thì bước 1 lần đầu `409` ERR-12-029, lần hai thành công; bước 2 `409` ERR-12-027.

  @TC-12-096 @P1 @Dương @Âm
  Kịch bản: TC-12-096 Thu hồi phiên bản và quay lui về gói đã chạy
    # Truy vết: FR-12-055 · UC-12-36 · UI-12-12 · API-12-099, 100, 101 · BR-12-010 · ERR-12-027
    Biết hai phiên bản đã phát hành liên tiếp; U-T68-SO, U-PA.
    Khi `:revoke` phiên bản mới nhất kèm lý do.
    Và `POST /policy-bundles:rollback` về gói trước; thử quay lui về gói chưa từng chạy.
    Thì hiệu lực ≤ 60 giây; quay lui về gói chưa từng chạy bị từ chối; quyết định sau quay lui khớp gói cũ; KT: có.
