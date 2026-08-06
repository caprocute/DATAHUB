package vn.lgsp.control.routes.internal;

import java.time.OffsetDateTime;
import java.util.Locale;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.stereotype.Component;
import vn.lgsp.control.shared.events.SystemApprovedEvent;

/**
 * Bản sao đọc danh mục hệ thống đã kết nạp, thuộc sở hữu PH-04 (IP-07 K1-7c).
 *
 * <p><b>Vì sao không hỏi thẳng PH-01.</b> Cả {@code routes} lẫn {@code onboarding} đều khai
 * {@code allowedDependencies = "shared"}, nên gọi {@code OnboardingApi} từ đây làm
 * {@code ApplicationModules.verify()} đỏ — kiến trúc **cố ý** giữ hai phân hệ độc lập.
 * PH-01 phát sự kiện, PH-04 giữ bản sao trong schema của chính mình.
 *
 * <p><b>Ràng buộc nhất quán.</b> Đây là bản sao **cuối cùng sẽ nhất quán**, không phải
 * nguồn sự thật. Hệ thống vừa kết nạp có thể chưa kịp về đây trong khoảnh khắc ngắn; hệ quả
 * xấu nhất là một luồng đối ngoại tạm thời được coi là nội bộ, tức là **cảnh báo thay vì
 * chặn** — nới lỏng chứ không siết nhầm, nên chấp nhận được. Hàng cũ đã được nạp một lần
 * bằng changeset {@code 008-…-backfill}, không thì hệ thống kết nạp trước khi có sự kiện sẽ
 * mãi bị coi là nội bộ.
 */
@Component
class ExternalSystemRegistry {

  private final JdbcTemplate jdbc;

  ExternalSystemRegistry(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  /**
   * Ghi nhận một hệ thống vừa được kết nạp.
   *
   * <p>Chạy **sau khi giao dịch của PH-01 commit**, nên không có chuyện bản sao ghi nhận
   * một hệ thống mà giao dịch gốc lại quay đầu. Dùng {@code @TransactionalEventListener}
   * của Spring thay vì {@code @ApplicationModuleListener} để khỏi thêm phụ thuộc
   * {@code spring-modulith-starter-events} chỉ cho một chỗ dùng; ngữ nghĩa sau-commit là
   * như nhau. Đổi lại là **không có outbox trong tiến trình**: tiến trình chết đúng giữa
   * commit và lượt chạy listener thì bản ghi này lỡ — chấp nhận được vì hệ quả xấu nhất là
   * cảnh báo thay vì chặn, và changeset backfill vá được khi triển khai lại.
   */
  @TransactionalEventListener
  void on(SystemApprovedEvent event) {
    String code = event.systemCode();
    if (code == null || code.isBlank()) {
      return;
    }
    jdbc.update(
        """
        INSERT INTO ph04.external_system (system_code, synced_at)
        VALUES (?, ?)
        ON CONFLICT (system_code) DO UPDATE SET synced_at = EXCLUDED.synced_at
        """,
        code.toLowerCase(Locale.ROOT),
        OffsetDateTime.now());
  }

  /**
   * Mã hệ thống này có phải hệ thống đã kết nạp không.
   *
   * <p>So khớp **không phân biệt hoa thường**: {@code source_system} của luồng do người dùng
   * gõ tay, còn {@code system_code} do quy trình kết nạp sinh — hai bên khác kiểu chữ là
   * chuyện thường, mà so khớp cứng thì luồng đối ngoại lọt qua chốt chặn một cách im lặng.
   */
  boolean isOnboarded(String systemCode) {
    if (systemCode == null || systemCode.isBlank()) {
      return false;
    }
    Integer hit =
        jdbc.query(
            "SELECT 1 FROM ph04.external_system WHERE system_code = ? LIMIT 1",
            rs -> rs.next() ? 1 : null,
            systemCode.toLowerCase(Locale.ROOT));
    return hit != null;
  }
}
