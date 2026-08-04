import { describe, expect, it } from 'vitest';
import { collapseUnchanged, diffLines, diffStat } from './diff';

describe('so sánh hai bản YAML theo dòng', () => {
  it('hai bản giống nhau thì không có khác biệt', () => {
    const lines = diffLines('a\nb\nc', 'a\nb\nc');
    expect(lines.every((l) => l.kind === 'same')).toBe(true);
    expect(diffStat(lines)).toEqual({ added: 0, removed: 0 });
  });

  it('nhận ra dòng thêm và dòng bỏ', () => {
    const lines = diffLines('a\nb\nc', 'a\nx\nc');
    expect(diffStat(lines)).toEqual({ added: 1, removed: 1 });
    expect(lines.find((l) => l.kind === 'remove')?.text).toBe('b');
    expect(lines.find((l) => l.kind === 'add')?.text).toBe('x');
  });

  it('chèn thêm dòng giữa tệp không làm lệch phần còn lại', () => {
    // So theo vị trí sẽ báo 3 đổi; tìm dãy con chung chỉ báo đúng 1 dòng thêm.
    const lines = diffLines('a\nb\nc', 'a\nMOI\nb\nc');
    expect(diffStat(lines)).toEqual({ added: 1, removed: 0 });
  });

  it('đánh số dòng theo từng bản', () => {
    const lines = diffLines('a\nb', 'a\nb\nc');
    const them = lines.find((l) => l.kind === 'add')!;
    expect(them.newNo).toBe(3);
    expect(them.oldNo).toBeNull();
  });

  it('bản rỗng: mọi dòng đều là thêm mới', () => {
    expect(diffStat(diffLines('', 'a\nb'))).toEqual({ added: 2, removed: 0 });
    expect(diffStat(diffLines('a\nb', ''))).toEqual({ added: 0, removed: 2 });
  });

  it('bỏ qua khác biệt khoảng trắng ở cuối tệp', () => {
    expect(diffStat(diffLines('a\nb\n', 'a\nb'))).toEqual({ added: 0, removed: 0 });
  });
});

describe('gộp đoạn không đổi', () => {
  it('giữ ngữ cảnh quanh chỗ đổi và gộp phần giữa', () => {
    const oldText = Array.from({ length: 40 }, (_, i) => `dong ${i}`).join('\n');
    const newText = oldText.replace('dong 20', 'dong 20 da doi');
    const collapsed = collapseUnchanged(diffLines(oldText, newText), 2);

    // Phải có dấu ngắt quãng, và số dòng hiển thị ít hơn hẳn toàn bộ tệp.
    expect(collapsed.some((l) => l === null)).toBe(true);
    expect(collapsed.length).toBeLessThan(20);
    expect(collapsed.some((l) => l?.text === 'dong 20 da doi')).toBe(true);
  });

  it('không có khác biệt thì gộp hết thành một dấu ngắt', () => {
    const same = Array.from({ length: 20 }, (_, i) => `x${i}`).join('\n');
    expect(collapseUnchanged(diffLines(same, same))).toEqual([null]);
  });
});
