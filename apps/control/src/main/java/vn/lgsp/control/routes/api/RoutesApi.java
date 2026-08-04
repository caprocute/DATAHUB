package vn.lgsp.control.routes.api;

import java.util.List;

public interface RoutesApi {

  RouteSummaryDto create(RouteCreateRequest request, String actor);

  List<RouteSummaryDto> list();

  /** Danh sách có lọc/sắp xếp/phân trang **phía máy chủ** (FR-D-001, IP-06 G2-1). */
  RoutePageDto search(RouteQuery query);

  RouteSummaryDto get(String routeCode);

  /* ---------- Thao tác trên một luồng (FR-D-002, IP-06 G2-3) ---------- */

  /** Đổi tên hiển thị; mã luồng giữ nguyên vì là khóa GitOps. */
  RouteSummaryDto rename(String routeCode, RouteRenameRequest request, String actor);

  /** Nhân bản thành luồng nháp mới, không kế thừa vết commit. */
  RouteSummaryDto duplicate(String routeCode, RouteDuplicateRequest request, String actor);

  /** Tạm dừng / kích hoạt lại luồng đang chạy. */
  RouteSummaryDto setPaused(String routeCode, boolean paused, String actor);

  /** Xóa một phiên bản nháp. Chỉ xóa được bản `DRAFT` chưa từng publish. */
  void deleteDraft(String routeCode, int versionNo, String actor);

  /** Lịch sử phiên bản của một luồng (FR-D-004, IP-06 G2-5). */
  List<RouteVersionDto> listVersions(String routeCode);

  /* ---------- Nhật ký chạy thử (FR-D-040/041, IP-06 G5-6/G5-7) ---------- */

  /** Danh sách lần chạy của một luồng, mới nhất trước. */
  List<TestRunSummaryDto> listTestRuns(String routeCode, String outcome, int limit);

  /** Chi tiết một lần chạy kèm waterfall theo chặng. */
  TestRunDetailDto getTestRun(String routeCode, java.util.UUID runId);

  /**
   * Dọn nhật ký chạy quá hạn lưu trữ (FR-D-042).
   *
   * @return số lần chạy đã xóa
   */
  int purgeTestRuns(int retentionDays);

  RouteVersionDto getVersion(String routeCode, int versionNo);

  RouteVersionDto saveDefinition(
      String routeCode, int versionNo, RouteDefinitionUpdate update, String actor);

  ValidationResultDto validate(String definitionYaml);

  RouteVersionDto submit(String routeCode, int versionNo, String actor);

  RouteVersionDto publish(String routeCode, int versionNo, String actor);

  /** Hàng đợi phiên bản PENDING_REVIEW (UI-04-09). */
  List<RouteVersionDto> listPendingReview();

  /**
   * Phê duyệt / trả lại. Bốn mắt: reviewer ≠ người tạo phiên bản. APPROVE → GitOps publish.
   */
  RouteVersionDto review(String routeCode, int versionNo, RouteReviewRequest request, String actor);

  /** WP-25 — chạy thử giả lập đích; không log secret. Kết quả được ghi vào nhật ký. */
  TestRunResultDto testRun(
      String routeCode, int versionNo, TestRunRequest request, String actor);

  String moduleStatus();
}
