import { execFileSync } from 'node:child_process';
import { DB_CONTAINER, DB_NAME } from './env';

/** Người dùng hệ thống của dữ liệu nền (seed 07-S01), dùng làm created_by cho dữ liệu dựng sẵn. */
const SEED_ACTOR = '0192f000-0000-7000-8000-00000000a001';

function psql(sql: string): string {
  return execFileSync(
    'docker',
    ['exec', DB_CONTAINER, 'psql', '-U', 'postgres', '-d', DB_NAME, '-v', 'ON_ERROR_STOP=1', '-tA', '-c', sql],
    { encoding: 'utf8' },
  ).trim();
}

const quote = (value: string): string => `'${value.replace(/'/g, "''")}'`;

/** Dựng nhóm cho bài kiểm thử (superuser, bỏ qua RLS). Mỗi bài dùng mã riêng nên không đụng nhau. */
export function seedGroup(tenant: string, code: string, name: string, parentCode?: string): void {
  const parent = parentCode === undefined ? 'null' : `(select id from ph07_rdm.catalog_group where tenant_id = ${quote(tenant)} and code = ${quote(parentCode)})`;
  psql(
    `insert into ph07_rdm.catalog_group (id, tenant_id, code, name, parent_id, sort_order, created_by, updated_by) ` +
      `values (uuidv7(), ${quote(tenant)}, ${quote(code)}, ${quote(name)}, ${parent}, 10, '${SEED_ACTOR}', '${SEED_ACTOR}')`,
  );
}

/** Gắn một danh mục vào nhóm để nhóm không còn xóa được. */
export function seedCatalog(tenant: string, code: string, groupCode: string): void {
  psql(
    `insert into ph07_rdm.catalog (id, tenant_id, code, name, group_id, created_by, updated_by) ` +
      `values (uuidv7(), ${quote(tenant)}, ${quote(code)}, ${quote('Danh mục ' + code)}, ` +
      `(select id from ph07_rdm.catalog_group where tenant_id = ${quote(tenant)} and code = ${quote(groupCode)}), '${SEED_ACTOR}', '${SEED_ACTOR}')`,
  );
}

export function groupExists(tenant: string, code: string): boolean {
  return psql(`select count(*) from ph07_rdm.catalog_group where tenant_id = ${quote(tenant)} and code = ${quote(code)}`) === '1';
}
