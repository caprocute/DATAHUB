import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { t } from '@datahub/i18n';
import { parseClaims, type AuthUser } from './claims';
import { tokenStore } from './token-store';

export type AuthStatus = 'loading' | 'authenticated' | 'error';

interface AuthContextValue {
  status: AuthStatus;
  user: AuthUser | undefined;
  error: string | undefined;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

/** Lấy token: nhánh e2e chỉ tồn tại khi build với VITE_DH_E2E_AUTH=1, còn lại là OIDC. */
async function acquireToken(): Promise<string> {
  if (import.meta.env.VITE_DH_E2E_AUTH === '1') {
    const { readE2eToken } = await import('./e2e-auth');
    return readE2eToken();
  }
  const { readOidcConfig, signInWithOidc } = await import('./oidc');
  return signInWithOidc(readOidcConfig(import.meta.env));
}

export interface AuthProviderProps {
  children: ReactNode;
  /** Thay cách lấy token (kiểm thử). */
  acquire?: () => Promise<string>;
}

export function AuthProvider({ children, acquire = acquireToken }: AuthProviderProps) {
  const [state, setState] = useState<AuthContextValue>({ status: 'loading', user: undefined, error: undefined });

  useEffect(() => {
    let cancelled = false;
    acquire().then(
      (token) => {
        if (cancelled) {
          return;
        }
        tokenStore.set(token);
        setState({ status: 'authenticated', user: parseClaims(token), error: undefined });
      },
      (error: unknown) => {
        if (!cancelled) {
          setState({ status: 'error', user: undefined, error: error instanceof Error ? error.message : t('auth.failed') });
        }
      },
    );
    return () => {
      cancelled = true;
    };
  }, [acquire]);

  const value = useMemo(() => state, [state]);
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const value = useContext(AuthContext);
  if (value === undefined) {
    throw new Error('useAuth phải nằm trong AuthProvider');
  }
  return value;
}

/** Người dùng đã xác thực; chỉ gọi bên dưới cổng chờ đăng nhập. */
export function useCurrentUser(): AuthUser {
  const { user } = useAuth();
  if (user === undefined) {
    throw new Error('Chưa có người dùng đăng nhập');
  }
  return user;
}
