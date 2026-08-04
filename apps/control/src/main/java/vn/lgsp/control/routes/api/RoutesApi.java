package vn.lgsp.control.routes.api;

import java.util.List;

public interface RoutesApi {

  RouteSummaryDto create(RouteCreateRequest request, String actor);

  List<RouteSummaryDto> list();

  RouteSummaryDto get(String routeCode);

  RouteVersionDto getVersion(String routeCode, int versionNo);

  RouteVersionDto saveDefinition(String routeCode, int versionNo, RouteDefinitionUpdate update);

  ValidationResultDto validate(String definitionYaml);

  RouteVersionDto submit(String routeCode, int versionNo, String actor);

  RouteVersionDto publish(String routeCode, int versionNo, String actor);

  /** Hàng đợi phiên bản PENDING_REVIEW (UI-04-09). */
  List<RouteVersionDto> listPendingReview();

  /**
   * Phê duyệt / trả lại. Bốn mắt: reviewer ≠ người tạo phiên bản. APPROVE → GitOps publish.
   */
  RouteVersionDto review(String routeCode, int versionNo, RouteReviewRequest request, String actor);

  String moduleStatus();
}
