package vn.datahub.data.rdm.api;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.jspecify.annotations.Nullable;

/** Nhóm danh mục trả ra ngoài (lược đồ {@code CatalogGroup} của lát cắt F-07-010). */
@JsonInclude(JsonInclude.Include.ALWAYS)
public record CatalogGroupView(
    UUID id,
    String tenantId,
    String code,
    String name,
    @Nullable UUID parentId,
    int sortOrder,
    @Nullable String description,
    int catalogCount,
    List<CatalogGroupView> children,
    Instant createdAt,
    String createdBy,
    Instant updatedAt,
    String updatedBy,
    int version) {

  /** Bản sao với danh sách con mới (dựng cây). */
  public CatalogGroupView withChildren(List<CatalogGroupView> newChildren) {
    return new CatalogGroupView(
        id,
        tenantId,
        code,
        name,
        parentId,
        sortOrder,
        description,
        catalogCount,
        newChildren,
        createdAt,
        createdBy,
        updatedAt,
        updatedBy,
        version);
  }
}
