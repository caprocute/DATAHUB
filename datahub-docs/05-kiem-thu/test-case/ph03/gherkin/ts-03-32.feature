# language: vi
# Sinh tự động từ D05-02-PH03 bằng ph03/tools/gen_gherkin.py; không sửa tay.
@PH-03 @TS-03-32
Tính năng: TS-03-32 · Truy cập giao diện, IPv6 và lưu giữ

  @TC-03-134 @P2 @Truy @cập
  Kịch bản: TC-03-134 Quét truy cập tự động toàn bộ màn UI-03
    # Truy vết: UI-03-01…18 · NFR-03-027 · NFR-00-040…045.
    Biết `axe-core` trong Playwright; dữ liệu mẫu đủ để mọi màn có nội dung, trạng thái rỗng và lỗi.
    Khi mở từng màn UI-03-01…18 ở các trạng thái chuẩn.
    Và chạy `axe-core` ở giao diện sáng và tối, thu phóng 200 %.
    Thì 0 vi phạm mức nghiêm trọng, đáng kể ở WCAG 2.2 AA; tương phản đạt; không dùng màu làm tín hiệu duy nhất (trạng thái, mức dùng hạn mức luôn có chữ).

  @TC-03-135 @P2 @Dương
  Kịch bản: TC-03-135 Hai cửa vào hoạt động qua IPv6
    # Truy vết: FR-03-001, 028 · NFR-03-025 · CMP-LAW-09 · UC-03-05.
    Biết hai cửa có địa chỉ AAAA; máy thử IPv6.
    Khi `curl -6` tới `ext.t68.sim.test`, `int.t68.sim.test` bằng token hợp lệ.
    Và gửi tải 100 lượt/giây qua IPv6 từ một địa chỉ vượt `gw.ip.apiReqPerSecond`.
    Thì bước 1 `200`. Bước 2 giới hạn theo địa chỉ IPv6 (nhóm `/64` theo cấu hình) cho `429` Lỗi GW 119; nhật ký ghi đúng `srcIp` IPv6.

  @TC-03-136 @P3 @Dương
  Kịch bản: TC-03-136 Lưu giữ nhật ký theo thời hạn
    # Truy vết: FR-03-050, 051 · API-03-074 · ERR-03-021 · NFR-03-026 · NFR-00-028.
    Biết dữ liệu giả lập tuổi 89, 91 ngày (vận hành), 11, 13 tháng (siêu dữ liệu lượt gọi, nhật ký an ninh); `faketime`.
    Khi chạy tác vụ dọn theo lịch.
    Và truy vấn từng loại.
    Thì nhật ký vận hành > 90 ngày bị xóa; siêu dữ liệu và nhật ký an ninh giữ 12 tháng; truy vấn quá 12 tháng `400` ERR-03-021; kiểm toán thao tác còn 12 tháng online và có ở WORM.
