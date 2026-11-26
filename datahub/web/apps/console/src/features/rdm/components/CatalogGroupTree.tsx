import type { CatalogGroup } from '@datahub/api-client';
import { t } from '@datahub/i18n';
import { Button, CaretDownOutlined, CaretRightOutlined, Dropdown, EllipsisOutlined, Tag, type MenuProps } from '@datahub/ui';
import { useRef, useState, type KeyboardEvent, type ReactNode } from 'react';
import { childrenOf, findNode, parentIdOf, visibleIds } from '../tree-model';

export interface CatalogGroupTreeProps {
  nodes: readonly CatalogGroup[];
  selectedId: string | undefined;
  collapsed: ReadonlySet<string>;
  /** Lọc đang bật: mọi nhánh được mở để thấy kết quả. */
  forceExpanded: boolean;
  /** Nhóm này có hiện menu "⋯" Sửa, Xóa không (theo quyền và tenant). */
  canEdit: (group: CatalogGroup) => boolean;
  onSelect: (id: string) => void;
  onToggle: (id: string) => void;
  onEdit: (group: CatalogGroup) => void;
  onDelete: (group: CatalogGroup) => void;
}

const idOfLabel = (id: string) => `grp-${id}-label`;
const idOfCount = (id: string) => `grp-${id}-count`;
const idOfBadge = (id: string) => `grp-${id}-badge`;

/**
 * Cây nhóm theo mẫu WAI-ARIA `tree` (D03-06-PH07 §7.8), dạng phẳng (treeitem anh em, cấp bằng aria-level,
 * để tên truy cập của mỗi mục chỉ gồm chữ của chính nó): role tree/treeitem, aria-level,
 * aria-setsize, aria-posinset, aria-expanded, aria-selected; một điểm dừng tab (roving tabindex);
 * mũi tên, Home, End, Enter/Space; Shift+F10 hoặc phím Menu mở thao tác của nút.
 */
export function CatalogGroupTree({ nodes, selectedId, collapsed, forceExpanded, canEdit, onSelect, onToggle, onEdit, onDelete }: CatalogGroupTreeProps) {
  const effectiveCollapsed: ReadonlySet<string> = forceExpanded ? new Set<string>() : collapsed;
  const ids = visibleIds(nodes, effectiveCollapsed);
  const [focusedId, setFocusedId] = useState<string | undefined>(undefined);
  const [menuFor, setMenuFor] = useState<string | undefined>(undefined);
  const itemRefs = useRef(new Map<string, HTMLLIElement>());

  const tabStop = focusedId !== undefined && ids.includes(focusedId) ? focusedId : (selectedId !== undefined && ids.includes(selectedId) ? selectedId : ids[0]);

  const focusItem = (id: string | undefined) => {
    if (id === undefined) {
      return;
    }
    setFocusedId(id);
    itemRefs.current.get(id)?.focus();
  };

  const onKeyDown = (event: KeyboardEvent<HTMLUListElement>) => {
    const target = (event.target as HTMLElement).closest<HTMLElement>('[role="treeitem"]');
    const id = target?.dataset['id'];
    if (id === undefined || target !== event.target) {
      return;
    }
    const index = ids.indexOf(id);
    const node = findNode(nodes, id);
    if (node === undefined) {
      return;
    }
    const hasChildren = childrenOf(node).length > 0;
    const isCollapsed = effectiveCollapsed.has(id);
    switch (event.key) {
      case 'ArrowDown':
        focusItem(ids[index + 1]);
        break;
      case 'ArrowUp':
        focusItem(ids[index - 1]);
        break;
      case 'Home':
        focusItem(ids[0]);
        break;
      case 'End':
        focusItem(ids[ids.length - 1]);
        break;
      case 'ArrowRight':
        if (hasChildren && isCollapsed) {
          onToggle(id);
        } else if (hasChildren) {
          focusItem(ids[index + 1]);
        }
        break;
      case 'ArrowLeft':
        if (hasChildren && !isCollapsed && !forceExpanded) {
          onToggle(id);
        } else {
          focusItem(parentIdOf(nodes, id));
        }
        break;
      case 'Enter':
      case ' ':
        onSelect(id);
        break;
      case 'ContextMenu':
        if (canEdit(node)) {
          setMenuFor(id);
        }
        break;
      case 'F10':
        if (event.shiftKey && canEdit(node)) {
          setMenuFor(id);
        } else {
          return;
        }
        break;
      default:
        return;
    }
    event.preventDefault();
    event.stopPropagation();
  };

  const render = (list: readonly CatalogGroup[], level: number): ReactNode[] =>
    list.flatMap((node, position) => {
      const kids = childrenOf(node);
      const hasChildren = kids.length > 0;
      const expanded = hasChildren && !effectiveCollapsed.has(node.id);
      const selected = node.id === selectedId;
      const editable = canEdit(node);
      const items: MenuProps['items'] = [
        { key: 'edit', label: t('rdm.groups.menu.edit') },
        { key: 'delete', label: t('rdm.groups.menu.delete'), danger: true },
      ];
      const item = (
        <li
          key={node.id}
          role="treeitem"
          ref={(element) => {
            if (element) {
              itemRefs.current.set(node.id, element);
            } else {
              itemRefs.current.delete(node.id);
            }
          }}
          data-id={node.id}
          data-code={node.code}
          aria-level={level}
          aria-setsize={list.length}
          aria-posinset={position + 1}
          aria-expanded={hasChildren ? expanded : undefined}
          aria-selected={selected}
          aria-labelledby={[idOfLabel(node.id), node.tenantId === 'COMMON' ? idOfBadge(node.id) : undefined, idOfCount(node.id)].filter(Boolean).join(' ')}
          tabIndex={node.id === tabStop ? 0 : -1}
          className="rdm-tree__item"
          onFocus={(event) => {
            if (event.target === event.currentTarget) {
              setFocusedId(node.id);
            }
          }}
        >
          <div className={selected ? 'rdm-tree__row rdm-tree__row--selected' : 'rdm-tree__row'}>
            <span
              className="rdm-tree__toggle"
              aria-hidden="true"
              onClick={() => {
                if (hasChildren && !forceExpanded) {
                  onToggle(node.id);
                }
              }}
            >
              {hasChildren ? expanded ? <CaretDownOutlined /> : <CaretRightOutlined /> : null}
            </span>
            <span
              role="presentation"
              className="rdm-tree__label"
              onClick={() => {
                onSelect(node.id);
                setFocusedId(node.id);
              }}
            >
              <span id={idOfLabel(node.id)} className="rdm-tree__name">
                {node.name}
              </span>
              {node.tenantId === 'COMMON' ? ' ' : null}
              {node.tenantId === 'COMMON' ? (
                <span id={idOfBadge(node.id)}>
                  <Tag className="rdm-tree__badge">{t('rdm.groups.commonBadge.short')}</Tag>
                </span>
              ) : null}
              {' '}
              <span id={idOfCount(node.id)} className="rdm-tree__count">
                {`(${node.catalogCount ?? 0})`}
              </span>
            </span>
            {editable ? (
              <Dropdown
                trigger={['click']}
                open={menuFor === node.id}
                onOpenChange={(open) => setMenuFor(open ? node.id : undefined)}
                menu={{
                  items,
                  onClick: ({ key }) => {
                    setMenuFor(undefined);
                    if (key === 'edit') {
                      onEdit(node);
                    } else {
                      onDelete(node);
                    }
                  },
                }}
              >
                <Button
                  type="text"
                  size="small"
                  className="rdm-tree__menu"
                  tabIndex={-1}
                  aria-label={t('rdm.groups.menu', { name: node.name })}
                  icon={<EllipsisOutlined />}
                />
              </Dropdown>
            ) : null}
          </div>
        </li>
      );
      return expanded ? [item, ...render(kids, level + 1)] : [item];
    });

  return (
    <ul role="tree" aria-label={t('rdm.groups.title')} className="rdm-tree" onKeyDown={onKeyDown}>
      {render(nodes, 1)}
    </ul>
  );
}
