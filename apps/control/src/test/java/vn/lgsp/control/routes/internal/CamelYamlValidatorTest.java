package vn.lgsp.control.routes.internal;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class CamelYamlValidatorTest {

  private final CamelYamlValidator validator = new CamelYamlValidator();

  @Test
  void acceptsMinimalCamelYaml() {
    String yaml =
        """
        - route:
            id: demo-ping
            from:
              uri: direct:start
              steps:
                - log:
                    message: "receive schema authz transform enrich route deliver audit respond"
        """;
    var result = validator.validate(yaml);
    assertThat(result.valid()).isTrue();
  }

  @Test
  void rejectsSecretLiteral() {
    String yaml =
        """
        - route:
            id: bad
            from:
              uri: "http://x?password=secret"
              steps:
                - log: { message: "receive schema authz transform enrich route deliver audit respond" }
        """;
    var result = validator.validate(yaml);
    assertThat(result.valid()).isFalse();
    assertThat(result.findings()).anyMatch(f -> "SECRET".equals(f.code()));
  }

  @Test
  void rejectsBrokenYaml() {
    var result = validator.validate("route: [");
    assertThat(result.valid()).isFalse();
  }

  @Test
  void rejectsMissingRouteShape() {
    var result = validator.validate("foo: bar\n");
    assertThat(result.valid()).isFalse();
    assertThat(result.findings()).anyMatch(f -> "ROUTE_SHAPE".equals(f.code()));
  }

  /* ---------- IP-07 K2-6 / K1-7b ---------- */

  private static final String KAMELET =
      """
      apiVersion: camel.apache.org/v1
      kind: Kamelet
      metadata:
        name: nguon-mau
      spec:
        template:
          from:
            uri: timer:tick
            steps:
              - to:
                  uri: kamelet:sink
      """;

  private static final String PIPE =
      """
      apiVersion: camel.apache.org/v1
      kind: Pipe
      metadata:
        name: ong-mau
      spec:
        source:
          ref:
            kind: Kamelet
            name: timer-source
        sink:
          ref:
            kind: Kamelet
            name: log-sink
      """;

  private static final String ROUTE_THIEU_CHANG =
      """
      - route:
          id: toi-gian
          from:
            uri: direct:start
            steps:
              - log:
                  message: xin chao
      """;

  @Test
  void kameletHopLeKhongBiBatTheoKhungRoute() {
    // Kamelet về cấu trúc không thể có khung chín chặng — bắt theo khung route là báo sai.
    var result = validator.validate(KAMELET, CamelYamlValidator.ResourceKind.KAMELET, false);
    assertThat(result.valid()).isTrue();
    assertThat(result.findings()).noneMatch(f -> "STAGE_META".equals(f.code()));
  }

  @Test
  void pipeHopLeKhongBiBatTheoKhungRoute() {
    var result = validator.validate(PIPE, CamelYamlValidator.ResourceKind.PIPE, false);
    assertThat(result.valid()).isTrue();
    assertThat(result.findings()).noneMatch(f -> "STAGE_META".equals(f.code()));
  }

  @Test
  void kameletThieuSpecTemplateBiTuChoi() {
    String xau =
        """
        apiVersion: camel.apache.org/v1
        kind: Kamelet
        metadata:
          name: thieu
        spec: {}
        """;
    var result = validator.validate(xau, CamelYamlValidator.ResourceKind.KAMELET, false);
    assertThat(result.valid()).isFalse();
    assertThat(result.findings()).anyMatch(f -> "ROUTE_SHAPE".equals(f.code()));
  }

  @Test
  void routeNoiBoThieuChangChiLaCanhBao() {
    var result =
        validator.validate(ROUTE_THIEU_CHANG, CamelYamlValidator.ResourceKind.ROUTE, false);
    assertThat(result.valid()).isTrue();
    assertThat(result.findings()).anyMatch(f -> "STAGE_META".equals(f.code()));
    assertThat(result.findings())
        .filteredOn(f -> "STAGE_META".equals(f.code()))
        .allMatch(f -> "WARN".equals(f.severity()));
  }

  /**
   * K1-7b — trước đây khung chuẩn chỉ phát `WARN` ở mọi trường hợp, mà `publish()` chỉ
   * chặn khi có `ERROR`, nên **không tầng nào** thực sự bắt buộc khung chuẩn. Nay luồng
   * đối ngoại thiếu chặng là chặn thật.
   */
  @Test
  void routeDoiNgoaiThieuChangBiChanThat() {
    var result = validator.validate(ROUTE_THIEU_CHANG, CamelYamlValidator.ResourceKind.ROUTE, true);
    assertThat(result.valid()).isFalse();
    assertThat(result.findings())
        .filteredOn(f -> "STAGE_META".equals(f.code()))
        .allMatch(f -> "ERROR".equals(f.severity()));
  }

  @Test
  void routeDoiNgoaiDuChangVanQuaDuoc() {
    String du =
        """
        - route:
            id: du-chang
            from:
              uri: direct:start
              steps:
                - log:
                    message: "receive schema authz transform enrich route deliver audit respond"
        """;
    assertThat(validator.validate(du, CamelYamlValidator.ResourceKind.ROUTE, true).valid()).isTrue();
  }
}
