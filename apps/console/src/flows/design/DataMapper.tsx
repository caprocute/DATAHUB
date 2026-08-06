import { Alert, Button, Input, Modal, Select, Typography } from 'antd'
import { useEffect, useMemo, useState } from 'react'
import {
  flattenSchema,
  previewMapping,
  schemaFromSample,
  toJq,
  validateMappings,
  type FieldMapping,
  type SchemaField,
  type TransformFn,
} from '../core/mapper'

interface Props {
  open: boolean
  /** Bản tin mẫu của chặng — dùng suy lược đồ nguồn khi không có JSON Schema. */
  sample?: string
  onClose: () => void
  onSave: (jq: string, mappings: FieldMapping[]) => void
  /**
   * Ánh xạ đã lưu kèm chặng.
   *
   * Phải giữ riêng vì **JQ là một chiều**: từ biểu thức sinh ra không dựng ngược lại bảng
   * ánh xạ được. Không giữ thì mở lại lần sau người dùng thấy bảng trắng dù chặng đã có
   * ánh xạ — tưởng công sức mất.
   */
  savedMappings?: FieldMapping[]
}

const TRANSFORMS: { value: TransformFn; label: string }[] = [
  { value: 'none', label: 'Giữ nguyên' },
  { value: 'trim', label: 'Cắt khoảng trắng' },
  { value: 'upper', label: 'IN HOA' },
  { value: 'lower', label: 'in thường' },
  { value: 'toString', label: 'Sang chuỗi' },
  { value: 'toNumber', label: 'Sang số' },
  { value: 'defaultIfEmpty', label: 'Mặc định nếu rỗng' },
]

/** Lược đồ CDM sẵn có trong `contracts/cdm/` — đích thường dùng nhất của LGSP. */
const CDM_PERSON = {
  title: 'CDM Person v1',
  type: 'object',
  required: ['personId', 'fullName'],
  properties: {
    personId: { type: 'string', title: 'Mã định danh' },
    fullName: { type: 'string', title: 'Họ tên' },
    dateOfBirth: { type: 'string', title: 'Ngày sinh' },
    nationalId: { type: 'string', title: 'Số CMND/CCCD' },
  },
}

/**
 * Trình vẽ ánh xạ trường nguồn → đích (K6 — FR-D-083…085).
 *
 * Sinh **biểu thức JQ** — đúng cơ chế `contracts/cdm/mappers/*.jq` mà ADR-013 đã chốt và
 * `CdmMapperTest` đang chứng minh chạy được trên Camel thật. Nhờ vậy ánh xạ vẽ ở đây thay
 * được lớp mapper Java viết tay (`LegacyCitizenToPersonMapper`: 60 dòng cho 4 trường), vốn
 * hay trôi khỏi tệp `.jq` cạnh nó lúc nào không ai biết.
 */
export function DataMapper({ open, sample, onClose, onSave, savedMappings }: Props) {
  const [mappings, setMappings] = useState<FieldMapping[]>([])
  const [targetKind, setTargetKind] = useState<'cdm-person' | 'sample'>('cdm-person')
  const [targetSample, setTargetSample] = useState('')

  useEffect(() => {
    if (open) setMappings(savedMappings?.length ? savedMappings : [])
  }, [open, savedMappings])

  const sourceFields = useMemo<SchemaField[]>(
    () => (sample ? flattenSchema(schemaFromSample(sample)) : []),
    [sample],
  )

  const targetFields = useMemo<SchemaField[]>(
    () =>
      targetKind === 'cdm-person'
        ? flattenSchema(CDM_PERSON)
        : flattenSchema(schemaFromSample(targetSample)),
    [targetKind, targetSample],
  )

  const findings = validateMappings(mappings, targetFields)
  const errors = findings.filter((f) => f.level === 'error')
  const jq = useMemo(() => toJq(mappings, 'Sinh từ trình ánh xạ LGSP'), [mappings])

  const preview = useMemo(
    () => (sample ? previewMapping(mappings, sample) : undefined),
    [mappings, sample],
  )

  function patch(i: number, part: Partial<FieldMapping>) {
    setMappings((ms) => ms.map((m, j) => (j === i ? { ...m, ...part } : m)))
  }

  return (
    <Modal
      open={open}
      title="Ánh xạ dữ liệu"
      onCancel={onClose}
      onOk={() => {
        if (errors.length) return
        onSave(jq, mappings)
        onClose()
      }}
      okText="Lưu ánh xạ"
      cancelText="Hủy"
      okButtonProps={{ disabled: errors.length > 0 }}
      width={1100}
    >
      {!sample && (
        <Alert
          type="warning"
          showIcon
          className="kml__errs"
          message="Chặng chưa có bản tin mẫu"
          description="Ghim một bản tin mẫu ở cửa sổ cấu hình chặng để suy ra cây trường nguồn."
        />
      )}

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

      <div className="dmp__target">
        <span>Cấu trúc đích</span>
        <Select
          size="small"
          value={targetKind}
          onChange={setTargetKind}
          style={{ width: 220 }}
          options={[
            { value: 'cdm-person', label: 'CDM Person v1 (contracts/cdm)' },
            { value: 'sample', label: 'Suy từ bản tin mẫu đích' },
          ]}
        />
        {targetKind === 'sample' && (
          <Input
            size="small"
            placeholder='{"personId":"...","fullName":"..."}'
            value={targetSample}
            onChange={(e) => setTargetSample(e.target.value)}
          />
        )}
      </div>

      <div className="dmp">
        <div className="dmp__col">
          <div className="dmp__head">Trường nguồn</div>
          <ul className="dmp__fields">
            {sourceFields.map((f) => (
              <li key={f.path} style={{ paddingLeft: 8 + f.depth * 12 }}>
                <span className="dmp__fname">{f.name}</span>
                <span className="dmp__ftype">{f.type}</span>
              </li>
            ))}
            {!sourceFields.length && <li className="dmp__empty">Chưa có bản tin mẫu</li>}
          </ul>
        </div>

        <div className="dmp__col dmp__col--wide">
          <div className="dmp__head">
            Ánh xạ
            <Button
              size="small"
              onClick={() =>
                setMappings((ms) => [...ms, { from: [''], to: '', transform: 'none' }])
              }
            >
              ＋ Thêm
            </Button>
          </div>
          <div className="dmp__rows">
            {mappings.map((m, i) => (
              <div className="dmp__row" key={i}>
                <Select
                  size="small"
                  mode="multiple"
                  allowClear
                  placeholder="Trường nguồn"
                  value={m.from.filter(Boolean)}
                  onChange={(v) => patch(i, { from: v.length ? v : [''] })}
                  options={sourceFields
                    .filter((f) => f.type !== 'object' && f.type !== 'array')
                    .map((f) => ({ value: f.path, label: f.path }))}
                  style={{ flex: '1 1 30%' }}
                />
                <Select
                  size="small"
                  value={m.transform}
                  onChange={(v) => patch(i, { transform: v })}
                  options={TRANSFORMS}
                  style={{ flex: '0 0 150px' }}
                />
                {m.transform === 'defaultIfEmpty' && (
                  <Input
                    size="small"
                    placeholder="giá trị mặc định"
                    value={m.arg ?? ''}
                    onChange={(e) => patch(i, { arg: e.target.value })}
                    style={{ flex: '0 0 130px' }}
                  />
                )}
                <Select
                  size="small"
                  allowClear
                  showSearch
                  placeholder="Trường đích"
                  value={m.to || undefined}
                  onChange={(v) => patch(i, { to: v ?? '' })}
                  options={targetFields
                    .filter((f) => f.type !== 'object' && f.type !== 'array')
                    .map((f) => ({
                      value: f.path,
                      label: f.required ? `${f.path} *` : f.path,
                    }))}
                  style={{ flex: '1 1 30%' }}
                />
                <Button
                  size="small"
                  type="text"
                  danger
                  onClick={() => setMappings((ms) => ms.filter((_x, j) => j !== i))}
                  title="Xóa ánh xạ"
                >
                  ✕
                </Button>
              </div>
            ))}
            {!mappings.length && (
              <div className="dmp__empty">Chưa có ánh xạ nào. Bấm «Thêm» để bắt đầu.</div>
            )}
          </div>
        </div>

        <div className="dmp__col">
          <div className="dmp__head">Trường đích</div>
          <ul className="dmp__fields">
            {targetFields.map((f) => {
              const done = mappings.some((m) => m.to === f.path && m.from.some(Boolean))
              return (
                <li key={f.path} style={{ paddingLeft: 8 + f.depth * 12 }}>
                  <span className="dmp__fname">
                    {f.name}
                    {f.required && <span className="cfg__req"> *</span>}
                  </span>
                  <span className={done ? 'dmp__ok' : 'dmp__ftype'}>{done ? '✓' : f.type}</span>
                </li>
              )
            })}
          </ul>
        </div>
      </div>

      <div className="dmp__out">
        <div>
          <div className="dmp__head">Biểu thức JQ sinh ra</div>
          <pre className="dmp__jq">{jq}</pre>
        </div>
        <div>
          <div className="dmp__head">Xem trước trên bản tin mẫu</div>
          <pre className="dmp__jq">
            {preview
              ? preview.ok
                ? JSON.stringify(preview.value, null, 2)
                : preview.error
              : 'Chưa có bản tin mẫu'}
          </pre>
        </div>
      </div>

      <Typography.Paragraph type="secondary" className="t-small dmp__note">
        Xem trước chạy <b>trong trình duyệt</b> nên chỉ để ước lượng nhanh. Kết quả thật do
        Camel chạy JQ ở máy chủ quyết định (FR-D-085).
      </Typography.Paragraph>
    </Modal>
  )
}
