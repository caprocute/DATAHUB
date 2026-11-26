package vn.datahub.data.support;

import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import vn.datahub.data.DataApplication;

/**
 * Nền chung của kiểm thử tích hợp: ứng dụng thật trên cổng ngẫu nhiên, CSDL PostgreSQL 18 thật,
 * khóa JWT thử sinh lúc chạy. Mọi lớp kế thừa dùng chung một ngữ cảnh Spring.
 */
@SpringBootTest(classes = DataApplication.class, webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public abstract class ApiTest {

  @DynamicPropertySource
  static void properties(DynamicPropertyRegistry registry) {
    registry.add("spring.datasource.url", TestPostgres::jdbcUrl);
    registry.add("spring.datasource.username", () -> TestPostgres.APP_USER);
    registry.add("spring.datasource.password", () -> TestPostgres.APP_PASSWORD);
    registry.add("datahub.security.jwt.public-key", TestJwt::publicKeyPem);
  }
}
