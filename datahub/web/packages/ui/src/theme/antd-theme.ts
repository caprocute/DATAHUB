import { theme, type ThemeConfig } from 'antd';
import { tokens, type DhDensity, type DhGlass, type DhMode } from './tokens';

/** Lấy token theo tên; thiếu token là lỗi cấu hình, báo ngay thay vì trả `undefined` cho antd. */
function pick(record: Readonly<Record<string, string>>, name: string): string {
  const value = record[name];
  if (value === undefined) {
    throw new Error(`Thiếu token Datahub: ${name}`);
  }
  return value;
}

/**
 * Ánh xạ token Datahub sang theme antd 6 (D03-05-02 §13.4). Giá trị lấy từ `tokens`, không chép
 * tay. Lớp nổi (Modal, Popover, Dropdown) dùng glass; vùng nội dung dày dùng nền đặc (ADR-020).
 */
export function buildAntdTheme(mode: DhMode, density: DhDensity, glass: DhGlass): ThemeConfig {
  const t = tokens[mode];
  const c = t.color;
  const algorithm = [mode === 'dark' ? theme.darkAlgorithm : theme.defaultAlgorithm];
  if (density === 'compact') {
    algorithm.push(theme.compactAlgorithm);
  }
  const elevatedBg = glass === 'off' ? pick(c, 'surfaceSolid') : pick(t.glass, 'overlay');
  const compact = density === 'compact';

  return {
    cssVar: { prefix: 'ant' },
    hashed: false,
    algorithm,
    token: {
      colorPrimary: pick(c, 'accent'),
      colorPrimaryHover: pick(c, 'accentHover'),
      colorPrimaryActive: pick(c, 'accentPressed'),
      colorPrimaryBg: pick(c, 'accentSubtle'),
      colorPrimaryBgHover: pick(c, 'fillSelectedHover'),
      colorPrimaryText: pick(c, 'textLink'),
      colorLink: pick(c, 'textLink'),
      colorSuccess: pick(c, 'successText'),
      colorWarning: pick(c, 'warningText'),
      colorError: pick(c, 'errorText'),
      colorInfo: pick(c, 'infoText'),
      colorBgBase: pick(c, 'surfaceSolid'),
      colorTextBase: pick(c, 'textPrimary'),
      colorBgLayout: pick(c, 'canvas'),
      colorBgContainer: pick(c, 'surfaceSolid'),
      colorBgElevated: elevatedBg,
      colorBgSpotlight: pick(c, 'surfaceInverse'),
      colorBgMask: pick(c, 'scrim'),
      colorText: pick(c, 'textPrimary'),
      colorTextSecondary: pick(c, 'textSecondary'),
      colorTextTertiary: pick(c, 'textTertiary'),
      colorTextPlaceholder: pick(c, 'textTertiary'),
      colorTextDescription: pick(c, 'textTertiary'),
      colorTextDisabled: pick(c, 'textDisabled'),
      colorBorder: pick(c, 'borderControl'),
      colorBorderSecondary: pick(c, 'borderSubtle'),
      colorSplit: pick(c, 'borderSubtle'),
      fontSize: 14,
      lineHeight: 22 / 14,
      borderRadius: 10,
      borderRadiusSM: 6,
      borderRadiusLG: 14,
      borderRadiusXS: 4,
      lineWidthFocus: 2,
      motionDurationFast: '0.14s',
      motionDurationMid: '0.22s',
      motionDurationSlow: '0.32s',
      boxShadow: pick(t.shadow, '3'),
      boxShadowSecondary: pick(t.shadow, '3'),
      boxShadowTertiary: pick(t.shadow, '1'),
      wireframe: false,
    },
    components: {
      Layout: { bodyBg: 'transparent', headerBg: 'transparent', siderBg: 'transparent', headerHeight: compact ? 48 : 56 },
      Modal: { contentBg: elevatedBg, headerBg: 'transparent', footerBg: 'transparent', titleFontSize: 20, titleLineHeight: 1.4 },
      Popover: { colorBgElevated: elevatedBg },
      Tooltip: { maxWidth: 320 },
      Card: { headerFontSize: 16 },
      Button: { primaryShadow: 'none', defaultShadow: 'none', dangerShadow: 'none', fontWeight: 500 },
      Message: { contentBg: pick(c, 'surfaceInverse') },
    },
  };
}
