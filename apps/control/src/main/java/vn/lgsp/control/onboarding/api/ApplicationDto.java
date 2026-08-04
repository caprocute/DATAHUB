package vn.lgsp.control.onboarding.api;

import java.util.UUID;

public record ApplicationDto(
    UUID id,
    String systemCode,
    String systemName,
    String ownerOrg,
    String status,
    String clientId,
    String clientSecretSealed) {}
