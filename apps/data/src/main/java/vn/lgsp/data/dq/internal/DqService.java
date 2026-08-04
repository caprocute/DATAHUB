package vn.lgsp.data.dq.internal;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import vn.lgsp.data.dq.api.DqApi;

@Service
class DqService implements DqApi {

  private final JdbcTemplate jdbc;

  DqService(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public String moduleStatus() {
    Integer n =
        jdbc.queryForObject("SELECT COUNT(*) FROM ph08.schema_marker WHERE module = ?", Integer.class, "dq");
    return n != null && n > 0 ? "ok" : "missing-marker";
  }
}
