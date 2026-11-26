import { App as AntApp, ConfigProvider } from 'antd';
import viVN from 'antd/locale/vi_VN';
import dayjs from 'dayjs';
import 'dayjs/locale/vi';
import { useLayoutEffect, useMemo, type ReactNode } from 'react';
import { buildAntdTheme } from './antd-theme';
import { tokensToCss, type DhDensity, type DhGlass, type DhMode } from './tokens';
import './base.css';

export interface DhThemeProviderProps {
  mode?: DhMode;
  density?: DhDensity;
  glass?: DhGlass;
  children: ReactNode;
}

const TOKEN_CSS = tokensToCss();

/**
 * Cấp theme antd từ token, biến CSS `--dh-*` và các thuộc tính `data-theme|density|glass` trên
 * `<html>`. Bao `AntApp` để message, notification, modal nhận đúng theme (dùng qua App.useApp()).
 */
export function DhThemeProvider({ mode = 'light', density = 'comfortable', glass = 'full', children }: DhThemeProviderProps) {
  const themeConfig = useMemo(() => buildAntdTheme(mode, density, glass), [mode, density, glass]);
  dayjs.locale('vi');

  useLayoutEffect(() => {
    const root = document.documentElement;
    root.dataset['theme'] = mode;
    root.dataset['density'] = density;
    root.dataset['glass'] = glass;
  }, [mode, density, glass]);

  return (
    <>
      <style href="dh-tokens" precedence="default">
        {TOKEN_CSS}
      </style>
      <ConfigProvider
        theme={themeConfig}
        locale={viVN}
        componentSize={density === 'compact' ? 'small' : 'middle'}
        wave={{ disabled: true }}
      >
        <AntApp>{children}</AntApp>
      </ConfigProvider>
    </>
  );
}
