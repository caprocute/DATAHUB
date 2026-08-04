package vn.lgsp.control.onboarding.api;

import java.util.List;

/**
 * Một trang kết quả.
 *
 * Dùng phân trang theo số trang (không phải con trỏ) vì màn kết nạp cần nhảy trang
 * và hiện tổng số hồ sơ; `CursorPage` của `libs/common-java` hợp với luồng cuộn vô hạn.
 */
public record PageDto<T>(List<T> items, int page, int size, long total) {

  public int totalPages() {
    return size <= 0 ? 0 : (int) Math.ceil((double) total / size);
  }
}
