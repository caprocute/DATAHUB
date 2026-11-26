# language: vi
# Sinh tự động từ mục 7 của D05-02-PH14; không sửa tay.
@PH-14 @UAT
Tính năng: Nghiệm thu người dùng tương đương kết nối NGSP cũ

  Bối cảnh:
    Biết cán bộ vận hành của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và cấu hình dịch vụ quốc gia của tỉnh đã được nhập từ hệ cũ

  @UAT-01
  Kịch bản: UAT-01 Tra danh sách hồ sơ, trạng thái lý lịch tư pháp; đăng ký và tra kết quả hộ tịch
    # Chức năng hệ cũ: LGC-NGSP-001, LGC-NGSP-002; FR: FR-14-017, 018; TC: TS-14-12
    Khi cán bộ tra danh sách hồ sơ, trạng thái lý lịch tư pháp; đăng ký và tra kết quả hộ tịch
    Thì cùng dữ liệu như hệ cũ, HTTT chỉ gọi một API, không giữ khóa

  @UAT-02
  Kịch bản: UAT-02 Tra dữ liệu bảo hiểm xã hội của hộ gia đình
    # Chức năng hệ cũ: LGC-NGSP-003; FR: FR-14-019, 011; TC: TS-14-13, 10
    Khi cán bộ tra dữ liệu bảo hiểm xã hội của hộ gia đình
    Thì có mục đích, mã hồ sơ; chỉ trường cần thiết

  @UAT-03
  Kịch bản: UAT-03 Lấy danh sách hồ sơ cấp mã ĐVQHNS theo khoảng thời gian
    # Chức năng hệ cũ: LGC-NGSP-004; FR: FR-14-020; TC: TS-14-14
    Khi cán bộ lấy danh sách hồ sơ cấp mã ĐVQHNS theo khoảng thời gian
    Thì đủ hồ sơ, không phải tự phân trang

  @UAT-04
  Kịch bản: UAT-04 Tra dữ liệu đăng ký doanh nghiệp mới nhất và hồ sơ trong ngày
    # Chức năng hệ cũ: LGC-NGSP-005; FR: FR-14-021, 035; TC: TS-14-14, 22
    Khi cán bộ tra dữ liệu đăng ký doanh nghiệp mới nhất và hồ sơ trong ngày
    Thì kết quả đúng, lượt lặp nhanh hơn nhờ đệm

  @UAT-05
  Kịch bản: UAT-05 Tìm văn bản quy phạm pháp luật theo lĩnh vực, cơ quan, người ký
    # Chức năng hệ cũ: LGC-NGSP-007; FR: FR-14-022; TC: TS-14-14
    Khi cán bộ tìm văn bản quy phạm pháp luật theo lĩnh vực, cơ quan, người ký
    Thì đủ tiêu chí tìm như hệ cũ

  @UAT-06
  Kịch bản: UAT-06 Kéo danh mục dùng chung quốc gia về PH-07
    # Chức năng hệ cũ: LGC-NGSP-006, LGC-DMDC-019; FR: FR-14-023, 007; TC: TS-14-15, 06
    Khi cán bộ kéo danh mục dùng chung quốc gia về PH-07
    Thì danh sách, cấu trúc, dữ liệu, đề xuất bổ sung đầy đủ

  @UAT-07
  Kịch bản: UAT-07 Lấy token và xoay thông tin xác thực mà không còn thấy Consumer Key
    # Chức năng hệ cũ: LGC-NGSP-008; FR: FR-14-024, 025; TC: TS-14-16
    Khi cán bộ lấy token và xoay thông tin xác thực mà không còn thấy Consumer Key
    Thì không cần giữ khóa ở HTTT; xoay không gián đoạn

  @UAT-08
  Kịch bản: UAT-08 Nhập cấu hình dịch vụ từ phụ lục NGSP cũ
    # Chức năng hệ cũ: LGC-NGSP-008; FR: FR-14-056; TC: TS-14-31
    Khi cán bộ nhập cấu hình dịch vụ từ phụ lục NGSP cũ
    Thì có đề xuất dịch vụ; chỉ phải cấp lại khóa

  @UAT-09
  Kịch bản: UAT-09 Chạy song song với kết nối cũ và đọc bảng khớp
    # Chức năng hệ cũ: LGC-NGSP-001, LGC-NGSP-003; FR: FR-14-055; TC: TS-14-31
    Khi cán bộ chạy song song với kết nối cũ và đọc bảng khớp
    Thì thấy tỷ lệ khớp, khác biệt chỉ cảnh báo

  @UAT-10
  Kịch bản: UAT-10 Tìm một giao dịch lỗi và xem nguyên nhân
    # Chức năng hệ cũ: LGC-NGSP-001; FR: FR-14-049, 050; TC: TS-14-28
    Khi cán bộ tìm một giao dịch lỗi và xem nguyên nhân
    Thì thấy trong 3 thao tác từ menu; nội dung che đúng quyền
