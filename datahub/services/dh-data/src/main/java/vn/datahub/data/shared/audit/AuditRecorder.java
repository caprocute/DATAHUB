package vn.datahub.data.shared.audit;

import jakarta.servlet.http.HttpServletRequest;
import java.time.Clock;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import tools.jackson.databind.json.JsonMapper;
import vn.datahub.data.shared.persistence.UuidV7;
import vn.datahub.data.shared.security.CurrentUserProvider;
import vn.datahub.data.shared.security.TenantContext;
import vn.datahub.data.shared.web.TraceFilter;

/**
 * Ghi kiểm toán vào {@code ph07_rdm.outbox} trong CÙNG giao dịch với thay đổi (SS-07-08, CC-TX-03).
 * Sự kiện {@code vn.datahub.rdm.audit.recorded.v1}, topic {@code {tenant thường}.rdm.audit.recorded.v1};
 * ghi PLATFORM vào COMMON thì outbox mang tenant COMMON. Tạm đặt ở nhân dh-data cho tới khi có thư
 * viện chung {@code vn.datahub.common.audit}.
 */
@Component
public class AuditRecorder {

  static final String EVENT_TYPE = "vn.datahub.rdm.audit.recorded.v1";

  private final JdbcClient jdbc;
  private final JsonMapper mapper;
  private final Clock clock;
  private final CurrentUserProvider users;

  public AuditRecorder(
      JdbcClient jdbc, JsonMapper mapper, Clock clock, CurrentUserProvider users) {
    this.jdbc = jdbc;
    this.mapper = mapper;
    this.clock = clock;
    this.users = users;
  }

  public void record(AuditEvent event) {
    String dataTenant = TenantContext.dataTenant();
    HttpServletRequest request = currentRequest();
    String traceId = request == null ? UuidV7.generate().toString().replace("-", "") : TraceFilter.traceId(request);
    Map<String, Object> payload = new LinkedHashMap<>();
    payload.put("action", event.action());
    payload.put("actor", users.require().id().toString());
    payload.put("objectRef", event.aggregateType() + ":" + event.aggregateId());
    payload.put("before", event.before());
    payload.put("after", event.after());
    payload.put("ip", request == null ? null : request.getRemoteAddr());
    payload.put("traceId", traceId);
    payload.put("at", clock.instant().toString());
    jdbc.sql(
            "insert into ph07_rdm.outbox (event_id, tenant_id, event_type, topic, aggregate_type,"
                + " aggregate_id, payload, trace_id) values (:id, :tenant, :type, :topic, :agg,"
                + " :aggId, cast(:payload as jsonb), :trace)")
        .param("id", UuidV7.generate())
        .param("tenant", dataTenant)
        .param("type", EVENT_TYPE)
        .param("topic", dataTenant.toLowerCase(java.util.Locale.ROOT) + ".rdm.audit.recorded.v1")
        .param("agg", event.aggregateType())
        .param("aggId", event.aggregateId())
        .param("payload", mapper.writeValueAsString(payload))
        .param("trace", traceId)
        .update();
  }

  private static HttpServletRequest currentRequest() {
    RequestAttributes attributes = RequestContextHolder.getRequestAttributes();
    return attributes instanceof ServletRequestAttributes sra ? sra.getRequest() : null;
  }

}
