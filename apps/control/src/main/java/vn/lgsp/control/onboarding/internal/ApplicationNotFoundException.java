package vn.lgsp.control.onboarding.internal;

import java.util.UUID;

/**
 * Không có hồ sơ với mã đã cho.
 *
 * Tách khỏi `IllegalArgumentException` để controller phân biệt được: hồ sơ không tồn tại
 * là **404**, còn dữ liệu người dùng gửi sai (tệp rỗng, định dạng không cho phép) là **400**.
 */
class ApplicationNotFoundException extends RuntimeException {

  ApplicationNotFoundException(UUID id) {
    super("không có hồ sơ: " + id);
  }
}
