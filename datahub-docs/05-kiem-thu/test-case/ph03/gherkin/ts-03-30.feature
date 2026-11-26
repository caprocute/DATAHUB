# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-30
Tính năng: TS-03-30 · Chịu lỗi và phục hồi

  @TC-03-128 @P1 @Chịu @lỗi
  Kịch bản: TC-03-128 Mất một vùng sẵn sàng
    # Truy vết: FR-03-043, 029 · API-03-063, 077 · UI-03-01, 11 · NFR-03-006, 005 · BR-03-010.
    Biết mỗi cửa 3 bản sao trải 2 vùng; tải 300 lượt/giây.
    Khi chaos Mesh tắt toàn bộ nút của một vùng 10 phút.
    Và theo dõi độ trễ, lỗi, `GET /nodes`.
    Và khôi phục vùng.
    Thì độ trễ p95 tăng ≤ 50 %, không mất cấu hình, tỉ lệ lỗi do nền tảng < 0,1 % sau khi cân bằng lại; số bản sao còn lại ≥ 1 mỗi cửa; vùng trở lại tự nhận đúng phiên bản cấu hình.

  @TC-03-129 @P1 @Chịu @lỗi
  Kịch bản: TC-03-129 Nâng cấp cuốn chiếu và tắt an toàn dưới tải
    # Truy vết: FR-03-043 · API-03-063 · NFR-03-024 · NFR-00-013 · BR-03-010.
    Biết tải 1.000 lượt/giây và 500 kết nối dài; `maxUnavailable: 1`.
    Khi nâng cấp phiên bản ảnh APISIX cuốn chiếu.
    Và gửi tín hiệu tắt cho một pod khi có yêu cầu dài 20 giây đang xử lý.
    Thì 0 lượt gọi lỗi do nâng cấp; yêu cầu đang xử lý hoàn tất trong ≤ 30 giây khi tắt; kết nối mới không vào pod đang tắt.

  @TC-03-130 @P2 @Chịu @lỗi
  Kịch bản: TC-03-130 Sẵn sàng đo bằng kiểm tra tổng hợp suốt 24 giờ
    # Truy vết: FR-03-053 · API-03-080, 077 · NFR-03-005 · UI-03-01.
    Biết kiểm tra tổng hợp mỗi phút trên 5 route quan trọng; chạy kịch bản lỗi nhẹ định kỳ (xóa một pod mỗi giờ).
    Khi chạy 24 giờ.
    Và tính tỉ lệ kiểm tra thành công.
    Thì sẵn sàng ≥ 99,95 % quy đổi tháng (ngoại suy từ cửa sổ 24 giờ); mọi lần thất bại có cảnh báo `synthetic-failed`.
