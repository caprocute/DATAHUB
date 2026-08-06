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

  /** Ghi nhận rà soát quyền định kỳ và đặt hạn rà soát kế tiếp (FR-01-013). */
  ApplicationDto recordAccessReview(UUID id, AccessReviewRequest request, String actor);

  /** Hồ sơ tới hạn rà soát quyền — dùng cho danh sách nhắc việc (FR-01-013). */
  List<ApplicationDto> dueForAccessReview();

  /**
   * Mã hệ thống đó đã kết nạp và đang hiệu lực hay chưa (`APPROVED`/`ACTIVE`).
   *
   * PH-04 dùng để biết một luồng có phải **đối ngoại** không: luồng có `source_system`
   * khớp một hệ thống đã kết nạp thì phải đủ khung chuẩn mới publish được (BR-D-01).
   * Trả về qua API mô-đun thay vì cho PH-04 đọc thẳng bảng `ph01.*` — ranh giới
   * Modulith cấm truy cập `internal/` xuyên mô-đun.
   */
  boolean isOnboardedSystem(String systemCode);

  /* ---------- Tệp đính kèm (FR-01-003) ---------- */

  AttachmentDto attach(
      UUID id, String fileName, String contentType, byte[] content, String uploadedBy);

  List<AttachmentDto> attachments(UUID id);

  /** Nội dung tệp để tải về; rỗng nếu không có hoặc không thuộc hồ sơ. */
  Optional<DownloadedFile> download(UUID applicationId, UUID attachmentId);

  /** Tệp đã tải cùng siêu dữ liệu cần cho header HTTP. */
  record DownloadedFile(String fileName, String contentType, byte[] content) {}

  Optional<ApplicationDto> findById(UUID id);

  /** Trang danh sách có lọc và tìm kiếm phía máy chủ (C4-1). */
  PageDto<ApplicationDto> search(String query, String status, int page, int size);

  /** Toàn bộ hồ sơ khớp bộ lọc, không phân trang — dùng để xuất tệp (C4-3). */
  List<ApplicationDto> exportAll(String query, String status);

  /** Nhật ký kiểm toán của một hồ sơ (C4-5). */
  List<AuditEntryDto> auditTrail(UUID id);

  String moduleStatus();
}
