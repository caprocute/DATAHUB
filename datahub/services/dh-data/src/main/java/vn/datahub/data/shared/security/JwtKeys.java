package vn.datahub.data.shared.security;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.security.GeneralSecurityException;
import java.security.KeyFactory;
import java.security.interfaces.RSAPublicKey;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

/** Đọc khóa công khai RSA dạng PEM (SubjectPublicKeyInfo). */
final class JwtKeys {

  private JwtKeys() {}

  static RSAPublicKey load(JwtProperties props) {
    String pem = props.publicKey();
    if ((pem == null || pem.isBlank())
        && props.publicKeyFile() != null
        && !props.publicKeyFile().toString().isEmpty()) {
      try {
        pem = Files.readString(props.publicKeyFile(), StandardCharsets.UTF_8);
      } catch (IOException e) {
        throw new IllegalStateException("Không đọc được tệp khóa công khai JWT", e);
      }
    }
    if (pem == null || pem.isBlank()) {
      throw new IllegalStateException(
          "Chưa cấu hình datahub.security.jwt.public-key hoặc public-key-file");
    }
    return parse(pem);
  }

  static RSAPublicKey parse(String pem) {
    String base64 =
        pem.replace("-----BEGIN PUBLIC KEY-----", "")
            .replace("-----END PUBLIC KEY-----", "")
            .replaceAll("\\s+", "");
    try {
      byte[] der = Base64.getDecoder().decode(base64);
      return (RSAPublicKey)
          KeyFactory.getInstance("RSA").generatePublic(new X509EncodedKeySpec(der));
    } catch (GeneralSecurityException | IllegalArgumentException e) {
      throw new IllegalStateException("Khóa công khai JWT không hợp lệ", e);
    }
  }
}
