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
}
