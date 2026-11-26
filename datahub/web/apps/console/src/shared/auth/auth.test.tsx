import { render, screen, waitFor } from '@testing-library/react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { adminToken } from '../../../../../test/fixtures';
import { AuthProvider, useAuth } from './AuthProvider';
import { parseClaims } from './claims';
import { readE2eToken } from './e2e-auth';
import { readOidcConfig } from './oidc';
import { tokenStore } from './token-store';

function Probe() {
  const { status, user, error } = useAuth();
  return <p>{`${status}|${user?.tenant ?? ''}|${user?.name ?? ''}|${error ?? ''}`}</p>;
}

afterEach(() => {
  tokenStore.set(undefined);
  delete window.__DH_E2E_TOKEN__;
});

describe('claims', () => {
  it('đọc tenant, quyền, vai trò và bỏ tiền tố ROLE-', () => {
    const user = parseClaims(adminToken);
    expect(user.tenant).toBe('T01');
    expect(user.perms).toContain('PERM-07-create');
    expect(user.roles).toEqual(['TENANT_ADMIN']);
    expect(user.name).toBe('Quản trị T01');
  });

  it('claim thiếu thì dùng giá trị rỗng, tên lấy từ sub; token sai định dạng thì ném lỗi', () => {
    const payload = btoa(JSON.stringify({ sub: 'abcdefghijk', roles: ['ROLE-PLATFORM_ADMIN', 5] }));
    const user = parseClaims(`h.${payload}.s`);
    expect(user).toMatchObject({ tenant: '', perms: [], roles: ['PLATFORM_ADMIN'], name: 'abcdefgh' });
    expect(() => parseClaims('khong-co-cham')).toThrow();
  });
});

describe('token-store và e2e-auth', () => {
  it('chỉ giữ trong bộ nhớ, không ghi storage', () => {
    tokenStore.set('abc');
    expect(tokenStore.get()).toBe('abc');
    expect(window.localStorage.length + window.sessionStorage.length).toBe(0);
  });

  it('đọc token e2e hoặc ném lỗi khi thiếu', () => {
    expect(() => readE2eToken()).toThrow();
    window.__DH_E2E_TOKEN__ = 'tok';
    expect(readE2eToken()).toBe('tok');
  });
});

describe('oidc config', () => {
  it('thiếu authority hoặc client thì ném lỗi; có đủ thì có mặc định', () => {
    expect(() => readOidcConfig({})).toThrow();
    const cfg = readOidcConfig({ VITE_OIDC_AUTHORITY: 'https://idp', VITE_OIDC_CLIENT_ID: 'dh' });
    expect(cfg).toMatchObject({ authority: 'https://idp', clientId: 'dh', scope: 'openid profile' });
    expect(cfg.redirectUri).toBe(`${window.location.origin}/`);
  });
});

describe('AuthProvider', () => {
  it('đăng nhập thành công: lưu token vào bộ nhớ và cấp người dùng', async () => {
    render(
      <AuthProvider acquire={() => Promise.resolve(adminToken)}>
        <Probe />
      </AuthProvider>,
    );
    expect(screen.getByText(/^loading/)).toBeInTheDocument();
    await waitFor(() => expect(screen.getByText(/^authenticated\|T01/)).toBeInTheDocument());
    expect(tokenStore.get()).toBe(adminToken);
  });

  it('đăng nhập thất bại: báo lỗi', async () => {
    const acquire = vi.fn(() => Promise.reject(new Error('hỏng')));
    render(
      <AuthProvider acquire={acquire}>
        <Probe />
      </AuthProvider>,
    );
    await waitFor(() => expect(screen.getByText('error|||hỏng')).toBeInTheDocument());
  });

  it('mặc định (không bật e2e) đi nhánh OIDC và báo lỗi cấu hình thiếu', async () => {
    render(
      <AuthProvider>
        <Probe />
      </AuthProvider>,
    );
    await waitFor(() => expect(screen.getByText(/^error/)).toBeInTheDocument());
  });
});
