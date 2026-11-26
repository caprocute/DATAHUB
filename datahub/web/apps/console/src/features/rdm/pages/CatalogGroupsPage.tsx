import type { CatalogGroup } from '@datahub/api-client';
import { t } from '@datahub/i18n';
import { App, Button, ConflictDialog, Empty, Input, PlusOutlined, ProblemAlert, Skeleton, type ConflictRow } from '@datahub/ui';
import { useMemo, useState } from 'react';
import { toUserMessage } from '../../../shared/api/problem';
import { useCurrentUser } from '../../../shared/auth/AuthProvider';
import { useCatalogGroups, useCreateGroup, useDeleteGroup, useUpdateGroup } from '../api/groups';
import { CatalogGroupTree } from '../components/CatalogGroupTree';
import { GroupFormModal, type GroupFormValues } from '../components/GroupFormModal';
import { canCreateGroups, canEditGroup, dataTenantOf } from '../permissions';
import { countNodes, filterTree, findNode } from '../tree-model';
import './catalog-groups-page.css';

/** `undefined` là đóng; `{ group: undefined }` là thêm; `{ group }` là sửa. */
interface FormState {
  group: CatalogGroup | undefined;
}

interface ConflictState {
  group: CatalogGroup;
  values: GroupFormValues;
  rows: ConflictRow[];
}

const toBody = (values: GroupFormValues) => ({
  name: values.name.trim(),
  parentId: values.parentId,
  sortOrder: values.sortOrder,
  description: values.description.trim() === '' ? null : values.description.trim(),
});

function diffRows(values: GroupFormValues, server: CatalogGroup): ConflictRow[] {
  const candidates: Array<[string, string, string]> = [
    [t('rdm.groups.form.name'), values.name.trim(), server.name],
    [t('rdm.groups.form.sortOrder'), String(values.sortOrder), String(server.sortOrder ?? 0)],
    [t('rdm.groups.form.description'), values.description.trim(), server.description ?? ''],
  ];
  return candidates.filter(([, mine, theirs]) => mine !== theirs).map(([field, mine, server_]) => ({ field, mine, server: server_ }));
}

/** Trang `/du-lieu/danh-muc`: khung trái là cây nhóm (F-07-010), khung phải dành cho bảng danh mục (F-07-001). */
export function CatalogGroupsPage() {
  const user = useCurrentUser();
  const { message, modal } = App.useApp();
  const groups = useCatalogGroups();
  const createGroup = useCreateGroup();
  const updateGroup = useUpdateGroup();
  const deleteGroup = useDeleteGroup();

  const [query, setQuery] = useState('');
  const [selectedId, setSelectedId] = useState<string | undefined>(undefined);
  const [collapsed, setCollapsed] = useState<ReadonlySet<string>>(new Set());
  const [form, setForm] = useState<FormState | undefined>(undefined);
  const [conflict, setConflict] = useState<ConflictState | undefined>(undefined);

  const tree = useMemo(() => groups.data ?? [], [groups.data]);
  const filtered = useMemo(() => filterTree(tree, query), [tree, query]);
  const filtering = query.trim() !== '';
  const canCreate = canCreateGroups(user);

  const toggle = (id: string) =>
    setCollapsed((previous) => {
      const next = new Set(previous);
      if (!next.delete(id)) {
        next.add(id);
      }
      return next;
    });

  const submit = async (values: GroupFormValues, idempotencyKey: string) => {
    const editing = form?.group;
    if (editing === undefined) {
      const created = await createGroup.mutateAsync({
        body: { code: values.code, ...toBody(values) },
        idempotencyKey,
      });
      setSelectedId(created.id);
      setForm(undefined);
      void message.success(t('rdm.groups.success.created', { name: created.name }));
      return;
    }
    await updateGroup.mutateAsync({ id: editing.id, version: editing.version ?? 0, body: toBody(values) });
    setForm(undefined);
    void message.success(t('rdm.groups.success.updated'));
  };

  const openConflict = async (values: GroupFormValues) => {
    const editing = form?.group;
    if (editing === undefined) {
      return;
    }
    const fresh = await groups.refetch();
    const server = findNode(fresh.data ?? [], editing.id) ?? editing;
    setConflict({ group: server, values, rows: diffRows(values, server) });
  };

  const overwrite = async () => {
    if (conflict === undefined) {
      return;
    }
    try {
      await updateGroup.mutateAsync({ id: conflict.group.id, version: conflict.group.version ?? 0, body: toBody(conflict.values) });
      setConflict(undefined);
      setForm(undefined);
      void message.success(t('rdm.groups.success.updated'));
    } catch (error) {
      setConflict(undefined);
      showFailure(t('rdm.groups.saveFailedTitle'), error, conflict.values.name);
    }
  };

  const showFailure = (title: string, error: unknown, name: string) => {
    const info = toUserMessage(error, { name });
    modal.error({
      title,
      okText: t('rdm.groups.delete.close'),
      content: (
        <ProblemAlert
          title={info.title}
          {...(info.hint !== undefined ? { detail: info.hint } : {})}
          {...(info.code !== undefined ? { code: info.code } : {})}
          {...(info.traceId !== undefined ? { traceId: info.traceId } : {})}
        />
      ),
      icon: null,
    });
  };

  const confirmDelete = (group: CatalogGroup) => {
    modal.confirm({
      title: t('rdm.groups.delete.title', { name: group.name }),
      content: t('rdm.groups.delete.body'),
      okText: t('rdm.groups.delete.confirm'),
      cancelText: t('rdm.groups.form.cancel'),
      okButtonProps: { danger: true },
      onOk: async () => {
        try {
          await deleteGroup.mutateAsync({ id: group.id, version: group.version ?? 0 });
          if (selectedId === group.id) {
            setSelectedId(undefined);
          }
          void message.success(t('rdm.groups.success.deleted', { name: group.name }));
        } catch (error) {
          showFailure(t('rdm.groups.delete.failedTitle'), error, group.name);
        }
      },
    });
  };

  const selected = selectedId === undefined ? undefined : findNode(tree, selectedId);
  const loadError = groups.isError ? toUserMessage(groups.error) : undefined;

  return (
    <div className="rdm-page">
      <section className="rdm-page__groups" aria-labelledby="rdm-groups-heading">
        <h2 id="rdm-groups-heading" className="rdm-page__heading">
          {t('rdm.groups.title')}
        </h2>
        <Input.Search
          allowClear
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder={t('rdm.groups.filter.placeholder')}
          aria-label={t('rdm.groups.filter.label')}
        />
        <p role="status" className="dh-visually-hidden">
          {filtering ? t('rdm.groups.filter.result', { count: countNodes(filtered) }) : ''}
        </p>
        <div className="rdm-page__tree">
          {groups.isPending ? (
            <Skeleton active title={false} paragraph={{ rows: 5 }} aria-label={t('rdm.groups.loading')} />
          ) : loadError !== undefined ? (
            <ProblemAlert
              title={loadError.title}
              {...(loadError.code !== undefined ? { code: loadError.code } : {})}
              {...(loadError.traceId !== undefined ? { traceId: loadError.traceId } : {})}
              onRetry={() => void groups.refetch()}
            />
          ) : filtered.length === 0 ? (
            <Empty description={filtering ? t('rdm.groups.emptyFiltered') : t('rdm.groups.empty')} />
          ) : (
            <CatalogGroupTree
              nodes={filtered}
              selectedId={selectedId}
              collapsed={collapsed}
              forceExpanded={filtering}
              canEdit={(group) => canEditGroup(user, group)}
              onSelect={setSelectedId}
              onToggle={toggle}
              onEdit={(group) => setForm({ group })}
              onDelete={confirmDelete}
            />
          )}
        </div>
        {canCreate ? (
          <div className="rdm-page__foot">
            <Button type="primary" icon={<PlusOutlined aria-hidden="true" />} block onClick={() => setForm({ group: undefined })}>
              {t('rdm.groups.add')}
            </Button>
          </div>
        ) : null}
      </section>

      <section className="rdm-page__table" aria-label={t('rdm.table.placeholder.title')}>
        <Empty description={t('rdm.table.placeholder.body')} />
      </section>

      {form !== undefined ? (
        <GroupFormModal
          key={form.group?.id ?? 'new'}
          group={form.group}
          tree={tree}
          dataTenant={dataTenantOf(user)}
          defaultParentId={selected !== undefined && selected.tenantId === dataTenantOf(user) ? selected.id : undefined}
          onSubmit={submit}
          onConflict={(values) => void openConflict(values)}
          onCancel={() => setForm(undefined)}
        />
      ) : null}
      <ConflictDialog
        open={conflict !== undefined}
        rows={conflict?.rows ?? []}
        onReload={() => {
          setConflict(undefined);
          setForm(undefined);
        }}
        onOverwrite={() => void overwrite()}
        onClose={() => setConflict(undefined)}
      />
    </div>
  );
}
