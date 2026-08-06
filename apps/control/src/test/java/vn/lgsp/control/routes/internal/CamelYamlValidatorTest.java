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

  /**
   * K2-2/K2-6 — lối **tạo mới** cũng phải kiểm theo đúng loại tài nguyên.
   *
   * Bắt được khi chạy thật: `create()` gọi overload một tham số (luôn coi là ROUTE) nên
   * tạo Kamelet/Pipe từ mẫu bị trả 422 "thiếu khối route/from". Kiểm theo khung route một
   * loại tài nguyên vốn không có `route:` là sai từ gốc.
   */
  @Test
  void kameletVaPipeKhongBiKiemTheoKhungRouteOLoiTaoMoi() {
    assertThat(validator.validate(KAMELET, CamelYamlValidator.ResourceKind.KAMELET, false).valid())
        .isTrue();
    assertThat(validator.validate(PIPE, CamelYamlValidator.ResourceKind.PIPE, false).valid())
        .isTrue();
    // Và đúng như lỗi đã gặp: kiểm nhầm theo ROUTE thì cả hai đều trượt.
    assertThat(validator.validate(KAMELET, CamelYamlValidator.ResourceKind.ROUTE, false).valid())
        .isFalse();
    assertThat(validator.validate(PIPE, CamelYamlValidator.ResourceKind.ROUTE, false).valid())
        .isFalse();
  }

  /* ---------- IP-07 K5-4 — BR-D-02 ---------- */

  private static String routeWithBean(String propLine) {
    return """
        - beans:
            - name: khoBiMat
              type: vn.lgsp.KhoBiMat
              properties:
        %s
        - route:
            id: r
            from:
              uri: direct:start
              steps:
                - log:
                    message: "receive schema authz transform enrich route deliver audit respond"
        """
        .formatted(propLine);
  }

  @Test
  void chanBiMatGhiThangVaoBean() {
    var r = validator.validate(routeWithBean("        password: matkhau-that"));
    assertThat(r.valid()).isFalse();
    assertThat(r.findings()).anyMatch(f -> "SECRET".equals(f.code()));
  }

  /**
   * Mẫu cũ chặn cả tham chiếu Vault — tức là **cấm đúng cách làm mà BR-D-02 yêu cầu**.
   * Người dùng làm đúng vẫn bị chặn publish thì họ sẽ tìm cách lách, và đó mới là rủi ro thật.
   */
  @Test
  void khongChanThamChieuVaultVaBean() {
    assertThat(validator.validate(routeWithBean("        password: '{{vault:lgsp/db#password}}'")).valid())
        .isTrue();
    assertThat(validator.validate(routeWithBean("        password: '#khoBiMat'")).valid()).isTrue();
    assertThat(validator.validate(routeWithBean("        apiKey: '{{lgsp.api.key}}'")).valid())
        .isTrue();
  }

  /** `token` là khóa bí mật rất thường gặp mà mẫu cũ cho lọt. */
  @Test
  void chanCaTokenChuKhongRiengPassword() {
    for (String key : new String[] {"token", "apiKey", "api_key", "clientSecret", "privateKey"}) {
      var r = validator.validate(routeWithBean("        " + key + ": lo-that"));
      assertThat(r.valid()).as("khóa %s lẽ ra phải bị chặn", key).isFalse();
    }
  }
}
