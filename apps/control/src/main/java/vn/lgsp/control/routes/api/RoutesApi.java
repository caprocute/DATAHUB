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

  String moduleStatus();
}
