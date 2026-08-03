import { useMemo, useState, type DragEvent } from 'react';
import { PALETTE, type PaletteItem } from '../catalog/catalog';
import { DRAG_MIME } from '../flow/interaction';

interface Props {
  /** Đã có chặng tiếp nhận thì các mục chỉ dùng làm đầu luồng bị khóa lại. */
  hasFrom: boolean;
}

export function Palette({ hasFrom }: Props) {
  const [q, setQ] = useState('');

  const groups = useMemo(() => {
    const needle = q.trim().toLowerCase();
    if (!needle) return PALETTE;
    return PALETTE.map((g) => ({
      label: g.label,
      items: g.items.filter(
        (it) => it.label.toLowerCase().includes(needle) || it.ref.toLowerCase().includes(needle),
      ),
    })).filter((g) => g.items.length > 0);
  }, [q]);

  const onDragStart = (e: DragEvent<HTMLDivElement>, item: PaletteItem) => {
    e.dataTransfer.setData(DRAG_MIME, JSON.stringify(item));
    e.dataTransfer.effectAllowed = 'copy';
  };

  return (
    <div className="panel">
      <div className="panel__head">Thành phần</div>
      <div className="panel__body" style={{ padding: 'var(--sp-3) var(--sp-3) 0' }}>
        <div className="search" style={{ minWidth: 0 }}>
          <span className="search__icon">⌕</span>
          <input
            className="input"
            type="text"
            placeholder="Tìm thành phần…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
        </div>
        <p className="t-small t-muted" style={{ margin: 'var(--sp-2) 0 0' }}>
          Kéo một mục vào sơ đồ, hoặc thả lên chốt <strong>＋</strong> trên cạnh để chèn vào giữa.
        </p>
      </div>
      <div className="panel__body panel__body--flush">
        {groups.map((g) => (
          <div className="palette__group" key={g.label}>
            <div className="palette__label">{g.label}</div>
            {g.items.map((it) => {
              const disabled = Boolean(it.consumerOnly && hasFrom);
              return (
                <div
                  key={`${g.label}-${it.ref}-${it.label}`}
                  className={disabled ? 'palette__item is-disabled' : 'palette__item'}
                  draggable={!disabled}
                  onDragStart={(e) => !disabled && onDragStart(e, it)}
                  title={
                    disabled
                      ? 'Luồng đã có chặng tiếp nhận — mỗi luồng chỉ có một đầu vào'
                      : `Kéo vào sơ đồ · thành phần Camel: ${it.ref}`
                  }
                >
                  <span>{it.icon}</span> {it.label}
                </div>
              );
            })}
          </div>
        ))}
        {groups.length === 0 && (
          <div className="palette__group t-small t-muted">Không có thành phần nào khớp từ khóa.</div>
        )}
      </div>
    </div>
  );
}
