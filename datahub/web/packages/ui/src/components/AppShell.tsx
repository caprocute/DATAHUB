import type { MouseEvent, ReactNode } from 'react';
import { t } from '@datahub/i18n';
import './app-shell.css';

export interface ShellNavItem {
  key: string;
  label: string;
  href: string;
}

export interface ShellNavGroup {
  key: string;
  label: string;
  items: readonly ShellNavItem[];
}

export interface AppShellProps {
  /** Tên hiển thị trên đầu thanh bên, ví dụ "Datahub · Quản trị". */
  brand: string;
  groups: readonly ShellNavGroup[];
  activeKey: string;
  /** Gọi khi bấm một liên kết điều hướng (để dùng bộ định tuyến phía khách). */
  onNavigate?: (href: string) => void;
  tenantLabel?: string;
  userName?: string;
  children: ReactNode;
}

function initials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  const letters = parts.slice(-2).map((p) => p.charAt(0).toUpperCase());
  return letters.join('') || '?';
}

/**
 * Khung ứng dụng: thanh trên và thanh bên là lớp điều hướng dùng vật liệu glass (ADR-020), vùng
 * nội dung bên dưới là nền đặc. Có liên kết "Bỏ qua tới nội dung" và các vùng mốc header, nav, main.
 */
export function AppShell({ brand, groups, activeKey, onNavigate, tenantLabel, userName, children }: AppShellProps) {
  const handleClick = (event: MouseEvent<HTMLAnchorElement>, href: string) => {
    if (onNavigate && !event.metaKey && !event.ctrlKey && !event.shiftKey && event.button === 0) {
      event.preventDefault();
      onNavigate(href);
    }
  };

  return (
    <div className="dh-shell">
      <a className="dh-skip-link" href="#dh-main">
        {t('app.skipToContent')}
      </a>
      <header className="dh-topbar dh-glass">
        <span className="dh-topbar__brand">{brand}</span>
        <span className="dh-topbar__spacer" />
        {tenantLabel ? <span className="dh-topbar__tenant">{tenantLabel}</span> : null}
        {userName ? (
          <span className="dh-avatar" role="img" aria-label={t('app.user', { name: userName })}>
            {initials(userName)}
          </span>
        ) : null}
      </header>
      <nav className="dh-sidebar dh-glass" aria-label={t('app.nav.label')}>
        {groups.map((group) => (
          <div className="dh-nav-group" key={group.key}>
            <p className="dh-nav-group__label" id={`dh-nav-${group.key}`}>
              {group.label}
            </p>
            <ul className="dh-nav-list" aria-labelledby={`dh-nav-${group.key}`}>
              {group.items.map((item) => (
                <li key={item.key}>
                  <a
                    className="dh-nav-link"
                    href={item.href}
                    aria-current={item.key === activeKey ? 'page' : undefined}
                    onClick={(event) => handleClick(event, item.href)}
                  >
                    {item.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </nav>
      <main id="dh-main" className="dh-main" tabIndex={-1}>
        {children}
      </main>
    </div>
  );
}
