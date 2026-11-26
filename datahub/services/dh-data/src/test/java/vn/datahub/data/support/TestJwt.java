package vn.datahub.data.support;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.RSASSASigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;
import java.util.List;
import java.util.UUID;

/** Khóa RS256 thử SINH LÚC CHẠY (không có khóa nào trong mã) và bộ đúc token theo vai trò. */
public final class TestJwt {

  private static final KeyPair PAIR = generate();
  private static final KeyPair OTHER = generate();

  private TestJwt() {}

  private static KeyPair generate() {
    try {
      KeyPairGenerator gen = KeyPairGenerator.getInstance("RSA");
      gen.initialize(2048);
      return gen.generateKeyPair();
    } catch (java.security.GeneralSecurityException e) {
      throw new IllegalStateException(e);
    }
  }

  /** Khóa công khai PEM để cấu hình cho ứng dụng. */
  public static String publicKeyPem() {
    return pem(PAIR);
  }

  private static String pem(KeyPair pair) {
    String body =
        Base64.getMimeEncoder(64, "\n".getBytes(java.nio.charset.StandardCharsets.US_ASCII))
            .encodeToString(pair.getPublic().getEncoded());
    return "-----BEGIN PUBLIC KEY-----\n" + body + "\n-----END PUBLIC KEY-----\n";
  }

  /** Vai trò mẫu theo quy ước của Gherkin: TA, DS, PA (D02-08). */
  public record Persona(UUID sub, String tenant, List<String> perms, List<String> roles) {}

  public static Persona persona(String role, String tenant, UUID sub) {
    return switch (role) {
      case "TA" ->
          new Persona(sub, tenant, List.of("PERM-07-read", "PERM-07-create", "PERM-07-update"), List.of("TENANT_ADMIN"));
      case "DS" -> new Persona(sub, tenant, List.of("PERM-07-read"), List.of("DATA_STEWARD"));
      case "PA" ->
          new Persona(
              sub,
              tenant,
              List.of(
                  "PERM-07-read",
                  "PERM-07-create",
                  "PERM-07-update",
                  "PERM-07-submit",
                  "PERM-07-publish",
                  "PERM-07-export",
                  "PERM-07-sync"),
              List.of("PLATFORM_ADMIN"));
      default -> throw new IllegalArgumentException("Vai trò lạ: " + role);
    };
  }

  public static String token(Persona p) {
    return sign(PAIR, p.sub().toString(), p.tenant(), p.perms(), p.roles(), Instant.now().plusSeconds(600));
  }

  public static String token(String sub, String tenant, List<String> perms, List<String> roles) {
    return sign(PAIR, sub, tenant, perms, roles, Instant.now().plusSeconds(600));
  }

  public static String expired(Persona p) {
    return sign(PAIR, p.sub().toString(), p.tenant(), p.perms(), p.roles(), Instant.now().minusSeconds(3600));
  }

  /** Token ký bằng khóa khác khóa ứng dụng tin cậy. */
  public static String signedByStranger(Persona p) {
    return sign(OTHER, p.sub().toString(), p.tenant(), p.perms(), p.roles(), Instant.now().plusSeconds(600));
  }

  private static String sign(
      KeyPair pair, String sub, String tenant, List<String> perms, List<String> roles, Instant exp) {
    try {
      JWTClaimsSet claims =
          new JWTClaimsSet.Builder()
              .subject(sub)
              .claim("tenant", tenant)
              .claim("perms", perms)
              .claim("roles", roles)
              .issueTime(new Date())
              .expirationTime(Date.from(exp))
              .build();
      SignedJWT jwt = new SignedJWT(new JWSHeader(JWSAlgorithm.RS256), claims);
      jwt.sign(new RSASSASigner((RSAPrivateKey) pair.getPrivate()));
      return jwt.serialize();
    } catch (com.nimbusds.jose.JOSEException e) {
      throw new IllegalStateException(e);
    }
  }

  static RSAPublicKey publicKey() {
    return (RSAPublicKey) PAIR.getPublic();
  }
}
