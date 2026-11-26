import { InMemoryWebStorage, UserManager, WebStorageStateStore } from 'oidc-client-ts';

export interface OidcConfig {
  authority: string;
  clientId: string;
  redirectUri: string;
  scope: string;
}

/** Đọc cấu hình OIDC từ biến môi trường build; thiếu thì ném lỗi rõ ràng. */
export function readOidcConfig(env: {
  VITE_OIDC_AUTHORITY?: string | undefined;
  VITE_OIDC_CLIENT_ID?: string | undefined;
  VITE_OIDC_REDIRECT_URI?: string | undefined;
  VITE_OIDC_SCOPE?: string | undefined;
}): OidcConfig {
  const { VITE_OIDC_AUTHORITY: authority, VITE_OIDC_CLIENT_ID: clientId } = env;
  if (!authority || !clientId) {
    throw new Error('Chưa cấu hình VITE_OIDC_AUTHORITY và VITE_OIDC_CLIENT_ID');
  }
  return {
    authority,
    clientId,
    redirectUri: env.VITE_OIDC_REDIRECT_URI || window.location.origin + '/',
    scope: env.VITE_OIDC_SCOPE || 'openid profile',
  };
}

/**
 * Đăng nhập Authorization Code + PKCE (FR-00-001). Hồ sơ người dùng (chứa token) nằm trong bộ nhớ;
 * chỉ trạng thái đăng nhập tạm của PKCE dùng sessionStorage để sống qua lần chuyển hướng.
 */
export function createUserManager(config: OidcConfig): UserManager {
  return new UserManager({
    authority: config.authority,
    client_id: config.clientId,
    redirect_uri: config.redirectUri,
    response_type: 'code',
    scope: config.scope,
    userStore: new WebStorageStateStore({ store: new InMemoryWebStorage() }),
    stateStore: new WebStorageStateStore({ store: window.sessionStorage }),
  });
}

export async function signInWithOidc(config: OidcConfig): Promise<string> {
  const manager = createUserManager(config);
  const params = new URLSearchParams(window.location.search);
  if (params.has('code') && params.has('state')) {
    const user = await manager.signinCallback();
    window.history.replaceState({}, document.title, config.redirectUri);
    if (user) {
      return user.access_token;
    }
  }
  const existing = await manager.getUser();
  if (existing && !existing.expired) {
    return existing.access_token;
  }
  await manager.signinRedirect();
  // Trình duyệt đã chuyển hướng; promise này không bao giờ hoàn tất.
  return new Promise<string>(() => undefined);
}
