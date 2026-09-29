package vn.lgsp.data.rdm.internal;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.lgsp.data.rdm.api.CatalogDto;
import vn.lgsp.data.rdm.api.CatalogItemDto;
import vn.lgsp.data.rdm.api.CatalogVersionDto;
import vn.lgsp.data.rdm.api.CreateCatalogRequest;
import vn.lgsp.data.rdm.api.CreateVersionRequest;
import vn.lgsp.data.rdm.api.RdmApi;
import vn.lgsp.data.rdm.api.ResolveRequest;
import vn.lgsp.data.rdm.api.ResolveResultDto;
import vn.lgsp.data.rdm.api.UpsertItemRequest;

/** Hiện thực PH-07 RDM (WP-31). Bảng ở schema {@code ph07}. */
@Service
class RdmService implements RdmApi {

  /** Trần của một lần tra hàng loạt (FR-07-008 E1). */
  static final int BATCH_LIMIT = 500;

  private static final RowMapper<CatalogDto> CATALOG_MAPPER =
      (rs, i) ->
          new CatalogDto(
              rs.getObject("danh_muc_id", UUID.class),
              rs.getString("ma_danh_muc"),
              rs.getString("ten"),
              rs.getString("mo_ta"),
              rs.getString("don_vi_chu_quan"),
              rs.getString("nguon_goc"),
              rs.getString("cau_truc_ma"),
              rs.getBoolean("co_phan_cap"),
              rs.getString("dai_ma_dia_phuong"),
              rs.getObject("phien_ban_hien_tai", UUID.class));

  private static final RowMapper<CatalogVersionDto> VERSION_MAPPER =
      (rs, i) ->
          new CatalogVersionDto(
              rs.getObject("phien_ban_id", UUID.class),
              rs.getObject("danh_muc_id", UUID.class),
              rs.getInt("so_phien_ban"),
              rs.getObject("hieu_luc_tu", LocalDate.class),
              rs.getObject("hieu_luc_den", LocalDate.class),
              rs.getString("trang_thai"),
              rs.getString("can_cu_ban_hanh"),
              rs.getString("nguoi_soan"),
              rs.getString("nguoi_duyet"),
              rs.getInt("so_muc"));

  private final JdbcTemplate jdbc;

  RdmService(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public String moduleStatus() {
    return "ok";
  }

  /* ---------- Nhóm A — quản lý ---------- */

  @Override
  public List<CatalogDto> listCatalogs() {
    return jdbc.query(
        "SELECT * FROM ph07.danh_muc ORDER BY ma_danh_muc", CATALOG_MAPPER);
  }

  @Override
  @Transactional
  public CatalogDto createCatalog(CreateCatalogRequest request) {
    if (!List.of("NATIONAL", "LOCAL", "HYBRID").contains(request.nguonGoc())) {
      throw new RdmValidationException("nguonGoc phải là NATIONAL, LOCAL hoặc HYBRID");
    }
    // Cấu trúc mã là biểu thức chính quy sẽ dùng để kiểm mọi mã mục về sau (FR-07-001 bước 2).
    // Biểu thức hỏng mà lọt vào CSDL thì mọi lần thêm mục sau đó đều nổ ở chỗ khó lần ra.
    try {
      Pattern.compile(request.cauTrucMa());
    } catch (PatternSyntaxException e) {
      throw new RdmValidationException("cauTrucMa không phải biểu thức chính quy hợp lệ");
    }
    Integer existing =
        jdbc.queryForObject(
            "SELECT count(*) FROM ph07.danh_muc WHERE ma_danh_muc = ?",
            Integer.class,
            request.maDanhMuc());
    if (existing != null && existing > 0) {
      throw new RdmConflictException("mã danh mục đã tồn tại: " + request.maDanhMuc());
    }
    UUID id = UUID.randomUUID();
    jdbc.update(
        """
        INSERT INTO ph07.danh_muc
          (danh_muc_id, ma_danh_muc, ten, mo_ta, don_vi_chu_quan, nguon_goc,
           cau_truc_ma, co_phan_cap, dai_ma_dia_phuong, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        id,
        request.maDanhMuc(),
        request.ten(),
        request.moTa(),
        request.donViChuQuan(),
        request.nguonGoc(),
        request.cauTrucMa(),
        request.coPhanCap(),
        request.daiMaDiaPhuong(),
        OffsetDateTime.now());
    return getCatalog(request.maDanhMuc());
  }

  @Override
  public CatalogDto getCatalog(String maDanhMuc) {
    try {
      return jdbc.queryForObject(
          "SELECT * FROM ph07.danh_muc WHERE ma_danh_muc = ?", CATALOG_MAPPER, maDanhMuc);
    } catch (EmptyResultDataAccessException e) {
      throw new RdmNotFoundException("không có danh mục: " + maDanhMuc);
    }
  }

  @Override
  public List<CatalogVersionDto> listVersions(String maDanhMuc) {
    CatalogDto catalog = getCatalog(maDanhMuc);
    return jdbc.query(
        "SELECT * FROM ph07.danh_muc_phien_ban WHERE danh_muc_id = ? ORDER BY so_phien_ban DESC",
        VERSION_MAPPER,
        catalog.danhMucId());
  }

  @Override
  @Transactional
  public CatalogVersionDto createVersion(
      String maDanhMuc, CreateVersionRequest request, String actor) {
    CatalogDto catalog = getCatalog(maDanhMuc);
    LocalDate from = request.hieuLucTu() != null ? request.hieuLucTu() : LocalDate.now();
    if (request.hieuLucDen() != null && request.hieuLucDen().isBefore(from)) {
      throw new RdmValidationException("hieuLucDen sớm hơn hieuLucTu");
    }
    Integer maxVersion =
        jdbc.queryForObject(
            "SELECT coalesce(max(so_phien_ban), 0) FROM ph07.danh_muc_phien_ban WHERE danh_muc_id = ?",
            Integer.class,
            catalog.danhMucId());
    int next = (maxVersion == null ? 0 : maxVersion) + 1;

    UUID versionId = UUID.randomUUID();
    jdbc.update(
        """
        INSERT INTO ph07.danh_muc_phien_ban
          (phien_ban_id, danh_muc_id, so_phien_ban, hieu_luc_tu, hieu_luc_den, trang_thai,
           can_cu_ban_hanh, nguoi_soan, so_muc, created_at)
        VALUES (?, ?, ?, ?, ?, 'DRAFT', ?, ?, 0, ?)
        """,
        versionId,
        catalog.danhMucId(),
        next,
        from,
        request.hieuLucDen(),
        request.canCuBanHanh(),
        actor,
        OffsetDateTime.now());

    // Sao chép mục từ phiên bản gần nhất (FR-07-003 bước 1). Không sao chép thì cán bộ
    // phải gõ lại toàn bộ danh mục chỉ để sửa một mã — với DVHC là 63 dòng.
    findLatestVersionId(catalog.danhMucId(), next)
        .ifPresent(
            prev ->
                jdbc.update(
                    """
                    INSERT INTO ph07.muc_danh_muc
                      (muc_id, phien_ban_id, ma_muc, ten, ten_viet_tat, ten_khong_dau,
                       thu_tu, nguon_goc, ngung_dung, ma_thay_the, thuoc_tinh)
                    SELECT gen_random_uuid(), ?, ma_muc, ten, ten_viet_tat, ten_khong_dau,
                           thu_tu, nguon_goc, ngung_dung, ma_thay_the, thuoc_tinh
                    FROM ph07.muc_danh_muc WHERE phien_ban_id = ?
                    """,
                    versionId,
                    prev));
    refreshItemCount(versionId);
    return findVersion(catalog.danhMucId(), next);
  }

  @Override
  @Transactional
  public CatalogItemDto upsertItem(String maDanhMuc, int soPhienBan, UpsertItemRequest request) {
    CatalogDto catalog = getCatalog(maDanhMuc);
    CatalogVersionDto version = findVersion(catalog.danhMucId(), soPhienBan);
    if (!"DRAFT".equals(version.trangThai())) {
      throw new RdmConflictException(
          "chỉ sửa được phiên bản DRAFT; phiên bản này đang " + version.trangThai());
    }
    // Danh mục nguồn quốc gia không cho sửa thủ công (FR-07-002 E1) — chỉ đồng bộ.
    if ("NATIONAL".equals(catalog.nguonGoc())) {
      throw new RdmForbiddenException(
          "danh mục nguồn NATIONAL chỉ đồng bộ, không sửa tay: " + maDanhMuc);
    }
    if (!Pattern.compile(catalog.cauTrucMa()).matcher(request.maMuc()).matches()) {
      throw new RdmValidationException(
          "mã mục '" + request.maMuc() + "' không khớp cấu trúc " + catalog.cauTrucMa());
    }
    UUID parentId = resolveParent(version.phienBanId(), request.maCha());

    String tenKhongDau = boDau(request.ten());
    boolean ngungDung = Boolean.TRUE.equals(request.ngungDung());
    String nguonGoc = request.nguonGoc() != null ? request.nguonGoc() : "LOCAL";
    int thuTu = request.thuTu() != null ? request.thuTu() : 0;

    // upsert theo (phien_ban_id, ma_muc) — trùng khớp ràng buộc UNIQUE của bảng.
    jdbc.update(
        """
        INSERT INTO ph07.muc_danh_muc
          (muc_id, phien_ban_id, ma_muc, ten, ten_viet_tat, ten_khong_dau,
           ma_cha_id, thu_tu, nguon_goc, ngung_dung, ma_thay_the)
        VALUES (gen_random_uuid(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT (phien_ban_id, ma_muc) DO UPDATE SET
          ten = excluded.ten,
          ten_viet_tat = excluded.ten_viet_tat,
          ten_khong_dau = excluded.ten_khong_dau,
          ma_cha_id = excluded.ma_cha_id,
          thu_tu = excluded.thu_tu,
          nguon_goc = excluded.nguon_goc,
          ngung_dung = excluded.ngung_dung,
          ma_thay_the = excluded.ma_thay_the
        """,
        version.phienBanId(),
        request.maMuc(),
        request.ten(),
        request.tenVietTat(),
        tenKhongDau,
        parentId,
        thuTu,
        nguonGoc,
        ngungDung,
        request.maThayThe());
    refreshItemCount(version.phienBanId());
    return findItem(version.phienBanId(), request.maMuc(), soPhienBan);
  }

  @Override
  @Transactional
  public CatalogVersionDto publishVersion(String maDanhMuc, int soPhienBan, String actor) {
    CatalogDto catalog = getCatalog(maDanhMuc);
    CatalogVersionDto version = findVersion(catalog.danhMucId(), soPhienBan);
    if ("PUBLISHED".equals(version.trangThai())) {
      return version;
    }
    if (!"DRAFT".equals(version.trangThai()) && !"PENDING_APPROVAL".equals(version.trangThai())) {
      throw new RdmConflictException("không phát hành được từ trạng thái " + version.trangThai());
    }
    // Kiểm toàn vẹn phân cấp trước khi phát hành (FR-07-004 bước 1). Vòng lặp cha-con lọt
    // vào bản PUBLISHED sẽ làm mọi lần dựng cây sau đó treo.
    assertNoCycle(version.phienBanId());

    // Khép phiên bản đang hiệu lực lại để khoảng hiệu lực không chồng lấn (EN-07-02) —
    // điều kiện để tra theo thời điểm cho đúng một kết quả.
    jdbc.update(
        """
        UPDATE ph07.danh_muc_phien_ban
           SET hieu_luc_den = ?, trang_thai = 'SUPERSEDED'
         WHERE danh_muc_id = ? AND trang_thai = 'PUBLISHED'
           AND phien_ban_id <> ? AND (hieu_luc_den IS NULL OR hieu_luc_den >= ?)
        """,
        version.hieuLucTu().minusDays(1),
        catalog.danhMucId(),
        version.phienBanId(),
        version.hieuLucTu());

    jdbc.update(
        """
        UPDATE ph07.danh_muc_phien_ban
           SET trang_thai = 'PUBLISHED', nguoi_duyet = ?, phat_hanh_luc = ?
         WHERE phien_ban_id = ?
        """,
        actor,
        OffsetDateTime.now(),
        version.phienBanId());
    jdbc.update(
        "UPDATE ph07.danh_muc SET phien_ban_hien_tai = ? WHERE danh_muc_id = ?",
        version.phienBanId(),
        catalog.danhMucId());
    return findVersion(catalog.danhMucId(), soPhienBan);
  }

  /* ---------- Nhóm B — tra cứu ---------- */

  @Override
  public Optional<CatalogItemDto> resolve(String maDanhMuc, String maMuc, LocalDate thoiDiem) {
    LocalDate at = thoiDiem != null ? thoiDiem : LocalDate.now();
    List<CatalogItemDto> found =
        jdbc.query(
            """
            SELECT m.muc_id, m.ma_muc, m.ten, m.ten_viet_tat, m.thu_tu, m.nguon_goc,
                   m.ngung_dung, m.ma_thay_the, v.so_phien_ban,
                   (SELECT c.ma_muc FROM ph07.muc_danh_muc c WHERE c.muc_id = m.ma_cha_id) AS ma_cha
              FROM ph07.muc_danh_muc m
              JOIN ph07.danh_muc_phien_ban v ON v.phien_ban_id = m.phien_ban_id
              JOIN ph07.danh_muc d ON d.danh_muc_id = v.danh_muc_id
             WHERE d.ma_danh_muc = ? AND m.ma_muc = ?
               AND v.trang_thai = 'PUBLISHED'
               AND v.hieu_luc_tu <= ?
               AND (v.hieu_luc_den IS NULL OR v.hieu_luc_den >= ?)
             ORDER BY v.so_phien_ban DESC
             LIMIT 1
            """,
            ITEM_MAPPER,
            maDanhMuc,
            maMuc,
            at,
            at);
    return found.stream().findFirst();
  }

  @Override
  public List<ResolveResultDto> resolveBatch(ResolveRequest request) {
    List<ResolveRequest.Entry> entries =
        request.items() == null ? List.of() : request.items();
    if (entries.size() > BATCH_LIMIT) {
      throw new RdmTooLargeException(
          "tra hàng loạt tối đa " + BATCH_LIMIT + " phần tử, nhận " + entries.size());
    }
    List<ResolveResultDto> out = new ArrayList<>(entries.size());
    for (ResolveRequest.Entry e : entries) {
      // Giữ đúng thứ tự yêu cầu và không bỏ phần tử nào: bên gọi ghép kết quả theo chỉ số.
      CatalogItemDto item = resolve(e.maDanhMuc(), e.maMuc(), request.thoiDiem()).orElse(null);
      out.add(new ResolveResultDto(e.maDanhMuc(), e.maMuc(), item != null, item));
    }
    return out;
  }

  @Override
  public List<CatalogItemDto> listItems(
      String maDanhMuc, LocalDate thoiDiem, boolean includeDeprecated) {
    LocalDate at = thoiDiem != null ? thoiDiem : LocalDate.now();
    return jdbc.query(
        """
        SELECT m.muc_id, m.ma_muc, m.ten, m.ten_viet_tat, m.thu_tu, m.nguon_goc,
               m.ngung_dung, m.ma_thay_the, v.so_phien_ban,
               (SELECT c.ma_muc FROM ph07.muc_danh_muc c WHERE c.muc_id = m.ma_cha_id) AS ma_cha
          FROM ph07.muc_danh_muc m
          JOIN ph07.danh_muc_phien_ban v ON v.phien_ban_id = m.phien_ban_id
          JOIN ph07.danh_muc d ON d.danh_muc_id = v.danh_muc_id
         WHERE d.ma_danh_muc = ?
           AND v.trang_thai = 'PUBLISHED'
           AND v.hieu_luc_tu <= ?
           AND (v.hieu_luc_den IS NULL OR v.hieu_luc_den >= ?)
           AND (? OR m.ngung_dung = false)
         ORDER BY m.thu_tu, m.ma_muc
        """,
        ITEM_MAPPER,
        maDanhMuc,
        at,
        at,
        includeDeprecated);
  }

  /* ---------- nội bộ ---------- */

  private static final RowMapper<CatalogItemDto> ITEM_MAPPER =
      (rs, i) ->
          new CatalogItemDto(
              rs.getObject("muc_id", UUID.class),
              rs.getString("ma_muc"),
              rs.getString("ten"),
              rs.getString("ten_viet_tat"),
              rs.getString("ma_cha"),
              rs.getInt("thu_tu"),
              rs.getString("nguon_goc"),
              rs.getBoolean("ngung_dung"),
              rs.getString("ma_thay_the"),
              rs.getInt("so_phien_ban"));

  private Optional<UUID> findLatestVersionId(UUID catalogId, int below) {
    return jdbc
        .query(
            """
            SELECT phien_ban_id FROM ph07.danh_muc_phien_ban
             WHERE danh_muc_id = ? AND so_phien_ban < ?
             ORDER BY so_phien_ban DESC LIMIT 1
            """,
            (rs, i) -> rs.getObject("phien_ban_id", UUID.class),
            catalogId,
            below)
        .stream()
        .findFirst();
  }

  private CatalogVersionDto findVersion(UUID catalogId, int soPhienBan) {
    try {
      return jdbc.queryForObject(
          "SELECT * FROM ph07.danh_muc_phien_ban WHERE danh_muc_id = ? AND so_phien_ban = ?",
          VERSION_MAPPER,
          catalogId,
          soPhienBan);
    } catch (EmptyResultDataAccessException e) {
      throw new RdmNotFoundException("không có phiên bản " + soPhienBan);
    }
  }

  private CatalogItemDto findItem(UUID versionId, String maMuc, int soPhienBan) {
    return jdbc.queryForObject(
        """
        SELECT m.muc_id, m.ma_muc, m.ten, m.ten_viet_tat, m.thu_tu, m.nguon_goc,
               m.ngung_dung, m.ma_thay_the, ? AS so_phien_ban,
               (SELECT c.ma_muc FROM ph07.muc_danh_muc c WHERE c.muc_id = m.ma_cha_id) AS ma_cha
          FROM ph07.muc_danh_muc m WHERE m.phien_ban_id = ? AND m.ma_muc = ?
        """,
        ITEM_MAPPER,
        soPhienBan,
        versionId,
        maMuc);
  }

  private UUID resolveParent(UUID versionId, String maCha) {
    if (maCha == null || maCha.isBlank()) {
      return null;
    }
    List<UUID> parent =
        jdbc.query(
            "SELECT muc_id FROM ph07.muc_danh_muc WHERE phien_ban_id = ? AND ma_muc = ?",
            (rs, i) -> rs.getObject("muc_id", UUID.class),
            versionId,
            maCha);
    if (parent.isEmpty()) {
      throw new RdmValidationException("mã cha không tồn tại trong phiên bản: " + maCha);
    }
    return parent.get(0);
  }

  private void refreshItemCount(UUID versionId) {
    jdbc.update(
        """
        UPDATE ph07.danh_muc_phien_ban SET so_muc =
          (SELECT count(*) FROM ph07.muc_danh_muc WHERE phien_ban_id = ?)
        WHERE phien_ban_id = ?
        """,
        versionId,
        versionId);
  }

  /**
   * Chặn vòng lặp cha-con trước khi phát hành (FR-07-004 bước 1, FR-07-002 E3).
   *
   * <p>Dùng truy vấn đệ quy có mốc dừng: PostgreSQL sẽ **treo** trên `WITH RECURSIVE` nếu
   * dữ liệu có vòng, nên phải chặn bằng `cycle` clause thay vì để CSDL tự phát hiện.
   */
  private void assertNoCycle(UUID versionId) {
    List<String> cycles =
        jdbc.query(
            """
            WITH RECURSIVE walk(muc_id, ma_muc, ma_cha_id, depth) AS (
              SELECT muc_id, ma_muc, ma_cha_id, 1 FROM ph07.muc_danh_muc WHERE phien_ban_id = ?
              UNION ALL
              SELECT w.muc_id, w.ma_muc, m.ma_cha_id, w.depth + 1
                FROM walk w JOIN ph07.muc_danh_muc m ON m.muc_id = w.ma_cha_id
               WHERE w.depth < 64
            )
            SELECT DISTINCT ma_muc FROM walk WHERE muc_id = ma_cha_id OR depth >= 64
            """,
            (rs, i) -> rs.getString("ma_muc"),
            versionId);
    if (!cycles.isEmpty()) {
      throw new RdmValidationException("phát hiện vòng lặp phân cấp ở mã: " + cycles);
    }
  }

  /**
   * Bỏ dấu tiếng Việt để tìm kiếm không dấu (EN-07-03, FR-07-010).
   *
   * <p>Dùng {@code Normalizer} NFD rồi bỏ dấu phụ; riêng `đ`/`Đ` không phải dấu phụ
   * Unicode nên phải thay tay — thiếu bước này thì "Đà Nẵng" ra "a nang", gõ "da nang"
   * không tìm được.
   */
  static String boDau(String s) {
    if (s == null) {
      return "";
    }
    String norm = java.text.Normalizer.normalize(s, java.text.Normalizer.Form.NFD);
    return norm.replaceAll("\\p{InCombiningDiacriticalMarks}+", "")
        .replace('đ', 'd')
        .replace('Đ', 'D')
        .toLowerCase(Locale.ROOT);
  }
}
