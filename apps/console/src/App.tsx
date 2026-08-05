import { useEffect } from 'react'
import { BrowserRouter, Navigate, Route, Routes, useLocation, useNavigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './auth/AuthContext'
import { AppShell } from './shell/AppShell'
import { CatalogPage } from './pages/CatalogPage'
import { DesignerPage } from './flows/design/DesignerPage'
import { FlowListPage } from './flows/list/FlowListPage'
import { ReviewPage } from './flows/review/ReviewPage'
import { RunLogPage } from './flows/runs/RunLogPage'
import { TestRunPage } from './flows/test/TestRunPage'
import { OnboardingPage } from './pages/OnboardingPage'
import { LoginPage } from './pages/LoginPage'

function Protected({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth()
  const location = useLocation()
  if (loading) return null
  // Mang theo nơi định vào để đăng nhập xong quay lại đúng chỗ, không đổ về mặc định.
  //
  // Đặt trong **query** chứ không chỉ `state` của Router: `state` nằm trong bộ nhớ,
  // mất khi người dùng tải lại trang `/login` hoặc dán thẳng link. Query sống qua cả
  // vòng chuyển trang sang Keycloak nên deep link mới thật sự được giữ (G0-4).
  if (!user) {
    const target = `${location.pathname}${location.search}`
    return <Navigate to={`/login?from=${encodeURIComponent(target)}`} replace />
  }
  return children
}

/**
 * Đưa người dùng về đúng nơi họ định vào sau khi Keycloak trả về.
 *
 * Phải điều hướng bằng Router: đổi thanh địa chỉ bằng `history.replaceState`
 * không làm Router vẽ lại, nên đăng nhập xong người dùng vẫn đứng ở trang đăng nhập.
 */
function OidcRedirect() {
  const { redirectTo, clearRedirect } = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    if (!redirectTo) return
    navigate(redirectTo, { replace: true })
    clearRedirect()
  }, [redirectTo, navigate, clearRedirect])

  return null
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <OidcRedirect />
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route
            path="/flows/:code/design"
            element={
              <Protected>
                <DesignerPage />
              </Protected>
            }
          />
          <Route
            path="/"
            element={
              <Protected>
                <AppShell />
              </Protected>
            }
          >
            <Route index element={<Navigate to="/flows" replace />} />
            <Route path="flows" element={<FlowListPage />} />
            <Route path="flows/review" element={<ReviewPage />} />
            <Route path="flows/:code/test" element={<TestRunPage />} />
            <Route path="flows/:code/runs" element={<RunLogPage />} />
            <Route path="onboarding" element={<OnboardingPage />} />
            <Route path="catalog" element={<CatalogPage />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
