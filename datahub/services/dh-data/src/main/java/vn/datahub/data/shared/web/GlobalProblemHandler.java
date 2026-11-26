package vn.datahub.data.shared.web;

import jakarta.servlet.http.HttpServletRequest;
import java.time.Clock;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.TypeMismatchException;
import org.springframework.dao.OptimisticLockingFailureException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.ServletWebRequest;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.NoHandlerFoundException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;
import org.springframework.web.servlet.resource.NoResourceFoundException;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.exc.UnrecognizedPropertyException;

/**
 * Bộ xử lý lỗi toàn cục duy nhất của DU (CC-ERR-01): mọi ngoại lệ thành RFC 9457 kèm mã ERR-07.
 * Không lộ stack trace, tên lớp, SQL hay thông điệp gốc của hạ tầng (CC-ERR-03).
 */
@RestControllerAdvice
public class GlobalProblemHandler extends ResponseEntityExceptionHandler {

  private static final Logger log = LoggerFactory.getLogger(GlobalProblemHandler.class);

  private final Clock clock;

  public GlobalProblemHandler(Clock clock) {
    this.clock = clock;
  }

  @ExceptionHandler(DatahubException.class)
  ResponseEntity<Object> handleBusiness(DatahubException ex, HttpServletRequest request) {
    log.info("business_error code={}", ex.errorCode().code());
    return respond(
        ex.errorCode(), ex.safeDetail(), ex.errors(), ex.extensions(), request, new HttpHeaders());
  }

  @ExceptionHandler(AccessDeniedException.class)
  ResponseEntity<Object> handleAccessDenied(AccessDeniedException ex, HttpServletRequest request) {
    log.info("access_denied");
    return respond(
        ApiError.FORBIDDEN,
        "Bạn không có quyền thực hiện thao tác này. Liên hệ quản trị tỉnh nếu cần được cấp quyền.",
        List.of(),
        Map.of(),
        request,
        new HttpHeaders());
  }

  @ExceptionHandler(OptimisticLockingFailureException.class)
  ResponseEntity<Object> handleOptimisticLock(
      OptimisticLockingFailureException ex, HttpServletRequest request) {
    log.info("optimistic_lock_conflict");
    return respond(
        ApiError.PRECONDITION_FAILED,
        "Dữ liệu đã được người khác cập nhật trong lúc bạn đang sửa. Hãy tải lại rồi thực hiện lại.",
        List.of(),
        Map.of(),
        request,
        new HttpHeaders());
  }

  @ExceptionHandler(Exception.class)
  ResponseEntity<Object> handleUnexpected(Exception ex, HttpServletRequest request) {
    log.error("unexpected_error", ex);
    return respond(
        ApiError.INTERNAL,
        "Đã xảy ra lỗi hệ thống. Vui lòng liên hệ hỗ trợ kèm mã truy vết.",
        List.of(),
        Map.of(),
        request,
        new HttpHeaders());
  }

  @Override
  protected ResponseEntity<Object> handleExceptionInternal(
      Exception ex,
      Object body,
      HttpHeaders headers,
      HttpStatusCode statusCode,
      WebRequest webRequest) {
    HttpServletRequest request = ((ServletWebRequest) webRequest).getRequest();
    return switch (ex) {
      case MethodArgumentNotValidException invalid ->
          respond(
              ApiError.VALIDATION,
              "Có " + invalid.getBindingResult().getFieldErrorCount() + " giá trị không hợp lệ.",
              fieldErrors(invalid),
              Map.of(),
              request,
              headers);
      case HttpMessageNotReadableException unreadable -> notReadable(unreadable, request, headers);
      case HttpMediaTypeNotSupportedException unsupported ->
          respond(
              ApiError.UNSUPPORTED_MEDIA_TYPE,
              "Kiểu nội dung không được hỗ trợ: " + unsupported.getContentType() + ".",
              List.of(),
              Map.of(),
              request,
              headers);
      case MissingRequestHeaderException missing
          when "If-Match".equalsIgnoreCase(missing.getHeaderName()) ->
          respond(
              ApiError.PRECONDITION_REQUIRED,
              "Thiếu tiêu đề If-Match. Hãy tải lại dữ liệu để lấy ETag.",
              List.of(),
              Map.of(),
              request,
              headers);
      case NoResourceFoundException ignored -> notFound(request, headers);
      case NoHandlerFoundException ignored -> notFound(request, headers);
      case HttpRequestMethodNotSupportedException ignored ->
          respond(
              ApiError.METHOD_NOT_ALLOWED,
              "Phương thức HTTP không được hỗ trợ cho đường dẫn này.",
              List.of(),
              Map.of(),
              request,
              headers);
      case MethodArgumentTypeMismatchException mismatch -> typeMismatch(mismatch, request, headers);
      case TypeMismatchException mismatch ->
          respond(
              ApiError.VALIDATION,
              "Giá trị tham số không đúng kiểu.",
              List.of(new FieldError(mismatch.getPropertyName(), "TYPE", "Giá trị không đúng kiểu.")),
              Map.of(),
              request,
              headers);
      default ->
          respond(
              ApiError.BAD_REQUEST,
              "Yêu cầu sai cú pháp hoặc thiếu tham số bắt buộc.",
              List.of(),
              Map.of(),
              request,
              headers);
    };
  }

  private ResponseEntity<Object> notFound(HttpServletRequest request, HttpHeaders headers) {
    return respond(
        ApiError.RESOURCE_NOT_FOUND,
        "Không tìm thấy tài nguyên theo đường dẫn đã gọi.",
        List.of(),
        Map.of(),
        request,
        headers);
  }

  private ResponseEntity<Object> typeMismatch(
      MethodArgumentTypeMismatchException ex, HttpServletRequest request, HttpHeaders headers) {
    if (ex.getParameter().hasParameterAnnotation(PathVariable.class)) {
      // Định danh sai dạng thì không thể tồn tại: cùng câu trả lời với "không thấy" (CC-TEN-06).
      return notFound(request, headers);
    }
    return respond(
        ApiError.VALIDATION,
        "Giá trị tham số \"" + ex.getName() + "\" không đúng kiểu.",
        List.of(new FieldError(ex.getName(), "TYPE", "Giá trị không đúng kiểu.")),
        Map.of(),
        request,
        headers);
  }

  private ResponseEntity<Object> notReadable(
      HttpMessageNotReadableException ex, HttpServletRequest request, HttpHeaders headers) {
    FieldError error = new FieldError(null, "TYPE", "Thân yêu cầu không phải JSON hợp lệ.");
    for (Throwable t = ex.getCause(); t != null; t = t.getCause()) {
      if (t instanceof UnrecognizedPropertyException unknown) {
        error =
            new FieldError(
                unknown.getPropertyName(),
                "UNKNOWN_FIELD",
                "Trường không được khai báo trong hợp đồng API.");
        break;
      }
      if (t instanceof JacksonException jackson && !jackson.getPath().isEmpty()) {
        String field = jackson.getPath().getLast().getPropertyName();
        error = new FieldError(field, "TYPE", "Giá trị không đúng kiểu dữ liệu.");
        break;
      }
    }
    return respond(
        ApiError.VALIDATION,
        "Thân yêu cầu không hợp lệ.",
        List.of(error),
        Map.of(),
        request,
        headers);
  }

  private static List<FieldError> fieldErrors(MethodArgumentNotValidException ex) {
    List<FieldError> result = new ArrayList<>();
    for (org.springframework.validation.FieldError fe : ex.getBindingResult().getFieldErrors()) {
      result.add(
          new FieldError(
              fe.getField(),
              ConstraintCodes.subCode(fe.getCode(), fe.getRejectedValue()),
              fe.getDefaultMessage()));
    }
    return result;
  }

  private ResponseEntity<Object> respond(
      ErrorCode code,
      String detail,
      List<FieldError> errors,
      Map<String, Object> extensions,
      HttpServletRequest request,
      HttpHeaders headers) {
    ProblemBody body = Problems.of(code, detail, errors, extensions, request, clock);
    HttpHeaders out = new HttpHeaders();
    out.putAll(headers);
    out.setContentType(ProblemBody.MEDIA_TYPE);
    return ResponseEntity.status(code.status()).headers(out).body(body);
  }
}
