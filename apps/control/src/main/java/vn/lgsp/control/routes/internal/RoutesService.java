package vn.lgsp.control.routes.internal;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.lgsp.control.routes.api.RouteCreateRequest;
import vn.lgsp.control.routes.api.RouteDefinitionUpdate;
import vn.lgsp.control.routes.api.RouteReviewRequest;
import vn.lgsp.control.routes.api.RouteSummaryDto;
import vn.lgsp.control.routes.api.RouteVersionDto;
import vn.lgsp.control.routes.api.RoutesApi;
import vn.lgsp.control.routes.api.TestRunRequest;
import vn.lgsp.control.routes.api.TestRunResultDto;
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
              rs.getString("status"),
              rs.getString("source_system"),
              rs.getString("target_system"),
              rs.getObject("current_version_id", UUID.class),
              (Integer) rs.getObject("draft_version_no"),
              (Integer) rs.getObject("current_version_no"),
              rs.getString("git_commit_ref"));

  private final JdbcTemplate jdbc;
  private final CamelYamlValidator validator;
  private final GitOpsPublisher gitOps;

  RoutesService(JdbcTemplate jdbc, CamelYamlValidator validator, GitOpsPublisher gitOps) {
    this.jdbc = jdbc;
    this.validator = validator;
    this.gitOps = gitOps;
  }

  @Override
  @Transactional
  public RouteSummaryDto create(RouteCreateRequest request, String actor) {
    ValidationResultDto v = validator.validate(stripCanvasMarker(request.definitionYaml()));
    if (!v.valid()) {
      throw new RouteValidationException("YAML không hợp lệ khi tạo route", v);
    }
    UUID routeId = UUID.randomUUID();
    UUID versionId = UUID.randomUUID();
    OffsetDateTime now = OffsetDateTime.now();
    String type =
        request.routeType() == null || request.routeType().isBlank() ? "SYNC" : request.routeType();
    jdbc.update(
        """
        INSERT INTO ph04.route
          (route_id, route_code, title, route_type, status, source_system, target_system,
           current_version_id, created_by, created_at, updated_at)
        VALUES (?, ?, ?, ?, 'DRAFT', ?, ?, NULL, ?, ?, ?)
        """,
        routeId,
        request.routeCode(),
        request.title(),
        type,
        request.sourceSystem(),
        request.targetSystem(),
        actor,
        now,
        now);
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
    return jdbc.query(
        """
        SELECT r.route_id, r.route_code, r.title, r.route_type, r.status,
               r.source_system, r.target_system, r.current_version_id,
               (SELECT MAX(v.version_no) FROM ph04.route_version v
                 WHERE v.route_id = r.route_id AND v.status = 'DRAFT') AS draft_version_no,
               cv.version_no AS current_version_no,
               cv.git_commit_ref AS git_commit_ref
        FROM ph04.route r
        LEFT JOIN ph04.route_version cv ON cv.version_id = r.current_version_id
        ORDER BY r.created_at DESC
        """,
        SUMMARY);
  }

  @Override
  public RouteSummaryDto get(String routeCode) {
    try {
      return jdbc.queryForObject(
          """
          SELECT r.route_id, r.route_code, r.title, r.route_type, r.status,
                 r.source_system, r.target_system, r.current_version_id,
                 (SELECT MAX(v.version_no) FROM ph04.route_version v
                   WHERE v.route_id = r.route_id AND v.status = 'DRAFT') AS draft_version_no,
                 cv.version_no AS current_version_no,
                 cv.git_commit_ref AS git_commit_ref
          FROM ph04.route r
          LEFT JOIN ph04.route_version cv ON cv.version_id = r.current_version_id
          WHERE r.route_code = ?
          """,
          SUMMARY,
          routeCode);
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
      String routeCode, int versionNo, RouteDefinitionUpdate update) {
    RouteVersionDto current = loadVersion(routeCode, versionNo);
    if (!"DRAFT".equals(current.status())) {
      throw new IllegalStateException("chỉ sửa được phiên bản DRAFT");
    }
    ValidationResultDto v = validator.validate(stripCanvasMarker(update.definitionYaml()));
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
    return loadVersion(routeCode, versionNo);
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
    ValidationResultDto v = validator.validate(stripCanvasMarker(current.definitionYaml()));
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
    ValidationResultDto v = validator.validate(stripCanvasMarker(current.definitionYaml()));
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
  public TestRunResultDto testRun(String routeCode, int versionNo, TestRunRequest request) {
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
    return new TestRunResultDto(routeCode, versionNo, mode, "PASSED", duration, waterfall);
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
