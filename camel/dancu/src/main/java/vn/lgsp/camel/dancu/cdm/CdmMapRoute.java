package vn.lgsp.camel.dancu.cdm;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.apache.camel.builder.RouteBuilder;

/** Route thí điểm CDM (WP-22): POST body legacy → person.v1. */
@ApplicationScoped
public class CdmMapRoute extends RouteBuilder {

  @Inject LegacyCitizenToPersonMapper mapper;

  @Override
  public void configure() {
    from("direct:cdm-map-person")
        .routeId("cdm-map-person")
        .process(mapper);

    from("platform-http:/demo/cdm/person?httpMethodRestrict=POST")
        .routeId("demo-cdm-person")
        .to("direct:cdm-map-person");
  }
}
