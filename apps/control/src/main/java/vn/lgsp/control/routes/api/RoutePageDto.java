package vn.lgsp.control.routes.api;

import java.util.List;

/**
 * Một trang danh sách luồng.
 *
 * `total` là **tổng số dòng khớp bộ lọc**, không phải số dòng trả về — giao diện cần
 * con số này để vẽ thanh phân trang cho đúng.
 */
public record RoutePageDto(List<RouteSummaryDto> items, long total, int page, int size) {}
