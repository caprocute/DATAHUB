import { ApiProblemError, newIdempotencyKey, type CatalogGroup } from '@datahub/api-client';
import { t } from '@datahub/i18n';
import { Form, Input, InputNumber, Modal, ProblemAlert, Select } from '@datahub/ui';
import { useState } from 'react';
import { fieldErrorMessage, toUserMessage, type UserMessage } from '../../../shared/api/problem';
import { flatten, selfAndDescendantIds } from '../tree-model';

export interface GroupFormValues {
  code: string;
  name: string;
  parentId: string | null;
  sortOrder: number;
  description: string;
}

export interface GroupFormModalProps {
  /** Có `group` là sửa, không có là thêm. */
  group: CatalogGroup | undefined;
  /** Cây nhóm hiện có (để chọn nhóm cha); chỉ nhóm của tenant ghi được mới chọn được. */
  tree: readonly CatalogGroup[];
  dataTenant: string;
  /** Gợi ý nhóm cha khi thêm (nhóm đang chọn). */
  defaultParentId: string | undefined;
  /** Gửi biểu mẫu; ném ApiProblemError khi máy chủ từ chối. `idempotencyKey` giữ nguyên khi thử lại. */
  onSubmit: (values: GroupFormValues, idempotencyKey: string) => Promise<void>;
  /** 412 ERR-07-018: giao cho trang mở hộp thoại xung đột. */
  onConflict: (values: GroupFormValues) => void;
  onCancel: () => void;
}

const FIELDS = ['code', 'name', 'parentId', 'sortOrder', 'description'] as const;
type FieldName = (typeof FIELDS)[number];

const isField = (name: string | undefined): name is FieldName => FIELDS.includes(name as FieldName);

/**
 * Hộp thoại Thêm/Sửa nhóm (D03-06-PH07 §7.4): Mã, Tên, Nhóm cha, Thứ tự, Mô tả. Lỗi theo trường của
 * máy chủ (`errors[]`) gắn vào đúng ô; lỗi khác hiện ở ProblemAlert đầu biểu mẫu.
 */
export function GroupFormModal({ group, tree, dataTenant, defaultParentId, onSubmit, onConflict, onCancel }: GroupFormModalProps) {
  const [form] = Form.useForm<GroupFormValues>();
  const [submitting, setSubmitting] = useState(false);
  const [alert, setAlert] = useState<UserMessage | undefined>(undefined);
  // Trang gắn component này mới cho mỗi lần mở, nên khóa chống trùng và giá trị đầu là của riêng lần mở này.
  const [idempotencyKey] = useState(() => newIdempotencyKey());
  const editing = group !== undefined;
  const initialValues: GroupFormValues = {
    code: group?.code ?? '',
    name: group?.name ?? '',
    parentId: group ? (group.parentId ?? null) : (defaultParentId ?? null),
    sortOrder: group?.sortOrder ?? 0,
    description: group?.description ?? '',
  };

  const excluded = group ? selfAndDescendantIds(group) : new Set<string>();
  const parentOptions = flatten(tree)
    .filter(({ node }) => node.tenantId === dataTenant && !excluded.has(node.id))
    .map(({ node, level }) => ({ value: node.id, label: `${'— '.repeat(level - 1)}${node.name}` }));

  const handleOk = async () => {
    let values: GroupFormValues;
    try {
      values = await form.validateFields();
    } catch {
      return;
    }
    setSubmitting(true);
    setAlert(undefined);
    try {
      await onSubmit(values, idempotencyKey);
    } catch (error) {
      if (error instanceof ApiProblemError && error.code === 'ERR-07-018') {
        onConflict(values);
      } else {
        showServerError(error, values);
      }
    } finally {
      setSubmitting(false);
    }
  };

  const showServerError = (error: unknown, values: GroupFormValues) => {
    if (error instanceof ApiProblemError) {
      const mapped = error.fieldErrors.filter((fe) => isField(fe.field));
      if (mapped.length > 0) {
        form.setFields(
          mapped.map((fe) => ({
            name: fe.field as FieldName,
            errors: [fieldErrorMessage(error.code, fe.code, { code: values.code })],
          })),
        );
        return;
      }
    }
    setAlert(toUserMessage(error, { name: values.name }));
  };

  return (
    <Modal
      open
      title={editing ? t('rdm.groups.form.editTitle') : t('rdm.groups.form.createTitle')}
      okText={t('rdm.groups.form.save')}
      cancelText={t('rdm.groups.form.cancel')}
      confirmLoading={submitting}
      onOk={() => void handleOk()}
      onCancel={onCancel}
    >
      {alert ? (
        <ProblemAlert
          title={alert.title}
          {...(alert.hint !== undefined ? { detail: alert.hint } : {})}
          {...(alert.code !== undefined ? { code: alert.code } : {})}
          {...(alert.traceId !== undefined ? { traceId: alert.traceId } : {})}
        />
      ) : null}
      <Form form={form} initialValues={initialValues} layout="vertical" requiredMark autoComplete="off" onFinish={() => void handleOk()}>
        <Form.Item
          name="code"
          label={t('rdm.groups.form.code')}
          extra={editing ? undefined : t('rdm.groups.form.code.help')}
          normalize={(value: unknown) => (typeof value === 'string' ? value.toUpperCase() : value)}
          rules={[
            { required: true, message: t('rdm.groups.form.required', { field: t('rdm.groups.form.code') }) },
            { pattern: /^[A-Z0-9][A-Z0-9_.-]{0,63}$/, message: t('rdm.groups.form.codePattern') },
          ]}
        >
          <Input disabled={editing} maxLength={64} />
        </Form.Item>
        <Form.Item
          name="name"
          label={t('rdm.groups.form.name')}
          rules={[
            { required: true, whitespace: true, message: t('rdm.groups.form.required', { field: t('rdm.groups.form.name') }) },
            { max: 255, message: t('rdm.groups.form.maxLength', { field: t('rdm.groups.form.name'), max: 255 }) },
          ]}
        >
          <Input />
        </Form.Item>
        <Form.Item name="parentId" label={t('rdm.groups.form.parent')}>
          <Select
            allowClear
            showSearch={{ optionFilterProp: 'label' }}
            placeholder={t('rdm.groups.form.parent.none')}
            options={parentOptions}
          />
        </Form.Item>
        <Form.Item name="sortOrder" label={t('rdm.groups.form.sortOrder')}>
          <InputNumber precision={0} />
        </Form.Item>
        <Form.Item
          name="description"
          label={t('rdm.groups.form.description')}
          rules={[{ max: 4000, message: t('rdm.groups.form.maxLength', { field: t('rdm.groups.form.description'), max: 4000 }) }]}
        >
          <Input.TextArea rows={3} />
        </Form.Item>
      </Form>
    </Modal>
  );
}
