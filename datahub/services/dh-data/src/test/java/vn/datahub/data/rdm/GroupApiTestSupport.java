package vn.datahub.data.rdm;

import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.junit.jupiter.api.BeforeEach;
import vn.datahub.data.support.Api;
import vn.datahub.data.support.ApiTest;
import vn.datahub.data.support.Db;
import vn.datahub.data.support.TestJwt;

/** Nền cho IT của nhóm danh mục: HTTP thật, dữ liệu về seed trước mỗi test. */
abstract class GroupApiTestSupport extends ApiTest {

  @Value("${local.server.port}")
  int port;

  Api api;

  @BeforeEach
  void resetData() {
    Db.resetToSeed();
    api = new Api(port);
  }

  static String tokenFor(String role, String tenant) {
    return TestJwt.token(TestJwt.persona(role, tenant, UUID.randomUUID()));
  }
}
