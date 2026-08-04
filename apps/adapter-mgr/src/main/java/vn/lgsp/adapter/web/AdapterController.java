package vn.lgsp.adapter.web;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/v1/adapters")
public class AdapterController {

  private final JdbcTemplate jdbc;

  public AdapterController(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @GetMapping
  Map<String, Object> list() {
    List<Map<String, Object>> items =
        jdbc.queryForList(
            """
            SELECT id, name, type, endpoint_url AS "endpointUrl", vault_path AS "vaultPath"
            FROM ph05.adapter ORDER BY created_at
            """);
    return Map.of("items", items);
  }

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  Map<String, Object> create(@RequestBody CreateAdapter body) {
    String id = body.id() != null && !body.id().isBlank() ? body.id() : "adp-" + UUID.randomUUID();
    if (!"HTTP_MOCK".equals(body.type())) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "W1 chỉ hỗ trợ HTTP_MOCK");
    }
    jdbc.update(
        """
        INSERT INTO ph05.adapter (id, name, type, endpoint_url, vault_path, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        id,
        body.name(),
        body.type(),
        body.endpointUrl(),
        body.vaultPath() != null ? body.vaultPath() : "secret/data/lgsp/dev/adapters/" + id,
        OffsetDateTime.now());
    return resolve(id);
  }

  /** Camel gọi endpoint này để lấy URL runtime — secret không nằm trong response. */
  @GetMapping("/{id}/resolve")
  Map<String, Object> resolve(@PathVariable("id") String id) {
    try {
      return jdbc.queryForMap(
          """
          SELECT id, type, endpoint_url AS "endpointUrl", vault_path AS "vaultPath"
          FROM ph05.adapter WHERE id = ?
          """,
          id);
    } catch (EmptyResultDataAccessException e) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "adapter not found");
    }
  }

  public record CreateAdapter(
      String id, String name, String type, String endpointUrl, String vaultPath) {}
}
