package vn.lgsp.control.onboarding.api;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Tệp đính kèm hồ sơ kết nạp (FR-01-003).
 *
 * Không lộ khóa đối tượng trong kho: người dùng tải qua `id`, máy chủ tự tra khóa.
 */
public record AttachmentDto(
    UUID id,
    String fileName,
    String contentType,
    long sizeBytes,
    String sha256,
    String uploadedBy,
    OffsetDateTime createdAt) {}
