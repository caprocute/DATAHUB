/**
 * Design token Datahub (D03-05-02): NGUỒN DUY NHẤT của màu, bo góc, khoảng cách, chữ, kích thước.
 * Từ đây sinh biến CSS `--dh-*` (tokensToCss) và theme antd (buildAntdTheme). Ứng dụng và thành
 * phần chỉ dùng `var(--dh-*)`, không viết màu hoặc px cứng (CC-FE-13).
 */
export type DhMode = 'light' | 'dark';
export type DhDensity = 'comfortable' | 'compact';
export type DhGlass = 'full' | 'lite' | 'off';

export interface ModeTokens {
  readonly color: Readonly<Record<string, string>>;
  readonly glass: Readonly<Record<string, string>>;
  readonly shadow: Readonly<Record<string, string>>;
}

const light: ModeTokens = {
  color: {
    canvas: '#F2F3F7',
    canvasWash:
      'radial-gradient(1200px 600px at 10% -10%, #DCE8FB 0%, transparent 60%), radial-gradient(900px 500px at 100% 0%, #EDE7FB 0%, transparent 55%)',
    surfaceSolid: '#FFFFFF',
    surfaceSolid2: '#F7F8FA',
    fillControl: '#EEEEF1',
    fillHover: 'rgba(0,0,0,0.04)',
    fillPressed: 'rgba(0,0,0,0.08)',
    fillSelected: '#E8F1FC',
    fillSelectedHover: '#D6E6FA',
    scrim: 'rgba(15,17,21,0.32)',
    surfaceInverse: '#1D1D1F',
    textOnInverse: '#F5F5F7',
    textPrimary: '#1D1D1F',
    textSecondary: '#4B4B55',
    textTertiary: '#63636D',
    textDisabled: '#9A9AA2',
    textLink: '#0A66D8',
    textOnAccent: '#FFFFFF',
    accent: '#0A66D8',
    accentHover: '#0857BC',
    accentPressed: '#0749A0',
    accentSubtle: '#E8F1FC',
    accentOnSubtle: '#0A66D8',
    borderControl: '#868690',
    borderSubtle: '#D9D9DE',
    borderGlassHighlight: 'rgba(255,255,255,0.65)',
    borderGlassEdge: 'rgba(0,0,0,0.08)',
    focusRing: '#0A66D8',
    focusRingInner: '#FFFFFF',
    successText: '#1A7F37',
    successBg: '#E8F5EC',
    warningText: '#8A5A00',
    warningBg: '#FFF4D6',
    errorText: '#B4232A',
    errorBg: '#FDECEC',
    errorSolid: '#C9252D',
    infoText: '#0A66D8',
    infoBg: '#E8F1FC',
    neutralText: '#4B4B55',
    neutralBg: '#EEEEF1',
  },
  glass: {
    chrome: 'rgba(255,255,255,0.72)',
    chromeScrolled: 'rgba(255,255,255,0.86)',
    modal: 'rgba(255,255,255,0.88)',
    overlay: 'rgba(255,255,255,0.94)',
    lite: 'rgba(255,255,255,0.96)',
    highlightTop: 'inset 0 1px 0 0 rgba(255,255,255,0.65)',
    edge: '0 0 0 0.5px rgba(0,0,0,0.08)',
  },
  shadow: {
    '0': 'none',
    '1': '0 1px 2px rgba(16,24,40,0.06), 0 1px 3px rgba(16,24,40,0.08)',
    '2': '0 2px 6px rgba(16,24,40,0.06), 0 8px 24px rgba(16,24,40,0.08)',
    '3': '0 4px 12px rgba(16,24,40,0.08), 0 16px 40px rgba(16,24,40,0.12)',
    '4': '0 8px 24px rgba(16,24,40,0.12), 0 32px 64px rgba(16,24,40,0.18)',
  },
};

const dark: ModeTokens = {
  color: {
    canvas: '#0E0E10',
    canvasWash:
      'radial-gradient(1200px 600px at 10% -10%, #10233F 0%, transparent 60%), radial-gradient(900px 500px at 100% 0%, #1B1530 0%, transparent 55%)',
    surfaceSolid: '#1C1C1E',
    surfaceSolid2: '#242427',
    fillControl: '#2C2C2E',
    fillHover: 'rgba(255,255,255,0.06)',
    fillPressed: 'rgba(255,255,255,0.10)',
    fillSelected: '#11233A',
    fillSelectedHover: '#16304F',
    scrim: 'rgba(0,0,0,0.56)',
    surfaceInverse: '#F5F5F7',
    textOnInverse: '#1D1D1F',
    textPrimary: '#F5F5F7',
    textSecondary: '#C7C7CC',
    textTertiary: '#A1A1A8',
    textDisabled: '#6C6C72',
    textLink: '#4C9EFF',
    textOnAccent: '#FFFFFF',
    accent: '#0A66D8',
    accentHover: '#1F74E0',
    accentPressed: '#0749A0',
    accentSubtle: '#11233A',
    accentOnSubtle: '#4C9EFF',
    borderControl: '#7C7C84',
    borderSubtle: '#3A3A3E',
    borderGlassHighlight: 'rgba(255,255,255,0.14)',
    borderGlassEdge: 'rgba(0,0,0,0.60)',
    focusRing: '#4C9EFF',
    focusRingInner: '#0E0E10',
    successText: '#3FB950',
    successBg: '#12261A',
    warningText: '#E3B341',
    warningBg: '#2B2111',
    errorText: '#FF6B6B',
    errorBg: '#2D1517',
    errorSolid: '#C9252D',
    infoText: '#4C9EFF',
    infoBg: '#11233A',
    neutralText: '#C7C7CC',
    neutralBg: '#2A2A2E',
  },
  glass: {
    chrome: 'rgba(28,28,30,0.70)',
    chromeScrolled: 'rgba(28,28,30,0.84)',
    modal: 'rgba(28,28,30,0.88)',
    overlay: 'rgba(28,28,30,0.90)',
    lite: 'rgba(28,28,30,0.96)',
    highlightTop: 'inset 0 1px 0 0 rgba(255,255,255,0.12)',
    edge: '0 0 0 0.5px rgba(0,0,0,0.60)',
  },
  shadow: {
    '0': 'none',
    '1': '0 1px 2px rgba(0,0,0,0.5)',
    '2': '0 2px 6px rgba(0,0,0,0.5), 0 8px 24px rgba(0,0,0,0.4)',
    '3': '0 4px 12px rgba(0,0,0,0.5), 0 16px 40px rgba(0,0,0,0.5)',
    '4': '0 8px 24px rgba(0,0,0,0.6), 0 32px 64px rgba(0,0,0,0.6)',
  },
};

/** Token không phụ thuộc chế độ sáng/tối (D03-05-02 §6–§12). */
export const staticTokens = {
  radius: { xs: '4px', sm: '6px', md: '10px', lg: '14px', xl: '20px', pill: '9999px' },
  space: {
    '0': '0',
    '0-5': '2px',
    '1': '4px',
    '2': '8px',
    '3': '12px',
    '4': '16px',
    '5': '20px',
    '6': '24px',
    '8': '32px',
    '10': '40px',
    '12': '48px',
    '16': '64px',
  },
  font: {
    familySans:
      '"Inter Variable", Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
    familyMono: '"JetBrains Mono Variable", "JetBrains Mono", ui-monospace, "SF Mono", Menlo, Consolas, monospace',
    caption: '12px',
    footnote: '13px',
    body: '14px',
    callout: '16px',
    title2: '20px',
    title1: '24px',
    lineCaption: '18px',
    lineBody: '22px',
    lineTitle2: '28px',
    weightRegular: '400',
    weightMedium: '500',
    weightSemibold: '600',
  },
  blur: { md: '24px', lg: '32px', xl: '40px', saturate: '180%', saturateMuted: '160%' },
  motion: {
    durationFast: '140ms',
    durationBase: '220ms',
    easeStandard: 'cubic-bezier(0.2, 0, 0, 1)',
  },
  size: {
    controlSm: '24px',
    controlMd: '32px',
    iconMd: '16px',
    topbar: '56px',
    sidebar: '256px',
    treePanel: '320px',
    page: '1600px',
    avatar: '32px',
    touchMin: '24px',
  },
  z: { sidebar: '200', topbar: '300', skipLink: '1300' },
} as const;

export const tokens: Readonly<Record<DhMode, ModeTokens>> = { light, dark };

function kebab(name: string): string {
  return name.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();
}

function declarations(mode: ModeTokens): string {
  const lines: string[] = [];
  for (const [name, value] of Object.entries(mode.color)) {
    lines.push(`--dh-color-${kebab(name)}: ${value};`);
  }
  for (const [name, value] of Object.entries(mode.glass)) {
    lines.push(`--dh-glass-${kebab(name)}: ${value};`);
  }
  for (const [name, value] of Object.entries(mode.shadow)) {
    lines.push(`--dh-shadow-${name}: ${value};`);
  }
  return lines.join('\n  ');
}

function staticDeclarations(): string {
  const lines: string[] = [];
  for (const [group, entries] of Object.entries(staticTokens)) {
    for (const [name, value] of Object.entries(entries)) {
      lines.push(`--dh-${kebab(group)}-${kebab(name)}: ${value};`);
    }
  }
  return lines.join('\n  ');
}

/** Sinh CSS biến `--dh-*`: chế độ sáng mặc định, tối khi `data-theme="dark"`. */
export function tokensToCss(): string {
  return [
    `:root,\n:root[data-theme="light"] {\n  color-scheme: light;\n  ${declarations(light)}\n  ${staticDeclarations()}\n}`,
    `:root[data-theme="dark"] {\n  color-scheme: dark;\n  ${declarations(dark)}\n}`,
  ].join('\n');
}
