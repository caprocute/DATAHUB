package vn.lgsp.data.privacy.internal;

import java.util.Map;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.lgsp.data.privacy.api.PrivacyApi;

@RestController
@RequestMapping("/api/v1/privacy")
class PrivacyController {

  private final PrivacyApi privacyApi;

  PrivacyController(PrivacyApi privacyApi) {
    this.privacyApi = privacyApi;
  }

  @GetMapping("/status")
  @PreAuthorize("isAuthenticated()")
  Map<String, String> status() {
    return Map.of("module", "privacy", "schema", "ph09", "status", privacyApi.moduleStatus());
  }
}
