package vn.lgsp.control.routes.api;

import java.util.List;
import java.util.Locale;

/**
 * Điều kiện lọc danh sách luồng — thực hiện **phía máy chủ** (FR-D-001).
 *
 * Trước đợt này giao diện tải toàn bộ danh sách rồi lọc trong trình duyệt; cách đó vỡ
 * khi số luồng lớn và làm phân trang thành phân trang giả.
 *
 * @param q tìm theo mã / tên / hệ nguồn
 * @param status lọc theo trạng thái, rỗng là mọi trạng thái
 * @param sort tên cột sắp xếp; chỉ nhận danh sách trắng bên dưới
 * @param desc sắp xếp giảm dần
 * @param page trang bắt đầu từ 0
 * @param size số dòng mỗi trang
 */
public record RouteQuery(
    String q, String status, String sort, boolean desc, int page, int size) {

  /**
   * Cột được phép sắp xếp → biểu thức SQL.
   *
   * Danh sách trắng, **không** ghép tên cột từ tham số vào câu lệnh: `sort` đi thẳng
   * vào SQL là lỗ SQL injection kinh điển mà tham số hóa không đỡ được (không tham số
   * hóa được tên cột).
   */
  private static final List<String> SORTABLE =
      List.of("route_code", "title", "status", "source_system", "updated_at", "created_at");

  private static final int MAX_SIZE = 200;

  /** Chuẩn hóa giá trị người dùng gửi lên về dạng dùng được, có biên rõ ràng. */
  public RouteQuery {
    q = q == null || q.isBlank() ? null : q.trim();
    status = status == null || status.isBlank() ? null : status.trim().toUpperCase(Locale.ROOT);
    // Phải xét null **trước**: `SORTABLE` tạo bằng `List.of(...)` nên không nhận null,
    // `contains(null)` ném thẳng NullPointerException. Mà null lại là trường hợp
    // thường gặp nhất — giao diện không gửi tham số sắp xếp thì mọi lần liệt kê đều 500.
    sort = sort != null && SORTABLE.contains(sort) ? sort : "updated_at";
    page = Math.max(page, 0);
    size = size <= 0 ? 20 : Math.min(size, MAX_SIZE);
  }

  /** Mệnh đề `ORDER BY` an toàn — cột đã qua danh sách trắng ở constructor. */
  public String orderBy() {
    return "r." + sort + (desc ? " DESC" : " ASC");
  }

  public int offset() {
    return page * size;
  }
}
