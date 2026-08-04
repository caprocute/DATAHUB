package vn.lgsp.data.dq.internal;

import java.util.Map;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.lgsp.data.dq.api.DqApi;

@RestController
@RequestMapping("/api/v1/dq")
class DqController {

  private final DqApi dqApi;

  DqController(DqApi dqApi) {
    this.dqApi = dqApi;
  }

  @GetMapping("/status")
  @PreAuthorize("isAuthenticated()")
  Map<String, String> status() {
    return Map.of("module", "dq", "schema", "ph08", "status", dqApi.moduleStatus());
  }
}
