package vn.lgsp.control.routes.api;

import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Một dòng trong danh sách luồng (FR-D-002).
 *
 * `updatedBy`/`updatedAt` bổ sung ở IP-06 G2-2: khi có sự cố, câu hỏi đầu tiên luôn là
 * "ai sửa gần nhất, lúc nào" — thiếu hai cột này phải mở từng phiên bản ra dò.
 */
public record RouteSummaryDto(
    UUID routeId,
    String routeCode,
    String title,
    String routeType,
    String status,
    String sourceSystem,
    String targetSystem,
    UUID currentVersionId,
    Integer draftVersionNo,
    Integer currentVersionNo,
    String gitCommitRef,
    String updatedBy,
    OffsetDateTime updatedAt) {}
