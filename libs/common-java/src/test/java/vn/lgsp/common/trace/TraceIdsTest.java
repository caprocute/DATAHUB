package vn.lgsp.common.trace;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class TraceIdsTest {

  @Test
  void parsesTraceparent() {
    var tp = "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01";
    assertEquals(
        "4bf92f3577b34da6a3ce929d0e0e4736", TraceIds.fromTraceparent(tp).orElseThrow());
  }

  @Test
  void newIdHas32Hex() {
    assertTrue(TraceIds.newId().matches("[0-9a-f]{32}"));
  }
}
