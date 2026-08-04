package vn.lgsp.camel.dancu.pipeline;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.apache.camel.builder.RouteBuilder;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Template khung 9 bước PH-04 (WP-20). Gọi {@code direct:pipeline-execute} với header
 * {@code LgspDeliverUri} (tuỳ chọn). Lỗi → seda DLQ + header {@code LgspErrorCode}.
 */
@ApplicationScoped
public class StandardPipelineRoute extends RouteBuilder {

  @Inject StageProcessor stages;

  @ConfigProperty(name = "lgsp.dlq.uri", defaultValue = "seda:dlq")
  String dlqUri;

  @Override
  public void configure() {
    errorHandler(
        deadLetterChannel(dlqUri)
            .maximumRedeliveries(1)
            .redeliveryDelay(200)
            .useOriginalMessage()
            .log("pipeline error → DLQ: ${exception.message}"));

    from("direct:pipeline-execute")
        .routeId("standard-pipeline")
        .process(stages.mark(StageIds.RECEIVE))
        .process(stages.mark(StageIds.SCHEMA))
        .process(
            exchange -> {
              String body = exchange.getMessage().getBody(String.class);
              if (body != null && body.contains("\"__invalid_schema__\"")) {
                stages.failStage(exchange, StageIds.SCHEMA, "SCHEMA_INVALID", "payload không hợp lệ");
                throw new IllegalArgumentException("SCHEMA_INVALID");
              }
            })
        .process(stages.mark(StageIds.AUTHZ))
        .process(stages.mark(StageIds.TRANSFORM))
        .to("direct:pipeline-transform")
        .process(stages.mark(StageIds.ENRICH))
        .process(stages.mark(StageIds.ROUTE))
        .process(stages.mark(StageIds.DELIVER))
        .choice()
          .when(header("LgspDeliverUri").isNotNull())
            .toD("${header.LgspDeliverUri}?bridgeEndpoint=true&throwExceptionOnFailure=true")
          .otherwise()
            .setBody(constant("{\"ok\":true,\"pipeline\":\"template\"}"))
        .end()
        .process(stages.mark(StageIds.AUDIT))
        .process(stages.mark(StageIds.RESPOND))
        .setHeader("X-Lgsp-Stages", constant(String.join(",", StageIds.ORDERED)));

    from("seda:dlq")
        .routeId("dlq-handler")
        .setHeader("LgspDlq", constant(true))
        .log("DLQ LgspErrorCode=${header.LgspErrorCode} stage=${header.LgspStage} msg=${exception.message}");

    from("direct:pipeline-transform")
        .routeId("pipeline-transform-default")
        .to("direct:cdm-map-person");
  }
}
