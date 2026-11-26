package vn.datahub.data.shared.persistence;

import java.security.SecureRandom;
import java.util.UUID;

/** UUID phiên bản 7 (RFC 9562) sinh ở tầng ứng dụng (D00-01 §5; CC-JPA-01). */
public final class UuidV7 {

  private static final SecureRandom RANDOM = new SecureRandom();

  private UuidV7() {}

  public static UUID generate() {
    return generate(System.currentTimeMillis());
  }

  static UUID generate(long epochMillis) {
    long msb = (epochMillis & 0xFFFFFFFFFFFFL) << 16;
    long randA = RANDOM.nextLong() & 0x0FFFL;
    msb |= 0x7000L | randA;
    long lsb = (RANDOM.nextLong() & 0x3FFFFFFFFFFFFFFFL) | 0x8000000000000000L;
    return new UUID(msb, lsb);
  }
}
