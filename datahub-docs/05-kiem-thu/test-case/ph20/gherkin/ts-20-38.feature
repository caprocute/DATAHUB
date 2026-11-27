# language: vi
# Sinh tự động từ D05-02-PH20 bằng ph20/tools/gen_gherkin.py; không sửa tay.
@PH-20 @TS-20-38
Tính năng: TS-20-38 · Phân quyền âm và bốn mắt

  @TC-20-194 @P1 @Âm
  Kịch bản: TC-20-194 Mỗi PERM-20 bị từ chối khi vai không có quyền
    # Truy vết: BR-20-008 · ERR-00-403 · API-20-002, 049, 071, 086, 110, 129, 132, 136, 140, 144 · `PERM-20-provision`, `PERM-20-lifecycle`, `PERM-20-quota`, `PERM-20-merge`, `PERM-20-release`, `PERM-20-admin`, `PERM-20-settings`, `PERM-20-org`, `PERM-20-usage-read`, `PERM-20-read`, `PERM-20-approve`, `PERM-20-org-read`
    Biết `U-PO` (chỉ `PERM-20-read`, `PERM-20-release` theo dõi), `U-PAU` (chỉ đọc), `U-T90-VW`, `U-T90-TA`, `U-T90-AU`; mỗi thao tác chọn đúng một API đại diện của quyền.
    Khi `U-PAU` gọi thao tác cần `PERM-20-provision`, `PERM-20-lifecycle`, `PERM-20-quota`, `PERM-20-merge`, `PERM-20-admin`
    Và `U-PO` gọi thao tác cần `PERM-20-lifecycle`, `PERM-20-quota`, `PERM-20-merge`, `PERM-20-approve`
    Và `U-T90-VW` gọi thao tác cần `PERM-20-settings`, `PERM-20-org`
    Và `U-T90-AU` gọi thao tác cần `PERM-20-org`, `PERM-20-settings`, `PERM-20-usage-read` ngoài phạm vi
    Và `U-T90-TA` gọi thao tác nền tảng cần `PERM-20-read`
    Thì mọi bước `403` `ERR-00-403`, không đổi dữ liệu, không lộ tên quyền thiếu ở thông báo cho người dùng cuối; có bản ghi kiểm toán từ chối.

  @TC-20-195 @P1 @Âm
  Kịch bản: TC-20-195 Năm điểm bốn mắt: người lập không được duyệt
    # Truy vết: BR-20-008 · FR-20-025, 027, 040, 041, 045 · ERR-20-007 · `PERM-20-approve`
    Biết `U-PA1`, `U-PA2`, `U-PA3`; năm đề nghị: đổi chế độ cách ly, hạ hạn mức dưới mức đang dùng, chấm dứt, xác nhận bàn giao gói dữ liệu, kế hoạch sáp nhập.
    Khi `U-PA1` lập từng đề nghị rồi tự duyệt
    Và `U-PA3` (đủ hai quyền) lập, gửi rồi duyệt đề nghị của chính mình
    Và `U-PA2` duyệt từng đề nghị
    Và với chấm dứt: người duyệt đề nghị chấm dứt xác nhận bàn giao gói dữ liệu
    Thì bước 1, 2 `403` `ERR-20-007` ("Anh/chị là người lập nên không được duyệt. Cần một quản trị nền tảng khác duyệt."). Bước 3 `200`. Bước 4 `403` `ERR-20-007`. Cả năm điểm đều bị chặn; đề nghị giữ trạng thái chờ.

  @TC-20-196 @P2 @Âm
  Kịch bản: TC-20-196 Quyền tỉnh chỉ trong phạm vi tenant của mình, cấp cho vai khác
    # Truy vết: BR-20-008 · API-20-135, 144 · ERR-00-403 · ERR-20-002 · `PERM-20-settings`, `PERM-20-org-read`
    Biết `U-T90-TA`, `U-T90-DS` (nhà phát triển), `U-T90-SO`; `T90`, `T91`.
    Khi `U-T90-SO` `GET T/organizations`; `PUT T/settings`
    Và `U-T90-DS` `GET T/usage`
    Và `U-T90-TA` gọi `GET T/organizations/{mã của T91}`
    Thì bước 1 đọc `200` (`PERM-20-org-read` cho mọi vai trò tỉnh), ghi `403` `ERR-00-403`. Bước 2 `403` `ERR-00-403` hoặc `200` theo ma trận D02-08 (ghi nhận kết quả thực tế). Bước 3 `404` `ERR-20-002`.

  @TC-20-197 @P2 @Âm
  Kịch bản: TC-20-197 Không đăng nhập, token hết hạn, thiếu scope
    # Truy vết: ERR-00-401 · ERR-00-403 · API-20-001, 135, 162
    Biết không token; token hết hạn; `S-NOSCOPE`.
    Khi gọi `GET P/tenants`, `GET T/settings`, `GET I/tenants` không token
    Và gọi với token hết hạn
    Và `S-NOSCOPE` gọi `GET I/tenants`
    Thì bước 1, 2 `401` `ERR-00-401` đúng định dạng RFC 9457 có `code`, `traceId`. Bước 3 `403` `ERR-20-104`.
