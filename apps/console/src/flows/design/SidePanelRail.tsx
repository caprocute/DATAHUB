import type { ReactNode } from 'react'

/**
 * Một thẻ trên thanh ray — mô tả **một chức năng** của panel bên.
 *
 * Thêm màn mới về sau chỉ là thêm một phần tử vào mảng truyền cho `SidePanelRail`,
 * không phải sửa bố cục: đó là lý do panel bên được tách ra thành ray thẻ thay vì
 * xếp chồng mọi khối vào cùng một cột như trước.
 */
export interface RailTab {
  /** Mã thẻ, dùng để nhớ thẻ đang mở. */
  key: string
  /** Nhãn dọc trên ray — giữ ngắn, ray chỉ rộng 40px. */
  label: string
  /** Đếm phụ hiện cạnh nhãn (số route, số lỗi…). Bỏ trống thì không hiện. */
  badge?: number
  /** Tông màu thẻ, để phân biệt nhóm chức năng bằng mắt. */
  tone?: 'brand' | 'ok' | 'warn' | 'err'
  /** Nội dung panel — chỉ dựng khi thẻ đang mở. */
  render: () => ReactNode
}

interface Props {
  tabs: RailTab[]
  /** Thẻ đang mở; `null` là panel đang thu gọn hẳn, chỉ còn ray. */
  active: string | null
  onChange: (key: string | null) => void
  /** Ray nằm bên nào của panel — quyết định phía bo góc và chiều mũi tên. */
  side: 'left' | 'right'
}

/**
 * Panel bên dạng **ray thẻ** (thay cho kiểu xếp chồng nhiều khối trong một cột).
 *
 * Kiểu cũ nhét danh sách route, bảng thành phần vào cùng một cột dọc nên mỗi khối chỉ
 * còn một mẩu chiều cao — khối "thêm route" bị ép xuống còn một dòng, còn danh sách 751
 * thành phần thì phải cuộn trong khoảng chật. Ray thẻ cho **mỗi chức năng dùng trọn
 * chiều cao** panel, đổi qua lại bằng một cú bấm.
 *
 * Bấm lại thẻ đang mở thì thu gọn panel — người dùng cần chỗ cho sơ đồ thì không phải
 * đi tìm nút gập riêng.
 */
export function SidePanelRail({ tabs, active, onChange, side }: Props) {
  const current = tabs.find((t) => t.key === active) ?? null

  const rail = (
    <div className={`dsg-rail dsg-rail--${side}`} role="tablist" aria-orientation="vertical">
      {tabs.map((t) => {
        const on = t.key === active
        return (
          <button
            key={t.key}
            type="button"
            role="tab"
            aria-selected={on}
            className={`dsg-rail__tab dsg-rail__tab--${t.tone ?? 'brand'}${on ? ' is-active' : ''}`}
            // Bấm lại thẻ đang mở = thu gọn panel.
            onClick={() => onChange(on ? null : t.key)}
            title={on ? `Thu gọn ${t.label}` : t.label}
          >
            <span className="dsg-rail__label">{t.label}</span>
            {t.badge !== undefined && t.badge > 0 && (
              <span className="dsg-rail__badge">{t.badge}</span>
            )}
          </button>
        )
      })}
    </div>
  )

  return (
    <>
      {side === 'right' && rail}
      {current && (
        <div className="dsg-rail__panel" role="tabpanel" aria-label={current.label}>
          {current.render()}
        </div>
      )}
      {side === 'left' && rail}
    </>
  )
}
