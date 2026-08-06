package vn.lgsp.control.routes.internal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.ResultSetExtractor;
import vn.lgsp.control.shared.events.SystemApprovedEvent;

/**
 * Bản sao đọc danh mục hệ thống đã kết nạp (IP-07 K1-7c).
 *
 * <p>Điểm dễ hỏng nhất là **so khớp hoa thường**: `source_system` của luồng do người dùng
 * gõ tay, `system_code` do quy trình kết nạp sinh. So khớp cứng thì luồng đối ngoại lọt qua
 * chốt chặn một cách im lặng — đúng kiểu lỗi mà cả đợt này đang cố chặn.
 */
class ExternalSystemRegistryTest {

  private final JdbcTemplate jdbc = mock(JdbcTemplate.class);
  private final ExternalSystemRegistry registry = new ExternalSystemRegistry(jdbc);

  @Test
  void ghiNhanHeThongMoiVaHaThapChuHoa() {
    registry.on(new SystemApprovedEvent("SYS_ABC123"));
    // Lưu ở dạng thường để tra cứu không phụ thuộc kiểu chữ người dùng gõ.
    verify(jdbc).update(anyString(), eq("sys_abc123"), any());
  }

  @Test
  void boQuaMaRongVaNull() {
    registry.on(new SystemApprovedEvent(null));
    registry.on(new SystemApprovedEvent("   "));
    verify(jdbc, org.mockito.Mockito.never()).update(anyString(), any(), any());
  }

  @Test
  @SuppressWarnings("unchecked")
  void traCuuKhongPhanBietHoaThuong() {
    when(jdbc.query(anyString(), any(ResultSetExtractor.class), eq("sys_abc123"))).thenReturn(1);
    // Người dùng gõ hoa, dữ liệu lưu thường — vẫn phải nhận ra là hệ thống đã kết nạp.
    assertThat(registry.isOnboarded("SYS_ABC123")).isTrue();
  }

  @Test
  @SuppressWarnings("unchecked")
  void khongTimThayThiKhongPhaiDoiNgoai() {
    when(jdbc.query(anyString(), any(ResultSetExtractor.class), anyString())).thenReturn(null);
    assertThat(registry.isOnboarded("khong-co")).isFalse();
  }

  @Test
  void maRongKhongPhaiDoiNgoai() {
    assertThat(registry.isOnboarded(null)).isFalse();
    assertThat(registry.isOnboarded("  ")).isFalse();
  }
}
