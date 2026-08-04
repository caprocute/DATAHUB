package vn.lgsp.camel.dancu;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import java.util.UUID;
import org.apache.camel.Exchange;
import org.apache.camel.builder.RouteBuilder;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import vn.lgsp.camel.dancu.pipeline.StageIds;
import vn.lgsp.camel.dancu.pipeline.StageProcessor;

/** Thin-slice + khung 9 bước: APISIX → pipeline → adapter resolve → WireMock. */
@ApplicationScoped
public class TraCuuRoute extends RouteBuilder {

  @ConfigProperty(name = "lgsp.adapter-mgr.base-url", defaultValue = "http://localhost:8082")
  String adapterMgrBaseUrl;

  @ConfigProperty(name = "lgsp.adapter.id", defaultValue = "http-mock-tra-cuu")
  String adapterId;

  @Inject StageProcessor stages;

  private final ObjectMapper mapper = new ObjectMapper();

  @Override
  public void configure() {
    onException(Exception.class)
        .handled(true)
        .setHeader(Exchange.HTTP_RESPONSE_CODE, constant(502))
        .setHeader(Exchange.CONTENT_TYPE, constant("application/json"))
        .setBody(
            simple(
                "{\"title\":\"Bad Gateway\",\"detail\":\"${exception.message}\",\"stage\":\"${header.LgspStage}\",\"errorCode\":\"${header.LgspErrorCode}\"}"));

    from("platform-http:/demo/tra-cuu?httpMethodRestrict=GET")
        .routeId("demo-tra-cuu")
        .process(this::ensureTrace)
        .process(stages.mark(StageIds.RECEIVE))
        .process(this::clearHttpHeaders)
        .setHeader(Exchange.HTTP_METHOD, constant("GET"))
        .process(stages.mark(StageIds.SCHEMA))
        .process(stages.mark(StageIds.AUTHZ))
        .toD(
            adapterMgrBaseUrl
                + "/api/v1/adapters/"
                + adapterId
                + "/resolve?bridgeEndpoint=true&throwExceptionOnFailure=true")
        .process(this::extractEndpoint)
        .process(stages.mark(StageIds.TRANSFORM))
        .process(stages.mark(StageIds.ENRICH))
        .process(stages.mark(StageIds.ROUTE))
        .process(this::clearHttpHeaders)
        .setHeader(Exchange.HTTP_METHOD, constant("GET"))
        .process(stages.mark(StageIds.DELIVER))
        .toD(
            "${header.LgspTargetUrl}?bridgeEndpoint=true&throwExceptionOnFailure=true"
                + "&connectTimeout=3000&socketTimeout=5000")
        .process(stages.mark(StageIds.AUDIT))
        .process(stages.mark(StageIds.RESPOND))
        .setHeader("X-Trace-Id", simple("${header.LgspTraceId}"))
        .setHeader("X-Lgsp-Stages", constant(String.join(",", StageIds.ORDERED)))
        .setHeader(Exchange.CONTENT_TYPE, constant("application/json"));
  }

  private void clearHttpHeaders(Exchange exchange) {
    exchange.getMessage().removeHeaders("CamelHttp*");
    exchange.getMessage().removeHeader(Exchange.HTTP_PATH);
    exchange.getMessage().removeHeader(Exchange.HTTP_URI);
    exchange.getMessage().removeHeader(Exchange.HTTP_QUERY);
    exchange.getMessage().setBody(null);
  }

  private void ensureTrace(Exchange exchange) {
    String trace = exchange.getMessage().getHeader("traceparent", String.class);
    String traceId;
    if (trace != null && trace.contains("-")) {
      String[] parts = trace.split("-");
      traceId = parts.length > 1 ? parts[1] : UUID.randomUUID().toString().replace("-", "");
    } else {
      traceId = UUID.randomUUID().toString().replace("-", "");
      exchange
          .getMessage()
          .setHeader("traceparent", "00-" + traceId + "-" + traceId.substring(0, 16) + "-01");
    }
    exchange.getMessage().setHeader("LgspTraceId", traceId);
  }

  private void extractEndpoint(Exchange exchange) throws Exception {
    String body = exchange.getMessage().getBody(String.class);
    String url;
    try {
      JsonNode node = mapper.readTree(body);
      url = node.path("endpointUrl").asText(null);
    } catch (Exception e) {
      url = null;
    }
    if (url == null || url.isBlank()) {
      int i = body.indexOf("\"endpointUrl\"");
      if (i < 0) {
        throw new IllegalStateException("adapter resolve thiếu endpointUrl: " + body);
      }
      int colon = body.indexOf(':', i);
      int start = body.indexOf('"', colon) + 1;
      int end = body.indexOf('"', start);
      url = body.substring(start, end);
    }
    exchange.getMessage().setHeader("LgspTargetUrl", url);
  }
}
