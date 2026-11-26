package vn.datahub.data.support;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.function.Function;

/** Truy cập CSDL bằng superuser cho kiểm thử: dựng dữ liệu, đọc kiểm, dọn giữa các kịch bản. */
public final class Db {

  private Db() {}

  public static void execute(String sql, Object... params) {
    try (Connection c = TestPostgres.admin();
        PreparedStatement ps = c.prepareStatement(sql)) {
      bind(ps, params);
      ps.execute();
    } catch (SQLException e) {
      throw new IllegalStateException(e);
    }
  }

  public static <T> List<T> query(String sql, Function<ResultSet, T> mapper, Object... params) {
    try (Connection c = TestPostgres.admin();
        PreparedStatement ps = c.prepareStatement(sql)) {
      bind(ps, params);
      try (ResultSet rs = ps.executeQuery()) {
        List<T> rows = new ArrayList<>();
        while (rs.next()) {
          rows.add(mapper.apply(rs));
        }
        return rows;
      }
    } catch (SQLException e) {
      throw new IllegalStateException(e);
    }
  }

  public static long count(String sql, Object... params) {
    return query(sql, rs -> {
          try {
            return rs.getLong(1);
          } catch (SQLException e) {
            throw new IllegalStateException(e);
          }
        }, params)
        .getFirst();
  }

  /** Chèn một nhóm (superuser, bỏ qua RLS) và trả id. */
  public static UUID insertGroup(
      String tenant, String code, String name, UUID parentId, int sortOrder) {
    UUID id = vn.datahub.data.shared.persistence.UuidV7.generate();
    execute(
        "insert into ph07_rdm.catalog_group (id, tenant_id, code, name, parent_id, sort_order,"
            + " created_by, updated_by) values (?, ?, ?, ?, ?, ?, ?, ?)",
        id, tenant, code, name, parentId, sortOrder, TestPostgres.SEED_ACTOR, TestPostgres.SEED_ACTOR);
    return id;
  }

  /** Chèn danh mục mẫu LOCAL/DRAFT thuộc nhóm (xem CREATE TABLE ph07_rdm.catalog). */
  public static UUID insertCatalog(String tenant, String code, UUID groupId, boolean softDeleted) {
    UUID id = vn.datahub.data.shared.persistence.UuidV7.generate();
    execute(
        "insert into ph07_rdm.catalog (id, tenant_id, code, name, group_id, created_by, updated_by,"
            + " deleted_at) values (?, ?, ?, ?, ?, ?, ?, " + (softDeleted ? "now()" : "null") + ")",
        id, tenant, code, "Danh mục " + code, groupId, TestPostgres.SEED_ACTOR, TestPostgres.SEED_ACTOR);
    return id;
  }

  /** Xóa mọi dữ liệu do kiểm thử tạo; giữ lại dữ liệu nền COMMON của seed. */
  public static void resetToSeed() {
    try (Connection c = TestPostgres.admin();
        Statement s = c.createStatement()) {
      s.execute("delete from ph07_rdm.outbox");
      s.execute("delete from ph07_rdm.idempotency_key");
      s.execute("delete from ph07_rdm.catalog where created_by = '" + TestPostgres.SEED_ACTOR + "' and tenant_id <> 'COMMON'");
      s.execute("delete from ph07_rdm.catalog_group where created_by <> '" + TestPostgres.SEED_ACTOR + "' or tenant_id <> 'COMMON'");
    } catch (SQLException e) {
      throw new IllegalStateException(e);
    }
  }

  private static void bind(PreparedStatement ps, Object... params) throws SQLException {
    for (int i = 0; i < params.length; i++) {
      ps.setObject(i + 1, params[i]);
    }
  }
}
