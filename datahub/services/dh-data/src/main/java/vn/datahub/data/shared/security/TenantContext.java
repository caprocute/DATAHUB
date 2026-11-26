package vn.datahub.data.shared.security;

import java.util.List;
import java.util.function.Supplier;
import java.util.regex.Pattern;

/**
 * Tenant của yêu cầu hiện tại, lấy từ claim {@code tenant} của JWT đã xác minh (CC-TEN-01).
 * Chỉ {@code shared.security} và {@link #runAs} được đặt giá trị.
 */
public final class TenantContext {

  public static final String COMMON = "COMMON";
  public static final String PLATFORM = "PLATFORM";
  private static final Pattern PROVINCE = Pattern.compile("^T\\d{2}$");
  private static final ThreadLocal<String> CURRENT = new ThreadLocal<>();

  private TenantContext() {}

  /** Mã tenant hợp lệ của token: tỉnh {@code Tnn} hoặc {@code PLATFORM}. */
  public static boolean isValidTokenTenant(String tenant) {
    return tenant != null && (PLATFORM.equals(tenant) || PROVINCE.matcher(tenant).matches());
  }

  static void set(String tenant) {
    CURRENT.set(tenant);
  }

  static void clear() {
    CURRENT.remove();
  }

  /** Tenant hiện tại; không có thì lỗi (không bao giờ ngầm dùng tenant rỗng). */
  public static String require() {
    String tenant = CURRENT.get();
    if (tenant == null) {
      throw new IllegalStateException("Không có tenant trong ngữ cảnh yêu cầu");
    }
    return tenant;
  }

  /** Tenant sở hữu dữ liệu ghi: PLATFORM ghi vào COMMON, tenant tỉnh ghi vào chính nó (RLS mẫu S). */
  public static String dataTenant() {
    String tenant = require();
    return PLATFORM.equals(tenant) ? COMMON : tenant;
  }

  /** Các tenant mà tenant hiện tại được đọc: chính nó và COMMON (PLATFORM chỉ thấy COMMON). */
  public static List<String> visibleTenants() {
    String tenant = require();
    return PLATFORM.equals(tenant) ? List.of(COMMON) : List.of(tenant, COMMON);
  }

  /** Chạy khối mã với tenant chỉ định (tác vụ nền, kiểm thử), rồi khôi phục. */
  public static <T> T runAs(String tenant, Supplier<T> action) {
    String previous = CURRENT.get();
    CURRENT.set(tenant);
    try {
      return action.get();
    } finally {
      if (previous == null) {
        CURRENT.remove();
      } else {
        CURRENT.set(previous);
      }
    }
  }
}
