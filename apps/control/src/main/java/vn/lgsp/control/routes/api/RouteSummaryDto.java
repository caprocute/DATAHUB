package vn.lgsp.control.routes.api;

import java.util.UUID;

public record RouteSummaryDto(
    UUID routeId,
    String routeCode,
    String title,
    String routeType,
    String status,
    String sourceSystem,
    String targetSystem,
    UUID currentVersionId,
    Integer draftVersionNo,
    Integer currentVersionNo,
    String gitCommitRef) {}
