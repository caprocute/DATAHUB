package vn.lgsp.control.onboarding.api;

import jakarta.validation.constraints.Min;

/** Ghi nhận một lần rà soát quyền định kỳ (FR-01-013). */
public record AccessReviewRequest(String note, @Min(1) Integer nextInMonths) {

  /** Mặc định rà soát lại sau 12 tháng nếu người dùng không chỉ định. */
  public int nextInMonthsOrDefault() {
    return nextInMonths == null ? 12 : nextInMonths;
  }
}
