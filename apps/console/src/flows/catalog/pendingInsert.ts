/**
 * Bắc cầu giữa màn danh mục và trình thiết kế (K4-4 — FR-D-070).
 *
 * Trình thiết kế mở ở route riêng (`/flows/:code/design`, **ngoài** `AppShell`), còn màn
 * danh mục nằm trong shell. Hai màn không có tổ tiên chung nào ngoài `BrowserRouter`,
 * nên không có context nào truyền thẳng được thứ người dùng chọn.
 *
 * Dùng `sessionStorage` chứ không phải `localStorage`: đây là **một thao tác dở dang**
 * của đúng tab này. `localStorage` dùng chung giữa mọi tab, người dùng mở hai luồng ở
 * hai tab sẽ thấy thành phần chọn ở tab này nhảy sang luồng của tab kia.
 */

const TARGET_KEY = 'lgsp.catalog.target';
const PICK_KEY = 'lgsp.catalog.pick';

/** Luồng đang mở lúc người dùng rời trình thiết kế sang danh mục. */
export interface PendingTarget {
  code: string;
  title?: string;
}

/** Thành phần người dùng đã chọn ở danh mục, chờ trình thiết kế nhận. */
export interface PendingPick {
  /** Khóa `kind/name` của nút catalog. */
  ref: string;
  code: string;
}

function readJson<T>(store: Storage, key: string): T | null {
  try {
    const raw = store.getItem(key);
    return raw ? (JSON.parse(raw) as T) : null;
  } catch {
    // Dữ liệu hỏng hoặc `sessionStorage` bị chặn (chế độ riêng tư của vài trình duyệt).
    // Cả hai đều không phải lỗi người dùng cần biết — tính năng chỉ đơn giản không kích hoạt.
    return null;
  }
}

/** Trình thiết kế gọi trước khi điều hướng sang danh mục. */
export function setPendingTarget(target: PendingTarget): void {
  try {
    sessionStorage.setItem(TARGET_KEY, JSON.stringify(target));
  } catch {
    /* không lưu được thì nút "Thêm vào luồng" ở danh mục chỉ không hiện */
  }
}

export function readPendingTarget(): PendingTarget | null {
  const t = readJson<PendingTarget>(sessionStorage, TARGET_KEY);
  return t?.code ? t : null;
}

export function clearPendingTarget(): void {
  try {
    sessionStorage.removeItem(TARGET_KEY);
  } catch {
    /* bỏ qua */
  }
}

/** Danh mục gọi khi người dùng bấm "Thêm vào luồng". */
export function setPendingPick(pick: PendingPick): void {
  try {
    sessionStorage.setItem(PICK_KEY, JSON.stringify(pick));
  } catch {
    /* bỏ qua */
  }
}

/**
 * Trình thiết kế lấy thành phần đang chờ — **đọc một lần rồi xóa**.
 *
 * Phải xóa ngay trong cùng lượt đọc: để lại thì mỗi lần người dùng mở lại luồng đó
 * (hoặc React StrictMode gọi effect lần hai) sẽ chèn thêm một chặng nữa.
 *
 * Chỉ trả về khi `code` khớp luồng đang mở, tránh chèn nhầm sang luồng khác nếu người
 * dùng đổi ý và mở luồng thứ hai.
 */
export function takePendingPick(code: string): string | null {
  const p = readJson<PendingPick>(sessionStorage, PICK_KEY);
  if (!p?.ref) return null;
  if (p.code !== code) return null;
  try {
    sessionStorage.removeItem(PICK_KEY);
  } catch {
    /* bỏ qua */
  }
  return p.ref;
}
