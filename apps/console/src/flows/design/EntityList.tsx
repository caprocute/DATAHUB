import { App as AntApp, Button, Dropdown, Input } from 'antd'
import { useState } from 'react'
import type { CamelResource } from '../core/tree'

interface Props {
  resource: CamelResource | null
  activeIndex: number
  onSelect: (index: number) => void
  onAdd: (id: string) => void
  onRemove: (index: number) => void
  onDuplicate: (index: number, newId: string) => void
  onRename: (index: number, newId: string) => void
  disabled?: boolean
}

/** Mã hợp lệ cho route: chữ thường, số, gạch ngang — đúng luật `route_code` của máy chủ. */
const ID_RE = /^[a-z0-9][a-z0-9-]*$/

/**
 * Danh sách thực thể trong một tệp (FR-D-005/006/007 — K2-1).
 *
 * Một tệp Camel YAML chứa được **nhiều route**; trước đây trình thiết kế chỉ mở được một
 * và bộ đọc cũ còn từ chối hẳn tệp nhiều route. Bảng này là chỗ chuyển qua lại giữa chúng.
 *
 * Nay nằm trong **thẻ riêng** trên ray panel trái nên luôn hiện đủ danh sách, kể cả khi
 * tệp mới có một route: thẻ đã là chỗ dành riêng, không còn giành chiều cao với bảng
 * thành phần như hồi hai khối xếp chồng trong một cột.
 */
export function EntityList({
  resource,
  activeIndex,
  onSelect,
  onAdd,
  onRemove,
  onDuplicate,
  onRename,
  disabled,
}: Props) {
  const { modal } = AntApp.useApp()
  const [adding, setAdding] = useState(false)
  const [draft, setDraft] = useState('')
  const [error, setError] = useState<string | null>(null)

  const entities = resource?.entities ?? []

  /** Kiểm mã trước khi nhận: trùng mã làm hai route đè lên nhau khi Camel nạp. */
  function validate(id: string, exceptIndex = -1): string | null {
    const v = id.trim()
    if (!v) return 'Chưa nhập mã route'
    if (!ID_RE.test(v)) return 'Chỉ dùng chữ thường, số và dấu gạch ngang'
    if (entities.some((e, i) => e.id === v && i !== exceptIndex)) return `Mã “${v}” đã có trong tệp`
    return null
  }

  function commitAdd() {
    const err = validate(draft)
    if (err) {
      setError(err)
      return
    }
    onAdd(draft.trim())
    setAdding(false)
    setDraft('')
  }

  function promptRename(index: number) {
    let value = entities[index].id
    modal.confirm({
      title: 'Đổi mã route',
      content: (
        <div>
          <Input
            defaultValue={value}
            onChange={(e) => {
              value = e.target.value
            }}
            placeholder="ma-route-moi"
          />
          <p className="dsg__ents-hint">
            Mọi tham chiếu <code>direct:</code>/<code>seda:</code> trỏ tới route này sẽ được
            sửa theo.
          </p>
        </div>
      ),
      okText: 'Đổi mã',
      cancelText: 'Hủy',
      onOk: () => {
        const err = validate(value, index)
        if (err) return Promise.reject(new Error(err))
        onRename(index, value.trim())
        return Promise.resolve()
      },
    })
  }

  function promptRemove(index: number) {
    modal.confirm({
      title: `Xóa route “${entities[index].id || '(chưa đặt mã)'}”?`,
      content: 'Route này và mọi chặng bên trong sẽ bị gỡ khỏi tệp. Hoàn tác được bằng ⌘Z.',
      okText: 'Xóa',
      okButtonProps: { danger: true },
      cancelText: 'Hủy',
      onOk: () => onRemove(index),
    })
  }

  return (
    <div className="dsg__ents">
      <div className="dsg__panel-head">
        Route trong tệp
        <span className="count">{entities.length}</span>
      </div>

      <ul className="dsg__ents-list">
        {entities.map((e, i) => (
          <li key={`${e.path}-${i}`}>
            <button
              type="button"
              className={i === activeIndex ? 'dsg__ent is-active' : 'dsg__ent'}
              onClick={() => onSelect(i)}
              title={e.from?.uri ?? e.kind}
            >
              <span className="dsg__ent-name">{e.id || '(chưa đặt mã)'}</span>
              <span className="dsg__ent-sub">{e.from?.uri ?? e.kind}</span>
            </button>
            <Dropdown
              trigger={['click']}
              disabled={disabled}
              menu={{
                items: [
                  { key: 'rename', label: 'Đổi mã' },
                  { key: 'dup', label: 'Nhân bản' },
                  {
                    key: 'del',
                    label: 'Xóa',
                    danger: true,
                    // Tệp phải còn ít nhất một route — xóa hết thì không còn gì để vẽ.
                    disabled: entities.length <= 1,
                  },
                ],
                onClick: ({ key }) => {
                  if (key === 'rename') promptRename(i)
                  if (key === 'dup') onDuplicate(i, uniqueId(entities.map((x) => x.id), e.id))
                  if (key === 'del') promptRemove(i)
                },
              }}
            >
              <button type="button" className="dsg__ent-more" title="Thao tác">
                ⋯
              </button>
            </Dropdown>
          </li>
        ))}
      </ul>

      {adding ? (
        <div className="dsg__ents-add-row">
          <Input
            autoFocus
            size="small"
            value={draft}
            placeholder="ma-route-moi"
            status={error ? 'error' : undefined}
            onChange={(e) => {
              setDraft(e.target.value)
              setError(null)
            }}
            onPressEnter={commitAdd}
          />
          <Button size="small" type="primary" onClick={commitAdd}>
            Thêm
          </Button>
          <Button size="small" onClick={() => setAdding(false)}>
            Hủy
          </Button>
          {error && <div className="dsg__ents-err">{error}</div>}
        </div>
      ) : (
        <button
          type="button"
          className="dsg__ents-add"
          onClick={() => {
            setDraft('')
            setError(null)
            setAdding(true)
          }}
          disabled={disabled}
        >
          ＋ Thêm route
        </button>
      )}
    </div>
  )
}

/** Sinh mã chưa dùng cho bản sao: `ma` → `ma-ban-sao`, đụng nữa thì thêm số. */
export function uniqueId(taken: string[], base: string): string {
  const seed = `${base || 'route'}-ban-sao`
  if (!taken.includes(seed)) return seed
  for (let n = 2; ; n += 1) {
    const candidate = `${seed}-${n}`
    if (!taken.includes(candidate)) return candidate
  }
}
