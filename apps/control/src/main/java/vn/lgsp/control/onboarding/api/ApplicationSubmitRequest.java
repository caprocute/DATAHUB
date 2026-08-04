package vn.lgsp.control.onboarding.api;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Hồ sơ đăng ký kết nạp (FR-01-001, FR-01-003).
 *
 * Căn cứ pháp lý và hồ sơ năng lực kỹ thuật là bắt buộc: hai bước thẩm định
 * (FR-01-004 / FR-01-005) không có gì để thẩm định nếu thiếu.
 */
public record ApplicationSubmitRequest(
    @NotBlank
        @Pattern(
            regexp = "^[A-Z][A-Z0-9_]{2,63}$",
            message = "mã hệ thống viết hoa, dùng chữ số và gạch dưới, 3–64 ký tự")
        String systemCode,
    @NotBlank @Size(max = 255) String systemName,
    @NotBlank @Size(max = 255) String ownerOrg,
    @NotBlank(message = "phải nêu căn cứ pháp lý") String legalBasis,
    @NotBlank(message = "phải khai hồ sơ năng lực kỹ thuật") String techProfile,
    @NotBlank @Size(max = 255) String contactName,
    @NotBlank @Email @Size(max = 255) String contactEmail,
    @Size(max = 64) String contactPhone) {}
