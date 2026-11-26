package vn.datahub.data.shared.web;

/**
 * Mã lỗi của lớp biên (xác thực, điều kiện tiên quyết, kiểm tra đầu vào, khung HTTP). Dùng mã ERR-07
 * vì lát cắt mẫu chỉ phục vụ PH-07 (tóm tắt §6); khi DU có thêm phân hệ thì tham số hóa theo module.
 */
public enum ApiError implements ErrorCode {
  VALIDATION("ERR-07-009", 422, "Dữ liệu không hợp lệ", "validation"),
  PRECONDITION_FAILED("ERR-07-018", 412, "Dữ liệu đã bị người khác cập nhật", "precondition-failed"),
  IDEMPOTENCY_CONFLICT("ERR-07-022", 409, "Khóa chống trùng đã dùng với nội dung khác", "idempotency-conflict"),
  PRECONDITION_REQUIRED("ERR-07-040", 400, "Thiếu hoặc sai tiêu đề If-Match", "precondition-required"),
  UNAUTHENTICATED("ERR-07-041", 401, "Thiếu hoặc sai token", "unauthenticated"),
  PAYLOAD_TOO_LARGE("ERR-07-042", 413, "Thân yêu cầu quá lớn", "payload-too-large"),
  UNSUPPORTED_MEDIA_TYPE("ERR-07-043", 415, "Kiểu nội dung không được hỗ trợ", "unsupported-media-type"),
  RESOURCE_NOT_FOUND("ERR-07-045", 404, "Không tìm thấy tài nguyên", "resource-not-found"),
  FORBIDDEN("ERR-07-046", 403, "Không đủ quyền thực hiện thao tác", "forbidden"),
  BAD_REQUEST("ERR-00-400", 400, "Yêu cầu không hợp lệ", "bad-request"),
  METHOD_NOT_ALLOWED("ERR-00-405", 405, "Phương thức không được hỗ trợ", "method-not-allowed"),
  INTERNAL("ERR-00-500", 500, "Lỗi hệ thống", "internal");

  private final String code;
  private final int status;
  private final String title;
  private final String slug;

  ApiError(String code, int status, String title, String slug) {
    this.code = code;
    this.status = status;
    this.title = title;
    this.slug = slug;
  }

  @Override
  public String code() {
    return code;
  }

  @Override
  public int status() {
    return status;
  }

  @Override
  public String title() {
    return title;
  }

  @Override
  public String slug() {
    return slug;
  }
}
