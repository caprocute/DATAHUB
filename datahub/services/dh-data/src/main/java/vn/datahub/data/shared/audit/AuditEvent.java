package vn.datahub.data.shared.audit;

import java.util.Map;
import org.jspecify.annotations.Nullable;

/** Một sự kiện kiểm toán: hành động, đối tượng, và các trường đổi (chỉ trường đổi). */
public record AuditEvent(
    String action,
    String aggregateType,
    String aggregateId,
    @Nullable Map<String, Object> before,
    @Nullable Map<String, Object> after) {}
