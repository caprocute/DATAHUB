package vn.lgsp.control.catalog.internal;

import jakarta.validation.Valid;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import vn.lgsp.control.catalog.api.CatalogApi;
import vn.lgsp.control.catalog.api.ServiceRegisterRequest;
import vn.lgsp.control.catalog.api.ServiceSummaryDto;

@RestController
@RequestMapping("/api/v1/catalog")
class CatalogController {

  private final CatalogApi catalogApi;

  CatalogController(CatalogApi catalogApi) {
    this.catalogApi = catalogApi;
  }

  @GetMapping("/status")
  Map<String, String> status() {
    return Map.of("module", "catalog", "status", catalogApi.moduleStatus());
  }

  @GetMapping("/services")
  @PreAuthorize("isAuthenticated()")
  Map<String, Object> list() {
    return Map.of("items", catalogApi.list());
  }

  @PostMapping("/services")
  @ResponseStatus(HttpStatus.CREATED)
  @PreAuthorize("hasAnyRole('INTEGRATION_DEVELOPER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  ServiceSummaryDto register(@Valid @RequestBody ServiceRegisterRequest body) {
    return catalogApi.register(body);
  }

  @PostMapping("/services/{id}/publish")
  @PreAuthorize("hasAnyRole('INTEGRATION_ADMIN','PLATFORM_ADMIN','INTEGRATION_REVIEWER')")
  ServiceSummaryDto publish(@PathVariable("id") UUID id) {
    try {
      return catalogApi.publish(id);
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
    }
  }
}
