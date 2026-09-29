package vn.lgsp.data.rdm.api;

import java.time.LocalDate;

/**
 * Tạo phiên bản mới (FR-07-003) — sao chép toàn bộ mục từ phiên bản hiệu lực gần nhất.
 *
 * @param hieuLucTu rỗng thì lấy ngày hôm nay
 * @param canCuBanHanh số và ngày văn bản ban hành
 */
public record CreateVersionRequest(LocalDate hieuLucTu, LocalDate hieuLucDen, String canCuBanHanh) {}
