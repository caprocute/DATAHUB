package vn.lgsp.control.catalog.api;

import java.util.List;
import java.util.UUID;

/** Hợp đồng công bố — PH-02. */
public interface CatalogApi {

  ServiceSummaryDto register(ServiceRegisterRequest request);

  ServiceSummaryDto publish(UUID id);

  List<ServiceSummaryDto> list();

  String moduleStatus();
}
