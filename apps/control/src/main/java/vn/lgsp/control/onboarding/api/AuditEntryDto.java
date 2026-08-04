package vn.lgsp.control.onboarding.api;

import java.time.OffsetDateTime;
import java.util.UUID;

/** Một dòng nhật ký kiểm toán của hồ sơ (C4-5). */
public record AuditEntryDto(
    UUID id,
    String action,
    String fromStatus,
    String toStatus,
    String actor,
    String note,
    OffsetDateTime createdAt) {}
