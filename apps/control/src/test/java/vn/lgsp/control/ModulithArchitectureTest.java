package vn.lgsp.control;

import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;

class ModulithArchitectureTest {

  @Test
  void verifiesModularStructure() {
    ApplicationModules.of(ControlApplication.class).verify();
  }
}
