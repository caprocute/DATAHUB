package vn.datahub.data.shared.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import vn.datahub.data.shared.web.ApiError;
import vn.datahub.data.shared.web.ProblemWriter;

/** 401 ERR-07-041 cho thiếu token hoặc token hỏng, hết hạn, sai chữ ký. */
class ProblemAuthenticationEntryPoint implements AuthenticationEntryPoint {

  private final ProblemWriter problems;

  ProblemAuthenticationEntryPoint(ProblemWriter problems) {
    this.problems = problems;
  }

  @Override
  public void commence(
      HttpServletRequest request, HttpServletResponse response, AuthenticationException ex)
      throws IOException {
    response.setHeader("WWW-Authenticate", "Bearer error=\"invalid_token\"");
    problems.write(
        request,
        response,
        ApiError.UNAUTHENTICATED,
        "Thiếu hoặc sai token đăng nhập. Hãy đăng nhập lại.");
  }
}
