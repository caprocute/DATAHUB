package vn.lgsp.control.catalog.api;

import java.util.UUID;

public record ServiceSummaryDto(
    UUID id,
    String serviceCode,
    String title,
    String status,
    String publicPath,
    String routeFile) {}
