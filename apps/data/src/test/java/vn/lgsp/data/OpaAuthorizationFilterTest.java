package vn.lgsp.data;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class OpaAuthorizationFilterTest {

  @Test
  void mapsModuleStatusPaths() {
    assertThat(OpaAuthorizationFilter.resolveAction("/api/v1/rdm/status")).contains("data.rdm.status");
    assertThat(OpaAuthorizationFilter.resolveAction("/api/v1/mdm/status")).contains("data.mdm.status");
    assertThat(OpaAuthorizationFilter.resolveAction("/api/v1/privacy/status"))
        .contains("data.privacy.status");
    assertThat(OpaAuthorizationFilter.resolveAction("/api/v1/dq/status")).contains("data.dq.status");
  }

  @Test
  void unknownApiDenied() {
    assertThat(OpaAuthorizationFilter.resolveAction("/api/v1/unknown")).isEmpty();
  }
}
