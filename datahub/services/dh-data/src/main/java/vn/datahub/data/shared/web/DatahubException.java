package vn.datahub.data.shared.web;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Ngoại lệ nghiệp vụ mang mã lỗi (CC-ERR-02). {@code detail} là câu an toàn, không chứa dữ liệu nhạy cảm. */
public class DatahubException extends RuntimeException {

  private final transient ErrorCode errorCode;
  private final List<FieldError> errors;
  private final Map<String, Object> extensions = new LinkedHashMap<>();

  public DatahubException(ErrorCode errorCode, String detail) {
    this(errorCode, detail, List.of());
  }

  public DatahubException(ErrorCode errorCode, String detail, List<FieldError> errors) {
    super(detail, null, false, false);
    this.errorCode = errorCode;
    this.errors = List.copyOf(errors);
  }

  public ErrorCode errorCode() {
    return errorCode;
  }

  public String safeDetail() {
    return getMessage();
  }

  public List<FieldError> errors() {
    return errors;
  }

  /** Thành viên mở rộng của phản hồi lỗi (ví dụ số danh mục còn lại). */
  public DatahubException with(String name, Object value) {
    extensions.put(name, value);
    return this;
  }

  public Map<String, Object> extensions() {
    return extensions;
  }
}
