package vn.datahub.data.shared.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;
import vn.datahub.data.support.TestJwt;

class SecurityConfigTest {

  private static Jwt jwt(String sub, Object tenant) {
    Jwt.Builder builder =
        Jwt.withTokenValue("t")
            .header("alg", "RS256")
            .subject(sub)
            .issuedAt(Instant.now())
            .expiresAt(Instant.now().plusSeconds(60))
            .claim("perms", List.of("PERM-07-read"))
            .claim("roles", List.of("ROLE-TENANT_ADMIN", "DATA_STEWARD"));
    if (tenant != null) {
      builder.claim("tenant", tenant);
    }
    return builder.build();
  }

  @Test
  @DisplayName("perms thành quyền, roles thành ROLE_ (bỏ tiền tố ROLE-)")
  void authorities() {
    List<String> names =
        SecurityConfig.authorities(jwt(UUID.randomUUID().toString(), "T68")).stream()
            .map(GrantedAuthority::getAuthority)
            .toList();
    assertThat(names)
        .containsExactlyInAnyOrder("PERM-07-read", "ROLE_TENANT_ADMIN", "ROLE_DATA_STEWARD");
  }

  @Test
  @DisplayName("Thiếu perms và roles thì không có quyền nào (mặc định từ chối)")
  void noClaimsNoAuthorities() {
    Jwt bare =
        Jwt.withTokenValue("t")
            .header("alg", "RS256")
            .subject(UUID.randomUUID().toString())
            .claim("tenant", "T68")
            .build();
    assertThat(SecurityConfig.authorities(bare)).isEmpty();
  }

  @Test
  @DisplayName("Claim sub phải là UUID và tenant là Tnn hoặc PLATFORM")
  void claimsValidator() {
    var validator = SecurityConfig.claimsValidator();
    assertThat(validator.validate(jwt(UUID.randomUUID().toString(), "T68")).hasErrors()).isFalse();
    assertThat(validator.validate(jwt(UUID.randomUUID().toString(), "PLATFORM")).hasErrors()).isFalse();
    assertThat(validator.validate(jwt("khong-phai-uuid", "T68")).hasErrors()).isTrue();
    assertThat(validator.validate(jwt(UUID.randomUUID().toString(), "COMMON")).hasErrors()).isTrue();
    assertThat(validator.validate(jwt(UUID.randomUUID().toString(), null)).hasErrors()).isTrue();
  }

  @Test
  @DisplayName("CurrentUser đọc từ JWT")
  void currentUser() {
    UUID sub = UUID.randomUUID();
    CurrentUser user = CurrentUserProvider.from(jwt(sub.toString(), "T68"));
    assertThat(user.id()).isEqualTo(sub);
    assertThat(user.tenant()).isEqualTo("T68");
    assertThat(user.hasPermission("PERM-07-read")).isTrue();
    assertThat(user.hasPermission("PERM-07-update")).isFalse();
    assertThat(CurrentUserProvider.claimSet(jwt(sub.toString(), "T68"), "khong-co")).isEmpty();
  }

  @Test
  @DisplayName("Khóa công khai đọc từ nội dung PEM hoặc từ tệp; thiếu hoặc hỏng thì lỗi rõ ràng")
  void keyLoading(@TempDir Path dir) throws Exception {
    String pem = TestJwt.publicKeyPem();
    assertThat(JwtKeys.load(new JwtProperties(pem, null, null)).getAlgorithm()).isEqualTo("RSA");
    Path file = dir.resolve("public.pem");
    Files.writeString(file, pem);
    assertThat(JwtKeys.load(new JwtProperties("", file, null)).getAlgorithm()).isEqualTo("RSA");
    assertThatThrownBy(() -> JwtKeys.load(new JwtProperties(null, null, null)))
        .isInstanceOf(IllegalStateException.class);
    assertThatThrownBy(() -> JwtKeys.load(new JwtProperties(null, Path.of(""), null)))
        .isInstanceOf(IllegalStateException.class);
    assertThatThrownBy(() -> JwtKeys.load(new JwtProperties(null, dir.resolve("khong-co.pem"), null)))
        .isInstanceOf(IllegalStateException.class);
    assertThatThrownBy(() -> JwtKeys.parse("-----BEGIN PUBLIC KEY-----\nAAAA\n-----END PUBLIC KEY-----"))
        .isInstanceOf(IllegalStateException.class);
    assertThatThrownBy(() -> JwtKeys.parse("!!!")).isInstanceOf(IllegalStateException.class);
    assertThat(Map.of()).isEmpty();
  }
}
