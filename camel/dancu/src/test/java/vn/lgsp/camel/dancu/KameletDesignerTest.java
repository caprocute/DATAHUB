package vn.lgsp.camel.dancu;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.util.concurrent.TimeUnit;
import org.apache.camel.CamelContext;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.component.mock.MockEndpoint;
import org.junit.jupiter.api.Test;

/**
 * Cổng nghiệm thu <b>N-2b</b> (IP-07 §10): Camel thật phải nạp được <b>Kamelet do trình
 * thiết kế sinh</b>, không chỉ route.
 *
 * <p>Trước đây cổng này ⛔ vì kho Maven offline thiếu {@code camel-quarkus-kamelet}, nên
 * IP-07 phải thay bằng đối chiếu cấu trúc với lược đồ nhà sản xuất — tức là
 * <em>chưa từng chạy thật</em>. Nay gói tải được thì kiểm thẳng.
 *
 * <p>Tệp Kamelet ở {@code src/test/resources/kamelets/lgsp-echo-source.kamelet.yaml} là
 * bản đã quay vòng qua chính lõi designer ({@code deserialize} → {@code serialize}), nên
 * test này chứng minh đúng thứ cần chứng minh: <b>đầu ra của designer nạp được</b>.
 */
@QuarkusTest
class KameletDesignerTest {

  @Inject CamelContext context;

  /**
   * Kamelet nạp được và <b>chạy ra đúng thân bản tin</b>.
   *
   * <p>Chỉ khẳng định "route Started" là không đủ — đó chính là bài học lỗi #5 của IP-07:
   * route vẫn khởi động bình thường trong khi thân bản tin đã biến mất. Ở đây phải thấy
   * giá trị thật đi tới đích.
   */
  @Test
  void kameletDesignerSinhRaChayDuocTrenCamelThat() throws Exception {
    context.addRoutes(
        new RouteBuilder() {
          @Override
          public void configure() {
            from("kamelet:lgsp-echo-source?message=lgsp-kamelet:ok")
                .routeId("n2b-kamelet-consumer")
                .to("mock:n2b");
          }
        });

    MockEndpoint mock = context.getEndpoint("mock:n2b", MockEndpoint.class);
    mock.expectedMessageCount(1);
    mock.setAssertPeriod(0);
    mock.assertIsSatisfied(10_000);

    String body = mock.getExchanges().get(0).getIn().getBody(String.class);
    assertEquals("lgsp-kamelet:ok", body, "than ban tin phai con nguyen qua Kamelet");
    assertTrue(
        context.getRouteController().getRouteStatus("n2b-kamelet-consumer").isStarted(),
        "route tieu thu Kamelet phai o trang thai Started");
  }
}
