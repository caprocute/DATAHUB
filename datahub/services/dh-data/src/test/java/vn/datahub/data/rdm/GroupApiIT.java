package vn.datahub.data.rdm;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import tools.jackson.databind.JsonNode;
import vn.datahub.data.support.Api.Reply;
import vn.datahub.data.support.Db;

/** Nhánh lỗi, quyền, kiểm tra đầu vào và khung HTTP của F-07-010 qua HTTP thật. */
class GroupApiIT extends GroupApiTestSupport {

  private String ta() {
    return tokenFor("TA", "T68");
  }

  private static String errorCode(Reply reply) {
    return reply.json().path("code").asString();
  }

  private static String subCodes(Reply reply) {
    StringBuilder sb = new StringBuilder();
    for (JsonNode e : reply.json().path("errors")) {
      sb.append(e.path("field").asString("")).append(':').append(e.path("code").asString("")).append(' ');
    }
    return sb.toString().trim();
  }

  private Reply createGroup(String code) {
    return api.postJson("/catalog-groups", ta(), "{\"code\":\"" + code + "\",\"name\":\"Nhóm " + code + "\"}");
  }

  // ---------------------------------------------------------------- xác thực

  @Test
  @DisplayName("401 ERR-07-041: thiếu token, token hỏng, hết hạn, sai chữ ký, tenant hoặc sub sai")
  void authenticationFailures() {
    var persona = vn.datahub.data.support.TestJwt.persona("TA", "T68", UUID.randomUUID());
    String[] tokens = {
      null,
      "khong.phai.jwt",
      vn.datahub.data.support.TestJwt.expired(persona),
      vn.datahub.data.support.TestJwt.signedByStranger(persona),
      vn.datahub.data.support.TestJwt.token(UUID.randomUUID().toString(), "COMMON", persona.perms(), persona.roles()),
      vn.datahub.data.support.TestJwt.token("khong-uuid", "T68", persona.perms(), persona.roles())
    };
    for (String token : tokens) {
      Reply reply = api.get("/catalog-groups", token);
      assertThat(reply.status()).as("token %s", token).isEqualTo(401);
      assertThat(errorCode(reply)).isEqualTo("ERR-07-041");
      assertThat(reply.header("content-type")).startsWith("application/problem+json");
      assertThat(reply.json().path("traceId").asString()).matches("^[0-9a-f]{32}$");
    }
  }

  @Test
  @DisplayName("traceId của lỗi lấy từ traceparent của yêu cầu")
  void traceIdFromTraceparent() {
    Reply reply =
        api.send("GET", "/catalog-groups", null,
            Map.of("traceparent", "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"), null);
    assertThat(reply.json().path("traceId").asString()).isEqualTo("4bf92f3577b34da6a3ce929d0e0e4736");
  }

  // ---------------------------------------------------------------- quyền (SS-07-03)

  @Test
  @DisplayName("403 ERR-07-046: thiếu quyền hoặc có quyền nhưng sai vai trò (DS)")
  void permissionMatrix() {
    UUID id = Db.insertGroup("T68", "NHOM_Q", "Nhóm Q", null, 1);
    var ds = vn.datahub.data.support.TestJwt.token(UUID.randomUUID().toString(), "T68",
        java.util.List.of("PERM-07-read", "PERM-07-create", "PERM-07-update"), java.util.List.of("DATA_STEWARD"));
    var noRole = vn.datahub.data.support.TestJwt.token(UUID.randomUUID().toString(), "T68",
        java.util.List.of("PERM-07-read", "PERM-07-create", "PERM-07-update"), java.util.List.of());
    var noPerm = vn.datahub.data.support.TestJwt.token(UUID.randomUUID().toString(), "T68",
        java.util.List.of(), java.util.List.of("TENANT_ADMIN"));
    for (String token : new String[] {ds, noRole, noPerm}) {
      assertThat(errorCode(api.postJson("/catalog-groups", token, "{\"code\":\"X\",\"name\":\"X\"}"))).isEqualTo("ERR-07-046");
      assertThat(errorCode(api.patchJson("/catalog-groups/" + id, token, "W/\"0\"", "{\"name\":\"Y\"}"))).isEqualTo("ERR-07-046");
      assertThat(errorCode(api.delete("/catalog-groups/" + id, token, "W/\"0\""))).isEqualTo("ERR-07-046");
    }
    assertThat(errorCode(api.get("/catalog-groups", noPerm))).isEqualTo("ERR-07-046");
    assertThat(Db.count("select count(*) from ph07_rdm.catalog_group where id = ? and name = 'Nhóm Q'", id)).isEqualTo(1);
    assertThat(Db.count("select count(*) from ph07_rdm.outbox")).isZero();
  }

  @Test
  @DisplayName("Quyền ở claim roles dạng ROLE-TENANT_ADMIN cũng được chấp nhận")
  void rolePrefixAccepted() {
    String token = vn.datahub.data.support.TestJwt.token(UUID.randomUUID().toString(), "T68",
        java.util.List.of("PERM-07-read", "PERM-07-create"), java.util.List.of("ROLE-TENANT_ADMIN"));
    assertThat(createGroupWith(token, "ROLE_PREFIX").status()).isEqualTo(201);
  }

  private Reply createGroupWith(String token, String code) {
    return api.postJson("/catalog-groups", token, "{\"code\":\"" + code + "\",\"name\":\"N\"}");
  }

  // ---------------------------------------------------------------- kiểm tra đầu vào

  @Test
  @DisplayName("422 ERR-07-009: trường bắt buộc, mẫu mã, độ dài, kiểu, trường lạ, JSON hỏng")
  void validationErrors() {
    Reply missing = api.postJson("/catalog-groups", ta(), "{}");
    assertThat(missing.status()).isEqualTo(422);
    assertThat(errorCode(missing)).isEqualTo("ERR-07-009");
    assertThat(subCodes(missing)).contains("code:REQUIRED").contains("name:REQUIRED");

    assertThat(subCodes(api.postJson("/catalog-groups", ta(), "{\"code\":\"-bad\",\"name\":\"A\"}"))).isEqualTo("code:PATTERN");
    assertThat(subCodes(api.postJson("/catalog-groups", ta(), "{\"code\":\"OK\",\"name\":\"" + "n".repeat(256) + "\"}"))).isEqualTo("name:MAX_LENGTH");
    assertThat(subCodes(api.postJson("/catalog-groups", ta(), "{\"code\":\"OK\",\"name\":\"A\",\"sortOrder\":\"abc\"}"))).isEqualTo("sortOrder:TYPE");
    assertThat(subCodes(api.postJson("/catalog-groups", ta(), "{\"code\":\"OK\",\"name\":\"A\",\"tenantId\":\"T01\"}"))).isEqualTo("tenantId:UNKNOWN_FIELD");

    // Không ép kiểu số/logic thành chuỗi: thân phải đúng kiểu OpenAPI (nhất quán với PATCH).
    Reply numeric = api.postJson("/catalog-groups", ta(), "{\"code\":\"OK\",\"name\":5}");
    assertThat(numeric.status()).isEqualTo(422);
    assertThat(errorCode(numeric)).isEqualTo("ERR-07-009");
    assertThat(subCodes(numeric)).isEqualTo("name:TYPE");
    assertThat(subCodes(api.postJson("/catalog-groups", ta(), "{\"code\":\"OK\",\"name\":\"A\",\"description\":true}"))).isEqualTo("description:TYPE");

    Reply broken = api.postJson("/catalog-groups", ta(), "{khong-phai-json");
    assertThat(broken.status()).isEqualTo(422);
    assertThat(errorCode(broken)).isEqualTo("ERR-07-009");
    assertThat(subCodes(broken)).isEqualTo(":TYPE");
    assertThat(Db.count("select count(*) from ph07_rdm.outbox")).isZero();
  }

  @Test
  @DisplayName("Tạo chuẩn hóa mã chữ hoa và tên NFC; nhóm cha là COMMON bị 403 ERR-07-003")
  void createNormalizesAndRejectsCommonParent() {
    String nfd = java.text.Normalizer.normalize("Kinh tế", java.text.Normalizer.Form.NFD);
    Reply ok = api.postJson("/catalog-groups", ta(), "{\"code\":\" kinh_te \",\"name\":\"" + nfd + "\"}");
    assertThat(ok.status()).isEqualTo(201);
    assertThat(ok.json().path("code").asString()).isEqualTo("KINH_TE");
    assertThat(ok.json().path("name").asString()).isEqualTo("Kinh tế");
    assertThat(ok.json().path("tenantId").asString()).isEqualTo("T68");
    assertThat(ok.json().path("catalogCount").asInt()).isZero();
    assertThat(ok.json().path("children").size()).isZero();

    UUID commonParent = UUID.fromString("0192f000-0000-7000-8000-000000000101");
    Reply denied = api.postJson("/catalog-groups", ta(),
        "{\"code\":\"CON_CUA_COMMON\",\"name\":\"Con\",\"parentId\":\"" + commonParent + "\"}");
    assertThat(denied.status()).isEqualTo(403);
    assertThat(errorCode(denied)).isEqualTo("ERR-07-003");
  }

  @Test
  @DisplayName("Sửa: thân rỗng, null ở tên, trường lạ, nhóm cha không tồn tại, vòng, độ sâu")
  void updateValidation() {
    UUID a = Db.insertGroup("T68", "A", "A", null, 1);
    UUID b = Db.insertGroup("T68", "B", "B", a, 1);
    Reply empty = api.patchJson("/catalog-groups/" + a, ta(), "W/\"0\"", "{}");
    assertThat(empty.status()).isEqualTo(422);
    assertThat(errorCode(empty)).isEqualTo("ERR-07-009");
    assertThat(errorCode(api.patchJson("/catalog-groups/" + a, ta(), "W/\"0\"", "{\"name\":null}"))).isEqualTo("ERR-07-009");
    assertThat(errorCode(api.patchJson("/catalog-groups/" + a, ta(), "W/\"0\"", "{\"parentId\":\"" + UUID.randomUUID() + "\"}"))).isEqualTo("ERR-07-009");
    Reply self = api.patchJson("/catalog-groups/" + a, ta(), "W/\"0\"", "{\"parentId\":\"" + a + "\"}");
    assertThat(self.status()).isEqualTo(409);
    assertThat(subCodes(self)).isEqualTo("parentId:CYCLE");
    Reply cycle = api.patchJson("/catalog-groups/" + a, ta(), "W/\"0\"", "{\"parentId\":\"" + b + "\"}");
    assertThat(subCodes(cycle)).isEqualTo("parentId:CYCLE");

    // Chuyển cây con vào chỗ làm vượt độ sâu.
    UUID chain = null;
    for (int i = 1; i <= 5; i++) {
      chain = Db.insertGroup("T68", "S" + i, "S" + i, chain, 1);
    }
    Reply deep = api.patchJson("/catalog-groups/" + a, ta(), "W/\"0\"", "{\"parentId\":\"" + chain + "\"}");
    assertThat(deep.status()).isEqualTo(409);
    assertThat(subCodes(deep)).isEqualTo("parentId:DEPTH");
  }

  @Test
  @DisplayName("Sửa: đổi nhóm cha hợp lệ, gỡ nhóm cha bằng null, không đổi gì thì không ghi kiểm toán")
  void updateMoveAndNoop() {
    UUID a = Db.insertGroup("T68", "A", "A", null, 1);
    UUID b = Db.insertGroup("T68", "B", "B", null, 2);
    Reply moved = api.patchJson("/catalog-groups/" + b, ta(), "W/\"0\"", "{\"parentId\":\"" + a + "\",\"description\":\"Mô tả\"}");
    assertThat(moved.status()).isEqualTo(200);
    assertThat(moved.header("etag")).isEqualTo("W/\"1\"");
    assertThat(moved.json().path("parentId").asString()).isEqualTo(a.toString());
    assertThat(moved.json().path("description").asString()).isEqualTo("Mô tả");

    Reply detached = api.patchJson("/catalog-groups/" + b, ta(), "W/\"1\"", "{\"parentId\":null}");
    assertThat(detached.status()).isEqualTo(200);
    assertThat(detached.json().path("parentId").isNull()).isTrue();

    long before = Db.count("select count(*) from ph07_rdm.outbox");
    Reply noop = api.patchJson("/catalog-groups/" + b, ta(), "W/\"2\"", "{\"name\":\"B\"}");
    assertThat(noop.status()).isEqualTo(200);
    assertThat(noop.header("etag")).isEqualTo("W/\"2\"");
    assertThat(Db.count("select count(*) from ph07_rdm.outbox")).isEqualTo(before);
  }

  // ---------------------------------------------------------------- If-Match, xóa

  @Test
  @DisplayName("If-Match sai định dạng là 400 ERR-07-040; ETag cũ là 412 ERR-07-018 cả ở PATCH và DELETE")
  void ifMatchHandling() {
    UUID id = Db.insertGroup("T68", "A", "A", null, 1);
    assertThat(errorCode(api.patchJson("/catalog-groups/" + id, ta(), "abc", "{\"name\":\"X\"}"))).isEqualTo("ERR-07-040");
    assertThat(errorCode(api.delete("/catalog-groups/" + id, ta(), null))).isEqualTo("ERR-07-040");
    assertThat(errorCode(api.delete("/catalog-groups/" + id, ta(), "W/\"5\""))).isEqualTo("ERR-07-018");
    assertThat(Db.count("select count(*) from ph07_rdm.catalog_group where id = ?", id)).isEqualTo(1);
  }

  @Test
  @DisplayName("Xóa nhóm còn nhóm con, hoặc chỉ còn danh mục đã xóa mềm: 409 ERR-07-037 nêu số lượng")
  void deleteBlockedByChildrenOrSoftDeletedCatalogs() {
    UUID parent = Db.insertGroup("T68", "CHA", "Cha", null, 1);
    Db.insertGroup("T68", "CON", "Con", parent, 1);
    Reply withChild = api.delete("/catalog-groups/" + parent, ta(), "W/\"0\"");
    assertThat(withChild.status()).isEqualTo(409);
    assertThat(errorCode(withChild)).isEqualTo("ERR-07-037");
    assertThat(withChild.json().path("detail").asString()).contains("1 nhóm con");
    assertThat(withChild.json().path("childCount").asInt()).isEqualTo(1);
    assertThat(withChild.json().path("catalogCount").asInt()).isZero();

    UUID leaf = Db.insertGroup("T68", "LA", "Lá", null, 1);
    Db.insertCatalog("T68", "DM_XOA_MEM", leaf, true);
    Reply softDeleted = api.delete("/catalog-groups/" + leaf, ta(), "W/\"0\"");
    assertThat(softDeleted.status()).isEqualTo(409);
    assertThat(softDeleted.json().path("detail").asString()).contains("1 danh mục đã xóa mềm");
    assertThat(Db.count("select count(*) from ph07_rdm.outbox")).isZero();
  }

  @Test
  @DisplayName("PA xóa nhóm COMMON do mình tạo; nhóm COMMON có danh mục của tỉnh khác thì 409")
  void platformDeletesCommonGroup() {
    String pa = tokenFor("PA", "PLATFORM");
    Reply created = api.postJson("/catalog-groups", pa, "{\"code\":\"TAM\",\"name\":\"Tạm\"}");
    assertThat(created.status()).isEqualTo(201);
    UUID id = UUID.fromString(created.json().path("id").asString());
    assertThat(api.delete("/catalog-groups/" + id, pa, created.header("etag")).status()).isEqualTo(204);

    UUID commonWithForeign = Db.insertGroup("COMMON", "DUNG_CHUNG", "Dùng chung", null, 5);
    Db.insertCatalog("T01", "DM_T01", commonWithForeign, false);
    Reply blocked = api.delete("/catalog-groups/" + commonWithForeign, pa, "W/\"0\"");
    assertThat(blocked.status()).isEqualTo(409);
    assertThat(errorCode(blocked)).isEqualTo("ERR-07-037");
  }

  // ---------------------------------------------------------------- Idempotency-Key

  @Test
  @DisplayName("Idempotency-Key sai định dạng là 422; phản hồi phát lại giữ nguyên ETag và Location")
  void idempotencyKeyFormatAndReplay() {
    Reply bad = api.send("POST", "/catalog-groups", ta(),
        Map.of("Content-Type", "application/json", "Idempotency-Key", "ngan"), "{\"code\":\"A\",\"name\":\"A\"}");
    assertThat(bad.status()).isEqualTo(422);
    assertThat(subCodes(bad)).isEqualTo("Idempotency-Key:PATTERN");

    String key = "phat-lai-0123456789";
    Map<String, String> headers = Map.of("Content-Type", "application/json", "Idempotency-Key", key);
    String token = ta();
    Reply first = api.send("POST", "/catalog-groups", token, headers, "{\"code\":\"PL\",\"name\":\"Phát lại\"}");
    Reply second = api.send("POST", "/catalog-groups", token, headers, "{\"name\":\"Phát lại\",\"code\":\"pl\"}");
    assertThat(first.status()).isEqualTo(201);
    assertThat(second.status()).isEqualTo(201);
    assertThat(second.header("idempotent-replayed")).isEqualTo("true");
    assertThat(second.header("location")).isEqualTo(first.header("location"));
    assertThat(second.header("etag")).isEqualTo(first.header("etag"));
    assertThat(second.json().path("id").asString()).isEqualTo(first.json().path("id").asString());
    assertThat(Db.count("select count(*) from ph07_rdm.outbox where payload->>'action' = 'RDM_GROUP_CREATE'")).isEqualTo(1);
  }

  @Test
  @DisplayName("Khóa hết hạn được dùng lại như khóa mới")
  void expiredKeyIsReusable() {
    String key = "het-han-0123456789ab";
    Map<String, String> headers = Map.of("Content-Type", "application/json", "Idempotency-Key", key);
    String token = ta();
    assertThat(api.send("POST", "/catalog-groups", token, headers, "{\"code\":\"HH1\",\"name\":\"Một\"}").status()).isEqualTo(201);
    Db.execute("update ph07_rdm.idempotency_key set expires_at = now() - interval '1 hour'");
    Reply again = api.send("POST", "/catalog-groups", token, headers, "{\"code\":\"HH2\",\"name\":\"Hai\"}");
    assertThat(again.status()).isEqualTo(201);
    assertThat(again.header("idempotent-replayed")).isNull();
  }

  // ---------------------------------------------------------------- khung HTTP

  @Test
  @DisplayName("413 ERR-07-042 thân quá lớn; 415 ERR-07-043 sai kiểu nội dung")
  void sizeAndMediaType() {
    String huge = "{\"code\":\"BIG\",\"name\":\"" + "x".repeat(1_200_000) + "\"}";
    Reply large = api.postJson("/catalog-groups", ta(), huge);
    assertThat(large.status()).isEqualTo(413);
    assertThat(errorCode(large)).isEqualTo("ERR-07-042");

    Reply media = api.send("POST", "/catalog-groups", ta(), Map.of("Content-Type", "text/plain"), "x");
    assertThat(media.status()).isEqualTo(415);
    assertThat(errorCode(media)).isEqualTo("ERR-07-043");
  }

  @Test
  @DisplayName("404 ERR-07-045 đường dẫn lạ hoặc id sai dạng; 405 phương thức không hỗ trợ; 422 tham số sai kiểu")
  void routing() {
    assertThat(errorCode(api.get("/khong-co", ta()))).isEqualTo("ERR-07-045");
    Reply badId = api.patchJson("/catalog-groups/khong-phai-uuid", ta(), "W/\"0\"", "{\"name\":\"X\"}");
    assertThat(badId.status()).isEqualTo(404);
    assertThat(errorCode(badId)).isEqualTo("ERR-07-045");
    Reply unknownId = api.delete("/catalog-groups/" + UUID.randomUUID(), ta(), "W/\"0\"");
    assertThat(unknownId.status()).isEqualTo(404);
    assertThat(errorCode(unknownId)).isEqualTo("ERR-07-045");
    Reply method = api.send("PUT", "/catalog-groups", ta(), Map.of("Content-Type", "application/json"), "{}");
    assertThat(method.status()).isEqualTo(405);
    Reply flat = api.get("/catalog-groups?flat=maybe", ta());
    assertThat(flat.status()).isEqualTo(422);
    assertThat(subCodes(flat)).isEqualTo("flat:TYPE");
  }

  @Test
  @DisplayName("Phản hồi lỗi không lộ stack trace, tên lớp hay SQL")
  void errorsDoNotLeakInternals() {
    Reply reply = api.postJson("/catalog-groups", ta(), "{\"code\":\"OK\",\"name\":\"A\",\"parentId\":\"khong-uuid\"}");
    assertThat(reply.body()).doesNotContain("Exception").doesNotContain("at vn.datahub").doesNotContain("select ");
    Reply created = createGroup("BINH_THUONG");
    assertThat(created.status()).isEqualTo(201);
  }
}
