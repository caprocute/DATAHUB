package vn.datahub.data.rdm.internal;

import java.util.UUID;
import org.jspecify.annotations.Nullable;

/**
 * Lệnh sửa nhóm theo merge-patch: trường vắng mặt thì giữ nguyên (cờ {@code has*}), trường có giá
 * trị null (parentId, description) nghĩa là đặt về rỗng.
 */
public record UpdateGroupCommand(
    boolean hasName,
    @Nullable String name,
    boolean hasParentId,
    @Nullable UUID parentId,
    boolean hasSortOrder,
    int sortOrder,
    boolean hasDescription,
    @Nullable String description) {}
