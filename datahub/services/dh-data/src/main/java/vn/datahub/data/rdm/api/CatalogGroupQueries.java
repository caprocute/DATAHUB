package vn.datahub.data.rdm.api;

import java.util.List;

/** Truy vấn nhóm danh mục cho module khác trong DU (đồng bộ, chỉ đọc). */
public interface CatalogGroupQueries {

  /** Rừng nhóm (SS-07-10): nhóm gốc của tenant và COMMON ở cấp 1, con lồng trong {@code children}. */
  List<CatalogGroupView> tree();

  /** Danh sách phẳng, mỗi phần tử có {@code parentId}, {@code children} rỗng. */
  List<CatalogGroupView> flat();
}
