package vn.lgsp.data.rdm.internal;

import java.util.Map;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.lgsp.data.rdm.api.RdmApi;

@RestController
@RequestMapping("/api/v1/rdm")
class RdmController {

  private final RdmApi rdmApi;

  RdmController(RdmApi rdmApi) {
    this.rdmApi = rdmApi;
  }

  @GetMapping("/status")
  @PreAuthorize("isAuthenticated()")
  Map<String, String> status() {
    return Map.of("module", "rdm", "schema", "ph07", "status", rdmApi.moduleStatus());
  }
}
