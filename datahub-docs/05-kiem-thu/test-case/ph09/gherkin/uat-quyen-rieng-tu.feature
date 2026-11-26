# language: vi
# Sinh tự động từ mục 7 của D05-02-PH09; không sửa tay.
@PH-09 @UAT
Tính năng: Nghiệm thu người dùng Quyền riêng tư

  Bối cảnh:
    Biết người quản lý dữ liệu của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và bộ dữ liệu thử tổng hợp của tenant UAT đã được nạp

  @UAT-01
  Kịch bản: UAT-01 DO thẩm định và chấp thuận có điều kiện yêu cầu khai thác của HTTT-BH
    # Liên quan hệ cũ: LGC-NGSP-003; FR: FR-09-015, 016, 019; TC: TS-09-09, 10, 13, 42
    Khi người dùng dO thẩm định và chấp thuận có điều kiện yêu cầu khai thác của HTTT-BH
    Thì chấp thuận ACTIVE kèm điều kiện, HTTT-BH tra được đúng trường, HTTT-TK bị từ chối

  @UAT-02
  Kịch bản: UAT-02 DO thu hồi chấp thuận đang dùng
    # Liên quan hệ cũ: LGC-NGSP-003; FR: FR-09-017, 018; TC: TS-09-11, 39
    Khi người dùng dO thu hồi chấp thuận đang dùng
    Thì HTTT-BH bị chặn trong 15 giây, có sự kiện và kiểm toán

  @UAT-03
  Kịch bản: UAT-03 TA soạn chính sách che, mô phỏng, DA duyệt
    # Liên quan hệ cũ: LGC-TOOL-012; FR: FR-09-024, 025, 026; TC: TS-09-16, 17, 42
    Khi người dùng tA soạn chính sách che, mô phỏng, DA duyệt
    Thì kết quả xem trước đúng mẫu che, phát hành bốn mắt, có phiên bản và quay lại được

  @UAT-04
  Kịch bản: UAT-04 SO xem giá trị đầy đủ một trường Nhạy cảm
    # Liên quan hệ cũ: LGC-TOOL-012; FR: FR-09-029; TC: TS-09-20
    Khi người dùng sO xem giá trị đầy đủ một trường Nhạy cảm
    Thì hộp thoại nhập lý do, đếm ngược 60 giây, tự che lại, có nhật ký

  @UAT-05
  Kịch bản: UAT-05 SO tiếp nhận, xác minh, tra cứu và trả lời yêu cầu của chủ thể
    # Liên quan hệ cũ: —; FR: FR-09-045, 046, 047, 050; TC: TS-09-29, 30
    Khi người dùng sO tiếp nhận, xác minh, tra cứu và trả lời yêu cầu của chủ thể
    Thì báo cáo đúng hạn, tra cứu theo băm, không lộ định danh

  @UAT-06
  Kịch bản: UAT-06 SO ghi nhận vi phạm và theo dõi đồng hồ 72 giờ
    # Liên quan hệ cũ: —; FR: FR-09-058, 059, 060; TC: TS-09-33, 39
    Khi người dùng sO ghi nhận vi phạm và theo dõi đồng hồ 72 giờ
    Thì cảnh báo ở 24, 48, 60 giờ, thông báo Cục A05 có bằng chứng

  @UAT-07
  Kịch bản: UAT-07 DS chạy ẩn danh hóa tập dữ liệu cho AI
    # Liên quan hệ cũ: —; FR: FR-09-036, 037, 038; TC: TS-09-25, 26
    Khi người dùng dS chạy ẩn danh hóa tập dữ liệu cho AI
    Thì tập đạt k ≥ 10, báo cáo rủi ro, rủi ro HIGH bị chặn

  @UAT-08
  Kịch bản: UAT-08 SO lập sổ hoạt động xử lý và hồ sơ DPIA, xuất cho Cục A05
    # Liên quan hệ cũ: —; FR: FR-09-009, 010, 055, 057; TC: TS-09-07, 32
    Khi người dùng sO lập sổ hoạt động xử lý và hồ sơ DPIA, xuất cho Cục A05
    Thì hoạt động ACTIVE sau duyệt bốn mắt, hồ sơ xuất đủ mục

  @UAT-09
  Kịch bản: UAT-09 SO xác nhận phân loại trường và thử kích hoạt hợp đồng Nhạy cảm
    # Liên quan hệ cũ: —; FR: FR-09-004, 022; TC: TS-09-03, 15
    Khi người dùng sO xác nhận phân loại trường và thử kích hoạt hợp đồng Nhạy cảm
    Thì hợp đồng bị chặn tới khi có chấp thuận và hoạt động xử lý
