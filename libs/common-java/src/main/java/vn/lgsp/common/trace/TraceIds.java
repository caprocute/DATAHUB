package vn.lgsp.common.trace;

import java.util.Optional;
import java.util.UUID;

/** Helper traceId — W3C-compatible string; không phụ thuộc OTel API. */
public final class TraceIds {

  public static final String HEADER = "traceparent";
  public static final String ALT_HEADER = "X-Trace-Id";

  private TraceIds() {}

  public static String newId() {
    return UUID.randomUUID().toString().replace("-", "");
  }

  public static Optional<String> fromTraceparent(String header) {
    if (header == null || header.isBlank()) {
      return Optional.empty();
    }
    // version-traceid-spanid-flags
    String[] parts = header.trim().split("-");
    if (parts.length >= 2 && parts[1].length() == 32) {
      return Optional.of(parts[1]);
    }
    return Optional.empty();
  }
}
