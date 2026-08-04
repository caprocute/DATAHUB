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
