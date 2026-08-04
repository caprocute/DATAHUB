import type { Finding } from '../validate';

interface Props {
  findings: Finding[];
  onSelect: (nodeId: string) => void;
}

export function FindingsPanel({ findings, onSelect }: Props) {
  const errors = findings.filter((f) => f.level === 'error').length;
  const warns = findings.length - errors;

  return (
    <div className="panel">
      <div className="panel__head">
        Kết quả kiểm tra
        <span className="t-small t-muted" style={{ fontWeight: 400 }}>
          — {errors} lỗi, {warns} cảnh báo
        </span>
      </div>
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
        {findings.map((f) => (
          <div
            className={f.nodeId ? 'finding finding--clickable' : 'finding'}
            key={f.id}
            onClick={() => f.nodeId && onSelect(f.nodeId)}
            role={f.nodeId ? 'button' : undefined}
            tabIndex={f.nodeId ? 0 : undefined}
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
