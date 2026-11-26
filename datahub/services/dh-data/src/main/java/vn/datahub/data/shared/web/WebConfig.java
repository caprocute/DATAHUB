package vn.datahub.data.shared.web;

import java.time.Clock;
import tools.jackson.databind.cfg.CoercionAction;
import tools.jackson.databind.cfg.CoercionInputShape;
import tools.jackson.databind.type.LogicalType;
import org.springframework.boot.jackson.autoconfigure.JsonMapperBuilderCustomizer;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration(proxyBeanMethods = false)
class WebConfig {

  @Bean
  Clock clock() {
    return Clock.systemUTC();
  }

  /**
   * Thân JSON phải đúng kiểu OpenAPI: số hoặc logic ở trường chuỗi (name: 5) bị từ chối (422 TYPE),
   * không tự ép thành chuỗi.
   */
  @Bean
  JsonMapperBuilderCustomizer strictTextCoercion() {
    return builder ->
        builder.withCoercionConfig(
            LogicalType.Textual,
            config -> {
              config.setCoercion(CoercionInputShape.Integer, CoercionAction.Fail);
              config.setCoercion(CoercionInputShape.Float, CoercionAction.Fail);
              config.setCoercion(CoercionInputShape.Boolean, CoercionAction.Fail);
            });
  }

  /** Chạy trước chuỗi lọc bảo mật (order -100) để lỗi 401 cũng có traceId. */
  @Bean
  FilterRegistrationBean<TraceFilter> traceFilter() {
    FilterRegistrationBean<TraceFilter> reg = new FilterRegistrationBean<>(new TraceFilter());
    reg.setOrder(-200);
    return reg;
  }

  @Bean
  FilterRegistrationBean<RequestLimitsFilter> requestLimitsFilter(ProblemWriter problems) {
    FilterRegistrationBean<RequestLimitsFilter> reg =
        new FilterRegistrationBean<>(new RequestLimitsFilter(problems));
    reg.setOrder(-150);
    return reg;
  }
}
