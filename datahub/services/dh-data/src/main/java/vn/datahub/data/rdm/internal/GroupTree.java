package vn.datahub.data.rdm.internal;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.jspecify.annotations.Nullable;

/**
 * Quy tắc cây nhóm thuần (không phụ thuộc Spring/CSDL): độ sâu ≤ 5 (BR-07-014), không vòng. Cấp
 * của nhóm gốc là 1.
 */
final class GroupTree {

  static final int MAX_DEPTH = 5;

  /** Kết quả kiểm tra gắn nhóm vào nhóm cha. */
  enum Violation {
    CYCLE,
    DEPTH
  }

  private final Map<UUID, @Nullable UUID> parentOf = new HashMap<>();
  private final Map<UUID, List<UUID>> childrenOf = new HashMap<>();

  GroupTree(Map<UUID, @Nullable UUID> parents) {
    parentOf.putAll(parents);
    parents.forEach(
        (id, parent) -> {
          if (parent != null) {
            childrenOf.computeIfAbsent(parent, k -> new ArrayList<>()).add(id);
          }
        });
  }

  /** Cấp của nút (gốc = 1). Nút không có trong cây (nhóm mới) có cấp 0. */
  int depth(@Nullable UUID id) {
    int depth = 0;
    Set<UUID> seen = new HashSet<>();
    UUID cursor = id;
    while (cursor != null && parentOf.containsKey(cursor) && seen.add(cursor)) {
      depth++;
      cursor = parentOf.get(cursor);
    }
    return depth;
  }

  /** Số cấp của cây con gốc tại {@code id} (lá = 1). */
  int height(UUID id) {
    int best = 0;
    for (UUID child : childrenOf.getOrDefault(id, List.of())) {
      best = Math.max(best, height(child));
    }
    return best + 1;
  }

  /** {@code candidate} là chính {@code id} hoặc hậu duệ của {@code id}. */
  boolean isSelfOrDescendant(UUID id, UUID candidate) {
    if (id.equals(candidate)) {
      return true;
    }
    for (UUID child : childrenOf.getOrDefault(id, List.of())) {
      if (isSelfOrDescendant(child, candidate)) {
        return true;
      }
    }
    return false;
  }

  /** Kiểm tra tạo nhóm mới (lá) dưới {@code newParent}. */
  @Nullable Violation checkCreate(@Nullable UUID newParent) {
    return depth(newParent) + 1 > MAX_DEPTH ? Violation.DEPTH : null;
  }

  /** Kiểm tra chuyển nhóm {@code id} (kèm cây con) sang {@code newParent}. */
  @Nullable Violation checkMove(UUID id, @Nullable UUID newParent) {
    if (newParent == null) {
      return null;
    }
    if (isSelfOrDescendant(id, newParent)) {
      return Violation.CYCLE;
    }
    return depth(newParent) + height(id) > MAX_DEPTH ? Violation.DEPTH : null;
  }
}
