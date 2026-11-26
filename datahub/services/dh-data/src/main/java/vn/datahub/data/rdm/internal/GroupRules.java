package vn.datahub.data.rdm.internal;

import java.text.Normalizer;
import java.util.Locale;

/** Chuẩn hóa đầu vào nhóm trước khi kiểm tra (CC-VAL-03): mã chữ hoa, tên NFC, cắt khoảng trắng. */
public final class GroupRules {

  /** Mẫu T-CODE (lát cắt OpenAPI, ràng buộc ck_catalog_group_code). */
  public static final String CODE_PATTERN = "^[A-Z0-9][A-Z0-9_.-]{0,63}$";

  private GroupRules() {}

  public static String normalizeCode(String raw) {
    return raw.strip().toUpperCase(Locale.ROOT);
  }

  public static String normalizeName(String raw) {
    return Normalizer.normalize(raw.strip(), Normalizer.Form.NFC);
  }

  public static String normalizeDescription(String raw) {
    return Normalizer.normalize(raw, Normalizer.Form.NFC);
  }
}
