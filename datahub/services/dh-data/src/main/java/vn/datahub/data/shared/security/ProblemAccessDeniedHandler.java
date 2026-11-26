package vn.datahub.data.shared.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;
import vn.datahub.data.shared.web.ApiError;
import vn.datahub.data.shared.web.ProblemWriter;

/** 403 ERR-07-046 khi bộ lọc (không phải phương thức) từ chối. */
class ProblemAccessDeniedHandler implements AccessDeniedHandler {

  private final ProblemWriter problems;

  ProblemAccessDeniedHandler(ProblemWriter problems) {
    this.problems = problems;
  }

  @Override
  public void handle(
      HttpServletRequest request, HttpServletResponse response, AccessDeniedException ex)
      throws IOException {
    problems.write(
        request,
        response,
        ApiError.FORBIDDEN,
        "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tỉnh nếu cần được cấp quyền.");
  }
}
