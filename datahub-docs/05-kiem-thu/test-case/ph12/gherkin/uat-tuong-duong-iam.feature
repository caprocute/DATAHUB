# language: vi
# Sinh tự động từ mục 7 của D05-02-PH12; không sửa tay.
@PH-12 @UAT
Tính năng: Nghiệm thu người dùng tương đương hệ IAM, Bus và APIM cũ

  Bối cảnh:
    Biết quản trị viên của tỉnh thí điểm đã đăng nhập môi trường UAT
    Và người dùng, client của tỉnh đã được chuyển từ hệ cũ

  @UAT-01
  Kịch bản: UAT-01 Tạo người dùng mới và gán vai trò
    # Chức năng hệ cũ: LGC-IAM-002; FR: FR-12-003, 012, 013; TC: TS-12-02, 07, 08
    Khi cán bộ tạo người dùng mới và gán vai trò
    Thì làm trong 3 phút, có kiểm tra xung đột vai trò trước khi lưu, người dùng nhận thư kích hoạt

  @UAT-02
  Kịch bản: UAT-02 Đăng nhập một lần vào console và ứng dụng khác
    # Chức năng hệ cũ: LGC-IAM-001; FR: FR-12-020; TC: TS-12-14
    Khi cán bộ đăng nhập một lần vào console và ứng dụng khác
    Thì đăng nhập một lần cho mọi khối, đăng xuất một nơi thì thoát mọi nơi

  @UAT-03
  Kịch bản: UAT-03 Cấu hình xác thực hai yếu tố
    # Chức năng hệ cũ: LGC-IAM-003; FR: FR-12-022, 024; TC: TS-12-16, 17
    Khi cán bộ cấu hình xác thực hai yếu tố
    Thì làm được TOTP như cũ, thêm WebAuthn; đặt lại khi mất thiết bị có duyệt

  @UAT-04
  Kịch bản: UAT-04 Liên kết LDAP hoặc AD của tỉnh
    # Chức năng hệ cũ: LGC-IAM-004; FR: FR-12-026; TC: TS-12-18
    Khi cán bộ liên kết LDAP hoặc AD của tỉnh
    Thì kiểm tra liên kết trước khi lưu, đồng bộ có báo cáo người nhập

  @UAT-05
  Kịch bản: UAT-05 Xem phiên và buộc một người đăng xuất
    # Chức năng hệ cũ: LGC-IAM-005; FR: FR-12-029, 040; TC: TS-12-20, 24
    Khi cán bộ xem phiên và buộc một người đăng xuất
    Thì thấy phiên, buộc thoát có hiệu lực trong 60 giây

  @UAT-06
  Kịch bản: UAT-06 Lấy token để thử gọi API (thay grant `password`)
    # Chức năng hệ cũ: LGC-IAM-006; FR: FR-12-020, 035; TC: TS-12-14, 23
    Khi cán bộ lấy token để thử gọi API (thay grant `password`)
    Thì người dùng dùng PKCE, hệ thống dùng `client_credentials`; hướng dẫn rõ ràng khi thử grant cũ

  @UAT-07
  Kịch bản: UAT-07 Đăng nhập một lần cho màn quản trị Bus bằng SAML
    # Chức năng hệ cũ: LGC-IAM-008; FR: FR-12-025; TC: TS-12-18
    Khi cán bộ đăng nhập một lần cho màn quản trị Bus bằng SAML
    Thì màn quản trị đăng nhập qua Keycloak, không cần midPoint

  @UAT-08
  Kịch bản: UAT-08 Tìm đăng nhập bằng mạng xã hội
    # Chức năng hệ cũ: LGC-IAM-007; FR: FR-12-028; TC: TS-12-19
    Khi cán bộ tìm đăng nhập bằng mạng xã hội
    Thì không còn; có VNeID thay thế khi tỉnh yêu cầu

  @UAT-09
  Kịch bản: UAT-09 Quản lý nhóm và gán quyền theo nhóm, đơn vị
    # Chức năng hệ cũ: LGC-BUS-032; FR: FR-12-014, 012; TC: TS-12-09, 07
    Khi cán bộ quản lý nhóm và gán quyền theo nhóm, đơn vị
    Thì cây nhóm, phạm vi kế thừa, không gán vai trò cho nhóm

  @UAT-10
  Kịch bản: UAT-10 Cấp client cho một HTTT và đổi chứng thư
    # Chức năng hệ cũ: LGC-APIM-020; LGC-NGSP-008, LGC-BUS-041; FR: FR-12-030, 033, 034; TC: TS-12-21, 22
    Khi cán bộ cấp client cho một HTTT và đổi chứng thư
    Thì cấp trong 5 phút, bí mật giao một lần, mTLS theo hợp đồng
