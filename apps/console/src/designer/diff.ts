/**
 * So sánh hai bản YAML theo dòng (B7-5).
 *
 * Dùng thuật toán dãy con chung dài nhất — đủ nhanh cho định nghĩa luồng vài trăm
 * dòng và cho ra khác biệt gọn hơn so sánh từng dòng theo vị trí.
 */

export type DiffKind = 'same' | 'add' | 'remove';

export interface DiffLine {
  kind: DiffKind;
  /** Số dòng ở bản cũ; `null` với dòng mới thêm. */
  oldNo: number | null;
  /** Số dòng ở bản mới; `null` với dòng bị bỏ. */
  newNo: number | null;
  text: string;
}

export interface DiffStat {
  added: number;
  removed: number;
}

/**
 * Bảng độ dài dãy con chung dài nhất.
 *
 * Giới hạn kích thước: hai bản quá dài thì bảng quy hoạch động tốn bộ nhớ vô ích
 * trong khi người duyệt cũng không đọc nổi — khi đó rơi về so sánh theo vị trí.
 */
const MAX_CELLS = 4_000_000;

export function diffLines(oldText: string, newText: string): DiffLine[] {
  // `''.split('\n')` cho `['']` — một dòng rỗng ảo; bản rỗng phải là không dòng nào.
  const split = (t: string) => {
    const trimmed = t.replace(/\s+$/, '');
    return trimmed === '' ? [] : trimmed.split('\n');
  };
  const a = split(oldText);
  const b = split(newText);

  if ((a.length + 1) * (b.length + 1) > MAX_CELLS) {
    return positionalDiff(a, b);
  }

  const lcs: number[][] = Array.from({ length: a.length + 1 }, () =>
    new Array<number>(b.length + 1).fill(0),
  );
  for (let i = a.length - 1; i >= 0; i -= 1) {
    for (let j = b.length - 1; j >= 0; j -= 1) {
      lcs[i][j] = a[i] === b[j] ? lcs[i + 1][j + 1] + 1 : Math.max(lcs[i + 1][j], lcs[i][j + 1]);
    }
  }

  const out: DiffLine[] = [];
  let i = 0;
  let j = 0;
  while (i < a.length && j < b.length) {
    if (a[i] === b[j]) {
      out.push({ kind: 'same', oldNo: i + 1, newNo: j + 1, text: a[i] });
      i += 1;
      j += 1;
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      out.push({ kind: 'remove', oldNo: i + 1, newNo: null, text: a[i] });
      i += 1;
    } else {
      out.push({ kind: 'add', oldNo: null, newNo: j + 1, text: b[j] });
      j += 1;
    }
  }
  while (i < a.length) {
    out.push({ kind: 'remove', oldNo: i + 1, newNo: null, text: a[i] });
    i += 1;
  }
  while (j < b.length) {
    out.push({ kind: 'add', oldNo: null, newNo: j + 1, text: b[j] });
    j += 1;
  }
  return out;
}

/** Lối dự phòng cho tệp rất lớn: so theo vị trí, không tìm dãy con chung. */
function positionalDiff(a: string[], b: string[]): DiffLine[] {
  const out: DiffLine[] = [];
  const n = Math.max(a.length, b.length);
  for (let k = 0; k < n; k += 1) {
    if (a[k] === b[k]) {
      out.push({ kind: 'same', oldNo: k + 1, newNo: k + 1, text: a[k] });
      continue;
    }
    if (k < a.length) out.push({ kind: 'remove', oldNo: k + 1, newNo: null, text: a[k] });
    if (k < b.length) out.push({ kind: 'add', oldNo: null, newNo: k + 1, text: b[k] });
  }
  return out;
}

export function diffStat(lines: DiffLine[]): DiffStat {
  let added = 0;
  let removed = 0;
  for (const l of lines) {
    if (l.kind === 'add') added += 1;
    else if (l.kind === 'remove') removed += 1;
  }
  return { added, removed };
}

/**
 * Chỉ giữ đoạn quanh chỗ đổi, gộp dòng giống nhau ở giữa.
 *
 * Người duyệt cần thấy ngữ cảnh chứ không phải toàn bộ tệp; trả về `null` ở chỗ
 * bị gộp để giao diện vẽ dấu ngắt quãng.
 */
export function collapseUnchanged(lines: DiffLine[], context = 3): (DiffLine | null)[] {
  const keep = new Set<number>();
  lines.forEach((l, i) => {
    if (l.kind === 'same') return;
    for (let k = Math.max(0, i - context); k <= Math.min(lines.length - 1, i + context); k += 1) {
      keep.add(k);
    }
  });

  const out: (DiffLine | null)[] = [];
  let skipping = false;
  lines.forEach((l, i) => {
    if (keep.has(i)) {
      out.push(l);
      skipping = false;
    } else if (!skipping) {
      out.push(null);
      skipping = true;
    }
  });
  return out;
}
