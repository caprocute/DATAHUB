package vn.lgsp.data.rdm.api;

import java.util.UUID;

/**
 * Một mục (mã) trong phiên bản danh mục (EN-07-03) — cũng là dạng trả của FR-07-007.
 *
 * <p>{@code ngungDung} thay cho xóa (RB-05): hồ sơ cũ tham chiếu mã đã sáp nhập vẫn phải
 * giải mã được. Khi {@code ngungDung = true} thì {@code maThayThe} cho biết dùng mã nào
 * thay — đúng nhánh E2 của FR-07-007.
 */
public record CatalogItemDto(
    UUID mucId,
    String maMuc,
    String ten,
    String tenVietTat,
    String maCha,
    int thuTu,
    String nguonGoc,
    boolean ngungDung,
    String maThayThe,
    int phienBanDanhMuc) {}
