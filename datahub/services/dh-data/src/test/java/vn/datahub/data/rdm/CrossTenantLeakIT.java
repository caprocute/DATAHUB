package vn.datahub.data.rdm;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.JsonNode;
import vn.datahub.data.support.Api.Reply;
import vn.datahub.data.support.Db;

/** CC-TEST-03 / D03-10 quy tắc 6: tenant này không thấy, không sửa, không xóa dữ liệu của tenant kia. */
class CrossTenantLeakIT extends GroupApiTestSupport {

  private UUID t01Group() {
    return Db.insertGroup("T01", "RIENG_T01", "Riêng T01", null, 1);
  }

  private static List<String> codes(Reply reply) {
    return reply.json().path("items").valueStream().map(n -> n.path("code").asString()).toList();
  }

  @Test
  @DisplayName("Danh sách (phẳng và cây) của T68 không lộ nhóm của T01 nhưng có nhóm COMMON")
  void listDoesNotLeak() {
    t01Group();
    String t68 = tokenFor("TA", "T68");
    assertThat(codes(api.get("/catalog-groups?flat=true", t68))).doesNotContain("RIENG_T01").contains("KHAC");
    assertThat(codes(api.get("/catalog-groups", t68))).doesNotContain("RIENG_T01");
    assertThat(codes(api.get("/catalog-groups?flat=true", tokenFor("TA", "T01")))).contains("RIENG_T01");
  }

  @Test
  @DisplayName("PLATFORM chỉ thấy COMMON, không thấy nhóm của tỉnh")
  void platformSeesOnlyCommon() {
    t01Group();
    Reply reply = api.get("/catalog-groups?flat=true", tokenFor("PA", "PLATFORM"));
    assertThat(reply.status()).isEqualTo(200);
    for (JsonNode n : reply.json().path("items")) {
      assertThat(n.path("tenantId").asString()).isEqualTo("COMMON");
    }
  }

  @Test
  @DisplayName("Sửa, xóa nhóm của tenant khác: 404 ERR-07-045 (không phải 403), dữ liệu giữ nguyên")
  void mutationsReturn404() {
    UUID id = t01Group();
    String t68 = tokenFor("TA", "T68");
    Reply patch = api.patchJson("/catalog-groups/" + id, t68, "W/\"0\"", "{\"name\":\"Chiếm\"}");
    assertThat(patch.status()).isEqualTo(404);
    assertThat(patch.json().path("code").asString()).isEqualTo("ERR-07-045");
    Reply delete = api.delete("/catalog-groups/" + id, t68, "W/\"0\"");
    assertThat(delete.status()).isEqualTo(404);
    assertThat(delete.json().path("code").asString()).isEqualTo("ERR-07-045");
    assertThat(Db.count("select count(*) from ph07_rdm.catalog_group where id = ? and name = 'Riêng T01'", id))
        .isEqualTo(1);
    assertThat(Db.count("select count(*) from ph07_rdm.outbox")).isZero();
  }

  @Test
  @DisplayName("Không đặt được nhóm của tenant khác làm nhóm cha (422 PARENT_NOT_FOUND)")
  void foreignParentIsRejected() {
    UUID id = t01Group();
    Reply reply =
        api.postJson(
            "/catalog-groups",
            tokenFor("TA", "T68"),
            "{\"code\":\"CON\",\"name\":\"Con\",\"parentId\":\"" + id + "\"}");
    assertThat(reply.status()).isEqualTo(422);
    assertThat(reply.json().path("code").asString()).isEqualTo("ERR-07-009");
    assertThat(reply.json().path("errors").get(0).path("code").asString()).isEqualTo("PARENT_NOT_FOUND");
  }

  @Test
  @DisplayName("Nhóm tạo bởi T68 không hiện với T01 và Idempotency-Key không dùng chung giữa tenant")
  void createdGroupAndIdempotencyAreScoped() {
    String key = "khoa-chong-trung-0001";
    String body = "{\"code\":\"CHI_T68\",\"name\":\"Chỉ T68\"}";
    Reply first =
        api.send("POST", "/catalog-groups", tokenFor("TA", "T68"),
            java.util.Map.of("Content-Type", "application/json", "Idempotency-Key", key), body);
    assertThat(first.status()).isEqualTo(201);
    assertThat(codes(api.get("/catalog-groups?flat=true", tokenFor("TA", "T01")))).doesNotContain("CHI_T68");
    Reply other =
        api.send("POST", "/catalog-groups", tokenFor("TA", "T01"),
            java.util.Map.of("Content-Type", "application/json", "Idempotency-Key", key), body);
    assertThat(other.status()).isEqualTo(201);
    assertThat(other.header("idempotent-replayed")).isNull();
    assertThat(Db.count("select count(*) from ph07_rdm.catalog_group where code = 'CHI_T68'")).isEqualTo(2);
  }

  private static int countOf(JsonNode items, String code, String tenant) {
    for (JsonNode n : items) {
      if (code.equals(n.path("code").asString()) && tenant.equals(n.path("tenantId").asString())) {
        return n.path("catalogCount").asInt();
      }
    }
    throw new AssertionError("Không thấy nhóm " + code);
  }

  @Test
  @DisplayName("Đếm danh mục theo nhóm không cộng danh mục xóa mềm hay danh mục của tenant khác")
  void catalogCountIgnoresOtherTenants() {
    UUID t68Group = Db.insertGroup("T68", "NHOM_A", "Nhóm A", null, 1);
    String token = tokenFor("TA", "T68");
    int commonBefore = countOf(api.get("/catalog-groups?flat=true", token).json().path("items"), "HANH_CHINH", "COMMON");

    Db.insertCatalog("T68", "DM_T68", t68Group, false);
    Db.insertCatalog("T68", "DM_T68_XOA", t68Group, true);
    UUID commonGroup = UUID.fromString("0192f000-0000-7000-8000-000000000101");
    Db.insertCatalog("T01", "DM_T01_DUNG_NHOM_COMMON", commonGroup, false);

    JsonNode items = api.get("/catalog-groups?flat=true", token).json().path("items");
    assertThat(countOf(items, "NHOM_A", "T68")).as("danh mục xóa mềm không được đếm").isEqualTo(1);
    assertThat(countOf(items, "HANH_CHINH", "COMMON"))
        .as("danh mục của T01 không lộ sang T68")
        .isEqualTo(commonBefore);
  }
}
