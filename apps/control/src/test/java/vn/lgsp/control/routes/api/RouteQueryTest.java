package vn.lgsp.control.routes.api;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * `RouteQuery` chuẩn hóa tham số lọc trước khi vào SQL.
 *
 * Đáng test riêng vì `sort` là thứ **duy nhất** được ghép chuỗi vào câu lệnh — tên cột
 * không tham số hóa được. Danh sách trắng ở đây là chốt chặn SQL injection.
 */
class RouteQueryTest {

  @Test
  @DisplayName("cột sắp xếp lạ bị đẩy về mặc định, không lọt vào SQL")
  void rejectsUnknownSortColumn() {
    RouteQuery q = new RouteQuery(null, null, "route_code; DROP TABLE ph04.route", false, 0, 20);
    assertThat(q.sort()).isEqualTo("updated_at");
    assertThat(q.orderBy()).isEqualTo("r.updated_at ASC");
  }

  @Test
  @DisplayName("cột sắp xếp hợp lệ được giữ nguyên")
  void keepsWhitelistedSortColumn() {
    assertThat(new RouteQuery(null, null, "route_code", true, 0, 20).orderBy())
        .isEqualTo("r.route_code DESC");
  }

  @Test
  @DisplayName("chuỗi tìm kiếm rỗng coi như không lọc")
  void blankSearchBecomesNull() {
    assertThat(new RouteQuery("   ", null, null, false, 0, 20).q()).isNull();
    assertThat(new RouteQuery(null, null, null, false, 0, 20).q()).isNull();
  }

  @Test
  @DisplayName("chuỗi tìm kiếm được cắt khoảng trắng thừa")
  void trimsSearch() {
    assertThat(new RouteQuery("  tra-cuu  ", null, null, false, 0, 20).q()).isEqualTo("tra-cuu");
  }

  @Test
  @DisplayName("trạng thái chuẩn hóa về chữ hoa để khớp dữ liệu trong bảng")
  void normalizesStatus() {
    assertThat(new RouteQuery(null, "active", null, false, 0, 20).status()).isEqualTo("ACTIVE");
    assertThat(new RouteQuery(null, "  ", null, false, 0, 20).status()).isNull();
  }

  @Test
  @DisplayName("kích thước trang có biên trên, tránh một lần gọi kéo cả bảng")
  void capsPageSize() {
    assertThat(new RouteQuery(null, null, null, false, 0, 10_000).size()).isEqualTo(200);
    assertThat(new RouteQuery(null, null, null, false, 0, 0).size()).isEqualTo(20);
    assertThat(new RouteQuery(null, null, null, false, 0, -5).size()).isEqualTo(20);
  }

  @Test
  @DisplayName("số trang âm bị kéo về 0, không sinh OFFSET âm")
  void clampsNegativePage() {
    RouteQuery q = new RouteQuery(null, null, null, false, -3, 20);
    assertThat(q.page()).isZero();
    assertThat(q.offset()).isZero();
  }

  @Test
  @DisplayName("độ lệch tính đúng theo trang và kích thước")
  void computesOffset() {
    assertThat(new RouteQuery(null, null, null, false, 3, 25).offset()).isEqualTo(75);
  }
}
