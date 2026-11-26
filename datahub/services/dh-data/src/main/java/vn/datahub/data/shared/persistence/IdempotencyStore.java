package vn.datahub.data.shared.persistence;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Lưu {@code Idempotency-Key} ở {@code ph07_rdm.idempotency_key} (CC-TX-06). Ghi trong CÙNG giao
 * dịch với thao tác nên "đã thực hiện" và "đã ghi khóa" không lệch; RLS theo tenant của phiên.
 * Phải gọi trong giao dịch đã đặt tenant.
 */
@Component
public class IdempotencyStore {

  /** Kết quả bắt đầu một lần xử lý khóa. */
  public sealed interface Outcome permits Fresh, Replay, Mismatch {}

  /** Khóa mới: thực hiện thao tác rồi gọi {@link #complete}. */
  public record Fresh() implements Outcome {}

  /** Cùng khóa, cùng thân: trả lại phản hồi đã lưu. */
  public record Replay(int status, String responseBody) implements Outcome {}

  /** Cùng khóa, khác thân (ERR-07-022). */
  public record Mismatch() implements Outcome {}

  private final JdbcClient jdbc;

  public IdempotencyStore(JdbcClient jdbc) {
    this.jdbc = jdbc;
  }

  public Outcome begin(String tenant, String principal, String operation, String key, String hash) {
    jdbc.sql(
            "delete from ph07_rdm.idempotency_key where tenant_id = :t and principal = :p"
                + " and operation = :o and key = :k and expires_at < now()")
        .param("t", tenant)
        .param("p", principal)
        .param("o", operation)
        .param("k", key)
        .update();
    int inserted =
        jdbc.sql(
                "insert into ph07_rdm.idempotency_key (tenant_id, principal, operation, key,"
                    + " request_hash) values (:t, :p, :o, :k, :h)"
                    + " on conflict (tenant_id, principal, operation, key) do nothing")
            .param("t", tenant)
            .param("p", principal)
            .param("o", operation)
            .param("k", key)
            .param("h", hash)
            .update();
    if (inserted == 1) {
      return new Fresh();
    }
    return jdbc.sql(
            "select request_hash, response_status, response_body::text as body"
                + " from ph07_rdm.idempotency_key where tenant_id = :t and principal = :p"
                + " and operation = :o and key = :k")
        .param("t", tenant)
        .param("p", principal)
        .param("o", operation)
        .param("k", key)
        .query(
            (rs, i) -> {
              String stored = rs.getString("request_hash").trim();
              int status = rs.getInt("response_status");
              if (!stored.equals(hash) || rs.getString("body") == null) {
                return (Outcome) new Mismatch();
              }
              return (Outcome) new Replay(status, rs.getString("body"));
            })
        .optional()
        .orElseGet(Mismatch::new);
  }

  public void complete(
      String tenant,
      String principal,
      String operation,
      String key,
      int status,
      String responseBody,
      Optional<UUID> resourceId) {
    jdbc.sql(
            "update ph07_rdm.idempotency_key set status = 'COMPLETED', response_status = :s,"
                + " response_body = cast(:b as jsonb), resource_ref = :r where tenant_id = :t"
                + " and principal = :p and operation = :o and key = :k")
        .param("s", status)
        .param("b", responseBody)
        .param("r", resourceId.map(UUID::toString).orElse(null))
        .param("t", tenant)
        .param("p", principal)
        .param("o", operation)
        .param("k", key)
        .update();
  }

  /** SHA-256 dạng hex 64 ký tự của chuỗi chuẩn hóa của thân yêu cầu. */
  public static String sha256(String canonicalBody) {
    try {
      byte[] digest =
          MessageDigest.getInstance("SHA-256").digest(canonicalBody.getBytes(StandardCharsets.UTF_8));
      return HexFormat.of().formatHex(digest);
    } catch (NoSuchAlgorithmException e) {
      throw new IllegalStateException(e);
    }
  }
}
