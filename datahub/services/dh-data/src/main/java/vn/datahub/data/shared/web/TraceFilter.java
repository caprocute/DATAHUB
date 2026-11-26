package vn.datahub.data.shared.web;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.security.SecureRandom;
import java.util.HexFormat;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.slf4j.MDC;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Nhận {@code traceparent} W3C; thiếu hoặc sai thì sinh mới. {@code traceId} (32 hex) được dùng cho
 * phản hồi lỗi, outbox và nhật ký (MDC). Không bao giờ ghi token vào nhật ký (CC-LOG-04).
 */
public class TraceFilter extends OncePerRequestFilter {

  public static final String ATTRIBUTE = TraceFilter.class.getName() + ".traceId";
  public static final String MDC_KEY = "traceId";

  private static final Pattern TRACEPARENT =
      Pattern.compile("^[0-9a-f]{2}-([0-9a-f]{32})-[0-9a-f]{16}-[0-9a-f]{2}$");
  private static final String ZERO = "0".repeat(32);
  private static final SecureRandom RANDOM = new SecureRandom();

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain chain)
      throws ServletException, IOException {
    String traceId = parse(request.getHeader("traceparent"));
    request.setAttribute(ATTRIBUTE, traceId);
    MDC.put(MDC_KEY, traceId);
    try {
      chain.doFilter(request, response);
    } finally {
      MDC.remove(MDC_KEY);
    }
  }

  static String parse(String header) {
    if (header != null) {
      Matcher m = TRACEPARENT.matcher(header.trim());
      if (m.matches() && !ZERO.equals(m.group(1))) {
        return m.group(1);
      }
    }
    byte[] bytes = new byte[16];
    RANDOM.nextBytes(bytes);
    return HexFormat.of().formatHex(bytes);
  }

  /** TraceId của yêu cầu; nếu bộ lọc chưa chạy (không nên xảy ra) thì sinh tạm. */
  public static String traceId(HttpServletRequest request) {
    Object value = request.getAttribute(ATTRIBUTE);
    return value instanceof String s ? s : parse(null);
  }
}
