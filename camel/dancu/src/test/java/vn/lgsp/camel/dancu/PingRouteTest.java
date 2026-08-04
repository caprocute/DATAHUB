package vn.lgsp.camel.dancu;

import static org.junit.jupiter.api.Assertions.assertEquals;

import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import org.apache.camel.ProducerTemplate;
import org.junit.jupiter.api.Test;

@QuarkusTest
class PingRouteTest {

  @Inject
  ProducerTemplate producerTemplate;

  @Test
  void pingRouteReturnsOk() {
    String body = producerTemplate.requestBody("direct:health", null, String.class);
    assertEquals("lgsp-camel-dancu:ok", body);
  }
}
