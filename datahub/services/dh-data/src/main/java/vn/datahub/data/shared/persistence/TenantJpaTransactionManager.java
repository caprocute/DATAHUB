package vn.datahub.data.shared.persistence;

import jakarta.persistence.EntityManagerFactory;
import java.sql.PreparedStatement;
import org.hibernate.Session;
import org.springframework.orm.jpa.EntityManagerHolder;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import vn.datahub.data.shared.security.TenantContext;

/**
 * Đặt {@code app.tenant_id} ở ĐẦU mỗi giao dịch bằng {@code set_config(..., true)} (tương đương
 * SET LOCAL, CC-TX-02) để RLS lọc theo tenant của token. Mã nghiệp vụ không tự chạy SET. Thiếu
 * tenant thì từ chối bắt đầu giao dịch, không dựa vào lỗi CSDL (SS-07-07).
 */
public class TenantJpaTransactionManager extends JpaTransactionManager {

  private static final String SET_TENANT = "select set_config('app.tenant_id', ?, true)";

  public TenantJpaTransactionManager(EntityManagerFactory emf) {
    super(emf);
  }

  @Override
  protected void doBegin(Object transaction, TransactionDefinition definition) {
    String tenant = TenantContext.require();
    super.doBegin(transaction, definition);
    try {
      EntityManagerHolder holder =
          (EntityManagerHolder)
              TransactionSynchronizationManager.getResource(obtainEntityManagerFactory());
      if (holder == null) {
        throw new IllegalStateException("Không tìm thấy EntityManager của giao dịch");
      }
      holder
          .getEntityManager()
          .unwrap(Session.class)
          .doWork(
              connection -> {
                try (PreparedStatement ps = connection.prepareStatement(SET_TENANT)) {
                  ps.setString(1, tenant);
                  ps.execute();
                }
              });
    } catch (RuntimeException e) {
      doCleanupAfterCompletion(transaction);
      throw e;
    }
  }
}
