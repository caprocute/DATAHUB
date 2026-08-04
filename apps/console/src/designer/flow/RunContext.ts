import { createContext, useContext } from 'react';

/** Trạng thái một chặng sau lần chạy thử (FR-04-035). */
export type RunStatus = 'ok' | 'error' | 'skipped';

export interface StageRun {
  status: RunStatus;
  durationMs: number;
  /** Thứ tự chặng trên đường chạy — dùng đánh số huy hiệu trên sơ đồ. */
  order: number;
}

/**
 * Kết quả chạy thử theo từng chặng.
 *
 * Đi qua context như `StatusContext`: nhét vào `data` của nút sẽ khiến React Flow
 * vẽ lại toàn sơ đồ mỗi lần chạy thử.
 */
export const RunContext = createContext<Record<string, StageRun>>({});

export function useStageRun(id: string): StageRun | undefined {
  return useContext(RunContext)[id];
}

/** Một chặng trong kết quả waterfall do máy chủ trả về (WP-25). */
export interface WaterfallStage {
  stage: string;
  status: string;
  durationMs: number;
  offsetMs: number;
}

/** Nhãn chặng của máy chủ → mã chặng trên sơ đồ. */
function normalize(s: string): string {
  return (
    s
      .toLowerCase()
      .normalize('NFD')
      // Bỏ dấu thanh và dấu mũ tiếng Việt để so khớp không phụ thuộc cách gõ.
      .replace(/[̀-ͯ]/g, '')
      // `đ` là chữ cái riêng, NFD không tách được nên phải thay tay.
      .replace(/đ/g, 'd')
      .replace(/[^a-z0-9]+/g, '')
  );
}

/**
 * Ghép waterfall của máy chủ vào các chặng trên sơ đồ.
 *
 * Máy chủ trả tên chặng theo khung chín bước, còn sơ đồ dùng mã nút do trình thiết kế
 * sinh ra. Ghép theo nhãn đã chuẩn hóa; chặng nào không ghép được thì **bỏ qua** thay vì
 * gán bừa cho nút gần nhất — tô sai còn tệ hơn không tô.
 */
export function mapWaterfall(
  waterfall: WaterfallStage[],
  nodes: { id: string; data: { label: string; ref: string } }[],
): Record<string, StageRun> {
  const out: Record<string, StageRun> = {};
  const used = new Set<string>();

  waterfall.forEach((w, i) => {
    const key = normalize(w.stage);
    const hit = nodes.find(
      (n) => !used.has(n.id) && (normalize(n.data.label) === key || normalize(n.data.ref).endsWith(key)),
    );
    if (!hit) return;
    used.add(hit.id);
    const s = w.status.toUpperCase();
    out[hit.id] = {
      status: s === 'OK' || s === 'SUCCESS' ? 'ok' : s === 'SKIPPED' ? 'skipped' : 'error',
      durationMs: w.durationMs,
      order: i + 1,
    };
  });

  return out;
}
