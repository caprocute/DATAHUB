# language: vi
# Sinh tự động từ D05-02-PH05 bằng ph05/tools/gen_gherkin.py; không sửa tay.
@PH-05 @TS-05-16
Tính năng: TS-05-16 · Bộ điều hợp SOAP và WSDL

  @TC-05-063 @P1 @Dương
  Kịch bản: TC-05-063 Khai báo thao tác SOAP từ WSDL, gọi có UsernameToken
    # Truy vết: FR-05-034 · API-05-050 · UI-05-10 · UC-05-14 · LGC-BUS-041
    Biết U-T68-IE1; `tc-qlvb` từ TC-05-054; SIM-SOAP WSDL v1.
    Khi Ở UI-05-10 thêm thao tác `lay-van-ban-den`, nhóm Giao thức: chọn dịch vụ, cổng, thao tác từ WSDL.
    Và kiểm thử trên TEST.
    Thì bước 1 danh sách dịch vụ nạp từ WSDL đệm, `soapAction` tự điền. Bước 2 SIM-SOAP nhận phong bì có `wsse:UsernameToken` với `Nonce`, `Created`; phản hồi chuyển về JSON chuẩn.

  @TC-05-064 @P1 @Âm @Bảo @mật
  Kịch bản: TC-05-064 WSDL có thực thể ngoài (XXE) bị từ chối
    # Truy vết: FR-05-034 · API-05-050, 065 · ERR-05-023
    Biết SIM-SOAP phục vụ WSDL có `<!DOCTYPE … SYSTEM "file:///etc/passwd">` và một bản có "billion laughs".
    Thì cả hai `422` ERR-05-023 "WSDL có khai báo DOCTYPE"; không có yêu cầu nào ra `file://` hay máy chủ ngoài; tiến trình không tăng bộ nhớ đột biến.

  @TC-05-065 @P2 @Âm
  Kịch bản: TC-05-065 SOAP Fault được phân loại theo bảng ánh xạ
    # Truy vết: FR-05-034 · ERR-05-107
    Biết thao tác có `faultMapping`: `soap:Server.Busy` → `TRANSIENT`, `VB-404` → `BUSINESS`.
    Thì ERR-05-107 với lớp lỗi `TRANSIENT`, `BUSINESS`, `BUSINESS` (không có trong bảng); PH-04 chỉ thử lại lớp `TRANSIENT`.

  @TC-05-066 @P2 @Dương
  Kịch bản: TC-05-066 WSDL ở hệ đích đổi so với bản đệm hạ sức khỏe
    # Truy vết: FR-05-034, 020 · BR-05-023 · EVT-05-06
    Biết A-QLVB v3 đang chạy; SIM-SOAP đổi sang WSDL v2 (xóa thao tác `LayVanBanDen`).
    Thì sức khỏe A-QLVB `DEGRADED`, lý do nêu thao tác lệch; EVT: `health.changed`; chủ sở hữu nhận cảnh báo.
