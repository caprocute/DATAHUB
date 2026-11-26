package vn.datahub.data.shared.security;

import java.nio.file.Path;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Cấu hình xác minh JWT RS256. Khóa CÔNG KHAI dạng PEM (nội dung hoặc tệp); không có khóa riêng,
 * không có bí mật trong mã. Nguồn thật (JWKS của Keycloak) nối ở lát cắt sau (SS-07-09).
 */
@ConfigurationProperties("datahub.security.jwt")
public record JwtProperties(String publicKey, Path publicKeyFile, String issuer) {}
