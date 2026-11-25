# language: vi
# Sinh tự động từ D05-02-PH07 bằng ph07/tools/gen_gherkin.py; không sửa tay.
@PH-07 @TS-07-06
Tính năng: TS-07-06 · So sánh phiên bản và phân loại thay đổi phá vỡ

  @TC-07-067 @P1 @Dương
  Kịch bản: TC-07-067 So sánh bản nháp với phiên bản hiện hành
    # Truy vết: FR-07-014 · API-07-021 · AT-07-009 (SRS cũ)
    Biết như chung.
    Khi gọi `GET /catalogs/LOAI_HINH_TC/versions/draft/diff?against=current`.
    Và gọi lại với `?against=current&changeType=CHANGED&page=0&size=50`.
    Thì `200`; `summary` = `{added:2, changed:4, deprecated:1, parentChanged:1, attributeAdded:1, breaking:2}` (đổi mã cha và ngừng dùng là phá vỡ). Mỗi mục có `itemCode`, `changeType`, `breaking`, `before`, `after` chỉ gồm trường thay đổi. Bước 2 lọc đúng.

  @TC-07-068 @P1 @Dương @Âm
  Kịch bản: TC-07-068 Bộ phân loại thay đổi phá vỡ theo bảng quyết định
    # Truy vết: FR-07-014 · BR-07-013 · khung §3.18
    Biết bảng quyết định dưới đây là dữ liệu tham số hóa (`@ParameterizedTest`).
    Khi với mỗi dòng của bảng, dựng cặp phiên bản trước và sau tối thiểu rồi gọi bộ phân loại.
    Thì kết quả khớp bảng sau.

  @TC-07-069 @P2 @Âm
  Kịch bản: TC-07-069 So sánh với phiên bản không tồn tại
    # Truy vết: FR-07-014 · ERR-07-006
    Biết CAT-LH chỉ có v1, v2.
    Khi gọi `GET .../versions/draft/diff?against=9`.
    Và gọi `GET .../versions/9/diff?against=1`.
    Thì cả hai trả `404` `ERR-07-006`.

  @TC-07-070 @P2 @Dương
  Kịch bản: TC-07-070 So sánh hai phiên bản đã phát hành không liền kề
    # Truy vết: FR-07-014 · API-07-021
    Biết `DVHC` có v1, v2, v3 (mục 2.4); người gọi U-PA.
    Khi gọi `GET /catalogs/DVHC/versions/3/diff?against=1`.
    Thì `200`; kết quả là khác biệt trực tiếp giữa v1 và v3 (không phải cộng dồn từng bước): `99001`, `99002`, `99003`, `99005` và các huyện ở trạng thái ngừng dùng hoặc vắng mặt theo cách hệ thống quy ước; `99101`, `99102`, `99201` là thêm; `99004` là đổi tên.

  @TC-07-071 @P2 @Dương
  Kịch bản: TC-07-071 Màn so sánh phiên bản trên giao diện
    # Truy vết: FR-07-014 · UI-07-07
    Biết như chung; người dùng U-T68-DA1.
    Khi mở UI-07-07 cho bản nháp v2; xem thẻ tổng hợp và bảng khác biệt.
    Và bật bộ lọc "Chỉ thay đổi phá vỡ".
    Thì thẻ tổng hợp hiển thị đúng số liệu như TC-07-067; dòng phá vỡ có nhãn cảnh báo (không chỉ dùng màu, có biểu tượng và chữ); bộ lọc còn 2 dòng.
