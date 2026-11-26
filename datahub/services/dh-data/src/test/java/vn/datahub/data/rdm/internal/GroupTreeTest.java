package vn.datahub.data.rdm.internal;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class GroupTreeTest {

  private final UUID a = UUID.randomUUID();
  private final UUID b = UUID.randomUUID();
  private final UUID c = UUID.randomUUID();
  private final UUID d = UUID.randomUUID();
  private final UUID e = UUID.randomUUID();
  private final UUID f = UUID.randomUUID();

  /** a > b > c > d > e (5 cấp) và f là gốc riêng. */
  private GroupTree chain() {
    Map<UUID, UUID> parents = new HashMap<>();
    parents.put(a, null);
    parents.put(b, a);
    parents.put(c, b);
    parents.put(d, c);
    parents.put(e, d);
    parents.put(f, null);
    return new GroupTree(parents);
  }

  @Test
  @DisplayName("Cấp của nút: gốc là 1, nút chưa có trong cây là 0")
  void depthCountsFromRoot() {
    GroupTree tree = chain();
    assertThat(tree.depth(a)).isEqualTo(1);
    assertThat(tree.depth(e)).isEqualTo(5);
    assertThat(tree.depth(null)).isZero();
    assertThat(tree.depth(UUID.randomUUID())).isZero();
  }

  @Test
  @DisplayName("Chiều cao cây con: lá là 1")
  void heightOfSubtree() {
    GroupTree tree = chain();
    assertThat(tree.height(e)).isEqualTo(1);
    assertThat(tree.height(a)).isEqualTo(5);
    assertThat(tree.height(f)).isEqualTo(1);
  }

  @Test
  @DisplayName("Tạo nhóm mới dưới nút cấp 5 vượt độ sâu, dưới cấp 4 thì được")
  void createDepthLimit() {
    GroupTree tree = chain();
    assertThat(tree.checkCreate(e)).isEqualTo(GroupTree.Violation.DEPTH);
    assertThat(tree.checkCreate(d)).isNull();
    assertThat(tree.checkCreate(null)).isNull();
  }

  @Test
  @DisplayName("Chuyển nhóm vào chính nó hoặc hậu duệ của nó tạo vòng")
  void moveCreatesCycle() {
    GroupTree tree = chain();
    assertThat(tree.checkMove(a, a)).isEqualTo(GroupTree.Violation.CYCLE);
    assertThat(tree.checkMove(a, c)).isEqualTo(GroupTree.Violation.CYCLE);
    assertThat(tree.checkMove(b, e)).isEqualTo(GroupTree.Violation.CYCLE);
  }

  @Test
  @DisplayName("Chuyển cây con làm tổng số cấp vượt 5 thì bị từ chối")
  void moveExceedsDepth() {
    GroupTree tree = chain();
    // f (1 cấp) dưới e (cấp 5) → 6; b (4 cấp) dưới f (cấp 1) → 5 là vừa đủ.
    assertThat(tree.checkMove(f, e)).isEqualTo(GroupTree.Violation.DEPTH);
    assertThat(tree.checkMove(b, f)).isNull();
    assertThat(tree.checkMove(a, null)).isNull();
  }

  @Test
  @DisplayName("Dữ liệu hỏng có vòng sẵn không làm vòng lặp vô hạn")
  void brokenDataDoesNotLoop() {
    Map<UUID, UUID> parents = new HashMap<>();
    parents.put(a, b);
    parents.put(b, a);
    assertThat(new GroupTree(parents).depth(a)).isEqualTo(2);
  }
}
