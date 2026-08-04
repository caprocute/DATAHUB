import { Button, Typography } from 'antd'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'

export function LoginPage() {
  const { user, loading, login } = useAuth()
  if (loading) return null
  if (user) return <Navigate to="/flows" replace />

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
        <Button type="primary" size="large" block onClick={() => void login()}>
          Đăng nhập OIDC
        </Button>
      </div>
    </div>
  )
}
