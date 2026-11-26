package vn.datahub.data.shared.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class PersistenceUnitTest {

  @Test
  @DisplayName("UUID v7: phiên bản 7, biến thể RFC 9562, tăng dần theo thời gian, không trùng")
  void uuidV7() {
    UUID early = UuidV7.generate(1_700_000_000_000L);
    UUID late = UuidV7.generate(1_800_000_000_000L);
    assertThat(early.version()).isEqualTo(7);
    assertThat(early.variant()).isEqualTo(2);
    assertThat(early.toString()).isLessThan(late.toString());
    Set<UUID> seen = new HashSet<>();
    for (int i = 0; i < 1000; i++) {
      assertThat(seen.add(UuidV7.generate())).isTrue();
    }
  }

  @Test
  @DisplayName("SHA-256 dạng hex 64 ký tự, ổn định theo nội dung")
  void sha256() {
    String hash = IdempotencyStore.sha256("{\"code\":\"A\"}");
    assertThat(hash).matches("^[0-9a-f]{64}$");
    assertThat(IdempotencyStore.sha256("{\"code\":\"A\"}")).isEqualTo(hash);
    assertThat(IdempotencyStore.sha256("{\"code\":\"B\"}")).isNotEqualTo(hash);
    assertThat(IdempotencyStore.sha256("")).isEqualTo("e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
  }
}
