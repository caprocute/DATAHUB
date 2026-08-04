package vn.lgsp.control.routes.internal;

import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import vn.lgsp.control.routes.api.RouteCreateRequest;
import vn.lgsp.control.routes.api.RouteDefinitionUpdate;
import vn.lgsp.control.routes.api.RouteReviewRequest;
import vn.lgsp.control.routes.api.RouteSummaryDto;
import vn.lgsp.control.routes.api.RouteVersionDto;
import vn.lgsp.control.routes.api.RoutesApi;
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

  @GetMapping
  @PreAuthorize("isAuthenticated()")
  Map<String, Object> list() {
    return Map.of("items", routesApi.list());
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
      @Valid @RequestBody RouteDefinitionUpdate body) {
    try {
      return routesApi.saveDefinition(routeCode, versionNo, body);
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
