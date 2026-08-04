package vn.lgsp.data.privacy.internal;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import vn.lgsp.data.privacy.api.PrivacyApi;

@Service
class PrivacyService implements PrivacyApi {

  private final JdbcTemplate jdbc;

  PrivacyService(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public String moduleStatus() {
    Integer n =
        jdbc.queryForObject(
            "SELECT COUNT(*) FROM ph09.schema_marker WHERE module = ?", Integer.class, "privacy");
    return n != null && n > 0 ? "ok" : "missing-marker";
  }
}
