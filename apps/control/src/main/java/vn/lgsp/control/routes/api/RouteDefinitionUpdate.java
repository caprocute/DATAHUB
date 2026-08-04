package vn.lgsp.control.routes.api;

import jakarta.validation.constraints.NotBlank;

public record RouteDefinitionUpdate(@NotBlank String definitionYaml) {}
