# language: vi
# Sinh tự động từ mục 7 của D05-02-PH06; không sửa tay.
@PH-06 @UAT
Tính năng: Nghiệm thu người dùng Dữ liệu chủ

  Bối cảnh:
    Biết người quản lý dữ liệu của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và bộ dữ liệu thử tổng hợp của tenant UAT đã được nạp

  @UAT-01
  Kịch bản: UAT-01 Xem tổng quan: hàng đợi, tỷ lệ tự động, cảnh báo
    # Liên quan hệ cũ: —; FR: FR-06-055; TC: TS-06-26
    Khi người dùng xem tổng quan: hàng đợi, tỷ lệ tự động, cảnh báo
    Thì bảy thẻ chỉ số đúng, bấm vào ra danh sách đã lọc

  @UAT-02
  Kịch bản: UAT-02 Xử lý một mục hàng đợi: so sánh và quyết định
    # Liên quan hệ cũ: —; FR: FR-06-029, 030; TC: TS-06-13
    Khi người dùng xử lý một mục hàng đợi: so sánh và quyết định
    Thì quyết định trong 60 giây, lý do ≥ 20 ký tự

  @UAT-03
  Kịch bản: UAT-03 Hợp nhất hai bản ghi và hoàn tác
    # Liên quan hệ cũ: —; FR: FR-06-037, 039; TC: TS-06-18, 20
    Khi người dùng hợp nhất hai bản ghi và hoàn tác
    Thì làm được, thấy lịch sử, hoàn tác khôi phục

  @UAT-04
  Kịch bản: UAT-04 Xem nguồn gốc từng thuộc tính của một công dân
    # Liên quan hệ cũ: LGC-NGSP-003; FR: FR-06-043; TC: TS-06-16
    Khi người dùng xem nguồn gốc từng thuộc tính của một công dân
    Thì thấy nguồn từng thuộc tính, dữ liệu BHXH qua PH-14

  @UAT-05
  Kịch bản: UAT-05 Xem dữ liệu doanh nghiệp từ đăng ký kinh doanh
    # Liên quan hệ cũ: LGC-NGSP-005; FR: FR-06-046, 053; TC: TS-06-21, 25
    Khi người dùng xem dữ liệu doanh nghiệp từ đăng ký kinh doanh
    Thì tổ chức gom theo MST, nguồn `QG-DKDN`

  @UAT-06
  Kịch bản: UAT-06 Nạp tệp lô, xem trước, xác nhận
    # Liên quan hệ cũ: LGC-DMDC-015; FR: FR-06-013, 015; TC: TS-06-06, 07
    Khi người dùng nạp tệp lô, xem trước, xác nhận
    Thì báo cáo lỗi theo dòng, địa chỉ chuẩn hóa theo mã ĐVHC hiện hành

  @UAT-07
  Kịch bản: UAT-07 Xử lý lệch đồng bộ quốc gia
    # Liên quan hệ cũ: —; FR: FR-06-053, 054; TC: TS-06-25
    Khi người dùng xử lý lệch đồng bộ quốc gia
    Thì danh sách lệch, giải quyết bốn cách, cảnh báo tạm dừng

  @UAT-08
  Kịch bản: UAT-08 Tiếp nhận yêu cầu của chủ thể dữ liệu
    # Liên quan hệ cũ: —; FR: FR-06-058; TC: TS-06-27
    Khi người dùng tiếp nhận yêu cầu của chủ thể dữ liệu
    Thì báo cáo đúng hạn, sửa tại nguồn
