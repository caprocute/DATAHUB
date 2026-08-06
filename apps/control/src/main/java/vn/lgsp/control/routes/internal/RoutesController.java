package vn.lgsp.control.routes.internal;

import jakarta.validation.Valid;
import java.util.Map;
import java.util.UUID;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import vn.lgsp.control.routes.api.RouteCreateRequest;
import vn.lgsp.control.routes.api.RouteDefinitionUpdate;
import vn.lgsp.control.routes.api.RouteDuplicateRequest;
import vn.lgsp.control.routes.api.RoutePageDto;
import vn.lgsp.control.routes.api.RouteQuery;
import vn.lgsp.control.routes.api.RouteRenameRequest;
import vn.lgsp.control.routes.api.RouteReviewRequest;
import vn.lgsp.control.routes.api.RouteSummaryDto;
import vn.lgsp.control.routes.api.RouteVersionDto;
import vn.lgsp.control.routes.api.RoutesApi;
import vn.lgsp.control.routes.api.TestRunDetailDto;
import vn.lgsp.control.routes.api.TestRunRequest;
import vn.lgsp.control.routes.api.TestRunResultDto;
import vn.lgsp.control.routes.api.ValidateRequest;
import vn.lgsp.control.routes.api.ValidationResultDto;

@RestController
@RequestMapping("/api/admin/v1/routes")
class RoutesController {

  private final RoutesApi routesApi;

  RoutesController(RoutesApi routesApi) {
    this.routesApi = routesApi;
  }

  @GetMapping("/status")
  Map<String, String> status() {
    return Map.of("module", "routes", "status", routesApi.moduleStatus());
  }

  /**
   * Danh sách luồng — lọc/sắp xếp/phân trang **phía máy chủ** (FR-D-001).
   *
   * Không tham số thì vẫn trả nguyên dạng cũ `{items: [...]}` để phần gọi cũ không vỡ;
   * có tham số thì trả thêm `total/page/size` cho thanh phân trang.
   */
  @GetMapping
  @PreAuthorize("isAuthenticated()")
  Map<String, Object> list(
      @RequestParam(value = "q", required = false) String q,
      @RequestParam(value = "status", required = false) String status,
      @RequestParam(value = "resourceKind", required = false) String resourceKind,
      @RequestParam(value = "sort", required = false) String sort,
      @RequestParam(value = "desc", defaultValue = "true") boolean desc,
      @RequestParam(value = "page", defaultValue = "0") int page,
      @RequestParam(value = "size", defaultValue = "20") int size) {
    RoutePageDto result = routesApi.search(new RouteQuery(q, status, resourceKind, sort, desc, page, size));
    return Map.of(
        "items", result.items(),
        "total", result.total(),
        "page", result.page(),
        "size", result.size());
  }

  @GetMapping("/{routeCode}/versions")
  @PreAuthorize("isAuthenticated()")
  Map<String, Object> listVersions(@PathVariable("routeCode") String routeCode) {
    return Map.of("items", routesApi.listVersions(routeCode));
  }

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  @PreAuthorize("hasAnyRole('INTEGRATION_DEVELOPER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  RouteSummaryDto create(@Valid @RequestBody RouteCreateRequest body, Authentication auth) {
    return routesApi.create(body, actor(auth));
  }

  /** Literal path trước `/{routeCode}` — tránh nuốt thành mã route. */
  @GetMapping("/pending-review")
  @PreAuthorize("hasAnyRole('INTEGRATION_REVIEWER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  Map<String, Object> pendingReview() {
    return Map.of("items", routesApi.listPendingReview());
  }

  @PostMapping("/validate")
  @PreAuthorize("isAuthenticated()")
  ValidationResultDto validate(@Valid @RequestBody ValidateRequest body) {
    return routesApi.validate(body.definitionYaml());
  }

  @GetMapping("/{routeCode}")
  @PreAuthorize("isAuthenticated()")
  RouteSummaryDto get(@PathVariable("routeCode") String routeCode) {
    try {
      return routesApi.get(routeCode);
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
    }
  }

  @GetMapping("/{routeCode}/versions/{versionNo}")
  @PreAuthorize("isAuthenticated()")
  RouteVersionDto getVersion(
      @PathVariable("routeCode") String routeCode, @PathVariable("versionNo") int versionNo) {
    try {
      return routesApi.getVersion(routeCode, versionNo);
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
    }
  }

  @PutMapping("/{routeCode}/versions/{versionNo}/definition")
  @PreAuthorize("hasAnyRole('INTEGRATION_DEVELOPER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  RouteVersionDto saveDefinition(
      @PathVariable("routeCode") String routeCode,
      @PathVariable("versionNo") int versionNo,
      @Valid @RequestBody RouteDefinitionUpdate body,
      Authentication auth) {
    try {
      return routesApi.saveDefinition(routeCode, versionNo, body, actor(auth));
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
    } catch (IllegalStateException e) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, e.getMessage());
    }
  }

  @PostMapping("/{routeCode}/versions/{versionNo}/submit")
  @PreAuthorize("hasAnyRole('INTEGRATION_DEVELOPER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  RouteVersionDto submit(
      @PathVariable("routeCode") String routeCode,
      @PathVariable("versionNo") int versionNo,
      Authentication auth) {
    try {
      return routesApi.submit(routeCode, versionNo, actor(auth));
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
    } catch (IllegalStateException e) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, e.getMessage());
    }
  }

  @PostMapping("/{routeCode}/versions/{versionNo}/publish")
  @PreAuthorize("hasAnyRole('INTEGRATION_ADMIN','PLATFORM_ADMIN','INTEGRATION_REVIEWER')")
  RouteVersionDto publish(
      @PathVariable("routeCode") String routeCode,
      @PathVariable("versionNo") int versionNo,
      Authentication auth) {
    try {
      return routesApi.publish(routeCode, versionNo, actor(auth));
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
    } catch (IllegalStateException e) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, e.getMessage());
    }
  }

  @PostMapping("/{routeCode}/versions/{versionNo}/test-runs")
  @PreAuthorize("hasAnyRole('INTEGRATION_DEVELOPER','INTEGRATION_ADMIN','PLATFORM_ADMIN','INTEGRATION_REVIEWER')")
  TestRunResultDto testRun(
      @PathVariable("routeCode") String routeCode,
      @PathVariable("versionNo") int versionNo,
      @RequestBody(required = false) TestRunRequest body,
      Authentication auth) {
    try {
      return routesApi.testRun(
          routeCode,
          versionNo,
          body != null ? body : new TestRunRequest("MOCK", null),
          actor(auth));
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
    }
  }

  @PostMapping("/{routeCode}/versions/{versionNo}/review")
  @PreAuthorize("hasAnyRole('INTEGRATION_REVIEWER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  RouteVersionDto review(
      @PathVariable("routeCode") String routeCode,
      @PathVariable("versionNo") int versionNo,
      @Valid @RequestBody RouteReviewRequest body,
      Authentication auth) {
    try {
      return routesApi.review(routeCode, versionNo, body, actor(auth));
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
    } catch (IllegalStateException e) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, e.getMessage());
    }
  }

  /* ---------- Thao tác trên một luồng (FR-D-002) ---------- */

  @PutMapping("/{routeCode}/title")
  @PreAuthorize("hasAnyRole('INTEGRATION_DEVELOPER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  RouteSummaryDto rename(
      @PathVariable("routeCode") String routeCode,
      @Valid @RequestBody RouteRenameRequest body,
      Authentication auth) {
    try {
      return routesApi.rename(routeCode, body, actor(auth));
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
    }
  }

  @PostMapping("/{routeCode}/duplicate")
  @ResponseStatus(HttpStatus.CREATED)
  @PreAuthorize("hasAnyRole('INTEGRATION_DEVELOPER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  RouteSummaryDto duplicate(
      @PathVariable("routeCode") String routeCode,
      @Valid @RequestBody RouteDuplicateRequest body,
      Authentication auth) {
    try {
      return routesApi.duplicate(routeCode, body, actor(auth));
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
    } catch (DuplicateKeyException e) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, "mã luồng đã tồn tại");
    }
  }

  /** Tạm dừng / kích hoạt. Đổi trạng thái vận hành nên đòi quyền quản trị tích hợp. */
  @PostMapping("/{routeCode}/paused")
  @PreAuthorize("hasAnyRole('INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  RouteSummaryDto setPaused(
      @PathVariable("routeCode") String routeCode,
      @RequestParam("value") boolean paused,
      Authentication auth) {
    try {
      return routesApi.setPaused(routeCode, paused, actor(auth));
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
    } catch (IllegalStateException e) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, e.getMessage());
    }
  }

  @DeleteMapping("/{routeCode}/versions/{versionNo}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  @PreAuthorize("hasAnyRole('INTEGRATION_DEVELOPER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  void deleteDraft(
      @PathVariable("routeCode") String routeCode,
      @PathVariable("versionNo") int versionNo,
      Authentication auth) {
    try {
      routesApi.deleteDraft(routeCode, versionNo, actor(auth));
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
    } catch (IllegalStateException e) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, e.getMessage());
    }
  }

  /* ---------- Nhật ký chạy thử (FR-D-040/041) ---------- */

  @GetMapping("/{routeCode}/test-runs")
  @PreAuthorize("isAuthenticated()")
  Map<String, Object> listTestRuns(
      @PathVariable("routeCode") String routeCode,
      @RequestParam(value = "outcome", required = false) String outcome,
      @RequestParam(value = "limit", defaultValue = "50") int limit) {
    return Map.of("items", routesApi.listTestRuns(routeCode, outcome, limit));
  }

  @GetMapping("/{routeCode}/test-runs/{runId}")
  @PreAuthorize("isAuthenticated()")
  TestRunDetailDto getTestRun(
      @PathVariable("routeCode") String routeCode, @PathVariable("runId") UUID runId) {
    try {
      return routesApi.getTestRun(routeCode, runId);
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
    }
  }

  @ExceptionHandler(RouteValidationException.class)
  @ResponseStatus(HttpStatus.UNPROCESSABLE_ENTITY)
  Map<String, Object> handleValidation(RouteValidationException e) {
    return Map.of(
        "title", e.getMessage(),
        "valid", e.result().valid(),
        "findings", e.result().findings());
  }

  private static String actor(Authentication auth) {
    return auth != null && auth.getName() != null ? auth.getName() : "anonymous";
  }
}
