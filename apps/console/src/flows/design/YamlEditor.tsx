import { Alert, Button, Modal, Space, Typography } from 'antd'
import { useEffect, useState } from 'react'
import { deserialize, DeserializeError } from '../core/deserialize'
import { flatten } from '../core/flatten'
import { bumpSeq, type SeqEdge, type StageNode } from '../core/model'
import type { CamelResource } from '../core/tree'

interface Props {
  open: boolean
  /** YAML đang sinh từ sơ đồ — nguồn để mở trình soạn. */
  yaml: string
  onClose: () => void
  /**
   * Áp YAML đã sửa ngược lại sơ đồ.
   *
   * Trả kèm **cây** vừa đọc: trình thiết kế phải thay cây đang giữ, không thì lần sinh
   * YAML sau vẫn áp thay đổi lên cây cũ và **nuốt mất** bản sửa tay.
   */
  onApply: (nodes: StageNode[], edges: SeqEdge[], tree: CamelResource) => void
}

/**
 * D-02 — Xem và sửa YAML ở cửa sổ lớn, đồng bộ ngược về sơ đồ.
 *
 * Panel YAML bên phải chỉ đủ liếc qua; đọc nghiêm túc hay sửa tay thì cần cả màn hình.
 *
 * Đồng bộ ngược đi qua lõi cây (K1 — IP-07), nên **mọi cấu trúc Camel hợp lệ** đều đọc
 * được, kể cả `doTry`/`loadBalance` và nhiều route một tệp. Chỉ YAML **hỏng cú pháp**
 * mới bị từ chối, kèm số dòng — giữ nguyên sơ đồ thay vì dựng ra sơ đồ sai.
 */
export function YamlEditor({ open, yaml, onClose, onApply }: Props) {
  const [draft, setDraft] = useState(yaml)
  const [error, setError] = useState<string | null>(null)

  // Mở lại thì lấy bản mới nhất từ sơ đồ, không giữ bản nháp cũ đã lạc hậu.
  useEffect(() => {
    if (open) {
      setDraft(yaml)
      setError(null)
    }
  }, [open, yaml])

  const dirty = draft !== yaml

  function apply() {
    try {
      const tree = deserialize(draft)
      const g = flatten(tree)
      // Đẩy bộ đếm mã vượt mọi mã vừa nạp, không thì chặng thêm sau sẽ trùng mã và
      // React Flow bỏ mất nút (lỗi đã gặp ở IP-06 §0).
      bumpSeq([...g.nodes.map((n) => n.id), ...g.edges.map((e) => e.id)])
      onApply(g.nodes, g.edges, tree)
      setError(null)
      onClose()
    } catch (e) {
      // Đọc không được thì **giữ nguyên sơ đồ** và nói rõ dòng lỗi.
      setError(
        e instanceof DeserializeError && e.line
          ? `Dòng ${e.line}: ${e.message}`
          : String(e instanceof Error ? e.message : e),
      )
    }
  }

  return (
    <Modal
      open={open}
      onCancel={onClose}
      footer={null}
      className="cfg-modal yml-modal"
      width="95vw"
      centered
      destroyOnHidden
      title={
        <Space>
          <span>Camel YAML DSL</span>
          <Typography.Text type="secondary" className="t-small">
            {draft.trimEnd().split('\n').length} dòng
            {dirty && ' · đã sửa, chưa áp'}
          </Typography.Text>
        </Space>
      }
    >
      <div className="yml">
        {error && (
          <Alert
            type="error"
            showIcon
            className="yml__err"
            message="Không đọc được YAML — sơ đồ giữ nguyên"
            description={error}
          />
        )}
        <textarea
          className="yml__code"
          spellCheck={false}
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          aria-label="Nội dung Camel YAML DSL"
        />
      </div>

      <div className="cfg__foot">
        <div className="cfg__foot-left">
          <Typography.Text type="secondary" className="cfg__hint">
            Sửa ở đây rồi «Áp vào sơ đồ». Chỉ đọc được tập con mà trình thiết kế sinh ra.
          </Typography.Text>
        </div>
        <Button size="small" disabled={!dirty} onClick={() => setDraft(yaml)}>
          Hoàn tác
        </Button>
        <Button type="primary" disabled={!dirty} onClick={apply}>
          Áp vào sơ đồ
        </Button>
      </div>
    </Modal>
  )
}
