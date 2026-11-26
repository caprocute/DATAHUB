import { t } from '@datahub/i18n';
import { AppShell, DhThemeProvider, ProblemAlert, Spin, type ShellNavGroup } from '@datahub/ui';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState, type ReactNode } from 'react';
import { BrowserRouter, Navigate, Route, Routes, useLocation, useNavigate } from 'react-router-dom';
import { ApiProvider } from '../shared/api/ApiProvider';
import { AuthProvider, useAuth } from '../shared/auth/AuthProvider';
import { CatalogGroupsPage } from '../features/rdm/pages/CatalogGroupsPage';

export const CATALOG_PATH = '/du-lieu/danh-muc';

const NAV: readonly ShellNavGroup[] = [
  {
    key: 'data',
    label: t('app.nav.data'),
    items: [{ key: 'catalogs', label: t('app.nav.catalogs'), href: CATALOG_PATH }],
  },
];

function Layout({ children }: { children: ReactNode }) {
  const { user } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const active = location.pathname.startsWith(CATALOG_PATH) ? 'catalogs' : '';
  return (
    <AppShell
      brand={t('app.name')}
      groups={NAV}
      activeKey={active}
      onNavigate={(href) => void navigate(href)}
      {...(user !== undefined ? { tenantLabel: t('app.tenant', { tenant: user.tenant }), userName: user.name } : {})}
    >
      {children}
    </AppShell>
  );
}

/** Cổng chờ đăng nhập: chỉ vẽ ứng dụng khi đã có token (giữ trong bộ nhớ). */
function AuthGate({ children }: { children: ReactNode }) {
  const { status, error } = useAuth();
  if (status === 'loading') {
    return (
      <div role="status">
        <Spin tip={t('auth.signingIn')} />
      </div>
    );
  }
  if (status === 'error') {
    return <ProblemAlert title={error ?? t('auth.failed')} />;
  }
  return <>{children}</>;
}

export function App() {
  const [queryClient] = useState(
    () => new QueryClient({ defaultOptions: { queries: { retry: false, refetchOnWindowFocus: false } } }),
  );
  return (
    <DhThemeProvider>
      <AuthProvider>
        <AuthGate>
          <ApiProvider>
            <QueryClientProvider client={queryClient}>
              <BrowserRouter>
                <Layout>
                  <Routes>
                    <Route path={CATALOG_PATH} element={<CatalogGroupsPage />} />
                    <Route path="*" element={<Navigate to={CATALOG_PATH} replace />} />
                  </Routes>
                </Layout>
              </BrowserRouter>
            </QueryClientProvider>
          </ApiProvider>
        </AuthGate>
      </AuthProvider>
    </DhThemeProvider>
  );
}
