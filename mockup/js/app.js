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
      { id: 'portal',     icon: '◫', text: 'Cổng nhà phát triển', href: 'pages/portal.html',  ph: 'PH-15' },
      { id: 'routes',     icon: '⇄', text: 'Luồng tích hợp',   href: 'pages/routes.html',     ph: 'PH-04' },
      { id: 'designer',   icon: '✎', text: 'Thiết kế luồng',   href: 'pages/designer/index.html', ph: 'PH-04' },
      { id: 'adapters',   icon: '🔌', text: 'Adapter kết nối',  href: 'pages/adapters.html',   ph: 'PH-05' },
      { id: 'gateway',    icon: '🛡', text: 'Cổng tiếp nhận',   href: 'pages/gateway.html',    ph: 'PH-03' },
    ],
  },
  {
    label: 'Dữ liệu',
    items: [
      { id: 'mdm',       icon: '◉', text: 'Dữ liệu chủ',      href: 'pages/mdm.html',       ph: 'PH-06', badge: 12 },
      { id: 'reference', icon: '📖', text: 'Danh mục dùng chung', href: 'pages/reference.html', ph: 'PH-07' },
      { id: 'dq',        icon: '✓', text: 'Chất lượng dữ liệu',  href: 'pages/dq.html',        ph: 'PH-08' },
      { id: 'privacy',   icon: '⊘', text: 'Bảo vệ dữ liệu',   href: 'pages/privacy.html',   ph: 'PH-09' },
      { id: 'national',  icon: '🌐', text: 'Kết nối quốc gia', href: 'pages/national.html',  ph: 'PH-14' },
    ],
  },
  {
    label: 'Vận hành',
    items: [
      { id: 'monitoring', icon: '◎', text: 'Giám sát & truy vết', href: 'pages/monitoring.html', ph: 'PH-13' },
      { id: 'dlq',        icon: '⚠', text: 'Bản tin lỗi',         href: 'pages/dlq.html',        ph: 'PH-18', badge: 47 },
      { id: 'events',     icon: '📡', text: 'Truyền thông sự kiện', href: 'pages/events.html',    ph: 'PH-10' },
      { id: 'bpm',        icon: '⑃', text: 'Quy trình nghiệp vụ', href: 'pages/bpm.html',        ph: 'PH-11', badge: 8 },
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

/** Lọc bảng theo ô tìm kiếm: data-filter trỏ tới id của bảng (Enter = tìm — CRUD-FLT-03) */
function initFilters() {
  document.querySelectorAll('[data-filter]').forEach(input => {
    const apply = () => {
      const q = input.value.trim().toLowerCase();
      const table = document.getElementById(input.dataset.filter);
      if (!table) return;
      let visible = 0;
      table.querySelectorAll('tbody tr').forEach(tr => {
        const hide = !!(q && !tr.textContent.toLowerCase().includes(q));
        tr.classList.toggle('hidden', hide);
        if (!hide) visible += 1;
      });
      const wrap = table.closest('.table-wrap');
      const empty = wrap?.parentElement?.querySelector('[data-crud-empty]');
      if (empty) empty.classList.toggle('hidden', visible > 0 || !q);
      const noResult = wrap?.parentElement?.querySelector('[data-crud-no-result]');
      if (noResult) noResult.classList.toggle('hidden', visible > 0 || !q);
    };
    input.addEventListener('input', apply);
    input.addEventListener('keydown', e => {
      if (e.key === 'Enter') {
        e.preventDefault();
        apply();
      }
    });
  });
}

/** Chuẩn CRUD mock (docs/ui_ux_rule.md) — filter nâng cao, pagination khớp số, sticky, bulk, tooltip */
function initCrudUi() {
  // Sticky thead + cột thao tác
  document.querySelectorAll('table.table').forEach(table => {
    if (!table.classList.contains('table--sticky')) table.classList.add('table--sticky');
    const wrap = table.closest('.table-wrap');
    if (wrap && !wrap.classList.contains('table-wrap--sticky')) {
      wrap.classList.add('table-wrap--sticky');
    }
  });

  // Tooltip bắt buộc cho nút chỉ có biểu tượng (CRUD-UI-06/07)
  document.querySelectorAll('button.btn, a.btn').forEach(el => {
    if (el.getAttribute('title') || el.getAttribute('aria-label')) return;
    const text = (el.textContent || '').replace(/\s+/g, ' ').trim();
    if (!text || text.length <= 2) {
      const demo = el.getAttribute('data-demo');
      el.setAttribute('title', demo || 'Thao tác');
      if (!el.getAttribute('aria-label')) el.setAttribute('aria-label', demo || 'Thao tác');
    }
  });

  // Thu gọn / hiện bộ lọc nâng cao
  document.querySelectorAll('[data-crud-filter-toggle]').forEach(btn => {
    btn.addEventListener('click', () => {
      const root = btn.closest('[data-crud-filter]') || btn.closest('.crud-filter') || btn.parentElement;
      const adv = root?.querySelector('.crud-filter__advanced');
      if (!adv) return;
      const nowHidden = adv.classList.toggle('hidden');
      const showing = !nowHidden;
      btn.setAttribute('aria-expanded', showing ? 'true' : 'false');
      btn.title = showing ? 'Ẩn bộ lọc nâng cao' : 'Hiện bộ lọc nâng cao';
      if (!btn.dataset.keepLabel) {
        btn.textContent = showing ? 'Thu gọn bộ lọc' : 'Bộ lọc nâng cao';
      }
    });
  });

  // Đặt lại bộ lọc
  document.querySelectorAll('[data-crud-reset]').forEach(btn => {
    btn.addEventListener('click', e => {
      e.preventDefault();
      const root = btn.closest('[data-crud-filter]') || btn.closest('.card') || document;
      root.querySelectorAll('input[type="text"], input[type="search"]').forEach(i => {
        i.value = '';
        i.dispatchEvent(new Event('input'));
      });
      root.querySelectorAll('select').forEach(s => { s.selectedIndex = 0; });
      if (btn.dataset.demo) return; // initDemoActions vẫn bắt nếu có data-demo
    });
  });

  // Phân trang khớp total / pageSize / totalPages (CRUD-PAG-*)
  document.querySelectorAll('table.table[data-crud-total]').forEach(table => {
    const wrap = table.closest('.table-wrap');
    if (!wrap) return;
    if (wrap.parentElement?.querySelector(':scope > .crud-pagination')) return;
    const total = Math.max(0, Number(table.dataset.crudTotal) || 0);
    const size = Math.max(1, Number(table.dataset.crudPageSize) || 10);
    let page = Math.max(1, Number(table.dataset.crudPage) || 1);
    const totalPages = Math.max(1, Math.ceil(total / size) || 1);
    if (page > totalPages) page = totalPages;

    const nav = document.createElement('div');
    nav.className = 'crud-pagination';
    nav.setAttribute('role', 'navigation');
    nav.setAttribute('aria-label', 'Phân trang');
    const from = total === 0 ? 0 : (page - 1) * size + 1;
    const to = Math.min(page * size, total);
    nav.innerHTML = `
      <div class="crud-pagination__total">
        Hiển thị <strong>${from}–${to}</strong> / <strong>${total.toLocaleString('vi-VN')}</strong> bản ghi
      </div>
      <label class="t-small">Mỗi trang
        <select class="select crud-pagination__size" style="width:auto;height:var(--ant-control-h-sm)" title="Số dòng mỗi trang">
          ${[10, 20, 50, 100].map(n => `<option value="${n}"${n === size ? ' selected' : ''}>${n}</option>`).join('')}
        </select>
      </label>
      <div class="crud-pagination__pages">
        <button type="button" class="btn btn--sm" data-crud-page="prev" title="Trang trước" ${page <= 1 ? 'disabled' : ''}>‹</button>
        <button type="button" class="btn btn--sm is-active" title="Trang hiện tại">${page} / ${totalPages}</button>
        <button type="button" class="btn btn--sm" data-crud-page="next" title="Trang sau" ${page >= totalPages ? 'disabled' : ''}>›</button>
      </div>
      <label class="t-small">Tới trang
        <input class="input crud-pagination__jump" type="number" min="1" max="${totalPages}" value="${page}" title="Nhập số trang">
      </label>`;
    wrap.insertAdjacentElement('afterend', nav);

    nav.querySelector('[data-crud-page="prev"]')?.addEventListener('click', () => {
      alert(`[Mockup] Trang ${Math.max(1, page - 1)} — phân trang phía máy chủ (CRUD-TBL-02).`);
    });
    nav.querySelector('[data-crud-page="next"]')?.addEventListener('click', () => {
      alert(`[Mockup] Trang ${Math.min(totalPages, page + 1)} — phân trang phía máy chủ (CRUD-TBL-02).`);
    });
    nav.querySelector('.crud-pagination__size')?.addEventListener('change', e => {
      alert(`[Mockup] Đổi pageSize=${e.target.value} → về trang 1 (CRUD-FLT-06).`);
    });
    nav.querySelector('.crud-pagination__jump')?.addEventListener('keydown', e => {
      if (e.key !== 'Enter') return;
      const v = Number(e.target.value);
      if (v < 1 || v > totalPages) {
        alert(`[Mockup] Số trang phải trong 1…${totalPages} (CRUD-PAG-07).`);
        e.target.value = String(page);
        return;
      }
      alert(`[Mockup] Nhảy tới trang ${v}.`);
    });
  });

  // Bulk bar: hiện khi có checkbox được chọn
  document.querySelectorAll('[data-crud-bulk]').forEach(bar => {
    const tableId = bar.dataset.crudBulk;
    const table = document.getElementById(tableId);
    if (!table) return;
    const countEl = bar.querySelector('[data-crud-bulk-count]');
    const sync = () => {
      const boxes = [...table.querySelectorAll('tbody input[type="checkbox"]')];
      const n = boxes.filter(c => c.checked).length;
      bar.classList.toggle('is-visible', n > 0);
      if (countEl) countEl.textContent = String(n);
      boxes.forEach(c => c.closest('tr')?.classList.toggle('is-selected', c.checked));
      const head = table.querySelector('thead input[type="checkbox"]');
      if (head && boxes.length) {
        head.checked = n === boxes.length;
        head.indeterminate = n > 0 && n < boxes.length;
      }
    };
    table.addEventListener('change', e => {
      if (e.target.matches('input[type="checkbox"]')) {
        if (e.target.closest('thead')) {
          const on = e.target.checked;
          table.querySelectorAll('tbody input[type="checkbox"]').forEach(c => { c.checked = on; });
        }
        sync();
      }
    });
    sync();
  });

  // Ellipsis + title đầy đủ (CRUD-TBL-07)
  document.querySelectorAll('td.t-ellipsis, .t-ellipsis').forEach(el => {
    if (!el.getAttribute('title')) el.setAttribute('title', el.textContent.trim());
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
  initCrudUi();
  initDemoActions();
  initThemeToggle();
});
