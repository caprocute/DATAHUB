package vn.lgsp.control.onboarding.internal;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/** Bus DEV: đọc outbox → log (Kafka/Redpanda gắn sau khi có broker). */
@Component
class OutboxDispatcher {

  private static final Logger log = LoggerFactory.getLogger(OutboxDispatcher.class);

  private final JdbcTemplate jdbc;

  OutboxDispatcher(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Scheduled(fixedDelayString = "${lgsp.outbox.poll-ms:2000}")
  void publishPending() {
    List<Map<String, Object>> rows =
        jdbc.queryForList(
            """
            SELECT id, topic, payload_json FROM ph01.outbox_event
            WHERE published_at IS NULL
            ORDER BY created_at
            LIMIT 50
            """);
    for (Map<String, Object> row : rows) {
      UUID id = (UUID) row.get("id");
      String topic = (String) row.get("topic");
      String payload = (String) row.get("payload_json");
      log.info("outbox.publish topic={} payload={}", topic, payload);
      jdbc.update(
          "UPDATE ph01.outbox_event SET published_at = ? WHERE id = ?",
          OffsetDateTime.now(),
          id);
    }
  }
}
