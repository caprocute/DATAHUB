package vn.datahub.data.rdm.internal;

import static org.assertj.core.api.Assertions.assertThat;

import java.text.Normalizer;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class GroupRulesTest {

  @Test
  @DisplayName("Mã chuẩn hóa chữ hoa và cắt khoảng trắng")
  void codeIsUppercasedAndTrimmed() {
    assertThat(GroupRules.normalizeCode("  hanh_chinh.to-chuc ")).isEqualTo("HANH_CHINH.TO-CHUC");
  }

  @Test
  @DisplayName("Tên chuẩn hóa NFC: dạng tổ hợp (NFD) thành dựng sẵn")
  void nameIsNfc() {
    String nfd = Normalizer.normalize("Hành chính", Normalizer.Form.NFD);
    assertThat(nfd).isNotEqualTo("Hành chính");
    assertThat(GroupRules.normalizeName("  " + nfd + " ")).isEqualTo("Hành chính");
  }

  @Test
  @DisplayName("Mô tả chuẩn hóa NFC nhưng giữ nguyên khoảng trắng")
  void descriptionIsNfc() {
    String nfd = Normalizer.normalize("Mô tả ", Normalizer.Form.NFD);
    assertThat(GroupRules.normalizeDescription(nfd)).isEqualTo("Mô tả ");
  }

  @Test
  @DisplayName("Mẫu mã T-CODE")
  void codePattern() {
    assertThat("A".matches(GroupRules.CODE_PATTERN)).isTrue();
    assertThat("A_B.C-1".matches(GroupRules.CODE_PATTERN)).isTrue();
    assertThat("_A".matches(GroupRules.CODE_PATTERN)).isFalse();
    assertThat("a".matches(GroupRules.CODE_PATTERN)).isFalse();
    assertThat("A".repeat(65).matches(GroupRules.CODE_PATTERN)).isFalse();
  }
}
