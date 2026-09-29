package vn.lgsp.data.rdm.api;

import java.time.LocalDate;
import java.util.List;

/**
 * Tra hàng loạt (FR-07-008) — gom nhiều mã vào một lời gọi để giảm số vòng mạng.
 *
 * @param thoiDiem thời điểm tham chiếu; rỗng = hiện tại. Xử lý lại hồ sơ năm 2023 phải
 *     dùng danh mục hiệu lực **năm 2023**, nếu không mã đã sáp nhập sẽ không giải mã được
 *     (FR-07-007 bước 4).
 */
public record ResolveRequest(List<Entry> items, LocalDate thoiDiem) {

  /** Một cặp (danh mục, mã) cần tra. */
  public record Entry(String maDanhMuc, String maMuc) {}
}
