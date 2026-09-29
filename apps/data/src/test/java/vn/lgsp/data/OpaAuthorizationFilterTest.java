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

  @Test
  void mapsReferencePathsToRdmPermissions() {
    // WP-31 — SRS-19 §3.4.7 tách đọc khỏi ghi. Dùng chung một action thì mọi vai trò đọc
    // được danh mục sẽ ghi được luôn.
    assertThat(OpaAuthorizationFilter.resolveAction("/api/v1/reference/catalogs"))
        .contains("rdm.catalog.read");
    assertThat(OpaAuthorizationFilter.resolveAction("/api/v1/reference/DVHC/01"))
        .contains("rdm.catalog.read");
    assertThat(OpaAuthorizationFilter.resolveAction("/api/v1/reference/lookup/batch"))
        .contains("rdm.catalog.read");
  }

  @Test
  void adminReferencePathsRequireWritePermission() {
    // Nhánh quản trị phải được xét **trước** nhánh tra cứu; nếu xét sau thì
    // `/api/admin/v1/reference/...` không khớp tiền tố `/api/v1/reference` và rơi vào
    // nhánh unknown → 403 oan cho cán bộ có quyền.
    assertThat(OpaAuthorizationFilter.resolveAction("/api/admin/v1/reference/catalogs"))
        .contains("rdm.entry.write");
    assertThat(
            OpaAuthorizationFilter.resolveAction(
                "/api/admin/v1/reference/catalogs/DVHC/versions/1/publish"))
        .contains("rdm.entry.write");
  }
}
