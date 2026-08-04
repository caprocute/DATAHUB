package vn.lgsp.common.problem;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.net.URI;

/** RFC 9457 — không phụ thuộc Spring (dùng chung Boot / Camel). */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ProblemDetail(
    URI type, String title, int status, String detail, String instance, String traceId) {

  public static ProblemDetail of(int status, String title, String detail, String traceId) {
    return new ProblemDetail(
        URI.create("about:blank"), title, status, detail, null, traceId);
  }
}
