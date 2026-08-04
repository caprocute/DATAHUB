package vn.lgsp.control.onboarding.internal;

import java.time.OffsetDateTime;
import java.util.UUID;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
class OutboxWriter {

  private final JdbcTemplate jdbc;

  OutboxWriter(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  void enqueue(String topic, String payloadJson) {
    jdbc.update(
        """
        INSERT INTO ph01.outbox_event (id, topic, payload_json, created_at)
        VALUES (?, ?, ?, ?)
        """,
        UUID.randomUUID(),
        topic,
        payloadJson,
        OffsetDateTime.now());
  }
}
