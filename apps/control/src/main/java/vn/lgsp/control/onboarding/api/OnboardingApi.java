package vn.lgsp.control.onboarding.api;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/** Hợp đồng công bố — PH-01. */
public interface OnboardingApi {

  ApplicationDto submit(ApplicationSubmitRequest request, String submittedBy);

  ApplicationDto approve(UUID id, String approvedBy);

  Optional<ApplicationDto> findById(UUID id);

  List<ApplicationDto> list(int limit);

  String moduleStatus();
}
