package vn.lgsp.control.onboarding.api;

import jakarta.validation.constraints.NotBlank;

public record ApplicationSubmitRequest(
    @NotBlank String systemCode,
    @NotBlank String systemName,
    @NotBlank String ownerOrg) {}
