package vn.datahub.data.rdm.internal.web;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import vn.datahub.data.shared.web.ConstraintCodes;

class CatalogGroupCreateRequestTest {

  private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

  @Test
  @DisplayName("Chuẩn hóa chạy trước kiểm tra: mã chữ thường hợp lệ sau khi in hoa")
  void normalizesBeforeValidating() {
    var request = new CatalogGroupCreateRequest(" kinh_te ", "  Kinh tế  ", null, null, null);
    assertThat(request.code()).isEqualTo("KINH_TE");
    assertThat(request.name()).isEqualTo("Kinh tế");
    assertThat(validator.validate(request)).isEmpty();
    var command = request.toCommand();
    assertThat(command.sortOrder()).isZero();
    assertThat(command.code()).isEqualTo("KINH_TE");
  }

  @Test
  @DisplayName("Thiếu mã, tên rỗng, mã sai mẫu và mô tả quá dài cho đúng mã con")
  void reportsSubCodes() {
    var request = new CatalogGroupCreateRequest(null, "   ", null, 3, "x".repeat(4001));
    var codes =
        ConstraintCodes.fromViolations(validator.validate(request)).stream()
            .map(e -> e.field() + ":" + e.code())
            .toList();
    assertThat(codes).containsExactlyInAnyOrder("code:REQUIRED", "name:REQUIRED", "description:MAX_LENGTH");

    var badPattern = new CatalogGroupCreateRequest("-sai", "Tên", null, null, null);
    assertThat(ConstraintCodes.fromViolations(validator.validate(badPattern)))
        .extracting(e -> e.field() + ":" + e.code())
        .containsExactly("code:PATTERN");

    var tooLong = new CatalogGroupCreateRequest("OK", "n".repeat(256), null, null, null);
    assertThat(ConstraintCodes.fromViolations(validator.validate(tooLong)))
        .extracting(e -> e.field() + ":" + e.code())
        .containsExactly("name:MAX_LENGTH");
  }

  @Test
  @DisplayName("Ánh xạ mã con theo loại ràng buộc")
  void subCodeMapping() {
    assertThat(ConstraintCodes.subCode("NotNull", null)).isEqualTo("REQUIRED");
    assertThat(ConstraintCodes.subCode("Size", "")).isEqualTo("REQUIRED");
    assertThat(ConstraintCodes.subCode("Size", "abc")).isEqualTo("MAX_LENGTH");
    assertThat(ConstraintCodes.subCode("Min", 1)).isEqualTo("RANGE");
    assertThat(ConstraintCodes.subCode("Email", "x")).isEqualTo("INVALID");
    assertThat(ConstraintCodes.subCode(null, null)).isEqualTo("INVALID");
  }
}
