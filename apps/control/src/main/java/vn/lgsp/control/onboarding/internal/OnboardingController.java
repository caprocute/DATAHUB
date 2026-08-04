package vn.lgsp.control.onboarding.internal;

import jakarta.validation.Valid;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
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
import vn.lgsp.control.onboarding.api.ApplicationDto;
import vn.lgsp.control.onboarding.api.ApplicationSubmitRequest;
import vn.lgsp.control.onboarding.api.OnboardingApi;
import vn.lgsp.control.onboarding.api.PageDto;
import vn.lgsp.control.onboarding.api.ReviewRequest;
import vn.lgsp.control.onboarding.api.StatusChangeRequest;

@RestController
@RequestMapping("/api/v1/onboarding")
class OnboardingController {

  private final OnboardingApi onboardingApi;

  OnboardingController(OnboardingApi onboardingApi) {
    this.onboardingApi = onboardingApi;
  }

  @GetMapping("/status")
  Map<String, String> status() {
    return Map.of("module", "onboarding", "status", onboardingApi.moduleStatus());
  }

  @GetMapping("/applications")
  @PreAuthorize("isAuthenticated()")
  PageDto<ApplicationDto> list(
      @RequestParam(required = false) String q,
      @RequestParam(required = false) String status,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "20") int size) {
    return onboardingApi.search(q, status, page, size);
  }

  @GetMapping("/applications/{id}")
  @PreAuthorize("isAuthenticated()")
  ApplicationDto get(@PathVariable("id") UUID id) {
    return onboardingApi
        .findById(id)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "not found"));
  }

  @GetMapping("/applications/{id}/audit")
  @PreAuthorize("hasAnyRole('INTEGRATION_REVIEWER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  Map<String, Object> audit(@PathVariable("id") UUID id) {
    return Map.of("items", onboardingApi.auditTrail(id));
  }

  @PostMapping("/applications")
  @ResponseStatus(HttpStatus.CREATED)
  @PreAuthorize("hasAnyRole('INTEGRATION_DEVELOPER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  ApplicationDto submit(@Valid @RequestBody ApplicationSubmitRequest body, Authentication auth) {
    return onboardingApi.submit(body, principalName(auth));
  }

  /** FR-01-004 — thẩm định căn cứ pháp lý. */
  @PostMapping("/applications/{id}/review/legal")
  @PreAuthorize("hasAnyRole('INTEGRATION_REVIEWER','PLATFORM_ADMIN')")
  ApplicationDto reviewLegal(
      @PathVariable("id") UUID id, @Valid @RequestBody ReviewRequest body, Authentication auth) {
    return onboardingApi.reviewLegal(id, body, principalName(auth));
  }

  /** FR-01-005 — thẩm định kỹ thuật. */
  @PostMapping("/applications/{id}/review/technical")
  @PreAuthorize("hasAnyRole('INTEGRATION_REVIEWER','PLATFORM_ADMIN')")
  ApplicationDto reviewTechnical(
      @PathVariable("id") UUID id, @Valid @RequestBody ReviewRequest body, Authentication auth) {
    return onboardingApi.reviewTechnical(id, body, principalName(auth));
  }

  /** FR-01-006 / FR-01-008 — duyệt và cấp danh tính; bí mật trả một lần. */
  @PostMapping("/applications/{id}/approve")
  @PreAuthorize("hasAnyRole('INTEGRATION_REVIEWER','PLATFORM_ADMIN')")
  ApplicationDto approve(@PathVariable("id") UUID id, Authentication auth) {
    return onboardingApi.approve(id, principalName(auth));
  }

  @PostMapping("/applications/{id}/reject")
  @PreAuthorize("hasAnyRole('INTEGRATION_REVIEWER','PLATFORM_ADMIN')")
  ApplicationDto reject(
      @PathVariable("id") UUID id,
      @Valid @RequestBody StatusChangeRequest body,
      Authentication auth) {
    return onboardingApi.reject(id, body.reason(), principalName(auth));
  }

  /** FR-01-010 — kích hoạt sau khi kiểm thử kết nối đạt. */
  @PostMapping("/applications/{id}/activate")
  @PreAuthorize("hasAnyRole('INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  ApplicationDto activate(@PathVariable("id") UUID id, Authentication auth) {
    return onboardingApi.activate(id, principalName(auth));
  }

  @PostMapping("/applications/{id}/suspend")
  @PreAuthorize("hasAnyRole('INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  ApplicationDto suspend(
      @PathVariable("id") UUID id,
      @Valid @RequestBody StatusChangeRequest body,
      Authentication auth) {
    return onboardingApi.suspend(id, body.reason(), principalName(auth));
  }

  @PostMapping("/applications/{id}/resume")
  @PreAuthorize("hasAnyRole('INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  ApplicationDto resume(@PathVariable("id") UUID id, Authentication auth) {
    return onboardingApi.resume(id, principalName(auth));
  }

  @PostMapping("/applications/{id}/revoke")
  @PreAuthorize("hasRole('PLATFORM_ADMIN')")
  ApplicationDto revoke(
      @PathVariable("id") UUID id,
      @Valid @RequestBody StatusChangeRequest body,
      Authentication auth) {
    return onboardingApi.revoke(id, body.reason(), principalName(auth));
  }

  /* ---------- Ánh xạ lỗi nghiệp vụ sang mã HTTP ---------- */

  @ExceptionHandler(IllegalArgumentException.class)
  @ResponseStatus(HttpStatus.NOT_FOUND)
  Map<String, String> notFound(IllegalArgumentException e) {
    return Map.of("error", e.getMessage());
  }

  /** Bước chuyển trạng thái không hợp lệ — xung đột trạng thái, không phải lỗi quyền. */
  @ExceptionHandler(IllegalStateException.class)
  @ResponseStatus(HttpStatus.CONFLICT)
  Map<String, String> conflict(IllegalStateException e) {
    return Map.of("error", e.getMessage());
  }

  /** Vi phạm bốn mắt — người dùng có vai trò nhưng không được làm trên hồ sơ này. */
  @ExceptionHandler(SelfReviewException.class)
  @ResponseStatus(HttpStatus.FORBIDDEN)
  Map<String, String> forbidden(SelfReviewException e) {
    return Map.of("error", e.getMessage());
  }

  private static String principalName(Authentication auth) {
    if (auth != null && auth.getPrincipal() instanceof Jwt jwt) {
      String preferred = jwt.getClaimAsString("preferred_username");
      return preferred != null ? preferred : jwt.getSubject();
    }
    return auth != null ? auth.getName() : "anonymous";
  }
}
