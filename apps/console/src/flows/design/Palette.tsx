import { useDeferredValue, useEffect, useMemo, useRef, useState, type DragEvent } from 'react'
import { searchRoutes } from '../../api/routesApi'
import {
  CATALOG_TOTAL,
  KIND_VI,
  TONE_ICON,
  labelVi,
  labelsOfKind,
  refOf,
  searchNodes,
  toneOfNode,
  type CatalogNode,
  type NodeKind,
} from '../core/catalog'
import { DRAG_MIME } from './interaction'

interface Props {
  /** Đã có chặng tiếp nhận thì mục chỉ dùng làm đầu luồng bị khóa lại. */
  hasFrom: boolean
}

const TABS: { key: NodeKind; label: string }[] = [
  { key: 'component', label: KIND_VI.component },
  { key: 'pattern', label: KIND_VI.pattern },
  { key: 'kamelet', label: KIND_VI.kamelet },
  { key: 'dataformat', label: KIND_VI.dataformat },
  { key: 'language', label: KIND_VI.language },
]

/** Chiều cao một dòng — cần biết trước để ảo hóa. */
const ROW_H = 52
/** Số dòng đệm trên/dưới tầm nhìn, tránh nháy khi cuộn nhanh. */
const OVERSCAN = 6

/**
 * Bảng thành phần cho 751 nút (FR-D-011).
 *
 * Ảo hóa danh sách: chỉ dựng phần tử trong tầm nhìn. Dựng cả 751 thẻ làm mỗi lần
 * gõ phím phải vẽ lại toàn bộ, không đạt ngưỡng < 50 ms của NFR-D-02.
 */
export function Palette({ hasFrom }: Props) {
  /**
   * Kamelet **tự viết** trong hệ thống (K3-2 — FR-D-062).
   *
   * Nạp một lần khi mở tab Kamelet. Hiện cạnh 243 kamelet dựng sẵn nhưng **có huy hiệu
   * riêng**: người dùng phải phân biệt được thứ nền tảng bảo đảm với thứ đơn vị mình tự
   * viết — nhầm hai loại này là nhầm cả trách nhiệm vận hành khi nó hỏng.
   */
  const [mine, setMine] = useState<CatalogNode[]>([])
  const [mineLoaded, setMineLoaded] = useState(false)
  const [q, setQ] = useState('')
  const [kind, setKind] = useState<NodeKind>('component')
  const [label, setLabel] = useState<string | null>(null)
  /** Khối nhãn mặc định thu gọn để nhường chỗ cho danh sách. */
  const [labelsOpen, setLabelsOpen] = useState(false)
  const [scrollTop, setScrollTop] = useState(0)
  const [viewH, setViewH] = useState(600)
  const listRef = useRef<HTMLDivElement>(null)

  // Hoãn lọc để gõ phím không giật khi danh mục lớn.
  const deferredQ = useDeferredValue(q)
  const role = hasFrom ? 'step' : undefined

  useEffect(() => {
    if (kind !== 'kamelet' || mineLoaded) return
    setMineLoaded(true)
    void searchRoutes({ resourceKind: 'KAMELET', size: 200 })
      .then((page) =>
        setMine(
          page.items.map((r) => ({
            name: r.routeCode,
            kind: 'kamelet' as const,
            title: r.title || r.routeCode,
            description: `Kamelet tự viết — ${r.sourceSystem}`,
            labels: ['tu-viet'],
          })),
        ),
      )
      // Không nạp được thì bảng vẫn dùng được với kamelet dựng sẵn; báo lỗi ồn ào ở đây
      // chặn mất việc chính của người dùng.
      .catch(() => setMine([]))
  }, [kind, mineLoaded])

  const labels = useMemo(() => labelsOfKind(kind), [kind])
  const results = useMemo(() => {
    const base = searchNodes(deferredQ, { kind, label: label ?? undefined, role })
    if (kind !== 'kamelet' || !mine.length) return base
    // Kamelet tự viết lên **đầu** danh sách: đó là thứ người dùng vừa tạo và đang tìm.
    const needle = deferredQ.trim().toLowerCase()
    const mineHit = needle
      ? mine.filter(
          (m) =>
            m.name.toLowerCase().includes(needle) || m.title.toLowerCase().includes(needle),
        )
      : mine
    return [...mineHit, ...base]
  }, [deferredQ, kind, label, role, mine])

  const first = Math.max(0, Math.floor(scrollTop / ROW_H) - OVERSCAN)
  const last = Math.min(results.length, Math.ceil((scrollTop + viewH) / ROW_H) + OVERSCAN)
  const slice = results.slice(first, last)

  function onDragStart(e: DragEvent<HTMLDivElement>, n: CatalogNode) {
    e.dataTransfer.setData(DRAG_MIME, JSON.stringify({ ref: refOf(n) }))
    e.dataTransfer.effectAllowed = 'copy'
  }

  function switchKind(k: NodeKind) {
    setKind(k)
    setLabel(null)
    setScrollTop(0)
    listRef.current?.scrollTo({ top: 0 })
  }

  return (
    <>
      <div className="dsg__panel-head">
        Thành phần
        <span className="count">{CATALOG_TOTAL} nút</span>
      </div>

      <div className="pal__filters">
        <input
          className="pal__search"
          type="text"
          placeholder="Tìm trong danh mục Camel…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          aria-label="Tìm thành phần trong danh mục Camel"
        />

        <div className="pal__tabs" role="tablist" aria-label="Loại thành phần">
          {TABS.map((t) => (
            <button
              key={t.key}
              type="button"
              role="tab"
              aria-selected={kind === t.key}
              className={kind === t.key ? 'pal__tab is-active' : 'pal__tab'}
              onClick={() => switchKind(t.key)}
            >
              {t.label}
            </button>
          ))}
        </div>

        {/* Nhãn gập lại được: đây là khối ăn nhiều chiều cao nhất của bảng lọc (đo được
            ~100px trên tổng 201px), mà phần lớn thời gian người dùng chỉ tìm theo tên.
            Mặc định thu gọn để danh sách 751 nút có thêm chỗ; đang lọc thì mở sẵn. */}
        {labels.length > 0 && (
          <>
            <button
              type="button"
              className="pal__more"
              aria-expanded={labelsOpen}
              onClick={() => setLabelsOpen((v) => !v)}
            >
              {labelsOpen ? '▾' : '▸'} Lọc theo nhãn
              {label && <span className="pal__chip-n"> · {labelVi(label)}</span>}
            </button>
            {labelsOpen && (
              <div className="pal__chips">
                <button
                  type="button"
                  className={label === null ? 'pal__chip is-active' : 'pal__chip'}
                  onClick={() => setLabel(null)}
                >
                  Tất cả
                </button>
                {labels.map((l) => (
                  <button
                    key={l.label}
                    type="button"
                    className={label === l.label ? 'pal__chip is-active' : 'pal__chip'}
                    onClick={() => setLabel(label === l.label ? null : l.label)}
                  >
                    {labelVi(l.label)} <span className="pal__chip-n">{l.count}</span>
                  </button>
                ))}
              </div>
            )}
          </>
        )}
      </div>

      <div
        className="dsg__panel-body pal__list"
        ref={listRef}
        onScroll={(e) => {
          setScrollTop(e.currentTarget.scrollTop)
          setViewH(e.currentTarget.clientHeight)
        }}
      >
        {results.length === 0 ? (
          <p className="pal__empty">Không có thành phần nào khớp từ khóa.</p>
        ) : (
          // Khối đệm giữ đúng chiều cao tổng để thanh cuộn phản ánh số mục thật.
          <div style={{ height: results.length * ROW_H, position: 'relative' }}>
            <div style={{ transform: `translateY(${first * ROW_H}px)` }}>
              {slice.map((n) => {
                const tone = toneOfNode(n)
                const disabled = Boolean(hasFrom && n.consumerOnly)
                return (
                  <div
                    key={refOf(n)}
                    className={disabled ? 'pal__item is-disabled' : 'pal__item'}
                    style={{ height: ROW_H }}
                    draggable={!disabled}
                    onDragStart={(e) => !disabled && onDragStart(e, n)}
                    title={
                      disabled
                        ? 'Mục này chỉ dùng làm chặng tiếp nhận — luồng đã có đầu vào'
                        : `${n.description || n.title}${n.syntax ? `\n\ncú pháp: ${n.syntax}` : ''}`
                    }
                  >
                    <span className={`pal__icon pal__icon--${tone}`} aria-hidden="true">
                      {TONE_ICON[tone]}
                    </span>
                    <span className="pal__text">
                      <span className="pal__name">
                        {n.title}
                        {/* Kamelet tự viết: nền tảng **không** bảo đảm, trách nhiệm vận
                            hành thuộc đơn vị viết ra nó — phải nhìn là biết ngay. */}
                        {n.labels?.includes('tu-viet') && (
                          <span className="pal__badge pal__badge--mine">tự viết</span>
                        )}
                        {n.deprecated && <span className="pal__badge pal__badge--warn">cũ</span>}
                        {n.supportLevel === 'Preview' && <span className="pal__badge">thử nghiệm</span>}
                      </span>
                      <span className="pal__ref">{n.name}</span>
                    </span>
                  </div>
                )
              })}
            </div>
          </div>
        )}
      </div>

      <div className="pal__foot">
        {results.length} mục · kéo vào sơ đồ
      </div>
    </>
  )
}
