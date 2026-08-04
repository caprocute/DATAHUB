package vn.lgsp.control.routes.api;

import java.util.List;
import java.util.Map;

public record TestRunResultDto(
    String routeCode,
    int versionNo,
    String mode,
    String outcome,
    int durationMs,
    List<Map<String, Object>> waterfall) {}
