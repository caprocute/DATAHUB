package vn.lgsp.control.onboarding.api;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Hồ sơ kết nạp.
 *
 * `clientSecretSealed` **chỉ** có giá trị ngay sau lần duyệt cấp danh tính (one-shot);
 * mọi lối đọc khác trả `null` (FR-01-009, C2-3).
 */
public record ApplicationDto(
    UUID id,
    String systemCode,
    String systemName,
    String ownerOrg,
    String status,
    String clientId,
    String clientSecretSealed,
    String legalBasis,
    String techProfile,
    String contactName,
    String contactEmail,
    String contactPhone,
    String submittedBy,
    String approvedBy,
    String statusReason,
    ReviewDto legalReview,
    ReviewDto techReview,
    OffsetDateTime createdAt,
    OffsetDateTime updatedAt) {}
