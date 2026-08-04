import { useMemo, useState } from 'react';
import type { Finding } from '../validate';

interface Props {
  findings: Finding[];
  onSelect: (nodeId: string) => void;
}

type Filter = 'all' | 'error' | 'warn';

export function FindingsPanel({ findings, onSelect }: Props) {
  const [filter, setFilter] = useState<Filter>('all');
  const errors = findings.filter((f) => f.level === 'error').length;
  const warns = findings.length - errors;

  // Luồng lớn sinh nhiều phát hiện; lọc theo mức để tìm lỗi chặn gửi duyệt trước.
  const shown = useMemo(
    () => (filter === 'all' ? findings : findings.filter((f) => f.level === filter)),
    [findings, filter],
  );

  return (
    <div className="panel">
      <div className="panel__head">
        Kết quả kiểm tra
        <span className="t-small t-muted" style={{ fontWeight: 400 }}>
          — {errors} lỗi, {warns} cảnh báo
        </span>
      </div>
      {findings.length > 0 && (
        <div className="finding__filters" role="group" aria-label="Lọc phát hiện theo mức">
          {(
            [
              { key: 'all', label: `Tất cả (${findings.length})` },
              { key: 'error', label: `Lỗi (${errors})` },
              { key: 'warn', label: `Cảnh báo (${warns})` },
            ] as const
          ).map((b) => (
            <button
              key={b.key}
              type="button"
              className={filter === b.key ? 'palette__chip is-active' : 'palette__chip'}
              aria-pressed={filter === b.key}
              onClick={() => setFilter(b.key)}
            >
              {b.label}
            </button>
          ))}
        </div>
      )}

      <div className="panel__body panel__body--flush">
        {findings.length === 0 && (
          <div className="finding">
            <span className="finding__mark" style={{ color: 'var(--c-ok-mark)' }}>
              ✓
            </span>
            <div className="finding__text">
              <div className="finding__title">Không có phát hiện nào</div>
              <div className="finding__meta">Luồng hợp lệ theo khung xương chuẩn, có thể gửi duyệt.</div>
            </div>
          </div>
        )}
        {findings.length > 0 && shown.length === 0 && (
          <div className="finding">
            <div className="finding__text">
              <div className="finding__meta t-muted">
                Không có mục nào ở mức này. Chọn «Tất cả» để xem lại.
              </div>
            </div>
          </div>
        )}

        {shown.map((f) => (
          <div
            className={f.nodeId ? 'finding finding--clickable' : 'finding'}
            key={f.id}
            onClick={() => f.nodeId && onSelect(f.nodeId)}
            role={f.nodeId ? 'button' : undefined}
            tabIndex={f.nodeId ? 0 : undefined}
            title={f.nodeId ? 'Bấm để chọn chặng trên sơ đồ' : undefined}
            onKeyDown={(e) => {
              if (f.nodeId && (e.key === 'Enter' || e.key === ' ')) {
                e.preventDefault();
                onSelect(f.nodeId);
              }
            }}
          >
            <span className={`finding__mark finding__mark--${f.level === 'error' ? 'err' : 'warn'}`}>
              {f.level === 'error' ? '✕' : '⚠'}
            </span>
            <div className="finding__text">
              <div className="finding__title">{f.title}</div>
              <div className="finding__meta">{f.detail}</div>
              {f.hint && <div className="finding__meta t-muted">Gợi ý: {f.hint}</div>}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
