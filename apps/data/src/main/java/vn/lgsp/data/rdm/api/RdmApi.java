package vn.lgsp.data.rdm.api;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Danh mục dùng chung (PH-07 / WP-31).
 *
 * <p>Đây là <b>giao diện công bố</b> của module {@code rdm}; module khác chỉ được import
 * {@code api/}, không đụng {@code internal/} (luật Modulith, AGENTS.md §4).
 *
 * <p>Phạm vi WP-31 bám đúng DoD IP-04: CRUD danh mục + phiên bản (FR-07-001…004), tra cứu
 * và resolve (FR-07-007…009), seed một danh mục cho route thí điểm. Ánh xạ từ điển quốc
 * gia (FR-07-011…014) và ánh xạ chéo (FR-07-015) <b>không</b> thuộc WP này.
 */
public interface RdmApi {

  String moduleStatus();

  /* ---------- Nhóm A — quản lý (FR-07-001…004) ---------- */

  List<CatalogDto> listCatalogs();

  CatalogDto createCatalog(CreateCatalogRequest request);

  CatalogDto getCatalog(String maDanhMuc);

  List<CatalogVersionDto> listVersions(String maDanhMuc);

  /** Tạo phiên bản mới, sao chép mục từ phiên bản gần nhất (FR-07-003). */
  CatalogVersionDto createVersion(String maDanhMuc, CreateVersionRequest request, String actor);

  /** Thêm/sửa mục trong phiên bản {@code DRAFT} (FR-07-002). */
  CatalogItemDto upsertItem(String maDanhMuc, int soPhienBan, UpsertItemRequest request);

  /** Phát hành phiên bản (FR-07-004) — khép phiên bản đang hiệu lực lại. */
  CatalogVersionDto publishVersion(String maDanhMuc, int soPhienBan, String actor);

  /* ---------- Nhóm B — tra cứu (FR-07-007…009) ---------- */

  /**
   * Tra một mã tại thời điểm tham chiếu (FR-07-007).
   *
   * @param thoiDiem rỗng = hiện tại
   */
  Optional<CatalogItemDto> resolve(String maDanhMuc, String maMuc, LocalDate thoiDiem);

  /** Tra hàng loạt, giữ nguyên thứ tự yêu cầu (FR-07-008). */
  List<ResolveResultDto> resolveBatch(ResolveRequest request);

  /** Toàn bộ mục của phiên bản hiệu lực (FR-07-009). */
  List<CatalogItemDto> listItems(String maDanhMuc, LocalDate thoiDiem, boolean includeDeprecated);
}
