package vn.datahub.data.rdm.internal;

import java.time.Clock;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;
import org.jspecify.annotations.Nullable;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import tools.jackson.databind.json.JsonMapper;
import vn.datahub.data.rdm.api.CatalogGroupQueries;
import vn.datahub.data.rdm.api.CatalogGroupView;
import vn.datahub.data.shared.audit.AuditEvent;
import vn.datahub.data.shared.audit.AuditRecorder;
import vn.datahub.data.shared.persistence.IdempotencyStore;
import vn.datahub.data.shared.security.CurrentUser;
import vn.datahub.data.shared.security.CurrentUserProvider;
import vn.datahub.data.shared.security.TenantContext;
import vn.datahub.data.shared.web.ApiError;
import vn.datahub.data.shared.web.DatahubException;
import vn.datahub.data.shared.web.FieldError;

/**
 * Nghiệp vụ nhóm danh mục (FR-07-010): cây theo SS-07-10, xóa hẳn theo SS-07-05, kiểm toán theo
 * SS-07-08. Mỗi phương thức public là một giao dịch; tenant được đặt ở đầu giao dịch bởi
 * {@code TenantJpaTransactionManager}, RLS lọc theo tenant (CC-TX-01/02).
 */
@Service
public class CatalogGroupService implements CatalogGroupQueries {

  static final String OP_CREATE = "API-07-008";
  private static final String AGGREGATE = "catalog_group";
  private static final Comparator<CatalogGroup> ORDER =
      Comparator.comparingInt(CatalogGroup::getSortOrder).thenComparing(CatalogGroup::getCode);

  /** Kết quả tạo: {@code replayed} là true khi trả lại phản hồi đã lưu của Idempotency-Key. */
  public record CreateResult(CatalogGroupView view, boolean replayed) {}

  private final CatalogGroupRepository repository;
  private final JdbcClient jdbc;
  private final AuditRecorder audit;
  private final IdempotencyStore idempotency;
  private final CurrentUserProvider users;
  private final Clock clock;
  private final JsonMapper mapper;

  CatalogGroupService(
      CatalogGroupRepository repository,
      JdbcClient jdbc,
      AuditRecorder audit,
      IdempotencyStore idempotency,
      CurrentUserProvider users,
      Clock clock,
      JsonMapper mapper) {
    this.repository = repository;
    this.jdbc = jdbc;
    this.audit = audit;
    this.idempotency = idempotency;
    this.users = users;
    this.clock = clock;
    this.mapper = mapper;
  }

  // ---------------------------------------------------------------- đọc

  @Override
  @Transactional(readOnly = true)
  public List<CatalogGroupView> tree() {
    List<CatalogGroup> groups = repository.findByTenantIdIn(TenantContext.visibleTenants());
    Map<UUID, Integer> counts = catalogCounts();
    Map<UUID, List<CatalogGroup>> byParent = new HashMap<>();
    List<CatalogGroup> roots = new ArrayList<>();
    Map<UUID, CatalogGroup> byId = groups.stream().collect(Collectors.toMap(CatalogGroup::getId, g -> g));
    for (CatalogGroup g : groups) {
      UUID parent = g.getParentId();
      if (parent == null || !byId.containsKey(parent)) {
        roots.add(g);
      } else {
        byParent.computeIfAbsent(parent, k -> new ArrayList<>()).add(g);
      }
    }
    roots.sort(ORDER);
    return roots.stream().map(g -> build(g, byParent, counts)).toList();
  }

  @Override
  @Transactional(readOnly = true)
  public List<CatalogGroupView> flat() {
    Map<UUID, Integer> counts = catalogCounts();
    return repository.findByTenantIdIn(TenantContext.visibleTenants()).stream()
        .sorted(ORDER)
        .map(g -> toView(g, counts.getOrDefault(g.getId(), 0), List.of()))
        .toList();
  }

  private CatalogGroupView build(
      CatalogGroup group, Map<UUID, List<CatalogGroup>> byParent, Map<UUID, Integer> counts) {
    List<CatalogGroup> kids = new ArrayList<>(byParent.getOrDefault(group.getId(), List.of()));
    kids.sort(ORDER);
    return toView(
        group,
        counts.getOrDefault(group.getId(), 0),
        kids.stream().map(k -> build(k, byParent, counts)).toList());
  }

  /** Số danh mục chưa xóa mềm theo nhóm (RLS lọc theo tenant), không cộng nhóm con. */
  private Map<UUID, Integer> catalogCounts() {
    Map<UUID, Integer> counts = new HashMap<>();
    jdbc.sql(
            "select group_id, count(*) as n from ph07_rdm.catalog"
                + " where deleted_at is null and group_id is not null group by group_id")
        .query((rs, i) -> counts.put(rs.getObject("group_id", UUID.class), rs.getInt("n")))
        .list();
    return counts;
  }

  // ---------------------------------------------------------------- tạo

  @Transactional
  public CreateResult create(CreateGroupCommand cmd, @Nullable String idempotencyKey) {
    CurrentUser user = users.require();
    String principal = user.id().toString();
    if (idempotencyKey != null) {
      String hash = IdempotencyStore.sha256(mapper.writeValueAsString(cmd));
      switch (idempotency.begin(user.tenant(), principal, OP_CREATE, idempotencyKey, hash)) {
        case IdempotencyStore.Replay replay -> {
          return new CreateResult(mapper.readValue(replay.responseBody(), CatalogGroupView.class), true);
        }
        case IdempotencyStore.Mismatch ignored ->
            throw new DatahubException(
                ApiError.IDEMPOTENCY_CONFLICT,
                "Idempotency-Key này đã được dùng với nội dung khác. Tải lại trang rồi thực hiện lại.");
        case IdempotencyStore.Fresh ignored -> {
          // tiếp tục tạo
        }
      }
    }

    String owner = TenantContext.dataTenant();
    GroupTree tree = loadTree(owner);
    UUID parentId = cmd.parentId();
    if (parentId != null) {
      requireOwnParent(parentId, owner);
    }
    if (repository.existsByTenantIdAndCode(owner, cmd.code())) {
      throw uniqueConflict(cmd.code());
    }
    if (tree.checkCreate(parentId) == GroupTree.Violation.DEPTH) {
      throw depthConflict();
    }

    CatalogGroup group =
        new CatalogGroup(
            owner,
            cmd.code(),
            cmd.name(),
            parentId,
            cmd.sortOrder(),
            cmd.description(),
            user.id(),
            clock.instant());
    try {
      repository.saveAndFlush(group);
    } catch (DataIntegrityViolationException e) {
      if (mentionsConstraint(e, "uq_catalog_group_code")) {
        throw uniqueConflict(cmd.code());
      }
      throw e;
    }
    audit.record(
        new AuditEvent("RDM_GROUP_CREATE", AGGREGATE, group.getId().toString(), null, snapshot(group)));

    CatalogGroupView view = toView(group, 0, List.of());
    if (idempotencyKey != null) {
      idempotency.complete(
          user.tenant(),
          principal,
          OP_CREATE,
          idempotencyKey,
          201,
          mapper.writeValueAsString(view),
          Optional.of(group.getId()));
    }
    return new CreateResult(view, false);
  }

  // ---------------------------------------------------------------- sửa

  @Transactional
  public CatalogGroupView update(UUID id, int expectedVersion, UpdateGroupCommand cmd) {
    CurrentUser user = users.require();
    CatalogGroup group = loadWritable(id, expectedVersion);
    String owner = group.getTenantId();

    String newName = cmd.hasName() && cmd.name() != null ? cmd.name() : group.getName();
    UUID newParent = cmd.hasParentId() ? cmd.parentId() : group.getParentId();
    int newSort = cmd.hasSortOrder() ? cmd.sortOrder() : group.getSortOrder();
    String newDescription = cmd.hasDescription() ? cmd.description() : group.getDescription();

    boolean parentChanged = !java.util.Objects.equals(newParent, group.getParentId());
    if (parentChanged && newParent != null) {
      requireOwnParent(newParent, owner);
      GroupTree.Violation violation = loadTree(owner).checkMove(id, newParent);
      if (violation == GroupTree.Violation.CYCLE) {
        throw new DatahubException(
            Ph07Error.GROUP_CONFLICT,
            "Nhóm cha được chọn là chính nhóm này hoặc nhóm con của nó nên tạo thành vòng lặp.",
            List.of(new FieldError("parentId", "CYCLE", "Nhóm cha tạo thành vòng lặp.")));
      }
      if (violation == GroupTree.Violation.DEPTH) {
        throw depthConflict();
      }
    }

    Map<String, Object> before = new LinkedHashMap<>();
    Map<String, Object> after = new LinkedHashMap<>();
    diff("name", group.getName(), newName, before, after);
    diff("parentId", asText(group.getParentId()), asText(newParent), before, after);
    diff("sortOrder", group.getSortOrder(), newSort, before, after);
    diff("description", group.getDescription(), newDescription, before, after);
    if (after.isEmpty()) {
      return toView(group, countOf(id), List.of());
    }

    group.apply(newName, newParent, newSort, newDescription, user.id(), clock.instant());
    repository.saveAndFlush(group);
    audit.record(new AuditEvent("RDM_GROUP_UPDATE", AGGREGATE, id.toString(), before, after));
    return toView(group, countOf(id), List.of());
  }

  // ---------------------------------------------------------------- xóa

  @Transactional
  public void delete(UUID id, int expectedVersion) {
    CatalogGroup group = loadWritable(id, expectedVersion);
    long children = repository.countByParentId(id);
    int[] counts =
        jdbc.sql(
                "select count(*) filter (where deleted_at is null) as live, count(*) as total"
                    + " from ph07_rdm.catalog where group_id = :id")
            .param("id", id)
            .query((rs, i) -> new int[] {rs.getInt("live"), rs.getInt("total")})
            .single();
    int live = counts[0];
    int softDeleted = counts[1] - counts[0];
    if (children > 0 || live > 0 || softDeleted > 0) {
      throw notEmpty(group.getName(), live, softDeleted, children);
    }
    Map<String, Object> before = snapshot(group);
    try {
      repository.delete(group);
      repository.flush();
    } catch (DataIntegrityViolationException e) {
      // Danh mục của tenant khác tham chiếu nhóm COMMON mà RLS che khỏi PLATFORM.
      throw notEmpty(group.getName(), 0, 0, 0);
    }
    audit.record(new AuditEvent("RDM_GROUP_DELETE", AGGREGATE, id.toString(), before, null));
  }

  // ---------------------------------------------------------------- trợ giúp

  /** Tìm nhóm ghi được: 404 nếu không thấy, 403 nếu COMMON với tenant tỉnh, 412 nếu ETag lệch. */
  private CatalogGroup loadWritable(UUID id, int expectedVersion) {
    CatalogGroup group =
        repository
            .findByIdAndTenantIdIn(id, TenantContext.visibleTenants())
            .orElseThrow(
                () ->
                    new DatahubException(
                        Ph07Error.GROUP_NOT_FOUND, "Không tìm thấy nhóm danh mục đã chọn."));
    if (!group.getTenantId().equals(TenantContext.dataTenant())) {
      throw new DatahubException(
          Ph07Error.COMMON_READ_ONLY,
          "Nhóm danh mục dùng chung chỉ quản trị nền tảng được sửa hoặc xóa.");
    }
    if (group.getVersion() != expectedVersion) {
      throw new DatahubException(
          ApiError.PRECONDITION_FAILED,
          "Dữ liệu đã được người khác cập nhật trong lúc bạn đang sửa. Hãy tải lại rồi thực hiện lại.");
    }
    return group;
  }

  /** Nhóm cha phải thấy được (422 nếu không) và cùng tenant với nhóm con (403 nếu là COMMON). */
  private void requireOwnParent(UUID parentId, String owner) {
    CatalogGroup parent =
        repository
            .findByIdAndTenantIdIn(parentId, TenantContext.visibleTenants())
            .orElseThrow(
                () ->
                    new DatahubException(
                        ApiError.VALIDATION,
                        "Nhóm cha không tồn tại.",
                        List.of(
                            new FieldError(
                                "parentId", "PARENT_NOT_FOUND", "Nhóm cha không tồn tại."))));
    if (!parent.getTenantId().equals(owner)) {
      throw new DatahubException(
          Ph07Error.COMMON_READ_ONLY,
          "Nhóm danh mục dùng chung chỉ đọc với tỉnh của bạn nên không thể đặt làm nhóm cha.");
    }
  }

  private GroupTree loadTree(String owner) {
    Map<UUID, UUID> parents = new HashMap<>();
    for (CatalogGroup g : repository.findByTenantIdIn(List.of(owner))) {
      parents.put(g.getId(), g.getParentId());
    }
    return new GroupTree(parents);
  }

  private int countOf(UUID groupId) {
    return jdbc.sql(
            "select count(*) from ph07_rdm.catalog where group_id = :id and deleted_at is null")
        .param("id", groupId)
        .query(Integer.class)
        .single();
  }

  private static DatahubException uniqueConflict(String code) {
    return new DatahubException(
        Ph07Error.GROUP_CONFLICT,
        "Mã nhóm \"" + code + "\" đã được dùng trong tenant hiện tại.",
        List.of(new FieldError("code", "UNIQUE", "Mã nhóm đã được dùng.")));
  }

  private static DatahubException depthConflict() {
    return new DatahubException(
        Ph07Error.GROUP_CONFLICT,
        "Cây nhóm tối đa " + GroupTree.MAX_DEPTH + " cấp; nhóm cha được chọn làm vượt độ sâu.",
        List.of(new FieldError("parentId", "DEPTH", "Vượt độ sâu tối đa 5 cấp.")));
  }

  private static DatahubException notEmpty(String name, int live, int softDeleted, long children) {
    List<String> parts = new ArrayList<>();
    if (live > 0) {
      parts.add(live + " danh mục");
    }
    if (softDeleted > 0) {
      parts.add(softDeleted + " danh mục đã xóa mềm còn tham chiếu");
    }
    if (children > 0) {
      parts.add(children + " nhóm con");
    }
    String what = parts.isEmpty() ? "danh mục tham chiếu" : String.join(" và ", parts);
    return new DatahubException(
            Ph07Error.GROUP_NOT_EMPTY,
            "Nhóm \"" + name + "\" còn " + what + " nên không xóa được. Hãy chuyển chúng sang nhóm khác trước.")
        .with("catalogCount", live)
        .with("childCount", children);
  }

  private static boolean mentionsConstraint(Throwable error, String constraint) {
    for (Throwable t = error; t != null; t = t.getCause()) {
      if (t.getMessage() != null && t.getMessage().contains(constraint)) {
        return true;
      }
    }
    return false;
  }

  private static void diff(
      String field, @Nullable Object oldValue, @Nullable Object newValue, Map<String, Object> before, Map<String, Object> after) {
    if (!java.util.Objects.equals(oldValue, newValue)) {
      before.put(field, oldValue);
      after.put(field, newValue);
    }
  }

  private static @Nullable String asText(@Nullable UUID id) {
    return id == null ? null : id.toString();
  }

  private static Map<String, Object> snapshot(CatalogGroup g) {
    Map<String, Object> map = new LinkedHashMap<>();
    map.put("code", g.getCode());
    map.put("name", g.getName());
    map.put("tenantId", g.getTenantId());
    map.put("parentId", asText(g.getParentId()));
    map.put("sortOrder", g.getSortOrder());
    map.put("description", g.getDescription());
    return map;
  }

  private static CatalogGroupView toView(CatalogGroup g, int catalogCount, List<CatalogGroupView> children) {
    return new CatalogGroupView(
        g.getId(),
        g.getTenantId(),
        g.getCode(),
        g.getName(),
        g.getParentId(),
        g.getSortOrder(),
        g.getDescription(),
        catalogCount,
        children,
        g.getCreatedAt(),
        g.getCreatedBy().toString(),
        g.getUpdatedAt(),
        g.getUpdatedBy().toString(),
        g.getVersion());
  }

}
