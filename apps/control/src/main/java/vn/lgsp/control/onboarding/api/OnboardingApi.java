package vn.lgsp.control.onboarding.api;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Hợp đồng công bố — PH-01.
 *
 * Vòng đời hồ sơ:
 *
 * <pre>
 * SUBMITTED → (thẩm định pháp lý + kỹ thuật) → REVIEWED → APPROVED → ACTIVE
 *      │                                          │           │
 *      └──────────── REJECTED ────────────────────┘      SUSPENDED ⇄ ACTIVE
 *                                                             │
 *                                                          REVOKED
 * </pre>
 */
public interface OnboardingApi {

  ApplicationDto submit(ApplicationSubmitRequest request, String submittedBy);

  /** Ghi kết quả thẩm định căn cứ pháp lý (FR-01-004). */
  ApplicationDto reviewLegal(UUID id, ReviewRequest request, String reviewer);

  /** Ghi kết quả thẩm định kỹ thuật (FR-01-005). */
  ApplicationDto reviewTechnical(UUID id, ReviewRequest request, String reviewer);

  /**
   * Phê duyệt kết nạp và cấp danh tính kỹ thuật (FR-01-006, FR-01-008).
   *
   * Chỉ duyệt được khi cả hai bước thẩm định đã đạt, và người duyệt phải khác người
   * nộp hồ sơ (bốn mắt). Bí mật trả về **một lần duy nhất** trong kết quả này.
   */
  ApplicationDto approve(UUID id, String approvedBy);

  /** Từ chối hồ sơ kèm lý do (FR-01-006 E1). */
  ApplicationDto reject(UUID id, String reason, String actor);

  /** Kích hoạt sau khi kiểm thử kết nối đạt (FR-01-010). */
  ApplicationDto activate(UUID id, String actor);

  /** Tạm ngừng thành viên (FR-01-011). */
  ApplicationDto suspend(UUID id, String reason, String actor);

  /** Khôi phục sau tạm ngừng (FR-01-011). */
  ApplicationDto resume(UUID id, String actor);

  /** Thu hồi kết nạp (FR-01-012). */
  ApplicationDto revoke(UUID id, String reason, String actor);

  Optional<ApplicationDto> findById(UUID id);

  /** Trang danh sách có lọc và tìm kiếm phía máy chủ (C4-1). */
  PageDto<ApplicationDto> search(String query, String status, int page, int size);

  /** Nhật ký kiểm toán của một hồ sơ (C4-5). */
  List<AuditEntryDto> auditTrail(UUID id);

  String moduleStatus();
}
