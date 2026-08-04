package vn.lgsp.camel.dancu.cdm;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import jakarta.enterprise.context.ApplicationScoped;
import org.apache.camel.Exchange;
import org.apache.camel.Processor;

/**
 * Mapper HTTT giả → CDM person.v1 (tương đương {@code contracts/cdm/mappers/legacy-citizen-to-person.jq}).
 */
@ApplicationScoped
public class LegacyCitizenToPersonMapper implements Processor {

  private final ObjectMapper mapper = new ObjectMapper();

  @Override
  public void process(Exchange exchange) throws Exception {
    String raw = exchange.getMessage().getBody(String.class);
    if (raw == null || raw.isBlank()) {
      return;
    }
    JsonNode in = mapper.readTree(raw);
    // Bỏ qua nếu đã là CDM hoặc không phải citizen legacy
    if (in.hasNonNull("personId") && in.hasNonNull("fullName") && !in.has("hoTen") && !in.has("maCongDan")) {
      return;
    }
    if (!in.has("hoTen") && !in.has("maCongDan") && !in.has("citizenId") && !in.has("fullName")) {
      return;
    }
    ObjectNode out = mapper.createObjectNode();
    out.put("personId", text(in, "maCongDan", "citizenId", "id"));
    out.put("fullName", text(in, "hoTen", "fullName"));
    String dob = textOrNull(in, "ngaySinh", "dob", "dateOfBirth");
    if (dob != null) {
      out.put("dateOfBirth", dob);
    }
    String nid = textOrNull(in, "soCMND", "nationalId");
    if (nid != null) {
      out.put("nationalId", nid);
    }
    exchange.getMessage().setBody(mapper.writeValueAsString(out));
    exchange.getMessage().setHeader("Content-Type", "application/json");
    exchange.getMessage().setHeader("X-Lgsp-Cdm", "person.v1");
  }

  private static String text(JsonNode in, String... keys) {
    String v = textOrNull(in, keys);
    return v != null ? v : "";
  }

  private static String textOrNull(JsonNode in, String... keys) {
    for (String k : keys) {
      JsonNode n = in.get(k);
      if (n != null && !n.isNull()) {
        return n.asText();
      }
    }
    return null;
  }
}
