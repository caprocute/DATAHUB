import { Button, Typography } from 'antd'
import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'

export function LoginPage() {
  const { user, loading, login } = useAuth()
  const location = useLocation()
  /**
   * Nơi người dùng định vào trước khi bị chặn.
   *
   * Ưu tiên query (sống qua tải lại trang và qua vòng chuyển sang Keycloak), rồi mới
   * tới `state` của Router để tương thích lối điều hướng cũ. Chỉ nhận đường dẫn nội
   * bộ bắt đầu bằng một dấu `/` — nhận cả URL tuyệt đối là mở đường chuyển hướng
   * người dùng sang trang ngoài ngay sau khi đăng nhập (open redirect).
   */
  const raw =
    new URLSearchParams(location.search).get('from') ??
    (location.state as { from?: string } | null)?.from
  const from = raw && /^\/(?!\/)/.test(raw) ? raw : undefined

  if (loading) return null
  // Còn tham số callback trên URL nghĩa là `handleOidcCallback` chưa chạy xong; tự
  // điều hướng lúc này sẽ tranh chấp với `OidcRedirect` và cướp mất đích deep link.
  const q = new URLSearchParams(location.search)
  if (q.has('code') || q.has('state') || q.has('error')) return null
  // Đã có phiên rồi thì vào thẳng, không bắt bấm lại nút đăng nhập.
  if (user) return <Navigate to={from && from !== '/login' ? from : '/flows'} replace />

  return (
    <div
      style={{
        minHeight: '100%',
        display: 'grid',
        placeItems: 'center',
        padding: 24,
      }}
    >
      <div className="page-card" style={{ maxWidth: 420, width: '100%' }}>
        <Typography.Title level={2} style={{ marginTop: 0 }}>
          LGSP
        </Typography.Title>
        <Typography.Paragraph type="secondary">
          Console quản trị — đăng nhập Keycloak DEV (realm <code>lgsp</code>).
        </Typography.Paragraph>
        <Button type="primary" size="large" block onClick={() => void login(from)}>
          Đăng nhập OIDC
        </Button>
      </div>
    </div>
  )
}
