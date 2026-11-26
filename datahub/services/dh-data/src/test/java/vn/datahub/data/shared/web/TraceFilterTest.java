package vn.datahub.data.shared.web;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class TraceFilterTest {

  private static final String VALID = "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01";

  @Test
  @DisplayName("traceId lấy từ traceparent hợp lệ")
  void usesTraceparent() {
    assertThat(TraceFilter.parse(VALID)).isEqualTo("4bf92f3577b34da6a3ce929d0e0e4736");
  }

  @Test
  @DisplayName("Thiếu, sai định dạng hoặc toàn số 0 thì sinh traceId mới 32 hex")
  void generatesWhenInvalid() {
    for (String bad : new String[] {null, "", "xyz", "00-" + "0".repeat(32) + "-00f067aa0ba902b7-01"}) {
      assertThat(TraceFilter.parse(bad)).matches("^[0-9a-f]{32}$").isNotEqualTo("0".repeat(32));
    }
  }

  @Test
  @DisplayName("Bộ lọc gắn traceId vào yêu cầu và dọn MDC sau khi xử lý")
  void filterSetsAttribute() throws Exception {
    MockHttpServletRequest request = new MockHttpServletRequest();
    request.addHeader("traceparent", VALID);
    new TraceFilter().doFilter(request, new MockHttpServletResponse(), new MockFilterChain());
    assertThat(TraceFilter.traceId(request)).isEqualTo("4bf92f3577b34da6a3ce929d0e0e4736");
    assertThat(org.slf4j.MDC.get(TraceFilter.MDC_KEY)).isNull();
  }

  @Test
  @DisplayName("traceId của yêu cầu chưa qua bộ lọc vẫn có giá trị hợp lệ")
  void fallbackTraceId() {
    HttpServletRequest request = new MockHttpServletRequest();
    assertThat(TraceFilter.traceId(request)).matches("^[0-9a-f]{32}$");
  }
}
