package vn.datahub.data.rdm.internal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import org.jspecify.annotations.Nullable;
import vn.datahub.data.shared.persistence.TenantScopedEntity;

/** EN-07-01 Nhóm danh mục. Đổi trạng thái qua phương thức có tên nghiệp vụ (CC-JPA-02). */
@Entity
@Table(schema = "ph07_rdm", name = "catalog_group")
public class CatalogGroup extends TenantScopedEntity {

  @Column(nullable = false, length = 64, updatable = false)
  private String code;

  @Column(nullable = false)
  private String name;

  @Column(name = "parent_id")
  private @Nullable UUID parentId;

  @Column(name = "sort_order", nullable = false)
  private int sortOrder;

  @Column private @Nullable String description;

  protected CatalogGroup() {}

  public CatalogGroup(
      String tenantId,
      String code,
      String name,
      @Nullable UUID parentId,
      int sortOrder,
      @Nullable String description,
      UUID actor,
      Instant now) {
    super(tenantId, actor, now);
    this.code = code;
    this.name = name;
    this.parentId = parentId;
    this.sortOrder = sortOrder;
    this.description = description;
  }

  /** Áp thay đổi đã chuẩn hóa và kiểm tra; mã nhóm không bao giờ đổi. */
  void apply(
      String newName,
      @Nullable UUID newParentId,
      int newSortOrder,
      @Nullable String newDescription,
      UUID actor,
      Instant now) {
    this.name = newName;
    this.parentId = newParentId;
    this.sortOrder = newSortOrder;
    this.description = newDescription;
    touch(actor, now);
  }

  public String getCode() {
    return code;
  }

  public String getName() {
    return name;
  }

  public @Nullable UUID getParentId() {
    return parentId;
  }

  public int getSortOrder() {
    return sortOrder;
  }

  public @Nullable String getDescription() {
    return description;
  }
}
