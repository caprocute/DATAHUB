package vn.lgsp.data.rdm.internal;

import jakarta.validation.Valid;
import java.security.Principal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import vn.lgsp.data.rdm.api.CatalogDto;
import vn.lgsp.data.rdm.api.CatalogItemDto;
import vn.lgsp.data.rdm.api.CatalogVersionDto;
import vn.lgsp.data.rdm.api.CreateCatalogRequest;
import vn.lgsp.data.rdm.api.CreateVersionRequest;
import vn.lgsp.data.rdm.api.RdmApi;
import vn.lgsp.data.rdm.api.ResolveRequest;
import vn.lgsp.data.rdm.api.ResolveResultDto;
import vn.lgsp.data.rdm.api.UpsertItemRequest;

/**
 * API PH-07 (WP-31).
 *
 * <p>Đường dẫn bám SRS PH-07 §5.2/§5.4: tra cứu ở {@code /api/v1/reference}, quản trị ở
 * {@code /api/admin/v1/reference}. Giữ nguyên {@code /api/v1/rdm/status} của WP-30 để
 * không phá bên đang gọi.
 */
@RestController
class RdmController {

  private final RdmApi rdmApi;

  RdmController(RdmApi rdmApi) {
    this.rdmApi = rdmApi;
  }

  /* ---------- WP-30 ---------- */

  @GetMapping("/api/v1/rdm/status")
  @PreAuthorize("isAuthenticated()")
  Map<String, String> status() {
    return Map.of("module", "rdm", "schema", "ph07", "status", rdmApi.moduleStatus());
  }

  /* ---------- Tra cứu (FR-07-007…009) ---------- */

  @GetMapping("/api/v1/reference/catalogs")
  @PreAuthorize("isAuthenticated()")
  List<CatalogDto> listCatalogs() {
    return rdmApi.listCatalogs();
  }

  @GetMapping("/api/v1/reference/{catalog}")
  @PreAuthorize("isAuthenticated()")
  List<CatalogItemDto> listItems(
      @PathVariable("catalog") String catalog,
      @RequestParam(value = "thoiDiem", required = false)
          @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate thoiDiem,
      @RequestParam(value = "includeDeprecated", defaultValue = "false") boolean includeDeprecated) {
    return rdmApi.listItems(catalog, thoiDiem, includeDeprecated);
  }

  @GetMapping("/api/v1/reference/{catalog}/{code}")
  @PreAuthorize("isAuthenticated()")
  CatalogItemDto resolve(
      @PathVariable("catalog") String catalog,
      @PathVariable("code") String code,
      @RequestParam(value = "thoiDiem", required = false)
          @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate thoiDiem) {
    return rdmApi
        .resolve(catalog, code, thoiDiem)
        .orElseThrow(
            () ->
                new ResponseStatusException(
                    HttpStatus.NOT_FOUND, "không có mã " + code + " trong danh mục " + catalog));
  }

  @PostMapping("/api/v1/reference/lookup/batch")
  @PreAuthorize("isAuthenticated()")
  List<ResolveResultDto> resolveBatch(@RequestBody ResolveRequest request) {
    return rdmApi.resolveBatch(request);
  }

  /* ---------- Quản trị (FR-07-001…004) ---------- */

  @GetMapping("/api/admin/v1/reference/catalogs/{catalog}")
  @PreAuthorize("isAuthenticated()")
  CatalogDto getCatalog(@PathVariable("catalog") String catalog) {
    return rdmApi.getCatalog(catalog);
  }

  @PostMapping("/api/admin/v1/reference/catalogs")
  @ResponseStatus(HttpStatus.CREATED)
  @PreAuthorize("isAuthenticated()")
  CatalogDto createCatalog(@Valid @RequestBody CreateCatalogRequest request) {
    return rdmApi.createCatalog(request);
  }

  @GetMapping("/api/admin/v1/reference/catalogs/{catalog}/versions")
  @PreAuthorize("isAuthenticated()")
  List<CatalogVersionDto> listVersions(@PathVariable("catalog") String catalog) {
    return rdmApi.listVersions(catalog);
  }

  @PostMapping("/api/admin/v1/reference/catalogs/{catalog}/versions")
  @ResponseStatus(HttpStatus.CREATED)
  @PreAuthorize("isAuthenticated()")
  CatalogVersionDto createVersion(
      @PathVariable("catalog") String catalog,
      @RequestBody CreateVersionRequest request,
      Principal principal) {
    return rdmApi.createVersion(catalog, request, actorOf(principal));
  }

  @PostMapping("/api/admin/v1/reference/catalogs/{catalog}/versions/{version}/items")
  @PreAuthorize("isAuthenticated()")
  CatalogItemDto upsertItem(
      @PathVariable("catalog") String catalog,
      @PathVariable("version") int version,
      @Valid @RequestBody UpsertItemRequest request) {
    return rdmApi.upsertItem(catalog, version, request);
  }

  @PostMapping("/api/admin/v1/reference/catalogs/{catalog}/versions/{version}/publish")
  @PreAuthorize("isAuthenticated()")
  CatalogVersionDto publish(
      @PathVariable("catalog") String catalog,
      @PathVariable("version") int version,
      Principal principal) {
    return rdmApi.publishVersion(catalog, version, actorOf(principal));
  }

  private static String actorOf(Principal principal) {
    return principal != null ? principal.getName() : "anonymous";
  }

  /* ---------- ánh xạ lỗi nghiệp vụ → HTTP (SRS PH-07 M3) ---------- */

  @ExceptionHandler(RdmNotFoundException.class)
  @ResponseStatus(HttpStatus.NOT_FOUND)
  Map<String, String> notFound(RdmNotFoundException e) {
    return Map.of("title", e.getMessage());
  }

  @ExceptionHandler(RdmValidationException.class)
  @ResponseStatus(HttpStatus.UNPROCESSABLE_ENTITY)
  Map<String, String> invalid(RdmValidationException e) {
    return Map.of("title", e.getMessage());
  }

  @ExceptionHandler(RdmConflictException.class)
  @ResponseStatus(HttpStatus.CONFLICT)
  Map<String, String> conflict(RdmConflictException e) {
    return Map.of("title", e.getMessage());
  }

  @ExceptionHandler(RdmForbiddenException.class)
  @ResponseStatus(HttpStatus.FORBIDDEN)
  Map<String, String> forbidden(RdmForbiddenException e) {
    return Map.of("title", e.getMessage());
  }

  @ExceptionHandler(RdmTooLargeException.class)
  @ResponseStatus(HttpStatus.PAYLOAD_TOO_LARGE)
  Map<String, String> tooLarge(RdmTooLargeException e) {
    return Map.of("title", e.getMessage());
  }
}
