package vn.lgsp.control.onboarding.internal;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.lgsp.control.shared.events.SystemApprovedEvent;
import vn.lgsp.control.onboarding.api.AccessReviewRequest;
import vn.lgsp.control.onboarding.api.ApplicationDto;
import vn.lgsp.control.onboarding.api.ApplicationSubmitRequest;
import vn.lgsp.control.onboarding.api.AttachmentDto;
import vn.lgsp.control.onboarding.api.AuditEntryDto;
import vn.lgsp.control.onboarding.api.OnboardingApi;
import vn.lgsp.control.onboarding.api.PageDto;
import vn.lgsp.control.onboarding.api.ReviewDto;
import vn.lgsp.control.onboarding.api.ReviewRequest;

@Service
class OnboardingService implements OnboardingApi {

  /** Cột đọc chung — không bao giờ có `client_secret_sealed`. */
  private static final String COLUMNS =
      """
      id, system_code, system_name, owner_org, status, client_id,
      legal_basis, tech_profile, contact_name, contact_email, contact_phone,
      submitted_by, approved_by, status_reason,
      legal_review_status, legal_review_by, legal_review_note, legal_review_at,
      tech_review_status, tech_review_by, tech_review_note, tech_review_at,
      created_at, updated_at
      """;

  /**
   * Bí mật **không** nằm trong mapper: mọi lối đọc thông thường đều không trả về.
   * Chỉ `approve()` gắn thêm bí mật vừa sinh vào kết quả một lần duy nhất (FR-01-009).
   */
  private static final RowMapper<ApplicationDto> MAPPER =
      (rs, i) ->
          new ApplicationDto(
              rs.getObject("id", UUID.class),
              rs.getString("system_code"),
              rs.getString("system_name"),
              rs.getString("owner_org"),
              rs.getString("status"),
              rs.getString("client_id"),
              null,
              rs.getString("legal_basis"),
              rs.getString("tech_profile"),
              rs.getString("contact_name"),
              rs.getString("contact_email"),
              rs.getString("contact_phone"),
              rs.getString("submitted_by"),
              rs.getString("approved_by"),
              rs.getString("status_reason"),
              new ReviewDto(
                  rs.getString("legal_review_status"),
                  rs.getString("legal_review_by"),
                  rs.getString("legal_review_note"),
                  rs.getObject("legal_review_at", OffsetDateTime.class)),
              new ReviewDto(
                  rs.getString("tech_review_status"),
                  rs.getString("tech_review_by"),
                  rs.getString("tech_review_note"),
                  rs.getObject("tech_review_at", OffsetDateTime.class)),
              rs.getObject("created_at", OffsetDateTime.class),
              rs.getObject("updated_at", OffsetDateTime.class));

  private static final RowMapper<AuditEntryDto> AUDIT_MAPPER =
      (rs, i) ->
          new AuditEntryDto(
              rs.getObject("id", UUID.class),
              rs.getString("action"),
              rs.getString("from_status"),
              rs.getString("to_status"),
              rs.getString("actor"),
              rs.getString("note"),
              rs.getObject("created_at", OffsetDateTime.class));

  /** Chuyển trạng thái hợp lệ — mọi bước ngoài bảng này bị chặn. */
  private static final Map<String, Set<String>> ALLOWED =
      Map.of(
          "SUBMITTED", Set.of("REVIEWED", "REJECTED"),
          "REVIEWED", Set.of("APPROVED", "REJECTED"),
          "APPROVED", Set.of("ACTIVE", "REVOKED"),
          "ACTIVE", Set.of("SUSPENDED", "REVOKED"),
          "SUSPENDED", Set.of("ACTIVE", "REVOKED"),
          "REJECTED", Set.of(),
          "REVOKED", Set.of());

  private static final RowMapper<AttachmentDto> ATTACHMENT_MAPPER =
      (rs, i) ->
          new AttachmentDto(
              rs.getObject("id", UUID.class),
              rs.getString("file_name"),
              rs.getString("content_type"),
              rs.getLong("size_bytes"),
              rs.getString("sha256"),
              rs.getString("uploaded_by"),
              rs.getObject("created_at", OffsetDateTime.class));

  private final JdbcTemplate jdbc;
  private final OutboxWriter outbox;
  private final AttachmentStorage storage;

  /**
   * Kênh sự kiện **trong tiến trình** cho các phân hệ khác trong cùng ứng dụng.
   *
   * Song song với outbox chứ không thay thế: outbox dành cho bus ngoài (chưa có broker),
   * còn kênh này để PH-04 biết ngay mà không phải phụ thuộc vào `onboarding :: api` —
   * phụ thuộc đó làm `ApplicationModules.verify()` đỏ (IP-07 K1-7c).
   */
  private final ApplicationEventPublisher events;

  OnboardingService(
      JdbcTemplate jdbc,
      OutboxWriter outbox,
      AttachmentStorage storage,
      ApplicationEventPublisher events) {
    this.events = events;
    this.jdbc = jdbc;
    this.outbox = outbox;
    this.storage = storage;
  }

  @Override
  @Transactional
  public ApplicationDto submit(ApplicationSubmitRequest request, String submittedBy) {
    UUID id = UUID.randomUUID();
    OffsetDateTime now = OffsetDateTime.now();
    jdbc.update(
        """
        INSERT INTO ph01.application
          (id, system_code, system_name, owner_org, status,
           legal_basis, tech_profile, contact_name, contact_email, contact_phone,
           submitted_by, created_at, updated_at)
        VALUES (?, ?, ?, ?, 'SUBMITTED', ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        id,
        request.systemCode(),
        request.systemName(),
        request.ownerOrg(),
        request.legalBasis(),
        request.techProfile(),
        request.contactName(),
        request.contactEmail(),
        request.contactPhone(),
        submittedBy,
        now,
        now);
    audit(id, "SUBMIT", null, "SUBMITTED", submittedBy, null);
    return load(id);
  }

  @Override
  @Transactional
  public ApplicationDto reviewLegal(UUID id, ReviewRequest request, String reviewer) {
    return review(id, request, reviewer, "legal");
  }

  @Override
  @Transactional
  public ApplicationDto reviewTechnical(UUID id, ReviewRequest request, String reviewer) {
    return review(id, request, reviewer, "tech");
  }

  /**
   * Ghi một bước thẩm định.
   *
   * Người thẩm định không được là người nộp hồ sơ: thẩm định là chốt chặn độc lập,
   * tự thẩm định hồ sơ của mình thì chốt chặn mất tác dụng.
   */
  private ApplicationDto review(UUID id, ReviewRequest request, String reviewer, String kind) {
    ApplicationDto current = load(id);
    if (!"SUBMITTED".equals(current.status())) {
      throw new IllegalStateException(
          "chỉ thẩm định hồ sơ ở trạng thái SUBMITTED, hiện: " + current.status());
    }
    requireDifferentActor(current.submittedBy(), reviewer, "thẩm định");

    boolean pass = request.decision() == ReviewRequest.Decision.PASS;
    String status = pass ? "PASS" : "FAIL";
    OffsetDateTime now = OffsetDateTime.now();

    jdbc.update(
        "UPDATE ph01.application SET %s_review_status = ?, %s_review_by = ?, %s_review_note = ?, %s_review_at = ?, updated_at = ? WHERE id = ?"
            .formatted(kind, kind, kind, kind),
        status,
        reviewer,
        request.note(),
        now,
        now,
        id);
    audit(id, ("legal".equals(kind) ? "REVIEW_LEGAL" : "REVIEW_TECH"), current.status(), null, reviewer, status + (request.note() == null ? "" : " — " + request.note()));

    ApplicationDto after = load(id);

    // Một bước trượt là hồ sơ bị từ chối ngay, không chờ bước còn lại.
    if (!pass) {
      return transition(
          id, after, "REJECTED", reviewer, "Thẩm định %s không đạt".formatted("legal".equals(kind) ? "pháp lý" : "kỹ thuật"), "REJECT");
    }
    // Đủ cả hai bước đạt thì hồ sơ sẵn sàng để duyệt.
    if (isPass(after.legalReview()) && isPass(after.techReview())) {
      return transition(id, after, "REVIEWED", reviewer, null, "REVIEWED");
    }
    return after;
  }

  private static boolean isPass(ReviewDto r) {
    return r != null && "PASS".equals(r.status());
  }

  @Override
  @Transactional
  public ApplicationDto approve(UUID id, String approvedBy) {
    ApplicationDto current = load(id);
    if ("APPROVED".equals(current.status())) {
      // Duyệt lại không cấp bí mật mới — tránh vô tình xoay bí mật đang dùng.
      return current;
    }
    if (!"REVIEWED".equals(current.status())) {
      throw new IllegalStateException(
          "phải hoàn tất thẩm định pháp lý và kỹ thuật trước khi duyệt, hiện: " + current.status());
    }
    requireDifferentActor(current.submittedBy(), approvedBy, "duyệt");

    String clientId = "lgsp-" + current.systemCode().toLowerCase().replace('_', '-');
    // DEV: bí mật niêm phong tại chỗ. PROD cấp qua Keycloak + Vault (FR-01-008).
    String sealed = "sealed:dev:" + UUID.randomUUID();
    OffsetDateTime now = OffsetDateTime.now();

    jdbc.update(
        """
        UPDATE ph01.application
        SET status = 'APPROVED', client_id = ?, client_secret_sealed = ?, approved_by = ?, updated_at = ?
        WHERE id = ?
        """,
        clientId,
        sealed,
        approvedBy,
        now,
        id);
    audit(id, "APPROVE", current.status(), "APPROVED", approvedBy, null);

    String payload =
        """
        {"specversion":"1.0","type":"onboarding.system-approved.v1","source":"urn:lgsp:control:onboarding","id":"%s","time":"%s","data":{"applicationId":"%s","systemCode":"%s","clientId":"%s","approvedBy":"%s"}}
        """
            .formatted(
                UUID.randomUUID(),
                now,
                id,
                escape(current.systemCode()),
                escape(clientId),
                escape(approvedBy));
    outbox.enqueue("onboarding.system-approved.v1", payload);
    // Phát trong tiến trình để PH-04 cập nhật bản sao đọc danh mục hệ thống.
    events.publishEvent(new SystemApprovedEvent(current.systemCode()));

    ApplicationDto after = load(id);
    // Bí mật trả về đúng một lần ở đây; các lối đọc khác luôn `null`.
    return new ApplicationDto(
        after.id(),
        after.systemCode(),
        after.systemName(),
        after.ownerOrg(),
        after.status(),
        after.clientId(),
        sealed,
        after.legalBasis(),
        after.techProfile(),
        after.contactName(),
        after.contactEmail(),
        after.contactPhone(),
        after.submittedBy(),
        after.approvedBy(),
        after.statusReason(),
        after.legalReview(),
        after.techReview(),
        after.createdAt(),
        after.updatedAt());
  }

  @Override
  @Transactional
  public ApplicationDto reject(UUID id, String reason, String actor) {
    ApplicationDto current = load(id);
    requireDifferentActor(current.submittedBy(), actor, "từ chối");
    return transition(id, current, "REJECTED", actor, reason, "REJECT");
  }

  @Override
  @Transactional
  public ApplicationDto activate(UUID id, String actor) {
    return transition(id, load(id), "ACTIVE", actor, null, "ACTIVATE");
  }

  @Override
  @Transactional
  public ApplicationDto suspend(UUID id, String reason, String actor) {
    return transition(id, load(id), "SUSPENDED", actor, reason, "SUSPEND");
  }

  @Override
  @Transactional
  public ApplicationDto resume(UUID id, String actor) {
    ApplicationDto current = load(id);
    if (!"SUSPENDED".equals(current.status())) {
      throw new IllegalStateException("chỉ khôi phục hồ sơ đang tạm ngừng, hiện: " + current.status());
    }
    return transition(id, current, "ACTIVE", actor, null, "RESUME");
  }

  @Override
  @Transactional
  public ApplicationDto revoke(UUID id, String reason, String actor) {
    return transition(id, load(id), "REVOKED", actor, reason, "REVOKE");
  }

  /** Đổi trạng thái theo máy trạng thái; bước không hợp lệ bị chặn tại đây. */
  private ApplicationDto transition(
      UUID id, ApplicationDto current, String to, String actor, String reason, String action) {
    Set<String> allowed = ALLOWED.getOrDefault(current.status(), Set.of());
    if (!allowed.contains(to)) {
      throw new IllegalStateException(
          "không chuyển được từ %s sang %s".formatted(current.status(), to));
    }
    OffsetDateTime now = OffsetDateTime.now();
    jdbc.update(
        "UPDATE ph01.application SET status = ?, status_reason = ?, updated_at = ? WHERE id = ?",
        to,
        reason,
        now,
        id);
    audit(id, action, current.status(), to, actor, reason);
    return load(id);
  }

  /** Luật bốn mắt: người thực hiện phải khác người nộp hồ sơ (FR-01-006). */
  private static void requireDifferentActor(String submittedBy, String actor, String what) {
    if (submittedBy != null && submittedBy.equals(actor)) {
      throw new SelfReviewException(
          "người nộp hồ sơ không được tự %s hồ sơ của mình".formatted(what));
    }
  }

  private void audit(
      UUID applicationId, String action, String from, String to, String actor, String note) {
    jdbc.update(
        """
        INSERT INTO ph01.application_audit
          (id, application_id, action, from_status, to_status, actor, note, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        UUID.randomUUID(),
        applicationId,
        action,
        from,
        to,
        actor,
        note,
        OffsetDateTime.now());
  }

  private ApplicationDto load(UUID id) {
    return findById(id).orElseThrow(() -> new ApplicationNotFoundException(id));
  }

  private static String escape(String value) {
    return value == null ? "" : value.replace("\\", "\\\\").replace("\"", "\\\"");
  }

  @Override
  public Optional<ApplicationDto> findById(UUID id) {
    try {
      return Optional.of(
          jdbc.queryForObject(
              "SELECT %s FROM ph01.application WHERE id = ?".formatted(COLUMNS), MAPPER, id));
    } catch (EmptyResultDataAccessException e) {
      return Optional.empty();
    }
  }

  /** Vị từ lọc dùng chung cho danh sách và xuất tệp — giữ một chỗ để không lệch nhau. */
  private static String whereClause(String query, String status, List<Object> args) {
    StringBuilder where = new StringBuilder(" WHERE 1 = 1");
    if (query != null && !query.isBlank()) {
      where.append(
          " AND (LOWER(system_code) LIKE ? OR LOWER(system_name) LIKE ? OR LOWER(owner_org) LIKE ?)");
      String like = "%" + query.trim().toLowerCase() + "%";
      args.add(like);
      args.add(like);
      args.add(like);
    }
    if (status != null && !status.isBlank()) {
      where.append(" AND status = ?");
      args.add(status.trim().toUpperCase());
    }
    return where.toString();
  }

  @Override
  public PageDto<ApplicationDto> search(String query, String status, int page, int size) {
    int p = Math.max(page, 0);
    int s = Math.min(Math.max(size, 1), 100);

    List<Object> args = new ArrayList<>();
    String where = whereClause(query, status, args);

    Long total =
        jdbc.queryForObject(
            "SELECT COUNT(*) FROM ph01.application" + where, Long.class, args.toArray());

    List<Object> pageArgs = new ArrayList<>(args);
    pageArgs.add(s);
    pageArgs.add(p * s);
    List<ApplicationDto> items =
        jdbc.query(
            "SELECT %s FROM ph01.application%s ORDER BY created_at DESC LIMIT ? OFFSET ?"
                .formatted(COLUMNS, where),
            MAPPER,
            pageArgs.toArray());

    return new PageDto<>(items, p, s, total == null ? 0 : total);
  }

  @Override
  public List<ApplicationDto> exportAll(String query, String status) {
    List<Object> args = new ArrayList<>();
    String where = whereClause(query, status, args);
    // Trần 10 000 dòng: xuất báo cáo, không phải kênh trích xuất toàn bộ CSDL.
    return jdbc.query(
        "SELECT %s FROM ph01.application%s ORDER BY created_at DESC LIMIT 10000"
            .formatted(COLUMNS, where),
        MAPPER,
        args.toArray());
  }

  /* ---------- Rà soát quyền định kỳ (FR-01-013) ---------- */

  @Override
  @Transactional
  public ApplicationDto recordAccessReview(UUID id, AccessReviewRequest request, String actor) {
    ApplicationDto current = load(id);
    if (!Set.of("ACTIVE", "SUSPENDED").contains(current.status())) {
      throw new IllegalStateException(
          "chỉ rà soát quyền của thành viên đang hoạt động hoặc tạm ngừng, hiện: "
              + current.status());
    }
    OffsetDateTime now = OffsetDateTime.now();
    OffsetDateTime next = now.plusMonths(request.nextInMonthsOrDefault());
    jdbc.update(
        """
        UPDATE ph01.application
        SET last_access_review_at = ?, last_access_review_by = ?, next_access_review_at = ?, updated_at = ?
        WHERE id = ?
        """,
        now,
        actor,
        next,
        now,
        id);
    audit(id, "ACCESS_REVIEW", current.status(), current.status(), actor, request.note());
    return load(id);
  }

  @Override
  public List<ApplicationDto> dueForAccessReview() {
    // Chưa rà soát lần nào cũng coi là tới hạn — không để hồ sơ cũ trôi khỏi tầm ngắm.
    return jdbc.query(
        """
        SELECT %s FROM ph01.application
        WHERE status IN ('ACTIVE', 'SUSPENDED')
          AND (next_access_review_at IS NULL OR next_access_review_at <= now())
        ORDER BY next_access_review_at NULLS FIRST, created_at
        """
            .formatted(COLUMNS),
        MAPPER);
  }

  @Override
  public boolean isOnboardedSystem(String systemCode) {
    if (systemCode == null || systemCode.isBlank()) {
      return false;
    }
    // So khớp không phân biệt hoa thường: `source_system` của luồng do người dùng gõ tay,
    // còn `system_code` do quy trình kết nạp sinh — hai bên khác kiểu chữ là chuyện thường.
    Integer hit =
        jdbc.query(
            """
            SELECT 1 FROM ph01.application
            WHERE LOWER(system_code) = LOWER(?) AND status IN ('APPROVED', 'ACTIVE')
            LIMIT 1
            """,
            rs -> rs.next() ? 1 : null,
            systemCode);
    return hit != null;
  }

  /* ---------- Tệp đính kèm (FR-01-003) ---------- */

  @Override
  @Transactional
  public AttachmentDto attach(
      UUID id, String fileName, String contentType, byte[] content, String uploadedBy) {
    ApplicationDto app = load(id);
    // Hồ sơ đã chốt thì không nhận thêm tệp: hồ sơ đã duyệt phải bất biến để truy vết.
    if (!Set.of("SUBMITTED", "REVIEWED").contains(app.status())) {
      throw new IllegalStateException(
          "chỉ đính kèm khi hồ sơ chưa duyệt xong, hiện: " + app.status());
    }
    if (content == null || content.length == 0) {
      throw new IllegalArgumentException("tệp rỗng");
    }
    if (content.length > AttachmentStorage.MAX_BYTES) {
      throw new IllegalArgumentException(
          "tệp vượt %d MB".formatted(AttachmentStorage.MAX_BYTES / (1024 * 1024)));
    }
    if (contentType == null || !AttachmentStorage.ALLOWED_TYPES.contains(contentType)) {
      throw new IllegalArgumentException("định dạng không được phép: " + contentType);
    }

    UUID attachmentId = UUID.randomUUID();
    String safeName = sanitize(fileName);
    String objectKey = "onboarding/%s/%s-%s".formatted(id, attachmentId, safeName);
    storage.put(objectKey, content, contentType);

    OffsetDateTime now = OffsetDateTime.now();
    jdbc.update(
        """
        INSERT INTO ph01.application_attachment
          (id, application_id, file_name, content_type, size_bytes, object_key, sha256, uploaded_by, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        attachmentId,
        id,
        safeName,
        contentType,
        (long) content.length,
        objectKey,
        sha256(content),
        uploadedBy,
        now);
    audit(id, "ATTACH", app.status(), app.status(), uploadedBy, safeName);

    return new AttachmentDto(
        attachmentId, safeName, contentType, content.length, sha256(content), uploadedBy, now);
  }

  @Override
  public List<AttachmentDto> attachments(UUID id) {
    load(id);
    return jdbc.query(
        """
        SELECT id, file_name, content_type, size_bytes, sha256, uploaded_by, created_at
        FROM ph01.application_attachment WHERE application_id = ? ORDER BY created_at
        """,
        ATTACHMENT_MAPPER,
        id);
  }

  @Override
  public Optional<DownloadedFile> download(UUID applicationId, UUID attachmentId) {
    try {
      // Ràng cả `application_id`: không cho đoán id tệp của hồ sơ khác.
      Map<String, Object> row =
          jdbc.queryForMap(
              """
              SELECT file_name, content_type, object_key
              FROM ph01.application_attachment WHERE id = ? AND application_id = ?
              """,
              attachmentId,
              applicationId);
      byte[] content = storage.get((String) row.get("object_key"));
      return Optional.of(
          new DownloadedFile(
              (String) row.get("file_name"), (String) row.get("content_type"), content));
    } catch (EmptyResultDataAccessException e) {
      return Optional.empty();
    }
  }

  /** Bỏ đường dẫn và ký tự lạ khỏi tên tệp do người dùng đặt. */
  private static String sanitize(String fileName) {
    String base = fileName == null ? "tep" : fileName.replaceAll(".*[/\\\\]", "");
    String cleaned = base.replaceAll("[^\\p{L}\\p{N}._-]", "_");
    return cleaned.isBlank() ? "tep" : cleaned.substring(0, Math.min(cleaned.length(), 200));
  }

  private static String sha256(byte[] content) {
    try {
      byte[] digest = MessageDigest.getInstance("SHA-256").digest(content);
      StringBuilder sb = new StringBuilder(digest.length * 2);
      for (byte b : digest) sb.append("%02x".formatted(b));
      return sb.toString();
    } catch (NoSuchAlgorithmException e) {
      throw new IllegalStateException("JVM thiếu SHA-256", e);
    }
  }

  @Override
  public List<AuditEntryDto> auditTrail(UUID id) {
    // Xác nhận hồ sơ tồn tại: hồ sơ lạ phải là 404, không phải danh sách rỗng.
    load(id);
    return jdbc.query(
        """
        SELECT id, action, from_status, to_status, actor, note, created_at
        FROM ph01.application_audit WHERE application_id = ? ORDER BY created_at
        """,
        AUDIT_MAPPER,
        id);
  }

  @Override
  public String moduleStatus() {
    return "ok";
  }
}
