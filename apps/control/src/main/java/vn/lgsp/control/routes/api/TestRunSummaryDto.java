package vn.lgsp.control.routes.api;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Một lần chạy thử trong nhật ký (FR-D-040).
 *
 * Chỉ siêu dữ liệu: không mang thân bản tin hay tiêu đề — xem ghi chú ATTT ở changeset
 * `006-d-route-test-run`.
 */
public record TestRunSummaryDto(
    UUID runId,
    String routeCode,
    int versionNo,
    String mode,
    String outcome,
    int durationMs,
    String traceId,
    String runBy,
    OffsetDateTime runAt,
    /** Số chặng đã ghi; chi tiết lấy qua API chi tiết lần chạy. */
    int stageCount) {}
