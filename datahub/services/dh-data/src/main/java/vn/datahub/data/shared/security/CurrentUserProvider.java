package vn.datahub.data.shared.security;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

/** Đọc chủ thể từ JWT đã xác minh trong SecurityContext. */
@Component
public class CurrentUserProvider {

  public CurrentUser require() {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth instanceof JwtAuthenticationToken token) {
      return from(token.getToken());
    }
    throw new IllegalStateException("Không có người dùng đã xác thực");
  }

  static CurrentUser from(Jwt jwt) {
    return new CurrentUser(
        UUID.fromString(jwt.getSubject()),
        jwt.getClaimAsString("tenant"),
        claimSet(jwt, "perms"),
        claimSet(jwt, "roles"));
  }

  static Set<String> claimSet(Jwt jwt, String claim) {
    List<String> values = jwt.getClaimAsStringList(claim);
    return values == null ? Set.of() : new HashSet<>(values);
  }
}
