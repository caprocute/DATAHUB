package vn.lgsp.control.routes.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record RouteCreateRequest(
    @NotBlank @Pattern(regexp = "^[a-z0-9-]+$") String routeCode,
    @NotBlank String title,
    String routeType,
    @NotBlank String sourceSystem,
    String targetSystem,
    @NotBlank String definitionYaml) {}
