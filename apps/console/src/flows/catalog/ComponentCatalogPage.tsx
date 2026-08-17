import { useDeferredValue, useEffect, useMemo, useRef, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import {
  ALL_KINDS,
  CATALOG_COUNTS,
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
import { CatalogLicense } from './CatalogLicense'
import { NodeDetail } from './NodeDetail'
import { readPendingTarget } from './pendingInsert'
import './catalog.css'

/** Chiều cao một dòng — cần biết trước để ảo hóa (FR-D-071). */
const ROW_H = 64
/** Số dòng đệm trên/dưới tầm nhìn, tránh nháy khi cuộn nhanh. */
const OVERSCAN = 8
/** Số nhãn hiện lúc chưa mở rộng — đủ hai dòng chip, không nuốt chỗ của danh sách. */
const LABELS_COLLAPSED = 12

/**
 * Màn danh mục thành phần D-07 (FR-D-070…073).
 *
 * Khác **bảng thành phần** trong trình thiết kế ở ba điểm, và ba điểm đó là lý do nó
 * tồn tại như một màn riêng:
 *  - bảng thành phần chỉ hiện 5 loại **thả được vào sơ đồ**, màn này duyệt đủ **cả bảy**
 *    (751 nút) kể cả `entity`/`loadbalancer` — thứ người dùng cần *tra cứu* chứ không kéo;
 *  - bảng thành phần lọc theo vị trí trong luồng (`role`), màn này không lọc gì cả;
 *  - màn này có **trang chi tiết** đầy đủ thuộc tính, nơi kia chỉ có tooltip.
 *
 * Đường dẫn là `/components`, **không** phải `/catalog`: `/catalog` đã là màn đăng ký
 * dịch vụ API của PH-02 — hai nghiệp vụ khác hẳn nhau, gộp tên sẽ gây nhầm.
 */
export function ComponentCatalogPage() {
  const [params, setParams] = useSearchParams()
  const navigate = useNavigate()

  // Trạng thái duyệt nằm trong URL: người dùng gửi link tới đúng nút đang xem được,
  // và nút Back của trình duyệt trả về đúng chỗ vừa đứng.
  const kind = (params.get('kind') as NodeKind | null) ?? 'component'
  const label = params.get('label')
  const selected = params.get('node')
  const q = params.get('q') ?? ''

  const [draft, setDraft] = useState(q)
  const [labelsOpen, setLabelsOpen] = useState(false)
  const [scrollTop, setScrollTop] = useState(0)
  const [viewH, setViewH] = useState(640)
  const listRef = useRef<HTMLDivElement>(null)

  // Hoãn lọc để gõ phím không giật trên 751 nút (NFR-D-02 — dưới 50 ms mỗi lần gõ).
  const deferredQ = useDeferredValue(draft)

  // Ô tìm và URL là hai nguồn của cùng một giá trị. Đồng bộ một chiều URL → ô tìm chỉ
  // khi chúng thật sự lệch (người dùng bấm Back), nếu không sẽ nuốt mất ký tự đang gõ.
  useEffect(() => {
    setDraft((d) => (d === q ? d : q))
  }, [q])

  // Ghi từ khóa vào URL sau khi người dùng ngừng gõ — mỗi ký tự một lượt `history`
  // sẽ làm nút Back phải bấm hàng chục lần mới thoát khỏi màn.
  useEffect(() => {
    if (deferredQ === q) return
    const t = setTimeout(() => {
      setParams(
        (p) => {
          const next = new URLSearchParams(p)
          if (deferredQ) next.set('q', deferredQ)
          else next.delete('q')
          return next
        },
        { replace: true },
      )
    }, 250)
    return () => clearTimeout(t)
  }, [deferredQ, q, setParams])

  const labels = useMemo(() => labelsOfKind(kind), [kind])
  // Nhãn đang lọc phải luôn nhìn thấy, kể cả khi nó nằm ngoài 12 nhãn đầu — nếu không
  // người dùng thấy danh sách bị thu hẹp mà không thấy thứ gây ra điều đó.
  const shownLabels = useMemo(() => {
    if (labelsOpen) return labels
    const head = labels.slice(0, LABELS_COLLAPSED)
    if (label && !head.some((l) => l.label === label)) {
      const active = labels.find((l) => l.label === label)
      if (active) return [...head, active]
    }
    return head
  }, [labels, labelsOpen, label])
  const hiddenLabels = labels.length - Math.min(labels.length, LABELS_COLLAPSED)
  const results = useMemo(
    // Không truyền `role`: màn tra cứu hiện mọi nút, kể cả nút chỉ đứng đầu luồng.
    () => searchNodes(deferredQ, { kind, label: label ?? undefined }),
    [deferredQ, kind, label],
  )

  /** Luồng đang mở chờ nhận thành phần (K4-4); `null` là vào thẳng từ menu. */
  const [pending, setPending] = useState(() => readPendingTarget())
  useEffect(() => {
    // Đọc lại mỗi lần quay lại màn: người dùng có thể mở luồng khác ở tab khác.
    const onFocus = () => setPending(readPendingTarget())
    window.addEventListener('focus', onFocus)
    return () => window.removeEventListener('focus', onFocus)
  }, [])

  function patch(next: Record<string, string | null>) {
    setParams((p) => {
      const q2 = new URLSearchParams(p)
      for (const [k, v] of Object.entries(next)) {
        if (v === null) q2.delete(k)
        else q2.set(k, v)
      }
      return q2
    })
  }

  function switchKind(k: NodeKind) {
    patch({ kind: k, label: null, node: null })
    setLabelsOpen(false)
    setScrollTop(0)
    listRef.current?.scrollTo({ top: 0 })
  }

  const first = Math.max(0, Math.floor(scrollTop / ROW_H) - OVERSCAN)
  const last = Math.min(results.length, Math.ceil((scrollTop + viewH) / ROW_H) + OVERSCAN)
  const slice = results.slice(first, last)

  return (
    // `page-fill` — màn tự quản chiều cao: hai panel cuộn riêng, thanh lọc dính trên.
    // Xem luật bố cục ở `styles.css`.
    <div className="cat page-fill">
      <div className="cat__head">
        <div>
          <h1 className="cat__title">Danh mục thành phần Camel</h1>
          <p className="cat__sub">
            {CATALOG_TOTAL} nút đã vendor sẵn — tra cứu tham số, cú pháp URI và phụ thuộc trước
            khi dựng luồng. Bảng thành phần trong{' '}
            <Link to="/flows">trình thiết kế</Link> chỉ hiện loại thả được vào sơ đồ.
          </p>
        </div>
      </div>

      {pending && (
        // K4-4 — người dùng bấm "Tìm trong danh mục" từ trình thiết kế. Nói rõ họ đang ở
        // giữa một thao tác dở dang, kèm lối quay lại; không thì nút "Thêm vào luồng" ở
        // trang chi tiết hiện ra mà không rõ *luồng nào*.
        <div className="cat__pending">
          <span>
            Đang chọn thành phần cho luồng <strong>{pending.code}</strong>
            {pending.title ? ` · ${pending.title}` : ''}
          </span>
          <button
            type="button"
            className="cat__link-btn"
            onClick={() => navigate(`/flows/${pending.code}/design`)}
          >
            Quay lại trình thiết kế
          </button>
        </div>
      )}

      <div className="cat__body">
        <div className="cat__list-pane">
          <input
            className="cat__search"
            type="search"
            placeholder="Tìm theo tên, tiêu đề, mô tả hoặc nhãn…"
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            aria-label="Tìm trong danh mục thành phần Camel"
          />

          <div className="cat__tabs" role="tablist" aria-label="Loại thành phần">
            {ALL_KINDS.map((k) => (
              <button
                key={k}
                type="button"
                role="tab"
                aria-selected={kind === k}
                className={kind === k ? 'cat__tab is-active' : 'cat__tab'}
                onClick={() => switchKind(k)}
              >
                {KIND_VI[k]} <span className="cat__tab-n">{CATALOG_COUNTS[k] ?? 0}</span>
              </button>
            ))}
          </div>

          {labels.length > 0 && (
            /* Thành phần có 48 nhãn — hiện hết chiếm gần nửa panel, mà cắt cụt bằng
               `max-height` thì người dùng không biết còn nhãn bên dưới. Cho gập/mở, mặc
               định hiện `LABELS_COLLAPSED` nhãn phổ biến nhất và nói rõ còn bao nhiêu. */
            <div className="cat__chips">
              <button
                type="button"
                className={label === null ? 'cat__chip is-active' : 'cat__chip'}
                onClick={() => patch({ label: null })}
              >
                Tất cả <span className="cat__chip-n">{CATALOG_COUNTS[kind] ?? 0}</span>
              </button>
              {shownLabels.map((l) => (
                <button
                  key={l.label}
                  type="button"
                  className={label === l.label ? 'cat__chip is-active' : 'cat__chip'}
                  onClick={() => patch({ label: label === l.label ? null : l.label })}
                >
                  {labelVi(l.label)} <span className="cat__chip-n">{l.count}</span>
                </button>
              ))}
              {hiddenLabels > 0 && (
                <button
                  type="button"
                  className="cat__chip cat__chip--more"
                  aria-expanded={labelsOpen}
                  onClick={() => setLabelsOpen((v) => !v)}
                >
                  {labelsOpen ? 'Thu gọn' : `+${hiddenLabels} nhãn nữa`}
                </button>
              )}
            </div>
          )}

          <div className="cat__count" aria-live="polite">
            {results.length} / {CATALOG_COUNTS[kind] ?? 0} mục
          </div>

          <div
            className="cat__list"
            ref={listRef}
            onScroll={(e) => {
              setScrollTop(e.currentTarget.scrollTop)
              setViewH(e.currentTarget.clientHeight)
            }}
          >
            {results.length === 0 ? (
              <p className="cat__empty">Không có mục nào khớp từ khóa.</p>
            ) : (
              // Khối đệm giữ đúng chiều cao tổng để thanh cuộn phản ánh số mục thật.
              <div style={{ height: results.length * ROW_H, position: 'relative' }}>
                <div style={{ transform: `translateY(${first * ROW_H}px)` }}>
                  {slice.map((n) => (
                    <CatalogRow
                      key={refOf(n)}
                      node={n}
                      active={selected === refOf(n)}
                      onPick={() => patch({ node: refOf(n) })}
                    />
                  ))}
                </div>
              </div>
            )}
          </div>

          <CatalogLicense />
        </div>

        <div className="cat__detail-pane">
          {selected ? (
            <NodeDetail nodeRef={selected} pending={pending} />
          ) : (
            <p className="cat__hint">Chọn một mục bên trái để xem mô tả và bảng tham số đầy đủ.</p>
          )}
        </div>
      </div>
    </div>
  )
}

function CatalogRow({
  node,
  active,
  onPick,
}: {
  node: CatalogNode
  active: boolean
  onPick: () => void
}) {
  const tone = toneOfNode(node)
  return (
    <button
      type="button"
      className={active ? 'cat__row is-active' : 'cat__row'}
      style={{ height: ROW_H }}
      onClick={onPick}
      aria-current={active ? 'true' : undefined}
      // Tên nội dung nằm trong `span` lồng nhau nên trình đọc màn hình suy ra tên rỗng —
      // cây khả truy cập chỉ đọc "button", không phân biệt nổi 323 hàng với nhau.
      // Đặt tên tường minh gồm cả tên trần vì đó là thứ người dùng gõ vào YAML.
      aria-label={`${node.title} (${node.name})`}
    >
      <span className={`cat__icon cat__icon--${tone}`} aria-hidden="true">
        {TONE_ICON[tone]}
      </span>
      <span className="cat__row-text">
        <span className="cat__row-name">
          {node.title}
          {node.deprecated && <span className="cat__badge cat__badge--warn">không dùng nữa</span>}
          {node.supportLevel === 'Preview' && <span className="cat__badge">thử nghiệm</span>}
          {/* Không chạy được ở ảnh native là ràng buộc thật với ADR-002/020. */}
          {node.nativeSupported === false && (
            <span className="cat__badge cat__badge--warn">không native</span>
          )}
        </span>
        <span className="cat__row-desc">{node.description || node.name}</span>
      </span>
      <span className="cat__row-ref">{node.name}</span>
    </button>
  )
}
