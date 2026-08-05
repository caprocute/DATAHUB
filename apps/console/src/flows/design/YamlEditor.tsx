import { Alert, Button, Modal, Space, Typography } from 'antd'
import { useEffect, useState } from 'react'
import { graphFromYaml, YamlParseError } from '../core/parse'
import { bumpSeq, type SeqEdge, type StageNode } from '../core/model'

interface Props {
  open: boolean
  /** YAML đang sinh từ sơ đồ — nguồn để mở trình soạn. */
  yaml: string
  onClose: () => void
  /** Áp YAML đã sửa ngược lại sơ đồ. */
  onApply: (nodes: StageNode[], edges: SeqEdge[]) => void
}

/**
 * D-02 — Xem và sửa YAML ở cửa sổ lớn, đồng bộ ngược về sơ đồ.
 *
 * Panel YAML bên phải chỉ đủ liếc qua; đọc nghiêm túc hay sửa tay thì cần cả màn hình.
 *
 * Đồng bộ ngược đi qua `graphFromYaml` — bộ đọc **chỉ hiểu tập con** mà trình thiết kế
 * sinh ra. Cấu trúc ngoài tập con bị từ chối kèm số dòng thay vì dựng ra sơ đồ sai:
 * mất công sức của người dùng còn tệ hơn là báo "chưa đọc được".
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
      const g = graphFromYaml(draft)
      // Đẩy bộ đếm mã vượt mọi mã vừa nạp, không thì chặng thêm sau sẽ trùng mã và
      // React Flow bỏ mất nút (lỗi đã gặp ở IP-06 §0).
      bumpSeq([...g.nodes.map((n) => n.id), ...g.edges.map((e) => e.id)])
      onApply(g.nodes, g.edges)
      setError(null)
      onClose()
    } catch (e) {
      // Đọc không được thì **giữ nguyên sơ đồ** và nói rõ dòng lỗi.
      setError(
        e instanceof YamlParseError && e.line
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
