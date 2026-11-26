package vn.datahub.data.support;

import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.UUID;
import org.testcontainers.containers.wait.strategy.Wait;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.MountableFile;

/**
 * PostgreSQL 18 thật qua Testcontainers, nạp NGUYÊN DDL và seed nguồn bằng psql (chép vào
 * /docker-entrypoint-initdb.d/, tệp có \set và khối DO). Ứng dụng kết nối bằng vai trò đăng nhập
 * thành viên ph07_app; kiểm thử dùng kết nối superuser riêng để dựng và kiểm dữ liệu.
 */
public final class TestPostgres {

  private static final String[] SCRIPTS = {
    "datahub-docs/03-thiet-ke/csdl/ph07/ddl/ph07_rdm.sql",
    "datahub-docs/03-thiet-ke/csdl/ph07/seed/07-S01-nhom-danh-muc.sql",
    "datahub-docs/03-thiet-ke/csdl/ph07/seed/07-S02-gioi-tinh.sql",
    "datahub-docs/03-thiet-ke/csdl/ph07/seed/07-S03-dvhc-khung.sql"
  };

  public static final String APP_USER = "dh_data_app";
  public static final String APP_PASSWORD = UUID.randomUUID().toString();
  /** Người dùng hệ thống của dữ liệu nền (seed 07-S01). */
  public static final UUID SEED_ACTOR = UUID.fromString("0192f000-0000-7000-8000-00000000a001");

  private static final PostgreSQLContainer PG;

  static {
    Path root = repoRoot();
    PostgreSQLContainer container = new PostgreSQLContainer("postgres:18");
    for (int i = 0; i < SCRIPTS.length; i++) {
      container.withCopyFileToContainer(
          MountableFile.forHostPath(root.resolve(SCRIPTS[i])),
          "/docker-entrypoint-initdb.d/0" + (i + 1) + "-" + Path.of(SCRIPTS[i]).getFileName());
    }
    container.waitingFor(Wait.forListeningPort());
    container.start();
    PG = container;
    try (Connection c = admin();
        Statement s = c.createStatement()) {
      s.execute(
          "create role " + APP_USER + " login password '" + APP_PASSWORD + "' in role ph07_app");
    } catch (SQLException e) {
      throw new IllegalStateException(e);
    }
  }

  private TestPostgres() {}

  /** Gốc repo: thư mục tổ tiên chứa datahub-docs. */
  static Path repoRoot() {
    Path dir = Path.of("").toAbsolutePath();
    while (dir != null && !Files.isDirectory(dir.resolve("datahub-docs"))) {
      dir = dir.getParent();
    }
    if (dir == null) {
      throw new IllegalStateException("Không tìm thấy gốc repo (thư mục datahub-docs)");
    }
    return dir;
  }

  public static String jdbcUrl() {
    return PG.getJdbcUrl();
  }

  /** Kết nối superuser (bỏ qua RLS) dành cho dựng dữ liệu và kiểm tra của kiểm thử. */
  public static Connection admin() throws SQLException {
    return DriverManager.getConnection(PG.getJdbcUrl(), PG.getUsername(), PG.getPassword());
  }

  /** Kết nối bằng vai trò ứng dụng (thành viên ph07_app), để kiểm tra RLS trực tiếp. */
  public static Connection app() throws SQLException {
    return DriverManager.getConnection(PG.getJdbcUrl(), APP_USER, APP_PASSWORD);
  }
}
