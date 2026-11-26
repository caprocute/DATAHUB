package vn.datahub.data.shared.security;

import java.util.Set;
import java.util.UUID;

/** Chủ thể của yêu cầu: định danh người dùng, tenant, quyền {@code PERM-*} và vai trò. */
public record CurrentUser(UUID id, String tenant, Set<String> permissions, Set<String> roles) {

  public boolean hasPermission(String permission) {
    return permissions.contains(permission);
  }
}
