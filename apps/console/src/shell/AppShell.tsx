import {
  ApiOutlined,
  ApartmentOutlined,
  AppstoreOutlined,
  FormOutlined,
  LogoutOutlined,
  UserOutlined,
} from '@ant-design/icons'
import { Button, Layout, Menu, Tooltip, Typography } from 'antd'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'

const { Sider, Content } = Layout

/**
 * Khung ứng dụng.
 *
 * **Chiều cao cố định bằng màn hình, không bao giờ tràn.** `Layout` ngoài cùng khóa
 * `height: 100vh` + `overflow: hidden`, nên mọi thứ dài hơn màn hình phải cuộn *bên trong*
 * khung của nó chứ không đẩy cả trang dài ra. Xem `.shell-content` trong `styles.css`.
 *
 * Danh tính người dùng và nút đăng xuất nằm ở **chân side menu**, không phải thanh trên:
 * thanh trên chỉ chứa hai thứ đó thì tốn nguyên một dải ngang của mọi màn để hiển thị
 * thông tin người dùng gần như không bao giờ cần đọc. Bỏ nó đi, toàn bộ chiều ngang và
 * dải đó thuộc về nội dung màn.
 */
export function AppShell() {
  const navigate = useNavigate()
  const location = useLocation()
  const { user, logout } = useAuth()
  const selected = location.pathname.split('/')[1] || 'flows'
  const name = user?.profile?.preferred_username ?? user?.profile?.email ?? ''

  return (
    <Layout className="shell">
      <Sider width={220} theme="dark" className="shell-sider">
        <div className="shell-logo">LGSP</div>

        {/* Menu chiếm phần co giãn và tự cuộn khi thêm mục — khối người dùng bên dưới
            luôn nằm nguyên ở chân, không bị đẩy khuất. */}
        <Menu
          theme="dark"
          mode="inline"
          className="shell-menu"
          selectedKeys={[selected]}
          onClick={({ key }) => navigate(`/${key}`)}
          items={[
            { key: 'flows', icon: <ApartmentOutlined />, label: 'Thiết kế luồng' },
            { key: 'onboarding', icon: <FormOutlined />, label: 'Kết nạp' },
            { key: 'catalog', icon: <ApiOutlined />, label: 'Catalog API' },
            { key: 'components', icon: <AppstoreOutlined />, label: 'Danh mục thành phần' },
          ]}
        />

        <div className="shell-user">
          <div className="shell-user__id">
            <UserOutlined className="shell-user__avatar" />
            {/* Tên đăng nhập có thể là email dài — cắt bằng `…` và cho tooltip xem đủ,
                thay vì để nó xuống dòng đẩy cao khối chân menu. */}
            <Tooltip title={name} placement="top">
              <Typography.Text className="shell-user__name" ellipsis>
                {name}
              </Typography.Text>
            </Tooltip>
          </div>
          <Button
            icon={<LogoutOutlined />}
            onClick={() => void logout()}
            block
            size="small"
            className="shell-user__logout"
          >
            Đăng xuất
          </Button>
        </div>
      </Sider>

      <Layout className="shell-main">
        <Content className="shell-content">
          <Outlet />
        </Content>
      </Layout>
    </Layout>
  )
}
