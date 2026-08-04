package vn.lgsp.control.onboarding.api;

import jakarta.validation.constraints.NotBlank;

/**
 * Đổi trạng thái có lý do: từ chối, tạm ngừng, khôi phục, thu hồi
 * (FR-01-006 E1, FR-01-011, FR-01-012).
 *
 * Lý do bắt buộc — đây là dấu vết để rà soát về sau.
 */
public record StatusChangeRequest(@NotBlank(message = "phải ghi lý do") String reason) {}
