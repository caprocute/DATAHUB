package vn.datahub.data.rdm.internal.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import jakarta.validation.Validation;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.json.JsonMapper;
import vn.datahub.data.rdm.internal.UpdateGroupCommand;
import vn.datahub.data.shared.web.DatahubException;
import vn.datahub.data.shared.web.FieldError;

class GroupPatchParserTest {

  private final JsonMapper mapper = JsonMapper.builder().build();
  private final GroupPatchParser parser =
      new GroupPatchParser(Validation.buildDefaultValidatorFactory().getValidator());

  private UpdateGroupCommand parse(String json) {
    return parser.parse(mapper.readTree(json));
  }

  private List<String> errorsOf(String json) {
    DatahubException ex =
        (DatahubException)
            assertThatThrownBy(() -> parse(json)).isInstanceOf(DatahubException.class).actual();
    return ex.errors().stream().map((FieldError e) -> e.field() + ":" + e.code()).toList();
  }

  @Test
  @DisplayName("Merge-patch: trường vắng giữ nguyên, null đặt về rỗng")
  void presenceIsTracked() {
    UUID parent = UUID.randomUUID();
    UpdateGroupCommand cmd =
        parse("{\"name\":\"  Tên mới \",\"parentId\":\"" + parent + "\",\"description\":null}");
    assertThat(cmd.hasName()).isTrue();
    assertThat(cmd.name()).isEqualTo("Tên mới");
    assertThat(cmd.hasParentId()).isTrue();
    assertThat(cmd.parentId()).isEqualTo(parent);
    assertThat(cmd.hasSortOrder()).isFalse();
    assertThat(cmd.hasDescription()).isTrue();
    assertThat(cmd.description()).isNull();

    UpdateGroupCommand detach = parse("{\"parentId\":null,\"sortOrder\":7}");
    assertThat(detach.hasParentId()).isTrue();
    assertThat(detach.parentId()).isNull();
    assertThat(detach.sortOrder()).isEqualTo(7);
  }

  @Test
  @DisplayName("Trường lạ (kể cả code) bị từ chối UNKNOWN_FIELD")
  void unknownFields() {
    assertThat(errorsOf("{\"code\":\"DOI\"}")).containsExactly("code:UNKNOWN_FIELD");
    assertThat(errorsOf("{\"name\":\"A\",\"tenantId\":\"T01\"}")).containsExactly("tenantId:UNKNOWN_FIELD");
  }

  @Test
  @DisplayName("Thân rỗng hoặc không phải đối tượng")
  void emptyOrNotObject() {
    assertThat(errorsOf("{}")).containsExactly("null:REQUIRED");
    assertThat(errorsOf("[1]")).containsExactly("null:TYPE");
  }

  @Test
  @DisplayName("Sai kiểu và null ở trường bắt buộc")
  void typeErrors() {
    assertThat(errorsOf("{\"name\":null}")).containsExactly("name:REQUIRED");
    assertThat(errorsOf("{\"name\":5}")).containsExactly("name:TYPE");
    assertThat(errorsOf("{\"parentId\":\"khong-phai-uuid\"}")).containsExactly("parentId:TYPE");
    assertThat(errorsOf("{\"parentId\":5}")).containsExactly("parentId:TYPE");
    assertThat(errorsOf("{\"sortOrder\":\"5\"}")).containsExactly("sortOrder:TYPE");
    assertThat(errorsOf("{\"sortOrder\":1.5}")).containsExactly("sortOrder:TYPE");
    assertThat(errorsOf("{\"sortOrder\":null}")).containsExactly("sortOrder:REQUIRED");
  }

  @Test
  @DisplayName("Ràng buộc Jakarta sau chuẩn hóa: tên rỗng, tên và mô tả quá dài")
  void jakartaConstraints() {
    assertThat(errorsOf("{\"name\":\"   \"}")).containsExactly("name:REQUIRED");
    assertThat(errorsOf("{\"name\":\"" + "x".repeat(256) + "\"}")).containsExactly("name:MAX_LENGTH");
    assertThat(errorsOf("{\"description\":\"" + "x".repeat(4001) + "\"}"))
        .containsExactly("description:MAX_LENGTH");
  }
}
