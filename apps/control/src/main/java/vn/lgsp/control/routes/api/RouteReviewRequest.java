package vn.lgsp.control.routes.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record RouteReviewRequest(
    @NotBlank @Pattern(regexp = "APPROVE|REJECT") String decision,
    String comment) {}
