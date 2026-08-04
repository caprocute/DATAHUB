package vn.lgsp.control.routes.internal;

import static org.assertj.core.api.Assertions.assertThat;

import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class GitOpsPublisherTest {

  @TempDir Path temp;

  @Test
  void writesRouteCamelYamlWithoutGitCommit() throws Exception {
    Path routes = temp.resolve("routes");
    Files.createDirectories(routes);
    // repo-like layout for resolveRepoRoot fallback — publisher uses cwd; force absolute dir
    GitOpsPublisher publisher =
        new GitOpsPublisher(routes.toAbsolutePath().toString(), false, "bot", "bot@local");
    String yaml =
        """
        - route:
            id: t
            from:
              uri: direct:x
              steps:
                - log: { message: "receive schema authz transform enrich route deliver audit respond" }
        """;
    var result = publisher.publish("demo-wp23", 1, yaml);
    Path written = routes.resolve("demo-wp23/route.camel.yaml");
    assertThat(written).exists();
    assertThat(Files.readString(written)).contains("routeCode=demo-wp23");
    assertThat(result.gitPath()).contains("demo-wp23");
    assertThat(result.commitRef()).startsWith("file:");
  }
}
