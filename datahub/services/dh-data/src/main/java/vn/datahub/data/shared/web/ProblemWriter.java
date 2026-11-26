package vn.datahub.data.shared.web;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;
import tools.jackson.databind.json.JsonMapper;

/** Ghi lỗi RFC 9457 trực tiếp ra phản hồi cho nơi ngoài MVC (bộ lọc bảo mật, giới hạn kích thước). */
@Component
public class ProblemWriter {

  private final JsonMapper mapper;
  private final Clock clock;

  public ProblemWriter(JsonMapper mapper, Clock clock) {
    this.mapper = mapper;
    this.clock = clock;
  }

  public void write(
      HttpServletRequest request, HttpServletResponse response, ErrorCode code, String detail)
      throws IOException {
    ProblemBody body = Problems.of(code, detail, List.of(), Map.of(), request, clock);
    response.setStatus(code.status());
    response.setContentType(ProblemBody.MEDIA_TYPE_VALUE);
    response.setCharacterEncoding(StandardCharsets.UTF_8.name());
    response.getOutputStream().write(mapper.writeValueAsBytes(body));
  }
}
