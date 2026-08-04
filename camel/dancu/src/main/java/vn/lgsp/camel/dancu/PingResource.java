package vn.lgsp.camel.dancu;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import org.apache.camel.ProducerTemplate;

@Path("/ping")
public class PingResource {

  @Inject
  ProducerTemplate producerTemplate;

  @GET
  @Produces(MediaType.TEXT_PLAIN)
  public String ping() {
    return producerTemplate.requestBody("direct:health", null, String.class);
  }
}
