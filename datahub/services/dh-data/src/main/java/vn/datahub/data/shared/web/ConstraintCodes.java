package vn.datahub.data.shared.web;

import jakarta.validation.ConstraintViolation;
import java.util.ArrayList;
import java.util.List;
import org.jspecify.annotations.Nullable;

/** Ánh xạ ràng buộc Jakarta sang mã con của {@code errors[]}: REQUIRED, MAX_LENGTH, PATTERN, RANGE. */
public final class ConstraintCodes {

  private ConstraintCodes() {}

  public static String subCode(@Nullable String constraint, @Nullable Object rejected) {
    return switch (constraint == null ? "" : constraint) {
      case "NotNull", "NotBlank", "NotEmpty" -> "REQUIRED";
      case "Size" -> rejected == null || rejected.toString().isEmpty() ? "REQUIRED" : "MAX_LENGTH";
      case "Pattern" -> "PATTERN";
      case "Min", "Max", "Range" -> "RANGE";
      default -> "INVALID";
    };
  }

  public static List<FieldError> fromViolations(java.util.Set<? extends ConstraintViolation<?>> violations) {
    List<FieldError> errors = new ArrayList<>();
    for (ConstraintViolation<?> v : violations) {
      String constraint = v.getConstraintDescriptor().getAnnotation().annotationType().getSimpleName();
      errors.add(
          new FieldError(
              v.getPropertyPath().toString(),
              subCode(constraint, v.getInvalidValue()),
              v.getMessage()));
    }
    errors.sort(java.util.Comparator.comparing(e -> String.valueOf(e.field())));
    return errors;
  }
}
