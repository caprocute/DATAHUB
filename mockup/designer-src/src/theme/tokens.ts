import { theme, type ThemeConfig } from 'antd';

export type Mode = 'light' | 'dark';

/**
 * Nối hệ thiết kế của mockup vào Ant Design.
 *
 * `mockup/css/app.css` là nguồn duy nhất của các giá trị màu; ở đây chỉ khai báo lại
 * đúng những giá trị đó dưới dạng token antd, vì `ConfigProvider` cần số cụ thể chứ
 * không đọc được biến CSS. Hai nơi phải đi cùng nhau: sửa app.css thì sửa cả đây.
 *
 * Cơ sở của các lựa chọn màu, gồm cả những chỗ cố ý lệch khỏi mặc định antd để đạt
 * ngưỡng tương phản WCAG AA: docs/05-adr/README.md#adr-016
 */

const shared = {
  fontFamily:
    "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans', sans-serif",
  fontFamilyCode: "'JetBrains Mono', 'SFMono-Regular', Consolas, 'Liberation Mono', Menlo, monospace",
  fontSize: 14,
  borderRadius: 6,
  borderRadiusLG: 8,
  borderRadiusSM: 4,
  controlHeight: 32,
  wireframe: false,
};

const light: ThemeConfig['token'] = {
  ...shared,
  colorPrimary: '#1677ff',
  colorSuccess: '#52c41a',
  colorWarning: '#faad14',
  colorError: '#ff4d4f',
  colorInfo: '#1677ff',
  colorBgBase: '#ffffff',
  colorBgLayout: '#fafafa',
  colorBgContainer: '#ffffff',
  colorBgElevated: '#ffffff',
  colorText: '#09090b',
  colorTextSecondary: '#52525b',
  colorTextTertiary: '#71717a',
  colorTextQuaternary: '#a1a1aa',
  colorBorder: '#d4d4d8',
  colorBorderSecondary: '#e4e4e7',
  colorFillSecondary: '#f4f4f5',
  colorFillTertiary: '#fafafa',
};

const dark: ThemeConfig['token'] = {
  ...shared,
  colorPrimary: '#1668dc',
  colorSuccess: '#49aa19',
  colorWarning: '#d89614',
  colorError: '#dc4446',
  colorInfo: '#1668dc',
  colorBgBase: '#18181b',
  colorBgLayout: '#09090b',
  colorBgContainer: '#18181b',
  colorBgElevated: '#27272a',
  colorText: '#fafafa',
  colorTextSecondary: '#d4d4d8',
  colorTextTertiary: '#a1a1aa',
  colorTextQuaternary: '#71717a',
  colorBorder: '#3f3f46',
  colorBorderSecondary: '#27272a',
  colorFillSecondary: '#27272a',
  colorFillTertiary: '#18181b',
};

export function antdThemeFor(mode: Mode): ThemeConfig {
  return {
    algorithm: mode === 'dark' ? theme.darkAlgorithm : theme.defaultAlgorithm,
    token: mode === 'dark' ? dark : light,
    components: {
      // Nút của mockup theo lối shadcn: viền mảnh, bóng gần như không thấy.
      Button: { primaryShadow: 'none', defaultShadow: 'none', dangerShadow: 'none' },
      Select: { optionSelectedBg: mode === 'dark' ? '#111a2c' : '#e6f4ff' },
      Table: { headerBg: mode === 'dark' ? '#27272a' : '#fafafa' },
    },
  };
}
