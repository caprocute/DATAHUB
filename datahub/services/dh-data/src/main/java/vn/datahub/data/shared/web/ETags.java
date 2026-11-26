package vn.datahub.data.shared.web;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** ETag yếu của tài nguyên quản trị: {@code W/"{version}"} (CC-TX-04). */
public final class ETags {

  private static final Pattern IF_MATCH = Pattern.compile("^(?:W/)?\"(\\d{1,9})\"$");

  private ETags() {}

  public static String weak(int version) {
    return "W/\"" + version + "\"";
  }

  /**
   * Đọc version từ If-Match.
   *
   * @throws DatahubException 400 ERR-07-040 nếu thiếu hoặc sai định dạng
   */
  public static int parseIfMatch(String header) {
    if (header == null || header.isBlank()) {
      throw new DatahubException(
          ApiError.PRECONDITION_REQUIRED, "Thiếu tiêu đề If-Match. Hãy tải lại dữ liệu để lấy ETag.");
    }
    Matcher m = IF_MATCH.matcher(header.trim());
    if (!m.matches()) {
      throw new DatahubException(
          ApiError.PRECONDITION_REQUIRED, "Tiêu đề If-Match không đúng định dạng W/\"{version}\".");
    }
    return Integer.parseInt(m.group(1));
  }
}
