package vn.lgsp.control.onboarding;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import vn.lgsp.control.onboarding.api.ApplicationSubmitRequest;
import vn.lgsp.control.onboarding.api.OnboardingApi;

/** AT khói — cần Postgres DEV. Bật bằng LGSP_IT=1. */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "LGSP_IT", matches = "1")
class OnboardingSmokeTest {

  @Autowired OnboardingApi onboardingApi;

  @Test
  void submitAndApprove() {
    String code = "SYS_" + UUID.randomUUID().toString().substring(0, 8);
    var created = onboardingApi.submit(new ApplicationSubmitRequest(code, "Demo", "Sở Demo"), "dev");
    assertThat(created.status()).isEqualTo("SUBMITTED");

    var approved = onboardingApi.approve(created.id(), "reviewer");
    assertThat(approved.status()).isEqualTo("APPROVED");
    assertThat(approved.clientId()).isNotBlank();
    assertThat(approved.clientSecretSealed()).startsWith("sealed:dev:");
  }

  @Test
  void listContainsSubmitted() {
    String code = "SYS_" + UUID.randomUUID().toString().substring(0, 8);
    onboardingApi.submit(new ApplicationSubmitRequest(code, "Demo2", "Sở Demo"), "dev");
    assertThat(onboardingApi.list(50).stream().anyMatch(a -> code.equals(a.systemCode()))).isTrue();
  }
}
