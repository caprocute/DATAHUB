/**
 * Nhân dùng chung của DU dh-data (không phải module nghiệp vụ): bảo mật, web, persistence, kiểm toán.
 * Khai báo OPEN để module nghiệp vụ dùng được các gói con; nhân không được phụ thuộc module nào.
 */
@NullMarked
@ApplicationModule(type = ApplicationModule.Type.OPEN, displayName = "Nhân dùng chung dh-data")
package vn.datahub.data.shared;

import org.jspecify.annotations.NullMarked;
import org.springframework.modulith.ApplicationModule;
