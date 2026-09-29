package vn.lgsp.data.rdm.internal;

/**
 * Bốn loại lỗi nghiệp vụ của RDM, tách riêng để controller ánh xạ đúng mã HTTP mà SRS
 * PH-07 đã quy định — gộp hết vào {@code IllegalArgumentException} thì mọi thứ thành 400
 * và bên gọi không phân biệt được "mã sai" với "không được phép".
 *
 * <ul>
 *   <li>{@link RdmNotFoundException} → 404 (FR-07-007 E1)
 *   <li>{@link RdmValidationException} → 422 (FR-07-001 E2, FR-07-002 E2/E3)
 *   <li>{@link RdmConflictException} → 409 (FR-07-001 E1, FR-07-002 E4)
 *   <li>{@link RdmForbiddenException} → 403 (FR-07-002 E1 — danh mục NATIONAL)
 *   <li>{@link RdmTooLargeException} → 413 (FR-07-008 E1)
 * </ul>
 */
final class RdmExceptions {
  private RdmExceptions() {}
}

/** Không tìm thấy danh mục / phiên bản / mục. */
class RdmNotFoundException extends RuntimeException {
  RdmNotFoundException(String message) {
    super(message);
  }
}

/** Dữ liệu gửi lên không hợp lệ về nghiệp vụ (cấu trúc mã, mã cha, vòng lặp). */
class RdmValidationException extends RuntimeException {
  RdmValidationException(String message) {
    super(message);
  }
}

/** Xung đột trạng thái: mã trùng, sửa phiên bản đã phát hành. */
class RdmConflictException extends RuntimeException {
  RdmConflictException(String message) {
    super(message);
  }
}

/** Thao tác bị cấm theo nguồn gốc danh mục (NATIONAL chỉ đồng bộ). */
class RdmForbiddenException extends RuntimeException {
  RdmForbiddenException(String message) {
    super(message);
  }
}

/** Lô tra cứu vượt trần cho phép. */
class RdmTooLargeException extends RuntimeException {
  RdmTooLargeException(String message) {
    super(message);
  }
}
