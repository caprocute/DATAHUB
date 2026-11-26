package vn.datahub.data.shared.web;

import com.fasterxml.jackson.annotation.JsonAnyGetter;
import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonPropertyOrder;
import java.util.List;
import java.util.Map;
import org.springframework.http.MediaType;

/** Thân phản hồi lỗi RFC 9457 (application/problem+json) mở rộng bằng code, traceId, timestamp, errors. */
@JsonInclude(JsonInclude.Include.NON_NULL)
@JsonPropertyOrder({"type", "title", "status", "code", "detail", "instance", "traceId", "timestamp", "errors"})
public record ProblemBody(
    String type,
    String title,
    int status,
    String code,
    String detail,
    String instance,
    String traceId,
    String timestamp,
    @JsonInclude(JsonInclude.Include.NON_EMPTY) List<FieldError> errors,
    @JsonAnyGetter Map<String, Object> extensions) {

  public static final MediaType MEDIA_TYPE = MediaType.APPLICATION_PROBLEM_JSON;
  public static final String MEDIA_TYPE_VALUE = MediaType.APPLICATION_PROBLEM_JSON_VALUE;
}
