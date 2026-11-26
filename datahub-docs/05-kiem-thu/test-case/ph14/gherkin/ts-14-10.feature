# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-10
Tính năng: TS-14-10 · Mục đích khai thác và ủy quyền theo mục đích

  @TC-14-028 @P1 @Dương
  Kịch bản: TC-14-028 Gọi dịch vụ DLCN đủ mục đích, mã thủ tục, mã hồ sơ
    # Truy vết: FR-14-011, 052 · API-14-075, 065 · UI-14-13 · UC-14-09 · BR-14-008, 009 · SEC-37.
    Biết S-HT-MC được cấp V-BHXH; U-T68-AU.
    Khi gọi V-BHXH `purposeCode = GIAI_QUYET_TTHC`, `procedureCode = 1.001234`, `caseCode = HS-2026-08-001234`.
    Và U-T68-AU mở UI-14-13, lọc theo HTTT và mục đích.
    Thì `200`; nhật ký khai thác có HTTT, người dùng cuối nếu có, mục đích, mã thủ tục, mã hồ sơ, dịch vụ, thời điểm; không có giá trị DLCN trong nhật ký.

  @TC-14-029 @P1 @Âm @Bảo @mật
  Kịch bản: TC-14-029 Từ chối: chưa được cấp, mục đích sai, thiếu mã hồ sơ, ngoài khung giờ
    # Truy vết: FR-14-011 · API-14-075 · ERR-14-106, 107, 132 · BR-14-008 · NFR-14-024.
    Biết S-HT-KHAC; S-HT-MC; `14.purpose.allowed-hours = 07:00-18:00`, giờ giả lập 22:00.
    Khi S-HT-KHAC gọi V-BHXH.
    Và S-HT-MC gọi với `purposeCode` không thuộc danh mục.
    Và S-HT-MC gọi V-BHXH thiếu `caseCode`.
    Và chuyển giờ giả lập 22:00, gọi đúng; rồi dừng OPA và gọi lại.
    Thì bước 1, 2 `403` ERR-14-106; bước 3 `422` ERR-14-107; bước 4 lần một `403` ERR-14-106, lần hai `503` ERR-14-132 (từ chối an toàn). Không lượt nào chạm `sim-ndxp`; mỗi lượt từ chối có dòng nhật ký.
