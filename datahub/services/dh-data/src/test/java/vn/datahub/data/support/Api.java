package vn.datahub.data.support;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/** Khách HTTP thật tới ứng dụng đang chạy (JDK HttpClient), trả về {@link Reply}. */
public final class Api {

  /** Phản hồi: mã, tiêu đề (chữ thường), thân thô. */
  public record Reply(int status, Map<String, String> headers, String body) {

    private static final JsonMapper MAPPER = JsonMapper.builder().build();

    public JsonNode json() {
      return MAPPER.readTree(body);
    }

    public String header(String name) {
      return headers.get(name.toLowerCase(java.util.Locale.ROOT));
    }
  }

  private static final HttpClient CLIENT =
      HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10)).build();

  private final String baseUrl;

  public Api(int port) {
    this.baseUrl = "http://localhost:" + port + "/api/rdm/v1";
  }

  public Reply send(
      String method, String path, String token, Map<String, String> headers, String body) {
    HttpRequest.Builder builder =
        HttpRequest.newBuilder(URI.create(baseUrl + path)).timeout(Duration.ofSeconds(30));
    if (token != null) {
      builder.header("Authorization", "Bearer " + token);
    }
    headers.forEach(builder::header);
    HttpRequest.BodyPublisher publisher =
        body == null
            ? HttpRequest.BodyPublishers.noBody()
            : HttpRequest.BodyPublishers.ofString(body, StandardCharsets.UTF_8);
    builder.method(method, publisher);
    try {
      HttpResponse<String> response =
          CLIENT.send(builder.build(), HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
      Map<String, String> lower = new HashMap<>();
      response.headers().map().forEach((k, v) -> lower.put(k.toLowerCase(java.util.Locale.ROOT), v.getFirst()));
      return new Reply(response.statusCode(), lower, response.body());
    } catch (IOException e) {
      throw new IllegalStateException(e);
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      throw new IllegalStateException(e);
    }
  }

  public Reply get(String path, String token) {
    return send("GET", path, token, Map.of(), null);
  }

  public Reply postJson(String path, String token, String json) {
    return send("POST", path, token, Map.of("Content-Type", "application/json"), json);
  }

  public Reply patchJson(String path, String token, String ifMatch, String json) {
    Map<String, String> headers = new HashMap<>();
    headers.put("Content-Type", "application/merge-patch+json");
    if (ifMatch != null) {
      headers.put("If-Match", ifMatch);
    }
    return send("PATCH", path, token, headers, json);
  }

  public Reply delete(String path, String token, String ifMatch) {
    Map<String, String> headers = new HashMap<>();
    if (ifMatch != null) {
      headers.put("If-Match", ifMatch);
    }
    return send("DELETE", path, token, headers, null);
  }
}
