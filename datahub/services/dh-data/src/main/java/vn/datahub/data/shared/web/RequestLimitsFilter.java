package vn.datahub.data.shared.web;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.web.filter.OncePerRequestFilter;

/** Giới hạn kích thước thân yêu cầu (CC-VAL-05): vượt thì 413 ERR-07-042 trước khi đọc thân. */
public class RequestLimitsFilter extends OncePerRequestFilter {

  /** 1 MiB. */
  public static final long MAX_BODY_BYTES = 1024L * 1024L;

  private final ProblemWriter problems;

  public RequestLimitsFilter(ProblemWriter problems) {
    this.problems = problems;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain chain)
      throws ServletException, IOException {
    if (request.getContentLengthLong() > MAX_BODY_BYTES) {
      problems.write(
          request, response, ApiError.PAYLOAD_TOO_LARGE, "Thân yêu cầu vượt quá 1 MB.");
      return;
    }
    chain.doFilter(request, response);
  }
}
