package vn.lgsp.control.onboarding.internal;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.lgsp.control.onboarding.api.ApplicationDto;
import vn.lgsp.control.onboarding.api.ApplicationSubmitRequest;
import vn.lgsp.control.onboarding.api.OnboardingApi;

@Service
class OnboardingService implements OnboardingApi {

  private static final RowMapper<ApplicationDto> MAPPER =
      (rs, i) ->
          new ApplicationDto(
              rs.getObject("id", UUID.class),
              rs.getString("system_code"),
              rs.getString("system_name"),
              rs.getString("owner_org"),
              rs.getString("status"),
              rs.getString("client_id"),
              rs.getString("client_secret_sealed"));

  private final JdbcTemplate jdbc;
  private final OutboxWriter outbox;

  OnboardingService(JdbcTemplate jdbc, OutboxWriter outbox) {
    this.jdbc = jdbc;
    this.outbox = outbox;
  }

  @Override
  @Transactional
  public ApplicationDto submit(ApplicationSubmitRequest request, String submittedBy) {
    UUID id = UUID.randomUUID();
    OffsetDateTime now = OffsetDateTime.now();
    jdbc.update(
        """
        INSERT INTO ph01.application
          (id, system_code, system_name, owner_org, status, created_at, updated_at)
        VALUES (?, ?, ?, ?, 'SUBMITTED', ?, ?)
        """,
        id,
        request.systemCode(),
        request.systemName(),
        request.ownerOrg(),
        now,
        now);
    return findById(id).orElseThrow();
  }

  @Override
  @Transactional
  public ApplicationDto approve(UUID id, String approvedBy) {
    ApplicationDto current =
        findById(id).orElseThrow(() -> new IllegalArgumentException("application not found: " + id));
    if ("APPROVED".equals(current.status())) {
      return current;
    }
    if (!"SUBMITTED".equals(current.status())) {
      throw new IllegalStateException("chỉ duyệt hồ sơ SUBMITTED, hiện: " + current.status());
    }
    String clientId = "lgsp-" + current.systemCode().toLowerCase().replace('_', '-');
    String sealed = "sealed:dev:" + UUID.randomUUID();
    OffsetDateTime now = OffsetDateTime.now();
    jdbc.update(
        """
        UPDATE ph01.application
        SET status = 'APPROVED', client_id = ?, client_secret_sealed = ?, updated_at = ?
        WHERE id = ?
        """,
        clientId,
        sealed,
        now,
        id);

    String payload =
        """
        {"specversion":"1.0","type":"onboarding.system-approved.v1","source":"urn:lgsp:control:onboarding","id":"%s","time":"%s","data":{"applicationId":"%s","systemCode":"%s","clientId":"%s","approvedBy":"%s"}}
        """
            .formatted(
                UUID.randomUUID(),
                now,
                id,
                escape(current.systemCode()),
                escape(clientId),
                escape(approvedBy));
    outbox.enqueue("onboarding.system-approved.v1", payload);
    return findById(id).orElseThrow();
  }

  private static String escape(String value) {
    return value == null ? "" : value.replace("\\", "\\\\").replace("\"", "\\\"");
  }

  @Override
  public Optional<ApplicationDto> findById(UUID id) {
    try {
      return Optional.of(
          jdbc.queryForObject(
              """
              SELECT id, system_code, system_name, owner_org, status, client_id, client_secret_sealed
              FROM ph01.application WHERE id = ?
              """,
              MAPPER,
              id));
    } catch (EmptyResultDataAccessException e) {
      return Optional.empty();
    }
  }

  @Override
  public List<ApplicationDto> list(int limit) {
    return jdbc.query(
        """
        SELECT id, system_code, system_name, owner_org, status, client_id, client_secret_sealed
        FROM ph01.application ORDER BY created_at DESC LIMIT ?
        """,
        MAPPER,
        Math.min(Math.max(limit, 1), 100));
  }

  @Override
  public String moduleStatus() {
    return "ok";
  }
}
