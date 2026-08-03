import { Button, Collapse, Input, InputNumber, Select, Switch, Tooltip } from 'antd';
import { useMemo } from 'react';
import { groupOf, lookup, type SchemaProp } from '../catalog/catalog';
import type { StageNode } from '../flow/model';

type PropValue = string | number | boolean;

interface Props {
  node: StageNode | undefined;
  onLabel: (v: string) => void;
  onUri: (v: string) => void;
  onProp: (key: string, v: PropValue | undefined) => void;
  onDelete: () => void;
}

/** Một ô nhập, kiểu điều khiển suy ra từ `type` trong lược đồ gốc của Camel. */
function Control({
  name,
  schema,
  value,
  onChange,
}: {
  name: string;
  schema: SchemaProp;
  value: PropValue | undefined;
  onChange: (v: PropValue | undefined) => void;
}) {
  const placeholder = schema.default !== undefined ? `mặc định: ${String(schema.default)}` : '';

  if (schema.type === 'boolean') {
    return (
      <Switch
        size="small"
        checked={value === true || value === 'true'}
        onChange={(v) => onChange(v)}
        aria-label={schema.title ?? name}
      />
    );
  }
  if (schema.enum?.length) {
    return (
      <Select
        size="small"
        style={{ width: '100%' }}
        allowClear
        placeholder={placeholder || 'Chọn giá trị'}
        value={value === undefined || value === '' ? undefined : String(value)}
        onChange={(v) => onChange(v ?? undefined)}
        options={schema.enum.map((o) => ({ value: o, label: o }))}
      />
    );
  }
  if (schema.type === 'integer' || schema.type === 'number') {
    return (
      <InputNumber
        size="small"
        style={{ width: '100%' }}
        placeholder={placeholder}
        value={typeof value === 'number' ? value : value === undefined || value === '' ? null : Number(value)}
        onChange={(v) => onChange(v === null ? undefined : Number(v))}
      />
    );
  }
  return (
    <Input
      size="small"
      placeholder={placeholder}
      value={value === undefined ? '' : String(value)}
      onChange={(e) => onChange(e.target.value === '' ? undefined : e.target.value)}
    />
  );
}

function Field({
  name,
  schema,
  required,
  value,
  onChange,
}: {
  name: string;
  schema: SchemaProp;
  required: boolean;
  value: PropValue | undefined;
  onChange: (v: PropValue | undefined) => void;
}) {
  return (
    <div className="field">
      <label className="field__label">
        {schema.title ?? name}
        {required && <span className="field__req"> *</span>}{' '}
        {schema.description && (
          <Tooltip title={schema.description} placement="topLeft">
            <span className="field__info" aria-hidden="true">
              ⓘ
            </span>
          </Tooltip>
        )}
      </label>
      <Control name={name} schema={schema} value={value} onChange={onChange} />
      <div className="field__hint t-mono">{name}</div>
    </div>
  );
}

export function PropertiesPanel({ node, onLabel, onUri, onProp, onDelete }: Props) {
  const entry = node ? lookup(node.data.ref) : undefined;

  const { basic, advanced } = useMemo(() => {
    const all = Object.entries(entry?.propertiesSchema.properties ?? {});
    const b: [string, SchemaProp][] = [];
    const a: [string, SchemaProp][] = [];
    for (const [k, v] of all) {
      // `id`, `description`, `disabled` là siêu dữ liệu của mọi mẫu EIP, không phải
      // tham số nghiệp vụ, nên dồn xuống phần nâng cao cho gọn bảng.
      const meta = k === 'id' || k === 'description' || k === 'disabled' || k === 'note';
      (groupOf(v).advanced || meta ? a : b).push([k, v]);
    }
    return { basic: b, advanced: a };
  }, [entry]);

  if (!node) {
    return (
      <div className="panel">
        <div className="panel__head">Thuộc tính</div>
        <div className="panel__body">
          <p className="t-small t-muted" style={{ margin: 0 }}>
            Chọn một chặng trên sơ đồ để xem và sửa thuộc tính. Biểu mẫu bên dưới sinh ra từ lược đồ JSON Schema của
            chính thành phần Camel đó.
          </p>
        </div>
      </div>
    );
  }

  const required = new Set(entry?.propertiesSchema.required ?? []);
  const isComponent = entry?.kind === 'component' || node.data.uri !== undefined;

  return (
    <div className="panel">
      <div className="panel__head">
        Thuộc tính — {node.data.label}
        <span className="badge badge--muted badge--plain" style={{ marginLeft: 'auto' }}>
          {entry?.kind === 'pattern' ? 'EIP' : 'thành phần'}
        </span>
      </div>
      <div className="panel__body">
        <div className="field">
          <label className="field__label">Tên chặng</label>
          <Input size="small" value={node.data.label} onChange={(e) => onLabel(e.target.value)} />
          <div className="field__hint">
            {entry?.title ?? node.data.ref} — <span className="t-mono">{node.data.ref}</span>
          </div>
        </div>

        {isComponent && (
          <div className="field">
            <label className="field__label">
              URI Camel<span className="field__req"> *</span>
            </label>
            <Input.TextArea
              size="small"
              autoSize={{ minRows: 2, maxRows: 4 }}
              className="t-mono"
              value={node.data.uri ?? ''}
              onChange={(e) => onUri(e.target.value)}
            />
            {entry?.syntax && <div className="field__hint t-mono">cú pháp: {entry.syntax}</div>}
          </div>
        )}

        {basic.map(([k, v]) => (
          <Field
            key={k}
            name={k}
            schema={v}
            required={required.has(k)}
            value={node.data.props[k] as PropValue | undefined}
            onChange={(val) => onProp(k, val)}
          />
        ))}

        {advanced.length > 0 && (
          <Collapse
            size="small"
            ghost
            items={[
              {
                key: 'adv',
                label: <span className="t-small">Thuộc tính nâng cao ({advanced.length})</span>,
                children: advanced.map(([k, v]) => (
                  <Field
                    key={k}
                    name={k}
                    schema={v}
                    required={required.has(k)}
                    value={node.data.props[k] as PropValue | undefined}
                    onChange={(val) => onProp(k, val)}
                  />
                )),
              },
            ]}
          />
        )}

        <div className="divider" />
        {node.data.locked ? (
          <p className="t-small t-muted" style={{ margin: 0 }}>
            🔒 Chặng bắt buộc của khung chuẩn — sửa được thuộc tính nhưng không gỡ khỏi luồng.
          </p>
        ) : (
          <Button danger size="small" block onClick={onDelete}>
            Gỡ chặng khỏi luồng
          </Button>
        )}
      </div>
    </div>
  );
}
