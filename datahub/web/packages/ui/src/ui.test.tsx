import { fireEvent, render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { AppShell, buildAntdTheme, ConflictDialog, DhThemeProvider, ProblemAlert, tokens, tokensToCss } from './index';

describe('token và theme antd', () => {
  it('sinh biến --dh-* cho sáng, tối và token tĩnh', () => {
    const css = tokensToCss();
    expect(css).toContain(':root[data-theme="dark"]');
    expect(css).toContain('--dh-color-accent:');
    expect(css).toContain('--dh-glass-chrome:');
  });

  it('ánh xạ màu antd từ token, không chép tay', () => {
    const light = buildAntdTheme('light', 'comfortable', 'full');
    expect(light.token?.colorPrimary).toBe(tokens.light.color['accent']);
    const dark = buildAntdTheme('dark', 'compact', 'off');
    expect(dark.token?.colorPrimary).toBe(tokens.dark.color['accent']);
    expect(dark.token?.colorBgElevated).toBe(tokens.dark.color['surfaceSolid']);
    expect(Array.isArray(dark.algorithm) ? dark.algorithm.length : 0).toBe(2);
  });

  it('DhThemeProvider đặt thuộc tính trên <html>', () => {
    render(
      <DhThemeProvider mode="dark" density="compact" glass="lite">
        <p>nội dung</p>
      </DhThemeProvider>,
    );
    expect(document.documentElement.dataset['theme']).toBe('dark');
    expect(document.documentElement.dataset['density']).toBe('compact');
    expect(document.documentElement.dataset['glass']).toBe('lite');
    expect(screen.getByText('nội dung')).toBeInTheDocument();
  });
});

describe('ProblemAlert', () => {
  it('hiện câu chính, gợi ý, mã lỗi và mã truy vết, sao chép được', async () => {
    const writeText = vi.fn(() => Promise.resolve());
    Object.defineProperty(navigator, 'clipboard', { value: { writeText }, configurable: true });
    const onRetry = vi.fn();
    render(<ProblemAlert title="Không xóa được" detail="Hãy chuyển danh mục." code="ERR-07-037" traceId="t-1" onRetry={onRetry} className="x" />);
    expect(screen.getByRole('alert')).toHaveTextContent('Không xóa được');
    expect(screen.getByText('Hãy chuyển danh mục.')).toBeInTheDocument();
    expect(screen.getByText(/ERR-07-037/)).toHaveTextContent('t-1');
    await userEvent.click(screen.getByRole('button', { name: 'Sao chép' }));
    expect(writeText).toHaveBeenCalledWith(expect.stringContaining('t-1'));
    await userEvent.click(screen.getByRole('button', { name: 'Thử lại' }));
    expect(onRetry).toHaveBeenCalled();
  });

  it('chỉ có tiêu đề thì không vẽ dòng mã', () => {
    render(<ProblemAlert title="Lỗi" />);
    expect(screen.queryByRole('button', { name: 'Sao chép' })).not.toBeInTheDocument();
  });

  it('chỉ có mã lỗi (chưa có traceId) vẫn hiện mã', () => {
    render(<ProblemAlert title="Lỗi" code="ERR-00-500" />);
    expect(screen.getByText('ERR-00-500')).toBeInTheDocument();
  });
});

describe('ConflictDialog', () => {
  const rows = [{ field: 'Tên nhóm', mine: 'A', server: 'B' }];

  it('Tải lại là nút mặc định; Ghi đè cần xác nhận lần hai', async () => {
    const onReload = vi.fn();
    const onOverwrite = vi.fn();
    render(<ConflictDialog open updatedBy="An" updatedAt="10:00" rows={rows} onReload={onReload} onOverwrite={onOverwrite} onClose={() => undefined} />);
    expect(screen.getByRole('dialog')).toHaveTextContent('Dữ liệu đã được An cập nhật lúc 10:00');
    expect(screen.getByRole('cell', { name: 'B' })).toBeInTheDocument();
    await userEvent.click(screen.getByRole('button', { name: 'Ghi đè' }));
    expect(onOverwrite).not.toHaveBeenCalled();
    expect(screen.getByText(/Tiếp tục/)).toBeInTheDocument();
    await userEvent.click(screen.getByRole('button', { name: 'Ghi đè' }));
    expect(onOverwrite).toHaveBeenCalledTimes(1);
  });

  it('bấm Tải lại gọi onReload; không có chênh lệch thì báo', async () => {
    const onReload = vi.fn();
    render(<ConflictDialog open rows={[]} onReload={onReload} onOverwrite={() => undefined} onClose={() => undefined} />);
    expect(screen.getByText('Không có trường nào khác nhau.')).toBeInTheDocument();
    expect(screen.getByRole('dialog')).toHaveTextContent('người khác cập nhật');
    await userEvent.click(screen.getByRole('button', { name: 'Tải lại' }));
    expect(onReload).toHaveBeenCalled();
  });
});

describe('AppShell', () => {
  const groups = [{ key: 'data', label: 'Dữ liệu', items: [{ key: 'catalogs', label: 'Danh mục dùng chung', href: '/du-lieu/danh-muc' }] }];

  it('có vùng mốc, liên kết bỏ qua, mục đang chọn và tên người dùng', () => {
    render(
      <AppShell brand="Datahub" groups={groups} activeKey="catalogs" tenantLabel="Tenant T01" userName="Nguyễn Văn An">
        <p>nội dung</p>
      </AppShell>,
    );
    expect(screen.getByRole('banner')).toBeInTheDocument();
    expect(screen.getByRole('navigation')).toBeInTheDocument();
    expect(screen.getByRole('main')).toHaveTextContent('nội dung');
    expect(screen.getByRole('link', { name: 'Danh mục dùng chung' })).toHaveAttribute('aria-current', 'page');
    expect(screen.getByRole('link', { name: 'Bỏ qua tới nội dung' })).toHaveAttribute('href', '#dh-main');
    expect(screen.getByText('Tenant T01')).toBeInTheDocument();
    expect(screen.getByText('VA')).toBeInTheDocument();
  });

  it('điều hướng phía khách khi có onNavigate, nhưng để trình duyệt xử lý khi giữ Ctrl', async () => {
    const onNavigate = vi.fn();
    render(
      <AppShell brand="Datahub" groups={groups} activeKey="" onNavigate={onNavigate}>
        <p>x</p>
      </AppShell>,
    );
    const link = screen.getByRole('link', { name: 'Danh mục dùng chung' });
    await userEvent.click(link);
    expect(onNavigate).toHaveBeenCalledWith('/du-lieu/danh-muc');
    onNavigate.mockClear();
    link.addEventListener('click', (event) => event.preventDefault(), { once: true });
    fireEvent.click(link, { ctrlKey: true });
    expect(onNavigate).not.toHaveBeenCalled();
  });
});
