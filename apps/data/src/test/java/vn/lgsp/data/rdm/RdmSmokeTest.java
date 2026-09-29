package vn.lgsp.data.rdm;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import vn.lgsp.data.rdm.api.CatalogDto;
import vn.lgsp.data.rdm.api.CatalogItemDto;
import vn.lgsp.data.rdm.api.CatalogVersionDto;
import vn.lgsp.data.rdm.api.CreateCatalogRequest;
import vn.lgsp.data.rdm.api.CreateVersionRequest;
import vn.lgsp.data.rdm.api.RdmApi;
import vn.lgsp.data.rdm.api.ResolveRequest;
import vn.lgsp.data.rdm.api.ResolveResultDto;
import vn.lgsp.data.rdm.api.UpsertItemRequest;

/**
 * AT khói PH-07 RDM (WP-31) — cần Postgres DEV. Bật bằng {@code LGSP_IT=1}.
 *
 * <p>Theo đúng lối của {@code OnboardingSmokeTest}: test đụng CSDL không chạy mặc định để
 * {@code mvn test} trên máy sạch vẫn xanh, nhưng có đường chạy thật khi cần nghiệm thu.
 */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "LGSP_IT", matches = "1")
class RdmSmokeTest {

  @Autowired RdmApi rdmApi;

  private static final String ACTOR = "canbo.dulieu";

  private String newCatalogCode() {
    return "TEST_" + UUID.randomUUID().toString().substring(0, 8).toUpperCase().replace("-", "");
  }

  private CatalogDto createLocalCatalog(String code) {
    return rdmApi.createCatalog(
        new CreateCatalogRequest(
            code,
            "Danh mục thử " + code,
            "Danh mục dựng trong AT khói WP-31",
            "Sở Thử nghiệm",
            "LOCAL",
            "^[0-9]{2}$",
            false,
            null));
  }

  /* ---------- seed ---------- */

  @Test
  void seedDvhcTraCuuDuoc() {
    // DoD WP-31 mục 4: seed một danh mục dùng cho route thí điểm.
    CatalogItemDto hanoi = rdmApi.resolve("DVHC", "01", null).orElseThrow();
    assertThat(hanoi.ten()).isEqualTo("Thành phố Hà Nội");
    assertThat(hanoi.ngungDung()).isFalse();
  }

  @Test
  void maNgungDungVanTraDuocVaChiRaMaThayThe() {
    // RB-05 + FR-07-007 E2: không xóa mã đã dùng — hồ sơ cũ vẫn phải giải mã được,
    // và phải biết dùng mã nào thay.
    CatalogItemDto haTay = rdmApi.resolve("DVHC", "02", null).orElseThrow();
    assertThat(haTay.ngungDung()).isTrue();
    assertThat(haTay.maThayThe()).isEqualTo("01");

    // Mặc định danh sách không kèm mã đã ngừng…
    assertThat(rdmApi.listItems("DVHC", null, false))
        .extracting(CatalogItemDto::maMuc)
        .doesNotContain("02");
    // …nhưng hỏi thì phải có.
    assertThat(rdmApi.listItems("DVHC", null, true))
        .extracting(CatalogItemDto::maMuc)
        .contains("02");
  }

  /* ---------- tra hàng loạt ---------- */

  @Test
  void traHangLoatGiuThuTuVaDanhDauPhanTuKhongThay() {
    // FR-07-008 E2: một mã sai không được làm hỏng cả lô.
    List<ResolveResultDto> out =
        rdmApi.resolveBatch(
            new ResolveRequest(
                List.of(
                    new ResolveRequest.Entry("DVHC", "01"),
                    new ResolveRequest.Entry("DVHC", "KHONG_CO"),
                    new ResolveRequest.Entry("DVHC", "48")),
                null));

    assertThat(out).hasSize(3);
    assertThat(out.get(0).found()).isTrue();
    assertThat(out.get(1).found()).isFalse();
    assertThat(out.get(1).item()).isNull();
    assertThat(out.get(2).found()).isTrue();
    assertThat(out.get(2).item().ten()).isEqualTo("Thành phố Đà Nẵng");
  }

  /* ---------- vòng đời phiên bản ---------- */

  @Test
  void vongDoiPhienBan_taoSuaPhatHanh() {
    String code = newCatalogCode();
    createLocalCatalog(code);

    CatalogVersionDto v1 =
        rdmApi.createVersion(code, new CreateVersionRequest(LocalDate.now(), null, "QĐ thử"), ACTOR);
    assertThat(v1.soPhienBan()).isEqualTo(1);
    assertThat(v1.trangThai()).isEqualTo("DRAFT");

    rdmApi.upsertItem(
        code, 1, new UpsertItemRequest("10", "Mục mười", "M10", null, 1, "LOCAL", false, null));

    // Chưa phát hành thì tra cứu không thấy — chỉ phiên bản PUBLISHED mới phục vụ tra cứu.
    assertThat(rdmApi.resolve(code, "10", null)).isEmpty();

    rdmApi.publishVersion(code, 1, ACTOR);
    assertThat(rdmApi.resolve(code, "10", null).orElseThrow().ten()).isEqualTo("Mục mười");
  }

  @Test
  void phienBanMoiSaoChepMucCuVaKhepPhienBanCu() {
    String code = newCatalogCode();
    createLocalCatalog(code);
    rdmApi.createVersion(code, new CreateVersionRequest(LocalDate.now().minusDays(10), null, null), ACTOR);
    rdmApi.upsertItem(
        code, 1, new UpsertItemRequest("10", "Mục mười", null, null, 1, "LOCAL", false, null));
    rdmApi.publishVersion(code, 1, ACTOR);

    // FR-07-003 bước 1: phiên bản mới kế thừa toàn bộ mục, không bắt gõ lại.
    CatalogVersionDto v2 =
        rdmApi.createVersion(code, new CreateVersionRequest(LocalDate.now(), null, null), ACTOR);
    assertThat(v2.soPhienBan()).isEqualTo(2);
    assertThat(v2.soMuc()).isEqualTo(1);

    rdmApi.upsertItem(
        code, 2, new UpsertItemRequest("20", "Mục hai mươi", null, null, 2, "LOCAL", false, null));
    rdmApi.publishVersion(code, 2, ACTOR);

    // Sau khi phát hành v2, tra hiện tại phải ra v2 và thấy cả mã mới.
    assertThat(rdmApi.resolve(code, "20", null)).isPresent();
    assertThat(rdmApi.resolve(code, "10", null).orElseThrow().phienBanDanhMuc()).isEqualTo(2);
  }

  @Test
  void traCuuTheoThoiDiemDungPhienBanCuaThoiDiemDo() {
    // FR-07-007 bước 4 — năng lực hay bị bỏ sót: xử lý lại hồ sơ cũ phải dùng danh mục
    // hiệu lực **lúc đó**, không phải danh mục hôm nay.
    String code = newCatalogCode();
    createLocalCatalog(code);
    LocalDate xua = LocalDate.now().minusYears(3);

    rdmApi.createVersion(code, new CreateVersionRequest(xua, null, null), ACTOR);
    rdmApi.upsertItem(
        code, 1, new UpsertItemRequest("10", "Tên cũ", null, null, 1, "LOCAL", false, null));
    rdmApi.publishVersion(code, 1, ACTOR);

    rdmApi.createVersion(code, new CreateVersionRequest(LocalDate.now(), null, null), ACTOR);
    rdmApi.upsertItem(
        code, 2, new UpsertItemRequest("10", "Tên mới", null, null, 1, "LOCAL", false, null));
    rdmApi.publishVersion(code, 2, ACTOR);

    assertThat(rdmApi.resolve(code, "10", null).orElseThrow().ten()).isEqualTo("Tên mới");
    assertThat(rdmApi.resolve(code, "10", xua.plusDays(1)).orElseThrow().ten()).isEqualTo("Tên cũ");
  }

  /* ---------- ràng buộc ---------- */

  @Test
  void danhMucNguonQuocGiaKhongSuaTay() {
    // FR-07-002 E1 — DVHC seed là NATIONAL.
    rdmApi.createVersion("DVHC", new CreateVersionRequest(LocalDate.now(), null, null), ACTOR);
    assertThatThrownBy(
            () ->
                rdmApi.upsertItem(
                    "DVHC",
                    2,
                    new UpsertItemRequest("99", "Tỉnh bịa", null, null, 99, "LOCAL", false, null)))
        .hasMessageContaining("NATIONAL");
  }

  @Test
  void maMucKhongKhopCauTrucThiTuChoi() {
    String code = newCatalogCode();
    createLocalCatalog(code); // cấu trúc ^[0-9]{2}$
    rdmApi.createVersion(code, new CreateVersionRequest(LocalDate.now(), null, null), ACTOR);
    assertThatThrownBy(
            () ->
                rdmApi.upsertItem(
                    code,
                    1,
                    new UpsertItemRequest("ABC", "Sai cấu trúc", null, null, 1, "LOCAL", false, null)))
        .hasMessageContaining("không khớp cấu trúc");
  }

  @Test
  void maDanhMucTrungThiBaoXungDot() {
    String code = newCatalogCode();
    createLocalCatalog(code);
    assertThatThrownBy(() -> createLocalCatalog(code)).hasMessageContaining("đã tồn tại");
  }

  @Test
  void khongSuaDuocPhienBanDaPhatHanh() {
    String code = newCatalogCode();
    createLocalCatalog(code);
    rdmApi.createVersion(code, new CreateVersionRequest(LocalDate.now(), null, null), ACTOR);
    rdmApi.upsertItem(
        code, 1, new UpsertItemRequest("10", "Mục mười", null, null, 1, "LOCAL", false, null));
    rdmApi.publishVersion(code, 1, ACTOR);

    assertThatThrownBy(
            () ->
                rdmApi.upsertItem(
                    code, 1, new UpsertItemRequest("11", "Thêm sau", null, null, 2, "LOCAL", false, null)))
        .hasMessageContaining("DRAFT");
  }
}
