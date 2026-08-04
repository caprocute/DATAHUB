package vn.lgsp.control.onboarding.api;

import java.time.OffsetDateTime;

/** Kết quả một bước thẩm định (pháp lý hoặc kỹ thuật). */
public record ReviewDto(String status, String reviewedBy, String note, OffsetDateTime reviewedAt) {}
