import { Button, Collapse, Input, InputNumber, Modal, Select, Switch, Tabs, Tooltip } from 'antd';
import { useEffect, useMemo, useState } from 'react';
import {
  groupOf,
  loadSchema,
  lookup,
  peekSchema,
  refName,
  type PropertiesSchema,
  type SchemaProp,
} from '../catalog/catalog';
import type { FieldMapping, StageNode } from '../flow/model';
import { DataMapperPanel } from './DataMapper';
import { ExpressionField } from './ExpressionField';

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
  /** Bản tin mẫu hiệu lực của chặng (pin của chính nó hoặc kế thừa chặng trước). */
  sample?: { sample: string; inherited: boolean };
  /** Gắn / gỡ pin bản tin mẫu cho chặng đang mở (FR-04-033). */
  onPin: (v: string | undefined) => void;
  /** Ghi chú nghiệp vụ của chặng (FR-04-039). */
  onNote: (v: string) => void;
  /** Kết quả chặng sau lần chạy thử gần nhất (FR-04-035). */
  runOutput?: { status: string; durationMs: number; detail?: string };
  env?: Record<string, string>;
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

/** Trường mang bí mật — không bao giờ nhập thẳng trên node (FR-04-032). */
const SECRET_HINT = /password|secret|token|credential|accesskey|privatekey|passphrase|apikey/i;

function isSecretField(name: string, schema: SchemaProp): boolean {
  return SECRET_HINT.test(name) || SECRET_HINT.test(schema.title ?? '') || schema.format === 'password';
}

/** Trường nhận biểu thức — cho dùng trình soạn có xem trước (FR-04-031). */
function isExpressionField(name: string, schema: SchemaProp): boolean {
  if (schema.enum?.length || schema.type === 'boolean') return false;
  return /expression|predicate|simple|language|correlationExpression|completionPredicate/i.test(
    `${name} ${schema.title ?? ''}`,
  );
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
  name: string;
  schema: SchemaProp;
  required: boolean;
  value: PropValue | undefined;
  onChange: (v: PropValue | undefined) => void;
  sample?: { sample: string; inherited: boolean };
  env?: Record<string, string>;
}) {
  const secret = isSecretField(name, schema);
  const expression = !secret && isExpressionField(name, schema);

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

      {secret ? (
        // Không có ô nhập tự do: bí mật chỉ tham chiếu qua kết nối đã đăng ký.
        <div className="field__secret">
          <Input
            size="small"
            readOnly
            value={value === undefined ? '' : String(value)}
            placeholder="Tham chiếu kết nối, ví dụ {{vault:lgsp/adapter#matKhau}}"
          />
          <p className="t-small t-muted" style={{ margin: '4px 0 0' }}>
            Trường bí mật — chọn kết nối đã đăng ký ở PH-05 hoặc tham chiếu Vault. Không dán giá trị
            thật lên node.
          </p>
        </div>
      ) : expression ? (
        <ExpressionField
          value={value === undefined ? '' : String(value)}
          onChange={(v) => onChange(v === '' ? undefined : v)}
          sample={sample?.sample}
          inherited={sample?.inherited}
          env={env}
          rows={1}
        />
      ) : (
        <Control name={name} schema={schema} value={value} onChange={onChange} />
      )}

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
  sample,
  onPin,
  onNote,
  runOutput,
  env,
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

  // Mẫu dán vào có thể là XML; chỉ báo lỗi khi trông như JSON mà phân tích hỏng.
  const pinError = useMemo(() => {
    const raw = node?.data.pinnedSample?.trim();
    if (!raw || !/^[[{]/.test(raw)) return undefined;
    try {
      JSON.parse(raw);
      return undefined;
    } catch (e) {
      return e instanceof Error ? e.message : String(e);
    }
  }, [node?.data.pinnedSample]);

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
          sample={sample}
          env={env}
        />
      ))}

      {(refName(node.data.ref) === 'transform' || node.data.mappings) && (
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
                  sample={sample}
                  env={env}
                />
              )),
            },
          ]}
        />
      )}
    </div>
  );

  const pinTab = (
    <div className="n8n-cfg__body">
      <p className="t-small t-muted" style={{ marginTop: 0 }}>
        Bản tin mẫu gắn theo chặng (FR-04-033) — dùng để xem trước biểu thức và chạy thử. Mẫu
        <strong> không </strong> đi vào định nghĩa luồng khi triển khai; đừng dán dữ liệu thật có
        chứa thông tin cá nhân.
      </p>
      <Input.TextArea
        className="t-mono"
        autoSize={{ minRows: 8, maxRows: 18 }}
        placeholder={'{\n  "loaiHoSo": "CAP_MOI"\n}'}
        value={node.data.pinnedSample ?? ''}
        onChange={(e) => onPin(e.target.value === '' ? undefined : e.target.value)}
      />
      <div className="n8n-cfg__pin-foot">
        {pinError ? (
          <span className="t-small" style={{ color: 'var(--c-err-600, #dc2626)' }}>
            JSON chưa hợp lệ: {pinError}
          </span>
        ) : node.data.pinnedSample ? (
          <span className="t-small t-muted">Mẫu hợp lệ.</span>
        ) : sample?.inherited ? (
          <span className="t-small t-muted">Đang dùng mẫu kế thừa từ chặng trước.</span>
        ) : (
          <span className="t-small t-muted">Chưa có mẫu cho chặng này.</span>
        )}
        {node.data.pinnedSample && (
          <Button size="small" onClick={() => onPin(undefined)}>
            Gỡ mẫu
          </Button>
        )}
      </div>
    </div>
  );

  const noteTab = (
    <div className="n8n-cfg__body">
      <p className="t-small t-muted" style={{ marginTop: 0 }}>
        Ghi chú nghiệp vụ của chặng (FR-04-039) — hiện cho người duyệt đọc khi thẩm định luồng.
      </p>
      <Input.TextArea
        autoSize={{ minRows: 4, maxRows: 12 }}
        placeholder="Vì sao chặng này tồn tại, ràng buộc nghiệp vụ, đầu mối liên hệ…"
        value={node.data.note ?? ''}
        onChange={(e) => onNote(e.target.value)}
      />
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
          <div className="n8n-cfg__side-label">
            INPUT
            {sample?.inherited && (
              <span className="badge badge--muted badge--plain" style={{ marginLeft: 6 }}>
                kế thừa
              </span>
            )}
          </div>
          {sample ? (
            <pre className="n8n-cfg__side-code t-mono">{sample.sample}</pre>
          ) : (
            <div className="n8n-cfg__side-empty t-small t-muted">
              Chưa gắn bản tin mẫu. Mở tab «Dữ liệu mẫu» để dán mẫu — cần cho xem trước biểu thức.
            </div>
          )}
        </aside>

        <div className="n8n-cfg__main">
          <Tabs
            size="small"
            className="n8n-cfg__tabs"
            items={[
              { key: 'params', label: 'Tham số', children: paramsTab },
              { key: 'pin', label: 'Dữ liệu mẫu', children: pinTab },
              { key: 'note', label: 'Ghi chú', children: noteTab },
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
          {runOutput ? (
            <>
              <div className={`badge badge--${runOutput.status === 'OK' ? 'ok' : 'err'}`}>
                {runOutput.status} · {runOutput.durationMs} ms
              </div>
              {runOutput.detail && (
                <pre className="n8n-cfg__side-code t-mono">{runOutput.detail}</pre>
              )}
            </>
          ) : (
            <div className="n8n-cfg__side-empty t-small t-muted">
              Chưa có lần chạy thử. Bấm «Chạy thử» trên thanh công cụ để lấy kết quả từng chặng.
            </div>
          )}
        </aside>
      </div>
    </Modal>
  );
}
