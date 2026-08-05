import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { App as AntApp, ConfigProvider, theme } from 'antd'
import viVN from 'antd/locale/vi_VN'
import App from './App'
import './styles.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ConfigProvider
      locale={viVN}
      theme={{
        algorithm: theme.defaultAlgorithm,
        token: {
          colorPrimary: '#0B5CAB',
          borderRadius: 6,
          fontFamily: '"Be Vietnam Pro", "Segoe UI", sans-serif',
          // Tương phản WCAG AA (N-7). Tông mặc định của antd cho thẻ trạng thái chỉ
          // đạt ~3,3:1 trên nền nhạt của chính nó — dưới ngưỡng 4,5:1 cho chữ thường.
          // Thẻ trạng thái luồng là thông tin nghiệp vụ, phải đọc được.
          //
          // Chỉnh qua **token của antd** chứ không đè bằng CSS: antd dùng CSS-in-JS
          // sinh lớp riêng, quy tắc ngoài không thắng được dù tăng độ ưu tiên.
          colorSuccess: '#15803d',
          colorError: '#b91c1c',
          colorWarning: '#b45309',
          colorInfo: '#1d4ed8',
        },
      }}
    >
      {/* `AntApp` cấp context cho `App.useApp()` — thiếu nó thì `message`/`modal`
          chỉ là hàm rỗng và gọi vào sẽ ném `message.success is not a function`. */}
      <AntApp>
        <App />
      </AntApp>
    </ConfigProvider>
  </StrictMode>,
)
