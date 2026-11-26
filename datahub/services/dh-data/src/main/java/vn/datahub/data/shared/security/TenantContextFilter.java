package vn.datahub.data.shared.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.filter.OncePerRequestFilter;

/** Đặt {@link TenantContext} từ claim của JWT đã xác minh; xóa khi kết thúc yêu cầu. */
class TenantContextFilter extends OncePerRequestFilter {

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain chain)
      throws ServletException, IOException {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    try {
      if (auth instanceof JwtAuthenticationToken token) {
        TenantContext.set(token.getToken().getClaimAsString("tenant"));
      }
      chain.doFilter(request, response);
    } finally {
      TenantContext.clear();
    }
  }
}
