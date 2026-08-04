import { Button, Collapse, Input, InputNumber, Modal, Select, Switch, Tabs, Tooltip } from 'antd';
import { useEffect, useMemo, useState } from 'react';
import {
  groupOf,
  loadSchema,
  lookup,
  peekSchema,
  type PropertiesSchema,
  type SchemaProp,
} from '../catalog/catalog';
import type { FieldMapping, StageNode } from '../flow/model';
import { DataMapperPanel } from './DataMapper';

type PropValue = string | number | boolean;

interface Props {
  open: boolean;
  node: StageNode | undefined;
  onClose: () => void;
  onLabel: (v: string) => void;
  onUri: (v: string) => void;
  onProp: (key: string, v: PropValue | undefined) => void;
  onMappings: (m: FieldMapping[]) => void;
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

/**
 * Popup cấu hình một chặng — kiểu n8n (overlay giữa màn hình, không sidebar).
 * Mở bằng nhấp đúp node hoặc nút «Cấu hình» trên thanh công cụ.
 */
export function NodeConfigModal({
  open,
  node,
  onClose,
  onLabel,
  onUri,
  onProp,
  onMappings,
  onDelete,
}: Props) {
  const entry = node ? lookup(node.data.ref) : undefined;
  // Lược đồ tham số nặng nên nạp lười theo từng nút, chỉ khi popup thật sự mở.
  const [schema, setSchema] = useState<PropertiesSchema>({});

  useEffect(() => {
    if (!open || !entry) {
      setSchema({});
      return;
    }
    let alive = true;
    setSchema(peekSchema(entry) ?? {});
    void loadSchema(entry).then((s) => {
      if (alive) setSchema(s);
    });
    return () => {
      alive = false;
    };
  }, [open, entry]);

  const { basic, advanced } = useMemo(() => {
    const all = Object.entries(schema.properties ?? {});
    const b: [string, SchemaProp][] = [];
    const a: [string, SchemaProp][] = [];
    for (const [k, v] of all) {
      const meta = k === 'id' || k === 'description' || k === 'disabled' || k === 'note';
      (groupOf(v).advanced || meta ? a : b).push([k, v]);
    }
    return { basic: b, advanced: a };
  }, [schema]);

  if (!node) return null;

  const required = new Set(schema.required ?? []);
  const isComponent = entry?.kind === 'component' || node.data.uri !== undefined;
  const kindLabel = entry?.kind === 'pattern' ? 'EIP' : 'Thành phần Camel';

  const paramsTab = (
    <div className="n8n-cfg__body">
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

      {(node.data.ref === 'transform' || node.data.mappings) && (
        <>
          <div className="divider" />
          <DataMapperPanel mappings={node.data.mappings ?? []} onChange={onMappings} locked={false} />
        </>
      )}

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
    </div>
  );

  const settingsTab = (
    <div className="n8n-cfg__body">
      <p className="t-small t-muted" style={{ marginTop: 0 }}>
        Cài đặt chặng — không lưu secret trên node. Kết nối và credential chọn qua picker (Vault / PH-05).
      </p>
      {node.data.locked ? (
        <p className="t-small t-muted" style={{ margin: 0 }}>
          🔒 Chặng bắt buộc của khung chuẩn — sửa được thuộc tính nhưng không gỡ khỏi luồng.
        </p>
      ) : (
        <Button
          danger
          size="small"
          onClick={() => {
            onDelete();
            onClose();
          }}
        >
          Gỡ chặng khỏi luồng
        </Button>
      )}
    </div>
  );

  const docsTab = (
    <div className="n8n-cfg__body">
      <p className="t-small" style={{ marginTop: 0 }}>
        <strong>{entry?.title ?? node.data.ref}</strong>
      </p>
      <p className="t-small t-muted">
        {entry?.description ??
          'Mô tả lấy từ catalog Camel subset trong console; URI/tham số theo schema thành phần.'}
      </p>
      {entry?.syntax && (
        <p className="t-small t-mono" style={{ marginBottom: 0 }}>
          {entry.syntax}
        </p>
      )}
    </div>
  );

  return (
    <Modal
      open={open}
      onCancel={onClose}
      footer={null}
      width={980}
      destroyOnHidden
      centered
      maskClosable
      keyboard
      className="n8n-cfg-modal"
      styles={{
        header: { margin: 0, padding: '16px 20px', borderBottom: '1px solid var(--c-border)' },
        body: { padding: 0, overflow: 'hidden' },
      }}
      title={
        <div className="n8n-cfg__title">
          <span className="n8n-cfg__icon" aria-hidden="true">
            {node.data.icon}
          </span>
          <div className="n8n-cfg__title-text">
            <div className="n8n-cfg__name">{node.data.label}</div>
            <div className="n8n-cfg__meta">
              <span className="badge badge--muted badge--plain">{kindLabel}</span>
              <span className="t-mono t-muted">{node.data.ref}</span>
            </div>
          </div>
        </div>
      }
    >
      <div className="n8n-cfg">
        <aside className="n8n-cfg__side n8n-cfg__side--in" aria-label="Dữ liệu vào">
          <div className="n8n-cfg__side-label">INPUT</div>
          <p className="t-small t-muted" style={{ margin: 0 }}>
            Pin bản tin mẫu (FR-04-033) — dùng xem trước biểu thức và chạy thử từng bước.
          </p>
          <pre className="n8n-cfg__side-code t-mono">{`{\n  "loaiHoSo": "CAP_MOI",\n  "chuSoHuu": { "hoTen": "…" }\n}`}</pre>
        </aside>

        <div className="n8n-cfg__main">
          <Tabs
            size="small"
            className="n8n-cfg__tabs"
            items={[
              { key: 'params', label: 'Tham số', children: paramsTab },
              { key: 'settings', label: 'Cài đặt', children: settingsTab },
              { key: 'docs', label: 'Tài liệu', children: docsTab },
            ]}
          />
          <div className="n8n-cfg__foot">
            <span className="t-small t-muted">Khung cố định kiểu n8n NDV · Esc đóng</span>
            <Button type="primary" size="small" onClick={onClose}>
              Xong
            </Button>
          </div>
        </div>

        <aside className="n8n-cfg__side n8n-cfg__side--out" aria-label="Dữ liệu ra">
          <div className="n8n-cfg__side-label">OUTPUT</div>
          <p className="t-small t-muted" style={{ margin: 0 }}>
            Kết quả chặng sau chạy thử (FR-04-035) hiện ở đây.
          </p>
          <div className="n8n-cfg__side-empty t-small t-muted">Chưa có lần chạy thử</div>
        </aside>
      </div>
    </Modal>
  );
}
