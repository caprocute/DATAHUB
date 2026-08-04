package vn.lgsp.control.routes.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Nhân bản một luồng thành luồng mới ở trạng thái nháp (FR-D-002).
 *
 * Bản sao luôn bắt đầu lại từ phiên bản 1 và **không** kế thừa `git_commit_ref` — nó
 * chưa từng được publish, gán vết commit của bản gốc là nói dối lịch sử triển khai.
 */
public record RouteDuplicateRequest(
    @NotBlank @Pattern(regexp = "^[a-z][a-z0-9-]{2,63}$") String routeCode,
    @NotBlank @Size(max = 255) String title) {}
