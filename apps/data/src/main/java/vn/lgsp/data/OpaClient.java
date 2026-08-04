package vn.lgsp.data;

import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

/** PEP HTTP tới OPA `/v1/data/lgsp/authz/allow` — fail-closed khi OPA lỗi. */
@Component
public class OpaClient {

  private static final Logger log = LoggerFactory.getLogger(OpaClient.class);

  private final OpaProperties properties;
  private final RestClient restClient = RestClient.create();

  public OpaClient(OpaProperties properties) {
    this.properties = properties;
  }

  public boolean allow(String action, Collection<String> roles) {
    if (!properties.isEnabled()) {
      return true;
    }
    try {
      Map<String, Object> input = new LinkedHashMap<>();
      input.put("action", action);
      input.put("roles", roles == null ? List.of() : List.copyOf(roles));
      @SuppressWarnings("unchecked")
      Map<String, Object> resp =
          restClient
              .post()
              .uri(trimSlash(properties.getUrl()) + "/v1/data/lgsp/authz/allow")
              .body(Map.of("input", input))
              .retrieve()
              .body(Map.class);
      if (resp == null) {
        return false;
      }
      Object result = resp.get("result");
      return Boolean.TRUE.equals(result);
    } catch (Exception e) {
      log.warn("OPA unreachable — deny (fail-closed): {}", e.toString());
      return false;
    }
  }

  private static String trimSlash(String url) {
    if (url == null || url.isBlank()) {
      return "http://localhost:8181";
    }
    return url.endsWith("/") ? url.substring(0, url.length() - 1) : url;
  }
}
