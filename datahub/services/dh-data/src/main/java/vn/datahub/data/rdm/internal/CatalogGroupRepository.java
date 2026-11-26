package vn.datahub.data.rdm.internal;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface CatalogGroupRepository extends JpaRepository<CatalogGroup, UUID> {

  List<CatalogGroup> findByTenantIdIn(Collection<String> tenants);

  Optional<CatalogGroup> findByIdAndTenantIdIn(UUID id, Collection<String> tenants);

  boolean existsByTenantIdAndCode(String tenantId, String code);

  long countByParentId(UUID parentId);
}
