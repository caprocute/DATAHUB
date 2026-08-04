package vn.lgsp.control.routes.internal;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Pattern;
import org.springframework.stereotype.Component;
import org.yaml.snakeyaml.Yaml;
import vn.lgsp.control.routes.api.ValidationFinding;
import vn.lgsp.control.routes.api.ValidationResultDto;

/** Validate Camel YAML DSL tối thiểu trước submit/publish (WP-23). */
@Component
class CamelYamlValidator {

  private static final Pattern SECRET_PATTERN =
      Pattern.compile(
          "(?i)(password|client[_-]?secret|api[_-]?key|private[_-]?key)\\s*[:=]\\s*\\S+");

  private static final String[] REQUIRED_STAGES = {
    "receive", "schema", "authz", "transform", "enrich", "route", "deliver", "audit", "respond"
  };

  ValidationResultDto validate(String yamlText) {
    List<ValidationFinding> findings = new ArrayList<>();
    if (yamlText == null || yamlText.isBlank()) {
      findings.add(error("EMPTY", "definitionYaml trống"));
      return new ValidationResultDto(false, findings);
    }
    if (SECRET_PATTERN.matcher(yamlText).find()) {
      findings.add(error("SECRET", "phát hiện chuỗi giống secret trong YAML — không được publish"));
    }
    Object parsed;
    try {
      parsed = new Yaml().load(yamlText);
    } catch (Exception e) {
      findings.add(error("YAML_PARSE", "YAML không hợp lệ: " + e.getMessage()));
      return new ValidationResultDto(false, findings);
    }
    if (parsed == null) {
      findings.add(error("YAML_EMPTY", "YAML parse ra null"));
      return new ValidationResultDto(false, findings);
    }
    if (!hasRouteShape(parsed)) {
      findings.add(
          error("ROUTE_SHAPE", "thiếu khối route/from (Camel YAML DSL: `- route:` + `from:`)"));
    }
    String lower = yamlText.toLowerCase(Locale.ROOT);
    for (String stage : REQUIRED_STAGES) {
      if (!lower.contains(stage)) {
        findings.add(
            new ValidationFinding(
                "STAGE_META",
                "thiếu metadata/chặng '" + stage + "' (khuyến nghị khung 9 bước PH-04)",
                "WARN"));
      }
    }
    boolean valid = findings.stream().noneMatch(f -> "ERROR".equals(f.severity()));
    return new ValidationResultDto(valid, List.copyOf(findings));
  }

  private static ValidationFinding error(String code, String message) {
    return new ValidationFinding(code, message, "ERROR");
  }

  @SuppressWarnings("unchecked")
  private static boolean hasRouteShape(Object parsed) {
    if (parsed instanceof List<?> list) {
      for (Object item : list) {
        if (item instanceof Map<?, ?> map && map.containsKey("route")) {
          Object route = map.get("route");
          if (route instanceof Map<?, ?> rm && rm.containsKey("from")) {
            return true;
          }
        }
      }
      return false;
    }
    if (parsed instanceof Map<?, ?> map) {
      if (map.containsKey("route")) {
        Object route = map.get("route");
        return route instanceof Map<?, ?> rm && rm.containsKey("from");
      }
      // YAML DSL đôi khi bọc trong camel / routes
      Object routes = map.get("routes");
      if (routes != null) {
        return hasRouteShape(routes);
      }
    }
    return false;
  }
}
