package vn.lgsp.control;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.oauth2.jwt.Jwt;

/** Kiểm tra JWT realm_access.roles → ROLE_* (SRS-19). */
class SecurityRoleMappingTest {

  @Test
  void mapsRealmRoles() {
    SecurityConfig config = new SecurityConfig();
    Converter<Jwt, ? extends AbstractAuthenticationToken> converter = config.jwtAuthConverter();
    Jwt jwt =
        new Jwt(
            "token",
            Instant.now(),
            Instant.now().plusSeconds(60),
            Map.of("alg", "none"),
            Map.of("realm_access", Map.of("roles", List.of("INTEGRATION_REVIEWER")), "sub", "u1"));
    AbstractAuthenticationToken auth = converter.convert(jwt);
    assertThat(auth).isNotNull();
    assertThat(auth.getAuthorities())
        .extracting(Object::toString)
        .contains("ROLE_INTEGRATION_REVIEWER");
  }
}
