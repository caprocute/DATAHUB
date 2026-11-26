# language: vi
# Sinh tự động từ D05-02-PH12 bằng ph12/tools/gen_gherkin.py; không sửa tay.
@PH-12 @TS-12-06
Tính năng: TS-12-06 · Danh mục vai trò chuẩn và quyền hiệu lực

  @TC-12-027 @P1 @Dương @Âm
  Kịch bản: TC-12-027 Danh mục vai trò, quyền khớp ma trận D02-08
    # Truy vết: FR-12-011 · UC-12-08 · UI-12-05 · API-12-019, 020, 021 · LGC-IAM-002
    Biết U-T68-AU; ma trận D02-08 dạng máy đọc.
    Khi `GET /roles`, `GET /roles/TENANT_ADMIN`, `GET /permissions`.
    Và đối chiếu tự động với ma trận D02-08.
    Thì đủ 22 vai trò chuẩn, tập quyền từng vai trò trùng ma trận (ký hiệu ●/○/—); vai trò `PLATFORM_*` không hiện ở tenant thường.

  @TC-12-028 @P1 @Dương
  Kịch bản: TC-12-028 Quyền hiệu lực của người dùng
    # Truy vết: FR-12-016, 046 · UC-12-08 · UI-12-02 · API-12-013 · BR-12-037
    Biết U-T68-PH07 (vai trò + phạm vi `DV-A`), một quyền có thời hạn còn hiệu lực.
    Khi `GET /users/{id}/effective-permissions`.
    Thì danh sách quyền kèm nguồn (vai trò, nhóm, quyền có thời hạn), phạm vi `DV-A`, hạn của quyền tạm; khớp quyết định của `/decide` cho 10 quyền mẫu.

  @TC-12-029 @P1 @Âm @Bảo @mật
  Kịch bản: TC-12-029 Quyền hiệu lực của người dùng tenant khác
    # Truy vết: FR-12-016 · API-12-013 · ERR-12-001 · BR-12-041
    Biết U-T68-TA1; người dùng của T01.
    Khi `GET /users/{id-T01}/effective-permissions`.
    Thì 404-ẩn.
