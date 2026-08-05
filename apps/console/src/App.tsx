import { useEffect, useState } from 'react'
import { BrowserRouter, Navigate, Route, Routes, useLocation, useNavigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './auth/AuthContext'
import { takeBootTarget } from './auth/oidc'
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
    // Đang ở giữa lượt quay về từ Keycloak: URL còn `code`/`state` và phiên chưa dựng
    // xong. Đẩy sang `/login` lúc này sẽ **gói cả URL callback vào tham số `from`**,
    // callback bị tiêu thụ nhầm chỗ và deep link mất sạch. Đứng yên chờ
    // `handleOidcCallback` xong, `OidcRedirect` sẽ đưa tới đúng đích.
    const q = new URLSearchParams(location.search)
    if (q.has('code') || q.has('state') || q.has('error')) return null

    const target = `${location.pathname}${location.search}`
    return <Navigate to={`/login?from=${encodeURIComponent(target)}`} replace />
  }
  return children
}

/**
 * Trang mặc định khi vào `/`.
 *
 * `redirect_uri` của OIDC là `/`, nên ngay sau lượt quay về từ Keycloak route `index`
 * này được vẽ. Chuyển thẳng sang `/flows` ở đây là **cướp mất** nơi người dùng thật
 * sự định vào, nên phải xét đích deep link trước (G0-4).
 */
function HomeRedirect() {
  const { redirectTo, loading } = useAuth()
  // Đích bắt được đồng bộ lúc nạp trang — có sẵn ngay lượt vẽ đầu nên không thua
  // cuộc đua với effect bất đồng bộ của `AuthProvider` (G0-4).
  const [boot] = useState(() => takeBootTarget())
  if (boot) return <Navigate to={boot} replace />
  if (loading || redirectTo) return null
  return <Navigate to="/flows" replace />
}

/**
 * Đưa người dùng về đúng nơi họ định vào sau khi Keycloak trả về.
 *
 * Phải điều hướng bằng Router: đổi thanh địa chỉ bằng `history.replaceState` không làm
 * Router vẽ lại, nên đăng nhập xong người dùng vẫn đứng ở màn cũ.
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
            <Route index element={<HomeRedirect />} />
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
