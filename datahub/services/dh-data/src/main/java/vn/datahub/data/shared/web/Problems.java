package vn.datahub.data.shared.web;

import jakarta.servlet.http.HttpServletRequest;
import java.time.Clock;
import java.util.List;
import java.util.Map;

/** Dựng {@link ProblemBody} từ mã lỗi và yêu cầu hiện tại. */
public final class Problems {

  private static final String TYPE_BASE = "https://datahub.gov.vn/problems/rdm/";

  private Problems() {}

  public static ProblemBody of(
      ErrorCode code,
      String detail,
      List<FieldError> errors,
      Map<String, Object> extensions,
      HttpServletRequest request,
      Clock clock) {
    return new ProblemBody(
        TYPE_BASE + code.slug(),
        code.title(),
        code.status(),
        code.code(),
        detail,
        request.getRequestURI(),
        TraceFilter.traceId(request),
        clock.instant().toString(),
        errors,
        extensions);
  }
}
