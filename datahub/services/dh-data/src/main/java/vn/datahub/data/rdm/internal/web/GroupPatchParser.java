package vn.datahub.data.rdm.internal.web;

import jakarta.validation.Validator;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Component;
import tools.jackson.databind.JsonNode;
import vn.datahub.data.rdm.internal.UpdateGroupCommand;
import vn.datahub.data.shared.web.ApiError;
import vn.datahub.data.shared.web.ConstraintCodes;
import vn.datahub.data.shared.web.DatahubException;
import vn.datahub.data.shared.web.FieldError;

/**
 * Đọc thân merge-patch thành {@link UpdateGroupCommand}: từ chối trường lạ (SS-07-13, ví dụ
 * {@code code}), kiểm kiểu, yêu cầu ít nhất một trường, rồi chạy Jakarta Validation.
 */
@Component
class GroupPatchParser {

  private static final Set<String> KNOWN = Set.of("name", "parentId", "sortOrder", "description");

  private final Validator validator;

  GroupPatchParser(Validator validator) {
    this.validator = validator;
  }

  UpdateGroupCommand parse(JsonNode body) {
    if (!body.isObject()) {
      throw invalid(List.of(new FieldError(null, "TYPE", "Thân yêu cầu phải là một đối tượng JSON.")));
    }
    List<FieldError> errors = new ArrayList<>();
    Set<String> present = new LinkedHashSet<>();
    for (String field : body.propertyNames()) {
      if (KNOWN.contains(field)) {
        present.add(field);
      } else {
        errors.add(
            new FieldError(field, "UNKNOWN_FIELD", "Trường không được khai báo hoặc không được sửa."));
      }
    }
    if (present.isEmpty() && errors.isEmpty()) {
      errors.add(new FieldError(null, "REQUIRED", "Cần ít nhất một trường để sửa."));
    }

    String name = text(body, "name", false, errors);
    UUID parentId = uuid(body, errors);
    Integer sortOrder = integer(body, errors);
    String description = text(body, "description", true, errors);
    if (!errors.isEmpty()) {
      throw invalid(errors);
    }

    CatalogGroupUpdateRequest request =
        new CatalogGroupUpdateRequest(name, parentId, sortOrder, description, present);
    var violations = validator.validate(request);
    if (!violations.isEmpty()) {
      throw invalid(ConstraintCodes.fromViolations(violations));
    }
    return request.toCommand();
  }

  private static String text(JsonNode body, String field, boolean nullable, List<FieldError> errors) {
    JsonNode node = body.get(field);
    if (node == null) {
      return null;
    }
    if (node.isNull()) {
      if (!nullable) {
        errors.add(new FieldError(field, "REQUIRED", "Trường này không được để trống."));
      }
      return null;
    }
    if (!node.isString()) {
      errors.add(new FieldError(field, "TYPE", "Giá trị phải là chuỗi."));
      return null;
    }
    return node.asString();
  }

  private static UUID uuid(JsonNode body, List<FieldError> errors) {
    JsonNode node = body.get("parentId");
    if (node == null || node.isNull()) {
      return null;
    }
    if (node.isString()) {
      try {
        return UUID.fromString(node.asString());
      } catch (IllegalArgumentException e) {
        // rơi xuống báo lỗi kiểu
      }
    }
    errors.add(new FieldError("parentId", "TYPE", "Giá trị phải là UUID hoặc null."));
    return null;
  }

  private static Integer integer(JsonNode body, List<FieldError> errors) {
    JsonNode node = body.get("sortOrder");
    if (node == null) {
      return null;
    }
    if (node.isNull()) {
      errors.add(new FieldError("sortOrder", "REQUIRED", "Trường này không được để trống."));
      return null;
    }
    if (!node.isIntegralNumber() || !node.canConvertToInt()) {
      errors.add(new FieldError("sortOrder", "TYPE", "Giá trị phải là số nguyên."));
      return null;
    }
    return node.intValue();
  }

  private static DatahubException invalid(List<FieldError> errors) {
    return new DatahubException(
        ApiError.VALIDATION, "Có " + errors.size() + " giá trị không hợp lệ.", errors);
  }
}
