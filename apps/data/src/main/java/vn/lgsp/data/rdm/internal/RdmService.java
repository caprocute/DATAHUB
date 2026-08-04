package vn.lgsp.data.rdm.internal;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import vn.lgsp.data.rdm.api.RdmApi;

@Service
class RdmService implements RdmApi {

  private final JdbcTemplate jdbc;

  RdmService(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public String moduleStatus() {
    Integer n =
        jdbc.queryForObject("SELECT COUNT(*) FROM ph07.schema_marker WHERE module = ?", Integer.class, "rdm");
    return n != null && n > 0 ? "ok" : "missing-marker";
  }
}
