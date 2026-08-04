package vn.lgsp.control.onboarding;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import vn.lgsp.control.onboarding.api.AccessReviewRequest;
import vn.lgsp.control.onboarding.api.ApplicationDto;
import vn.lgsp.control.onboarding.api.ApplicationSubmitRequest;
import vn.lgsp.control.onboarding.api.OnboardingApi;
import vn.lgsp.control.onboarding.api.ReviewRequest;

/** AT khói vòng đời kết nạp PH-01 — cần Postgres DEV. Bật bằng LGSP_IT=1. */
@SpringBootTest
@EnabledIfEnvironmentVariable(named = "LGSP_IT", matches = "1")
class OnboardingSmokeTest {

  @Autowired OnboardingApi onboardingApi;

  private static final String NOP_VIEN = "canbo.nop";
  private static final String THAM_DINH = "canbo.thamdinh";

  private ApplicationDto submitNew() {
    String code = "SYS_" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    return onboardingApi.submit(
        new ApplicationSubmitRequest(
            code,
            "Hệ thống thử",
            "Sở Thử nghiệm",
            "Quyết định 123/QĐ-UBND",
            "Máy chủ ứng dụng, đã có chứng thư số",
            "Nguyễn Văn A",
            "a@example.gov.vn",
            "0900000000"),
        NOP_VIEN);
  }

  private ApplicationDto passBothReviews(ApplicationDto app) {
    onboardingApi.reviewLegal(app.id(), new ReviewRequest(ReviewRequest.Decision.PASS, "đủ căn cứ"), THAM_DINH);
    return onboardingApi.reviewTechnical(
        app.id(), new ReviewRequest(ReviewRequest.Decision.PASS, "đạt"), THAM_DINH);
  }

  @Test
  void nopHoSoRoiThamDinhHaiBuocThiSanSangDuyet() {
    ApplicationDto created = submitNew();
    assertThat(created.status()).isEqualTo("SUBMITTED");
    assertThat(created.submittedBy()).isEqualTo(NOP_VIEN);

    // Thẩm định một bước thì chưa đủ để chuyển sang REVIEWED.
    ApplicationDto afterLegal =
        onboardingApi.reviewLegal(
            created.id(), new ReviewRequest(ReviewRequest.Decision.PASS, "đủ căn cứ"), THAM_DINH);
    assertThat(afterLegal.status()).isEqualTo("SUBMITTED");
    assertThat(afterLegal.legalReview().status()).isEqualTo("PASS");

    ApplicationDto reviewed =
        onboardingApi.reviewTechnical(
            created.id(), new ReviewRequest(ReviewRequest.Decision.PASS, "đạt"), THAM_DINH);
    assertThat(reviewed.status()).isEqualTo("REVIEWED");
  }

  @Test
  void motBuocThamDinhTruotThiHoSoBiTuChoiNgay() {
    ApplicationDto created = submitNew();
    ApplicationDto after =
        onboardingApi.reviewLegal(
            created.id(),
            new ReviewRequest(ReviewRequest.Decision.FAIL, "thiếu quyết định giao nhiệm vụ"),
            THAM_DINH);
    assertThat(after.status()).isEqualTo("REJECTED");
    assertThat(after.statusReason()).contains("pháp lý");
  }

  @Test
  void duyetCapDanhTinhVaTraBiMatDungMotLan() {
    ApplicationDto app = passBothReviews(submitNew());

    ApplicationDto approved = onboardingApi.approve(app.id(), THAM_DINH);
    assertThat(approved.status()).isEqualTo("APPROVED");
    assertThat(approved.clientId()).isNotBlank();
    assertThat(approved.clientSecretSealed()).startsWith("sealed:dev:");

    // Đọc lại không bao giờ thấy bí mật nữa (FR-01-009).
    assertThat(onboardingApi.findById(app.id()).orElseThrow().clientSecretSealed()).isNull();
    assertThat(onboardingApi.search(null, null, 0, 50).items())
        .allSatisfy(a -> assertThat(a.clientSecretSealed()).isNull());
  }

  @Test
  void nguoiNopKhongDuocTuThamDinhHoacTuDuyet() {
    ApplicationDto created = submitNew();

    assertThatThrownBy(
            () ->
                onboardingApi.reviewLegal(
                    created.id(), new ReviewRequest(ReviewRequest.Decision.PASS, "ok"), NOP_VIEN))
        .hasMessageContaining("không được tự");

    ApplicationDto reviewed = passBothReviews(created);
    assertThatThrownBy(() -> onboardingApi.approve(reviewed.id(), NOP_VIEN))
        .hasMessageContaining("không được tự");
  }

  @Test
  void chuaThamDinhDuThiKhongDuyetDuoc() {
    ApplicationDto created = submitNew();
    assertThatThrownBy(() -> onboardingApi.approve(created.id(), THAM_DINH))
        .hasMessageContaining("thẩm định");
  }

  @Test
  void vongDoiThanhVien_kichHoat_tamNgung_khoiPhuc_thuHoi() {
    ApplicationDto app = passBothReviews(submitNew());
    onboardingApi.approve(app.id(), THAM_DINH);

    assertThat(onboardingApi.activate(app.id(), "quantri").status()).isEqualTo("ACTIVE");
    assertThat(onboardingApi.suspend(app.id(), "vi phạm hạn mức", "quantri").status())
        .isEqualTo("SUSPENDED");
    assertThat(onboardingApi.resume(app.id(), "quantri").status()).isEqualTo("ACTIVE");
    assertThat(onboardingApi.revoke(app.id(), "ngừng hợp tác", "quantri").status())
        .isEqualTo("REVOKED");

    // Đã thu hồi thì không quay lại được.
    assertThatThrownBy(() -> onboardingApi.resume(app.id(), "quantri"))
        .isInstanceOf(IllegalStateException.class);
  }

  @Test
  void nhatKyKiemToanGhiDuMoiBuoc() {
    ApplicationDto app = passBothReviews(submitNew());
    onboardingApi.approve(app.id(), THAM_DINH);

    assertThat(onboardingApi.auditTrail(app.id()))
        .extracting("action")
        .contains("SUBMIT", "REVIEW_LEGAL", "REVIEW_TECH", "REVIEWED", "APPROVE");
  }

  @Test
  void dinhKemTepHopLeVaTaiVeDuocNguyenVen() {
    ApplicationDto app = submitNew();
    byte[] noiDung = "%PDF-1.4 hồ sơ năng lực".getBytes(java.nio.charset.StandardCharsets.UTF_8);

    var att =
        onboardingApi.attach(app.id(), "ho so/nang luc.pdf", "application/pdf", noiDung, NOP_VIEN);
    // Tên tệp bị lọc bỏ đường dẫn để không ghi ra ngoài thư mục dự kiến.
    assertThat(att.fileName()).doesNotContain("/");
    assertThat(att.sizeBytes()).isEqualTo(noiDung.length);

    assertThat(onboardingApi.attachments(app.id())).hasSize(1);

    var tai = onboardingApi.download(app.id(), att.id()).orElseThrow();
    assertThat(tai.content()).isEqualTo(noiDung);
  }

  @Test
  void chanTepSaiDinhDangHoacQuaLon() {
    ApplicationDto app = submitNew();

    assertThatThrownBy(
            () -> onboardingApi.attach(app.id(), "x.exe", "application/x-msdownload", new byte[] {1}, NOP_VIEN))
        .hasMessageContaining("định dạng");

    assertThatThrownBy(
            () -> onboardingApi.attach(app.id(), "x.pdf", "application/pdf", new byte[0], NOP_VIEN))
        .hasMessageContaining("rỗng");
  }

  @Test
  void khongTaiDuocTepCuaHoSoKhac() {
    ApplicationDto a = submitNew();
    ApplicationDto b = submitNew();
    var att = onboardingApi.attach(a.id(), "a.pdf", "application/pdf", new byte[] {1, 2}, NOP_VIEN);

    // Đoán đúng id tệp nhưng sai hồ sơ thì vẫn không lấy được.
    assertThat(onboardingApi.download(b.id(), att.id())).isEmpty();
  }

  @Test
  void hoSoDaDuyetKhongNhanThemTep() {
    ApplicationDto app = passBothReviews(submitNew());
    onboardingApi.approve(app.id(), THAM_DINH);

    assertThatThrownBy(
            () -> onboardingApi.attach(app.id(), "x.pdf", "application/pdf", new byte[] {1}, NOP_VIEN))
        .hasMessageContaining("chưa duyệt xong");
  }

  @Test
  void raSoatQuyenDinhKyDatHanKeTiep() {
    ApplicationDto app = passBothReviews(submitNew());
    onboardingApi.approve(app.id(), THAM_DINH);
    onboardingApi.activate(app.id(), "quantri");

    // Chưa rà soát lần nào thì phải nằm trong danh sách tới hạn.
    assertThat(onboardingApi.dueForAccessReview()).extracting("id").contains(app.id());

    onboardingApi.recordAccessReview(app.id(), new AccessReviewRequest("đã rà", 12), "quantri");
    assertThat(onboardingApi.dueForAccessReview()).extracting("id").doesNotContain(app.id());
    assertThat(onboardingApi.auditTrail(app.id())).extracting("action").contains("ACCESS_REVIEW");
  }

  @Test
  void xuatDanhSachTheoDungBoLocDangAp() {
    ApplicationDto created = submitNew();
    var rows = onboardingApi.exportAll(created.systemCode(), null);
    assertThat(rows).extracting("systemCode").containsExactly(created.systemCode());
    // Xuất cũng không kèm bí mật.
    assertThat(rows).allSatisfy(a -> assertThat(a.clientSecretSealed()).isNull());
  }

  @Test
  void timKiemVaLocTheoTrangThaiChayPhiaMayChu() {
    ApplicationDto created = submitNew();

    var found = onboardingApi.search(created.systemCode(), null, 0, 20);
    assertThat(found.items()).extracting("systemCode").contains(created.systemCode());

    var byStatus = onboardingApi.search(null, "SUBMITTED", 0, 20);
    assertThat(byStatus.items()).allSatisfy(a -> assertThat(a.status()).isEqualTo("SUBMITTED"));

    var empty = onboardingApi.search("khong-ton-tai-" + UUID.randomUUID(), null, 0, 20);
    assertThat(empty.items()).isEmpty();
    assertThat(empty.total()).isZero();
  }
}
