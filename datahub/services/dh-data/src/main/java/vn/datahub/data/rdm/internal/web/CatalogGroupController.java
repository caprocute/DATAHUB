package vn.datahub.data.rdm.internal.web;

import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;
import tools.jackson.databind.JsonNode;
import vn.datahub.data.rdm.api.CatalogGroupView;
import vn.datahub.data.rdm.internal.CatalogGroupService;
import vn.datahub.data.shared.web.ApiError;
import vn.datahub.data.shared.web.DatahubException;
import vn.datahub.data.shared.web.ETags;
import vn.datahub.data.shared.web.FieldError;

/**
 * API-07-007…010 (F-07-010). Quyền theo SS-07-03: đọc cần PERM-07-read; tạo cần PERM-07-create, sửa
 * và xóa cần PERM-07-update, kèm vai trò TENANT_ADMIN hoặc PLATFORM_ADMIN (DS bị từ chối).
 */
@RestController
@RequestMapping("/api/rdm/v1/catalog-groups")
class CatalogGroupController {

  private static final String MANAGER_ROLE = "hasAnyRole('TENANT_ADMIN','PLATFORM_ADMIN')";
  private static final java.util.regex.Pattern IDEMPOTENCY_KEY =
      java.util.regex.Pattern.compile("^[A-Za-z0-9_-]{16,128}$");

  private final CatalogGroupService service;
  private final GroupPatchParser patchParser;

  CatalogGroupController(CatalogGroupService service, GroupPatchParser patchParser) {
    this.service = service;
    this.patchParser = patchParser;
  }

  @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('PERM-07-read')")
  ItemsResponse list(@RequestParam(name = "flat", defaultValue = "false") boolean flat) {
    return new ItemsResponse(flat ? service.flat() : service.tree());
  }

  @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE, produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('PERM-07-create') and " + MANAGER_ROLE)
  ResponseEntity<CatalogGroupView> create(
      @RequestHeader(name = "Idempotency-Key", required = false) String idempotencyKey,
      @Valid @RequestBody CatalogGroupCreateRequest request) {
    if (idempotencyKey != null && !IDEMPOTENCY_KEY.matcher(idempotencyKey).matches()) {
      throw new DatahubException(
          ApiError.VALIDATION,
          "Idempotency-Key gồm 16 đến 128 ký tự A-Z, a-z, 0-9, _ hoặc -.",
          List.of(new FieldError("Idempotency-Key", "PATTERN", "Khóa chống trùng không đúng định dạng.")));
    }
    CatalogGroupService.CreateResult result = service.create(request.toCommand(), idempotencyKey);
    CatalogGroupView view = result.view();
    URI location =
        ServletUriComponentsBuilder.fromCurrentRequestUri().path("/{id}").build(view.id());
    ResponseEntity.BodyBuilder response =
        ResponseEntity.created(location).eTag(ETags.weak(view.version()));
    if (result.replayed()) {
      response.header("Idempotent-Replayed", "true");
    }
    return response.body(view);
  }

  @PatchMapping(
      path = "/{groupId}",
      consumes = {"application/merge-patch+json", MediaType.APPLICATION_JSON_VALUE},
      produces = MediaType.APPLICATION_JSON_VALUE)
  @PreAuthorize("hasAuthority('PERM-07-update') and " + MANAGER_ROLE)
  ResponseEntity<CatalogGroupView> update(
      @PathVariable UUID groupId,
      @RequestHeader(name = HttpHeaders.IF_MATCH, required = false) String ifMatch,
      @RequestBody JsonNode body) {
    int expected = ETags.parseIfMatch(ifMatch);
    CatalogGroupView view = service.update(groupId, expected, patchParser.parse(body));
    return ResponseEntity.ok().eTag(ETags.weak(view.version())).body(view);
  }

  @DeleteMapping("/{groupId}")
  @PreAuthorize("hasAuthority('PERM-07-update') and " + MANAGER_ROLE)
  ResponseEntity<Void> delete(
      @PathVariable UUID groupId,
      @RequestHeader(name = HttpHeaders.IF_MATCH, required = false) String ifMatch) {
    service.delete(groupId, ETags.parseIfMatch(ifMatch));
    return ResponseEntity.noContent().build();
  }

  /** Thân phản hồi của GET /catalog-groups. */
  record ItemsResponse(List<CatalogGroupView> items) {}
}
