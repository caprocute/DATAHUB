package vn.datahub.data.shared.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class TenantContextTest {

  @AfterEach
  void clear() {
    TenantContext.clear();
  }

  @Test
  @DisplayName("Chỉ chấp nhận tenant của token: Tnn hoặc PLATFORM")
  void validTokenTenants() {
    assertThat(TenantContext.isValidTokenTenant("T68")).isTrue();
    assertThat(TenantContext.isValidTokenTenant("PLATFORM")).isTrue();
    assertThat(TenantContext.isValidTokenTenant("COMMON")).isFalse();
    assertThat(TenantContext.isValidTokenTenant("T6")).isFalse();
    assertThat(TenantContext.isValidTokenTenant("t68")).isFalse();
    assertThat(TenantContext.isValidTokenTenant(null)).isFalse();
  }

  @Test
  @DisplayName("Không có tenant thì từ chối, không ngầm dùng giá trị rỗng")
  void requireFailsWithoutTenant() {
    assertThatThrownBy(TenantContext::require).isInstanceOf(IllegalStateException.class);
    assertThatThrownBy(TenantContext::dataTenant).isInstanceOf(IllegalStateException.class);
    assertThatThrownBy(TenantContext::visibleTenants).isInstanceOf(IllegalStateException.class);
  }

  @Test
  @DisplayName("PLATFORM ghi COMMON và chỉ thấy COMMON; tenant tỉnh thấy mình và COMMON")
  void dataAndVisibleTenants() {
    TenantContext.runAs(
        "PLATFORM",
        () -> {
          assertThat(TenantContext.dataTenant()).isEqualTo("COMMON");
          assertThat(TenantContext.visibleTenants()).containsExactly("COMMON");
          return null;
        });
    TenantContext.runAs(
        "T68",
        () -> {
          assertThat(TenantContext.dataTenant()).isEqualTo("T68");
          assertThat(TenantContext.visibleTenants()).containsExactly("T68", "COMMON");
          return null;
        });
  }

  @Test
  @DisplayName("runAs khôi phục tenant trước đó, kể cả khi có lỗi")
  void runAsRestores() {
    TenantContext.set("T01");
    assertThatThrownBy(
            () ->
                TenantContext.runAs(
                    "T02",
                    () -> {
                      throw new IllegalArgumentException("x");
                    }))
        .isInstanceOf(IllegalArgumentException.class);
    assertThat(TenantContext.require()).isEqualTo("T01");
    TenantContext.clear();
    TenantContext.runAs("T03", () -> TenantContext.require());
    assertThatThrownBy(TenantContext::require).isInstanceOf(IllegalStateException.class);
  }
}
