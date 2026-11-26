package vn.datahub.data.rdm.internal;

import vn.datahub.data.shared.web.ErrorCode;

/** Mã lỗi nghiệp vụ của nhóm danh mục (D03-04-PH07 §6; lựa chọn theo san-sang.md SS-07-04, 05). */
public enum Ph07Error implements ErrorCode {
  COMMON_READ_ONLY("ERR-07-003", 403, "Đối tượng chỉ đọc với tỉnh của bạn", "read-only"),
  GROUP_NOT_EMPTY("ERR-07-037", 409, "Nhóm còn danh mục hoặc nhóm con", "group-not-empty"),
  GROUP_CONFLICT("ERR-07-039", 409, "Mã nhóm trùng, nhóm cha tạo vòng hoặc vượt độ sâu", "group-conflict"),
  GROUP_NOT_FOUND("ERR-07-045", 404, "Không tìm thấy nhóm danh mục", "group-not-found");

  private final String code;
  private final int status;
  private final String title;
  private final String slug;

  Ph07Error(String code, int status, String title, String slug) {
    this.code = code;
    this.status = status;
    this.title = title;
    this.slug = slug;
  }

  @Override
  public String code() {
    return code;
  }

  @Override
  public int status() {
    return status;
  }

  @Override
  public String title() {
    return title;
  }

  @Override
  public String slug() {
    return slug;
  }
}
