import { Alert, Button, Checkbox, Input, Modal, Select, Table } from 'antd'
import { useEffect, useState } from 'react'
import {
  KAMELET_PROP_TYPES,
  readMeta,
  readProps,
  validateProps,
  writeMeta,
  writeProps,
  type KameletProp,
} from '../core/kamelet'
import type { CamelResource } from '../core/tree'

interface Props {
  open: boolean
  resource: CamelResource | null
  onClose: () => void
  onSave: (next: CamelResource) => void
}

/**
 * Trình soạn tham số Kamelet (K3-1 — FR-D-061).
 *
 * Kamelet là **mảnh dùng lại**, nên tham số là mặt tiếp xúc với người dùng khác — đặt sai
 * kiểu hay thiếu mô tả thì người dùng lại phải mở YAML ra đọc mới hiểu. Bảng này soạn
 * `spec.definition` đúng dạng JSON Schema mà 243 kamelet gốc dùng.
 */
export function KameletSpec({ open, resource, onClose, onSave }: Props) {
  const [props, setProps] = useState<KameletProp[]>([])
  const [title, setTitle] = useState('')
  const [desc, setDesc] = useState('')

  // Mở lại thì lấy bản mới nhất từ cây, không giữ bản nháp cũ đã lạc hậu.
  useEffect(() => {
    if (!open || !resource) return
    setProps(readProps(resource))
    const m = readMeta(resource)
    setTitle(m.title)
    setDesc(m.description)
  }, [open, resource])

  const errors = validateProps(props)

  function save() {
    if (!resource || errors.length) return
    onSave(writeProps(writeMeta(resource, { title, description: desc }), props))
    onClose()
  }

  function patch(index: number, part: Partial<KameletProp>) {
    setProps((ps) => ps.map((p, i) => (i === index ? { ...p, ...part } : p)))
  }

  return (
    <Modal
      open={open}
      title="Tham số Kamelet"
      onCancel={onClose}
      onOk={save}
      okText="Lưu tham số"
      cancelText="Hủy"
      okButtonProps={{ disabled: errors.length > 0 }}
      width={900}
    >
      <div className="kml__meta">
        <label>
          <span>Tiêu đề</span>
          <Input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Nguồn dữ liệu X" />
        </label>
        <label>
          <span>Mô tả</span>
          <Input value={desc} onChange={(e) => setDesc(e.target.value)} placeholder="Kamelet này làm gì" />
        </label>
      </div>

      {errors.length > 0 && (
        <Alert
          type="error"
          showIcon
          className="kml__errs"
          message={errors.length === 1 ? errors[0] : `${errors.length} lỗi cần sửa`}
          description={
            errors.length > 1 ? (
              <ul>
                {errors.map((e) => (
                  <li key={e}>{e}</li>
                ))}
              </ul>
            ) : undefined
          }
        />
      )}

      <Table<KameletProp>
        size="small"
        rowKey={(_, i) => String(i)}
        dataSource={props}
        pagination={false}
        locale={{ emptyText: 'Chưa có tham số nào. Kamelet không tham số vẫn hợp lệ.' }}
        columns={[
          {
            title: 'Tên',
            dataIndex: 'name',
            width: 160,
            render: (_, __, i) => (
              <Input
                size="small"
                value={props[i].name}
                onChange={(e) => patch(i, { name: e.target.value })}
                placeholder="tenThamSo"
              />
            ),
          },
          {
            title: 'Kiểu',
            dataIndex: 'type',
            width: 120,
            render: (_, __, i) => (
              <Select
                size="small"
                style={{ width: '100%' }}
                value={props[i].type}
                onChange={(v) => patch(i, { type: v })}
                options={KAMELET_PROP_TYPES.map((t) => ({ value: t, label: t }))}
              />
            ),
          },
          {
            title: 'Nhãn',
            dataIndex: 'title',
            render: (_, __, i) => (
              <Input
                size="small"
                value={props[i].title ?? ''}
                onChange={(e) => patch(i, { title: e.target.value })}
              />
            ),
          },
          {
            title: 'Mô tả',
            dataIndex: 'description',
            render: (_, __, i) => (
              <Input
                size="small"
                value={props[i].description ?? ''}
                onChange={(e) => patch(i, { description: e.target.value })}
              />
            ),
          },
          {
            title: 'Mặc định',
            dataIndex: 'default',
            width: 120,
            render: (_, __, i) => (
              <Input
                size="small"
                value={props[i].default === undefined ? '' : String(props[i].default)}
                onChange={(e) => {
                  const raw = e.target.value
                  // Giữ đúng kiểu: mặc định của tham số số mà ghi ra chuỗi thì Camel
                  // từ chối nạp kamelet.
                  const t = props[i].type
                  const val =
                    raw === ''
                      ? undefined
                      : t === 'integer' || t === 'long'
                        ? Number.isFinite(Number(raw))
                          ? Number(raw)
                          : raw
                        : t === 'boolean'
                          ? raw === 'true'
                          : raw
                  patch(i, { default: val as KameletProp['default'] })
                }}
              />
            ),
          },
          {
            title: 'Bắt buộc',
            dataIndex: 'required',
            width: 90,
            align: 'center',
            render: (_, __, i) => (
              <Checkbox
                checked={props[i].required}
                onChange={(e) => patch(i, { required: e.target.checked })}
              />
            ),
          },
          {
            title: '',
            width: 48,
            render: (_, __, i) => (
              <Button
                size="small"
                type="text"
                danger
                onClick={() => setProps((ps) => ps.filter((_p, j) => j !== i))}
                title="Xóa tham số"
              >
                ✕
              </Button>
            ),
          },
        ]}
      />

      <Button
        className="kml__add"
        size="small"
        onClick={() =>
          setProps((ps) => [...ps, { name: '', type: 'string', required: false }])
        }
      >
        ＋ Thêm tham số
      </Button>
    </Modal>
  )
}
