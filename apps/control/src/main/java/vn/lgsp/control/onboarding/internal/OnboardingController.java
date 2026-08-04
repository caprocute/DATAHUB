package vn.lgsp.control.onboarding.internal;

import jakarta.validation.Valid;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
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
  Map<String, Object> list(@RequestParam(defaultValue = "20") int limit) {
    List<ApplicationDto> items = onboardingApi.list(limit);
    return Map.of("items", items);
  }

  @GetMapping("/applications/{id}")
  @PreAuthorize("isAuthenticated()")
  ApplicationDto get(@PathVariable("id") UUID id) {
    return onboardingApi
        .findById(id)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "not found"));
  }

  @PostMapping("/applications")
  @ResponseStatus(HttpStatus.CREATED)
  @PreAuthorize("hasAnyRole('INTEGRATION_DEVELOPER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  ApplicationDto submit(@Valid @RequestBody ApplicationSubmitRequest body, Authentication auth) {
    return onboardingApi.submit(body, principalName(auth));
  }

  @PostMapping("/applications/{id}/approve")
  @PreAuthorize("hasAnyRole('INTEGRATION_REVIEWER','PLATFORM_ADMIN')")
  ApplicationDto approve(@PathVariable("id") UUID id, Authentication auth) {
    try {
      return onboardingApi.approve(id, principalName(auth));
    } catch (IllegalArgumentException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, e.getMessage());
    } catch (IllegalStateException e) {
      throw new ResponseStatusException(HttpStatus.CONFLICT, e.getMessage());
    }
  }

  private static String principalName(Authentication auth) {
    if (auth != null && auth.getPrincipal() instanceof Jwt jwt) {
      String preferred = jwt.getClaimAsString("preferred_username");
      return preferred != null ? preferred : jwt.getSubject();
    }
    return auth != null ? auth.getName() : "anonymous";
  }
}
