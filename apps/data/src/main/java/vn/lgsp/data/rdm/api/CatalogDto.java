package vn.lgsp.data.rdm.api;

import java.util.UUID;

/**
 * Một danh mục dùng chung (EN-07-01).
 *
 * @param nguonGoc {@code NATIONAL} (chỉ đọc, chỉ đồng bộ) · {@code LOCAL} · {@code HYBRID}
 * @param cauTrucMa biểu thức chính quy kiểm mã mục — FR-07-001 bước 2
 * @param phienBanHienTai phiên bản đang hiệu lực; rỗng khi chưa phát hành phiên bản nào
 */
public record CatalogDto(
    UUID danhMucId,
    String maDanhMuc,
    String ten,
    String moTa,
    String donViChuQuan,
    String nguonGoc,
    String cauTrucMa,
    boolean coPhanCap,
    String daiMaDiaPhuong,
    UUID phienBanHienTai) {}
