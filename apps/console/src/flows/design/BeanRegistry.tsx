import { Alert, Button, Input, Modal, Table } from 'antd'
import { useEffect, useState } from 'react'
import { readBeans, validateBeans, writeBeans, type BeanDef } from '../core/beans'
import type { CamelResource } from '../core/tree'

interface Props {
  open: boolean
  resource: CamelResource | null
  onClose: () => void
  onSave: (next: CamelResource) => void
}

/**
 * Sổ đăng ký bean cấp tệp (K5-1 — FR-D-080).
 *
 * Bean khai ở đây dùng được cho **mọi route trong tệp**, nên nó là cấu hình cấp tệp chứ
 * không thuộc chặng nào — vì vậy tách thành cửa sổ riêng thay vì nhét vào cấu hình chặng.
 *
 * Chặn lưu khi còn lỗi: bean trùng tên hoặc thiếu lớp thì Camel từ chối nạp, mà lỗi chỉ
 * hiện ra lúc publish — xa chỗ người dùng gây ra nó.
 */
export function BeanRegistry({ open, resource, onClose, onSave }: Props) {
  const [beans, setBeans] = useState<BeanDef[]>([])

  useEffect(() => {
    if (open && resource) setBeans(readBeans(resource))
  }, [open, resource])

  const findings = validateBeans(beans)
  const errors = findings.filter((f) => f.level === 'error')

  function patch(index: number, part: Partial<BeanDef>) {
    setBeans((bs) => bs.map((b, i) => (i === index ? { ...b, ...part } : b)))
  }

  /** Thuộc tính bean soạn dạng `khoa=giatri` mỗi dòng — gọn hơn bảng lồng bảng. */
  function propsToText(p: Record<string, string>): string {
    return Object.entries(p)
      .map(([k, v]) => `${k}=${v}`)
      .join('\n')
  }

  function textToProps(text: string): Record<string, string> {
    const out: Record<string, string> = {}
    for (const line of text.split('\n')) {
      const at = line.indexOf('=')
      if (at <= 0) continue
      out[line.slice(0, at).trim()] = line.slice(at + 1).trim()
    }
    return out
  }

  return (
    <Modal
      open={open}
      title="Bean dùng chung trong tệp"
      onCancel={onClose}
      onOk={() => {
        if (!resource || errors.length) return
        onSave(writeBeans(resource, beans))
        onClose()
      }}
      okText="Lưu bean"
      cancelText="Hủy"
      okButtonProps={{ disabled: errors.length > 0 }}
      width={860}
    >
      {errors.length > 0 && (
        <Alert
          type="error"
          showIcon
          className="kml__errs"
          message={errors.length === 1 ? errors[0].message : `${errors.length} lỗi cần sửa`}
          description={
            errors.length > 1 ? (
              <ul>
                {errors.map((e) => (
                  <li key={e.message}>{e.message}</li>
                ))}
              </ul>
            ) : undefined
          }
        />
      )}

      <Table<BeanDef>
        size="small"
        rowKey={(_, i) => String(i)}
        dataSource={beans}
        pagination={false}
        locale={{ emptyText: 'Chưa khai bean nào. Tệp không có bean vẫn hợp lệ.' }}
        columns={[
          {
            title: 'Tên',
            width: 170,
            render: (_, __, i) => (
              <Input
                size="small"
                value={beans[i].name}
                onChange={(e) => patch(i, { name: e.target.value })}
                placeholder="boChuyenDoi"
              />
            ),
          },
          {
            title: 'Lớp (fully qualified)',
            render: (_, __, i) => (
              <Input
                size="small"
                value={beans[i].type}
                onChange={(e) => patch(i, { type: e.target.value })}
                placeholder="vn.lgsp.ChuyenDoiCdm"
              />
            ),
          },
          {
            title: 'Thuộc tính (khoa=giatri mỗi dòng)',
            width: 280,
            render: (_, __, i) => (
              <Input.TextArea
                size="small"
                rows={2}
                value={propsToText(beans[i].properties)}
                onChange={(e) => patch(i, { properties: textToProps(e.target.value) })}
                placeholder={'muiGio=Asia/Ho_Chi_Minh\npassword={{vault:lgsp/db#password}}'}
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
                onClick={() => setBeans((bs) => bs.filter((_b, j) => j !== i))}
                title="Xóa bean"
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
          setBeans((bs) => [...bs, { name: '', type: '', properties: {}, rest: {} }])
        }
      >
        ＋ Thêm bean
      </Button>

      <p className="dsg__ents-hint">
        Không đặt bí mật thẳng vào đây (BR-D-02). Dùng <code>{'{{vault:...}}'}</code> hoặc
        tham chiếu kết nối PH-05.
      </p>
    </Modal>
  )
}
