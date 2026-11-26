package vn.datahub.data.rdm.internal.web;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.UUID;
import org.jspecify.annotations.Nullable;
import vn.datahub.data.rdm.internal.CreateGroupCommand;
import vn.datahub.data.rdm.internal.GroupRules;

/**
 * Thân POST /catalog-groups. Chuẩn hóa (mã chữ hoa, tên NFC, cắt khoảng trắng) chạy trong hàm tạo,
 * TRƯỚC khi Jakarta Validation kiểm tra (CC-VAL-03). Trường lạ bị từ chối ở bộ giải mã JSON.
 */
public record CatalogGroupCreateRequest(
    @NotBlank(message = "Mã nhóm là bắt buộc.")
        @Pattern(
            regexp = GroupRules.CODE_PATTERN,
            message = "Mã chỉ gồm chữ hoa, số, _ . - ; bắt đầu bằng chữ hoặc số; tối đa 64 ký tự.")
        @Nullable String code,
    @NotBlank(message = "Tên nhóm là bắt buộc.")
        @Size(max = 255, message = "Tên nhóm tối đa 255 ký tự.")
        @Nullable String name,
    @Nullable UUID parentId,
    @Nullable Integer sortOrder,
    @Size(max = 4000, message = "Mô tả tối đa 4000 ký tự.") @Nullable String description) {

  public CatalogGroupCreateRequest {
    code = code == null ? null : GroupRules.normalizeCode(code);
    name = name == null ? null : GroupRules.normalizeName(name);
    description = description == null ? null : GroupRules.normalizeDescription(description);
  }

  /** Chỉ gọi sau khi đã kiểm tra hợp lệ (code, name khác null). */
  CreateGroupCommand toCommand() {
    return new CreateGroupCommand(
        java.util.Objects.requireNonNull(code),
        java.util.Objects.requireNonNull(name),
        parentId,
        sortOrder == null ? 0 : sortOrder,
        description);
  }
}
