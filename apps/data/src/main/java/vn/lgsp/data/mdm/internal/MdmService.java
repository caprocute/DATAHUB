package vn.lgsp.data.mdm.internal;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import vn.lgsp.data.mdm.api.MdmApi;

@Service
class MdmService implements MdmApi {

  private final JdbcTemplate jdbc;

  MdmService(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public String moduleStatus() {
    Integer n =
        jdbc.queryForObject("SELECT COUNT(*) FROM ph06.schema_marker WHERE module = ?", Integer.class, "mdm");
    return n != null && n > 0 ? "ok" : "missing-marker";
  }
}
