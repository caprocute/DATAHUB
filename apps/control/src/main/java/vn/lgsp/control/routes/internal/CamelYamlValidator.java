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

  /**
   * Loại tài nguyên Camel tương ứng một tệp YAML (IP-07 K2).
   *
   * Kamelet và Pipe **về cấu trúc không thể** có khung chín chặng: Kamelet là mảnh
   * dùng lại, Pipe là nối nguồn–đích. Bắt chúng theo khung của route là báo lỗi sai.
   */
  enum ResourceKind {
    ROUTE,
    KAMELET,
    PIPE,
    TEST
  }

  ValidationResultDto validate(String yamlText) {
    return validate(yamlText, ResourceKind.ROUTE, false);
  }

  /**
   * Kiểm định nghĩa theo **loại tài nguyên** và mức độ nghiêm ngặt.
   *
   * @param external luồng đối ngoại — khung chín chặng là **bắt buộc**, thiếu thì chặn
   *     publish. Luồng nội bộ chỉ nhận cảnh báo.
   */
  ValidationResultDto validate(String yamlText, ResourceKind kind, boolean external) {
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
    if (!hasShapeFor(kind, parsed)) {
      findings.add(error("ROUTE_SHAPE", shapeMessage(kind)));
    }

    // Khung chín chặng chỉ áp cho **route**; kamelet/pipe/test có hình dạng khác hẳn.
    if (kind == ResourceKind.ROUTE) {
      String lower = yamlText.toLowerCase(Locale.ROOT);
      for (String stage : REQUIRED_STAGES) {
        if (!lower.contains(stage)) {
          // IP-07 K1-7b: luồng **đối ngoại** thì thiếu chặng là lỗi chặn publish thật.
          // Trước đây mọi trường hợp đều chỉ `WARN`, mà `publish()` chỉ chặn khi có
          // `ERROR` — nghĩa là không tầng nào thực sự bắt buộc khung chuẩn.
          findings.add(
              new ValidationFinding(
                  "STAGE_META",
                  "thiếu metadata/chặng '"
                      + stage
                      + "' ("
                      + (external ? "bắt buộc với luồng đối ngoại" : "khuyến nghị khung 9 bước PH-04")
                      + ")",
                  external ? "ERROR" : "WARN"));
        }
      }
    }
    boolean valid = findings.stream().noneMatch(f -> "ERROR".equals(f.severity()));
    return new ValidationResultDto(valid, List.copyOf(findings));
  }

  private static ValidationFinding error(String code, String message) {
    return new ValidationFinding(code, message, "ERROR");
  }

  /** Hình dạng hợp lệ theo từng loại tài nguyên (IP-07 K2-6). */
  private static boolean hasShapeFor(ResourceKind kind, Object parsed) {
    return switch (kind) {
      case ROUTE -> hasRouteShape(parsed);
      case KAMELET -> hasCrdShape(parsed, "Kamelet", "template");
      case PIPE -> hasCrdShape(parsed, "Pipe", "source");
      // Test do bộ chạy thử tự kiểm; ở đây chỉ cần YAML đọc được.
      case TEST -> true;
    };
  }

  private static String shapeMessage(ResourceKind kind) {
    return switch (kind) {
      case ROUTE -> "thiếu khối route/from (Camel YAML DSL: `- route:` + `from:`)";
      case KAMELET -> "thiếu `kind: Kamelet` hoặc `spec.template`";
      case PIPE -> "thiếu `kind: Pipe` hoặc `spec.source`";
      case TEST -> "";
    };
  }

  /** Kamelet/Pipe là CRD: `kind:` ở gốc và một khóa bắt buộc dưới `spec`. */
  private static boolean hasCrdShape(Object parsed, String kind, String specKey) {
    if (!(parsed instanceof Map<?, ?> map)) {
      return false;
    }
    if (!kind.equals(map.get("kind"))) {
      return false;
    }
    return map.get("spec") instanceof Map<?, ?> spec && spec.containsKey(specKey);
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
