package vn.lgsp.data.rdm.api;

/**
 * Kết quả một phép tra mã trong lời gọi hàng loạt (FR-07-008).
 *
 * <p>Tra hàng loạt **không** hỏng cả lô khi một mã sai: phần tử không tìm thấy trả
 * {@code found = false} kèm {@code item = null}, đúng nhánh E2 của FR-07-008 ("trả kết quả
 * một phần, đánh dấu rõ"). Thứ tự phần tử trả về giữ đúng thứ tự yêu cầu.
 */
public record ResolveResultDto(String maDanhMuc, String maMuc, boolean found, CatalogItemDto item) {}
