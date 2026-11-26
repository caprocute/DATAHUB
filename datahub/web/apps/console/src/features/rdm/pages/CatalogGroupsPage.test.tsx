import { createRdmClient } from '@datahub/api-client';
import { DhThemeProvider } from '@datahub/ui';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { http, HttpResponse } from 'msw';
import { beforeEach, describe, expect, it } from 'vitest';
import { adminToken, BASE, fakeToken, group, sampleTree, viewerToken } from '../../../../../../test/fixtures';
import { server } from '../../../../../../test/server';
import { ApiProvider } from '../../../shared/api/ApiProvider';
import { AuthProvider } from '../../../shared/auth/AuthProvider';
import { CatalogGroupsPage } from './CatalogGroupsPage';

const problem = (status: number, code: string, extra: Record<string, unknown> = {}) =>
  HttpResponse.json({ type: 'about:blank', title: 'Lỗi', status, code, traceId: 'trace-9', ...extra }, { status, headers: { 'content-type': 'application/problem+json' } });

function renderPage(token: string) {
  const client = createRdmClient({ baseUrl: BASE, getToken: () => token });
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <DhThemeProvider>
      <AuthProvider acquire={() => Promise.resolve(token)}>
        <ApiProvider client={client}>
          <QueryClientProvider client={queryClient}>
            <GateThenPage />
          </QueryClientProvider>
        </ApiProvider>
      </AuthProvider>
    </DhThemeProvider>,
  );
}

import { useAuth } from '../../../shared/auth/AuthProvider';
function GateThenPage() {
  const { status } = useAuth();
  return status === 'authenticated' ? <CatalogGroupsPage /> : null;
}

let tree = sampleTree();
beforeEach(() => {
  tree = sampleTree();
  server.use(http.get(`${BASE}/catalog-groups`, () => HttpResponse.json({ items: tree })));
});

describe('trang nhóm danh mục', () => {
  it('hiện cây với số danh mục, nhãn dùng chung và khung phải giữ chỗ', async () => {
    renderPage(adminToken);
    const treeEl = await screen.findByRole('tree', { name: 'Nhóm danh mục' });
    const items = within(treeEl).getAllByRole('treeitem');
    expect(items).toHaveLength(3);
    expect(items[0]).toHaveAccessibleName(/Hành chính.*Dùng chung.*\(3\)|Hành chính.*\(3\)/s);
    expect(items[1]).toHaveAttribute('aria-expanded', 'true');
    expect(items[2]).toHaveAttribute('aria-level', '2');
    expect(screen.getByText(/Bảng danh mục \(F-07-001\)/)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Thêm nhóm' })).toBeInTheDocument();
    // COMMON chỉ đọc với tenant tỉnh: không có menu; nhóm của tenant có menu
    expect(screen.queryByRole('button', { name: 'Thao tác nhóm Hành chính' })).not.toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Thao tác nhóm Kinh tế' })).toBeInTheDocument();
  });

  it('người chỉ xem không thấy nút Thêm nhóm và menu thao tác', async () => {
    renderPage(viewerToken);
    await screen.findByRole('tree');
    expect(screen.queryByRole('button', { name: 'Thêm nhóm' })).not.toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /Thao tác nhóm/ })).not.toBeInTheDocument();
  });

  it('lọc không phân biệt dấu, báo số kết quả; không khớp thì báo trống', async () => {
    renderPage(adminToken);
    await screen.findByRole('tree');
    await userEvent.type(screen.getByRole('searchbox', { name: 'Lọc nhóm danh mục' }), 'doanh nghiep');
    expect(screen.getAllByRole('treeitem')).toHaveLength(2);
    expect(screen.getByRole('status')).toHaveTextContent('Tìm thấy 2 nhóm.');
    await userEvent.type(screen.getByRole('searchbox'), 'zzz');
    expect(await screen.findByText('Không có nhóm nào khớp.')).toBeInTheDocument();
  });

  it('bàn phím: mũi tên, Home/End, thu gọn bằng ArrowLeft, mở bằng ArrowRight', async () => {
    renderPage(adminToken);
    const first = (await screen.findAllByRole('treeitem'))[0]!;
    first.focus();
    await userEvent.keyboard('{ArrowDown}');
    expect(screen.getAllByRole('treeitem')[1]).toHaveFocus();
    await userEvent.keyboard('{ArrowLeft}');
    expect(screen.getAllByRole('treeitem')).toHaveLength(2);
    expect(screen.getAllByRole('treeitem')[1]).toHaveAttribute('aria-expanded', 'false');
    await userEvent.keyboard('{ArrowRight}');
    expect(screen.getAllByRole('treeitem')).toHaveLength(3);
    await userEvent.keyboard('{ArrowRight}');
    expect(screen.getAllByRole('treeitem')[2]).toHaveFocus();
    await userEvent.keyboard('{ArrowLeft}');
    expect(screen.getAllByRole('treeitem')[1]).toHaveFocus();
    await userEvent.keyboard('{End}');
    expect(screen.getAllByRole('treeitem')[2]).toHaveFocus();
    await userEvent.keyboard('{Home}');
    expect(screen.getAllByRole('treeitem')[0]).toHaveFocus();
    await userEvent.keyboard('{ArrowUp}{Enter}');
    expect(screen.getAllByRole('treeitem')[0]).toHaveAttribute('aria-selected', 'true');
  });

  it('thêm nhóm con: gửi Idempotency-Key, báo thành công, cây làm mới', async () => {
    let received: { body: unknown; key: string | null } | undefined;
    server.use(
      http.post(`${BASE}/catalog-groups`, async ({ request }) => {
        received = { body: await request.json(), key: request.headers.get('Idempotency-Key') };
        tree = [...tree, group({ id: 'g-new', code: 'MOI', name: 'Nhóm mới' })];
        return HttpResponse.json(tree[2], { status: 201, headers: { ETag: 'W/"1"' } });
      }),
    );
    renderPage(adminToken);
    await screen.findByRole('tree');
    await userEvent.click(screen.getByRole('button', { name: 'Thêm nhóm' }));
    const dialog = await screen.findByRole('dialog');
    await userEvent.type(within(dialog).getByLabelText('Mã nhóm'), 'moi');
    await userEvent.type(within(dialog).getByLabelText('Tên nhóm'), ' Nhóm mới ');
    await userEvent.click(within(dialog).getByRole('button', { name: 'Lưu' }));
    expect(await screen.findByText('Đã thêm nhóm "Nhóm mới".')).toBeInTheDocument();
    expect(received?.body).toMatchObject({ code: 'MOI', name: 'Nhóm mới', parentId: null, sortOrder: 0 });
    expect(received?.key).toMatch(/^[0-9a-f-]{36}$/);
    await waitFor(() => expect(screen.getAllByRole('treeitem')).toHaveLength(4));
  });

  it('thêm nhóm: kiểm tra phía khách và lỗi UNIQUE của máy chủ gắn vào ô Mã', async () => {
    server.use(
      http.post(`${BASE}/catalog-groups`, () => problem(409, 'ERR-07-039', { errors: [{ field: 'code', code: 'UNIQUE' }] })),
    );
    renderPage(adminToken);
    await screen.findByRole('tree');
    await userEvent.click(screen.getByRole('button', { name: 'Thêm nhóm' }));
    const dialog = await screen.findByRole('dialog');
    await userEvent.click(within(dialog).getByRole('button', { name: 'Lưu' }));
    expect(await within(dialog).findAllByText(/là bắt buộc/)).not.toHaveLength(0);
    await userEvent.type(within(dialog).getByLabelText('Mã nhóm'), 'KINH_TE');
    await userEvent.type(within(dialog).getByLabelText('Tên nhóm'), 'Trùng');
    await userEvent.click(within(dialog).getByRole('button', { name: 'Lưu' }));
    await waitFor(() => expect(within(dialog).queryByText(/là bắt buộc/)).not.toBeInTheDocument());
    expect(await within(dialog).findByText(/đã tồn tại|đã được dùng|trùng/i)).toBeInTheDocument();
  });

  it('lỗi không gắn được vào trường hiện ProblemAlert trong hộp thoại', async () => {
    server.use(http.post(`${BASE}/catalog-groups`, () => problem(500, 'ERR-00-500')));
    renderPage(adminToken);
    await screen.findByRole('tree');
    await userEvent.click(screen.getByRole('button', { name: 'Thêm nhóm' }));
    const dialog = await screen.findByRole('dialog');
    await userEvent.type(within(dialog).getByLabelText('Mã nhóm'), 'X1');
    await userEvent.type(within(dialog).getByLabelText('Tên nhóm'), 'X');
    await userEvent.click(within(dialog).getByRole('button', { name: 'Lưu' }));
    expect(await within(dialog).findByRole('alert')).toHaveTextContent('trace-9');
  });

  it('sửa nhóm: gửi If-Match theo version, báo đã lưu', async () => {
    let ifMatch: string | null = null;
    server.use(
      http.patch(`${BASE}/catalog-groups/g-eco`, ({ request }) => {
        ifMatch = request.headers.get('If-Match');
        return HttpResponse.json({ ...tree[1], name: 'Kinh tế mới', version: 5 }, { headers: { ETag: 'W/"5"' } });
      }),
    );
    renderPage(adminToken);
    await screen.findByRole('tree');
    await userEvent.click(screen.getByRole('button', { name: 'Thao tác nhóm Kinh tế' }));
    await userEvent.click(await screen.findByRole('menuitem', { name: 'Sửa' }));
    const dialog = await screen.findByRole('dialog');
    expect(within(dialog).getByLabelText('Mã nhóm')).toBeDisabled();
    const name = within(dialog).getByLabelText('Tên nhóm');
    await userEvent.clear(name);
    await userEvent.type(name, 'Kinh tế mới');
    await userEvent.click(within(dialog).getByRole('button', { name: 'Lưu' }));
    expect(await screen.findByText('Đã lưu nhóm.')).toBeInTheDocument();
    expect(ifMatch).toBe('W/"4"');
  });

  it('412: mở hộp thoại xung đột, Ghi đè xác nhận hai lần rồi gửi với version mới', async () => {
    const versions: Array<string | null> = [];
    server.use(
      http.patch(`${BASE}/catalog-groups/g-eco`, ({ request }) => {
        versions.push(request.headers.get('If-Match'));
        if (versions.length === 1) {
          tree = [tree[0]!, { ...tree[1]!, name: 'Tên của người khác', version: 6 }];
          return problem(412, 'ERR-07-018');
        }
        return HttpResponse.json({ ...tree[1], version: 7 });
      }),
    );
    renderPage(adminToken);
    await screen.findByRole('tree');
    await userEvent.click(screen.getByRole('button', { name: 'Thao tác nhóm Kinh tế' }));
    await userEvent.click(await screen.findByRole('menuitem', { name: 'Sửa' }));
    const form = await screen.findByRole('dialog');
    const name = within(form).getByLabelText('Tên nhóm');
    await userEvent.clear(name);
    await userEvent.type(name, 'Tên của tôi');
    await userEvent.click(within(form).getByRole('button', { name: 'Lưu' }));
    const conflict = (await screen.findByRole('button', { name: 'Ghi đè' })).closest<HTMLElement>('[role="dialog"]')!;
    expect(within(conflict).getByRole('cell', { name: 'Tên của người khác' })).toBeInTheDocument();
    await userEvent.click(within(conflict).getByRole('button', { name: 'Ghi đè' }));
    await userEvent.click(within(conflict).getByRole('button', { name: 'Ghi đè' }));
    expect(await screen.findByText('Đã lưu nhóm.')).toBeInTheDocument();
    expect(versions).toEqual(['W/"4"', 'W/"6"']);
  });

  it('412: Tải lại bỏ thay đổi và đóng cả hai hộp thoại', async () => {
    server.use(http.patch(`${BASE}/catalog-groups/g-eco`, () => problem(412, 'ERR-07-018')));
    renderPage(adminToken);
    await screen.findByRole('tree');
    await userEvent.click(screen.getByRole('button', { name: 'Thao tác nhóm Kinh tế' }));
    await userEvent.click(await screen.findByRole('menuitem', { name: 'Sửa' }));
    const form = await screen.findByRole('dialog');
    await userEvent.type(within(form).getByLabelText('Tên nhóm'), ' x');
    await userEvent.click(within(form).getByRole('button', { name: 'Lưu' }));
    await userEvent.click(await screen.findByRole('button', { name: 'Tải lại' }));
    await waitFor(() => expect(screen.queryByRole('button', { name: 'Ghi đè' })).not.toBeInTheDocument());
  });

  it('xóa nhóm rỗng: xác nhận, gửi If-Match, báo đã xóa', async () => {
    let ifMatch: string | null = null;
    server.use(
      http.delete(`${BASE}/catalog-groups/g-child`, ({ request }) => {
        ifMatch = request.headers.get('If-Match');
        return new HttpResponse(null, { status: 204 });
      }),
    );
    renderPage(adminToken);
    await screen.findByRole('tree');
    await userEvent.click(screen.getByRole('button', { name: 'Thao tác nhóm Doanh nghiệp' }));
    await userEvent.click(await screen.findByRole('menuitem', { name: 'Xóa' }));
    const confirm = await screen.findByRole('dialog');
    expect(confirm).toHaveTextContent('Xóa nhóm "Doanh nghiệp"?');
    await userEvent.click(within(confirm).getByRole('button', { name: 'Xóa' }));
    expect(await screen.findByText('Đã xóa nhóm "Doanh nghiệp".')).toBeInTheDocument();
    expect(ifMatch).toBe('W/"1"');
  });

  it('xóa nhóm còn danh mục: hiện ERR-07-037 kèm số danh mục', async () => {
    server.use(http.delete(`${BASE}/catalog-groups/g-eco`, () => problem(409, 'ERR-07-037', { catalogCount: 2, childCount: 1 })));
    renderPage(adminToken);
    await screen.findByRole('tree');
    await userEvent.click(screen.getByRole('button', { name: 'Thao tác nhóm Kinh tế' }));
    await userEvent.click(await screen.findByRole('menuitem', { name: 'Xóa' }));
    await userEvent.click(within(await screen.findByRole('dialog')).getByRole('button', { name: 'Xóa' }));
    const alert = await screen.findByRole('alert');
    expect(alert).toHaveTextContent('ERR-07-037');
    expect(alert).toHaveTextContent('2');
  });

  it('không tải được cây: hiện lỗi và cho thử lại; cây rỗng hiện Empty', async () => {
    server.use(http.get(`${BASE}/catalog-groups`, () => problem(403, 'ERR-07-003')));
    const first = renderPage(fakeToken({ tenant: 'T01', perms: ['PERM-07-read'], roles: ['DATA_STEWARD'] }));
    expect(await screen.findByRole('alert')).toHaveTextContent('ERR-07-003');
    server.use(http.get(`${BASE}/catalog-groups`, () => HttpResponse.json({ items: [] })));
    await userEvent.click(screen.getByRole('button', { name: 'Thử lại' }));
    expect(await screen.findByText('Chưa có nhóm danh mục nào.')).toBeInTheDocument();
    first.unmount();
  });
});
