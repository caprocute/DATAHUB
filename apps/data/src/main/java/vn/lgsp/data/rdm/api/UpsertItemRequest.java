package vn.lgsp.data.rdm.api;

import jakarta.validation.constraints.NotBlank;

/**
 * Thêm hoặc sửa một mục trong phiên bản đang soạn (FR-07-002).
 *
 * <p>Không có đường xóa: mã đã dùng chỉ được đánh dấu {@code ngungDung} (RB-05).
 */
public record UpsertItemRequest(
    @NotBlank String maMuc,
    @NotBlank String ten,
    String tenVietTat,
    String maCha,
    Integer thuTu,
    String nguonGoc,
    Boolean ngungDung,
    String maThayThe) {}
