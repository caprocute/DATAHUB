package vn.datahub.data.shared.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

/**
 * Cột chuẩn của entity theo tenant (D00-01 §5.1; CC-JPA-01): id UUID v7 gán ở ứng dụng, tenant_id
 * không đổi, cột kiểm toán và khóa lạc quan {@code version}.
 */
@MappedSuperclass
public abstract class TenantScopedEntity {

  @Id private UUID id;

  @Column(name = "tenant_id", nullable = false, updatable = false, length = 16)
  private String tenantId;

  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;

  @Column(name = "created_by", nullable = false, updatable = false)
  private UUID createdBy;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @Column(name = "updated_by", nullable = false)
  private UUID updatedBy;

  /** Null khi chưa lưu (để Spring Data nhận ra entity mới); Hibernate đặt 0 khi chèn. */
  @Version private Integer version;

  protected TenantScopedEntity() {}

  protected TenantScopedEntity(String tenantId, UUID actor, Instant now) {
    this.id = UuidV7.generate();
    this.tenantId = tenantId;
    this.createdAt = now;
    this.createdBy = actor;
    this.updatedAt = now;
    this.updatedBy = actor;
  }

  protected void touch(UUID actor, Instant now) {
    this.updatedBy = actor;
    this.updatedAt = now;
  }

  public UUID getId() {
    return id;
  }

  public String getTenantId() {
    return tenantId;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public UUID getCreatedBy() {
    return createdBy;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public UUID getUpdatedBy() {
    return updatedBy;
  }

  public int getVersion() {
    return version == null ? 0 : version;
  }
}
