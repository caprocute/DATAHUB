import { Button, Empty, Input, InputNumber, Modal, Select, Switch, Tabs, Tooltip, Typography } from 'antd'
import { useEffect, useMemo, useState } from 'react'
import {
  GROUP_VI,
  groupOf,
  loadSchema,
  lookupNode,
  peekSchema,
  refName,
  type PropGroup,
  type PropertiesSchema,
  type SchemaProp,
} from '../core/catalog'
import type { StageNode } from '../core/model'
import { ExpressionField } from './ExpressionField'

type PropValue = string | number | boolean

interface Props {
  open: boolean
  node: StageNode | undefined
  onClose: () => void
  onLabel: (v: string) => void
  onUri: (v: string) => void
  onProp: (key: string, v: PropValue | undefined) => void
  onPin: (v: string | undefined) => void
  onNote: (v: string) => void
  onDelete: () => void
  sample?: { sample: string; inherited: boolean }
  runOutput?: { status: string; durationMs: number; detail?: string }
  env?: Record<string, string>
}

/** Trường mang bí mật — không bao giờ nhập thẳng trên node (BR-D-02). */
const SECRET_HINT = /password|secret|token|credential|accesskey|privatekey|passphrase|apikey/i

function isSecret(name: string, s: SchemaProp): boolean {
  return SECRET_HINT.test(name) || SECRET_HINT.test(s.title ?? '') || s.format === 'password'
}

function isExpression(name: string, s: SchemaProp): boolean {
  if (s.enum?.length || s.type === 'boolean') return false
  return /expression|predicate|simple|language|correlationExpression|completionPredicate/i.test(
    `${name} ${s.title ?? ''}`,
  )
}

/** Trường kiểu thời lượng — hiện ô số kèm đơn vị thay vì ô text. */
function isDuration(name: string, s: SchemaProp): boolean {
  return s.format === 'duration' || /timeout|delay|period|interval|ttl/i.test(name)
}

/**
 * Sinh điều khiển theo **kiểu thật** trong lược đồ (FR-D-022).
 *
 * Catalog có 876 trường `enum` — dùng ô text cho chúng là bắt người dùng đoán giá trị
 * hợp lệ, đây là điểm bản trước làm sai khiến "751 nút trông không khác gì nhau".
 */
/**
 * Bảng khóa–giá trị cho trường `object` / `array` (FR-D-022, G4-6).
 *
 * Giá trị vẫn lưu dưới dạng chuỗi JSON để không phải đổi kiểu `props`; bảng chỉ là lớp
 * soạn thảo bên trên. JSON hỏng thì **không** nuốt mất dữ liệu — hiện ô text thô để
 * người dùng tự sửa, vì im lặng ghi đè bằng bảng rỗng là xóa cấu hình của họ.
 */
function KeyValueTable({
  value,
  onChange,
  arrayMode,
}: {
  value: string
  onChange: (v: string) => void
  arrayMode: boolean
}) {
  const parsed = useMemo((): { rows: [string, string][]; broken: boolean } => {
    if (!value.trim()) return { rows: [], broken: false }
    try {
      const j: unknown = JSON.parse(value)
      if (Array.isArray(j)) {
        return { rows: j.map((v, i) => [String(i), typeof v === 'string' ? v : JSON.stringify(v)]), broken: false }
      }
      if (j && typeof j === 'object') {
        return {
          rows: Object.entries(j as Record<string, unknown>).map(([k, v]) => [
            k,
            typeof v === 'string' ? v : JSON.stringify(v),
          ]),
          broken: false,
        }
      }
      return { rows: [], broken: true }
    } catch {
      return { rows: [], broken: true }
    }
  }, [value])

  function write(rows: [string, string][]) {
    if (arrayMode) {
      onChange(rows.length ? JSON.stringify(rows.map(([, v]) => v)) : '')
      return
    }
    const obj: Record<string, string> = {}
    for (const [k, v] of rows) if (k.trim()) obj[k] = v
    onChange(Object.keys(obj).length ? JSON.stringify(obj) : '')
  }

  if (parsed.broken) {
    return (
      <>
        <Input.TextArea
          size="small"
          autoSize={{ minRows: 2, maxRows: 6 }}
          value={value}
          onChange={(e) => onChange(e.target.value)}
        />
        <div className="cfg__hint cfg__hint--warn">
          Giá trị hiện không phải JSON hợp lệ nên chưa mở được dạng bảng. Sửa ở đây rồi
          bảng sẽ hiện lại — dữ liệu của bạn không bị xóa.
        </div>
      </>
    )
  }

  return (
    <div className="cfg__kv">
      {parsed.rows.map(([k, v], i) => (
        <div className="cfg__kv-row" key={i}>
          {!arrayMode && (
            <Input
              size="small"
              placeholder="khóa"
              value={k}
              onChange={(e) => {
                const next = [...parsed.rows]
                next[i] = [e.target.value, v]
                write(next)
              }}
            />
          )}
          <Input
            size="small"
            placeholder={arrayMode ? `phần tử ${i + 1}` : 'giá trị'}
            value={v}
            onChange={(e) => {
              const next = [...parsed.rows]
              next[i] = [k, e.target.value]
              write(next)
            }}
          />
          <Button
            size="small"
            type="text"
            danger
            title="Xóa dòng"
            onClick={() => write(parsed.rows.filter((_, j) => j !== i))}
          >
            ×
          </Button>
        </div>
      ))}
      <Button
        size="small"
        type="dashed"
        block
        onClick={() => write([...parsed.rows, [arrayMode ? String(parsed.rows.length) : '', '']])}
      >
        + Thêm {arrayMode ? 'phần tử' : 'khóa'}
      </Button>
    </div>
  )
}

function Control({
  name,
  schema,
  value,
  onChange,
  sample,
  env,
}: {
  name: string
  schema: SchemaProp
  value: PropValue | undefined
  onChange: (v: PropValue | undefined) => void
  sample?: { sample: string; inherited: boolean }
  env?: Record<string, string>
}) {
  const placeholder = schema.default !== undefined ? `mặc định: ${String(schema.default)}` : ''

  if (isSecret(name, schema)) {
    return (
      <>
        <Input
          size="small"
          readOnly
          value={value === undefined ? '' : String(value)}
          placeholder="Tham chiếu kết nối, ví dụ {{vault:lgsp/adapter#matKhau}}"
        />
        <div className="cfg__hint cfg__hint--warn">
          Trường bí mật — chọn kết nối đã đăng ký ở PH-05 hoặc tham chiếu Vault. Không dán giá trị thật.
        </div>
      </>
    )
  }

  if (schema.enum?.length) {
    return (
      <Select
        size="small"
        style={{ width: '100%' }}
        allowClear
        showSearch
        placeholder={placeholder || 'Chọn giá trị'}
        value={value === undefined || value === '' ? undefined : String(value)}
        onChange={(v) => onChange(v ?? undefined)}
        options={schema.enum.map((o) => ({ value: o, label: o }))}
      />
    )
  }

  if (schema.type === 'boolean') {
    return (
      <div className="cfg__switch">
        <Switch
          size="small"
          checked={value === true || value === 'true'}
          onChange={onChange}
          aria-label={schema.title ?? name}
        />
        <span className="cfg__hint">
          {value === undefined ? `chưa đặt (mặc định ${String(schema.default ?? false)})` : ''}
        </span>
      </div>
    )
  }

  if (isExpression(name, schema)) {
    return (
      <ExpressionField
        value={value === undefined ? '' : String(value)}
        onChange={(v) => onChange(v === '' ? undefined : v)}
        sample={sample?.sample}
        inherited={sample?.inherited}
        env={env}
        rows={1}
      />
    )
  }

  // Trường `object`/`array`: bảng khóa–giá trị (FR-D-022, G4-6).
  //
  // Camel nhận các trường này dạng map tham số (ví dụ `headers`, `parameters`). Ô text
  // trần bắt người dùng tự gõ JSON đúng cú pháp, sai một dấu ngoặc là hỏng cả route mà
  // chỉ biết khi Camel từ chối nạp.
  if (schema.type === 'object' || schema.type === 'array') {
    return (
      <KeyValueTable
        value={value === undefined ? '' : String(value)}
        onChange={(v) => onChange(v === '' ? undefined : v)}
        arrayMode={schema.type === 'array'}
      />
    )
  }

  if (schema.type === 'integer' || schema.type === 'number' || isDuration(name, schema)) {
    return (
      <div className="cfg__num">
        <InputNumber
          size="small"
          style={{ width: '100%' }}
          placeholder={placeholder}
          value={typeof value === 'number' ? value : value === undefined || value === '' ? null : Number(value)}
          onChange={(v) => onChange(v === null ? undefined : Number(v))}
        />
        {isDuration(name, schema) && <span className="cfg__unit">ms</span>}
      </div>
    )
  }

  return (
    <Input
      size="small"
      placeholder={placeholder}
      value={value === undefined ? '' : String(value)}
      onChange={(e) => onChange(e.target.value === '' ? undefined : e.target.value)}
    />
  )
}

function Field({
  name,
  schema,
  required,
  value,
  onChange,
  sample,
  env,
}: {
  name: string
  schema: SchemaProp
  required: boolean
  value: PropValue | undefined
  onChange: (v: PropValue | undefined) => void
  sample?: { sample: string; inherited: boolean }
  env?: Record<string, string>
}) {
  const missing = required && (value === undefined || value === '')
  return (
    <div className={missing ? 'cfg__field cfg__field--missing' : 'cfg__field'}>
      <label className="cfg__label">
        {schema.title ?? name}
        {required && <span className="cfg__req"> *</span>}
        {schema.deprecated && <span className="cfg__dep">đã ngừng khuyến nghị</span>}
        {schema.description && (
          <Tooltip title={schema.description} placement="topLeft">
            <span className="cfg__info" aria-hidden="true">
              ⓘ
            </span>
          </Tooltip>
        )}
      </label>
      <Control
        name={name}
        schema={schema}
        value={value}
        onChange={onChange}
        sample={sample}
        env={env}
      />
      <div className="cfg__param">{name}</div>
      {missing && <div className="cfg__hint cfg__hint--err">Trường bắt buộc</div>}
    </div>
  )
}

/**
 * D-03 — Cửa sổ cấu hình một chặng.
 *
 * Chốt **75% × 75%** màn hình: lược đồ Camel có trung vị 19 thuộc tính, p90 64 và tối
 * đa 154 — cửa sổ nhỏ như bản trước không thể dùng được. Tab chia theo **nhóm gốc**
 * của catalog (Kaoto), bố cục ba cột INPUT│THAM SỐ│OUTPUT theo thẩm mỹ n8n.
 */
export function NodeConfig({
  open,
  node,
  onClose,
  onLabel,
  onUri,
  onProp,
  onPin,
  onNote,
  onDelete,
  sample,
  runOutput,
  env,
}: Props) {
  const entry = node ? lookupNode(node.data.ref) : undefined
  const [schema, setSchema] = useState<PropertiesSchema>({})
  const [tab, setTab] = useState<string>('common')
  const [fieldQuery, setFieldQuery] = useState('')
  const [showAll, setShowAll] = useState(false)

  useEffect(() => {
    if (!open || !entry) {
      setSchema({})
      return
    }
    let alive = true
    setSchema(peekSchema(entry) ?? {})
    void loadSchema(entry).then((s) => alive && setSchema(s))
    return () => {
      alive = false
    }
  }, [open, entry])

  // Mở cửa sổ mới thì đặt lại bộ lọc, tránh mang trạng thái của chặng trước sang.
  useEffect(() => {
    setFieldQuery('')
    setShowAll(false)
  }, [node?.id])

  const props = useMemo(() => Object.entries(schema.properties ?? {}), [schema])
  const required = useMemo(() => new Set(schema.required ?? []), [schema])

  /** Gom trường theo nhóm gốc; nhóm rỗng sẽ không sinh tab. */
  const byGroup = useMemo(() => {
    const m = new Map<PropGroup, [string, SchemaProp][]>()
    for (const [k, v] of props) {
      const g = groupOf(v).group
      if (!m.has(g)) m.set(g, [])
      m.get(g)!.push([k, v])
    }
    return m
  }, [props])

  const values = node?.data.props ?? {}

  /** Trường đáng hiện: bắt buộc, đã có giá trị, hoặc người dùng bấm «Hiện tất cả». */
  function visible(list: [string, SchemaProp][]): [string, SchemaProp][] {
    const q = fieldQuery.trim().toLowerCase()
    if (q) {
      return list.filter(
        ([k, v]) =>
          k.toLowerCase().includes(q) ||
          (v.title ?? '').toLowerCase().includes(q) ||
          (v.description ?? '').toLowerCase().includes(q),
      )
    }
    if (showAll) return list
    return list.filter(([k]) => required.has(k) || values[k] !== undefined)
  }

  // Khi có từ khóa thì tìm xuyên mọi tab — người dùng không phải đoán trường nằm ở đâu.
  const searching = fieldQuery.trim().length > 0

  const groupsPresent = useMemo(() => {
    const order: PropGroup[] = ['common', 'producer', 'consumer', 'security', 'scheduler', 'khac', 'advanced']
    return order.filter((g) => (byGroup.get(g)?.length ?? 0) > 0)
  }, [byGroup])

  // Tab mở sẵn là nhóm có trường bắt buộc, nếu không thì nhóm đầu tiên.
  useEffect(() => {
    if (!groupsPresent.length) return
    const withRequired = groupsPresent.find((g) =>
      (byGroup.get(g) ?? []).some(([k]) => required.has(k)),
    )
    setTab(withRequired ?? groupsPresent[0])
  }, [groupsPresent, byGroup, required])

  if (!node) return null

  const missingCount = [...required].filter((k) => values[k] === undefined || values[k] === '').length
  const isComponent = entry?.kind === 'component' || entry?.kind === 'kamelet' || node.data.uri !== undefined

  const paramPanel = (list: [string, SchemaProp][], groupTotal: number) => (
    <div className="cfg__fields">
      {list.length === 0 ? (
        <Empty
          image={Empty.PRESENTED_IMAGE_SIMPLE}
          description={
            searching ? 'Không có trường nào khớp từ khóa' : 'Nhóm này chưa đặt trường nào'
          }
        />
      ) : (
        list.map(([k, v]) => (
          <Field
            key={k}
            name={k}
            schema={v}
            required={required.has(k)}
            value={values[k] as PropValue | undefined}
            onChange={(val) => onProp(k, val)}
            sample={sample}
            env={env}
          />
        ))
      )}
      {!searching && !showAll && groupTotal > list.length && (
        <Button size="small" block onClick={() => setShowAll(true)}>
          Hiện tất cả ({groupTotal - list.length} trường còn lại)
        </Button>
      )}
    </div>
  )

  return (
    <Modal
      open={open}
      onCancel={onClose}
      footer={null}
      className="cfg-modal"
      width="75vw"
      centered
      destroyOnHidden
      title={
        <div className="cfg__title">
          <span className={`cfg__icon cfg__icon--${node.data.tone}`} aria-hidden="true">
            {node.data.icon}
          </span>
          <div className="cfg__title-text">
            <Input
              size="small"
              variant="borderless"
              className="cfg__name-input"
              value={node.data.label}
              onChange={(e) => onLabel(e.target.value)}
            />
            <div className="cfg__meta">
              <span className="cfg__kind">{entry?.kind === 'pattern' ? 'Mẫu EIP' : 'Thành phần Camel'}</span>
              <code>{refName(node.data.ref)}</code>
              {entry?.description && <span className="cfg__desc">{entry.description}</span>}
            </div>
          </div>
        </div>
      }
    >
      <div className="cfg">
        {/* Cột trái — bản tin mẫu vào */}
        <aside className="cfg__side" aria-label="Dữ liệu vào">
          <div className="cfg__side-head">
            INPUT
            {sample?.inherited && <span className="cfg__tag">kế thừa</span>}
          </div>
          <textarea
            className="cfg__sample"
            placeholder={'Dán bản tin mẫu JSON/XML để xem trước biểu thức…'}
            value={node.data.pinnedSample ?? ''}
            onChange={(e) => onPin(e.target.value === '' ? undefined : e.target.value)}
          />
          {sample?.inherited && (
            <div className="cfg__hint">Đang dùng mẫu của chặng trước trên đường đi.</div>
          )}
        </aside>

        {/* Cột giữa — tham số */}
        <div className="cfg__main">
          <div className="cfg__toolbar">
            <input
              className="cfg__find"
              placeholder="Tìm trong trường cấu hình…"
              value={fieldQuery}
              onChange={(e) => setFieldQuery(e.target.value)}
              aria-label="Tìm trong trường cấu hình"
            />
            <span className="cfg__count">
              {props.length} trường · {missingCount > 0 ? `${missingCount} bắt buộc còn trống` : 'đủ trường bắt buộc'}
            </span>
          </div>

          {isComponent && (
            <div className="cfg__uri">
              <label className="cfg__label">
                URI Camel<span className="cfg__req"> *</span>
              </label>
              <Input.TextArea
                autoSize={{ minRows: 1, maxRows: 3 }}
                value={node.data.uri ?? ''}
                onChange={(e) => onUri(e.target.value)}
              />
              {entry?.syntax && <div className="cfg__param">cú pháp: {entry.syntax}</div>}
            </div>
          )}

          <div className="cfg__tabs-wrap">
            {searching ? (
              paramPanel(visible(props), props.length)
            ) : groupsPresent.length ? (
              <Tabs
                size="small"
                activeKey={tab}
                onChange={setTab}
                className="cfg__tabs"
                items={groupsPresent.map((g) => {
                  const list = byGroup.get(g) ?? []
                  const set = list.filter(([k]) => values[k] !== undefined).length
                  return {
                    key: g,
                    label: (
                      <span>
                        {GROUP_VI[g]} <span className="cfg__tabnum">{set}/{list.length}</span>
                      </span>
                    ),
                    children: paramPanel(visible(list), list.length),
                  }
                })}
              />
            ) : (
              <Empty description="Chặng này không có tham số cấu hình" />
            )}
          </div>

          <div className="cfg__foot">
            <div className="cfg__foot-left">
              {node.data.locked ? (
                <span className="cfg__hint">🔒 Chặng bắt buộc của khung chuẩn — không gỡ được</span>
              ) : (
                <Button size="small" danger onClick={() => { onDelete(); onClose() }}>
                  Gỡ chặng
                </Button>
              )}
            </div>
            <Typography.Text type="secondary" className="cfg__hint">
              Esc để đóng · thay đổi áp ngay
            </Typography.Text>
            <Button type="primary" onClick={onClose}>
              Xong
            </Button>
          </div>
        </div>

        {/* Cột phải — kết quả chạy + ghi chú */}
        <aside className="cfg__side" aria-label="Dữ liệu ra">
          <div className="cfg__side-head">OUTPUT</div>
          {runOutput ? (
            <>
              <div className={`cfg__run cfg__run--${runOutput.status === 'OK' ? 'ok' : 'err'}`}>
                {runOutput.status} · {runOutput.durationMs} ms
              </div>
              {runOutput.detail && <pre className="cfg__out">{runOutput.detail}</pre>}
            </>
          ) : (
            <div className="cfg__empty">Chưa có lần chạy thử nào cho chặng này.</div>
          )}

          <div className="cfg__side-head" style={{ marginTop: 12 }}>
            GHI CHÚ
          </div>
          <textarea
            className="cfg__sample cfg__sample--note"
            placeholder="Ghi chú nghiệp vụ, hiện cho người duyệt…"
            value={node.data.note ?? ''}
            onChange={(e) => onNote(e.target.value)}
          />
        </aside>
      </div>
    </Modal>
  )
}
