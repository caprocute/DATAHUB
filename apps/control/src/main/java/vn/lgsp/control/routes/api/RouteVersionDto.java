package vn.lgsp.control.routes.api;

import java.util.UUID;

public record RouteVersionDto(
    UUID versionId,
    UUID routeId,
    String routeCode,
    int versionNo,
    String status,
    String definitionYaml,
    String gitCommitRef,
    String gitPath,
    String source) {}
