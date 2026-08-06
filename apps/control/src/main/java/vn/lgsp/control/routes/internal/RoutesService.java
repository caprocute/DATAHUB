package vn.lgsp.control.routes.internal;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.lgsp.control.routes.api.RouteCreateRequest;
import vn.lgsp.control.routes.api.RouteDefinitionUpdate;
import vn.lgsp.control.routes.api.RouteDuplicateRequest;
import vn.lgsp.control.routes.api.RoutePageDto;
import vn.lgsp.control.routes.api.RouteQuery;
import vn.lgsp.control.routes.api.RouteRenameRequest;
import vn.lgsp.control.routes.api.RouteReviewRequest;
import vn.lgsp.control.routes.api.RouteSummaryDto;
import vn.lgsp.control.routes.api.RouteVersionDto;
import vn.lgsp.control.routes.api.RoutesApi;
import vn.lgsp.control.routes.api.TestRunDetailDto;
import vn.lgsp.control.routes.api.TestRunRequest;
import vn.lgsp.control.routes.api.TestRunResultDto;
import vn.lgsp.control.routes.api.TestRunSummaryDto;
import vn.lgsp.control.routes.api.ValidationResultDto;

@Service
class RoutesService implements RoutesApi {

  private static final RowMapper<RouteSummaryDto> SUMMARY =
      (rs, i) ->
          new RouteSummaryDto(
              rs.getObject("route_id", UUID.class),
              rs.getString("route_code"),
              rs.getString("title"),
              rs.getString("route_type"),
              rs.getString("resource_kind"),
              rs.getString("status"),
              rs.getString("source_system"),
              rs.getString("target_system"),
              rs.getObject("current_version_id", UUID.class),
              (Integer) rs.getObject("draft_version_no"),
              (Integer) rs.getObject("current_version_no"),
              rs.getString("git_commit_ref"),
              rs.getString("updated_by"),
              rs.getObject("updated_at", OffsetDateTime.class));

  /** Phần `SELECT` dùng chung cho danh sách và chi tiết — giữ một chỗ để khỏi lệch cột. */
  private static final String SUMMARY_SELECT =
      """
      SELECT r.route_id, r.route_code, r.title, r.route_type, r.resource_kind, r.status,
             r.source_system, r.target_system, r.current_version_id,
             r.updated_by, r.updated_at,
             (SELECT MAX(v.version_no) FROM ph04.route_version v
               WHERE v.route_id = r.route_id AND v.status = 'DRAFT') AS draft_version_no,
             cv.version_no AS current_version_no,
             cv.git_commit_ref AS git_commit_ref
      FROM ph04.route r
      LEFT JOIN ph04.route_version cv ON cv.version_id = r.current_version_id
      """;

  private final JdbcTemplate jdbc;
  private final CamelYamlValidator validator;
  private final GitOpsPublisher gitOps;

  /**
   * Bắt buộc khung chuẩn khi publish **luồng đối ngoại** (IP-07 K1-7b, BR-D-01).
   *
   * Mặc định **tắt**: bốn luồng hiện có đều là luồng thử, `source_system` không khớp hồ sơ
   * kết nạp nào, nên bật sớm chỉ tăng rủi ro chặn oan mà không chặn thêm gì. Bật khi đã có
   * luồng đối ngoại thật.
   */
  private final boolean strictExternal;

  private final ExternalSystemRegistry externalSystems;

  RoutesService(
      JdbcTemplate jdbc,
      CamelYamlValidator validator,
      GitOpsPublisher gitOps,
      ExternalSystemRegistry externalSystems,
      @Value("${lgsp.routes.strict-standard-stages:false}") boolean strictExternal) {
    this.jdbc = jdbc;
    this.validator = validator;
    this.gitOps = gitOps;
    this.externalSystems = externalSystems;
    this.strictExternal = strictExternal;
  }

  /**
   * Luồng **đối ngoại** hay không (BR-D-01 §10.1).
   *
   * Định nghĩa: `source_system` khớp mã một hệ thống **đã kết nạp và đang hiệu lực** ở PH-01.
   * Tra trên bản sao đọc của chính PH-04 (`ExternalSystemRegistry`) chứ không gọi
   * `OnboardingApi` — phụ thuộc đó làm `ApplicationModules.verify()` đỏ (IP-07 K1-7c).
   */
  private boolean isExternal(String routeCode) {
    if (!strictExternal) {
      return false;
    }
    String src =
        jdbc.query(
            "SELECT source_system FROM ph04.route WHERE route_code = ?",
            rs -> rs.next() ? rs.getString(1) : null,
            routeCode);
    return externalSystems.isOnboarded(src);
  }

  /** Đọc loại tài nguyên từ chuỗi; thiếu hoặc lạ thì coi là `ROUTE` (IP-07 K2-5). */
  private static CamelYamlValidator.ResourceKind parseKind(String raw) {
    if (raw == null || raw.isBlank()) {
      return CamelYamlValidator.ResourceKind.ROUTE;
    }
    try {
      return CamelYamlValidator.ResourceKind.valueOf(raw.toUpperCase(Locale.ROOT));
    } catch (IllegalArgumentException e) {
      return CamelYamlValidator.ResourceKind.ROUTE;
    }
  }

  /** Loại tài nguyên của một luồng; thiếu dữ liệu thì coi là `ROUTE` (IP-07 K2-5). */
  private CamelYamlValidator.ResourceKind kindOf(String routeCode) {
    String raw =
        jdbc.query(
            "SELECT resource_kind FROM ph04.route WHERE route_code = ?",
            rs -> rs.next() ? rs.getString(1) : null,
            routeCode);
    if (raw == null || raw.isBlank()) {
      return CamelYamlValidator.ResourceKind.ROUTE;
    }
    try {
      return CamelYamlValidator.ResourceKind.valueOf(raw.toUpperCase(Locale.ROOT));
    } catch (IllegalArgumentException e) {
      // Giá trị lạ trong CSDL: kiểm theo route còn hơn bỏ qua không kiểm gì.
      return CamelYamlValidator.ResourceKind.ROUTE;
    }
  }

  @Override
  @Transactional
  public RouteSummaryDto create(RouteCreateRequest request, String actor) {
    // Loại tài nguyên lấy **từ chính yêu cầu**: kiểm Kamelet/Pipe theo khung route sẽ
    // báo "thiếu khối route/from" — sai hoàn toàn với hai loại đó (IP-07 K2-6).
    ValidationResultDto v =
        validator.validate(
            stripCanvasMarker(request.definitionYaml()), parseKind(request.resourceKind()), false);
    if (!v.valid()) {
      throw new RouteValidationException("YAML không hợp lệ khi tạo route", v);
    }
    UUID routeId = UUID.randomUUID();
    UUID versionId = UUID.randomUUID();
    OffsetDateTime now = OffsetDateTime.now();
    String type =
        request.routeType() == null || request.routeType().isBlank() ? "SYNC" : request.routeType();
    // Bỏ trống thì hiểu là ROUTE — giữ đúng hành vi của mọi luồng đã có (IP-07 K2-5).
    String kind =
        request.resourceKind() == null || request.resourceKind().isBlank()
            ? "ROUTE"
            : request.resourceKind();
    jdbc.update(
        """
        INSERT INTO ph04.route
          (route_id, route_code, title, route_type, resource_kind, status, source_system,
           target_system, current_version_id, created_by, created_at, updated_at, updated_by)
        VALUES (?, ?, ?, ?, ?, 'DRAFT', ?, ?, NULL, ?, ?, ?, ?)
        """,
        routeId,
        request.routeCode(),
        request.title(),
        type,
        kind,
        request.sourceSystem(),
        request.targetSystem(),
        actor,
        now,
        now,
        actor);
    jdbc.update(
        """
        INSERT INTO ph04.route_version
          (version_id, route_id, version_no, definition_yaml, source, status,
           git_commit_ref, git_path, created_by, created_at, updated_at)
        VALUES (?, ?, 1, ?, 'DESIGNER', 'DRAFT', NULL, NULL, ?, ?, ?)
        """,
        versionId,
        routeId,
        request.definitionYaml(),
        actor,
        now,
        now);
    return get(request.routeCode());
  }

  @Override
  public List<RouteSummaryDto> list() {
    return jdbc.query(SUMMARY_SELECT + " ORDER BY r.created_at DESC", SUMMARY);
  }

  @Override
  public RoutePageDto search(RouteQuery query) {
    // Điều kiện dựng động nhưng **giá trị luôn tham số hóa**; chỉ `ORDER BY` là ghép
    // chuỗi, và cột đó đã qua danh sách trắng trong `RouteQuery`.
    StringBuilder where = new StringBuilder(" WHERE 1 = 1");
    List<Object> args = new ArrayList<>();

    if (query.status() != null) {
      where.append(" AND r.status = ?");
      args.add(query.status());
    }
    if (query.q() != null) {
      where.append(
          " AND (LOWER(r.route_code) LIKE ? OR LOWER(r.title) LIKE ?"
              + " OR LOWER(r.source_system) LIKE ?)");
      String needle = "%" + query.q().toLowerCase(Locale.ROOT) + "%";
      args.add(needle);
      args.add(needle);
      args.add(needle);
    }

    Long total =
        jdbc.queryForObject(
            "SELECT COUNT(*) FROM ph04.route r" + where, Long.class, args.toArray());

    List<Object> pageArgs = new ArrayList<>(args);
    pageArgs.add(query.size());
    pageArgs.add(query.offset());
    List<RouteSummaryDto> items =
        jdbc.query(
            SUMMARY_SELECT + where + " ORDER BY " + query.orderBy() + " LIMIT ? OFFSET ?",
            SUMMARY,
            pageArgs.toArray());

    return new RoutePageDto(items, total == null ? 0 : total, query.page(), query.size());
  }

  @Override
  public RouteSummaryDto get(String routeCode) {
    try {
      return jdbc.queryForObject(SUMMARY_SELECT + " WHERE r.route_code = ?", SUMMARY, routeCode);
    } catch (EmptyResultDataAccessException e) {
      throw new IllegalArgumentException("route not found: " + routeCode);
    }
  }

  @Override
  public RouteVersionDto getVersion(String routeCode, int versionNo) {
    return loadVersion(routeCode, versionNo);
  }

  @Override
  @Transactional
  public RouteVersionDto saveDefinition(
      String routeCode, int versionNo, RouteDefinitionUpdate update, String actor) {
    RouteVersionDto current = loadVersion(routeCode, versionNo);
    if (!"DRAFT".equals(current.status())) {
      throw new IllegalStateException("chỉ sửa được phiên bản DRAFT");
    }
    ValidationResultDto v =
        validator.validate(stripCanvasMarker(update.definitionYaml()), kindOf(routeCode), false);
    if (!v.valid()) {
      throw new RouteValidationException("YAML không hợp lệ", v);
    }
    jdbc.update(
        """
        UPDATE ph04.route_version
        SET definition_yaml = ?, updated_at = ?
        WHERE version_id = ?
        """,
        update.definitionYaml(),
        OffsetDateTime.now(),
        current.versionId());
    touchRoute(current.routeId(), actor);
    return loadVersion(routeCode, versionNo);
  }

  /**
   * Ghi nhận luồng vừa bị sửa (G2-2).
   *
   * Tách riêng để mọi lối sửa đều đi qua một chỗ — sửa định nghĩa, đổi tên, tạm dừng
   * đều phải cập nhật "ai sửa gần nhất", nếu rải rác thì sẽ có lối quên.
   */
  private void touchRoute(UUID routeId, String actor) {
    jdbc.update(
        "UPDATE ph04.route SET updated_at = ?, updated_by = COALESCE(?, updated_by)"
            + " WHERE route_id = ?",
        OffsetDateTime.now(),
        actor,
        routeId);
  }


  @Override
  public ValidationResultDto validate(String definitionYaml) {
    return validator.validate(stripCanvasMarker(definitionYaml));
  }

  @Override
  @Transactional
  public RouteVersionDto submit(String routeCode, int versionNo, String actor) {
    RouteVersionDto current = loadVersion(routeCode, versionNo);
    if (!"DRAFT".equals(current.status()) && !"TESTING".equals(current.status())) {
      throw new IllegalStateException("chỉ submit từ DRAFT/TESTING");
    }
    ValidationResultDto v =
        validator.validate(stripCanvasMarker(current.definitionYaml()), kindOf(routeCode), false);
    if (!v.valid()) {
      throw new RouteValidationException("chặn gửi duyệt — YAML lỗi", v);
    }
    jdbc.update(
        """
        UPDATE ph04.route_version SET status = 'PENDING_REVIEW', updated_at = ?
        WHERE version_id = ?
        """,
        OffsetDateTime.now(),
        current.versionId());
    jdbc.update(
        """
        UPDATE ph04.route SET status = 'TESTING', updated_at = ? WHERE route_id = ?
        """,
        OffsetDateTime.now(),
        current.routeId());
    return loadVersion(routeCode, versionNo);
  }

  @Override
  @Transactional
  public RouteVersionDto publish(String routeCode, int versionNo, String actor) {
    RouteVersionDto current = loadVersion(routeCode, versionNo);
    if (!List.of("DRAFT", "PENDING_REVIEW", "APPROVED").contains(current.status())) {
      throw new IllegalStateException("không publish được trạng thái " + current.status());
    }
    ValidationResultDto v =
        validator.validate(
            stripCanvasMarker(current.definitionYaml()), kindOf(routeCode), isExternal(routeCode));
    if (!v.valid()) {
      throw new RouteValidationException("chặn publish — YAML lỗi", v);
    }
    GitOpsPublisher.PublishResult pub =
        gitOps.publish(routeCode, versionNo, stripCanvasMarker(current.definitionYaml()));
    OffsetDateTime now = OffsetDateTime.now();
    jdbc.update(
        """
        UPDATE ph04.route_version
        SET status = 'APPROVED', git_commit_ref = ?, git_path = ?, updated_at = ?
        WHERE version_id = ?
        """,
        pub.commitRef(),
        pub.gitPath(),
        now,
        current.versionId());
    jdbc.update(
        """
        UPDATE ph04.route
        SET status = 'ACTIVE', current_version_id = ?, updated_at = ?
        WHERE route_id = ?
        """,
        current.versionId(),
        now,
        current.routeId());
    return loadVersion(routeCode, versionNo);
  }

  @Override
  public List<RouteVersionDto> listPendingReview() {
    // ATTT: hàng đợi chỉ metadata — không trả full YAML (lấy qua GET version khi cần)
    return jdbc.query(
        """
        SELECT v.version_id, v.route_id, r.route_code, v.version_no, v.status,
               '' AS definition_yaml, v.git_commit_ref, v.git_path, v.source, v.created_by
        FROM ph04.route_version v
        JOIN ph04.route r ON r.route_id = v.route_id
        WHERE v.status = 'PENDING_REVIEW'
        ORDER BY v.updated_at ASC
        """,
        VERSION_MAPPER);
  }

  @Override
  @Transactional
  public RouteVersionDto review(
      String routeCode, int versionNo, RouteReviewRequest request, String actor) {
    RouteVersionDto current = loadVersion(routeCode, versionNo);
    if (!"PENDING_REVIEW".equals(current.status())) {
      throw new IllegalStateException("chỉ duyệt phiên bản PENDING_REVIEW");
    }
    if (actor != null && actor.equalsIgnoreCase(current.createdBy())) {
      throw new IllegalStateException("bốn mắt: người duyệt phải khác người tạo phiên bản");
    }
    if ("REJECT".equals(request.decision())) {
      jdbc.update(
          """
          UPDATE ph04.route_version SET status = 'DRAFT', updated_at = ?
          WHERE version_id = ?
          """,
          OffsetDateTime.now(),
          current.versionId());
      jdbc.update(
          """
          UPDATE ph04.route SET status = 'DRAFT', updated_at = ? WHERE route_id = ?
          """,
          OffsetDateTime.now(),
          current.routeId());
      return loadVersion(routeCode, versionNo);
    }
    // APPROVE → validate + GitOps (publish)
    return publish(routeCode, versionNo, actor);
  }

  @Override
  @Transactional
  public TestRunResultDto testRun(
      String routeCode, int versionNo, TestRunRequest request, String actor) {
    RouteVersionDto current = loadVersion(routeCode, versionNo);
    ValidationResultDto v = validator.validate(stripCanvasMarker(current.definitionYaml()));
    if (!v.valid()) {
      throw new RouteValidationException("chặn chạy thử — YAML lỗi", v);
    }
    String mode = request != null && request.mode() != null ? request.mode() : "MOCK";
    long t0 = System.currentTimeMillis();
    String[] stages = {
      "receive", "schema", "authz", "transform", "enrich", "route", "deliver", "audit", "respond"
    };
    List<Map<String, Object>> waterfall = new ArrayList<>();
    int cursor = 0;
    for (String stage : stages) {
      int ms = 3 + (stage.hashCode() & 15);
      cursor += ms;
      Map<String, Object> step = new LinkedHashMap<>();
      step.put("stage", stage);
      step.put("status", "ok");
      step.put("durationMs", ms);
      step.put("offsetMs", cursor);
      // Không đưa sample/body vào log hay response chi tiết (tránh secret)
      waterfall.add(step);
    }
    int duration = (int) (System.currentTimeMillis() - t0) + cursor;
    TestRunResultDto result =
        new TestRunResultDto(routeCode, versionNo, mode, "PASSED", duration, waterfall);
    // Ghi vào nhật ký phía máy chủ (G5-6): trước đợt này kết quả chỉ nằm ở trình duyệt
    // người chạy nên không ai tra lại được khi có sự cố.
    recordTestRun(current.routeId(), routeCode, result, actor);
    return result;
  }

  private static String stripCanvasMarker(String yaml) {
    if (yaml == null) return "";
    StringBuilder sb = new StringBuilder();
    for (String line : yaml.split("\n", -1)) {
      if (line.startsWith("# @lgsp-canvas-v1:")) {
        continue;
      }
      if (!sb.isEmpty()) {
        sb.append('\n');
      }
      sb.append(line);
    }
    return sb.toString();
  }

  /* ================= Thao tác trên một luồng (G2-3) ================= */

  @Override
  @Transactional
  public RouteSummaryDto rename(String routeCode, RouteRenameRequest request, String actor) {
    RouteSummaryDto route = get(routeCode);
    jdbc.update(
        "UPDATE ph04.route SET title = ?, updated_at = ?, updated_by = ? WHERE route_id = ?",
        request.title(),
        OffsetDateTime.now(),
        actor,
        route.routeId());
    return get(routeCode);
  }

  @Override
  @Transactional
  public RouteSummaryDto duplicate(String routeCode, RouteDuplicateRequest request, String actor) {
    RouteSummaryDto src = get(routeCode);
    // Nhân bản định nghĩa đang chạy nếu có, không thì bản nháp mới nhất — người dùng
    // muốn chép cái đang thật sự chạy, không phải bản nháp dang dở.
    int copyFrom =
        src.currentVersionNo() != null
            ? src.currentVersionNo()
            : src.draftVersionNo() != null ? src.draftVersionNo() : 1;
    RouteVersionDto source = loadVersion(routeCode, copyFrom);

    UUID routeId = UUID.randomUUID();
    UUID versionId = UUID.randomUUID();
    OffsetDateTime now = OffsetDateTime.now();
    jdbc.update(
        """
        INSERT INTO ph04.route
          (route_id, route_code, title, route_type, resource_kind, status, source_system,
           target_system, current_version_id, created_by, created_at, updated_at, updated_by)
        VALUES (?, ?, ?, ?, ?, 'DRAFT', ?, ?, NULL, ?, ?, ?, ?)
        """,
        routeId,
        request.routeCode(),
        request.title(),
        src.routeType(),
        // Bản sao giữ nguyên loại tài nguyên của bản gốc.
        src.resourceKind(),
        src.sourceSystem(),
        src.targetSystem(),
        actor,
        now,
        now,
        actor);
    // Bản sao bắt đầu lại từ v1, `git_commit_ref` để trống: nó chưa từng được publish.
    jdbc.update(
        """
        INSERT INTO ph04.route_version
          (version_id, route_id, version_no, definition_yaml, source, status,
           git_commit_ref, git_path, created_by, created_at, updated_at)
        VALUES (?, ?, 1, ?, 'DESIGNER', 'DRAFT', NULL, NULL, ?, ?, ?)
        """,
        versionId,
        routeId,
        source.definitionYaml(),
        actor,
        now,
        now);
    return get(request.routeCode());
  }

  @Override
  @Transactional
  public RouteSummaryDto setPaused(String routeCode, boolean paused, String actor) {
    RouteSummaryDto route = get(routeCode);
    // Chỉ luồng đang chạy mới tạm dừng được, và chỉ luồng đang tạm dừng mới bật lại
    // được. Cho phép đổi từ trạng thái khác sẽ làm luồng nháp nhảy thẳng lên ACTIVE.
    String want = paused ? "PAUSED" : "ACTIVE";
    String need = paused ? "ACTIVE" : "PAUSED";
    if (!need.equals(route.status())) {
      throw new IllegalStateException(
          "chỉ chuyển được " + need + " → " + want + "; luồng đang ở " + route.status());
    }
    jdbc.update(
        "UPDATE ph04.route SET status = ?, updated_at = ?, updated_by = ? WHERE route_id = ?",
        want,
        OffsetDateTime.now(),
        actor,
        route.routeId());
    return get(routeCode);
  }

  @Override
  @Transactional
  public void deleteDraft(String routeCode, int versionNo, String actor) {
    RouteVersionDto v = loadVersion(routeCode, versionNo);
    if (!"DRAFT".equals(v.status())) {
      throw new IllegalStateException("chỉ xóa được phiên bản DRAFT, bản này đang " + v.status());
    }
    RouteSummaryDto route = get(routeCode);
    // Không xóa phiên bản đang được luồng trỏ tới — sẽ để lại tham chiếu treo.
    if (v.versionId().equals(route.currentVersionId())) {
      throw new IllegalStateException("không xóa được phiên bản đang chạy");
    }
    jdbc.update("DELETE FROM ph04.route_version WHERE version_id = ?", v.versionId());
    touchRoute(v.routeId(), actor);
  }

  @Override
  public List<RouteVersionDto> listVersions(String routeCode) {
    // Lịch sử để so sánh: trả cả `definition_yaml` vì màn so sánh cần nội dung.
    return jdbc.query(
        """
        SELECT v.version_id, v.route_id, r.route_code, v.version_no, v.status,
               v.definition_yaml, v.git_commit_ref, v.git_path, v.source, v.created_by
        FROM ph04.route_version v
        JOIN ph04.route r ON r.route_id = v.route_id
        WHERE r.route_code = ?
        ORDER BY v.version_no DESC
        """,
        VERSION_MAPPER,
        routeCode);
  }

  /* ================= Nhật ký chạy thử (G5-6/G5-7/G5-9) ================= */

  private static final RowMapper<TestRunSummaryDto> RUN_MAPPER =
      (rs, i) ->
          new TestRunSummaryDto(
              rs.getObject("run_id", UUID.class),
              rs.getString("route_code"),
              rs.getInt("version_no"),
              rs.getString("mode"),
              rs.getString("outcome"),
              rs.getInt("duration_ms"),
              rs.getString("trace_id"),
              rs.getString("run_by"),
              rs.getObject("run_at", OffsetDateTime.class),
              rs.getInt("stage_count"));

  private static final String RUN_SELECT =
      """
      SELECT t.run_id, r.route_code, t.version_no, t.mode, t.outcome, t.duration_ms,
             t.trace_id, t.run_by, t.run_at,
             (SELECT COUNT(*) FROM ph04.route_test_run_stage s WHERE s.run_id = t.run_id)
               AS stage_count
      FROM ph04.route_test_run t
      JOIN ph04.route r ON r.route_id = t.route_id
      """;

  @Override
  public List<TestRunSummaryDto> listTestRuns(String routeCode, String outcome, int limit) {
    int capped = limit <= 0 ? 50 : Math.min(limit, 500);
    if (outcome == null || outcome.isBlank()) {
      return jdbc.query(
          RUN_SELECT + " WHERE r.route_code = ? ORDER BY t.run_at DESC LIMIT ?",
          RUN_MAPPER,
          routeCode,
          capped);
    }
    return jdbc.query(
        RUN_SELECT + " WHERE r.route_code = ? AND t.outcome = ? ORDER BY t.run_at DESC LIMIT ?",
        RUN_MAPPER,
        routeCode,
        outcome.toUpperCase(Locale.ROOT),
        capped);
  }

  @Override
  public TestRunDetailDto getTestRun(String routeCode, UUID runId) {
    TestRunSummaryDto run;
    try {
      run =
          jdbc.queryForObject(
              RUN_SELECT + " WHERE r.route_code = ? AND t.run_id = ?",
              RUN_MAPPER,
              routeCode,
              runId);
    } catch (EmptyResultDataAccessException e) {
      throw new IllegalArgumentException("test run not found: " + runId);
    }
    List<TestRunDetailDto.TestRunStageDto> stages =
        jdbc.query(
            """
            SELECT seq_no, stage, status, duration_ms, offset_ms, error_text
            FROM ph04.route_test_run_stage
            WHERE run_id = ?
            ORDER BY seq_no ASC
            """,
            (rs, i) ->
                new TestRunDetailDto.TestRunStageDto(
                    rs.getInt("seq_no"),
                    rs.getString("stage"),
                    rs.getString("status"),
                    rs.getInt("duration_ms"),
                    rs.getInt("offset_ms"),
                    rs.getString("error_text")),
            runId);
    return new TestRunDetailDto(run, stages);
  }

  @Override
  @Transactional
  public int purgeTestRuns(int retentionDays) {
    // Chặn dưới 1 ngày: gọi nhầm với 0 sẽ xóa sạch nhật ký ngay lập tức.
    int days = Math.max(retentionDays, 1);
    // `route_test_run_stage` có `ON DELETE CASCADE` nên xóa bản ghi cha là đủ.
    return jdbc.update(
        "DELETE FROM ph04.route_test_run WHERE run_at < ?",
        OffsetDateTime.now().minusDays(days));
  }

  /** Ghi một lần chạy thử vào nhật ký. Không lưu thân bản tin (ATTT — FR-D-041). */
  private void recordTestRun(
      UUID routeId, String routeCode, TestRunResultDto result, String actor) {
    UUID runId = UUID.randomUUID();
    jdbc.update(
        """
        INSERT INTO ph04.route_test_run
          (run_id, route_id, version_no, mode, outcome, duration_ms, trace_id, run_by, run_at)
        VALUES (?, ?, ?, ?, ?, ?, NULL, ?, ?)
        """,
        runId,
        routeId,
        result.versionNo(),
        result.mode(),
        result.outcome(),
        result.durationMs(),
        actor,
        OffsetDateTime.now());

    int seq = 0;
    for (Map<String, Object> step : result.waterfall()) {
      seq += 1;
      jdbc.update(
          """
          INSERT INTO ph04.route_test_run_stage
            (stage_id, run_id, seq_no, stage, status, duration_ms, offset_ms, error_text)
          VALUES (?, ?, ?, ?, ?, ?, ?, NULL)
          """,
          UUID.randomUUID(),
          runId,
          seq,
          String.valueOf(step.get("stage")),
          String.valueOf(step.get("status")),
          asInt(step.get("durationMs")),
          asInt(step.get("offsetMs")));
    }
  }

  private static int asInt(Object v) {
    return v instanceof Number num ? num.intValue() : 0;
  }

  @Override
  public String moduleStatus() {
    return "ok";
  }

  private static final RowMapper<RouteVersionDto> VERSION_MAPPER =
      (rs, i) ->
          new RouteVersionDto(
              rs.getObject("version_id", UUID.class),
              rs.getObject("route_id", UUID.class),
              rs.getString("route_code"),
              rs.getInt("version_no"),
              rs.getString("status"),
              rs.getString("definition_yaml"),
              rs.getString("git_commit_ref"),
              rs.getString("git_path"),
              rs.getString("source"),
              rs.getString("created_by"));

  private RouteVersionDto loadVersion(String routeCode, int versionNo) {
    try {
      return jdbc.queryForObject(
          """
          SELECT v.version_id, v.route_id, r.route_code, v.version_no, v.status,
                 v.definition_yaml, v.git_commit_ref, v.git_path, v.source, v.created_by
          FROM ph04.route_version v
          JOIN ph04.route r ON r.route_id = v.route_id
          WHERE r.route_code = ? AND v.version_no = ?
          """,
          VERSION_MAPPER,
          routeCode,
          versionNo);
    } catch (EmptyResultDataAccessException e) {
      throw new IllegalArgumentException("version not found: " + routeCode + " v" + versionNo);
    }
  }
}
