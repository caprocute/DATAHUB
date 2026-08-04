package vn.lgsp.control.routes.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Đổi tên hiển thị của luồng (FR-D-002). Mã luồng **không** đổi được — nó là khóa GitOps. */
public record RouteRenameRequest(@NotBlank @Size(max = 255) String title) {}
