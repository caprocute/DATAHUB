package vn.lgsp.data.mdm.internal;

import java.util.Map;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.lgsp.data.mdm.api.MdmApi;

@RestController
@RequestMapping("/api/v1/mdm")
class MdmController {

  private final MdmApi mdmApi;

  MdmController(MdmApi mdmApi) {
    this.mdmApi = mdmApi;
  }

  @GetMapping("/status")
  @PreAuthorize("isAuthenticated()")
  Map<String, String> status() {
    return Map.of("module", "mdm", "schema", "ph06", "status", mdmApi.moduleStatus());
  }
}
