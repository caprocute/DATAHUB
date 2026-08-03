import { useEffect, useMemo, useRef, useState } from 'react';
import { PALETTE, type PaletteItem } from '../catalog/catalog';

interface Props {
  at: { x: number; y: number };
  onPick: (item: PaletteItem) => void;
  onClose: () => void;
}

/** Danh sách chọn thành phần, mở ngay tại chỗ bấm trên cạnh. */
export function InsertMenu({ at, onPick, onClose }: Props) {
  const [q, setQ] = useState('');
  const box = useRef<HTMLDivElement>(null);
  const input = useRef<HTMLInputElement>(null);

  useEffect(() => {
    input.current?.focus();
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    const onDown = (e: MouseEvent) => {
      if (box.current && !box.current.contains(e.target as Node)) onClose();
    };
    document.addEventListener('keydown', onKey);
    // Hoãn một nhịp, nếu không chính cú bấm mở danh sách sẽ đóng luôn nó.
    const t = window.setTimeout(() => document.addEventListener('mousedown', onDown), 0);
    return () => {
      document.removeEventListener('keydown', onKey);
      document.removeEventListener('mousedown', onDown);
      window.clearTimeout(t);
    };
  }, [onClose]);

  const groups = useMemo(() => {
    const needle = q.trim().toLowerCase();
    return PALETTE.map((g) => ({
      label: g.label,
      // Chặng tiếp nhận là đầu luồng, không chèn được vào giữa.
      items: g.items.filter(
        (it) => !it.consumerOnly && (!needle || it.label.toLowerCase().includes(needle) || it.ref.includes(needle)),
      ),
    })).filter((g) => g.items.length > 0);
  }, [q]);

  // Giữ danh sách trong khung nhìn khi bấm ở sát rìa dưới hoặc rìa phải.
  const left = Math.min(at.x, window.innerWidth - 260);
  const top = Math.min(at.y, window.innerHeight - 340);

  return (
    <div className="insert-menu" style={{ left, top }} ref={box} role="dialog" aria-label="Chèn chặng">
      <div className="insert-menu__head">
        <input
          ref={input}
          className="input input--sm"
          placeholder="Tìm thành phần…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
      </div>
      <div className="insert-menu__list">
        {groups.map((g) => (
          <div className="insert-menu__group" key={g.label}>
            <div className="palette__label">{g.label}</div>
            {g.items.map((it) => (
              <button
                type="button"
                className="palette__item palette__item--btn"
                key={`${g.label}-${it.ref}-${it.label}`}
                onClick={() => onPick(it)}
              >
                <span>{it.icon}</span> {it.label}
              </button>
            ))}
          </div>
        ))}
        {groups.length === 0 && <div className="insert-menu__empty t-small t-muted">Không có thành phần khớp.</div>}
      </div>
    </div>
  );
}
