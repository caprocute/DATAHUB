package vn.lgsp.data;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Optional;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * PEP OPA cho {@code /api/**}. Ánh xạ path → action {@code data.<module>.status} (WP-30).
 */
public class OpaAuthorizationFilter extends OncePerRequestFilter {

  private final OpaClient opaClient;
  private final OpaProperties properties;

  public OpaAuthorizationFilter(OpaClient opaClient, OpaProperties properties) {
    this.opaClient = opaClient;
    this.properties = properties;
  }

  @Override
  protected boolean shouldNotFilter(HttpServletRequest request) {
    if (!properties.isEnabled()) {
      return true;
    }
    if (HttpMethod.OPTIONS.matches(request.getMethod())) {
      return true;
    }
    String path = request.getRequestURI();
    return path.startsWith("/actuator");
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {
    String path = request.getRequestURI();
    if (!path.startsWith("/api/")) {
      filterChain.doFilter(request, response);
      return;
    }
    Optional<String> action = resolveAction(path);
    if (action.isEmpty()) {
      forbid(response, "OPA: unknown API path");
      return;
    }
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth == null || !auth.isAuthenticated()) {
      response.sendError(HttpServletResponse.SC_UNAUTHORIZED);
      return;
    }
    List<String> roles =
        auth.getAuthorities().stream()
            .map(GrantedAuthority::getAuthority)
            .filter(a -> a.startsWith("ROLE_"))
            .map(a -> a.substring("ROLE_".length()))
            .toList();
    if (!opaClient.allow(action.get(), roles)) {
      forbid(response, "OPA deny: " + action.get());
      return;
    }
    filterChain.doFilter(request, response);
  }

  static Optional<String> resolveAction(String path) {
    if (path.equals("/api/v1/rdm/status") || path.startsWith("/api/v1/rdm/")) {
      return Optional.of("data.rdm.status");
    }
    if (path.equals("/api/v1/mdm/status") || path.startsWith("/api/v1/mdm/")) {
      return Optional.of("data.mdm.status");
    }
    if (path.equals("/api/v1/privacy/status") || path.startsWith("/api/v1/privacy/")) {
      return Optional.of("data.privacy.status");
    }
    if (path.equals("/api/v1/dq/status") || path.startsWith("/api/v1/dq/")) {
      return Optional.of("data.dq.status");
    }
    return Optional.empty();
  }

  private static void forbid(HttpServletResponse response, String message) throws IOException {
    response.setStatus(HttpServletResponse.SC_FORBIDDEN);
    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
    response.getWriter().write("{\"title\":\"" + message.replace("\"", "'") + "\"}");
  }
}
