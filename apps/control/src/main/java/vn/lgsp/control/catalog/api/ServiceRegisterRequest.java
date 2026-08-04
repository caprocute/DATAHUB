package vn.lgsp.control.catalog.api;

import jakarta.validation.constraints.NotBlank;

public record ServiceRegisterRequest(
    @NotBlank String serviceCode,
    @NotBlank String title,
    @NotBlank String openapiYaml,
    String publicPath,
    String upstreamUrl) {}
