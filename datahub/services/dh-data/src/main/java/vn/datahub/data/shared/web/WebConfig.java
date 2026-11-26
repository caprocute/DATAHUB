package vn.datahub.data.shared.web;

import java.time.Clock;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration(proxyBeanMethods = false)
class WebConfig {

  @Bean
  Clock clock() {
    return Clock.systemUTC();
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
