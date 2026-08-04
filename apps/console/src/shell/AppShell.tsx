import {
  ApiOutlined,
  ApartmentOutlined,
  FormOutlined,
  LogoutOutlined,
} from '@ant-design/icons'
import { Button, Layout, Menu, Typography } from 'antd'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'

const { Header, Sider, Content } = Layout

export function AppShell() {
  const navigate = useNavigate()
  const location = useLocation()
  const { user, logout } = useAuth()
  const selected = location.pathname.split('/')[1] || 'flows'

  return (
    <Layout style={{ minHeight: '100%' }}>
      <Sider width={220} theme="dark">
        <div style={{ padding: '16px 18px' }} className="shell-logo">
          LGSP
        </div>
        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[selected]}
          onClick={({ key }) => navigate(`/${key}`)}
          items={[
            { key: 'flows', icon: <ApartmentOutlined />, label: 'Luồng' },
            { key: 'onboarding', icon: <FormOutlined />, label: 'Kết nạp' },
            { key: 'catalog', icon: <ApiOutlined />, label: 'Catalog' },
          ]}
        />
      </Sider>
      <Layout>
        <Header
          style={{
            background: 'transparent',
            display: 'flex',
            justifyContent: 'flex-end',
            alignItems: 'center',
            gap: 12,
            paddingInline: 24,
          }}
        >
          <Typography.Text>
            {user?.profile?.preferred_username ?? user?.profile?.email}
          </Typography.Text>
          <Button icon={<LogoutOutlined />} onClick={() => void logout()}>
            Đăng xuất
          </Button>
        </Header>
        <Content style={{ padding: 24 }}>
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  )
}
