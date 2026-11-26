package vn.datahub.data.shared.web;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class ETagsTest {

  @Test
  @DisplayName("ETag yếu sinh từ version")
  void weakEtag() {
    assertThat(ETags.weak(0)).isEqualTo("W/\"0\"");
    assertThat(ETags.weak(12)).isEqualTo("W/\"12\"");
  }

  @Test
  @DisplayName("If-Match đọc được dạng yếu và dạng mạnh")
  void parses() {
    assertThat(ETags.parseIfMatch("W/\"7\"")).isEqualTo(7);
    assertThat(ETags.parseIfMatch(" \"3\" ")).isEqualTo(3);
  }

  @Test
  @DisplayName("If-Match thiếu hoặc sai định dạng là 400 ERR-07-040")
  void rejects() {
    for (String bad : new String[] {null, "", "  ", "*", "W/abc", "W/\"-1\"", "W/\"12345678901\""}) {
      assertThatThrownBy(() -> ETags.parseIfMatch(bad))
          .isInstanceOfSatisfying(
              DatahubException.class,
              ex -> assertThat(ex.errorCode().code()).isEqualTo("ERR-07-040"));
    }
  }
}
