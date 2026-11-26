import { groupExists, seedCatalog, seedGroup, seedManyGroups } from './support/db';
import { expect, expectNoAxeViolations, openAs, test } from './support/fixtures';

test.describe('F-07-010 · Nhóm danh mục (UI-07-01, khung cây nhóm)', () => {
  test('xem cây nhóm: cấp lồng nhau, số danh mục, nhóm dùng chung, khung phải giữ chỗ', async ({ page }) => {
    seedGroup('T01', 'E2E_XEM', 'Nhóm xem e2e');
    seedGroup('T01', 'E2E_XEM.CON', 'Nhóm con xem e2e', 'E2E_XEM');
    seedCatalog('T01', 'E2E_XEM_DM1', 'E2E_XEM');

    await openAs(page, 'TA');
    const tree = page.getByRole('tree', { name: 'Nhóm danh mục' });
    await expect(tree).toBeVisible();

    const parent = tree.getByRole('treeitem', { name: /^Nhóm xem e2e/ });
    await expect(parent).toHaveAttribute('aria-level', '1');
    await expect(parent).toHaveAttribute('aria-expanded', 'true');
    await expect(parent).toContainText('(1)');
    await expect(tree.getByRole('treeitem', { name: /^Nhóm con xem e2e/ })).toHaveAttribute('aria-level', '2');
    await expect(tree.getByText('Dùng chung').first()).toBeVisible();
    await expect(page.getByText(/Bảng danh mục \(F-07-001\)/)).toBeVisible();
    await expect(page.getByRole('button', { name: 'Thêm nhóm' })).toBeVisible();

    await page.getByRole('searchbox', { name: 'Lọc nhóm danh mục' }).fill('nhom con xem');
    await expect(tree.getByRole('treeitem')).toHaveCount(2);
    await expectNoAxeViolations(page);
  });

  test('thêm nhóm con: hộp thoại, thông báo thành công, cây có nhóm mới', async ({ page }) => {
    seedGroup('T01', 'E2E_THEM', 'Nhóm cha thêm e2e');
    await openAs(page, 'TA');
    await page.getByRole('treeitem', { name: /^Nhóm cha thêm e2e/ }).click();
    await page.getByRole('button', { name: 'Thêm nhóm' }).click();

    const dialog = page.getByRole('dialog', { name: 'Thêm nhóm danh mục' });
    await expect(dialog).toBeVisible();
    await expectNoAxeViolations(page);

    await dialog.getByLabel('Mã nhóm').fill('e2e_them.con');
    await dialog.getByLabel('Tên nhóm').fill('Nhóm con thêm e2e');
    await dialog.getByRole('button', { name: 'Lưu' }).click();

    await expect(page.getByText('Đã thêm nhóm "Nhóm con thêm e2e".')).toBeVisible();
    const child = page.getByRole('treeitem', { name: /^Nhóm con thêm e2e/ });
    await expect(child).toHaveAttribute('aria-level', '2');
    expect(groupExists('T01', 'E2E_THEM.CON')).toBe(true);
  });

  test('thêm nhóm: mã trùng được báo ngay tại ô Mã', async ({ page }) => {
    seedGroup('T01', 'E2E_TRUNG', 'Nhóm trùng e2e');
    await openAs(page, 'TA');
    await page.getByRole('button', { name: 'Thêm nhóm' }).click();
    const dialog = page.getByRole('dialog', { name: 'Thêm nhóm danh mục' });
    await dialog.getByLabel('Mã nhóm').fill('E2E_TRUNG');
    await dialog.getByLabel('Tên nhóm').fill('Nhóm khác');
    await dialog.getByRole('button', { name: 'Lưu' }).click();
    await expect(dialog.locator('.ant-form-item-explain-error')).toContainText(/mã/i);
    await expectNoAxeViolations(page);
  });

  test('sửa nhóm: đổi tên, thông báo đã lưu, mã không đổi được', async ({ page }) => {
    seedGroup('T01', 'E2E_SUA', 'Nhóm sửa e2e');
    await openAs(page, 'TA');
    await page.getByRole('button', { name: 'Thao tác nhóm Nhóm sửa e2e' }).click();
    await page.getByRole('menuitem', { name: 'Sửa' }).click();
    const dialog = page.getByRole('dialog', { name: 'Sửa nhóm danh mục' });
    await expect(dialog.getByLabel('Mã nhóm')).toBeDisabled();
    await dialog.getByLabel('Tên nhóm').fill('Nhóm đã sửa e2e');
    await dialog.getByRole('button', { name: 'Lưu' }).click();
    await expect(page.getByText('Đã lưu nhóm.')).toBeVisible();
    await expect(page.getByRole('treeitem', { name: /^Nhóm đã sửa e2e/ })).toBeVisible();
  });

  test('xóa nhóm rỗng: xác nhận rồi nhóm biến mất', async ({ page }) => {
    seedGroup('T01', 'E2E_XOA', 'Nhóm xóa e2e');
    await openAs(page, 'TA');
    await page.getByRole('button', { name: 'Thao tác nhóm Nhóm xóa e2e' }).click();
    await page.getByRole('menuitem', { name: 'Xóa' }).click();
    const confirm = page.getByRole('dialog', { name: /Xóa nhóm "Nhóm xóa e2e"\?/ });
    await expect(confirm).toBeVisible();
    await expectNoAxeViolations(page);
    await confirm.getByRole('button', { name: 'Xóa' }).click();
    await expect(page.getByText('Đã xóa nhóm "Nhóm xóa e2e".')).toBeVisible();
    await expect(page.getByRole('treeitem', { name: /^Nhóm xóa e2e/ })).toHaveCount(0);
    expect(groupExists('T01', 'E2E_XOA')).toBe(false);
  });

  test('xóa nhóm còn danh mục: báo ERR-07-037 và nhóm vẫn còn', async ({ page }) => {
    seedGroup('T01', 'E2E_CODM', 'Nhóm có danh mục e2e');
    seedCatalog('T01', 'E2E_CODM_DM1', 'E2E_CODM');
    seedCatalog('T01', 'E2E_CODM_DM2', 'E2E_CODM');
    await openAs(page, 'TA');
    await page.getByRole('button', { name: 'Thao tác nhóm Nhóm có danh mục e2e' }).click();
    await page.getByRole('menuitem', { name: 'Xóa' }).click();
    await page.getByRole('dialog', { name: /Xóa nhóm/ }).getByRole('button', { name: 'Xóa' }).click();

    const alert = page.getByRole('alert');
    await expect(alert).toContainText('ERR-07-037');
    await expect(alert).toContainText('2');
    await expect(alert).toContainText('Mã truy vết');
    await expectNoAxeViolations(page);
    await page.getByRole('button', { name: 'Đóng' }).click();
    expect(groupExists('T01', 'E2E_CODM')).toBe(true);
  });

  test('người dùng chỉ xem không thấy nút Thêm nhóm và menu thao tác', async ({ page }) => {
    seedGroup('T01', 'E2E_CHIXEM', 'Nhóm chỉ xem e2e');
    await openAs(page, 'DS');
    await expect(page.getByRole('treeitem', { name: /^Nhóm chỉ xem e2e/ })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Thêm nhóm' })).toHaveCount(0);
    await expect(page.getByRole('button', { name: /Thao tác nhóm/ })).toHaveCount(0);
    await expectNoAxeViolations(page);
  });

  test('quản trị nền tảng sửa được nhóm dùng chung; quản trị tỉnh thì không', async ({ page }) => {
    await openAs(page, 'PA');
    await expect(page.getByRole('button', { name: /Thao tác nhóm/ }).first()).toBeVisible();
    await page.context().clearCookies();
    const other = await page.context().newPage();
    await openAs(other, 'TA');
    const common = other.getByRole('treeitem').filter({ hasText: 'Dùng chung' }).first();
    await expect(common).toBeVisible();
    await expect(common.getByRole('button', { name: /Thao tác nhóm/ })).toHaveCount(0);
  });

  // Chặn hồi quy bố cục (CC-FE-14): nhiều nhóm thì cây cuộn TRONG khung, nút ở chân cây luôn thấy.
  for (const viewport of [
    { width: 1440, height: 900 },
    { width: 1280, height: 720 },
  ]) {
    test(`cây nhiều nhóm cuộn trong khung, nút Thêm nhóm luôn trong màn hình ${viewport.width}x${viewport.height}`, async ({ page }) => {
      const prefix = `E2E_DAI${viewport.width}`;
      seedManyGroups('T01', prefix, 35);
      await page.setViewportSize(viewport);
      await openAs(page, 'TA');

      const tree = page.getByRole('tree', { name: 'Nhóm danh mục' });
      const add = page.getByRole('button', { name: 'Thêm nhóm' });
      await expect(tree.getByRole('treeitem', { name: new RegExp(`^Nhóm ${prefix} 001`) })).toBeVisible();

      // Nút ở chân khung nằm gọn trong màn hình ngay khi mở, không cần cuộn trang.
      const addBox = await add.boundingBox();
      expect(addBox).not.toBeNull();
      expect((addBox?.y ?? Infinity) + (addBox?.height ?? 0)).toBeLessThanOrEqual(viewport.height);

      // Khung cây tự cuộn (nội dung dài hơn khung) và không làm trang giãn ra.
      const metrics = await tree.evaluate((el) => {
        const scroller = el.parentElement as HTMLElement;
        return { scrollHeight: scroller.scrollHeight, clientHeight: scroller.clientHeight, docHeight: document.documentElement.scrollHeight };
      });
      expect(metrics.scrollHeight).toBeGreaterThan(metrics.clientHeight);
      expect(metrics.docHeight).toBeLessThanOrEqual(viewport.height);

      // Nhóm cuối cuộn tới được và nằm trong khung cây, trong màn hình.
      const last = tree.getByRole('treeitem', { name: new RegExp(`^Nhóm ${prefix} 035`) });
      await last.scrollIntoViewIfNeeded();
      await expect(last).toBeInViewport({ ratio: 0.9 });
      const lastBox = await last.boundingBox();
      const treeBox = await tree.locator('xpath=..').boundingBox();
      expect((lastBox?.y ?? Infinity) + (lastBox?.height ?? 0)).toBeLessThanOrEqual((treeBox?.y ?? 0) + (treeBox?.height ?? 0) + 1);
      await expect(add).toBeInViewport({ ratio: 1 });
      await expectNoAxeViolations(page);
    });
  }
});
