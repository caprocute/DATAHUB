package vn.datahub.data.rdm.internal.web;

import jakarta.validation.constraints.Size;
import java.util.UUID;
import org.jspecify.annotations.Nullable;
import vn.datahub.data.rdm.internal.GroupRules;
import vn.datahub.data.rdm.internal.UpdateGroupCommand;

/**
 * Giá trị đã chuẩn hóa của PATCH (merge-patch). {@code present} ghi nhận trường nào có trong thân để
 * phân biệt "vắng mặt" với "null". Kiểm tra bằng Jakarta Validation sau chuẩn hóa.
 */
record CatalogGroupUpdateRequest(
    @Size(min = 1, max = 255, message = "Tên nhóm gồm 1 đến 255 ký tự.") @Nullable String name,
    @Nullable UUID parentId,
    @Nullable Integer sortOrder,
    @Size(max = 4000, message = "Mô tả tối đa 4000 ký tự.") @Nullable String description,
    java.util.Set<String> present) {

  CatalogGroupUpdateRequest {
    name = name == null ? null : GroupRules.normalizeName(name);
    description = description == null ? null : GroupRules.normalizeDescription(description);
  }

  UpdateGroupCommand toCommand() {
    return new UpdateGroupCommand(
        present.contains("name"),
        name,
        present.contains("parentId"),
        parentId,
        present.contains("sortOrder"),
        sortOrder == null ? 0 : sortOrder,
        present.contains("description"),
        description);
  }
}
