package vn.datahub.data.rdm.internal;

import java.util.UUID;
import org.jspecify.annotations.Nullable;

/** Lệnh tạo nhóm: giá trị đã chuẩn hóa và kiểm tra ở biên. */
public record CreateGroupCommand(
    String code, String name, @Nullable UUID parentId, int sortOrder, @Nullable String description) {}
