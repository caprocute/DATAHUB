package vn.lgsp.common.page;

import java.util.List;

public record CursorPage<T>(List<T> items, String nextCursor) {

  public static <T> CursorPage<T> of(List<T> items, String nextCursor) {
    return new CursorPage<>(List.copyOf(items), nextCursor);
  }

  public static <T> CursorPage<T> empty() {
    return new CursorPage<>(List.of(), null);
  }
}
