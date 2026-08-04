package vn.lgsp.control.onboarding.api;

import jakarta.validation.constraints.NotNull;

/** Ghi kết quả một bước thẩm định (FR-01-004 / FR-01-005). */
public record ReviewRequest(@NotNull Decision decision, String note) {

  public enum Decision {
    PASS,
    FAIL
  }
}
