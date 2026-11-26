# language: vi
# Sinh tự động từ D05-02-PH14 bằng ph14/tools/gen_gherkin.py; không sửa tay.
@PH-14 @TS-14-13
Tính năng: TS-14-13 · Bộ điều hợp bảo hiểm xã hội

  @TC-14-034 @P1 @Dương
  Kịch bản: TC-14-034 Tra hộ gia đình theo mã số, theo tiêu chí
    # Truy vết: FR-14-019 · API-14-075 · UC-14-12 · BR-14-009, 014 · LGC-NGSP-003.
    Biết S-HT-MC; V-BHXH; hộ mẫu 4 thành viên.
    Khi tra theo mã số hộ, đủ mục đích và mã hồ sơ; lặp lại ngay.
    Và lấy mã số theo tiêu chí.
    Thì chỉ trường theo hợp đồng cung cấp lại; lượt lặp lại vẫn gọi ra quốc gia (mục `SENSITIVE`, không đệm); lượt lặp có nhật ký riêng.

  @TC-14-035 @P3 @Biên @Âm
  Kịch bản: TC-14-035 Hộ vượt giới hạn thành viên
    # Truy vết: FR-14-019 · API-14-075 · ERR-14-108 · UC-14-12.
    Biết hộ giả lập 31 thành viên; `14.bhxh.max-members = 30`.
    Khi tra hộ 31 thành viên.
    Thì chỉ trả 30 thành viên kèm cờ cắt bớt và số tổng; DLCN không vào nhật ký.
