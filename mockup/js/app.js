/* ============================================================
   LGSP Mockup — Khung dùng chung: điều hướng, layout, tiện ích
   Mỗi trang chỉ cần khai báo window.LGSP_PAGE rồi gọi renderShell()
   ============================================================ */

const NAV = [
  {
    label: 'Tổng quan',
    items: [
      { id: 'home', icon: '◈', text: 'Bảng điều khiển', href: 'index.html', ph: null },
    ],
  },
  {
    label: 'Quản trị kết nối',
    items: [
      { id: 'onboarding', icon: '⊕', text: 'Kết nạp hệ thống', href: 'pages/onboarding.html', ph: 'PH-01', badge: 3 },
      { id: 'catalog',    icon: '☰', text: 'Danh mục dịch vụ', href: 'pages/catalog.html',    ph: 'PH-02' },
      { id: 'routes',     icon: '⇄', text: 'Luồng tích hợp',   href: 'pages/routes.html',     ph: 'PH-04' },
      { id: 'designer',   icon: '✎', text: 'Thiết kế luồng',   href: 'pages/designer/index.html', ph: 'PH-04' },
      { id: 'adapters',   icon: '🔌', text: 'Adapter kết nối',  href: 'pages/adapters.html',   ph: 'PH-05' },
      { id: 'gateway',    icon: '🛡', text: 'Cổng tiếp nhận',   href: 'pages/gateway.html',    ph: 'PH-03' },
    ],
  },
  {
    label: 'Dữ liệu',
    items: [
      { id: 'mdm',     icon: '◉', text: 'Dữ liệu chủ',        href: 'pages/mdm.html',     ph: 'PH-06', badge: 12 },
      { id: 'privacy', icon: '⊘', text: 'Bảo vệ dữ liệu',     href: 'pages/privacy.html', ph: 'PH-09' },
    ],
  },
  {
    label: 'Vận hành',
    items: [
      { id: 'monitoring', icon: '◎', text: 'Giám sát & truy vết', href: 'pages/monitoring.html', ph: 'PH-13' },
      { id: 'dlq',        icon: '⚠', text: 'Bản tin lỗi',         href: 'pages/dlq.html',        ph: 'PH-18', badge: 47 },
    ],
  },
  {
    label: 'Tuân thủ',
    items: [
      { id: 'kpi', icon: '◱', text: 'Báo cáo KPI',   href: 'pages/kpi.html', ph: 'PH-16' },
      { id: 'ai',  icon: '✦', text: 'Quản trị AI',   href: 'pages/ai.html',  ph: 'PH-17' },
    ],
  },
  {
    label: 'Định danh',
    items: [
      { id: 'iam', icon: '🔐', text: 'Người dùng & quyền', href: 'pages/iam.html', ph: 'PH-12' },
    ],
  },
];

/** Tiền tố đường dẫn: trang trong pages/ cần lùi một cấp */
function base() {
  return window.location.pathname.includes('/pages/') ? '../' : '';
}

function renderSidebar(activeId) {
  const b = base();
  const groups = NAV.map(g => {
    const items = g.items.map(it => {
      const active = it.id === activeId ? ' is-active' : '';
      const badge = it.badge ? `<span class="nav__badge">${it.badge}</span>` : '';
      const ph = !it.badge && it.ph ? `<span class="nav__ph">${it.ph}</span>` : '';
      return `<a class="nav__item${active}" href="${b}${it.href}">
        <span class="nav__icon">${it.icon}</span>
        <span>${it.text}</span>${badge}${ph}
      </a>`;
    }).join('');
    return `<div class="nav__group"><div class="nav__label">${g.label}</div>${items}</div>`;
  }).join('');

  return `<aside class="sidebar" id="sidebar">
    <div class="sidebar__brand">
      <a class="sidebar__logo" href="${b}index.html" style="text-decoration:none">
        <span class="sidebar__logo-mark">LG</span>
        <span>LGSP</span>
      </a>
      <div class="sidebar__sub">Nền tảng tích hợp, chia sẻ dữ liệu</div>
    </div>
    <nav class="sidebar__nav">${groups}</nav>
    <div class="sidebar__foot">
      Phiên bản mockup 1.0<br>
      <span style="opacity:.7">Tỉnh/Bộ — môi trường thử nghiệm</span>
    </div>
  </aside>`;
}

function renderHeader(page) {
  const crumbs = (page.crumbs || [])
    .map(c => c.href
      ? `<a href="${base()}${c.href}">${c.text}</a>`
      : `<span>${c.text}</span>`)
    .join('<span class="crumb__sep">/</span>');

  return `<header class="header">
    <button class="btn btn--ghost btn--sm" onclick="document.getElementById('sidebar').classList.toggle('is-open')"
            style="display:none" id="burger">☰</button>
    <div class="header__title">${page.title}</div>
    <div class="header__spacer"></div>
    <div class="crumb" style="margin:0">${crumbs}</div>
    <button class="theme-toggle" id="theme-toggle" aria-label="Chuyển chế độ sáng tối"
            title="Chuyển chế độ sáng / tối">
      <span class="theme-toggle__moon" aria-hidden="true">☾</span>
      <span class="theme-toggle__sun" aria-hidden="true">☀</span>
    </button>
    <div class="header__user">
      <div class="avatar">NV</div>
      <div>
        <div class="header__user-name">Nguyễn Văn Quản</div>
        <div class="header__user-role">Quản trị viên nền tảng</div>
      </div>
    </div>
  </header>`;
}

/** Dựng khung trang: sidebar + header, rồi bọc nội dung sẵn có trong <main> */
function renderShell() {
  const page = window.LGSP_PAGE || { id: 'home', title: 'LGSP', crumbs: [] };
  const body = document.body;
  const content = body.innerHTML;

  body.innerHTML = `<div class="layout">
    ${renderSidebar(page.id)}
    <div class="main">
      ${renderHeader(page)}
      <div class="content">${content}</div>
    </div>
  </div>`;

  document.title = `${page.title} — LGSP`;

  if (window.innerWidth <= 820) {
    const bg = document.getElementById('burger');
    if (bg) bg.style.display = 'inline-flex';
  }
}

/* ---------- Tiện ích tương tác cho mockup ---------- */

/** Chuyển tab: data-tab trên nút, data-panel trên vùng nội dung */
function initTabs() {
  document.querySelectorAll('[data-tab]').forEach(btn => {
    btn.addEventListener('click', () => {
      const group = btn.closest('.tabs');
      const target = btn.dataset.tab;
      group.querySelectorAll('[data-tab]').forEach(b => b.classList.toggle('is-active', b === btn));
      document.querySelectorAll(`[data-panel]`).forEach(p => {
        if (p.dataset.panelGroup === group.dataset.tabsGroup) {
          p.classList.toggle('hidden', p.dataset.panel !== target);
        }
      });
    });
  });
}

/** Mở sẵn một tab theo mảnh neo, ví dụ `designer.html#review` */
function initTabHash() {
  const target = window.location.hash.slice(1);
  if (!target) return;
  const btn = document.querySelector(`[data-tab="${target}"]`);
  if (btn) btn.click();
}

/** Lọc bảng theo ô tìm kiếm: data-filter trỏ tới id của bảng */
function initFilters() {
  document.querySelectorAll('[data-filter]').forEach(input => {
    input.addEventListener('input', () => {
      const q = input.value.trim().toLowerCase();
      const table = document.getElementById(input.dataset.filter);
      if (!table) return;
      table.querySelectorAll('tbody tr').forEach(tr => {
        tr.classList.toggle('hidden', q && !tr.textContent.toLowerCase().includes(q));
      });
    });
  });
}

/** Nút chỉ để minh họa — báo cho người xem biết đây là mockup */
function initDemoActions() {
  document.querySelectorAll('[data-demo]').forEach(el => {
    el.addEventListener('click', e => {
      e.preventDefault();
      alert(`[Mockup] Thao tác: ${el.dataset.demo}\n\nĐây là bản minh họa giao diện, chưa nối hệ thống thật.`);
    });
  });
}

/** Nút chuyển sáng/tối — phải gắn sau renderShell vì thanh đỉnh được dựng lại */
function initThemeToggle() {
  const btn = document.getElementById('theme-toggle');
  if (btn && window.LGSP_THEME) btn.addEventListener('click', () => window.LGSP_THEME.toggle());
}

document.addEventListener('DOMContentLoaded', () => {
  renderShell();
  initTabs();
  initTabHash();
  initFilters();
  initDemoActions();
  initThemeToggle();
});
