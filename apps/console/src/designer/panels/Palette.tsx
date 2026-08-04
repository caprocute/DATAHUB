import { useDeferredValue, useMemo, useRef, useState, type DragEvent } from 'react';
import {
  CATALOG_RUNTIME,
  CATALOG_TOTAL,
  ICON_BY_TONE,
  KIND_VI,
  PALETTE,
  fitsRole,
  labelVi,
  labelsOfKind,
  searchNodes,
  toneOfNode,
  type CatalogNode,
  type NodeKind,
  type NodeTone,
  type PaletteItem,
} from '../catalog/catalog';
import { DRAG_MIME } from '../flow/interaction';

interface Props {
  /** Đã có chặng tiếp nhận thì các mục chỉ dùng làm đầu luồng bị khóa lại. */
  hasFrom: boolean;
}

/** Tab của bảng thành phần: nhóm nghiệp vụ LGSP trước, rồi tới phân loại gốc của catalog. */
type Tab = 'lgsp' | NodeKind;

const TABS: { key: Tab; label: string }[] = [
  { key: 'lgsp', label: 'Dùng nhiều' },
  { key: 'component', label: KIND_VI.component },
  { key: 'pattern', label: KIND_VI.pattern },
  { key: 'kamelet', label: KIND_VI.kamelet },
  { key: 'dataformat', label: KIND_VI.dataformat },
  { key: 'language', label: KIND_VI.language },
];

export function Palette({ hasFrom }: Props) {
  const [q, setQ] = useState('');
  const [tab, setTab] = useState<Tab>('lgsp');
  const [label, setLabel] = useState<string | null>(null);
  // Danh mục hơn 700 nút: hoãn lọc để gõ phím không giật.
  const deferredQ = useDeferredValue(q);
  const listRef = useRef<HTMLDivElement>(null);

  // Chặng tiếp nhận đã có thì chỉ còn chỗ cho chặng xử lý.
  const role = hasFrom ? 'step' : undefined;

  const lgspGroups = useMemo(() => {
    const needle = deferredQ.trim().toLowerCase();
    if (!needle) return PALETTE;
    return PALETTE.map((g) => ({
      ...g,
      items: g.items.filter(
        (it) => it.label.toLowerCase().includes(needle) || it.ref.toLowerCase().includes(needle),
      ),
    })).filter((g) => g.items.length > 0);
  }, [deferredQ]);

  const labels = useMemo(() => (tab === 'lgsp' ? [] : labelsOfKind(tab)), [tab]);

  const results = useMemo(() => {
    if (tab === 'lgsp') return [];
    return searchNodes(deferredQ, {
      kind: tab,
      label: label ?? undefined,
      role,
      limit: 400,
    });
  }, [tab, deferredQ, label, role]);

  const onDragItem = (e: DragEvent<HTMLDivElement>, item: PaletteItem, tone: NodeTone) => {
    e.dataTransfer.setData(DRAG_MIME, JSON.stringify({ ...item, tone: item.tone ?? tone }));
    e.dataTransfer.effectAllowed = 'copy';
  };

  const onDragNode = (e: DragEvent<HTMLDivElement>, n: CatalogNode) => {
    const tone = toneOfNode(n);
    const item: PaletteItem = {
      ref: `${n.kind}/${n.name}`,
      label: n.title,
      icon: ICON_BY_TONE[tone],
      consumerOnly: n.consumerOnly,
      // Cú pháp gốc làm gợi ý URI để người dùng biết dạng cần điền.
      uri: n.scheme ? n.syntax : undefined,
      tone,
    };
    e.dataTransfer.setData(DRAG_MIME, JSON.stringify(item));
    e.dataTransfer.effectAllowed = 'copy';
  };

  function switchTab(next: Tab) {
    setTab(next);
    setLabel(null);
    listRef.current?.scrollTo({ top: 0 });
  }

  return (
    <div className="panel panel--palette">
      <div className="panel__head">
        Thành phần
        <span className="t-small t-muted" style={{ marginLeft: 'auto', fontWeight: 400 }}>
          {CATALOG_TOTAL} nút
        </span>
      </div>

      <div className="panel__body" style={{ padding: 'var(--sp-3) var(--sp-3) 0' }}>
        <div className="search" style={{ minWidth: 0 }}>
          <span className="search__icon">⌕</span>
          <input
            className="input"
            type="text"
            placeholder="Tìm trong danh mục Camel…"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            aria-label="Tìm thành phần trong danh mục Camel"
          />
        </div>

        <div className="palette__tabs" role="tablist" aria-label="Phân loại thành phần">
          {TABS.map((t) => (
            <button
              key={t.key}
              type="button"
              role="tab"
              aria-selected={tab === t.key}
              className={tab === t.key ? 'palette__tab is-active' : 'palette__tab'}
              onClick={() => switchTab(t.key)}
            >
              {t.label}
            </button>
          ))}
        </div>

        {labels.length > 0 && (
          <div className="palette__chips">
            <button
              type="button"
              className={label === null ? 'palette__chip is-active' : 'palette__chip'}
              onClick={() => setLabel(null)}
            >
              Tất cả
            </button>
            {labels.map((l) => (
              <button
                key={l.label}
                type="button"
                className={label === l.label ? 'palette__chip is-active' : 'palette__chip'}
                onClick={() => setLabel(label === l.label ? null : l.label)}
                title={`${l.count} mục`}
              >
                {labelVi(l.label)} <span className="palette__chip-n">{l.count}</span>
              </button>
            ))}
          </div>
        )}
      </div>

      <div className="panel__body panel__body--flush" ref={listRef}>
        {tab === 'lgsp' ? (
          <>
            {lgspGroups.map((g) => (
              <div className="palette__group" key={g.label}>
                <div className="palette__label">{g.label}</div>
                {g.items.map((it) => {
                  const disabled = Boolean(it.consumerOnly && hasFrom);
                  const tone = it.tone ?? g.tone;
                  return (
                    <div
                      key={`${g.label}-${it.ref}-${it.label}`}
                      className={disabled ? 'palette__tile is-disabled' : 'palette__tile'}
                      draggable={!disabled}
                      onDragStart={(e) => !disabled && onDragItem(e, it, tone)}
                      title={
                        disabled
                          ? 'Luồng đã có chặng tiếp nhận — mỗi luồng chỉ có một đầu vào'
                          : `Kéo vào sơ đồ · Camel: ${it.ref}`
                      }
                    >
                      <span
                        className={`palette__tile-icon palette__tile-icon--${tone}`}
                        aria-hidden="true"
                      >
                        {it.icon}
                      </span>
                      <span className="palette__tile-text">
                        <span className="palette__tile-name">{it.label}</span>
                        <span className="palette__tile-ref t-mono">{it.ref}</span>
                      </span>
                    </div>
                  );
                })}
              </div>
            ))}
            {lgspGroups.length === 0 && (
              <div className="palette__group t-small t-muted">
                Không có mục quen thuộc nào khớp. Thử tab «{KIND_VI.component}» để tìm toàn bộ danh
                mục.
              </div>
            )}
          </>
        ) : (
          <div className="palette__group">
            {results.map((n) => {
              const tone = toneOfNode(n);
              const disabled = Boolean(n.consumerOnly && hasFrom) || (hasFrom && !fitsRole(n, 'step'));
              return (
                <div
                  key={`${n.kind}/${n.name}`}
                  className={disabled ? 'palette__tile is-disabled' : 'palette__tile'}
                  draggable={!disabled}
                  onDragStart={(e) => !disabled && onDragNode(e, n)}
                  title={
                    disabled
                      ? 'Mục này chỉ dùng làm chặng tiếp nhận — luồng đã có đầu vào'
                      : `${n.description || n.title}\n\nCamel: ${n.name}${n.syntax ? `\ncú pháp: ${n.syntax}` : ''}`
                  }
                >
                  <span
                    className={`palette__tile-icon palette__tile-icon--${tone}`}
                    aria-hidden="true"
                  >
                    {ICON_BY_TONE[tone]}
                  </span>
                  <span className="palette__tile-text">
                    <span className="palette__tile-name">
                      {n.title}
                      {n.deprecated && (
                        <span className="palette__badge palette__badge--warn" title="Đã ngừng khuyến nghị">
                          cũ
                        </span>
                      )}
                      {n.supportLevel === 'Preview' && (
                        <span className="palette__badge" title="Mức hỗ trợ: Preview">
                          thử nghiệm
                        </span>
                      )}
                    </span>
                    <span className="palette__tile-ref t-mono">{n.name}</span>
                  </span>
                </div>
              );
            })}
            {results.length === 0 && (
              <div className="t-small t-muted">Không có thành phần nào khớp từ khóa.</div>
            )}
          </div>
        )}
      </div>

      <div className="palette__foot t-small t-muted">
        Danh mục {CATALOG_RUNTIME} · kéo vào canvas, thả lên chốt <strong>＋</strong> giữa cạnh để
        chèn.
      </div>
    </div>
  );
}
