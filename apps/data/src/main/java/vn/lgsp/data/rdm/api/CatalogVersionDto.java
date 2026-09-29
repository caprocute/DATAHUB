package vn.lgsp.data.rdm.api;

import java.time.LocalDate;
import java.util.UUID;

/**
 * Phiên bản của một danh mục (EN-07-02).
 *
 * <p>{@code hieuLucDen} rỗng nghĩa là còn hiệu lực. Khoảng {@code [hieuLucTu, hieuLucDen]}
 * của các phiên bản {@code PUBLISHED} cùng danh mục không được chồng lấn — điều kiện để
 * tra cứu theo thời điểm (FR-07-007 bước 4) cho kết quả xác định.
 */
public record CatalogVersionDto(
    UUID phienBanId,
    UUID danhMucId,
    int soPhienBan,
    LocalDate hieuLucTu,
    LocalDate hieuLucDen,
    String trangThai,
    String canCuBanHanh,
    String nguoiSoan,
    String nguoiDuyet,
    int soMuc) {}
