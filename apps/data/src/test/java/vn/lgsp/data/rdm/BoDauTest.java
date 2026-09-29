package vn.lgsp.data.rdm;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.reflect.Method;
import org.junit.jupiter.api.Test;

/**
 * Bỏ dấu tiếng Việt cho tìm kiếm không dấu (EN-07-03 · FR-07-010).
 *
 * <p>Chạy không cần CSDL. Gọi qua reflection vì {@code RdmService} nằm trong {@code
 * internal/} — test không được phá ranh giới Modulith bằng cách nới visibility của mã sản
 * phẩm chỉ để kiểm được.
 */
class BoDauTest {

  private static String boDau(String s) throws Exception {
    Class<?> c = Class.forName("vn.lgsp.data.rdm.internal.RdmService");
    Method m = c.getDeclaredMethod("boDau", String.class);
    m.setAccessible(true);
    return (String) m.invoke(null, s);
  }

  @Test
  void boDauThuongVaHoa() throws Exception {
    assertThat(boDau("Thành phố Hà Nội")).isEqualTo("thanh pho ha noi");
    assertThat(boDau("Tỉnh Nghệ An")).isEqualTo("tinh nghe an");
  }

  @Test
  void chuDPhaiThanhD() throws Exception {
    // `đ`/`Đ` không phải dấu phụ Unicode nên NFD không tách ra được — thiếu bước thay tay
    // thì "Đà Nẵng" ra "a nang" và gõ "da nang" không tìm thấy gì.
    assertThat(boDau("Thành phố Đà Nẵng")).isEqualTo("thanh pho da nang");
    assertThat(boDau("Tỉnh Đồng Nai")).isEqualTo("tinh dong nai");
    assertThat(boDau("đường Đê La Thành")).isEqualTo("duong de la thanh");
  }

  @Test
  void chuoiRongVaNullKhongNo() throws Exception {
    assertThat(boDau(null)).isEmpty();
    assertThat(boDau("")).isEmpty();
  }

  @Test
  void giuNguyenChuKhongDau() throws Exception {
    assertThat(boDau("Can Tho 79")).isEqualTo("can tho 79");
  }
}
