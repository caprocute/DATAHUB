# language: vi
# Sinh tự động từ D05-02-PH02 bằng ph02/tools/gen_gherkin.py; không sửa tay.
@PH-02 @TS-02-27
Tính năng: TS-02-27 · Truy cập, quan sát, thông báo và lưu giữ

  @TC-02-082 @P2 @Truy @cập
  Kịch bản: TC-02-082 Quét axe và bàn phím trên 17 màn UI-02
    # Truy vết: NFR-02-016 · UI-02-01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17.
    Biết dữ liệu mục 2; Playwright với axe.
    Khi mở từng màn ở trạng thái có dữ liệu, rỗng, lỗi; chạy axe.
    Và thao tác UI-02-03 (wizard) và UI-02-10 (duyệt) chỉ bằng bàn phím.
    Thì không vi phạm WCAG 2.2 AA mức nghiêm trọng; thứ tự tab đúng; lỗi gắn với trường qua `aria-describedby`.

  @TC-02-083 @P2 @Dương
  Kịch bản: TC-02-083 Chỉ số, kiểm toán và lưu giữ
    # Truy vết: NFR-02-017, 019 · FR-02-036, 040, 056 · API-02-091.
    Biết đã chạy TS-02-11, 14, 19.
    Khi đọc `/metrics`: `catalog_apis_total{status}`, `catalog_spec_validation_total{result,mode}`, `catalog_publish_duration_seconds`, `catalog_national_sync_status`.
    Và xóa mềm API, kiểm tra đặc tả và lịch sử còn; kiểm tra chính sách lưu giữ kỳ SLA.
    Thì đủ chỉ số, nhãn đúng; đặc tả, phiên bản, đăng ký giữ vĩnh viễn kể cả đã xóa; chính sách lưu giữ khớp NFR-02-017.

  @TC-02-151 @P2 @Biên @Dương
  Kịch bản: TC-02-151 Thông báo trong ứng dụng ≤ 15 phút, thư điện tử ≤ 1 giờ
    # Truy vết: FR-02-057 · API-02-077 · UI-02-13 · UC-02-33 · BR-02-029 · NFR-02-015.
    Biết A-DATDAI có 3 bên đăng ký; PH-13 giả (trong ứng dụng), M-MAIL (thư điện tử) có độ trễ điều chỉnh được.
    Khi phát một thông báo bắt buộc (tạm ngừng).
    Và đặt độ trễ M-MAIL 50 phút, rồi 70 phút.
    Và bên nhận thử tắt thông báo bắt buộc trong hồ sơ.
    Thì trong ứng dụng tới đủ 3 bên ≤ 15 phút. Thư điện tử 50 phút đạt, 70 phút bị ghi "vi phạm mục tiêu" ở chỉ số. Không tắt được thông báo bắt buộc.

  @TC-02-152 @P2 @Biên @Bảo @mật
  Kịch bản: TC-02-152 Dọn dữ liệu theo thời hạn lưu giữ: chỉ dọn loại được phép
    # Truy vết: NFR-02-017 · BR-02-014 · API-02-020, 072, 077.
    Biết đồng hồ giả; dữ liệu có tuổi 1 năm ± 1 ngày (kết quả kiểm tra đặc tả), 3 năm ± 1 ngày (kỳ SLA), 2 năm (thông báo), 5 năm (bản ghi đồng bộ); đặc tả `RETIRED` 10 năm.
    Khi chạy bộ dọn lưu giữ.
    Và đọc lại từng loại qua API.
    Thì chỉ dữ liệu quá thời hạn bị dọn (kết quả kiểm tra > 1 năm, kỳ SLA > 3 năm, thông báo > 2 năm, bản ghi đồng bộ > 5 năm); dữ liệu sát ngày thì giữ. Đặc tả, phiên bản, đăng ký, lịch sử vòng đời, cam kết SLA không bao giờ bị dọn (BR-02-014).
