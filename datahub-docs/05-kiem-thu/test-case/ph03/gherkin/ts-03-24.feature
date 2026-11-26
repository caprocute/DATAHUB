# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-24
Tính năng: TS-03-24 · Duyệt thay đổi gateway bốn mắt (xuyên suốt)

  @TC-03-097 @P1 @Dương
  Kịch bản: TC-03-097 Hàng đợi duyệt: xem, duyệt, từ chối cho bốn loại thay đổi
    # Truy vết: FR-03-006, 023, 038 · API-03-071, 072, 073 · UI-03-17 · UC-03-13, 16, 25 · BR-03-019.
    Biết bốn yêu cầu chờ duyệt: đổi chế độ WAF, mở route `EXT`, hạ hạn mức tenant, (ngoại lệ WAF qua API riêng); U-T68-TA, U-T68-TA2, U-T68-SO1, U-T68-SO2.
    Khi `GET /change-requests?state=PENDING`.
    Và người thứ hai duyệt hai yêu cầu bằng `:approve`.
    Và người thứ hai từ chối yêu cầu còn lại bằng `:reject` kèm lý do.
    Và `GET /change-requests/{id}`.
    Thì bước 1 `200`, mỗi yêu cầu có loại, người đề nghị, lý do, thay đổi trước và sau. Bước 2 áp dụng đúng thay đổi, ảnh chụp mới hiệu lực ≤ 60 s. Bước 3 yêu cầu `REJECTED`, thay đổi không áp. KT: có cho từng quyết định.

  @TC-03-098 @P1 @Âm @Bảo @mật
  Kịch bản: TC-03-098 Tự duyệt, sai vai trò, quyết định lần hai, tenant khác
    # Truy vết: FR-03-006, 023, 038 · API-03-072, 073 · UI-03-17 · ERR-03-008, 022, 019, 001 · BR-03-019.
    Biết U-T68-SO-VD (vừa đề nghị vừa có quyền duyệt); U-T68-TO; U-T01-TA.
    Khi SO-VD đề nghị rồi `:approve`, và `:reject` yêu cầu của chính mình.
    Và TO `:approve`.
    Và duyệt yêu cầu đã duyệt.
    Và U-T01-TA duyệt yêu cầu của T68.
    Thì bước 1 `403` ERR-03-008 "Bạn đã đề nghị thay đổi này nên không thể tự duyệt." (cả duyệt lẫn từ chối). Bước 2 403-PQ. Bước 3 `409` ERR-03-019. Bước 4 404-ẩn. Thay đổi không áp.
