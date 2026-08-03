import type { ReactNode } from 'react';

/**
 * Khung vỏ của mockup — thanh điều hướng bên trái và thanh đỉnh.
 *
 * Dựng lại đúng cấu trúc và tên lớp mà `mockup/js/app.js` sinh ra, để trang React này
 * và các trang HTML tĩnh trông như cùng một sản phẩm. Trang nằm ở `pages/designer/`
 * nên mọi liên kết lùi hai cấp.
 */

const BASE = '../../';

interface NavItem {
  id: string;
  icon: string;
  text: string;
  href: string;
  ph?: string;
  badge?: number;
}

const NAV: { label: string; items: NavItem[] }[] = [
  { label: 'Tổng quan', items: [{ id: 'home', icon: '◈', text: 'Bảng điều khiển', href: 'index.html' }] },
  {
    label: 'Quản trị kết nối',
    items: [
      { id: 'onboarding', icon: '⊕', text: 'Kết nạp hệ thống', href: 'pages/onboarding.html', ph: 'PH-01', badge: 3 },
      { id: 'catalog', icon: '☰', text: 'Danh mục dịch vụ', href: 'pages/catalog.html', ph: 'PH-02' },
      { id: 'routes', icon: '⇄', text: 'Luồng tích hợp', href: 'pages/routes.html', ph: 'PH-04' },
      { id: 'designer', icon: '✎', text: 'Thiết kế luồng', href: 'pages/designer/index.html', ph: 'PH-04' },
    ],
  },
  {
    label: 'Dữ liệu',
    items: [
      { id: 'mdm', icon: '◉', text: 'Dữ liệu chủ', href: 'pages/mdm.html', ph: 'PH-06', badge: 12 },
      { id: 'privacy', icon: '⊘', text: 'Bảo vệ dữ liệu', href: 'pages/privacy.html', ph: 'PH-09' },
    ],
  },
  {
    label: 'Vận hành',
    items: [
      { id: 'monitoring', icon: '◎', text: 'Giám sát & truy vết', href: 'pages/monitoring.html', ph: 'PH-13' },
      { id: 'dlq', icon: '⚠', text: 'Bản tin lỗi', href: 'pages/dlq.html', ph: 'PH-18', badge: 47 },
    ],
  },
  {
    label: 'Tuân thủ',
    items: [
      { id: 'kpi', icon: '◱', text: 'Báo cáo KPI', href: 'pages/kpi.html', ph: 'PH-16' },
      { id: 'ai', icon: '✦', text: 'Quản trị AI', href: 'pages/ai.html', ph: 'PH-17' },
    ],
  },
];

interface Crumb {
  text: string;
  href?: string;
}

interface Props {
  activeId: string;
  title: string;
  crumbs: Crumb[];
  onToggleTheme: () => void;
  children: ReactNode;
}

export function AppShell({ activeId, title, crumbs, onToggleTheme, children }: Props) {
  return (
    <div className="layout">
      <aside className="sidebar" id="sidebar">
        <div className="sidebar__brand">
          <a className="sidebar__logo" href={`${BASE}index.html`} style={{ textDecoration: 'none' }}>
            <span className="sidebar__logo-mark">LG</span>
            <span>LGSP</span>
          </a>
          <div className="sidebar__sub">Nền tảng tích hợp, chia sẻ dữ liệu</div>
        </div>
        <nav className="sidebar__nav">
          {NAV.map((g) => (
            <div className="nav__group" key={g.label}>
              <div className="nav__label">{g.label}</div>
              {g.items.map((it) => (
                <a
                  className={it.id === activeId ? 'nav__item is-active' : 'nav__item'}
                  href={`${BASE}${it.href}`}
                  key={it.id}
                >
                  <span className="nav__icon">{it.icon}</span>
                  <span>{it.text}</span>
                  {it.badge ? (
                    <span className="nav__badge">{it.badge}</span>
                  ) : it.ph ? (
                    <span className="nav__ph">{it.ph}</span>
                  ) : null}
                </a>
              ))}
            </div>
          ))}
        </nav>
        <div className="sidebar__foot">
          Phiên bản mockup 1.0
          <br />
          <span style={{ opacity: 0.7 }}>Tỉnh/Bộ — môi trường thử nghiệm</span>
        </div>
      </aside>

      <div className="main">
        <header className="header">
          <div className="header__title">{title}</div>
          <div className="header__spacer" />
          <div className="crumb" style={{ margin: 0 }}>
            {crumbs.map((c, i) => (
              <span key={c.text}>
                {i > 0 && <span className="crumb__sep">/</span>}
                {c.href ? <a href={`${BASE}${c.href}`}>{c.text}</a> : <span>{c.text}</span>}
              </span>
            ))}
          </div>
          <button
            className="theme-toggle"
            onClick={onToggleTheme}
            aria-label="Chuyển chế độ sáng tối"
            title="Chuyển chế độ sáng / tối"
          >
            <span className="theme-toggle__moon" aria-hidden="true">
              ☾
            </span>
            <span className="theme-toggle__sun" aria-hidden="true">
              ☀
            </span>
          </button>
          <div className="header__user">
            <div className="avatar">NV</div>
            <div>
              <div className="header__user-name">Nguyễn Văn Quản</div>
              <div className="header__user-role">Quản trị viên nền tảng</div>
            </div>
          </div>
        </header>
        <div className="content">{children}</div>
      </div>
    </div>
  );
}
