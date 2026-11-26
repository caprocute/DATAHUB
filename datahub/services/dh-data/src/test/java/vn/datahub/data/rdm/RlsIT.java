package vn.datahub.data.rdm;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import vn.datahub.data.rdm.api.CatalogGroupQueries;
import vn.datahub.data.shared.security.TenantContext;
import vn.datahub.data.support.ApiTest;
import vn.datahub.data.support.Db;
import vn.datahub.data.support.TestPostgres;

/** Kiểm RLS bằng đúng vai trò đăng nhập của ứng dụng, và việc giao dịch luôn có tenant (SS-07-07). */
class RlsIT extends ApiTest {

  @Autowired CatalogGroupQueries queries;

  @BeforeEach
  void reset() {
    Db.resetToSeed();
  }

  private static long visibleGroups(Connection c, String tenant) throws SQLException {
    try (Statement s = c.createStatement()) {
      s.execute("select set_config('app.tenant_id', '" + tenant + "', false)");
      try (var rs = s.executeQuery("select count(*) from ph07_rdm.catalog_group where tenant_id <> 'COMMON'")) {
        rs.next();
        return rs.getLong(1);
      }
    }
  }

  @Test
  @DisplayName("Vai trò ứng dụng không BYPASSRLS và không phải chủ bảng")
  void appRoleIsConstrained() throws SQLException {
    try (Connection c = TestPostgres.app();
        Statement s = c.createStatement();
        var rs =
            s.executeQuery(
                "select rolbypassrls or rolsuper from pg_roles where rolname = current_user")) {
      rs.next();
      assertThat(rs.getBoolean(1)).isFalse();
    }
  }

  @Test
  @DisplayName("RLS: tenant chỉ thấy dòng của mình và COMMON; tenant rỗng chỉ thấy COMMON")
  void rowsAreFilteredByTenant() throws SQLException {
    Db.insertGroup("T01", "G_T01", "T01", null, 1);
    Db.insertGroup("T68", "G_T68", "T68", null, 1);
    try (Connection c = TestPostgres.app()) {
      assertThat(visibleGroups(c, "T01")).isEqualTo(1);
      assertThat(visibleGroups(c, "T68")).isEqualTo(1);
      assertThat(visibleGroups(c, "T99")).isZero();
      assertThat(visibleGroups(c, "")).isZero();
      assertThat(visibleGroups(c, "PLATFORM")).isZero();
    }
  }

  @Test
  @DisplayName("RLS ghi: tenant tỉnh không chèn được dòng COMMON hoặc của tenant khác")
  void writesAreConstrained() throws SQLException {
    try (Connection c = TestPostgres.app();
        Statement s = c.createStatement()) {
      s.execute("select set_config('app.tenant_id', 'T68', false)");
      assertThatThrownBy(() -> insert(s, "COMMON")).isInstanceOf(SQLException.class);
      assertThatThrownBy(() -> insert(s, "T01")).isInstanceOf(SQLException.class);
      insert(s, "T68");
    }
  }

  private static void insert(Statement s, String tenant) throws SQLException {
    UUID id = UUID.randomUUID();
    s.execute(
        "insert into ph07_rdm.catalog_group (id, tenant_id, code, name, created_by, updated_by)"
            + " values ('" + id + "', '" + tenant + "', 'RLS_" + id.toString().substring(0, 8).toUpperCase()
            + "', 'x', '" + id + "', '" + id + "')");
  }

  @Test
  @DisplayName("Giao dịch không có tenant bị từ chối ngay, không trả rỗng, không dùng tenant cũ")
  void transactionWithoutTenantFails() {
    assertThatThrownBy(() -> queries.tree()).isInstanceOf(IllegalStateException.class);
    assertThat(TenantContext.runAs("T68", () -> queries.flat())).isNotEmpty();
    // Sau khi runAs kết thúc, kết nối trong pool không giữ tenant cũ: lại bị từ chối.
    assertThatThrownBy(() -> queries.flat()).isInstanceOf(IllegalStateException.class);
  }
}
