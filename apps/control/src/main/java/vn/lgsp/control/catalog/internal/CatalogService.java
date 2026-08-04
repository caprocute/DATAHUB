package vn.lgsp.control.catalog.internal;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.lgsp.control.catalog.api.CatalogApi;
import vn.lgsp.control.catalog.api.ServiceRegisterRequest;
import vn.lgsp.control.catalog.api.ServiceSummaryDto;

@Service
class CatalogService implements CatalogApi {

  private static final RowMapper<ServiceSummaryDto> MAPPER =
      (rs, i) ->
          new ServiceSummaryDto(
              rs.getObject("id", UUID.class),
              rs.getString("service_code"),
              rs.getString("title"),
              rs.getString("status"),
              rs.getString("public_path"),
              rs.getString("route_file"));

  private final JdbcTemplate jdbc;
  private final ApisixRouteWriter routeWriter;

  CatalogService(JdbcTemplate jdbc, ApisixRouteWriter routeWriter) {
    this.jdbc = jdbc;
    this.routeWriter = routeWriter;
  }

  @Override
  @Transactional
  public ServiceSummaryDto register(ServiceRegisterRequest request) {
    UUID id = UUID.randomUUID();
    OffsetDateTime now = OffsetDateTime.now();
    String publicPath =
        request.publicPath() != null && !request.publicPath().isBlank()
            ? request.publicPath()
            : "/demo/" + request.serviceCode();
    String upstream =
        request.upstreamUrl() != null && !request.upstreamUrl().isBlank()
            ? request.upstreamUrl()
            : "http://host.docker.internal:8088";
    jdbc.update(
        """
        INSERT INTO ph02.api_service
          (id, service_code, title, openapi_yaml, status, public_path, upstream_url, created_at, updated_at)
        VALUES (?, ?, ?, ?, 'DRAFT', ?, ?, ?, ?)
        """,
        id,
        request.serviceCode(),
        request.title(),
        request.openapiYaml(),
        publicPath,
        upstream,
        now,
        now);
    return find(id);
  }

  @Override
  @Transactional
  public ServiceSummaryDto publish(UUID id) {
    ServiceRow row = findRow(id);
    if ("PUBLISHED".equals(row.status())) {
      return find(id);
    }
    String routeFile = routeWriter.writeRoute(row.serviceCode(), row.publicPath(), row.upstreamUrl());
    jdbc.update(
        """
        UPDATE ph02.api_service
        SET status = 'PUBLISHED', route_file = ?, updated_at = ?
        WHERE id = ?
        """,
        routeFile,
        OffsetDateTime.now(),
        id);
    return find(id);
  }

  @Override
  public List<ServiceSummaryDto> list() {
    return jdbc.query(
        """
        SELECT id, service_code, title, status, public_path, route_file
        FROM ph02.api_service ORDER BY created_at DESC
        """,
        MAPPER);
  }

  @Override
  public String moduleStatus() {
    return "ok";
  }

  private ServiceSummaryDto find(UUID id) {
    return jdbc.queryForObject(
        """
        SELECT id, service_code, title, status, public_path, route_file
        FROM ph02.api_service WHERE id = ?
        """,
        MAPPER,
        id);
  }

  private ServiceRow findRow(UUID id) {
    try {
      return jdbc.queryForObject(
          """
          SELECT id, service_code, status, public_path, upstream_url
          FROM ph02.api_service WHERE id = ?
          """,
          (rs, i) ->
              new ServiceRow(
                  rs.getObject("id", UUID.class),
                  rs.getString("service_code"),
                  rs.getString("status"),
                  rs.getString("public_path"),
                  rs.getString("upstream_url")),
          id);
    } catch (EmptyResultDataAccessException e) {
      throw new IllegalArgumentException("service not found: " + id);
    }
  }

  private record ServiceRow(
      UUID id, String serviceCode, String status, String publicPath, String upstreamUrl) {}
}
