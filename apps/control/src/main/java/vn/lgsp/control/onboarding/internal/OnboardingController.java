package vn.lgsp.control.onboarding.internal;

import jakarta.validation.Valid;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;
import vn.lgsp.control.onboarding.api.AccessReviewRequest;
import vn.lgsp.control.onboarding.api.ApplicationDto;
import vn.lgsp.control.onboarding.api.ApplicationSubmitRequest;
import vn.lgsp.control.onboarding.api.AttachmentDto;
import vn.lgsp.control.onboarding.api.OnboardingApi;
import vn.lgsp.control.onboarding.api.PageDto;
import vn.lgsp.control.onboarding.api.ReviewRequest;
import vn.lgsp.control.onboarding.api.StatusChangeRequest;

@RestController
@RequestMapping("/api/v1/onboarding")
class OnboardingController {

  private final OnboardingApi onboardingApi;

  OnboardingController(OnboardingApi onboardingApi) {
    this.onboardingApi = onboardingApi;
  }

  @GetMapping("/status")
  Map<String, String> status() {
    return Map.of("module", "onboarding", "status", onboardingApi.moduleStatus());
  }

  @GetMapping("/applications")
  @PreAuthorize("isAuthenticated()")
  PageDto<ApplicationDto> list(
      @RequestParam(required = false) String q,
      @RequestParam(required = false) String status,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "20") int size) {
    return onboardingApi.search(q, status, page, size);
  }

  @GetMapping("/applications/{id}")
  @PreAuthorize("isAuthenticated()")
  ApplicationDto get(@PathVariable("id") UUID id) {
    return onboardingApi
        .findById(id)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "not found"));
  }

  @GetMapping("/applications/{id}/audit")
  @PreAuthorize("hasAnyRole('INTEGRATION_REVIEWER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  Map<String, Object> audit(@PathVariable("id") UUID id) {
    return Map.of("items", onboardingApi.auditTrail(id));
  }

  @PostMapping("/applications")
  @ResponseStatus(HttpStatus.CREATED)
  @PreAuthorize("hasAnyRole('INTEGRATION_DEVELOPER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  ApplicationDto submit(@Valid @RequestBody ApplicationSubmitRequest body, Authentication auth) {
    return onboardingApi.submit(body, principalName(auth));
  }

  /** FR-01-004 — thẩm định căn cứ pháp lý. */
  @PostMapping("/applications/{id}/review/legal")
  @PreAuthorize("hasAnyRole('INTEGRATION_REVIEWER','PLATFORM_ADMIN')")
  ApplicationDto reviewLegal(
      @PathVariable("id") UUID id, @Valid @RequestBody ReviewRequest body, Authentication auth) {
    return onboardingApi.reviewLegal(id, body, principalName(auth));
  }

  /** FR-01-005 — thẩm định kỹ thuật. */
  @PostMapping("/applications/{id}/review/technical")
  @PreAuthorize("hasAnyRole('INTEGRATION_REVIEWER','PLATFORM_ADMIN')")
  ApplicationDto reviewTechnical(
      @PathVariable("id") UUID id, @Valid @RequestBody ReviewRequest body, Authentication auth) {
    return onboardingApi.reviewTechnical(id, body, principalName(auth));
  }

  /** FR-01-006 / FR-01-008 — duyệt và cấp danh tính; bí mật trả một lần. */
  @PostMapping("/applications/{id}/approve")
  @PreAuthorize("hasAnyRole('INTEGRATION_REVIEWER','PLATFORM_ADMIN')")
  ApplicationDto approve(@PathVariable("id") UUID id, Authentication auth) {
    return onboardingApi.approve(id, principalName(auth));
  }

  @PostMapping("/applications/{id}/reject")
  @PreAuthorize("hasAnyRole('INTEGRATION_REVIEWER','PLATFORM_ADMIN')")
  ApplicationDto reject(
      @PathVariable("id") UUID id,
      @Valid @RequestBody StatusChangeRequest body,
      Authentication auth) {
    return onboardingApi.reject(id, body.reason(), principalName(auth));
  }

  /** FR-01-010 — kích hoạt sau khi kiểm thử kết nối đạt. */
  @PostMapping("/applications/{id}/activate")
  @PreAuthorize("hasAnyRole('INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  ApplicationDto activate(@PathVariable("id") UUID id, Authentication auth) {
    return onboardingApi.activate(id, principalName(auth));
  }

  @PostMapping("/applications/{id}/suspend")
  @PreAuthorize("hasAnyRole('INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  ApplicationDto suspend(
      @PathVariable("id") UUID id,
      @Valid @RequestBody StatusChangeRequest body,
      Authentication auth) {
    return onboardingApi.suspend(id, body.reason(), principalName(auth));
  }

  @PostMapping("/applications/{id}/resume")
  @PreAuthorize("hasAnyRole('INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  ApplicationDto resume(@PathVariable("id") UUID id, Authentication auth) {
    return onboardingApi.resume(id, principalName(auth));
  }

  @PostMapping("/applications/{id}/revoke")
  @PreAuthorize("hasRole('PLATFORM_ADMIN')")
  ApplicationDto revoke(
      @PathVariable("id") UUID id,
      @Valid @RequestBody StatusChangeRequest body,
      Authentication auth) {
    return onboardingApi.revoke(id, body.reason(), principalName(auth));
  }

  /* ---------- Tệp đính kèm (FR-01-003) ---------- */

  @GetMapping("/applications/{id}/attachments")
  @PreAuthorize("isAuthenticated()")
  Map<String, Object> attachments(@PathVariable("id") UUID id) {
    return Map.of("items", onboardingApi.attachments(id));
  }

  @PostMapping(value = "/applications/{id}/attachments", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  @ResponseStatus(HttpStatus.CREATED)
  @PreAuthorize("hasAnyRole('INTEGRATION_DEVELOPER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  AttachmentDto upload(
      @PathVariable("id") UUID id, @RequestPart("file") MultipartFile file, Authentication auth) {
    try {
      return onboardingApi.attach(
          id,
          file.getOriginalFilename(),
          file.getContentType(),
          file.getBytes(),
          principalName(auth));
    } catch (IOException e) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "không đọc được tệp tải lên");
    }
  }

  @GetMapping("/applications/{id}/attachments/{attachmentId}")
  @PreAuthorize("isAuthenticated()")
  ResponseEntity<Resource> download(
      @PathVariable("id") UUID id, @PathVariable("attachmentId") UUID attachmentId) {
    return onboardingApi
        .download(id, attachmentId)
        .map(
            f ->
                ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(f.contentType()))
                    .header(
                        HttpHeaders.CONTENT_DISPOSITION,
                        // `attachment` + tên đã lọc: không để tệp tải về tự chạy trong trình duyệt.
                        ContentDisposition.attachment().filename(f.fileName()).build().toString())
                    .body((Resource) new ByteArrayResource(f.content())))
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "không có tệp"));
  }

  /* ---------- Rà soát quyền định kỳ (FR-01-013) ---------- */

  @GetMapping("/applications/due-access-review")
  @PreAuthorize("hasAnyRole('INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  Map<String, Object> dueAccessReview() {
    return Map.of("items", onboardingApi.dueForAccessReview());
  }

  @PostMapping("/applications/{id}/access-review")
  @PreAuthorize("hasAnyRole('INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  ApplicationDto accessReview(
      @PathVariable("id") UUID id,
      @Valid @RequestBody AccessReviewRequest body,
      Authentication auth) {
    return onboardingApi.recordAccessReview(id, body, principalName(auth));
  }

  /* ---------- Xuất danh sách (C4-3) ---------- */

  @GetMapping("/applications/export")
  @PreAuthorize("hasAnyRole('INTEGRATION_REVIEWER','INTEGRATION_ADMIN','PLATFORM_ADMIN')")
  ResponseEntity<Resource> export(
      @RequestParam(required = false) String q, @RequestParam(required = false) String status) {
    List<ApplicationDto> rows = onboardingApi.exportAll(q, status);
    StringBuilder csv = new StringBuilder();
    // BOM để Excel nhận UTF-8, nếu không thì tiếng Việt hiện sai.
    csv.append('\uFEFF');
    csv.append("Mã hệ thống,Tên,Đơn vị chủ quản,Trạng thái,clientId,Người nộp,Người duyệt,Thẩm định pháp lý,Thẩm định kỹ thuật,Ngày tạo\n");
    for (ApplicationDto a : rows) {
      csv.append(
          String.join(
                  ",",
                  csvCell(a.systemCode()),
                  csvCell(a.systemName()),
                  csvCell(a.ownerOrg()),
                  csvCell(a.status()),
                  csvCell(a.clientId()),
                  csvCell(a.submittedBy()),
                  csvCell(a.approvedBy()),
                  csvCell(a.legalReview() == null ? null : a.legalReview().status()),
                  csvCell(a.techReview() == null ? null : a.techReview().status()),
                  csvCell(a.createdAt() == null ? null : a.createdAt().toString()))
              )
          .append('\n');
    }
    byte[] bytes = csv.toString().getBytes(StandardCharsets.UTF_8);
    return ResponseEntity.ok()
        .contentType(MediaType.parseMediaType("text/csv; charset=UTF-8"))
        .header(
            HttpHeaders.CONTENT_DISPOSITION,
            ContentDisposition.attachment().filename("ho-so-ket-nap.csv").build().toString())
        .body(new ByteArrayResource(bytes));
  }

  /**
   * Bọc một ô CSV.
   *
   * Ô bắt đầu bằng `= + - @` bị thêm dấu nháy đơn: Excel sẽ diễn giải chúng là công thức,
   * và dữ liệu do người ngoài nhập có thể lợi dụng điều đó (CSV injection).
   */
  private static String csvCell(String value) {
    String v = value == null ? "" : value;
    if (!v.isEmpty() && "=+-@".indexOf(v.charAt(0)) >= 0) {
      v = "'" + v;
    }
    return '"' + v.replace("\"", "\"\"") + '"';
  }

  /* ---------- Ánh xạ lỗi nghiệp vụ sang mã HTTP ---------- */

  @ExceptionHandler(ApplicationNotFoundException.class)
  @ResponseStatus(HttpStatus.NOT_FOUND)
  Map<String, String> notFound(ApplicationNotFoundException e) {
    return Map.of("error", e.getMessage());
  }

  /** Dữ liệu người dùng gửi sai (tệp rỗng, định dạng không cho phép, quá cỡ). */
  @ExceptionHandler(IllegalArgumentException.class)
  @ResponseStatus(HttpStatus.BAD_REQUEST)
  Map<String, String> badRequest(IllegalArgumentException e) {
    return Map.of("error", e.getMessage());
  }

  /** Bước chuyển trạng thái không hợp lệ — xung đột trạng thái, không phải lỗi quyền. */
  @ExceptionHandler(IllegalStateException.class)
  @ResponseStatus(HttpStatus.CONFLICT)
  Map<String, String> conflict(IllegalStateException e) {
    return Map.of("error", e.getMessage());
  }

  /** Vi phạm bốn mắt — người dùng có vai trò nhưng không được làm trên hồ sơ này. */
  @ExceptionHandler(SelfReviewException.class)
  @ResponseStatus(HttpStatus.FORBIDDEN)
  Map<String, String> forbidden(SelfReviewException e) {
    return Map.of("error", e.getMessage());
  }

  private static String principalName(Authentication auth) {
    if (auth != null && auth.getPrincipal() instanceof Jwt jwt) {
      String preferred = jwt.getClaimAsString("preferred_username");
      return preferred != null ? preferred : jwt.getSubject();
    }
    return auth != null ? auth.getName() : "anonymous";
  }
}
