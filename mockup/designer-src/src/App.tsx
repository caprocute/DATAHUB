import { ReactFlowProvider } from '@xyflow/react';
import { App as AntApp, Button, ConfigProvider } from 'antd';
import { useCallback, useEffect, useState } from 'react';
import { Designer } from './Designer';
import { ROUTE_ID } from './flow/model';
import { ReviewPanel } from './panels/ReviewPanel';
import { TestPanel } from './panels/TestPanel';
import { AppShell } from './shell/AppShell';
import { antdThemeFor } from './theme/tokens';
import { useTheme } from './theme/useTheme';

export type DesignerTab = 'design' | 'test' | 'review';

function tabFromHash(): DesignerTab {
  const h = (window.location.hash || '').replace(/^#/, '');
  if (h === 'test' || h === 'review') return h;
  return 'design';
}

export function App() {
  const { mode, toggle } = useTheme();
  const [dirty, setDirty] = useState(false);
  const [counts, setCounts] = useState({ errors: 0, warns: 0 });
  const [tab, setTab] = useState<DesignerTab>(tabFromHash);

  const onDirty = useCallback(() => setDirty(true), []);

  const go = useCallback((next: DesignerTab) => {
    setTab(next);
    const hash = next === 'design' ? 'design' : next;
    if (window.location.hash.replace(/^#/, '') !== hash) {
      window.history.replaceState(null, '', `${window.location.pathname}${window.location.search}#${hash}`);
    }
  }, []);

  useEffect(() => {
    const onHash = () => setTab(tabFromHash());
    window.addEventListener('hashchange', onHash);
    return () => window.removeEventListener('hashchange', onHash);
  }, []);

  return (
    <ConfigProvider theme={antdThemeFor(mode)}>
      <AntApp>
        <AppShell
          activeId="designer"
          title="Thiết kế luồng"
          crumbs={[
            { text: 'Trang chủ', href: 'index.html' },
            { text: 'Luồng tích hợp', href: 'pages/routes.html' },
            { text: 'Thiết kế luồng' },
          ]}
          onToggleTheme={toggle}
        >
          <div className="mock-note">
            <strong>PH-04 — Thiết kế luồng bằng giao diện.</strong> Màn <span className="tag-ph">UI-04-07</span> trình
            thiết kế kéo thả (XYFlow), <span className="tag-ph">UI-04-08</span> chạy thử và{' '}
            <span className="tag-ph">UI-04-09</span> duyệt — cùng một app React. Động cơ sơ đồ:{' '}
            <a href="../../../docs/05-adr/README.md#adr-017">ADR-017</a>; catalog/YAML theo mẫu{' '}
            <a href="https://kaoto.io/">Kaoto</a> (<a href="../../../docs/05-adr/README.md#adr-015">ADR-015</a>). Đặc tả
            tại M6 của <a href="../../../docs/07-srs/SRS-PH-04-integration-core.md">SRS PH-04</a>.
          </div>

          <div className="page-head">
            <div className="page-head__main">
              <h1 className="page-title">{ROUTE_ID}</h1>
              <p className="page-desc">
                Tra cứu thông tin thửa đất · phiên bản 4 <span className="badge badge--muted">DRAFT</span>
                <span className="t-small t-muted">
                  {dirty ? ' — có thay đổi chưa lưu' : ' — lưu lúc 15:04, người sửa: Nguyễn Văn Quản'}
                </span>
              </p>
            </div>
            <div className="page-head__actions">
              <a className="btn" href="../routes.html">
                ← Danh sách luồng
              </a>
              <Button onClick={() => setDirty(false)}>Lưu bản nháp</Button>
              <Button onClick={() => go('test')}>▷ Chạy thử</Button>
              <Button
                type="primary"
                disabled={counts.errors > 0}
                title={
                  counts.errors > 0
                    ? `Còn ${counts.errors} lỗi cần xử lý trước khi gửi duyệt`
                    : 'Gửi luồng sang hàng đợi duyệt'
                }
                onClick={() => go('review')}
              >
                Gửi duyệt
              </Button>
            </div>
          </div>

          <div className="tabs">
            <button type="button" className={tab === 'design' ? 'tab is-active' : 'tab'} onClick={() => go('design')}>
              Thiết kế
            </button>
            <button type="button" className={tab === 'test' ? 'tab is-active' : 'tab'} onClick={() => go('test')}>
              Chạy thử
            </button>
            <button type="button" className={tab === 'review' ? 'tab is-active' : 'tab'} onClick={() => go('review')}>
              Duyệt <span className="tab__count">4</span>
            </button>
          </div>

          {tab === 'design' && (
            <ReactFlowProvider>
              <Designer mode={mode} onDirty={onDirty} onStatus={setCounts} />
            </ReactFlowProvider>
          )}
          {tab === 'test' && <TestPanel />}
          {tab === 'review' && <ReviewPanel />}
        </AppShell>
      </AntApp>
    </ConfigProvider>
  );
}
