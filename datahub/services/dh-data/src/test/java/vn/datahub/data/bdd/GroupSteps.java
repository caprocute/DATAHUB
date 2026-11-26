package vn.datahub.data.bdd;

import static org.assertj.core.api.Assertions.assertThat;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.beans.factory.annotation.Value;
import tools.jackson.databind.JsonNode;
import vn.datahub.data.support.Api;
import vn.datahub.data.support.Api.Reply;
import vn.datahub.data.support.Db;
import vn.datahub.data.support.TestJwt;
import vn.datahub.data.support.TestPostgres;

/**
 * Hiện thực bước của gherkin/F-07-010.feature: mọi lệnh đi qua HTTP thật tới ứng dụng; CSDL chỉ
 * dùng để dựng tiền điều kiện và kiểm hậu điều kiện (bằng superuser, bỏ qua RLS).
 */
public class GroupSteps {

  private static final Pattern ID_PLACEHOLDER = Pattern.compile("<id ([^>]+)>");

  @Value("${local.server.port}")
  private int port;

  private Api api;
  private String token;
  private String userTenant = "T68";
  private Reply reply;
  private final Map<String, UUID> knownIds = new HashMap<>();
  private final Map<UUID, Integer> lastEtagVersion = new HashMap<>();
  private TestJwt.Persona persona;

  private Api api() {
    if (api == null) {
      api = new Api(port);
    }
    return api;
  }

  // ------------------------------------------------------------ tiền điều kiện

  @Given("CSDL đã nạp dữ liệu nền nhóm COMMON")
  public void seedLoaded() {
    assertThat(Db.count("select count(*) from ph07_rdm.catalog_group where tenant_id = 'COMMON'"))
        .as("seed 07-S01 phải có 9 nhóm COMMON")
        .isGreaterThanOrEqualTo(9);
  }

  @Given("tenant {string} có nhóm {string} tên {string} thứ tự {int}")
  public void tenantHasRootGroup(String tenant, String code, String name, int sortOrder) {
    knownIds.put(code, Db.insertGroup(tenant, code, name, null, sortOrder));
  }

  @Given("tenant {string} có nhóm {string} tên {string} là con của {string}")
  public void tenantHasChildGroup(String tenant, String code, String name, String parentCode) {
    UUID parent = idOf(parentCode);
    knownIds.put(code, Db.insertGroup(tenant, code, name, parent, 10));
  }

  @Given("tenant {string} có nhóm {string} tên {string}")
  public void tenantHasGroup(String tenant, String code, String name) {
    knownIds.put(code, Db.insertGroup(tenant, code, name, null, 0));
  }

  @Given("tenant {string} có {int} danh mục thuộc nhóm {string}")
  public void tenantHasCatalogs(String tenant, int count, String groupCode) {
    UUID group = idOf(groupCode);
    for (int i = 1; i <= count; i++) {
      Db.insertCatalog(tenant, groupCode + "_DM" + i, group, false);
    }
  }

  @Given("tenant {string} có chuỗi nhóm lồng {string}")
  public void tenantHasChain(String tenant, String chain) {
    UUID parent = null;
    for (String code : chain.split(">")) {
      parent = Db.insertGroup(tenant, code, "Nhóm " + code, parent, 0);
      knownIds.put(code, parent);
    }
  }

  @Given("tôi là người dùng {string} của tenant {string}")
  public void iAmUser(String role, String tenant) {
    persona = TestJwt.persona(role, tenant, persona == null ? UUID.randomUUID() : persona.sub());
    token = TestJwt.token(persona);
    userTenant = tenant;
  }

  @Given("tôi chưa đăng nhập")
  public void iAmAnonymous() {
    token = null;
  }

  // ------------------------------------------------------------ hành động

  @When("tôi gọi GET {string}")
  public void callGet(String path) {
    reply = api().get(expand(path), token);
    remember(reply);
  }

  @When("tôi gọi POST {string} với thân:")
  public void callPost(String path, String body) {
    reply = api().postJson(expand(path), token, expand(body));
    remember(reply);
  }

  @When("tôi gọi POST {string} với Idempotency-Key {string} và thân:")
  public void callPostIdempotent(String path, String key, String body) {
    reply =
        api().send(
                "POST",
                expand(path),
                token,
                Map.of("Content-Type", "application/json", "Idempotency-Key", key),
                expand(body));
    remember(reply);
  }

  @When("tôi gọi PATCH {string} với If-Match đúng và thân:")
  public void callPatchCorrect(String path, String body) {
    String expanded = expand(path);
    reply = api().patchJson(expanded, token, currentEtag(expanded), expand(body));
    remember(reply);
  }

  @When("tôi gọi PATCH {string} với If-Match {string} và thân:")
  public void callPatchWith(String path, String ifMatch, String body) {
    reply = api().patchJson(expand(path), token, ifMatch, expand(body));
    remember(reply);
  }

  @When("tôi gọi PATCH {string} không có If-Match và thân:")
  public void callPatchWithout(String path, String body) {
    reply = api().patchJson(expand(path), token, null, expand(body));
    remember(reply);
  }

  @When("tôi gọi DELETE {string} với If-Match đúng")
  public void callDelete(String path) {
    String expanded = expand(path);
    reply = api().delete(expanded, token, currentEtag(expanded));
    remember(reply);
  }

  // ------------------------------------------------------------ kiểm tra phản hồi

  @Then("mã phản hồi là {int}")
  public void statusIs(int status) {
    assertThat(reply.status()).as("thân: %s", reply.body()).isEqualTo(status);
  }

  @Then("phản hồi có header {string} bằng {string}")
  public void headerEquals(String name, String value) {
    assertThat(reply.header(name)).isEqualTo(value);
  }

  @Then("phản hồi có header {string} kết thúc bằng id của nhóm {string}")
  public void headerEndsWithId(String name, String code) {
    UUID id = knownIds.get(code);
    assertThat(id).as("id nhóm %s đã biết từ phản hồi", code).isNotNull();
    assertThat(reply.header(name)).endsWith("/" + id);
  }

  @Then("phản hồi có trường {string} bằng {string}")
  public void fieldEquals(String field, String value) {
    assertThat(reply.json().path(field).asString()).isEqualTo(value);
  }

  @Then("lỗi có code {string}")
  public void errorCode(String code) {
    assertThat(reply.header("content-type")).startsWith("application/problem+json");
    JsonNode problem = reply.json();
    assertThat(problem.path("code").asString()).isEqualTo(code);
    assertThat(problem.path("status").asInt()).isEqualTo(reply.status());
    assertThat(problem.path("traceId").asString()).matches("^[0-9a-f]{32}$");
    assertThat(problem.path("title").asString()).isNotBlank();
    assertThat(problem.path("type").asString()).startsWith("https://datahub.gov.vn/problems/rdm/");
  }

  @Then("lỗi có code {string} và errors chứa code {string} ở trường {string}")
  public void errorWithSubCode(String code, String subCode, String field) {
    errorCode(code);
    boolean found = false;
    for (JsonNode e : reply.json().path("errors")) {
      if (subCode.equals(e.path("code").asString()) && field.equals(e.path("field").asString())) {
        found = true;
      }
    }
    assertThat(found).as("errors[] phải có {field=%s, code=%s}: %s", field, subCode, reply.body()).isTrue();
  }

  @Then("lỗi có code {string} và detail chứa {string}")
  public void errorWithDetail(String code, String fragment) {
    errorCode(code);
    assertThat(reply.json().path("detail").asString()).contains(fragment);
  }

  // ------------------------------------------------------------ kiểm tra cây, CSDL

  @Then("trong cây, nhóm {string} có các con theo thứ tự {string}")
  public void childrenInOrder(String code, String expected) {
    JsonNode node = findNode(reply.json().path("items"), code, userTenant);
    List<String> actual = new ArrayList<>();
    for (JsonNode child : node.path("children")) {
      actual.add(child.path("code").asString());
    }
    assertThat(String.join(", ", actual)).isEqualTo(expected);
  }

  @Then("trong cây, nhóm {string} có catalogCount là {int}")
  public void catalogCountIs(String code, int count) {
    assertThat(findNode(reply.json().path("items"), code, userTenant).path("catalogCount").asInt())
        .isEqualTo(count);
  }

  @Then("trong cây có nhóm gốc {string} của tenant {string}")
  public void rootGroupOfTenant(String code, String tenant) {
    boolean found = false;
    for (JsonNode root : reply.json().path("items")) {
      if (code.equals(root.path("code").asString())
          && tenant.equals(root.path("tenantId").asString())
          && root.path("parentId").isNull()) {
        found = true;
      }
    }
    assertThat(found).as("nhóm gốc %s của %s", code, tenant).isTrue();
  }

  @Then("danh sách không có nhóm {string}")
  public void listLacks(String code) {
    assertThat(flatten(reply.json().path("items")).stream().map(n -> n.path("code").asString()))
        .doesNotContain(code);
  }

  @Then("danh sách có nhóm {string} của tenant {string}")
  public void listHas(String code, String tenant) {
    assertThat(
            flatten(reply.json().path("items")).stream()
                .anyMatch(
                    n ->
                        code.equals(n.path("code").asString())
                            && tenant.equals(n.path("tenantId").asString())))
        .isTrue();
  }

  @Then("nhóm {string} vẫn không có nhóm cha")
  public void stillNoParent(String code) {
    assertThat(
            Db.count(
                "select count(*) from ph07_rdm.catalog_group where id = ? and parent_id is null",
                idOf(code)))
        .isEqualTo(1);
  }

  @Then("nhóm {string} vẫn tồn tại")
  public void stillExists(String code) {
    assertThat(Db.count("select count(*) from ph07_rdm.catalog_group where id = ?", idOf(code)))
        .isEqualTo(1);
  }

  @Then("tenant {string} chỉ có {int} nhóm mã {string}")
  public void onlyNGroups(String tenant, int count, String code) {
    assertThat(
            Db.count(
                "select count(*) from ph07_rdm.catalog_group where tenant_id = ? and code = ?",
                tenant,
                code))
        .isEqualTo(count);
  }

  @Then("có bản ghi kiểm toán {string} cho nhóm {string}")
  public void auditRecorded(String action, String code) {
    UUID id = knownIds.containsKey(code) ? knownIds.get(code) : idOf(code);
    List<Map<String, String>> rows =
        Db.query(
            "select tenant_id, event_type, topic, aggregate_type, trace_id, payload::text as payload"
                + " from ph07_rdm.outbox where aggregate_id = ? and payload->>'action' = ?",
            rs -> {
              try {
                Map<String, String> row = new LinkedHashMap<>();
                for (String col :
                    List.of("tenant_id", "event_type", "topic", "aggregate_type", "trace_id", "payload")) {
                  row.put(col, rs.getString(col));
                }
                return row;
              } catch (java.sql.SQLException e) {
                throw new IllegalStateException(e);
              }
            },
            id.toString(),
            action);
    assertThat(rows).as("đúng MỘT dòng outbox kiểm toán %s cho %s", action, code).hasSize(1);
    Map<String, String> row = rows.getFirst();
    String dataTenant = "PLATFORM".equals(userTenant) ? "COMMON" : userTenant;
    assertThat(row.get("tenant_id")).isEqualTo(dataTenant);
    assertThat(row.get("event_type")).isEqualTo("vn.datahub.rdm.audit.recorded.v1");
    assertThat(row.get("topic")).isEqualTo(dataTenant.toLowerCase() + ".rdm.audit.recorded.v1");
    assertThat(row.get("aggregate_type")).isEqualTo("catalog_group");
    JsonNode payload = new tools.jackson.databind.json.JsonMapper().readTree(row.get("payload"));
    assertThat(payload.path("actor").asString()).isEqualTo(persona.sub().toString());
    assertThat(payload.path("objectRef").asString()).isEqualTo("catalog_group:" + id);
    assertThat(payload.path("traceId").asString()).isEqualTo(row.get("trace_id").trim());
    assertThat(payload.has("at")).isTrue();
    assertThat(payload.has("ip")).isTrue();
  }

  // ------------------------------------------------------------ trợ giúp

  /** Thay {@code <id X>} bằng id nhóm mã X. */
  private String expand(String text) {
    Matcher m = ID_PLACEHOLDER.matcher(text);
    StringBuilder out = new StringBuilder();
    while (m.find()) {
      m.appendReplacement(out, Matcher.quoteReplacement(idOf(m.group(1)).toString()));
    }
    m.appendTail(out);
    return out.toString();
  }

  /** Id nhóm theo mã: ưu tiên nhóm của tenant ghi hiện tại, sau đó bất kỳ tenant nào. */
  private UUID idOf(String code) {
    UUID known = knownIds.get(code);
    if (known != null && Db.count("select count(*) from ph07_rdm.catalog_group where id = ?", known) == 1) {
      return known;
    }
    String preferred = "PLATFORM".equals(userTenant) ? "COMMON" : userTenant;
    List<UUID> ids =
        Db.query(
            "select id from ph07_rdm.catalog_group where code = ? order by (tenant_id = ?) desc",
            rs -> {
              try {
                return rs.getObject("id", UUID.class);
              } catch (java.sql.SQLException e) {
                throw new IllegalStateException(e);
              }
            },
            code,
            preferred);
    if (ids.isEmpty() && known != null) {
      return known; // nhóm đã xóa: vẫn cần id để kiểm kiểm toán
    }
    assertThat(ids).as("nhóm mã %s phải tồn tại", code).isNotEmpty();
    knownIds.put(code, ids.getFirst());
    return ids.getFirst();
  }

  /** ETag W/"{version}" từ lần đọc gần nhất của nhóm trong đường dẫn; chưa đọc thì lấy từ CSDL. */
  private String currentEtag(String path) {
    UUID id = UUID.fromString(path.substring(path.lastIndexOf('/') + 1));
    Integer version = lastEtagVersion.get(id);
    if (version == null) {
      version =
          Db.query(
                  "select version from ph07_rdm.catalog_group where id = ?",
                  rs -> {
                    try {
                      return rs.getInt(1);
                    } catch (java.sql.SQLException e) {
                      throw new IllegalStateException(e);
                    }
                  },
                  id)
              .getFirst();
    }
    return "W/\"" + version + "\"";
  }

  /** Ghi nhớ id và version thấy được trong phản hồi (tạo, sửa, danh sách). */
  private void remember(Reply r) {
    if (r.status() >= 400 || r.body() == null || r.body().isBlank()) {
      return;
    }
    JsonNode json = r.json();
    if (json.has("items")) {
      for (JsonNode n : flatten(json.path("items"))) {
        note(n);
      }
    } else {
      note(json);
    }
  }

  private void note(JsonNode node) {
    if (node.has("id") && node.has("code") && node.has("version")) {
      UUID id = UUID.fromString(node.path("id").asString());
      lastEtagVersion.put(id, node.path("version").asInt());
      if (node.path("tenantId").asString().equals("PLATFORM".equals(userTenant) ? "COMMON" : userTenant)) {
        knownIds.put(node.path("code").asString(), id);
      }
    }
  }

  private static List<JsonNode> flatten(JsonNode items) {
    List<JsonNode> all = new ArrayList<>();
    for (JsonNode n : items) {
      all.add(n);
      all.addAll(flatten(n.path("children")));
    }
    return all;
  }

  private static JsonNode findNode(JsonNode items, String code, String preferredTenant) {
    List<JsonNode> matches =
        flatten(items).stream().filter(n -> code.equals(n.path("code").asString())).toList();
    assertThat(matches).as("nhóm %s phải có trong cây", code).isNotEmpty();
    return matches.stream()
        .filter(n -> preferredTenant.equals(n.path("tenantId").asString()))
        .findFirst()
        .orElse(matches.getFirst());
  }
}
