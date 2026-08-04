package vn.lgsp.control.onboarding.internal;

/**
 * Vi phạm luật bốn mắt: người nộp hồ sơ tự thẩm định / duyệt hồ sơ của mình.
 *
 * Tách riêng khỏi `IllegalStateException` để controller trả 403 thay vì 409 — đây là
 * vấn đề thẩm quyền, không phải trạng thái hồ sơ.
 */
class SelfReviewException extends RuntimeException {

  SelfReviewException(String message) {
    super(message);
  }
}
